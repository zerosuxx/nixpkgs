{ lib
, stdenv
, fetchFromGitHub
, go
, bash
}:

let
  # The Go bridge lives in the Nix-on-Droid app repository, next to the app
  # that hosts the Termux:API implementation it talks to.
  socketSrc = fetchFromGitHub {
    name = "nix-on-droid-app-source";
    owner = "zerosuxx";
    repo = "nix-on-droid-app";
    rev = "a5059c548e897697eda4c4a84fa1431f03b124d3";
    hash = "sha256-reFcU6fBLofRfQbfZF62uKlKOMbb3txw/ptp2mIOFxQ=";
  };

  # Upstream's shell scripts are the user facing API; they only ever call
  # `$TERMUX_PREFIX/libexec/termux-api`, which termux-api-socket replaces.
  scriptsSrc = fetchFromGitHub {
    name = "termux-api-package-source";
    owner = "termux";
    repo = "termux-api-package";
    rev = "0e3f9222eea7760c76ea6368dadbdf884ab85fbf";
    hash = "sha256-Q7uTNO8T9k+XMia/Km9XlA0e6rZ9cgNf55fC+GVXN50=";
  };

  # Scripts that do not go through libexec/termux-api, and so have nothing to
  # talk to here:
  #   termux-api-start/stop  start upstream's KeepAliveService via `am`; the
  #                          Nix-on-Droid app hosts the API in-process, so
  #                          there is no service to keep alive.
  #   termux-sms-inbox       a stub that only prints a deprecation notice
  #                          pointing at termux-sms-list.
  excludedScripts = [
    "termux-api-start.in"
    "termux-api-stop.in"
    "termux-sms-inbox.in"
  ];

  # Convenience aliases for the clipboard scripts, so the usual muscle memory
  # from macOS (pbcopy/pbpaste) and X11 (xclip) works.
  clipboardAliases = {
    termux-clipboard-set = [ "pbcopy" "xclip" ];
    termux-clipboard-get = [ "pbpaste" ];
  };
in
stdenv.mkDerivation {
  pname = "termux-api";
  version = "0-unstable-2025-06-26";

  srcs = [ socketSrc scriptsSrc ];

  sourceRoot = ".";

  nativeBuildInputs = [ go ];

  strictDeps = true;

  # The bridge has no dependencies, so buildGoModule's vendoring machinery
  # would only add a pointless fixed-output derivation; a plain `go build`
  # against the module in the source tree is enough.
  buildPhase = ''
    runHook preBuild

    export HOME=$TMPDIR
    export GOCACHE=$TMPDIR/go-cache
    export GOPATH=$TMPDIR/go
    # Nothing to resolve, so the network is not needed at all.
    export GOFLAGS=-mod=mod
    export GOPROXY=off
    export CGO_ENABLED=0
    export GOOS=android
    export GOARCH=arm64

    (cd ${socketSrc.name}/termux-api-socket \
      && go build -trimpath -ldflags=-s -o $TMPDIR/termux-api .)

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # libexec is where the scripts look for it, matching upstream's layout.
    install -Dm755 $TMPDIR/termux-api $out/libexec/termux-api

    mkdir -p $out/bin

    # Also exposed on PATH, so the bridge can be driven directly with the
    # am-style extras its own --help documents.
    ln -s ../libexec/termux-api $out/bin/termux-api
    for script in ${scriptsSrc.name}/scripts/*.in; do
      name=$(basename "$script")
      case " ${lib.concatStringsSep " " excludedScripts} " in
        *" $name "*) continue ;;
      esac

      # Each script uses either sh or bash, never both, so neither
      # substitution can be required.
      target=$out/bin/''${name%.in}
      substitute "$script" "$target" \
        --replace-quiet '@TERMUX_PREFIX@/bin/sh' '${bash}/bin/sh' \
        --replace-quiet '@TERMUX_PREFIX@/bin/bash' '${bash}/bin/bash' \
        --replace-quiet '@TERMUX_PREFIX@' "$out"
      chmod 755 "$target"
    done

    ${lib.concatStrings (lib.mapAttrsToList (script: aliases:
      lib.concatMapStrings (alias: ''
        ln -s ${script} $out/bin/${alias}
      '') aliases) clipboardAliases)}

    runHook postInstall
  '';

  # The scripts are shell, and the bridge is cross-compiled for Android on
  # aarch64, so there is nothing here for the host toolchain to strip.
  dontFixup = true;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    for expected in termux-api termux-battery-status termux-clipboard-get \
      termux-clipboard-set termux-notification termux-toast pbcopy pbpaste xclip; do
      test -e "$out/bin/$expected" \
        || { echo "missing $out/bin/$expected"; exit 1; }
    done

    # meta.mainProgram has to resolve, or `nix run` fails.
    test -x "$out/bin/termux-api" || { echo "bin/termux-api is not executable"; exit 1; }

    for unexpected in termux-api-start termux-api-stop termux-sms-inbox; do
      if [ -e "$out/bin/$unexpected" ]; then
        echo "$unexpected should have been excluded"; exit 1
      fi
    done

    if grep -l '@TERMUX_PREFIX@' $out/bin/*; then
      echo "unsubstituted @TERMUX_PREFIX@ left in the scripts"; exit 1
    fi

    # Every installed script must point at an interpreter that exists.
    for script in $out/bin/*; do
      interpreter=$(sed -n '1s/^#!//p' "$script")
      test -n "$interpreter" || continue
      test -x "$interpreter" \
        || { echo "$script has a broken shebang: $interpreter"; exit 1; }
    done

    runHook postInstallCheck
  '';

  meta = {
    description = "Termux:API command line tools backed by the Nix-on-Droid app's socket listener";
    longDescription = ''
      The upstream termux-api shell scripts together with termux-api-socket, a
      Go reimplementation of upstream's libexec/termux-api helper that hands
      the command line to the Nix-on-Droid app's SocketListener over an
      abstract unix socket instead of going through `am broadcast`.

      The socket to contact can be redirected at runtime with
      TERMUX_API_PACKAGE_NAME or TERMUX_API_LISTEN_ADDRESS.
    '';
    homepage = "https://github.com/zerosuxx/nix-on-droid-app";
    license = lib.licenses.gpl3Only;
    mainProgram = "termux-api";
    platforms = [ "aarch64-linux" ];
  };
}
