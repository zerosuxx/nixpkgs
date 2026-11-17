{ lib
, fetchurl
, buildNpmPackage
, nodejs_22
}:

buildNpmPackage rec {
  pname = "cloudflare-cli";
  version = "1.0.0-rc.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/cf/-/cf-1.0.0-rc.0.tgz";
    hash = "sha512-cNrt9utDeaxE61jaTA477Utxwnkr1shMH6vCa6s2+sbsoaU3UbhHiVM/8qZEmNkN5F5YASejcZCRWS3XFCYBJQ==";
  };

  sourceRoot = "package";
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  nodejs = nodejs_22;
  npmDepsHash = "sha256-WeGc5y/Cq3PStTVdr1ljamcz7ewLt810LGFg+t3/jB0=";
  npmInstallFlags = [ "--omit=dev" "--legacy-peer-deps" ];
  npmPruneFlags = [ "--omit=dev" "--legacy-peer-deps" ];
  dontNpmBuild = true;

  meta = {
    description = "Cloudflare command-line interface for the Cloudflare API and Workers projects";
    homepage = "https://developers.cloudflare.com/cf/";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = "cf";
    platforms = nodejs_22.meta.platforms;
  };
}
