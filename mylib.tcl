###################################################################
# This file is part of tk2, tk3, tk7, tk10, tk75, tk92, tk120,
# tk150, tk500, tk545, and tk8500.
# 
#    Copyright (C) 2001 - 2003, Bob Parnass
# 
# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this software; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307  USA
###################################################################

###################################################################
# Dialog to open a file for reading.
#
# Note:
#	I placed a wrapper around the built in Tk routine
#	because the MacOS X version
#	does not handle the initialdir parameter properly.
###################################################################
proc Mytk_getOpenFile {parent initialdir title types} \
{
	global tcl_platform

	if { [regexp "Darwin" $tcl_platform(os) ] } \
		{
		# For Mac OS X.
		set initialdir ":"
		}

	set code [tk_getOpenFile -parent $parent \
		-initialdir $initialdir \
		-title $title -filetypes $types]

	return $code
}



###################################################################
# Dialog to open a file for writing.
#
# Note:
#	I placed a wrapper around the built in Tk routine
#	because the MacOS X version
#	does not handle the initialdir parameter properly.
###################################################################
proc Mytk_getSaveFile {f initialdir defaultextension title types} \
{
	global tcl_platform

	if { [regexp "Darwin" $tcl_platform(os) ] } \
		{
		# For Mac OS X.
		set initialdir ":"
		}

	set code [tk_getSaveFile -parent $f \
		-initialdir $initialdir \
		-defaultextension $defaultextension \
		-title $title \
		-filetypes $types]

	return $code
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


##########################################################
#
# Channel Listbox with optional scrollbars.
#
#
# This is modified version of Example 29-1.
# From "Practical Programming in Tcl and Tk,"
# second edition, by Brent B. Welch.
#
# This proc prevents huge listbox windows on MacOS X.
# A bug in the version of Tk for MacOS X prevents the user
# from being able to resize windows larger than the screen.
##########################################################
proc List_channels { parent values height } \
{
	global tcl_platform

	if { [regexp "Darwin" $tcl_platform(os) ] \
		&& (($height == 0) || ($height > 30)) }\
		{
		# Limit the height for Mac OS X.
		set height 30
		}

	frame $parent
	set choices [Scrolled_Listbox $parent.choices \
		-width 0 -height $height ]

	# Insert all the choices
	foreach x $values \
		{
		$choices insert end $x
		}

	pack $parent.choices -side left
	return "$choices"
}


##########################################################
#
# Return the item selected in the channel selector listbox
#
##########################################################

proc ListSelected { w } \
{
	set i [ $w curselection ]
	set item [ $w get $i ]
	return "$item"
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
	regsub " .*" $line "" ch
	return "$ch"
}


##########################################################
# Insert commas in a number
##########################################################

proc InsertCommas {num {sep ,}} {
    while {[regsub {^([-+]?\d+)(\d\d\d)} $num "\\1$sep\\2" num]} {}
    return $num
}


##########################################################
# Active delay
##########################################################

proc waiter { millisec } \
{
	global Waiter

	set Waiter 0
	after $millisec {incr Waiter}
	tkwait variable Waiter
	return
}

###################################################################
# Display tcl version information.
###################################################################
proc HelpTclInfo { } \
{
	global tcl_patchLevel
	global tcl_platform
	global tcl_version

	set version   $tcl_version
	set patch      $tcl_patchLevel
	
	set byteorder $tcl_platform(byteOrder)
	set machine   $tcl_platform(machine)
	set osVersion $tcl_platform(osVersion)
	set platform  $tcl_platform(platform)
	set os        $tcl_platform(os)
	

	set msg ""
	append msg "Tcl version: $version\n"
	append msg "Patch level: $patch\n"
	append msg "Byte order: $byteorder\n"
	append msg "Machine: $machine\n"
	append msg "OS Version: $osVersion\n"
	append msg "Platform: $platform\n"
	append msg "OS: $os\n"

	return $msg
}


###################################################################
# Return the basename of the given pathname.
###################################################################
proc Basename { p } \
{
	regsub -all {.*/} $p "" b
	return $b
}

###################################################################
# Return the directory of the given absolute pathname.
#
# Afterthought: I guess we could have used the 'find dirname'
#	tcl command instead.
###################################################################

proc Dirname { p } \
{
	set lst [ split $p {/} ]
	set n [ llength $lst ]
	incr n -2

	set lst [lrange $lst 0 $n]
	set lst [ join $lst {/} ]

	if { $lst == "" } \
		{
		set lst {.}
		}

	return $lst
}


###################################################################
# Pad 'x' on the left with the proper number of 0s
# until it is 'n' characters long.
###################################################################
proc PadLeft0 { n x } \
{
	set s $x
	set l [ string length $x ]

	set nz [ expr $n - $l ]

	for {set i 0} {$i < $nz} {incr i} \
		{
		# set s [ append s "0" $x ]
		set s [ format "0%s" $s ]
		}

	# puts "n= $n l= $l x= $x s= $s\n"

	return $s
}


###################################################################
# Read global parameters from the configuration file.
#
# Strip off comments.
# Strip out blank and empty lines.
#
# Remaining lines should be of the form:
#
# Fieldname=value
###################################################################

proc ReadSetup { } \
{
	global env
	global GlobalParam
	global Mode
	global Rcfile
	global RootDir
	global tcl_platform


	if [ catch { open $Rcfile "r"} fid] \
		{
		# Tattle "Cannot open $Rcfile for reading."
		return
		} 


	# For each line in the file.

	while { [gets $fid rline] >= 0 } \
		{
		set line $rline

		# Discard comment line.
		# Comment line starts with (optional) white space
		# followed by a pound sign.

		if { [regexp {^[ \t]*#.*} $line] } \
			{
			continue
			}

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

		set msg [format "Error in setup file %s,\n" $Rcfile]
		set msg [append msg [format "in this line:\n%s" $rline]]

		if {$n != 2} \
			{
			tk_dialog .error "tk545" \
				$msg error 0 OK

			exit 1
			}
		set field [ lindex $plist 0 ]
		set value [ lindex $plist 1 ]
		set GlobalParam($field) $value
		}


	close $fid
	return
}


###################################################################
# Save global parameters in the configuration file.
###################################################################

proc SaveSetup { } \
{
	global argv0
	global GlobalParam
	global Rcfile
	global Version

	set pgm [Basename $argv0]

	if [ catch { open $Rcfile "w"} fid] \
		{
		# error
		tk_dialog .error $pgm \
			"Cannot save setup in file $Rcfile" error 0 OK

		return
		} 

	set rcf [Basename $Rcfile]
	puts $fid "# $rcf configuration file, Version $Version"

	set a [array names GlobalParam]
	set a [ lsort -dictionary $a ]

	foreach x $a \
		{
		puts $fid "$x=$GlobalParam($x)"
		}

	close $fid
	return
}


###################################################################
# Test bit number <n> in byte <byte>
###################################################################

proc GetBit { byte n } \
{
	if { ($n >= 0) && ($n <= 7) } \
		{
		binary scan $byte "B*" bits

		set b [string index $bits $n]
		# puts "$bits bit $n is $b"
		} \
	else \
		{
		# Error
		set b ""
		}

	return $b
}

###################################################################
# Set bit <n> to 1 in byte <byte>
# Note: bit 0 is the most significant bit.
###################################################################

proc SetBit { byte n } \
{
	binary scan $byte "B*" bits
	set s [string replace $bits $n $n 1]
	set newbyte [binary format "B8" $s]

	return $newbyte
}

###################################################################
# Clear bit <n> to 0 in byte <byte>
# Note: bit 0 is the most significant bit.
###################################################################

proc ClearBit { byte n } \
{
	binary scan $byte "B*" bits
	set s [string replace $bits $n $n 0]
	set newbyte [binary format "B8" $s]

	return $newbyte
}

###################################################################
# Assign bit <n> 0 or 1 in byte <byte>
#
# Inputs:
#	byte	-8 bit byte
#	n	-which bit to assign
#	val	-0 means clear bit n
#		-otherwise means set bit n
#
# Returns:	new byte value
#
# Note: bit 0 is the most significant bit.
###################################################################
proc AssignBit { byte n val } \
{

	if {$val} \
		{
		return [SetBit $byte $n]
		} \
	else \
		{
		return [ClearBit $byte $n]
		}
}


###################################################################
#
# Extract a bit field from an 8-bit byte.
#
# Inputs:
#	byte	-an 8 bit byte
#	first	-first bit number
#	last	-last bit number (inclusive)
#
# Returns:
#	Integer value 0 - 255
#
# Notes:
#	Bits are numbered from left to right, i.e.,
#	01234567 with bit 0 being most significant
#
#	first <= last
###################################################################
proc GetBitField { byte first last } \
{
	set n [ expr {$last - $first + 1} ]

	if {($first < 0) || ($first > 7) \
		|| ($last < 0) || ($last > 7) || ($n <= 0) } \
		{
		# error
		return 0
		}

	# Convert the byte to an ascii string of 1s and 0s
	binary scan $byte "B*" bits
	set b [string range $bits $first $last]

	# Convert the string of 1s and 0s to a base 10 number.
	set sum 0
	for {set i 0} {$i < $n} {incr i} \
		{
		set x [string index $b $i]
		set sum [expr {$sum + $sum + $x}]
		}
	return $sum
}


###################################################################
#
# Set a bit field in an 8-bit byte.
#
# Inputs:
#	byte	-an 8 bit byte
#	first	-first bit number
#	last	-last bit number (inclusive)
#	val	-field value
#
# Returns:
#	an 8-bit byte
#
# Notes:
#	Bits are numbered from left to right, i.e.,
#	01234567 with bit 0 being most significant
#
#	first <= last
###################################################################
proc SetBitField { byte first last val } \
{
	set n [ expr {$last - $first + 1} ]

	if {$val == ""} \
		{
		set val 0
		}

	if { ($val > 255) || ($first < 0) || ($first > 7) \
		|| ($last < 0) || ($last > 7) || ($n <= 0) \
		|| ($byte == "") } \
		{
		# error
		return $byte
		}

	# Convert the input byte to an ascii string of 1s and 0s
	binary scan $byte "B*" bits

	set vhex [format "%x" $val]
	if {[string length $vhex] == 1 }\
		{
		set vhex [format "0%s" $vhex]
		}
	set vbyte [binary format "H2" $vhex]
	binary scan $vbyte "B*" vbits

	set nn [expr { 0 - ($n - 8)}]
	set nvbits [string range $vbits $nn end]

	set newbits [string replace $bits $first $last $nvbits]

	# Convert the string of 1s and 0s to a base 10 number.
	set sum 0
	for {set i 0} {$i < 8} {incr i} \
		{
		set x [string index $newbits $i]
		set sum [expr {$sum + $sum + $x}]
		}
	set sumhex [format "%x" $sum]
	if {[string length $sumhex] == 1 }\
		{
		set sumhex [format "0%s" $sumhex]
		}

	# Convert to an 8-bit binary value
	set newbyte [binary format "H2" $sumhex]

	return $newbyte
}

################################################################
#
# Generate an error message for a line in a file.
#
# Inputs:
#	description	-message describing the specific problem.
#	line		-the line read
#	filename	-name of file
#
# Returns:
#	0	- user says continue
#	1	- user says exit this program
#
################################################################
proc ErrorInFile {description line filename} \
{
	global GlobalParam

	set msg ""
	append msg "The following line in file\n"
	append msg "$filename "
	append msg "contains an error:\n\n"
	append msg "$line\n\n"
	append msg "$description\n\n"
	append msg "Continue or exit the program?"

	set response [tk_dialog .badcsv "Error in file" \
		$msg error 0 OK Exit]

	return $response
}



######################################################################
#					Bob Parnass
#					DATE:
#
# PROGRAM NAME:	Bank2List
#
# USAGE:	Bank2List farray first last
#
# INPUTS:
#		farray		-array of frequencies
#		first		-index of first element in farray
#				to sort
#		last		-index of last element in farray
#				to sort
#
# RETURNS:	A list of the frequencies
#
#
# PURPOSE:	Converts part of an array of freqs into a list.
#
# DESCRIPTION:
#
######################################################################

proc Bank2List { farray first last } \
{
	upvar $farray freqarray

	set chlist [ list ]
	for {set i $first} {$i <= $last} {incr i} \
		{
		if { [info exists freqarray($i)] } \
			{
			lappend chlist $freqarray($i)
			} \
		else \
			{
			lappend chlist ""
			}
		}

	return $chlist
}

######################################################################
#					Bob Parnass
#
# Given a list of frequencies, return a vector of the indices
# in ascending frequency order.
# Exception: forces 0 freqs to be last.
#
# EXAMPLE:
#	SortFreqList 500.0 400.0 0.0 2.0
#
#	returns the list: 3 1 0 2
#	
######################################################################

proc SortFreqList { flist } \
{

	set listsize [llength $flist]
	set onebank [ list ]
	for {set i 0} {$i < $listsize} {incr i} \
		{
		set freq [lindex $flist $i]
		set tuple [ list $freq $i ]
		lappend onebank $tuple
		}
	set sbank [ lsort -command CompareFreq $onebank ]

	set slistsize [llength $sbank]

	set chlist [ list ]
	for {set i 0} {$i < $slistsize} {incr i} \
		{
		set tuple [lindex $sbank $i]
		set ch [lindex $tuple 1]
		lappend chlist $ch
		# puts stderr "ch= $ch"
		}

	return $chlist
}


######################################################################
#					Bob Parnass
#
# Given a list of text labels, return a vector of the indices
# in ascending caseless, alphanumeric order.
#
# EXAMPLE:
#	SortLabelList "TAXI" "NYPD" "" "USAF"
#
#	returns the list: 2 1 0 3
#	
######################################################################

proc SortLabelList { tlist } \
{

	set listsize [llength $tlist]
	set onebank [ list ]
	for {set i 0} {$i < $listsize} {incr i} \
		{
		set label [lindex $tlist $i]
		set tuple [ list $label $i ]
		lappend onebank $tuple
		}
	# set sbank [ lsort -dictionary -increasing $onebank ]
	set sbank [ lsort -command CompareLabel $onebank ]

	set slistsize [llength $sbank]

	set chlist [ list ]
	for {set i 0} {$i < $slistsize} {incr i} \
		{
		set tuple [lindex $sbank $i]
		set ch [lindex $tuple 1]
		lappend chlist $ch
		# puts stderr "ch= $ch"
		}

	return $chlist
}

###################################################################
# Compare two alphanumeric strings.
#
# Inputs:
#	la	-list of {first string, index}
#	lb	-list of {second string, index}
#
# Returns:
#	0	-if equal
#	-1	-if a < b
#	1	-if a > b
#
# 	Exceptions: treat the empty string as greater than
#		any non-empty string
###################################################################

proc CompareLabel {la lb} \
{
	set a [lindex $la 0]
	set b [lindex $lb 0]

	if {$a == ""} \
		{
		if {$b == ""} {set code 0} \
		else {set code 1}
		} \
	elseif {$b == ""} \
		{
		if {$a == ""} {set code 0} \
		else {set code -1}
		} \
	else \
		{
		set code [string compare -nocase $a $b]
		}
	return $code
}


###################################################################
# Compare two frequencies.
#
# Inputs:
#	la	-list of {first freq, index}
#	lb	-list of {second freq, index}
#
# Returns:
#	0	-if equal
#	-1	-if a < b
#	1	-if a > b
#
# 	Exceptions: treat the 0 as greater than
#		any non-empty freq
###################################################################

proc CompareFreq {la lb} \
{
	set a [lindex $la 0]
	set b [lindex $lb 0]
	set small .0001
	set nsmall -.0001

	if {$a == ""} {set a 0}
	if {$b == ""} {set b 0}

	if { ($a <= $small) && ($a >= $nsmall) } \
		{
		if {($b <= $small) && ($b >= $nsmall)} {set code 0} \
		else {set code 1}
		} \
	elseif { ($b <= $small)  && ($b >= $nsmall) } \
		{
		if {($a <= $small) && ($a >= $nsmall)} {set code 0} \
		else {set code -1}
		} \
	else \
		{
		if {$a < $b} {set code -1} \
		elseif {$a > $b} {set code 1} \
		else {set code 0}

		}
#	puts stderr "CompareFreq: $a $b $code"
	return $code
}

proc SortArray { iarray vorder } \
{
	upvar $iarray inarray

	# set tmplist [array get $inarray]
	# array set tmparray $tmplist

	# Make temp copy of array
	foreach e [array names inarray] \
		{
		set tmparray($e) $inarray($e)
		}

	foreach e [array names inarray] \
		{
		set inarray($e) ""
		}

	set listsize [llength $vorder]

	for {set i 0} {$i < $listsize} {incr i} \
		{
		set ch [lindex $vorder $i]
		# set tmparray($i) $inarray($ch)
		set inarray($i) $tmparray($ch)
		# puts stderr "i= $i, $inarray($i)"
		}
	
	return
}

######################################################################
# Reorder the elements in a list based on a specified order.
#
#					Bob Parnass
#
# INPUTS:
#	inlist	-list to reorder
#	vorder	-list of indices
#
# RETURNS:
#	reordered list
#
# EXAMPLE:
#	ReorderList { a b c } { 1 2 0 }
#	returns the list: b c a
#
#	ReorderList { a b c } { 1 0 }
#	returns the list: b a {}
#
#
#
# NOTES:
#	If the vorder list is shorter than the input list,
#	the trailing elements in the list are set to null.
#
######################################################################

proc ReorderList { inlist vorder } \
{

	set isize [llength $inlist]
	set vsize [llength $vorder]

#	puts stderr "ReorderList: inlist: $inlist \nvorder: $vorder"
	# Make temp copy of array
	set outlist [list]

	# Create a list of null entries.
	# It should have the same number of entries
	# as the input list but each entry will be null.

	for {set i 0} {$i < $isize} {incr i} \
		{
		lappend outlist ""
		}
	

	for {set i 0} {$i < $vsize} {incr i} \
		{
		set ch [lindex $vorder $i]
		set e [lindex $inlist $ch]
		set outlist [lreplace $outlist $i $i $e]
		}

	
	return $outlist
}

###################################################################
#
# Ask which bank to sort.
# Create a popup window with an entry box for a Bank
# number and a couple of buttons.
#
###################################################################

proc MakeSortFrame { } \
{
	global BankID
	global Cht
	global GlobalParam
	global HasLabels
	global MemLabel
	global NBanks
	global NChanPerBank
	global VNChanPerBank


	catch {destroy .sortwin}
	toplevel .sortwin
	wm title .sortwin "Sort channels in a bank"

	set f .sortwin
	frame $f.a -relief groove -borderwidth 3
	set a $f.a



	radiobutton $a.byfreq -text "Sort by frequency" \
		-variable GlobalParam(SortType) -value "freq"

	radiobutton $a.bylabel -text "Sort by label" \
		-variable GlobalParam(SortType) -value "label"

	pack $a.byfreq -side top -anchor w
	pack $a.bylabel -side top -anchor w


	frame $f.b -relief groove -borderwidth 3
	set b $f.b

	radiobutton $b.butall -text "All Banks" \
		-variable GlobalParam(SortBank) \
		-value -1
	pack $b.butall -side top -anchor w

	for {set bn 0} {$bn < $NBanks} {incr bn} \
		{
		if { [info exists BankID($bn)] } \
			{
			set bid $BankID($bn)
			} \
		else \
			{
			set bid $bn
			}

		radiobutton $b.but$bn -text "Bank $bid" \
			-variable GlobalParam(SortBank) \
			-value $bn
		pack $b.but$bn -side top -anchor w
		}



	frame $f.c -relief flat -borderwidth 3
	set c $f.c

	button $c.apply -text "Sort" -command \
		{
		global Cht
		global GlobalParam
		global TimerCode

		if {$GlobalParam(SortBank) == -1} \
			{
			SortAllBanks
			} \
		else \
			{
			set first [expr { $GlobalParam(SortBank) \
				* $VNChanPerBank }]
			set last [expr {$first + $NChanPerBank - 1}]
			if {[SortaBank $first $last] == 0} \
				{
				ShowChannels $Cht
				}
			}
		catch {destroy .sortwin}
		}

	button $c.cancel -text "Cancel" -command \
		{
		catch {destroy .sortwin}
		}

	pack $c.apply $c.cancel -side left -padx 3 -pady 3

	if {$HasLabels == "yes"} \
		{
		pack $a -side top -padx 3 -pady 3
		}
	pack $b -side top -padx 3 -pady 3
	pack $c -side top -padx 3 -pady 3

	update
	return
}


######################################################################
#					Bob Parnass
#					DATE:
#
# USAGE:	SortAllBanks
#
# INPUTS:
#
# RETURNS:	nothing
#
# PURPOSE:	Sort the channels in all memory banks.
#
# DESCRIPTION:
#
######################################################################
proc SortAllBanks { } \
{
	global Cht
	global GlobalParam
	global NBanks
	global NChanPerBank
	global VNChanPerBank
	global Mimage

	if {$GlobalParam(Populated) == 0} \
		{
		set msg "You must open a file\n"
		append msg " or read an image from the radio\n"
		append msg " before sorting channels.\n"

		tk_dialog .belch "Sort All Banks" \
			$msg info 0 OK
		return
		}

	set first 0

	for {set bn 0} {$bn < $NBanks} {incr bn} \
		{
		set last [expr {$first + $NChanPerBank - 1}]
		SortaBank $first $last
		incr first $VNChanPerBank
		}

	if {$GlobalParam(Populated)} \
		{
		ShowChannels $Cht
		}
	return
}



###################################################################
# Create a list of duplicate frequencies in memory channels.
#
# Check for the same frequency stored in more than
# one memory channel.
#
# Returns:
#	A sorted list of duplicate frequencies.
#	Each element consists of an informative text string containing
#	the frequency and the bank and channel numbers which
#	contain that frequency.
#
###################################################################
proc ListDuplicate { } \
{
	global BankID
	global ChanNumberRepeat
	global MemFreq
	global NBanks
	global NChanPerBank
	global VNChanPerBank

	# For each non-zero frequency contained in any memory
	# channel, create a list of channels which are
	# programmed with that frequency.
 
	set nch [expr {$NBanks * $NChanPerBank}]

	for {set bn 0} {$bn < $NBanks} {incr bn} \
		{
		set ch [expr {$bn * $VNChanPerBank}]

		for {set i 0} {$i < $NChanPerBank} {incr i} \
			{
			# puts stderr "i: $i, bn: $bn, ch: $ch"
			if { ([info exists MemFreq($ch)]) } \
				{
				set f $MemFreq($ch)
				if {$f > .001} \
					{
					set f [format "%.5f" $MemFreq($ch)]
					if {$ChanNumberRepeat == "yes"}\
						{
						set ich [expr {fmod($ch,$NChanPerBank)}]
						set ich [expr {int($ich)}]
						} \
					else \
						{
						set ich $ch
						}

					if { [info exists BankID($bn)] } \
						{
						set bid $BankID($bn)
						} \
					else \
						{
						set bid $bn
						}

					set s [format "(bank %s, ch %3d) " $bid $ich]
					lappend ChList($f) $s
					set FreqExists($f) 1
					}
				}
			incr ch
			}
		}

	set duplist [list]

	foreach f [ array names FreqExists ] \
		{
		set m ""
		# puts stderr "$f, channels: $ChList($f)"
		if { [llength $ChList($f)] > 1 } \
			{
			# Frequency is a duplicate.
			append m [format "%10s MHz: " $f]
			set n [llength $ChList($f)]

			for {set i 0} {$i < $n} {incr i} \
				{
				append m [lindex $ChList($f) $i]
				}
			lappend duplist $m 
			}
		}
	set duplist [lsort $duplist]
	return $duplist
}

###################################################################
# Display a popup window of duplicate frequencies.
###################################################################
proc CkDuplicate { } \
{
	global Mimage

	if {[info exists Mimage] == 0} \
		{
		set msg "You must open a file\n"
		append msg " or read data from the radio before\n"
		append msg " checking for duplicate frequencies.\n"

		tk_dialog .nodata "No data" \
			$msg info 0 OK
		return
		}



	set duplist [ListDuplicate]
	if { [llength $duplist] } \
		{
		catch {destroy .dup}
		toplevel .dup

		label .dup.lab -text "Duplicate Frequencies in Memory"

		set dupes [ List_channels .dup.f \
			$duplist 30 ]

		button .dup.dismiss -text "OK" \
			-command "destroy .dup"

		wm title .dup "Duplicate Frequencies"
		pack .dup.dismiss -side bottom -padx 3 -pady 3
		pack .dup.lab -side top -padx 3 -pady 3
		pack .dup.f -side bottom -padx 3 -pady 3
		wm deiconify .dup
		$dupes activate 1
		}
	return
}


###################################################################
#
# Ask which banks to swap.
#
###################################################################

proc MakeSwapFrame { } \
{
	global BankID
	global GlobalParam
	global NBanks

	if { ( [info exists GlobalParam(SwapBankA)] == 0 )  \
		|| ( [info exists GlobalParam(SwapBankA)] == 0 ) } \
		{
		set GlobalParam(SwapBankA) 0
		set GlobalParam(SwapBankB) 0
		}


	catch {destroy .swapwin}
	toplevel .swapwin
	wm title .swapwin "Swap channel banks"

	set f .swapwin
	frame $f.a -relief groove -borderwidth 3
	set a $f.a

	label $a.lab1 -text "First Bank" -borderwidth 3
	label $a.lab2 -text "Second Bank" -borderwidth 3

	set row 0
	grid $a.lab1 -row $row -column 0 -sticky ew
	grid $a.lab2 -row $row -column 1 -sticky ew

	set row 5
	for {set i 0} {$i < $NBanks} {incr i} \
		{
		if { [info exists BankID($i)] } \
			{
			set bid $BankID($i)
			} \
		else \
			{
			set bid $i
			}

		radiobutton $a.swapbanka$i -text $bid \
			-variable GlobalParam(SwapBankA) -value $i

		radiobutton $a.swapbankb$i -text $bid \
			-variable GlobalParam(SwapBankB) -value $i

		grid $a.swapbanka$i -row $row -column 0 -sticky ew
		grid $a.swapbankb$i -row $row -column 1 -sticky ew
		incr row
		}


	frame $f.c -relief flat -borderwidth 3
	set c $f.c

	button $c.apply -text "Swap" -command \
		{
		global GlobalParam

		SwapBank \
			$GlobalParam(SwapBankA) $GlobalParam(SwapBankB)

		catch {destroy .swapwin}
		}

	button $c.cancel -text "Cancel" -command \
		{
		catch {destroy .swapwin}
		}

	pack $c.apply $c.cancel -side left -padx 3 -pady 3

	pack $a -side top -padx 3 -pady 3
	pack $c -side top -padx 3 -pady 3

	update
	return
}



###################################################################
# Read variables and values from an open file and return them
# in a list of lines.
#
# Each label must be of the form:
#
#	variable(key)=label
#
# Example:
#
#	MemLabel(4)=Kencom P1
###################################################################
proc ReadVariables { filename fid } \
{
	global Pgm


	# For each line in the file.

	set vlist [list]
	while { [gets $fid rline] >= 0 } \
		{
		set line $rline

		# Discard comment line.
		# Comment line starts with (optional) white space
		# followed by a pound sign.

		if { [regexp {^[ \t]*#.*} $line] } \
			{
			continue
			}

		# Skip blank line.
		if { [regexp {^ *$} $line] } \
			{
			continue
			}

		set line [string trimleft $line " "]

		# Valid parameter line must be of the form:
		# MemLabel(channel)=label

		set plist [ split $line "=" ]
		set n [llength $plist]

		set msg [format "Error in file %s,\n" $filename]
		set msg [append msg [format "in this line:\n%s" $rline]]

		if {$n != 2} \
			{
			tk_dialog .error $Pgm $msg error 0 OK
			exit 1
			}

		set field [ lindex $plist 0 ]
		set value [ lindex $plist 1 ]

		lappend vlist $line
		}

	return $vlist
}

