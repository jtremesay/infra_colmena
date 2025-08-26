{ config, ... }:
{
  sops.secrets = {
    "nextcloud/jtremesay/password" = { };
  };

  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.13";

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
        programs.neovim = {
          defaultEditor = true;
          enable = true;
        };
        services = {
          nextcloud = {
            enable = true;
            package = pkgs.nextcloud31;
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
            hostName = "cloud.jtremesay.org";
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

  services.caddy.virtualHosts."cloud.jtremesay.org" = {
    extraConfig = ''
      reverse_proxy nextcloud:80
    '';
  };

  services.borgmatic.settings.source_directories = [
    "/var/lib/nixos-containers/nextcloud/var/lib/nextcloud"
    "/var/lib/nixos-containers/nextcloud/var/lib/postgresql"
  ];
}
