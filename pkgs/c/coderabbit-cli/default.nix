{
  lib,
  stdenv,
  fetchurl,
  unzip,
  makeWrapper,
}:

let
  pname = "coderabbit";
  version = "0.7.6";

  sources = {
    x86_64-linux = {
      asset = "${pname}-linux-x64.zip";
      hash = "sha256-hToXJ2CasP8fVoY/pt56zz3lk6bcG9f5GjLxHFck/8k=";
    };

    aarch64-linux = {
      asset = "${pname}-linux-arm64.zip";
      hash = "sha256-InBkGmMUvvDaMuWQPdxt5iZTVJYvfPZR/FgaSpHyJEc=";
    };

    x86_64-darwin = {
      asset = "${pname}-darwin-x64.zip";
      hash = "sha256-HGJC3sigmD/3CEK8HQ6MiI0akrGtgK+5acAMlMSCpwQ=";
    };

    aarch64-darwin = {
      asset = "${pname}-darwin-arm64.zip";
      hash = "sha256-+XDmCOODEU4e3yFO6nGpnWYE6h3QnAHnVO5rjUuFLLE=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://cli.coderabbit.ai/releases/${version}/${source.asset}";
    hash = source.hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    makeWrapper
  ];

  # The released binary is a Bun `--compile` single-file executable: Bun appends
  # its JavaScript payload after the ELF image and locates it by absolute byte
  # offset. Any rewrite of the ELF shifts those offsets, after which Bun no
  # longer finds its embedded entrypoint and silently falls back to behaving as
  # a plain Bun runtime -- `coderabbit --help` prints Bun's own help and
  # `--version` reports Bun's version instead of CodeRabbit's.
  #
  # So autoPatchelfHook must not touch it, and fixupPhase's strip and RPATH
  # shrink would corrupt it the same way. Keep the ELF byte-for-byte intact and
  # invoke the dynamic loader explicitly through a wrapper instead.
  dontFixup = true;

  installPhase =
    ''
      runHook preInstall

    ''
    + (
      if stdenv.hostPlatform.isLinux then
        ''
          install -Dm755 coderabbit $out/libexec/coderabbit

          mkdir -p $out/bin
          makeWrapper ${stdenv.cc.bintools.dynamicLinker} $out/bin/coderabbit \
            --add-flags $out/libexec/coderabbit \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}
        ''
      else
        ''
          install -Dm755 coderabbit $out/bin/coderabbit
        ''
    )
    + ''

      runHook postInstall
    '';

  meta = {
    description = "AI code review CLI";
    homepage = "https://www.coderabbit.ai/cli";
    mainProgram = pname;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
