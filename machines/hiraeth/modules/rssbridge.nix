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
          useHostResolvConf = lib.mkForce false;
          nameservers = [
            "193.110.81.0"
            "185.253.5.0"
          ];
          firewall.allowedTCPPorts = [
            80
          ];
        };

        system.stateVersion = "25.05";
      };
  };

  services.caddy.virtualHosts."rssbridge.jtremesay.org" = {
    extraConfig = ''
      reverse_proxy rssbridge:80
    '';
  };
}
