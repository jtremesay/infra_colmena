{ config, ... }:
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
  };

  sops.secrets.tailscale_auth_key = {
    sopsFile = ../secrets/default.yaml;
  };
}
