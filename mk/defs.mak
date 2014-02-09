uboot_dir := $(root_dir)/$(uboot_version)
kernel_dir := $(root_dir)/$(kernel_version)
busybox_dir := $(root_dir)/$(busybox_version)
rootfs_dir := $(root_dir)/rootfs

target_out := $(root_dir)/out
download_dir := $(root_dir)/downloads

TARGETS := $(uboot_target) $(kernel_target) $(rootfs_target)

target_out_uboot := $(target_out)/uboot
target_out_kernel := $(target_out)/kernel
target_out_busybox := $(target_out)/busybox
target_out_romfs := $(target_out)/romfs
