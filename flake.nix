{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    let
      addGems = ruby: ruby.withPackages (ps: with ps; [ sinatra rackup ]);

      forAllSystems = function:
        nixpkgs.lib.genAttrs
          [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ]
          (system: function nixpkgs.legacyPackages.${system});
    in
    {
      # packages = forAllSystems (pkgs: {
      #   default = pkgs.callPackage ./package.nix {};
      # });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ (addGems pkgs.ruby) ]; };
      });

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem { };
    };
}
