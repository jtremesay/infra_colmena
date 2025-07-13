{
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      home-manager,
      lanzaboote,
      nixpkgs,
      nixpkgs_unstable,
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
        home-manager.nixosModules.home-manager
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
      };

      deployments = {
        edemaruh = {
          #targetHost = "192.168.1.50"; # wlan0
          #targetHost = "192.168.1.168"; # eth0
        };

        hiraeth = {
          #targetHost = "hiraeth.jtremesay.org";
        };
      };

      colmena =
        {
          meta = {
            nixpkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [ ];
            };

            nodeNixpkgs.edemaruh = import nixpkgs_unstable {
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
