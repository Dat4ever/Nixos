{ pkgs, inputs, ... }:

{
  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    vim                  # Text editor
    brightnessctl        # Screen brightness control
    wget                 # Web file retriever
    curl                 # URL file transfer utility
    git                  # Version control
    rsync                # System-level file sync & backups
    nixos-anywhere       # NixOS installation via SSH
    glib                 # gsettings binary
    gsettings-desktop-schemas  # GLib schemas (GTK theme backend)
    inputs.datfetch.packages.${pkgs.stdenv.hostPlatform.system}.default # datfetch from flake
  ];

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # Link gsettings schemas into system profile (GLib looks in glib-2.0/schemas/)
  environment.pathsToLink = [ "/share/gsettings-schemas" "/share/glib-2.0" ];
  environment.extraSetup = ''
    # Collect ALL schema XML files from every package into one directory
    mkdir -p "$out/share/glib-2.0/schemas"
    for schema_dir in "$out"/share/gsettings-schemas/*/; do
      if [ -d "$schema_dir/glib-2.0/schemas" ]; then
        for f in "$schema_dir/glib-2.0/schemas/"*.xml; do
          cp "$f" "$out/share/glib-2.0/schemas/$(basename "$f")" 2>/dev/null || true
        done
      fi
    done
    # Compile ALL schemas into a single gschemas.compiled
    ${pkgs.glib}/bin/glib-compile-schemas "$out/share/glib-2.0/schemas/" 2>/dev/null || true
  '';
}
