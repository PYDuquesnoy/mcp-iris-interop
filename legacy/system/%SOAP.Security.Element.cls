/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Abstract base class for security elements in SOAP Security header.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.Security.Element Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

/// Force any subclass into choice list.
/// This usage of XMLINCLUDEINGROUP is only needed for classes in %XML and %SOAP packages.
Parameter XMLINCLUDEINGROUP = 2;

Property Id As %String(MAXLEN = "", REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLPROJECTION = "ATTRIBUTE", XMLREF = 1) [ Internal ];

/// Return the value of the Id property.
/// Populate the Id property if it is not yet set.
Method GetId() As %String [ Internal ]
{
	If ..Id="" Set ..Id="Id-"_$system.Util.CreateGUID()
	Quit ..Id
}

/// Indicates that this element was originally encrypted
Property WasEncrypted As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// If this is the decrypted version of an EncryptedData element, then the original element
Property OriginalElement As %SOAP.Security.Element(XMLPROJECTION = "none") [ Internal ];

/// Default Initializationation method
Method InitializeForService(service As %SOAP.WebBase, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Default InitializeKey method.  Called to complete unreferenced Key element.
Method InitializeKey(service As %SOAP.WebBase, algorithm As %String) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Default method to perform the work.
Method Perform(messageStream As %BinaryStream, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Default Reset method
Method Reset() [ Internal ]
{
	Set ..OriginalElement=""
	Set ..WasEncrypted=0
}

/// Default Validate method
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	Quit ""
}

}
