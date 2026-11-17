{ lib
, fetchurl
, buildNpmPackage
, nodejs_22
}:

buildNpmPackage {
  pname = "neon-cli";
  version = "9.6.0-1";

  src = fetchurl {
    url = "https://registry.npmjs.org/neon/-/neon-9.6.0.tgz";
    hash = "sha512-kyg+0j02wleOep3ifBY6BjCyHN3ZvzwSljbBQRcNaHbdKTV4VT84RU9PecjFlxPo0phiLMdVqyAYJYnEcoCtQg==";
  };

  sourceRoot = "package";
  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
    patch -p1 < ${./oauth-callback-port.patch}
  '';

  nodejs = nodejs_22;
  npmDepsHash = "sha256-pXYiCClun/bt+uid3vgMg2cLsJatRRG/80+vOHv/ACk=";
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
