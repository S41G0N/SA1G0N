# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg-utils desktop

MY_PV="1.0.0-a.34"  # Actual version from GitHub release
MY_P="zen"

DESCRIPTION="Zen Browser - A Firefox-based browser focused on privacy"
HOMEPAGE="https://github.com/zen-browser/desktop"
SRC_URI="https://github.com/zen-browser/desktop/releases/download/${MY_PV}/${MY_P}.linux-specific.tar.bz2 -> ${P}.tar.bz2"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS=""

IUSE="+alsa +gmp-autoupdate +pulseaudio selinux wayland"

BDEPEND="app-arch/unzip"
RDEPEND="${DEPEND}
	!www-client/zen-bin:0
	>=app-accessibility/at-spi2-core-2.46.0:2
	>=dev-libs/glib-2.26:2
	media-libs/alsa-lib
	media-libs/fontconfig
	>=media-libs/freetype-2.4.10
	sys-apps/dbus
	virtual/freedesktop-icon-theme
	>=x11-libs/cairo-1.10[X]
	x11-libs/gdk-pixbuf:2
	>=x11-libs/gtk+-3.11:3[X,wayland?]
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libxcb
	>=x11-libs/pango-1.22.0
	alsa? (
		!pulseaudio? ( media-sound/apulse )
	)
	pulseaudio? ( media-libs/libpulse )
	selinux? ( sec-policy/selinux-mozilla )
"
DEPEND="${RDEPEND}"

QA_PREBUILT="opt/zen/*"

S="${WORKDIR}"

src_install() {
    # Create installation directory
    local destdir="/opt/zen"
    dodir "${destdir}"

    # Install browser files
    cp -a "${S}/zen"/* "${ED}${destdir}" || die

    # Create zen-bin symlink
    dosym "${destdir}/zen-bin" "/usr/bin/zen-bin" || die

    # Install icons if they exist
    local icon_dir="${ED}${destdir}/browser/chrome/icons/default"
    if [[ -d "${icon_dir}" ]]; then
        for size in 16 32 48 64 128; do
            if [[ -f "${icon_dir}/default${size}.png" ]]; then
                newicon -s ${size} "${icon_dir}/default${size}.png" zen.png
            fi
        done
    else
        ewarn "Icon directory not found, skipping icon installation"
    fi

    # Create desktop entry
    make_desktop_entry zen-bin "Zen Browser" zen "Network;WebBrowser"

    # Ensure correct permissions
    fperms 0755 "${destdir}"/{zen-bin,updater,glxtest,vaapitest}
    fperms 0750 "${destdir}"/pingsender
}

pkg_postinst() {
    xdg_icon_cache_update
    xdg_desktop_database_update
    elog "For optimal performance and compatibility, please ensure"
    elog "that you have the latest graphics drivers installed."
}

pkg_postrm() {
    xdg_icon_cache_update
    xdg_desktop_database_update
}
