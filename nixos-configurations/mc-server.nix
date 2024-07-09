{ lib, pkgs, modulesPath, inputs, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_pci"
      "virtio_scsi"
      "usbhid"
      "sr_mod"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/79136d92-c8e9-4bb3-83f3-6c4cf33ace32";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7793-2667";
      fsType = "vfat";
    };
  };

  swapDevices = [{
    device = "/dev/disk/by-uuid/218337e4-3f20-46c2-8422-e81762af1d80";
  }];

  networking = {
    useDHCP = true;
    firewall.allowedUDPPorts = [ 24454 ]; # Simple Voice Chat
  };

  time.timeZone = "Europe/Frankfurt";
  i18n.defaultLocale = "en_IE.UTF-8";
  system.stateVersion = "23.11";

  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = "aarch64-linux";
    overlays = [
      inputs.nix-minecraft.overlay
      inputs.self.overlays.default
    ];
  };

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  environment.systemPackages = lib.attrValues {
    inherit (pkgs)
      git
      neovim
      tmux
      wget
      ;
  };

  services = {
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;
      servers.vanilla-plus = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_20_4;
        jvmOpts = builtins.concatStringsSep " " [
          "-Xms6G"
          "-Xmx6G"
          "-XX:+UseG1GC"
          "-XX:+UnlockExperimentalVMOptions"
          "-XX:MaxGCPauseMillis=35"
          "-XX:+DisableExplicitGC"
          "-XX:TargetSurvivorRatio=90"
          "-XX:G1NewSizePercent=50"
          "-XX:G1MaxNewSizePercent=80"
          "-XX:G1MixedGCLiveThresholdPercent=50"
          "-XX:+AlwaysPreTouch"
        ];
        symlinks = {
          "mods" = "${pkgs.vanilla-plus-server}/mods";
        };
        serverProperties = {
          difficulty = "hard";
          white-list = true;
          motd = "Vanilla+ server";
          view-distance = 16;
          simulation-distance = 12;
        };
        whitelist = {
          Ellie_eh = "fdfb210e-c03b-4e6a-bb9d-cb647786c4a5";
          SaxyPandaBear = "773d108e-bbb4-4bef-b3dd-137413f62b97";
          ponty10 = "d33471d8-1c4f-481b-87d6-b28ec77828c7";
          UnlockedWifi42 = "a1504016-bb4c-4eda-9758-bed6c493891a";
          Razentic12 = "35b16250-5264-4e9f-9e55-5dea17277b4f";
          danipenguin = "d1fd607d-3bc9-49cd-83fd-469414ae3289";
        };
      };
    };
  };
}
