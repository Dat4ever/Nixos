{
  description = "datLOQ";

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
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs: {
    nixosConfigurations.datLOQ = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      specialArgs = { inherit inputs; }; 

      modules = [
        ./hardware-configuration.nix
        ./configuration.nix

        # Home Manager
        home-manager.nixosModules.home-manager {
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; }; 
          home-manager.users.dat = {
            imports = [
              stylix.homeModules.stylix 
              ./home-config/home.nix
            ];
          };
        }
      ];
    };
  };
}
