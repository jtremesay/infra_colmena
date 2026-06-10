{
  config,
  lib,
  ...
}:
{
  options.slaanesh.caddy = {
    reverseProxies = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Reverse proxy mappings: hostname -> backend_url";
    };
  };

  config =
    let
      cfg = config.slaanesh.caddy;
      reverseProxyHosts = lib.mapAttrs (host: backend: {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy ${backend}
        '';
      }) cfg.reverseProxies;
      allHosts = reverseProxyHosts // {
        ":80" = {
          extraConfig = ''
            redir / https://{host} permanent
          '';
        };
      };
    in
    {
      sops.secrets = {
        "actalis_eab" = {
          owner = config.services.caddy.user;
        };
      };

      services.caddy = {
        enable = true;
        environmentFile = config.sops.secrets."actalis_eab".path;
        acmeCA = "https://acme-api.actalis.com/acme/directory";
        globalConfig = ''
          acme_eab {
            key_id {$EAB_KEY_ID}
            mac_key {$EAB_MAC_KEY}
          }
        '';
        email = "jonathan.tremesaygues@slaanesh.org";
        virtualHosts = allHosts;
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
