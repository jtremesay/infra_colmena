{ config, ... }:
{
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      log = {
        level = "INFO";
      };

      entryPoints = {
        http = {
          address = ":80";
          http = {
            redirections = {
              entryPoint = {
                to = "https";
                scheme = "https";
                permanent = true;
              };
            };
          };
        };

        https = {
          address = ":443";
          asDefault = true;
        };
      };

      certificatesResolvers = {
        le = {
          acme = {
            email = "jonathan.tremesaygues@slaanesh.org";
            storage = "${config.services.traefik.dataDir}/acme.json";
            httpChallenge = {
              entryPoint = "http";
            };
          };
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
