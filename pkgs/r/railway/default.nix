{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  version = "5.74.1";

  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-poh74winH1dZo2WlRi30i+u1JvJvUe4EUY8rSGx5lRA=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-cgrAl3rWvgzxLps9ovq8BMDzc5HHIdnkTIrIXdaimas=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      hash = "sha256-/3FQztCUEn32x6zU/hAMYU86XERhlCTO+TiLSzmJ81A=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-Upvs2bDKAgvSkXONvR0wffETAFXyKky4yYmn8WkPhsM=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "railway";
  inherit version;

  src = fetchurl {
    url = "https://github.com/railwayapp/cli/releases/download/v${version}/railway-v${version}-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    install -Dm755 railway $out/bin/railway

    runHook postInstall
  '';

  meta = {
    description = "The Railway command line interface";
    homepage = "https://github.com/railwayapp/cli";
    changelog = "https://github.com/railwayapp/cli/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "railway";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
