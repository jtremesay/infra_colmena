{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  services.displayManager.sddm.wayland.enable = true;

  environment.systemPackages = with pkgs; [
    kanshi
  ];
}
