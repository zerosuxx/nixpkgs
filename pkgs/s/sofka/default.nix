{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  glibc,
  xgcc,
}:

let
  pname = "sofka";
  version = "0.24.4";

  sources = {
    x86_64-linux = {
      asset = "${pname}-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "hpZ42fCrj7a8af8tynw/6fRTQjNOGL7GDWB5nd6W0pA=";
    };

    aarch64-linux = {
      asset = "${pname}-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "Pwvn4SR8MZv6FQ39Hkrts4vORGw1Kln/Q3o06XXNydc=";
    };

    x86_64-darwin = {
      asset = "${pname}-v${version}-x86_64-apple-darwin.tar.gz";
      hash = "lA/X8urvHHYwqdsxeRs2ratqXZKZ6IXDZ6MQBtFwCVM=";
    };

    aarch64-darwin = {
      asset = "${pname}-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "+U8dr7ODROvyPO7MlCJNdg4D68zKHjKNWkg/IpSnZ5c=";
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

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    glibc
    xgcc.libgcc
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
