# ----------------------------------------------------------------------
#  EXAMPLE: use "wm" commands to manage a balloon help window
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

option add *Balloonhelp*background yellow widgetDefault
option add *Balloonhelp*foreground black widgetDefault
option add *Balloonhelp.info.wrapLength 3i widgetDefault
option add *Balloonhelp.info.justify left widgetDefault
option add *Balloonhelp.info.font \
    -*-lucida-medium-r-normal-sans-*-120-* widgetDefault

toplevel .balloonhelp -class Balloonhelp \
    -background black -borderwidth 1 -relief flat

# label .balloonhelp.arrow -anchor nw \
#     -bitmap @[file join $env(EFFTCL_LIBRARY) images arrow.xbm]
# pack .balloonhelp.arrow -side left -fill y

label .balloonhelp.info
pack .balloonhelp.info -side left -fill y

wm overrideredirect .balloonhelp 1
wm withdraw .balloonhelp

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_for <win> <mesg>
#
#  Adds balloon help to the widget named <win>.  Whenever the mouse
#  pointer enters this widget and rests within it for a short delay,
#  a balloon help window will automatically appear showing the
#  help <mesg>.
# ----------------------------------------------------------------------
proc balloonhelp_for {win mesg} {
    global bhInfo
    set bhInfo($win) $mesg

    bind $win <Enter> {balloonhelp_pending %W}
    bind $win <Leave> {balloonhelp_cancel}
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_control <state>
#
#  Turns balloon help on/off for the entire application.
# ----------------------------------------------------------------------
set bhInfo(active) 1

proc balloonhelp_control {state} {
    global bhInfo

    if {$state} {
        set bhInfo(active) 1
    } else {
        balloonhelp_cancel
        set bhInfo(active) 0
    }
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_pending <win>
#
#  Used internally to mark the point in time when a widget is first
#  touched.  Sets up an "after" event so that balloon help will appear
#  if the mouse remains within the current window.
# ----------------------------------------------------------------------
proc balloonhelp_pending {win} {
    global bhInfo

    balloonhelp_cancel
    set bhInfo(pending) [after 1500 [list balloonhelp_show $win]]
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_cancel
#
#  Used internally to mark the point in time when the mouse pointer
#  leaves a widget.  Cancels any pending balloon help requested earlier
#  and hides the balloon help window, in case it is visible.
# ----------------------------------------------------------------------
proc balloonhelp_cancel {} {
    global bhInfo

    if {[info exists bhInfo(pending)]} {
        after cancel $bhInfo(pending)
        unset bhInfo(pending)
    }
    wm withdraw .balloonhelp
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_show <win>
#
#  Used internally to display the balloon help window for the
#  specified <win>.
#
# Modified 1/3/2002 by Bob Parnass:
#	Check flag to enable/inhibit help messages.
# ----------------------------------------------------------------------
proc balloonhelp_show {win} {
    global GlobalParam
    global bhInfo

    if {($GlobalParam(BalloonHelpWindows) == "on" ) \
        && ($bhInfo(active))} {
        .balloonhelp.info configure -text $bhInfo($win) \
		-background yellow

        set x [expr [winfo rootx $win]+10]
        set y [expr [winfo rooty $win]+[winfo height $win]]
        wm geometry .balloonhelp +$x+$y
        wm deiconify .balloonhelp
        raise .balloonhelp
    }
    unset bhInfo(pending)
}
# ----------------------------------------------------------------------
#  EXAMPLE: procedures to create dialogs
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

proc dialog_create {class {win "auto"}} {
    if {$win == "auto"} {
        set count 0
        set win ".dialog[incr count]"
        while {[winfo exists $win]} {
            set win ".dialog[incr count]"
        }
    }
    toplevel $win -class $class

    frame $win.info
    pack $win.info -expand yes -fill both -padx 4 -pady 4

    frame $win.sep -height 2 -borderwidth 1 -relief sunken
    pack $win.sep -fill x -pady 4

    frame $win.controls
    pack $win.controls -fill x -padx 4 -pady 4

    wm title $win $class
    wm group $win .

    after idle [format {
        update idletasks
        wm minsize %s [winfo reqwidth %s] [winfo reqheight %s]
    } $win $win $win]

    return $win
}

proc dialog_info {win} {
    return "$win.info"
}

proc dialog_controls {win} {
    return "$win.controls"
}

proc dialog_wait {win varName} {
    dialog_safeguard $win

    set x [expr [winfo rootx .]+50]
    set y [expr [winfo rooty .]+50]
    wm geometry $win "+$x+$y"

    wm deiconify $win
    grab set $win

    vwait $varName

    grab release $win
    wm withdraw $win
}

bind modalDialog <ButtonPress> {
    wm deiconify %W
    raise %W
}
proc dialog_safeguard {win} {
    if {[lsearch [bindtags $win] modalDialog] < 0} {
        bindtags $win [linsert [bindtags $win] 0 modalDialog]
    }
}
# ----------------------------------------------------------------------
#  EXAMPLE: procedures to manipulate fonts
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================
#
# Modified 2/2/2002 by Bob Parnass:
#	 Eliminated underline and overstrike attributes.


option add *Fontselect*Listbox.background white widgetDefault
option add *Fontselect*Text.background white widgetDefault
option add *Fontselect*Entry.background white widgetDefault

# ----------------------------------------------------------------------
# USAGE: font_best <family> <family>... <option> <value>...
#
# Creates a new font with an automatically generated name.  If the
# first <family> is not installed, then the font defaults to the next
# family, and the next, and so on.  If none of the families are
# installed, the font defaults to a system face.  The remaining
# arguments are treated as <option> <value> pairs like "-size 10",
# used to configure the font.
# ----------------------------------------------------------------------
proc font_best {args} {
    set fname [font create]
    set family ""
    while {[llength $args] > 0} {
        set arg0 [lindex $args 0]
        if {[string index $arg0 0] == "-"} {
            break
        }
        set args [lrange $args 1 end]

        if {$family == ""} {
            font configure $fname -family $arg0
            if {[font actual $fname -family] == $arg0} {
                set family $arg0
            }
        }
    }

    eval font configure $fname $args
    return $fname
}

# ----------------------------------------------------------------------
# Fontselect dialog
# ----------------------------------------------------------------------
# USAGE: font_select_update
#
# Invoked whenever one of the slots within the fnInfo structure
# changes.  If the slot corresponds to a font characteristic, then
# the internal font is updated to the current state.
# ----------------------------------------------------------------------
proc font_select_update {name1 name2 op} {
    global fnInfo

    switch -- $name2 {
        family - size - weight - slant - underline - overstrike {
            font configure $fnInfo(font) -$name2 $fnInfo($name2)
        }
    }
}

# ----------------------------------------------------------------------
set fnInfo(font) [font create]
trace variable fnInfo w font_select_update

set fnInfo(dialog) [dialog_create Fontselect]
wm title $fnInfo(dialog) "Font Selector"

wm protocol $fnInfo(dialog) WM_DELETE_WINDOW {
    set win [dialog_controls $fnInfo(dialog)]
    $win.cancel invoke
}
wm withdraw $fnInfo(dialog)

set win [dialog_info $fnInfo(dialog)]
frame $win.sample -height 1i
pack propagate $win.sample 0
pack $win.sample -side bottom -fill x
text $win.sample.text -width 1 -height 1 -wrap none \
    -font $fnInfo(font) \
    -yscrollcommand "$win.sample.sbar set"
pack $win.sample.text -side left -expand yes -fill both
scrollbar $win.sample.sbar -orient vertical \
    -command "$win.sample.text yview"
pack $win.sample.sbar -side right -fill y
label $win.samplel -text "Sample:"
pack $win.samplel -side bottom -anchor w
frame $win.sep2 -height 2 -borderwidth 1 -relief sunken
pack $win.sep2 -side bottom -fill x -pady 8

listbox $win.families -height 10 -exportselection 0 \
    -yscrollcommand "$win.sbar set"
pack $win.families -side left -expand yes -fill both
scrollbar $win.sbar -orient vertical -command "$win.families yview"
pack $win.sbar -side left -fill y
frame $win.opts
pack $win.opts -side left -padx 2
label $win.opts.sizel -text "Size:"
grid $win.opts.sizel -row 0 -column 0 -sticky e
entry $win.opts.size -width 5
grid $win.opts.size -row 0 -column 1 -sticky ew
label $win.opts.weightl -text "Weight:"
grid $win.opts.weightl -row 1 -column 0 -sticky e
tk_optionMenu $win.opts.weight fnInfo(weight) normal bold
grid $win.opts.weight -row 1 -column 1 -sticky ew
label $win.opts.slantl -text "Slant:"
grid $win.opts.slantl -row 2 -column 0 -sticky e
tk_optionMenu $win.opts.slant fnInfo(slant) roman italic
grid $win.opts.slant -row 2 -column 1 -sticky ew
set fnInfo(underline) off
set fnInfo(overstrike) off

eval $win.families insert 0 [lsort [font families]]
$win.families selection set 0
set fnInfo(family) [$win.families get 0]

bind $win.families <ButtonPress-1> {font_select_family %W %y}
bind $win.families <B1-Motion> {font_select_family %W %y}

proc font_select_family {win y} {
    global fnInfo

    set index [$win nearest $y]
    if {$index != ""} {
        set fnInfo(family) [$win get $index]
    }
}

$win.opts.size insert 0 "12"
bind $win.opts.size <KeyPress-Return> {font_select_size %W}
bind $win.opts.size <Leave> {font_select_size %W}
bind $win.opts.size <FocusOut> {font_select_size %W}

proc font_select_size {win} {
    global fnInfo

    set size [$win get]
    if {[catch {expr round($size)} size] == 0} {
        set fnInfo(size) $size
    } else {
        $win delete 0 end
        $win insert 0 $fnInfo(size)
    }
}

set win [dialog_controls $fnInfo(dialog)]
button $win.ok -text "OK" -command {
    set fnInfo(ok) 1
}
pack $win.ok -side left -expand yes -padx 4

button $win.cancel -text "Cancel" -command {
    set fnInfo(ok) 0
}
pack $win.cancel -side left -expand yes -padx 4

set fnInfo(size) 12
set fnInfo(sample) "ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
1234567890 !@#$%^&*()"


# ----------------------------------------------------------------------
# USAGE: font_select ?<sample>?
#
# Pops up a dialog, allowing the user to select a font.  If the
# <sample> text is included, then this text is displayed in the
# dialog.  Otherwise, a default string is displayed, showing part
# of the alphabet.
# ----------------------------------------------------------------------
proc font_select {{sample ""}} {
    global fnInfo
    set info [dialog_info $fnInfo(dialog)]

    $info.sample.text delete 1.0 end
    if {[string length $sample] == 0} {
        set sample $fnInfo(sample)
    }
    $info.sample.text insert 1.0 $sample

    set cntls [dialog_controls $fnInfo(dialog)]
    focus $cntls.ok
    dialog_wait $fnInfo(dialog) fnInfo(ok)

    if {$fnInfo(ok)} {
        return [font configure $fnInfo(font)]
    }
    return ""
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


##########################################################
#
# Create a scrollable frame.
#
#
# From "Effective Tcl/Tk Programming,"
# by Mark Harrison and Michael McLennan.
# Page 121.
#
##########################################################

proc ScrollformCreate { win } \
{

	frame $win -class Scrollform -relief groove -borderwidth 3
	scrollbar $win.sbar -command "$win.vport yview"
	pack $win.sbar -side right -fill y

	canvas $win.vport -yscrollcommand "$win.sbar set"
	pack $win.vport -side left -fill both -expand true

	frame $win.vport.form
	$win.vport create window 0 0 -anchor nw \
		-window $win.vport.form

	bind $win.vport.form <Configure> "ScrollFormResize $win"
	return $win
}

proc ScrollFormResize { win } \
{
	set bbox [ $win.vport bbox all ]
	set wid [ winfo width $win.vport.form ]
	$win.vport configure -width $wid \
		-scrollregion $bbox -yscrollincrement 0.1i
}

proc ScrollFormInterior { win } \
{
	return "$win.vport.form"
}

# ----------------------------------------------------------------------
#  EXAMPLE: read-only text display
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

option add *Textdisplay*text.wrap word widgetDefault
option add *Textdisplay*text.background white widgetDefault
option add *Textdisplay*text.width 60 widgetDefault
option add *Textdisplay*text.height 15 widgetDefault

proc textdisplay_create {{title "Text Display"}} {
    set top [dialog_create Textdisplay]
    wm title $top $title

    set info [dialog_info $top]
    scrollbar $info.sbar -command "$info.text yview"
    pack $info.sbar -side right -fill y
    text $info.text -wrap word -yscrollcommand "$info.sbar set"
    pack $info.text -side left -expand yes -fill both

    set cntls [dialog_controls $top]
    button $cntls.dismiss -text "Dismiss" -command "destroy $top"

	
    # Added by Bob Parnass, Dec. 2001
    bind $cntls.dismiss <Key-Return> "global top; destroy $top"

    pack $cntls.dismiss -pady 4
    focus $cntls.dismiss

    $info.text configure -state disabled

    $info.text tag configure normal -spacing1 6p \
        -font -*-helvetica-medium-r-normal--*-120-*

    $info.text tag configure heading -spacing1 0.2i \
        -font -*-helvetica-bold-r-normal--*-120-*

    $info.text tag configure bold \
        -font -*-helvetica-bold-r-normal--*-120-*

    $info.text tag configure italic \
        -font -*-helvetica-medium-o-normal--*-120-*

    $info.text tag configure typewriter -wrap none \
        -font -*-courier-medium-r-normal--*-120-*

    return $top
}

proc textdisplay_file {top fname} {
    set info [dialog_info $top]
    set fid [open $fname r]
    set contents [read $fid]
    close $fid
    $info.text configure -state normal
    $info.text delete 1.0 end
    $info.text insert end $contents "typewriter"
    $info.text configure -state disabled
}

proc textdisplay_clear {top} {
    set info [dialog_info $top]
    $info.text configure -state normal
    $info.text delete 1.0 end
    $info.text configure -state disabled
}

proc textdisplay_append {top mesg {tag "normal"}} {
    set info [dialog_info $top]
    $info.text configure -state normal
    $info.text insert end $mesg $tag
    $info.text configure -state disabled
}

# ----------------------------------------------------------------------
#  EXAMPLE: simple notebook that can dial up pages
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

option add *Notebook.borderWidth 2 widgetDefault
option add *Notebook.relief sunken widgetDefault

proc notebook_create {win} {
    global nbInfo

    frame $win -class Notebook
    pack propagate $win 0

    set nbInfo($win-count) 0
    set nbInfo($win-pages) ""
    set nbInfo($win-current) ""
    return $win
}

proc notebook_page {win name} {
    global nbInfo

    set page "$win.page[incr nbInfo($win-count)]"
    lappend nbInfo($win-pages) $page
    set nbInfo($win-page-$name) $page

    frame $page

    if {$nbInfo($win-count) == 1} {
        after idle [list notebook_display $win $name]
    }
    return $page
}

proc notebook_display {win name} {
    global nbInfo

    set page ""
    if {[info exists nbInfo($win-page-$name)]} {
        set page $nbInfo($win-page-$name)
    } elseif {[winfo exists $win.page$name]} {
        set page $win.page$name
    }
    if {$page == ""} {
        error "bad notebook page \"$name\""
    }

    notebook_fix_size $win

    if {$nbInfo($win-current) != ""} {
        pack forget $nbInfo($win-current)
    }
    pack $page -expand yes -fill both
    set nbInfo($win-current) $page
}

proc notebook_fix_size {win} {
    global nbInfo

    update idletasks

    set maxw 0
    set maxh 0
    foreach page $nbInfo($win-pages) {
        set w [winfo reqwidth $page]
        if {$w > $maxw} {
            set maxw $w
        }
        set h [winfo reqheight $page]
        if {$h > $maxh} {
            set maxh $h
        }
    }
    set bd [$win cget -borderwidth]
    set maxw [expr $maxw+2*$bd]
    set maxh [expr $maxh+2*$bd]
    $win configure -width $maxw -height $maxh
}


# ----------------------------------------------------------------------
#  EXAMPLE: tabnotebook that can dial up pages
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

option add *Tabnotebook.tabs.background #666666 widgetDefault
option add *Tabnotebook.margin 6 widgetDefault
option add *Tabnotebook.tabColor #a6a6a6 widgetDefault
option add *Tabnotebook.activeTabColor #d9d9d9 widgetDefault
option add *Tabnotebook.tabFont \
    -*-helvetica-bold-r-normal--*-120-* widgetDefault

proc tabnotebook_create {win} {
    global tnInfo

    frame $win -class Tabnotebook
    canvas $win.tabs -highlightthickness 0
    pack $win.tabs -fill x

    notebook_create $win.notebook
    pack $win.notebook -expand yes -fill both

    set tnInfo($win-tabs) ""
    set tnInfo($win-current) ""
    set tnInfo($win-pending) ""
    return $win
}

proc tabnotebook_page {win name} {
    global tnInfo

    set page [notebook_page $win.notebook $name]
    lappend tnInfo($win-tabs) $name

    if {$tnInfo($win-pending) == ""} {
        set id [after idle [list tabnotebook_refresh $win]]
        set tnInfo($win-pending) $id
    }
    return $page
}

proc tabnotebook_refresh {win} {
    global tnInfo

    $win.tabs delete all

    set margin [option get $win margin Margin]
    set color [option get $win tabColor Color]
    set font [option get $win tabFont Font]
    set x 2
    set maxh 0

    foreach name $tnInfo($win-tabs) {
        set id [$win.tabs create text \
            [expr $x+$margin+2] [expr -0.5*$margin] \
            -anchor sw -text $name -font $font \
            -tags [list $name]]

        set bbox [$win.tabs bbox $id]
        set wd [expr [lindex $bbox 2]-[lindex $bbox 0]]
        set ht [expr [lindex $bbox 3]-[lindex $bbox 1]]
        if {$ht > $maxh} {
            set maxh $ht
        }

        $win.tabs create polygon 0 0  $x 0 \
            [expr $x+$margin] [expr -$ht-$margin] \
            [expr $x+$margin+$wd] [expr -$ht-$margin] \
            [expr $x+$wd+2*$margin] 0 \
            2000 0  2000 10  0 10 \
            -outline black -fill $color \
            -tags [list $name tab tab-$name]

        $win.tabs raise $id

        $win.tabs bind $name <ButtonPress-1> \
            [list tabnotebook_display $win $name]

        set x [expr $x+$wd+2*$margin]
    }
    set height [expr $maxh+2*$margin]
    $win.tabs move all 0 $height

    $win.tabs configure -width $x -height [expr $height+4]

    if {$tnInfo($win-current) != ""} {
        tabnotebook_display $win $tnInfo($win-current)
    } else {
        tabnotebook_display $win [lindex $tnInfo($win-tabs) 0]
    }
    set tnInfo($win-pending) ""
}

proc tabnotebook_display {win name} {
    global tnInfo

    notebook_display $win.notebook $name

    set normal [option get $win tabColor Color]
    $win.tabs itemconfigure tab -fill $normal

    set active [option get $win activeTabColor Color]
    $win.tabs itemconfigure tab-$name -fill $active
    $win.tabs raise $name

    set tnInfo($win-current) $name
}
