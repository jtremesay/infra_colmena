{ ... }:
{
  users.users.github-ci = {
    isNormalUser = true;
    extraGroups = [
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "command=\"docker system dial-stdio\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIF+80iTtdE6+AXmkj0FrhrBYGeL/Jixs9pZ0fyQLKYB github-ci@pan"
    ];
  };
}
