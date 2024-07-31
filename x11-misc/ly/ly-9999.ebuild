# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd git-r3

DESCRIPTION="Ly - a TUI display manager"
HOMEPAGE="https://github.com/fairyglade/ly"
EGIT_REPO_URI="https://github.com/fairyglade/ly.git"

CLAP="0.9.1"
ZIGINI="bdb6fd15c6dcedb0c6c2a46381f2d298e2f05fff"
ZIGLIBINI="e8a2da707555c5afd2618ce48cda19e6f4c2b693"

SRC_URI="
    https://github.com/Hejsil/zig-clap/archive/refs/tags/${CLAP}.tar.gz -> zig-clap-${CLAP}.tar.gz
    https://github.com/Kawaii-Ash/zigini/archive/${ZIGINI}.tar.gz -> zigini-${ZIGINI}.tar.gz
    https://github.com/ziglibs/ini/archive/${ZIGLIBINI}.tar.gz -> ziglibini-${ZIGLIBINI}.tar.gz
"

LICENSE="WTFPL-2"
SLOT="0"
KEYWORDS=""

EZIG_MIN="0.12"

DEPEND="
    || ( dev-lang/zig-bin:${EZIG_MIN} dev-lang/zig:${EZIG_MIN} )
    sys-libs/pam
    x11-libs/libxcb
"
RDEPEND="
    x11-base/xorg-server
    x11-apps/xauth
    sys-libs/ncurses
"

RES="${S}/res"

PATCHES=(
    "${FILESDIR}/${PN}-build-zig-zon-git.patch"
    "${FILESDIR}/${PN}-zigini-build-zig-zon-git.patch"
)

src_unpack() {
    git-r3_src_unpack
    default

    # Move the dependencies to the correct locations
    mkdir -p "${S}/deps" || die
    mv "${WORKDIR}/zig-clap-${CLAP}" "${S}/deps/zig-clap" || die
    mv "${WORKDIR}/zigini-${ZIGINI}" "${S}/deps/zigini" || die
    mv "${WORKDIR}/ini-${ZIGLIBINI}" "${S}/deps/zigini/ini" || die
}

src_compile() {
    zig build || die "Zig build failed"
}

src_install(){
    dobin "${S}/zig-out/bin/${PN}"
    newinitd "${RES}/${PN}-openrc" ly
    systemd_dounit "${RES}/${PN}.service"
}

pkg_postinst() {
    systemd_reenable "${PN}.service"
    ewarn
    ewarn "The init scripts are installed only for systemd/openrc"
    ewarn "If you are using something else like runit etc."
    ewarn "Please check upstream for get some help"
    ewarn "You may need to take a look at /etc/ly/config.ini"
    ewarn "If you are using a window manager as DWM"
    ewarn "Please make sure there is a .desktop file in /usr/share/xsessions for it"
}
