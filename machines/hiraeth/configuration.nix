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
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/firewall.nix
    ../../modules/tailscale.nix
    ../../modules/borgmatic.nix
    ../../modules/docker.nix
    ../../modules/github_ci.nix
    ./modules/reverse_proxy.nix
    ./modules/public_html.nix
    ./modules/freshrss.nix
    ./modules/mattermost.nix
    ./modules/mirrors
    ./modules/nextcloud.nix
    ./modules/rssbridge.nix
    ./modules/vaultwarden.nix
  ];

  networking.hostName = "hiraeth";

  networking = {
    nat = {
      enable = true;
      # Use "ve-*" when using nftables instead of iptables
      internalInterfaces = [ "ve-+" ];
      externalInterface = "eno1";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };
    nftables = {
      tables = {
        nat = {
          content = ''
            chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                oifname "eno1" masquerade
            }
          '';
          family = "ip";
        };
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
