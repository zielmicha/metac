{fetchgit, ...}:
{
  backplane = fetchgit {
    name = "backplane";
    url = "https://github.com/metacontainer/backplane";
    rev = "81fb10d68fea6f87ddbbb2f80bcbd5ad1409acb2";
    fetchSubmodules = true;
    sha256 = "1fw07qcj3dyq5l6fyscp7snkj2mqls9jv945gxmpkx8dp81x9363";
  };
  channelguard = fetchgit {
    name = "channelguard";
    url = "https://github.com/zielmicha/channelguard";
    rev = "7d7456e6cfd5d886abd387252ab0ec88dba78b71";
    fetchSubmodules = true;
    sha256 = "1555mfapb8pha9n81n25x4r86c3wkbp1rb21lphxfzfys6jv7xwd";
  };
  cligen = fetchgit {
    name = "cligen";
    url = "https://github.com/metacontainer/cligen";
    rev = "b1b4267122d7d1a6b34d422fe306d78bb32cc251";
    fetchSubmodules = true;
    sha256 = "0x7751a2q5dnhzsr63d1q9jnzavsxvh3lqr11ddwcmqyb6zjgc4l";
  };
  collections = fetchgit {
    name = "collections";
    url = "https://github.com/zielmicha/collections.nim";
    rev = "a6b3a024c95390adb6d95549471b14af9a515efc";
    fetchSubmodules = true;
    sha256 = "0xrzgr51dw1hjcnksvb1j8bkx4sw9v3bgvgmw726qapnd1kjck1k";
  };
  reactor = fetchgit {
    name = "reactor";
    url = "https://github.com/zielmicha/reactor.nim";
    rev = "698ac0645e12f3cac34ba2523248d7d2781f613a";
    fetchSubmodules = true;
    sha256 = "0cwqmac77lsmpl5znwm2jap4gc2f6zgyjjz5l54mp669jcchvvyx";
  };
  sctp = fetchgit {
    name = "sctp";
    url = "https://github.com/metacontainer/sctp.nim";
    rev = "fe0438d989b1d6fa12ac0a8bd9eb9ac9699b3b1b";
    fetchSubmodules = true;
    sha256 = "10db9zv1p26qq6myqc3d7ldbwisfa8rr162g6j6dbw4349adjxa9";
  };
  sodium = fetchgit {
    name = "sodium";
    url = "https://github.com/zielmicha/libsodium.nim";
    rev = "e1c88906d5958ffe56ee2590d34fdc8b2f3a96f5";
    fetchSubmodules = true;
    sha256 = "1ymzrxb0i7fhrzrfbrvpcbbxn7qj0s9sgf2pkraq79gaaghq62z3";
  };
  xrest = fetchgit {
    name = "xrest";
    url = "https://github.com/zielmicha/xrest";
    rev = "6a977ae087d4a7960a148fa55e787ccc26a7bddf";
    fetchSubmodules = true;
    sha256 = "02fg7z2qvl8c6c2krph0qhn603hx2x9l20v1kk7aj17q0k26fr9r";
  };
}
