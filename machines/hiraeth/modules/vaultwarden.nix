{ config, ... }:
{
  containers.vaultwarden = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.12";

    config =
      { pkgs, lib, ... }:
      {
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
          nameservers = [
            "193.110.81.0"
            "185.253.5.0"

          ];
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
        rule = "Host(`vault.jtremesay.org`)";
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
}
