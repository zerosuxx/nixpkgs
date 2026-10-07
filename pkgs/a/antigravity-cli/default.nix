{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  pname = "antigravity-cli";
  version = "1.3.1";
  # Release URLs carry a build id next to the version, see
  # https://storage.googleapis.com/antigravity-public/antigravity-cli/<version>/manifest.json
  buildId = "4582356770750464";

  sources = {
    x86_64-linux = {
      asset = "linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-DjE7MJ6ljHFDHOhruCCTajcA4X5E6rznvyJkYX3IIts=";
    };

    aarch64-linux = {
      asset = "linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha256-+W7+yZyL2g0xaGdiLmX3kgugwrdKYtafzU7RPg6EEZ0=";
    };

    x86_64-darwin = {
      asset = "darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha256-U+j6APgAX+biKGd9Q6swTcVOZ0Fv1WLc8AIdMb+0TTA=";
    };

    aarch64-darwin = {
      asset = "darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha256-7144WzKv2kzxYSNou0vxVdP49MVdUUiGSfUIuu/nfIY=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-${buildId}/${source.asset}";
    hash = source.hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 antigravity $out/bin/agy

    runHook postInstall
  '';

  meta = {
    description = "Google's terminal user interface (TUI) agent client";
    homepage = "https://antigravity.google";
    changelog = "https://antigravity.google/changelog";
    license = lib.licenses.unfree;
    mainProgram = "agy";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
