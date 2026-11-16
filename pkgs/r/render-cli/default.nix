{ lib
, stdenv
, fetchurl
, unzip
}:

let
  version = "2.36.0";

  sources = {
    x86_64-linux = {
      target = "linux_amd64";
      hash = "sha256-l8g86uXpnIvC00KnHBjArzmEG8ivNCnQHKmmKaymbQ4=";
    };
    aarch64-linux = {
      target = "linux_arm64";
      hash = "sha256-raxByaYZWwvsTKctCzXPWHAM5JNR2Ou6DolVCEh7MJY=";
    };
    x86_64-darwin = {
      target = "darwin_amd64";
      hash = "sha256-FxyHsE7t6nf7ObYZAurnQtSrsqZpkxi//bQiH5ip8bM=";
    };
    aarch64-darwin = {
      target = "darwin_arm64";
      hash = "sha256-Etqk8NJn+46hgfRb0F+PnRevzR63bAVg2586e5riJ9s=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "render-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/render-oss/cli/releases/download/v${version}/cli_${version}_${source.target}.zip";
    inherit (source) hash;
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall

    install -Dm755 cli_v${version} $out/bin/render

    runHook postInstall
  '';

  meta = {
    description = "Official command-line interface for Render cloud hosting platform";
    homepage = "https://github.com/render-oss/cli";
    changelog = "https://github.com/render-oss/cli/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "render";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
