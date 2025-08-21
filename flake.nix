{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "parts";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.parts.lib.mkFlake
    { inherit inputs; }
    {
      imports = [
        inputs.ez-configs.flakeModule
        inputs.parts.flakeModules.easyOverlay
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      ezConfigs = {
        root = ./.;
        globalArgs = { inherit inputs; };
      };

      perSystem = { pkgs, config, system, ... }:
        let
          fetchPackwizModpack = inputs.nix-minecraft.legacyPackages.${system}.fetchPackwizModpack;
        in
        {
          devShells.default = pkgs.mkShell {
            name = "vanilla-plus-shell";
            packages = [ pkgs.packwiz ];
          };

          overlayAttrs = {
            inherit (config.packages)
              vanilla-plus-server
              vanilla-plus-manifest
              ;
          };

          packages = rec {
            default = vanilla-plus-server;
            vanilla-plus-server = (fetchPackwizModpack {
              src = ./pack;
              packHash = "sha256-TBjQLF7uVnwKrfZO9rtaUp6Z4+O5dThAcyaEqMZ/SVI=";
            });
            vanilla-plus-manifest = pkgs.runCommand
              "vanilla-plus-manifest"
              {
                buildInputs = [ pkgs.packwiz ];
                __noChroot = true;
                # outputHashMode = "recursive";
                # outputHashAlgo = "sha256";
                # outputHash = "";
              } ''
              set -euo pipefail
              HOME=$(mktemp -d) # packwiz tries to write to a user cache directory
              mkdir -p $out

              cp -r ${./pack}/. .
              chmod +w -R . # packwiz tries to open all pack files in rw mode
              packwiz modrinth export

              mv vanilla-plus*.mrpack "$out/manifest.mrpack"
            '';
          };
        };
    };
}
