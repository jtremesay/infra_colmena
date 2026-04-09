{ ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  services.borgmatic.settings.source_directories = [
    "/var/lib/docker/volumes"
  ];
}
