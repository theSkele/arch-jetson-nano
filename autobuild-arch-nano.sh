#!/bin/bash
RED="\x1b[1;31m"
WHITE="\x1b[1;37m"
YELLOW="\x1b[1;33m"
RESET="\x1b[0m"

# Check if tarballs are already downloaded
if [ ! -f Jetson-210_Linux_R32.7.3_aarch64.tbz2  ]; then
    wget --output-document=Jetson-210_Linux_R32.7.3_aarch64.tbz2 https://developer.nvidia.com/downloads/remetpack-463r32releasev73t210jetson-210linur3273aarch64tbz2
fi

if [ ! -f ArchLinuxARM-aarch64-latest.tar.gz ]; then
    wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
fi

# Check if directory exists
if [ -d Linux_for_Tegra ]; then
    # Prompt user for deletion confirmation
    echo -e -n "${YELLOW}'Linux_for_Tegra' ${WHITE}already exists. Do you want to delete it? (${YELLOW}y${WHITE}/${RED}n${WHITE}): "
    read choice

    # Check user's choice
    if [ "$choice" == "y" ]; then
        # Delete the directory
        sudo rm -rf Linux_for_Tegra
    else
        echo -e "${RED}'Linux_for_Tegra' was NOT deleted, Stopping.${RESET}"
        exit 1
    fi
fi

echo -e "${RED}Extracting Jetson and Arch Linux ARM Archives...${YELLOW}"

# Extract Tegra kernel if directory doesn't exist
if [ ! -d Linux_for_Tegra ]; then
    sudo tar jxpf Jetson-210_Linux_R32.7.3_aarch64.tbz2
fi

# Extract ArchLinux-ARM filesystem if doesnt exist
if [[ $(find -maxdepth 1 -type f | wc -l) -gt 1 ]]; then
    sudo tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C Linux_for_Tegra/rootfs
fi

echo -e "${RED}Extracted, ${WHITE}modifying NVIDIA scripts..."

# Modify apply_binaries.sh file
sudo sed -i 's/tar -I lbzip2 -xpmf/tar -I lbzip2 --keep-directory-symlink -xpmf/g' Linux_for_Tegra/apply_binaries.sh

# Modify nv_customize_rootfs.sh file
sudo sed -i '/ARM_ABI_DIR_ABS="usr\/lib\/aarch64-linux-gnu"/a \ \ \ \ elif [ -d "${LDK_ROOTFS_DIR}\/usr\/lib\/tegra" ]; then\n\ \ \ \ \ \ \ \ ARM_ABI_DIR="${LDK_ROOTFS_DIR}\/usr\/lib"\n' Linux_for_Tegra/nv_tools/scripts/nv_customize_rootfs.sh

# Create required folders
mkdir Linux_for_Tegra/nv_tegra/nvidia_drivers Linux_for_Tegra/nv_tegra/config Linux_for_Tegra/nv_tegra/nv_tools Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps

echo -e "${RED}Done, ${WHITE}extracting NVIDIA archives..."

# Extract and move the contents of nvidia_drivers
sudo tar -xpjf Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2 -C Linux_for_Tegra/nv_tegra/nvidia_drivers/
sudo rm -r Linux_for_Tegra/nv_tegra/nvidia_drivers.tbz2

sudo tar -xpjf Linux_for_Tegra/nv_tegra/config.tbz2 -C Linux_for_Tegra/nv_tegra/config/
sudo rm -r Linux_for_Tegra/nv_tegra/config.tbz2

sudo tar -xpjf Linux_for_Tegra/nv_tegra/nv_tools.tbz2 -C Linux_for_Tegra/nv_tegra/nv_tools/
sudo rm -r Linux_for_Tegra/nv_tegra/nv_tools.tbz2

sudo tar -xpjf Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps.tbz2 -C Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps/
sudo rm -r Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps.tbz2

sudo mv Linux_for_Tegra/nv_tegra/nvidia_drivers/lib/* Linux_for_Tegra/nv_tegra/nvidia_drivers/usr/lib/
sudo rm -r Linux_for_Tegra/nv_tegra/nvidia_drivers/lib/

sudo mv Linux_for_Tegra/nv_tegra/nvidia_drivers/usr/lib/aarch64-linux-gnu/* Linux_for_Tegra/nv_tegra/nvidia_drivers/usr/lib/
sudo rm -r Linux_for_Tegra/nv_tegra/nvidia_drivers/usr/lib/aarch64-linux-gnu/

echo -e "${RED}Extracted, ${WHITE}modifying configs..."

# Modify nvidia-tegra.conf
sudo sed -i 's/\/usr\/lib\/aarch64-linux-gnu\/tegra\//\/usr\/lib\/tegra\//g' Linux_for_Tegra/nv_tegra/nvidia_drivers/etc/nv_tegra_release

# Modify nvidia-tegra.conf
sudo sed -i '$a/usr/lib/tegra-egl' Linux_for_Tegra/nv_tegra/nvidia_drivers/etc/ld.so.conf.d/nvidia-tegra.conf

# Move contents of nvgstapps
sudo mv Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps/usr/lib/aarch64-linux-gnu/* Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps/usr/lib/
sudo rm -r Linux_for_Tegra/nv_tegra/nv_sample_apps/nvgstapps/usr/lib/aarch64-linux-gnu/

echo -e "${RED}Done, ${WHITE}Repackaging Tegra files..."

# Repackage the files
cd Linux_for_Tegra/nv_tegra/nvidia_drivers
sudo tar -cpjf ../nvidia_drivers.tbz2 *

cd ../config
sudo tar -cpjf ../config.tbz2 *

cd ../nv_tools
sudo tar -cpjf ../nv_tools.tbz2 *

cd ../nv_sample_apps/nvgstapps
sudo tar -cpjf ../nvgstapps.tbz2 *

cd ../../../..
echo -e "${RED}Done, ${WHITE}creating service file and init script..."

# Modify pacman.conf
sudo sed -i 's/#IgnorePkg   =/IgnorePkg=linux-aarch64/g' Linux_for_Tegra/rootfs/etc/pacman.conf

# Create systemd service file
echo '[Unit]
Description=The NVIDIA tegra init script

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/nvidia-tegra-init-script

[Install]
WantedBy=multi-user.target' | sudo tee Linux_for_Tegra/rootfs/usr/lib/systemd/system/nvidia-tegra.service > /dev/null

# Create nvidia-tegra-init-script
echo '#!/bin/bash

if [ -e /sys/power/state ]; then
    chmod 0666 /sys/power/state
fi

if [ -e /sys/devices/soc0/family ]; then
    SOCFAMILY="\$(cat /sys/devices/soc0/family)"
fi

if [ "\$SOCFAMILY" = "Tegra210" ] &&
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
    uartNode="/dev/ttyHS\$uartInst"
    if [ -e "\$uartNode" ]; then
        ln -s /dev/ttyHS\$uartInst /dev/ttyTHS\$uartInst
    fi
done

machine=\$(cat /sys/devices/soc0/machine)
if [ "\${machine}" = "jetson-nano-devkit" ] ; then
    echo 4 > /sys/class/graphics/fb0/blank
    BoardRevision=\$(cat /proc/device-tree/chosen/board_info/major_revision)
    if [ "\${BoardRevision}" = "A" ] ||
            [ "\${BoardRevision}" = "B" ] ||
            [ "\${BoardRevision}" = "C" ] ||
            [ "\${BoardRevision}" = "D" ]; then
        echo 0 > /sys/devices/platform/tegra-otg/enable_device
        echo 1 > /sys/devices/platform/tegra-otg/enable_host
    fi
fi

if [ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
    read governors < /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
    case \$governors in
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

echo "Success! Exiting!"
exit 0' | sudo tee Linux_for_Tegra/rootfs/usr/bin/nvidia-tegra-init-script > /dev/null

echo -e "${RED}Applying Binaries (apply_binaries.sh)${YELLOW}"

cd Linux_for_Tegra
sudo ./apply_binaries.sh --target-overlay | sed 's/^/    /'

echo -e "${RED}Done, ${WHITE}creating symlinks"

sudo cp rootfs/usr/lib/ld-linux-aarch64.so.1 rootfs/lib/ld-linux-aarch64.so.1

cd rootfs/etc/systemd/system/sysinit.target.wants/
sudo ln -s ../../../../usr/lib/systemd/system/nvidia-tegra.service nvidia-tegra.service

echo -e "${RED}Done, ${WHITE}Script has Finished!${RESET}"
