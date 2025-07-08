/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

Class %ZEN.Report.Display.COSChart.Date Extends %RegisteredObject [ Deprecated ]
{

/// milliseconds since 1970
Property time As %Double;

Method %OnNew(initvalue As %String) As %Status
{
	if $D(initvalue),$$$ISNAN($$$PARSEFLOAT(initvalue)) {
		Set ..time="NaN" ; an invalid date
	} else {
		try {
			set ..time=$system.SQL.DATEDIFF("ms","1970-01-01",$s('$D(initvalue):$zdate($h,3),1:initvalue))
		} catch {
			set ..time=$system.SQL.DATEDIFF("ms","1970-01-01",$zdate($h,3))
		}
	}
	quit $$$OK
}

Method diff(anotherTime As Date)
{
		
	quit anotherTime.getTimeMS()-..time
}

/// return time in milliseconds since the epoch, 1970-01-01
Method getTime()
{
	quit ..time
}

Method getTimeMS() [ Internal ]
{
	quit ..time
}

Method getFullYear()
{
	Set date=..convertToDate()
	quit $system.SQL.YEAR(date)
}

Method getMonth()
{
	Set date=..convertToDate()
	quit $system.SQL.MONTH(date)-1
}

/// set *day* of month of date, returns date in milliseconds since the epoch, 1970-01-01
Method setDate(dayOfMonth)
{
	Set dateODBC = ..convertToDate()
	Set $P(dateODBC,"-",3)="01"
	Set dateODBC=$SYSTEM.SQL.DATEADD("day",dayOfMonth-1,dateODBC)
	Set ..time=$system.SQL.DATEDIFF("ms","1970-01-01",dateODBC)
}

/// set time in milliseconds since the epoch, 1970-01-01
Method setTime(timeMS)
{
	Set ..time=timeMS
}

/// get day
Method getDate()
{
	Set date=..convertToDate()
	quit $system.SQL.DAYOFMONTH(date)
}

Method getHours()
{
	Set dateAndTime=..convertToDateAndTime()
	quit $P($P(dateAndTime," ",2),":",1)
}

Method getMinutes()
{
	Set dateAndTime=..convertToDateAndTime()
	quit $P($P(dateAndTime," ",2),":",2)
}

Method getSeconds()
{
	Set dateAndTime=..convertToDateAndTime()
	quit $P($P(dateAndTime," ",2),":",3)
}

Method setHours(time)
{
	Set dateODBC = ..zenDateToString(##this,1)
	Set dateODBC=$SYSTEM.SQL.DATEADD("hour",time,dateODBC)
	Set ..time=$system.SQL.DATEDIFF("ms","1970-01-01",dateODBC)
}

Method setMinutes(time)
{
	Set dateODBC = ..zenDateToString(##this,1)
	Set dateODBC=$SYSTEM.SQL.DATEADD("minute",time,dateODBC)
	Set ..time=$system.SQL.DATEDIFF("ms","1970-01-01",dateODBC)
}

Method setSeconds(time)
{
	Set dateODBC = ..zenDateToString(##this,1)
	Set dateODBC=$SYSTEM.SQL.DATEADD("second",time,dateODBC)
	Set ..time=$system.SQL.DATEDIFF("ms","1970-01-01",dateODBC)
}

Method dateToString()
{
	quit ..convertToDate()
}

/// Takes a Date object, converts it to YYYY-MM-DD.
/// If hasTime, add a time portion to the string.
ClassMethod zenDateToString(d, hasTime = 0, format, sep)
{
	if (d="") {
		quit "" // JSL4339
	}
	Set format = $s('$D(format) : "YYYY-MM-DD", 1 : format)
	Set sep = $s('$D(sep) : "-", 1 : sep)
	if ($$$ISNAN(d.getTime())) {
		// return error value
		quit -1
	}

	Set mon = d.getMonth()
	Set mon = $s(mon<9:"0", 1:"") _ (mon+1)
	Set day = d.getDate()
	Set day = $s(day<10:"0", 1:"") _ (day)
	Set yr = d.getFullYear()

	if format="MDY" {
		Set t = mon _ sep _ day _ sep _ yr
	}
	elseif format="DMY" {
		Set t = day _ sep _ mon _ sep _ yr
	} else {
		//case 'YMD':
		//default:
		Set t = yr _ sep _ mon _ sep _ day
	}

	if (hasTime) {
		Set t = t _" " _ d.getHours() _ ":" _  d.getMinutes() _ ":" _  d.getSeconds()
	}
	quit t
}

Method convertToDateAndTime() [ Internal ]
{
	Set epoch=$ZDATEH("1970-01-01",3)
	Set timeSince1970=..time
	Set date=$SYSTEM.SQL.DATEADD("ms",timeSince1970,epoch)
	quit date
}

Method convertToDate() [ Internal ]
{

	Set dateAndTime=..convertToDateAndTime()
	Set retVal=$PIECE(dateAndTime," ",1)
	quit retVal
}

ClassMethod createDate(year, month, day)
{
	// note that month can be greater than 12 and day greater than 31!!!
	Set date=year_"-01-01"
	Set date=$SYSTEM.SQL.DATEADD("month",month,date)
	Set date=$PIECE(date," ",1)
	Set date=$SYSTEM.SQL.DATEADD("day",day-1,date)
	Set date=$PIECE(date," ",1)
	quit ##class(Date).%New(date)
}

ClassMethod createDateFromMS(time)
{
	Set d=##class(Date).%New("")
	Set d.time=time
	quit d
}

ClassMethod createDate1(year, month, day, hours, minutes, seconds, milliseconds, ByRef pStatus)
{
	try {
	// note that month can be greater than 12 and day greater than 31!!!
		Set date=year_"-01-01"
		Set date=$SYSTEM.SQL.DATEADD("month",month,date)
		Set date=$SYSTEM.SQL.DATEADD("day",day-1,date)
		Set date=$SYSTEM.SQL.DATEADD("hour",hours,date)
		Set date=$SYSTEM.SQL.DATEADD("minute",minutes,date)
		Set date=$SYSTEM.SQL.DATEADD("second",seconds,date)
		Set date=$SYSTEM.SQL.DATEADD("millisecond",milliseconds,date)
	} catch {
		Set pStatus=$$$ERROR($$$GeneralError, "Error in createDate1 year="_$g(year)_" month="_$g(month)_" day="_$g(day)_" hours="_$g(hours)_" minutes="_$g(minutes)_" seconds="_$g(seconds)_" milliseconds="_$g(milliseconds)_"error="_$ze)
	}
	quit ##class(Date).%New(date)
}

/// Convert a string to a date value.
/// Handles the following formats:
/// 'T'|'t' => today, T+n t-n
/// '' => ''
/// 2005-12-20,2005/12/20,2005 12 20
/// Various date formats supported by COS
/// Returns either '', -1 (for invalid dates)
/// or a date string in the form YYYY-MM-DD
/// (or in the format specified by format and sep)
ClassMethod ParseDate(value, hasTime, format, sep)
{
	Set retVal=-1
	try {
		// ''/null
		if value="" Set retVal="" quit
		Set hasTime = $s('$D(hasTime) : 0, 1 : $s(hasTime : 1, 1 : 0))
		//value = value.toString();

		// T,T+n,T-n
		Set f1 = $e(value)
		Set f2 = $e(value,2,*)

		if (("T" = f1) || ("t" = f1)) && (("" = f2) || '$$$ISNAN($$$PARSEINT(f2))) {
			Set d = ..%New() ; now
			if ("" '= f2) {
				// adjust
				do d.setDate(d.getDate()+$$$PARSEINT(fs2))
			}
			Set retVal=d.dateToString() ;,hasTime,format,sep)
			quit 
		}

		// test for MMM-YYYY JSL4255 and if in this format convert to YYYY-MM-DD format
		Set v = $tr(value,"-"," ")
		;Set v = $tr(v,"/"," ")
		Set v = $tr(v,"."," ")
		Set p = ##class(cchart).split(v, " ")
		if $LL(p) = 2 {
			if $LI(p,1)?1.A {
				Set mmm=$LI(p,1) ; month
			} elseif $LI(p,2)?1.A {
				Set mmm=$LI(p,2) ; month
			}
			if $LI(p,2)?4N {
				Set yyyy=$LI(p,2) ; year
			} elseif $LI(p,1)?4N {
				Set yyyy=$LI(p,1) ; year
			}
			if $D(mmm)&&$D(yyyy) {
				Set value=$zdate($zdateh("01 "_mmm_" "_yyyy,2),3)
			}
		} elseif $LL(p) = 3 { // JSL4339
			if $LI(p,1)?1.A {
				Set mmm=$LI(p,1) ; month
			} elseif $LI(p,2)?1.A {
				Set mmm=$LI(p,2) ; month
			}
			if $LI(p,2)?1.N {
				Set ddd=$LI(p,2) ; day
			} else {
				Set ddd="01"
			}

			if $LI(p,3)?4N {
				Set yyyy=$LI(p,3) ; year
			} elseif $LI(p,1)?4N {
				Set yyyy=$LI(p,1) ; year
			}
			if $D(mmm)&&$D(yyyy)&$D(ddd) {
				Set value=$zdate($zdateh(ddd_" "_mmm_" "_yyyy,2),3)
			}
		
		} elseif $LL(p)>3 {
			Set dd=$LI(p,1)
			Set mmmm=$LI(p,2)
			Set yyyy=$LI(p,3)
			if mmmm?1.A {
				Set value=$zdate($zdateh(dd_" "_mmm_" "_yyyy,2),3)
			}
		}
				
		// test for YYYY/MM/DD: normalize delimiter
		Set v = $tr(value,"-","/")
		Set v = $tr(v," ","/")
		Set v = $tr(v,".","/")
		Set p = ##class(cchart).split(v, "/") 
		if ($LL(p) >= 2) {
			Set year = $$$PARSEINT($LG(p,1))
			Set month = $$$PARSEINT($LG(p,2))
			Set day = 1
			if ("" '= $LG(p,3)) {
				Set day = $$$PARSEINT($LG(p,3))
			}
			Set hour = 1
			Set min = 0
			Set sec = 0
			if (hasTime && ("" '= $LG(p,4))) {
				Set t = ##class(cchart).split($LG(p,4),":")
				Set hour = $s($LG(t,1)'="" : $$$PARSEINT($LG(t,1)), 1 : "")
				Set min = $s($LG(t,2)'="" : $$$PARSEINT($LG(t,2)), 1 : "")
				Set sec = $s($LG(t,3)'="" : $$$PARSEINT($LG(t,3)), 1 : "")
				Set hour = $s($$$ISNAN($$$PARSEINT(hour)) : 0, 1 : hour)
				Set min = $s($$$ISNAN($$$PARSEINT(min)) : 0, 1 : min)
				Set sec = $s($$$ISNAN($$$PARSEINT(sec)) : 0, 1 : sec)
				if ((hour<0)||(hour>23)||(min<0)||(min>59)||(sec<0)||(sec>59)) {
					Set retVal=-1 quit 
				}
			}

			if ('$$$ISNAN(year) && '$$$ISNAN(month) && '$$$ISNAN(day)) {
				// validate (as JS does not!)
				Set d = ..%New("NaN")
				if (year >= 1000 && year <= 9999) {
					if (month >= 1 && month <= 12) {
						// get # of days per month
						Set daysInMonth = $LB(31,28,31,30,31,30,31,31,30,31,30,31)

						// is this a leap year?
						if (year#4 = 0) {
							if ((year#100 = 0) && ((year#400) '= 0)) {
								// skip these
							}
							else {
								Set $LI(daysInMonth,2) = 29
							}
						}

						if ((day >= 1) && (day <= $LG(daysInMonth,month))) {
							Set d = ..createDate1(year,month-1,day,hour,min,sec,0,.tSC)
						}
					}
				}

				Set retVal=..zenDateToString(d,1) ;,hasTime,format,sep)
				quit
			}
		}

		// last, let COS/JS have a shot
		Set ms = $system.SQL.DATEDIFF("ms","1970-01-01",$zdate($zdatetimeh(value,3),3))
		if ($$$ISNAN(ms)) {
			// try adding this year to the end!
			Set now = ..%New()
			Set ms = $system.SQL.DATEDIFF("ms","1970-01-01",$zdate($zdatetimeh(value _ " " _ now.getFullYear(),15),3))
		}

		Set d = ##class(Date).%New()
		Set d.time = ms
		Set retVal=..zenDateToString(d,hasTime,format,sep)
	}
	catch{
	}
	quit retVal
}

ClassMethod stringToDate(dval As %String)
{
	Set str = ..ParseDate(dval,1)
	If (("" = str)||(-1 = str)) Quit ""
	Set d = ..createDate($$$PARSEINT($e(str,1,4)),$$$PARSEINT($e(str,6,7))-1,$$$PARSEINT($e(str,9,10)))
	Quit d
}

}
