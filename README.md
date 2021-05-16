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

## Build it yourself (Debian/Ubuntu)
So before we begin i use a Linux based operating system with `apt` but for those who like `apt-get` can use that.<br>
it's all up to you.


I love housekeeping so let's start with:
```
$ sudo apt update
$ sudo apt upgrade -y
$ sudo apt autoremove -y
$ sudo apt autoclean
```

Before we begin we need some tools so let's download them
```
$ sudo apt install curl wget git nano
$ sudo apt-get install qemu-user-static
```

Create a `Folder` for this project
```
$ mkdir ProjectFolder
$ cd ProjectFolder
```

Download the Nvidia Jetson Nano L4T Driver Package (BSP) and extract
```
$ wget https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/t210/jetson-210_linux_r32.5.1_aarch64.tbz2
$ sudo tar jxpf jetson-210_linux_r32.5.1_aarch64.tbz2
$ sudo rm -r jetson-210_linux_r32.5.1_aarch64.tbz2
$ cd Linux_for_Tegra
```

Download Arch Linux aarch64 and extract
```
$ cd rootfs
$ wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
$ sudo tar -xpf ArchLinuxARM-aarch64-latest.tar.gz
$ sudo rm -r ArchLinuxARM-aarch64-latest.tar.gz
```


Now we need to add some lines to the `nv_customize_rootfs.sh` file
```
$ cd ../nv_tools/scripts/
$ nano nv_customize_rootfs.sh
```

Find
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

Replace with:
```
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
Now save this with the following command because we use nano: `CTRL` + `X` then `Y` and hit `enter`

<br/>

Now we need to create some folders
```
$ cd ../../nv_tegra
$ mkdir nvidia_drivers config nv_tools nv_sample_apps/nvgstapps
```

After the folders are created we extract .tbz2 and move the folders
```
$ sudo tar -xpjf nvidia_drivers.tbz2 -C nvidia_drivers/ && sudo rm -r nvidia_drivers.tbz2

$ sudo tar -xpjf config.tbz2 -C config/ && sudo rm -r config.tbz2

$ sudo tar -xpjf nv_tools.tbz2 -C nv_tools/ && sudo rm -r nv_tools.tbz2

$ sudo tar -xpjf nv_sample_apps/nvgstapps.tbz2 -C nv_sample_apps/nvgstapps/ && sudo rm -r nv_sample_apps/nvgstapps.tbz2
```

```
$ cd ../nv_tegra/nvidia_drivers
$ sudo mv lib/* usr/lib/
$ sudo rm -r lib
```

```
$ sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/
$ sudo rm -r usr/lib/aarch64-linux-gnu
```

```
$ sudo nano etc/nv_tegra_release
```

Find
```
0c165125388fbd943e7f8b37a272dec7c5d57c15 */usr/lib/aarch64-linux-gnu/tegra/libnvmm.so
```

Repalce with:
```
0c165125388fbd943e7f8b37a272dec7c5d57c15 */usr/lib/tegra/libnvmm.so
```
Now save this with the following command because we use nano: `CTRL` + `X` then `Y` and hit `enter`


Now go in the folder `Linux_for_Tegra/nv_tegra/nvidia_drivers/etc/ld.so.conf.d/`
to point to the right directory and add the `tegra-egl` entry. 

The contents of `nvidia-tegra.conf` 
```
$ sudo nano etc/ld.so.conf.d/nvidia-tegra.conf
```

It should look like this:
```
/usr/lib/tegra
/usr/lib/tegra-egl
```



### Changes to nv_tools Package
The tegrastats script should be moved from home/ubuntu into the /usr/bin directory. This removes the dependency on a user called ubuntu.
```
$ cd ../../../nv_tegra/nv_tools
$ mkdir -p usr/bin
```

### Changes to nvgstapps Package
```
$ cd ../../nv_tegra/nv_sample_apps/nvgstapps/
$ sudo mv usr/lib/aarch64-linux-gnu/* usr/lib/
$ sudo rm -r usr/lib/aarch64-linux-gnu
```

### Finalizing Configuration Changes
When you have finished making all the listed changes, repackage the files:
```
$ cd ../../../nv_tegra/nvidia_drivers
$ sudo tar -cpjf ../nvidia_drivers.tbz2 *

$ cd ../config
$ sudo tar -cpjf ../config.tbz2 *

$ cd ../nv_tools
$ sudo tar -cpjf ../nv_tools.tbz2 *

$ cd ../nv_sample_apps/nvgstapps
$ sudo tar -cpjf ../nvgstapps.tbz2 *
$ cd ../..
```
### Changes to rootfs
The following are changes that will be made to contents in your rootfs directory.

### Initialization Script
As Arch Linux uses systemd rather than upstart, the init script will need to be converted into a systemd service. Information on systemd and how to create services can be found on the Arch Linux Wiki page for systemd

To create the systemd service, we will need the service descriptor file, that tells systemd about the service. 

Hence need to create a service file as below in 
```
$ cd ../rootfs/usr/lib/systemd/system
```

Create a file with `nano` 
```
sudo nano nvidia-tegra.service
```

Then past this in...
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


Instructions on how to enable the script are in After First Boot section. If you wish to enable the script before flashing / first boot, create the following symbolic link to enable the service.
```
cd ../../../../etc/systemd/system/sysinit.target.wants/
```
```
ln -s ../../../../usr/lib/systemd/system/nvidia-tegra.service nvidia-tegra.service
```
This should be executed after apply_binaries, so the nvidia-tegra service is in place.

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
IgnorePkg=linux
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
![alt text](https://docs.Volt.cx/images/50171c51fd3ebadee6e11c600850ef2d.png)

*   Jumper need to be in 3 and 4
*   Connect your micro USB cable to your jetson nano
*   Now connect the USB in your PC/Laptop

Open your terminal en type:
```
lsusb
```
You must see `NVIDIA Corp. APX` plugged in you PC


Now apply the NVIDIA specific configuration, binaries, and the L4T kernel
```
sudo ./apply_binaries.sh
```
Create the image from the rootfs directory and flash the image to the Jetson
```
sudo ./flash.sh jetson-nano-devkit mmcblk0p1
```
Your device should reboot and prompt you to login. The default login for Arch Linux ARM is `root`/`root`.







# WORK IN PROGRESS

## Extra Info
* L4T VERSION: R32.5.1
