{ config, pkgs, lib, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  dotnet = pkgs.dotnetCorePackages.sdk_10_0;
in

{
  home.username = "whatsaaaa";
  home.homeDirectory = "/Users/whatsaaaa";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    # the font everything renders in
    nerd-fonts.hack
    dotnet        # .NET SDK
    nodejs_latest # Node
    pnpm          # PNPM package manager
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    DOTNET_ROOT = "${dotnet}/share/dotnet";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm/bin" # pnpm 11 puts global bins here
    "$HOME/.dotnet/tools"
  ];

  home.activation.aspireCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "$HOME/.dotnet/tools/aspire" ]; then
        export DOTNET_ROOT="${dotnet}/share/dotnet"
        run ${dotnet}/bin/dotnet tool install -g Aspire.Cli
      fi
    '';

  # Firstmate's AXI CLIs live on npm, not nixpkgs. Their Claude Code hooks are
  # committed in home/.claude/settings.json, so `setup hooks` never needs to run.
  home.activation.axiTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      (
        export PNPM_HOME="$HOME/.local/share/pnpm"
        export PATH="$PNPM_HOME/bin:${pkgs.nodejs_latest}/bin:$PATH"
        installed=$(${pkgs.pnpm}/bin/pnpm ls -g --depth 0 --json 2>/dev/null \
          | ${pkgs.jq}/bin/jq -c '[.[].dependencies // {} | to_entries[] | {(.key): .value.version}] | add // {}') \
          || installed='{}'
        specs=()
        for tool in gh-axi chrome-devtools-axi tasks-axi quota-axi; do
          ${pkgs.jq}/bin/jq -e --arg t "$tool" 'has($t)' <<<"$installed" >/dev/null || specs+=("$tool")
        done
        ${pkgs.jq}/bin/jq -e '(."lavish-axi" // "0") | try (split(".") | map(tonumber) >= [0, 1, 77]) catch false' \
          <<<"$installed" >/dev/null || specs+=("lavish-axi@>=0.1.77")
        if [ ''${#specs[@]} -gt 0 ]; then
          run ${pkgs.pnpm}/bin/pnpm add -g "''${specs[@]}" \
            || warnEcho "pnpm could not install ''${specs[*]}; run ./rebuild.sh again once the network is back"
        fi
      )
    '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
