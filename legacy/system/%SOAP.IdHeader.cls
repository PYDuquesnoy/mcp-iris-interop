/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated since now all headers may have wsu:Id attribute.  
/// Contents of this class added to %SOAP.Header
/// Super class for all SOAP headers which have a wsu:Id attribute
/// 
Class %SOAP.IdHeader Extends %SOAP.Header [ Deprecated, System = 3 ]
{

/// Header may have a wsu:Id attribute
Property Id As %String(MAXLEN = "", REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLPROJECTION = "XATTRIBUTE", XMLREF = 1);

/// Return the value of the Id property.
/// Populate the Id property if it is not yet set.
Method GetId() As %String
{
	If ..Id="" Set ..Id="Id-"_$system.Util.CreateGUID()
	Quit ..Id
}

}
