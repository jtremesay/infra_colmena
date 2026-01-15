{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    aerion
  ];
}
