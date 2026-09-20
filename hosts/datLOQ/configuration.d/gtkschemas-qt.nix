{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    glib                      # gsettings binary
    gsettings-desktop-schemas # GLib schemas (GTK theme backend)
  ];

  # Link gsettings schemas into system profile
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

  # Qt platform theme + style.
  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };
}
