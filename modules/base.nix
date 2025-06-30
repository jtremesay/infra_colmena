{ pkgs, ... }:
{
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jtremesay = {
    isNormalUser = true;
    description = " jtremesay";
    extraGroups = [
      "wheel"
    ];
    packages = with pkgs; [
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2QfuCeW4Pv+fZnlukbg844Z2P67m4ImBvdyNL7bPXdxH1FoAlWEbZpTvvZPXWNzHnrAQ63GEN07a0bzlbzG0ut/xHKBx/ltZcjcNQkQGB5ta2mewfKCQM/nAA2VdhwbZCa5VGJyCq3oj9HKaJ5RTHsSOSIvh7FQRbM/uAKUZHtfLzd7jBWwuyB/VSB1qSEO4yCHtYjvO4eEjur86fZNe+pHsejtuFN5HMh5QVMeud0VmbeB93L3M2die76u0Nd/Ea9q7/FkR4xR8a9OXAmp7PmCoB7/UlKufh6KvGeHE8xKl8Pibf/cpR56ViRvav660+TREQ9uxoi81S9r4qCOUUEEsuAIaVmGTsKeZ1zSWG3PGwTtIgMOxpCXF1FhSHcIvMh4JNkykzdG6Ul76kDEw6Tdc2cE6uA+o7jnVo3TDrSM5ZYE1ZrRlCz1SWRspx04GUxrjWNTd3wkiAx6vliKMM9/2FdzZRgDk4hlbQgoi1jO7TK/KZQKTaWBbIyTDgGNXQZjhM5fwW2LrmLymD6OXJo4qGLZwD51X+TX0JJZrxmUlsTNQE852o0snEl/rqojsp0+dn3x3Zti868kINTNF0PNcO/HgqwLqk67K3JcFlJNV+sVshUtW7gjHaqZ+Fpe4vV5mECQ2qrSw/ulr8EmeMaPsve9hltE2qnYSZaQSq0Q== killruana@edemaruh.slaanesh.org"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2QfuCeW4Pv+fZnlukbg844Z2P67m4ImBvdyNL7bPXdxH1FoAlWEbZpTvvZPXWNzHnrAQ63GEN07a0bzlbzG0ut/xHKBx/ltZcjcNQkQGB5ta2mewfKCQM/nAA2VdhwbZCa5VGJyCq3oj9HKaJ5RTHsSOSIvh7FQRbM/uAKUZHtfLzd7jBWwuyB/VSB1qSEO4yCHtYjvO4eEjur86fZNe+pHsejtuFN5HMh5QVMeud0VmbeB93L3M2die76u0Nd/Ea9q7/FkR4xR8a9OXAmp7PmCoB7/UlKufh6KvGeHE8xKl8Pibf/cpR56ViRvav660+TREQ9uxoi81S9r4qCOUUEEsuAIaVmGTsKeZ1zSWG3PGwTtIgMOxpCXF1FhSHcIvMh4JNkykzdG6Ul76kDEw6Tdc2cE6uA+o7jnVo3TDrSM5ZYE1ZrRlCz1SWRspx04GUxrjWNTd3wkiAx6vliKMM9/2FdzZRgDk4hlbQgoi1jO7TK/KZQKTaWBbIyTDgGNXQZjhM5fwW2LrmLymD6OXJo4qGLZwD51X+TX0JJZrxmUlsTNQE852o0snEl/rqojsp0+dn3x3Zti868kINTNF0PNcO/HgqwLqk67K3JcFlJNV+sVshUtW7gjHaqZ+Fpe4vV5mECQ2qrSw/ulr8EmeMaPsve9hltE2qnYSZaQSq0Q== killruana@edemaruh.slaanesh.org"
  ];

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
}
