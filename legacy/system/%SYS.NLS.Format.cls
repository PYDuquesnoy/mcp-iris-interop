/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// This class exposes the NLS properties related
/// to Date, Time and Number formats. Their initial
/// values come from the current locale defaults.
/// Changing a property of an instantiated object
/// affects only the current process. For more details
/// see the documentation for $ZDATE, $ZDATEH, $FNUMBER.<br><br>
/// 
/// For generic locale properties see <class>%SYS.NLS.Locale</class>.<br>
/// For system and process NLS table settings see <class>%SYS.NLS.Table</class>.<br>
/// For current device NLS properties see <class>%SYS.NLS.Device</class>.<br>
Class %SYS.NLS.Format Extends (%RegisteredObject, %SYSTEM.Help) [ Inheritance = right, System = 4 ]
{

/// Sufix which may optionally be appended to time values
/// prior to 12 noon.<br><br>
/// Example: "AM"
Property AM As %String;

/// The DateFormat code used whenever a $ZDATE, $ZDATEH,
/// $ZDATETIME or $ZDATETIMEH function call omits its second
/// parameter, or specifies	a second parameter value of -1.<br><br>
/// Example: 1
Property DateFormat As %Integer;

/// The maximum value for a date allowed in $ZDATE, $ZDATEH,
/// $ZDATETIME or $ZDATETIMEH functions.<br><br>
/// Example: 94232  (12/30/2098)
Property DateMaximum As %Integer;

/// The minimum value for a date allowed in $ZDATE, $ZDATEH,
/// $ZDATETIME or $ZDATETIMEH functions.<br><br>
/// Example: 1
Property DateMinimum As %Integer;

/// The character used to delimit the months, days, and years
/// of those dates which are otherwise entirely numeric.<br><br>
/// Example: "/"
Property DateSeparator As %String;

/// The character used by the $FNUMBER function to separate
/// the whole part of a number from the fractional part of
/// the number. Also used by $ZDATETIME, $ZDATETIMEH, $ZTIME
/// and $ZTIMEH to separate the whole part of the seconds from
/// the optional fractional part of the seconds, if any.<br><br>
/// Example: "."
Property DecimalSeparator As %String;

/// This property controls the source of the formats.<br><br>
/// 
/// Locale="" means that the system default formats
/// (usually US English) are in effect for the current
/// process.<br><br>
/// 
/// Locale="&lt;locale name&gt;" (eg: "rusw" or "csy8") means that
/// the formats come from that locale.<br><br>
/// 
/// This property may be changed after the object is instantiated
/// or by passing the desired locale to %New. For example:<br><br>
/// 
/// Set fmt=##class(%SYS.NLS.Format).%New("jpnw")<br><br>
/// 
/// As a convenience, the word "Current" can be used instead of
/// a locale name in order to mean the current locale.
Property Locale As %String;

/// This is where the Locale is actually stored.
Property PrivateLocale As %String [ Internal ];

/// The suffix which may optionally be appended to time
/// values corresponding to exactly 12 midnight.<br><br>
/// Example: "MIDNIGHT"
Property Midnight As %String;

/// The character which may precede or follow a negative
/// numeric quantity formatted by the $FNUMBER function.<br><br>
/// Example: "-"
Property MinusSign As %String;

/// The abbreviations of the names of the twelve months,
/// used whenever a $ZDATE, $ZDATEH, $ZDATETIME or $ZDATETIMEH
/// function call omits its MonthNameList parameter, or specifies
/// a MonthNameList parameter value of -1, and the selected date
/// format uses month name abbreviations (i.e., the effective
/// DateFormat code is 0, 2, 5, 6 or 7)<br><br>
/// Example: " Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
Property MonthAbbr As %String;

/// The full names of the twelve months, used whenever a
/// $ZDATE, $ZDATEH, $ZDATETIME or $ZDATETIMEH function call
/// omits its MonthNameList parameter, or specifies a MonthNameList
/// parameter value of -1, and the selected date format uses full
/// month names (i.e., the effective DateFormat code is 9).<br><br>
/// Example: " January February March April... November December"
Property MonthName As %String;

/// The suffix which may optionally be appended to time values
/// corresponding to exactly 12 noon.<br><br>
/// Example: "NOON"
Property Noon As %String;

/// The character used to separate groups of numeric digits
/// within the whole number portion of a number formatted by
/// the $FNUMBER function.<br><br>
/// Example: ","
Property NumericGroupSeparator As %String;

/// The number of digits in a numeric group formatted by the
/// $FNUMBER function.<br><br>
/// Example: 3
Property NumericGroupSize As %Integer;

/// The suffix which may optionally be appended to time values
/// at or after 12 noon.<br><br>
/// Example: "PM"
Property PM As %String;

/// The character which may optionally precede or follow a
/// non-negative numeric quantity formatted by the $FNUMBER
/// function.<br><br>
/// Example: "+"
Property PlusSign As %String;

/// The TimeFormat code used whenever a $ZDATETIME, $ZDATETIMEH,
/// $ZTIME or $ZTIMEH function call omits its TimeFormat parameter,
/// or specifies a TimeFormat parameter value of -1.<br><br>
/// Example: 1
Property TimeFormat As %Integer;

/// The number of fractional digits displayed in a time value
/// whenever a $ZDATETIME or $ZTIME function call omits its
/// Precision parameter, or specifies a Precision parameter
/// value of -1.<br><br>
/// Example: 0
Property TimePrecision As %Integer;

/// The character used to delimit the hours, minutes and seconds
/// in a time value.<br><br>
/// Example: ":"
Property TimeSeparator As %String;

/// The abbreviations of the names of the seven days of the
/// week, starting with Sunday and ending with Saturday, used
/// whenever a $ZDATE or $ZDATEIME function call selects a date
/// format which uses weekday name abbreviations (i.e., the
/// effective DateFormat code is 11).<br><br>
/// Example: " Sun Mon Tue Wed Thu Fri Sat"
Property WeekdayAbbr As %String;

/// The full names of the seven days of the week, starting
/// with Sunday and ending with Saturday, used whenever a
/// $ZDATE or $ZDATEIME function call selects a date format
/// which uses full weekday names (i.e., the effective
/// DateFormat code is 12).<br><br>
/// Example: " Sunday Monday Tuesday... Friday Saturday"
Property WeekdayName As %String;

/// The YearOption code used whenever a $ZDATE, $ZDATEH,
/// $ZDATETIME or $ZDATETIMEH function call omits its
/// YearOption parameter, or specifies a YearOption parameter
/// value of -1.<br><br>
/// Example: 0
Property YearOption As %Integer;

Method LocaleGet() As %String [ Internal ]
{
	Quit ..PrivateLocale
}

Method LocaleSet(new As %String) As %Status [ Internal ]
{
 Set new=$ZCVT(new,"L"),old=..PrivateLocale
 If new="current" Set new=$$$LOCALENAME
 #; If new locale == old locale, don't do anything
 If new'=old {
	#; If new locale = "", revert to system formats
	If new="" { Do $ZU(122,0,0) }
	Else {
		#; Check if new locale is available
		Set ref=$Name($$$NLSLocalesGbl)
		If '$D(@ref@(new),lrec) Quit $$$ERROR($$$GeneralError,"Locale not available: "_new)
		#; Load formats from new locale
		Do $ZU(122,$$$FMTDateFormat,$$$GetLocaleDateFormat(lrec))
		Do $ZU(122,$$$FMTYearOption,$$$GetLocaleYearOption(lrec))
		Do $ZU(122,$$$FMTTimeFormat,$$$GetLocaleTimeFormat(lrec))
		Do $ZU(122,$$$FMTTimePrecision,$$$GetLocaleTimePrecision(lrec))
		Do $ZU(122,$$$FMTNumericGroupSize,$$$GetLocaleNumericGroupSize(lrec))
		Do $ZU(122,$$$FMTDecimalSeparator,$$$GetLocaleDecimalSeparator(lrec))
		Do $ZU(122,$$$FMTNumericGroupSeparator,$$$GetLocaleNumericGroupSeparator(lrec))
		Do $ZU(122,$$$FMTDateSeparator,$$$GetLocaleDateSeparator(lrec))
		Do $ZU(122,$$$FMTTimeSeparator,$$$GetLocaleTimeSeparator(lrec))
		Do $ZU(122,$$$FMTPlusSign,$$$GetLocalePlusSign(lrec))
		Do $ZU(122,$$$FMTMinusSign,$$$GetLocaleMinusSign(lrec))
		Do $ZU(122,$$$FMTAM,$$$GetLocaleAM(lrec))
		Do $ZU(122,$$$FMTPM,$$$GetLocalePM(lrec))
		Do $ZU(122,$$$FMTNoon,$$$GetLocaleNoon(lrec))
		Do $ZU(122,$$$FMTMidnight,$$$GetLocaleMidnight(lrec))
		Do $ZU(122,$$$FMTMonthAbbr,$$$GetLocaleMonthAbbr(lrec))
		Do $ZU(122,$$$FMTMonthName,$$$GetLocaleMonthName(lrec))
		Do $ZU(122,$$$FMTWeekdayAbbr,$$$GetLocaleWeekdayAbbr(lrec))
		Do $ZU(122,$$$FMTWeekdayName,$$$GetLocaleWeekdayName(lrec))
		Do $ZU(122,$$$FMTDateMinimum,$$$GetLocaleDateMinimum(lrec))
		Do $ZU(122,$$$FMTDateMaximum,$$$GetLocaleDateMaximum(lrec))
	}
	#; Set internal locale
	Set ..PrivateLocale=new
 }
 Quit $$$OK
 
DCFtrap Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

Method AMGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTAM)
}

Method AMSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTAM,value)
}

Method PMGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTPM)
}

Method PMSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTPM,value)
}

Method NoonGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTNoon)
}

Method NoonSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTNoon,value)
}

Method MidnightGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTMidnight)
}

Method MidnightSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTMidnight,value)
}

Method MonthNameGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTMonthName)
}

Method MonthNameSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTMonthName,value)
}

Method MonthAbbrGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTMonthAbbr)
}

Method MonthAbbrSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTMonthAbbr,value)
}

Method WeekdayNameGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTWeekdayName)
}

Method WeekdayNameSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTWeekdayName,value)
}

Method WeekdayAbbrGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTWeekdayAbbr)
}

Method WeekdayAbbrSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTWeekdayAbbr,value)
}

Method DateFormatGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTDateFormat)
}

Method DateFormatSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTDateFormat,value)
}

Method DateMinimumGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTDateMinimum)
}

Method DateMinimumSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTDateMinimum,value)
}

Method DateMaximumGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTDateMaximum)
}

Method DateMaximumSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTDateMaximum,value)
}

Method DateSeparatorGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTDateSeparator)
}

Method DateSeparatorSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTDateSeparator,value)
}

Method YearOptionGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTYearOption)
}

Method YearOptionSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTYearOption,value)
}

Method TimeFormatGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTTimeFormat)
}

Method TimeFormatSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTTimeFormat,value)
}

Method TimePrecisionGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTTimePrecision)
}

Method TimePrecisionSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTTimePrecision,value)
}

Method TimeSeparatorGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTTimeSeparator)
}

Method TimeSeparatorSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTTimeSeparator,value)
}

Method DecimalSeparatorGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTDecimalSeparator)
}

Method DecimalSeparatorSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTDecimalSeparator,value)
}

Method NumericGroupSeparatorGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTNumericGroupSeparator)
}

Method NumericGroupSeparatorSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTNumericGroupSeparator,value)
}

Method NumericGroupSizeGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTNumericGroupSize)
}

Method NumericGroupSizeSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTNumericGroupSize,value)
}

Method MinusSignGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTMinusSign)
}

Method MinusSignSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTMinusSign,value)
}

Method PlusSignGet() As %String [ Internal ]
{
 Quit $ZU(122,$$$FMTPlusSign)
}

Method PlusSignSet(value As %String) As %Status [ Internal ]
{
 Quit ..setitem($$$FMTPlusSign,value)
}

/// Helper function to the PropSet methods.
/// Parameters:<ul>
///   <li>index - item index
///   <li>val   - new value for item</li></ul>
/// Returns: previous item value or "" in case of error
ClassMethod setitem(index As %Integer, val As %String) As %Status [ Internal ]
{
 Set $ZT="DCFtrap"
 Do $ZU(122,index,val)
 Quit $$$OK
 
DCFtrap Quit $$$ERROR($$$InvalidArgument)
}

/// Gets a format item from the current process context<br><br>
/// Parameter:<ul>
///   <li>item - item name (eg: "YEAROPTION", "DATEFORMAT")</li></ul>
/// Returns: selected item or "" in case of error
ClassMethod GetFormatItem(item As %String) As %String
{
 Set $ZT="DCFtrap"
 Set index=..getformatindex(item) 
 If index'<0 Quit $ZU(122,index)
 
DCFtrap Quit ""
}

/// Sets a format item in the current process context<br><br>
/// Parameters:<ul>
///   <li>item - item name (eg: "YEAROPTION", "DATEFORMAT")</li>
///   <li>val - new value for item</li></ul>
/// Returns: previous item value or "" in case of error
ClassMethod SetFormatItem(item As %String, val As %String) As %String
{
 Set $ZT="DCFtrap"
 Set index=..getformatindex(item) 
 If index'<0 Quit $ZU(122,index,val)
 
DCFtrap Quit ""
}

/// Gets the index associated with a Format item name<br><br>
/// Parameter:<ul>
///   <li>item - item name (eg: "YEAROPTION", "DATEFORMAT")</li></ul>
/// Returns: item index or -1 in case of error
ClassMethod getformatindex(item As %String) As %Integer [ Internal ]
{
 Quit $Case($ZCVT(item,"U"),"DATEFORMAT":1,"YEAROPTION":2,"TIMEFORMAT":3,"TIMEPRECISION":4,"NUMERICGROUPSIZE":5,"DECIMALSEPARATOR":6,"NUMERICGROUPSEPARATOR":7,"DATESEPARATOR":8,"TIMESEPARATOR":9,"PLUSSIGN":10,"MINUSSIGN":11,"AM":12,"PM":13,"NOON":14,"MIDNIGHT":15,"MONTHABBR":16,"MONTHNAME":17,"WEEKDAYABBR":18,"WEEKDAYNAME":19,"DATEMINIMUM":20,"DATEMAXIMUM":21,:-1)
}

/// Gets the system flag that indicates whether date/time/number
/// functions should use the locale format by default. Besides, if
/// a new boolean flag is passed as an argument, the system flag
/// is set to this new value. A system reboot or locale reload is
/// necessary to activate the change.<br><br>
/// Parameter: (optional)<ul>
///   <li>new - sets locale format flag to this value (0 or 1)</li></ul>
/// Returns: previous value of the system locale format flag
ClassMethod UseLocale(new As %Boolean) As %Boolean
{
	Set ref=$Name($$$NLSConfigGbl),gbl=$Name(@ref@("LocaleFormat"))
	Set old=$G(@gbl,0)
	If $D(new),$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) {
		If new Set @gbl=new
		Else  Kill @gbl
	}
	Quit old
}

Method %OnNew(loc As %String = "") As %Status [ Internal ]
{
 If loc="" Do $ZU(122,0,0)
 Quit ..LocaleSet(loc)
}

}
