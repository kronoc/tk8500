tk8500 is software to allow you to control an Icom IC-R8500 radio from a computer, and also perform memory management functions (import/export memorues to a CSV etc.).

tk8500 runs in the X Windows System graphical environment and is independent of your desktop manager (e.g., KDE or Gnome). tk8500 has been tested on a 1400 MHz AMD Athlon® based computer running RedHat® Linux® 7.3 with kernel 2.4.18-4. and Tcl/Tk version 8.3, patchlevel 8.3.3.
This is experimental software and probably contains defects. It remains under development. When available, newer versions of tk8500 will be made available for download at this web site.

Downloading and Installing tk8500 for Linux

Download and install the free tcl and tk RPMs for your system. You can search for download locations at http://rpmfind.net. If the rpmfind server is unavailable, you can download them from the Tcl Developer Xchange at http://tcl.activestate.com or from http://www.scriptics.com.
Create a new installation directory on your system, e.g., 
mkdir /home/username/tk8500
Download the gzipped version of tk8500, tk8500-0.9.tgz into the installation directory you created earlier. 
Decompress and untar the file after downloading it: 
cd /home/username/tk8500
tar -zxvf tk8500-0.9.tgz
This will create a new subdirectory, named tk8500-0.9 and place the files there. 
Define and export tk8500, a new environment variable to point to the installation subdirectory just created.
tk8500=/home/username/tk8500/tk8500-0.9
export tk8500
To make the change permanent, you must add the two lines above to your shell's profile, e.g., /home/username/.bash_profile if you use the bash shell. 
Remove the .tk8500rc configuration file if you have one from a previous installation.
To ensure the tk8500 environment variable is made known within X Windows, you should logout, login again, then restart your graphical user interface before using tk8500 for the first time.
Notes

Make sure your serial port has both read and write permissions for the user who will run the program.
For example, I use /dev/ttyS1 as the serial port to connect the radio. If I type in a console window:

ls -l /dev/ttyS1
the output shows the permissions:
crw-rw-rw-    1 root     uucp       4,  65 Aug 15 06:40 /dev/ttyS1
Notice that /dev/ttyS1 is readable and writeable by everyone (user, group, and others).
Login as root or run the su program to assume root privileges. Then, change the permissions and exit.

chmod   ugo+rw   /dev/ttyS1
exit
See the Release notes.
Memory channel data files created for tk8500 version 0.4 and earlier will not work with this version. To use these data files, you must add a new Volume field (located before the Label field) to each line. It is easy to insert a new data column using Gnumeric, Excel, Star Calc, or other spreadsheet program. Don't forget to to save the file in .csv format.
tk8500 presumes the wish windowing shell is in your PATH.
Before using tk8500, be sure the IC-R8500's "initial set mode" options are set as follows:
CIV ADDR = 4AH
CIV BAUD = AUTO
CIV TRAN = OFF
CIV 731 = OFF
See pp. 31 - 32 in the IC-R8500 instruction manual to learn how to set them.
Power your IC-R8500 receiver on before starting tk8500 or else the program will freeze.
