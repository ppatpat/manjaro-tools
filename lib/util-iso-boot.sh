#!/bin/bash
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

download_efi_shellv2(){
	curl -k -o $1/shellx64_v2.efi https://svn.code.sf.net/p/edk2/code/trunk/edk2/ShellBinPkg/UefiShell/X64/Shell.efi
}

download_efi_shellv1(){
	curl -k -o $1/shellx64_v1.efi https://svn.code.sf.net/p/edk2/code/trunk/edk2/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
}

copy_efi_shells(){
	if [[ -f ${PKGDATADIR}/efi_shell/shellx64_v1.efi ]];then
		msg2 "Copying shellx64_v1.efi ..."
		cp ${PKGDATADIR}/efi_shell/shellx64_v1.efi $1/
	else
		download_efi_shellv1 "$1"
	fi
	if [[ -f ${PKGDATADIR}/efi_shell/shellx64_v2.efi ]];then
		msg2 "Copying shellx64_v2.efi ..."
		cp ${PKGDATADIR}/efi_shell/shellx64_v2.efi $1/
	else
		download_efi_shellv2 "$1"
	fi
}

# $1: work_dir
gen_boot_image(){
	local _kernver=$(cat $1/usr/lib/modules/*/version)
	chroot-run $1 \
		/usr/bin/mkinitcpio -k ${_kernver} \
		-c /etc/mkinitcpio-${iso_name}.conf \
		-g /boot/${iso_name}.img
}

copy_efi_loaders(){
	msg2 "Copying efi loaders ..."
	cp $1/usr/lib/prebootloader/PreLoader.efi $2/bootx64.efi
	cp $1/usr/lib/prebootloader/HashTool.efi $2/
	cp $1/usr/lib/gummiboot/gummibootx64.efi $2/loader.efi
}

copy_boot_images(){
	msg2 "Copying boot images ..."
	cp $1/x86_64/${iso_name} $2/${iso_name}.efi
	cp $1/x86_64/${iso_name}.img $2/${iso_name}.img
	if [[ -f $1/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		cp $1/intel_ucode.img $2/intel_ucode.img
	fi
}

copy_initcpio(){
	msg2 "Copying initcpio ..."
	cp /usr/lib/initcpio/hooks/miso* $1/usr/lib/initcpio/hooks
	cp /usr/lib/initcpio/install/miso* $1/usr/lib/initcpio/install
	cp mkinitcpio.conf $1/etc/mkinitcpio-${iso_name}.conf
}

write_loader_conf(){
	local fn=loader.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo 'timeout 3' > ${conf}
	echo "default ${iso_name}-${arch}" >> ${conf}
}

write_efi_shellv1_conf(){
	local fn=uefi-shell-v1-${arch}.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "title  UEFI Shell ${arch} v1" > ${conf}
	echo "efi    /EFI/shellx64_v1.efi" >> ${conf}
}

write_efi_shellv2_conf(){
	local fn=uefi-shell-v2-${arch}.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "title  UEFI Shell ${arch} v2" > ${conf}
	echo "efi    /EFI/shellx64_v2.efi" >> ${conf}
}

write_dvd_conf(){
	local fn=${iso_name}-${arch}.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "title   ${dist_name} Linux ${arch} UEFI DVD (default)" > ${conf}
	echo "linux   /EFI/miso/${iso_name}.efi" >> ${conf}
	if [[ -f ${path_iso}/${iso_name}/boot/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		echo "initrd  /EFI/miso/intel_ucode.img" >> ${conf}
	fi
	echo "initrd  /EFI/miso/${iso_name}.img" >> ${conf}
	echo "options misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=1 i915.modeset=1 radeon.modeset=1 logo.nologo overlay=free" >> ${conf}
}

write_dvd_nonfree_conf(){
	local fn=${iso_name}-${arch}-nonfree.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "title   ${dist_name} Linux ${arch} UEFI DVD (nonfree)" > ${conf}
	echo "linux   /EFI/miso/${iso_name}.efi" >> ${conf}
	if [[ -f ${path_iso}/${iso_name}/boot/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		echo "initrd  /EFI/miso/intel_ucode.img" >> ${conf}
	fi
	echo "initrd  /EFI/miso/${iso_name}.img" >> ${conf}
	echo "options misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=1 i915.modeset=1 radeon.modeset=1 logo.nologo overlay=nonfree nonfree=yes" >> ${conf}
}

write_usb_conf(){
	local fn=${iso_name}-${arch}.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "title   ${dist_name} Linux ${arch} UEFI USB (default)" > ${conf}
	echo "linux   /${iso_name}/boot/${arch}/${iso_name}" >> ${conf}
	if [[ -f ${path_iso}/${iso_name}/boot/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		echo "initrd  /${iso_name}/boot/intel_ucode.img" >> ${conf}
	fi
	echo "initrd  /${iso_name}/boot/${arch}/${iso_name}.img" >> ${conf}
	echo "options misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=1 i915.modeset=1 radeon.modeset=1 logo.nologo overlay=free" >> ${conf}
}

write_usb_nonfree_conf(){
	local fn=${iso_name}-${arch}-nonfree.conf
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "title   ${dist_name} Linux ${arch} UEFI USB (nonfree)" > ${conf}
	echo "linux   /${iso_name}/boot/${arch}/${iso_name}" >> ${conf}
	if [[ -f ${path_iso}/${iso_name}/boot/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		echo "initrd  /${iso_name}/boot/intel_ucode.img" >> ${conf}
	fi
	echo "initrd  /${iso_name}/boot/${arch}/${iso_name}.img" >> ${conf}
	echo "options misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=1 i915.modeset=1 radeon.modeset=1 logo.nologo overlay=nonfree nonfree=yes" >> ${conf}
}

copy_isolinux_bin(){
	if [[ -e $1/usr/lib/syslinux/bios ]]; then
		msg2 "Copying isolinux bios binaries ..."
		cp $1/usr/lib/syslinux/bios/isolinux.bin $2
		cp $1/usr/lib/syslinux/bios/isohdpfx.bin $2
		cp $1/usr/lib/syslinux/bios/ldlinux.c32 $2
		cp $1/usr/lib/syslinux/bios/gfxboot.c32 $2
		cp $1/usr/lib/syslinux/bios/whichsys.c32 $2
		cp $1/usr/lib/syslinux/bios/mboot.c32 $2
		cp $1/usr/lib/syslinux/bios/hdt.c32 $2
		cp $1/usr/lib/syslinux/bios/chain.c32 $2
		cp $1/usr/lib/syslinux/bios/libcom32.c32 $2
		cp $1/usr/lib/syslinux/bios/libmenu.c32 $2
		cp $1/usr/lib/syslinux/bios/libutil.c32 $2
		cp $1/usr/lib/syslinux/bios/libgpl.c32 $2
	else
		msg2 "Copying isolinux binaries ..."
		cp $1/usr/lib/syslinux/isolinux.bin $2
		cp $1/usr/lib/syslinux/isohdpfx.bin $2
		cp $1/usr/lib/syslinux/gfxboot.c32 $2
		cp $1/usr/lib/syslinux/whichsys.c32 $2
		cp $1/usr/lib/syslinux/mboot.c32 $2
		cp $1/usr/lib/syslinux/hdt.c32 $2
		cp $1/usr/lib/syslinux/chain.c32 $2
	fi
}

write_isolinux_cfg(){
	local fn=isolinux.cfg
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "default start" > ${conf}
	echo "implicit 1" >> ${conf}
	echo "display isolinux.msg" >> ${conf}
	echo "ui gfxboot bootlogo isolinux.msg" >> ${conf}
	echo "prompt   1" >> ${conf}
	echo "timeout  200" >> ${conf}
	echo '' >> ${conf}
	echo "label start" >> ${conf}
	echo "  kernel /${iso_name}/boot/${arch}/${iso_name}" >> ${conf}
	if [[ -f ${path_iso}/${iso_name}/boot/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		echo "  append initrd=/${iso_name}/boot/intel_ucode.img,/${iso_name}/boot/${arch}/${iso_name}.img misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=1 i915.modeset=1 radeon.modeset=1 logo.nologo overlay=free quiet splash showopts" >> ${conf}
	else
		echo "  append initrd=/${iso_name}/boot/${arch}/${iso_name}.img misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=1 i915.modeset=1 radeon.modeset=1 logo.nologo overlay=free quiet splash showopts" >> ${conf}
	fi
	echo '' >> ${conf}
	echo "label nonfree" >> ${conf}
	echo "  kernel /${iso_name}/boot/${arch}/${iso_name}" >> ${conf}
	if [[ -f ${path_iso}/${iso_name}/boot/intel_ucode.img ]] ; then
		msg2 "Using intel_ucode.img ..."
		echo "  append initrd=/${iso_name}/boot/intel_ucode.img,/${iso_name}/boot/${arch}/${iso_name}.img misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=0 i915.modeset=1 radeon.modeset=0 nonfree=yes logo.nologo overlay=nonfree quiet splash showopts" >> ${conf}
	else
		echo "  append initrd=/${iso_name}/boot/${arch}/${iso_name}.img misobasedir=${iso_name} misolabel=${iso_label} nouveau.modeset=0 i915.modeset=1 radeon.modeset=0 nonfree=yes logo.nologo overlay=nonfree quiet splash showopts" >> ${conf}
	fi
	echo '' >> ${conf}
	echo "label harddisk" >> ${conf}
	echo "  com32 whichsys.c32" >> ${conf}
	echo "  append -iso- chain.c32 hd0" >> ${conf}
	echo '' >> ${conf}
	echo "label hdt" >> ${conf}
	echo "  kernel hdt.c32" >> ${conf}
	echo '' >> ${conf}
	echo "label memtest" >> ${conf}
	echo "  kernel memtest" >> ${conf}
}

write_isolinux_msg(){
	local fn=isolinux.msg
	local conf=$1/${fn}
	msg2 "Writing ${fn} ..."
	echo "Welcome to ${dist_name} Linux!" > ${conf}
	echo '' >> ${conf}
	echo "To start the system enter 'start' and press <return>" >> ${conf}
	echo '' >> ${conf}
	echo '' >> ${conf}
	echo "Available boot options:" >> ${conf}
	echo "start                    - Start ${dist_name} Live System" >> ${conf}
	echo "nonfree                  - Start with proprietary drivers" >> ${conf}
	echo "harddisk                 - Boot from local hard disk" >> ${conf}
	echo "hdt                      - Run Hardware Detection Tool" >> ${conf}
	echo "memtest                  - Run Memory Test" >> ${conf}
}

update_isolinux_cfg(){
	local fn=isolinux.cfg
	msg2 "Updating ${fn} ..."
	sed -i "s|%MISO_LABEL%|${iso_label}|g;
			s|%ISO_NAME%|${iso_name}|g;
			s|%ARCH%|${arch}|g" $1/${fn}
}

update_isolinux_msg(){
	local fn=isolinux.msg
	msg2 "Updating ${fn} ..."
	sed -i "s|%DIST_NAME%|${dist_name}|g" $1/${fn}
}

write_isomounts(){
	echo '# syntax: <img> <arch> <mount point> <type> <kernel argument>' > $1
	echo '# Sample kernel argument in syslinux: overlay=extra,extra2' >> $1
	echo '' >> $1
	msg2 "Writing livecd entry ..."
	echo "${arch}/livecd-image.sqfs ${arch} / squashfs" >> $1
	if [[ -f Packages-Lng ]] ; then
		msg2 "Writing lng entry ..."
		echo "${arch}/lng-image.sqfs ${arch} / squashfs" >> $1
	fi
	if [[ -f Packages-Xorg ]] ; then
		msg2 "Writing pkgs entry ..."
		echo "${arch}/pkgs-image.sqfs ${arch} / squashfs" >> $1
	fi
	if [[ -f "${packages_custom}" ]] ; then
		msg2 "Writing ${custom} entry ..."
		echo "${arch}/${custom}-image.sqfs ${arch} / squashfs" >> $1
	fi
	msg2 "Writing root entry ..."
	echo "${arch}/root-image.sqfs ${arch} / squashfs" >> $1
}
