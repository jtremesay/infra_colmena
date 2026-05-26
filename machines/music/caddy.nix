{ ... }:
{
  containers.caddy = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    hostAddress6 = "fc00::1";
    localAddress = "192.168.100.3";
    localAddress6 = "fc00::3";

    config =
      { lib, ... }:
      {
        imports = [ ../../modules/dns/resolved.nix ];

        services = {
          caddy = {
            enable = true;
            virtualHosts = {
              "http://slaanesh.org" = {
                extraConfig = ''
                  respond "Hello, world"
                '';
              };
            };
          };
        };

        networking = {
          useHostResolvConf = lib.mkForce false;
          firewall.allowedTCPPorts = [
            80
          ];
        };

        system.stateVersion = "26.05";
      };
  };
}
