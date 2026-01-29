{ config, lib, ... }:
let
  cfg = config.slaanesh.traefik_dashboard;
in
{
  options.slaanesh.traefik_dashboard = {
    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the traefik dashboard service";
      default = "traefik.jtremesay.org";
    };
  };

  config = {
    services.traefik = {
      staticConfigOptions = {
        api = {
          dashboard = true;
          insecure = true;
        };
      };

      dynamicConfigOptions = {
        http = {
          routers = {
            traefik-dashboard = {
              entryPoints = [ "https" ];
              rule = "Host(`${cfg.host}`)";
              service = "api@internal";
              tls.certResolver = "le";
            };
          };
        };
      };
    };
  };
}
