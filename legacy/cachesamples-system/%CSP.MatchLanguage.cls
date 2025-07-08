/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS.
/// You should not make direct use of it within your applications.
/// There is no guarantee made about either the behavior or future operation of this class.<p>
/// 
/// The <b>CSP:MATCHLANGUAGE</b> tag forces a single call to %response.MatchLanguage
/// to be added to the PREHTML section.  This tag is a way for the programmer to
/// force setting of %response.Language for the current page.
Class %CSP.MatchLanguage Extends %CSP.Rule [ System = 3 ]
{

/// When object encountered in DOM scan then add code to get browser language.
Method RenderStartTag() As %Status [ Internal ]
{
	If %compiler.Get("%language")="" {
		Do %compiler.Set("%language",1)  ; make sure only generated once
		Do ..PushDefaultSection("PREHTML,0")
		Do ..WriteServer($select(%compiler.IsBasic:"",1:"	Do")_" %response"_$select(%compiler.PageLanguage="mvbasic":"->",1:".")_"MatchLanguage()",0)
		Do ..PopDefaultSection() 
	}
	Quit $$$SKIPCHILDREN
}

}
