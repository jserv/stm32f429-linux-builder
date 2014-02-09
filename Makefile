root_dir := $(shell pwd)

uboot_version := u-boot
kernel_version := uclinux
busybox_version := busybox-1.22.1

uboot_dir := $(root_dir)/$(uboot_version)
kernel_dir := $(root_dir)/$(kernel_version)
busybox_dir := $(root_dir)/$(busybox_version)
rootfs_dir := $(root_dir)/rootfs

target_out := $(root_dir)/out
download_dir := $(root_dir)/downloads

uboot_target :=  $(target_out)/uboot/u-boot.bin
kernel_target := $(target_out)/kernel/arch/arm/boot/xipuImage.bin
rootfs_target := $(target_out)/romfs.bin
TARGETS := $(uboot_target) $(kernel_target) $(rootfs_target)

.PHONY: all prepare uboot kernel rootfs
all: prepare stamp-uboot stamp-kernel stamp-rootfs

prepare:

CROSS_COMPILE ?= arm-uclinuxeabi-

ROOTFS_CFLAGS := "-march=armv7-m -mthumb -Wl,-elf2flt=-s -Wl,-elf2flt=16384"

# downloads and temporary output directory
$(shell mkdir -p $(target_out))
$(shell mkdir -p $(download_dir))

# Check cross compiler
filesystem_path := $(shell which ${CROSS_COMPILE}gcc 2>/dev/null)
ifeq ($(strip $(filesystem_path)),)
$(error No uClinux toolchain found)
endif

# Check u-boot
filesystem_path := $(shell ls $(uboot_dir) 2>/dev/null)
ifeq ($(strip $(filesystem_path)),)
$(info *** Fetching u-boot source ***)
$(info $(shell git clone git@github.com:robutest/u-boot.git))
$(info **********************************)
endif

# Check kernel
filesystem_path := $(shell ls $(kernel_dir) 2>/dev/null)
ifeq ($(strip $(filesystem_path)),)
$(info *** Fetching uClinux source ***)
$(info $(shell git clone git@github.com:robutest/uclinux.git))
$(info **********************************)
endif

# Check busybox
filesystem_path := $(shell ls $(busybox_dir) 2>/dev/null)
ifeq ($(strip $(filesystem_path)),)
$(info *** Fetching busybox source ***)
$(info $(shell wget -P downloads -c http://busybox.net/downloads/${busybox_version}.tar.bz2))
$(info $(shell tar -jxf downloads/${busybox_version}.tar.bz2 -C $(root_dir)))
$(info **********************************)
endif

# u-boot
stamp-uboot:
	$(MAKE) build-uboot
	touch $@
build-uboot:
	@echo $(uboot_version) $(uboot_config)
	$(shell mkdir -p ${target_out}/uboot)
	env LC_ALL=C make -C $(uboot_dir) \
		ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) \
		O=$(target_out)/uboot \
		stm32429-disco

uboot_clean:
	rm -rf $(target_out)/uboot stamp-uboot

# Linux kernel
stamp-kernel:
	$(MAKE) build-kernel
	touch $@
build-kernel: $(target_out)/uboot/tools/mkimage
	$(shell mkdir -p ${target_out}/kernel)
	cp -f configs/kernel_config $(target_out)/kernel/.config
	env PATH=$(target_out)/uboot:$(PATH) make -C $(kernel_dir) \
		ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) \
		O=$(target_out)/kernel oldconfig xipImage
	cat $(kernel_dir)/arch/arm/boot/tempfile \
	    $(target_out)/kernel/arch/arm/boot/xipImage > $(target_out)/kernel/arch/arm/boot/xipImage.bin
	$(target_out)/uboot/tools/mkimage \
		-x -A arm -O linux -T kernel -C none \
		-a 0x08020040 -e 0x08020041 \
		-n "Linux-2.6.33-arm1" \
		-d $(target_out)/kernel/arch/arm/boot/xipImage.bin \
		$(target_out)/kernel/arch/arm/boot/xipuImage.bin

kernel_clean:
	rm -rf $(target_out)/kernel stamp-kernel

# Root file system
stamp-rootfs:
	$(MAKE) build-rootfs
	touch $@
build-rootfs: busybox $(rootfs_target)

busybox:
	$(shell mkdir -p ${target_out}/busybox)
	$(shell mkdir -p ${target_out}/romfs)
	cp -f configs/busybox_config $(target_out)/busybox/.config
	make -C $(busybox_dir) \
		O=$(target_out)/busybox oldconfig
	make -C $(target_out)/busybox \
		ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) \
		CFLAGS=$(ROOTFS_CFLAGS) SKIP_STRIP=y \
		CONFIG_PREFIX=$(target_out)/romfs install

$(rootfs_target): $(rootfs_dir)
	cp -af $(rootfs_dir)/* $(target_out)/romfs
	cd $(target_out) && genromfs -v \
		-V "ROM Disk" \
		-f romfs.bin \
		-d $(target_out)/romfs 2> $(target_out)/romfs.map

rootfs_clean:
	rm -rf $(target_out)/busybox $(target_out)/romfs stamp-rootfs

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
