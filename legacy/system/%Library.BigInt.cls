/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%BigInt</b> represents a 64 bit integer value.
/// <p>This is identical to the <CLASS>%Integer</CLASS> data type with the
/// exception that it has odbctype of BIGINT.
Class %Library.BigInt Extends %Integer [ ClientDataType = BIGINT, OdbcType = BIGINT, System = 2 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL As INTEGER = 9223372036854775807;

/// The minimum allowed logical value for the data type.
Parameter MINVAL As INTEGER = -9223372036854775808;

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "long";

/// Converts the SOAP encoded input decimal value into a %BiglInt value.
/// Returns "" for error.
ClassMethod XSDToLogical(%val As %String) As %BigInt [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$number(%val,""I"",-9223372036854775808,9223372036854775807)"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Integer [ ServerOnly = 1 ]
{
		#; For %BigInt we add the $decimal in case %val is type DOUBLE.  For INTEGER values, %val\1 returns an INTEGER (type 4), 
		#; but for BIGINT values %val\1 returns type 8 (DOUBLE), so we convert with $decimal
	Quit $select(%val=$c(0)&&$zu(115,13):"",1:$decimal(%val)\1)
}

/// Tests if the logical value <var>%val</var>, which is an integer value, is valid.
/// The validation is based on the class parameter settings used
/// for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	if %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		RETURN $$$OK
	}
	set %code=0
	set %codemode=$$$cMETHCODEMODEEXPRESSION
	if %parameter("VALUELIST")'="" {
		set sep=$e(%parameter("VALUELIST")) ;for now
		set %code="$select(%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))"
		RETURN $$$OK
	}
	set max=$s(%parameter("MAXVAL")="":9223372036854775807,%parameter("MAXVAL")>9223372036854775807:9223372036854775807,1:%parameter("MAXVAL"))
	set min=$s(%parameter("MINVAL")="":-9223372036854775808,%parameter("MINVAL")<-9223372036854775808:-9223372036854775808,1:%parameter("MINVAL"))
	set str="$isvalidnum(%val,0,"_min_","_max_")"
	set %code="$select("_str_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val),%val<"_min_":$$$ERROR($$$DTMinVal,%val,"_min_"),1:$$$ERROR($$$DTMaxVal,%val,"_max_"))"
	RETURN $$$OK
}

}
