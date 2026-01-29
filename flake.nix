{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;

      src = ./.;

      deploy.nodes = {
      };

      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks inputs.self.deploy
      ) inputs.deploy-rs.lib;

      devShells.x86_64-linux.default =
        let
          pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.mkShell {
          packages = [
            inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
            pkgs.age
            pkgs.colmena
            pkgs.fish
            pkgs.nil
            pkgs.nixd
            pkgs.nixfmt-rfc-style
            pkgs.sops
            pkgs.ssh-to-age
          ];
          shellHook = ''
            exec ${pkgs.fish}/bin/fish
          '';
        };
    };
}
