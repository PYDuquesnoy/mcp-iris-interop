/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

Class EnsLib.EDI.SEF.Util.Stack Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This property holds the stack items
Property Items [ MultiDimensional ];

/// This holds the index of top of the stack
Property CurrentIndex As %Integer [ InitialExpression = 0 ];

/// This method clears the stack
Method Clear()
{
	Kill ..Items  Set ..CurrentIndex=0
}

Method Display()
{
	For tI=1:1:..CurrentIndex {
		Write tI," = ",..Items(tI),!
	}
}

/// This method determines if the stack is empty
Method Empty() As %Boolean [ CodeMode = expression ]
{
..CurrentIndex=0
}

/// This method pushes an item onto the stack
Method Push(Item As %String)
{
	Set ..CurrentIndex=..CurrentIndex+1
	Set ..Items(..CurrentIndex)=Item
}

/// This method pops an item off the stack, if the stack is empty
/// an underflow exception will be thrown
Method Pop()
{
	ZT:'..CurrentIndex "UFLOW"
	Kill ..Items(..CurrentIndex)
	Set ..CurrentIndex=..CurrentIndex-1
}

/// This method retrieves the item at the top of the stack, if the stack
/// is empty an underflow exception will be thrown
Method Top() As %String
{
	ZT:'..CurrentIndex "UFLOW"
	Quit ..Items(..CurrentIndex)
}

}
