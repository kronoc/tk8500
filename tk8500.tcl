#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"

###################################################################
# This file is part of tk8500, a control program for the
# ICOM IC-R8500 receiver.
# 
#    Copyright (C) 2001 - 2003, Bob Parnass
#					AJ9S
# 
# tk8500 is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version.
# 
# tk8500 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with tk8500; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
###################################################################


######################################################################
# Write error messages to stderr if linux/unix, stdout otherwise
######################################################################

proc Tattle { msg } \
{
	global tcl_platform

	 set platform $tcl_platform(os) 
	 switch -glob $platform \
		{
		{[Ll]inux} \
			{
			puts stderr $msg
			}
		{unix} \
			{
			puts stderr $msg
			}
		default \
			{
			puts $msg
			}
		}

	return
}
############################################################
set Version "0.9"

set AboutMsg  "tk8500
version $Version

Copyright 2001 - 2003, Bob Parnass
Oswego, Illinois
USA
http://parnass.com

Released under the GNU General Public License.

tk8500 is a control program for the
ICOM IC-R8500 receiver.
This is beta software. If you find a defect,
please report it."

############################################################

# trace variable Sid r {puts stderr "Sid trace trap"}
set Pgm [lindex [split $argv0 "/"] end]
set Lfilename ""
set Libdir $env(tk8500)
set ScanFlag 0


# Sanity check for the Libdir environment variable.
if {$Libdir == ""}\
	{
	Tattle "$Pgm: error: Environment variable tk8500 must"
	Tattle "be set to the directory containing the library"
	Tattle "files for program $Pgm."
	exit 1
	}

source [ format "%s/%s" $Libdir "misclib.tcl" ]
source [ format "%s/%s" $Libdir "mylib.tcl" ]
source [ format "%s/%s" $Libdir "api8500.tcl" ]
source [ format "%s/%s" $Libdir "gui8500.tcl" ]
source [ format "%s/%s" $Libdir "presets.tcl" ]


SetUp


wm title . "untitled.csv - tk8500"

set lst [ InitStuff ]
set Rcfile [ lindex $lst 0 ]
set LabelFile [ lindex $lst 1 ]

FirstTimeCheck $Rcfile

# Set most global variables from configuration file.

PresetGlobals
ReadSetup
OverrideGlobals

ReadLabel


set CancelXfer 0

set FileTypes \
	{
	{"IC-R8500 data files"           {.csv .txt}     }
	}


# Create graphical widgets.

MakeGui

# Add the current frequency and mode to the session history list.
Add2History

# Start polling the radio for S meter readings after a delay.
after 1000 PollSmeter

SetNB off
StopScan
update idletasks
