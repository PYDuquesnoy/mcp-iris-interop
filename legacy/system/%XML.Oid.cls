/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %XML.Oid datatype class represents an OID field in an XML enabled class and has the following behavior:<br>
/// 1) If the property has not been set, it's value will default to ..%Oid(). 
/// Thus opening and exporting a persistent object will result in including the OID.<br>
/// 2) It is possible to set the property value and then retrieve it. Thus 
/// the exported class can be imported and the imported Id is available to 
/// the programmer. Note that it will still be the programmer's 
/// responsibility to deal with the imported OID -- no automatic matching of 
/// records is done based on this OID. 
Class %XML.Oid Extends %String [ System = 2 ]
{

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "string";

/// Override of default Get method
Method Get() As %String [ CodeMode = generator, Internal, NoContext ]
{
	If $$$getClassType(%class)'=$$$cCLASSCLASSTYPEDATATYPE {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		If $$$comClassKeyGet(%class,$$$cCLASSclasstype) = $$$cCLASSCLASSTYPEPERSISTENT {
			Set %code="$select(i%"_%property_"="""":$lg(..%Oid(),2)_"",""_$lg(..%Oid()),1:i%"_%property_")"
		} Else {
			Set %code="i%"_%property
		}
	} Else {
		Set %code=0
	}
	Quit $$$OK
}

}
