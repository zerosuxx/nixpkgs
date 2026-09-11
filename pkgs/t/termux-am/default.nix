{ lib
, stdenv
, fetchFromGitHub
, cmake
, bash
, coreutils
, util-linux
}:

let
  appPackage = "com.termux.nix";
  appPath = "/data/data/${appPackage}/files/apps/${appPackage}";
  socketPath = "${appPath}/termux-am/am.sock";

  # termux-open and termux-open-url drive `am` rather than the Termux:API
  # socket, so they belong next to it rather than in termux-api.
  toolsSrc = fetchFromGitHub {
    owner = "termux";
    repo = "termux-tools";
    rev = "9463f66b650383a896fb728579f0dd54bc9ebe5b";
    hash = "sha256-ilf4fkHFKTSmqj3tEMKdyxsboAA3RRiv3G/jhwDJNDg=";
  };
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

    # The scripts call `am`, `getopt` and `realpath` by bare name; wire them to
    # this output and to the store so they do not depend on PATH.
    #
    # The intent component is spelled out rather than run through upstream's
    # @TERMUX_APP_PACKAGE@ substitution, which would give
    # "com.termux.nix.app.TermuxOpenReceiver": the receiver's Java package
    # stayed com.termux.app, and only the applicationId gained the .nix suffix,
    # so the class to name is com.termux.app.TermuxOpenReceiver.
    for name in termux-open termux-open-url; do
      substitute ${toolsSrc}/scripts/$name.in $out/bin/$name \
        --replace-fail '#!/bin/sh' '#!${bash}/bin/sh' \
        --replace-quiet '@TERMUX_APP_PACKAGE@/@TERMUX_APP_PACKAGE@.app.TermuxOpenReceiver' \
                        '${appPackage}/com.termux.app.TermuxOpenReceiver' \
        --replace-quiet 'getopt \' '${util-linux}/bin/getopt \' \
        --replace-quiet 'realpath "$FILE"' '${coreutils}/bin/realpath "$FILE"' \
        --replace-quiet 'am start' "$out/bin/am start" \
        --replace-quiet 'am broadcast' "$out/bin/am broadcast"
      chmod 755 $out/bin/$name
    done

    # Without a scheme the intent resolves to nothing, and the am library then
    # dies inside its own ActivityNotFoundException handler: it formats the
    # message with intent.getComponent().toShortString(), and a `-d <url>`
    # intent has no component, so an NPE buries the real cause. Reject a
    # schemeless argument up front instead.
    substituteInPlace $out/bin/termux-open-url \
      --replace-fail 'case "''${TERMUX__USER_ID:-}"' \
    'case "$1" in
	*://*) ;;
	*)
		echo "termux-open-url: '"'"'$1'"'"' has no scheme, try https://$1" >&2
		exit 1
		;;
esac

case "''${TERMUX__USER_ID:-}"'

    # xdg-open is what most tooling reaches for. URLs go straight to the system
    # resolver; a path goes through termux-open, which shares the file via the
    # app's content provider rather than exposing a file:// URI.
    cat > $out/bin/xdg-open <<XDG_EOF
#!${bash}/bin/sh
set -e -u

if [ \$# != 1 ]; then
	echo "usage: xdg-open <file-or-url>" >&2
	exit 1
fi

case "\$1" in
	*://*) exec $out/bin/termux-open-url "\$1" ;;
	*)     exec $out/bin/termux-open "\$1" ;;
esac
XDG_EOF
    chmod 755 $out/bin/xdg-open
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    for expected in am termux-am termux-am-socket termux-open termux-open-url \
      xdg-open; do
      test -e "$out/bin/$expected" \
        || { echo "missing $out/bin/$expected"; exit 1; }
    done

    # A leftover placeholder or a bare `am` would only fail at runtime.
    if grep -l '@TERMUX_APP_PACKAGE@' $out/bin/termux-open $out/bin/termux-open-url; then
      echo "unsubstituted @TERMUX_APP_PACKAGE@ left in the scripts"; exit 1
    fi

    for script in termux-open termux-open-url; do
      grep -qE "^[[:space:]]*am[[:space:]]" "$out/bin/$script" \
        && { echo "$script still calls am off PATH"; exit 1; }
    done

    grep -q 'com.termux.app.TermuxOpenReceiver' $out/bin/termux-open \
      || { echo "termux-open lost its receiver component"; exit 1; }

    # --help needs getopt to work, so this exercises the wiring end to end.
    $out/bin/termux-open --help | grep -q 'Open a file or URL' \
      || { echo "termux-open --help did not run"; exit 1; }

    # A schemeless URL must be refused before it ever reaches `am`.
    if $out/bin/termux-open-url google.com 2>/dev/null; then
      echo "termux-open-url accepted a schemeless url"; exit 1
    fi
    # Both of these exit non-zero by design, so capture before grepping.
    schemeless=$($out/bin/termux-open-url google.com 2>&1 || true)
    case "$schemeless" in
      *"no scheme"*) ;;
      *) echo "termux-open-url did not explain the missing scheme: $schemeless"; exit 1 ;;
    esac

    usage=$($out/bin/xdg-open 2>&1 || true)
    case "$usage" in
      *"usage: xdg-open"*) ;;
      *) echo "xdg-open did not print its usage: $usage"; exit 1 ;;
    esac

    runHook postInstallCheck
  '';

  meta = {
    description = "Send Android intents from Nix-on-Droid via the app's am socket";
    longDescription = ''
      termux-am-socket, which replaces Android's `am` by talking to the
      Nix-on-Droid app over a unix socket, together with the termux-tools
      scripts that build on it: termux-open and termux-open-url hand a file or
      URL to an external app.

      Sending an intent needs the app's am socket to be live at
      ${socketPath}.
    '';
    homepage = "https://github.com/termux/termux-am-socket";
    license = lib.licenses.gpl3Only;
    mainProgram = "am";
    platforms = [ "aarch64-linux" ];
  };
}
