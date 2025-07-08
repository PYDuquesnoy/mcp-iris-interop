/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// used by dsFormulaParser
Class %ZEN.Report.Display.COSChart.parseTreeNode Extends %RegisteredObject [ Deprecated ]
{

Property children As array Of %ZEN.Report.Display.COSChart.parseTreeNode;

Property type As %String;

Property value As %String;

Property inParens As %Boolean;

Method %OnNew(type, value) As %Status
{
	if '$D(type) quit $$$OK
	Set ..type=type
	if '$D(value) quit $$$OK
	Set ..value=value
	quit $$$OK
}

Method dumpTree()
{
	for i=1:1:..children.Count() {
		do ..children.GetAt(i).dumpTree()
	}
}

}
