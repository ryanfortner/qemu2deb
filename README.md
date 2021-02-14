# qemu2deb-RPi
Compiling/packaging/installing QEMU on the Raspberry Pi made easier than ever.
### This script was only tested on a Raspberry Pi 4 4gb running TwisterOS, the script should work on any Debian based armhf OS though.<br>the script DOES NOT work on arm64 and support for arm64 ISN'T planned!*
## **THIS SCRIPT WILL NOT WORK ON A X86 COMPUTER!***
*: to package QEMU for arm64 and x86 use checkinstall, it works perfectly fine.

## Usage:
<!--
1) Download the script: you can get the latest release [here](https://raw.githubusercontent.com/Itai-Nelken/qemu2deb-RPi/0.3.1/qemu2deb.sh) the newest "bleeding edge" stable version [here](https://raw.githubusercontent.com/Itai-Nelken/qemu2deb-RPi/main/qemu2deb.sh), and the Beta version [here](https://raw.githubusercontent.com/Itai-Nelken/qemu2deb-RPi/Dev/qemu2deb.sh) (the Beta version isn't always available). you can use `wget` to download the script or simply copy-and-paste the contents to a file called `qemu2deb.sh`.
2) give it executable permissions: `sudo chmod +x qemu2deb.sh`
-->
1) Download the deb file from the latest release [here](https://github.com/Itai-Nelken/qemu2deb-RPi/releases/latest).
2) Install it using this command: `sudo dpkg -i qemu2deb_*_armhf.deb` or using your favorite graphical app/command.
3) to run the qemu2deb script, type the following in terminal (works from any location): `qemu2deb`<br>
**For a full walkthrough, read [USAGE.md](USAGE.md)**<br>
NOTE: don't run the script as root! if you do, the script will warn you and exit.<br>
if you have passwordless root access **disabled**, you will have to enter your password at least once while running the script.

## How it works
First the script asks you where is your working directory, then if you tell it QEMU isn't compiled and installed yet, it will compile and install it.
after it has the QEMU directory and your working directory and QEMU is installed on your system, it will copy all the QEMU files to a temporary folder, create the DEBIAN/control file and package the temporary folder to a deb using `dpkg-deb`.
after packaging is complete, the script will clean up after itself.

## [Changelog](CHANGELOG.md)

## compatibility list:

| OS               | ARCHITECTURE | SHOULD WORK | TESTED AND WORKS     | TESTED AND NOT WORKING          | if not working right now, will it work in the future |
| :---:            | :---:        |     :---:   |         :---:        |         :---:                   |    :---:                                             |
| TwisterOS        | armhf        | yes         | works perfectly fine | N/A                             | yes                                                  |
| RPiOS            | armhf        | yes         | N/A                  | N/A                             | yes                                                  |
| RPiOS 64bit beta | arm64        | not really  | N/A                  | it doesn't work on RPiOS arm64. | **NO** use checkinstall                              |
| Ubuntu 64bit (stock, MATE, etc.) | arm64 | no | N/A | N/A | **NO** use checkinstall |
| Ubuntu 32bit (stock, MATE, etc. using desktopify) | armhf | maybe | N/A | N/A | if checkinstall doesn't work, *yes* |

### Tested on another OS and have problems? feel free to open a issue [here](https://github.com/Itai-Nelken/qemu2deb-RPi/issues/new/choose)!
### Used on one of the OS's on the table above but the script isn't working? feel free to open a issue [here](https://github.com/Itai-Nelken/qemu2deb-RPi/issues/new/choose)!
### have a fix, suggestion or a bug to report? feel free to open a issue or a Pull request!


## FAQ:
### Q = question<br>A = answer

**Q:**
>why did you create this script?

**A:**
>because compiling QEMU on the Raspberry Pi takes over an hour, and I wanted to have a easy and fast way to install QEMU because I switch OS's a lot.
first I tried using checkinstall, but it didn't work, so after trying a lot of fixes and ways I decided to create the deb manually.
I tracked down all the qemu files on my system, put them in a folder, created the DEBIAN/control file, and pakaged it. to my surprise it worked, but I got a error that the bios wasn't found. after searching a bit I found the issue: broken links. I found the files the links pointed to and copied them over to the folder, then packaged it again.
this time I messed up the two debs, so I deleted both debs, and packaged one again. this time it worked!
so I started to write this script for my own use. once I saw how well it was working, and how much time it was saving me, I decided to make a repo for it so other people can use it.
I hope you enjoy using this script and find it useful, it took me a week to get it working correctly, and A whole year almost of trying different ways to package it, and I don't want anyone else to have to go through this.
