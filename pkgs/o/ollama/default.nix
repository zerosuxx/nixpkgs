{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, addDriverRunpath
, vulkan-loader
, zstd
}:

stdenv.mkDerivation rec {
  pname = "ollama";
  version = "0.35.0";

  src =
    let
      system = stdenv.hostPlatform.system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      # The darwin tarball is a universal binary, shared by both darwin systems.
      asset = selectSystem {
        x86_64-linux = "ollama-linux-amd64.tar.zst";
        x86_64-darwin = "ollama-darwin.tgz";
        aarch64-linux = "ollama-linux-arm64.tar.zst";
        aarch64-darwin = "ollama-darwin.tgz";
      };

      sha256 = selectSystem {
        x86_64-linux = "sha256-HBFKayIMXvyi7yseXwHR5TXib2zW0WeMhIkyXSg15SU=";
        x86_64-darwin = "sha256-JgjbsKDwE2oZjbnUi0907OVfRSMUo5RS/KNbfPIMJYk=";
        aarch64-linux = "sha256-y2J9Mysf5QVb1UhcoQ1ZXahCnkR2SCCeN1OQ7DvQk3Q=";
        aarch64-darwin = "sha256-JgjbsKDwE2oZjbnUi0907OVfRSMUo5RS/KNbfPIMJYk=";
      };
    in
    fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/${asset}";
      inherit sha256;
    };

  sourceRoot = ".";

  nativeBuildInputs = [ zstd ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    vulkan-loader
  ];

  # libcuda.so.1 comes from the host's NVIDIA driver, not from the tarball.
  autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];
  appendRunpaths = lib.optionals stdenv.hostPlatform.isLinux [ "${addDriverRunpath.driverLink}/lib" ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  # The darwin binaries are code-signed; any fixup would invalidate the signatures.
  dontFixup = stdenv.hostPlatform.isDarwin;

  # ollama finds its runners and backends relative to the resolved path of its
  # executable: ../lib/ollama on linux, the executable's own directory on darwin.
  installPhase = ''
    runHook preInstall

  '' + (if stdenv.hostPlatform.isDarwin then ''
    mkdir -p $out/bin $out/lib/ollama
    cp -R ./* $out/lib/ollama/
    ln -s $out/lib/ollama/ollama $out/bin/ollama
  '' else ''
    mkdir -p $out
    cp -R bin lib $out/
  '') + ''

    runHook postInstall
  '';

  meta = {
    description = "Get up and running with large language models locally";
    homepage = "https://github.com/ollama/ollama";
    license = lib.licenses.mit;
    mainProgram = "ollama";
    platforms = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
