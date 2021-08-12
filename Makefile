BUSYBOX_VSN = 1.33.1
LINUX_VSN = 5.13.10
SEDUTIL_VSN = 1.15.1.01

build:	\
	_build/sedutil/sedutil-cli

checksum:
	sha256sum -c SHA256

configure:	\
	_build/busybox/.config	\
	_build/sedutil/config.h

extract:	\
	_build	\
	_build/busybox	\
	_build/linux	\
	_build/sedutil

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
	mkdir $@
	tar -jxf _dl/busybox-$(BUSYBOX_VSN).tar.bz2 --strip-components=1 -C $@

_build/busybox/.config:
	make -C $(@D) defconfig
	sed -i 's|# CONFIG_STATIC is not set|CONFIG_STATIC=y|' $@

#########
# linux #
#########

_dl/linux-$(LINUX_VSN).tar.xz:
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v5.x/$(@F)

_build/linux:
	mkdir $@
	tar -Jxf _dl/linux-$(LINUX_VSN).tar.xz --strip-components=1 -C $@

###########
# sedutil #
###########

_dl/sedutil-$(SEDUTIL_VSN).tar.gz:
	wget -O $@ https://github.com/Drive-Trust-Alliance/sedutil/archive/refs/tags/$(SEDUTIL_VSN).tar.gz

_build/sedutil:
	mkdir $@
	tar -zxf _dl/sedutil-$(SEDUTIL_VSN).tar.gz --strip-components=1 -C $@

_build/sedutil/config.h:
	cd $(@D) &&	\
	autoreconf -v -i &&	\
	LDFLAGS='-static -static-libgcc -static-libstdc++'	\
		./configure --prefix=/usr --sysconfdir=/etc	\
			--mandir=/usr/share/man --infodir=/usr/share/info	\
			--localstatedir=/var

_build/sedutil/sedutil-cli:
	make -C $(@D) -j
	strip $@
