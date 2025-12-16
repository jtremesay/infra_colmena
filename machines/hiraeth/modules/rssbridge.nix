{ config, ... }:
{
  containers.rssbridge = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.11";

    config =
      { pkgs, lib, ... }:
      {
        services.rss-bridge = {
          enable = true;
          config = {
            system.enabled_bridges = [ "*" ];
            error = {
              output = "http";
              report_limit = 5;
            };
            FileCache = {
              enable_purge = true;
            };
          };
        };

        networking = {
          firewall.allowedTCPPorts = [
            80
          ];
        };

        system.stateVersion = "25.05";
      };
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers."rssbridge" = {
        rule = "Host(`rssbridge.jtremesay.org`)";
        service = "rssbridge";
        entryPoints = [ "https" ];
        tls.certResolver = "le";
      };

      services."rssbridge" = {
        loadBalancer = {
          servers = [
            { url = "http://${config.containers.rssbridge.localAddress}:80"; }
          ];
        };
      };
    };
  };
}
