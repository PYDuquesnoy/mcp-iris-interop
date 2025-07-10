/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class is an internal detail of the implementation of the BPL compiler.
Class Ens.BPL.ContextStack Extends Ens.BPL.Stack [ ClassType = "", ProcedureBlock, System = 3 ]
{

Property Path As %String [ Calculated ];

/// Return the context path as a string
Method PathGet() As %String
{
	Set tIndex=1,tPath=""
	While (tIndex'>..CurrentIndex) {
		Set tPath=tPath_"\"_..Items.GetAt(tIndex)
		Set tIndex=tIndex+1
	}
	Quit tPath
}

/// This method pushes an item onto the stack
Method Push(Item As %String)
{
	Set ..CurrentIndex=..CurrentIndex+1
	Do ..Items.SetAt(Item,..CurrentIndex)
}

/// This method pops an item off the stack, if the stack is empty
/// an underflow exception will be thrown
Method Pop()
{
	If ..Empty() ZT "UFLOW"
	Do ..Items.RemoveAt(..CurrentIndex)
	Set ..CurrentIndex=..CurrentIndex-1
}

/// This method returns the current context by examining the
/// context 'Path' to return the innermost recognized code context
Method CurrentContext() As Ens.DataType.CodeContext
{
	$$$ASSERT('..Empty())
	Set tPath=..Path For tI=$Length(tPath,"\"):-1:1 {
		Set tP=$Piece(tPath,"\",tI)
		If tP="Process"||(tP="Request")||(tP="Response") Quit
	}
	If tP="Process" Quit $$$eCodeContextProcess
	If tP="Request" Quit $$$eCodeContextRequest
	If tP="Response" Quit $$$eCodeContextResponse
	Quit $$$eCodeContextNone
}

}
