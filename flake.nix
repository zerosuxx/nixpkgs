{
  description = "A collection of packages for the Nix package manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: rec {
        packages = with pkgs; {
          adminer = callPackage ./pkgs/a/adminer { };
          antigravity-cli = callPackage ./pkgs/a/antigravity-cli { };
          bws = callPackage ./pkgs/b/bws { };
          cloudflare-cli = callPackage ./pkgs/c/cloudflare-cli {
            nodejs_22 = nodejs_22;
          };
          coderabbit-cli = callPackage ./pkgs/c/coderabbit-cli { };
          codex = callPackage ./pkgs/c/codex { };
          elasticsearch = callPackage ./pkgs/e/elasticsearch {
            util-linux = util-linuxMinimal;
            jdk = jdk17;
          };
          kibana = callPackage ./pkgs/k/kibana { };
          kubelogin = callPackage ./pkgs/k/kubelogin { };
          labctl = callPackage ./pkgs/l/labctl { };
          neon-cli = callPackage ./pkgs/n/neon-cli {
            nodejs_22 = nodejs_22;
          };
          ollama = callPackage ./pkgs/o/ollama { };
          railway = callPackage ./pkgs/r/railway { };
          render-cli = callPackage ./pkgs/r/render-cli { };
          sofka = callPackage ./pkgs/s/sofka { };
          terraform = callPackage ./pkgs/t/terraform { };
        } // pkgs.lib.optionalAttrs (system == "aarch64-linux") {
          termux-am = pkgs.callPackage ./pkgs/t/termux-am { };
          termux-api = pkgs.callPackage ./pkgs/t/termux-api { };
        };
      };
    };
}

