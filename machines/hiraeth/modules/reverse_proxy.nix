{ ... }:
{
  services.caddy = {
    enable = true;
    acmeCA = "https://acme-v02.api.letsencrypt.org/directory";
    #acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    email = "jonathan.tremesaygues@slaanesh.org";
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
