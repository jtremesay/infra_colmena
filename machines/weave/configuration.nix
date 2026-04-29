{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];
  networking.hostName = "weave";
  system.stateVersion = "25.11";
}
