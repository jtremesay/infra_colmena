{ pkgs, ... }:
{
  imports = [
    ./desktop_wayland.nix
  ];

  programs.sway = {
    enable = true;
  };
}
