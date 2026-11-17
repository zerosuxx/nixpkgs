{ lib
, stdenv
, fetchurl
, patchelf
}:

with lib;
let
  info = splitString "-" stdenv.hostPlatform.system;
  arch = elemAt info 0;
  platform = elemAt info 1;
in
stdenv.mkDerivation rec {
  pname = "kibana";
  version = "8.15.0";

  src =
    let
      system = stdenv.hostPlatform.system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      sha256 = selectSystem {
        x86_64-linux   = "sha256-13+dZa1yT3NhXS5bPBhGBYHp08ifMwD7717QAV5hGkQ=";
        x86_64-darwin  = "sha256-qTvS28lp1Ixi/7arzYxdKUMQ7GGiNhh4adyazV2EkN4=";
        aarch64-linux  = "sha256-sziNNOD6df2nDMMT+5JTU63e/SZw21ftA2QrLc1nf3c=";
        aarch64-darwin = "sha256-POKdqPoEXMrhph6OZH+QHtBGSi40LoRaF5glS2211gA=";
      };
    in
    fetchurl {
      url = "https://artifacts.elastic.co/downloads/${pname}/${pname}-${version}-${platform}-${arch}.tar.gz";
      inherit sha256;
    };

  patches = [ ./kibana-bin.patch ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ patchelf ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
  dontFixup = true;

  installPhase = ''
    mkdir -p $out
    cp -R bin config node node_modules src x-pack *.json $out

    chmod +x $out/bin/*
  '';

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib stdenv.cc.libc ]} \
      $out/node/glibc-217/bin/node
  '';

  meta = {
    description = "Kibana is your window into the Elastic Stack. Specifically, it's a browser-based analytics and search dashboard for Elasticsearch.";
    platforms = platforms.unix;
    mainProgram = pname;
    maintainers = with maintainers; [ zerosuxx ];
  };
}
