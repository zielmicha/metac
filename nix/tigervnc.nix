{pkgs}:

with pkgs;
with {
  fontDirectories = [ xorg.fontadobe75dpi xorg.fontmiscmisc xorg.fontcursormisc xorg.fontbhlucidatypewriter75dpi ];
};
with stdenv.lib;

stdenv.mkDerivation rec {
  version = "1.9.0";
  name = "tigervnc-${version}";

  src = fetchFromGitHub {
    owner = "TigerVNC";
    repo = "tigervnc";
    sha256 = "0b47fg3741qs3zdpl2zr0s6jz46dypp2j6gqrappbzm3ywnnmm1x";
    rev = "v1.9.0";
  };

  inherit fontDirectories;

  dontUseCmakeBuildDir = true;

  # TODO: we sould probably ship xkb?
  # TODO: also ship swrast_dri.so
  postBuild = ''
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error=int-to-pointer-cast -Wno-error=pointer-to-int-cast"
    export CXXFLAGS="$CXXFLAGS -fpermissive"
    # Build Xvnc
    tar xf ${xorg.xorgserver.src}
    cp -R xorg*/* unix/xserver
    pushd unix/xserver
    version=$(echo ${xorg.xorgserver.name} | sed 's/.*-\([0-9]\+\).\([0-9]\+\).*/\1\2/g')
    patch -p1 < ${src}/unix/xserver$version.patch
    autoreconf -vfi
    ./configure $configureFlags  --disable-devel-docs --disable-docs \
        --disable-xorg --disable-xnest --disable-xvfb --disable-dmx \
        --disable-xwin --disable-xephyr --disable-kdrive --with-pic \
        --disable-xorgcfg --disable-xprint --disable-static \
        --enable-composite --disable-xtrap --enable-xcsecurity \
        --disable-{a,c,m}fb \
        --disable-xwayland \
        --disable-config-dbus --disable-config-udev --disable-config-hal \
        --disable-xevie \
        --disable-dri --disable-dri2 --disable-dri3 --enable-glx \
        --enable-install-libxf86config \
        --prefix="$out" --disable-unit-tests \
        --with-xkb-path=/usr/share/X11/xkb \
        --with-xkb-bin-directory=/usr/bin \
        --with-xkb-output=$out/share/X11/xkb/compiled
    make TIGERVNC_SRCDIR=`pwd`/../..
    make -C hw/vnc TIGERVNC_SRCDIR=`pwd`/../..
    popd
  '';

  postInstall = ''
    pushd unix/xserver/hw/vnc
    make TIGERVNC_SRCDIR=`pwd`/../../../.. install
    popd
    rm -f $out/lib/xorg/protocol.txt

    wrapProgram $out/bin/vncserver \
      --prefix PATH : ${stdenv.lib.makeBinPath (with xorg; [ xterm twm xsetroot ]) }
  '';

  buildInputs = with xorg; [
    libjpeg_turbo fltk pixman
    pam nettle
    fixesproto damageproto compositeproto randrproto
    xcmiscproto bigreqsproto randrproto renderproto
    fontsproto videoproto scrnsaverproto resourceproto presentproto
    utilmacros libXtst libXext libX11 libXext libICE libXi libSM libXft
    libxkbfile libXfont2 libpciaccess xineramaproto
    glproto libGLU
  ] ++ xorgserver.buildInputs;

  nativeBuildInputs = with xorg; [ cmake zlib gettext libtool utilmacros fontutil makeWrapper ]
    ++ xorg.xorgserver.nativeBuildInputs;

  propagatedNativeBuildInputs = xorg.xorgserver.propagatedNativeBuildInputs;

  enableParallelBuilding = true;

  meta = {
    homepage = http://www.tigervnc.org/;
    license = stdenv.lib.licenses.gpl2Plus;
    description = "Fork of tightVNC, made in cooperation with VirtualGL";
    maintainers = with stdenv.lib.maintainers; [viric];
    platforms = with stdenv.lib.platforms; linux;
    # Prevent a store collision.
    priority = 4;
  };
}
