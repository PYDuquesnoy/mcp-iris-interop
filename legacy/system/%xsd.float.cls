/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This data type represents a floating point number.
/// Internally, it is stored as a floating point value.
Class %xsd.float Extends %Float [ Not ProcedureBlock, System = 2 ]
{

/// Declares the XSD type used when projecting XML schemas.
Parameter XSDTYPE = "float";

Parameter JSONTYPE = "double";

/// Converts the SOAP encoded input decimal value into a logical value.
/// Also supports the XML values of -0, INF, -INF and NaN which are stored as strings.
/// Returns "" for error.
ClassMethod XSDToLogical(%val As %String) As %Float [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select((%val=""INF"")||(%val=""-INF"")||(%val=""NaN""):%val,$isvalidnum(%val):+%val,1:"""")"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Tests if the logical value <var>%val</var>, which is a floating point value, is valid.
/// The validation is based on the class parameter settings used for the class
/// attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, GenerateAfter = IsValidDT ]
{
	n sep,str,flag
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="(%val'["""_sep_""")&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_"""))"
	s str="$isvalidnum(%val,,"_%parameter("MINVAL")_","_%parameter("MAXVAL")_")||(%val=""INF"")||(%val=""-INF"")||(%val=""NaN"")"
	s %code="$select("_str_":1,1:$$$ERROR($$$DatatypeValidationError,""%xsd.float"",%val))"
	QUIT $$$OK
}

}
