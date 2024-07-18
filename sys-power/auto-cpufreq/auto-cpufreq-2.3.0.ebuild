# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..12} )

inherit python-single-r1 systemd desktop

DESCRIPTION="Automatic CPU speed & power optimizer for Linux"
HOMEPAGE="https://github.com/AdnanHodzic/auto-cpufreq"
SRC_URI="https://github.com/AdnanHodzic/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="gtk openrc"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
    ${PYTHON_DEPS}
    $(python_gen_cond_dep '
        >=dev-python/click-8.1.0[${PYTHON_USEDEP}]
        >=dev-python/distro-1.8.0[${PYTHON_USEDEP}]
        >=dev-python/requests-2.31.0[${PYTHON_USEDEP}]
        >=dev-python/pygobject-3.46.0[${PYTHON_USEDEP}]
        dev-python/pyinotify[${PYTHON_USEDEP}]
        dev-python/psutil[${PYTHON_USEDEP}]
    ')
    sys-apps/dmidecode
    dev-libs/gobject-introspection
    x11-libs/cairo
    gtk? ( x11-libs/gtk+:3 )
"
DEPEND="${RDEPEND}"
BDEPEND="
    $(python_gen_cond_dep '
        dev-python/poetry-core[${PYTHON_USEDEP}]
        dev-python/poetry-dynamic-versioning[${PYTHON_USEDEP}]
    ')
"

DOCS=( README.md )

src_prepare() {
    default
    # Replace /usr/local with /usr
    sed -i 's|/usr/local|/usr|g' scripts/${PN}.service scripts/${PN}-openrc auto_cpufreq/core.py auto_cpufreq/gui/app.py || die
}

src_install() {
    python_moduleinto auto_cpufreq
    python_domodule auto_cpufreq/*.py
    python_newscript auto_cpufreq/bin/auto_cpufreq.py auto-cpufreq
    use gtk && python_newscript auto_cpufreq/bin/auto_cpufreq_gtk.py auto-cpufreq-gtk

    # Install scripts
    exeinto "/usr/share/${PN}/scripts"
    doexe scripts/cpufreqctl.sh

    # Install CSS
    insinto "/usr/share/${PN}/scripts"
    doins scripts/style.css

    # Install images
    insinto "/usr/share/${PN}/images"
    doins images/*

    # Install icon
    doicon images/icon.png

    if use openrc; then
        # Install OpenRC init script
        newinitd scripts/${PN}-openrc ${PN}
    else
        # Install systemd service
        systemd_dounit scripts/${PN}.service
    fi

    # Install polkit policy
    insinto /usr/share/polkit-1/actions
    doins scripts/org.auto-cpufreq.pkexec.policy

    if use gtk; then
        domenu scripts/auto-cpufreq-gtk.desktop
    fi

    einstalldocs
}

pkg_postinst() {
    xdg_desktop_database_update
    if use openrc; then
        elog "To enable auto-cpufreq daemon service at boot:"
        elog "OpenRC: rc-update add auto-cpufreq default"
    else
        elog "To enable auto-cpufreq daemon service at boot:"
        elog "systemd: systemctl enable --now auto-cpufreq"
    fi
    elog ""
    elog "To view live log, run: auto-cpufreq --stats"
}

pkg_postrm() {
    xdg_desktop_database_update
}

pkg_prerm() {
    if use openrc; then
        # Remove from runlevels
        rc-update del auto-cpufreq default
    else
        # Stop and disable the systemd service
        systemctl is-active --quiet auto-cpufreq && systemctl stop auto-cpufreq
        systemctl disable auto-cpufreq
    fi

    # Remove any runtime-created files
    rm -f /var/log/auto-cpufreq.log
    rm -f /usr/bin/cpufreqctl

    # Restore original cpufreqctl binary if backup exists
    if [[ -f /usr/bin/cpufreqctl.auto-cpufreq.bak ]]; then
        mv /usr/bin/cpufreqctl.auto-cpufreq.bak /usr/bin/cpufreqctl
    fi
}
