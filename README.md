# nix-health

🩺 Check the health of your Nix install

> [!NOTE] 
> nix-health ng is being worked on. See [here](https://github.com/juspay/nix-browser/tree/main/crates/nix_health)

## Usage

```sh
nix run github:srid/nix-health
```

## Development

```sh
nix run nixpkgs#watchexec -- -e nix -e nu nix run
```

## Help

If nix-health reports a warning or error, see https://zero-to-flakes.com/gotchas#nix-health
