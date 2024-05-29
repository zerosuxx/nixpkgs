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

      sha256 = selectSystem {
        x86_64-linux = "sha256-CFaO/5N1WzCQnNLJspReAf+0LiVuse9uEJIvWT++n5c=";
        x86_64-darwin = "sha256-qXkg09nutVrVt4gZ+w+nVYBKq6c9pP+I8OuYbw4ypMs=";
        aarch64-linux = "sha256-hRfro3Xwi+Kr/hu/pFZytTEEztMdSeF2VxbAduXbjQk=";
        aarch64-darwin = "sha256-5AJJKdiYNgpfs4Dadt1Bruv2lsQ+qcM314S26ZaZvWc=";
      };
    in
    fetchurl {
      inherit sha256;

      url = "https://github.com/zerosuxx/db-adminer/releases/download/${version}/adminer-${system}";
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