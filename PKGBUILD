# Maintainer: Oleg Shparber <trollixx+aur@gmail.com>
# Contributor: Bartłomiej Piotrowski <bpiotrowski@archlinux.org>
# Contributor: Andrea Scarpino <andrea@archlinux.org>
# Contributor: Sébastien Luttringer
# Contributor: xduugu
# Contributor: Ronald van Haren <ronald.archlinux.org>
# Contributor: Vesa Kaihlavirta
# URL: https://github.com/trollixx/aur-packages
# Upstream: https://projects.archlinux.org/svntogit/community.git/tree/trunk?h=packages/awesome

_pkgname=awesome
pkgname=${_pkgname}-git
pkgver=4.0.57.g5e1b88cb
pkgrel=1
pkgdesc='Highly configurable framework window manager'
arch=('i686' 'x86_64')
url='http://awesome.naquadah.org/'
license=('GPL2')
depends=('cairo' 'dbus' 'gdk-pixbuf2' 'imlib2' 'libxdg-basedir' 'libxkbcommon-x11'
         'lua' 'lua-lgi' 'pango' 'startup-notification' 'xcb-util-cursor'
         'xcb-util-keysyms' 'xcb-util-wm' 'xcb-util-xrm' 'xorg-xmessage')
makedepends=('asciidoc' 'cmake' 'docbook-xsl' 'doxygen' 'imagemagick' 'ldoc' 'xmlto')
optdepends=('rlwrap: readline support for awesome-client'
            'dex: autostart your desktop files'
            'vicious: widgets for the Awesome window manager')
provides=('notification-daemon' 'awesome')
conflicts=('awesome')
backup=('etc/xdg/awesome/rc.lua')
#source=("$pkgname::git://github.com/awesomeWM/awesome.git")
#source=("$pkgname::git://github.com/actionless/awesome.git#branch=grow-master")
#source=("$pkgname::git://github.com/actionless/awesome.git#branch=xresources-theme-refinements")
source=("$pkgname::git://github.com/actionless/awesome.git#branch=local")
md5sums=('SKIP')

pkgver() {
  cd $pkgname
  git describe | sed 's/^v//;s/-/./g'
}

prepare() {
  mkdir -p build
}

build() {
  cd build
  cmake ../$pkgname \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DSYSCONFDIR=/etc \
    -DLUA_LIBRARY=/usr/lib/liblua.so.5.3
  make
}

package() {
  cd build
  make DESTDIR="$pkgdir" install

  #sed "$srcdir"/$pkgname/awesome.desktop -i -e 's/^Exec=awesome/Exec=awesome --no-argb >> \/home\/lie\/.cache\/awesome_stdout \&2>> \/home\/lie\/.cache\/awesome_stderr/g'
  sed "$srcdir"/$pkgname/awesome.desktop -i -e 's/^Exec=awesome/Exec=awesome_no_argb/g'
  sed ${pkgdir}/etc/xdg/awesome/rc.lua -i -e 's/default\/theme/xresources\/theme/g'
  install -Dm644 "$srcdir"/$pkgname/awesome.desktop \
    "$pkgdir/usr/share/xsessions/awesome.desktop"
}
