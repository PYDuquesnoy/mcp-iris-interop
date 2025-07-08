/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.XMLA.PropertiesRestrictions Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Property PropertyName As String;

Property PropertyNameList As list Of String(XMLPROJECTION = "none");

Method Normalize() As %Status
{
	quit ##class(Server).ParseRestrictions("PropertyName", ..PropertyName, ..PropertyNameList)
}

}
