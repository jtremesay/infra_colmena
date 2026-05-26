{ ... }:
{
  containers.haproxy = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "192.168.100.1";
    hostAddress6 = "fc00::1";
    localAddress = "192.168.100.2";
    localAddress6 = "fc00::2";

    config =
      { lib, ... }:
      {
        imports = [ ../../modules/dns/resolved.nix ];

        services = {
          haproxy = {
            enable = true;
            config = ''
              defaults
                mode http
                timeout connect 5000ms
                timeout client 50000ms
                timeout server 50000ms

              frontend http_in
                bind :::80 v4v6
                default_backend servers

              frontend https_in
                bind :::443 v4v6 ssl crt /etc/ssl/certs/haproxy.pem
                default_backend servers

              backend servers
                server s1 192.168.100.3:80
            '';
          };
        };

        networking = {
          useHostResolvConf = lib.mkForce false;
          firewall.allowedTCPPorts = [
            80
            443
          ];
        };

        system.stateVersion = "26.05";
      };

    forwardPorts = [
      {
        protocol = "tcp";
        hostPort = 80;
        containerPort = 80;
      }
      {
        protocol = "tcp";
        hostPort = 443;
        containerPort = 443;
      }
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };
}
