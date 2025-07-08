/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%SmallInt</b> represents a small integer value.
/// This implements the SmallInt ODBC datatype 
Class %Library.SmallInt Extends %Integer [ OdbcType = SMALLINT, System = 2 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL As INTEGER = 32767;

/// The minimum allowed logical value for the data type.
Parameter MINVAL As INTEGER = -32768;

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "short";

/// Converts the SOAP encoded input decimal value into a %SmallInt value.
/// Returns "" for error.
ClassMethod XSDToLogical(%val As %String) As %SmallInt [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$number(%val,""I"",-32768,32767)"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Integer [ CodeMode = expression, ServerOnly = 1 ]
{
$select($zu(115,13)&&(%val=$c(0)):"",1:%val\1)
}

/// Tests if the logical value <var>%val</var>, which is an integer value, is valid.
/// The validation is based on the class parameter settings used
/// for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="$select(%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))"
	s max=$s(%parameter("MAXVAL")="":32767,%parameter("MAXVAL")>32767:32767,1:%parameter("MAXVAL"))
	s min=$s(%parameter("MINVAL")="":-32768,%parameter("MINVAL")<-32768:-32768,1:%parameter("MINVAL"))
	s str="$isvalidnum(%val,0,"_min_","_max_")"
	s %code="$select($zu(115,13)&&(%val=$c(0)):1,"_str_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val),%val<"_min_":$$$ERROR($$$DTMinVal,%val,"_min_"),1:$$$ERROR($$$DTMaxVal,%val,"_max_"))"
	QUIT $$$OK
}

}
