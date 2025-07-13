{ config, ... }:
{
  sops.secrets = {
    "freshrss/jtremesay/password" = { };
  };

  containers.freshrss = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.10";

    bindMounts = {
      freshrss_jtremesay_password = {
        hostPath = config.sops.secrets."freshrss/jtremesay/password".path;
        mountPoint = "/run/secrets/freshrss_jtremesay_password";
        isReadOnly = true;
      };
    };

    config =
      { pkgs, lib, ... }:
      {
        systemd = {
          timers.freshrss-actualize = {
            wantedBy = [ "timers.target" ];
            unitConfig = {
              Description = "FreshRSS Actualize Timer";
            };
            timerConfig = {
              OnCalendar = "minutely";
              units = [ "freshrss-actualize.service" ];
            };
          };

          services.freshrss-actualize = {
            unitConfig = {
              Description = "FreshRSS Actualize Service";
              Environment = "DATA_PATH=${config.services.freshrss.dataDir}";
              ExecStart = "${pkgs.freshrss}/app/actualize_script.php";
            };
          };
        };

        services.freshrss = {
          enable = true;
          baseUrl = "https://rss.hiraeth.jtremesay.org";
          defaultUser = "jtremesay";
          passwordFile = "/run/secrets/freshrss_jtremesay_password";
          database.type = "pgsql";
        };

        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_17;
          ensureDatabases = [ config.services.freshrss.database.name ];
          ensureUsers = [
            {
              name = config.services.freshrss.database.name;
              ensureDBOwnership = true;
            }
          ];
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

  services.caddy.virtualHosts."rss.hiraeth.jtremesay.org" = {
    extraConfig = ''
      reverse_proxy freshrss:80
    '';
  };

  services.borgmatic.settings.source_directories = [
    "/var/lib/nixos-containers/freshrss/var/lib/freshrss"
    "/var/lib/nixos-containers/freshrss/var/lib/postgresql"
  ];
}
