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
            vanilla-plus-server = (bootstrapPackwiz {
              src = ./pack;
              packHash = "sha256-Pld3WYJppMlvebsaj6DfC/AKRp7lQIy0cEPpMirVvWc=";
            }).addFiles {
              "mods/Discord-MC-Chat.jar" = pkgs.fetchurl rec {
                pname = "Discord-MC-Chat";
                version = "2.3.2";
                url = "https://github.com/Xujiayao/Discord-MC-Chat/releases/download/${version}/${pname}-${version}.jar";
                hash = "sha256-nNyAFnjvRPgaQMolvMWCTcC/7UIRXAVjuGCvLLukEFA=";
              };
            };
          };
      };
    };
}
