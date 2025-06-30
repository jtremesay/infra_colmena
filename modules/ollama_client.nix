{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ollama
  ];
  environment.sessionVariables.OLLAMA_HOST = "100.74.48.117";
}
