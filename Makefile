root_dir := $(shell pwd)

include configs/sources

include mk/defs.mak

uboot_target :=  $(target_out)/uboot/u-boot.bin
kernel_target := $(target_out)/kernel/arch/arm/boot/xipuImage.bin
rootfs_target := $(target_out)/romfs.bin

# toolchain configurations
CROSS_COMPILE ?= arm-uclinuxeabi-
ROOTFS_CFLAGS := "-march=armv7-m -mthumb -Wl,-elf2flt=-s -Wl,-elf2flt=16384"

.PHONY: all prepare uboot kernel rootfs
all: prepare stamp-uboot stamp-kernel stamp-rootfs

prepare:

include mk/download.mak

# u-boot
stamp-uboot:
	$(MAKE) build-uboot
	touch $@
include mk/uboot.mak
uboot_clean:
	rm -rf $(target_out)/uboot stamp-uboot

# Linux kernel
stamp-kernel:
	$(MAKE) build-kernel
	touch $@
include mk/kernel.mak
kernel_clean:
	rm -rf $(target_out_kernel) stamp-kernel

# Root file system
stamp-rootfs:
	$(MAKE) build-rootfs
	touch $@
include mk/rootfs.mak
rootfs_clean:
	rm -rf $(target_out_busybox) $(target_out_romfs) stamp-rootfs

.PHONY += install
install: $(TARGETS)
	openocd \
		-f interface/stlink-v2.cfg \
		-f target/stm32f4x_stlink.cfg \
		-c "init" \
		-c "reset init" \
        	-c "flash probe 0" \
	        -c "flash info 0" \
		-c "flash write_image erase $(uboot_target)  0x08000000" \
		-c "flash write_image erase $(kernel_target) 0x08020000" \
		-c "flash write_image erase $(rootfs_target) 0x08120000" \
		-c "reset run" -c shutdown

.PHONY += clean
clean: uboot_clean kernel_clean rootfs_clean
	rm -rf $(target_out)

.PHONY += distclean
distclean: clean
	rm -rf $(uboot_dir) $(kernel_dir) $(busybox_dir) $(download_dir)

.PHONY += help
help:
	@echo "Avaialble commands:"
	@echo
	@echo "build the u-boot:"
	@echo "    make build-uboot; make uboot_clean"
	@echo
	@echo "build the Linux kernel:"
	@echo "    make build-kernel; make kernel_clean"
	@echo
	@echo "build the root file system:"
	@echo "    make build-rootfs; make rootfs_clean"
	@echo
	@echo "clean the targets:"
	@echo "    make clean"
	@echo
	@echo "flash images to STM32F429 Discovery"
	@echo "    make install"
