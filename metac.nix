with (let
      # Pin a revision from Nixpkgs repo for reproducible builds.
      _nixpkgs = import <nixpkgs> { };
      repo = _nixpkgs.fetchFromGitHub { owner = "NixOS"; repo = "nixpkgs"; rev = "849b5a5193be4c3e61af53e8db5bdb9d95b2074f"; sha256 = "1i1fhllx7k115zzjj0vf3qrmkp52icq2hb33qg5jig52vqk8ij6g"; };
      in import repo) {};

rec {
  fullDiod = stdenv.mkDerivation rec {
    name = "diod";
    env = buildEnv { name = name; paths = []; };
    buildInputs = [autoconf libtool automake perl ncurses];
    src = ./third-party/diod;
    preConfigurePhases = ["autogen"];
    autogen = "./autogen.sh";
  };

  diod = stdenv.mkDerivation rec {
    name = "diod";
    env = buildEnv { name = name; paths = []; };
    buildInputs = [clang stdenv.glibc.static];
    src = ./third-party/diod;
    buildPhase = ''clang ${cFlags} -static -O2 -flto -fPIE -fstack-protector-strong -DHAVE_GETOPT_H -DHAVE_GETOPT_LONG -D_FORTIFY_SOURCE=2 -DMETA_ALIAS='"diod-metac"' -D_GNU_SOURCE -I libnpclient -I libnpfs -I liblsd -I libdiod -DX_LOCALSTATEDIR='""' -Wall diod/diod.c diod/exp.c diod/fid.c diod/ioctx.c diod/ops.c diod/xattr.c libnpclient/chmod.c libnpclient/fid.c libnpclient/fsys.c libnpclient/mkdir.c libnpclient/mount.c libnpclient/mtfsys.c libnpclient/open.c libnpclient/pool.c libnpclient/read.c libnpclient/readdir.c libnpclient/remove.c libnpclient/stat.c libnpclient/walk.c libnpclient/write.c libnpclient/xattr.c liblsd/error.c liblsd/hash.c liblsd/hostlist.c liblsd/list.c liblsd/thread.c libnpfs/conn.c libnpfs/ctl.c libnpfs/error.c libnpfs/fcall.c libnpfs/fdtrans.c libnpfs/fidpool.c libnpfs/fmt.c libnpfs/np.c libnpfs/npstring.c libnpfs/srv.c libnpfs/trans.c libnpfs/user.c libdiod/diod_auth.c libdiod/diod_conf.c libdiod/diod_log.c libdiod/diod_sock.c -pthread -o diod-server ${ldFlags} '';
    installPhase = ''mkdir -p $out/bin; cp diod-server $out/bin'';
  };

  vmKernel = buildLinux rec {
    version = "4.4.76";
    src = fetchurl {
      url = "mirror://kernel/linux/kernel/v4.x/linux-${version}.tar.xz";
      sha256 = "180mngyar7ky2aiaszmgfqpfvwi0kxcym8j3ifflzggwqjkgrrki";
    };
    configfile = ./kernel-config;
    # we need the following, or build will fail during postInstall phase
    config = { CONFIG_MODULES = "y"; CONFIG_FW_LOADER = "m"; };
  };

  localDeps = {
    reactor = ../reactor;
    capnp = ../capnp;
    collections = ../collections;
    cligen = ../cligen;
    morelinux = ../morelinux;
  };

  nimCsources = stdenv.mkDerivation rec {
    name = "nim-csource";
    buildInputs = [];
    src = fetchurl {
      url = "https://github.com/nim-lang/csources/archive/cdd0f3ff527a6a905fd9e821f381983af45b65de.tar.gz";
      sha256 = "1dmddbayxs4h6a8vwvia85dp6pcq93ijgm260k4j1ib907r6x0fw";
    };
    installPhase = ''
cp bin/nim $out
'';
    enableParallelBuilding = true;
  };

  nimBootstrap = lastNim: stdenv.mkDerivation rec {
    name = "nim";
    buildInputs = [clang];
    srcs = fetchurl {
      url = "https://github.com/nim-lang/nim/archive/8c0e27e.tar.gz";
      sha256 = "0ib7zn0a9jmgig3f903knyba2gj5sakr41srsq7k9dsljyh4g2zq";
    };
    buildPhase = ''
mkdir -p bin
cp ${lastNim} bin/nim
./bin/nim c koch
./koch boot -d:release
'';
    installPhase = ''
install -Dt $out/bin bin/* koch
./koch install $out
mv $out/nim/bin/* $out/bin/ && rmdir $out/nim/bin
mv $out/nim/*     $out/     && rmdir $out/nim
'';
  };

  nim = nimBootstrap nimCsources;

  #cFlags = "-nostdinc -isystem ${musl}/include -ffunction-sections -fdata-sections";
  #ldFlags = "-nostdlib -L${musl}/lib ${musl}/lib/crt1.o ${musl}/lib/crti.o ${musl}/lib/crtn.o -lc -lm -static";

  # musl crashes diod, compile with glibc for now
  cFlags = "-DSTATIC_GLIBC";
  ldFlags = "-static -lm";
  clangMuslNim = ''--passl:"${ldFlags}" --passc:"${cFlags}"'';

  nimArgs = {deps, args}: "${clangMuslNim} --path:${deps.reactor} --path:${deps.collections} --path:${deps.capnp} --path:${deps.collections} --path:${deps.cligen} --path:${deps.morelinux} --path:. --nimcache:nix_nimcache ${args}";

  setupNimProject = options: ''
if find -name nimcache | grep -q '.*'; then
  echo "nimcache exists"
  exit 1
fi
awk '/\[nim\]/,EOF' < ${./nimenv.cfg} | tail -n +2 > nim.cfg
'';

  vmAgent = options: stdenv.mkDerivation rec {
    name = "vm-agent";
    buildInputs = [nim gawk clang_4 stdenv.glibc.static];
    buildPhase = ''
cp -r ${./metac} metac
touch metac.nimble
${setupNimProject options}
echo ${nimArgs options}
nim c ${nimArgs options} --passl:"-static" --out:$out metac/compute_agent.nim
'';
    phases = ["buildPhase"];
  };

  busyboxStatic = (pkgs.busybox.override {
         enableStatic = true;
         extraConfig = ''
           CONFIG_STATIC y
           CONFIG_INSTALL_APPLET_DONT y
           CONFIG_INSTALL_APPLET_SYMLINKS n
         '';
      });

  vmInitrd = options: stdenv.mkDerivation rec {
    name = "vm-initrd.cpio";
    buildInputs = [cpio];
    buildPhase = ''
mkdir -p initrd/bin
cp ${vmAgent options} initrd/bin/init
cp ${busyboxStatic}/bin/busybox initrd/bin/busybox
for name in sh mount ifconfig ip; do
    ln -sf /bin/busybox initrd/bin/$name
done
cp ${sshfs}/bin/sshfs initrd/bin/metac-sshfs
cp ${fuseStatic}/bin/fusermount initrd/bin/fusermount
(cd initrd && find ./ | cpio -H newc -o | gzip > $out)

'';
    phases = ["buildPhase"];
  };

  overrideStatic = pkg: pkg.overrideDerivation (attrs: rec {
    buildInputs = attrs.buildInputs ++ [clang stdenv.glibc.static];
    enableStatic = true;
    preBuild = ''
      makeFlagsArray=(PREFIX="$out"
                      CC="clang"
                      CFLAGS="${cFlags}"
                      LDFLAGS="${ldFlags}")
    '';
  });

  sqliteStatic = overrideStatic pkgs.sqlite;
  glibStatic = overrideStatic pkgs.glib;
  fuseStatic = overrideStatic pkgs.fuse;

  sshfs = stdenv.mkDerivation rec {
    version = "2.9";
    name = "sshfs-fuse-${version}";
    enableStatic = true;

    config = ''/* Name of package */
#define PACKAGE "sshfs"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME "sshfs"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "sshfs 2.9"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "sshfs"

/* Define to the home page for this package. */
#define PACKAGE_URL ""

/* Define to the version of this package. */
#define PACKAGE_VERSION "2.9"

/* Compile ssh NODELAY workaround */
/* #undef SSH_NODELAY_WORKAROUND */

/* Version number of package */
#define VERSION "2.9"

#define IDMAP_DEFAULT "none"
'';

    buildPhase = ''
echo "$config" > config.h
gcc -D_FILE_OFFSET_BITS=64 cache.c sshfs.c -DFUSE_USE_VERSION=26 -D_REENTRANT -I${fuseStatic}/include -I${fuseStatic}/include/fuse -I${glibStatic.dev}/include/glib-2.0 -I${glibStatic}/lib/glib-2.0/include -g -O2 -Wall -W -o sshfs  -L${fuseStatic}/lib -L${glibStatic}/lib -lfuse -lgthread-2.0 -pthread -lglib-2.0 -ldl -static
'';
    installPhase = ''mkdir -p $out/bin; cp sshfs $out/bin'';

    phases = ["unpackPhase" "buildPhase" "installPhase"];

    src = fetchFromGitHub {
      repo = "sshfs";
      owner = "libfuse";
      rev = "sshfs-${version}";
      sha256 = "1n0cq72ps4dzsh72fgfprqn8vcfr7ilrkvhzpy5500wjg88diapv";
    };

    buildInputs = [ pkgconfig glibStatic fuseStatic autoreconfHook stdenv.glibc.static ];
  };

  sftpServer = pkgs.openssh.overrideDerivation (attrs: rec {
    name = "sftp-server";
    buildInputs = attrs.buildInputs ++ [stdenv.glibc.static];
    buildPhase = ''make libssh.a ./openbsd-compat/libopenbsd-compat.a
gcc -o sftp-server ${./metac/sftp-server.c} sftp-common.c -Lopenbsd-compat -L. -I.  -fstack-protector-strong -lssh -lopenbsd-compat -Wl,--gc-sections -static -L${stdenv.glibc.static}/lib'';
    installPhase = ''mkdir -p $out/bin; cp sftp-server $out/bin'';
  });

  metac = options: stdenv.mkDerivation rec {
    name = "metac";
    version = "0.0.1";
    buildInputs = [nim gawk clang_4 sqliteStatic stdenv.glibc.static]; # sqliteStatic
    buildPhase = ''
cp -r ${./metac} metac
cp -r ${./tests} tests
cp ${./metac.nim} metac.nim
touch metac.nimble
${setupNimProject options}
mkdir -p $out/bin/ $out/share/
${./util/install-systemd.sh} $out
cp ${vmInitrd options} $out/share/metac-initrd
cp ${vmKernel}/bzImage $out/share/metac-vmlinuz
#cp {diod}/bin/diod-server $out/bin/metac-diod
cp ${sshfs}/bin/sshfs $out/bin/metac-sshfs
cp ${sftpServer}/bin/sftp-server $out/bin/metac-sftp-server
nim c ${nimArgs options} -d:withSqlite -d:kernelPath="../share/metac-initrd" -d:initrdPath="../share/metac-initrd" --out:$out/bin/metac -d:diodPath="metac-diod" metac/main.nim
'';
    phases = ["buildPhase" "fixupPhase"];
  };

  buildDeb = {pkg, control, postinst}: stdenv.mkDerivation rec {
    name = pkg.name + ".deb";
    buildInputs = [dpkg fakeroot];
    buildPhase = ''
mkdir pkg
cp -a ${pkg} pkg/usr
chmod u+w pkg
mkdir -p pkg/DEBIAN
arch=$(echo $system | cut -d- -f1)
if [ $arch = x86_64 ]; then
  arch=amd64
fi
substituteAll ${control} pkg/DEBIAN/control
cp ${postinst} pkg/DEBIAN/postinst
chmod +x pkg/DEBIAN/postinst
fakeroot -- dpkg-deb --build pkg $out
'';
    phases = ["buildPhase"];
  };

  metacDeb = buildDeb {
    pkg = metacRelease;
    control = writeText "control" ''Package: metac
Version: ${metacDebug.version}
Section: custom
Priority: optional
Architecture: @arch@
Essential: no
Installed-Size: 1024
Maintainer: Michał Zieliński <michal@zielinscy.org.pl>
Description: MetaContainer - decentralized container orchestration
Dependencies: fuse, ipset, iptables
'';
    postinst = writeText "postinst" ''
systemctl daemon-reload
systemctl enable metac.target
systemctl enable metac-bridge
for name in persistence vm fs network computevm; do
    systemctl enable metac-$name
done
'';
  };

  debugOptions = {
    deps = localDeps;
    args = "";
  };

  releaseOptions = {
    deps = localDeps;
    args = "-d:release";
  };

  vmInitrdDebug = vmInitrd debugOptions;
  vmAgentDebug = vmAgent debugOptions;
  metacDebug = metac debugOptions;

  vmAgentRelease = vmAgent releaseOptions;
  metacRelease = metac releaseOptions;
}
