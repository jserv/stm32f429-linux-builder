root_dir := $(shell pwd)

include configs/sources

include mk/defs.mak

uboot_target :=  $(target_out)/uboot/u-boot.bin
kernel_target := $(target_out)/kernel/arch/arm/boot/xipuImage.bin
rootfs_target := $(target_out)/romfs.bin

# toolchain configurations
CROSS_COMPILE ?= arm-uclinuxeabi-
ROOTFS_CFLAGS := "-march=armv7-m -mtune=cortex-m4 \
-mlittle-endian -mthumb \
-Os -ffast-math \
-ffunction-sections -fdata-sections \
-Wl,--gc-sections \
-fno-common \
--param max-inline-insns-single=1000 \
-Wl,-elf2flt=-s -Wl,-elf2flt=16384"

.PHONY: all prepare uboot kernel rootfs
all: prepare stamp-uboot stamp-kernel stamp-rootfs

prepare:

include mk/download.mak

# u-boot
stamp-uboot:
	$(MAKE) build-uboot
	touch $@
include mk/uboot.mak
clean-uboot:
	rm -rf $(target_out)/uboot stamp-uboot

# Linux kernel
stamp-kernel:
	$(MAKE) build-kernel
	touch $@
include mk/kernel.mak
clean-kernel:
	rm -rf $(target_out_kernel) stamp-kernel

# Root file system
stamp-rootfs:
	$(MAKE) build-rootfs
	touch $@
include mk/rootfs.mak
clean-rootfs:
	rm -rf $(target_out_busybox) $(target_out_romfs) stamp-rootfs

.PHONY += install
include mk/flash.mak
install: $(TARGETS)
	$(shell ${FLASH_CMD})

.PHONY += clean
clean: clean-uboot clean-kernel clean-rootfs
	rm -rf $(target_out)

.PHONY += distclean
distclean: clean
	rm -rf $(uboot_dir) $(kernel_dir) $(busybox_dir) $(download_dir)

.PHONY += help
help:
	@echo "Avaialble commands:"
	@echo
	@echo "build the u-boot:"
	@echo "    make build-uboot; make clean-uboot"
	@echo
	@echo "build the Linux kernel:"
	@echo "    make build-kernel; make clean-kernel"
	@echo
	@echo "build the root file system:"
	@echo "    make build-rootfs; make clean-rootfs"
	@echo
	@echo "clean the targets:"
	@echo "    make clean"
	@echo
	@echo "flash images to STM32F429 Discovery"
	@echo "    make install"
