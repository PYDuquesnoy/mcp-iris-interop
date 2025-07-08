/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// PropertiesType from WS-SecureConversation 1.4.
/// MetaData for DerviedKeyToken.<br><br>
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.WSSC.Properties Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsc";

/// Order of elements does not matter
Parameter XMLSEQUENCE = 0;

/// Ignore unexpected elements.
Parameter XMLIGNOREINVALIDTAG = 1;

Property Name As %xsd.anyURI;

Property Label As %String(MAXLEN = "");

Property Nonce As %xsd.base64Binary;

}
