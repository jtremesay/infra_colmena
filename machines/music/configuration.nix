# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./network.nix
    ../../modules/base.nix
    ../../modules/boot.nix
    ../../modules/dns/resolved.nix
    ../../modules/laptop/lid.nix
    ../../modules/network/tailscale.nix
    ../../users
  ];

  networking.hostName = "music";

  services.caddy = {
    enable = true;
    email = "jonathan.tremesaygues@slaanesh.org";
    virtualHosts = {
      "slaanesh.org" = {
        listenAddresses = [
          "tcp6/[::]"
        ];
        extraConfig = ''
          respond "Hello, world"
        '';
      };
    };
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [
      "lo"
    ];
    allowedTCPPorts = [
      80
      443
    ];
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
