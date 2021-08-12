BUSYBOX_VSN = 1.33.1
LINUX_VSN = 5.13.10
SEDUTIL_VSN = 1.15.1.01

checksum:
	sha256sum -c SHA256

fetch:	\
	_dl	\
	_dl/busybox-$(BUSYBOX_VSN).tar.bz2	\
	_dl/linux-$(LINUX_VSN).tar.xz	\
	_dl/sedutil-$(SEDUTIL_VSN).tar.gz

_build _dl _target:
	test -d /tmp/$@ || mkdir /tmp/$@
	ln -s /tmp/$@ $@

###########
# busybox #
###########

_dl/busybox-$(BUSYBOX_VSN).tar.bz2:
	wget -O $@ https://busybox.net/downloads/$(@F)

_build/busybox:
	tar -jxf _dl/busybox-$(BUSYBOX_VSN).tar.bz2 --strip-components=1 -C $@

#########
# linux #
#########

_dl/linux-$(LINUX_VSN).tar.xz:
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v5.x/$(@F)

###########
# sedutil #
###########

_dl/sedutil-$(SEDUTIL_VSN).tar.gz:
	wget -O $@ https://github.com/Drive-Trust-Alliance/sedutil/archive/refs/tags/$(SEDUTIL_VSN).tar.gz

_build/sedutil:
	tar -zxf _dl/sedutil-$(SEDUTIL_VSN).tar.gz --strip-components=1 -C $@

_build/sedutil/config.h:
	cd $(@D) &&	\
	autoreconf -v -i &&	\
	LDFLAGS='-static -static-libgcc -static-libstdc++'	\
		./configure --prefix=/usr --sysconfdir=/etc	\
			--mandir=/usr/share/man --infodir=/usr/share/info	\
			--localstatedir=/var
