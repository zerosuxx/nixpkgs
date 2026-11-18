{ lib
, stdenv
, fetchurl
, makeWrapper
}:

let
  version = "3.2.0";

  sources = {
    x86_64-linux = {
      target = "linux_amd64";
      hash = "sha256-+4ixdagXVjUFvgLGCHIGC8uNXIaaGqVlbq6whdSi8eQ=";
    };
    aarch64-linux = {
      target = "linux_arm64";
      hash = "sha256-zZtLbFsExvtoyL9rNaftKSS2ZxzaJjYT/Ypyc7n6Fns=";
    };
    x86_64-darwin = {
      target = "darwin_amd64";
      hash = "sha256-CwKsY9ZACz8jikQsPSqnLSl3s6Xc0/LmeQlaAEczEC4=";
    };
    aarch64-darwin = {
      target = "darwin_arm64";
      hash = "sha256-yeJ82vhI8haHnfCjVPypbH5awNFSfZNLcw7GK6NIuG0=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "supabase-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/supabase/cli/releases/download/v${version}/supabase_${version}_${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ makeWrapper ];
  dontFixup = true;

  installPhase =
    ''
      runHook preInstall

    ''
    + (if stdenv.hostPlatform.isLinux then ''
      install -Dm755 supabase $out/libexec/supabase

      makeWrapper ${stdenv.cc.bintools.dynamicLinker} $out/bin/supabase \
        --add-flags $out/libexec/supabase \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.libc ]}
    '' else ''
      install -Dm755 supabase $out/bin/supabase
    '')
    + ''
      runHook postInstall
    '';

  meta = {
    description = "Supabase command-line interface for local development and deployment";
    homepage = "https://supabase.com/docs/guides/local-development/cli/getting-started";
    changelog = "https://github.com/supabase/cli/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "supabase";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
