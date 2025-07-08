/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://glassfish.iscinternal.com:9180/opensso/identityservices?WSDL
Class %Net.OpenAM.tns.identityDetails Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = , Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 0;

Parameter NAMESPACE = "http://opensso.idsvcs.identity.sun.com/";

Parameter XMLNAME = "identityDetails";

Parameter XMLSEQUENCE = 1;

Property name As %String(MAXLEN = "", XMLNAME = "name");

Property type As %String(MAXLEN = "", XMLNAME = "type");

Property realm As %String(MAXLEN = "", XMLNAME = "realm");

Property roles As list Of %String(MAXLEN = "", XMLNAME = "roles", XMLPROJECTION = "ELEMENT");

Property groups As list Of %String(MAXLEN = "", XMLNAME = "groups", XMLPROJECTION = "ELEMENT");

Property members As list Of %String(MAXLEN = "", XMLNAME = "members", XMLPROJECTION = "ELEMENT");

Property attributes As list Of %Net.OpenAM.tns.attribute(XMLNAME = "attributes", XMLPROJECTION = "ELEMENT");

}
