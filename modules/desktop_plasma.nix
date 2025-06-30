{ config, pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  services.desktopManager.plasma6.enable = true;
}
