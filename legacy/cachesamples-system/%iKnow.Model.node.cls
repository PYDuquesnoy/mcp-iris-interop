/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.Model.node Extends %iKnow.Model.abstractNode [ Abstract, Deprecated, System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/iknow";

Parameter XMLINCLUDEINGROUP = 1;

Parameter XMLIGNOREINVALIDATTRIBUTE = 0;

/// Utility method to check if a particular attribute value is actually an expression and should
/// not necessarily be validated at compile-time (fe, configuration name)
ClassMethod %IsExpression(pString As %String) As %Boolean [ Internal ]
{
	quit $find(pString, "%domain.") || $find(pString, "%expression.")
}

/// Some basic XML formatting
/// Note: this expects nicely formatted attribute content and no surprises in CDATA !
ClassMethod FormatXML(pString As %String) As %String [ Internal ]
{
	set tString = "", tPrevPos=0
	for {
		set tPos = $find(pString,"<",tPrevPos)
		if 'tPos {
			set tString = tString _ $e(pString,tPrevPos,*)
			quit
		}
				
		// first add tag content, if any
		if tPrevPos && (tPrevPos<tPos-2) {
			set tString = tString_$e(pString,tPrevPos,tPos-2)
		}
		
		// catch CDATA
		if ($e(pString,tPos,tPos+6)="!CDATA[") {
			set tEndPos = $find(pString,"]]>",tPos)
			set tString = tString_$e(pString,tPos-1,tEndPos-1)
			set tPrevPos = tEndPos
			set tLastOpenTag = ""
			continue
		}
		
		// process normal tags
		set tFirstSpace = $find(pString," ",tPos), tFirstClose = $find(pString,">",tPos)
		set tTag = $e(pString,tPos,$s(tFirstSpace&&(tFirstSpace<tFirstClose):tFirstSpace, 1:tFirstClose)-2)
		
		// check if we can immediately close the tag
		set tClosing = $e(pString,tFirstClose,tFirstClose+$l(tTag)+2)
		if (tClosing = ("</"_tTag_">")) || (tClosing = ("</"_tTag_" ")) {
			set tString = tString _ $e(pString,tPos-1,tFirstClose-2) _ " />"_$c(13,10)
			set tPrevPos = $find(pString,">",tFirstClose)
		} else {
			// just append tag
			set tString = tString _ $e(pString,tPos-1,tFirstClose-1)
			set tPrevPos = tFirstClose
			
			if ($e(pString,tFirstClose)="<") && ($e(pString,tFirstClose,tFirstClose+7)'="<!CDATA[") {
				set tString = tString _ $c(13,10)
			}
		}
	}
	quit tString
}

}
