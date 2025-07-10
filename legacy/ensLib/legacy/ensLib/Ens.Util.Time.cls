/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occInclude)

/// This class provides utility methods related to Time.
Class Ens.Util.Time [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This call accepts a time value in either of the formats:
/// <ul>
/// <li>duration (<a target="_top" href="http://www.w3.org/TR/xmlschema-2/#duration">http://www.w3.org/TR/xmlschema-2/#duration</a>)</li>
/// <li>dateTime (<a target="_top" href="http://www.w3.org/TR/xmlschema-2/#dateTime">http://www.w3.org/TR/xmlschema-2/#dateTime</a>)</li>
/// </ul>
/// It returns the number of seconds until the specified time (via <var>pSeconds</var>).<br/>
/// If the time value is already a number of seconds, return it.
ClassMethod TimeoutToSeconds(pTimeout As %String, Output pSeconds As %Float) As %Status
{
	if pTimeout=+pTimeout set pSeconds=pTimeout quit $$$OK
	if $zcvt($e(pTimeout,1),"u")="P" {
		quit ..Duration(pTimeout,.pSeconds)
	} else {
		quit ..SecondsUntil(pTimeout,.pSeconds)
	}
}

/// Given a 'dateTime' value in the format, <a target="_top" href="http://www.w3.org/TR/xmlschema-2/#dateTime">http://www.w3.org/TR/xmlschema-2/#dateTime</a>
/// return the number of seconds until that instant (via <var>pSeconds</var>.
/// If the time instant has passed return 0.<br/> 
/// 'dateTime' format example:- 2003-06-06T09:30:00
ClassMethod SecondsUntil(pDateTime As %String, Output pSeconds As %Float) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tLen=$Length(pDateTime),tSeconds=0

		#; Discard the TimeZone piece ( we do not support it )
		If $Extract(pDateTime,tLen)="Z" {
			Set pDateTime=$Extract(pDateTime,1,tLen-1)
		} ElseIf $Case($Extract(pDateTime,tLen-5),"+":1,"-":1,:0) {
			Set pDateTime=$Extract(pDateTime,1,tLen-6)
		}
		#; Convert to $Horolog format
		Set tDateTime=$Tr(pDateTime,"T"," ")
		#; If Date hasn't been specified, default to today

		If $Piece(tDateTime," ")="" Set $Piece(tDateTime," ")=$Piece($ZDT($zdTH($zts,-3),3)," ")
		#; Compare tThen and tNow in UCT to account for DST
		Set tThen=$ZDT($zdTH(tDateTime,3,1,,,,,,,""),-3), tNow=$ZTS
		#; Convert then and now to seconds
		Set tThen=86400*$Piece(tThen,",",1)+$Piece(tThen,",",2)
		Set tNow=86400*$Piece(tNow,",",1)+$Piece(tNow,",",2)
		#; Return the number of seconds until the DateTime
		If tThen-tNow<0 {
			Set tSeconds=0
		} Else {
			Set tSeconds=tThen-tNow
		}
	} While 0
	#; Assign the output
	Set pSeconds=tSeconds
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	If $ZE["<ILLEGAL VALUE>" Set tSC=$$$EnsError($$$EnsErrInvalidDateTimeFormat)
	Goto Exit
}

/// Given a time duration in the format, 
/// <a target="_top" href="http://www.w3.org/TR/xmlschema-2/#duration">http://www.w3.org/TR/xmlschema-2/#duration</a>,
/// return the duration as a number of seconds (via <var>pSeconds</var>).<br/>
/// 'duration' format example: P1Y2M3DT10H30M3S <br/>
/// Only positive duration values are supported.
ClassMethod Duration(pDuration As %String, Output pSeconds As %Integer) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSeconds=0,pDuration=$ZCVT(pDuration,"U")

		#; Don't support negative durations
		If $Extract(pDuration)="-" Quit

		#; 'P' may be present, remove it
		If $Extract(pDuration)="P" Set $Extract(pDuration)=""

		#; Don't support fractional seconds
		Set pDuration=$Piece(pDuration,".",1)
		#; Walk duration string and calculate total number of seconds
		Set tSeconds=0,tThis=0,tTime=0 
		For tI=1:1:$Length(pDuration) {
			#; Pick out the character
			Set tChar=$Extract(pDuration,tI)
			If tChar?1N {
				#; It's a number
				Set tThis=tThis*10+tChar
			} Else {
				#; Detect (T)ime indicator
				If tChar="T" Set tTime=1,tThis=0 continue

				#; It's a multiplier
				If 'tTime {
					Set tMutiplier=$Case(tChar,"Y":31536000,"M":2592000,"D":86400)
				} Else {
					Set tMutiplier=$Case(tChar,"H":3600,"M":60,"S":1)
				}
				Set tSeconds=tSeconds+(tThis*tMutiplier)
				Set tThis=0
			}
		}
	} While 0
	#; Assign the output
	Set pSeconds=tSeconds
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	If $ZE["<ILLEGAL VALUE>" Set tSC=$$$EnsError($$$EnsErrInvalidDurationFormat)
	Goto Exit
}

/// Parse the given formatting tokens.<br/>
/// <var>pSpecIn</var> is the format string that describes the input.
ClassMethod parseSpec(pSpecIn As %String, ByRef pieces, opt As %Boolean) As %Status [ Internal ]
{
	//f is the position 
	Set (pieces,f)=0

	For { Set prevf=f, f=$F(pSpecIn,"%",f)  Quit:'f
		Set pieces=pieces+1
		Set pieces(pieces)=$G(pieces(pieces))_$E(pSpecIn,prevf,f-2)
		Set pieces(pieces,"spec")=$G(pieces(pieces,"spec"),0)

		Set:opt&&'pieces(pieces,"spec") pieces(pieces,"opt")=1
		For {
			#; first test for quoted chars
			Set ch=$E(pSpecIn,f)
				If $Case(ch,"%":1,"(":1,"-":1,:0) {
				If "-"=ch { Set opt=1  Set:'pieces(pieces,"spec") pieces=pieces-1 }
				ElseIf ""=ch||'pieces(pieces,"spec") { Set pieces(pieces)=pieces(pieces)_ch, pieces=pieces-1 } ; append the quoted char to the literal, keep adding to the literal
				Else { Set pieces(pieces+1)=ch } ; start a fresh spec node
				Set f=f+1
				Quit ; continue the outer loop
			}
			Set iSpec=pieces(pieces,"spec")+1, pieces(pieces,"spec")=iSpec
			Set pieces(pieces,"spec",iSpec)=ch, f=f+1
			Set:opt pieces(pieces,"spec",iSpec,"opt")=1
			// !!! put q handling in here
			//deal with a #; see what the next character is
			Set:"#"=ch ch=$E(pSpecIn,f), pieces(pieces,"spec",iSpec)=pieces(pieces,"spec",iSpec)_ch, f=f+1
			Set:"("=$E(pSpecIn,f) args=$P($E(pSpecIn,f+1,*),")"), pieces(pieces,"spec",iSpec,"args")=args, f=f+1+$L(args)+1
			Set ch=$E(pSpecIn,f) Quit:"%"'=ch
			Set f=f+1
		}
	}
	Quit:'pieces $$$OK
	Set tLastLiteral=$E(pSpecIn,prevf,*)
	Set:""'=tLastLiteral pieces=pieces+1, pieces(pieces)=tLastLiteral, pieces(pieces,"spec")=0
	Set:opt pieces(pieces,"opt")=1
	Do ..expandSpec(.pieces,1)
	Quit $$$OK
}

/*at this point, pUseFlex is always true...  !!! refactor */
ClassMethod expandSpec(ByRef pieces, pUseFlex As %Boolean = 0) As %Status [ Internal ]
{
	#; Expand expandable specs
	#; go through each spec- see if it needs to be expanded to something else
	Set (i,newi,lasti)="" For {
		If ""=newi {
			Set i=$O(pieces(i),1,lit)  Quit:""=i
			If ""'=lasti && 'pieces(lasti,"spec") { Set pieces(i)=pieces(lasti)_pieces(i)  Set:$G(pieces(lasti,"opt")) pieces(lasti,"opt")=1  Kill pieces(lasti) }
			Set lasti=i
			Set nextj=$O(pieces(i,"spec",""))
		} Else {
			#; Move old remaining i,j specs into newi
			Set:'pieces(newi,"spec") lasti=newi ; if the node is a literal only (no j's), then allow it to be merged with
			Set tnextj=nextj For { Set j=tnextj  Quit:""=j  Set tnextj=$O(pieces(i,"spec",j))
				Merge pieces(newi,"spec",j)=pieces(i,"spec",j)  Kill pieces(i,"spec",j)  Set pieces(newi,"spec")=pieces(newi,"spec")+1, pieces(i,"spec")=pieces(i,"spec")-1
			}
			Set i=newi, newi=""
		}
		For { Set j=nextj  Quit:""=j  Set nextj=$O(pieces(i,"spec",j))
			Set spec=pieces(i,"spec",j)
			If ((spec="q") || (spec="Q")){
				//deal with the q case, which can have varied arguments
				//if there are no args, then it's simple, else just look at the args,
				//as when there are args the q's are equivalent, but need to differentiate
				//between q() and Q() and Q (the last two are different..maybe: the spec is ambiguous);
				Set next= ""
				Set next = $O(pieces(i,"spec",j,next),1, value)
				If next="" {
					//there are no parens
					Set:"q"=spec exp="%Y%m%d%H%M%#S" 
					Set:"Q"=spec exp="%Y-%m-%d %H:%M:%S.%N"
				}
				If next = "args" {
					//there are parens
					Set exp = $Case(value
						, 0: "%Y%m%d%H%M%#S"
						, 1: "%Y-%m-%d %H:%M:%S.%N"
						, 2: "%Y-%m-%d"
						, 3: "q(3)"
						, 4: "q(4)"
						, 5: "%Y%m%d%H%M%S"
						,"":"%Y%m%d%H%M%#S" // empty parens...
						,:"" //default: do not parse when the arguments are not legal. !!! should post a message to the user
						)
				}
			} ElseIf (spec="c") {
				Set args = $G(pieces(i,"spec",j,"args"))
				Set exp = ..getCExpansion(args, .nLength)
			} Else {
				If ((spec="W") || (spec="#W")) {
					//get the args, if they exist:	(1 is the default)
					Set wArgs= $Get(pieces(i,"spec",j,"args"),1)
				}
				Set exp=$Case(spec
						,"C":$Case($G(pieces(i,"spec",j,"args"))
							,"":$S(pUseFlex:"%#m/%#d/%Y %#H:%M:%S", 1:"%m/%d/%Y %H:%M:%S")
							,:"")
						,"D":  "%m/%d/%y" 
						,"#D": "%#m/%#d/%y"
						,"#r": "%I:%M:%S%#p"
						,"r":  "%I:%M:%S %p"
						,"R":  "%H:%M"
						,"T":  $S(pUseFlex:"%H:%M:%S", 1:"%H:%M:%S")
						,"W":  "%U("_wArgs_")"
						,"#W": "%#U("_wArgs_")"
						,"x"  :$S(pUseFlex:"%#m/%#d/%Y", 1:"%m/%d/%Y")
						,"X":  $S(pUseFlex:"%#H:%M:%S", 1:"%H:%M:%S")
						,:"")
			}
			If ""'=exp {
				If ((exp="q(3)")||(exp="q(4)")) {
					Set pieces(i,"spec",j) = exp
				} Else {
					Do ..parseSpec(exp,.subtree,$G(pieces(i,"spec",j,"opt")))
					Kill pieces(i,"spec",j)
					Set ji="" For { Set ji=$O(subtree(ji),1,jilit)  Quit:""=ji
						If ""'=lasti { ; add literal and specs from subtree(ji) to old node
							Set pieces(lasti)=pieces(lasti)_jilit
						} Else { ; make newi node, copy subtree(ji) to it
							Set (newi,lasti)=i_"."_ji
							Set pieces(lasti)=jilit, pieces(lasti,"spec")=0
						}
						Set:$G(subtree(ji,"opt")) pieces(lasti,"opt")=1
						Set jj="" For { Set jj=$O(subtree(ji,"spec",jj))  Quit:""=jj
							Merge pieces(lasti,"spec",j_"."_jj)=subtree(ji,"spec",jj)  Set pieces(lasti,"spec") = pieces(lasti,"spec")+1
						}
						Set:pieces(lasti,"spec") lasti=""
					}
					Quit:""'=newi ; start over in outer loop where the rest of the j's will get attached to newi
				}
			}
			Set lasti=""
		}
	}
	Quit $$$OK
}

/// Convert a string in a particular date format(<var>pSpecIn</var>) to the format as described by <var>pSpecOut</var>.<br/>
/// If the token %f is used in <var>pSpecOut</var>, then %f is replaced by the string designated by <var>pFReplacementOut</var>,
/// and the status (or errors) are returned in <var>pSC</var>.<br/>
/// If <var>pAllowExtraValueChars</var> is false (the default) then the parsed time string  needs to exactly match the input spec.</br>
/// If true, then it is okay if the input has extra text left over at the end that wasn't exactly matched by the spec.<br/>
/// <br/>
/// This method essentially calls <method>ParseDateTime</method> on the initial String (<var>pValue</var>) to turn it into a time,
/// then calls <method>FormatDateTime</method> to convert the time into the desired output format.
/// Refer to the class documentation on these two methods for usage and limitations.<br/>
/// The important point is that there is currently a date range for parsing dates- it is from January 1, 1970 
/// through January 18, 2038. The exact times of the cutoff dates are Operating System dependent.
/// For more details see <method>ParseDateTime</method>.
ClassMethod ConvertDateTime(pValue As %String, pSpecIn As %String, pSpecOut As %String, pFReplacementOut As %String, Output pSC As %Status, pAllowExtraValueChars As %Boolean) As %String
{
	If $G(pSpecOut)="" Set pSC = $$$ERROR($$$EnsErrGeneral,"No output format was provided")  Quit ""
	#; If the input and output are in the same timezone, force it to UTC time so as to avoid timezone conversions that may hit OS restrictions
	Set:"%K"'=$E(pSpecOut,1,2)&&(""'=$G(pSpecIn))&&("%K"'=$E(pSpecIn,1,2)) pSpecIn="%K(UTC)"_pSpecIn, pSpecOut="%K(UTC)"_pSpecOut
	Set tUTCODBC=..ParseDateTime(.pValue, pSpecIn, .pSC, .pAllowExtraValueChars)  Quit:$$$ISERR(pSC) ""
	$$$ASSERT(""'=tUTCODBC)
	Quit ..FormatDateTime(pSpecOut,.pFReplacementOut,tUTCODBC)
}

/// Parse the given <var>pValue</var> according to a format string <var>pSpecIn</var>.<br/>
/// Returns a time string in the UTC time zone (Universal Coordinated Time a.k.a. GMT / Greenwich Mean Time)
/// in ODBC format (YYYY-MM-DD), or empty string if <var>pValue</var> cannot be parsed.
/// <br/>
/// Note:  the $$$timeLocaltoUTC macro removes any fractional second precision beyond three digits.
/// Also: tz (timezone) is set to "server" by default, so when timeLocalToUTC() is called, it only accepts dates between
/// January 1, 1970 ($HOROLOG = 47117,00000) through January 18, 2038 ($HOROLOG = 71971,86399). This is because 
/// zutil(193) is used; any dates outside of this range causes an Illegal Value error. This is an operating system
/// limitation.(<i>this paragraph also appears in the documentation</i>).
/// <br/>
/// The <var>pSpec</var> argument may contain literal characters, and any of the following format codes to represent time
/// fields to be parsed. It is composed of zero or more format codes. Each format code is composed of one of the following:
/// <ul>
/// <li>one or more white-space characters</li>
/// <li>an ordinary character (neither '%' nor a white-space character)</li>
/// <li>a format code.</li>
/// </ul>
/// <br/>
/// Each format code is composed of a '%' character followed by a conversion character that specifies how to interpret the
/// input value text at that position. Format codes of indeterminate length must be preceded by literal text or format
/// codes of fixed size, and must be followed by literal text or end-of-text.
/// <br/>
/// For example, when using a day of the month that could be either one or two characters(the 5th of july, or the 30th); the date
/// can be represented as 7/5/2007.  since there is a slash after the 5; that day can be separated and parsed out from the other 
/// numbers.  however, for the date 1/2/1975; without slashes-121975; the date could be misconstrued as december 19, 1975 instead
/// of january 2, 1975.  Therefore, when fields do not have delimiters only fixed length fields can be used, 01021975 would be a valid
/// way to get enter the date without delimiters such as slashes.
/// <br/>
/// Even if zeros are used (as in the prior example), indeterminite length fields must have delimiters for this code to function properly.
/// <br/>
/// The following format codes are supported:<br/>
/// Base timezone to convert to before formatting (supported only at the beginning of the format spec string)<br>
/// <table><tr style="text-align:left"><th> code </th><th> Description </th></tr>
/// <tr><td> %K(&lt;tz&gt;)</td><td> Timezone offset, &lt;tz&gt; values (case insensitive):</td></tr>
/// <tr><td> Server</td><td>  (default) time on the server where the executing code resides.</td></tr>
/// <tr><td> UTC</td><td>      Universal Time Coordinated (a.k.a. GMT / Greenwich Mean Time)</td></tr>
/// <tr><td> [+]n</td><td>     number of hours after (east of) UTC time (may be fractional)</td></tr>
/// <tr><td> -n</td><td>       number of hours before (west of) UTC time (may be fractional)</td></tr>
/// <tr><td> [+]hhmm</td><td>  hours and minutes after (east of) UTC time (in the ISO 8601:2000 standard format)</td></tr>
/// <tr><td> -hhmm</td><td>    hours and minutes after (west of) UTC time</td></tr></table>
/// <br/>
/// Date and Time Expansion:<br/>
/// <br/>
/// <table><tr style="text-align:left"><th> code </th><th> Description </th></tr>
/// <tr><td> %a</td><td> day of the week using the locale's weekday names; either the abbreviated or full name will be matched. </td></tr>
/// <tr><td> %A</td><td> equivalent to %a. </td></tr>
/// <tr><td> %b</td><td> month using the locale's month names; either the abbreviated or full name will be matched. </td></tr>
/// <tr><td> %B</td><td> equivalent to %b. </td></tr>
/// <tr><td> %c</td><td> equivalent to c(1,1,3)</td></tr>
/// <tr><td> %c(&lt;df&gt;,&lt;tf&gt;,&lt;sp&gt;)</td><td> date/time formatted according to $ZDateTime() date 'dformat', time 'tformat', and sub-second 'precision'</td></tr>
/// <tr><td> %C</td><td> equivalent to %c</td></tr>
/// <tr><td> %d</td><td> day of the month as a 2-digit number (01-31)</td></tr>
/// <tr><td> %#d</td><td> day of the month as a number (1-31); leading zeros not required</td></tr>
/// <tr><td> %D</td><td> date; equivalent to %m / %d / %y </td></tr>
/// <tr><td> %#D</td><td> date; equivalent to %#m / %#d / %y</td></tr>
/// <tr><td> %h</td><td> equivalent to %b</td></tr>
/// <tr><td> %H</td><td> hour in 24-hour format as a 2-digit number (00-23)</td></tr>
/// <tr><td> %#H</td><td> hour in 24-hour format as a number (0-23); leading zeros not required</td></tr>
/// <tr><td> %I</td><td> hour in 12-hour format as a 2-digit number (01-12)</td></tr>
/// <tr><td> %#I</td><td> hour in 12-hour format as a number (1-12); leading zeros not required</td></tr>
/// <tr><td> %j</td><td> day of the year as a 3-digit number (001-366)</td></tr>
/// <tr><td> %#j</td><td> day of the year as a number (1-366); leading zeros not required</td></tr>
/// <tr><td> %K(&lt;tz&gt;)</td><td> timezone to use to convert time for display, see above. Produces no output; supported only at the beginning of the format spec string.</td></tr>
/// <tr><td> %m</td><td> month as a 2-digit number (01-12)</td></tr>
/// <tr><td> %#m</td><td> month as number (1-12); leading zeros not required</td></tr>
/// <tr><td> %M</td><td> minute as a 2-digit number (00-59)</td></tr>
/// <tr><td> %#M</td><td> minute as number (0-59); leading zeros not required</td></tr>
/// <tr><td> %N</td><td> fractional second in milliseconds as number (000-999)</td></tr>
/// <tr><td> %N(&lt;num&gt;)</td><td> same as above (fractional part of a second), but the input number indicates the number of digits that </td></tr>
/// <tr><td> the</td><td> fraction uses, three is the default if there are no args.  </td></tr>
/// <tr><td> %p</td><td> locale's equivalent of a.m. or p.m.; either lowercase or uppercase will be matched. </td></tr>
/// <tr><td> %#p</td><td> locale's equivalent of am or pm (without dots); either lowercase or uppercase will be matched. </td></tr>
/// <tr><td> %P</td><td> equivalent to %p</td></tr>
/// <tr><td> %#P</td><td> equivalent to %#p</td></tr>
/// <tr><td> %q</td><td> equivalent to %q() or %q(0)</td></tr>
/// <tr><td> %q(0)</td><td> HL7 format date/time; equivalent to %Y%m%d%H%M%#S with seconds optional</td></tr>
/// <tr><td> %q(1)</td><td> ODBC format date/time; equivalent to %Y-%m-%d %H:%M:%S.%N</td></tr>
/// <tr><td> %q(2)</td><td> ISO 8601:2000 standard date format; equivalent to %Y-%m-%d</td></tr>
/// <tr><td> %q(3)</td><td> $Horolog format</td></tr>
/// <tr><td> %q(4)</td><td> $ZTimestamp format</td></tr>
/// <tr><td> %q(5)</td><td> HL7 format date/time; equivalent to %Y%m%d%H%M%S with seconds required</td></tr>
/// <tr><td> %Q</td><td> ODBC format date/time; equivalent to %c(3,,3) or %q(1)</td></tr>
/// <tr><td> %Q(n)</td><td> equivalent to %q(n)</td></tr>
/// <tr><td> %r</td><td> time with seconds in 12-hour format using a.m./p.m. notation; equivalent to %I:%M:%S %p</td></tr>
/// <tr><td> %#r</td><td> time with seconds in 12-hour format using am/pm notation without whitespace or dots; equivalent to %I:%M:%S%#p</td></tr>
/// <tr><td> %R</td><td> time in 24-hour notation; equivalent to %H:%M</td></tr>
/// <tr><td> %S</td><td> seconds as a 2-digit number (00-60) (60 for leap seconds)</td></tr>
/// <tr><td> %#S</td><td> optionally appearing seconds as a 0, 1, or 2 digit number (0-60) (60 for leap seconds)</td></tr>
/// <tr><td> %t</td><td> any white space. </td></tr>
/// <tr><td> %T</td><td> time with seconds in 24-hour notation; equivalent to %H:%M:%S</td></tr>
/// <tr><td> %u</td><td> day of the week as a number (1-7), with 1 representing Monday. </td></tr>
/// <tr><td> %#u</td><td> equivalent to %u</td></tr>
/// <tr><td> %U</td><td> week of year as a number, with Sunday as first day of week (00-53); equivalent to %U(0). The first Sunday of January is the first day of week 1; days in the new year before this are in week 0.</td></tr>
/// <tr><td> %U(&lt;dow&gt;)</td><td> week of the year as a number, starting on the given DayOfWeek (Sunday=0)</td></tr>
/// <tr><td> %#U</td><td> week of the year as a number, with Sunday as first day of week (00-53); leading zeros not required; equivalent to %#U(0)</td></tr>
/// <tr><td> %#U(&lt;dow&gt;)</td><td> week of the year as a number, starting on the given DayOfWeek (Sunday=0); leading zeros not required</td></tr>
/// <tr><td> %w</td><td> day of the week as a number (0-6; Sunday is 0)</td></tr>
/// <tr><td> %#w</td><td> equivalent to %w</td></tr>
/// <tr><td> %W</td><td> week of the year as a number (00-53); equivalent to %U(1). The first Monday of January is the first day of week 1; days in the new year before this are in week 0.</td></tr>
/// <tr><td> %W(&lt;dow&gt;)</td><td> equivalent to %U(&lt;dow&gt;)</td></tr>
/// <tr><td> %#W</td><td> week of the year as a number (0-53); leading zeros not required, equivalent to %#U(1).</td></tr>
/// <tr><td> %#W(&lt;dow&gt;)</td><td> equivalent to %#U(&lt;dow&gt;)</td></tr>
/// <tr><td> %y</td><td> year within a century as a number (00-99). When the century is not otherwise specified, the method FixCentury() is called to resolve it.</td></tr>
/// <tr><td> %Y</td><td> year including the century, as a 4-digit number (0000-9999)</td></tr>
/// <tr><td> %z</td><td> timezone offset from UTC in the ISO 8601:2000 standard format ( +hhmm or -hhmm ). For example, "-0430" means 4 hours 30 minutes behind UTC (west of Greenwich)</td></tr>
/// <tr><td> %#z</td><td> timezone offset from UTC in hours with leading +/- and without leading or trailing zeros; trailing decimals may appear ( +h.nnn or -h.nnn ) For example, "-4.5" means 4 hours 30 minutes behind UTC (west of Greenwich)</td></tr>
/// <tr><td> %%</td><td> Literal % percent sign</td></tr>
/// <tr><td> %(</td><td> Literal ( left parenthesis</td></tr></table>
ClassMethod ParseDateTime(pValue As %String, pSpecIn As %String, Output pSC As %Status, pAllowExtraValueChars As %Boolean = 0) As %String
{
 /*
these parts are in the spec that this code was based on, but are not supported yet:

Base locale to use with locale-dependent format codes. (supported only at the beginning of the format spec string)
   %L(<locale>) Locale specifier; <locale> values (case insensitive):
       POSIX    (default) use the standard POSIX locale.
       Server   use the executing server's installed default locale
   %-    at any point in the spec means that all parts following it are optional
   %e    day of the month as a number padded with a leading space character ( 1-31)
   %#e   day of the month as a number with leading whitespace and/or zeros allowed (1-31)
   %f    match any upper or lowercase text, including digits and punctuation
   %F    match any uppercase text, including digits and punctuation
   %g    last 2 digits of the week-based year as a 2-digit number (00-99); see description under FormatDateTime
   %#g   last 2 digits of the week-based year as a number (0-99); leading zeros not required; see description under FormatDateTime
   %G    week-based year as a 4-digit number (0000-9999); see description under FormatDateTime
   %#G   week-based year as a number (0-9999); leading zeros not required; see description under FormatDateTime 
   %n    any white space. 
   %#N   fractional second in milliseconds as number (0-999); leading zeros not required
   %#S   second as a number (0-60) ; leading zeros not required
   %V    week of week-based year as a number (01-53); see description under FormatDateTime
   %#V   week of week-based year as a number (1-53); leading zeros not required
   %x    date representation for locale (See the Base Definitions volume of IEEE Std 1003.1-2001)
   %X    time representation for locale (See the Base Definitions volume of IEEE Std 1003.1-2001)
   %#y   year within a century as a number (0-99); leading zeros not required
   %#Y   year including the century, as a number (0-9999); leading zeros not required
   %Z    timezone name or abbreviation, or empty string if no timezone information is available.
 */
	If $G(pValue)="" Set pSC=$$$ERROR($$$EnsErrGeneral,"No value to be parsed/converted was provided")  Quit ""
	If $G(pSpecIn)="" Set pSC=$$$ERROR($$$EnsErrGeneral,"No input format was provided")  Quit ""

	Set pSC=$$$OK
	#; is a timezone being used?
	If "%K"=$E(pSpecIn,1,2) {
		If "("=$E(pSpecIn,3) {
			Set tz=$ZCVT($ZStrip($P($E(pSpecIn,4,*),")"),"<>W"),"L")
			Set f=5+$L(tz)
			Set tzSign=$Case($E(tz),"+":1,"-":1,:0)
			Set:$IsValidNum(tz)&&(tz'[".")&&($L(tz)-tzSign>2) mm=$E(tz,*-1,*), tz=$E(tz,1,*-2)_$S(+mm=0:"",mm>=60:"",1:mm/60)
			Set:""=$tr(tz,"+-0.")&&$L(tz) tz=0
		} Else { Set tz="server", f=3 }
	} Else { Set tz="", f=1 }

	Do ..parseSpec($E(pSpecIn,f,*),.pieces,0) 
	Quit:'pieces ""

	#; Walk the literals, matching the contained specs
	#; note: when no year is given, the current year is used.
	#; firstdayOfWeek used when getting which week of the year- when U or W is specified
	Set (Y,yy,dow,doy,woy,ampm,H12,Z)="", (m,d)="01", (H,M,S)="00", N="000",firstdayOfWeek = "0"
	Set pos=1, valLen=$L(pValue)
	Set k="" 
	Do { 
		Set prevk=k, k=$O(pieces(k),1,lit)  Set:""=k lit="" //while at end: While k'="" && (prev <= valLen) && $$$ISOK(pSC)
		Set prev=pos
		If ""'=lit {
			Set pos=$Find(pValue,lit,prev)
			If pos { Set epos=pos-$L(lit) }
			Else { 
				If '$G(pieces(k,"opt")) Set pSC=$$$ERROR($$$EnsErrGeneral,"Required literal '"_lit_"' not satisfied after '"_$E(pValue,1,prev-1)_"'")  Quit
				Set (pos,epos)=valLen+1
			}
		} ElseIf ""=k { Set (pos,epos)=valLen+1 }
			Continue:""=prevk
			Set s="" While $$$ISOK(pSC) { Set s=$O(pieces(prevk,"spec",s),1,spec) Quit:""=s
				Quit:prev>=epos
				Set opt=$G(pieces(prevk,"spec",s,"opt"),0)
				Set args=$G(pieces(prevk,"spec",s,"args"))
				Set valid=1

				GoTo $Case(spec
				,"a":getWeekdayAbbrev
				,"A":getWeekdayFull
				,"b":getMonthAbbrev
				,"B":getMonthFull
				,"d":getDayOfMonth
				,"#d":getDayOfMonthZeroAllowed
				,"h":getMonthAbbrev
				,"H":getHour
				,"#H":getHourZeroAllowed
				,"I":getHour12
				,"#I":getHour12ZeroAllowed
				,"j":getDayOfYear
				,"#j":getPaddedDayOfYear
				,"m":getMonth
				,"#m":getMonthZeroAllowed
				,"M":getMinute
				,"#M":getMinuteZeroAllowed
				,"N":getMillis
				,"p":getAMPMWithDots
				,"#p":getAMPM
				,"P":getAMPMWithDots
				,"#P":getAMPM
				,"q(3)":getHorologFormat
				,"q(4)":getZdatetimeFormat
				,"S":getSecs
				,"#S":getSecsVariableLength
				,"u":getMondayBasedDayOfWeek
				,"#u":getMondayBasedDayOfWeek
				,"#U":getWeekOfYearWithArgsZeroAllowed
				,"U":getWeekOfYearWithArgs
				,"w":getDayOfWeek
				,"#w":getDayOfWeek
				,"y":getYear2
				,"Y":getYear4
				,"z":getTimezoneMins
				,"#z":getTimezoneFrac
				,"Z":getTimezoneName
				,:getX)
parseNext
		} //end while $$$isok loop
		If prev<epos && $L(lit) && $$$ISOK(pSC) { Set pSC=$$$ERROR($$$EnsErrGeneral,"Extra text '"_$E(pValue,prev,epos-1)_"' not parsed before end marker '"_lit_"'")  Quit }
	} While k'="" && (prev <= valLen) && $$$ISOK(pSC)

	#; return errors for incomplete or overlong pValue string
	Quit:$$$ISERR(pSC) ""
	If ""'=s && (""'=prevk) && '$G(pieces(prevk,"spec",s,"opt")) && '(spec="#S") {
		Set pSC=$$$ERROR($$$EnsErrGeneral,"Required spec '%"_pieces(prevk,"spec",s)_"' not satisfied after '"_$E(pValue,1,prev-1)_"'") 
		Quit ""
	}
	If ""'=k && (""'=pieces(k)) && '$G(pieces(k,"opt")) && '(spec="#S") {
		Set pSC=$$$ERROR($$$EnsErrGeneral,"Required literal '"_pieces(k)_"' not satisfied after '"_$E(pValue,1,prev-1)_"'")  
		Quit ""
	}
	If prev<valLen&&'pAllowExtraValueChars {
		Set pSC=$$$ERROR($$$EnsErrGeneral,"Extra text '"_$E(pValue,prev,valLen)_"' not parsed after exhausting spec '"_pSpecIn_"'")  
		Quit ""
	}

	// canonical form e.g. 2006-02-01 03:53:21.890
	Set:""=Y&&(""'=yy) Y=..FixCentury(yy) ; %Y overrides %y
	//now, check if Y is empty; if so then set it to the current year:
	if (Y="") {
		//set Y = $E($ZDate(2,8),1,4) //use the second day- as zero time is 12/31/1840;
		set Y = "1970" //use 1970 as the zero year, since the functions that use this year rely on unix time
	}

	//H is automatically set to 00 so test for that not empty string
	If "00"=H&&(""'=H12)&&(""'=ampm) Set H=H12+(ampm*12) Set:H=12 H="00" Set:H=24 H="12" ; %H overrides %I/%P
	// pad the H with zero as 05:30 am yields H==5
	Set:$L(H)=1 H="0"_H

	//dow,woy
	//first day of week is the day that is the first of the week (0 = sunday, 1 = monday, ...6= saturday)
	//while day of week specifies which day of that week (0 = sunday, 1 = monday...6= saturday) is wanted.
	//these are 2 different numbers

	//week of year is checked first; day of week is only parsed when week of year is present; otherwise it is discarded.
	//if week of year is not present, then day of year is checked; (it is assumed that the two would never be together)
	//and then after that, the default month-day-year parsing is done. 

	//ie, woy and dow together:
	//like: "week 1, monday"
	If (woy '= "") {
		Set jan1 = "1/1/"_Y
		//find out the day of the week of jan1:
		Set jan1dow = ..ConvertDateTime(jan1,"%#m/%#d/%Y","%w")

		//now, find out which day of the week the week starts on, and update the starting time accordingly:
		Set:""=dow dow=0

		//jan1dow will be an int, as will dow;
		//what's the difference? this adjusts for when the first week actually starts
		Set jan1plus = ..getDayDifference(firstdayOfWeek, jan1dow)

		If (woy >=0) {
			//this adjusts for which day of the week is requested
			Set correctDay = ..getDayDifference(dow,firstdayOfWeek)
			//woy = 0 already handled, then seven will get subtracted from the first day
			//of the week (which is $ZDateH(jan1) + jan1plus)  
			Set days = $ZDateH(jan1) + jan1plus + (7*(woy-1)) + correctDay

			Set t = $ZDate(days,3)_" "_H_":"_M_":"_S_"."_N
		} Else {
			//create an error; as woy needs to be an integer greater than or equal to zero
			Set t=""
		}
	} ElseIf (doy '="") {
		//if day of year is set, and month and day are still the default:
		//found out the appropriate month and day values for the doy amount given:

		//do this using the zdate function, given that the number returned is the number of days since 1840; 
		//so can do simple arithmetic to make a date given the day of the year
		Set days = $ZDateH("1/1/"_Y) + doy - 1 //-1 for fence posting 

		Set t = $ZDate(days,3)_" "_H_":"_M_":"_S_"."_N

		} Else { //the default
			Set t=Y_"-"_m_"-"_d_" "_H_":"_M_":"_S_"."_N
		}

	//if there aren't 19 chars before the . (dot); then quit with empty string and an error
	If $L($P(t,"."))'=19 Set pSC=$$$ERROR($$$EnsErrGeneral,"Intermediate time string '"_t_"' is not valid")  Quit ""

	// tz (timezone) is 'server' by default, so  timeLocalToUTC() is called, which may only accept dates between
	// January 1, 1970 ($HOROLOG = 47117,00000) through January 18, 2038 ($HOROLOG = 71971,86399) depending on the OS.
	// This is because zutil(193) is used; any dates outside of this range causes an <ILLEGAL VALUE> error; this is 
	// an operating system limitation.
	Set:tz="" tz=Z ; %K overrides %Z	
	Set t=$Case(tz
		,"":$$$timeLocaltoUTC(t)
		,"server":$$$timeLocaltoUTC(t)
		,"utc":t
		,:$S(+tz=0:t, 1:$$$timeUTCHtoUTC($$HorologAddSecs^EnsUtil($$$timeUTCtoUTCH(t),-tz*3600))))
	Quit t

notThere
	Set:'opt pSC=$$$ERROR($$$EnsErrGeneral,$S('valid:"Found invalid value "_$E(pValue,prev,valLen)_" for", 1:"Found end-of-text after '"_$E(pValue,prev,epos-1)_"' before satisfying")_" spec '%"_spec_$S(""=args:"",1:"("_args_")")_"'")
	Goto parseNext
getX
	Set error=1
	Goto parseNext
getWeekdayAbbrev
getWeekdayFull
	//parse the day of the week into a number; set to the dow variable: day of the week
	GoTo:prev+1>=epos notThere
	Set dow=$Case($ZCVT($E(pValue,prev,prev+1),"L")
			,"su":0, "mo":1, "tu":2, "we":3, "th":4, "fr":5, "sa":6, :"")
	Set valid=(""'=dow)  GoTo:'valid notThere
	// !!!look for digits...
	Set prev=epos ; no support yet for run-together words
	Goto parseNext
getMonthAbbrev
getMonthFull
	GoTo:prev+2>=epos notThere
	//prev line: make sure that the two required strings are there

	//convert the first two characters (being set to m) to lower case:
	Set m=$Case($ZCVT($E(pValue,prev,prev+2),"L")
			,"jan":"01", "feb":"02", "mar":"03", "apr":"04", "may":"05", "jun":"06", "jul":"07", "aug":"08", "sep":"09", "oct":"10", "nov":"11", "dec":"12",:"")
	Set valid=(""'=m)  GoTo:'valid notThere
	// !!!look for digits...
	Set prev=epos ; no support yet for run-together words
	Goto parseNext
getDayOfMonth
	GoTo:prev+1>=epos notThere
	Set d=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(d)&&(d>=1)&&(d<=31)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getDayOfMonthZeroAllowed
	GoTo:$$isNotOneOrTwoChars(prev,epos) notThere
	Set d=$E(pValue,prev,(epos-1))
	set d = $$maybePadWithZero(d)
	Set valid=$IsValidNum(d)&&(d>=1)&&(d<=31)  GoTo:'valid notThere
	Set prev=epos+1
	Goto parseNext
getHour
	GoTo:prev+1>=epos notThere
	Set H=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(H)&&(H>=0)&&(H<=23)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getHourZeroAllowed
	GoTo:$$isNotOneOrTwoChars(prev,epos) notThere
	Set H=$E(pValue,prev,epos-1)
	set H = $$maybePadWithZero(H)
	Set valid=$IsValidNum(H)&&(H>=0)&&(H<=23)  GoTo:'valid notThere
	Set prev=epos
	Goto parseNext
getHour12
	GoTo:prev+1>=epos notThere
	Set H12=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(H12)&&(H12>=1)&&(H12<=12)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getHour12ZeroAllowed
	//could be 1 or 2 chars
	//has to be at least one, or at most 2
	//epos is after the last char; at the :
	GoTo:$$isNotOneOrTwoChars(prev,epos) notThere
	Set H12 = $E(pValue,prev,(epos-1))
	//it can't be zero since it is 12 based; only 24 hour clocks can have a 
	//zero as the hour
	Set valid=$IsValidNum(H12)&&(H12>=1)&&(H12<=12)  GoTo:'valid notThere
	Set prev=epos+1
	Goto parseNext
getDayOfYear
	GoTo:prev+2>=epos notThere
	Set doy=$E(pValue,prev,prev+2)
	Set valid=$IsValidNum(doy)&&(doy>=1)&&(doy<=366)  GoTo:'valid&&'opt notThere
	Set prev=prev+3
	Goto parseNext
getPaddedDayOfYear
	GoTo:$$IsNotOneTwoOrThreeChars(prev,epos) notThere
	Set doy=$E(pValue,prev,(epos-1))
	Set valid=$IsValidNum(doy)&&(doy>=1)&&(doy<=366)  GoTo:'valid&&'opt notThere
	set doy = $$$NUM(doy, 3) //pad it to three chars
	Set prev=epos + 1
	Goto parseNext
getMonth
	GoTo:prev+1>=epos notThere
	Set m=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(m)&&(m>=1)&&(m<=12)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getMonthZeroAllowed
	GoTo:$$isNotOneOrTwoChars(prev,epos) notThere
	Set m=$E(pValue,prev,(epos-1))
	set m = $$maybePadWithZero(m)
	Set valid=$IsValidNum(m)&&(m>=1)&&(m<=12)  GoTo:'valid notThere
	Set prev=epos+1
	Goto parseNext
getMinute
	GoTo:prev+1>=epos notThere
	Set M=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(M)&&(m>=0)&&(M<=59)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getMinuteZeroAllowed
	GoTo:$$isNotOneOrTwoChars(prev,epos) notThere
	Set M=$E(pValue,prev,(epos-1))
	set M = $$maybePadWithZero(M)
	Set valid=$IsValidNum(M)&&(m>=0)&&(M<=59)  GoTo:'valid notThere
	Set prev=epos+1
	Goto parseNext
getMillis
	set nLength = 3 //default length of fractional seconds
	if ((args '="") && ($IsValidNum(args))) {
		set nLength = args
	}
	GoTo:prev+(nLength-1)>=epos notThere
	Set N=$E(pValue,prev,prev+(nLength-1))
	Set valid=$IsValidNum(N)&&(N>=0) GoTo:'valid&&'opt notThere
	Set prev=prev+nLength
	Goto parseNext
getAMPM
	GoTo:prev>=epos notThere
	Set ampm=$Case($ZCVT($E(pValue,prev),"L")
			,"a":0, "p":1, :"")
	Set valid=(""'=ampm)  GoTo:'valid notThere
	Set prev=prev+1+("m"=$ZCVT($E(pValue,prev+1),"L"))
	Goto parseNext
getAMPMWithDots
	GoTo:prev>=epos notThere
	Set ampm=$Case($ZCVT($E(pValue,prev),"L")
			,"a":0, "p":1, :"")
	Set valid=(""'=ampm)  GoTo:'valid notThere
	Set prev=prev+4
	Goto parseNext
getHorologFormat
	//find out how many chars are needed....
	//at least, there needs to be a comma in it
	GoTo:prev>=epos notThere
	set initialString = $E(pValue,prev,epos-1)
	set maybeN = $P(initialString,".",2)
	set:(maybeN'="") N = maybeN
	Set timeString = $ZDT(initialString,8,1)
	Set date = $P(timeString," ")
	Set time = $P(timeString," ",2)
	if ((date="") || (time ="")) { GoTo notThere }
	Set Y = $E(date,1,4)
	Set m = $E(date,5,6)
	Set d = $E(date,7,8)
	Set H = $P(time,":")
	Set M = $P(time,":",2)
	Set S = $P(time,":",3)
	set prev = epos
	Goto parseNext
getZdatetimeFormat
	//find out how many chars are needed....
	//at least, there needs to be a comma in it
	GoTo:prev>=epos notThere
	set initialString = $E(pValue,prev,epos-1)
	// get milliseconds
	set maybeN = $P(initialString,".",2)
    Set len=$L(maybeN)
	If (len=0) { Set N = "000" }
	ElseIf (len=1) { Set N = maybeN_"00" }
	ElseIf (len=2) { Set N = maybeN_"0" }
	Else { Set N = $E(maybeN,1,3) } // 3 digits max
	// get date and time
	Set timeString = $ZDT(initialString,8,1)
	Set date = $P(timeString," ")
	Set time = $P(timeString," ",2)
	if ((date="") || (time ="")) { GoTo notThere }
	Set Y = $E(date,1,4)
	Set m = $E(date,5,6)
	Set d = $E(date,7,8)
	Set H = $P(time,":")
	Set M = $P(time,":",2)
	Set S = $P(time,":",3)
	set prev = epos
	Goto parseNext
getSecs
	GoTo:prev+1>=epos notThere
	Set S=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(S)&&(S>=0)&&(S<=60)  GoTo:'valid notThere ; 60 for leap second
	Set prev=prev+2
	Goto parseNext 
getSecsVariableLength
	Set (s1,s2) = ""
	If (prev+1>epos) { // nothing to read
		Set S="00" 
		Set valid=1 
		Goto parseNext 
	}
	Else {
		// 1st char
		Set s1=$E(pValue,prev)  
		Set valid=$IsValidNum(s1)&&(s1>=0)&&(s1<=9)  
		If valid { 
			Set prev=prev+1 
		}
		Else { // this character is not a number
			Set S="00" 
			Set valid=1 
			Goto parseNext 
		}
		// 2nd char
		If (prev<=epos) { 
			Set s2=$E(pValue,prev) 
			Set valid=$IsValidNum(s2)&&(s2>=0)&&(s2<=60) // 60 for leap second
			If valid { 
				Set prev=prev+1 
				Set S = s1_s2
			}
			Else { 
				Set S = "0"_s1
				Set valid=1 
			}
			Goto parseNext 
		}
	}
	Goto parseNext 
getWeekOfYear
	GoTo:prev+1>=epos notThere
	Set woy=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(woy)&&(woy>=0)&&(woy<=53)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getWeekOfYearWithArgs
	GoTo:prev+1>=epos notThere
	Set woy=$E(pValue,prev,prev+1)
	if ((args'="") && (args>=0) && (args <=6)) { set firstdayOfWeek = args }
	Set valid=$IsValidNum(woy)&&(woy>=0)&&(woy<=53)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getWeekOfYearWithArgsZeroAllowed
	GoTo:$$isNotOneOrTwoChars(prev,epos) notThere
	Set woy=$E(pValue,prev,(epos-1))
	Set woy = $$maybePadWithZero(woy)
	if ((args'="") && (args>=0) && (args <=6)) { set firstdayOfWeek = args }
	Set valid=$IsValidNum(woy)&&(woy>=0)&&(woy<=53)  GoTo:'valid notThere
	Set prev=epos+1
	Goto parseNext
getDayOfWeek
	GoTo:prev>=epos notThere
	Set dow=$E(pValue,prev)
	Set valid=$IsValidNum(dow)&&(dow>=0)&&(dow<=6)  GoTo:'valid notThere
	Set prev=prev+1
	Goto parseNext
getMondayBasedDayOfWeek
	GoTo:prev>=epos notThere
	Set dow=$E(pValue,prev)
  //parsing 1 for monday, 2 for tuesday,...7 for sunday
  //now, dow maps 0=sunday, 1=monday, ...6= saturday
  //so, just need to change dow to 0 if it's seven, and then do normal check
	set:dow=7 dow = 0
	Set valid=$IsValidNum(dow)&&(dow>=0)&&(dow<=6)  GoTo:'valid notThere
	Set prev=prev+1
	Goto parseNext
getYear2
	GoTo:prev+1>=epos notThere
	Set yy=$E(pValue,prev,prev+1)
	Set valid=$IsValidNum(yy)&&(yy>=0)&&(yy<=99)  GoTo:'valid notThere
	Set prev=prev+2
	Goto parseNext
getYear4
	GoTo:prev+3>=epos notThere
	Set Y=$E(pValue,prev,prev+3)
	Set valid=$IsValidNum(Y)&&(Y>=0)&&(Y<=9999)  GoTo:'valid notThere
	Set prev=prev+4
	Goto parseNext
getTimezoneMins
	GoTo:prev+3>=epos notThere
	Set tzSign=$Case($E(pValue,prev),"+":1,"-":1,:0)
	Set Z=$E(pValue,prev,prev+tzSign+4)
	Set prev=prev+$L(Z) ; no support for guessing variable-length
	Set Z=$ZCVT($ZStrip(Z,"<>W"),"L")
	Set:$IsValidNum(Z)&&(Z'[".")&&($L(Z)-tzSign>2) mm=$E(Z,*-1,*), Z=$E(Z,1,*-2)_$S(+mm=0:"",mm>=60:"",1:mm/60)
	Set:""=$tr(Z,"+-0.")&&$L(Z) Z=0
	Set valid=$IsValidNum(Z)&&(Z>-24)&&(Z<24)  GoTo:'valid notThere
	Goto parseNext
getTimezoneFrac
	GoTo:prev>=epos notThere
	Set tzPlus=$Case($E(pValue,prev),"+":1,:0)
	Set Z=+$E(pValue,prev,*)
	Set prev=prev+tzPlus+$L(Z)
	Set valid=$IsValidNum(Z)&&(Z>-24)&&(Z<24)  GoTo:'valid notThere
	Goto parseNext
getTimezoneName
	Set prev=epos ; no support for guessing variable-length
	Goto parseNext
isNotOneOrTwoChars(prev,epos)
	quit:(prev+1=epos) 0
	quit:(prev+2=epos) 0
	quit 1
IsNotOneTwoOrThreeChars(prev,epos)
	quit:(prev+1=epos) 0
	quit:(prev+2=epos) 0
	quit:(prev+3=epos) 0
	quit 1
maybePadWithZero(d)
	//d might be a single digit- like 5.
	//if so, prepend a "0" to it; otherwise do nothing
	if $L(d)=1 { set d = "0"_d }
	quit d
}

/*used for telling the difference between two days, a positive number is always returned;
the result is added to a date (if day1 is a monday), to yield the correct day of the week; 
(as day2 may be a wednesday) */
ClassMethod getDayDifference(day1 As %Integer, day2 As %Integer) [ Internal ]
{
	set daydiff = day1-day2
	if (daydiff = 0) {
		q 0
	} elseif (daydiff > 0) {
		q daydiff
	} else {
		//it's negative
		q (7 + daydiff)
	}
}

/// Format a time according to a format string <var>pSpec</var>. If given, the time <var>pTimeUTCODBC</var> must be in the UTC time zone (Universal Coordinated Time a.k.a. GMT / Greenwich Mean Time)
/// given in ODBC format. The string <var>pFReplacement</var> will be substituted wherever pSpec contains the token %f or %F.<br/>
/// If <var>pTimeUTCODBC</var> (the input time to format) is not provided then the current time is used.
/// <br/>
/// The <var>pSpec</var> argument consists of one or more format codes; the format codes are preceded by a percent sign (%).
/// Characters that are not part of a format code are output unchanged.
/// <br/> 
/// The following format codes are supported:<br/>
/// Base timezone to convert to before formatting (supported only at the beginning of the format spec string).<br/>
/// <table><tr style="text-align:left"><th> code </th><th> Description </th></tr>
/// <tr><td> %K(&lt;tz&gt;)</td><td> Timezone offset, &lt;tz&gt; values (case insensitive):</td></tr>
/// <tr><td> Server</td><td>  (default) time on the server where the executing code resides.</td></tr>
/// <tr><td> UTC</td><td>      Universal Time Coordinated (a.k.a. GMT / Greenwich Mean Time)</td></tr>
/// <tr><td> [+]n</td><td>     number of hours after (east of) UTC time (may be fractional)</td></tr>
/// <tr><td> -n</td><td>       number of hours before (west of) UTC time (may be fractional)</td></tr>
/// <tr><td> [+]hhmm</td><td>  hours and minutes after (east of) UTC time (in the ISO 8601:2000 standard format)</td></tr>
/// <tr><td> -hhmm</td><td>    hours and minutes after (west of) UTC time</td></tr></table>
/// <br/>
/// Date and Time Expansion:<br/>
/// <table><tr style="text-align:left"><th> code </th><th> Description </th></tr>
/// <tr><td> %a </td><td> locale's abbreviated weekday name</td></tr>
/// <tr><td> %A </td><td> locale's full weekday name</td></tr>
/// <tr><td> %b </td><td> locale's abbreviated month name</td></tr>
/// <tr><td> %B </td><td> locale's full month name</td></tr>
/// <tr><td> %c </td><td> date and time representation appropriate for locale ; equivalent to %c(-1,-1,-1)</td></tr>
/// <tr><td> %c(&lt;df&gt;,&lt;tf&gt;,&lt;sp&gt;)</td><td> date/time formatted according to $ZDateTime() date 'dformat', time 'tformat', and sub-second 'precision'</td></tr>
/// <tr><td> %d </td><td> day of the month as a 2-digit number (01-31)</td></tr>
/// <tr><td> %#d </td><td> day of the month as a number (1-31) without leading zero</td></tr>
/// <tr><td> %D </td><td> date; equivalent to %m / %d / %y </td></tr>
/// <tr><td> %#D </td><td> date; equivalent to %#m / %#d / %y </td></tr>
/// <tr><td> %f </td><td> input replacement text</td></tr>
/// <tr><td> %#f </td><td> input replacement text, stripped of final dot piece, if any</td></tr>
/// <tr><td> %$f </td><td> final dot piece of input replacement text and dot, if any</td></tr>
/// <tr><td> %$#f </td><td> final dot piece of input replacement text, if any</td></tr>
/// <tr><td> %F </td><td> input replacement text converted to uppercase</td></tr>
/// <tr><td> %#F </td><td> input replacement text converted to uppercase, stripped of final dot piece, if any</td></tr>
/// <tr><td> %$F </td><td> final dot piece of input replacement text and dot, if any, converted to uppercase</td></tr>
/// <tr><td> %$#F </td><td> final dot piece of input replacement text, if any, converted to uppercase</td></tr>
/// <tr><td> %h </td><td> equivalent to %b</td></tr>
/// <tr><td> %H </td><td> hour in 24-hour format as a 2-digit number (00-23)</td></tr>
/// <tr><td> %#H </td><td> hour in 24-hour format as a number (0-23) without leading zeros</td></tr>
/// <tr><td> %I </td><td> hour in 12-hour format as a 2-digit number(01-12)</td></tr>
/// <tr><td> %#I </td><td> hour in 12-hour format as a number (1-12) without leading zeros</td></tr>
/// <tr><td> %j </td><td> day of the year as a 3-digit number (001-366)</td></tr>
/// <tr><td> %#j </td><td> day of the year as a number (1-366) without leading zeros</td></tr>
/// <tr><td> %K(&lt;tz&gt;)</td><td> timezone to use to convert time for display, see above. Produces no output; supported only at the beginning of the format spec string.</td></tr>
/// <tr><td> %m </td><td> month as a 2-digit number (01-12)</td></tr>
/// <tr><td> %#m </td><td> month as a number (1-12) without leading zeros</td></tr>
/// <tr><td> %M </td><td> minute as a 2-digit number (00-59)</td></tr>
/// <tr><td> %#M </td><td> minute as a number (0-59) without leading zeros</td></tr>
/// <tr><td> %N </td><td> fractional second in milliseconds as a 3-digit number (000-999)</td></tr>
/// <tr><td> %p </td><td> current locale's a.m./p.m. indicator for 12-hour clock (lowercase)</td></tr>
/// <tr><td> %#p </td><td> current locale's am/pm indicator for 12-hour clock (lowercase, without dots)</td></tr>
/// <tr><td> %P </td><td> current locale's A.M./P.M. indicator for 12-hour clock (uppercase)</td></tr>
/// <tr><td> %#P </td><td> current locale's AM/PM indicator for 12-hour clock (uppercase, without dots)</td></tr>
/// <tr><td> %q </td><td> equivalent to %q() or %q(0)</td></tr>
/// <tr><td> %q(0) </td><td> HL7 format date/time; equivalent to %Y%m%d%H%M%S </td></tr>
/// <tr><td> %q(1)</td><td> ODBC format date/time; equivalent to %Y-%m-%d %H:%M:%S.%N</td></tr>
/// <tr><td> %q(2)</td><td> ISO 8601:2000 standard date format; equivalent to %Y-%m-%d</td></tr>
/// <tr><td> %q(3)</td><td> $Horolog format</td></tr>
/// <tr><td> %q(4)</td><td> $ZTimestamp format</td></tr>
/// <tr><td> %q(5)</td><td> A 36-character GUID (Globally Unique IDentifier). This is guaranteed to be unique but is not technically a timestamp.</td></tr>
/// <tr><td> %Q</td><td> ODBC format date/time; equivalent to %c(3,,3) or %q(1)</td></tr>
/// <tr><td> %Q(n)</td><td> equivalent to %q(n)</td></tr>
/// <tr><td> %r</td><td> time with seconds in 12-hour format using a.m./p.m. notation; equivalent to %I:%M:%S %p</td></tr>
/// <tr><td> %#r</td><td> time with seconds in 12-hour format using am/pm notation without whitespace or dots; equivalent to %I:%M:%S%#p</td></tr>
/// <tr><td> %R</td><td> time in 24-hour notation; equivalent to %H:%M</td></tr>
/// <tr><td> %S</td><td> second as a 2-digit number (00-60) (60 for leap seconds)</td></tr>
/// <tr><td> %t</td><td> replaced by a &lt;tab&gt;. </td></tr>
/// <tr><td> %T</td><td> time with seconds in 24-hour notation; equivalent to %H:%M:%S</td></tr>
/// <tr><td> %u</td><td> day of the week as a number (1-7), with 1 representing Monday. </td></tr>
/// <tr><td> %#u</td><td> equivalent to %u</td></tr>
/// <tr><td> %U</td><td> week of year as a number, with Sunday as first day of week (00-53); equivalent to %U(0). The first Sunday of January is the first day of week 1; days in the new year before this are in week 0.</td></tr>
/// <tr><td> %U(&lt;dow&gt;)</td><td> week of the year as a number, starting on the given DayOfWeek (Sunday=0)</td></tr>
/// <tr><td> %#U</td><td> week of the year as a number, with Sunday as first day of week (00-53), without leading zeros (0-53); equivalent to %#U(0)</td></tr>
/// <tr><td> %#U(&lt;dow&gt;)</td><td> week of the year as a number, starting on the given DayOfWeek (Sunday=0), without leading zeros</td></tr>
/// <tr><td> %w</td><td> day of the week as a number (0-6; Sunday is 0)</td></tr>
/// <tr><td> %#w</td><td> equivalent to %w</td></tr>
/// <tr><td> %W</td><td> week of the year as a number (00-53); equivalent to %U(1). The first Monday of January is the first day of week 1; days in the new year before this are in week 0.</td></tr>
/// <tr><td> %W(&lt;dow&gt;)</td><td> equivalent to %U(&lt;dow&gt;)</td></tr>
/// <tr><td> %#W</td><td> week of the year as a number (0-53) without leading zeros; equivalent to %#U(1).</td></tr>
/// <tr><td> %#W(&lt;dow&gt;)</td><td> equivalent to %#U(&lt;dow&gt;)</td></tr>
/// <tr><td> %y</td><td> year within a century as a number (00-99)</td></tr>
/// <tr><td> %Y</td><td> year including the century, as a 4-digit number (0000-9999)</td></tr>
/// <tr><td> %z</td><td> timezone offset from UTC in the ISO 8601:2000 standard format ( +hhmm or -hhmm ). For example, "-0430" means 4 hours 30 minutes behind UTC (west of Greenwich)</td></tr>
/// <tr><td> %#z</td><td> timezone offset from UTC in hours with leading +/- and without leading or trailing zeros; trailing decimals may appear ( +h.nnn or -h.nnn ) For example, "-4.5" means 4 hours 30 minutes behind UTC (west of Greenwich)</td></tr>
/// <tr><td> %%</td><td> Literal % percent sign</td></tr>
/// <tr><td> %(</td><td> Literal ( left parenthesis</td></tr>
/// <tr><td> %_</td><td> Reserved token (currently treated as a literal- printed out as itself)</td></tr></table>
/// 
ClassMethod FormatDateTime(pSpec As %String = "", pFReplacement As %String = "", pTimeUTCODBC As %String) As %String
{
 /*
 these parts are in the spec that this code was based on, but are not supported yet:
 
   %C    century as a 2-digit number (00-99), i.e. year divided by 100 and truncated to an integer 
   %#C   century as a number (0-99) without leading zero
   %e    day of the month as a number padded with a leading space character ( 1-31)
   %#e   equivalent to %#d
   %g    last 2 digits of the week-based year as a 2-digit number (00-99); see description below
   %#g   last 2 digits of the week-based year as a number  without leading zeros (0-99); see description below
   %G    week-based year as a 4-digit number (0000-9999); see description below
   %#G   week-based year as a number without leading zeros (0-9999); see description below
   %L(<loc>)  locale to use for display of locale-dependent format codes, see above. Produces no output; supported only at the beginning of the format spec string.
   %n    replaced by a <newline>. 
   %#N   fractional second in milliseconds as a number without leading zeros (0-999)
   %#S   second as a number (0-60) without leading zeros
   %V    week of week-based year as a number (01-53) with Monday as the first day of the week, as a number (01-53) (see description below; If the week containing 1 January has four or more days in the new year, then it is considered week 1. Otherwise, it is the last week of the previous year, and the next week is week 1. Both January 4th and the first Thursday of January are always in week 1)
   %#V   week of week-based year as a number (1-53) without leading zeros
   %x    date representation for locale (See the Base Definitions volume of IEEE Std 1003.1-2001)
   %X    time representation for locale (See the Base Definitions volume of IEEE Std 1003.1-2001)
   %#y   year within a century as a number (0-99) without leading zeros
   %#Y   year including the century, as a number (0-9999) without leading zeros
   %Z    timezone name or abbreviation, or empty string if no timezone information is available.
 Notes:
  %g, %G, and %V give values according to the ISO 8601:2000 standard week-based year. In this system, weeks begin on
  a Monday and week 1 of the year is the week that includes January 4th, which is also the week that includes the
  first Thursday of the year, and is also the first week that contains at least four days in the year.
  If the first Monday of January is the 2nd, 3rd, or 4th, the preceding days are part of the last week of the
  preceding year; thus, for Saturday 2nd January 1999, %G is replaced by 1998 and %V is replaced by 53.
  If December 29th, 30th, or 31st is a Monday, it and any following days are part of week 1 of the following year.
  Thus, for Tuesday 30th December 1997, %G is replaced by 1998 and %V is replaced by 01.
 
Differences from POSIX/IEEE/ISO standard
 %#<char> - certain Microsoft extended semantics supported, and additional ones.
 %c - IRIS format
 %F - uppercase replacement string, not ISO date. ISO date supported as %q(2)
 %K - define the timezone as part of the spec rather than as a function argument or environment variable
 %L - define the locale as part of the spec rather than as a function argument or environment variable
 %E<char>, %O<char> - these extensions are not supported
 %q,%Q(<n>) - various standard formats
 %P - Uppercase AM/PM
 %( - defined as literal '('
*/
	If "%K"=$E(pSpec,1,2) {
		If "("=$E(pSpec,3) {
			Set tz=$ZCVT($ZStrip($P($E(pSpec,4,*),")"),"<>W"),"L")
			Set tzSign=$Case($E(tz),"+":1,"-":1,:0)
			Set str=$E(pSpec,5+$L(tz),*)
			Set:$IsValidNum(tz)&&(tz'[".")&&($L(tz)-tzSign>2) mm=$E(tz,*-1,*), tz=$E(tz,1,*-2)_$S(+mm=0:"",mm>=60:"",1:mm/60)
			Set:""=tz tz="server"
		} Else { Set tz="server", str=$E(pSpec,3,*) }
	} Else { Set tz="server",str=pSpec }

	Set t=$G(pTimeUTCODBC) 
	If ""=t {
		Set t=$Case(tz
			,"server":$$$timeUTCtoLocal($$$timeUTC)
			,"utc":$$$timeUTC
			,:$S(+tz=0:$$$timeUTC, 1:$$$timeUTCHtoUTC($$HorologAddSecs^EnsUtil($$$timeUTCH,+tz*3600))))
	} Else {
		Set t=$Case(tz
			,"server":$$$timeUTCtoLocal(t)
			,"utc":t
			,:$S(+tz=0:t, 1:$$$timeUTCHtoUTC($$HorologAddSecs^EnsUtil($$$timeUTCtoUTCH(t),+tz*3600))))
	}
	Set tz=$Case(tz
		,"server":""
		,"utc":0
		,"":""
		,:+tz)

	Set f=1  For { Set (f,f2)=$F(str,"%",f) Quit:'f  Set ch=$E(str,f)
		#; if the # character is found, also look at the next char as well
		Set:"#"=ch||("$"=ch&&$Case($E(str,f+1),"f":1,"F":1,"#":$Case($E(str,f+2),"f":1,"F":1,:0),:0)) (f,f2)=f+1, ch=ch_$E(str,f)
		Set:$Case(ch,"#$":1,"$#":1,:0)&&($Case($E(str,f+1),"f":1,"F":1,:0)) (f,f2)=f+1, ch=ch_$E(str,f)
		If ((ch="q") || (ch="Q")) {
			#; want to get the entire q format, then at the end of this clause have the string 
			#; replaced properly and have ch hold the entire q format....
			Set ch=$$getEntireQFormat(ch, f, str)

			#; if it was a large Q or small q by itself(no parentheses or arguments), then need to replace it here, so that the replacement
			#; string retrieved from doExpansion is inserted into the str correctly: (else do not do any replacement)
			Set:$E(str,(f+1))'="(" $E(str, f)=ch
		}
		#; see if the ch is a key that needs to be replaced by another set;
		#; like %D goes to %m/%d/%y
		#; if so, replace it, then continue with the loop
		Set replacementStr=$$doExpansion(ch)

		If replacementStr '= ch {
			#; if ch starts with "#" need to go an extra character back...
			Set beginReplacement = f-1

			If ($E(ch) = "#") { set beginReplacement = f-2 }
			Set endReplacement = beginReplacement + $L(ch) 
			#; it is correct to use the length; not length-1; since the first char to be replaced is the % sign,
			#; so need to account for the entire length of the ch- must replace it all; not just the first char or 2.
			Set $E(str,beginReplacement,endReplacement) = replacementStr
			#; also need to set the f position back one(or two), so that it parses correctly (so that it sees the "%" as it should)
			Set f=beginReplacement
			Continue
		}
		Set sub=$Case(ch
			,"a":$ZDate($$$timeUTCtoUTCH(t),11)
			,"A":$ZDate($$$timeUTCtoUTCH(t),12)
			,"b":$P($ZDate($$$timeUTCtoUTCH(t),6)," ")
			,"B":$P($ZDate($$$timeUTCtoUTCH(t),9)," ")
			,"c":$S(1+$$setargsf2():$ZDT($$$timeUTCtoUTCH(t),$S(""=$P(args,",",1):-1,1:$P(args,",",1)),$S(""=$P(args,",",2):-1,1:$P(args,",",2)),$S(""=$P(args,",",3):-1,1:$P(args,",",3))), 1:t)
			,"d":$E(t,9,10)
			,"#d":$$maybeChopOffZero($E(t,9,10))
			,"f":pFReplacement
			,"#f":$S($L(pFReplacement,".")>1:$P(pFReplacement,".",1,$L(pFReplacement,".")-1), 1:pFReplacement)
			,"$f":$S($L(pFReplacement,".")>1:"."_$P(pFReplacement,".",$L(pFReplacement,".")), 1:"")
			,"#$f":$S($L(pFReplacement,".")>1:$P(pFReplacement,".",$L(pFReplacement,".")), 1:"")
			,"$#f":$S($L(pFReplacement,".")>1:$P(pFReplacement,".",$L(pFReplacement,".")), 1:"")
			,"F":$ZCVT(pFReplacement,"U")
			,"#F":$ZCVT($S($L(pFReplacement,".")>1:$P(pFReplacement,".",1,$L(pFReplacement,".")-1), 1:pFReplacement),"U")
			,"$F":$S($L(pFReplacement,".")>1:"."_$ZCVT($P(pFReplacement,".",$L(pFReplacement,".")),"U"), 1:"")
			,"#$F":$S($L(pFReplacement,".")>1:$ZCVT($P(pFReplacement,".",$L(pFReplacement,".")),"U"), 1:"")
			,"$#F":$S($L(pFReplacement,".")>1:$ZCVT($P(pFReplacement,".",$L(pFReplacement,".")),"U"), 1:"")
			,"h":$P($ZDate($$$timeUTCtoUTCH(t),6)," ")
			,"H":$E(t,12,13)
			,"#H":$$maybeChopOffZero($E(t,12,13))
			,"I":$E($ZDT($$$timeUTCtoUTCH(t),3,4),12,13)
			,"#I":$$maybeChopOffZero($E($ZDT($$$timeUTCtoUTCH(t),3,4),12,13)) ; do a maybeChopOffZero to above expression
			,"j":$$$NUM($$getDayOfYear(t),3)
			,"#j":$$getDayOfYear(t) 
			,"m":$E(t,6,7)
			,"#m":$$maybeChopOffZero($E(t,6,7))
			,"M":$E(t,15,16)
			,"#M":$$maybeChopOffZero($E(t,15,16))
			,"N":$E(t,21,23)
			,"p":$$getDottedLowerCaseAmPm(t)
			,"P":$$getDottedUpperCaseAmPm(t)
			,"#p":$$getLowerCaseAmPm(t)
			,"#P":$$getAmPmSimple(t)
			,"q(3)":$$doQFunctionf2(t,3)
			,"q(4)":$$doQFunctionf2(t,4)
			,"q(5)":$$doQFunctionf2(t,5)
			,"S":$E(t,18,19)
			,"t":$C(9)
			,"T":$E(t,12,19)
			,"u":$$getDayOfWeek(t)
			,"#u":$$getDayOfWeek(t)
			,"U":$$$NUM($S('$$setargsf2():$$weeknum(t,0), 1:$$weeknum(t,+args)),2)
			,"#U":$S('$$setargsf2():$$weeknum(t,0), 1:$$weeknum(t,+args))
			,"W":$$$NUM($S('$$setargsf2():$$weeknum(t,1), 1:$$weeknum(t,+args)),2)
			,"#W":$S('$$setargsf2():$$weeknum(t,1), 1:$$weeknum(t,+args))
			,"w":$ZDate($$$timeUTCtoUTCH(t),10)
			,"#w":$ZDate($$$timeUTCtoUTCH(t),10)
			,"x":$E($ZDT($$$timeUTCtoUTCH(t)),1,10)
			,"X":$E($ZDT($$$timeUTCtoUTCH(t)),12,19)
			,"y":$E(t,3,4)
			,"Y":$E(t,1,4)
			,"z":$$timezone(tz,0)
			,"#z":$$timezone(tz,1)
			,"Z":""
			,"%":ch
			,"(":ch
			,:"%"_ch)
		#; in here: if there is a %#; in next line need to get rid of the % as well; (so need to replace an extra character back)
		Set beginReplacement = f-1-$Case($E(ch),"#":$S("$"=$E(ch,*-1):2,1:1), "$":$S("#"=$E(ch,*-1):2,"$"=ch:0,1:1), :0)
		#; currently, the end replacement character is f2; which is by default one more than f and is reset in the ...f2 subroutines as a side effect
		Set $E(str,beginReplacement,f2)=sub, f=beginReplacement+$L(sub)
	}
	Quit str

maybeChopOffZero(number) 
	set:$E(number)="0" number=$E(number,2,*)
	quit number
doExpansion(ch)
	quit $Case(ch
		,"D":"%m/%d/%y"
		,"#D":"%#m/%#d/%y"
		,"q()":"%Y%m%d%H%M%S" ; q() and q(0) are the same
		,"q(0)":"%Y%m%d%H%M%S"
		,"q(1)":"%Y-%m-%d %H:%M:%S.%N"
		,"q(2)":"%Y-%m-%d"
		,"r":"%I:%M:%S %p"
		,"#r":"%I:%M:%S%#p"
		,"R":"%H:%M"
		,:ch)
weeknum(t,dow1)
	#; january 1st - get the $h value for jan1st in the same year as the date being processed
	s j1h=$P($$$timeUTCtoUTCH($E(t,1,4)_"-01-01"),",")
	#; day of year, with 0 as the first day of the year
	s doy0=$P($$$timeUTCtoUTCH(t),",")-j1h
	s dow=$ZDate($$$timeUTCtoUTCH(t),10)
	#; what was the day of the week on january 1st?
	s dowj1=$ZDate(j1h,10)
	#; now: mod them; given which day should be the first day of the week; adding a seven so that
	#; it's 1 based; not 0 based:
	q (7+doy0+dowj1-dow1)\7
timezone(tz, dofrac)
	s:""=tz ts=$ZTS, tz=$$HorologDiff^EnsUtil($zdTH(ts,-3),ts), tz=tz+$s(tz<0:-30,1:30)\60/60 ; round to the nearest minute
	s hrs=$p(tz,".")  s:hrs>=0 hrs="+"_+hrs
	s frac=$e($p(tz,".",2),1,3)
	if dofrac { s:frac hrs=hrs_"."_frac }
	else { s mm=60*+("."_frac), hrs=$e(hrs)_$$$NUM($e(hrs,2,*),2)_$$$NUM($P(mm+0.5,"."),2) }
	q hrs
setargsf2() ; local routine with side effect of setting the variables 'args' and 'f2'
	#; first; look for arguments- do that by looking for an open paren- ch2 is the next "peek" character
	s ch2=$E(str,f+1)
	i "("'=ch2 s args=""  q 0 ; if no arguments, quit with 0 
	s args=$P($E(str,f+2,*),")") ; get all the args- the content within the parens
	s f2=f+1+$L(args)+1 ; reset f2 so that it points beyond the paren
	q (""'=args) ; quit with a true as long as there actually are args; else false if there are no args within the parens
doQFunctionf2(t, arg)
	set f2=f + 3 ; it's actually beginReplacement + 4(the length of the q(3) or q(4); 
	if arg=5 quit $System.Util.CreateGUID()
	#; but beginReplacement isn't in scope while somehow f is)
	set almost=$$$timeUTCtoUTCH(t)
	if (arg=3) {
		set almost = $P(almost,".")
	}
	quit almost
getDayOfWeek(t)
	#; want to return 1 for monday, 2 for tuesday,...7 for sunday
	#; zdate does 1 for monday, 2 for tuesday...but starts out with 0 for sunday
	#; so, if it's zero return a 7; else return it as is:
	set almost = $ZDate($$$timeUTCtoUTCH(t),10)
	if (almost=0) quit 7
	quit almost
getDayOfYear(t)
	quit 1+$P($$$timeUTCtoUTCH(t),",")-$P($$$timeUTCtoUTCH($E(t,1,4)_"-01-01"),",")
getAmPmSimple(t)
	quit $E($ZDT($$$timeUTCtoUTCH(t),3,4),17,18)
getLowerCaseAmPm(t)
	quit $ZCVT($$getAmPmSimple(t),"L")
getDottedLowerCaseAmPm(t)
	Set undotted = $$getLowerCaseAmPm(t)
	Set dotted = $E(undotted,1)_"."_$E(undotted,2)_"."
	quit dotted
getDottedUpperCaseAmPm(t)
	Set undotted = $$getAmPmSimple(t)
	Set dotted = $E(undotted,1)_"."_$E(undotted,2)_"."
	quit dotted
getEntireQFormat(ch, f, str)
	#; whenever a q or a Q is encountered, this method fires;
	#; need to deal with translating the Q's to the q's, and then extracting everything until
	#; the ")" (close paren)

	#; first: see if it's a large Q or a small q by itself; besides that- case is insensitive
	if $E(str,(f+1))'="(" {
		quit:ch="Q" "q(1)"
		quit:ch="q" "q(0)" 
		#; only need those two cases, as this method is only called when
		#; ch=Q or q	
	}
	#; an open paren is present, it should just fall through; but the large q should turn into a small q:
	Set closeparen = $Find(str,")", f)
	quit "q"_$E(str,f+1, (closeparen-1))

	#; then, convert it lower case, then get everything until (including) the close paren
	#; and the expansion method will handle any translation
}

/// Override to use your own century fixing algorithm
ClassMethod FixCentury(yy)
{
	Set now=$E($ZDT($ZTS,3),1,4)
	Set nowcc=$E(now,1,2), nowyy=$E(now,3,4)
	Quit:yy-nowyy>50 (nowcc-1)_yy
	Quit:nowyy-yy>50 (nowcc+1)_yy
	Quit nowcc_yy
}

ClassMethod getCExpansion(args As %String, ByRef nLength)
{
	set numArgs =$L(args,",")
	if (numArgs >3) {
		quit "" // put in an error about wrong number of arguments?
	}
	if (""=args) { // can't use 0; $L("",",") returns 1
		set arg1=1, arg2=1, nLength=0
	} elseif (1=numArgs) {
	set arg1=$P(args,","), arg2=1, nLength=0
	} elseif (2=numArgs) {
		set arg1=$P(args,","), arg2=$P(args,",", 2), nLength=0
	} elseif (3=numArgs) {
		set arg1=$P(args,","), arg2=$P(args,",", 2), nLength=$P(args,",", 3)
	}
	// ! make sure all the args are valid numbers
	set dateformat = $case(arg1
	, "-1" :  "%m/%d/%Y"
	, 1 :  "%m/%d/%Y"
	, 2: "%d %b %Y"
	, 3: "%Y-%m-%d"
	, 4: "%d/%m/%Y"
	, 5: "%b %#d, %Y"
	, 6: "%b %#d %Y"
	, 7: "%b %d %Y"
	, 8: "%Y%m%d"
	, 9: "%b %#d, %Y"
	, 10: "%w"
	, 11: "%a"
	, 12: "%A"
	,:"")

	set timeformat= $case(arg2
	,1: " %H:%M:%S"
	,2: " %H:%M"
	,3: " %I:%M:%S%#P"
	,4: " %I:%M:%#P"
	,5: "T%H:%M:%S%z"
	,6: "T%H:%M%z"
	,7: "T%H:%M:%SZ"
	,8: "T%H:%MZ"
	,:"")

	if (nLength>0) {
		// ! replace %S with %S.%N
		set secondLocation = $F(timeformat,"%S")
		if (secondLocation >= 3) {
			set $E(timeformat, secondLocation-2, secondLocation-1) = "%S.%N("_nLength_")"
		}
	}
	//w !, dateformat_timeformat, !
	quit dateformat_timeformat
}

}
