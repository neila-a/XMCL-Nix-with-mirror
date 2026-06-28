{
    pkgs,
    ...
}:
with pkgs;
[
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
]
