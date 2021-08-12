BUSYBOX_VSN = 1.33.1
LINUX_VSN = 5.13.10
SEDUTIL_VSN = 1.15.1.01

checksum:
	sha256sum -c SHA256

fetch:	\
	dl/busybox-$(BUSYBOX_VSN).tar.bz2	\
	dl/linux-$(LINUX_VSN).tar.xz	\
	dl/sedutil-$(SEDUTIL_VSN).tar.gz

dl:
	ln -s /tmp $@

dl/busybox-$(BUSYBOX_VSN).tar.bz2: dl
	wget -O $@ https://busybox.net/downloads/$(@F)

dl/sedutil-$(SEDUTIL_VSN).tar.gz: dl
	wget -O $@ https://github.com/Drive-Trust-Alliance/sedutil/archive/refs/tags/$(SEDUTIL_VSN).tar.gz

dl/linux-$(LINUX_VSN).tar.xz: dl
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v5.x/$(@F)
