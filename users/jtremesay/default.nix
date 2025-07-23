{ pkgs, ... }:
{
  users.users.jtremesay = {
    isNormalUser = true;
    description = " jtremesay";
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2QfuCeW4Pv+fZnlukbg844Z2P67m4ImBvdyNL7bPXdxH1FoAlWEbZpTvvZPXWNzHnrAQ63GEN07a0bzlbzG0ut/xHKBx/ltZcjcNQkQGB5ta2mewfKCQM/nAA2VdhwbZCa5VGJyCq3oj9HKaJ5RTHsSOSIvh7FQRbM/uAKUZHtfLzd7jBWwuyB/VSB1qSEO4yCHtYjvO4eEjur86fZNe+pHsejtuFN5HMh5QVMeud0VmbeB93L3M2die76u0Nd/Ea9q7/FkR4xR8a9OXAmp7PmCoB7/UlKufh6KvGeHE8xKl8Pibf/cpR56ViRvav660+TREQ9uxoi81S9r4qCOUUEEsuAIaVmGTsKeZ1zSWG3PGwTtIgMOxpCXF1FhSHcIvMh4JNkykzdG6Ul76kDEw6Tdc2cE6uA+o7jnVo3TDrSM5ZYE1ZrRlCz1SWRspx04GUxrjWNTd3wkiAx6vliKMM9/2FdzZRgDk4hlbQgoi1jO7TK/KZQKTaWBbIyTDgGNXQZjhM5fwW2LrmLymD6OXJo4qGLZwD51X+TX0JJZrxmUlsTNQE852o0snEl/rqojsp0+dn3x3Zti868kINTNF0PNcO/HgqwLqk67K3JcFlJNV+sVshUtW7gjHaqZ+Fpe4vV5mECQ2qrSw/ulr8EmeMaPsve9hltE2qnYSZaQSq0Q== killruana@edemaruh.slaanesh.org"
    ];
  };

  home-manager.users.jtremesay = {
    home = {
      stateVersion = "25.05";
      packages = with pkgs; [
      ];
    };

    programs.git = {
      userName = "Jonathan Tremesaygues";
      userEmail = "jonathan.tremesaygues@slaanesh.org";
    };
  };
}
