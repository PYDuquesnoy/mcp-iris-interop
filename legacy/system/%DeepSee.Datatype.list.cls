/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This datatype represents a list of values and supports indexing on each individual value.
/// The list value can be in <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> format or be a character-delimited list. 
/// The default is comma-delimited.
Class %DeepSee.Datatype.list Extends %Library.String [ System = 3 ]
{

/// The maximum number of characters the string can contain.
Parameter MAXLEN = 30000;

/// This specifies whether the data in $List format (LIST) or character delimited (PIECE).
Parameter LISTTYPE [ Constraint = ",LIST,PIECE", Flags = ENUMEDIT ] = "PIECE";

/// If LISTTYPE is "PIECE", then this specifies the delimiter character.
Parameter DELIMITER = ",";

/// Convert the list to an array of values that can be indexed.
ClassMethod BuildValueArray(pDocument As %Binary, ByRef pValueArray As %String) As %Status
{
	If (pDocument'="") {
		If (..#LISTTYPE = "PIECE") {
			Set tDelim = ..#DELIMITER
			Set tLen = $L(pDocument,tDelim)
			For n = 1:1:tLen {
				Set tItem = $P(pDocument,tDelim,n)
				If (tItem '= "") {
					Set pValueArray(tItem) = ""
				}
			}
		}
		Else {
			Set tLen = $LL(pDocument)
			For n = 1:1:tLen {
				Set tItem = $LG(pDocument,n)
				If (tItem '= "") {
					Set pValueArray(tItem) = ""
				}
			}
		}
	}
	Else {
		// trick index into indexing null entries
		Set pValueArray(-1E14) = ""
	}
	Quit $$$OK
}

/// Crude display method.
ClassMethod LogicalToDisplay(%val = "") As %String
{
	If $G(%val)="" Quit ""
	Quit $S($ListValid(%val):$ListToString(%val,","),1:%val)
}

}
