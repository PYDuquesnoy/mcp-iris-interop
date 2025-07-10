/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Model.base Extends (%RegisteredObject, %XML.Adaptor, %JSON.Adaptor) [ Abstract, System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/rule";

Parameter XMLIGNORENULL = 1;

Parameter %JSONIGNOREINVALIDFIELD = 1;

Parameter %JSONIGNORENULL = 1;

Property type As %String(MAXLEN = "", XMLPROJECTION = "NONE");

Method typeGet() As %String
{
	quit ..%ClassName(0)
}

}
