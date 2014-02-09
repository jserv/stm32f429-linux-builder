build-kernel: $(target_out_uboot)/tools/mkimage
	$(shell mkdir -p ${target_out_kernel})
	cp -f configs/kernel_config $(target_out)/kernel/.config
	env PATH=$(target_out_uboot)/tools:$(PATH) make -C $(kernel_dir) \
		ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) \
		O=$(target_out_kernel) oldconfig xipImage modules
	cat $(kernel_dir)/arch/arm/boot/tempfile \
	    $(target_out_kernel)/arch/arm/boot/xipImage > $(target_out_kernel)/arch/arm/boot/xipImage.bin
	$< -x -A arm -O linux -T kernel -C none \
		-a 0x08020040 -e 0x08020041 \
		-n "Linux-2.6.33-arm1" \
		-d $(target_out_kernel)/arch/arm/boot/xipImage.bin \
		$(target_out_kernel)/arch/arm/boot/xipuImage.bin
