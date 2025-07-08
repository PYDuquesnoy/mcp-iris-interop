/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleText</b> class represents text within the DOM model for a CSR page.
Class %CSP.RuleText Extends %CSP.TextAtom [ System = 3 ]
{

/// Writes code into the routine builder object that will 
/// add outputing of the specified text to this rule class.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering text "_$tr(..Text,$c(13,10),$c(182)))
 Set doCmd=$case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Do ..")
 Set text=..Text
 If text="" Quit $$$SKIPCHILDREN
 If text=$$$EOL Quit $$$SKIPCHILDREN
 Set lines=$length(text,$$$EOL)
 For i=1:1:lines Do ..WriteServer(doCmd_"WriteCSPText("_$$Quote^%cspQuote($p(text,$$$EOL,i))_","_(i<lines)_")")
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering text finished")
 Quit $$$SKIPCHILDREN
}

}
