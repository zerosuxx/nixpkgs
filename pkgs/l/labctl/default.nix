{ lib
, stdenv
, fetchurl
}:

with lib;
let
  info     = splitString "-" stdenv.hostPlatform.system;
  arch     = elemAt info 0;
  platform = elemAt info 1;
in
stdenv.mkDerivation rec {
  repo    = "iximiuz/labctl";
  pname   = "labctl";
  version = "0.1.54";

  src =
    let
      system = stdenv.hostPlatform.system;

      os =
        if stdenv.hostPlatform.isDarwin then "darwin"
        else if stdenv.hostPlatform.isLinux then "linux"
        else throw "Unsupported OS for labctl: ${system}";
      arch =
        if stdenv.hostPlatform.isx86_64 then "amd64"
        else if stdenv.hostPlatform.isAarch64 then "arm64"
        else throw "Unsupported CPU arch for labctl: ${system}";

      asset = "${pname}_${os}_${arch}.tar.gz";
  
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      sha256 = selectSystem {
        x86_64-linux   = "sha256-mFABgzvLNg5d3Grl4Gq4v/WJqXI0D0uerFUsA+uSOQA=";
        x86_64-darwin  = "sha256-MQM7JLI5VQadr17ocrXeV6xCehByBmOllvtx3uCeLVM=";
        aarch64-linux  = "sha256-YLOEtgyBKXAqXh55KvCZXbtDHHOfhRQTVOWdFibMpFo=";
        aarch64-darwin = "sha256-xiBBhYL3L2fIEbsTFZysFEP0yCIK0MeAjzjHuC5qb2M=";
      };
    in
    fetchurl {
      url = "https://github.com/${repo}/releases/download/v${version}/${asset}";
      inherit sha256;
    };

  installPhase = ''
    mkdir -p $out/bin
    cp -R labctl $out/bin

    chmod +x $out/bin/*
  '';

  meta = {
    description = "iximiuz Labs control - start remote microVM playgrounds from the command line.";
    platforms = platforms.unix;
    mainProgram = pname;
    maintainers = with maintainers; [ zerosuxx ];
  };
}
