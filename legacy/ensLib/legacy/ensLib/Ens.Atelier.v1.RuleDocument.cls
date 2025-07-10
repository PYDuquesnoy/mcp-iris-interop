/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class provides some methods that Atelier uses to work with
/// Ensemble Business Rules
Class Ens.Atelier.v1.RuleDocument Extends Ens.Util.AbstractDocument [ System = 4 ]
{

Parameter EXTENSION = ".%rules";

/// URL to use to get actual editor for Studio to display.
Parameter EDITORURL = "EnsPortal.RuleEditor.zen";

ClassMethod GetURL(pName As %String) As %String
{
	Quit ..#EDITORURL _ "?RULE="_$zconvert($zconvert($piece(pName,".",1,*-1),"O","UTF8"),"O","URL") _ $select(..Exists(pName):"", 1:"&NEW=1")
}

}
