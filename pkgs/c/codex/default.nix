{ lib
, stdenv
, fetchurl
}:

let
  version = "0.162.1";

  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "sha256-hvJo2BuJjz4UTF7P8q0v2ixYAuBC1hlbclOP4PoSUFc=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "sha256-1o452PYmOfM/fQBlZVTLnD73gJ5mSjgn5iqzrOPCGyE=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "sha256-vzyicZ8RQ7FED72FwUk3nmlseCxQrXmR+L/OxgsmAME=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "sha256-spOg/N2HGQCkTApPQKGqQBsx4ChU95Dr24vV0Rd/0f4=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${source.target}.tar.gz";
    inherit (source) sha256;
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  # The Linux binaries are statically linked (musl) and the darwin ones are
  # code-signed; any fixup would at best be a no-op and at worst break them.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 codex-${source.target} $out/bin/codex

    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${version}";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
