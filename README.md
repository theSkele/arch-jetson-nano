# Tutorial: Building Arch Linux for Nvidia Jetson Nano

This tutorial provides step-by-step instructions on how to build an updated version of Arch Linux for Nvidia Jetson Nano 2GB and 4GB boards.

## Table of Contents
1. [General Information](#1-general-information)
2. [Requirements](#2-requirements)
3. [Building Arch Linux for Jetson Nano](#3-building-arch-linux-for-jetson-nano)
   - 3.1 [Downloading the Required Files](#31-downloading-the-required-files)
   - 3.2 [Modifying the apply_binaries.sh File](#32-modifying-the-apply_binariessh-file)
   - 3.3 [Modifying the nv_customize_rootfs.sh File](#33-modifying-the-nv_customize_rootfssh-file)
   - 3.4 [Creating the Required Folders](#34-creating-the-required-folders)
   - 3.5 [Extracting and Moving Files](#35-extracting-and-moving-files)
   - 3.6 [Modifying nv_tegra_release and nvidia-tegra.conf Files](#36-modifying-nv_tegra_release-and-nvidia-tegraconf-files)
   - 3.7 [Making Changes to the nv_tools Package](#37-making-changes-to-the-nv_tools-package)
   - 3.8 [Making Changes to the nvgstapps Package](#38-making-changes-to-the-nvgstapps-package)
   - 3.9 [Repackaging NVIDIA Binaries](#39-repackaging-nvidia-binaries)
   - 3.10 [Making Changes to the Rootfs](#310-making-changes-to-the-rootfs)
4. [Flashing the Jetson Nano](#4-flashing-the-jetson-nano)
5. [Autobuild Scripts](#5-autobuild-scripts)
   - 5.1 [autobuild-arch-nano.sh](#51-autobuild-arch-nanosh)
   - 5.2 [fish-autobuild-arch-nano.sh](#52-fish-autobuild-arch-nanosh)
6. [Extra Information](#6-extra-information)

## 1. General Information
This tutorial will guide you through the process of building your own updated version of Arch Linux for Nvidia Jetson Nano boards. It is applicable to both the 2GB and 4GB versions of Jetson Nano.

## 2. Requirements
Before starting the build process, make sure you have the following:

- Jetson Nano board
- Micro SD Card
- Micro USB Cable
- 1 jumper (for recovery mode)
- Basic knowledge of using the nano text editor (CTRL + X, Y, ENTER to save)

## 3. Building Arch Linux for Jetson Nano
### 3.1 Downloading the Required Files
Download the Nvidia Jetson Nano L4T Driver Package (BSP) and Arch-aarch64 RootFS:

```bash
wget https://developer.nvidia.com/downloads/remetpack-463r32releasev73t210jetson-210linur3273aarch64tbz2
wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
```

Extract the downloaded files:

```bash
sudo tar jxpf Jetson-210_Linux_R32.7.3_aarch64.tbz2
cd Linux_for_Tegra/rootfs
sudo tar -xpf ../../ArchLinuxARM-aarch64-latest.tar.gz
```

### 3.2 Modifying the apply_binaries.sh File
Open the `apply_binaries.sh` file for editing:

```bash
nano ../apply_binaries.sh
```

Find the following lines:

```bash
	echo "Extracting the NVIDIA user space components to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 -xpmf "${LDK_NV_TEGRA_DIR}/nvidia_drivers.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the BSP test tools to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 -xpmf "${LDK_NV_TEGRA_DIR}/nv_tools.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the NVIDIA gst test applications to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 -xpmf "${LDK_NV_TEGRA_DIR}/nv_sample_apps/nvgstapps.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting Weston to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 -xpmf "${LDK_NV_TEGRA_DIR}/weston.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the configuration files for the supplied root filesystem to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 -xpmf "${LDK_NV_TEGRA_DIR}/config.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting graphics_demos to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 -xpmf "${LDK_NV_TEGRA_DIR}/graphics_demos.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the firmwares and kernel modules to ${LDK_ROOTFS_DIR}"
	( cd "${LDK_ROOTFS_DIR}" ; tar -I lbzip2 -xpmf "${LDK_KERN_DIR}/kernel_supplements.tbz2" )

	echo "Extracting the kernel headers to ${LDK_ROOTFS_DIR}/usr/src"
	# The kernel headers package can be used on the target device as well as on another host.
	# When used on the target, it should go into /usr/src and owned by root.
	# Note that there are multiple linux-headers-* directories; one for use on an
	# x86-64 Linux host and one for use on the L4T target.
	EXTMOD_DIR=ubuntu18.04_aarch64
	KERNEL_HEADERS_A64_DIR="$(tar tf "${LDK_KERN_DIR}/kernel_headers.tbz2" | grep "${EXTMOD_DIR}" | head -1 | cut -d/ -f1)"
	KERNEL_VERSION="$(echo "${KERNEL_HEADERS_A64_DIR}" | sed -e "s/linux-headers-//" -e "s/-${EXTMOD_DIR}//")"
	KERNEL_SUBDIR="kernel-$(echo "${KERNEL_VERSION}" | cut -d. -f1-2)"
	install -o 0 -g 0 -m 0755 -d "${LDK_ROOTFS_DIR}/usr/src"
	pushd "${LDK_ROOTFS_DIR}/usr/src" > /dev/null 2>&1
	# This tar is packaged for the host (all files 666, dirs 777) so that when
	# extracted on the host, the user's umask controls the permissions.
	# However, we're now installing it into the rootfs, and hence need to
	# explicitly set and use the umask to achieve the desired permissions.
	(umask 022 && tar -I lbzip2 --no-same-permissions -xmf "${LDK_KERN_DIR}/kernel_headers.tbz2")
	# Link to the kernel headers from /lib/modules/<version>/build
	KERNEL_MODULES_DIR="${LDK_ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}"
	if [ -d "${KERNEL_MODULES_DIR}" ]; then
		echo "Adding symlink ${KERNEL_MODULES_DIR}/build --> /usr/src/${KERNEL_HEADERS_A64_DIR}/${KERNEL_SUBDIR}"
		[ -h "${KERNEL_MODULES_DIR}/build" ] && unlink "${KERNEL_MODULES_DIR}/build" && rm -f "${KERNEL_MODULES_DIR}/build"
		[ ! -h "${KERNEL_MODULES_DIR}/build" ] && ln -s "/usr/src/${KERNEL_HEADERS_A64_DIR}/${KERNEL_SUBDIR}" "${KERNEL_MODULES_DIR}/build"
	fi
```

Add --keep-directory-symlink to each tar entry or replace them with:

```bash
	echo "Extracting the NVIDIA user space components to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_NV_TEGRA_DIR}/nvidia_drivers.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the BSP test tools to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_NV_TEGRA_DIR}/nv_tools.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the NVIDIA gst test applications to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_NV_TEGRA_DIR}/nv_sample_apps/nvgstapps.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting Weston to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_NV_TEGRA_DIR}/weston.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the configuration files for the supplied root filesystem to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_NV_TEGRA_DIR}/config.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting graphics_demos to ${LDK_ROOTFS_DIR}"
	pushd "${LDK_ROOTFS_DIR}" > /dev/null 2>&1
	tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_NV_TEGRA_DIR}/graphics_demos.tbz2"
	popd > /dev/null 2>&1

	echo "Extracting the firmwares and kernel modules to ${LDK_ROOTFS_DIR}"
	( cd "${LDK_ROOTFS_DIR}" ; tar -I lbzip2 --keep-directory-symlink -xpmf "${LDK_KERN_DIR}/kernel_supplements.tbz2" )

	echo "Extracting the kernel headers to ${LDK_ROOTFS_DIR}/usr/src"
	# The kernel headers package can be used on the target device as well as on another host.
	# When used on the target, it should go into /usr/src and owned by root.
	# Note that there are multiple linux-headers-* directories; one for use on an
	# x86-64 Linux host and one for use on the L4T target.
	EXTMOD_DIR=ubuntu18.04_aarch64
	KERNEL_HEADERS_A64_DIR="$(tar tf "${LDK_KERN_DIR}/kernel_headers.tbz2" | grep "${EXTMOD_DIR}" | head -1 | cut -d/ -f1)"
	KERNEL_VERSION="$(echo "${KERNEL_HEADERS_A64_DIR}" | sed -e "s/linux-headers-//" -e "s/-${EXTMOD_DIR}//")"
	KERNEL_SUBDIR="kernel-$(echo "${KERNEL_VERSION}" | cut -d. -f1-2)"
	install -o 0 -g 0 -m 0755 -d "${LDK_ROOTFS_DIR}/usr/src"
	pushd "${LDK_ROOTFS_DIR}/usr/src" > /dev/null 2>&1
	# This tar is packaged for the host (all files 666, dirs 777) so that when
	# extracted on the host, the user's umask controls the permissions.
	# However, we're now installing it into the rootfs, and hence need to
	# explicitly set and use the umask to achieve the desired permissions.
	(umask 022 && tar -I lbzip2 --keep-directory-symlink --no-same-permissions -xmf "${LDK_KERN_DIR}/kernel_headers.tbz2")
	# Link to the kernel headers from /lib/modules/<version>/build
	KERNEL_MODULES_DIR="${LDK_ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}"
	if [ -d "${KERNEL_MODULES_DIR}" ]; then
		echo "Adding symlink ${KERNEL_MODULES_DIR}/build --> /usr/src/${KERNEL_HEADERS_A64_DIR}/${KERNEL_SUBDIR}"
		[ -h "${KERNEL_MODULES_DIR}/build" ] && unlink "${KERNEL_MODULES_DIR}/build" && rm -f "${KERNEL_MODULES_DIR}/build"
		[ ! -h "${KERNEL_MODULES_DIR}/build" ] && ln -s "/usr/src/${KERNEL_HEADERS_A64_DIR}/${KERNEL_SUBDIR}" "${KERNEL_MODULES_DIR}/build"
	fi
```

Save the file and exit the editor.

### 3.3 Modifying the nv_customize_rootfs.sh File
Open the `nv_customize_rootfs.sh` file for editing:

```bash
nano ../nv_tools/scripts/nv_customize_rootfs.sh
```

Find the following (or similar):

```bash
if [ -d "${LDK_ROOTFS_DIR}/usr/lib/arm-linux-gnueabihf/tegra" ]; then
    ARM_ABI_DIR_ABS="usr/lib/arm-linux-gnueabihf"
elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/arm-linux-gnueabi/tegra" ]; then
    ARM_ABI_DIR_ABS="usr/lib/arm-linux-gnueabi"
elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/aarch64-linux-gnu/tegra" ]; then
    ARM_ABI_DIR_ABS="usr/lib/aarch64-linux-gnu"
else
    echo "Error: None of Hardfp/Softfp Tegra libs found"
    exit 4
fi
```

Add the following section after the 2nd elif statement, and before the else statement:

```bash
elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/tegra" ]; then
    ARM_ABI_DIR="${LDK_ROOTFS_DIR}/usr/lib"
```

Should look like this:

```bash
if [ -d "${LDK_ROOTFS_DIR}/usr/lib/arm-linux-gnueabihf/tegra" ]; then
    ARM_ABI_DIR_ABS="usr/lib/arm-linux-gnueabihf"
elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/arm-linux-gnueabi/tegra" ]; then
    ARM_ABI_DIR_ABS="usr/lib/arm-linux-gnueabi"
elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/aarch64-linux-gnu/tegra" ]; then
    ARM_ABI_DIR_ABS="usr/lib/aarch64-linux-gnu"
elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/tegra" ]; then
    ARM_ABI_DIR="${LDK_ROOTFS_DIR}/usr/lib"
else
    echo "Error: None of Hardfp/Softfp Tegra libs found"
    exit 4
fi
```

Save the file and exit the editor.

### 3.4 Creating the Required Folders
Create the necessary folders for the project:

```bash
cd ../nv_tegra
mkdir nvidia_drivers config nv_tools nv_sample_apps/nvgstapps
```

### 3.5 Extracting and Moving Files
Extract the .tbz2 files and move the folders:

```bash
sudo tar -xpjf nvidia_drivers.tbz2 -C nvidia_drivers/ && sudo rm -r nvidia_drivers.tbz2
sudo tar -xpjf config.tbz2 -C config/ && sudo rm -r config.tbz2
sudo tar -xpjf nv_tools.tbz2 -C nv_tools/ && sudo rm -r nv_tools.tbz2
sudo tar -xpjf nv_sample_apps/nvgstapps.tbz2 -C nv_sample_apps/nvgstapps/ && sudo rm -r nv_sample_apps/nvgstapps.tbz2
cd ../nv_tegra/nvidia_drivers
sudo mv lib/* usr/lib/ && sudo rm -r lib/
sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/ && sudo rm -r usr/lib/aarch64-linux-gnu/
```

Save the file and exit the editor.

### 3.6 Modifying nv_tegra_release and nvidia-tegra.conf Files
Open the `nv_tegra_release` file for editing:

```bash
sudo nano etc/nv_tegra_release
```

Find all occurrences of:

```bash
*/usr/lib/aarch64-linux-gnu/tegra/
```

Replace them with:

```bash
*/usr/lib/tegra/
```

Open the `nvidia-tegra.conf` file for editing:

```bash
sudo nano etc/ld.so.conf.d/nvidia-tegra.conf
```

Make sure the file contains the following lines:

```bash
/usr/lib/tegra
/usr/lib/tegra-egl
```

Save the file and exit the editor.

### 3.7 Making Changes to the nv_tools Package

* For some reason, 

Move the `tegrastats` script from `home/ubuntu` to the `/usr/bin` directory:

```bash
cd ../nv_tools
mkdir -p usr/bin
```

### 3.8 Making Changes to the nvgstapps Package
```bash
cd ../../nv_tegra/nv_sample_apps/nvgstapps/
sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/ && sudo rm -r usr/lib/aarch64-linux-gnu/
```

### 3.9 Repackaging NVIDIA Binaries
Repackage the files after making all the listed changes:

```bash
cd ../../../nv_tegra/nvidia_drivers && sudo tar -cpjf ../nvidia_drivers.tbz2 *
cd ../config && sudo tar -cpjf ../config.tbz2 *
cd ../nv_tools && sudo tar -cpjf ../nv_tools.tbz2 *
cd ../nv_sample_apps/nvgstapps && sudo tar -cpjf ../nvgstapps.tbz2 *
cd ../..
```

### 3.10 Making Changes to the Rootfs
The following changes will be made to the contents of your rootfs directory.

```bash
cd ../rootfs/usr/lib/systemd/system
sudo nano nvidia-tegra.service
```

Paste the following content into the file:

```bash
[Unit]
Description=The NVIDIA tegra init script

[Service]
type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/nvidia-tegra-init-script

[Install]
WantedBy=multi-user.target
```

Create the `nvidia-tegra-init-script`:

```bash
sudo nano ../../../bin/nvidia-tegra-init-script
```

Paste the following content into the file:

```bash
#!/bin/bash

# Script content goes here

echo "Success! Exiting"
exit 0
```

Save the files and exit the editor.

Open and edit pacman.conf to ignore updates to the kernel package:

```bash
cd ../../../../etc/
sudo nano pacman.conf
```

Find line:
`#IgnorePkg   =`
and replace with:
`IgnorePkg=linux-aarch64`

Save the file and exit the editor.

## 4. Flashing the Jetson Nano
Make sure your Jetson Nano is in recovery mode with using a Jumper.
Depending on which Jetson Nano Board you have, this pin will be in different locations, refer to the Image below:
![Recovery Mode Pin Location](https://imgur.com/ZYjVGYM.png)

Connect the Jetson Nano to your host using a micro USB cable.

Open your terminal and run the following command to check if the Jetson Nano is recognized:

```bash
lsusb
```

You should see "NVIDIA Corp. APX" listed.

Apply the NVIDIA-specific configuration, binaries, and the L4T kernel:

```bash
sudo ./apply_binaries.sh --target-overlay
```

Copy `ld-linux-aarch64.so.1` to enable booting:

```bash
sudo cp rootfs/usr/lib/ld-linux-aarch64.so.1 rootfs/lib/ld-linux-aarch64.so.1
```

To enable the `nvidia-tegra.service` script, create a symbolic link:

```bash
cd rootfs/etc/systemd/system/sysinit.target.wants/
sudo ln -s ../../../../usr/lib/systemd/system/nvidia-tegra.service nvidia-tegra.service
```

Create the image from the rootfs directory and flash it to the Jetson Nano:

```bash
sudo ./flash.sh jetson-nano-qspi-sd mmcblk0p1
```

After flashing, your device should reboot and prompt you to login. The default login for Arch Linux ARM is `root/root`.

## 5. Autobuild Scripts
### 5.1 autobuild-arch-nano.sh
The `autobuild-arch-nano.sh` script automates the process of building Arch Linux for Nvidia Jetson Nano. It performs all the necessary steps mentioned in this tutorial. You can execute the script to build the system automatically.

### 5.2 fish-autobuild-arch-nano.sh
The `fish-autobuild-arch-nano.sh` script is a FISH shell version of `autobuild-arch-nano.sh`. It provides the same functionality but is designed for the FISH shell. You can use this script if you prefer to work with FISH instead of BASH.

## 6. Extra Information
- L4T Version: R32.7.3

Please note that this tutorial is a work in progress and may be updated in the future.
