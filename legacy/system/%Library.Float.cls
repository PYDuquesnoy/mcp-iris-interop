/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// <p> This class is <b>DEPRECATED</b>. Applications should use either 
/// the <class>%Double</class> datatype for cases where values should be in the IEEE 
/// float ($Double) format, or <class>%Decimal</class> for cases where values should be in Decimal
/// ($Decimal) format.</p>
/// The <b>%Float</b> data type class represents a floating point number.
/// <p>The logical value of the <b>%Float</b> data type is a floating point value.
Class %Library.Float Extends %DataType [ ClientDataType = DOUBLE, Deprecated, OdbcType = DOUBLE, SqlCategory = DOUBLE, System = 2 ]
{

/// The format specification for the data type's display value.
/// <p>The value of <var>FORMAT</var> corresponds to the formatting option
/// of the <code>$FNUMBER</code> function, which is used to perform the formatting.
Parameter FORMAT;

/// The scale value (number of digits following the decimal point) for this data type.  This parameter only affects the display value which will be rounded to the specified number of decimal places.
Parameter SCALE As INTEGER;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

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
Parameter XSDTYPE = "double";

Parameter JSONTYPE = "number";

/// Converts the SOAP encoded input decimal value into a logical value.
/// Returns "" for error.
ClassMethod XSDToLogical(%val As %String) As %Float [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select($isvalidnum(%val):+%val,1:"""")"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the Objectscript value to the JSON number value.
ClassMethod LogicalToJSON(%val As %Float) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If 1,($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select($extract(%val)=""."":""0""_%val,$extract(%val,1,2)=""-."":""-0.""_$extract(%val,3,*),1:%val)"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which is a string representing a floating point value,
/// into a logical floating point value.
/// <p>Returns the logical floating point value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %Float [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",$zu(115,13)&&(%val=$c(0)):"""",1:+$in(%val,"""_%parameter("FORMAT")_""",%val))"
	}
	QUIT $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Float [ CodeMode = expression, ServerOnly = 1 ]
{
$select($zu(115,13)&&(%val=$c(0)):"",1:$decimal(%val))
}

/// Tests if the logical value <var>%val</var>, which is a floating point value, is valid.
/// The validation is based on the class parameter settings used for the class
/// attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	If ($Get(%parameter("SCALE")) '= 0) && ($Get(%parameter("SCALE")) '= "") && (('$isvalidnum(%parameter("SCALE"),,1)) || (((+%parameter("SCALE")\1)) '= +%parameter("SCALE"))||(%parameter("SCALE")<0)||(%parameter("SCALE")>15)) { Quit $$$ERROR($$$DatatypeParameterScaleIncorrect,%class_"::"_%property,"SCALE",%parameter("SCALE")) }

	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationError,""%Float"",%val))"
		Quit $$$OK
	}
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="(%val'["""_sep_""")&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_"""))"
	s str="$isvalidnum(%val,,"_%parameter("MINVAL")_","_%parameter("MAXVAL")_")"
	s %code="$select($zu(115,13)&&(%val=$c(0)):1,"_str_":1,1:$$$ERROR($$$DatatypeValidationError,""%Float"",%val))"
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical floating point format, into a display string.
/// The formatting is based on the value of the <a href="#FORMAT">FORMAT</a> parameter.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Float) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("FORMAT")'="",'$$CheckNumericFormat^%occCheck(%parameter("FORMAT")) quit $$$ERROR($$$InorrectIntegerFormat,%class,%property,%method)
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		#; DPV3082 - even if there is no FORMAT or SCALE, we need to call $fn because they may have a setting such as SetDCFormat^%NLS("NumericGroupSeparator",...)
		#;           or SetDCFormat^%NLS("DecimalSeparator",...) and we want the display value to reflect that
		#; DPV3082 i %parameter("FORMAT")="",%parameter("SCALE")="" s %code="%val" QUIT $$$OK
		Set temp=""""_%parameter("FORMAT")_""""
		If %parameter("SCALE")'="" s temp=temp_","_%parameter("SCALE")
		Set %code="$s(%val="""":"""",1:$fn(%val,"_temp_"))"
	}
	QUIT $$$OK
}

}
