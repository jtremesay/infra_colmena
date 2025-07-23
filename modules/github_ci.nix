{ ... }:
{
  users.users.github-ci = {
    isNormalUser = true;
    extraGroups = [
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "command=\"docker system dial-stdio\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEi5LmLfVfaURHUrMc/Tny83YfDGautoI0bVQDd3q5IO github-ci@hiraeth"
    ];
  };
}
