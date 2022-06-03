BUSYBOX_VSN = 1.33.1
LINUX_VSN = 5.13.10
SEDUTIL_VSN = 8364306

all:	\
	fetch-busybox fetch-linux fetch-sedutil	\
	checksum	\
	extract-busybox configure-busybox build-busybox install-busybox	\
	extract-sedutil configure-sedutil build-sedutil install-sedutil	\
	install-overlay	\
	extract-linux configure-linux build-linux	\
	build-image

checksum:
	sha256sum -c SHA256

_build _dl _images _mnt _target:
	mkdir $@

###########
# busybox #
###########

fetch-busybox: _dl _dl/busybox-$(BUSYBOX_VSN).tar.bz2

extract-busybox: _build _build/busybox

configure-busybox: _build/busybox/.config

build-busybox: _build/busybox/busybox

install-busybox: _target _target/bin/busybox

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
	rm _target/linuxrc

#########
# linux #
#########

fetch-linux: _dl _dl/linux-$(LINUX_VSN).tar.xz

extract-linux: _build _build/linux

configure-linux: _build/linux/.config

build-linux: _build/linux/arch/x86_64/boot/bzImage

_dl/linux-$(LINUX_VSN).tar.xz:
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v5.x/$(@F)

_build/linux:
	mkdir $@
	tar -Jxf _dl/linux-$(LINUX_VSN).tar.xz --strip-components=1 -C $@

_build/linux/.config:
	cp linux.config.in $@
	sed -i "s|@INITRAMFS_SOURCE@|$$(readlink -f _target)|" $@

_build/linux/arch/x86_64/boot/bzImage:
	make -C _build/linux -j 4

###########
# sedutil #
###########

fetch-sedutil: _dl _dl/sedutil-$(SEDUTIL_VSN).tar.gz

extract-sedutil: _build _build/sedutil

configure-sedutil: _build/sedutil/config.h

build-sedutil: _build/sedutil/sedutil-cli

install-sedutil: _target _target/usr/sbin/sedutil-cli

_dl/sedutil-$(SEDUTIL_VSN).tar.gz:
	wget -O $@ https://github.com/badicsalex/sedutil/tarball/$(SEDUTIL_VSN)

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

###########
# overlay #
###########

install-overlay: _target _target/init _target/dev _target/dev/console _target/proc _target/sys

_target/init: init
	cp $< $@

_target/dev _target/proc _target/sys:
	mkdir $@

_target/dev/console:
	sudo mknod $@ c 5 1
	sudo chown $(shell id -u):$(shell id -g) $@
	chmod 620 $@

#########
# image #
#########

build-image: _images _images/minpba.img

_images/minpba.img: _mnt
	dd if=/dev/zero of=$@ bs=1M count=34
	(echo 'g'; echo 'n'; echo ''; echo ''; echo ''; echo 't'; echo '1'; echo 'w') | fdisk $@
	sudo losetup -P -v /dev/loop1 $@
	sudo mkfs.vfat -v -F 32 /dev/loop1p1
	sudo mount /dev/loop1p1 _mnt
	sudo chmod 777 _mnt
	sudo mkdir -p _mnt/efi/boot
	sudo cp _build/linux/arch/x86_64/boot/bzImage _mnt/efi/boot/bootx64.efi
	sudo umount _mnt
	sudo losetup -d /dev/loop1
