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
    rec {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeScriptBin "app" ("#!${addGems pkgs.ruby}/bin/ruby\n" + builtins.readFile ./app.rb);
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = [ (addGems pkgs.ruby) ]; };
      });

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ({ pkgs, lib, ... }:
            {
              nixpkgs.hostPlatform = "aarch64-linux";
              boot.isContainer = true;
              networking.nftables.enable = true;
              networking.firewall.allowedTCPPorts = [ 80 ];
              systemd.services.app = {
                description = "App";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = [ "${lib.getBin packages.aarch64-linux.default}/bin/app" ];
                  Environment = [ "PORT=80" "APP_ENV=production" ];
                  KillMode = "mixed";
                  Restart = "always";
                  RuntimeDirectory = "hawk";};
              };
            })
        ];
      };
    };
}
