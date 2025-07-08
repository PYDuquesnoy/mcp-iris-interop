/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// used by dsFormulaParser
/// Simple stack object.
Class %ZEN.Report.Display.COSChart.stack Extends %RegisteredObject [ Deprecated ]
{

Property stack [ MultiDimensional, Private ];

Property stackptr As %Integer [ Private ];

/// Simple stack object.
Method %OnNew() As %Status
{
	Set this=##this
	Set ..stackptr = 0
	quit $$$OK
}

Method push(item)
{
	Set this=##this
	Set ..stack(..stackptr) = item
	Set ..stackptr=..stackptr+1
}

Method debug()
{
	merge temp=..stack
	zw temp
}

Method pop()
{
	Set this=##this
	if (this.stackptr > 0) {
		Set this.stackptr = this.stackptr-1
		quit this.stack(this.stackptr)
	}
	quit ""
}

Method peek(offset)
{
	Set this=##this
	if (this.stackptr > offset) {
		quit this.stack(this.stackptr - (offset+1))
	}
	quit ""
}

}
