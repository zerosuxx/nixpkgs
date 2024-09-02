{ lib
, stdenv
, fetchurl
, nodejs_20
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

  installPhase = ''
    mkdir -p $out
    cp -R bin config node_modules src x-pack *.json $out

    chmod +x $out/bin/*

    substituteInPlace $out/bin/kibana \
      --replace 'NODE="''${DIR}/node/glibc-217/bin/node"' 'NODE="${nodejs_20}/bin/node"'
  '';

  meta = {
    description = "Kibana is your window into the Elastic Stack. Specifically, it's a browser-based analytics and search dashboard for Elasticsearch.";
    platforms = platforms.unix;
    mainProgram = pname;
    maintainers = with maintainers; [ zerosuxx ];
  };
}