 {
   lib,
   stdenv,
   fetchurl,
   unzip,
   autoPatchelfHook,
   glibc,
 }:
 
 let
   pname = "coderabbit";
   version = "0.7.6";
 
   sources = {
     x86_64-linux = {
       asset = "${pname}-linux-x64.zip";
       hash = "sha256-hToXJ2CasP8fVoY/pt56zz3lk6bcG9f5GjLxHFck/8k=";
     };
 
     aarch64-linux = {
       asset = "${pname}-linux-arm64.zip";
       hash = "sha256-InBkGmMUvvDaMuWQPdxt5iZTVJYvfPZR/FgaSpHyJEc=";
     };
 
     x86_64-darwin = {
       asset = "${pname}-darwin-x64.zip";
       hash = "sha256-HGJC3sigmD/3CEK8HQ6MiI0akrGtgK+5acAMlMSCpwQ=";
     };
 
     aarch64-darwin = {
       asset = "${pname}-darwin-arm64.zip";
       hash = "sha256-+XDmCOODEU4e3yFO6nGpnWYE6h3QnAHnVO5rjUuFLLE=";
     };
   };
 
   source =
     sources.${stdenv.hostPlatform.system}
       or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
 
 in
 stdenv.mkDerivation {
   inherit pname version;
 
   src = fetchurl {
     url = "https://cli.coderabbit.ai/releases/${version}/${source.asset}";
     hash = source.hash;
   };
 
   sourceRoot = ".";
 
   nativeBuildInputs = [
     unzip
   ]
   ++ lib.optionals stdenv.hostPlatform.isLinux [
     autoPatchelfHook
   ];
 
   buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
     glibc
     stdenv.cc.cc
   ];
 
   installPhase = ''
     runHook preInstall
 
     install -Dm755 coderabbit $out/bin/coderabbit
 
     runHook postInstall
   '';
 
   meta = {
     description = "AI code review CLI";
     homepage = "https://www.coderabbit.ai/cli";
     license = lib.licenses.unfree;
     mainProgram = pname;
     platforms = builtins.attrNames sources;
     sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
   };
 }
