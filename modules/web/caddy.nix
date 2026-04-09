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
      services.caddy = {
        enable = true;
        globalConfig = ''
          email jonathan.tremesaygues@slaanesh.org
        '';
        virtualHosts = allHosts;
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
