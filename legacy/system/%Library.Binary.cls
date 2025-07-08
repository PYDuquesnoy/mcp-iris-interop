/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%Binary</b> data type class is used to represent binary data.
/// The logical value for <b>%Binary</b> is a string containing a binary value.
/// 
/// <p>When a <b>%Binary</b> data type value is projected to a client application,
/// such as when it is used in a Java, Visual Basic (ActiveX), ODBC, or JDBC application,
/// the <i>Object Server</i> performs no translations or conversions on it.
/// That is the actual binary data is sent to and from the client without any Unicode (or other) translations.
Class %Library.Binary Extends %DataType [ ClientDataType = BINARY, OdbcType = VARBINARY, System = 2 ]
{

/// The maximum number of characters the string can contain.
Parameter MAXLEN As INTEGER = 50;

/// The minimum number of characters the string can contain.
Parameter MINLEN As INTEGER;

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "base64Binary";

Parameter JSONTYPE = "string";

/// If MTOM is true, then the property that references this binary data is available for optimization
/// when using SOAP MTOM (Message Transmission Optimization Mechanism).
/// The default for binary string data is false.
Parameter MTOM As BOOLEAN = 0;

/// If CANONICALXML is true, then the base64 output contains no white space.
Parameter CANONICALXML As BOOLEAN = 0;

/// Converts the SOAP encoded base64 input value to a logical value.
ClassMethod XSDToLogical(%val As %String) As %Binary [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$system.Encryption.Base64Decode($translate(%val,$char(9,10,13,32)))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the %Binary value to the SOAP base64 encoded value.
ClassMethod LogicalToXSD(%val As %Binary) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		If %parameter("CANONICALXML") {
			Set %code="$system.Encryption.Base64Encode(%val,1)"
		} Else {
			Set %code="$system.Encryption.Base64Encode(%val,$get(%xmlBase64NoLineBreaks))"
		}
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the base64 encoded input value to a logical value.
ClassMethod JSONToLogical(%val As %String) As %Binary [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$system.Encryption.Base64Decode($translate(%val,$char(9,10,13,32)))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the logical %Binary value to the base64 encoded value.
ClassMethod LogicalToJSON(%val As %Binary) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$system.Encryption.Base64Encode(%val,1)"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Tests if the logical value <var>%val</var>, which is a string, is valid.
/// The validation is based on the class parameter settings used for the class attribute this data type is associated with.
/// In this case, <a href="#MINLEN">MINLEN</a>, <a href="#MAXLEN">MAXLEN</a>, and <a href="#PATTERN">PATTERN</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	Set %code=0
	Set %codemode=$$$cMETHCODEMODEEXPRESSION
	Set str=""
	If %parameter("MINLEN")'="" s str=str_"($l(%val)<"_(+%parameter("MINLEN"))_"):$$$ERROR($$$DTMinLen,%val,"_+%parameter("MINLEN")_")"
	If %parameter("MAXLEN")'="" s str=str_$s(str="":"",1:",")_"($l(%val)>"_(+%parameter("MAXLEN"))_"):$$$ERROR($$$DTMaxLen,%val,"_+%parameter("MAXLEN")_")"
	If str="" s %code=1 QUIT $$$OK
	Set %code="$select("_str_",1:$$$OK)"
	QUIT $$$OK
}

}
