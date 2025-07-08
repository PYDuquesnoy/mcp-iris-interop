/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines the set of common index transformation (or collation) methods.
/// 
/// <p>An index transformation is used to tranform logical data values into 
/// values used by indices.
/// <p>For example, you may wish that a query by name finds 
/// the same results for both "ELVIS" and "elvis". Using a case-insensitive 
/// index transformation, such as String, will accomplish this. If you want an exact 
/// match, use Exact.
/// 
/// <p>Index transformations are specified via a property's <var>COLLATION</var> parameter. Every datatype 
/// has a default <var>COLLATION</var> value, which matches one of the methods of the 
/// <nobr><b>%Collation</b></nobr> class. 
/// The <var>COLLATION</var> parameter can be overwritten by an individual property or by 
/// a specific index definition.
/// 
/// <p>Note that changing a property's <var>COLLATION</var> value will corrupt any index values 
/// currently stored for that property and will require you to manually repopulate the 
/// index.
Class %Library.Collation [ Not ProcedureBlock, System = 2 ]
{

/// Converts a logical value to upper case, strips all punctuation and white space 
/// (except for ',' and '?').
/// <p>This method is included for compatability with earlier products; use 
/// <b>String</b> instead.
ClassMethod AlphaUp(%val As %String) As %String [ CodeMode = expression ]
{
$zu(28,%val,6)
}

/// Performs no transformation; the index value is exactly the logical value.
ClassMethod Exact(%val As %String) As %String [ CodeMode = expression ]
{
%val
}

/// Prepends a minus ('-') sign to the logical value.
/// <p>This method is included for compatability with earlier products; you should not 
/// need it in new applications.
ClassMethod Minus(%val As %String) As %String [ CodeMode = expression ]
{
-%val
}

/// Prepends a plus ('+') sign to the logical value.
/// <p>This method is included for compatability with earlier products; you should not 
/// need it in new applications.
ClassMethod Plus(%val As %String) As %String [ CodeMode = expression ]
{
+%val
}

/// Prepends a space (' ') character to the logical value.
/// <p>This method is included for compatability with earlier products; you should not 
/// need it in new applications.
ClassMethod Space(%val As %String) As %String [ CodeMode = expression ]
{
" "_%val
}

/// Prepends a space to force string collation and strips trailing whitespace.
/// <p>This method is used to insure that strings are collated case-sensitively and that numeric 
/// string values are collated correctly.
ClassMethod SqlString(%val As %String, maxlen As %Integer = 32768) As %String [ CodeMode = expression ]
{
$zu(28,%val,8,maxlen)
}

/// Converts a logical value to upper case, strips trailing whitespace and prepends a space
/// to force string collation.
/// <p>This method is used to insure that strings are collated case-insensitively and that numeric 
/// string values are collated correctly.
ClassMethod SqlUpper(%val As %String, maxlen As %Integer = 32768) As %String [ CodeMode = expression ]
{
$zu(28,%val,7,maxlen)
}

/// Converts a logical value to upper case, strips all punctuation and white space 
/// (except for ',').
/// <p>This method is used to insure that strings are collated case-insensitively and that numeric 
/// string values are collated correctly.
ClassMethod String(%val As %String, maxlen As %Integer = 32768) As %String [ CodeMode = expression ]
{
$zu(28,%val,9,maxlen)
}

/// Converts a logical value to upper case without removing any characters.
ClassMethod Upper(%val As %String) As %String [ CodeMode = expression ]
{
$zu(28,%val,5)
}

/// Converts a logical value to MVR collation
ClassMethod Mvr(%val As %String) As %String [ CodeMode = expression ]
{
$zu(28,%val,2)
}

/// Converts a logical value to exact colation with a defined length limit
ClassMethod Truncate(%val As %String, len As %Integer) As %String [ CodeMode = expression ]
{
$s($d(len):$e(%val,1,len),1:%val)
}

/// Converts a logical value to %COLLATE collation
ClassMethod Collate(val As %String, transSpec As %String = "", length As %String = "") As %String [ ProcedureBlock = 1 ]
{
	set str = $$$quote(transSpec)_","_length
	do getCollateParms^%qaqcpre(str,.parm1,.parm2)
	return $xecute("q "_$$$COLLATETCodeGen($$$quote(val),parm1,parm2))
}

/// Compares a %TimeStamp to a %Date value with the = operator.
ClassMethod TSEQDate(ts As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")=$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %TimeStamp to a %Date value with the &gt; operator.
ClassMethod TSGTDate(ts As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")>$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %TimeStamp to a %Date value with the '&lt; operator.
ClassMethod TSGEDate(ts As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")'<$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %TimeStamp to a %Date value with the &lt; operator.
ClassMethod TSLTDate(ts As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")<$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %TimeStamp to a %Date value with the '&gt; operator.
ClassMethod TSLEDate(ts As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")'>$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %TimeStamp to a %Date value with the '= operator.
ClassMethod TSNEDate(ts As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")'=$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %PosixTime to a %Date value with the = operator.
ClassMethod PTEQDate(pt As %PosixTime, d As %Date) As %Boolean [ CodeMode = expression ]
{
pt=$zu(1073741924,(d-47117)*86400)
}

/// Compares a %PosixTime to a %Date value with the &gt; operator.
ClassMethod PTGTDate(pt As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
pt>$zu(1073741924,(d-47117)*86400)
}

/// Compares a %PosixTime to a %Date value with the '&lt; operator.
ClassMethod PTGEDate(pt As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
pt'<$zu(1073741924,(d-47117)*86400)
}

/// Compares a %PosixTime to a %Date value with the &lt; operator.
ClassMethod PTLTDate(pt As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
pt<$zu(1073741924,(d-47117)*86400)
}

/// Compares a %PosixTime to a %Date value with the '&gt; operator.
ClassMethod PTLEDate(pt As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
pt'>$zu(1073741924,(d-47117)*86400)
}

/// Compares a %PosixTime to a %Date value with the '= operator.
ClassMethod PTNEDate(pt As %TimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
pt'=$zu(1073741924,(d-47117)*86400)
}

/// Compares a %PosixTime to a %TimeStamp value with the = operator.
ClassMethod PTEQTS(pt As %PosixTime, ts As %TimeStamp) As %Boolean
{
	RETURN:(ts="")||(pt="") 0
		#; convert ts to %PosixTime value, then compare with pt.  Comparing twp %PosixTime values is faster than comparing %TimeStamp values (strings)
	set ts=$zdatetimeh(ts,3,1,$l($p(ts,".",2)),,,,-672045,,"Error: '"_ts_"' is an invalid %TimeStamp value passed to TimeStampToLogical()") if $e(ts,1,5)="Error" { set %msg=ts ZTRAP "ODAT" }
	RETURN (pt=$zu(1073741924,(ts-47117)*86400+$p(ts,",",2)))
}

/// Compares a %PosixTime to a %TimeStamp value with the &gt; operator.
ClassMethod PTGTTS(pt As %PosixTime, ts As %TimeStamp) As %Boolean
{
	RETURN:(ts="")||(pt="") 0
		#; convert ts to %PosixTime value, then compare with pt.  Comparing twp %PosixTime values is faster than comparing %TimeStamp values (strings)
	set ts=$zdatetimeh(ts,3,1,$l($p(ts,".",2)),,,,-672045,,"Error: '"_ts_"' is an invalid %TimeStamp value passed to TimeStampToLogical()") if $e(ts,1,5)="Error" { set %msg=ts ZTRAP "ODAT" }
	RETURN (pt>$zu(1073741924,(ts-47117)*86400+$p(ts,",",2)))
}

/// Compares a %PosixTime to a %TimeStamp value with the '&lt; operator.
ClassMethod PTGETS(pt As %PosixTime, ts As %TimeStamp) As %Boolean
{
	RETURN:(ts="")||(pt="") 0
		#; convert ts to %PosixTime value, then compare with pt.  Comparing twp %PosixTime values is faster than comparing %TimeStamp values (strings)
	set ts=$zdatetimeh(ts,3,1,$l($p(ts,".",2)),,,,-672045,,"Error: '"_ts_"' is an invalid %TimeStamp value passed to TimeStampToLogical()") if $e(ts,1,5)="Error" { set %msg=ts ZTRAP "ODAT" }
	RETURN (pt'<$zu(1073741924,(ts-47117)*86400+$p(ts,",",2)))
}

/// Compares a %PosixTime to a %TimeStamp value with the &lt; operator.
ClassMethod PTLTTS(pt As %PosixTime, ts As %TimeStamp) As %Boolean
{
	RETURN:(ts="")||(pt="") 0
		#; convert ts to %PosixTime value, then compare with pt.  Comparing twp %PosixTime values is faster than comparing %TimeStamp values (strings)
	set ts=$zdatetimeh(ts,3,1,$l($p(ts,".",2)),,,,-672045,,"Error: '"_ts_"' is an invalid %TimeStamp value passed to TimeStampToLogical()") if $e(ts,1,5)="Error" { set %msg=ts ZTRAP "ODAT" }
	RETURN (pt<$zu(1073741924,(ts-47117)*86400+$p(ts,",",2)))
}

/// Compares a %PosixTime to a %TimeStamp value with the '&gt; operator.
ClassMethod PTLETS(pt As %PosixTime, ts As %TimeStamp) As %Boolean
{
	RETURN:(ts="")||(pt="") 0
		#; convert ts to %PosixTime value, then compare with pt.  Comparing twp %PosixTime values is faster than comparing %TimeStamp values (strings)
	set ts=$zdatetimeh(ts,3,1,$l($p(ts,".",2)),,,,-672045,,"Error: '"_ts_"' is an invalid %TimeStamp value passed to TimeStampToLogical()") if $e(ts,1,5)="Error" { set %msg=ts ZTRAP "ODAT" }
	RETURN (pt'>$zu(1073741924,(ts-47117)*86400+$p(ts,",",2)))
}

/// Compares a %PosixTime to a %TimeStamp value with the '= operator.
ClassMethod PTNETS(pt As %PosixTime, ts As %TimeStamp) As %Boolean
{
	RETURN:(ts="")||(pt="") 0
		#; convert ts to %PosixTime value, then compare with pt.  Comparing twp %PosixTime values is faster than comparing %TimeStamp values (strings)
	set ts=$zdatetimeh(ts,3,1,$l($p(ts,".",2)),,,,-672045,,"Error: '"_ts_"' is an invalid %TimeStamp value passed to TimeStampToLogical()") if $e(ts,1,5)="Error" { set %msg=ts ZTRAP "ODAT" }
	RETURN (pt'=$zu(1073741924,(ts-47117)*86400+$p(ts,",",2)))
}

/// Compares a %FilemanTimeStamp to a %PosixTime value with the = operator.
ClassMethod FMTSEQPT(fmts As %Library.FilemanTimeStamp, pt As %Library.PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).OdbcToLogical(##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts))=pt
}

/// Compares a %FilemanTimeStamp to a %PosixTime value with the '= operator.
ClassMethod FMTSNEPT(fmts As %Library.FilemanTimeStamp, pt As %Library.PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).OdbcToLogical(##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts))'=pt
}

/// Compares a %FilemanTimeStamp to a %PosixTime value with the > operator.
ClassMethod FMTSGTPT(fmts As %Library.FilemanTimeStamp, pt As %Library.PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).OdbcToLogical(##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts))>pt
}

/// Compares a %FilemanTimeStamp to a %PosixTime value with the >= operator.
ClassMethod FMTSGEPT(fmts As %Library.FilemanTimeStamp, pt As %Library.PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).OdbcToLogical(##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts))>=pt
}

/// Compares a %FilemanTimeStamp to a %PosixTime value with the < operator.
ClassMethod FMTSLTPT(fmts As %Library.FilemanTimeStamp, pt As %Library.PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).OdbcToLogical(##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts))<pt
}

/// Compares a %FilemanTimeStamp to a %PosixTime value with the <= operator.
ClassMethod FMTSLEPT(fmts As %Library.FilemanTimeStamp, pt As %Library.PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).OdbcToLogical(##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts))<=pt
}

/// Compares a %FilemanTimeStamp to a %TimeStamp value with the = operator.
ClassMethod FMTSEQTS(fmts As %Library.FilemanTimeStamp, ts As %Library.TimeStamp) As %Boolean [ CodeMode = expression ]
{
##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts)=ts
}

/// Compares a %FilemanTimeStamp to a %TimeStamp value with the '= operator.
ClassMethod FMTSNETS(fmts As %Library.FilemanTimeStamp, ts As %Library.TimeStamp) As %Boolean [ CodeMode = expression ]
{
##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts)'=ts
}

/// Compares a %FilemanTimeStamp to a %TimeStamp value with the > operator.
ClassMethod FMTSGTTS(fmts As %Library.FilemanTimeStamp, ts As %Library.TimeStamp) As %Boolean [ CodeMode = expression ]
{
##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts)]]ts
}

/// Compares a %FilemanTimeStamp to a %TimeStamp value with the >= operator.
ClassMethod FMTSGETS(fmts As %Library.FilemanTimeStamp, ts As %Library.TimeStamp) As %Boolean [ CodeMode = expression ]
{
ts']]##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts)
}

/// Compares a %FilemanTimeStamp to a %TimeStamp value with the < operator.
ClassMethod FMTSLTTS(fmts As %Library.FilemanTimeStamp, ts As %Library.TimeStamp) As %Boolean [ CodeMode = expression ]
{
ts]]##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts)
}

/// Compares a %FilemanTimeStamp to a %TimeStamp value with the <= operator.
ClassMethod FMTSLETS(fmts As %Library.FilemanTimeStamp, ts As %Library.TimeStamp) As %Boolean [ CodeMode = expression ]
{
##class(%Library.FilemanTimeStamp).LogicalToOdbc(fmts)']]ts
}

/// Compares a %FilemanTimeStamp to a %Date value with the = operator.
ClassMethod FMTSEQDate(ts As %FilemanTimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(##class(%Library.FilemanTimeStamp).LogicalToOdbc(ts),3,,,,,-672045,,,"e")=$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %FilemanTimeStamp to a %Date value with the &gt; operator.
ClassMethod FMTSGTDate(ts As %FilemanTimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(##class(%Library.FilemanTimeStamp).LogicalToOdbc(ts),3,,,,,-672045,,,"e")>$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %FilemanTimeStamp to a %Date value with the '&lt; operator.
ClassMethod FMTSGEDate(ts As %FilemanTimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(##class(%Library.FilemanTimeStamp).LogicalToOdbc(ts),3,,,,,-672045,,,"e")'<$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %FilemanTimeStamp to a %Date value with the &lt; operator.
ClassMethod FMTSLTDate(ts As %FilemanTimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(##class(%Library.FilemanTimeStamp).LogicalToOdbc(ts),3,,,,,-672045,,,"e")<$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %FilemanTimeStamp to a %Date value with the '&gt; operator.
ClassMethod FMTSLEDate(ts As %FilemanTimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(##class(%Library.FilemanTimeStamp).LogicalToOdbc(ts),3,,,,,-672045,,,"e")'>$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %FilemanTimeStamp to a %Date value with the '= operator.
ClassMethod FMTSNEDate(ts As %FilemanTimeStamp, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(##class(%Library.FilemanTimeStamp).LogicalToOdbc(ts),3,,,,,-672045,,,"e")'=$zdatetimeh(d,3,,,,,-672045,,,d_",0")
}

/// Compares a %FilemanDate to a %Date value with the = operator.
ClassMethod FMDEQDate(fmd As %FilemanDate, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdateh(fmd+17000000,8,,,,,-672045)=d
}

/// Compares a %FilemanDate to a %Date value with the &gt; operator.
ClassMethod FMDGTDate(fmd As %FilemanDate, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdateh(fmd+17000000,8,,,,,-672045)>d
}

/// Compares a %FilemanDate to a %Date value with the '&lt; operator.
ClassMethod FMDGEDate(fmd As %FilemanDate, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdateh(fmd+17000000,8,,,,,-672045)'<d
}

/// Compares a %FilemanDate to a %Date value with the &lt; operator.
ClassMethod FMDLTDate(fmd As %FilemanDate, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdateh(fmd+17000000,8,,,,,-672045)<d
}

/// Compares a %FilemanDate to a %Date value with the '&gt; operator.
ClassMethod FMDLEDate(fmd As %FilemanDate, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdateh(fmd+17000000,8)'>d
}

/// Compares a %FilemanDate to a %Date value with the '= operator.
ClassMethod FMDNEDate(fmd As %FilemanDate, d As %Date) As %Boolean [ CodeMode = expression ]
{
$zdateh(fmd+17000000,8,,,,,-672045)'=d
}

/// These methods deal with comparing %Library.FilemanDate values with %Library.PosixTime
/// Compares a %FilemanDate to a %PosixTime value with the = operator.
ClassMethod FMDEQPT(fmd As %FilemanDate, pt As %PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).DateToLogical($zdateh(fmd+17000000,8,,,,,-672045))=pt
}

/// Compares a %FilemanDate to a %PosixTime value with the &gt; operator.
ClassMethod FMDGTPT(fmd As %FilemanDate, pt As %PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).DateToLogical($zdateh(fmd+17000000,8,,,,,-672045))>pt
}

/// Compares a %FilemanDate to a %PosixTime value with the '&lt; operator.
ClassMethod FMDGEPT(fmd As %FilemanDate, pt As %PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).DateToLogical($zdateh(fmd+17000000,8,,,,,-672045))>=pt
}

/// Compares a %FilemanDate to a %PosixTime value with the &lt; operator.
ClassMethod FMDLTPT(fmd As %FilemanDate, pt As %PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).DateToLogical($zdateh(fmd+17000000,8,,,,,-672045))<pt
}

/// Compares a %FilemanDate to a %PosixTime value with the '&gt; operator.
ClassMethod FMDLEPT(fmd As %FilemanDate, pt As %PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).DateToLogical($zdateh(fmd+17000000,8,,,,,-672045))<=pt
}

/// Compares a %FilemanDate to a %PosixTime value with the '= operator.
ClassMethod FMDNEPT(fmd As %FilemanDate, pt As %PosixTime) As %Boolean [ CodeMode = expression ]
{
##class(%Library.PosixTime).DateToLogical($zdateh(fmd+17000000,8,,,,,-672045))'=pt
}

/// These methods deal with comparing %Library.FilemanDate values with %Library.TimeStamp
/// Compares a %FilemanDate to a %TimeStamp value with the = operator.
ClassMethod FMDEQTS(fmd As %FilemanDate, ts As %TimeStamp) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh($zdateh(fmd+17000000,8,,,,,-672045),3,,,,,-672045,,,$zdateh(fmd+17000000,8,,,,,-672045)_",0")=$zdatetimeh(ts,3,,,,,-672045,,,"e")
}

/// Compares a %FilemanDate to a %TimeStamp value with the &gt; operator.
ClassMethod FMDGTTS(fmd As %FilemanDate, ts As %TimeStamp) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh($zdateh(fmd+17000000,8,,,,,-672045),3,,,,,-672045,,,$zdateh(fmd+17000000,8,,,,,-672045)_",0")>$zdatetimeh(ts,3,,,,,-672045,,,"e")
}

/// Compares a %FilemanDate to a %TimeStamp value with the '&lt; operator.
ClassMethod FMDGETS(fmd As %FilemanDate, ts As %TimeStamp) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh($zdateh(fmd+17000000,8,,,,,-672045),3,,,,,-672045,,,$zdateh(fmd+17000000,8,,,,,-672045)_",0")'<$zdatetimeh(ts,3,,,,,-672045,,,"e")
}

/// Compares a %FilemanDate to a %TimeStamp value with the &lt; operator.
ClassMethod FMDLTTS(fmd As %FilemanDate, ts As %TimeStamp) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh($zdateh(fmd+17000000,8,,,,,-672045),3,,,,,-672045,,,$zdateh(fmd+17000000,8,,,,,-672045)_",0")<$zdatetimeh(ts,3,,,,,-672045,,,"e")
}

/// Compares a %FilemanDate to a %TimeStamp value with the '&gt; operator.
ClassMethod FMDLETS(fmd As %FilemanDate, ts As %TimeStamp) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh($zdateh(fmd+17000000,8,,,,,-672045),3,,,,,-672045,,,$zdateh(fmd+17000000,8,,,,,-672045)_",0")'>$zdatetimeh(ts,3,,,,,-672045,,,"e")
}

/// Compares a %FilemanDate to a %TimeStamp value with the '= operator.
ClassMethod FMDNETS(fmd As %FilemanDate, ts As %TimeStamp) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh($zdateh(fmd+17000000,8,,,,,-672045),3,,,,,-672045,,,$zdateh(fmd+17000000,8,,,,,-672045)_",0")'=$zdatetimeh(ts,3,,,,,-672045,,,"e")
}

/// ----------------------
/// These methods deal with comparing %MV.Date values with %Library.Date
/// The MultiValue start date is 01/01/1968<br>
/// ObjectScript date is 01/01/1841<br>
/// <br>
/// To convert an ObjectScript date ($h) to a MultiValue date:<br>
/// MVdate = ObjectScript date - 46385 <br>
/// <br>
/// To convert a MultiValue date to an ObjectScript date:<br>
/// ObjectScript date = MVdate + 46385 <br>
/// ----------------------
/// Compares a %MV.Date to a %Date value with the = operator.
ClassMethod MVDEQDate(mvd As %MV.Date, d As %Date) As %Boolean [ CodeMode = expression ]
{
(mvd+46385)=d
}

/// Compares a %MV.Date to a %Date value with the &gt; operator.
ClassMethod MVDGTDate(mvd As %MV.Date, d As %Date) As %Boolean [ CodeMode = expression ]
{
(mvd+46385)>d
}

/// Compares a %MV.Date to a %Date value with the '&lt; operator.
ClassMethod MVDGEDate(mvd As %MV.Date, d As %Date) As %Boolean [ CodeMode = expression ]
{
(mvd+46385)'<d
}

/// Compares a %MV.Date to a %Date value with the &lt; operator.
ClassMethod MVDLTDate(mvd As %MV.Date, d As %Date) As %Boolean [ CodeMode = expression ]
{
(mvd+46385)<d
}

/// Compares a %MV.Date to a %Date value with the '&gt; operator.
ClassMethod MVDLEDate(mvd As %MV.Date, d As %Date) As %Boolean [ CodeMode = expression ]
{
(mvd+46385)'>d
}

/// Compares a %MV.Date to a %Date value with the '= operator.
ClassMethod MVDNEDate(mvd As %MV.Date, d As %Date) As %Boolean [ CodeMode = expression ]
{
(mvd+46385)'=d
}

/// ----------------------
/// These methods deal with comparing %MV.Date values with %Library.TimeStamp
/// ----------------------
/// Compares a %TimeStamp to a %MV.Date value with the = operator.
ClassMethod TSEQMVDate(ts As %TimeStamp, d As %MV.Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")=$zdatetimeh(d+46385,3,,,,,-672045,,,d+46385_",0")
}

/// Compares a %TimeStamp to a %MV.Date value with the &gt; operator.
ClassMethod TSGTMVDate(ts As %TimeStamp, d As %MV.Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")>$zdatetimeh(d+46385,3,,,,,-672045,,,d+46385_",0")
}

/// Compares a %TimeStamp to a %MV.Date value with the '&lt; operator.
ClassMethod TSGEMVDate(ts As %TimeStamp, d As %MV.Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")'<$zdatetimeh(d+46385,3,,,,,-672045,,,d+46385_",0")
}

/// Compares a %TimeStamp to a %MV.Date value with the &lt; operator.
ClassMethod TSLTMVDate(ts As %TimeStamp, d As %MV.Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")<$zdatetimeh(d+46385,3,,,,,-672045,,,d+46385_",0")
}

/// Compares a %TimeStamp to a %MV.Date value with the '&gt; operator.
ClassMethod TSLEMVDate(ts As %TimeStamp, d As %MV.Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")'>$zdatetimeh(d+46385,3,,,,,-672045,,,d+46385_",0")
}

/// Compares a %TimeStamp to a %MV.Date value with the '= operator.
ClassMethod TSNEMVDate(ts As %TimeStamp, d As %MV.Date) As %Boolean [ CodeMode = expression ]
{
$zdatetimeh(ts,3,,,,,-672045,,,"e")'=$zdatetimeh(d+46385,3,,,,,-672045,,,d+46385_",0")
}

}
