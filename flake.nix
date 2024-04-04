{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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

      perSystem = { pkgs, config, ... }: {
        devShells.default = pkgs.mkShell {
          name = "vanilla-plus-shell";
          packages = [ pkgs.packwiz pkgs.updog ];
        };

        overlayAttrs = {
          inherit (config.packages)
            vanilla-plus-server
            ;
        };

        packages =
          let
            bootstrapPackwiz = pkgs.callPackage ./bootstrapPackwiz.nix { };
          in
          rec {
            default = vanilla-plus-server;
            vanilla-plus-server = bootstrapPackwiz {
              src = ./pack;
              packHash = "sha256-v7aC1k99ebza+eCY02U7BfSBiW7wzR4NQqAIzJxN4kU=";
            };
          };
      };
    };
}
