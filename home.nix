{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nex";
  home.homeDirectory = "/home/nex";
  home.stateVersion = "24.11"; # Dont change even with Home Manger updates

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Gaming
    prismlauncher
    discord
    lutris

    # Security
    keepassxc

    # Web
    vivaldi
    # (vivaldi.overrideAttrs # Fix for QT related crash on startup
    #   (oldAttrs: {
    #     dontWrapQtApps = false;
    #     dontPatchELF = true;
    #     nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
    #   }))
    vivaldi-ffmpeg-codecs

    # Tools
    kdePackages.konqueror
    filezilla
    qbittorrent
    ghostty # terminal
    nushell # shell
    carapace
    starship

    # Coding
    vscode
    git
    python3
    nixfmt-rfc-style

    (writeShellScriptBin "echo-pkgs" ''
      echo "${pkgs.glfw}/lib"
    '')
    (writeShellScriptBin "switch" ''
      echo "✨ Switching User!"
      home-manager switch
    '')
    (writeShellScriptBin "nixswitch" ''
      echo "✨ Switching NixOS System!"
      sudo nixos-rebuild switch --flake /etc/nixos
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".local/share/icons/keepassxc.svg".source = .Desktop/keepassxc.svg;
    # Desktop Files
    # ".local/share/applications/atlauncher.desktop".source = .Desktop/atlauncher.desktop;
    # ".local/share/icons/atlauncher.svg".source = .Desktop/atlauncher.svg;

    # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  # ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  # or ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  # or /etc/profiles/per-user/nex/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = with pkgs; {
    EDITOR = "code --wait";
    QT_QPA_PLATFORM_PLUGIN_PATH = "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins";
    LD_LIBRARY_PATH = "${pkgs.glfw}/lib";
  };

  programs.bash = {
    enable = true;
    sessionVariables = {
      EDITOR = "code --wait";
    };
    initExtra = ''
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    '';
  };

  programs.nushell = {
    enable = true;
    # The config.nu can be anywhere you want if you like to edit your Nushell with Nu
    # configFile.source = ./.../config.nu;
    # for editing directly to config.nu
    extraConfig = ''
      let carapace_completer = {|spans|
      carapace $spans.0 nushell $spans | from json
      }
      $env.config = {
       show_banner: false,
       completions: {
       case_sensitive: false # case-sensitive completions
       quick: true    # set to false to prevent auto-selecting completions
       partial: true    # set to false to prevent partial filling of the prompt
       algorithm: "fuzzy"    # prefix or fuzzy
       external: {
       # set to false to prevent nushell looking into $env.PATH to find more suggestions
           enable: true 
       # set to lower can improve completion performance at the cost of omitting some options
           max_results: 100 
           completer: $carapace_completer # check 'carapace_completer' 
         }
       }
      } 
      $env.PATH = ($env.PATH | 
      split row (char esep) |
      prepend /home/myuser/.apps |
      append /usr/bin/env
      )
    '';
    shellAliases = {
      vi = "hx";
      vim = "hx";
      nano = "hx";
    };
  };
  programs.carapace.enable = true;
  programs.carapace.enableNushellIntegration = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  programs.git = {
    enable = true;
    userEmail = "nex@nexhub.co.uk";
    userName = "Nex";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
