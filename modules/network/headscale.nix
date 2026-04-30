{ config, lib, ... }:
let
  cfg = config.slaanesh.headscale;
in
{
  options.slaanesh.headscale = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address for the headscale container";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the headscale service";
      default = "headscale.jtremesay.org";
    };
  };

  config = {
    containers.headscale = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;

      config =
        { pkgs, lib, ... }:
        {
          imports = [ ../dns/resolved.nix ];

          services.headscale = {
            enable = true;
            address = "0.0.0.0";

            settings = {
              server_url = "https://${cfg.host}";
              dns = {
                base_domain = "vpn.jtremesay.org";
                override_local_dns = false;
                name_servers = {
                  global = config.networking.nameservers;
                };
              };
            };
          };

          networking = {
            useHostResolvConf = lib.mkForce false;
            firewall.allowedTCPPorts = [
              8080
            ];
          };

          system.stateVersion = "25.05";
        };
    };

    slaanesh.caddy.reverseProxies."${cfg.host}" = "${config.containers.headscale.localAddress}:8080";
  };
}
