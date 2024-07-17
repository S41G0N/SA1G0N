# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Ly - a lightweight TUI display manager for Linux and BSD"
HOMEPAGE="https://github.com/fairyglade/ly"
EGIT_REPO_URI="https://github.com/fairyglade/ly.git"

LICENSE="WTFPL-2"
SLOT="0"
KEYWORDS=""
IUSE="systemd openrc"

DEPEND="
    sys-libs/pam
    x11-libs/libxcb
    net-misc/wget
"
RDEPEND="${DEPEND}
    x11-base/xorg-server
    x11-apps/xauth
    sys-apps/util-linux
"
BDEPEND="
    >=dev-lang/zig-0.12.0
"

fetch_zig_deps() {
    local deps=(
        "https://github.com/Hejsil/zig-clap/archive/refs/tags/0.9.1.tar.gz"
        "https://github.com/Kawaii-Ash/zigini/archive/refs/tags/0.2.2.tar.gz"
        "https://github.com/ziglibs/ini/archive/da0af3a32e3403e3113e103767065cbe9584f505.tar.gz"
    )

    for dep in "${deps[@]}"; do
        wget -P "${T}" "${dep}" || die "Failed to fetch ${dep}"
    done
}

src_unpack() {
    git-r3_src_unpack
    fetch_zig_deps

    # Extract the dependencies
    mkdir -p "${S}/deps"
    tar -xzf "${T}/0.9.1.tar.gz" -C "${S}/deps"
    tar -xzf "${T}/0.2.2.tar.gz" -C "${S}/deps"
    mv "${S}/deps/zig-clap-0.9.1" "${S}/deps/clap"
    mv "${S}/deps/zigini-0.2.2" "${S}/deps/zigini"

    # Handle nested dependency
    mkdir -p "${S}/deps/zigini/deps"
    tar -xzf "${T}/da0af3a32e3403e3113e103767065cbe9584f505.tar.gz" -C "${S}/deps/zigini/deps"
    mv "${S}/deps/zigini/deps/ini-da0af3a32e3403e3113e103767065cbe9584f505" "${S}/deps/zigini/deps/ini"
}

src_prepare() {
    default

    # Modify main build.zig.zon
    cat <<EOF > "${S}/build.zig.zon"
.{
    .name = "ly",
    .version = "1.0.0",
    .minimum_zig_version = "0.12.0",
    .dependencies = .{
        .clap = .{
            .path = "deps/clap",
        },
        .zigini = .{
            .path = "deps/zigini",
        },
    },
    .paths = .{""},
}
EOF

    # Modify zigini's build.zig.zon
    cat <<EOF > "${S}/deps/zigini/build.zig.zon"
.{
    .name = "zigini",
    .version = "0.2.2",
    .dependencies = .{
        .ini = .{
            .path = "deps/ini",
        },
    },
}
EOF
}

src_compile() {
    zig build -Doptimize=ReleaseSafe || die "compilation failed"
}

src_install() {
    if use systemd; then
        zig build installsystemd -Doptimize=ReleaseSafe || die "systemd installation failed"
    elif use openrc; then
        zig build installopenrc -Doptimize=ReleaseSafe || die "openrc installation failed"
    else
        zig build installexe -Doptimize=ReleaseSafe || die "basic installation failed"
    fi

    # Install configuration file
    insinto /etc/ly
    doins "${S}/res/config.ini"
}

pkg_postinst() {
    if use systemd; then
        elog "To enable Ly, run:"
        elog "    systemctl enable ly.service"
        elog "You may also need to disable getty on Ly's tty:"
        elog "    systemctl disable getty@tty2.service"
    elif use openrc; then
        elog "To enable Ly, run:"
        elog "    rc-update add ly"
        elog "You may need to disable getty on Ly's tty, e.g.:"
        elog "    rc-update del agetty.tty2"
    fi
    elog "Configuration file is located at /etc/ly/config.ini"
}
