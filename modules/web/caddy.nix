{
  config,
  lib,
  pkgs,
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
      caddyfile = pkgs.writeText "Caddyfile" ''
        {
          email jonathan.tremesaygues@slaanesh.org
        }

        :80 {
          redir / https://{host} permanent
        }

        ${lib.concatStringsSep "\n\n" (
          lib.mapAttrsToList (host: backend: ''
            ${host} {
              encode zstd gzip
              reverse_proxy ${backend}
            }
          '') cfg.reverseProxies
        )}
      '';
    in
    {
      services.caddy = {
        enable = true;
        configFile = caddyfile;
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
