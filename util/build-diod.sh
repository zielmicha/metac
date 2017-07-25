cd third-party/diod
gcc -fsanitize=null -O2 -g -flto -fPIE -fstack-protector-strong -DHAVE_GETOPT_H -DHAVE_GETOPT_LONG -D_FORTIFY_SOURCE=2 -DMETA_ALIAS='"diod-metac"' -D_GNU_SOURCE -I libnpclient -I libnpfs -I liblsd -I libdiod -DX_LOCALSTATEDIR='""' -Wall diod/diod.c diod/exp.c diod/fid.c diod/ioctx.c diod/ops.c diod/xattr.c libnpclient/chmod.c libnpclient/fid.c libnpclient/fsys.c libnpclient/mkdir.c libnpclient/mount.c libnpclient/mtfsys.c libnpclient/open.c libnpclient/pool.c libnpclient/read.c libnpclient/readdir.c libnpclient/remove.c libnpclient/stat.c libnpclient/walk.c libnpclient/write.c libnpclient/xattr.c liblsd/error.c liblsd/hash.c liblsd/hostlist.c liblsd/list.c liblsd/thread.c libnpfs/conn.c libnpfs/ctl.c libnpfs/error.c libnpfs/fcall.c libnpfs/fdtrans.c libnpfs/fidpool.c libnpfs/fmt.c libnpfs/np.c libnpfs/npstring.c libnpfs/srv.c libnpfs/trans.c libnpfs/user.c libdiod/diod_auth.c libdiod/diod_conf.c libdiod/diod_log.c libdiod/diod_sock.c -pthread -o ../../build/metac-diod
