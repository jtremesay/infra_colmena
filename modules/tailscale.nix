{ config, ... }:
{
  sops.secrets."tailscale/auth_key" = { };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale/auth_key".path;
  };
}
