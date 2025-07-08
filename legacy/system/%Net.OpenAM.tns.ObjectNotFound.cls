/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://glassfish.iscinternal.com:9180/opensso/identityservices?WSDL
Class %Net.OpenAM.tns.ObjectNotFound Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = , Inheritance = right, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 0;

Parameter NAMESPACE = "http://opensso.idsvcs.identity.sun.com/";

Parameter XMLNAME = "ObjectNotFound";

Parameter XMLSEQUENCE = 1;

Property message As %String(MAXLEN = "", XMLNAME = "message");

}
