{ lib
, stdenv
, fetchurl
, system
}:

stdenv.mkDerivation rec {
  pname = "adminer";
  version = "4.8.4-evo.1";

  src =
    let
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      suffix = selectSystem {
        x86_64-linux = "linux-x86_64";
        x86_64-darwin = "darwin-x86_64";
        aarch64-linux = "linux-aarch64";
        aarch64-darwin = "darwin-arm64";
      };
      sha256 = selectSystem {
        x86_64-linux = "sha256-XMlOV26eFzQD4jrRMB32jFWYx2Vi/v5GG3HJRtafIyw=";
        x86_64-darwin = "sha256-cHOoHlNr3lz8VNK7qzuAl0QT/WUtvT7JxjH3NLTY6NA=";
        aarch64-linux = "sha256-tAEpNsT0hOwKMtI9pA1h9H8wM3eSOjP3vb4tzCP6ng4=";
        aarch64-darwin = "sha256-RU6XeDvNTCKctKDDlSCgWPAGkDQFP+ODb7PYPvMoxD8=";
      };
    in
    fetchurl {
      inherit sha256;

      url = "https://github.com/zerosuxx/db-adminer/releases/download/${version}/adminer-${suffix}";
    };

  dontUnpack = true;
  dontCheck = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/adminer
    chmod +x $out/bin/adminer
  '';

  meta = {
    description = "AdminerEvo is a web-based database management interface, with a focus on security, user experience, performance, functionality and size.";
    mainProgram = "adminer";
  };
}