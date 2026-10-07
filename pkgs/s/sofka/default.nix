{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  glibc,
}:

let
  pname = "sofka";
  version = "0.24.4";

  sources = {
    x86_64-linux = {
      asset = "${pname}-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-ZOD9iSuja6fuMVAI+0d26GYVhzNT0ABD3a7qzpE2/yA=";
    };

    aarch64-linux = {
      asset = "${pname}-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-nhtWrmfoHzQ4RPwHfr0028WwC7Qb3o0Z8hx4qHbuIwE=";
    };

    x86_64-darwin = {
      asset = "${pname}-v${version}-x86_64-apple-darwin.tar.gz";
      hash = "sha256-dihMDuZkUjK0sGkDzzZUg1+/z0fA28tnF+7OGDs26T4=";
    };

    aarch64-darwin = {
      asset = "${pname}-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-bTZKOSXaeIq/yi/hohn2Qotv0QmazxY+bYb7bn6o5/w=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/nklmilojevic/sofka/releases/download/v${version}/${source.asset}";
    hash = source.hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glibc
    stdenv.cc.cc
  ];

  installPhase = ''
    install -Dm755 sofka $out/bin/sofka
  '';

  meta = {
    description = "Terminal user interface for Kubernetes";
    homepage = "https://github.com/nklmilojevic/sofka";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = builtins.attrNames sources;
  };
}
