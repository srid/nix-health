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
          name = "run-me";
          script = ''
            def green [msg: string] { 
              $"(ansi green_bold)✅(ansi reset) (ansi green_bold)($msg)(ansi reset)" 
            }
            def red [msg: string] { 
              $"(ansi red_bold)❌(ansi reset) (ansi red)($msg)(ansi reset)" 
            }
            # ${lib.getExe pkgs.nix-info} -m

            def main [cachixName?: string] {
              if 'IN_NIX_SHELL' in $env {
                # `nix doctor` can fail when run in a nix shell.
                red "You are in a nix-shell. Please exit it and run me again."
                exit 1
              }
              green "System: ${system}"

              # Nix version is not too old
              let nix_ver = (nix --version | parse "nix (Nix) {version}"  | first | get version | str trim)
              let nix_min_ver = "2.13.0"
              let min_of_both = (echo $"($nix_ver)\n($nix_min_ver)" | split row "\n" | sort | first)
              if $min_of_both != $nix_min_ver { red $"Nix version ($nix_ver) is too old" } else { green $"Nix version ($nix_ver)" }


              # Flakes is enabled
              nix flake show github:srid/haskell-flake --json out> /dev/null
              green "Flakes is enabled"

              # Rosetta is not detected
              if (uname) == "Darwin" {
                let trans = (sysctl -n sysctl.proc_translated) # 1 if rosetta
                if $trans != "0" { red "macOS: Rosetta detected" } else { green "macOS: not in Rosetta" }
              }

              # TODO: test the cachix can be used, but without configuring any caches.
              if ($cachixName != null) {
                nix run nixpkgs#cachix use $cachixName
                if $env.LAST_EXIT_CODE != "0" { red "Cachix is not configured (have you added yourself to trusted-users?)" } else { green "Cachix is configured" }
              }

              nix doctor
            }
          '';
        };
      };
    };
}

