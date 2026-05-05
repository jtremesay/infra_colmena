{ ... }:
{
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMGm5JRotZU5S8CIeY6UBRc6sVVw22lHHEHRHdwUXBJa jtremesay@nemo"
  ];

  home-manager.users.root = {
    home = {
      stateVersion = "25.05";
    };
  };
}
