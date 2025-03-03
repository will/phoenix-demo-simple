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
      packages = forAllSystems (pkgs: {
        default = pkgs.writeScriptBin "app" ("#!${addGems pkgs.ruby}/bin/ruby\n" + builtins.readFile ./app.rb);
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ (addGems pkgs.ruby) ]; };
      });

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem { };
    };
}
