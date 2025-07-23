{ config, ... }:
{
  containers.mattermost = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    localAddress = "192.168.100.14";

    config =
      { pkgs, lib, ... }:
      {
        environment.systemPackages = with pkgs; [
          mmctl
        ];

        services = {
          mattermost = {
            enable = true;
            package = pkgs.mattermostLatest;
            host = "0.0.0.0";
            mutableConfig = true;
            siteName = "Kamoulox";
            siteUrl = "https://mattermost.jtremesay.org";
            socket = {
              enable = true;
              export = true;
            };
          };

          postgresql = {
            enable = true;
            package = pkgs.postgresql_17;
            ensureDatabases = [ config.services.mattermost.database.name ];
            ensureUsers = [
              {
                name = config.services.mattermost.database.user;
                ensureDBOwnership = true;
              }
            ];
          };
        };

        networking = {
          useHostResolvConf = lib.mkForce false;
          nameservers = [
            "193.110.81.0"
            "185.253.5.0"
          ];
          firewall.allowedTCPPorts = [
            8065
          ];
        };

        system.stateVersion = "25.05";
      };
  };

  services.caddy.virtualHosts."mattermost.jtremesay.org" = {
    extraConfig = ''
      reverse_proxy mattermost:8065
    '';
  };

  services.borgmatic.settings.source_directories = [
    "/var/lib/nixos-containers/mattermost/etc/mattermost"
    "/var/lib/nixos-containers/mattermost/var/lib/mattermost"
    "/var/lib/nixos-containers/mattermost/var/lib/postgresql"
  ];
}
