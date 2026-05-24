{ config, lib, ... }:
let
  cfg = config.slaanesh.nextcloud;
in
{
  options.slaanesh.nextcloud = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address for the nextcloud container";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the nextcloud service";
      default = "cloud.jtremesay.org";
    };
  };

  config = {
    sops.secrets = {
      "nextcloud" = { };
    };

    containers.nextcloud = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;

      bindMounts = {
        nextcloud = {
          hostPath = config.sops.secrets."nextcloud".path;
          mountPoint = "/run/secrets/nextcloud";
          isReadOnly = true;
        };
      };

      config =
        { pkgs, lib, ... }:
        {
          imports = [ ../dns/resolved.nix ];

          services = {
            nextcloud = {
              enable = true;
              package = pkgs.nextcloud33;
              autoUpdateApps.enable = true;
              config = {
                adminuser = "jtremesay";
                adminpassFile = "/run/secrets/nextcloud";

                dbtype = "pgsql";
              };
              database.createLocally = true;
              extraApps = {
                inherit (pkgs.nextcloud33Packages.apps)
                  calendar
                  contacts
                  mail
                  tasks
                  ;
              };
              hostName = cfg.host;
              https = true;
              maxUploadSize = "16G";
              phpOptions = {
                "opcache.interned_strings_buffer" = "23";
              };
              settings = {
                maintenance_window_start = "1";
                trusted_proxies = [
                  "192.168.100.1"
                ];
              };
            };

            postgresql = {
              enable = true;
              package = pkgs.postgresql_18;
            };
          };

          networking = {
            useHostResolvConf = lib.mkForce false;
            firewall.allowedTCPPorts = [
              80
            ];
          };

          system.stateVersion = "25.05";
        };
    };

    slaanesh.caddy.reverseProxies."${cfg.host}" = "${config.containers.nextcloud.localAddress}:80";

    services.borgmatic.settings.source_directories = [
      "/var/lib/nixos-containers/nextcloud/var/lib/nextcloud"
      "/var/lib/nixos-containers/nextcloud/var/lib/postgresql"
    ];
  };
}
