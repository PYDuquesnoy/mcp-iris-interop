/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlx

Class %SYSTEM.SQL.Functions Extends %SYSTEM.Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// ABS returns the absolute value, which is always zero or a positive number
/// <p>
/// $SYSTEM.SQL.Functions.ABS(<i>numeric-expression</i>)<br>
/// <dl>
/// <dt><i>numeric-expression</i>
/// <dd>A number whose absolute value is to be returned<br>
/// </dl>
/// ABS returns the same data type as numeric-expression. If numeric-expression is not a number (for example, the string 'abc') ABS returns 0. ABS returns NULL when passed a NULL value. 
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+ABS">ABS</a> reference page.
/// </p>
ClassMethod ABS(val As %Library.String = "") As %Library.Float [ ProcedureBlock = 1 ]
{
	QUIT $s(val="":"",1:$zabs(+val))
}

/// ALPHAUP returns the Alphaup collation of the passed in value.
/// <dl>
/// <dt>$SYSTEM.SQL.Functions.ALPHAUP(<i>stringexp</i>)<br>
/// <dd><i>stringexp</i> Any string expression value.<br>
/// ALPHAUP converts all alphabetic characters to upper case (i.e., the ALPHAUP format) and removes all punctuation except commas and question marks.
/// </dl>
ClassMethod ALPHAUP(stringexp As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$ALPHAUP(stringexp)
}

/// FLOOR is a numeric function that returns the largest integer less than or equal to a given numeric expression
/// <p>
/// $SYSTEM.SQL.Functions.FLOOR(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>numeric-exp</i>
/// <dd>A number whose floor is to be calculated.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+FLOOR">FLOOR</a> reference page.
/// </p>
ClassMethod FLOOR(val As %Library.Numeric = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	QUIT $$$floor(val)
}

/// CEILING is a scalar numeric function that returns the smallest integer greater than or equal to a given numeric expression.
/// <p>
/// $SYSTEM.SQL.Functions.CEILING(<i>numeric-expression</i>)<br>
/// <dl>
/// <dt><i>numeric-expression</i>
/// <dd>A number whose ceiling is to be calculated<br>
/// </dl>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+CEILING">CEILING</a> reference page.
/// </p>
ClassMethod CEILING(val As %Library.String = "") As %Library.Float [ ProcedureBlock = 1 ]
{
	QUIT $$$ceiling(val)
}

/// CONVERT is a SQL function that converts a given expression to a specified data type.
/// <p>
/// $SYSTEM.SQL.Functions.CONVERT(<i>expr</i>,<i>convto</i>,<i>convfrom</i>)<br>
/// <dl>
/// <dt><i>expr</i>
/// <dd>The expression to be converted<br>
/// <dt><i>convto</i>
/// <dd>The data type to which <i>expr</i> is to be converted. Currently, only "SQL_TIMESTAMP", "SQL_POSIXTIME", "SQL_TIME", "SQL_DATE", "SQL_VARCHAR", "SQL_INTEGER", and "SQL_DOUBLE" are supported<br>
/// <dt><i>convfrom</i>
/// <dd>The data type of <i>expr</i>. Currently, only "SQL_TIMESTAMP", "SQL_POSIXTIME", "SQL_TIME", "SQL_DATE", "SQL_VARCHAR", "SQL_INTEGER", and "SQL_DOUBLE" are supported<br>
/// </dl>
/// CONVERT is a SQL function that converts expression <i>expr</i> from type <i>convfrom</i> to the specified data type <i>convto</i>.<br>
/// The <i>convfrom</i> value is expected to be a Logical value for SQL_DATE and SQL_TIME.
/// When converting from SQL_DATE, SQL_POSIXTIME, or SQL_TIME to SQL_TIMESTAMP, the input value is expected to be a logical <class>%Library.Date</class>, <class>%Library.PosixTime</class>, or <class>%Library.Time</class> value.
/// When converting from SQL_VARCHAR to SQL_TIME, the input value is expected to be an ODBC <class>%Library.Time</class> formatted value.
/// When converting from SQL_VARCHAR to SQL_DATE, the input value is expected to be an ODBC <class>%Library.Date</class> formatted value.
/// When converting from SQL_DATE, SQL_POSIXTIME, or SQL_TIME to SQL_VARCHAR, the returned value will contain the ODBC format of the <class>%Library.Date</class>, <class>%Library.PosixTime</class>, or <class>%Library.Time</class> value.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+CONVERT">CONVERT</a> reference page.
/// </p>
ClassMethod CONVERT(expr As %Library.String = "", convto As %Library.String = "", convfrom As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT:expr="" ""
	set convto=$$$UPPER(convto),convfrom=$$$UPPER(convfrom)
	if convto="SQL_POSIXTIME" {
		if convfrom="SQL_DATE" QUIT ##class(%Library.PosixTime).DateToLogical(expr)
		if convfrom="SQL_TIME" QUIT ##class(%Library.PosixTime).TimeToLogical(expr)
		if convfrom="SQL_TIMESTAMP" QUIT ##class(%Library.PosixTime).OdbcToLogical(expr)
		QUIT expr
	}
	if convto="SQL_TIMESTAMP" {
		if convfrom="SQL_DATE" QUIT ##class(%Library.Date).LogicalToOdbc(expr)_" 00:00:00"
		if convfrom="SQL_TIME" QUIT ##class(%Library.Date).LogicalToOdbc(+$H)_" "_##class(%Library.Time).LogicalToOdbc(expr)
		if convfrom="SQL_POSIXTIME" QUIT ##class(%Library.PosixTime).LogicalToOdbc(expr)
		QUIT expr
	}
	if convto="SQL_TIME" {
		if convfrom="SQL_POSIXTIME" QUIT ##class(%Library.PosixTime).LogicalToTime(expr)
		if convfrom="SQL_TIMESTAMP" QUIT $p($zdatetimeh(expr,3,,,,,,,,""),",",2)
		if convfrom="SQL_VARCHAR" QUIT $ztimeh(expr,,"")
		QUIT +expr\1
	}
	if convto="SQL_DATE" {
		if convfrom="SQL_POSIXTIME" QUIT ##class(%Library.PosixTime).LogicalToDate(expr)
		if convfrom="SQL_TIMESTAMP" QUIT $zdh(expr,3,,,,,,,"")
		if convfrom="SQL_VARCHAR" QUIT $zdh(expr,3,,,,,,,"")
		QUIT +expr\1
	}
	if convto="SQL_VARCHAR" {
		if convfrom="SQL_POSIXTIME" QUIT ##class(%Library.PosixTime).LogicalToOdbc(expr)
		if convfrom="SQL_DATE" QUIT ##class(%Library.Date).LogicalToOdbc(expr)
		if convfrom="SQL_TIME" QUIT ##class(%Library.Time).LogicalToOdbc(expr)
		QUIT expr
	}
	if convto="SQL_INTEGER" { QUIT +expr\1 }
	if convto="SQL_DOUBLE" { QUIT $double(expr) }
	QUIT ""
}

/// DATE is a date/time function that returns the date portion of the given date or timestamp expression.
/// <p>
/// $SYSTEM.SQL.Functions.DATE(<i>exp</i>)<br>
/// <dl>
/// <dt><i>exp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, <class>%Library.PosixTime</class>, %Library.Integer, or %Library.String value.<br>
/// </dl>
/// If "" (null) is passed in, "" (null) is returned.  If <i>exp</i> is not numeric, it is assumed the expression is in <class>%Library.TimeStamp</class> logical format.
/// Note, that if a string value is passed in as <i>exp</i>, it is expected that the value is a logical <class>%Library.TimeStamp</class> format, and not $Horolog format.  To convert $Horolog to DATE, use $SYSTEM.SQL.Functions.DATE(+$HOROLOG),<br>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DATE">DATE</a> reference page.
/// </p>
ClassMethod DATE(exp As %Library.String = "") As %Library.Date [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(exp) { set exp=##class(%Library.PosixTime).LogicalToDate(exp) }
	QUIT $s(exp="":"",$isvalidnum(exp):+exp\1,1:$zdateh(exp,3,,,,,-672045,,0))
}

/// DATEADD is a general date/time function that returns a date calculated by adding a certain number of date parts (such as hours or days) to a specified timestamp
/// <p>
/// $SYSTEM.SQL.Functions.DATEADD(<i>datepart</i>,<i>numeric-exp</i>,<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>datepart</i>
/// <dd>The full name or abbreviation of a date or time part.<br>
/// The following date parts are supported for DATEADD<br>
///     year		yy		yyyy<br>
///     quarter         qq		q<br>
///     month           mm		m<br>
///     week            wk		ww<br>
///     dayofyear       dy		y<br>
///     day             dd		d<br>
///     hour            hh		<br>
///     minute          mi		n<br>
///     second          ss		s<br>
///     millisecond     ms<br>
/// <dt><i>numeric-exp</i>
/// <dd>A numeric expression of any number type. The value is truncated to an integer. 
/// The value indicates the number of dateparts that will be added to <i>dateexp</i>.<br>
/// <dt><i>dateexp</i>
/// <dd>The date/time expression that will be modified.<br>
/// The <i>dateexp</i> parameter can be in any of the following formats, and may include or omit fractional seconds:
/// <ul>
/// <li> A <class>%Library.Date</class> logical value (+$H)</li>
/// <li> A <class>%Library.PosixTime</class> logical value</li>
/// <li> A <class>%Library.TimeStamp</class> logical value (YYYY-MM-DD HH:MM:SS)</li>
/// <li> A <class>%Library.String</class> (or compatible) value</li>
/// The <class>%Library.String</class> (or compatible) value can be in any of the following formats:<br>
///  <class>%Library.PosixTime</class> logical value
///  99999,99999 ($H format)<br>
///  Sybase/SQL-Server-date Sybase/SQL-Server-time<br>
///  Sybase/SQL-Server-time Sybase/SQL-Server-date<br>
///  Sybase/SQL-Server-date (default time is 00:00:00)<br>
///  Sybase/SQL-Server-time (default date is 01/01/1900)<br>
/// Sybase/SQL-Server-date is one of these five formats:<br>
/// mm<i>delimiter</i>dd<i>delimiter</i>[yy]yy<br>
/// dd Mmm[mm][,][yy]yy<br>
/// dd [yy]yy Mmm[mm]<br>
/// yyyy Mmm[mm] dd<br>
/// yyyy [dd] Mmm[mm]<br>
/// where <i>delimiter</i> is a slash (/), hyphen (-), or period (.).<br>
/// Sybase/SQL-Server-time represents one of these three formats:<br>
/// HH:MM[:SS:SSS][{AM|PM}]<br>
/// HH:MM[:SS.S]<br>
/// HH['']{AM|PM}<br>
/// </ul>
/// If the year is given as two digits, a sliding window is checked to interpret the date. The system default for the sliding window can be set via the %DATE utility, which is documented only in the "Legacy Documentation" chapter in Using InterSystems Documentation.
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DATEADD">DATEADD</a> reference page.
/// </p>
ClassMethod DATEADD(datepart As %Library.String = "", val As %Library.Numeric = "", dateexp As %Library.String = "") As %Library.TimeStamp [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$dateadd^%qarfunc(datepart,val,dateexp)
}

/// DATEDIFF is a general date/time function that returns the interval between two dates
/// <p>$SYSTEM.SQL.Functions.DATEDIFF(<i>datepart</i>,<i>startdate</i>,<i>enddate</i>)<br>
/// <dl>
/// <dt><i>datepart</i>
/// <dd>The date part in which the interval is to be measured.<br>
/// The following date parts are supported for DATEDIFF<br>
///     year		yy		yyyy<br>
///     month           mm		m<br>
///     week            wk		ww<br>
///     day             dd		d<br>
///     hour            hh		<br>
///     minute          mi		n<br>
///     second          ss		s<br>
///     millisecond     ms<br>
/// <dt><i>startdate</i>
/// <dd>The starting date for the interval.<br>
/// <dt><i>enddate</i>
/// <dd>The ending date for the interval.
/// </dl>
/// Startdate is subtracted from enddate to determine how many datepart intervals are between the two dates.<br>
/// The <i>startdate</i> and <i>enddate</i> parameters can be in any of the following formats:
/// <ul>
/// <li> A <class>%Library.Date</class> logical value (+$H)</li>
/// <li> A <class>%Library.PosixTime</class> logical value</li>
/// <li> A <class>%Library.TimeStamp</class> logical value (YYYY-MM-DD HH:MM:SS)</li>
/// <li> A <class>%Library.String</class> (or compatible) value</li>
/// <li>The <class>%Library.String</class> (or compatible) value can be in any of the following formats, and may include or omit fractional seconds:</li><br>
///  99999,99999 ($HOROLOG format)<br>
///  Sybase/SQL-Server-date Sybase/SQL-Server-time<br>
///  Sybase/SQL-Server-time Sybase/SQL-Server-date<br>
///  Sybase/SQL-Server-date (default time is 00:00:00)<br>
///  Sybase/SQL-Server-time (default date is 01/01/1900)<br>
/// <li>Sybase/SQL-Server-date is one of these five formats:</li><br>
/// mm<i>delimiter</i>dd<i>delimiter</i>[yy]yy<br>
/// dd Mmm[mm][,][yy]yy<br>
/// dd [yy]yy Mmm[mm]<br>
/// yyyy Mmm[mm] dd<br>
/// yyyy [dd] Mmm[mm]<br>
/// where <i>delimiter</i> is a slash (/), hyphen (-), or period (.).
/// <li>Sybase/SQL-Server-time represents one of these three formats:</li><br>
/// HH:MM[:SS:SSS][{AM|PM}]<br>
/// HH:MM[:SS.S]<br>
/// HH['']{AM|PM}<br>
/// </ul>
/// If the year is given as two digits, a sliding window is checked to interpret the date. The system default for the sliding window can be set via the %DATE utility, which is documented only in the "Legacy Documentation" chapter in Using InterSystems Documentation.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DATEDIFF">DATEDIFF</a> reference page.
/// </p>
ClassMethod DATEDIFF(datepart As %Library.String = "", startdate As %Library.String = "", enddate As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$datediff^%qarfunc(datepart,startdate,enddate)
}

/// DATETRUNC is a general date/time function that truncates a date to 
/// <p>$SYSTEM.SQL.Functions.DATETRUNC(<i>datepart</i>,<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>datepart</i>
/// <dd>The type of date part that the returned value will represent.<br>
/// The following date parts are supported for DATEDIFF<br>
///     YEAR		YYYY	YY<br>
/// 	QUARTER  	QQ		Q<br>
///     MONTH		MM 		M<br>
///     WEEK		WK		WW<br>
/// 	WEEKDAY		DW		W<br>
///     DAY			DD		D<br>
/// 	DAYOFYEAR	DY		Y<br>
///     HOUR		HH		H<br>
///     MINUTE		MI		N<br>
///     SECOND		SS		S<br>
/// 	MILLISECOND	MS<br>
/// 	MICROSECOND MCS<br>
/// 	NANOSECOND	NS<br> 
/// <dt><i>dateexp</i>
/// <dd>A date/time expression to be truncated to a granularity specified by datepart
/// </dl>
/// The <i>dateexp</i> parameter can be in any of the following formats:
/// <ul>
/// <li> A <class>%Library.Date</class> logical value (+$H)</li>
/// <li> A <class>%Library.PosixTime</class> logical value</li>
/// <li> A <class>%Library.TimeStamp</class> logical value (YYYY-MM-DD HH:MM:SS)</li>
/// <li> A <class>%Library.String</class> (or compatible) value</li>
/// <li>The <class>%Library.String</class> (or compatible) value can be in any of the following formats, and may include or omit fractional seconds:</li><br>
///  99999,99999 ($HOROLOG format)<br>
///  Sybase/SQL-Server-date Sybase/SQL-Server-time<br>
///  Sybase/SQL-Server-time Sybase/SQL-Server-date<br>
///  Sybase/SQL-Server-date (default time is 00:00:00)<br>
///  Sybase/SQL-Server-time (default date is 01/01/1900)<br>
/// <li>Sybase/SQL-Server-date is one of these five formats:</li><br>
/// mm<i>delimiter</i>dd<i>delimiter</i>[yy]yy<br>
/// dd Mmm[mm][,][yy]yy<br>
/// dd [yy]yy Mmm[mm]<br>
/// yyyy Mmm[mm] dd<br>
/// yyyy [dd] Mmm[mm]<br>
/// where <i>delimiter</i> is a slash (/), hyphen (-), or period (.).
/// <li>Sybase/SQL-Server-time represents one of these three formats:</li><br>
/// HH:MM[:SS:SSS][{AM|PM}]<br>
/// HH:MM[:SS.S]<br>
/// HH['']{AM|PM}<br>
/// </ul>
/// If the year is given as two digits, a sliding window is checked to interpret the date. The system default for the sliding window can be set via the %DATE utility, which is documented only in the "Legacy Documentation" chapter in Using InterSystems Documentation.
/// </p>
ClassMethod DATETRUNC(datepart As %Library.String = "", tdate As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$datetrunc^%qarfunc(datepart,tdate)
}

/// DATENAME is a general date/time function that returns a CHARACTER STRING containing the name of the specified date part of a date/time value.
/// <p>
/// $SYSTEM.SQL.Functions.DATENAME(<i>datepart</i>,<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>datepart</i>
/// <dd>The type of date part that the returned value will represent.<br>
/// The following date parts are supported for DATENAME<br>
///     year		yy		yyyy<br>
///     quarter         qq		q<br>
///     month           mm		m<br>
///     week            wk		ww<br>
/// 	weekday		dw<br>
///     dayofyear       dy		y<br>
///     day             dd		d<br>
///     hour            hh		<br>
///     minute          mi		n<br>
///     second          ss		s<br>
///     millisecond     ms<br>
/// <dt><i>dateexp</i>
/// <dd>A date/time expression from which the date part is to be returned.
/// </dl>
/// The <i>dateexp</i> parameter can be in any of the following formats:
/// <ul>
/// <li> A <class>%Library.Date</class> logical value (+$H)</li>
/// <li> A <class>%Library.PosixTime</class> logical value</li>
/// <li> A <class>%Library.TimeStamp</class> logical value (YYYY-MM-DD HH:MM:SS)</li>
/// <li> A <class>%Library.String</class> (or compatible) value</li>
/// <li>The <class>%Library.String</class> (or compatible) value can be in any of the following formats, and may include or omit fractional seconds:</li><br>
///  99999,99999 ($HOROLOG format)<br>
///  Sybase/SQL-Server-date Sybase/SQL-Server-time<br>
///  Sybase/SQL-Server-time Sybase/SQL-Server-date<br>
///  Sybase/SQL-Server-date (default time is 00:00:00)<br>
///  Sybase/SQL-Server-time (default date is 01/01/1900)<br>
/// <li>Sybase/SQL-Server-date is one of these five formats:</li><br>
/// mm<i>delimiter</i>dd<i>delimiter</i>[yy]yy<br>
/// dd Mmm[mm][,][yy]yy<br>
/// dd [yy]yy Mmm[mm]<br>
/// yyyy Mmm[mm] dd<br>
/// yyyy [dd] Mmm[mm]<br>
/// where <i>delimiter</i> is a slash (/), hyphen (-), or period (.).
/// <li>Sybase/SQL-Server-time represents one of these three formats:</li><br>
/// HH:MM[:SS:SSS][{AM|PM}]<br>
/// HH:MM[:SS.S]<br>
/// HH['']{AM|PM}<br>
/// </ul>
/// If the year is given as two digits, a sliding window is checked to interpret the date. The system default for the sliding window can be set via the %DATE utility, which is documented only in the "Legacy Documentation" chapter in Using InterSystems Documentation.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DATENAME">DATENAME</a> reference page.
/// </p>
ClassMethod DATENAME(datepart As %Library.String = "", dateexp As %Library.String = "") As %Library.String [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$datename^%qarfunc(datepart,dateexp)
}

/// DATEPART is a general date/time function that returns an INTEGER representing the specified date/time part of the specified date/time expression.
/// <p>
/// $SYSTEM.SQL.Functions.DATEPART(<i>datepart</i>,<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>datepart</i>
/// <dd>The type of date part that the returned value will represent.<br>
/// The following date parts are supported for DATEPART<br>
///     year		yy		yyyy<br>
///     quarter         qq		q<br>
///     month           mm		m<br>
///     week            wk		ww<br>
/// 	weekday		dw<br>
///     dayofyear       dy		y<br>
///     day             dd		d<br>
///     hour            hh		<br>
///     minute          mi		n<br>
///     second          ss		s<br>
///     millisecond     ms<br>
///     sqltimestamp	sts<br>
/// The sqltimestamp (abbreviated sts) datepart value is for use only with DATEPART. Do not attempt to use this parameter value in other contexts
/// <dt><i>dateexp</i>
/// <dd>A date/time expression from which the date part is to be returned.
/// </dl>
/// <i>dateexp</i> must contain a value of type datepart.<br>
/// The <i>dateexp</i> parameter can be in any of the following formats:
/// <ul>
/// <li> A <class>%Library.Date</class> logical value (+$H)</li>
/// <li> A <class>%Library.PosixTime</class> logical value</li>
/// <li> A <class>%Library.TimeStamp</class> logical value (YYYY-MM-DD HH:MM:SS)</li>
/// <li> A <class>%Library.String</class> (or compatible) value</li>
/// <li>The <class>%Library.String</class> (or compatible) value can be in any of the following formats, and may include or omit fractional seconds:</li><br>
///  99999,99999 ($HOROLOG format)<br>
///  Sybase/SQL-Server-date Sybase/SQL-Server-time<br>
///  Sybase/SQL-Server-time Sybase/SQL-Server-date<br>
///  Sybase/SQL-Server-date (default time is 00:00:00)<br>
///  Sybase/SQL-Server-time (default date is 01/01/1900)<br>
/// <li>Sybase/SQL-Server-date is one of these five formats:</li><br>
/// mm<i>delimiter</i>dd<i>delimiter</i>[yy]yy<br>
/// dd Mmm[mm][,][yy]yy<br>
/// dd [yy]yy Mmm[mm]<br>
/// yyyy Mmm[mm] dd<br>
/// yyyy [dd] Mmm[mm]<br>
/// where <i>delimiter</i> is a slash (/), hyphen (-), or period (.).
/// <li>Sybase/SQL-Server-time represents one of these three formats:</li><br>
/// HH:MM[:SS:SSS][{AM|PM}]<br>
/// HH:MM[:SS.S]<br>
/// HH['']{AM|PM}<br>
/// </ul>
/// If the year is given as two digits, a sliding window is checked to interpret the date. The system default for the sliding window can be set via the %DATE utility, which is documented only in the "Legacy Documentation" chapter in Using InterSystems Documentation.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DATEPART">DATEPART</a> reference page.
/// </p>
ClassMethod DATEPART(datepart As %Library.String = "", dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$datepart^%qarfunc(datepart,dateexp)
}

/// DAYNAME is a date/time function that returns a character string containing the name of the day in a given date or datetime expression.
/// <p>
/// $SYSTEM.SQL.Functions.DAYNAME(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// If the year is given as two digits, a sliding window is checked to interpret the date. The system default for the sliding window can be set via the %DATE utility, which is documented only in the "Legacy Documentation" chapter in Using InterSystems Documentation.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DAYNAME">DAYNAME</a> reference page.
/// </p>
ClassMethod DAYNAME(dateexp As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToDate(dateexp) }
	QUIT $s(dateexp="":"",dateexp=+dateexp:$zdate(dateexp,12,,,,,-672045),1:$zdate($zdateh($p(dateexp," "),3,,,,,-672045),12,,,,,-672045))
}

/// DAYOFMONTH is a date/time function that returns an integer from 1 to 31 that corresponds to the day of the month in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.DAYOFMONTH(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class>.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DAYOFMONTH">DAYOFMONTH</a> reference page.
/// </p>
ClassMethod DAYOFMONTH(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToDate(dateexp) }
	QUIT $s(dateexp="":"",dateexp=+dateexp:+$zdate(dateexp,2,,,,,-672045),1:$s(+$p(dateexp,"-",3):+$p(dateexp,"-",3),1:""))
}

/// DAYOFWEEK is a date/time function that returns an integer from 1 to 7 that corresponds to the day of the week in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.DAYOFWEEK(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class> value, <class>%Library.TimeStamp</class>, <class>%Library.PosixTime</class>, or an $Horolog value.<br>
/// </dl>
/// The returned values represent these days: 1 - Sunday, 2 - Monday, 3 - Tuesday, 4 - Wednesday, 5 - Thursday, 6 - Friday, 7 - Saturday<br>
/// The default is that Sunday is the first day of the week.<br>
/// This default can be overridden by specifying SET ^%SYS("sql","sys","day of week")=n, where n values are 1=Monday through 7=Sunday.<br>
/// Thus, to reset the default specify SET ^%SYS("sql","sys","day of week")=7.<br>
/// The day of week setting can also be defined on a per-namespace basis by adding an additional namespace subscript, for example:<br>
/// SET ^%SYS("sql","sys","day of week","USER")=n, where n values are 1=Monday through 7=Sunday.<br>
/// InterSystems IRIS also supports the ISO 8601 standard for determining the day of the week, week of the year, and other date settings. 
/// This standard is principally used in European countries. The ISO 8601 standard begins counting the days of the week with Monday. 
/// To activate ISO 8601, SET ^%SYS("sql","sys","week ISO8601")=1; to deactivate, set it to 0. 
/// If week ISO8601 is activated and "day of the week" is undefined or set to the default (7=Sunday), the ISO 8601 standard overrides the default. 
/// If "day of the week" is set to any other value, it overrides week ISO8601 for DAYOFWEEK.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DAYOFWEEK">DAYOFWEEK</a> reference page.
/// </p>
ClassMethod DAYOFWEEK(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $s(dateexp="":"",dateexp=+dateexp||(dateexp?1.7N1","1.5N)||(dateexp?1.7N1","1.5N1".".N):$$DayOfWeek^%qarfunc(dateexp),1:$$DayOfWeek^%qarfunc($zdateh($p(dateexp," "),3,,,,,-672045)))
}

/// DAYOFYEAR is a date/time function that returns an integer from 1 to 366 that corresponds to the day of the year in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.DAYOFYEAR(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class> value, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+DAYOFYEAR">DAYOFYEAR</a> reference page.
/// </p>
ClassMethod DAYOFYEAR(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToDate(dateexp) }
	QUIT $s(dateexp="":"",dateexp=+dateexp:+$zdate(dateexp,14,,,,,-672045),1:+$zdate($zdateh(dateexp,3,,,,,-672045),14,,,,,-672045))
}

/// HOUR is a date/time function that returns an integer from 0 to 23 that corresponds to the hour component in a given date-time expression.
/// <p>
/// $SYSTEM.SQL.Functions.HOUR(<i>timeexp</i>)<br>
/// <dl>
/// <dt><i>timeexp</i>
/// <dd>An expression that is a logical <class>%Library.Time</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+HOUR">HOUR</a> reference page.
/// </p>
ClassMethod HOUR(timeexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(timeexp) { set timeexp=##class(%Library.PosixTime).LogicalToOdbc(timeexp) }
	QUIT $s(timeexp="":"",timeexp=+timeexp:+$p($zt(timeexp,1),$zu(122,9)),1:+$p($p(timeexp," ",2),$zu(122,9),1))
}

/// INSTR is a function that searches <i>string</i> for <i>substring</i> and returns an integer indicating the position of the character in <i>string</i> that is the first character of this <i>occurrence</i>.
/// <p>
/// $SYSTEM.SQL.Functions.INSTR(<i>string</i>,<i>substring</i>,<i>position</i>,<i>occurrence</i>)<br>
/// <dl>
/// <dt><i>string</i>
/// <dd>The string to search in.<br>
/// <dt><i>substring</i>
/// <dd>The string to search for in <i>string</i>.<br>
/// <dt><i>position</i>
/// <dd>A nonzero integer indicating the character of <i>string</i> where InterSystems IRIS begins the search.  If <i>position</i> is negative, then InterSystems IRIS counts backward from the end of <i>string</i> and then searches backward from the resulting <i>position</i>.<br>
/// <dt><i>occurrence</i>
/// <dd>An integer indicating which occurrence of <i>substring</i> InterSystems IRIS should search for.  If <i>occurrence</i> is greater than 1, then InterSystems IRIS searches for the second occurrence beginning with the second character in the first occurrence of <i>string</i>, and so forth.  An <i>occurrence</i> of less than 1 is treated the same as 1.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+INSTR">INSTR</a> reference page.
/// </p>
ClassMethod INSTR(string As %Library.String = "", substring As %Library.String = "", position As %Library.Integer = 1, occurrence As %Library.Integer = 1) As %Library.Integer [ ProcedureBlock = 1 ]
{
	QUIT $$instr^%qarfunc(string,substring,position,occurrence)
}

/// LASTDAY is a scalar date/time function that returns the <class>%Library.Date</class> value of the last day of the month for a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.LASTDAY(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>A <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or %Library.PosixTime logical value.  
/// </dl>
/// LASTDAY returns the date of the last day of the specified month as a <class>%Library.Date</class> value. Leap years differences are calculated.
/// <p>LASTDAY returns 0 when an invalid date is specified: the day or month as zero; the month greater than 12; or the day larger than the number of days in that month on that year.<br>
ClassMethod LASTDAY(dateexp As %Library.String = "") As %Library.Date [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$lastday^%qarfunc(dateexp)
}

/// MINUTE is a date/time function that returns an integer from 0 to 59 that corresponds to the minute component in a given date-time expression.
/// <p>
/// $SYSTEM.SQL.Functions.MINUTE(<i>timeexp</i>)<br>
/// <dl>
/// <dt><i>timeexp</i>
/// <dd>An expression that is a logical <class>%Library.Time</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+MINUTE">MINUTE</a> reference page.
/// </p>
ClassMethod MINUTE(timeexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(timeexp) { set timeexp=##class(%Library.PosixTime).LogicalToOdbc(timeexp) }
	QUIT $s(timeexp="":"",timeexp=+timeexp:+$p($zt(timeexp,1),$zu(122,9),2),1:+$p($p(timeexp," ",2),$zu(122,9),2))
}

/// MONTH is a date/time function that returns an integer from 1 to 12 that corresponds to the month in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.MONTH(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+MONTH">MONTH</a> reference page.
/// </p>
ClassMethod MONTH(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToDate(dateexp) }
	QUIT $s(dateexp="":"",dateexp=+dateexp:+$p($zdate(dateexp,1,,,,,-672045),$zu(122,8)),1:+$p(dateexp,"-",2))
}

/// MONTHNAME is a date/time function that returns a character string containing the name of the month in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.MONTHNAME(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+MONTHNAME">MONTHNAME</a> reference page.
/// </p>
ClassMethod MONTHNAME(dateexp As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToDate(dateexp) }
	QUIT $s(dateexp="":"",dateexp=+dateexp:$p($zdate(dateexp,9,,,,,-672045)," "),1:$p($zdate($zdateh($p(dateexp," "),3,,,,,-672045),9,,,,,-672045)," "))
}

/// MVR returns the MVR collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.MVR(<i>stringexp</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// </dl>
/// MVR performs collation translations needed for MultiValue
ClassMethod MVR(stringexp As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$MVR(stringexp)
}

/// QUARTER is a date/time function that returns an integer from 1 to 4 that corresponds to the quarter of the year in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.QUARTER(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+QUARTER">QUARTER</a> reference page.
/// </p>
ClassMethod QUARTER(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToOdbc(dateexp) }
	if dateexp=+dateexp set dateexp=$zdate(dateexp,3,,,,,-672045)	// dateexp is now %TimeStamp format
	QUIT $s(dateexp="":"",1:$case(+$p(dateexp,"-",2),1:1,2:1,3:1,4:2,5:2,6:2,7:3,8:3,9:3,10:4,11:4,12:4,:""))
}

/// SECOND is a date/time function that returns an integer from 0 to 59 that corresponds to the second component in a given date-time expression.
/// <p>
/// $SYSTEM.SQL.Functions.SECOND(<i>timeexp</i>)<br>
/// <dl>
/// <dt><i>timeexp</i>
/// <dd>An expression that is a logical <class>%Library.Time</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+SECOND">SECOND</a> reference page.
/// </p>
ClassMethod SECOND(timeexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(timeexp) { set timeexp=##class(%Library.PosixTime).LogicalToOdbc(timeexp) }
	QUIT $s(timeexp="":"",timeexp=+timeexp:+$p($zt(timeexp,1),$zu(122,9),3),1:+$p($p(timeexp," ",2),$zu(122,9),3))
}

/// This entry point can be used to return the description of an SQLCODE value.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>SQLCODE</i>
/// <dd>SQLCODE value.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Functions.SQLCODE(-105)</li>
/// <li>Write $SYSTEM.SQL.Functions.SQLCODE(100)</li>
/// </ul>
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Functions_SQLCODE(<i>SQLCODE</i>)
ClassMethod SQLCODE(SQLCODE As %Library.Integer) As %Library.String [ SqlProc ]
{
	Quit $$sqlcode^%apiSQL($g(SQLCODE))
}

/// COLLATE returns the COLLATE collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.COLLATE(<i>stringexp</i>,<i>transSpec</i>,<i>maxlen</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// <dt><i>transSpec</i>
/// <dd>The transformation-spec is a comma-separated list of optional parameters to control the transformation.<br>
/// <dt><i>maxlen</i>
/// <dd>Optional. An integer, which specifies that the collated value will be truncated to the value of maxlen.<br>
/// </dl>
ClassMethod COLLATE(stringexp As %Library.String = "", transSpec As %Library.String = "", maxlen As %Library.Integer) As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$COLLATET(stringexp,transSpec,$g(maxlen,$$$MaxStringLength))
}

/// SQLSTRING returns the SqlString collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.SQLSTRING(<i>stringexp</i>,<i>maxlen</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// <dt><i>maxlen</i>
/// <dd>Optional. An integer, which specifies that the collated value will be truncated to the value of maxlen.<br>
/// SQLSTRING converts stringexp to a format that is sorted as a (case-sensitive) string. SQLSTRING strips trailing white space (spaces, tabs, and so on) from the string, then adds one leading blank space to the beginning of the string. It collates any value containing only white space (spaces, tabs, and so on) as the SQL empty string. SQL Empty string is represented as $Char(0) in ObjectScript, which collated as SqlString is " "_$Char(0).
/// </dl>
ClassMethod SQLSTRING(stringexp As %Library.String = "", maxlen As %Library.Integer) As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$SQLSTRINGT(stringexp,$g(maxlen,$$$MaxStringLength))
}

/// SQLUPPER returns the SqlUpper collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.SQLUPPER(<i>stringexp</i>,<i>maxlen</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// <dt><i>maxlen</i>
/// <dd>Optional. An integer, which specifies that the collated value will be truncated to the value of maxlen.<br>
/// </dl>
/// SQLUPPER converts stringexp to a format that is sorted as a (case-insensitive) upper-case string. SQLUPPER converts all alphabetic characters to uppercase, strips trailing white space (spaces, tabs, and so on) from the string, then adds one leading blank space to the beginning of the string. It collates any value containing only white space (spaces, tabs, and so on) as the SQL empty string. SQL Empty string is represented as $Char(0) in ObjectScript, which collated as SqlUpper is " "_$Char(0).
ClassMethod SQLUPPER(stringexp As %Library.String = "", maxlen As %Library.Integer) As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$SQLUPPERT(stringexp,$g(maxlen,$$$MaxStringLength))
}

/// STRING returns the String collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.STRING(<i>stringexp</i>,<i>maxlen</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// <dt><i>maxlen</i>
/// <dd>Optional. An integer, which specifies that the collated value will be truncated to the value of maxlen.<br>
/// STRING converts stringexp to a STRING collation format.
/// </dl>
/// STRING converts all alphabetic characters are uppercased; all punctuation characters are removed, except the comma; a single space is added to the beginning of the expression. It collates any value containing only white space (spaces, tabs, and so on) as the SQL empty string. SQL Empty string is represented as $Char(0) in ObjectScript, which collated as String is " "_$Char(0).
ClassMethod STRING(stringexp As %Library.String = "", maxlen As %Library.Integer) As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$STRINGT(stringexp,$g(maxlen,$$$MaxStringLength))
}

/// TOCHAR is a general SQL string function that converts a given date, timestamp, or number value to a string.
/// <p>
/// $SYSTEM.SQL.Functions.TOCHAR(<i>expr</i>,<i>format</i>)<br>
/// <dl>
/// <dt><i>expr</i>
/// <dd>A Logical <class>%Library.Date</class>, logical <class>%Library.TimeStamp</class>, logical <class>%Library.Time</class> value, $Horolog, or number expression to be converted.<br>
/// <dt><i>format</i>
/// <dd>A date or number format specifying the format for the <i>expr</i> conversion. 
/// If <i>format</i> contains the characters "Y", "MM", "RR", "DD", "J", "HH", "MI", "SS", "MON", "MONTH", "AM", "PM", or "D", <i>expr</i> is assumed to be a <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or $Horolog value.<br>
/// If <i>format</i> contains the characters "HH", "MI", "SS", "AM", or "PM" and it does not contain a date format, <i>expr</i> is assumed to be a <class>%Library.Time</class> value.<br>
/// Otherwise, it is a numeric value.<br>
/// </dl>
/// The first use of TOCHAR is to convert a date, time, or datetime expression to a string.<br>
/// The second use of TOCHAR is to convert a number to a string.<br>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+TO_CHAR">TO_CHAR</a> reference page.
/// </p>
ClassMethod TOCHAR(expr As %Library.String = "", format As %Library.String = "") As %Library.String [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$tochar^%qarfunc(expr,format)
}

/// TODATE is a general SQL string function that converts a given string expression to a value of DATE data type.
/// <p>
/// $SYSTEM.SQL.Functions.TODATE(<i>expr</i>,<i>format</i>)<br>
/// <dl>
/// <dt><i>expr</i>
/// <dd>The expression to be converted. The expression can be a string date expression, the name of a column, or a value where the underlying format is of type CHAR or VARCHAR. It can also be an integer between 1 and 2980013.<br>
/// <dt><i>format</i>
/// <dd>A date format specifying the format for <i>expr</i>. If 'J' is specified, <i>expr</i> must be an integer. If format is omitted, 'DD MON YYYY' is the default value.<br>
/// </dl>
/// The use of TODATE is to specify the input format of a string value containing a date to be converted to a Logical <class>%Library.Date</class> value. The format of <i>expr</i> is specified in the format parameter. <i>format</i> will be used as a key to translate <i>expr</i> into a valid <class>%Library.Date</class> logical value.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+TO_DATE">TODATE</a> reference page.
/// </p>
ClassMethod TODATE(dateexp As %Library.String = "", format As %Library.String = "") As %Library.String [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	QUIT $$todate^%qarfunc(dateexp,format)
}

/// TOPOSIXTIME is a general SQL string function that converts a given string expression to a logical value of a <class>%Library.PosixTime</class> data type.
/// <p>
/// $SYSTEM.SQL.Functions.TOPOSIXTIME(<i>stringexp</i>,<i>format</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>The expression to be converted. The expression can be a string datetime expression, the name of a column, or a value where the underlying format is of type CHAR or VARCHAR.<br>
/// <dt><i>format</i>
/// <dd>A datetime format code specifying the format for <i>stringexp</i>.  If format is omitted, 'DD MON YYYY HH:MM:SS' is the default value.<br>
/// </dl>
/// The use of TOPOSIXTIME is to specify the input format of a string value containing a datetime to be converted to a Logical <class>%Library.PosixTime</class> value. The format of <i>stringexp</i> is specified in the format parameter. <i>format</i> will be used as a key to translate <i>stringexp</i> into a valid <class>%Library.PosixTime</class> logical value.
/// If an error occurs during the execution of TOPOSIXTIME, the function will return a value of 0 and an error message will be defined in the %msg variable.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+TO_POSIXTIME">TO_POSIXTIME</a> reference page.
/// </p>
ClassMethod TOPOSIXTIME(stringexp As %Library.String = "", format As %Library.String = "") As %Library.String [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	try { s return=$$totimestamp^%qarfunc(stringexp,format,1) }
	catch { set:$g(%msg)="" %msg="Unexpected error occurred on call to $SYSTEM.SQL.Functions.TOPOSIXTIME("""_stringexp_""","""_format_"""):  "_$ze set return=0 }
	QUIT return
}

/// TOTIMESTAMP is a general SQL string function that converts a given string expression to a value of TIMESTAMP data type.
/// <p>
/// $SYSTEM.SQL.Functions.TOTIMESTAMP(<i>stringexp</i>,<i>format</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>The expression to be converted. The expression can be a string datetime expression, the name of a column, or a value where the underlying format is of type CHAR or VARCHAR.<br>
/// <dt><i>format</i>
/// <dd>A datetime format code specifying the format for <i>stringexp</i>.  If format is omitted, 'DD MON YYYY HH:MI:SS' is the default value.<br>
/// </dl>
/// The use of TOTIMESTAMP is to specify the input format of a string value containing a datetime to be converted to a Logical <class>%Library.TimeStamp</class> value. The format of <i>stringexp</i> is specified in the format parameter. <i>format</i> will be used as a key to translate <i>stringexp</i> into a valid <class>%Library.TimeStamp</class> logical value.
/// If an error occurs during the execution of TOTIMESTAMP, the function will return a value of 0 and an error message will be defined in the %msg variable.
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+TO_TIMESTAMP">TO_TIMESTAMP</a> reference page.
/// </p>
ClassMethod TOTIMESTAMP(stringexp As %Library.String = "", format As %Library.String = "") As %Library.String [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	try { s return=$$totimestamp^%qarfunc(stringexp,format) }
	catch { set:$g(%msg)="" %msg="Unexpected error occurred on call to $SYSTEM.SQL.Functions.TOTIMESTAMP("""_stringexp_""","""_format_"""):  "_$ze set return=0 }
	QUIT return
}

/// TRUNCATE returns the Truncate collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.TRUNCATE(<i>stringexp</i>,<i>maxlen</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// <dt><i>maxlen</i>
/// <dd>Optional. An integer, which specifies that the collated value will be truncated to the length of <i>maxlen</i>.
/// If <i>maxlen</i> is not specified, TRUNCATE behaves the same as EXACT.<br>
/// TRUNCATE leaves <i>stringexp</i> in the exact format it receives and is sorted as a (case-sensitive) string.  TRUNCATE simply returns the first <i>maxlen</i> characters of the expression.
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+TRUNCATE">TRUNCATE</a> reference page.
/// </p>
ClassMethod TRUNCATE(stringexp As %Library.String = "", maxlen As %Library.Integer = 32768) As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$TRUNCATET(stringexp,$s(maxlen:maxlen,1:32768))
}

/// UPPER returns the Upper collation of the passed in value.
/// <p>
/// $SYSTEM.SQL.Functions.UPPER(<i>stringexp</i>)<br>
/// <dl>
/// <dt><i>stringexp</i>
/// <dd>Any string expression value.<br>
/// </dl>
/// </p>
/// <p>UPPER converts all alphabetic characters to upper case (i.e., the UPPER format). Note that punctuation is not changed.
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+UPPER">UPPER</a> reference page.
/// </p>
ClassMethod UPPER(stringexp As %Library.String = "") As %Library.String [ ProcedureBlock = 1 ]
{
	QUIT $$$UPPER(stringexp)
}

/// VECTORCOSINE returns the cosine of the angle between two vectors, i.e., the dot product of the vectors divided by the product of their lengths.
/// <p>
/// $SYSTEM.SQL.Functions.VECTORCOSINE(<i>vec1</i>,<i>vec2</i>)<br>
/// <dl>
/// <dt><i>vec1,vec2</i>
/// <dd>Any vector.<br>
/// </dl>
/// </p>
/// <p>VECTORCOSINE returns the cosine distance of vectors vec1 and vec2, i.e., 
/// <p>the sum of the products of each pair of elements in the same position of the two input vectors, divided by a product of their lengths.
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/Doc.View.cls?KEY=RSQL_vectorcosine">VECTORCOSINE</a> reference page.
/// </p>
ClassMethod VECTORCOSINE(vec1 As %Library.Vector = "", vec2 As %Library.Vector = "") As %Library.Double [ ProcedureBlock = 1 ]
{
	RETURN:((vec1="")||(vec2="")) "" // return null if either arguments are null
	set return="" 	
	// check both inputs are valid vectors
	throw:'$isvector(vec1) ##class(%Exception.General).%New(,,,"Argument #1 of vector function VECTORCOSINE is not a vector.")
	throw:'$isvector(vec2) ##class(%Exception.General).%New(,,,"Argument #2 of vector function VECTORCOSINE is not a vector.")

	// check vector length matches
	set v1len=$vop("length",vec1),v2len=$vop("length",vec2)
	throw:v1len'=v2len ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORCOSINE on vectors of different lengths "_v1len_" and "_v2len)
	
	// check for vector types
	set v1type=$vop("type",vec1),v2type=$vop("type",vec2)
	// numeric data types
	throw:",integer,double,decimal,xf32,"'[(","_v1type_",") ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORCOSINE because Argument #1 is of type "_v1type_", not a numeric datatype")
	throw:",integer,double,decimal,xf32,"'[(","_v2type_",") ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORCOSINE because Argument #2 is of type "_v2type_", not a numeric datatype")	
	throw:v1type'=v2type ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORCOSINE on vectors of different datatypes "_v1type_" and "_v2type)
	
	try {
		if "double,decimal"[v1type { set return = $vop("cosine-similarity",vec1,vec2) }  // use the faster $vop for double and decimal vectors
		else {
			set vecLengthsSquared=$vop("sum",$vop("v*",vec1,vec1))*$vop("sum",$vop("v*",vec2,vec2)) // the squared product of both vector's lengths
			set:vecLengthsSquared'=0 return=$vop("sum",$vop("v*",vec1,vec2))/(vecLengthsSquared**0.5) // only if neither of the vector is 0-vector
		}
	}
	catch ex { 
		if ex.Name="<ILLEGAL VALUE>" { throw ##class(%Exception.General).%New(,,,"Overflow error occured on call to $SYSTEM.SQL.Functions.VECTORCOSINE")
		} elseif ex.Name="<DIVIDE>" { set return = "" // at least one of the vectors has length 0
		} else { throw ##class(%Exception.General).%New(,,,"Unexpected error occurred on call to $SYSTEM.SQL.Functions.VECTORCOSINE")}
	}
	RETURN return
}

/// VECTORDOTPRODUCT returns the dot product of two vectors.
/// <p>
/// $SYSTEM.SQL.Functions.VECTORDOTPRODUCT(<i>vec1</i>,<i>vec2</i>)<br>
/// <dl>
/// <dt><i>vec1,vec2</i>
/// <dd>Any vector.<br>
/// </dl>
/// </p>
/// <p>VECTORDOTPRODUCT returns the dot product of vectors vec1 and vec2, i.e., the sum of the products of each pair of elements in the same position of the two input vectors.
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/Doc.View.cls?KEY=RSQL_vectordotproduct">VECTORDOTPRODUCT</a> reference page.
/// </p>
ClassMethod VECTORDOTPRODUCT(vec1 As %Library.Vector = "", vec2 As %Library.Vector = "") As %Library.Double [ ProcedureBlock = 1 ]
{
	RETURN:((vec1="")||(vec2="")) "" // return null if either arguments are null
	set return="" 	
	// check both inputs are valid vectors
	throw:'$isvector(vec1) ##class(%Exception.General).%New(,,,"Argument #1 of vector function VECTORDOTPRODUCT is not a vector.")
	throw:'$isvector(vec2) ##class(%Exception.General).%New(,,,"Argument #2 of vector function VECTORDOTPRODUCT is not a vector.")

	// check vector length matches
	set v1len=$vop("length",vec1),v2len=$vop("length",vec2)
	throw:v1len'=v2len ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORDOTPRODUCT on vectors of different lengths "_v1len_" and "_v2len)
	
	// check for vector types
	set v1type=$vop("type",vec1),v2type=$vop("type",vec2)
	// numeric data types
	throw:",integer,double,decimal,xf32,"'[(","_v1type_",") ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORDOTPRODUCT because Argument #1 is of type "_v1type_", not a numeric datatype")
	throw:",integer,double,decimal,xf32,"'[(","_v2type_",") ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORDOTPRODUCT because Argument #2 is of type "_v2type_", not a numeric datatype")	
	throw:v1type'=v2type ##class(%Exception.General).%New(,,,"Cannot perform vector function VECTORDOTPRODUCT on vectors of different datatypes "_v1type_" and "_v2type)
	
	try { set return = $s("double,decimal"[v1type:$vop("dot-product",vec1,vec2),1:$vop("sum",$vop("v*",vec1,vec2)))} // use the faster $vop for double and decimal vectors
	catch { throw ##class(%Exception.General).%New(,,,"Unexpected error occurred on call to $SYSTEM.SQL.Functions.VECTORDOTPRODUCT")}
	
	
	RETURN return
}

/// WEEK is a date/time function that returns an integer from 1 to 53 that corresponds to the week of the year in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.WEEK(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+WEEK">WEEK</a> reference page.
/// </p>
ClassMethod WEEK(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	new %msg,SQLCODE
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToDate(dateexp) }
	QUIT $s(dateexp="":"",dateexp?0.1"-"1.7n:$$WeekOfYear^%qarfunc(dateexp),dateexp?4n1"-"1.2n1"-"1.2n0.1" ".e:$$WeekOfYear^%qarfunc($zdateh($p(dateexp," "),3,,,,,-672045)),1:$$WeekOfYear^%qarfunc($zdateh(dateexp,-1,,,,,-672045)))
}

/// YEAR is a date/time function that returns an integer in the range 1840-9999 that indicates the year in a given date expression.
/// <p>
/// $SYSTEM.SQL.Functions.YEAR(<i>dateexp</i>)<br>
/// <dl>
/// <dt><i>dateexp</i>
/// <dd>An expression that is a logical <class>%Library.Date</class>, <class>%Library.TimeStamp</class>, or <class>%Library.PosixTime</class> value.<br>
/// </dl>
/// </p>
/// <p>
/// <b>Also see</b> the <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=SQL+YEAR">YEAR</a> reference page.
/// </p>
ClassMethod YEAR(dateexp As %Library.String = "") As %Library.Integer [ ProcedureBlock = 1 ]
{
	if $$$sqlxPosixTimeIsValid(dateexp) { set dateexp=##class(%Library.PosixTime).LogicalToOdbc(dateexp) }
	QUIT $s(dateexp="":"",dateexp=+dateexp:+$zdate(dateexp,3,,,,,-672045),1:+dateexp)
}

}
