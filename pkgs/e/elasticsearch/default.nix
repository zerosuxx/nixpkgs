{ lib
, stdenv
, fetchurl
, makeWrapper
, jdk
, util-linux
, gnugrep
, coreutils
, autoPatchelfHook
, zlib
}:

with lib;
let
  info = splitString "-" stdenv.hostPlatform.system;
  arch = elemAt info 0;
  platform = elemAt info 1;
in
stdenv.mkDerivation rec {
  pname = "elasticsearch";
  version = "8.15.0";

  src =
    let
      system = stdenv.hostPlatform.system;
      selectSystem = attrs: attrs.${system} or (throw "Unsupported system: ${system}");

      sha256 = selectSystem {
        x86_64-linux   = "sha256-1Bef4sN7LH3cE9jh+OYeOg+mE4YTEO5fVNsIeEtBUWY=";
        x86_64-darwin  = "sha256-R6jRRcu0SMxjLiqYATjpSpZr5KWVbhly0mLurqLs4Qo=";
        aarch64-linux  = "sha256-Lu0vkVB3r59EPcx7xorhCbxyxX946H9Xq7XIjZpx8fY=";
        aarch64-darwin = "sha256-ka90+lkLuoT3Xud341G4h5WRJLdneTuTdN6jqntRxsQ=";
      };
    in
    fetchurl {
      url = "https://artifacts.elastic.co/downloads/${pname}/${pname}-${version}-${platform}-${arch}.tar.gz";
      inherit sha256;
    };

  patches = [ ./elasticsearch-bin.patch ];

  postPatch = ''
    substituteInPlace bin/elasticsearch-env --replace \
      "ES_CLASSPATH=\"\$ES_HOME/lib/*\"" \
      "ES_CLASSPATH=\"$out/lib/*\""

    substituteInPlace bin/elasticsearch-cli --replace \
      "ES_CLASSPATH=\"\$ES_CLASSPATH:\$ES_HOME/\$additional_classpath_directory/*\"" \
      "ES_CLASSPATH=\"\$ES_CLASSPATH:$out/\$additional_classpath_directory/*\""
  '';

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optional (!stdenv.hostPlatform.isDarwin) autoPatchelfHook;

  buildInputs = [ jdk util-linux zlib ];

  runtimeDependencies = [ zlib ];

  installPhase = ''
    mkdir -p $out
    cp -R bin config lib modules plugins $out

    chmod +x $out/bin/*

    substituteInPlace $out/bin/elasticsearch \
      --replace 'bin/elasticsearch-keystore' "$out/bin/elasticsearch-keystore"

    wrapProgram $out/bin/elasticsearch \
      --prefix PATH : "${makeBinPath [ util-linux coreutils gnugrep ]}" \
      --set ES_JAVA_HOME "${jdk}"
      
    wrapProgram $out/bin/elasticsearch-keystore \
      --prefix PATH : "${makeBinPath [ util-linux coreutils gnugrep ]}" \
      --set ES_JAVA_HOME "${jdk}"

    wrapProgram $out/bin/elasticsearch-plugin --set JAVA_HOME "${jdk}"
  '';

  meta = {
    description = "Open Source, Distributed, RESTful Search Engine";
    platforms = platforms.unix;
    mainProgram = pname;
    maintainers = with maintainers; [ zerosuxx ];
  };
}
