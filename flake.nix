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
        xmclVersion = "0.54.4";
        sha256 = "547fd1b91449c660fcb7716215e5e2448cb0e821ae78c6a042aa72793c29d27b";

        # --- Dependencies ---
        runtimeDeps = with pkgs; [
          stdenv.cc.cc.lib # Essential C++ runtime
          alsa-lib # Audio
          atk # Accessibility
          cairo # Graphics
          cups # Needeed for electron
          dbus # Inter-process communication
          expat # XML parsing
          fontconfig # Font management
          freetype # Font rendering
          gdk-pixbuf # Image loading
          glib # Core libraries
          gobject-introspection # Object system introspection
          gtk3 # GUI Toolkit
          hicolor-icon-theme # Standard icon theme infrastructure
          libdrm # Direct Rendering Manager
          libGL # OpenGL
          libglvnd # OpenGL vendor-neutral dispatch
          mesa # OpenGL implementation
          nspr # Netscape Portable Runtime
          nss # Network Security Services
          pango # Text layout
          udev # Device management
          vulkan-loader # Vulkan support
          libX11 # X11 core
          libXcomposite # X11 compositing
          libXcursor # X11 cursors
          libXdamage # X11 damage reporting
          libXext # X11 extensions
          libXfixes # X11 fixes extension
          libXi # X11 input extension
          libXrandr # X11 RandR extension (screen config)
          libXrender # X11 rendering extension
          libXScrnSaver # X11 screen saver extension
          libxshmfence # X11 shared memory fences
          libXtst # X11 test extension (automation, etc.)
          libxcb # X protocol C binding
          libXxf86vm # XFree86 Video Mode extension
        ];
      in
      {
        packages.xmcl = pkgs.stdenv.mkDerivation {
          pname = "xmcl";
          version = xmclVersion;

          src = pkgs.fetchurl {
            url = "http://kr2-proxy.gitwarp.top:9980/https://github.com/Voxelum/x-minecraft-launcher/releases/download/v${xmclVersion}/xmcl-${xmclVersion}-x64.tar.xz";
            sha256 = sha256;
          };

          # Tools needed during the build process itself
          nativeBuildInputs = with pkgs; [
            autoPatchelfHook # Automatically patches ELF binaries/libraries
            makeWrapper # Creates wrapper scripts
          ];

          # Libraries needed for autoPatchelfHook to find and link against
          buildInputs = runtimeDeps;

          installPhase = ''
            runHook preInstall

            # --- Basic Setup ---
            # Create necessary directories
            mkdir -p $out/bin $out/opt/xmcl $out/share/applications $out/share/icons/hicolor $out/share/fontconfig/conf.d

            # Copy unpacked application files
            cp -r ./* $out/opt/xmcl/

            # Ensure the main binary is executable
            chmod +x $out/opt/xmcl/xmcl

            # --- Font Configuration ---
            # Assuming fonts.conf exists relative to flake.nix
            # If it's optional or located elsewhere, adjust this path
            cp ${./assets/fonts.conf} $out/share/fontconfig/conf.d/10-xmcl-fonts.conf

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


            # --- Wrapper Setup ---
            # Create a wrapper script in $out/bin
            makeWrapper $out/opt/xmcl/xmcl $out/bin/xmcl \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath runtimeDeps} \
              --set FONTCONFIG_PATH "$out/share/fontconfig" \
              --set FONTCONFIG_FILE "$out/share/fontconfig/conf.d/10-xmcl-fonts.conf" \
              --set GTK_USE_PORTAL 1 \
              --set APPIMAGE 1 \
              --unset JAVA_HOME \
              --add-flags "--enable-webrtc-pipewire-capturer"

            # --- Desktop Entry Setup ---
            # Assuming xmcl.desktop exists relative to flake.nix
            cp ${./assets/xmcl.desktop} $out/share/applications/xmcl.desktop
            chmod 644 $out/share/applications/xmcl.desktop

            # Substitute placeholder paths in the desktop file
            substituteInPlace $out/share/applications/xmcl.desktop \
              --replace "Exec=xmcl" "Exec=$out/bin/xmcl" \
              --replace "Icon=xmcl" "Icon=xmcl" # Use generic icon name, DE will find the best size

            runHook postInstall
          '';

          installCheckPhase = ''
            # Check if the binary links correctly
            ldd $out/bin/xmcl | grep "not found" && exit 1 || exit 0
          '';

          meta = with pkgs.lib; {
            description = "X Minecraft Launcher (XMCL)";
            homepage = "https://github.com/Voxelum/x-minecraft-launcher";
            license = licenses.mit;
            platforms = [ "x86_64-linux" ];
            maintainers = with maintainers; [
              "CI010"
              "Volodia Kraplich"
            ];
            sourceProvenance = with sourceTypes; [ binaryNativeCode ];
          };
        };

        # Provide xmcl as the default package for `nix build .`
        packages.default = self.packages.${system}.xmcl;

        # Dev shell for working on the flake
        devShells.default = pkgs.mkShell {
          name = "xmcl-dev-shell";
          packages = with pkgs; [
            nixpkgs-fmt # Formatter
            patchelf # For inspecting ELF files

            #--- Update version ---
            go
          ];
        };
      }
    );
}
