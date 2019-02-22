# Overview

tk8500 is open source software designed to control and program the ICOM IC-R8500 receiver. An introductory article about this software appeared in April 2002 Monitoring Times magazine. tk8500 was favorably reviewed by Peter Bond in Britain's Short Wave Magazine, November 2002.

This is a Fork/Mirror of the project Copyright 2004, Bob Parnass - see http://parnass.org/tk8500/

Though tk8500 is intended chiefly for Linux, MacOS X, and BSD users, it will work on Microsoft Windows (95 and later), too.

tk8500 is distributed free of charge, but it is neither shareware nor in the public domain. tk8500 is a copyrighted work released under the terms of the GNU General Public License as published by the Free Software Foundation. tk8500 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

Most IC-R8500 controls are available in tk8500's Main Controls, Adjustments, and Secondary Controls windows. Less frequently used parameters may be accessed using the Scan Options pulldown menu, which may be "torn off" and used as a separate window (fig. 3).

You can only scan one bank at a time while operating the IC-R8500 using the radio's front panel controls. tk8500 lets you scan multiple memory channel banks. You can designate a special volume setting to be used when receiving selected frequencies (no sound card required). The louder audio can alert you to signals on important frequencies while scanning or can compensate for undermodulated transmitters.

tk8500 can be used to load the IC-R8500 memories or read memory data from the radio and store it in a file. Channels may be sorted by frequency or by label, within any bank or all banks.

Data files are in csv (comma-separated values) format, so users can create or edit them using spreadsheet or text editor programs.

tk8500 software provides a facility to log and timestamp active frequencies and relative signal strengths to a log file in csv format. For example:

	2002/01/19,18:06:28,159.15000,fm,99,"KANE"
	2002/01/19,18:07:56,460.52500,fm,135,"KENDL_P1"
	2002/01/19,18:07:59,154.86000,fm,0,"DE_KALB"
	2002/01/19,18:08:03,154.86000,fm,89,"DE_KALB"
	2002/01/19,18:08:05,154.86000,fm,89,"DE_KALB"
	2002/01/19,18:08:25,155.47500,fm,84,"ISPERN"
	2002/01/19,18:13:23,460.52500,fm,0,"KENDL_P1"
	2002/01/19,18:14:02,159.15000,fm,0,"KANE"
	

## Memory Channel Files

tk8500 can read files containing memory channel data. Using the mouse, you can click on a particular entry and tk8500 will tune the radio and set the mode, skip and select flags accordingly.

You can also download the memory data from a file to the IC-R8500, thus programming its memories.

A memory channel data file must be formated in csv (comma-separated values) format. The first line of the file should be this heading:

	Bank,Ch,MHz,Step,Mode,Skip,Select,Atten,Volume,Label

All the other lines should contain these fields:


	Bank number (0 - 19)
	Channel number (0 - 99)
	Frequency in MHz
	Step
	Mode (am, amn, amw, usb, lsb, cw, cwn, fm, fmn, wfm)
	skip (optional)
	select (optional)
	attenuation (optional: 0, 10, 20, 30)
	Volume (optional: vol2 )
	Label (an optional 8-char name which should not
		contain a comma or quotation marks.)
	Note (an optional variable length comment which should not
		contain a comma or quotation marks.)

This is a sample memory data file:

Bank,Ch,MHz,Step,Mode,Skip,Select,Atten,Volume,Label,Note
0,1,460.525,12.5,FM,,select,,vol2,"KNCOM P1","Kendall County Sheriff 1"
0,2,460.575,9,FM,,select,,vol2,"KNCOM F1","Kendall County Fire 1"
0,3,460.375,12.5,FM,,select,20,vol2,"KNCOM P2","Kendall County Sheriff 2"
0,4,462.975,12.5,FM,,select,,vol2,"KNCOM F2","Kendall County Fire 2"
0,5,155.475,5,FM,,select,,vol2,ISPERN
0,6,154.71,10,FM,,select,,,ExecProt,"IL Excecutive Protection"
0,7,155.46,5,FM,,select,,,"ISP HF4"
0,8,145.17,5,FM,,,,,IHARC,"IH repeater Naperville"
0,9,155.58,5,FM,,select,10,vol2,Oswego,"Oswego Police local comms"
0,10,146.52,5,FM,,,,,SIMPLEX,"2 meter simplex"
0,11,148.6,5,FM,,select,,,"ARMY JL","Army Elwood firing range"
0,12,154.95,5,FM,,select,,vol2,CPAT,"CPAT police surveillance"
0,13,145.77,10,FM,skip,select,,,CARMA,"CARMA 2m simplex frequency"
0,14,419.65,12.5,FM,skip,,,,"USPS INS"
0,15,52.525,10,FM,skip,,,,"6M smplx"

You can use a separate text editor or spreadsheet program to create, edit, and print memory channel files. You cannot create or edit memory channel data files within tk8500.

tk8500 runs in the X Windows System graphical environment and is independent of your desktop manager (e.g., KDE or Gnome). tk8500 has been tested on a 1400 MHz AMD Athlon® based computer running RedHat® Linux® 7.3 with kernel 2.4.18-4. and Tcl/Tk version 8.3, patchlevel 8.3.3.
This is experimental software and probably contains defects. It remains under development.

## Installing tk8500 for Linux

Clone this repository into a directory, eg tk8500-0.9 .

Define and export tk8500, a new environment variable to point to the installation subdirectory just created.
tk8500=/some/path/tk8500-0.9
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
