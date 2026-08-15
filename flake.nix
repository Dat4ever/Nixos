{
  description = "dat's flake.nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Datfetch (local)
    datfetch = {
      url = "path:/home/dat/Documents/projects/Datfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Outputs section
  outputs = { self, nixpkgs, home-manager, stylix, disko, datfetch, ... }@inputs: {

    # Global packages
    packages.x86_64-linux.datfetch = datfetch.packages.x86_64-linux.default;

    # datLOQ's outputs
    nixosConfigurations.datLOQ = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; 
      modules = [
        datfetch.nixosModules.default
        stylix.nixosModules.stylix
        disko.nixosModules.disko
        ./hosts/datLOQ/configuration.nix
        ./hosts/datLOQ/hardware-configuration.nix
        ./hosts/datLOQ/stylix.nix
        ./hosts/datLOQ/disko.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.dat = import ./hosts/datLOQ/home.nix;
        }
      ];
    };

    ## datSV's outputs (WIP — uncomment once hosts/datSV/ is tracked by git)
    # nixosConfigurations.datSV = nixpkgs.lib.nixosSystem {
    #   system = "x86_64-linux";
    #   specialArgs = { inherit inputs; }; 
    #   modules = [
    #     ./hosts/datSV/configuration.nix
    #     ./hosts/datSV/hardware-configuration.nix
    #     ./hosts/datSV/disko.nix
    #     disko.nixosModules.disko
    #     home-manager.nixosModules.home-manager
    #     datfetch.nixosModules.default
    #     {
    #       home-manager.useGlobalPkgs = true;
    #       home-manager.useUserPackages = true;
    #       home-manager.extraSpecialArgs = { inherit inputs; };
    #       home-manager.users.dat = import ./hosts/datSV/home.nix;
    #     }
    #   ];
    # };
  };
}
