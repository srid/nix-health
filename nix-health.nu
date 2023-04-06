def green [msg: string] { 
    $"(ansi green_bold)✅(ansi reset) (ansi green_bold)($msg)(ansi reset)" 
}
def red [msg: string] { 
    $"(ansi red_bold)❌(ansi reset) (ansi red)($msg)(ansi reset)" 
}
def isArmMac [] {
    # The simplest way to check if we are on an Apple Silicon Mac, *regardless
    # of Rosetta*, is to look at macdep.cpu.brand_string.  cf.
    # https://stackoverflow.com/q/65259300/55246
    (uname) == "Darwin" and (/usr/sbin/sysctl -n machdep.cpu.brand_string) =~ "Apple"
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

    # Rosetta is not detected
    if isArmMac {
        if inRosetta { red "macOS: Rosetta detected" } else { green "macOS: not in Rosetta" }
    }

    # TODO: test the cachix can be used, but without configuring any caches.
    if ($cachixName != null) {
        nix run nixpkgs#cachix use $cachixName
        if $env.LAST_EXIT_CODE != "0" { red "Cachix is not configured (have you added yourself to trusted-users?)" } else { green "Cachix is configured" }
    }

    nix doctor
}