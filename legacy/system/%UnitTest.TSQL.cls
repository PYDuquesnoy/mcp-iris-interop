/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %UnitTest.TSQL Extends (%UnitTest.TestCase, %UnitTest.ODBCSQL) [ Inheritance = right, System = 4 ]
{

/// Informix SPL dll/so is only built for 32-bit Windows and for 32-bit, 64-bit RedHat Linux
Method informixPlatform() As %Boolean
{
	s platform=$system.Version.GetBuildOS()_" "_$system.Version.GetPlatform()
	s sc=((platform["Windows")||(platform["Red Hat"))
	q:'sc '$$$OK
	s sc=$zcvt($zv,"U")["ITANIUM"
	q:sc '$$$OK
	s sc=((platform["Windows")&&($system.Version.Is64Bits()))
	q:sc '$$$OK
	q $$$OK
}

/// Method to display incorrect results in a more readable format.
Method processDiffFile(ByRef rslt As %Stream)
{
	while 'rslt.AtEnd {
			s str=rslt.ReadLine()
			d $$$LogMessage(str)
			d $$$LogMessage("SQL:"_$e(str,$f(str,":"),$f(str,"'")-2))
			d $$$LogMessage("SQL Length:"_$l($e(str,$f(str,":"),$f(str,"'")-2)))
			d $$$LogMessage("EXP:"_$e(str,$f(str,"'="),$l(str)))
			d $$$LogMessage("EXP Length:"_$l($e(str,$f(str,"'="),$l(str))))
		}
}

Method runSQLStatement(sql As %String = "", ByRef dsn As %String = "", verbose As %Boolean = 0, Username As %String = "", Password As %String = "", ByRef Rowcount As %Integer) As %Stream
{
	q ..runODBCSQLStatement(sql,.dsn,verbose,Username,Password, .Rowcount)
}

}
