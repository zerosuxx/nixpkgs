{ stdenv
, fetchFromGitHub
, cmake
}:

let
  appPath = "/data/data/com.termux.nix/files/apps/com.termux.nix";
  socketPath = "${appPath}/termux-am/am.sock";
in
stdenv.mkDerivation rec {
  pname = "termux-am";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "termux";
    repo = "termux-am-socket";
    rev = version;
    hash = "sha256-6pCv2HMBRp8Hi56b43mQqnaFaI7y5DfhS9gScANwg2I=";
  };

  nativeBuildInputs = [ cmake ];

  patchPhase = ''
    echo '#define SOCKET_PATH "${socketPath}"' > termux-am.h

    substituteInPlace termux-am.sh.in \
      --replace '@TERMUX_PREFIX@/bin/bash' '/bin/bash' \
      --replace \
        'termux-am-socket "$am_command_string"' \
        "$out/bin/termux-am-socket \"\$am_command_string\""
  '';

  postInstall = ''
    ln -s $out/bin/termux-am $out/bin/am
  '';
}
