{
  description = "A collection of packages for the Nix package manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        packages = with pkgs; {
          adminer = callPackage ./pkgs/a/adminer { };
          elasticsearch = callPackage ./pkgs/e/elasticsearch {
            util-linux = util-linuxMinimal;
            jdk = jdk17;
          };
          kibana = callPackage ./pkgs/k/kibana {
            nodejs_20 = nodejs_20;
          };
          terraform = callPackage ./pkgs/t/terraform { };
        };
      };
    };
}

