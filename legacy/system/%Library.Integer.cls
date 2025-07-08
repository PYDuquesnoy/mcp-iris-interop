/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%Integer</b> data type class represents an integer value.
/// <p>The logical value of the <b>%Integer</b> data type is an integer.
/// The %Integer datatype does not have built-in limits. 
/// It is a hybrid datatype the values of which is not exact outside of a certain range 
/// (currently it is the same range as  that of the 64-bit integer value). 
/// The current range for xDBC projections can be seen under configuration/advanced.
/// Its default corresponds to the usual signed 32-bit integer limits.
Class %Library.Integer Extends %DataType [ ClientDataType = INTEGER, OdbcType = INTEGER, SqlCategory = INTEGER, System = 2 ]
{

/// The format specification for the data type's display value.
/// <p>The value of <var>FORMAT</var> corresponds to the formatting option
/// of the <code>$FNUMBER</code> function, which is used to perform the formatting.
Parameter FORMAT;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL As INTEGER;

/// The minimum allowed logical value for the data type.
Parameter MINVAL As INTEGER;

/// The total number of digits for XML verification as defined by http://www.w3.org/TR/xmlschema-2/#rf-totalDigits
Parameter XMLTotalDigits;

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
Parameter XSDTYPE = "long";

Parameter JSONTYPE = "number";

/// If '1' then <method>IsValid</method> will return false for numbers that are not integers e.g. 1.2, -0.01
/// rather than the default behavior which is to allow these an normalize them to an integer. This validation
/// is done by $number using "I" format, so the rules associated with this function apply.
Parameter STRICT = 0;

/// Converts the SOAP encoded input decimal value into a logical value.
/// Returns "" for error.
ClassMethod XSDToLogical(%val As %String) As %Integer [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set min=%parameter("MINVAL")
		Set max=%parameter("MAXVAL")
		If max="" {
			Set mm=$select(min="":"",1:","_min)
		} Else {
			Set mm=","_min_","_max
		}
		Set totalDigits=$get(%parameter("XMLTotalDigits"))
		If totalDigits="" {
			$$$GENERATE("	Q $s($tr(%val,""Ee(),."")'=%val:"""",1:$number(%val,""I"""_mm_"))")
		} Else {
			$$$GENERATE("	If $tr(%val,""Ee(),."")'=%val Quit """"")
			$$$GENERATE("	Set num=$number(%val,""I"""_mm_")")
			$$$GENERATE("	Quit $select($length(num)>"_totalDigits_":"""",1:num)")
		}
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which is a string representing an integer,
/// into a logical integer value.
/// <p>Returns the logical integer value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %Integer [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("FORMAT")'="",'$$CheckNumericFormat^%occCheck(%parameter("FORMAT")) quit $$$ERROR($$$InorrectIntegerFormat,%class,%method)
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} Else {
		#; We only want to return +$in() here if the input is valid for the format.
		$$$GENERATE("	Q $select(%val="""":"""",%val=$c(0)&&$zu(115,13):"""",1:$s($in(%val,"""_%parameter("FORMAT")_""","""")'="""":+$in(%val,"""_%parameter("FORMAT")_""",%val),1:%val))")
	}
	QUIT $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Integer [ ServerOnly = 1 ]
{
	Quit $select(%val=$c(0)&&$zu(115,13):"",1:%val\1)
}

/// Tests if the logical value <var>%val</var>, which is an integer value, is valid.
/// The validation is based on the class parameter settings used
/// for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		$$$GENERATE("	Quit $s(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))")
		Quit $$$OK
	}
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. $$$GENERATE("	Quit $s(%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))")
	Set str=$select(%parameter("STRICT")=1:"$number(%val,""I""",1:"$isvalidnum(%val,0")_$select(%parameter("MINVAL")=""&&(%parameter("MAXVAL")=""):"",1:","_%parameter("MINVAL"))_$select(%parameter("MAXVAL")'="":","_%parameter("MAXVAL"),1:"")_")"_$select(%parameter("STRICT")=1:"'=""""",1:"")
	If %parameter("MAXVAL")="",%parameter("MINVAL")="" $$$GENERATE("	Quit $select(%val=$c(0)&&$zu(115,13):1,"_str_":1,1:$$$ERROR($$$DTNotNum,%val))") Quit $$$OK
	s code="$select(%val=$c(0)&&$zu(115,13):1,"_str_":1,"_$select(%parameter("STRICT")=1:"$number(%val,""I"")=""""",1:"'$isvalidnum(%val)")_":$$$ERROR($$$DTNotNum,%val)"
	If %parameter("MINVAL")'="" {
		If %parameter("MAXVAL")="" {
			Set code=code_",1:$$$ERROR($$$DTMinVal,%val,"_%parameter("MINVAL")_"))"
		} Else {
			Set code=code_",%val<"_%parameter("MINVAL")_":$$$ERROR($$$DTMinVal,%val,"_%parameter("MINVAL")_"),1:$$$ERROR($$$DTMaxVal,%val,"_%parameter("MAXVAL")_"))"
		}
	} Else {
		Set code=code_",1:$$$ERROR($$$DTMaxVal,%val,"_%parameter("MAXVAL")_"))"
	}
	$$$GENERATE("	Quit "_code)
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical integer format, into a display string.
/// The formatting is based on the value of the FORMAT parameter.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Integer) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("FORMAT")'="",'$$CheckNumericFormat^%occCheck(%parameter("FORMAT")) quit $$$ERROR($$$InorrectIntegerFormat,%class,%property,%method)
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		If %parameter("FORMAT")="" $$$GENERATE("	Q %val") QUIT $$$OK
		$$$GENERATE("	Q $s(%val="""":"""",1:$fn(%val,"""_%parameter("FORMAT")_"""))")
	}
	QUIT $$$OK
}

}
