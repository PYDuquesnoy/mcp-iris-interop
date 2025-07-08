/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleElement</b> class is the super class of all classes that represent 
/// elements within the DOM model for a CSR page.
Class %CSP.RuleElement Extends %CSP.Rule [ System = 3 ]
{

/// Trim white space from rule text.
Method TrimChildren() [ Private ]
{
 If ..GetAttribute("xml:space")="preserve" Quit
 Set endsInEOL=0
 For i=1:1:..Children.Count() {
	Set element=..Children.GetAt(i)
	If $classname(element)="%CSP.RuleText" {
		Set text=element.Text
		Set element.Text=
		  $select(endsInEOL||($extract(text,1,$length($$$EOL))=$$$EOL):$$$EOL,1:"")_
		  $zstrip(text,"<>W",$$$EOL)
		Set endsInEOL=
		  ((text'="")&&($zstrip($piece(text,$$$EOL,$length(text,$$$EOL)),">W")=""))
	} Else {
		Set endsInEOL=0
	}
 }
 Quit
}

/// Get the value of the HTML attribute <var>name</var> for this element.
/// For rules do not resolve ##( )## and ##' '##.
Method GetAttribute(name As %String, default As %String = "") As %String
{
 Set parm=$ZCVT(name,"U")
 If '..TagAttributes.IsDefined(parm) Quit default
 Quit $lg(..TagAttributes.GetAt(parm),1,default)
}

}
