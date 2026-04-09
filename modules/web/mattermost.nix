{ config, lib, ... }:
let
  cfg = config.slaanesh.mattermost;
in
{
  options.slaanesh.mattermost = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address for the mattermost container";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the mattermost service";
      default = "mattermost.jtremesay.org";
    };
  };

  config = {
    containers.mattermost = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;

      config =
        { pkgs, lib, ... }:
        {
          imports = [ ../dns/dns.nix ];

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
              siteUrl = "https://${cfg.host}";
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
            firewall.allowedTCPPorts = [
              8065
            ];
          };

          system.stateVersion = "25.05";
        };
    };

    slaanesh.caddy.reverseProxies."${cfg.host}" = "${config.containers.mattermost.localAddress}:8065";

    services.borgmatic.settings.source_directories = [
      "/var/lib/nixos-containers/mattermost/etc/mattermost"
      "/var/lib/nixos-containers/mattermost/var/lib/mattermost"
      "/var/lib/nixos-containers/mattermost/var/lib/postgresql"
    ];
  };
}
