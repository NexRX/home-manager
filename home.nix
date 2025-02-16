{
  config,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.hostPlatform.system;
  nix-gaming = inputs.nix-gaming.packages.${system};
in
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
    # Nix Gaming - https://github.com/fufexan/nix-gaming
    # nix-gaming.wine-ge or wine-tkg
    nix-gaming.wine-discord-ipc-bridge
    # nix-gaming.star-citizen

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
    kdePackages.filelight
    filezilla
    thunderbird
    qbittorrent
    ghostty # terminal
    nushell # shell
    carapace
    starship
    neofetch
    lsof

    # Key binidngs stuff
    xorg.xev
    xbindkeys
    xdotool

    # Coding
    vscode
    git
    python3
    nixfmt-rfc-style

    (writeShellScriptBin "echo-pkgs" ''
      echo "${pkgs.glfw}/lib"
    '')
    (writeShellScriptBin "wine-control-star-citizen" ''
      WINEPREFIX=$HOME/Games/star-citizen nix run github:fufexan/nix-gaming#wine-ge -- control
    '')
    (writeShellScriptBin "wine-cfg-star-citizen" ''
      WINEPREFIX=$HOME/Games/star-citizen nix run github:fufexan/nix-gaming#wine-ge -- winecfg
    '')
    (writeShellScriptBin "bt-reset" ''
      #!/bin/bash
      bluetoothctl power off
      sudo systemctl stop bluetooth
      sudo rfkill block bluetooth
      sudo rfkill unblock bluetooth
      sudo systemctl start bluetooth
      sleep 1
      bluetoothctl power on
      exit 0
    '')
    (writeShellScriptBin "bt-fix" ''
      #!/bin/bash
      # take first arg as mac address and use it or default to 78:2B:64:14:B8:27
      HEADPHONES_MAC="${"$"}{1:-78:2B:64:14:B8:27}"
      bluetoothctl remove $HEADPHONES_MAC
      bluetoothctl connect $HEADPHONES_MAC
    '')
    (writeShellScriptBin "hs" "switch")
    (writeShellScriptBin "switch" ''
      echo "✨ Switching User!"
      home-manager switch
    '')
    (writeShellScriptBin "ns" "nixswitch")
    (writeShellScriptBin "nixswitch" ''
      echo "✨ Switching NixOS System!"
      sudo nixos-rebuild switch --flake /etc/nixos
    '')
  ];

  # Custom Key binds - Run `systemctl --user restart xbindkeys` after changing
  xdg.configFile."xbindkeys/config".text = ''
    # On F3 Mouse Button, Type following:
    # "xdotool type 'Hello World'"
    "bash -c 'xdotool type $(cat ~/.config/home-manager/secrets/p.txt)'"
      F3
  '';
  systemd.user.services.xbindkeys = {
    Unit = {
      Description = "xbindkeys daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.xbindkeys}/bin/xbindkeys -n -f %h/.config/xbindkeys/config";
      Restart = "always";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

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
    # WINE_FULLSCREEN_FSR = "1";
  };

  services.kdeconnect.enable = true;
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
