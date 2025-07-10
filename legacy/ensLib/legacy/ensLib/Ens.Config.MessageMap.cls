/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Config.MessageMap Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

Parameter XMLNAME = "MapItem";

Property MessageType As %String(MAXLEN = 128, XMLNAME = "MessageType", XMLPROJECTION = "ATTRIBUTE");

Property ActionMethod As %String(MAXLEN = 180, XMLNAME = "Method", XMLPROJECTION = "ELEMENT");

}
