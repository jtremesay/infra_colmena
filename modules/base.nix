{ pkgs, ... }:
{
  imports = [
    ../users
  ];

  # Boot options
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure console keymap
  console = {
    # Cannnot use "fr-bepo" :(
    # https://github.com/NixOS/nixpkgs/issues/182631
    keyMap = "fr-bepo-latin9";
    earlySetup = true;
  };

  # Configure internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };
  };

  # Timezone
  time.timeZone = "Europe/Paris";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Programs
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.htop.enable = true;
  programs.neovim = {
    defaultEditor = true;
    enable = true;
  };
  programs.tmux.enable = true;

  # More programs
  environment.systemPackages = with pkgs; [
    dig
    killall
    tree
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  networking.firewall.allowedTCPPorts = [
    22 # SSH
  ];

  # Locate
  services.locate = {
    enable = true;
    interval = "hourly";
  };

  # Nix configuration
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Sops
  sops = {
    defaultSopsFile = ../secrets/default.yaml;
  };
}
