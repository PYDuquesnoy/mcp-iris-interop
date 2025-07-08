/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.token Extends %RegisteredObject [ Deprecated ]
{

Property type As %String;

Property value As %String;

Method %OnNew(type, value) As %Status
{
	Set ..type=type
	Set ..value=value
	quit $$$OK
}

}
