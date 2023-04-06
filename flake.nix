{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nuenv.url = "github:DeterminateSystems/nuenv";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      perSystem = { pkgs, lib, system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.nuenv.overlays.nuenv ];
        };
        packages.default = pkgs.nuenv.mkScript {
          name = "nix-health.nu";
          script = ''
            # nix-health: Check the health of your Nix install
            def main [
              --cachixName (-c): string # The cachix cache name to use.
              ] {
              if $cachixName == null {
                ${lib.getExe pkgs.nushell} ${./nix-health.nu} ${system}
              } else {
                ${lib.getExe pkgs.nushell} ${./nix-health.nu} ${system} ''$cachixName
              }
            }
          '';
        };
      };
    };
}






