{ lib
, fetchurl
, buildNpmPackage
, nodejs_22
}:

buildNpmPackage {
  pname = "neon-cli";
  version = "9.6.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/neon/-/neon-9.6.0.tgz";
    hash = "sha512-kyg+0j02wleOep3ifBY6BjCyHN3ZvzwSljbBQRcNaHbdKTV4VT84RU9PecjFlxPo0phiLMdVqyAYJYnEcoCtQg==";
  };

  sourceRoot = "package";
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  nodejs = nodejs_22;
  npmDepsHash = "sha256-UMNC/y5XETqLk9C/ty7oFtLK0/ZUzV8mcGtzD9Ec0y8=";
  npmInstallFlags = [ "--omit=dev" ];
  npmPruneFlags = [ "--omit=dev" ];
  dontNpmBuild = true;

  meta = {
    description = "Neon command-line interface for managing Neon projects and databases";
    homepage = "https://neon.com/docs/reference/neon-cli";
    license = lib.licenses.asl20;
    mainProgram = "neon";
    platforms = nodejs_22.meta.platforms;
  };
}
