/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.TextAtom</b> class represents a section of text within an HTML document. 
/// <b>%CSP.TextAtom</b> has no properties other than HTML text.
Class %CSP.TextAtom Extends %CSP.AbstractAtom [ Not ProcedureBlock, System = 3 ]
{

/// A flag indicating if this test is comment or not.
/// For comment, embedded expressions will not be translated.
Property IsComment As %Boolean;

/// A string containing the text for this element.
Property Text As %String;

/// Initialize text in the atom
Method %OnNew(initval As %String = "") As %Status [ Internal, Private ]
{
 Set i%Text=initval
 Quit $$$OK
}

/// Writes code into the routine builder object that will render this element.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering text "_$tr(..Text,$c(13,10),$c(182)))
 New i,text,lines
 Set text=..Text,lines=$length(text,$$$EOL)

 If i%IsComment {
 	For i=1:1:lines Do ..WriteText($p(text,$$$EOL,i),(i<lines))
 } Else {
 	For i=1:1:lines Do ..WriteCSPText($p(text,$$$EOL,i),(i<lines))
 }

 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $$$SKIPCHILDREN
}

}
