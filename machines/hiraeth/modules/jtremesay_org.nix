{ ... }: {
  services.caddy.virtualHosts."jtremesay.org" = {
    extraConfig = ''
      reverse_proxy localhost:8081
    '';
  };
}
