{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    configuration = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
	  pkgs.brave
	  pkgs.google-chrome
          pkgs.neovim
          pkgs.ghostty-bin
	  pkgs._1password-gui
	  pkgs.raycast
        ];

      system.primaryUser = "cass";
      system.defaults = {
        dock.autohide = true;
	dock.persistent-apps = [];
	NSGlobalDomain.KeyRepeat = 2;
	CustomUserPreferences = {
	  "com.apple.symbolichotkeys" = {
	    AppleSymbolicHotKeys = {
	      # Disable 'Cmd + Space' for Spotlight Search
              "64" = {
                enabled = false;
              };
	    };
	  };
	};
      };
      system.keyboard = {
      	enableKeyMapping = true;
  	remapCapsLockToControl = true;
      };

      homebrew = {
        enable = true;
	brews = [
	  "mas"
	];

	# only packages in this config will be installed, otherwise, others will be removed
	onActivation.cleanup = "zap";
	onActivation.autoUpdate= true;
	onActivation.upgrade= true;
      };

      nix.enable = false;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#samantha
    darwinConfigurations."samantha" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
	{
	  nix-homebrew = {
	    # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
	    user = "cass";

	    # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
	  };
	}
	# Optional: Align homebrew taps config with nix-homebrew
        ({config, ...}: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })
      ];
    };
  };
}
