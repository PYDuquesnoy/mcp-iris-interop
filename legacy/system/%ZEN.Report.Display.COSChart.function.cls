/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// used by dsFormulaParser
Class %ZEN.Report.Display.COSChart.function Extends %RegisteredObject [ Deprecated ]
{

Property instance As %String;

Property methodname As %String;

Property key As %String;

Method %OnNew(key, instance, methodname) As %Status
{
	Set ..instance = instance
	Set ..methodname = methodname
	Set ..key = key
	quit $$$OK
}

}
