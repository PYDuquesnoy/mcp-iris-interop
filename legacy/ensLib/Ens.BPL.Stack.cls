/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is an internal detail of the implementation of the BPL Compiler
Class Ens.BPL.Stack Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This property holds the stack items
Property Items As array Of %String;

/// This holds the index of top of the stack
Property CurrentIndex As %Integer [ InitialExpression = 0 ];

/// This method determines if the stack is empty
Method Empty() As %Boolean [ CodeMode = expression ]
{
..CurrentIndex=0
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

/// This method retrieves the item at the top of the stack, if the stack
/// is empty an underflow exception will be thrown
Method Top() As %String
{
	If ..Empty() ZT "UFLOW"
	Quit ..Items.GetAt(..CurrentIndex)
}

Method Peek(ByRef pItem As %String) As %Boolean
{
	If (..CurrentIndex-1) < 1 Quit 0
	Set pItem=..Items.GetAt(..CurrentIndex-1)
	Quit 1
}

}
