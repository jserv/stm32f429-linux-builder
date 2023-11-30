stm32f429-linux-builder
======================
This is a simple tool designed to create a uClinux distribution for STM32f429
Discovery board from [STMicroelectronics](http://www.st.com/). STM32F429 MCU
offers the performance of ARM Cortex M4 core (with floating point unit) running
at 180 MHz while reaching reasonably lower static power consumption.


Prerequisites
=============
The builder requires that various tools and packages be available for use in
the build procedure:

* [OpenOCD](http://openocd.sourceforge.net/)
  - OpenOCD 0.7.0 (and the 0.7.0-2 from Debian) can't write romfs to flash
    because of a post-0.7.0-stable bug (bad flash detection on stm32f429).
    You need to use 0.8.0 development version.
```
    git clone git://git.code.sf.net/p/openocd/code openocd
    cd openocd
    ./bootstrap
    ./configure --prefix=/usr/local --enable-stlink
    echo -e "all:\ninstall:" > doc/Makefile
    make
    sudo make install
```
* Set ARM/uClinux Toolchain:
  - Download [arm-2010q1-189-arm-uclinuxeabi-i686-pc-linux-gnu.tar.bz2](https://sourcery.mentor.com/public/gnu_toolchain/arm-uclinuxeabi/arm-2010q1-189-arm-uclinuxeabi-i686-pc-linux-gnu.tar.bz2) from Mentor Graphics
  - only arm-2010q1 is known to work; don't use SourceryG++ arm-2011.03
```
    tar jxvf arm-2010q1-189-arm-uclinuxeabi-i686-pc-linux-gnu.tar.bz2
    export PATH=`pwd`/arm-2010q1/bin:$PATH
```
* [genromfs](http://romfs.sourceforge.net/)
```
    sudo apt-get install genromfs
```
* GNU Toolchain

  - We extensively rely on the GNU toolchain to streamline our development process. At its core, we utilize the "Make" utility as the orchestration engine, automating the compilation and building of our source code. With a meticulously crafted Makefile, we define rules and dependencies necessary for compiling, linking, and generating binary images from our codebase.


  - Open a terminal and update your package repository to ensure you have the latest information about available packages.

```bash
    sudo apt update
```
  - Use the package manager to install the GNU Toolchain, which includes tools like gcc, g++, and binutils.

```bash
    sudo apt-get install build-essential
```

  - After the installation is complete, you can verify it by checking the installed version of GCC.

```bash
    gcc --version
```
* STLINK Tools
  - To facilitate programming and downloading firmware to the microcontroller, we use the ST-Link V2, a critical component in our project workflow. Here are the steps for its installation:

```bash
    cd ~
    git clone https://github.com/texane/stlink.git
    cd ./stlink
    sudo apt-get install libusb-1.0-0-dev
    sudo apt-get -y install cmake
    sudo apt-get install libstlink1
    make
    cd build/Release
    sudo make install
```

  - To verify the successful installation of ST-Link V2 and confirm its functionality, execute the following command:
```bash
    st-flash
```
  - Upon execution, the terminal should display a response indicating that ST-Link V2 is installed and ready for use.

Build Instructions
==================
* Simply execute ``make``, and it will fetch and build u-boot, linux kernel, and busybox from scratch:
```
    make
```
* Once STM32F429 Discovery board is properly connected via USB wire to Linux host, you can execute ``make install`` to flash the device. Note: you have to ensure the installation of the latest OpenOCD in advance.
```
    make install
```
Be patient when OpenOCD is flashing. Typically, it takes about 55 seconds.
Use `make help` to get detailed build targets.


## 64-bit System Support
Since the ARM-2010q1 toolchain is intended for 32-bit systems and if your system is 64-bit, you'll need to enable 32-bit support and install necessary libraries. Execute the following commands:
```bash
    sudo dpkg --add-architecture i386
    sudo apt-get update
    sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386
```

## "timeconst.pl" Script Error 
To resolve the Perl-related error, we need to edit the "timeconst.pl" script. We can use a text editor like nano:
```bash
    nano uclinux/kernel/timeconst.pl
```
In the "timeconst.pl" script, locate the problematic line (line 373) that checks for defined array values. Change the line from:
```perl
    if (! defined(@val)) {
```
to:
```perl
    if (!@val) {
```
This modification adjusts the logic to check if the array @val is empty rather than if it’s defined. Save the changes to the "timeconst.pl" file and exit the text editor.
After making the modification, attempt to build the kernel again:
```bash
    make
```
Now, the build process should proceed without encountering the Perl-related error, enabling the successful building of the kernel for our STM32F429 project.

USART Connection
================
The STM32F429 Discovery is equipped with various USARTs. USART stands for
Universal Synchronous Asynchronous Receiver Transmitter. The USARTs on the
STM32F429 support a wide range of serial protocols, the usual asynchronous
ones, plus things like IrDA, SPI etc. Since the STM32 works on 3.3V levels,
a level shifting component is needed to connect the USART of the STM32F429 to
a PC serial port.

Most PCs today come without an native RS232 port, thus an USB to serial
converter is also needed.

For example, we can simply connect the RX of the STM32 USART3 to the TX of
the converter, and the TX of the USART3 to the RX of the converter:
* pin PC10 -> TXD
* pin PC11 -> RXD


Reference Boot Messages
=======================
```
U-Boot 2010.03-00003-g934021a ( Feb 09 2014 - 17:42:47)

CPU  : STM32F4 (Cortex-M4)
Freqs: SYSCLK=180MHz,HCLK=180MHz,PCLK1=45MHz,PCLK2=90MHz
Board: STM32F429I-DISCOVERY board,Rev 1.0
DRAM:   8 MB
Using default environment

Hit any key to stop autoboot:  0 
## Booting kernel from Legacy Image at 08020000 ...
...

Starting kernel ...

Linux version 2.6.33-arm1 (jserv@venux) (gcc version 4.4.1 (Sourcery G++ Lite 2010q1-189) ) #2 Sun Feb 9 17:54:20 CST 2014
CPU: ARMv7-M Processor [410fc241] revision 1 (ARMv7M)
CPU: NO data cache, NO instruction cache
Machine: STMicro STM32
...
VFS: Mounted root (romfs filesystem) readonly on device 31:0.
Freeing init memory: 16K
starting pid 25, tty '/dev/ttyS2': '/bin/login -f root'
Welcome to
          ____ _  _
         /  __| ||_|                 
    _   _| |  | | _ ____  _   _  _  _ 
   | | | | |  | || |  _ \| | | |\ \/ /
   | |_| | |__| || | | | | |_| |/    \
   |  ___\____|_||_|_| |_|\____|\_/\_/
   | |
   |_|

For further information check:
http://www.uclinux.org/
```
