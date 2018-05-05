# Maintainer: Daniel Hahler <archlinux+aur@thequod.de>
# Contributor: noonov <noonov@gmail.com>
# Contributor: wtchappell <wtchappell@gmail.com>

_pkgname=awesome
pkgname=awesome-luajit-git
pkgver=4.2.84.ga20dd4ad
pkgrel=1
pkgdesc="awesome window manager built with luajit"
arch=('i686' 'x86_64')
url='http://awesome.naquadah.org/'
license=('GPL2')
depends=('cairo' 'dbus' 'gdk-pixbuf2' 'libxdg-basedir' 'libxkbcommon-x11'
         'luajit' 'luajit-lgi' 'pango' 'startup-notification' 'xcb-util-cursor'
         'xcb-util-keysyms' 'xcb-util-xrm' 'xcb-util-wm')
makedepends=('asciidoc' 'cmake' 'docbook-xsl' 'git' 'imagemagick' 'ldoc'
             'xmlto' 'lua-penlight-git')
optdepends=('rlwrap: readline support for awesome-client'
            'dex: autostart your desktop files'
            'vicious: widgets for the Awesome window manager')
provides=('notification-daemon' 'awesome')
conflicts=('awesome')
backup=('etc/xdg/awesome/rc.lua')
source=("$pkgname::git+https://github.com/actionless/awesome.git#branch=local"
        awesome.desktop
        awesomeksm.desktop)
sha256sums=('SKIP'
            'SKIP'
            '8f25957ef5453f825e05a63a74e24843aad945af86ddffcc0a84084ca2cf9928')

pkgver() {
  cd $pkgname
  git describe | sed 's/^v//;s/-/./g'
}

prepare() {
  cd $pkgname
  sed -i 's/COMMAND lua\b/COMMAND luajit/' awesomeConfig.cmake tests/examples/CMakeLists.txt
  sed -i 's/LUA_COV_RUNNER lua\b/LUA_COV_RUNNER luajit/' tests/examples/CMakeLists.txt

}

build() {
    rm -r build || true
    rm -fr themes/zenburn themes/sky
  mkdir -p build
  cd build

  cmake ../$pkgname \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DSYSCONFDIR=/etc \
    -DGENERATE_MANPAGES=false \
    -DGENERATE_DOC=true \
    -DLUA_INCLUDE_DIR=/usr/include/luajit-2.0 \
    -DLUA_LIBRARY=/usr/lib/libluajit-5.1.so
  make
}

package() {
  cd build
  make DESTDIR="$pkgdir" install

  sed ${pkgdir}/etc/xdg/awesome/rc.lua -i \
      -e 's/default\/theme/xresources\/theme/g' \
      -e 's/awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" },/awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12" },/g'

  install -Dm755 "$srcdir"/$pkgname/awesome_argb \
    "$pkgdir/usr/bin/awesome_argb"

  install -Dm755 "$srcdir"/$pkgname/awesome_no_argb \
    "$pkgdir/usr/bin/awesome_no_argb"

  install -Dm644 "$srcdir"/$pkgname/awesome.desktop \
    "$pkgdir/usr/share/xsessions/awesome.desktop"

  install -Dm644 "$srcdir"/$pkgname/awesome_no_argb.desktop \
    "$pkgdir/usr/share/xsessions/awesome_no_argb.desktop"

  install -Dm644 "$srcdir"/awesomeksm.desktop \
    "$pkgdir/usr/share/apps/ksmserver/windowmanagers/awesome.desktop"
}
