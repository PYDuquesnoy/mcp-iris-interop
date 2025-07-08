/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://glassfish.iscinternal.com:9180/opensso/identityservices?WSDL
Class %Net.OpenAM.tns.userDetails Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = , Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 0;

Parameter NAMESPACE = "http://opensso.idsvcs.identity.sun.com/";

Parameter XMLNAME = "userDetails";

Parameter XMLSEQUENCE = 1;

Property attributes As list Of %Net.OpenAM.tns.attribute(XMLNAME = "attributes", XMLPROJECTION = "ELEMENT");

Property roles As list Of %String(MAXLEN = "", XMLNAME = "roles", XMLPROJECTION = "ELEMENT");

Property token As %Net.OpenAM.tns.token(XMLNAME = "token");

}
