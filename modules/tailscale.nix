{ config, ... }:
{
  sops.secrets."tailscale/auth_key" = { };

  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
  };
}
