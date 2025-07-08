/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.TermCoocEntry Extends node [ Deprecated, System = 3 ]
{

Parameter XMLNAME = "Cooccurrent";

Property Entities As list Of %String(MAXLEN = 200, XMLPROJECTION = "ELEMENT");

Method ToString() As %String
{
	// first sort
	kill tValues 
	for j = 1:1:..Entities.Count() {
		set tValues(..Entities.GetAt(j)) = ""
	}
	set tValue="", tString=""
	for {
		set tValue = $order(tValues(tValue))
		quit:tValue=""
		set tString = tString _ $c(0) _ tValue
	}
	quit $e(tString,2,*)
}

}
