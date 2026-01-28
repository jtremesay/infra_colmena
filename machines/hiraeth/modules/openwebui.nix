{ config, ... }:
{
  containers.openwebui = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.15";

    config =
      { pkgs, lib, ... }:
      {
        services.open-webui = {
          enable = true;
          host = "0.0.0.0";
          openFirewall = true;
        };

        networking = {
          useHostResolvConf = lib.mkForce false;
          nameservers = [
            "86.54.11.100" # https://www.joindns4.eu
          ];
        };

        system.stateVersion = "25.05";
      };
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers."openwebui" = {
        rule = "Host(`openwebui.jtremesay.org`)";
        service = "openwebui";
        entryPoints = [ "https" ];
        tls.certResolver = "le";
      };

      services."openwebui" = {
        loadBalancer = {
          servers = [
            { url = "http://${config.containers.openwebui.localAddress}:8080"; }
          ];
        };
      };
    };
  };
}
