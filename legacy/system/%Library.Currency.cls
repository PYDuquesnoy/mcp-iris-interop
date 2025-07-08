/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%Currency</b> data type class represents a currency value.
/// <p><b>%Currency</b> is essentially the same as the <CLASS>%Numeric</CLASS> data type with
/// <b>clientdatatype</b> of CURRENCY and a fixed SCALE of 4.
/// It is a legacy type that is defined only for the 
/// purpose of moving existing applications from Sybase and SQL Server.
Class %Library.Currency Extends %DataType [ ClientDataType = CURRENCY, OdbcType = NUMERIC, SqlCategory = NUMERIC, System = 2 ]
{

/// The format specification for the data type's display value.
/// <p>The value of <var>FORMAT</var> corresponds to the formatting option
/// of the <code>$FNUMBER</code> function, which is used to perform the formatting.
Parameter FORMAT;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

/// The scale value (number of digits following the decimal point) for this data type.
/// The logical value will be rounded to the specified number of decimal places.
Parameter SCALE As INTEGER [ Final, Internal ] = 4;

/// Used for enumerated (multiple-choice) attributes.
/// <var>VALUELIST</var> is either a null string ("") or a delimiter
/// separated list (where the delimiter is the first character) of logical values.
/// If a non-null value is present, then the attribute is restricted to values
/// in the list, and the validation code simply checks to see if the value is in the list.
Parameter VALUELIST;

/// Used for enumerated (multiple-choice) attributes.
/// Used in conjunction with the <a href="#VALUELIST">VALUELIST</a> parameter for enumerated
/// (multiple-choice) attributes. <var>DISPLAYLIST</var>, if not null,
/// represents the display values for the attribute corresponding with
/// the logical values listed in <var>VALUELIST</var>.
/// <p>The display values are returned by the <a href="#LogicalToDisplay">LogicalToDisplay</a> method.
Parameter DISPLAYLIST;

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "decimal";

Parameter JSONTYPE = "number";

/// Converts the SOAP encoded input decimal value into a %Currency value.
/// Returns "" for error.
ClassMethod XSDToLogical(%val As %String) As %Currency [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$inumber(%val,""LO"","""")"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the Objectscript value to the JSON number value.
ClassMethod LogicalToJSON(%val As %Double) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If 1,($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select($extract(%val)=""."":""0""_%val,$extract(%val,1,2)=""-."":""-0.""_$extract(%val,3,*),1:%val)"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which is a string representing
/// a currency value, into a logical currency value.
/// <p>Returns the value of the input string <var>%val</var> as a currency (fixed point number).
ClassMethod DisplayToLogical(%val As %String) As %Currency [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("FORMAT")'="",'$$CheckNumericFormat^%occCheck(%parameter("FORMAT")) quit $$$ERROR($$$InorrectIntegerFormat,%class,%property,%method)
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$in(%val,"""_%parameter("FORMAT")_""",%val)"
	}
	QUIT $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Numeric [ CodeMode = expression, ServerOnly = 1 ]
{
$normalize($decimal(%val),4)
}

/// Tests if the logical value <var>%val</var>, which is a currency value, is valid.
/// The validation is based on the class parameter settings used for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	if $Get(%parameter("SCALE")) '= 4 { quit $$$ERROR($$$DatatypeParameterCurrencyScale,%class,%property) }
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
	s str="$isvalidnum(%val,4,"_%parameter("MINVAL")_","_%parameter("MAXVAL")_")"
	If %parameter("MAXVAL")="",%parameter("MINVAL")="" Set %code="$select("_str_":1,1:$$$ERROR($$$DTNotNum,%val))" Quit $$$OK
	s %code="$select("_str_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val)"
	If %parameter("MINVAL")'="" {
		If %parameter("MAXVAL")="" {
			Set %code=%code_",1:$$$ERROR($$$DTMinVal,%val,"_%parameter("MINVAL")_"))"
		} Else {
			Set %code=%code_",%val<"_%parameter("MINVAL")_":$$$ERROR($$$DTMinVal,%val,"_%parameter("MINVAL")_"),1:$$$ERROR($$$DTMaxVal,%val,"_%parameter("MAXVAL")_"))"
		}
	} Else {
		Set %code=%code_",1:$$$ERROR($$$DTMaxVal,%val,"_%parameter("MAXVAL")_"))"
	}
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in currency format, into a display string.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Currency) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set temp=""""_%parameter("FORMAT")_""""
		Set temp=temp_",4"
		Set %code="$s(%val="""":"""",1:$fn(%val,"_temp_"))"
	}
	QUIT $$$OK
}

}
