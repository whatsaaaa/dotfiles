# dotfiles

My macOS setup, defined declaratively with nix-darwin and home-manager.
Clone it, run a couple of commands, and a new Mac comes out configured exactly like my last one.

## Using This Repo

This is my personal config. It's public so you can browse it, borrow ideas, or fork it.
I don't take feature requests or pull requests (PRs get closed automatically).
If something is actually broken, open an issue with the bug report template.

## What's included

A switch sets up:

- **macOs defaults**: dark mode, key repeat, Dock, Finder, trackpad
- **Homebrew**: casks and CLI tools
- **Nix packages**: ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font
- **Neovim**: my config, rose-pine moon theme
- **WezTerm**: rose-pine moon theme, unfocused panes dimmed
- **AI agents**: Claude, Codex, and opencode all read the same `AGENTS.md`

## Requirements

- An Apple Sillicon Mac (Apple Intel chips are default, will be updated in the future).
- For Intel chips, set `nixpkgs.hostPlatform = "X86_64-darwin";` in `configuration.nix`.

## Setting up a new Mac

Read [Before you apply it](#before-you-apply-it) first. The first switch changes your system.

1. Install Nix (I use the Determinate installer):

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

2. Clone the repo and link it to `~/.dotfiles`. `home.nix` resolves config files through that

```sh
git clone https://github.com/whatsaaaa/dotfiles.git
cd dotfiles
ln -s "$PWD" ~/.dotfiles
```

3. Run the first switch. `darwin-rebuild` isn't installed yet, so pull it from nix-darwin:

```sh
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#whatsaaaa-mac
```

From then on, `darwin-rebuild` is on your PATH and you use `rebuild.sh`.

### Checking a change without applying it

```sh
nix flake check --no-build
nix build .#darwinConfigurations.whatsaaaa-mac.system --dry-run
```

Replace `whatsaaaa-mac` with your own host label if you changed it.

## Day to day

Edit the config then:

```sh
./rebuild.sh
```

That's the entire workflow.

## Before you apply it

If you're using this on your own machine, check these first:

- **Username**: set the `user` line in `flake.nix` to your macOs username. Every other path comes from that value.
- **Host label**: it's `whatsaaaa-mac` and appears in two places that must match
- **Architecture**: `hostPlatform` in `configuration.nix`.


**Git identity**: deliberately not set here. Git will ask for it on your first commit. To manage it in Nix instead, add this to `home.nix`:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew will remove things.** `configuration.nix` uses `homebrew.onActivation.cleanup = "zap"`, so every switch uninstalls any brew or cask not listed in `brews` / `casks`. If you already have Homebrew packages, add the ones you want to keep before your first switch.

**Things you'll inherit if you don't change them:**

- `home/AGENTS.md` is my own agent policy and gets installed for Claude, Codex, and opencode.
- The `cc` and `co` aliases run `claude --dangerously-skip-permissions` and `codex --full-auto`. They skip confirmations on purpose. Know that before you use them.
