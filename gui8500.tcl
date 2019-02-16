
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


proc MakeGui { } \
{
	global Cht
	global Chvector
	global GlobalParam
	global HistVector

	# Set custom font and colors.

	SetAppearance

	set msg [OpenDevice]
	
	if { $msg != ""} \
		{
		tk_dialog .opnerror "tk8500 error" \
			$msg error 0 OK
		exit
		}
	
	ReadAllBankNames
	ReadLimits
	
	###############################################################
	# Menu bar along the top edge.
	###############################################################
	set fr_menubar [MakeMenuBar .mb]
	set mf [frame .mainframe]
	frame $mf.chtable
	set Cht $mf.chtable
	
	###############################################################
	# Freq Display and tuning buttons.
	###############################################################
	set fr_freqdisplay [FreqDisplay .freqdisplay]
	set fr_comment [MakeNote .comment]
	
	set fr_sliderule [MakeSlideRule .dial]
	set fr_buttons [frame .fbuttons]
	
	set fr_vet [frame $fr_buttons.vertbar -borderwidth 6 \
		-relief groove]
	
	set fr_slew [MakeSlewFrame $fr_buttons.slew]
	balloonhelp_for $fr_slew \
		"Press once to start slew (autotune).\nPress again to stop."
	

	set fr_updown [MakeUpDownFrame $fr_buttons.updown]
	balloonhelp_for $fr_updown \
		"Click and release a button\nto change the frequency."

	pack $fr_slew -side top -fill x -expand y -padx 3
	pack $fr_updown -side top -fill x -expand y -padx 3
	

	if {$GlobalParam(DockSliders) == "on" } \
		{
		set adj $mf.adj
		} \
	else \
		{
		toplevel .adjust
		set adj .adjust.adj
		wm title .adjust "tk8500 Adjustments"

		# Prevent user from closing the adjustment window unless
		# he elects to exit the entire program.

		wm protocol .adjust WM_DELETE_WINDOW \
			{ExitApplication; exit}

	
		}

	###############################################################
	# Potentiometer (scale) controls
	###############################################################

	frame $adj -relief groove -borderwidth 3
	
	set fr_pots [ MakePots $adj.potentiometers]
	pack $fr_pots -side left -fill x -expand y -padx 3 -pady 3

	###############################################################
	# Key Pad super widget used for frequency entry.
	###############################################################
	set fr_kp [MakeKeyPad $adj.kp ]
	
	pack $fr_kp -side left -fill x -expand n -padx 1 -pady 1
	
	###############################################################
	# Secondary controls window
	###############################################################
	toplevel .controls
	set ctls .controls.ctls
	frame $ctls -relief groove
	
	# set fr_mod [MkModeSwitch $ctls.mode]
	# SetMode
	
	MakePushButtons $ctls.pushb
	
	toplevel .mc
	set Cht .mc
	
	# Prevent user from closing the channel list window unless
	# he elects to exit the entire program.
	
	wm protocol $Cht WM_DELETE_WINDOW {ExitApplication; exit}
	wm title $Cht "tk8500 Memory Channels"
	wm iconify $Cht
	
	
	set $ctls.scan [ MakeMemScanFrame $ctls.scan]
	set $ctls.search [ MakeSearchFrame $ctls.search]
	
	
	set Chvector ""
	
	pack $fr_menubar -side top -fill x -pady 3
	pack $fr_freqdisplay -side top -fill x
	pack $fr_comment -side top -fill x -expand y
	pack $fr_sliderule -side top -fill x -expand y

	pack $adj -side bottom -fill x -expand y -padx 3 -pady 3

	pack $fr_buttons -side top -fill x -expand y
	

	pack \
		$ctls.pushb \
		$ctls.scan \
		$ctls.search \
		-side left -anchor n -padx 3 -pady 3 -expand y -fill y
	
	
	pack $ctls -side top -fill both -expand true -padx 3 -pady 3
	pack .mainframe -side top -fill both -expand true
	
	# Zap the session history.
	set HistVector ""
	
	update idletasks
	
	###############################################################
	#  Ask the window manager to catch the delete window
	#  event.
	###############################################################
	wm protocol . WM_DELETE_WINDOW {ExitApplication; exit}
	
	# Prevent user from shrinking or expanding main window.
	# wm minsize . [winfo width .] [winfo height .]
	wm maxsize . [winfo width .] [winfo height .]
	
	wm protocol .controls WM_DELETE_WINDOW {ExitApplication; exit}
	wm title .controls "tk8500 Secondary Controls"
	
	# set x [winfo width $ctls.mode]
	# set x [expr $x + 14]
	
	# Prevent user from overshrinking or expanding controls window.
	wm minsize .controls [winfo width .controls] [winfo height .controls]
	wm maxsize .controls [winfo width .controls] [winfo height .controls]
	
	# Update the frequency display widget with the radio's frequency.
	
	if {$GlobalParam(DockSliders) == "off" } \
		{
		# Prevent user from shrinking or expanding window.
		wm minsize .adjust [winfo width .adjust] \
			[winfo height .adjust]
		wm maxsize .adjust [winfo width .adjust] \
			[winfo height .adjust]
		}
	
	UpdDisplay
	SetSlideRuleDial
	
	return
}


###################################################################
# Alter color and font appearance based on user preferences.
###################################################################
proc SetAppearance { } \
{
	global GlobalParam

	if {$GlobalParam(Font) != "" } \
		{
		# Designate a custom font for most widgets.
		option add *font $GlobalParam(Font)
		}

	if {$GlobalParam(BackGroundColor) != "" } \
		{
		# Designate a custom background color for most widgets.
		option add *background $GlobalParam(BackGroundColor)
		}

	if {$GlobalParam(ForeGroundColor) != "" } \
		{
		# Designate a custom foreground color for most widgets.
		option add *foreground $GlobalParam(ForeGroundColor)
		}

	if {$GlobalParam(TroughColor) != "" } \
		{
		# Designate a custom slider trough color
		# for most scale widgets.
		option add *troughColor $GlobalParam(TroughColor)
		}

	return
}



##########################################################
# Check if the configuration file exists.
# If it exits, return 1.
#
# Otherwise, prompt the user to select the
# serial port.
##########################################################

proc FirstTimeCheck { Rcfile } \
{
	global AboutMsg
	global GlobalParam
	global Libdir
	global tcl_platform

	if { [file readable $Rcfile] == 1 } \
		{
		return 0
		}

	tk_dialog .about "About tk8500" \
		$AboutMsg info 0 OK

	# No readable config file found.
	# Treat this as the first time the user has run the program.

	# Create a new window with radio buttions and
	# an entry field so user can designate the proper
	# serial port.

	set msg "Please identify the serial port to which\n"
	set msg [append msg "your IC-R8500 receiver is connected."]

	toplevel .serialport
	set sp .serialport

	label $sp.intro -text $msg

	frame $sp.rbframe
	set fr $sp.rbframe

	if { $tcl_platform(platform) == "windows" } \
		{
		# For Windows.
		radiobutton $fr.com1 -text COM1: -variable port \
			-value {COM1:}
		radiobutton $fr.com2 -text COM2: -variable port \
			-value {COM2:} 
		radiobutton $fr.com3 -text COM3: -variable port \
			-value {COM3:} 
		radiobutton $fr.com4 -text COM4: -variable port \
			-value {COM4:} 

		pack $fr.com1 $fr.com2 $fr.com3 $fr.com4 \
			-side top -padx 3 -pady 3 -anchor w

		} \
	else \
		{
		# For unix, mac, etc..
		radiobutton $fr.s0 -text /dev/ttyS0 -variable port \
			-value {/dev/ttyS0} 
		radiobutton $fr.s1 -text /dev/ttyS1 -variable port \
			-value {/dev/ttyS1} 
		radiobutton $fr.s2 -text /dev/ttyS2 -variable port \
			-value {/dev/ttyS2} 
		radiobutton $fr.s3 -text /dev/ttyS3 -variable port \
			-value {/dev/ttyS3} 
		radiobutton $fr.s4 -text /dev/ttyS4 -variable port \
			-value {/dev/ttyS4} 
		radiobutton $fr.s5 -text /dev/ttyUSB0 -variable port \
			-value {/dev/ttyUSB0} 

		pack \
			$fr.s0 $fr.s1 $fr.s2 \
			$fr.s3 $fr.s4 $fr.s5 \
			-side top -padx 3 -pady 3 -anchor w

		}

	radiobutton $fr.other -text "other (enter below)" \
		-variable port \
		-value other

	entry $fr.ent -width 30 -textvariable otherport

	pack $fr.other $fr.ent \
		-side top -padx 3 -pady 3 -anchor w

	button $sp.ok -text "OK" \
		-command \
			{ \
			global GlobalParam

			if {$port == "other"} \
				{
				set GlobalParam(Device) $otherport
				} \
			else \
				{
				set GlobalParam(Device) $port
				}
			# puts stderr "entered $GlobalParam(Device)"
			}

	button $sp.exit -text "Exit" \
		-command { exit }

	pack $sp.intro -side top -padx 3 -pady 3
	pack $fr -side top -padx 3 -pady 3
	pack $sp.ok $sp.exit -side left -padx 3 -pady 3 -expand true



	bind $fr.ent <Key-Return> \
		{
		global GlobalParam
		set GlobalParam(Device) $otherport
		}

	wm title $sp "Select serial port"
	wm protocol $sp WM_DELETE_WINDOW {exit}

	set errorflag true

	while { $errorflag == "true" } \
		{
		tkwait variable GlobalParam(Device)

		if { $tcl_platform(platform) != "unix" } \
			{
			set errorflag false
			break
			}

		# The following tests do not work properly
		# in Windows. That is why we won't perform
		# the serial port tests when running Windows version.

		if { ([file readable $GlobalParam(Device)] != 1) \
			|| ([file writable $GlobalParam(Device)] != 1)}\
			{
			# Device must be readable, writable.

			bell
			tk_dialog .badport "Serial port problem" \
				"Serial port problem" error 0 OK
			} \
		else \
			{
			set errorflag false
			}
		}

	destroy $sp
	return 1
}

##########################################################
# ExitApplication
#
# This procedure can do any cleanup necessary before
# exiting the program.
#
# Disable computer control of the radio, then quit.
##########################################################
proc ExitApplication { } \
{
	global Lid
	global Lfilename

	SaveSetup
	SaveLabel
	DisableCControl

	if { [info exists Lfilename] } \
		{
		if { $Lfilename != "" } \
			{
			# Close log file.
			close $Lid
			}
		}
	exit
}


##########################################################
# NoExitApplication
#
# This procedure prevents the user from
# killing the window.
##########################################################
proc NoExitApplication { } \
{

	set response [tk_dialog .quitit "Exit?" \
		"Do not close this window." \
		warning 0 OK ]

	return
}
##########################################################
#
# Scroll_Set manages optional scrollbars.
#
# From "Practical Programming in Tcl and Tk,"
# second edition, by Brent B. Welch.
# Example 27-2
#
##########################################################

proc Scroll_Set {scrollbar geoCmd offset size} {
	if {$offset != 0.0 || $size != 1.0} {
		eval $geoCmd;# Make sure it is visible
		$scrollbar set $offset $size
	} else {
		set manager [lindex $geoCmd 0]
		$manager forget $scrollbar								;# hide it
	}
}


##########################################################
#
# Listbox with optional scrollbars.
#
#
# Inputs: basename of configuration file
#
# From "Practical Programming in Tcl and Tk,"
# second edition, by Brent B. Welch.
# Example 27-3
#
##########################################################

proc Scrolled_Listbox { f args } {
	frame $f
	listbox $f.list \
		-font {courier 12} \
		-xscrollcommand [list Scroll_Set $f.xscroll \
			[list grid $f.xscroll -row 1 -column 0 -sticky we]] \
		-yscrollcommand [list Scroll_Set $f.yscroll \
			[list grid $f.yscroll -row 0 -column 1 -sticky ns]]
	eval {$f.list configure} $args
	scrollbar $f.xscroll -orient horizontal \
		-command [list $f.list xview]
	scrollbar $f.yscroll -orient vertical \
		-command [list $f.list yview]
	grid $f.list $f.yscroll -sticky news
	grid $f.xscroll -sticky news

	grid rowconfigure $f 0 -weight 1
	grid columnconfigure $f 0 -weight 1

	return $f.list
}


###################################################################
#
# Create one reception mode selection radiobutton widget
# named 'w', with text label 't' and value 'val'.
#
###################################################################
proc MkModeSel { w t val } \
{
	global GlobalParam

	radiobutton $w -text $t -variable GlobalParam(Mode) \
		-value $val -command { ChangeMode }

	return
}

###################################################################
# Change the detector mode.
#
# Notes:
#	This proc determines the mode from the variable
#	GlobalParam(Mode), so make sure it is set before
#	calling this proc.
###################################################################
proc ChangeMode { } \
{
	global GlobalParam
	global ModeLabel

	SetMode
	$ModeLabel configure -text $GlobalParam(Mode)

	Add2History

	return
}

##########################################################
#
# Read .csv input file.
# Massage contents of each line.
# Insert the info into the channel selector listbox.
#
##########################################################

proc ReadMemFile { } \
{
	global CancelXfer
	global Cht
	global Chvector
	global MemNote
	global MemVol
	global MemFreq
	global GlobalParam
	global MemAtten
	global MemLabel
	global MemMode
	global MemPopulated
	global MemSelect
	global MemSkip
	global MemStep

	global NBanks
	global NChanPerBank


#	for {set bn 0} {$bn < 25} {incr bn} \
#		{
#		for {set ch 0} {$ch < $NChanPerBank} {incr ch} \
#			{
#			set key [Chb2Key $bn $ch]
#			set MemPopulated($key) 0
#			}
#		}
	set sid [open $GlobalParam(Ifilename) "r"]

	set line ""
	set i 0

	# Read entire .csv file at one time.
	set allchannels [read $sid]

	# For each line in the .csv file.
	foreach line [split $allchannels "\n" ] \
		{
		update

		incr i
		if { $i > 1 } then\
			{
			# Delete double quote characters.
			regsub -all "\"" $line "" bline
			set line $bline

			if {$line == ""} then {continue}
		
			set flag [ParseCsvLine $line]

			if { $flag != "" } \
				{
				set msg [GenErrMsg $line $flag]
				set response [tk_dialog .badcsv \
					"Error in file" \
					$msg error 0 Continue Exit]
				if {$response == 0} then {continue} \
				else {DisableCControl; exit}
				}
		

			set mlist [split $bline ","]
			set bn [lindex $mlist 0]
			set ch [lindex $mlist 1]

			if { ($bn != "") && ($ch != "") } then \
				{
				set key [Chb2Key $bn $ch]
#				set s [format "%2d %3d %10.5f %5.1f %-3s %-8s %-4s %-7s %2s %s %s" \
#					$bn $ch $MemFreq($key) \
#					$MemStep($key) \
#					$MemMode($key) \
#					$MemLabel($key) \
#					$MemSkip($key) \
#					$MemSelect($key) \
#					$MemAtten($key) \
#					$MemVol($key) \
#					$MemNote($key) \
#					]
#				lappend Chvector $s

				if { $bn < 20 } \
					{
					# Add frequency and label
					# to a cache

					Add2LabelCache \
						$MemFreq($key) \
						$MemLabel($key) \
						$MemNote($key)
					}
				}
			}
		}
	close $sid

	wm title $Cht [ Basename $GlobalParam(Ifilename) ]
	return
}

##########################################################
#
# Return the bank selected from the channel selector listbox
#
##########################################################

proc BankSelected { w } \
{
	set line [ ListSelected $w ]
	if {[string compare -nocase -length 1 $line "-"] == 0} \
		{
		return -1
		}
	set line [string trimleft $line " "]
	regsub " .*" $line "" ch
	return "$ch"
}

##########################################################
#
# Return the channel selected from the channel selector listbox
#
##########################################################

proc ChSelected { w } \
{
	set line [ ListSelected $w ]
	set line [string trimleft $line " "]
	if {[string compare -nocase -length 1 $line "-"] == 0} \
		{
		return -1
		}

	regsub {^[0-9]} $line "" line
	regsub {^[0-9]} $line "" line
	set line [string trimleft $line " "]


	regsub " .*" $line "" ch
	return "$ch"
}


##########################################################
#
# Return the index selected from the history selector listbox
#
##########################################################

proc HistSelected { w } \
{
	set line [ ListSelected $w ]
	set line [string trimleft $line " "]

	regsub " .*" $line "" i
	return "$i"
}


###################################################################
# Parse one line of a .csv file and extract the fields.
#
# Returns:
#	""		-line passes parsing tests
#	error case	-line contains an error and this is
#			a string containing the error cause
###################################################################

proc ParseCsvLine { s } \
{
	global GlobalParam
	global VolumeByMemFreqArray
	global Mode
	global MemVol
	global MemPopulated MemFreq MemStep MemMode \
		MemSkip MemSelect MemAtten MemLabel \
		MemNote

	set mlist [split $s ","]

	# Skip empty lines.
	if { $s == "" } then {return "Empty line."}

	set n [llength $mlist]
	if { $n < 5 } then {return "Missing fields in line."}

	set frq [lindex $mlist 2]
	if { [string compare $frq ""] == 0 } \
		{return "Missing frequency."}
	if { ($frq <= 0) || ($frq >= $GlobalParam(HighestFrequency)) } \
		{return "Invalid frequency."}


	set bn [lindex $mlist 0]
	if {$bn == ""} {return "Missing bank number."}
	set bn [string trimleft $bn 0]

	if {$bn == ""} \
		{
		set bn 0
		}

	set ch [lindex $mlist 1]
	if {$ch == ""} {return "Missing channel number."}
	set ch [string trimleft $ch 0]

	if {$ch == ""} \
		{
		set ch 0
		}

#	puts stderr "bn: $bn, ch $ch, $s"

	if { $bn < 0 || $bn > 24 } {return "Bank must be 0 - 24."}
	if { $ch < 0 || $ch > 999 } {return "Channel must be 0 - 999."}

	set key [Chb2Key $bn $ch]

	set step [lindex $mlist 3]
	if {$step == ""} \
		{
		set step 1
		}
	if { ($step <= 0) || ($step > 1000) } \
		{return "Step must be 0 - 1000"}
	set MemStep($key) $step

	set mode [lindex $mlist 4]
	set mode [string toupper $mode]
	if {[ info exists Mode($mode) ] == 0 } \
		{return "Invalid mode field."}
	set MemMode($key) $mode

	set skip [lindex $mlist 5]
	if { ($skip != "") && ($skip != "skip") } \
		{return "Invalid Skip field."}
	set MemSkip($key) $skip

	set select [lindex $mlist 6]
	if { ($select != "") && ($select != "select") } \
			{return "Invalid Select field."}
	set MemSelect($key) $select

	set atten [lindex $mlist 7]
	if { ($atten != "") && ($atten != "10")
		&& ($atten != "20") && ($atten != "30") } \
		{
		return "Invalid attenuator field."
		}
	set MemAtten($key) $atten

	set vol [lindex $mlist 8]
	set MemVol($key) $vol

	if { $vol != "" } \
		{
		set f [format "%.5f" $frq]
		set VolumeByMemFreqArray($f) $vol
		}

	set MemLabel($key) [lindex $mlist 9]
	set MemNote($key) [lindex $mlist 10]
#	puts stderr "key=$key , $MemNote($key)"

	set MemFreq($key) $frq
	set MemPopulated($key) 1
	return ""
}

proc GenErrMsg { s cause } \
{
	global GlobalParam

	set msg ""
	append msg "The following line in file\n"
	append msg "$GlobalParam(Ifilename) "
	append msg "contains an error:\n\n"
	append msg "$s\n\n"
	if {$cause != ""} \
		{
		append msg "$cause\n\n"
		}
	append msg "Continue or exit the program?"

	return $msg
}


##########################################################
# Contruct the top row of pulldown menus
##########################################################
proc MakeMenuBar { f } \
{
	global AboutMsg
	global Device
	global FileTypes
	global GlobalParam
	global Pgm
	global Version

	# File pull down menu
	frame $f -relief groove -borderwidth 3

	menubutton $f.file -text "File" -menu $f.file.m \
		-underline 0
	menubutton $f.view -text "View" -menu $f.view.m \
		-underline 0
	menubutton $f.data -text "Data" -menu $f.data.m \
		-underline 0
	menubutton $f.options -text "Scan Options" -menu $f.options.m \
		-underline 0
	menubutton $f.log -text "Log" -menu $f.log.m \
		-underline 0
	menubutton $f.presets -text "Presets" -menu $f.presets.m \
		-underline 0
	menubutton $f.radio -text "Radio" -menu $f.radio.m \
		-underline 0
	menubutton $f.help -text "Help" -menu $f.help.m \
		-underline 0
	
	
	menu $f.view.m
	AddView $f.view.m

	menu $f.data.m
	AddData $f.data.m

	menu $f.options.m
	AddOptions $f.options.m

	menu $f.log.m
	AddLog $f.log.m

	set hint ""
	set hint [append hint "To tear off the Options menu, "]
	set hint [append hint "click on Options, "]
	set hint [append hint "then click on the dotted line."]
	balloonhelp_for $f.options $hint

	set hint ""
	set hint [append hint "To tear off the Log menu, "]
	set hint [append hint "click on Log, "]
	set hint [append hint "then click on the dotted line."]
	balloonhelp_for $f.log $hint

	
	menu $f.help.m
	$f.help.m add command -label "Tcl info" \
		-underline 0 \
		-command { \
			tk_dialog .about "Tcl info" \
				[HelpTclInfo] info 0 OK
			}

	$f.help.m add command -label "License" \
		-underline 0 \
		-command { \
			set helpfile [format "%s/COPYING" $Libdir ]
			set win [textdisplay_create "Notice"]
			textdisplay_file $win $helpfile
			}
	
	$f.help.m add command -label "About tk8500" \
		-underline 0 \
		-command { \
			tk_dialog .about "About tk8500" \
				$AboutMsg info 0 OK
			}
	
	menu $f.file.m -tearoff no

	$f.file.m add command -label "Open ..." \
		-underline 0 \
		-command {global Cht
			global GlobalParam
			# wm deiconify $Cht;
			set fr_table [MakeChannelListFrame $Cht]; \
			if { $GlobalParam(Ifilename) != ""} \
				{
				pack $fr_table
				SetWinTitle
				}
			}
	
#	$f.file.m add command -label "Save" \
#		-underline 0 \
#		-command { \
#			SaveSetup; SaveTemplate .mainframe 0; SaveLabel}

	$f.file.m add command -label "Save As ..." \
		-underline 0 \
		-command { \
			SaveSetup; SaveTemplate .mainframe 1; SaveLabel}

#	$f.file.m add command -label "Save setup" \
#		-underline 0 \
#		-command {SaveSetup; SaveLabel}

	$f.file.m add command -label "Exit" \
		-underline 1 \
		-command {SaveSetup; ExitApplication; exit }
	
	menu $f.radio.m -tearoff no
	AddRadio $f.radio.m

	menu $f.presets.m
	AddPresets $f.presets.m

	set hint ""
	set hint [append hint "Quickly tune the radio "]
	set hint [append hint "to preset frequencies."]
	balloonhelp_for $f.presets $hint

	pack $f.file $f.view $f.data $f.options $f.log \
		$f.presets $f.radio -side left -padx 10
	pack $f.help -side right
	
	update
	return $f
}


####################################################################
# Freq Display
####################################################################
proc FreqDisplay { f } \
{
	global ChanLabel
	global BankLabel
	global CurrentFreq
	global DisplayFontSize
	global GlobalParam
	global LabelLabel
	global MeterFrame
	global ModeLabel
	global Readout
	global SignalLabel


	frame $f -relief flat -background black -borderwidth 0
	set lf [frame $f.lf -relief flat -background black \
		-borderwidth 0]

#	set Power on
#	checkbutton $f.power -text "POWER" \
#		-variable Power \
#		-onvalue "on" \
#		-offvalue "off" \
#		-command { PowerSwitch $Power }
	

	set MeterFrame $f.meter
	MakeMeter


	set lw 15

	set BankLabel $lf.bank
	label $BankLabel -text "" -borderwidth 3 \
		-width $lw \
		-justify left \
		-background black -foreground yellow


	set LabelLabel $lf.label
	label $LabelLabel -text " " -borderwidth 3 \
		-width $lw \
		-justify left \
		-background black -foreground white

	set ChanLabel $lf.chan
	label $ChanLabel -text "VFO" -borderwidth 3 \
		-width $lw \
		-justify left \
		-background black -foreground yellow


	MkModeSwitch $lf.mode $lw

	pack \
		$LabelLabel \
		$BankLabel \
		$ChanLabel \
		$lf.mode \
		-anchor w -side top

		# -font {Courier $DisplayFontSize bold} 

	entry $f.display -width 10 \
		-font $DisplayFontSize \
		-textvariable CurrentFreq \
		-relief flat \
		-borderwidth 0 \
		-background black \
		-foreground yellow


	set Readout $f.display
	
	set rf [frame $f.rf -relief flat -background black \
		-borderwidth 0]

	set rw 6
	label $rf.units -text "MHz" -borderwidth 3

	set SignalLabel $rf.signal
	label $SignalLabel -text "    " -borderwidth 3 \
		-justify left \
		-width $rw \
		-background black -foreground red

	pack \
		$rf.units \
		$SignalLabel \
		-anchor w -side top

	set CurrentFreq [FormatFreq "0"]
	pack $f.meter -pady 3 -padx 10 -side left
	pack $lf -padx 4 -side left -expand y
	pack $f.display -padx 10 -side left -expand y
	pack $rf -padx 4 -side left
	
	bind $f.display <Key-Return> \
		{
		# If we are scanning, stop scanning. 
		set GlobalParam(ScanFlag) 0

		# Trim leading spaces or zeros.
		set tmp $CurrentFreq
		regsub {^[ 0]*} $tmp "" CurrentFreq

		set units mhz

		if { [regexp {[mM]$} $CurrentFreq] } \
			{
			# Ends in m or M so number is MHz
			set units mhz 
			regsub {[mM]$} $CurrentFreq {} CurrentFreq
			} \
		elseif { [regexp {[kK]$} $CurrentFreq] } \
			{
			# Ends in k or K so number is kHz
			set units khz
			regsub {[kK]$} $CurrentFreq "" CurrentFreq
			}

		if { [CheckFreqValid $CurrentFreq $units] } then \
			{
			if { $units == "khz" } \
				{
				set CurrentFreq [ expr { double($CurrentFreq) \
					/ double(1000) } ]
				}
			set CurrentFreq [FormatFreq $CurrentFreq ]

			SetSlideRuleDial
			set hz [expr {$CurrentFreq * 1000000}]
			set hz [expr {round($hz)}]
			SetFreq $hz
			set GlobalParam(PreviousFreq) $CurrentFreq

			Add2History
			} \
		else \
			{
			# Invalid frequency.
			bell
			set CurrentFreq $GlobalParam(PreviousFreq)
			set CurrentFreq [FormatFreq $CurrentFreq ]
			}
		}
	return $f
}

####################################################################
# Make frame for pushbuttons
####################################################################
proc MakePushButtons { f } \
{

	frame $f

	MakeNoiseBlanker $f
	MakeAPF $f
	MakeAGC $f.agc
	MakeAttenuator $f.attenuator

	pack $f.agc $f.attenuator -side top -expand y \
		-pady 3

	return $f
}


####################################################################
# Noise Noise Blanker controls
####################################################################

proc MakeNoiseBlanker { f }\
{
	global GlobalParam


	checkbutton $f.nb -text "Noise Blanker" \
		-variable GlobalParam(NB) \
		-onvalue on \
		-offvalue off \
		-command { SetNB $GlobalParam(NB) }

	pack $f.nb -padx 3 -anchor w

	return $f
}


####################################################################
# APF on/off control
####################################################################

proc MakeAPF { f }\
{
	global GlobalParam


	checkbutton $f.apf -text "Audio Peak Filter" \
		-variable GlobalParam(APF) \
		-onvalue on \
		-offvalue off \
		-command { SetAPF $GlobalParam(APF) }

	pack $f.apf -padx 3 -anchor w

	return $f
}

####################################################################
# Attenuator controls
####################################################################

proc MakeAttenuator { f }\
{
	global GlobalParam

	frame $f -relief groove -borderwidth 3

	label $f.lab -text "Attenuator" -borderwidth 3

	radiobutton $f.atten0 -text "Off" \
		-variable GlobalParam(Attenuator) \
		-value 0 \
		-command {SetAttenuator 0}

	radiobutton $f.atten10 -text "10 dB" \
		-variable GlobalParam(Attenuator) \
		-value 10 \
		-command {SetAttenuator 10}

	radiobutton $f.atten20 -text "20 dB" \
		-variable GlobalParam(Attenuator) \
		-value 20 \
		-command {SetAttenuator 20}

	radiobutton $f.atten30 -text "30 dB" \
		-variable GlobalParam(Attenuator) \
		-value 30 \
		-command {SetAttenuator 30}


	pack $f.lab $f.atten0 $f.atten10 $f.atten20 $f.atten30 \
		-side top -padx 3 -anchor w


	return $f
}


####################################################################
# AGC controls
####################################################################

proc MakeAGC { f }\
{
	global GlobalParam

	frame $f -relief groove -borderwidth 3

	radiobutton $f.agcf -text "AGC Fast" \
		-variable GlobalParam(AGC) \
		-value fast \
		-command {SetAGC fast}

	radiobutton $f.agcs -text "AGC Slow" \
		-variable GlobalParam(AGC) \
		-value slow \
		-command {SetAGC slow}

	pack $f.agcf $f.agcs -side top -padx 3 -anchor w
	return $f
}


####################################################################
# Make two rows of potentiometers
####################################################################

proc MakePots { f } \
{
	global Bwpot
	global GlobalParam
	global Volume1Widget
	global Volume2Widget

	frame $f -relief flat -borderwidth 3
	frame $f.basic -relief flat -borderwidth 3
	frame $f.adv -relief flat -borderwidth 3
	set p1 $f.basic
	set p2 $f.adv

	set Volume1Widget $p1.af
	
	scale $p1.af -from 0 -to 250 -label "Volume 1" \
		-variable GlobalParam(Volume1) \
		-resolution 5 \
		-orient horizontal  -command SetVolume \
		-troughcolor green 

	$p1.af set $GlobalParam(Volume1)
	
	scale $p1.tone -from 0 -to 250 -label "Audio Peak Filter" \
		-variable GlobalParam(APFadj) \
		-resolution 10 \
		-orient horizontal  -command AdjAPF
	$p1.tone set $GlobalParam(APFadj)
	
	scale $p1.squelch -from 0 -to 250 -label "Squelch" \
		-variable GlobalParam(Squelch) \
		-orient horizontal  -command SetSquelch \
		-troughcolor yellow
	$p1.squelch set $GlobalParam(Squelch)
	
	
	set Volume2Widget $p2.af
	scale $p2.af -from 0 -to 250 -label "Volume 2" \
		-variable GlobalParam(Volume2) \
		-command SetVolume \
		-resolution 5 \
		-orient horizontal

	$p2.af set $GlobalParam(Volume2)
	
	scale $p2.pbs -from -1250 -to 1250 -label "IF Shift (Hz)" \
		-resolution 25 \
		-variable GlobalParam(PassBandShift) \
		-orient horizontal  -command SetPBS
	# $p2.pbs set 0

	scale $p2.interval -from 300 -to 1000 \
		-label "Display Update Interval (ms)" \
		-resolution 25 \
		-variable GlobalParam(DisplayUpdateInterval) \
		-orient horizontal 
	

	pack $p1.af $p1.tone $p1.squelch -side left \
		-fill x -expand y -padx 3
	pack $p2.af $p2.pbs $p2.interval -side left -fill x \
		-expand y -padx 3
	pack $p1 -side top -fill x
	pack $p2 -side top -fill x

	return $f
}


proc MakeScrollPane {w x y} {
   frame $w -class ScrollPane -width $x -height $y
   canvas $w.c -xscrollcommand [list $w.x set] -yscrollcommand [list $w.y set]
   scrollbar $w.x -orient horizontal -command [list $w.c xview]
   scrollbar $w.y -orient vertical   -command [list $w.c yview]
   set f [frame $w.c.content -borderwidth 0 -highlightthickness 0]
   $w.c create window 0 0 -anchor nw -window $f
   grid $w.c $w.y -sticky nsew
   grid $w.x      -sticky nsew
   grid rowconfigure    $w 0 -weight 1
   grid columnconfigure $w 0 -weight 1
   # This binding makes the scroll-region of the canvas behave correctly as
   # you place more things in the content frame.
   bind $f <Configure> [list Scrollpane_cfg $w %w %h]
   $w.c configure -borderwidth 0 -highlightthickness 0
   return $f
}
proc Scrollpane_cfg {w wide high} {
   set newSR [list 0 0 $wide $high]
	return
   if {![string equals [$w cget -scrollregion] $newSR]} {
      $w configure -scrollregion $newSR
   }
}


###################################################################
# Check to see if someone is running another
# copy of  this program.
#
# Code Snippit by DJ Eaton.
# Ben Mesander helped with Mac OS X compatibility.
#
# Warning: works in Linux and Mac OS X only, not Solaris
#
###################################################################
proc CheckForDup { } \
{
	global argv0
	global Pgm

	set filename [lindex [split $argv0 "/"] end]
	set ppid [lindex \
		[exec ps xwww \| grep -i wish \| grep $filename] 0]

	if {$ppid != [pid] } \
		{
		puts stderr "$Pgm: A copy of this program is already running.\n"
		exit 1
		}
	unset ppid filename
	return;
}


###################################################################
# Change the current frequency by adding 'delta' MHz.
###################################################################
proc Qsy { delta } \
{
	global ChanLabel
	global CurrentFreq
	global GlobalParam

	# We are deviating off a channel so wipe out the
	# channel number label.

	if { $GlobalParam(ScanFlag) == 0 } \
		{
		$ChanLabel configure -text "VFO"
		}

	set CurrentFreq [expr {$CurrentFreq + $delta}]
	if { [CheckFreqValid $CurrentFreq mhz] } then \
		{
		set CurrentFreq [FormatFreq $CurrentFreq ]
		set newfreq [expr {$CurrentFreq * 1000000}]
		set newfreq [expr {round($newfreq)}]
		SetFreq $newfreq
		set GlobalParam(PreviousFreq) $CurrentFreq
		SetSlideRuleDial
		update
		} \
	else \
		{
		# Invalid frequency.
		bell
		set CurrentFreq [FormatFreq $GlobalParam(PreviousFreq)]
		}
	return

}

###################################################################
# Search between lower and upper frequency limits
###################################################################
proc Search { l u step type } \
{
	global BlinkToggle
	global CurrentFreq
	global GlobalParam
	global PreviousFreq

	# ts is in MHz
	set ts [expr { $step / 1000.0 } ]

	# NOTE: The IC-R8500 will only utilize the first
	# pair of search limits when directed to
	# search via a computer.
	# This is documented in the instruction manual.
	# Therefore, we must program the frequency limits, step,
	# etc., into bank 23, channels 0 and 1.

	set s [EncodeAChannel \
		23 0 $l \
		$GlobalParam(Mode) \
		$step \
		0 \
		"" \
		"" \
		"none" ]

	WriteAChannel $s


	set s [EncodeAChannel \
		23 1 $u \
		$GlobalParam(Mode) \
		$step \
		0 \
		"" \
		"" \
		"none" ]

	WriteAChannel $s

	if {$type == "autowritescan"} \
		{
		StartAutoWriteScan
		} \
	elseif {$type == "limitscan"} \
		{
		StartLimitScan
		}

	return
}

###################################################################
# Create memory scan widgets. 
###################################################################
proc MakeMemScanFrame { f }\
{
	global BlinkToggle
	global MemPopulated
	global ChanLabel
	global GlobalParam

	frame $f -relief sunken -borderwidth 3
	label $f.labmemscan -text "Memory Scan" -borderwidth 3

	set l $f.l
	set r $f.r

	# Create memory scan widgets.
	MakeMemScanTypes  $l

	# Create the list of memory banks.
	MkAllBankSw  $r

	pack $f.labmemscan -side top -padx 3 -pady 3
	pack $l $r -side left -anchor n -padx 3 -pady 3
	return
}

###################################################################
# Create button widgets for the various flavors of
# memory scanning.
###################################################################

proc MakeMemScanTypes { f }\
{
	global BlinkToggle
	global MemPopulated
	global ChanLabel
	global GlobalParam
	global ModeScanLabel

	frame $f -relief flat -borderwidth 3

	button $f.memscanstart -text "Memory Scan" \
		-command {\
			global GlobalParam

			DisableModeScan
			set GlobalParam(ScanType) "Memory Scan"

			PreScan
			StartMemoryScan
			}


	button $f.selscanstart -text "Select Scan" \
		-command { SelectScanCB }


	checkbutton $f.prioscan -text "Priority Scan" \
		-variable GlobalParam(PriorityScan) \
		-onvalue 1 -offvalue 0 \
		-command {\
			global GlobalParam

			if { $GlobalParam(PriorityScan) } \
				{
				# set GlobalParam(ScanType) "Memory Scan"
				set BlinkToggle 1	
				# set GlobalParam(ScanFlag) 1	
				if {[StartPriorityScan]} \
					{
					tk_dialog .error "tk8500" \
						"Priority scan error" \
						error 0 OK
					set GlobalParam(PriorityScan) 0
					}
				}
			}

	MakeModeScanMenu  $f.modescanstart 


	button $f.scanstop -text "Stop" \
		-command {\
			StopScan
			$ChanLabel configure -text "VFO"
			set GlobalParam(ScanFlag) 0
			DisableModeScan
			}

	pack \
		$f.memscanstart \
		$f.selscanstart \
		$f.modescanstart \
		$f.scanstop \
		-side top -padx 3 -fill x -anchor w

	return $f
}

###################################################################
# Select Memory Scan callback
###################################################################

proc SelectScanCB { } \
{
	global ChanLabel
	global GlobalParam
	global ModeScan
	global ModeScanLabel

	if {$GlobalParam(ScanFlag) } \
		{
		# We are already scanning so stop scanning first.
		StopScan
		$ChanLabel configure -text "VFO"
		set GlobalParam(ScanFlag) 0
		DisableModeScan
		}

	set GlobalParam(ScanType) "Select Scan"

	PreScan

	if { [StartSelectMemoryScan] } \
		{

		# The radio responded with an error.
		# Cannot do Select Memory Scan in this
		# bank probably because there are no
		# memory channels in this bank with the
		# Select tag enabled.

		set bn $GlobalParam(Bank)

		StopScan
		$ChanLabel configure -text "VFO"
		set GlobalParam(ScanFlag) 0
		DisableModeScan

		# Cannot start select mem scan.
		tk_dialog .noscan "Select Scan error" \
			"Cannot start Select Scan in bank $bn" \
			error 0 OK
		}
	return
}
###################################################################
# Validate frequency search limits
#
# Returns:
#	0	- limits invalid
#	1	- limits valid
###################################################################
proc CheckLimitsValid { l u } \
{
	if { [CheckFreqValid  $l mhz] == 0 } \
		{
		return 0
		} \
	elseif { [CheckFreqValid  $u mhz] == 0 } \
		{
		return 0
		} \
	elseif { $l >= $u } \
		{
		return 0
		} \
	else \
		{
		return 1
		}
}

###################################################################
# Create search widgets. 
###################################################################
proc MakeSearchFrame { f }\
{
	global ChanLabel
	global GlobalParam
	global LowerFreq
	global ModeScanLabel
	global UpperFreq
	global StepFreq

	frame $f -relief sunken -borderwidth 3
	label $f.limitscan -text "Limit Scan" -borderwidth 3

	MakeLimitMenu $f.lmenu 

	label $f.lowerl -text "Lower freq MHz" -borderwidth 3

	entry $f.lower -width 12 \
		-textvariable LowerFreq \
		-background white 

	# Set default value
	if {$GlobalParam(LowerLimit) > 0} \
		{
		$f.lower insert 0 $GlobalParam(LowerLimit)
		}

	label $f.upperl -text "Upper freq MHz" -borderwidth 3

	entry $f.upper -width 12 \
		-textvariable UpperFreq \
		-background white 

	# Set default value
	if {$GlobalParam(UpperLimit) > 0} \
		{
		$f.upper insert 0 $GlobalParam(UpperLimit)
		}


	label $f.stepl -text "Step size kHz" -borderwidth 3

	entry $f.stepent -width 6 \
		-textvariable StepFreq \
		-background white 

	if {$GlobalParam(SearchStep) > 0 } \
		{
		$f.stepent insert 0 $GlobalParam(SearchStep)
		}

	button $f.limitscanstart -text "Limit Scan" \
		-command { LimitScanCB }


	button $f.autowritescanstart -text "Auto Write Scan" \
		-command {\
			if { [CheckLimitsValid \
				$LowerFreq $UpperFreq] } \
				{
				set GlobalParam(LowerLimit) $LowerFreq
				set GlobalParam(UpperLimit) $UpperFreq
				set GlobalParam(SearchStep) $StepFreq

				set GlobalParam(ScanType) \
					"Auto Write Scan"
				PreScan

				Search $LowerFreq $UpperFreq \
					$StepFreq \
					"autowritescan"
				} \
			else \
				{
				tk_dialog .error "tk8500" \
					"Search limit error" error 0 OK
				}
			}

	button $f.searchstop -text "Stop" \
		-command {\
			StopScan
			$ChanLabel configure -text "VFO"
			set GlobalParam(ScanFlag) 0
			DisableModeScan
			}


	pack \
		$f.limitscan \
		$f.lmenu \
		$f.lowerl \
		$f.lower \
		$f.upperl \
		$f.upper \
		-side top -padx 3 -fill x
	pack \
		$f.stepl \
		$f.stepent \
		-side top -padx 3 -pady 3

	pack \
		$f.limitscanstart \
		$f.autowritescanstart \
		$f.searchstop \
		-side top -padx 3 -fill x
	return $f
}

###################################################################
# Limit Scan callback
###################################################################

proc LimitScanCB {} \
{
	global ChanLabel
	global GlobalParam
	global UpperFreq
	global LowerFreq
	global ModeScanLabel
	global StepFreq

	if { $GlobalParam(ScanFlag) } \
		{
		# We are already scanning so stop scanning first.
		StopScan
		$ChanLabel configure -text "VFO"
		set GlobalParam(ScanFlag) 0
		DisableModeScan
		}

	if { [CheckLimitsValid \
		$LowerFreq $UpperFreq] } \
		{
		set GlobalParam(LowerLimit) $LowerFreq
		set GlobalParam(UpperLimit) $UpperFreq
		set GlobalParam(SearchStep) $StepFreq
		set GlobalParam(ScanType) "Limit Scan"

		DisableModeScan

		PreScan

		Search $LowerFreq $UpperFreq \
			$StepFreq \
			"limitscan"
		} \
	else \
		{
		tk_dialog .error "tk8500" \
			"Search limit error" error 0 OK
		}
	return
}

###################################################################
# Set radio to logical channel.
#
# The proc send commands to the radio to set
# the frequency, mode, bandwidth, and AGC decay time
# according to the settings for channel "ch" in
# our global arrays.
#
# We will drive the radio with these logical channel
# settings from our software arrays instead of relying
# on the contents of what is actually programmed
# in the radio's memory channels.
###################################################################

proc SetLChannel { bn ch } \
{
	global BankLabel
	global ChanLabel
	global MemPopulated
	global CurrentFreq
	global MemFreq
	global GlobalParam
	global Mode
	global MemMode
	global ModeLabel
	global RMode

	set key [Chb2Key $bn $ch]

	set freq $MemFreq($key)

	# Trim leading spaces and zeroes.
	regsub {^[0 ]*} $freq "" tmp
	set freq $tmp

	if { [CheckFreqValid $freq mhz] } then \
		{
		SetBank $bn
		# Update the bank label display
		set tmp [FormatBank $bn]
		$BankLabel configure -text $tmp
		HighlightBank $bn

		# Update the frequency display.
		set CurrentFreq [FormatFreq $freq ]
		set hz [expr {$freq * 1000000}]
		set hz [expr {round($hz)}]
		SetFreq $hz

		set GlobalParam(PreviousFreq) $tmp
		SetSlideRuleDial

		# Update the channel label display.
		set tmp [FormatChan $ch]
		if {$GlobalParam(Debug) > 0 }\
			{
			;# puts stderr "chann $chann , tmp $tmp"
			}

		$ChanLabel configure -text $tmp


		set GlobalParam(Mode) $MemMode($key)

		ChangeMode
		} \
	else \
		{
		# Invalid frequency.
		bell
		set CurrentFreq $GlobalParam(PreviousFreq)
		set CurrentFreq [FormatFreq $CurrentFreq ]
		}

	return
}


##########################################################
# Make channel list frame
##########################################################

proc MakeChannelListFrame { f }\
{
	global Chb
	global GlobalParam
	global FileTypes
	global Mimage

	set GlobalParam(Ifilename) [Mytk_getOpenFile $f \
		$GlobalParam(MemoryFileDir) \
		"tk8500" $FileTypes]

	if {$GlobalParam(Ifilename) == ""} then {return ""}
	ReadMemFile
	
	set GlobalParam(MemoryFileDir) \
		[ Dirname $GlobalParam(Ifilename) ]

	ShowChannels $f
	set GlobalParam(Populated) 1
	set Mimage ""
	return $f.lch
}


##########################################################
# Show memory channels in a window.
##########################################################

proc ShowChannels { f }\
{
	global Chb
	global Chvector
	global GlobalParam

	FormatChannelList
	
	catch {destroy $f.lch}
	set Chb [ List_channels $f.lch $Chvector 30 ]
	wm deiconify $f
	$Chb activate 1
	pack $f.lch -side top
	
	# Tune radio to given memory channel when user clicks
	# mouse on channel selector listbox entry.

	bind $Chb <ButtonRelease-1> \
		{
		# If we are scanning, stop scanning. 
		set GlobalParam(ScanFlag) 0

		set bn [ global Chb; BankSelected $Chb ]
		set ch [ global Chb; ChSelected $Chb ]

		set key [Chb2Key $bn $ch]

		if {($bn >= 0) && ($ch >= 0)} \
			{

			# Tune radio to the channel.
			SetLChannel $bn $ch

			CheckVolume

			update
			}
		}

	return $f.lch
}

###################################################################
# Create a new history window and populate it with
# frequencies we've visited, mode and timestamp.
###################################################################

proc RefreshHistory {} \
{
	global GlobalParam
	global HistoryFreq
	global HistoryLabel
	global HistoryMode
	global HistoryTime
	global HistVector

	set HistVector ""
	for {set i 0} {$i < 1000} {incr i} \
		{
		if {[info exists HistoryTime($i)] == 0} {break}
		if {$HistoryTime($i) <= 0} {break}

		set s [format "%3d %10.5f %-6s %-8s %s" \
			$i \
			$HistoryFreq($i) \
			$HistoryMode($i) \
			$HistoryLabel($i) \
			$HistoryTime($i)]
		lappend HistVector $s
		}

	set f .hist
	catch {destroy $f}
	toplevel $f
	wm title $f "tk8500 Session History"

	if {$GlobalParam(ViewHistory) == "off"} \
		{
		# Hide window because user does not want to view it.
		wm iconify $f
		}

	MakeHistoryListFrame $f
	return
}

##########################################################
# Make session history list frame
##########################################################

proc MakeHistoryListFrame { f }\
{
	global Bwpot
	global ChanLabel
	global Histb
	global CurrentFreq
	global MemFreq
	global GlobalParam
	global HistVector

	
	# RefreshHistory

	set Histb [ List_channels $f.hch $HistVector 10 ]
	$Histb activate 1
	pack $f.hch -side top
	
	# Tune radio to given history freq entry
	# and set the mode when user clicks
	# the mouse button on history selector listbox entry.
	
	bind $Histb <ButtonRelease-1> \
		{

		# If we are scanning, stop scanning. 
		set GlobalParam(ScanFlag) 0

		set idx [ global Histb; HistSelected $Histb ]

		$ChanLabel configure -text VFO
		HighlightBank -1

		# Update the frequency display.
		set CurrentFreq $HistoryFreq($idx)
		set GlobalParam(PreviousFreq) $CurrentFreq

		SetSlideRuleDial

		# Tune radio to the channel.
                set hz [expr {$CurrentFreq * 1000000}]
                set hz [expr {round($hz)}]
                SetFreq $hz

		set GlobalParam(Mode) $HistoryMode($idx)
		SetMode

		$ModeLabel configure -text $GlobalParam(Mode)
		CheckVolume
		update
		}

	return $f.hch
}

##########################################################
# Make frame for the Up and Down single step freq buttons.
##########################################################

proc MakeUpDownFrame { g } \
{
	global GlobalParam

	frame $g -borderwidth 0 -relief flat
	frame $g.but -borderwidth 3 -relief sunken
	set f $g.but

	foreach inc { 50000 25000 15000 12500 10000 5000 1000 100 10 } \
		{
		frame $f.f$inc -borderwidth 3 -relief flat
		}

	button $f.f50000.down50000 -text "-50" -command {Qsy -0.050} -width 5
	button $f.f25000.down25000 -text "-25" -command {Qsy -0.025} -width 5
	button $f.f15000.down15000 -text "-15" -command {Qsy -0.015} -width 5
	button $f.f12500.down12500 -text "-12.5" -command {Qsy -0.0125} -width 5
	button $f.f10000.down10000 -text "-10" -command {Qsy -0.01} -width 5
	button $f.f5000.down5000 -text "-5" -command {Qsy -0.005} -width 5
	button $f.f1000.down1000 -text "-1" -command {Qsy -0.001} -width 5
	button $f.f100.down100 -text "-.1" -command {Qsy -0.0001} -width 5
	button $f.f10.down10 -text "-.01" -command {Qsy -0.00001} -width 5
	button $f.f10.up10 -text "+.01" -command {Qsy 0.00001} -width 5
	button $f.f100.up100 -text "+.1" -command {Qsy 0.0001} -width 5
	button $f.f1000.up1000 -text "+1" -command {Qsy 0.001} -width 5
	button $f.f5000.up5000 -text "+5" -command {Qsy 0.005} -width 5
	button $f.f10000.up10000 -text "+10" -command {Qsy 0.01} -width 5
	button $f.f12500.up12500 -text "+12.5" -command {Qsy 0.0125} -width 5
	button $f.f15000.up15000 -text "+15" -command {Qsy 0.015} -width 5
	button $f.f25000.up25000 -text "+25" -command {Qsy 0.025} -width 5
	button $f.f50000.up50000 -text "+50" -command {Qsy 0.050} -width 5


	foreach inc {50000 25000 15000 12500 10000 5000 1000 100 10} \
		{
		foreach direction { up down } \
			{
			# Pack each pair of up/down buttons.
			pack $f.f$inc.$direction$inc \
				-side top -fill x -expand y
			}
		}

	foreach inc {10 100 1000 5000 10000 12500 15000 25000 50000} \
		{
		pack $f.f$inc -side right -fill x -expand y
		}

	label $g.lab -text "Single Step"

	if { $GlobalParam(ViewUpDownButtons) == "on" } \
		{
		pack $f -side top -fill x -expand y
		}
	return $g
}

##########################################################
# Make the frequency display impossible to read.
##########################################################
proc BlankDisplay { } \
{
	global ChanLabel

	.freqdisplay.display config -foreground black
	return
}


##########################################################
# Make the frequency display possible to read.
##########################################################
proc RestoreDisplay { } \
{
	.freqdisplay.display config -foreground yellow
	return
}

###################################################################
# Start and stop frequency slewing (autotune).
###################################################################

proc SlewCB { w amt updown } \
{
	global GlobalParam

	if { $GlobalParam(Slewing) == 1 } \
		{
		# We are currently slewing. User wants to stop.

		set GlobalParam(Slewing) 0

		return
		}

	# We are not slewing and the user
	# wants to start slewing.

	HighlightBank -1

	set GlobalParam(Slewing) 1
	StartSlew $amt $updown

	return
}

###################################################################
# Make a frame for the freq slew (autotune) buttons.
###################################################################

proc MakeSlewFrame { g } \
{
	global GlobalParam

	frame $g -borderwidth 0 -relief flat
	frame $g.but -borderwidth 3 -relief sunken 
	set f $g.but

	set slew_text(down50000)  "<-50"
	set slew_text(down25000)  "<-25"
	set slew_text(down15000)  "<-15"
	set slew_text(down12500)  "<-12.5"
	set slew_text(down10000)  "<-10"
	set slew_text(down5000)  "<-5"
	set slew_text(down1000)  "<-1"
	set slew_text(down100)	"<-.1"
	set slew_text(down10)	"<-.01"

	set slew_text(up50000)  "->50"
	set slew_text(up25000)  "->25"
	set slew_text(up15000)  "->15"
	set slew_text(up10000)  "->10"
	set slew_text(up12500)  "->12.5"
	set slew_text(up5000)  "->5"
	set slew_text(up1000)  "->1"
	set slew_text(up100) "->.1"
	set slew_text(up10) "->.01"


	foreach inc {10 100 1000 5000 10000 12500 15000 25000 50000 } \
		{
		# Create one frame for each pair of slew buttons.

		frame $f.f$inc -borderwidth 3

		# label $f.f$inc.lab -text $slew_text($inc)


		foreach updown { up down }\
			{
			set w $f.f$inc.$updown
			button $w \
				-width 5 \
				-text $slew_text($updown$inc) \
				-command \
					"
					global inc
					global updown
					SlewCB $w $inc $updown
					"

			pack $f.f$inc.$updown -side top -fill x \
				-expand y
			}

		pack $f.f$inc -side right -fill x -expand y
		}


	if { $GlobalParam(ViewSlewButtons) == "on" } \
		{
		pack $f -side top -fill x -expand y
		}
	return $g
}


###################################################################
# Read the frequency from the receiver and update the
# display widget to reflect the receiver's true frequency.
###################################################################
proc UpdDisplay {} \
{
	global CurrentFreq
	global GlobalParam
	global Note
	global NoteLabel
	global LabelLabel
	global Label

	set CurrentFreq [ReadFreq]

	if { [CheckFreqValid $CurrentFreq mhz] } then \
		{
		set hz [expr {$CurrentFreq * 1000000}]
		set hz [expr {round($hz)}]
		# puts "$CurrentFreq $hz"
		set CurrentFreq [FormatFreq $CurrentFreq ]
		set GlobalParam(PreviousFreq) $CurrentFreq


		# Get and display frequency alpha label
		# from label/comment cache.

		set f [string trimleft $CurrentFreq " "]

		set label ""
		if { [info exists Label($f)] } \
			{
			set label $Label($f)
			}

		$LabelLabel configure  -text $label

		set comment ""
		if { [info exists Note($f)] } \
			{
			set comment $Note($f)
			} \

		set tmp [format "%s - %s" $label $comment]
		$NoteLabel configure -text $tmp

		} \
	else \
		{
		# Invalid frequency.
		bell
		set CurrentFreq $GlobalParam(PreviousFreq)
		set CurrentFreq [FormatFreq $CurrentFreq ]
		puts stderr "UpdDisplay: BAD FREQ"
		}

	# RestoreDisplay
	return
}


proc AlterDisplay { deltahz } \
{
	global CurrentFreq

	set ad [ expr {abs($deltahz)} ]

	# Force the least significant display digits to zero,
	# depending on the step size.

	if { $ad == 1000 }\
		{
		regsub "...$" $CurrentFreq "000" CurrentFreq
		} \
	elseif { $ad == 100 }\
		{
		regsub "..$" $CurrentFreq "00" CurrentFreq
		} \
	elseif { $ad == 10 }\
		{
		regsub ".$" $CurrentFreq "0" CurrentFreq
		}

	set hz [expr {$CurrentFreq * 1000000}]
	set hz [expr {$hz + $deltahz}]
	set CurrentFreq [expr {$hz / 1000000}]

	if { [CheckFreqValid $CurrentFreq mhz] } then \
		{
		set CurrentFreq [FormatFreq $CurrentFreq ]
		set GlobalParam(PreviousFreq) $CurrentFreq

		# Update the slide rule dial every 1 kHz
		if { [regexp {000$} $CurrentFreq] } \
			{
			SetSlideRuleDial
			}
		} \
	else \
		{
		# Invalid frequency.
		bell
		set CurrentFreq $GlobalParam(PreviousFreq)
		set CurrentFreq [FormatFreq $CurrentFreq ]
		}

	# RestoreDisplay
	return
}


##########################################################
# Add widgets to the view menu
##########################################################
proc AddView { m } \
{
	global GlobalParam
	global HistoryFreq
	global HistoryIdx
	global HistoryMode
	global HistoryTime
	global MeterFrame
	global SlideRule


	# Change font.

	if {$GlobalParam(Font) == ""} \
		{
		set msg "Change Font"
		} \
	else \
		{
		set msg [format "Change Font (%s)" $GlobalParam(Font)]
		}

	$m add command -label $msg -command \
		{
		set ft [font_select]
		if {$ft != ""} \
			{
			set GlobalParam(Font) $ft

			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wcf "Change Appearance" \
				$msg info 0 OK
			}
		}

	$m add command -label "Restore Original Font" -command \
		{
		set GlobalParam(Font) ""
		set msg "The change will take effect next "
		set msg [append msg "time you start tk8500."]

		tk_dialog .wcf "Change Appearance" $msg info 0 OK
		}

	$m add separator

	$m add command -label "Change Panel Color" -command \
		{
		set col [tk_chooseColor -initialcolor #d9d9d9]
		if {$col != ""} \
			{
			set GlobalParam(BackGroundColor) $col

			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wcf "Change Appearance" \
				$msg info 0 OK
			}
		}

	$m add command -label "Change Lettering Color" -command \
		{
		set col [tk_chooseColor -initialcolor black]
		if {$col != ""} \
			{
			set GlobalParam(ForeGroundColor) $col

			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wcf "Change Appearance" \
				$msg info 0 OK
			}
		}

	$m add command -label "Change Slider Trough Color" -command \
		{
		set col [tk_chooseColor -initialcolor #c3c3c3]
		if {$col != ""} \
			{
			set GlobalParam(TroughColor) $col

			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wcf "Change Appearance" \
				$msg info 0 OK
			}
		}

	$m add separator



	$m add  checkbutton -label \
		"Dock sliders and keypad to Main Controls window" \
                -variable GlobalParam(DockSliders) \
                -onvalue on \
                -offvalue off \
		-command \
			{
			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wcf "Change Appearance" \
				$msg info 0 OK
			}

	# Helpful tips balloons

	$m add  checkbutton \
		-label "Balloon Help Windows" \
                -variable GlobalParam(BalloonHelpWindows) \
                -onvalue on \
                -offvalue off 

	$m add  checkbutton \
		-label "Slide Rule Dial" \
                -variable GlobalParam(ViewSlideRule) \
                -onvalue on \
                -offvalue off \
		-command \
			{
			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wslew "Change appearance" \
				$msg info 0 OK
			}
	$m add  checkbutton \
		-label "Frequency Slew Buttons" \
                -variable GlobalParam(ViewSlewButtons) \
                -onvalue on \
                -offvalue off \
		-command \
			{
			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wslew "Change appearance" \
				$msg info 0 OK
			}


	$m add  checkbutton \
		-label "Frequency Step Buttons" \
                -variable GlobalParam(ViewUpDownButtons) \
                -onvalue on \
                -offvalue off \
		-command \
			{
			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wud "Change appearance" \
				$msg info 0 OK
			}


	$m add separator


	$m add  checkbutton \
		-label "Frequency Usage Notes" \
                -variable GlobalParam(ViewNote) \
                -onvalue on \
                -offvalue off \
		-command \
			{
			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wslew "Change appearance" \
				$msg info 0 OK
			}


	# Change frequency usage notes font.

	if {$GlobalParam(FreqNotesFont) == ""} \
		{
		set msg "Change Frequency Usage Notes Font"
		} \
	else \
		{
		set msg "Change Frequency Usage Notes Font"
		set msg [format "%s (%s)" \
			$msg $GlobalParam(FreqNotesFont)]
		}

	$m add command -label $msg -command \
		{
		set ft [font_select]
		if {$ft != ""} \
			{
			set GlobalParam(FreqNotesFont) $ft

			set msg "The change will take effect next "
			set msg [append msg "time you start tk8500."]

			tk_dialog .wcf "Change Appearance" \
				$msg info 0 OK
			}
		}

	$m add command -label \
		"Restore Original Frequency Usage Notes Font" \
		-command \
		{
		set GlobalParam(FreqNotesFont) ""
		set msg "The change will take effect next "
		set msg [append msg "time you start tk8500."]

		tk_dialog .wcf "Change Appearance" $msg info 0 OK
		}

	$m add separator

	$m add  checkbutton \
		-label "Session History Window" \
                -variable GlobalParam(ViewHistory) \
                -onvalue on \
                -offvalue off \
                -command \
			{
			if {$GlobalParam(ViewHistory) == "on"} \
				{
				catch {wm deiconify .hist}
				} \
			else \
				{
				catch {wm iconify .hist}
				}
			}

	$m add  command \
		-label "Clear Session History" \
                -command \
			{
			unset HistoryIdx
			unset HistoryTime
			unset HistoryFreq
			unset HistoryMode
			catch {destroy .hist}
			}

	return
}

##########################################################
# Add widgets to the data menu
##########################################################
proc AddData { m } \
{
	global GlobalParam


	$m add command -label "Check for duplicate frequencies" \
		-command { CkDuplicate }


	$m add separator

	$m add command -label "Clear All Channels ..." \
		-command { ClearAllChannels }


	$m add command -label "Sort Memory Channels ..." \
		-command { MakeSortFrame }

	return
}

##########################################################
# Add widgets to the Options menu
##########################################################
proc AddOptions { m } \
{
	global GlobalParam


	$m add  radiobutton \
		-label "Slew speed slow" \
		-variable GlobalParam(SlewSpeed) \
		-value 1000


	$m add  radiobutton \
		-label "Slew speed fast" \
		-variable GlobalParam(SlewSpeed) \
		-value 500

	$m add separator

	$m add  radiobutton \
		-label "Scan resume OFF" \
		-variable GlobalParam(Resume) \
		-value off \
		-command \
			{
			SetResume off
                	set GlobalParam(VSC) on
			SetVSC $GlobalParam(VSC)
			}


	$m add  radiobutton \
		-label "Scan resume DELAY" \
		-variable GlobalParam(Resume) \
		-value delay \
		-command {SetResume delay}

	$m add  radiobutton \
		-label "Scan resume INFINITE" \
		-variable GlobalParam(Resume) \
		-value infinite \
		-command {SetResume infinite}

	SetResume $GlobalParam(Resume)

	$m add separator

	$m add  checkbutton \
		-label "Voice Scan Control" \
                -variable GlobalParam(VSC) \
                -onvalue on \
                -offvalue off \
                -command \
			{
			if { $GlobalParam(Resume) == "off" } \
				{
				set GlobalParam(Resume) delay
				}
			SetVSC $GlobalParam(VSC)
			}


	if {$GlobalParam(Resume) == "off"} \
		{
		set GlobalParam(VSC) on
		}

	SetVSC $GlobalParam(VSC)

	return $m
}


##########################################################
# Add widgets to the Log menu
##########################################################
proc AddLog { m } \
{
	global GlobalParam
	global Lid
	global Lfilename


	set msg "Log active frequencies in a file automatically"

	$m add checkbutton \
		-label $msg \
                -variable GlobalParam(AutoLogging) \
                -onvalue on \
                -offvalue off \
                -command \
			{
			if {$Lfilename == ""} \
				{
				InitLogFile
				}
			}

	$m add command -label "Log the current frequency and time." \
		-command \
			{
			if { $Lfilename == "" } \
				{
				InitLogFile
				}
			LogTransmission
			}

	return $m
}

###################################################################
# Prompt user for the name of a file to create for logging
# active frequencies.
# Open the file.
###################################################################

proc InitLogFile { } \
{
	global FileTypes
	global GlobalParam
	global Lfilename
	global Lid

	set Lfilename [Mytk_getSaveFile \
		.mainframe \
		$GlobalParam(LogFileDir) \
		.csv \
		"Create a log file" \
		$FileTypes]

	if { [string length $Lfilename] != 0 } \
		{
		set GlobalParam(LogFileDir) \
			[ Dirname $Lfilename ]

		if { [catch {open $Lfilename {WRONLY APPEND CREAT} } \
			Lid] } \
			{
			bell
			tk_dialog .logfilerror "Log file error" \
				"Cannot create log file." error 0 OK
			}
		}
	return
}

##########################################################
# Add option widgets to the Presets menu
##########################################################
proc AddPresets { m } \
{
	global CurrentFreq
	global GlobalParam
	global PreviousFreq
	global PresetFreq PresetLabel PresetMode
	global Psi

	set n [array size PresetFreq]

	# For each preset frequency.

	for { set Psi 0 } { $Psi < $n } { incr Psi } \
		{

		set cmd [format "$m add command "]
		set cmd [append cmd "\-label {$PresetLabel($Psi)} "]
		set cmd [append cmd "\-command {GoToPreset $Psi}"]
		eval $cmd
		}
	return $m
}

proc GoToPreset { i } \
{
	global Bwpot
	global CurrentFreq
	global GlobalParam
	global Mode
	global ModeLabel
	global RMode
	global PreviousFreq
	global PresetFreq PresetLabel PresetMode

	set CurrentFreq [FormatFreq $PresetFreq($i) ]
	set hz [expr {$CurrentFreq * 1000000}]
	set hz [expr {round($hz)}]
	SetFreq $hz
	set GlobalParam(PreviousFreq) $CurrentFreq

	set m $PresetMode($i)
	set m [string toupper $m]
	set GlobalParam(Mode) $m
	SetMode
	$ModeLabel configure -text $GlobalParam(Mode)

	SetSlideRuleDial

	return
}


##########################################################
# Add choices to the Radio menu
##########################################################
proc AddRadio { m } \
{
	global GlobalParam
	global Libdir

	$m add command -label "Speech" \
		-command { Speak }
	
	$m add separator

	$m add command -label "Read from radio ..." \
		-command { \
			Radio2File .mainframe
			update
			}
	
	$m add command -label "Write memories to radio ..." \
		-command { \
			File2Radio .mainframe
			update
			}
	
	$m add command -label "Write bank names to radio ..." \
		-command { \
			for {set i 0} {$i < 20} {incr i} \
				{
				WriteBankName \
					$i $GlobalParam(BankName$i)
				update
				}
			}
	
	$m add separator


	$m add  checkbutton \
		-label "Debug" \
                -variable GlobalParam(Debug) \
                -onvalue "1" \
                -offvalue "0"

	return $m
}


##########################################################
#
# Create a progress gauge widget.
#
#
# From "Effective Tcl/Tk Programming,"
# by Mark Harrison and Michael McLennan.
# Page 125.
#
##########################################################
proc gauge_create {win {color ""}} \
{
	frame $win -class Gauge

	# set len [option get $win length Length]
	set len 300

	canvas $win.display -borderwidth 0 -background white \
		-highlightthickness 0 -width $len -height 20
	pack $win.display -expand yes -padx 10
	if {$color == ""} \
		{
		set color [option get $win color Color]
		}


	$win.display create rectangle 0 0 0 20 \
		-outline "" -fill $color -tags bar
	$win.display create text [expr {0.5 * $len}] 10 \
		-anchor c -text "0%" -tags value
	return $win
}

proc gauge_value {win val} \
{
	if {$val < 0 || $val > 100} \
		{
		error "bad value \"$val\": should be 0-100"
		}
	set msg [format "%.0f%%" $val]
	$win.display itemconfigure value -text $msg

	set w [expr {0.01 * $val * [winfo width $win.display]}]
	set h [winfo height $win.display]
	$win.display coords bar 0 0 $w $h

	update
}

proc MakeWaitWindow {f cnflag color} \
{
	global CancelXfer

	set CancelXfer 0

	frame $f
	button $f.cancel -text Cancel -command {\
		global CancelXfer; set CancelXfer 1; puts "Canceled"}

	gauge_create $f.g PaleGreen
	option add *Gauge.borderWidth 2 widgetDefault
	option add *Gauge.relief sunken widgetDefault
	option add *Gauge.length 300 widgetDefault
	option add *Gauge.color gray widgetDefault

	pack $f.g -expand yes -fill both \
		-padx 10 -pady 10

	if {$cnflag} \
		{
		pack $f.cancel -side top -padx 3 -pady 3
		}

	

	pack $f
	return $f.g
}

##########################################################
# Copy from radio to .csv file
##########################################################
proc Radio2File { f }\
{
	global FileTypes
	global GlobalParam
	global Home
	global Ofilename


	set Ofilename [Mytk_getSaveFile $f \
		$GlobalParam(MemoryFileDir) \
		.csv \
		"Copy from IC-R8500 to file" \
		$FileTypes]


	if {$Ofilename != ""} \
		{
		# puts "going to read from radio into $Ofilename"
	
		set GlobalParam(MemoryFileDir) \
			[ Dirname $GlobalParam(Ifilename) ]

		# Create and display progress bar.
		toplevel .pbw
		wm title .pbw "Reading IC-R8500"
		grab set .pbw
		set p [MakeWaitWindow .pbw.g 0 PaleGreen]
		set pc 0
		gauge_value $p $pc
		update
	
		# set memorydata [ReadMem $p]

		set fid [open $Ofilename "w"]

		# Write first line as the field names.
		puts $fid [format "Bank,Ch,MHz,Step,Mode,Skip,Select,Atten,Volume,Label,Note"]

		# We don't know whether a channel exists within
		# a bank until we try to read it.

		# Set the highest channel number so we
		# won't waste time trying to read many non-existent
		# channels.

		set hi $GlobalParam(HighestChannel)

		# For each memory bank.
		for {set bn 0} {$bn < 25} {incr bn} \
			{
			# For each memory channel in a bank.
			for {set ch 0} {$ch <= $hi} {incr ch} \
				{
				set lst [ReadAChannel $bn $ch]
				set status [lindex $lst 0]
				set line [lindex $lst 1]

				# Check for empty channel.
				# Check for invalid channel.

				if { ($status == "invalid")
					|| ($status == "empty")} \
					{
					continue
					}

				set memorydata [DecodeAChannel \
					$line $bn $ch ]

				set f [lindex $memorydata 0]
				set ts [lindex $memorydata 1]
				set mode [lindex $memorydata 2]
				set lab [lindex $memorydata 3]
				set skip [lindex $memorydata 4]
				set select [lindex $memorydata 5]
				set atten [lindex $memorydata 6]

				if { $f == 0 } {continue}

				set lab [string trimright $lab " "]
				set lab [string trimleft $lab " "]
				if {[string length $lab] > 0} \
					{
					set lab [format "\"%s\"" $lab]
					}
				if {$atten == 0} {set atten ""}
				set s [format "%d,%d,%.5f,%s,%s,%s,%s,%s,%s,%s," \
					$bn $ch $f $ts \
					$mode \
					$skip $select $atten "" $lab]
				puts $fid $s
				# puts stderr $s
				}

			# Update progress bar widget.
			set pc [ expr $bn * 100 / 25 ]
			gauge_value $p $pc
			}

		close $fid

		# Zap the progress bar.
		grab release .pbw
		destroy .pbw

		tk_dialog .belch "Read IC-R8500" \
			"Transfer Complete" info 0 OK

		return
		}
}

proc FileExistsDialog { file } \
{
	set result [tk_dialog .fed "Warning" \
		"File $file already exists. Overwrite file?" \
		warning 0 Cancel Overwrite ]

	puts "result is $result"
	return $result
}


##########################################################
# Copy from a .csv file to radio
##########################################################
proc File2Radio { f }\
{
	global FileTypes
	global GlobalParam
	global Cht;


	if {$GlobalParam(Ifilename) == ""} \
		{
		# Prompt for file name and read the file.
		# wm deiconify $Cht;
		set fr_table [MakeChannelListFrame $Cht]
		if {$GlobalParam(Ifilename) == ""} then {return}
		pack $fr_table
		}


	if {$GlobalParam(Ifilename) != ""} \
		{

		# Create a new window with a progress gauge
		# and prevent user from accessing main window
		# during the data transfer.

		toplevel .pbw
		wm title .pbw "Writing to IC-R8500"
		grab set .pbw

		set p [MakeWaitWindow .pbw.g 1 PaleGreen]
	
		Memories2Radio $p

		# Zap the progress bar window.
		grab release .pbw
		destroy .pbw

#			# warning: Font is ugly
#			tk_messageBox -icon info \
#				-message "Transfer Complete"

		tk_dialog .wpbr "Write to IC-R8500" \
			"Transfer Complete" info 0 OK

		return
		}
}
##########################################################
# Format and write memory data to the radio.
# Data has previously been stored in global arrays.
##########################################################
proc Memories2Radio { g } \
{
	global MemAtten
	global Bw
	global CancelXfer
	global MemPopulated
	global MemFreq
	global MemLabel
	global Mode
	global MemMode
	global MemSelect
	global Sid
	global MemSkip
	global MemStep


	set keylist [ array names MemPopulated ]
	set keylist [ lsort -dictionary $keylist ]

	set n [ llength $keylist ]
	set i 0

	foreach key $keylist \
		{
		update
		if {$CancelXfer} then {break}
		if {$key == "" } then {continue}
		if {$MemPopulated($key) != 1 } then {continue}

		set lst [Key2Chb $key]
		set bn [lindex $lst 0]
		set ch [lindex $lst 1]

		set s [EncodeAChannel $bn $ch \
			$MemFreq($key) \
			$MemMode($key) \
			$MemStep($key) \
			$MemAtten($key) \
			$MemSkip($key) \
			$MemSelect($key) \
			$MemLabel($key) ]


		# Write memory channel info to radio.
		WriteAChannel $s
 
		incr i
		set pc [ expr $i * 100 / $n ]
		gauge_value $g $pc
		}

	return
}


###################################################################
# Read S meter value from radio and update the S meter widget.
#
# This sequence repeats continuously whenever a callback
# is not running.
###################################################################
proc PollSmeter {} \
{
	global BlinkToggle
	global ChanLabel
	global Note
	global NoteLabel
	global CurrentFreq
	global GlobalParam
	global Label
	global LabelLabel
	global ModeLabel
	global RMode
	global ScanCounter
	global SignalLabel

	waiter 100

	set ScanCounter 0

	while {1} \
		{

		# Let events happen for a while.
		after $GlobalParam(DisplayUpdateInterval) [list set imdone 1]
		vwait imdone

		set signal [ReadSquelchStatus]

		# If signal present

		if {$signal} \
			{
			CheckVolume

			# Read the radio freq and
			# update the display widget.

			UpdDisplay

			# Read the S-meter
			ReadSmeter
			set m [ReadMode]

			updateMeter $GlobalParam(Smeter)

			SetSlideRuleDial
			RestoreDisplay
			RestoreSlideRuleDial

			set m $RMode($m)
			set GlobalParam(Mode) $m
			$ModeLabel configure -text $GlobalParam(Mode)

			# Illuminate signal lamp.
			$SignalLabel configure -text "SIGNAL"

			# If we are scanning and are supposed to stop
			# forever when we find a signal, and we
			# have found a signal ...

			# Note: The VSC takes precedence
			# over the Resume setting sometimes.
			# so the radio
			# will resume scanning after if hears a
			# signal even if the Resume is set to infinite
			# if VSC is enabled.
			# Since the radio's behavior is not consistent,
			# we will force consistency and make the
			# scan halt if the resume setting is
			# infinite.

			if { $GlobalParam(ScanFlag) \
				&& ($GlobalParam(Resume) == "infinite")}\
				{
				# Stop the scan.
				StopScan
				set GlobalParam(ScanFlag) 0
				$ChanLabel configure -text "VFO"
				}
			} \
		else \
			{
			# No signal.
			set GlobalParam(LastHit) 0

			if {$GlobalParam(ScanFlag)} \
				{
				# We are scanning and there is
				# no signal so blank out the
				# frequency display because
				# we don't know the frequency
				# the radio is tuned to a this
				# instant.

				BlankDisplay
				BlankSlideRuleDial
				$NoteLabel configure -text " "
				$LabelLabel configure -text " "
				wm title . "untitled .csv - tk8500"
				} \
			else \
				{
				# Not scanning.
				# Read the radio freq and
				# update the display widget.

				UpdDisplay
				SetSlideRuleDial
				RestoreDisplay
				RestoreSlideRuleDial
				}
			# Extinguish signal lamp.
			$SignalLabel configure -text " "

			# Zero the S meter
			set GlobalParam(Smeter) 0
			updateMeter $GlobalParam(Smeter)

			}

		if {$GlobalParam(ScanFlag) && ($signal == 0)} \
			{
			# Don't bother to poll the S meter
			# if there is no
			# signal while we are scanning.

			# Zero the S meter
			set GlobalParam(Smeter) 0
			updateMeter $GlobalParam(Smeter)

			set ty $GlobalParam(ScanType)

			if { ($ScanCounter == 0) \
				&& ($ty != "Limit Scan") \
				&& ($ty != "Auto Write Scan") } \
				{
				NextBank
				}

			} \
		else \
			{
			# Signal present or not scanning.
			# ReadSmeter
			# updateMeter $GlobalParam(Smeter)
			}

		if {$GlobalParam(ScanFlag) && $signal} \
			{
			# Signal present and scanning.

			if {$GlobalParam(LastHit) != $CurrentFreq} \
				{
				# Xmsn started on a new freq.

				if { $GlobalParam(AutoLogging) == "on"} \
					{
					LogTransmission  
					}
				set GlobalParam(LastHit) $CurrentFreq
				}
			}

		if {$GlobalParam(ScanFlag)} \
			{

			incr ScanCounter
			set ScanCounter \
				[expr {fmod ($ScanCounter, 3)}]
			set ScanCounter \
				[expr {round ($ScanCounter)}]
#			puts stderr "$ScanCounter"
			if { [info exists BlinkToggle] == 0} \
				{
				set BlinkToggle 0
				}
			if {$BlinkToggle} \
				{
				set BlinkToggle 0
				$ChanLabel configure -text $GlobalParam(ScanType)
				} \
			else \
				{
				set BlinkToggle 1
				$ChanLabel configure -text " "
				}
			}
		}
}

###################################################################
# Based on the current frequency, select the active volume
# control and adjust the volume.
###################################################################

proc CheckVolume { } \
{
	global VolumeByMemFreqArray
	global CurrentFreq
	global GlobalParam
	global Volume1Widget
	global Volume2Widget

	set f [format "%.5f" $CurrentFreq]

	set val ""
	if { ([info exists VolumeByMemFreqArray($f) ] ) \
		&& ($VolumeByMemFreqArray($f) != "") } \
		{
		set GlobalParam(VolumeWhich) 2
		} \
	else \
		{
		set GlobalParam(VolumeWhich) 1
		}

	SetVolume

	return
}

###################################################################
# Adjust the volume based on the designated volume control.
#
# Note:
#	To save time, we will not send a volume command to
#	be sent to the radio if the volume is already at the
#	desired level.
###################################################################

proc SetVolume { {val 0} } \
{
	global GlobalParam
	global Volume1Widget
	global Volume2Widget

	if {$GlobalParam(VolumeWhich) == 2} \
		{
		$Volume1Widget configure -troughcolor #c3c3c3
		$Volume2Widget configure -troughcolor green

		# The boost volume flag is set
		# so change the volume level if it is different
		# than the volume 2 level.

		if {$GlobalParam(VolumeCurrent) \
			!= $GlobalParam(Volume2) } \
			{
			SetAF $GlobalParam(Volume2)
			}
		} \
	else \
		{
		$Volume1Widget configure -troughcolor green
		$Volume2Widget configure -troughcolor #c3c3c3

		if {$GlobalParam(VolumeCurrent) \
			!= $GlobalParam(Volume1) } \
			{
			SetAF $GlobalParam(Volume1)
			}
		}


	return
}

###################################################################
# Select the next bank to scan and instruct the radio
# to change to that bank and commence scanning.
###################################################################
proc NextBank { } \
{
	global ChanLabel
	global BankLabel
	global GlobalParam
	global ModeScanLabel

	set current_bank $GlobalParam(Bank)

	# Create a list of scan banks.
	# Note: we must recreate this list frequently
	# so the user can enable and disable banks
	# while the radio is scanning.

	set lst {}
	for {set bn 0} {$bn < 20} {incr bn} \
		{
		if {$GlobalParam(ScanBank$bn) == "on"} \
			{
			lappend lst $bn
			}
		}

	set nbanks [llength $lst]

	if {$nbanks == 0} \
		{
		# User didn't choose any scan banks
		# so we force bank 0.

		set bn 0
		set GlobalParam(ScanBank$bn) on
		} \
	elseif {$nbanks == 1} \
		{
		# There is only one bank to scan.
		set bn [lindex $lst 0]
		} \
	else \
		{
		# Find the next active bank after the
		# current bank.

		# Find the index of the current bank.
		for {set i 0} {$i < $nbanks} {incr i} \
			{
			set b [lindex $lst $i]
			if {$b == $current_bank } \
				{
				break
				}
			}

		# Choose the bank after the current bank.
		incr i
		if {$i >= $nbanks} \
			{
			set i 0
			}
		set bn [lindex $lst $i]
		}
	
	if {$GlobalParam(Bank) == $bn } \
		{
		# We just scanned the only bank to scan.
		# return
		}

	set GlobalParam(Bank) $bn

	SetBank $GlobalParam(Bank)

	# Update the bank label display.
	set tmp [FormatBank $GlobalParam(Bank)]
	$BankLabel configure -text $tmp

	HighlightBank $bn

	if {$GlobalParam(ModeScan) != "off"} \
		{
		# We are already mode scanning so stop mode scanning.
		StopScan
		set GlobalParam(ScanFlag) 0

		set GlobalParam(Mode) $GlobalParam(ModeScan)
		SetMode
		if { [StartModeScan] } \
			{
			# Cannot do mode scan.

#			DisableModeScan
#
#			tk_dialog .noscan "Mode Scan error" \
#				"Cannot start Mode Scan in bank $bn" \
#				error 0 OK
#			$ChanLabel configure -text "VFO"


			# The radio responded with an error.
			# Cannot do Mode Scan in this
			# bank probably because there are not enough
			# memory channels in this bank with the
			# designated mode.
			# Therefore, we will ruthlessly
			# deselect this memory bank so we won't
			# bother to try scanning it.

			set GlobalParam(ScanBank$bn) off

			}
		set GlobalParam(ScanFlag) 1
		} \
	elseif {$GlobalParam(ScanType) == "Memory Scan"} \
		{
		StartMemoryScan
		} \
	elseif {$GlobalParam(ScanType) == "Select Scan"} \
		{
		if { [StartSelectMemoryScan] } \
			{
			# The radio responded with an error.
			# Cannot do Select Memory Scan in this
			# bank probably because there are no
			# memory channels in this bank with the
			# Select tag enabled.
			# Therefore, we will ruthlessly
			# deselect this memory bank so we won't
			# bother to try scanning it.

			set GlobalParam(ScanBank$bn) off
			}
		}


	if {$GlobalParam(PriorityScan)} \
		{
		StartPriorityScan
		}

	return
}

###################################################################
# Meter widget adapted from
# Bob Techentin's code.
###################################################################
proc updateMeter {v} \
{
	global MeterFrame

	# set meterht 75
	set meterht 50
	set min 0
	set max 255.0
 
	set pos [expr {$v / $max}]
	set x [expr {$meterht - $meterht * .9*(cos($pos*3.14))}]
	set y [expr {$meterht - $meterht * .9*(sin($pos*3.14))}]
	$MeterFrame.c coords meter $meterht $meterht $x $y
}
###################################################################
# Create a meter widget
#
# Variables:
#	max 	-the highest amplitude of what we will measure
#	meterht	-meter height in pixels
###################################################################
proc MakeMeter { } \
{
	global MeterFrame
	global Sunits2Db

	set max 255.0
	set meterht 50
	# set meterht 75
	set meterwidth [expr {$meterht * 2.0}]

	set f $MeterFrame
	frame $f -relief sunken -borderwidth 10 

	set meterhtplus [expr {$meterht * 1.1}]
	grid [canvas $f.c -width $meterwidth -height $meterhtplus \
		-borderwidth 1 -relief sunken -background white]

	# Calculate endpoints for the arc.

	set m10 [expr {$meterht * .1}]
	set m190 [expr {$meterwidth - $m10}]

	$f.c create arc $m10 $m10 $m190 $m190 \
		-extent 160 \
		-start 10 -style arc -outline black -width 2

	$f.c create line $meterht $meterht $m10 $meterht \
		-tag meter -width 2 \
		-fill red

	# Draw meter calibrations.
	set ndivs [ expr {$max / 24} ]
	for {set i 0} {$i <= $ndivs} {incr i}\
		{
		if {$i == 0} {continue}
		set pos [expr {$i * 24 / $max}]

		set x [expr {$meterht - $meterht \
			* .75 *(cos($pos*3.14))}]
		set y [expr {$meterht - $meterht \
			* .75 *(sin($pos*3.14))}]

		# Scale is 0 - 10 units.

		$f.c create text $x $y -text $i \
			-justify center \
			-fill black \
			-font {Courier 10 normal}
		}
	set ylogo [expr {.7 * $meterht}]
	$f.c create text $meterht $ylogo -text "tk8500" \
		-justify center \
		-fill blue \
		-font {Courier 10 bold}
	return $f
}

###################################################################
# Create a Keypad.
# This is based on a calculator program by Richard Suchenwirth.
###################################################################
proc MakeKeyPad {f} \
{
	global Enw

	frame $f -relief raised -borderwidth 10
	set Enw [entry $f.e -width 12 -textvar e \
		-just right -background white]
	grid $Enw -columnspan 3 
	bind $f.e <Return> {Ekey mhz}


	set hint ""
	set hint [append hint "You can enter a new frequency\n"]
	set hint [append hint "(in kHz or MHz) by using\n"]
	set hint [append hint "the simulated keypad."]
	balloonhelp_for $f $hint


	set n 0
	foreach row {
		{7 8 9 }
		{4 5 6 }
		{1 2 3 }
		{C 0 . }
		{ MHz kHz Spc }
		} {
		foreach key $row {
			switch -- $key {
				MHz   {set cmd {Ekey mhz}}
				kHz   {set cmd {Ekey khz}}
				C       {set cmd {set clear 1; set e ""}}
				Spc    {set cmd {Speak}}
				default {set cmd "Hit $f $key"}
				}
			lappend keys [button $f.[incr n] \
				-text $key \
				-width 3 \
				-command $cmd]
			}
		eval grid $keys -sticky we -padx 1 -pady 1
		set keys [list]
		}

	# grid $f.$n -columnspan 3 ;# make last key (E) triple wide
	return $f
}

proc Ekey { units }\
{
	global Enw
	global Bwpot
	global CurrentFreq
	global GlobalParam
	global Readout

	# Calculate the length of string entered.
	set elen [ string length $::e ]
	set tmp $::e


	# Trim leading spaces or zeros.
	regsub {^[ 0]*} $::e "" $tmp
	set CurrentFreq $tmp



	if { [CheckFreqValid $CurrentFreq $units] } then \
		{
		if { $units == "khz" } \
			{
			set CurrentFreq [ expr { double($CurrentFreq) \
				/ double(1000) } ]
			}
		set CurrentFreq [FormatFreq $CurrentFreq ]
		set hz [expr {$CurrentFreq * 1000000}]
		set hz [expr {round($hz)}]
		SetFreq $hz
		set GlobalParam(PreviousFreq) $CurrentFreq

		SetSlideRuleDial
		Add2History

		} \
	else \
		{
		# Invalid frequency.
		bell
		set CurrentFreq $GlobalParam(PreviousFreq)
		set CurrentFreq [FormatFreq $CurrentFreq ]
		}

	# Clear the string entered in the local entry box.
	$Enw delete 0 $elen
	return
 }
 
proc Hit {f key} \
{
	if $::clear {
		set ::e ""
		if ![regexp {[0-9().]} $key] {set ::e $::res}
		$f.e config -fg black
		$f.e icursor end
		set ::clear 0
		}
	$f.e insert end $key
}
set clear 0

###################################################################
# Return 1 if frequency is in range 0 - 2000 exclusive.
###################################################################
proc FreqInRange { f units } \
{
	if {$units == "mhz" } \
		{
		if { $f > 0 && $f < 2000.0 } \
			{
			return 1
			}
		} \
	elseif {$units == "khz" } \
		{
		if { $f > 0 && $f < 2000000.0 } \
			{
			return 1
			}
		}
	return 0
}

###################################################################
# Return 1 if string 's' is a valid frequency.
# Return 0 otherwise.
#
# Units should be khz or mhz
###################################################################
proc CheckFreqValid { s units }\
{
	if {$s == ""} then {return 0}

	# Check for non-digit and non decimal point chars.
	set rc [regexp {^[0-9.]*$} $s]
	if {$rc == 0} then {return 0}


	# All digits.
	set rc [regexp {^[0-9]*$} $s]
	if {$rc == 1} \
		{
		return [FreqInRange $s $units]
		}

	if {$s == "."} then {return 0}

	# Check for Two or more decimal points
	set tmp $s
	set tmp [split $s "."]
	set n [llength $tmp]
	if { $n >= 3 } then {return 0}
	
	return [FreqInRange $s $units]
}



###################################################################
# Format a bank label
###################################################################
proc FormatBank { bn } \
{
	global GlobalParam

	set bankname $GlobalParam(BankName$bn)
	set tmp [format "Bank %2d %5s" $bn $bankname ]
	return $tmp
}

###################################################################
# Format a channel label
###################################################################
proc FormatChan { ch } \
{
	set tmp [format "Ch %3d" $ch ]
	return $tmp
}

###################################################################
# Format a frequency into the proper
# floating point representation for display, i.e.,
#	4 digits . 5 digits
###################################################################
proc FormatFreq { freq } \
{
	set tmp [format "%10.5f" $freq ]
	return $tmp
}


###################################################################
# Set default receiver parameters
###################################################################
proc SetUp { } \
{
	global env
	global GlobalParam
	global RootDir
	global tcl_platform


	if { [regexp "Darwin" $tcl_platform(os) ] } \
		{
		# For Mac OS X.
		set RootDir ":"
		} \
	else \
		{
		set RootDir "/"
		}

	set GlobalParam(Debug) 0
	# set GlobalParam(Device) /dev/ttyS1
	set GlobalParam(Ifilename) {}
	set GlobalParam(MemoryFileDir) $RootDir
	set GlobalParam(PreviousFreq) 0.0

	return
}



###################################################################
# Read frequencies, labels, and comments from the label/comment file.
#
# Strip off comments.
# Strip out blank and empty lines.
#
# Remaining lines should be of the form:
#
# freq=label=comment
###################################################################

proc ReadLabel { } \
{
	global env
	global Label
	global LabelFile
	global Mode
	global RootDir


	if [ catch { open $LabelFile "r"} fid] \
		{
		# error
		# Tattle "Cannot open $LabelFile for reading."
		return
		} 


	# For each line in the file.

	while { [gets $fid rline] >= 0 } \
		{
		set line $rline

		# Discard comments.
		regsub {#.*} $line "" line

		# Skip blank line.
		if { [regexp {^ *$} $line] } \
			{
			continue
			}

		set line [string trimleft $line " "]

		# Valid parameter line must be of the form:
		# Fieldname=value

		set plist [ split $line "=" ]
		set n [llength $plist]

		set msg [format "Error in label file %s,\n" $LabelFile]
		set msg [append msg [format "in this line:\n%s" $rline]]

		if {$n < 2} \
			{
			tk_dialog .error "tk8500" \
				$msg error 0 OK

			exit 1
			}
		set field [ lindex $plist 0 ]
		set value [ lindex $plist 1 ]
		set comment [ lindex $plist 2 ]
		set Label($field) $value
		}


	close $fid
	return
}

###################################################################
# Save freq/label/comment correspondence in the label file.
###################################################################

proc SaveLabel { } \
{
	global env
	global Note
	global GlobalParam
	global LabelFile
	global Label
	global Version

	if [ catch { open $LabelFile "w"} fid] \
		{
		# error
		tk_dialog .error "tk8500" \
			"Cannot save labels in file $LabelFile" \
			error 0 OK

		return
		} 

	puts $fid "# tk8500 label file, Version $Version"

	set a [array names Label]
	set a [ lsort -dictionary $a ]

	foreach x $a \
		{
		set comment ""
		if {[ info exists Note($x) ]} \
			{
			set comment $Note($x)
			}

		puts $fid "$x=$Label($x)=$comment"
		}

	close $fid
	return
}


###################################################################
# Start or stop frequency slewing (autotune).
#
# Inputs:
#	ts	-frequency increment in kHz
#	updown	-direction up or down
###################################################################
proc StartSlew { ts updown }\
{
	global GlobalParam

	set GlobalParam(Slewing) 1;
	SetTS $ts
 
	if { $updown == "down" } \
		{
		set amount [ expr { -1 * $ts / 1000000.0 } ]
		} \
	else \
		{
		set amount [ expr { $ts / 1000000.0 } ]
		}

	while { $GlobalParam(Slewing) } \
		{
		Qsy $amount
		waiter $GlobalParam(SlewSpeed)
		}

	return
}


###################################################################
# Explain to user that he cannot scan memory channels
# until he opens a memory data file.
###################################################################
proc CannotScan {} \
{
	set msg ""
	set msg [append msg "You must open a memory data "]
	set msg [append msg "file before scanning."]

	tk_dialog .noscan "Memory scan" $msg warning 0 OK

	return
}

###################################################################
# Add a frequency and mode to the history list and
# timestamp the entry.
#
# Each entry is assigned a unique, sequential number, starting
# at 0.  Once the history list is full, we discard the oldest
# entry and move the remaining entries down one slot.
###################################################################

proc Add2History { } \
{
	global CurrentFreq
	global GlobalParam
	global HistoryTime
	global HistoryFreq
	global HistoryLabel
	global HistoryMode
	global HistoryIdx
	global Label
	global RMode


	# Maximum number of history entries - 1
	set n 99

	if {[ info exists HistoryIdx ] == 0 } \
		{
		set HistoryIdx -1
		}

	incr HistoryIdx

	# If list is full...

	if { $HistoryIdx > $n} \
		{
		# Overlay the oldest entry and move each
		# remaining entry down one slot.

		for {set i 0} { $i < $n} {incr i} \
			{
			set ip1 [expr {$i + 1}]
			set HistoryTime($i) $HistoryTime($ip1)
			set HistoryFreq($i) $HistoryFreq($ip1)
			set HistoryLabel($i) $HistoryLabel($ip1)
			set HistoryMode($i) $HistoryMode($ip1)
			}
		set HistoryIdx $n
		}
	set seconds [clock seconds]
	set HistoryTime($HistoryIdx) [clock format $seconds \
		-format {%T}]
	set HistoryFreq($HistoryIdx) $CurrentFreq

	set f [string trimleft $CurrentFreq " "]
	if { [info exists Label($f)] } \
		{
		set HistoryLabel($HistoryIdx) \
			[string range $Label($f) 0 7]
		} \
	else \
		{
		set HistoryLabel($HistoryIdx) \
			[string range "          " 0 7]
		}

	set mode $GlobalParam(Mode)
	set HistoryMode($HistoryIdx) $mode

	RefreshHistory

	return
}

###################################################################
# Create a label to hold a comment about the user of this
# frequency.
###################################################################

proc MakeNote { f }\
{
	global NoteLabel
	global CurrentFreq
	global GlobalParam

	global SlideRule
	frame $f -background ""

	set NoteLabel $f.comment

	if {$GlobalParam(FreqNotesFont) == ""} \
		{
		label $NoteLabel -text " " -borderwidth 3 \
			-justify left \
			-background black -foreground yellow
		} \
	else \
		{
		label $NoteLabel -text " " -borderwidth 3 \
			-justify left \
			-background black -foreground yellow \
			-font $GlobalParam(FreqNotesFont)
		}



	if {$GlobalParam(ViewNote) == "on"} \
		{
		pack $NoteLabel -padx 0 -pady 0 -expand yes -fill x
		}

	return $f
}

###################################################################
# Create an analog style slide rule dial using a scale widget.
# The scale and reading is adjusted by the SetSlideRuleDial
# procedure as the user tunes the radio.
###################################################################

proc MakeSlideRule { f }\
{
	global CurrentFreq
	global DialFreq
	global GlobalParam

	global SlideRule
	frame $f -background ""


	scale $f.d -from 0 -to 30 -showvalue yes \
		-orient horizontal \
		-width 6 \
		-sliderlength 6 -resolution 1 \
		-tickinterval 10 \
		-troughcolor white \
		-background black -foreground white \
		-activebackground red \
		-variable DialFreq \
		-state disabled

	set SlideRule $f.d

	if {$GlobalParam(ViewSlideRule) == "on"} \
		{
		pack $f.d -padx 0 -pady 0 -expand yes -fill x
		}

	return $f
}

###################################################################
# Update the slide rule tuning dial widget to show the
# frequency according to the global variable CurrentFreq.
###################################################################

proc SetSlideRuleDial {} \
{
	global CurrentFreq
	global DialFreq
	global SlideRule

	set lowlim [expr {floor($CurrentFreq)}]
	set hilim  [expr {ceil($CurrentFreq)}]


	if {$hilim == $lowlim} \
		{
		# We are tuned to a band edge.
		set hilim [ expr {$lowlim + 1.0}]
		}


	$SlideRule configure -from $lowlim -to $hilim \
		-showvalue yes -tickinterval .1 \
		-state disabled \
		-resolution .001 

	$SlideRule set $CurrentFreq
	set DialFreq $CurrentFreq

	update

	return
}

###################################################################
# This proc is not used currently.
###################################################################
proc TuneBySlideRule {f} \
{
	set CurrentFreq [FormatFreq $f ]
	set hz [expr {$CurrentFreq * 1000000}]
	set hz [expr {round($hz)}]
	SetFreq $hz
	set GlobalParam(PreviousFreq) $CurrentFreq

	UpdDisplay
	update
	return
}


proc DecodeAChannel {line bn ch} \
{
	global RMode
	global RTs

	if { [string length $line] == 0 } \
		{
		# Empty channel
		set lst [list 0 am empty 0]
		return $lst
		}

	# Extract frequency digit pairs. They are BCD in reversed order.
	set f [BCD2Freq $line 5]

	set alabel [string range $line 17 25]

	set mode [string range $line 10 11]
	binary scan $mode "H*" mode
	set mode [string trimleft $mode 0]


	if {[info exists RMode($mode)]} \
		{
		set amode $RMode($mode)
		} \
	else \
		{
		set amode "?"
		}

	set scn [string range $line 16 16]
	binary scan $scn "H*" scn

	# Note: the select/scan documentation in the user manual
	# appears to contain errors, with cases 01 and 02
	# being reversed.

	set skip ""
	set select ""

	if { $scn == "00" } \
		{
		set select ""
		set skip ""
		} \
	elseif { $scn == "02" } \
		{
		set select ""
		set skip "skip"
		} \
	elseif { $scn == "01" } \
		{
		set select "select"
		set skip ""
		} \
	elseif { $scn == "03" } \
		{
		set select "select"
		set skip "skip"
		}

	set ts [string range $line 12 12]
	binary scan $ts "H*" ts

	regsub {^0} $ts "" ts
	
	if {[info exists RTs($ts)]} \
		{
		set ats $RTs($ts)
		set ats [expr {$ats / 1000.0}]
		} \
	elseif {$ts == 13} \
		{
		# Custom tuning step.

		set f2 [string index $line 13 ]
		binary scan $f2 "H*" f2

		set f1 [string index $line 14 ]
		binary scan $f1 "H*" f1

		set fcust [format "%s%s" $f1 $f2]
		set fcust [string trimleft $fcust 0]
		set fcust [expr {$fcust / 10.0}]
		set ats [format "%.1f" $fcust]
		# puts stderr "NOTE: custom tuning step is $ats"
		} \
	else \
		{
		puts stderr "DecodeAChannel: WARNING: ts tuning step is $ts"
		set ats ?
		}

	set atten [string range $line 15 15]
	binary scan $atten "H*" atten
	regsub {^0} $atten "" atten



	# puts stderr [format "%s %s %s %s" $f $alabel $amode $scn]
	set lst [list $f $ats $amode $alabel $skip $select $atten]
	return $lst
}

###################################################################
# Decode a BCD frequency.
#
# Returns:	frequency in MHz
###################################################################

proc BCD2Freq { line start } \
{
	# Frequency digit pairs are reversed.

	set i $start

	set f5 [string index $line $i]
	binary scan $f5 "H*" f5
	incr i

	set f4 [string index $line $i]
	binary scan $f4 "H*" f4
	incr i

	set f3 [string index $line $i]
	binary scan $f3 "H*" f3
	incr i

	set f2 [string index $line $i]
	binary scan $f2 "H*" f2
	incr i

	set f1 [string index $line $i]
	binary scan $f1 "H*" f1
	incr i

	set f [format "%s%s%s%s%s" $f1 $f2 $f3 $f4 $f5]
	set f [string trimleft $f 0]

	if { $f == ""} \
		{
		set f 0.0
		}

	set f [expr {$f/1000000.0}]
	return $f
}

###################################################################
# Encode frequency into BCD format.
#
# Inputs:	frequency in Hz
# Returns:	frequency in BCD format with digit bytes reversed.
###################################################################

proc Freq2BCD { f } \
{
	# Convert frequency to a 10 digit integer in Hz.

	set f [expr {int($f)}]
	set f [ PadLeft0 10 $f ]

	# Frequency digit pairs are reversed.

	set bf ""

#	puts stderr "from Freq2BCD, f = $f"

	set dpair [string range $f 8 9]
	set bf [ append bf [binary format "H2" $dpair] ]

	set dpair [string range $f 6 7]
	set bf [ append bf [binary format "H2" $dpair] ]

	set dpair [string range $f 4 5]
	set bf [ append bf [binary format "H2" $dpair] ]

	set dpair [string range $f 2 3]
	set bf [ append bf [binary format "H2" $dpair] ]

	set dpair [string range $f 0 1]
	set bf [ append bf [binary format "H2" $dpair] ]

	return $bf
}

###################################################################
# Given a bank number and channel number, return a unique
# key for this combination.
###################################################################
proc Chb2Key {bn ch} \
{
	global VNChanPerBank

	if {$bn == ""} \
		{
		set bn 0
		}

	if {$ch == ""} \
		{
		set ch 0
		}

	set key [expr { ($bn * $VNChanPerBank) + $ch } ]

#	puts stderr "Chb2Key: bn: $bn, ch: $ch, key: $key"
	return $key
}


###################################################################
# Given a unique key, return bank number and channel number
# for this combination.
###################################################################
proc Key2Chb {key} \
{
	global VNChanPerBank

	if {$key == ""} \
		{
		set bn 0
		set ch 0
		} \
	else \
		{
		set bn [expr {$key / $VNChanPerBank}]
		set bn [expr {int($bn)} ]

		set ch [expr {fmod($key,$VNChanPerBank)}]
		set ch [expr {int($ch)}]
		}

#	puts stderr "Key2Chb: key= $key, bn: $bn, ch $ch"
	set lst [list $bn $ch]

	return $lst
}

###################################################################
# Encode memory channel parameters into a single binary string.
#
# Notes:
#	mode argument must be alphabetic, e.g, FM
###################################################################
proc EncodeAChannel { bn ch mhz mode step atten sk sel label } \
{
	global Mode

	set ich [ PadLeft0 4 $ch ]

	set bank [ PadLeft0 2 $bn ]

	set freq [ expr 1000000 * $mhz ]
	set freq [ expr round($freq) ]
	set bcdfreq [ Freq2BCD $freq ]


	# Get numeric mode and pad it with zeroes.
	set mode $Mode($mode)
	set mode [ PadLeft0 4 $mode ]

	set ts [EncodeTS $step]

	set atten [PadLeft0 2 $atten]


	# Note: the IC-R8500 user manual is incorrect in
	# its description of the following encoding.

	if     { ($sel == "") && ($sk == "") } {set scn 0} \
	elseif { ($sel != "") && ($sk == "") } {set scn 1} \
	elseif { ($sel == "") && ($sk != "") } {set scn 2} \
	elseif { ($sel != "") && ($sk != "") } {set scn 3}

	set scn [ PadLeft0 2 $scn ]

	set label [string range $label 0 7]
	set label [format "%-8s" $label]

	binary scan $ts "H*" xts
	set xs [format "%s %s %s %s %s %s %s %s" \
		$bank $ich $freq $mode $xts $atten $scn $label]

	# puts stderr "\nMemories2Radio: $xs"

	set s ""
	set s [ append s [binary format "H2" $bank]]
	set s [ append s [binary format "H4" $ich]]
	set s [ append s $bcdfreq]
	set s [ append s [binary format "H4" $mode]]
	set s [ append s $ts]
	set s [ append s [binary format "H2" $atten]]
	set s [ append s [binary format "H2" $scn]]
	set s [ append s $label]

	return $s
}

proc BlankSlideRuleDial {} \
{
	global SlideRule

	$SlideRule configure \
		-state disabled \
		-activebackground black \
		-foreground black \
		-troughcolor black
}

proc RestoreSlideRuleDial {} \
{
	global SlideRule

	$SlideRule configure \
		-state disabled \
		-activebackground red \
		-foreground white \
		-troughcolor white
}

###################################################################
# Setup before scanning
###################################################################
proc PreScan {} \
{
	global BankLabel
	global ChanLabel
	global BlinkToggle
	global GlobalParam

	set BlinkToggle 1	
	set GlobalParam(ScanFlag) 1	
	$ChanLabel configure -text $GlobalParam(ScanType)
	SetBank $GlobalParam(Bank)

	set ty $GlobalParam(ScanType)
	if { ($ty != "Limit Scan") && ($ty != "Auto Write Scan") } \
		{
		# Update the bank label display.
		set tmp [FormatBank $GlobalParam(Bank)]
		$BankLabel configure -text $tmp
		HighlightBank $GlobalParam(Bank)
		}

	set GlobalParam(Attenuator) 0
	return
}

###################################################################
# Read the names of all banks and store them in an array.
###################################################################
proc ReadAllBankNames { } \
{
	global GlobalParam

	for {set i 0} {$i < 20} {incr i} \
		{
		set GlobalParam(BankName$i) [ReadBankName $i]
		# puts stderr "Bank Name: $i $BankName($i)"
		}
	set GlobalParam(BankName20) FREE
	set GlobalParam(BankName21) AUTO
	set GlobalParam(BankName22) SKIP
	set GlobalParam(BankName23) LIMIT
	set GlobalParam(BankName24) PRIO
	return
}

###################################################################
# Add a frequency and label to a global cache.
###################################################################
proc Add2LabelCache { f label comment } \
{
	global Note
	global Label

	# puts stderr "from Add2LabelCache, f= $f"

	set f [string trimleft $f " "]

	if { ($label != "") && ($f != "") && ($f > 0) } \
		{
		set f [format "%.5f" $f]
		set Label($f) [format "%s" $label ]
		set Note($f) [format "%s" $comment]
		}
	return
}

###################################################################
# Append a line in csv format to the log file.
#
# Note:
#	The current value of the S-meter will be used,
#	so be sure to read the S-meter from the radio
#	while on the current frequency before calling this
#	procedure.
###################################################################

proc LogTransmission { } \
{
	global CurrentFreq
	global GlobalParam
	global Label
	global Lid
	global Lfilename
	global RMode

	# puts stderr "LogTransmission: entered"

	if { $Lfilename == "" } {return}


	set f [string trimleft $CurrentFreq " "]
	if { [info exists Label($f)] } \
		{
		set label $Label($f)
		} \
	else \
		{
		set label ""
		}

	set seconds [clock seconds]
	set time [clock format $seconds -format {%T}]
	set date [clock format $seconds -format {%Y/%m/%d}]

	regsub -all " " $label "_" label

	# Scale the signal strength reading from 0 - 256
	# to 0 - 10.

	set smeter [expr { $GlobalParam(Smeter) / 25.6 } ]

	set s [format "%s,%s,%s,%s,%.2f,\"%s\"" \
		$date $time $f \
		$GlobalParam(Mode) $smeter $label]

	if { [catch {puts $Lid $s}] } \
		{
		bell
		tk_dialog .logfilerror "Log file error" \
			"Cannot write to log file." error 0 OK
		} \
	else \
		{
		catch {flush $Lid}
		}
	return
}


###################################################################
#
# Create one bank selection button widget for bank 'bn'
# named 'w'.
#
###################################################################
proc MkBankSw { w bn } \
{
	global GlobalParam
	global BankEntLabel

	frame $w

	set s [format "%2d. %s" $bn $GlobalParam(BankName$bn)]

	checkbutton $w.but -text $bn \
		-variable GlobalParam(ScanBank$bn) \
		-onvalue "on" \
		-offvalue "off"

	entry $w.ent -width 7 -textvariable GlobalParam(BankName$bn) \
		-background white 

	set BankEntLabel($bn) $w.ent

	pack $w.but $w.ent -side left
	return
}

###################################################################
#
# Make the specified bank widget green and all the others white.
#
###################################################################
proc HighlightBank { bn } \
{
	global BankEntLabel

	for {set i 0} {$i < 20} {incr i} \
		{
		if {$i == $bn } \
			{
			$BankEntLabel($i)  configure \
				-background green
			} \
		else \
			{
			$BankEntLabel($i)  configure \
				-background white
			}
		}
	return
}


###################################################################
# Create a checkbutton widget for all banks.
###################################################################
proc MkAllBankSw { f } \
{
	global GlobalParam

	frame $f -relief flat -borderwidth 3
	set l [frame $f.l -relief flat -borderwidth 3]
	set r [frame $f.r -relief flat -borderwidth 3]

	for {set bn 0} {$bn < 10} {incr bn} \
		{
		MkBankSw $l.$bn $bn
		pack $l.$bn  -side top -anchor w
		}

	for {set bn 10} {$bn < 20} {incr bn} \
		{
		MkBankSw $r.$bn $bn
		pack $r.$bn  -side top -anchor w
		}


	pack $l $r -side left -anchor w

	return $f
}


###################################################################
# Create a Mode pulldown menu 
# and radiobutton widgets for all reception modes.
#
# The text displayed on the menu button will be changed
# as the mode changes to it reflects the current reception mode.
#
# Inputs:
#	f	-name of frame to create
#	lw	-width of frame to create
###################################################################
proc MkModeSwitch { f lw } \
{
	global Mode;
	global ModeLabel;
	global RMode;

	frame $f -relief flat -borderwidth 0

	set ModeLabel $f.modes
	menubutton $f.modes -text "MODE" -width $lw -menu $f.modes.m \
		-background black -foreground orange
	menu $f.modes.m

	foreach mode {AMN AM AMW USB LSB CW CWN FMN FM FMW} \
		{
		$f.modes.m add radiobutton \
			-label $mode \
			-variable GlobalParam(Mode) \
			-value $mode -command { ChangeMode }
		}

	pack $f.modes


	# Update the mode widget with the radio's mode.

	set m [ReadMode]
	set GlobalParam(Mode) $RMode($m)
	$ModeLabel configure -text $GlobalParam(Mode)

	return $f
}

###################################################################
# Read programed scan (search) limit pairs from bank 23
#
# Notes:
#	Even channels are lower limit.
#	Odd channels are upper limit.
###################################################################
proc ReadLimits { } \
{
	global GlobalParam
	global LimitScan

	set bn 23
	# For each memory channel in a bank.
	for {set ch 0} {$ch < 20} {incr ch} \
		{
		set lst [ReadAChannel $bn $ch]
		set status [lindex $lst 0]
		set line [lindex $lst 1]

		# Check for empty channel.
		# Check for invalid channel.

		if { ($status == "invalid")
			|| ($status == "empty")} \
			{
			continue
			}

		set memorydata [DecodeAChannel \
			$line $bn $ch ]

		set f [lindex $memorydata 0]
		set ts [lindex $memorydata 1]
		set mode [lindex $memorydata 2]
		set lab [lindex $memorydata 3]
		set skip [lindex $memorydata 4]
		set select [lindex $memorydata 5]
		set atten [lindex $memorydata 6]

		if { $f == 0 } {continue}

		set lab [string trimright $lab " "]
		set lab [string trimleft $lab " "]
		if {[string length $lab] > 0} \
			{
			set lab [format "\"%s\"" $lab]
			}
		if {$atten == 0} {set atten ""}
		set s [format "%d,%d,%.5f,%s,%s,%s,%s,%s,%s" \
			$bn $ch $f $ts \
			$mode \
			$skip $select $atten $lab]

		# puts stderr $s

		set j [expr {$ch / 2}]
		set j [expr {floor($j)}]
		set j [expr {int($j)}]
		set j2 [expr {$j + $j}]

		if {$j2 == $ch} \
			{
			# Even channel, must be lower limit.
			set lu Lower
			} \
		else \
			{
			# Odd channel, must be upper limit.
			set lu Upper
			}
		regsub -all "\"" $lab "" lab

		eval {set LimitScan($j,$lu) $f}
		eval {set LimitScan($j,Mode) $mode}
		eval {set LimitScan($j,Step) $ts}
		eval {set LimitScan($j,Label) $lab}
		}

	return

}

###################################################################
# Make pulldown menu of search ranges
###################################################################
proc MakeLimitMenu { f } \
{	
	global LimitScan

	frame $f -relief raised -borderwidth 2

	menubutton $f.limits -text "Choose Limits ..." \
		-menu $f.limits.m 
	menu $f.limits.m

	for {set i 1} {$i < 10} {incr i} \
		{
		set lab [format "%2d. %11.5f - %9.4f %3s %5.1f %s" \
			$i $LimitScan($i,Lower) $LimitScan($i,Upper) \
			$LimitScan($i,Mode) $LimitScan($i,Step) \
			$LimitScan($i,Label) ]
		
		$f.limits.m add radiobutton \
			-label $lab \
			-variable LimitScan(Pair) \
			-value $i -command \
				{
				CopyLimits $LimitScan(Pair)
				}
		}

	$f.limits.m add radiobutton \
		-label "Other" \
		-variable LimitScan(Pair) \
		-value other -command { }

	pack $f.limits

	return $f
}


###################################################################
# Make pulldown menu for mode scan
#
# Cannot start a mode scan if we are already scanning apparently.
# (But it would work ok using the radio front panel.)
###################################################################
proc MakeModeScanMenu { f } \
{	
	global GlobalParam
	global ModeLabel
	global ModeScanLabel

	frame $f -relief raised -borderwidth 2

	set ModeScanLabel $f.modescan

	menubutton $f.modescan -text "Mode Scan ..." \
		-menu $f.modescan.m 
	menu $f.modescan.m

	foreach mode { off AM USB LSB CW CWN FM FMW } \
		{

		$f.modescan.m add radiobutton \
			-label $mode \
			-variable GlobalParam(ModeScan) \
			-value $mode -command \
				{
				ModeScanCB
				}
		}

	pack $f.modescan -side top -fill x -expand y
	return $f
}

###################################################################
# Mode Scan Callback
###################################################################
proc ModeScanCB {} \
{
	global ChanLabel
	global GlobalParam
	global ModeLabel
	global ModeScanLabel

	if { ($GlobalParam(ModeScan) != "off")
		&& ( ($GlobalParam(ScanFlag) == 0) \
		|| ($GlobalParam(ScanType) == "Limit Scan") \
		|| ($GlobalParam(ScanType) == "Auto Write Scan") ) } \
		{
		# We are not scanning so do not honor user request.
		DisableModeScan

		set msg "The IC-R8500 must be scanning "
		set msg [append msg "in Memory Scan or "]
		set msg [append msg "Select Scan before choosing "]
		set msg [append msg "a Memory Scan mode. "]

		tk_dialog .noscan "Mode Scan info" \
			$msg info 0 OK
		return
		} 

	if {$GlobalParam(ModeScan) != "off"} \
		{
		set GlobalParam(Mode) \
			$GlobalParam(ModeScan)
		SetMode
		set GlobalParam(ScanFlag) 1
		$ModeLabel configure \
			-text $GlobalParam(Mode)

		if { [StartModeScan] } \
			{
			# Cannot start mode scan.
			set bn $GlobalParam(Bank)

			# The radio responded with an error.
			# Cannot do Mode Scan in this
			# bank probably because there are not enough
			# memory channels in this mode with the
			# designated mode.
			# Therefore, we will ruthlessly
			# deselect this memory bank so we won't
			# bother to try scanning it.

			set GlobalParam(ScanBank$bn) off

			}
		$ModeScanLabel configure -foreground red
		} \
	else \
		{
		# User turned off mode scan.
		$ChanLabel configure -text "VFO"
		DisableModeScan
		}

	$ModeLabel configure \
		-text $GlobalParam(Mode)

	return
}

###################################################################
# Copy frequency limits and step into entry widgets.
###################################################################

proc CopyLimits { i } \
{
	global BankLabel
	global ChanLabel
	global CurrentFreq
	global GlobalParam
	global LimitScan
	global LowerFreq
	global Mode
	global UpperFreq
	global StepFreq

	if {$GlobalParam(ScanFlag)} \
		{
		# We are currently scanning so stop.
		StopScan
		$ChanLabel configure -text "VFO"
		set GlobalParam(ScanFlag) 0
		DisableModeScan
		}

	set LowerFreq $LimitScan($i,Lower)
	set UpperFreq $LimitScan($i,Upper)
	set StepFreq $LimitScan($i,Step)
	set mode $LimitScan($i,Mode)

	set GlobalParam(LowerLimit) $LowerFreq
	set GlobalParam(UpperLimit) $UpperFreq
	set GlobalParam(SearchStep) $StepFreq
	set GlobalParam(Mode) $mode

	# Update the bank label display.
	$BankLabel configure -text $LimitScan($i,Label)
	HighlightBank -1

	set CurrentFreq [FormatFreq $LowerFreq ]
	set hz [expr {$CurrentFreq * 1000000}]
	set hz [expr {round($hz)}]
	SetFreq $hz
	SetSlideRuleDial
	ChangeMode

	return
}

###################################################################
# Disable Mode Scan within the software,
# though no commands are actually sent to the radio.
###################################################################

proc DisableModeScan { } \
{
	global GlobalParam
	global ModeScanLabel

	set GlobalParam(ModeScan) off
	$ModeScanLabel configure -foreground black

	return
}



###################################################################
# 
# Define receiver parameters before we read the
# global parameter configuration file in case they are missing
# from the configuration file.
# This avoids a tcl error if we tried to refer to an
# undefined variable.
#
# These initial definitions will be overridden with
# definitions from the configuration file.
#
###################################################################

proc PresetGlobals { } \
{
	global GlobalParam
	global Mode
	global Rcfile
	global RootDir
	global tcl_platform

	set GlobalParam(AGC) slow
	set GlobalParam(APFadj) 130
	set GlobalParam(APF) off
	set GlobalParam(Attenuator) 0
	set GlobalParam(BalloonHelpWindows) on
	set GlobalParam(Bank) 0

	for {set bn 0} {$bn < 20} {incr bn} \
		{
		set GlobalParam(ScanBank$bn) off
		}
	set GlobalParam(ScanBank0) on

	set GlobalParam(BackGroundColor) ""
	set GlobalParam(BClevel) 128
	set GlobalParam(BPFenable) on
	set GlobalParam(Debug) 0
	set GlobalParam(DisplayUpdateInterval) 500
	set GlobalParam(Font) ""
	set GlobalParam(ForeGroundColor) ""
	set GlobalParam(FreqNotesFont) ""
	set GlobalParam(HighestChannel) 99
	set GlobalParam(HighestFrequency) 2000.0
	set GlobalParam(LastHit) 0
	set GlobalParam(LogFileDir) $RootDir
	set GlobalParam(LowerLimit) 0
	set GlobalParam(MemoryFileDir) $RootDir
	set GlobalParam(Mode) $Mode(AM)
	set GlobalParam(NB) off
	set GlobalParam(NRlevel) 50
	set GlobalParam(PassBandShift) 0
	set GlobalParam(PreviousFreq) 10
	set GlobalParam(Resume) delay
	set GlobalParam(ScanFlag) 0
	set GlobalParam(ScanType) {}
	set GlobalParam(SearchStep) 1
	set GlobalParam(SortBank) 0
	set GlobalParam(SortType) label
	set GlobalParam(DockSliders) off
	set GlobalParam(Slewing) 0
	set GlobalParam(SlewSpeed) 500
	set GlobalParam(Smeter) 0
	set GlobalParam(Squelch) 0
	set GlobalParam(TroughColor) ""
	set GlobalParam(UpperLimit) 0
	set GlobalParam(ViewNote) on
	set GlobalParam(ViewHistory) off
	set GlobalParam(ViewSlewButtons) on
	set GlobalParam(ViewSlideRule) on
	set GlobalParam(ViewUpDownButtons) on
	set GlobalParam(VSC) off
	set GlobalParam(Volume1) 50
	set GlobalParam(Volume2) 50

	return
}


###################################################################
# Set global variables after reading the global
# configuration file so these settings override
# whatever values were in the configuration file.
###################################################################

proc OverrideGlobals { } \
{
	global env
	global GlobalParam
	global RootDir
	global tcl_platform


	set GlobalParam(AutoLogging) off
	set GlobalParam(Ifilename) {}
	set GlobalParam(LastHit) ""
	set GlobalParam(ScanFlag) 0
	set GlobalParam(ModeScan) off
	set GlobalParam(Populated) 0
	set GlobalParam(PriorityScan) 0
	set GlobalParam(VolumeWhich) 0
	set GlobalParam(VolumeCurrent) -1

	# Note on MacOS X:
	# The initial directory passed to the file chooser widget.
	# The problem here is that osx's tcl is utterly busted.
	# The _only_ pathname it accepts is ':' - no other ones work.
	# Now this isn't as bad as you might think because
	# the native macos file selector widget persistantly
	# remembers the last place you opened/saved a file
	# for a particular application. So the logic to
	# remember this is simply redundant on macos anyway...
	# Presumably they'll fix this someday and we can take
	# out the hack.
	# - Ben Mesander

	if { [regexp "Darwin" $tcl_platform(os) ] } \
		{
		# kluge for MacOS X.

		set GlobalParam(LogFileDir) $RootDir
		set GlobalParam(MemoryFileDir) $RootDir

		if {$GlobalParam(Ifilename) != ""} \
			{
			set GlobalParam(Ifilename) $RootDir
			}
		}

	return
}

proc FormatChannelList { } \
{
	global Chvector
	global GlobalParam

	global MemAtten
	global MemFreq
	global MemNote
	global MemLabel
	global MemMode
	global MemPopulated
	global MemSelect
	global MemSkip
	global MemStep
	global MemVol

	global NBanks
	global VNChanPerBank

	set Chvector ""

	set prevbn -1
	# for {set bn 0} {$bn < $NBanks} {incr bn}
	for {set bn 0} {$bn < 25} {incr bn} \
		{
		for {set ch 0} {$ch < $VNChanPerBank} {incr ch} \
			{

			if {$bn != $prevbn} \
				{
				set s [format "----- BANK: %2s %s" \
					$bn $GlobalParam(BankName$bn)]
				append s "-------------------"
				append s "--------------------"
				lappend Chvector $s
				set prevbn $bn
				}
	
			set key [Chb2Key $bn $ch]

			if { [info exists MemPopulated($key)] == 0 } \
				{
				continue
				}

			if { $MemPopulated($key) == "1"} \
				{
				# puts stderr "FormatChannelList: key: $key, bn: $bn, ch: $ch, Freq: $MemFreq($key), Note: $MemNote($key)"
				set s [format "%2d %3d %10.5f %5.1f %-3s %-8s %-2s %-3s %2s %-4s %s" \
					$bn $ch $MemFreq($key) \
					$MemStep($key) \
					$MemMode($key) \
					$MemLabel($key) \
					[string range $MemSkip($key) 0 1] \
					[string range $MemSelect($key) 0 2] \
					$MemAtten($key) \
					$MemVol($key) \
					$MemNote($key) \
					]
				lappend Chvector $s
				}
			}
		}
	return
}


######################################################################
#					Bob Parnass
#					DATE:
#
# USAGE:	SortaBank first last
#
# INPUTS:
#		first	-starting channel to sort
#		last	-ending channel to sort
#
# RETURNS:
#		0	-ok
#		-1	-error
#
#
# PURPOSE:	Sort a range of memory channels based on frequency.
#
# DESCRIPTION:
#
######################################################################
proc SortaBank { first last } \
{
	global GlobalParam

	global MemNote
	global MemVol
	global MemFreq
	global MemAtten
	global MemLabel
	global MemMode
	global MemNote
	global MemPopulated
	global MemSelect
	global MemSkip
	global MemStep


	if {$GlobalParam(Populated) == 0} \
		{
		set msg "You must open a memory channel file\n"
		append msg " before sorting channels.\n"

		tk_dialog .belch "tk8500" \
			$msg info 0 OK
		return -1
		}

	if {$GlobalParam(SortType) == "freq"} \
		{
		set inlist [Bank2List MemFreq $first $last]
		set vorder [SortFreqList $inlist]
		} \
	else \
		{
		set inlist [Bank2List MemLabel $first $last]
		set vorder [SortLabelList $inlist]
		}


	set inlist [Bank2List MemFreq $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemFreq($i) [lindex $slist $j]
		}

	set inlist [Bank2List MemMode $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemMode($i) [lindex $slist $j]
		if {$MemMode($i) == ""} \
			{
			set MemMode($i) NFM
			}
		}

	set inlist [Bank2List MemLabel $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemLabel($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemAtten $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemAtten($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemPopulated $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemPopulated($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemSelect $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemSelect($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemSkip $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemSkip($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemStep $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemStep($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemVol $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemVol($i) [lindex $slist $j]
		}


	set inlist [Bank2List MemNote $first $last]
	set slist [ReorderList $inlist $vorder]
	for {set i $first; set j 0} {$i <= $last} {incr i; incr j} \
		{
		set MemNote($i) [lindex $slist $j]
		}

	return 0
}


##########################################################
# Write data to csv file.
##########################################################
proc SaveTemplate { f asflag } \
{
	global FileTypes
	global MemNote
	global MemVol
	global MemFreq
	global GlobalParam
	global MemAtten
	global MemLabel
	global MemMode
	global MemNote
	global MemPopulated
	global MemSelect
	global MemSkip
	global MemStep

	global NBanks
	global NChanPerBank



	if {$GlobalParam(Populated) == 0} \
		{
		set msg "You must first open a file or read from"
		append msg " the radio before saving it in a"
		append msg " file."
		append msg " (Use the Radio menu for reading"
		append msg " from the radio.)"

		tk_dialog .error "No template data" \
			$msg error 0 OK
		return
		}


	set filename $GlobalParam(Ifilename)

	if { ($GlobalParam(Ifilename) == "") \
		|| ($asflag) } \
		{
		set filename \
			[Mytk_getSaveFile $f \
			$GlobalParam(MemoryFileDir) \
			.csv \
			"Save memory channel data to file" \
			$FileTypes]
		}



	if { $filename != "" }\
		{


		set GlobalParam(Ifilename) $filename
		SetWinTitle

		set GlobalParam(MemoryFileDir) \
			[ Dirname $GlobalParam(Ifilename) ]

		set fid [open $GlobalParam(Ifilename) "w"]
		# puts -nonewline $fid $Mimage

		puts $fid "Bank,Ch,MHz,Step,Mode,Skip,Select,Atten,Volume,Label"

		for {set bn 0} {$bn < 24} {incr bn} \
			{
			for {set ch 0} {$ch < $NChanPerBank} {incr ch} \
				{
				set key [Chb2Key $bn $ch]
				if {[info exists MemPopulated($key)] \
					== 0} \
					{
					continue
					}
				if {$MemPopulated($key) != 1} \
					{
					continue
					}
				set s ""
				append s "$bn,"
				append s "$ch,"
				append s "$MemFreq($key),"
				append s "$MemStep($key),"
				append s "$MemMode($key),"
				append s "$MemSkip($key),"
				append s "$MemSelect($key),"
				append s "$MemAtten($key),"
				append s "$MemVol($key),"

				if {$MemLabel($key) != ""} \
					{
					append s "\"$MemLabel($key)\","
					} \
				else \
					{
					append s ","
					}

				if {$MemNote($key) != ""} \
					{
					append s "\"$MemNote($key)\""
					}


				puts $fid $s
				}
			}

		close $fid
		set TemplateSavedFlag yes
		}

	return
}


###################################################################
# Set title of the main window so it contains the
# current template file name.
###################################################################
proc SetWinTitle { } \
{
	global GlobalParam

	if { ( [info exists GlobalParam(Ifilename)] == 0 ) \
		|| ($GlobalParam(Ifilename) == "") } \
		{
		set filename untitled.csv
		} \
	else \
		{
		set filename $GlobalParam(Ifilename)
		}

	set s [format "%s - tk8500" $filename]
	wm title . $s

	return
}

proc ClearAllChannels { } \
{
	global Cht
	global NChanPerBank
	global MemFreq
	global MemPopulated

	for {set bn 0} {$bn < 25} {incr bn} \
		{
		for {set ch 0} {$ch < $NChanPerBank} {incr ch} \
			{
			set key [Chb2Key $bn $ch]
			set MemPopulated($key) 0
			set MemFreq($key) 0
			}
		}

	ShowChannels $Cht
	return
}
