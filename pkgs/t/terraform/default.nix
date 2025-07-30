{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  pname = "terraform";
  version = "v1.12.2-1";

  src =
    let
      system = stdenv.hostPlatform.system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      sha256 = selectSystem {
        x86_64-linux = "sha256-n5DqjSP+7jf5xXauxMSJJJie8oIJXt5TWSQSvdgtQfU=";
        x86_64-darwin = "sha256-eD7g50eGVhTAeUlLxa3Uk2vs5P0UoYehVuMYK+r2gFg=";
        aarch64-linux = "sha256-Qe3uwma3CvJjUb7QuQyAIIQkIXgLMuEGpyi738+8glQ=";
        aarch64-darwin = "sha256-/BNiDGrks1ymBsW2pJZkb+G1DYjnuJqbFnXbZbNsKUo=";
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