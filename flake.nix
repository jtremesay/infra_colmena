{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      lanzaboote,
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
          colmena
          nixfmt-rfc-style
          fish
        ];
        shellHook = ''
          exec ${pkgs.fish}/bin/fish
        '';
      };

      nixosConfigurations = {
        edemaruh = nixpkgs.lib.nixosSystem {
          modules = [
            lanzaboote.nixosModules.lanzaboote
            ./machines/edemaruh/configuration.nix
          ];
        };

        music = nixpkgs.lib.nixosSystem {
          modules = [
            ./machines/music/configuration.nix
          ];
        };
      };

      deployments = {
        edemaruh = {
          targetHost = "192.168.1.50";
        };

        music = {
          targetHost = "192.168.1.145";
        };
      };

      colmena =
        {
          meta = {
            nixpkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [ ];
            };
          };
        }
        // builtins.mapAttrs (name: value: {
          deployment = self.deployments.${name} or { };
          nixpkgs.system = value.config.nixpkgs.system;
          imports = value._module.args.modules;
        }) (self.nixosConfigurations);
    };
}
