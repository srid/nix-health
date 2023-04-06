def green [msg: string] { 
    $"(ansi green_bold)✅(ansi reset) (ansi green_bold)($msg)(ansi reset)" 
}
def red [msg: string] { 
    $"(ansi red_bold)❌(ansi reset) (ansi red)($msg)(ansi reset)" 
}
def inRosetta [] {
    # 1 if rosetta
    (/usr/sbin/sysctl -n sysctl.proc_translated) != "0"
}
def parseNixVersion [] {
    parse "nix (Nix) {version}"  | first | get version | str trim
}
# Check that version a<=b
def semver_leq [a: string, b: string] {
    let min_of_both = (echo $"($b)\n($a)" | split row "\n" | sort | first)
    $min_of_both == $a
}
# ${lib.getExe pkgs.nix-info} -m

def main [system: string, cachixName?: string] {
    if 'IN_NIX_SHELL' in $env {
        # `nix doctor` can fail when run in a nix shell.
        red "You are in a nix-shell. Please exit it and run me again."
        exit 1
    }
    nix doctor

    green $"System: ($system)"

    # Nix version is not too old
    let nix_ver = (nix --version | parseNixVersion)
    if semver_leq "2.13.0" $nix_ver { 
        green $"Nix version ($nix_ver)" 
    } else { 
        red $"Nix version ($nix_ver) is too old" 
    }

    # Flakes is enabled
    nix flake show github:srid/haskell-flake --json out> /dev/null
    green "Flakes is enabled"

    # Make sure we are not accidentally on Rosetta.
    if $nu.os-info.name == "macos" {
        if $nu.os-info.arch == "aarch64" {
            if inRosetta { red "macOS: Rosetta detected" } else { green "macOS: not in Rosetta" }
        } else {
            green "macOS: not an Apple Silicon Mac"
        }
    }

    # TODO: test that cachix can be used, but without configuring any caches.
    # Using: https://github.com/srid/nix-health/issues/2
    if ($cachixName != null) {
        try { 
            nix run "nixpkgs#cachix" use $cachixName 
            green $"($cachixName).cachix.org will be used." 
        } catch {
            red $"($cachixName).cachix.org cannot be used. You must add yourself \(($env.USER)\) to nix.conf's trusted-users"
        }
    }
}