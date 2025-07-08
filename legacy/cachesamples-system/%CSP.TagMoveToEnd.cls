/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Instances of this class can be added to the DOM for a CSP in order to copy their children
/// to the end of their parent's list of children.  The purpose of this tag is to allow children to
/// be added to the end of the Children list from an OnMatch method.
Class %CSP.TagMoveToEnd Extends %CSP.Rule [ System = 3 ]
{

/// When this DOM element encountered, move this tag's children to the end of the parent's child list.
Method RenderStartTag() As %Status
{
	Set parent=..Parent
	For i=1:1:..Children.Count() {
		Set child=..Children.GetAt(i)
		Set child.Parent=parent
		Do parent.Children.Insert(child)
	}
	Quit $$$SKIPCHILDREN
}

}
