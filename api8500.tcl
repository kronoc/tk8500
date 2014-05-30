###################################################################
# This file is part of tk8500, a control program for the
# ICOM IC-R8500 receiver.
# 
#    Copyright (C) 2001 - 2003, Bob Parnass
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

set NBanks		20
set NChanPerBank	100
set VNChanPerBank	100
set ChanNumberRepeat	yes
set HasLabels		yes

set Mode(CW) "301"
set Mode(CWN) "302"
set Mode(USB) "101"
set Mode(LSB) "1"
set Mode(AM) "202"
set Mode(AMN) "203"
set Mode(AMW) "201"
set Mode(FMN) "502"
set Mode(FM) "501"
set Mode(FMW) "601"

set RMode(301) CW
set RMode(302) CWN
set RMode(101) USB
set RMode(1)   LSB
set RMode(203) AMN
set RMode(201) AMW
set RMode(202) AM
set RMode(501) FM
set RMode(502) FMN
set RMode(601) FMW

# Tuning step in Hz
set RTs(0) 10
set RTs(1) 50
set RTs(2) 100
set RTs(3) 1000
set RTs(4) 2500
set RTs(5) 5000
set RTs(6) 9000
set RTs(7) 10000
set RTs(8) 12500
set RTs(9) 20000
set RTs(10) 25000
set RTs(11) 100000
set RTs(12) 1000000

set Bw(narr) "2"
set Bw(inter) "1"
set Bw(wide) "0"

set RBw(2) narr
set RBw(1) inter
set RBw(0) wide

set Sunits2Db(1) 1
set Sunits2Db(2) 3
set Sunits2Db(3) 5
set Sunits2Db(4) 7
set Sunits2Db(5) 9
set Sunits2Db(7) {+25}
set Sunits2Db(8) {+40}
set Sunits2Db(9) {+55}

# Tuning step sizes
set Tstep(1) V0
set Tstep(10) V1
set Tstep(100) V2
set Tstep(1000) V3
set Tstep(10000) V4
set Tstep(100000) V5

##########################################################
# Open the serial port.
# Notes:
#	This procedure sets the global variable Sid.
#
# Returns:
#	"" -ok
#	else -error message
##########################################################

proc OpenDevice {} \
{
	global Pgm
	global GlobalParam
	global Sid
	global tcl_platform


	 set platform $tcl_platform(platform) 
	 switch -glob $platform \
		{
		{unix} \
			{
			set Sid [open $GlobalParam(Device) "r+"]
			}
		{macintosh} \
			{
			set Sid [open $GlobalParam(Device) "r+"]
			}
		{windows} \
			{
			set Sid [open $GlobalParam(Device) RDWR]
			}
		default \
			{
			set msg "$Pgm error: Platform $platform not supported."
			Tattle $msg
			return $msg
			}
		}


	# Set up the serial port parameters (similar to stty)
	if [catch {fconfigure $Sid \
		-buffering full \
		-translation binary \
		-mode 19200,n,8,1 -blocking 1}] \
		{
		set msg "$Pgm error: "
		set msg [append msg "Cannot configure serial port\n"]
		set msg [append msg "$GlobalParam(Device)"]
		Tattle $msg
		return $msg
		}
	return "" 
}
##########################################################
#
# Initialize a few global variables.
#
# Return the pathname to a configuration file in the user's
# HOME directory
#
# Returns:
#	list of 2 elements:
#		-name of configuration file
#		-name of label file
#
##########################################################
proc InitStuff { } \
{
	global argv0
	global DisplayFontSize
	global env
	global Home
	global Pgm
	global RootDir
	global tcl_platform


	set platform $tcl_platform(platform) 
	switch -glob $platform \
		{
		{unix} \
			{
			set Home $env(HOME)
			set rcfile [format "%s/.tk8500rc" $Home]
			set labelfile [format "%s/.tk8500la" $Home]

			set DisplayFontSize "Courier 56 bold"
			}
		{macintosh} \
			{

			# Configuration file should be
			# named $HOME/.tk8500rc

			# Use forward slashes within Tcl/Tk
			# instead of colons.

			set Home $env(HOME)
			regsub -all {:} $Home "/" Home
			set rcfile [format "%s/.tk8500rc" $Home]
			set labelfile [format "%s/.tk8500la" $Home]

			# The following font line may need changing.
			set DisplayFontSize "Courier 56 bold"
			}
		{windows} \
			{

			# Configuration file should be
			# named $tk8500/tk8500.ini
			# Use forward slashes within Tcl/Tk
			# instead of backslashes.

			set Home $env(tk8500)
			regsub -all {\\} $Home "/" Home
			set rcfile [format "%s/tk8500.ini" $Home]
			set labelfile [format "%s/tk8500.lab" $Home]

			set DisplayFontSize "Courier 28 bold"
			}
		default \
			{
			puts "Operating System $platform not supported."
			exit 1
			}
		}
	set Home $env(HOME)
	# set Pgm [string last "/" $argv0]


	set lst [list $rcfile $labelfile]
	return $lst
}

###################################################################
# Disable computer control of radio.
###################################################################
proc DisableCControl { } \
{
	global Sid

	after 500

	close $Sid
	return
}

###################################################################
# Return the preamble for messages sent from computer to radio.
###################################################################
proc MsgPreamble { } \
{
	# byte 0 = FE
	# byte 1 = FE
	# byte 2 = 4A (radio's unique address)
	# byte 3 = e0 (computer's address)

	set preamble [ binary format "H2H2H2H2" fe fe 4a e0]

	return $preamble
}


###################################################################
# Set memory channel.
#	Inputs:
#		ch	-channel
###################################################################
proc SetChannel { ch } \
{
	global Sid

	set bch [Ch2BCD $ch]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 08 ]]
	set cmd [ append cmd [binary format "H*" $bch ]]

	SendCmd $Sid $cmd

	return
}


###################################################################
# Set memory bank.
#	Inputs:
#		bn	-bank
###################################################################
proc SetBank { bn } \
{

	global Sid

	set bn [ PadLeft0 2 $bn ]

	set cmd [ append cmd [binary format "H2" 08 ]]
	set cmd [ append cmd [binary format "H2" A0 ]]
	set cmd [ append cmd [binary format "H2" $bn]]

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0


	return
}



###################################################################
# Set squelch.
#	Inputs:
#		val	- 0 to 255
###################################################################
proc SetSquelch { val } \
{

	global Sid

	set bval [Ch2BCD $val]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 14 ]]
	set cmd [ append cmd [binary format "H2" 03 ]]
	set cmd [ append cmd [binary format "H4" $bval ]]

	SendCmd $Sid $cmd


	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}

###################################################################
# Set AF gain (volume).
#	Inputs:
#		val	- 0 to 255
###################################################################
proc SetAF { val } \
{
	global GlobalParam
	global Sid

	set bval [Ch2BCD $val]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 14 ]]
	set cmd [ append cmd [binary format "H2" 01 ]]
	set cmd [ append cmd [binary format "H4" $bval ]]
	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	set GlobalParam(VolumeCurrent) $val

	return
}


###################################################################
# Set AGC slow/fast
###################################################################
proc SetAGC { slowfast } \
{
	global Sid


	set cmd ""
	set cmd [ append cmd [binary format "H2" 16 ]]

	if { $slowfast == "fast" } \
		{
		set cmd [ append cmd [binary format "H2" 11 ]]
		} \
	else \
		{
		set cmd [ append cmd [binary format "H2" 10 ]]
		}

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# MW - Memory write
###################################################################
proc SetMW { } \
{
	global Sid


	set cmd ""
	set cmd [ append cmd [binary format "H2" 09 ]]

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# Set Audio Peak Filter off/on.
###################################################################
proc SetAPF { offon } \
{
	global Sid


	set cmd ""
	set cmd [ append cmd [binary format "H2" 16 ]]

	if { $offon == "on" } \
		{
		set cmd [ append cmd [binary format "H2" 31 ]]
		} \
	else \
		{
		set cmd [ append cmd [binary format "H2" 30 ]]
		}

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0


	return
}

###################################################################
# Adjust APF (audio peak filter) control.
#	Inputs:
#		val	- 0 to 255
###################################################################
proc AdjAPF { val } \
{
	global Sid

	set bval [Ch2BCD $val]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 14 ]]
	set cmd [ append cmd [binary format "H2" 05 ]]
	set cmd [ append cmd [binary format "H4" $bval ]]
	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}

###################################################################
# Set Pass Band Shift.
#	Inputs:
#		val	-   -1280 to 1280
###################################################################
proc SetPBS { val } \
{
	global Sid

	set val [expr {$val / 10}]
	set val [expr {$val + 128}]

	set bval [Ch2BCD $val]


	set cmd ""
	set cmd [ append cmd [binary format "H2" 14 ]]
	set cmd [ append cmd [binary format "H2" 04 ]]
	set cmd [ append cmd [binary format "H4" $bval ]]

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# Set emission mode.
###################################################################
proc SetMode { } \
{
	global Sid
	global Mode
	global GlobalParam



	# Translate alphabetic mode to numeric equivalent.
	set m $GlobalParam(Mode)
#	puts stderr "SetMode: $m"
	set m $Mode($m)

	set bm [Ch2BCD $m]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 06 ]]
	set cmd [ append cmd [binary format "H4" $bm ]]

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
#
# Send "command" to radio.
# Write command to error stream if Debug flag is set.
#
###################################################################
proc SendCmd { Sid command } \
{
	global GlobalParam


	set cmd [MsgPreamble]
	set cmd [ append cmd $command]
	set cmd [ append cmd [binary format "H2" fd]]


	if { $GlobalParam(Debug) > 0 } \
		{
		binary scan $cmd "H*" s

		# Insert a space between each pair of hex digits
		# to improve readability.

		regsub -all ".." $s { \0} s
		set msg ""
		set msg [ append msg "---> " $s]
		Tattle $msg
		}

	# Write data to serial port.

	puts -nonewline $Sid $cmd
	flush $Sid
	return
}

###################################################################
# Set frequency.
#	Inputs:
#		freq	-frequency in Hz
#
# Note:
#	Radio sends back an ack after executing this
#	command.
###################################################################
proc SetFreq { freq } \
{
	global Sid

	set f [Freq2BCD $freq]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 05 ]]
	set cmd [ append cmd $f]

	SendCmd $Sid $cmd


	# Read the ok ack.
	ReadRx 0

	return
}


###################################################################
# Set speech synthesizer.
###################################################################
proc Speak { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 13 ]]
	set cmd [ append cmd [binary format "H2" 00 ]]

	SendCmd $Sid $cmd

	# Read the ok ack.
	ReadRx 0

	return
}


###################################################################
# Start limit scan (i.e., search) 
###################################################################
proc StartLimitScan { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 02 ]]

	SendCmd $Sid $cmd

	# Read the ok ack.
	ReadRx 0

	return
}


###################################################################
# Start auto write search 
###################################################################
proc StartAutoWriteScan { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 04 ]]

	SendCmd $Sid $cmd

	# Read the ok ack.
	ReadRx 0

	return
}


###################################################################
# Start memory bank scan 
#
# Returns:
#	0	-ok
#	1	-error
###################################################################
proc StartMemoryScan { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 22 ]]

	SendCmd $Sid $cmd

	# Read the ok ack.
	ReadRx 0

	return
}


###################################################################
# Start select memory scan 
#
# Returns:
#	0	-ok
#	1	-error
###################################################################
proc StartSelectMemoryScan { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 23 ]]

	SendCmd $Sid $cmd

	# Read the ack.
	set line [ReadRx 0]

	set len [string length $line]

	if { $len == 1} \
		{
		# Examine the status byte.

		if { [string compare -nocase -length 1 $line \xfb] == 0} \
			{
			# This ack message is ok.
			set status 0
			} \
		else \
			{
			# The command failed.

			# puts stderr "StartSelectMemoryScan: FAILED"
			set status 1
			}
		}
	
	return $status
}

###################################################################
# Start mode scan 
###################################################################
proc StartModeScan { } \
{
	global Sid


	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 24 ]]



	SendCmd $Sid $cmd

	# Read the ack.
	set line [ReadRx 0]

	set len [string length $line]

	if { $len == 1} \
		{
		# Examine the status byte.

		if { [string compare -nocase -length 1 $line \xfb] == 0} \
			{
			# This ack message is ok.
			set status 0
			} \
		else \
			{
			# The command failed.

			# puts stderr "StartModeScan: FAILED"
			set status 1
			}
		}
	
	return $status
}


###################################################################
# Start priority scan 
###################################################################
proc StartPriorityScan { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 42 ]]

	SendCmd $Sid $cmd

	# Read the ack.

	set line [ReadRx 0]

	set len [string length $line]

	if { $len == 1} \
		{
		# Examine the status byte.

		if { [string compare -nocase -length 1 $line \xfb] == 0} \
			{
			# This ack message is ok.
			set status 0
			} \
		else \
			{
			# The command failed.

			# puts stderr "StartPriorityScan: FAILED"
			set status 1
			}
		}

	
	return $status
}


###################################################################
# Stop scan 
###################################################################
proc StopScan { } \
{
	StopSearch
	return
}

###################################################################
# Stop search 
###################################################################
proc StopSearch { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]
	set cmd [ append cmd [binary format "H2" 00 ]]

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# Set the rescan resume condition 
###################################################################
proc SetResume { val } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]

	if {$val == "off" } \
		{
		set cmd [ append cmd [binary format "H2" D1 ]]
		} \
	elseif {$val == "delay" } \
		{
		set cmd [ append cmd [binary format "H2" D3 ]]
		} \
	elseif {$val == "infinite" } \
		{
		set cmd [ append cmd [binary format "H2" D0 ]]
		} \
	else {return}
	

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# Set the VSC  (voice scan control)
###################################################################
proc SetVSC { offon } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 0E ]]

	if {$offon == "off" } \
		{
		set cmd [ append cmd [binary format "H2" C0 ]]
		} \
	elseif {$offon == "on" } \
		{
		set cmd [ append cmd [binary format "H2" C1 ]]
		}
	
	SendCmd $Sid $cmd


	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# Read frequency.
#
#	Inputs:
#		none
#	Returns:
#		frequency in MHz
###################################################################
proc ReadFreq { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 03 ]]


	set error 1

	while {$error} \
		{
		SendCmd $Sid $cmd

		set error 0

		while {1} \
			{

			# Read messages until we find the
			# one which matches this request.
	
			set line [ReadRx]
			set len [string length $line]
			if {$len == 0} \
				{
				# Got an error while reading.
				puts stderr "ReadFreq: read error."
				set error 1
				break
				} \
			elseif {[Check4Meter $line]} \
				{
				# Radio sent an S meter value.
				# continue
				} \
			elseif {$len == 6} \
				{
				set cn [string range $line 0 0]
				binary scan $cn "H*" cn
				if {$cn == 3} {break}
				}
			}
		}

	set f [BCD2Freq $line 1]
	set f [ format "%.5f" $f ]

	return $f
}



###################################################################
# Read mode.
#
#	Inputs:
#		none
#	Returns:
#		numeric mode
###################################################################
proc ReadMode { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 04 ]]

	set error 1

	while {$error} \
		{
		SendCmd $Sid $cmd

		set error 0

		while {1} \
			{

			# Read messages until we find the
			# one which matches this request.
	
			set line [ReadRx]
			set len [string length $line]
			if {$len == 0} \
				{
				# Got an error while reading.
				puts stderr "ReadFreq: read error."
				set error 1
				break
				} \
			elseif {[Check4Meter $line]} \
				{
				# Radio sent an S meter value.
				# continue
				} \
			elseif {$len == 3} \
				{
				set cn [string range $line 0 0]
				binary scan $cn "H*" cn
				if {$cn == 4} {break}
				}
			}
		}

	set b1 [string range $line 1 1]
	binary scan $b1 "H*" b1

	set b2 [string range $line 2 2]
	binary scan $b2 "H*" b2

	set m [ format "%s%s" $b1 $b2]
	set m [string trimleft $m 0]

	return $m
}


###################################################################
# Read bank name.  It is a 5 character string.
#
#	Inputs:
#		bank number
#	Returns:
#		bank name
###################################################################
proc ReadBankName { bn } \
{
	global Sid

	set bn [ PadLeft0 2 $bn ]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 1A ]]
	set cmd [ append cmd [binary format "H2" 03 ]]
	set cmd [ append cmd [binary format "H2" $bn ]]


	set error 1

	while {$error} \
		{
		SendCmd $Sid $cmd

		set error 0

		while {1} \
			{

			# Read messages until we find the
			# one which matches this request.
	
			set line [ReadRx]
			set len [string length $line]
			if {$len == 0} \
				{
				# Got an error while reading.
				puts stderr "ReadBankName: read error."
				set error 1
				break
				} \
			elseif {[Check4Meter $line]} \
				{
				# Radio sent an S meter value.
				continue
				} \
			elseif {$len == 8} \
				{
				set cn [string range $line 0 0]
				binary scan $cn "H*" cn
				set sc [string range $line 1 1]
				binary scan $sc "H*" sc
				if {($cn == "1a") && ($sc == 03)} \
					{
					set val [string range $line 3 7]
					break
					}
				}
			}
		}

	return $val
}


###################################################################
# Write Bank Name.
#	Inputs:
#		bn	- bank number
#		val	- 5 character alphanumeric string
###################################################################
proc WriteBankName { bn val } \
{
	global Sid

	set bn [PadLeft0 2 $bn ]

	# Truncate bank name to 5 char. and pad on right with
	# spaces.

	set val [string range $val 0 4]
	set val [format "%-5s" $val]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 1A ]]
	set cmd [ append cmd [binary format "H2" 02 ]]
	set cmd [ append cmd [binary format "H2" $bn ]]
	set cmd [ append cmd $val ]
	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}

###################################################################
# Set noise blanker off/on.
###################################################################
proc SetNB { offon } \
{
	global Sid


	set cmd ""
	set cmd [ append cmd [binary format "H2" 16 ]]

	if { $offon == "on" } \
		{
		set cmd [ append cmd [binary format "H2" 21 ]]
		} \
	else \
		{
		set cmd [ append cmd [binary format "H2" 20 ]]
		}

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0


	return
}


###################################################################
# Set tuning step size (in Hz).
#	Inputs:
#		step	- tuning step in kHz
###################################################################
proc SetTS { step } \
{
	global Sid
	global Tstep

	set val [EncodeTS $step]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 10 ]]
	set cmd [ append cmd $val ]

	SendCmd $Sid $cmd

	return
}

###################################################################
# Set attenuator
#	Inputs:
#		val	- 0, 10, 20, 30
###################################################################
proc SetAttenuator { val } \
{
	global Sid

	if {($val != 0) && ($val != 10) \
		&& ($val != 20) && ($val != 30)} \
		{
		return
		}
	
	set val [ PadLeft0 2 $val ]

	set cmd ""
	set cmd [ append cmd [binary format "H2" 11 ]]
	set cmd [ append cmd [binary format "H2" $val ]]
	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0

	return
}


###################################################################
# Convert channel number (0 - 999) to BCD.
# Return a string of bytes.
###################################################################

proc Ch2BCD { ch } \
{

	set s [PadLeft0 4 $ch ]

	return $s
}

###################################################################
# Read one memory channel.
#	Inputs:
#		bn	-bank
#		ch	-channel
#
#	Returns a message.
#
# Notes:
#	1) If you ask to read an empty channel, the radio
#	responds with a shorter packet in which the frequency
#	contains only a single byte, ff.
#
#	e.g., if you asked for bank 0, channel 0, and it was
#	empty, the radio responds:
#
#		fe fe e0 4a 1a 01 00 00 00 ff fd
###################################################################
proc ReadAChannel { bn ch } \
{
	global Sid

	set bch [Ch2BCD $ch]
	set bbn [PadLeft0 2 $bn ]


	set cmd ""
	append cmd [binary format "H2" 1A ]
	append cmd [binary format "H2" 01 ]
	append cmd [binary format "H2" $bbn ]
	append cmd [binary format "H*" $bch ]

	SendCmd $Sid $cmd

	while {1} \
		{
		# Read messages until we find the
		# one which matches this request.

		set line [ReadRx]

		if {[Check4Meter $line]} \
			{
			# Radio sent an S meter value.
			continue
			}

		set len [string length $line]
		set cn [string range $line 0 0]
		binary scan $cn "H*" cn

		# If this is a response to our request.
		if {$cn == "1a"} {break}

		# If we got an NG message from the radio.
		if {$cn == "fa"} {break}
		}

	set status "ok"
	set len [string length $line]

	# Check if channel is empty.
	if {$len == 6}  \
		{
		set line ""
		set status "empty"
		}

	# Check if radio sent NG msg. 
	if {$len == 1}  \
		{
		set line ""
		set status "invalid"
		}

	set lst [list $status $line]

	return $lst
}

###################################################################
# Write one memory channel to the radio.
#	Inputs:
#		s	- encoded data string
###################################################################
proc WriteAChannel { s } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 1A ]]
	set cmd [ append cmd [binary format "H2" 00 ]]
	set cmd [ append cmd $s ]

	set nretries 5
	set status error

	for { set i 0 } {$i < $nretries} {incr i } \
		{
		SendCmd $Sid $cmd

		# Read ok/ng status to clean off the bus.
		ReadRx 0

return


		# Read the response
		set line [ReadRx]
		set len [string length $line]

		if { $len == 0} \
			{
			# Got a read error.
			puts stderr "WriteAChannel: got a read error from radio."
			set status error
			} \
		elseif { $len == 1} \
			{
			# Examine the byte.
			if { [string compare -nocase -length 1 $line \xfb] == 0} \
				{
				# This ack message is ok.
				set status ok
				break
				} \
			else \
				{
				# This ack message is ng.
				puts stderr "WriteAChannel: got NG ack from radio. Will retry."
				set status error
				continue
				}
			} \
		else \
			{
			# Got a strange response.
			puts stderr "WriteAChannel: got strange response from radio."
			set status error
			exit
			}

		}
	if {$status == "error" } \
		{
		puts stderr "WriteAChannel: Retried $nretries times and failed."
		exit
		}

	return
}

###################################################################
# Read a CI-V message from the serial port.
#
# Inputs:
#	any	- 0 means ignore messages with a "from address"
#		field which indicates the message is from
#		this computer.
#		- 1 means return any message
#
# Strip off the 2 address bytes.
#
# Returns: the message without the address fields.
###################################################################
proc ReadRx { {any 0} } \
{
	global GlobalParam

	set ignored "ignoring previous echo msg from the radio."

	set line {} 

	while { 1 } \
		{
		# Read message from the bus.

		set line [ReadCIV]

		if { [string length $line] == 0} \
			{
			# Got a read error.
			break
			}

		# Examine the address bytes.
		set to [string range $line 0 0]
		set from [string range $line 1 1]

		if { ([string compare -nocase -length 1 $to \xe0] != 0) \
			&& ([string compare -nocase -length 1 $to \x4a] != 0)} \
			{
			puts stderr "ReadRx: UNKNOWN MESSAGE"
			continue;
			}

		if { $any == 0 } \
			{
			if { [string compare -nocase -length 1 $from \xe0] == 0} \
				{
				# This message is from us,

				# so ignore it and read again.
				continue
				} \
			} 

		# Strip of the address bytes.
		set line [string range $line 2 end]
		set len [string length $line]

		if { [Check4Meter $line] } \
			{
			# Radio sent an S meter value.
			#  continue
			}


		# Ignore fa and fb ack messages. (caution!)

		break
		}
	return $line
}


###################################################################
# Read a CI-V message from the serial port.
#
# Returns:
#		The message unless there was an error.
#		The empty string if there was an error.
###################################################################
proc ReadCIV { } \
{
	global GlobalParam
	global Sid


	set collision_error false

	# Skip the 2 byte "fe fe" preamble
	read $Sid 1
	read $Sid 1

	set line ""


	while { 1 } \
		{
		set b [read $Sid 1]

		# A byte of hexadecimal fc means there was an
		# error, usually a collision.

		# Note: I have observered that the radio
		# usually sends 3 consecutive fc bytes after
		# a CIV collision.   Because fc should never appear
		# in the IC-R8500 data stream, we consider it 
		# an error whenever we see even a single fc byte.
		#        - Bob Parnass, 2/12/2002

		if { [string compare -nocase -length 1 $b \xfc] == 0} \
			{
			# Got an error, but continue reading bytes
			# until we get an end of message byte fe.

			set collision_error true
			set line [append line $b]
			} \
		elseif { [string compare -nocase -length 1 $b \xfd] == 0} \
			{
			# Got the end of message code byte.
			break
			} \
		elseif { [string compare -nocase -length 1 $b \xfe] == 0} \
			{
			; # Ignore leading preamble bytes.
			} \
		else \
			{
			set line [append line $b]
			}
		}

	if { $GlobalParam(Debug) > 0 } \
		{
		set msg "<--- "
		binary scan $line "H*" x

		regsub -all ".." $x { \0} x

		set msg [append msg $x]
		Tattle $msg
		}

	if { $collision_error == "true" } \
		{
		puts stderr "ReadCIV: collison error."
		set line ""
		}
	return $line
}

###################################################################
# Read S meter.
#
#	Inputs:
#		none
#	Returns:
#		nothing
#
# Notes
#	After calling this proc, the S-meter level
#	will be available in the variable GlobalParam(Smeter).
###################################################################
proc ReadSmeter { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 15 ]]
	set cmd [ append cmd [binary format "H2" 02 ]]


	while { 1 } \
		{
		SendCmd $Sid $cmd

		# Read response from radio.
	
		set line [ReadRx]
		set len [string length $line]

		if {$len > 0} \
			{
			break
			}

		# Got an error while reading.
		puts stderr "ReadSmeter: read error."
		}

	return
}


###################################################################
# Encode a tuning step from kHz to the command string
# the radio understands.
#
# Input:	step in kHz
#
# Returns:	3-byte binary string
###################################################################
proc EncodeTS { step } \
{
	# Convert from kHz to Hz

	set step [expr {$step * 1000}]
	set step [expr { round($step) }]

	switch $step \
		{
		10	{return [binary format H2H2H2 00 05 00]}
		50	{return [binary format H2H2H2 01 50 00]}
		100	{return [binary format H2H2H2 02 00 05]}
		1000	{return [binary format H2H2H2 03 50 01]}
		2500	{return [binary format H2H2H2 04 00 05]}
		5000	{return [binary format H2H2H2 05 50 01]}
		9000	{return [binary format H2H2H2 06 00 05]}
		10000	{return [binary format H2H2H2 07 50 01]}
		12500	{return [binary format H2H2H2 08 00 05]}
		20000	{return [binary format H2H2H2 09 00 05]}
		25000	{return [binary format H2H2H2 10 50 02]}
		100000	{return [binary format H2H2H2 11 00 05]}
		1000000	{return [binary format H2H2H2 12 00 05]}
		default \
			{
			# Programmable tuning step size.
			# Code is 13, encode the 4-digit amount as
			# as 2 bytes of BCD.
			# Notice that the byte order is reversed,
			# like the other frequency type fields.

			set step [ expr { $step / 100 } ]
			set step [ expr { round ($step) } ]
			set step [ PadLeft0 4 $step ]
			set msd2 [string range $step 0 1]
			set lsd2 [string range $step 2 3]
			return [binary format H2H2H2 13 $lsd2 $msd2]
			}
		}
}

###################################################################
# Read squelch status.
#
#	Inputs:
#		none
#
#	Returns:
#	0	- squelch is closed.
#	!=0	- squelch is open.
###################################################################
proc ReadSquelchStatus { } \
{
	global Sid

	set cmd ""
	set cmd [ append cmd [binary format "H2" 15 ]]
	set cmd [ append cmd [binary format "H2" 01 ]]


	set error 1

	while {$error} \
		{
		SendCmd $Sid $cmd

		set error 0

		while {1} \
			{

			# Read messages until we find the
			# one which matches this request.
	
			set line [ReadRx]
			set len [string length $line]

			if {$len == 0} \
				{
				# Got an error while reading.
				puts stderr "ReadSquelchStatus: read error."
				set error 1
				break
				} \
			elseif {$len == 3} \
				{
				set cn [string range $line 0 0]
				binary scan $cn "H*" cn

				set sc [string range $line 1 1]
				binary scan $sc "H*" sc

				if {($cn == 15) && ($sc == 01)} \
					{
					set val [string range $line 2 3]
					binary scan $val "H*" val

					set val [string trimleft $val 0]
					break
					}
				}
			}
		}

	if {$val == ""} \
		{
		set val 0
		}

	return $val
}
###################################################################
# Check the message in "line" to see
# if it is an S-meter value message.
# If so, save the value in a global variable.
###################################################################

proc Check4Meter { line } \
{
	global GlobalParam

	set ismeter 0

	set len [string length $line]

	if {$len == 4} \
		{
		set cn [string range $line 0 0]
		binary scan $cn "H*" cn

		set sc [string range $line 1 1]
		binary scan $sc "H*" sc

		if {($cn == 15) && ($sc == 02)} \
			{
			set val [string range $line 2 3]
			binary scan $val "H*" val

			set val [string trimleft $val 0]
			if {$val == ""} \
				{
				set val 0
				}
			set GlobalParam(Smeter) $val
			set ismeter 1
			}
		}
	return $ismeter
}


###################################################################
# Turn power off/on.
#
# Inputs:
#	off	-instruct radio to go into sleep mode
#	on	-instruct radio come back on from sleep mode
###################################################################
proc PowerSwitch { offon } \
{
	global Sid


	set cmd ""
	set cmd [ append cmd [binary format "H2" 18 ]]

	if { $offon == "on" } \
		{
		set cmd [ append cmd [binary format "H2" 01 ]]
		} \
	elseif { $offon == "off" } \
		{
		set cmd [ append cmd [binary format "H2" 00 ]]
		}

	SendCmd $Sid $cmd

	# Read ok/ng status to clean off the bus.
	ReadRx 0


	return
}

