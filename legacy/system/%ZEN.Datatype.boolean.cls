/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This datatype represents a boolean value.
Class %ZEN.Datatype.boolean Extends datatype [ ClientDataType = BOOLEAN, Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN;

/// Converts the SOAP encoded input value, which is true, false 1 or 0,
/// into a %Boolean value.
ClassMethod XSDToLogical(%val As %String) As %String [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		If (+$G(%parameter("ZENEXPRESSION"))) {
			#; allow #()# expressions
			Set %code="$S(%val[""#("":%val,1:$case(%val,""true"":1,""false"":0,1:1,0:0,:""""))"
		}
		Else {
			Set %code="$case(%val,""true"":1,""false"":0,1:1,0:0,:"""")"
		}
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the %Boolean value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %String) As %String [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val:""true"",1:""false"")"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which is a string representing
/// a boolean value, into a boolean value.
/// <p>Returns the boolean value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String = "") As %String [ CodeMode = expression ]
{
''%val
}

}
