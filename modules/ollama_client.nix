{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ollama
  ];
  environment.sessionVariables.OLLAMA_HOST = "edemaruh.taileb23fb.ts.net";
}
