/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// RequestedProofToken contents from WS-Trust 1.3.
/// Either BinarySecret, EncryptedKey or ComputedKey may be specified, but not both.
Class %SOAP.WST.RequestedProofToken Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Property BinarySecret As %SOAP.WST.BinarySecret(REFNAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512", XMLREF = 1);

Property EncryptedKey As %XML.Security.EncryptedKey(REFNAMESPACE = "http://www.w3.org/2001/04/xmlenc#", XMLREF = 1);

/// Algorithm for computing key -- $$$SOAPWSTPSHA1
Property ComputedKey As %xsd.anyURI(REFNAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512", XMLREF = 1);

}
