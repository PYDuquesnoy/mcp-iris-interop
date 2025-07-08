/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syNLS, ShmObj)

/// NLS tables can be divided into I/O (also called translation)
/// and Internal tables, each type having a set of categories:<br><br>
/// 
/// I/O tables<ul>
///  <li>Process</li>
///  <li>InterSystems IRIS Terminal</li>
///  <li>Other terminal</li>
///  <li>File</li>
///  <li>Magtape</li>
///  <li>TCP/IP</li>
///  <li>DSM-DDP</li>
///  <li>DTM-DCP</li>
///  <li>System call</li>
///  <li>Printer</li></ul>
/// 
/// 	Internal tables<ul>
///  <li>Pattern match</li>
///  <li>Identifier</li>
///  <li>Uppercase</li>
///  <li>Lowercase</li>
///  <li>Titlecase</li>
///  <li>Accent</li>
///  <li>Collation</li>
///  <li>$X/$Y action</li></ul>
/// 
/// For each category, a locale defines a set of available
/// tables and selects one of them to be used as the system
/// default. InterSystems distributes a set of read-only
/// locales but users can create their own locales.<br><br>
/// 
/// A configuration allows a different system default
/// to be selected among the available tables. Configuration
/// defaults are optional and independent of the locale.
/// They persist across system reboots and updates.<br><br>
/// 
/// At startup, the system defaults are set either from the
/// configured defaults or from the locale defaults. Configuration
/// defaults have precedence if defined; otherwise the locale
/// defaults are used.<br><br>
/// 
/// When a process starts
/// it inherits all the system defaults. The process
/// setting for I/O tables can still be overriden when
/// opening a device by specifying "K\TableName\" in the
/// OPEN parameters.<br><br>
/// 
/// This class has properties that represent each of
/// the above categories.<br><br>
/// 
/// To get the Configured defaults, instantiate an object with<br><br>
/// 
/// <code>Set obj=##class(%SYS.NLS.Table).%New("Config")</code><br><br>
/// 
/// To get the loaded System defaults, instantiate an object with<br><br>
/// 
/// <code>Set obj=##class(%SYS.NLS.Table).%New("System")</code><br><br>
/// 
/// To get the loaded Process settings, instantiate an object with<br><br>
/// 
/// <code>Set obj=##class(%SYS.NLS.Table).%New("Process")</code><br><br>
/// 
/// Changing a property for a Process object immediately
/// changes the corresponding setting in the process, but it
/// is not possible to change the properties of a system object.
/// Changes to a Config object will only affect the next system
/// reboot.<br><br>
/// 
/// For generic locale properties see <class>%SYS.NLS.Locale</class>.<br>
/// For current device NLS properties see <class>%SYS.NLS.Device</class>.<br>
/// For date, time and number format properties see <class>%SYS.NLS.Format</class>.<br>
Class %SYS.NLS.Table Extends %RegisteredObject [ System = 4 ]
{

Property Process As %String;

Property IRISTerminal As %String;

Property OtherTerminal As %String;

Property File As %String;

Property Magtape As %String;

Property TCPIP As %String;

Property DSMDDP As %String;

Property DTMDCP As %String;

Property SystemCall As %String;

Property Printer As %String;

Property PatternMatch As %String;

Property Identifier As %String;

Property Uppercase As %String;

Property Lowercase As %String;

Property Titlecase As %String;

Property Accent As %String;

Property Collation As %String;

Property XYAction As %String;

Property CSP As %String;

/// True if translation is ON
Property State As %Boolean;

Property IsSystem As %Boolean [ Internal ];

Property IsConfig As %Boolean [ Internal ];

Method ProcessGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOProcess)
}

Method ProcessSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOProcess,table)
}

Method IRISTerminalGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOMTerm)
}

Method IRISTerminalSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOMTerm,table)
}

Method OtherTerminalGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOTerminal)
}

Method OtherTerminalSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOTerminal,table)
}

Method FileGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOFile)
}

Method FileSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOFile,table)
}

Method MagtapeGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOMagtape)
}

Method MagtapeSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOMagtape,table)
}

Method TCPIPGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IONetwork)
}

Method TCPIPSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IONetwork,table)
}

Method DSMDDPGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IONetDSM)
}

Method DSMDDPSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IONetDSM,table)
}

Method DTMDCPGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IONetDTM)
}

Method DTMDCPSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IONetDTM,table)
}

Method SystemCallGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOSysCall)
}

Method SystemCallSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOSysCall,table)
}

Method PrinterGet() As %String [ Internal ]
{
 Quit ..GetIOTable($$$IOPrinter)
}

Method PrinterSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetIOTable($$$IOPrinter,table)
}

Method PatternMatchGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TablePattern)
}

Method PatternMatchSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TablePattern,table)
}

Method IdentifierGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableIdent)
}

Method IdentifierSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableIdent,table)
}

Method UppercaseGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableUpper)
}

Method UppercaseSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableUpper,table)
}

Method LowercaseGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableLower)
}

Method LowercaseSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableLower,table)
}

Method TitlecaseGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableTitle)
}

Method TitlecaseSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableTitle,table)
}

Method AccentGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableAccent)
}

Method AccentSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableAccent,table)
}

Method CollationGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableMax+1)
}

Method CollationSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableMax+1,table)
}

Method XYActionGet() As %String [ Internal ]
{
 Quit ..GetInternalTable($$$TableMax+2)
}

Method XYActionSet(table As %String) As %Status [ Internal ]
{
 Quit ..SetInternalTable($$$TableMax+2,table)
}

Method CSPGet() As %String [ Internal ]
{
 If ..IsConfig { Quit $G(@($Name($$$NLSConfigGbl))@("CSP")) }
 ElseIf '..IsSystem { Quit $G(@($Name($$$NLSProcessGbl))@("CSP")) }
 Quit ""
}

ClassMethod GetCSPTable() As %String [ Internal ]
{
	If $D(@($Name($$$NLSProcessGbl))@("CSP"),tab) Quit tab
	Quit $get(@($Name($$$NLSConfigGbl))@("CSP"))
}

Method CSPSet(table As %String) As %Status [ Internal ]
{
 If ..IsSystem Quit $$$ERROR($$$GeneralError,"Not valid for System objects")
 If ..IsConfig {
 	If '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) Quit $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
 	Set ref=$Name($$$NLSConfigGbl)
 } Else { Set ref=$Name($$$NLSProcessGbl) }
 Set tables=##class(%SYS.NLS.Locale).%New().XLTTables
 If '$LF(tables,table) Quit $$$ERROR($$$GeneralError,"Table not available")
 Set @ref@("CSP")=table
 Quit $$$OK
}

Method StateGet() As %Boolean [ Internal ]
{
 Quit $$getstate(0,0)!$$getstate(0,1)

getstate(han, dir)
 Set $ZT="errstate"
 Quit $$$GetIOStat(han,dir)
 
errstate Quit 0
}

Method StateSet(state As %Boolean) As %Status [ Internal ]
{
 If ..IsSystem Quit $$$ERROR($$$GeneralError,"Cannot change system setting")
 Set status=$$$OK,state=''state
 Do setstate(0,0,state),setstate(0,1,state)
 Quit status

setstate(han, dir, val)
 Set $ZT="errstate"
 Do $$$SetIOStat(han,dir,val)
 Quit
 
errstate Set status=$$$ERROR($$$ObjectScriptError,$ze)
}

/// Gets the name of an I/O table<br><br>
/// Parameter: index - table index<ol start="0">
///  <li>Process</li>
///  <li>InterSystems IRIS Terminal</li>
///  <li>Other terminal</li>
///  <li>File</li>
///  <li>Magtape</li>
///  <li>TCP/IP</li>
///  <li>DSM-DDP</li>
///  <li>DTM-DCP</li>
///  <li>System call</li>
///  <li>Printer</li></ol>
Method GetIOTable(index As %Integer) As %String
{
 Set name=""
 If index>-1,index'>$$$IOMax {
	If ..IsConfig {
		Set ref=$Name($$$NLSConfigGbl)
		Set name=$G(@ref@($P($$$IOProps,",",index+1)))
	} Else {
		If ..IsSystem { Set base=$$$DefaultIOOff,type=-2 }
		Else { Set base=$$$ProcessIOOff,type=-1 }
		Set off=$$$GetGenOff(base,index,type)
		Set name=$S(off:$$$NamOff2Str(off),1:"")
	}
 }
 Quit name
}

Method SetIOTable(index As %Integer, table As %String) As %Status [ Internal ]
{
 If ..IsSystem Quit $$$ERROR($$$GeneralError,"Cannot change system setting")
 If ..IsConfig {
 	If '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) Quit $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
 	Set tables=##class(%SYS.NLS.Locale).%New().XLTTables
 	If '$LF(tables,table) Quit $$$ERROR($$$GeneralError,"Table not available")
 	If index<0||(index>$$$IOMax) Quit $$$ERROR($$$GeneralError,"Invalid index")
 	Set ref=$Name($$$NLSConfigGbl),@ref@($P($$$IOProps,",",index+1))=table
 } Else {
 	Set namoff=$$$GetNamEle($$$IONameTable,table,0) 
 	If 'namoff Quit $$$ERROR($$$GeneralError,"Unknown table name: "_table)
 	$$$SetPartOff($$$ProcessIOOff,index,namoff)
 }
 Quit $$$OK
}

/// Gets the name of an Internal table<br><br>
/// Parameter: index - table index<ol start="0">
///  <li>Pattern match</li>
///  <li>Identifier</li>
///  <li>Uppercase</li>
///  <li>Lowercase</li>
///  <li>Titlecase</li>
///  <li>(reserved)</li>
///  <li>(reserved)</li>
///  <li>Accent</li>
///  <li>Collation</li>
///  <li>$X/$Y action</li></ol>
Method GetInternalTable(index As %Integer) As %String
{
 Set name=""
 If index>-1,index'>$$$TableMax,index'=$$$TableU2Pattern,index'=$$$TableAlphaup {
	#; Pattern match, Identifier, UpperCase, LowerCase, TitleCase, U2Pattern match, AlphaUp, Accent
	If ..IsConfig {
		Set ref=$Name($$$NLSConfigGbl)
		Set name=$G(@ref@($P($$$TableProps,",",index+1)))
	} Else {
		If ..IsSystem { Set base=$$$DefaultTableOff,type=-2 }
		Else { Set base=$$$ProcessTableOff,type=-1 }
		Set off=$$$GetGenOff(base,index,type)
		Set name=$S(off:..GetOffName(off,$P($$$TableTypes,",",index+1)),1:"")
	}
 } ElseIf index=($$$TableMax+1) {
	#; Collation
	If ..IsConfig { Set ref=$Name($$$NLSConfigGbl),name=$G(@ref@("Collation")) }
	Else { Set name=..GetCOL($ZU(23,'..IsSystem)) }
 } ElseIf index=($$$TableMax+2) {
	#; $X/$Y action
	If ..IsConfig { Set ref=$Name($$$NLSConfigGbl),name=$G(@ref@("XYAction")) }
	Else {
		If ..IsSystem { Set base=$$$DefaultXYOff,type=-2 }
		Else { Set base=$$$ProcessXYOff,type=-1 }
		Set off=$$$GetGenOff(base,0,type)
		Set name=$S(off:$$$NamOff2Str(off),1:"")
	}
 }
 Quit name
}

Method SetInternalTable(index As %Integer, table As %String) As %Status [ Internal ]
{
 If ..IsSystem Quit $$$ERROR($$$GeneralError,"Cannot change system setting")
 If ..IsConfig,'$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) Quit $$$ERROR($$$OperationRequires,$$$AdminManageResourceName_":"_$$$PermUseName)
 Set charset=..GetCharset(),type=$P($$$TableTypes,",",index+1),status=$$$OK
 
 If index>-1,index'>$$$TableMax,index'=$$$TableU2Pattern,index'=$$$TableAlphaup {
	#; Pattern match, Identifier, UpperCase, LowerCase, TitleCase, U2Pattern match, AlphaUp, Accent
	If ..IsConfig {
		Set loc=##class(%SYS.NLS.Locale).%New()
		Set tables=$Case(index=0,0:loc.PatternTables,1:loc.IdentifierTables,2:loc.UpperCaseTables,3:loc.LowerCaseTables,4:loc.TitleCaseTables,7:loc.AccentTables,:"")
 		If '$LF(tables,table) Quit $$$ERROR($$$GeneralError,"Table not available")
 		Set ref=$Name($$$NLSConfigGbl),@ref@($P($$$TableProps,",",index+1))=table
	} Else {
		Set typ=$P($$$TableTypes,",",index+1)
		Set oid=$O(^|"%SYS"|SYS("shm",$$$SHMSrc,1,"%nls",type,charset,table,""),-1)
		If oid { Do $$$PRsetoffset(index,^|"%SYS"|SYS("shm",$$$SHMOff,0,oid)) }
		Else { Set status=$$$ERROR($$$GeneralError,"Unknown table name: "_table) }
	}
 } ElseIf index=($$$TableMax+1) {
	#; Collation
	If ..IsConfig {
		Set tables=##class(%SYS.NLS.Locale).%New().CollationTables
 		If '$LF(tables,table) Quit $$$ERROR($$$GeneralError,"Table not available")
 		Set ref=$Name($$$NLSConfigGbl),@ref@("Collation")=table
	} Else {
		Set col=-1,ref=$Name($$$NLSTablesGbl)
		If table?1.N { Set col=+table }
		ElseIf $D(@ref@("COL",charset,table),rec) {
			Set col=$$$GetTableCOLRules(rec),col=+$List(col,1)
		}
		If col>-1,col<256,'$$$COLundef(col) { Do $$$COLswitch(col) }
		Else { Set status=$$$ERROR($$$GeneralError,"Invalid collation type: "_table) }
	}
 } ElseIf index=($$$TableMax+2) {
	#; $X/$Y action
	If ..IsConfig {
		Set tables=##class(%SYS.NLS.Locale).%New().XYTables
 		If '$LF(tables,table) Quit $$$ERROR($$$GeneralError,"Table not available")
 		Set ref=$Name($$$NLSConfigGbl),@ref@("XYAction")=table
	} Else {
		Set namoff=$$$GetNamEle($$$XYNameTable,table,0)
		If namoff { $$$SetPartOff($$$ProcessXYOff,0,namoff) }
		Else { Set status=$$$ERROR($$$GeneralError,"Unknown table name: "_table) }
	}
 } Else { Set status=$$$ERROR($$$GeneralError,"Invalid index") }
 Quit status
}

/// Get the name of a loaded collation
ClassMethod GetCOL(col As %Integer) As %String [ Internal ]
{
 Set rul=$ZU(23,2,col),name=""
 If $P(rul,"^",1,2)'="255^255" {
	Set num=$P(rul,"^",3)
	If num {
		Set offs=$ZU(83,num),dec=+$P(offs,",",2),enc=+offs
		If enc||dec {
			Set name=..GetOffName(enc,"COL")
			If col>128 Set name=name_" string"
		}
	} Else {
		If col<6 { Set name=$P("Old ANSI^New ANSI^^^^IRIS standard","^",col+1) }
 		ElseIf col#128<6 { Set name=$P("Old string^New string^^^^IRIS standard string","^",col-127) }
		Else { Set name="???" }
 	}
 }
 Quit name
}

/// Get the table name associated with a shm offset
ClassMethod GetOffName(off As %Integer, typ As %String) As %String [ Internal ]
{
 #; If we didn't load this offset, then it's a built-in table
 Set oid=+$O(^|"%SYS"|SYS("shm",$$$SHMOff,1,off,"")),typ=$G(typ,"XLT")
 If 'oid Quit $S(typ="XLT"||(typ="COL"):"Built-in",1:"Latin1")
 Set nam=$Q(^|"%SYS"|SYS("shm",$$$SHMSrc,0,oid)) Quit:$QS(nam,3)'=0 "" Quit:$QS(nam,4)'=oid ""
 Quit $S(typ="XLT":$QS(nam,7)_"->"_$QS(nam,8),1:$QS(nam,8))
}

/// Gets character set of current locale
ClassMethod GetCharset() As %String [ Internal ]
{
 If $ZBitget($ZVersion(0),1) Quit "Unicode"
 If '$D($$$LOCALENAME,loc) Quit "Latin1"
 Set rloc=$Name($$$NLSLocalesGbl),rloc=$Name(@rloc@(loc)),lrec=$G(@rloc)
 If lrec'="" Quit $$$GetLocaleCharacterSet(lrec)
 If $D(^%nls($$$NLSLoc,loc,$$$LocaleCharSet),lchs) Quit lchs
 Quit "Latin1"
}

/// Converts an external character set name to its internal name<br><br>
/// Parameter:<ul>
///    <li>ext - External charset name (eg: "ISO-8859-2").
///          If it is already an internal name (eg: "UTF8"),
///          it is returned unchanged (except that "Latin1"
///          is returned as "RAW").</li></ul>
/// Returns:<ul>
///    <li>Internal name equivalent to ext (eg: "Latin2")</li>
///    <li>"" if there is no internal equivalent to 'ext'</li></ul>
ClassMethod DisplayToLogical(ext As %String) As %String
{
 Quit $$MapCharset^%SYS.NLS(ext)
}

/// Converts an internal character set name to its preferred external name<br><br>
/// Parameter:<ul>
///    <li>int - Internal charset name (eg: "Latin2")</li></ul>
/// Returns:<ul>
///    <li>Preferred external name (eg: "ISO-8859-2")</li>
///    <li>"" if there is no internal charset 'int'.</li></ul>
ClassMethod LogicalToDisplay(int As %String) As %String
{
 Quit $$MapExtCharset^%SYS.NLS(int)
}

Method %OnNew(src As %String) As %Status [ Internal ]
{
 Set ..IsSystem=(src="System")
 Set ..IsConfig=(src="Config")
 Quit $$$OK
}

}
