#!/bin/bash

#function that runs when ctrl+c is pressed
function ctrl_c() {
    echo -e "\n$(tput setaf 3)$(tput bold)you have pressed CTRL+C, do you want the script to clean up? BEWARE: you will get errors! (y/n)$(tput sgr 0)" 
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
        echo -e "$(tput setaf 3)$(tput bold)cleaning up...$(tput sgr 0)"
        sleep 0.3
        #ask to uninstall QEMU
        echo -e "do you want to uninstall QEMU? $(tput bold)[recommended]$(tput sgr 0) (y/n)?"
        while true; do
            read answer
            if [[ "$answer" =~ [yY] ]]; then
                CONTINUE=1
                break
            elif [[ "$answer" =~ [nN] ]]; then
                CONTINUE=0
                break
            else
                echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
            fi
        done
    if [[ "$CONTINUE" == 1 ]]; then
        if [[ ! -z "$QBUILD" ]]; then
            cd $QBUILD
            sudo ninja uninstall
            cd $DIRECTORY
        else
            cd $DIRECTORY/qemu
            sudo ninja uninstall
            cd $DIRECTORY
        fi
    elif [[ "$CONTINUE" == 0 ]]; then
        echo "won't uninstall QEMU."
    fi
    CONTINUE=12
    #ask to delete the QEMU build folder
    echo "do you want to delete the qemu build folder (y/n)?"
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
       cd $QBUILD || echo -e "$(tput setaf 3)$(tput bold)Failed to change Directory!$(tput sgr 0)"
       cd .. || echo -e "$(tput setaf 3)$(tput bold)Failed to change Directory!$(tput sgr 0)"
       sudo rm -rf qemu || echo -e "$(tput setaf 3)$(tput bold)Failed to delete QEMU build folder!$(tput sgr 0)"
    elif [[ "$CONTINUE" == 0 ]]; then
       echo "won't remove $QBUILD"
    fi
    CONTINUE=12

    #ask to delete the unpacked deb folder
    read -p "do you want to delete the unpacked DEB (y/n)?" choice
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
       sudo rm -r qemu-$QVER-$ARCH || echo -e "$(tput setaf 3)$(tput bold)Failed to delete unpacked deb!$(tput sgr 0)"
    elif [[ "$CONTINUE" == 0 ]]; then
       echo "won't remove unpacked DEB"
    fi
    CONTINUE=12

    #if QEMU was compiled, ask to uninstall the build dependencies that were installed
    if [[ "$QBUILDV" == "1" ]]; then
        echo -e "do you wan't to remove the qemu build dependencies: $(tput setaf 3)$(tput sgr 0)"
        echo "'$TOINSTALL'. (y/n)?"
        while true; do
            read answer
            if [[ "$answer" =~ [yY] ]]; then
                CONTINUE=1
                break
            elif [[ "$answer" =~ [nN] ]]; then
                CONTINUE=0
                break
            else
                echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
            fi
        done
        if [[ "$CONTINUE" == "1" ]]; then
            pkg-manage uninstall "$TOINSTALL"
        elif [[ "$CONTINUE" == "0" ]]; then
            echo "won't remove dependencies"
        fi
        CONTINUE=12
    fi
    elif [[ "$CONTINUE" == 0 ]]; then
        echo "ok."
        sleep 1
    fi
    exit 2
}
#make the ctr_c function run if ctrl+c is pressed
trap "ctrl_c" 2

#check that script isn't being run as root.
if [ "$EUID" = 0 ]; then
  echo "You cannot run this script as root!"
  exit 1
fi

#variables
#CORES="`nproc`"

#check that OS arch is armhf
ARCH="`uname -m`"
if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "x86" ]] || [[ "$ARCH" == "i386" ]]; then
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        ARCH="amd64"
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        ARCH="i386"
    else
        echo -e "$(tput setaf 1)$(tput bold)Can't detect OS architecture! something is very wrong!$(tput sgr 0)"
        exit 1
    fi
elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "armv7l" ]] || [[ "$ARCH" == "armhf" ]]; then
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        ARCH="arm64"
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        ARCH="armhf"
    else
        echo -e "$(tput setaf 1)$(tput bold)Can't detect OS architecture! something is very wrong!$(tput sgr 0)"
        exit 1
    fi
else
    echo -e "$(tput setaf 1)$(tput bold)ERROR: '$ARCH' isn't a supported architecture!$(tput sgr 0)"
    exit 1
fi

#get machine name (not really, only for the Raspberry Pi)
RPI=$(grep ^Model /proc/cpuinfo  | cut -d':' -f2- | sed 's/ R/R/')
if [[ "$RPI" == *"Raspberry Pi"* ]]; then
    DEVICE="the Raspberry Pi and other $ARCH devices"
else
    DEVICE="Linux $ARCH devices."
fi


#script version variable
APPVER="0.6.0"

#functions
function intro() {
    echo -e "
    ###########################################
    #  QEMU2DEB $APPVER by Itai-Nelken | 2021   #
    #-----------------------------------------#
    #      compile/package/install QEMU       #
    ###########################################
    "
}

function error() {
    echo -e "$(tput setaf 1)$(tput bold)$1$(tput sgr 0)"
    exit 1
}

function warning() {
    echo -e "$(tput setaf 3)$(tput bold)$1$(tput sgr 0)"
    sleep 5
}

function help() {
    #usage
    echo -e "$(tput bold)$(tput setaf 6)usage:$(tput sgr 0)"
    echo "./qemu2deb.sh [flags]"
    #new line
    echo " "
    #available flags
    echo -e "$(tput setaf 6)available flags:$(tput sgr 0)"
    echo "--version  -  display version and exit."
    echo "--help  -  display this help."
    #short flags
    echo -e "$(tput bold)You can also use shorter versions of the flags:$(tput sgr 0)"
    echo "-h = --help"
    echo "-v = --version"
    #about architectures
    echo -e "$(tput bold)Compatibility:$(tput sgr 0)"
    echo -e "this script only works on $(tput bold)armhf (arm32), arm64 (aarch64), x86 (i386), x86_64 (amd64)$(tput sgr 0) OS's,"
}


function install-deb() {
    echo "do you want to install the DEB (y/n)?"
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
        cd $DIRECTORY
        sudo apt -f -y install ./qemu-$QVER-$ARCH.deb || error "Failed to install the deb!"
    elif [[ "$CONTINUE" == 0 ]]; then
        clear -x
    fi
}

function clean-up() {
    echo -e "$(tput setaf 3)$(tput bold)cleaning up...$(tput sgr 0)"
    sleep 0.3

    #ask to uninstall QEMU
    echo -e "do you want to uninstall QEMU? $(tput bold)[recommended]$(tput sgr 0) (y/n)?"
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
        if [[ ! -z "$QBUILD" ]] && [[ "$QBUILD" != "s" ]]; then
            cd $QBUILD
            sudo ninja uninstall || error "Failed to run 'sudo ninja uninstall'!"
            cd $DIRECTORY
        else
            cd $DIRECTORY/qemu
            sudo ninja uninstall || error "Failed to run 'sudo ninja uninstall'!"
            cd $DIRECTORY
        fi
    elif [[ "$CONTINUE" == 0 ]]; then
        echo "won't uninstall QEMU."
    fi
    CONTINUE=12

    #ask to install qemu from the deb.
    echo "do you want to install QEMU from the deb (y/n)?"
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
        cd $DIRECTORY
        sudo apt -f -y install ./qemu-$QVER-$ARCH.deb || error "Failed to install the deb!"
    elif [[ "$CONTINUE" == 0 ]]; then
        clear -x
    fi
    CONTINUE=12

    #ask to delete the QEMU build folder
    echo "do you want to delete the qemu build folder (y/n)?"
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
       cd $QBUILD || error "Failed to change Directory!"
       cd .. || error "Failed to change Directory!"
       sudo rm -rf qemu || error "Failed to delete QEMU build folder!"
    elif [[ "$CONTINUE" == 0 ]]; then
       echo "won't remove $QBUILD"
    fi
    CONTINUE=12

    #ask to delete the unpacked deb folder
    read -p "do you want to delete the unpacked DEB (y/n)?" choice
    while true; do
        read answer
        if [[ "$answer" =~ [yY] ]]; then
            CONTINUE=1
            break
        elif [[ "$answer" =~ [nN] ]]; then
            CONTINUE=0
            break
        else
            echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
        fi
    done
    if [[ "$CONTINUE" == 1 ]]; then
       sudo rm -r qemu-$QVER-$ARCH || error "Failed to delete unpacked deb!"
    elif [[ "$CONTINUE" == 0 ]]; then
       echo "won't remove unpacked DEB"
    fi
    CONTINUE=12

    #if QEMU was compiled, ask to uninstall the build dependencies that were installed
    if [[ "$QBUILDV" == "1" ]]; then
        echo -e "do you wan't to remove the qemu build dependencies: $(tput setaf 3)$(tput sgr 0)"
        echo "'$TOINSTALL'. (y/n)?"
        while true; do
            read answer
            if [[ "$answer" =~ [yY] ]]; then
                CONTINUE=1
                break
            elif [[ "$answer" =~ [nN] ]]; then
                CONTINUE=0
                break
            else
                echo -e "$(tput setaf 3)invalid option '$answer', please try again.$(tput sgr 0)"
            fi
        done
        if [[ "$CONTINUE" == "1" ]]; then
            pkg-manage uninstall "$TOINSTALL"
            pkg-manage clean
        elif [[ "$CONTINUE" == "0" ]]; then
            echo "won't remove dependencies"
        fi
        CONTINUE=12
    fi
}

#this variable holds all the QEMU build dependencies
DEPENDS="build-essential ninja-build libepoxy-dev libdrm-dev libgbm-dev libx11-dev libvirglrenderer-dev libpulse-dev libsdl2-dev git libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev libepoxy-dev libdrm-dev libgbm-dev libx11-dev libvirglrenderer-dev libpulse-dev libsdl2-dev"

function pkg-manage() {
    #usage: pkg-manage install "package1 package2 package3"
    #pkg-manage uninstall "package1 package2 package3"
    #pkg-manage check "packag1 package2 package3"
    #pkg-manage clean
    #
    #$1 is the operation: install or uninstall
    #$2 is the packages to operate on.
    if [[ "$1" == "install" ]]; then
        TOINSTALL="$(dpkg -l $2 2>&1 | awk '{if (/^D|^\||^\+/) {next} else if(/^dpkg-query:/) { print $6} else if(!/^[hi]i/) {print $2}}' | tr '\n' ' ')"
        sudo apt -f -y install $TOINSTALL || sudo apt -f -y install "$TOINSTALL"
    elif [[ "$1" == "uninstall" ]]; then
        sudo apt purge $2 -y
    elif [[ "$1" == "check" ]]; then
        TOINSTALL="$(dpkg -l $2 2>&1 | awk '{if (/^D|^\||^\+/) {next} else if(/^dpkg-query:/) { print $6} else if(!/^[hi]i/) {print $2}}' | tr '\n' ' ')"  
    elif [[ "$1" == "clean" ]]; then
        sudo apt clean
        sudo apt autoremove -y
        sudo apt autoclean
    else
        error "operation not specified!"
    fi
}

function compile-qemu() {
    cd $DIRECTORY || error "Failed to change directory!"
    echo -e "$(tput setaf 6)cloning QEMU git repo...$(tput sgr 0)"
    git clone https://git.qemu.org/git/qemu.git || error "Failed to clone QEMU git repo!"
    cd qemu || error "Failed to change Directory!"
    git submodule init || error "Failed to run 'git submodule init'"
    git submodule update --recursive || error "Failed to run 'git submodule update --recursive'!"
    echo "$(tput setaf 6)running ./configure...$(tput sgr 0)"
    ./configure --enable-sdl  --enable-opengl --enable-virglrenderer --enable-system --enable-modules --audio-drv-list=pa --enable-kvm || error "Failed to run './configure'!"
    echo "$(tput setaf 6)compiling QEMU...$(tput sgr 0)"
    #make -j$CORES || error "Failed to run make -j$CORES!"
    #sudo make install || error "Failed to run 'sudo make install'!"
    ninja -C build  || error "Failed to run ninja -C build'!"
    echo -e "$(tput setaf 6)nstalling QEMU...$(tput sgr 0)"
    sudo ninja install -C build || error "Failed to install QEMU with 'sudo ninja install -C build'!"
}

function make-deb() {
    #get QEMU version
    QVER="`qemu-system-ppc --version | grep version | cut -c23-28`" || QVER="`qemu-system-i386 --version | grep version | cut -c23-28`" || QVER="`qemu-system-arm --version | grep version | cut -c23-28`" || error "Failed to get QEMU version! is the full version installed?"
    #get all files inside a folder before building deb
    clear -x
    echo "copying files..."
    echo -ne '(0%)[#                         ](100%)\r'
    sleep 0.1
    cd $DIRECTORY || error "Failed to change directory to $DIRECTORY!"
    mkdir qemu-$QVER-$ARCH || error "Failed to create unpacked deb folder!"
    echo -ne '(0%)[##                        ](100%)\r'
    sleep 0.1
    cd qemu-$QVER-$ARCH || error "Failed to change Directory to $DIRECTORY/qemu-$QVER-$ARCH!"
    #mkdir -p usr/include/linux/ || error "Failed to create $DIRECTORY/qemu-$QVER-$ARCH/usr/include/linux/!"
    #cp /usr/include/linux/qemu_fw_cfg.h qemu-$QVER-$ARCH/usr/include/linux/
    sleep 0.1
    echo -ne '(0%)[###                       ](100%)\r'
    mkdir -p usr/local/bin
    cp /usr/local/bin/qemu* $DIRECTORY/qemu-$QVER-$ARCH/usr/local/bin
    echo -ne '(0%)[####                      ](100%)\r'
    mkdir -p usr/local/lib/
    sudo cp -r /usr/local/lib/qemu/ $DIRECTORY/qemu-$QVER-$ARCH/usr/local/lib
    echo -ne '(0%)[#####                     ](100%)\r'
    mkdir -p usr/local/libexec
    cp /usr/local/libexec/qemu-bridge-helper $DIRECTORY/qemu-$QVER-$ARCH/usr/local/libexec
    sleep 0.1
    echo -ne '(0%)[########                  ](100%)\r'
    mkdir -p usr/local/share/
    cp -r /usr/local/share/qemu/ $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share
    #mkdir -p usr/share/bash-completion/completions/
    #cp /usr/share/bash-completion/completions/qemu* $DIRECTORY/qemu-$QVER-$ARCH/usr/share/bash-completion/completions/
    mkdir -p usr/local/share/applications
    cp /usr/local/share/applications/qemu.desktop $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/applications/
    sleep 0.1
    echo -ne '(0%)[##########                ](100%)\r'
    mkdir -p usr/local/share/icons/hicolor/16x16/apps
    mkdir -p usr/local/share/icons/hicolor/24x24/apps
    sleep 0.05
    echo -ne '(0%)[#############             ](100%)\r'
    sleep 0.1
    mkdir -p usr/local/share/icons/hicolor/32x32/apps
    mkdir -p usr/local/share/icons/hicolor/48x48/apps
    sleep 0.01
    echo -ne '(0%)[##############            ](100%)\r'
    mkdir -p usr/local/share/icons/hicolor/64x64/apps
    mkdir -p usr/local/share/icons/hicolor/128x128/apps
    echo -ne '(0%)[###############           ](100%)\r'
    mkdir -p usr/local/share/icons/hicolor/256x256/apps
    mkdir -p usr/local/share/icons/hicolor/512x512/apps
    sleep 0.1
    echo -ne '(0%)[################          ](100%)\r'
    mkdir -p usr/local/share/icons/hicolor/scalable/apps
    cp /usr/local/share/icons/hicolor/16x16/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/16x16/apps
    cp /usr/local/share/icons/hicolor/24x24/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/24x24/apps
    echo -ne '(0%)[###################       ](100%)\r'
    cp /usr/local/share/icons/hicolor/32x32/apps/qemu.bmp $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/32x32/apps
    cp /usr/local/share/icons/hicolor/32x32/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/32x32/apps
    cp /usr/local/share/icons/hicolor/48x48/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/48x48/apps
    cp /usr/local/share/icons/hicolor/64x64/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/64x64/apps
    sleep 0.2
    echo -ne '(0%)[#####################     ](100%)\r'
    cp /usr/local/share/icons/hicolor/128x128/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/128x128/apps
    cp /usr/local/share/icons/hicolor/256x256/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/256x256/apps
    sleep 0.001
    echo -ne '(0%)[########################  ](100%)\r'
    cp /usr/local/share/icons/hicolor/512x512/apps/qemu.png $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/512x512/apps
    sleep 0.1
    echo -ne '(0%)[######################### ](100%)\r'
    cp /usr/local/share/icons/hicolor/scalable/apps/qemu.svg $DIRECTORY/qemu-$QVER-$ARCH/usr/local/share/icons/hicolor/scalable/apps
    sleep 0.1
    echo -ne '(0%)[##########################](100%)\r'
    sleep 0.5
}



##################################################################
##################################################################
##########The part where things actually start to happen##########
##################################################################
##################################################################

##########help and version flags##########
if  [[ $1 == "--version" ]] || [[ $1 == "-v" ]]; then
    intro
    exit 0
elif [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
    help
    exit 0
fi

#clear -x the screen
clear -x
#run the "intro" function
intro
#print a blank line
echo ' '
#ask for directory path, if doesn't exist ask again. if exists exit loop.
while true; do
    read -p "Enter full path to directory where you want to make the deb:" DIRECTORY
    if [ ! -d $DIRECTORY ]; then
        echo -e "$(tput bold)directory does not exist, please try again$(tput sgr 0)"
    else
        echo -e "$(tput bold)qemu will be built and packaged here: $DIRECTORY$(tput sgr 0)"
        break
    fi
done

#sleep 2 seconds and clear -x the screen
sleep 2
echo " "
#ask if you already compiled QEMU, if yes enter full path (same as other loop), if you press s, the loop exits.
while true; do
    read -p "If you already compiled and installed QEMU (with sudo ninja install -C build), enter the path to its folder. otherwise press s:" QBUILD
    if [[ "$QBUILD" == s ]]; then
        echo "QEMU will be compiled..."
        QBUILDV=1
        break
    fi
    if [ ! -d $QBUILD ]; then
        echo -e "$(tput bold)directory does not exist, please try again$(tput sgr 0)"
    else
        echo -e "$(tput bold)qemu is already built here: $QBUILD$(tput sgr 0)"
        QBUILDV=0
        break
    fi
done

#wait 1.5 seconds and clear -x the screen
sleep 1.5
clear -x

#if QEMU needs to be compiled, do so
if [[ "$QBUILDV" == 1 ]]; then
    echo -e "$(tput setaf 6)$(tput bold)QEMU will now be compiled, this will take over a hour and consume all CPU.$(tput sgr 0)"
    echo -e "$(tput setaf 6)$(tput bold)cooling is recommended.$(tput sgr 0)"
    read -p "Press [ENTER] to continue"
    #check what dependencies aren't installed and install them
    pkg-manage install "$DEPENDS" || error "Failed to install dependencies"
    compile-qemu || error "Failed to run compile-qemu function"
elif [[ "$QBUILDV" == 0 ]]; then
    read -p "do you want to install QEMU (run 'sudo ninja install -C build') (y/n)?" choice
    case "$choice" in 
      y|Y ) CONTINUE=1 ;;
      n|N ) CONTINUE=0 ;;
      * ) echo "invalid" ;;
    esac
    if [[ "$CONTINUE" == 1 ]]; then
        cd $QBUILD || error "Failed to change directory to $QBUILD"
        sudo ninja install -C build || error "Failed to run 'sudo make install'"
    elif [[ "$CONTINUE" == 0 ]]; then
        if ! command -v qemu-img >/dev/null || ! command -v qemu-system-ppc >/dev/null || ! command -v qemu-system-i386 >/dev/null ;then
            error "QEMU isn't installed! can't continue!"
        else
            echo "assuming QEMU is installed..."
        fi
    fi
fi

sleep 3
#clear -x the screen again
clear -x
#print the summary so far and ask to continue
printf "$(tput bold)\\e[3;4;37mSummary:\\n\\e[0m$(tput sgr 0)"
echo "the DEB will be built here: $DIRECTORY"
if [[ "$QBUILDV" == 1 ]]; then
    echo "QEMU was compiled here: $DIRECTORY/qemu"
elif [[ "$QBUILDV" == 0 ]]; then
    echo "QEMU is already compiled here: $QBUILD"
fi
read -p "Press [ENTER] to continue or [CTRL+C] to cancel"


#start making the deb folder (unpacked deb)
echo -e "$(tput setaf 6)$(tput bold)QEMU will now be packaged into a DEB, this will take a few minutes and consume all CPU.$(tput sgr 0)"
echo -e "$(tput setaf 6)$(tput bold)cooling is recommended. $(tput sgr 0)"
read -p "Press [ENTER] to continue"
#copy all files using the 'make-deb' function
make-deb || error "Failed to run make-deb function!"
echo -e "\ncreating DEBIAN folder..."
mkdir DEBIAN || error "Failed to create DEBIAN folder!"
cd DEBIAN || error "Failed to change to DEBIAN folder!"
sleep 2
clear -x
echo -e "creating control file..."
#ask for maintainer info
echo -e "$(tput setaf 3)$(tput bold)enter maintainer info:$(tput sgr 0)"
read MAINTAINER
clear -x

#create DEBIAN/control
cd $DIRECTORY/qemu-$QVER-$ARCH/DEBIAN
echo "Maintainer: $MAINTAINER 
Summary: QEMU $QVER $ARCH for $DEVICE built using qemu2deb.
Name: qemu 
Description: QEMU $QVER $ARCH built using QEMU2DEB for $DEVICE.
Version: 1:$QVER 
Release: 1 
License: GPL 
Architecture: $ARCH 
Provides: qemu
Priority: optional
Section: custom
Recommends: bash-completion
Conflicts: qemu-utils, qemu-system-common, qemu-system-gui, qemu-system-ppc, qemu-block-extra, qemu-guest-agent, qemu-kvm, qemu-system-arm, qemu-system-common, qemu-system-mips, qemu-system-misc, qemu-system-sparc, qemu-system-x86, qemu-system, qemu-user-binfmt, qemu-user-static, qemu-user, qemu, openbios-sparc, openbios-ppc, openbios-sparc, seabios, openhackware, qemu-slof, ovmf
Package: qemu" > control || error "Failed to create control file!"
#give it the necessary permissions
sudo chmod 775 control || error "Failed to change control file permissions!"
cd .. || error "Failed to go directory up!"
cd .. || error "Failed to go directory up!"
#build the DEB
sudo dpkg-deb --build qemu-$QVER-$ARCH/ || error "Failed to build the deb using dpkg-deb!"
sudo chmod 606 qemu-$QVER-$ARCH.deb || warning "WARNING: Failed to give the deb '606' permissions!"

echo -e "$(tput setaf 3)$(tput bold)DONE...$(tput sgr 0)"
echo "qemu deb will be in $DIRECTORY/qemu-$QVER-$ARCH.deb"
read -p "Press [ENTER] to continue"
clear -x

#clean up
clean-up || error "Failed to run clean-up function!"

echo -e "$(tput setaf 2)$(tput bold)DONE!$(tput sgr 0)"
echo "exiting in 5 seconds..."
sleep 5
exit 0
