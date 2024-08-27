# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo git-r3

DESCRIPTION="System76 Power Management"
HOMEPAGE="https://github.com/pop-os/system76-power"
EGIT_REPO_URI="https://github.com/pop-os/system76-power"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""

DEPEND="sys-apps/systemd"
RDEPEND="${DEPEND}"
BDEPEND="virtual/rust"

src_unpack(){
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install(){
	default
	elog "Enable the service: 'systemctl enable --now com.system76.PowerDaemon.service'"
}
