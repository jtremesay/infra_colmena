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
      "nextcloud/jtremesay/password" = { };
    };

    containers.nextcloud = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;

      bindMounts = {
        nextcloud_jtremesay_password = {
          hostPath = config.sops.secrets."nextcloud/jtremesay/password".path;
          mountPoint = "/run/secrets/nextcloud_jtremesay_password";
          isReadOnly = true;
        };
      };

      config =
        { pkgs, lib, ... }:
        {
          imports = [ ../dns/dns.nix ];

          programs.neovim = {
            defaultEditor = true;
            enable = true;
          };
          services = {
            nextcloud = {
              enable = true;
              package = pkgs.nextcloud33;
              autoUpdateApps.enable = true;
              config = {
                adminuser = "jtremesay";
                adminpassFile = "/run/secrets/nextcloud_jtremesay_password";

                dbtype = "pgsql";
              };
              database.createLocally = true;
              extraApps = {
                inherit (pkgs.nextcloud31Packages.apps)
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

    services.traefik.dynamicConfigOptions = {
      http = {
        routers."nextcloud" = {
          rule = "Host(`${cfg.host}`)";
          service = "nextcloud";
          entryPoints = [ "https" ];
          tls.certResolver = "le";
        };

        services."nextcloud" = {
          loadBalancer = {
            servers = [
              { url = "http://${config.containers.nextcloud.localAddress}:80"; }
            ];
          };
        };
      };
    };

    services.borgmatic.settings.source_directories = [
      "/var/lib/nixos-containers/nextcloud/var/lib/nextcloud"
      "/var/lib/nixos-containers/nextcloud/var/lib/postgresql"
    ];
  };
}
