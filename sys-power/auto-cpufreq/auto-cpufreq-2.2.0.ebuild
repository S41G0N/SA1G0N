# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=poetry

inherit distutils-r1 systemd xdg-utils desktop

DESCRIPTION="Automatic CPU speed & power optimizer for Linux"
HOMEPAGE="https://github.com/AdnanHodzic/auto-cpufreq"
SRC_URI="https://github.com/AdnanHodzic/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
    dev-python/click[${PYTHON_USEDEP}]
    dev-python/distro[${PYTHON_USEDEP}]
    dev-python/psutil[${PYTHON_USEDEP}]
    dev-python/pygobject[${PYTHON_USEDEP}]
    dev-python/pyinotify[${PYTHON_USEDEP}]
    dev-python/requests[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="
    dev-python/poetry-core[${PYTHON_USEDEP}]
"

DOCS=( README.md )

src_prepare() {
    default

    # Print initial content of pyproject.toml
    einfo "Initial pyproject.toml content:"
    cat pyproject.toml

    # Remove dynamic versioning from pyproject.toml
    sed -i '/^version/s/= .*/= "'${PV}'"/' pyproject.toml || die
    sed -i '/poetry-dynamic-versioning/d' pyproject.toml || die
    sed -i '/tool.poetry-dynamic-versioning/d' pyproject.toml || die

    # Update build-system section
    sed -i 's/poetry_dynamic_versioning.backend/poetry.core.masonry.api/' pyproject.toml || die
    sed -i '/poetry-dynamic-versioning/d' pyproject.toml || die

    # Remove invalid scripts configuration
    sed -i '/enable = true/d' pyproject.toml || die
    sed -i '/vcs = "git"/d' pyproject.toml || die
    sed -i '/format = "v{base}+{commit}"/d' pyproject.toml || die

    # Print modified content of pyproject.toml
    einfo "Modified pyproject.toml content:"
    cat pyproject.toml

	# Replace /usr/local/share with /usr/share in auto-cpufreq-install.sh
    sed -i 's|/usr/local/share|/usr/share|g' scripts/auto-cpufreq-install.sh || die

    # Adjust paths
    sed -i 's|usr/local|usr|g' "scripts/${PN}.service" "scripts/${PN}-openrc" auto_cpufreq/core.py || die
    sed -i 's|usr/local|usr|g' "scripts/${PN}.service" "scripts/${PN}-openrc" auto_cpufreq/gui/app.py || die

	# Modify the service file
    sed -i 's|WorkingDirectory=/opt/auto-cpufreq/venv||g' scripts/auto-cpufreq.service || die
    sed -i 's|Environment=PYTHONPATH=/opt/auto-cpufreq||g' scripts/auto-cpufreq.service || die
    sed -i 's|ExecStart=/opt/auto-cpufreq/venv/bin/python /opt/auto-cpufreq/venv/bin/auto-cpufreq --daemon|ExecStart=/usr/bin/auto-cpufreq --daemon|g' scripts/auto-cpufreq.service || die

	# Change the path in core.py
    sed -i 's|/opt/auto-cpufreq/override.pickle|/var/lib/auto-cpufreq/override.pickle|g' auto_cpufreq/core.py || die

    distutils-r1_src_prepare
}

python_install() {
    distutils-r1_python_install

    # Create the scripts directory if it doesn't exist
    dodir "/usr/share/${PN}/scripts"

	# Create the directory for override.pickle
    dodir /var/lib/auto-cpufreq
    keepdir /var/lib/auto-cpufreq
    fowners root:root /var/lib/auto-cpufreq
    fperms 0755 /var/lib/auto-cpufreq

    # Copy all scripts from the 'scripts' directory
    for script in scripts/*; do
        if [[ -f "$script" ]]; then
            case "${script##*/}" in
                *.sh|*.py|auto-cpufreq-*|cpufreqctl.sh)
                    exeinto "/usr/share/${PN}/scripts"
                    doexe "$script"
                    ;;
                *)
                    insinto "/usr/share/${PN}/scripts"
                    doins "$script"
                    ;;
            esac
        fi
    done

    # Copy images
    insinto "/usr/share/${PN}/images"
    doins images/*

	# Install icon
    doicon -s 128 images/icon.png

    # Install polkit policy
    insinto /usr/share/polkit-1/actions
    doins scripts/org.auto-cpufreq.pkexec.policy

    # Install desktop file
    domenu scripts/auto-cpufreq-gtk.desktop

    # Install systemd service file
    systemd_douserunit "scripts/${PN}.service"

    # Install OpenRC init script
    newinitd "scripts/${PN}-openrc" "${PN}"
}

pkg_postinst() {
	xdg_icon_cache_update
    xdg_desktop_database_update

	elog "Updating XDG database"

    elog "The auto-cpufreq override file will be stored in /var/lib/auto-cpufreq/override.pickle"

	#Create log file
    touch /var/log/auto-cpufreq.log
    elog ""
    elog "Enable auto-cpufreq daemon service at boot:"
    elog "systemd: systemctl enable --now auto-cpufreq"
    elog "openrc: rc-update add auto-cpufreq default"
    elog ""
    elog "To view live log, run:"
    elog "auto-cpufreq --stats"
}

pkg_postrm() {
	xdg_icon_cache_update
    xdg_desktop_database_update

	# Remove the polkit policy
    if [ -f "/usr/share/polkit-1/actions/org.auto-cpufreq.pkexec.policy" ]; then
        rm -rf /usr/share/polkit-1/actions/org.auto-cpufreq.pkexec.policy || die
    fi

	# Remove the override.pickle file and directory
    if [[ -d "/var/lib/auto-cpufreq" ]]; then
        rm -rf /var/lib/auto-cpufreq
    fi

    # Remove auto-cpufreq log file
    if [ -f "/var/log/auto-cpufreq.log" ]; then
        rm /var/log/auto-cpufreq.log || die
    fi
    # Remove auto-cpufreq's cpufreqctl binary
    # it overwrites cpufreqctl.sh
    if [ -f "/usr/bin/cpufreqctl" ]; then
        rm /usr/bin/cpufreqctl || die
    fi
    # Restore original cpufreqctl binary if backup was made
    if [ -f "/usr/bin/cpufreqctl.auto-cpufreq.bak" ]; then
        mv /usr/bin/cpufreqctl.auto-cpufreq.bak /usr/bin/cpufreqctl || die
    fi
}
