BUSYBOX_VSN = 1.33.1
LINUX_VSN = 5.13.10
SEDUTIL_VSN = 1.15.1.01

build:	\
	_build/busybox/busybox	\
	_build/sedutil/sedutil-cli	\
	_build/linux/arch/x86_64/boot/bzImage

checksum:
	sha256sum -c SHA256

configure:	\
	_build/busybox/.config	\
	_build/sedutil/config.h	\
	_build/linux/.config

extract:	\
	_build	\
	_build/busybox	\
	_build/sedutil	\
	_build/linux

fetch:	\
	_dl	\
	_dl/busybox-$(BUSYBOX_VSN).tar.bz2	\
	_dl/sedutil-$(SEDUTIL_VSN).tar.gz	\
	_dl/linux-$(LINUX_VSN).tar.xz

install:	\
	_target	\
	_target/bin/busybox	\
	_target/usr/sbin/sedutil-cli

_build _dl _images _target:
	mkdir $@

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

_build/busybox/busybox:
	make -C $(@D) -j 4

_target/bin/busybox:
	make CONFIG_PREFIX=$$(readlink -f _target) -C _build/busybox install
	cp _build/busybox/busybox $@

#########
# linux #
#########

_dl/linux-$(LINUX_VSN).tar.xz:
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v5.x/$(@F)

_build/linux:
	mkdir $@
	tar -Jxf _dl/linux-$(LINUX_VSN).tar.xz --strip-components=1 -C $@

_build/linux/.config:
	cp linux.config $@

_build/linux/arch/x86_64/boot/bzImage:
	make -C $(@D) -j 4

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
	make -C $(@D) -j 4
	strip $@

_target/usr/sbin/sedutil-cli:
	mkdir -p $(@D)
	cp _build/sedutil/sedutil-cli $@

##############
# filesystem #
##############

_images/rootfs.cpio:
	cd _target && find . -depth | sort | cpio -o -v -H newc > ../$@

_images/rootfs.cpio.gz:
	gzip -9 _images/rootfs.cpio

_images/minpba.img:
	dd if=/dev/zero of=$@ bs=1M count=8
	(echo 'n'; echo ''; echo ''; echo ''; echo 'ef00'; echo 'w'; echo 'Y') | gdisk $@
	sudo losetup --show -o 1048576 /dev/loop1 $@
	sudo mkfs.vfat -n UEFI64 /dev/loop1
	sudo mkdir $@-mount
	sudo mount /dev/loop1 $@-mount
	sudo chmod 777 $@-mount
	sudo mkdir -p $@-mount/EFI/minpba
	sudo cp _build/linux/arch/x86_64/boot/bzImage $@-mount/EFI/minpba
	sudo umount $@-mount
	sudo losetup -d /dev/loop1

_images/minpba.img.gz:
	gzip -9 _images/minpba.img
