# Nvidia Jetson Nano | Arch Linux | Volt.cx


## Table of contents
* [General info](#general-info)
* [Need for](#need-for)
* [Extra Info](#extra-info)

## General info
Here are the steps to build your own updated version of Arch Nano. Arch Linux for Nvidia Jetson Nano 2GB and 4GB.
If you encounter any problem with creation because i made a mistake some where just let me know so i can update this and make it better and everyone can enjoy a happy Arch Nano Project.

It will work on
* Jetson Nano (2GB)
* Jetson Nano (4GB)

## We need for this project:
* Jetson Nano
* Micro SD Card
* Micro USB Cable
* balenaEtcher
* 1 jumper (for recovery mode)

### Basic Knowledge:
* How to save with `nano`: `CTRL` + `X` then `Y` then `ENTER`

## Build it yourself (Debian/Ubuntu + Arch)
Originally provided for Debian/Ubuntu, I have added support for Arch </br>
Only difference is package manager (apt, apt-get vs. pacman) </br> 


## Keep your system up to date!
Arch:
```
pacman -Syu
```
Arch:
```
pacman -S curl wget git nano qemu-user-static openssl lbzip2
```

Create Directory for Project
```
mkdir Tegra && cd Tegra
```

Download the Nvidia Jetson Nano L4T Driver Package (BSP) and Arch-aarch64 RootFS, then extract:
```
wget https://developer.nvidia.com/downloads/remetpack-463r32releasev73t210jetson-210linur3273aarch64tbz2
```
```
wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
```
* Keep tarballs in case something gets messed up, why re-download?
```
sudo tar jxpf Jetson-210_Linux_R32.7.3_aarch64.tbz2
```
```
cd Linux_for_Tegra/rootfs
```
```
sudo tar -xpf ../../ArchLinuxARM-aarch64-latest.tar.gz
```


Modify `apply_binaries.sh` file:
```
nano ../apply_binaries.sh
```
Find
```
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
Simply add --keep-directory-symlink for each tar entry
or
Replace with:
```
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


Modify `nv_customize_rootfs.sh` file:
```
nano ../nv_tools/scripts/nv_customize_rootfs.sh
```

Find (or similar)
```
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

Add Section between *** (Remove '*'s and extra spacing):
```
    if [ -d "${LDK_ROOTFS_DIR}/usr/lib/arm-linux-gnueabihf/tegra" ]; then
        ARM_ABI_DIR_ABS="usr/lib/arm-linux-gnueabihf"
    elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/arm-linux-gnueabi/tegra" ]; then
        ARM_ABI_DIR_ABS="usr/lib/arm-linux-gnueabi"
    elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/aarch64-linux-gnu/tegra" ]; then
        ARM_ABI_DIR_ABS="usr/lib/aarch64-linux-gnu"
********************************************
    
    elif [ -d "${LDK_ROOTFS_DIR}/usr/lib/tegra" ]; then
        ARM_ABI_DIR="${LDK_ROOTFS_DIR}/usr/lib"

********************************************
    else
        echo "Error: None of Hardfp/Softfp Tegra libs found"
        exit 4
    fi
```
Now save this with the following command because we use nano: `CTRL` + `X` then `Y` and hit `enter`

<br/>

Now we need to create some folders
```
cd ../nv_tegra
```
```
mkdir nvidia_drivers config nv_tools nv_sample_apps/nvgstapps
```

After the folders are created we extract .tbz2 and move the folders
```
sudo tar -xpjf nvidia_drivers.tbz2 -C nvidia_drivers/ && sudo rm -r nvidia_drivers.tbz2
```
```
sudo tar -xpjf config.tbz2 -C config/ && sudo rm -r config.tbz2
```
```
sudo tar -xpjf nv_tools.tbz2 -C nv_tools/ && sudo rm -r nv_tools.tbz2
```
```
sudo tar -xpjf nv_sample_apps/nvgstapps.tbz2 -C nv_sample_apps/nvgstapps/ && sudo rm -r nv_sample_apps/nvgstapps.tbz2
```

```
cd ../nv_tegra/nvidia_drivers
```
```
sudo mv lib/* usr/lib/ && sudo rm -r lib/
```

```
sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/ && sudo rm -r usr/lib/aarch64-linux-gnu/
```

```
sudo nano etc/nv_tegra_release
```

Find All
```
*/usr/lib/aarch64-linux-gnu/tegra/
```

Repalce with:
```
*/usr/lib/tegra/
```
Now save this with the following command because we use nano: `CTRL` + `X` then `Y` and hit `enter`


Now go in the folder `Linux_for_Tegra/nv_tegra/nvidia_drivers/etc/ld.so.conf.d/`
to point to the right directory and add the `tegra-egl` entry. 

The contents of `nvidia-tegra.conf` 
```
sudo nano etc/ld.so.conf.d/nvidia-tegra.conf
```

It should look like this:
```
/usr/lib/tegra
/usr/lib/tegra-egl
```



### Changes to nv_tools Package
The tegrastats script should be moved from home/ubuntu into the /usr/bin directory. This removes the dependency on a user called ubuntu.
```
cd ../nv_tools
```
```
mkdir -p usr/bin
```

### Changes to nvgstapps Package
```
cd ../../nv_tegra/nv_sample_apps/nvgstapps/
```
```
sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/ && sudo rm -r usr/lib/aarch64-linux-gnu/
```

### Finalizing Configuration Changes
When you have finished making all the listed changes, repackage the files:
```
cd ../../../nv_tegra/nvidia_drivers && sudo tar -cpjf ../nvidia_drivers.tbz2 *
```
```
cd ../config && sudo tar -cpjf ../config.tbz2 *
```
```
cd ../nv_tools && sudo tar -cpjf ../nv_tools.tbz2 *
```
```
cd ../nv_sample_apps/nvgstapps && sudo tar -cpjf ../nvgstapps.tbz2 *
```
```
cd ../..
```
### Changes to rootfs
The following are changes that will be made to contents in your rootfs directory.

### Initialization Script
As Arch Linux uses systemd rather than upstart, the init script will need to be converted into a systemd service. Information on systemd and how to create services can be found on the Arch Linux Wiki page for systemd

To create the systemd service, we will need the service descriptor file, that tells systemd about the service. 

Hence need to create a service file as below in 
```
cd ../rootfs/usr/lib/systemd/system
```

Create a file with `nano` 
```
sudo nano nvidia-tegra.service
```

Then paste this in:
```
##Location
## /usr/lib/systemd/system/nvidia-tegra.service

[Unit]
Description=The NVIDIA tegra init script

[Service]
type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/nvidia-tegra-init-script

[Install]
WantedBy=multi-user.target
```

Now create the nvidia-tegra-init-script:
```
sudo nano ../../../bin/nvidia-tegra-init-script
```
Paste this in:
```
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
Now save this with the following command because we use nano: `CTRL` + `X` then `Y` and hit `ENTER`


### Pacman Configuration
As we have installed a custom kernel to boot linux on the jetson-nano-devkit, it is necessary to update pacman.conf to ignore updates to the kernel package.

To do so add linux as an ignored package to your <path_to_L4T_rootfs>
```
cd ../../../../etc/
```

Open `pacman.conf` with `nano`
```
sudo nano pacman.conf
```
Search now for
```
#IgnorePkg   =
```
replace it with:
```
IgnorePkg=linux-aarch64
```
close and save it.


### Alternatives Support
Arch Linux does not have a built in application for managing alternative versions of the same package as Debian/Ubuntu does.

It does however support having multiple packages installed at the same time, as long as their names are different.

A script can be created to automate the switching between which of the installed versions is treated as the default. As has been done with java [2].


### Flashing Jetson Nano
The steps for flashing the Arch Linux image to the Jetson are no different than flashing the image for Ubuntu.

Run the following commands to apply the configuration, create the image, and flash it to the Jetson

You need to have your Jetson nano in recovery mode with jumpers:
* Dependant on Jetson Nano Board, please compare your pin-layout to Image and follow relevant steps!
<img src="https://i.imgur.com/ZYjVGYM.png">

Board A02:
 - Jumper needs to on J40 Button Header: Pins 3 & 4 (2nd to bottom row of J40, Highlighted in Red)
 - Connect microUSB to Jetson Nano and Host Computer

Board B01:
- Jumper needs to be on J50 Button Header: Pins 3 & 4 (Highlighted in Red)

Open your terminal and type:
```
lsusb
```
You must see `NVIDIA Corp. APX` plugged in you PC


Now apply the NVIDIA specific configuration, binaries, and the L4T kernel
NECESSARY: '--target-overlay' bypasses dpkg to use tarballs
```
sudo ./apply_binaries.sh --target-overlay
```
Copy ld-linux-aarch64.so.1 (idk why, but allows boot)
```
sudo cp rootfs/usr/lib/ld-linux-aarch64.so.1 rootfs/lib/ld-linux-aarch64.so.1
```
Instructions on how to enable the script are in After First Boot section. If you wish to enable the script before flashing / first boot, then enable nvidia-tegra.service by creating this symbolic link:
* This MUST be executed after apply_binaries, so the nvidia-tegra service is in place.
```
cd rootfs/etc/systemd/system/sysinit.target.wants/
```
```
ln -s ../../../../usr/lib/systemd/system/nvidia-tegra.service nvidia-tegra.service
```

Optional: Before Flashing setup the Root Filesystem with pre-configured users and groups. Refer below

Create the image from the rootfs directory and flash the image to the Jetson
```
sudo ./flash.sh jetson-nano-qspi-sd mmcblk0p1
```
Your device should reboot and prompt you to login. The default login for Arch Linux ARM is `root`/`root`.

## Pre-configure System:
Before Flashing lets customize our System:
We need arch-chroot so:
```
pacman -S arch-install-scripts
```
Create mount directory:
```
sudo mkdir /mnt/Tegra
```
Mount rootfs, dev, proc, usr, and (optionally) home
```
sudo mount --bind ~/Tegra/Linux_for_Tegra/rootfs /mnt/Tegra
```
```
sudo mount --bind ~/Tegra/Linux_for_Tegra/rootfs/dev /mnt/Tegra/dev
```
```
sudo mount --bind ~/Tegra/Linux_for_Tegra/rootfs/proc /mnt/Tegra/proc
```
```
sudo mount --bind ~/Tegra/Linux_for_Tegra/rootfs/usr /mnt/Tegra/usr
```
Mount Home if you plan on customizing dotfiles or something
```
sudo mount --bind ~/Tegra/Linux_for_Tegra/rootfs/home /mnt/Tegra/home
```

Now we arch-chroot
```
sudo arch-chroot /mnt/Tegra
```
We are now in.

Lets setup users, groups, and passwords:
```
useradd -m -g 0 aSkeleton
```
This creates a user named aSkeleton added to wheel/root group and create a Home dir, if does not exist.

Now set passwords
```
passwd
```
^ Changes Root password
```
passwd aSkeleton
```
Process is the same for Groups: groupadd, groupdel, groupmod

Now lets setup pacman:
```
pacman-key --init
```
then
```
pacman-key --populate
```
now upgrade your system
```
pacman -Syu
```
* ITS VERY IMPORTANT THE LINUX KERNEL (LINUX-AARCH64) IS NOT UPGRADED AT ALL! YOU WILL BREAK YOUR SYSTEM!
You skipped a step if thats happening: Edit pacman.conf (/etc/pacman.conf) and change to "IgnorePkg=linux-aarch64"

# WORK IN PROGRESS

## Extra Info
* L4T VERSION: R32.7.3
