{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  pname = "adminer";
  version = "4.8.4-evo.1";

  src =
    let
      system = stdenv.hostPlatform.system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      sha256 = selectSystem {
        x86_64-linux = "sha256-HVSeN8vTh7vczI84tUvsmIJqW0L8ok4WCEoNWhYWZ8c=";
        x86_64-darwin = "sha256-no8r3HGShFqfbpaJ3RM6YUFZFQPfWvETWYacG7qGl68=";
        aarch64-linux = "sha256-X9iGQa8NO0bQnvaIyh/fZkOvRZS3toou1Mvw/BG8gdE=";
        aarch64-darwin = "sha256-7nXdhMA2kVwUUrg4a5vMMNG88dyfUAFdu7vARlfXXLA=";
      };
    in
    fetchurl {
      url = "https://github.com/zerosuxx/db-adminer/releases/download/${version}/${pname}-${system}";
      inherit sha256;
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