{
    description = "X Minecraft Launcher (XMCL) - A modern Minecraft launcher";

    inputs = {
        nixpkgs.url = "git+https://mirrors.cernet.edu.cn/nixpkgs.git?ref=master&shallow=1";
        flake-utils.url = "http://kr2-proxy.gitwarp.top:9980/https://github.com/numtide/flake-utils/archive/refs/heads/main.zip";
    };

    outputs =
        {
            self,
            nixpkgs,
            flake-utils,
        }:
        flake-utils.lib.eachDefaultSystem (
            system:
            let
                pkgs = nixpkgs.legacyPackages.${system};

                # --- Version ---
                xmclVersion = "0.56.4";
            in
            {
                packages.xmcl = pkgs.stdenv.mkDerivation rec {
                    pname = "xmcl";
                    version = xmclVersion;

                    src = pkgs.fetchurl {
                        url = "http://kr2-proxy.gitwarp.top:9980/https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${xmclVersion}/xmcl-${xmclVersion}-x64.tar.xz";
                        sha256 = "sha256-YpSK7qtCRhGENcmzp6+jgmYelenL5raBAGFmnl0s6Fs=";
                    };

                    # Tools needed during the build process itself
                    nativeBuildInputs = with pkgs; [
                        makeWrapper # Creates wrapper scripts
                    ];

                    installPhase = ''
                        runHook preInstall

                        mkdir -p $out/opt/xmcl
                        cp -r ./resources/app.asar $out/opt/xmcl
                        makeWrapper ${pkgs.lib.getExe pkgs.electron} $out/bin/xmcl \
                            --argv0 "xmcl" \
                            --add-flags "$out/opt/xmcl/app.asar" \
                            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
                            --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
                            --set-default ELECTRON_IS_DEV 0 

                        # --- Icons Setup ---
                        # Check if the standard icons directory exists in assets
                        if [ -d "${./assets/icons/hicolor}" ]; then
                            # Loop through standard sizes and copy if the specific icon exists
                            for size in 16 32 48 64 128 256 512; do
                                icon_file="${./assets/icons/hicolor}/''${size}x''${size}/apps/xmcl.png"
                                if [ -f "$icon_file" ]; then
                                    mkdir -p "$out/share/icons/hicolor/''${size}x''${size}/apps"
                                    cp "$icon_file" "$out/share/icons/hicolor/''${size}x''${size}/apps/"
                                    chmod 644 "$out/share/icons/hicolor/''${size}x''${size}/apps/xmcl.png"
                                fi
                            done
                            # Update icon cache if gtk3 is available
                            # gtk-update-icon-cache $out/share/icons/hicolor || true # Might need gtk3 in nativeBuildInputs if explicitly run
                        else
                            echo "Warning: Icon directory ${./assets/icons/hicolor} not found. Skipping icon installation."
                        fi

                        # --- Desktop Entry Setup ---
                        # Assuming xmcl.desktop exists relative to flake.nix
                        mkdir -p "$out/share/applications"
                        cp ${./assets/xmcl.desktop} $out/share/applications/xmcl.desktop
                        chmod 644 $out/share/applications/xmcl.desktop

                        # Substitute placeholder paths in the desktop file
                        substituteInPlace $out/share/applications/xmcl.desktop \
                            --replace "Exec=xmcl" "Exec=$out/bin/xmcl" \
                            --replace "Icon=xmcl" "Icon=xmcl" # Use generic icon name, DE will find the best size

                        runHook postInstall
                    '';

                    meta = with pkgs.lib; {
                        description = "X Minecraft Launcher (XMCL)";
                        homepage = "https://github.com/Voxelum/x-minecraft-launcher";
                        license = licenses.mit;
                        platforms = [ "x86_64-linux" ];
                        maintainers = with maintainers; [
                            "CI010"
                            "Volodia Kraplich"
                            "Neila"
                        ];
                        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
                    };
                };

                # Provide xmcl as the default package for `nix build .`
                packages.default = self.packages.${system}.xmcl;
            }
        );
}
