{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      overlays = [ (final: prev: { rubyWithGems = prev.ruby.withPackages (ps: with ps; [ sinatra rackup ]); }) ];
      forAllSystems = function: nixpkgs.lib.genAttrs
        [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ]
        (system: function (import nixpkgs { inherit system overlays; }));
    in
    rec {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeScriptBin "app" ("#!${pkgs.rubyWithGems}/bin/ruby\n" + builtins.readFile ./app.rb);
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell { packages = with pkgs; [ rubyWithGems nixpkgs-fmt ]; };
      });

      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        modules = [
          {
            nixpkgs.hostPlatform = "aarch64-linux";
            boot.isContainer = true;
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            networking.nftables.enable = true;
            networking.firewall.allowedTCPPorts = [ 80 ];
          }

          ({ pkgs, ... }:
            {
              systemd.services.app = {
                description = "App";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = [ "${packages.aarch64-linux.default}/bin/app" ];
                  Environment = [ "PORT=80" "APP_ENV=production" ];
                  KillMode = "mixed";
                  Restart = "always";
                  RuntimeDirectory = "app";
                };
              };
            })
        ];
      };
    };
}
