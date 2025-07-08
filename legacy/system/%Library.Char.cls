/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%Char</b> data type class represents a fixed length character field.
/// <p>The logical value of the <b>%character field</b> data type is a character field.
Class %Library.Char Extends %String [ System = 4 ]
{

/// Converts <var>%val</var>, which represents a CHAR in logical format (no blank space padding), into format (blank padded on the right).
/// <p>Returns the ODBC string for the logical value <var>%val</var>.
ClassMethod LogicalToOdbc(%val As %Char) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" i %val'=$c(0),$l(%val)<"_%parameter("MAXLEN")_" f i=($l(%val)+1):1:"_(+%parameter("MAXLEN"))_" s %val=%val_"" """)
	$$$GENERATE(" i %val=$c(0) s %val="" "" f i=2:1:"_(+%parameter("MAXLEN"))_" s %val=%val_"" """)
	$$$GENERATE(" q %val")
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical format, into a display string. Removes all the null characters from the string.
/// <p>Returns the string value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Char) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"),%parameter("COLLATION"))
	} Else {
		$$$GENERATE(" s %val=$tr(%val,$c(0),"""")")
		$$$GENERATE(" i $l(%val)<"_%parameter("MAXLEN")_" f i=($l(%val)+1):1:"_(+%parameter("MAXLEN"))_" s %val=%val_"" """)
		$$$GENERATE(" q %val")
	}
	QUIT $$$OK
}

}
