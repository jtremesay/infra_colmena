{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
    {
      self,
      deploy-rs,
      home-manager,
      lanzaboote,
      nixpkgs,
      sops-nix,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [

          deploy-rs.packages.${pkgs.system}.deploy-rs
          age
          fish
          nil
          nixd
          nixfmt-rfc-style
          sops
          ssh-to-age
        ];
        shellHook = ''
          exec ${pkgs.fish}/bin/fish
        '';
      };

      deploy.nodes = {
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
