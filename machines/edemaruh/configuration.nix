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
    ../../modules/secureboot.nix
    ../../modules/nvidia.nix
  ];

  networking.hostName = "edemaruh";
  networking.networkmanager.enable = true;

  # Ollama CUDA
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [
      "cogito:3b"
      "cogito:8b"
      "cogito:14b"
      "cogito:32b"
      "gemma3:1b"
      "gemma3:4b"
      "gemma3:12b"
      "gemma3:27b"
      "gemma3n:e2b"
      "gemma3n:e4b"
      "granite3.3:2b"
      "granite3.3:8b"
      "llama4:16x17b"
      "mistral-small3.2:24b"
      "phi4:14b"
      "phi4-reasoning:14b"
      "phi4-mini:3.8b"
      "phi4-mini-reasoning:3.8b"
      "qwen3:0.6b"
      "qwen3:1.7b"
      "qwen3:4b"
      "qwen3:8b"
      "qwen3:14b"
      "qwen3:30b"
      "qwen3:32b"
    ];
    host = "0.0.0.0";
  };

  # Don't suspend when the lid is closed.
  services.logind.lidSwitch = "ignore";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
