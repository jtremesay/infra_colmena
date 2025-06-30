{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
          age
          colmena
          fish
          nixfmt-rfc-style
          sops
          ssh-to-age
        ];
        shellHook = ''
          exec ${pkgs.fish}/bin/fish
        '';
      };

      commonModules = [
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
      ];

      nixosConfigurations = {
        edemaruh = nixpkgs.lib.nixosSystem {
          modules = self.commonModules ++ [
            ./machines/edemaruh/configuration.nix
          ];
        };

        hiraeth = nixpkgs.lib.nixosSystem {
          modules = self.commonModules ++ [
            ./machines/hiraeth/configuration.nix
          ];
        };

        music = nixpkgs.lib.nixosSystem {
          modules = self.commonModules ++ [
            ./machines/music/configuration.nix
          ];
        };
      };

      deployments = {
        edemaruh = {
          #targetHost = "192.168.1.50"; # wlan0
          #targetHost = "192.168.1.168"; # eth0
        };

        hiraeth = {
          targetHost = "hiraeth.jtremesay.org";
        };

        music = {
          #targetHost = "192.168.1.145"; # wlan0
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
