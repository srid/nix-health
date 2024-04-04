# nix-health

🩺 Check the health of your Nix install

> [!WARNING] 
> This project is superceded by the new [nix-health](https://github.com/juspay/nix-health). You should use that.

## Usage

```sh
nix run github:srid/nix-health
```

## Development

```sh
nix run nixpkgs#watchexec -- -e nix -e nu nix run
```
