<h1 align="center">dotfiles</h1>
<p align="center"><strong>My macOS setup, written down as code.&nbsp;</strong><br>
One repo, a few commands, and a fresh Mac looks exactly like my last one.</p>
<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-Apple%20Silicon-000000?style=flat-square&logo=apple&logoColor=white">
  <img alt="Built with Nix" src="https://img.shields.io/badge/built%20with-Nix-5277C3?style=flat-square&logo=nixos&logoColor=white">
  <img alt="nix-darwin" src="https://img.shields.io/badge/nix--darwin-26.05-7EBAE4?style=flat-square">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
</p>
<p align="center">
  <a href="#whats-inside">What's inside</a> ·
  <a href="#prerequisites">Prerequisites</a> ·
  <a href="#getting-started">Getting started</a> ·
  <a href="#day-to-day">Day to day</a> ·
  <a href="#gotchas">Gotchas</a> ·
  <a href="#repo-layout">Layout</a>
</p>

---

# About
 
This repo configures a whole Mac declaratively with [nix-darwin](https://github.com/nix-darwin/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager): system settings, apps, CLI tools, shell, editor, terminal, and AI agent configs.
 
It's public so you can read it, steal ideas, or fork it.
 
> [!NOTE]
> This is a personal config, not a framework. Feature requests and pull requests aren't accepted (PRs are closed automatically). If you find a real bug, open an issue using the bug report template.
 
## What's inside
 
| Area | What you get |
| --- | --- |
| **macOS** | Dark mode, fast key repeat, Dock, Finder, and trackpad preferences |
| **Homebrew** | GUI apps (casks) and CLI tools (brews), declared in `configuration.nix` |
| **Nix packages** | `ripgrep`, `fd`, `fzf`, `jq`, `lazygit`, Neovim, Hack Nerd Font |
| **Shell** | zsh, aliases, [starship](https://starship.rs) prompt |
| **Editor** | Neovim + [lazy.nvim](https://github.com/folke/lazy.nvim), rose-pine moon theme |
| **Terminal** | WezTerm, rose-pine moon theme, dimmed unfocused panes |
| **AI agents** | Claude, Codex, and opencode all share one `AGENTS.md` |
 
## Prerequisites
 
Before you start, make sure you have:
 
- [ ] **A Mac with Apple Silicon** (M1 or newer). Intel works too with a one-line change, see [step 4](#4-make-it-yours).
- [ ] **An admin account.** The first switch changes system settings and needs `sudo`.
- [ ] **Internet access.** Nix, Homebrew, and Neovim plugins are all downloaded on first run.
- [ ] **Xcode Command Line Tools**, step 1 covers this.
- [ ] **~30 minutes.** The first build downloads a lot. Later rebuilds take seconds.
You do **not** need to install Homebrew yourself. nix-darwin manages it.
 
## Getting started
 
### 1. Install the Command Line Tools
 
Install Apple's developer tools:
 
```sh
xcode-select --install
```
 
Click through the dialog and wait for it to finish.
 
### 2. Install Nix
 
This config is built around [Determinate Nix](https://determinate.systems/nix/):
 
```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```
 
When it's done, **close your terminal and open a new one** so `nix` is on your `PATH`. Check it worked:
 
```sh
nix --version
```
 
### 3. Clone the repo
 
```sh
git clone https://github.com/Whatsaaaa/dotfiles.git
cd dotfiles
```
 
### 4. Make it yours
 
Skip this step only if you're me. Otherwise, open these files and adjust:
 
| What | Where | Change it to |
| --- | --- | --- |
| **Username** | the `user = "..."` line in `flake.nix` | your macOS username (run `whoami`) |
| **Host label** | `darwinConfigurations."mac"` in `flake.nix` **and** `#mac` in `rebuild.sh` | any name, as long as both match |
| **CPU** | `nixpkgs.hostPlatform` in `configuration.nix` | `"x86_64-darwin"` on Intel, leave as is on Apple Silicon |
 
Every path in `configuration.nix` and `home.nix` is derived from `user`, so that one line is enough.
 
### 5. Review the Homebrew list
 
> [!WARNING]
> Every switch **uninstalls** any Homebrew package or app that isn't listed in `configuration.nix`. If you already use Homebrew, add everything you want to keep to `brews` and `casks` **before** continuing. See [Gotchas](#homebrew-deletes-what-it-doesnt-know-about).
 
### 6. Link the repo to `~/.dotfiles`
 
`home.nix` finds config files through `~/.dotfiles`, so this link must exist before the first build:
 
```sh
ln -s "$PWD" ~/.dotfiles
```
 
### 7. Test the build (optional, but recommended)
 
Make sure everything evaluates before you let it touch your system:
 
```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```
 
Use your own host label instead of `mac` if you changed it.
 
### 8. Run the first switch
 
`darwin-rebuild` isn't installed yet, so run it straight from nix-darwin:
 
```sh
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#mac
```
 
### 9. Finish up
 
1. **Open a new terminal.** Your new shell, prompt, and `darwin-rebuild` are only picked up by new sessions.
2. **Log out and back in.** Some macOS settings (like key repeat) only apply after that.
3. **Set your git identity**, which this config deliberately doesn't do:
```sh
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
```
 
4. **Launch `nvim` once** while online, so it can install its plugins.
You're done.
 
## Day to day
 
Change something, then apply it:
 
```sh
./rebuild.sh
```
 
Whether you even need that depends on what you changed:
 
| You changed... | Do you need `./rebuild.sh`? |
| --- | --- |
| A file under `home/` (Neovim, WezTerm, `AGENTS.md`...) | **No.** It's symlinked, so it's live immediately |
| A package, Homebrew app, alias, or macOS default | **Yes** |
| Added a brand new file anywhere | **Yes**, and `git add` it first (see below) |
 
## Gotchas
 
Things that aren't obvious until they bite you.
 
### Homebrew deletes what it doesn't know about
 
`configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`. On every switch, Homebrew removes **any** formula or cask not in `brews` / `casks`, along with its data. Installing something with `brew install` by hand works only until your next rebuild. Add it to the list instead.
 
### New files are invisible until you `git add` them
 
Flakes only see files tracked by git. If you create a new file and the build says it can't find it, run `git add <file>` (no need to commit) and rebuild.
 
### Don't move or rename the repo folder
 
`~/.dotfiles` points at wherever you cloned the repo, and all your config symlinks go through it. Move the folder and your editor, terminal, and shell configs all break at once. If you do move it, recreate the link:
 
```sh
ln -sfn /new/path/to/dotfiles ~/.dotfiles
```
 
### Existing config files block the first switch
 
If you already have files like `~/.zshrc` or `~/.config/nvim`, home-manager refuses to overwrite them and the switch fails with a "would be clobbered" error. Move them somewhere safe (or delete them) and run the switch again.
 
### The host label lives in more than one place
 
`flake.nix` and `rebuild.sh` both reference `mac`. If they disagree, the build fails with an error saying the configuration doesn't exist. Rename both together.
 
### You inherit my AI agent rules
 
`home/AGENTS.md` is my personal policy, and it gets installed for Claude, Codex, and opencode. If you fork this, edit or delete it, or every agent you run will follow my rules without you noticing.
 
### Two aliases skip all safety prompts
 
| Alias | Runs |
| --- | --- |
| `cc` | `claude --dangerously-skip-permissions` |
| `co` | `codex --full-auto` |
 
They let the agent run commands without asking. Convenient, but know what you're typing.
 
### Built for Determinate Nix
 
The config assumes Nix itself is installed and managed by the Determinate installer. If you used a different installer, you may get conflicts over who manages the Nix daemon.
 
### Neovim needs the internet once
 
The first `nvim` launch clones every plugin from GitHub. Offline, it starts with errors. After that first run, it works offline.
 
## Repo layout
 
```
.
├── flake.nix            # entry point: inputs, user, and the "mac" host
├── configuration.nix    # system level: macOS defaults, Homebrew
├── home.nix             # user level: shell, packages, prompt, symlinks
├── rebuild.sh           # re-apply the config after a change
└── home/                # real config files, symlinked into ~
```
 
### How the symlinks work
 
The files in `home/` are your live config, not copies. `home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` directly at `home/.config/nvim` in this repo, so the repo and your machine can never drift apart.
 
## Theme
 
Neovim and WezTerm both use **rose-pine moon**. Neovim has italics off and a transparent background on macOS, Windows, and WSL, so it blends into the terminal.
 
## License
 
[MIT](LICENSE).
