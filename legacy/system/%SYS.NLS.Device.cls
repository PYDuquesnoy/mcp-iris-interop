/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// Exposes some NLS properties of the current device.<br><br>
/// Changing a property acts immediately on the current device,
/// not on the device that was current when the object was
/// instantiated.<br><br>
/// 
/// For generic locale properties see <class>%SYS.NLS.Locale</class>.<br>
/// For system and process NLS table settings see <class>%SYS.NLS.Table</class>.<br>
/// For date, time and number format properties see <class>%SYS.NLS.Format</class>.<br>
Class %SYS.NLS.Device Extends %RegisteredObject [ System = 4 ]
{

/// Translation table associated with current device.
Property XLTTable As %String;

/// Input default action<ul>
/// <li>0 = generate error</li>
/// <li>1 = replace with replacement value/string</li>
/// <li>2 = ignore (replace with original character)</li></ul>
Property InpDefaultAction As %Integer;

/// Input replacement value/string.<br>
/// Substituted in case of error if InpDefaultAction=1
Property InpReplacementValue As %String;

/// If true indicates that a replacement occurred during
/// the last input translation.
Property InpReplaced As %Boolean;

/// Output default action<ul>
/// <li>0 = generate error</li>
/// <li>1 = replace with replacement value/string</li>
/// <li>2 = ignore (replace with original character)</li></ul>
Property OutDefaultAction As %Integer;

/// Output replacement value/string.<br>
/// Substituted in case of error if OutDefaultAction=1
Property OutReplacementValue As %String;

/// If true indicates that a replacement occurred during
/// the last output translation.
Property OutReplaced As %Boolean;

/// State of translation for current device<ul>
/// <li>0 = Off</li>
/// <li>1 = On</li></ul>
Property State As %Boolean;

/// Used with double width characters (e.g. Kanji)
Property Pitch As %Integer;

/// Sets I/O translation table for current device<br><br>
/// This method exists as a convenience only. Calling
/// it is equivalent to instantiating a %SYS.NLS.Device
/// object and setting obj.XLTTable=tabnam<br><br>
/// Parameters:<ul>
///   <li>tabnam - table name</li></ul>
/// Returns: previous table or "" in case of error
ClassMethod SetIO(tabnam As %String) As %String
{
 Quit $$$IOsetname(2,tabnam)
}

Method XLTTableGet() As %String [ Internal ]
{
 Quit $$$IOgetname(0)
}

Method XLTTableSet(value As %String) As %Status [ Internal ]
{
 Set status=$$$OK
 Do settable(value)
 Quit status
 
settable(table)
 Set $ZT="errstable"
 Do $$$IOsetname(2,table)
 Quit
 
errstable Set status=$$$ERROR($$$GeneralError,"Invalid table: "_table)
 Quit
}

Method InpDefaultActionGet() As %Integer [ Internal ]
{
 Quit:$$$IOvalid(0) $$$GetReplType("",0) Quit -1
}

Method InpDefaultActionSet(value As %Integer) As %Status [ Internal ]
{
 If $$$IOvalid(0) Do $$$SetReplType("",0,value) Quit $$$OK
 Else  Quit $$$ERROR($$$GeneralError,"Invalid device")
}

Method InpReplacementValueGet() As %String [ Internal ]
{
 Quit:$$$IOvalid(0) $$$GetReplVal("",0) Quit ""
}

Method InpReplacementValueSet(value As %String) As %Status [ Internal ]
{
 If $$$IOvalid(0) Do $$$SetReplVal("",0,value) Quit $$$OK
 Else  Quit $$$ERROR($$$GeneralError,"Invalid device")
}

Method InpReplacedGet() As %Boolean [ Internal ]
{
 Quit:$$$IOvalid(0) $$$GetReplStat("",0) Quit -1
}

Method InpReplacedSet(value As %Boolean) As %Status [ Internal ]
{
 If $$$IOvalid(0) Do $$$SetReplStat("",0,value) Quit $$$OK
 Else  Quit $$$ERROR($$$GeneralError,"Invalid device")
}

Method OutDefaultActionGet() As %Integer [ Internal ]
{
 Quit:$$$IOvalid(1) $$$GetReplType("",1) Quit -1
}

Method OutDefaultActionSet(value As %Integer) As %Status [ Internal ]
{
 If $$$IOvalid(1) Do $$$SetReplType("",1,value) Quit $$$OK
 Else  Quit $$$ERROR($$$GeneralError,"Invalid device")
}

Method OutReplacementValueGet() As %String [ Internal ]
{
 Quit:$$$IOvalid(1) $$$GetReplVal("",1) Quit ""
}

Method OutReplacementValueSet(value As %String) As %Status [ Internal ]
{
 If $$$IOvalid(1) Do $$$SetReplVal("",1,value) Quit $$$OK
 Else  Quit $$$ERROR($$$GeneralError,"Invalid device")
}

Method OutReplacedGet() As %Boolean [ Internal ]
{
 Quit:$$$IOvalid(1) $$$GetReplStat("",1) Quit -1
}

Method OutReplacedSet(value As %Boolean) As %Status [ Internal ]
{
 If $$$IOvalid(1) Do $$$SetReplStat("",1,value) Quit $$$OK
 Else  Quit $$$ERROR($$$GeneralError,"Invalid device")
}

Method StateGet() As %Boolean [ Internal ]
{
 Quit $$getstate("",0)!$$getstate("",1)

getstate(han, dir)
 Set $ZT="errstate"
 Quit $$$GetIOStat(han,dir)
 
errstate Quit 0
}

Method StateSet(state As %Boolean) As %Status [ Internal ]
{
 Set status=$$$OK,state=''state
 Do setstate("",0,state),setstate("",1,state)
 Quit status

setstate(han, dir, val)
 Set $ZT="errstate"
 Do $$$SetIOStat(han,dir,val)
 Quit
 
errstate Set status=$$$ERROR($$$ObjectScriptError,$ze)
}

Method PitchGet() As %Integer [ Internal ]
{
 Quit $$$IOgetpitch(0)/4
}

Method PitchSet(pitch As %Integer) As %Status [ Internal ]
{
 Quit $$$IOsetpitch(2,pitch*4\1)/4
 Quit $$$OK
}

/// Set input mode string<br>
/// Parameters:<ul>
///   <li>value  - new input mode string</li>
///   <li>mode   - mode number</li></ul>
/// Returns: previous input string for given mode or "" in case of error
Method InpModeStrSetAt(value As %String, mode As %Integer) As %String
{
 Quit:$$$IOvalid(0) $$$SetModeStr("",0,mode,value) Quit ""
}

/// Set output mode string<br>
/// Parameters:<ul>
///   <li>value  - new output mode string</li>
///   <li>mode   - mode number</li></ul>
/// Returns: previous output string for given mode or "" in case of error
Method OutModeStrSetAt(value As %String, mode As %Integer) As %String
{
 Quit:$$$IOvalid(1) $$$SetModeStr("",1,mode,value) Quit ""
}

/// Get input mode string<br>
/// Parameters:<ul>
///   <li>mode - mode number</li></ul>
/// Returns: current input string for given mode or "" in case of error
Method InpModeStrGetAt(mode As %Integer) As %String
{
 Quit:$$$IOvalid(0) $$$GetModeStr("",0,mode) Quit ""
}

/// Get output mode string<br>
/// Parameters:<ul>
///   <li>mode - mode number</li></ul>
/// Returns: current output string for given mode or "" in case of error
Method OutModeStrGetAt(mode As %Integer) As %String
{
 Quit:$$$IOvalid(1) $$$GetModeStr("",1,mode) Quit ""
}

}
