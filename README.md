# Tutorial: Building Arch Linux for Nvidia Jetson Nano

This tutorial provides step-by-step instructions on how to build Arch Linux for Nvidia Jetson Nano 2GB and 4GB boards.
- [Tutorial: Building Arch Linux for Nvidia Jetson Nano](#tutorial-building-arch-linux-for-nvidia-jetson-nano)
	- [1. Requirements](#1-requirements)
		- [1.1 Downloading and Extracting Required Archives](#11-downloading-and-extracting-required-archives)
	- [2. Modifying Linux For Tegra (L4T)](#2-modifying-linux-for-tegra-l4t)
		- [2.1 Modifying apply\_binaries.sh](#21-modifying-apply_binariessh)
		- [2.2 Modifying nv\_customize\_rootfs.sh](#22-modifying-nv_customize_rootfssh)
		- [2.3 Creating Required Directories](#23-creating-required-directories)
		- [2.4 Extracting Archives and Moving Files](#24-extracting-archives-and-moving-files)
		- [2.5 Modifying nv\_tegra\_release and nvidia-tegra.conf](#25-modifying-nv_tegra_release-and-nvidia-tegraconf)
		- [2.6 Modifying nv\_tools](#26-modifying-nv_tools)
		- [2.7 Modifying nvgstapps](#27-modifying-nvgstapps)
		- [2.8 Repackaging NVIDIA Binaries](#28-repackaging-nvidia-binaries)
		- [2.9 Modifying RootFS](#29-modifying-rootfs)
  		- [2.10 Arch Filesystem Structure](#210-arch-filesystem-structure) 
	- [3. Flashing the Jetson Nano](#3-flashing-the-jetson-nano)
		- [3.1 Apply NVIDIA Configurations and Binaries](#31-apply-nvidia-configurations-and-binaries)
	- [4. Autobuild Scripts](#4-autobuild-scripts)
	- [5. Extra Information](#5-extra-information)

## 1. Requirements
Before starting the build process, make sure you have the following:

- Jetson Nano board
- Micro SD Card
- Micro USB Cable
- 1 jumper (for recovery mode)
- Basic knowledge of using the nano text editor (CTRL + X [to save], then Y [confirm save])

### 1.1 Downloading and Extracting Required Archives
Download the Nvidia Jetson Nano L4T Driver Package (BSP) and Arch-aarch64 RootFS:

```bash
wget https://developer.nvidia.com/downloads/remetpack-463r32releasev73t210jetson-210linur3273aarch64tbz2
```
```bash
wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
```

Extract the BSP and RootFS archives:

```bash
sudo tar jxpf Jetson-210_Linux_R32.7.3_aarch64.tbz2
```
```bash
cd Linux_for_Tegra/rootfs
```
```bash
sudo tar -xpf ../../ArchLinuxARM-aarch64-latest.tar.gz
```

## 2. Modifying Linux For Tegra (L4T)

### 2.1 Modifying apply_binaries.sh
Open and edit `apply_binaries.sh`:

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

Save and exit the editor.

### 2.2 Modifying nv_customize_rootfs.sh
Open and edit `nv_customize_rootfs.sh`:

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

Save and exit the editor.

### 2.3 Creating Required Directories
Create the required directories:

```bash
cd ../nv_tegra
```
```bash
mkdir nvidia_drivers config nv_tools nv_sample_apps/nvgstapps
```

### 2.4 Extracting Archives and Moving Files
Extract the .tbz2 files and move the folders:

```bash
sudo tar -xpjf nvidia_drivers.tbz2 -C nvidia_drivers/ && sudo rm -r nvidia_drivers.tbz2
```
```bash
sudo tar -xpjf config.tbz2 -C config/ && sudo rm -r config.tbz2
```
```bash
sudo tar -xpjf nv_tools.tbz2 -C nv_tools/ && sudo rm -r nv_tools.tbz2
```
```bash
sudo tar -xpjf nv_sample_apps/nvgstapps.tbz2 -C nv_sample_apps/nvgstapps/ && sudo rm -r nv_sample_apps/nvgstapps.tbz2
```
```bash
cd ../nv_tegra/nvidia_drivers
```
```bash
sudo mv lib/* usr/lib/ && sudo rm -r lib/
```
```bash
sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/ && sudo rm -r usr/lib/aarch64-linux-gnu/
```

Save and exit the editor.

### 2.5 Modifying nv_tegra_release and nvidia-tegra.conf
Open `nv_tegra_release`:

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

Open `nvidia-tegra.conf`:

```bash
sudo nano etc/ld.so.conf.d/nvidia-tegra.conf
```

Make sure the file contains the following lines:

```bash
/usr/lib/tegra
/usr/lib/tegra-egl
```

Save and exit the editor.

### 2.6 Modifying nv_tools

* (For some unknown reason) 

Move `tegrastats` from `home/ubuntu` to `/usr/bin`:

```bash
cd ../nv_tools
```
```bash
mkdir -p usr/bin
```

### 2.7 Modifying nvgstapps
Move everything in `usr/lib/aarch64-linux-gnu/` into `usr/lib/` and remove `usr/lib/aarch64-linux-gnu` directory

```bash
cd ../../nv_tegra/nv_sample_apps/nvgstapps/
```
```bash
sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/ && sudo rm -r usr/lib/aarch64-linux-gnu/
```

### 2.8 Repackaging NVIDIA Binaries
Re-archive directories containing prior modifications

```bash
cd ../../../nv_tegra/nvidia_drivers && sudo tar -cpjf ../nvidia_drivers.tbz2 *
```
```bash
cd ../config && sudo tar -cpjf ../config.tbz2 *
```
```bash
cd ../nv_tools && sudo tar -cpjf ../nv_tools.tbz2 *
```
```bash
cd ../nv_sample_apps/nvgstapps && sudo tar -cpjf ../nvgstapps.tbz2 *
```
```bash
cd ../..
```

### 2.9 Modifying RootFS
Arch Linux uses systemd by default. So we create the service and init script.

```bash
cd ../rootfs/usr/lib/systemd/system
```
```bash
sudo nano nvidia-tegra.service
```

Paste the following into `nvidia-tegra.service`:

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

Save and exit the editor.

Create `nvidia-tegra-init-script`:

```bash
sudo nano ../../../bin/nvidia-tegra-init-script
```

Paste the following into `nvidia-tegra-init-script`:

```bash
#!/bin/bash

if [ -e /sys/power/state ]; then
    chmod 0666 /sys/power/state
fi

if [ -e /sys/devices/soc0/family ]; then
    SOCFAMILY="`cat /sys/devices/soc0/family`"
fi

if [ "$SOCFAMILY" = "Tegra210" ] &&
    [ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq ]; then
    sudo bash -c "echo -n 510000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
fi

if [ -d /sys/devices/system/cpu/cpuquiet/tegra_cpuquiet ] ; then
    echo 500 > /sys/devices/system/cpu/cpuquiet/tegra_cpuquiet/down_delay
    echo 1 > /sys/devices/system/cpu/cpuquiet/tegra_cpuquiet/enable
elif [ -w /sys/module/cpu_tegra210/parameters/auto_hotplug ] ; then
    echo 1 > /sys/module/cpu_tegra210/parameters/auto_hotplug
fi

if [ -e /sys/module/cpuidle/parameters/power_down_in_idle ] ; then
    echo "Y" > /sys/module/cpuidle/parameters/power_down_in_idle
elif [ -e /sys/module/cpuidle/parameters/lp2_in_idle ] ; then
    echo "Y" > /sys/module/cpuidle/parameters/lp2_in_idle
fi

if [ -e /sys/block/sda0/queue/read_ahead_kb ]; then
   echo 2048 > /sys/block/sda0/queue/read_ahead_kb
fi
if [ -e /sys/block/sda1/queue/read_ahead_kb ]; then
    echo 2048 > /sys/block/sda1/queue/read_ahead_kb
fi

for uartInst in 0 1 2 3
do
    uartNode="/dev/ttyHS$uartInst"
    if [ -e "$uartNode" ]; then
        ln -s /dev/ttyHS$uartInst /dev/ttyTHS$uartInst
    fi
done

machine=`cat /sys/devices/soc0/machine`
if [ "${machine}" = "jetson-nano-devkit" ] ; then
    echo 4 > /sys/class/graphics/fb0/blank
            BoardRevision=`cat /proc/device-tree/chosen/board_info/major_revision`
            if [ "${BoardRevision}" = "A" ] ||
                    [ "${BoardRevision}" = "B" ] ||
                    [ "${BoardRevision}" = "C" ] ||
                    [ "${BoardRevision}" = "D" ]; then
                    echo 0 > /sys/devices/platform/tegra-otg/enable_device
                    echo 1 > /sys/devices/platform/tegra-otg/enable_host
            fi
fi

if [ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
    read governors < /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
    case $governors in
        *interactive*)
            echo interactive > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
            if [ -e /sys/devices/system/cpu/cpufreq/interactive ] ; then
                echo "1224000" >/sys/devices/system/cpu/cpufreq/interactive/hispeed_freq
                echo "95" >/sys/devices/system/cpu/cpufreq/interactive/target_loads
                echo "20000" >/sys/devices/system/cpu/cpufreq/interactive/min_sample_time
            fi
                ;;
        *)
                ;;
    esac
fi

echo "Success! Exiting"
exit 0
```

Save and exit the editor.

Open and edit pacman.conf to ignore updates to the kernel package:

```bash
cd ../../../../etc/
```
```bash
sudo nano pacman.conf
```

Find line:
`#IgnorePkg   =`
and replace with:
`IgnorePkg=linux-aarch64`

Save and exit the editor.

### 2.10 Arch Filesystem Structure
In Archlinux, `/lib` is just a symbolic link to `/usr/lib`.
```bash
cd Linux_for_Tegra

sudo rsync -avxHAX lib/ usr/lib/
sudo rm -rf lib
sudo ln -s usr/lib lib
```

## 3. Flashing the Jetson Nano
Make sure your Jetson Nano is in recovery mode using a Jumper.
Depending on which Jetson Nano Board you have, this pin will be in different locations, refer to the Image below:
![Recovery Mode Pin Location](https://imgur.com/ZYjVGYM.png)

Connect the Jetson Nano to your host computer using a micro USB cable.

Open a terminal on host and run the following command to check if the Jetson Nano is recognized:

```bash
lsusb
```

You should see "NVIDIA Corp. APX" listed.

### 3.1 Apply NVIDIA Configurations and Binaries
Apply the NVIDIA-specific configuration, binaries, and the L4T kernel:

```bash
sudo ./apply_binaries.sh --target-overlay
```

Copy `ld-linux-aarch64.so.1` to enable booting:

```bash
sudo cp rootfs/usr/lib/ld-linux-aarch64.so.1 rootfs/lib/ld-linux-aarch64.so.1
```

To enable `nvidia-tegra.service`, create a symbolic link:

```bash
cd rootfs/etc/systemd/system/sysinit.target.wants/
```
```bash
sudo ln -s ../../../../usr/lib/systemd/system/nvidia-tegra.service nvidia-tegra.service
```

Create the image from the rootfs directory and flash it to the Jetson Nano:

```bash
sudo ./flash.sh jetson-nano-qspi-sd mmcblk0p1
```

After flashing, your device should reboot and prompt you to login. The default login for Arch Linux ARM is `root/root`.

## 4. Autobuild Scripts
BASH and FISH scripts automate the process explained in this tutorial.

BASH: `arch-nano.sh`
FISH: `arch-nano.fish`

## 5. Extra Information
[L4T Kernel Customization](https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3276/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/kernel_custom.html#)

[L4T Developer Guide](https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3276/index.html)

[L4T Downloads & Links](https://developer.nvidia.com/embedded/linux-tegra-r3276)

L4T 32.7.6 (JetPack 4.6.6)

Updated Version, Thank You @Yarpii
