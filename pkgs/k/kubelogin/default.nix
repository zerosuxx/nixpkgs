{ lib
, stdenv
, fetchurl
, unzip
}:

let
  version = "0.2.21";

  sources = {
    x86_64-linux = {
      target = "linux_amd64";
      sha256 = "sha256-k0oqlhjgGMufvrFPPkwoQW/a6BXfdwbfkVAOQdI062Y=";
    };
    x86_64-darwin = {
      target = "darwin_amd64";
      sha256 = "sha256-882SgAVvjdlMYAjwCvMABeWBmsDZiy9w387nf/Lrak8=";
    };
    aarch64-linux = {
      target = "linux_arm64";
      sha256 = "sha256-du7ocrTdpqA3jVfgGc+zlLbtWOaqIJ6lXZQQZac9N7Q=";
    };
    aarch64-darwin = {
      target = "darwin_arm64";
      sha256 = "sha256-3KJpYoVaOGX/7DYEmEiwdBwAAy97JQeNbjXvw43hxZg=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kubelogin";
  inherit version;

  src = fetchurl {
    url = "https://github.com/Azure/kubelogin/releases/download/v${version}/kubelogin-${builtins.replaceStrings [ "_" ] [ "-" ] source.target}.zip";
    inherit (source) sha256;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ unzip ];

  dontConfigure = true;
  dontBuild = true;
  # The Linux binaries are statically linked; the darwin binaries are code-signed
  # and any fixup would invalidate the signatures.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/${source.target}/kubelogin $out/bin/kubelogin

    runHook postInstall
  '';

  meta = {
    description = "Kubernetes credential (exec) plugin implementing Azure authentication";
    homepage = "https://github.com/Azure/kubelogin";
    changelog = "https://github.com/Azure/kubelogin/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "kubelogin";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
