{ config, lib, ... }:
let
  cfg = config.services.vaultwarden-container;
in
{
  options.services.vaultwarden-container = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address for the vaultwarden container";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the vaultwarden service";
      default = "vault.jtremesay.org";
    };
  };

  config = {
    containers.vaultwarden = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;

      config =
        { pkgs, lib, ... }:
        {
          imports = [ ../../../modules/dns/dns.nix ];

          services.vaultwarden = {
            enable = true;
            backupDir = "/var/backup/vaultwarden";
            config = {
              ROCKET_ADDRESS = "0.0.0.0";
              EXPERIMENTAL_CLIENT_FEATURE_FLAGS = "ssh-key-vault-item,ssh-agent";
            };
          };

          networking = {
            useHostResolvConf = lib.mkForce false;
            firewall.allowedTCPPorts = [
              8000
            ];
          };

          system.stateVersion = "25.05";
        };
    };

    services.traefik.dynamicConfigOptions = {
      http = {
        routers."vaultwarden" = {
          rule = "Host(`${cfg.host}`)";
          service = "vaultwarden";
          entryPoints = [ "https" ];
          tls.certResolver = "le";
        };

        services."vaultwarden" = {
          loadBalancer = {
            servers = [
              { url = "http://${config.containers.vaultwarden.localAddress}:8000"; }
            ];
          };
        };
      };
    };

    services.borgmatic.settings.source_directories = [
      "/var/lib/nixos-containers/vaultwarden/var/lib/vaultwarden"
      "/var/lib/nixos-containers/vaultwarden/var/backup/vaultwarden"
    ];
  };
}
