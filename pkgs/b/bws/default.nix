{ lib
, stdenv
, fetchurl
, unzip
, autoPatchelfHook
}:

let
  version = "2.1.0";

  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      sha256 = "sha256-uoIzw6Su5dQ+PHO70E2Z6bxauhO7v9BtibBzq+cyuGA=";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "sha256-b2JrOXE2iQKvG5hHwCeRobRmaWnXVh4gR2gc3teZdTc=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      sha256 = "sha256-GCU3VyhuEZ1FATOofrRjv4wc5BjOJMg09PJQ1gy6b54=";
    };
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "sha256-nLHBxuYWTYOy4zmIO6ArTLs3GIzppISxzoJJRDFj4GY=";
    };
  };

  source = sources.${stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "bws";
  inherit version;

  src = fetchurl {
    url = "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${version}/bws-${source.target}-${version}.zip";
    inherit (source) sha256;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ unzip ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;
  # The darwin binaries are code-signed; any fixup would invalidate the signatures.
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall

    install -Dm755 bws $out/bin/bws

    runHook postInstall
  '';

  meta = {
    description = "Bitwarden Secrets Manager CLI";
    homepage = "https://bitwarden.com/help/secrets-manager-cli/";
    changelog = "https://github.com/bitwarden/sdk-sm/releases/tag/bws-v${version}";
    mainProgram = "bws";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
