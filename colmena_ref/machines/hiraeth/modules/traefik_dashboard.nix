{ config, ... }:
{
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
            rule = "Host(`traefik.jtremesay.org`)";
            service = "api@internal";
            tls.certResolver = "le";
          };
        };
      };
    };
  };
}
