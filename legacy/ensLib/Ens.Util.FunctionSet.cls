/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class contains a set of utility methods that can be used
/// by Business Rules, DTL transforms and the like.
Class Ens.Util.FunctionSet [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/* NOTE: the names of these function arguments are used by
	the expression editor. DO NOT MODIFY THEM!
*/
/// Convert a string supplied in <var>value</var> to UPPER case.
ClassMethod ToUpper(value As %String = "") As %String [ CodeMode = expression, Final ]
{
$ZCVT(value,"U")
}

/// Convert a string supplied in <var>value</var> to lower case.
ClassMethod ToLower(value As %String = "") As %String [ CodeMode = expression, Final ]
{
$ZCVT(value,"L")
}

/// Get the length of a string. If <var>delimiter</var> is specified, return the number of substrings in <var>value</var>
/// based on the supplied <var>delimiter</var>.
ClassMethod Length(value As %String = "", delimiter As %String = "") As %String [ CodeMode = expression, Final ]
{
$S(""=delimiter:$Length(value),1:$Length(value,delimiter))
}

/// Look up the key specified by <var>value</var> in the lookup table specified by <var>table</var> and return the
/// lookup value associated with the input key value.
/// If the input key value is not found in the specified table, return <var>default</var>. If the <var>table</var> or the <var>value</var> argument is empty, the flag <var>defaultOnEmptyInput</var> determines
/// whether to return <var>default</var> or an empty string.
/// If <var>defaultOnEmptyInput</var> is:<ol>
/// <li>0 - Return empty string if <var>table</var> or <var>value</var> is empty. </li>
/// <li>1 - Return <var>default</var> if <var>table</var> is empty and <var>value</var> is not. Return empty string if <var>value</var> is empty. </li>
/// <li>2 - Return <var>default</var> if <var>value</var> is empty and <var>table</var> is not. Return empty string if <var>table</var> is empty. </li>
/// <li>3 - Return <var>default</var> if either <var>table</var> or <var>value</var> is empty. </li>
/// </ol> 
ClassMethod Lookup(table As %String = "", value As %String = "", default As %String = "", defaultOnEmptyInput As %Integer = 0) As %String [ CodeMode = expression, Final ]
{
$S($L(table)&&$L(value):$G(^Ens.LookupTable(table,value),default), (table=""&&'(defaultOnEmptyInput#2))||(value=""&&'(defaultOnEmptyInput\2#2)):"", 1:default)
}

/// Test if the key specified by <var>value</var> is defined within the lookup table specified by <var>table</var>.<br/>
/// Return true (1) if it is defined, and false (0) otherwise.
ClassMethod Exists(table As %String = "", value As %String = "") As %Boolean [ CodeMode = expression, Final ]
{
$S(((table="")||(value="")):0,1:''$D(^Ens.LookupTable(table,value)))
}

/// If <var>value</var> is true, returns the value of <var>true</var>
/// otherwise returns the value of <var>false</var>.
ClassMethod If(value As %String = "", true As %String = "", false As %String = "") As %String [ CodeMode = expression, Final ]
{
$S(value:true,1:false)
}

/// Perform a logical inversion. If <var>value</var> is true, return false, otherwise returns true.
ClassMethod Not(value As %String = "") As %String [ CodeMode = expression, Final ]
{
'value
}

/// Tests if the given <var>value</var> matches the regular expression <var>regex</var>
ClassMethod RegexMatch(value As %String, regex As %String) As %Boolean [ CodeMode = expression, Final ]
{
$match(value,regex)
}

/// Tests if the given <var>value</var> matches the <var>pattern</var> given in the ? operator pattern syntax
ClassMethod Matches(value As %String, pattern As %String) As %Boolean [ CodeMode = expression, Final, SqlName = Matches, SqlProc ]
{
$S(""=$g(pattern):""=$g(value), 1:$g(value)?@$g(pattern))
}

/// Tests if the given <var>value</var> matches the <var>pattern</var> given in the ? operator pattern syntax.
ClassMethod DoesNotMatch(value As %String, pattern As %String) As %Boolean [ CodeMode = expression, Final, SqlName = DoesNotMatch, SqlProc ]
{
'$S(""=$g(pattern):""=$g(value), 1:$g(value)?@$g(pattern))
}

/// Takes string <var>value</var>, returns the piece delimited by <var>delimiter</var> from <var>from</var> to <var>to</var>.
/// The default value for <var>delimiter</var> is "," and the default values for <var>from</var> and <var>to</var> are both 1.
/// See $Piece for further documentation.
/// An asterisk ('*') in <var>from</var> or <var>to</var> represents the number of delimited pieces in <var>value</var>.
ClassMethod Piece(value As %String = "", delimiter As %String = ",", from As %Integer = 1, to As %Integer = {from}) As %String [ CodeMode = expression, Final ]
{
$Piece(value,delimiter,$S(from'["*":from,1:$L(value,delimiter)+$TR(from,"*")),$S(to'["*":to,1:$L(value,delimiter)+$TR(to,"*")))
}

/// Takes string <var>value</var>, translates each occurrance of a character
/// in string <var>identifier</var> to the character at the corresponding position in string
/// <var>associator</var> and returns the result.
ClassMethod Translate(value As %String = "", identifier As %String = "", associator As %String = "") As %String [ CodeMode = expression, Final ]
{
$TR(value,identifier,associator)
}

/// Takes string <var>value</var>, removes characters matching categories specified in the <var>action</var>
/// template and the <var>remchar</var> string, excepting characters found in the <var>keepchar</var> string,
/// and returns the result.  See $ZStrip for further documentation.
ClassMethod Strip(value As %String = "", action As %String = "", remchar As %String = "", keepchar As %String = "") As %String [ CodeMode = expression, Final ]
{
$ZStrip(value,action,remchar,keepchar)
}

/// Takes string <var>value</var>, adds enough instances of <var>padchar</var> to lengthen the string to <var>padpos</var> characters.
/// If <var>padpos</var> is a negative value, the padding is prepended to the <var>value</var> string.
ClassMethod Pad(value As %String = "", padpos As %Integer = 10, padchar As %String = " ") As %String [ Final ]
{
	Set newval=""
	If padpos<0 { for i=$L(value)+padpos:1:-1 { Set newval=padchar_newval } Set newval=newval_value }
	Else { for i=$L(value)+1:1:padpos	{ Set newval=padchar_newval } Set newval=value_newval }
	quit newval
}

/// Takes string <var>value</var> representing a date/time value in format <var>informat</var> and converts it to
/// a date/time string in format <var>outformat</var>. Any %f elements in <var>outformat</var> will be replaced with
/// the <var>outf</var> string. If the input string does not match <var>informat</var>, it will be output unchanged.
/// The default for both input and output formats is ODBC format (%Q) in the server's local timezone.
ClassMethod ConvertDateTime(value As %String = "", informat As %String = "%Q", outformat As %String = "%Q", outf As %String = "") As %String [ Final ]
{
	Set newval=##class(Ens.Util.Time).ConvertDateTime(value,informat,outformat,outf,.pSC,1)
	Quit:$$$ISERR(pSC) value
	Quit newval
}

/// Returns a string representing a date/time value in format <var>format</var>. The default format is ODBC format (%Q) in the server's local timezone.
ClassMethod CurrentDateTime(format As %String = "%Q") As %String [ CodeMode = expression ]
{
##class(Ens.Util.Time).FormatDateTime(format)
}

/// Evaluate the state of the given <var>ScheduleSpec</var> string, named Schedule or Rule at the moment given by <var>ODBCDateTime</var>. <br/>
/// If <var>ScheduleSpec</var> begins with '@' it is a Schedule name or Rule name, otherwise a raw Schedule string. <br/>
/// If <var>ODBCDateTime</var> is blank, the evaluation is done for the current time.
ClassMethod Schedule(ScheduleSpec As %String = "", ODBCDateTime As %String = "") As %String [ CodeMode = expression, Final, SqlName = Schedule, SqlProc ]
{
##class(Ens.Util.Schedule).Evaluate(ScheduleSpec, ODBCDateTime)
}

/// Evaluate the return value of the rule specified in <var>RuleName</var> with the given <var>Context</var> object and the given <var>Activity</var> label for the Rule Log.
ClassMethod Rule(RuleName As %String, Context As %RegisteredObject, Activity As %String, pLogLevel As %String) As %String [ Final, SqlName = Rule, SqlProc ]
{
	Set tSC=##class(Ens.Rule.RuleDefinition).EvaluateRulesEx(RuleName, $G($$$JobSessionId), Context, $G(Activity,$S('$IsObject(Context):Context,1:$classname(Context))), .value, .reason,, .pLogLevel)
	Quit:$$$ISERR(tSC) ""
	Quit value
}

/// Takes string <var>value</var>, replaces occurrences of 
/// string <var>find</var> with the string <var>replace</var>
/// and returns the result.
ClassMethod ReplaceStr(value As %String = "", find As %String = "", replace As %String = "") As %String [ CodeMode = expression ]
{
$$replace^EnsUtil(.value,.find,.replace)
}

/// deprecated; legacy from class Ens.DataTransform
ClassMethod replace(value As %String = "", find As %String = "", replace As %String = "") As %String [ CodeMode = expression ]
{
$$replace^EnsUtil(.value,.find,.replace)
}

/// Returns the largest of the given values.
ClassMethod Max(value As %String = "", v2 As %String = "", v3 As %String = "", v4 As %String = "", v5 As %String = "", v6 As %String = "", v7 As %String = "", v8 As %String = "") As %String [ Final ]
{
	Set tVal = ""

	// copy inputs into an array
	Set:value'="" arr(1) = +value
	Set:v2'="" arr(2) = +v2
	Set:v3'="" arr(3) = +v3
	Set:v4'="" arr(4) = +v4
	Set:v5'="" arr(5) = +v5
	Set:v6'="" arr(6) = +v6
	Set:v7'="" arr(7) = +v7
	Set:v8'="" arr(8) = +v8
	
	For i=1:1:8 {
		Set:$D(arr(i)) tVal = $S(tVal="":arr(i),tVal>arr(i):tVal,1:arr(i))
	}
	
	Quit tVal
}

/// Returns the smallest of the given values.
ClassMethod Min(value As %String = "", v2 As %String = "", v3 As %String = "", v4 As %String = "", v5 As %String = "", v6 As %String = "", v7 As %String = "", v8 As %String = "") As %String [ Final ]
{
	Set tVal = ""

	// copy inputs into an array
	Set:value'="" arr(1) = +value
	Set:v2'="" arr(2) = +v2
	Set:v3'="" arr(3) = +v3
	Set:v4'="" arr(4) = +v4
	Set:v5'="" arr(5) = +v5
	Set:v6'="" arr(6) = +v6
	Set:v7'="" arr(7) = +v7
	Set:v8'="" arr(8) = +v8
	
	For i=1:1:8 {
		Set:$D(arr(i)) tVal = $S(tVal="":arr(i),tVal<arr(i):tVal,1:arr(i))
	}

	Quit tVal
}

/// Rounds off the given <var>value</var> to specified number of <var>digits</var> after the decimal point.
ClassMethod Round(value As %Float, digits As %Integer = 0) As %Float [ CodeMode = expression, Final ]
{
$FNumber(value,"",digits)
}

/// Returns a substring of a given <var>value</var>; starting with position <var>start</var> until position <var>end</var>.
/// Empty <var>start</var> will return <var>value</var> irrespective of <var>end</var>.
/// Specifying <var>start</var> position and omitting <var>end</var> position will return from <var>start</var> to the end of the string.
ClassMethod SubString(value As %String = "", start As %Integer = "", end As %Integer = "") As %String [ CodeMode = expression, Final ]
{
$S(start="":value,end="":$E(value,start,*),1:$E(value,start,end))
}

/// Tests if the given <var>value</var> is among the <var>items</var> in a comma-delimited string.
ClassMethod In(value As %String, items As %String) As %Boolean [ Final ]
{
	set value=$g(value),items=$g(items)
	If ",,"=$E(items,*-2,*-1) { Set (sep1,sep2)=$E(items,*), items=$E(items,1,*-3) }
	ElseIf ",,"=$E(items,*-3,*-2) { Set sep1=$E(items,*-1), sep2=$E(items,*), items=$E(items,1,*-4) }
	Else { Set (sep1,sep2)="," }
	Quit $S(items="":0, 1:(sep1_items_sep2) [ (sep1_value_sep2))
}

/// Tests if the given <var>value</var> is not among the <var>items</var> in a comma-delimited string.
ClassMethod NotIn(value As %String, items As %String) As %Boolean [ CodeMode = expression, Final ]
{
'..In(.value,.items)
}

/// Tests if the given <var>value</var> starts with the given <var>string</var>.
ClassMethod StartsWith(value As %String, string As %String) As %Boolean [ CodeMode = expression, Final ]
{
($E($g(value),1,$L($g(string)))=$g(string))
}

/// Tests if the given <var>value</var> does not start with the string in <var>start</var>.
ClassMethod DoesNotStartWith(value As %String, start As %String) As %Boolean [ CodeMode = expression, Final ]
{
'..StartsWith(.value, .start)
}

/// Tests if the given <var>value</var> contains the given <var>substring</var>.
ClassMethod Contains(value As %String, substring As %String) As %Boolean [ CodeMode = expression, Final ]
{
$S($g(value)'="":''$Find($g(value),$g(substring)),1:0)
}

/// Tests if the given <var>value</var> contains the given <var>substring</var>.
ClassMethod DoesNotContain(value As %String, substring As %String) As %Boolean [ CodeMode = expression, Final ]
{
'..Contains(.value, .substring)
}

/// Tests if the given <var>value</var> satisfies a SQL Like comparison with the given </var>pattern</var> string. In SQL Like patterns, % matches 0 or more characters, and _ matches any single character.
/// Note that an escape character can be specified by appending "%%<esc>" to the pattern, e.g. "#%SYSVAR_#_%%%#" to match any value string that starts with "%SYSVAR" followed by any single character, an underscore, and anything else.
ClassMethod Like(value As %String, pattern As %String) As %Boolean [ Final ]
{
	set value=$g(value),pattern=$g(pattern)
	If "%%"=$E(pattern,*-2,*-1) {
		Set esc=$E(pattern,*), pattern=$E(pattern,1,*-3)
	} Else { Set esc="" }
	
	Set patlen=$L(pattern),cospat="",(quotc,inquot)=0  For i=1:1:patlen { Set c=$E(pattern,i)
		If c=esc && (i<patlen) && 'quotc { Set quotc=1 }
		Else {
			Set:'quotc c=$Case(c,"%":".E","_":"1E",:c)
			If 1=$L(c) {
				Set:'inquot c="1"""_c, inquot=1
			} Else {
				Set:inquot c=""""_c, inquot=0 ; close quote
			}
			Set cospat=cospat_c, quotc=0
		}
	}
	Set:inquot cospat=cospat_"""" ; close quote
	Quit value?@cospat
}

/// Tests if the given <var>value</var> does not satisfy a SQL Like comparison with the given <var>pattern</var> string. In SQL Like patterns, % matches 0 or more characters, and _ matches any single character.
/// Note that an escape character can be specified by appending "%%<esc>" to the pattern, e.g. "#%SYSVAR_#_%%%#" to match any value string that starts with "%SYSVAR" followed by any single character, an underscore, and anything else.
ClassMethod NotLike(value As %String, pattern As %String) As %Boolean [ CodeMode = expression, Final ]
{
'..Like(.value, .pattern)
}

/// Tests if the given <var>value</var> is in the specified column in a table-formatted text file. <br/>
/// The <var>filenameSpec</var> argument consists of the filename followed by a comma and then a comma-separated list of additional parameters: <ol>
/// 	<li>columnPos (default = 1) - means character pos if positional, column ordinal if delimited. </li>
/// 	<li>rowSeparator (default = linefeed); negative value means row length if positional. </li>
/// 	<li>columnSeparator (default = tab) - zero value means positional columns. </li>
/// 	<li>columnWidth (default =0 meaning delimited not fixed-width) - means char count if positional. </li>
/// 	<li>lineComment (default = none)</li>
/// 	<li>stripPadChars (default = space,tab)</li></ol>
ClassMethod InFile(value As %String, filenameSpec As %String) As %Boolean [ Final, SqlName = InFile, SqlProc ]
{
	Set value=$g(value),filenameSpec=$g(filenameSpec)
	#; parse args - comma-delimited with '\' escape char for comma,\t,\n,\r.
	Set filename=$P(filenameSpec,",")
	Set i=1,(pos,lastpos)=$L(filename)+2  For { Set pos=$F(filenameSpec,",",pos)  Quit:'pos
		#; process escapes
		Set escpos=lastpos,esc=""  For { Set escpos=$F($E(filenameSpec,1,pos-1),"\",escpos)  Quit:'escpos
			Set $E(filenameSpec,escpos-1)="", esc=$E(filenameSpec,escpos-1), pos=pos-(esc'=",")
			Set $E(filenameSpec,escpos-1)=$Case(esc,"t":$C(9),"n":$C(10),"r":$C(13),:esc)
		}
		Continue:","=esc&&(escpos>lastpos)
		Set args(i)=$E(filenameSpec,lastpos,pos-2), i=i+1
		Set lastpos=pos
	} Set args(i)=$E(filenameSpec,lastpos,$L(filenameSpec))

	Set columnId=$G(args(1))  Set:""=columnId columnId=1
	Set rowSeparator=$G(args(2))  Set:""=rowSeparator rowSeparator=$C(10)
	Set columnSeparator=$G(args(3))  Set:""=columnSeparator columnSeparator=$C(9)
	Set columnWidth=$G(args(4))  Set:""=columnWidth columnWidth=0
	Set lineComment=$G(args(5))
	Set stripPadChars=$G(args(6))  Set:""=stripPadChars stripPadChars=" "_$C(9)

	#; Call the version that accepts regular args
	Quit ..InFileColumn(.value, filename, columnId, rowSeparator, columnSeparator, columnWidth, lineComment, stripPadChars)
}

/// Tests if the given <var>value</var> is in the column specified by <var>columnId</var> in a table-formatted text 
/// file specified by <var>filename</var>. <br/>
/// <var>rowSeparator</var> indicates what character sequence separates the rows in the file, but if the value is negative,
/// the value indicates the character length of each row. <br/>
/// <var>columnSeparator</var> indicates the character sequence used to separate columns. If the value of this argument is 0, 
/// then the value in the file is determined by extracting <var>columnWidth</var> characters starting at the character 
/// position <var>columnId</var>.
ClassMethod InFileColumn(value As %String = "", filename As %String = "", columnId As %Integer = 1, rowSeparator As %String = {$C(10)}, columnSeparator As %String = {$C(9)}, columnWidth As %Integer = 0, lineComment As %String = "", stripPadChars = {" "_$C(9)}) As %Boolean [ Final ]
{
	Quit:value="" 0
	Set file = ##class(%IO.FileStream).%New(filename)
	If '$IsObject(file)||'file.IsOpen Quit 0

	Set:rowSeparator>=0 file.LineTerminator=rowSeparator
	Set tCol=""  While 'file.AtEnd {
		If rowSeparator<0 { set tLine=file.Read(-rowSeparator) }
		Else { set tLine=file.ReadLine() }
		Continue:""=tLine
		Set tStrip=$S(""=stripPadChars:tLine,1:$ZStrip(tLine,"<>",stripPadChars))
		Continue:(""'=lineComment)&&(lineComment=$E(tStrip,1,$L(lineComment)))
		If columnSeparator=+columnSeparator&&(columnSeparator<=0) { Set tCol=$E(tLine,columnId,$S(columnWidth:columnId+columnWidth-1,1:$L(tLine))) }
		Else { Set tCol=$P(tLine,columnSeparator,columnId) }
		Set:(""'=lineComment&&(columnSeparator>0)) f=$F(tCol,lineComment), tCol=$S(f:$E(tCol,1,f-$L(lineComment)-1),1:tCol)
		Set:rowSeparator=$C(10)&&($E(tCol,$L(tCol))=$C(13)) $E(tCol,$L(tCol))=""
		Set:""'=stripPadChars tCol=$ZStrip(tCol,"<>",stripPadChars)
		Quit:value=tCol
	}
	Quit (value=tCol)
}

/// Tests if the given <var>value</var> is not in the specified column in a table-formatted text file.
/// See InFile() for a more detailed description of the options for <var>filenameSpec</var>.
ClassMethod NotInFile(value As %String, filenameSpec As %String) As %Boolean [ CodeMode = expression, Final, SqlName = NotInFile, SqlProc ]
{
'..InFile(.value, .filenameSpec)
}

/// Tests if any item from the given source list in <var>value</var> appears in the target list <var>items</var>. <br/>
/// A separator can be specified for the format of each list. By default the items in each list are assumed to be enclosed in angle brackets, e.g. "&lt;Item1&gt;&lt;Item2&gt;&lt;Item3&gt;". <br/>
/// Note: if the target list has only a single item this function is essentially the same as the Contains function. If the source list has only a single item this function is essentially the same as the In function.
ClassMethod IntersectsList(value As %String, items As %String, SourceListSeparator As %String = "><", TargetListSeparator As %String = "><") As %Boolean [ Final, SqlName = IntersectsList, SqlProc ]
{
	Set SourceList=$g(value), TargetList=$g(items)
	If $L(SourceListSeparator)>1 {
		Set sPreSep=$E(SourceListSeparator,*), sPostSep=$E(SourceListSeparator,1)
		Set:sPreSep=$E(SourceList) SourceList=$E(SourceList,2,*-(sPostSep=$E(SourceList,*)))
	} Else { Set (sPreSep,sPostSep)="" }
	If $L(TargetListSeparator)>1 {
		Set tPreSep=$E(TargetListSeparator,*), tPostSep=$E(TargetListSeparator,1)
		Set:tPreSep=$E(TargetList) TargetList=$E(TargetList,2,*-(tPostSep=$E(TargetList,*)))
	} Else { Set (tPreSep,tPostSep)="" }
	Set found=0,pos=""  For i=1:1 { Quit:pos=0  Set prev=pos, pos=$F(SourceList,SourceListSeparator,prev)
		Set item=$S(pos=0:$E(SourceList,prev,*), 1:$E(SourceList,prev,pos-1-$L(SourceListSeparator)))
		Set tpos=""  For j=1:1 { Quit:tpos=0  Set tprev=tpos, tpos=$F(TargetList,TargetListSeparator,tprev)
			Set titem=$S(tpos=0:$E(TargetList,tprev,*), 1:$E(TargetList,tprev,tpos-1-$L(TargetListSeparator)))
			If item=titem Set found=1  Quit
		}
		Quit:found
	}
	Quit found
}

/// Tests if the given source list, <var>value</var>, does not contain any item that is contained in the target list, <var>items</var>.
/// See IntersectsList() for description.
ClassMethod DoesNotIntersectList(value As %String, items As %String, SourceListSeparator As %String = "><", TargetListSeparator As %String = "><") As %Boolean [ CodeMode = expression, Final, SqlName = DoesNotIntersectList, SqlProc ]
{
'..IntersectsList(.value,.items,.SourceListSeparator,.TargetListSeparator)
}

}
