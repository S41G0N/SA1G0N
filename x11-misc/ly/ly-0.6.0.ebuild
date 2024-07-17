# /usr/local/portage/sys-auth/ly/ly-0.6.0.ebuild
EAPI=7
inherit git-r3

DESCRIPTION="Ly is a lightweight TUI (ncurses-like) display manager for Linux and BSD"
HOMEPAGE="https://github.com/fairyglade/ly"
EGIT_REPO_URI="https://github.com/fairyglade/ly.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="sys-libs/ncurses
        x11-libs/libxcb
        sys-libs/pam
        dev-libs/libpcre
        sys-libs/readline
        dev-libs/libev
        dev-libs/libconfig
        sys-devel/gcc"
RDEPEND="${DEPEND}"
BDEPEND="virtual/pkgconfig
         sys-devel/make"

# Define the submodules with their respective repositories
EGIT_SUBMODULES=(
    "sub/ctypes https://github.com/nullgemm/argoat.git"
    "sub/configator https://github.com/leogx9r/configator.git"
    "sub/dragonfail https://github.com/leogx9r/dragonfail.git"
    "sub/termbox_next https://github.com/termbox/termbox-next.git"
)

src_prepare() {
    default
    eapply_user
}

src_configure() {
    default
}

src_compile() {
    emake || die "emake failed"
}

src_install() {
    emake DESTDIR="${D}" install installsystemd || die "emake install failed"
    dodoc README.md
}

