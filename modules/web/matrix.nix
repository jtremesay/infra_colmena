{
  config,
  lib,
  ...
}:
let
  cfg = config.slaanesh.matrix;
in
{
  options.slaanesh.matrix = {
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address for the matrix container";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Hostname for the matrix service";
      default = "matrix.jtremesay.org";
    };
  };

  config = {
    sops.secrets."matrix/registration_shared_secret" = {
      # World-readable because the matrix-synapse user/uid only exists inside
      # the container, so we cannot chown the file to it from the host.
      mode = "0444";
    };

    containers.matrix = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "192.168.100.1";
      localAddress = cfg.localAddress;

      bindMounts."/run/secrets/matrix_registration_shared_secret" = {
        hostPath = config.sops.secrets."matrix/registration_shared_secret".path;
        isReadOnly = true;
      };

      config =
        { pkgs, lib, ... }:
        {
          imports = [
            ../dns/resolved.nix
          ];

          services = {
            matrix-synapse = {
              enable = true;
              configureRedisLocally = true;
              settings = {
                dynamic_thumbnails = true;
                listeners = [
                  {
                    bind_addresses = [
                      "0.0.0.0"
                    ];
                    port = 8008;
                    resources = [
                      {
                        compress = true;
                        names = [
                          "client"
                        ];
                      }
                      {
                        compress = false;
                        names = [
                          "federation"
                        ];
                      }
                    ];
                    tls = false;
                    type = "http";
                    x_forwarded = true;
                  }
                ];
                registration_shared_secret_path = "/run/secrets/matrix_registration_shared_secret";
                server_name = cfg.host;
              };
            };

            postgresql = {
              enable = true;
              package = pkgs.postgresql_18;
              # Synapse requires a database with C locale. See:
              # https://matrix-org.github.io/synapse/latest/postgres.html#set-up-database
              initialScript = pkgs.writeText "init-sql-script" ''
                CREATE USER "${config.services.matrix-synapse.settings.database.args.user}";
                CREATE DATABASE "${config.services.matrix-synapse.settings.database.args.database}" 
                  OWNER "${config.services.matrix-synapse.settings.database.args.user}"
                  ENCODING 'UTF8' 
                  LOCALE 'C'
                  TEMPLATE template0;
              '';
            };
          };

          networking = {
            useHostResolvConf = lib.mkForce false;
            firewall.allowedTCPPorts = [
              8008
            ];
          };

          system.stateVersion = "25.11";
        };
    };

    slaanesh.caddy.reverseProxies."${cfg.host}" = "${config.containers.matrix.localAddress}:8008";

    # Federation
    networking.firewall.allowedTCPPorts = [ 8448 ];
    slaanesh.caddy.reverseProxies."${cfg.host}:8448" = "${config.containers.matrix.localAddress}:8008";

    services.borgmatic.settings.source_directories = [
      "/var/lib/nixos-containers/matrix/var/lib/matrix-synapse"
      "/var/lib/nixos-containers/matrix/var/lib/postgresql"
    ];
  };
}
