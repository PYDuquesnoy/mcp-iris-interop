/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%Status</b> data type class is used to represent an error status code.
/// 
/// <p>Many of the methods provided by the system classes return error status 
/// information using the <b>%Status</b> data type. The include file <i>%occStatus.INC</i> contains several 
/// macro definitions that are useful in testing the value of an error code in <b>%Status</b> format.
/// These macros include:
/// </p>
/// <ul>
/// <li><code>$$$ISOK(status:%Status)</code> returns true (1) if the status code <var>status</var> 
/// does not represent an error condition.</li>
/// <li><code>$$$ISERR(status:%Status)</code> returns true (1) if the status code <var>status</var> 
/// represents an error condition.</li>
/// </ul>
/// <p>You can get a more detailed description of an error by using  
/// $system.Status.DecomposeStatus(status:%Status,&amp;err,flag), which 
/// takes a status code and returns an array of error strings; see <class>%SYSTEM.Status</class>.
/// </p>
/// <p>For example:
/// </p>
/// <example>
/// Set status=obj.%Save()
/// If $$$ISERR(status) Do $system.Status.DecomposeStatus(status,.err,"-d")
/// For i=1:1:err Write err(i),!
/// </example>
Class %Library.Status [ ClassType = datatype, ClientDataType = STATUS, System = 2 ]
{

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "base64Binary";

/// JSONTYPE is JSON type used for this datatype.
Parameter JSONTYPE = "string";

/// Maximum expected length of a %Status value
Parameter MAXLEN = 65536;

/// Converts the SOAP encoded base64 input value to a logical value.
ClassMethod XSDToLogical(%val As %String) As %Binary [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$system.Encryption.Base64Decode($translate(%val,$char(9,10,13,32)))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the %Binary value to the SOAP base64 encoded value.
ClassMethod LogicalToXSD(%val As %Binary) As %String [ CodeMode = generator ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$system.Encryption.Base64Encode(%val)"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the value of this data type from <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$LIST+FUNCTION">$List</a> format to a delimited string 
/// using the value of the <var>ODBCDELIMITER</var> parameter as a delimiter.
ClassMethod LogicalToOdbc(%val = "") As %String
{
	If $$$ISOK(%val) RETURN %val
	Do $system.Status.DecomposeStatus(%val,.text,"-d")
	Set one="" For i=1:1:$g(text) Set:i>1 one=one_$c(13,10) Set one=one_$g(text(i)) 
	RETURN one
}

}
