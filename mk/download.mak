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
$(info $(shell ${FETCH_CMD_uboot}))
endif

# Check kernel
filesystem_path := $(shell ls $(kernel_dir) 2>/dev/null)
ifeq ($(strip $(filesystem_path)),)
$(info *** Fetching uClinux source ***)
$(info $(shell ${FETCH_CMD_kernel}))
endif

# Check busybox
filesystem_path := $(shell ls $(busybox_dir) 2>/dev/null)
ifeq ($(strip $(filesystem_path)),)
$(info *** Fetching busybox source ***)
$(info $(shell ${FETCH_CMD_busybox}))
$(info $(shell tar -jxf downloads/${busybox_version}.tar.bz2 -C $(root_dir)))
endif
