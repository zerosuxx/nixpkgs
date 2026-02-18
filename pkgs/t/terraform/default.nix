{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  pname = "terraform";
  version = "v1.14.5-1";

  src =
    let
      system = stdenv.hostPlatform.system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      sha256 = selectSystem {
        x86_64-linux = "sha256-ykRTofpelRrBJgIuTUZGgk5dNynqH6Q3X0LEW5ICWzU=";
        x86_64-darwin = "sha256-RlOO3eiO+Wgtwbgq7y/GSd09gVg1fC8T8hqRL40DVx4=";
        aarch64-linux = "sha256-AeMa9PB2iH7ZJTidZt3v5yE1caQvDeStzhkbF/8etos=";
        aarch64-darwin = "sha256-ow9Kz3mLeOWLcUfjbWUbdXVepTWY4504sn9bn0F0S4A=";
      };
    in
    fetchurl {
      url = "https://github.com/zerosuxx/terraform/releases/download/${version}/${pname}-${system}";
      inherit sha256;
    };

  dontUnpack = true;
  dontCheck = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/terraform
    chmod +x $out/bin/terraform
  '';

  meta = {
    description = "Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently.";
    mainProgram = "terraform";
  };
}
