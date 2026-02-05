{
  inputs = {
    colmena.url = "github:zhaofengli/colmena";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
      colmena,
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

      commonModules = [
        home-manager.nixosModules.home-manager
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
      ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          age
          colmena.packages.${system}.colmena
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

      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ ];
          };
        };

        music = {
          deployment = {
            #targetHost = "192.168.1.79";
          };
          imports = commonModules ++ [ ./machines/music/configuration.nix ];
        };

        hiraeth = {
          deployment = {
            #targetHost = "hiraeth.jtremesay.org";
          };
          imports = commonModules ++ [ ./machines/hiraeth/configuration.nix ];
        };
      };
    };
}
