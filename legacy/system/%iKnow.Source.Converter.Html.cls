/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a sample implementation for <class>%iKnow.Source.Converter</class>, designed 
/// to weed out HTML tags from plain text input. Data is first buffered into a process-private
/// global and stripped of HTML in the <method>Convert</method> call.</p>
/// <p><b>Converter parameters</b>:
/// <ol>
/// 		<li><b>Unescape</b> As <class>%Boolean</class>: set to 1 to unescape HTML special
/// 				characters such as converting "&amp;amp;" to "&amp;" (default = 1)</li>
/// 		<li><b>SkipTags</b> As <class>%String</class>: comma-separated list of tags whose content
/// 				(text nested between the start and end tag) is to be left out (default = "script,style")</li>
/// 		<li><b>BreakLines</b> As <class>%Boolean</class>: whether or not to insert double 
/// 					line breaks for non-inline tags (such as p, br, td, ...), in order for the
/// 				iKnow engine to split sentences at those positions (default = 1)</li>
/// </ol></p>
Class %iKnow.Source.Converter.Html Extends %iKnow.Source.Converter [ Deprecated, System = 4 ]
{

Property Unescape As %Boolean [ InitialExpression = 1 ];

Property SkipTags As %String(MAXLEN = "") [ InitialExpression = ",script,style," ];

Property BreakLines As %Boolean [ InitialExpression = 1 ];

/// Make sure the PPG is empty
Method %OnNew(params As %String) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = ##super($g(params))
	kill ^||%IK.HtmlConv, ^||%IK.HtmlConvDone
    quit tSC
}

/// <p>Utility method called by the <class>%iKnow.Source.Processor</class> and <class>%iKnow.Source.Loader</class> 
/// logic to register any new or changed parameter values.</p>
Method SetParams(params As %String) As %Status
{
	if $listvalid(params) {
		set:$ld(params,1) i%Unescape = +$lg(params,1)
		set:$ld(params,2) i%SkipTags = ","_$$$LOWER($lg(params,2))_","
		set:$ld(params,3) i%BreakLines = +$lg(params,3)
	} else {
		set i%Unescape = +params
	}
	kill ^||%IK.HtmlConv, ^||%IK.HtmlConvDone
	quit $$$OK
}

/// Buffer data in the PPG
Method BufferString(data As %String) As %Status
{
	set ^||%IK.HtmlConv($i(^||%IK.HtmlConv)) = data
	quit $$$OK
}

/// <p>Loop through buffered data and strip off HTML tags. Reset the pointer in the root
/// PPG node at the end, for <method>NextConverterdPart</method> to know
/// where to start.</p>
Method Convert() As %Status
{
	set tEndTag = "", tUnescape = i%Unescape, tSkipTags = i%SkipTags, tBreakLines = i%BreakLines
	
	if tBreakLines {
		for tTag = "b","i","span","u","a","font","em","strong","img","label","small","sup","sub" {
			set tReplaceTag(tTag) = " ", tReplaceTag("/"_tTag) = " "
		}
	}
	
	kill ^||%IK.HtmlConvDone
	set tRunningSkipTag = ""
	for i = 1:1:+$g(^||%IK.HtmlConv) {
		set tString = tEndTag _ $g(^||%IK.HtmlConv(i)), tEndTag = ""
		set tLowerText = $$$LOWER(tString)
		
		if (tRunningSkipTag'="") {
			// look for closing tag
			set tPos = $find(tLowerText,"</"_tRunningSkipTag)
			if tPos {
				// if found, skip everything up to the closing tag
				set tRunningSkipTag = ""
				set tPosEnd = $find(tLowerText,">",tPos)
				set tString = $e(tString,tPosEnd,*), tLowerText = $e(tLowerText,tPosEnd,*)
			} else {
				// if not found, look at the next index, but make sure to carry incomplete 
				// closing tags along
				if $find(tLowerText,"</") {
					set tLastPos = $l(tLowerText)-$find($reverse(tLowerText),"/<")
					set tEndTag = $e(tString,tLastPos+2,*-1)
				}
				continue
			}
		}
		
		set tStartPos = 0
		for {
			set tPos = $find(tLowerText, "<", tStartPos)
			quit:'tPos // no tag start found
			
			// find the next space or > to build the tag name
			set tNextSpace = $f(tLowerText," ",tPos), tNextEnd = $f(tLowerText,">",tPos)
			
			// if this *could* have been a skippable tag, but the line ended early, prepend to next line
			if (tNextEnd=0) && (tNextSpace>=$l(tLowerText)) && (tSkipTags[(","_$e(tLowerText,tPos,*-1))) {
				set tEndTag = $e(tString,tPos-1,*-1), tString = $e(tString,1,tPos-2)
				quit
			} else {
				// find the tag name
				set tTag = $e(tLowerText,tPos,$s(tNextSpace&&(tNextSpace<tNextEnd):tNextSpace, 1:tNextEnd)-2)
				
				// if this tag needs to be skipped, find the closing tag
				if (tTag'="") && (tSkipTags[(","_tTag_",")) {
					set tPosEndTag = $find(tLowerText,"</"_tTag,tPos)
					
					// if no closing tag found, keep track of it and move on
					if 'tPosEndTag {
						set tRunningSkipTag = tTag, tPosEnd = 0
					} else {
						set tPosEnd = $find(tLowerText,">",tPosEndTag)
					}
				} else {
					
					// otherwise, just proceed to the tag close char >
					set tPosEnd = tNextEnd
				}
			}
			
			// we don't know where to end the current tag (skippable or not), so keep track
			// and move on
			if 'tPosEnd {
				set tEndTag = $e(tString,tPos-1,*)
				set tString = $e(tString,1,tPos-2)
				quit
			}
			
			// now replace the tag with the appropriate string
			set tReplace = $s('tBreakLines:" ", tTag="":" ", 1:$g(tReplaceTag(tTag),$c(13,10,13,10)))
			set tString = $e(tString,1,tPos-2) _ tReplace _ $e(tString,tPosEnd,*)
			set tLowerText = $e(tLowerText,1,tPos-2) _ tReplace _ $e(tLowerText,tPosEnd,*)
		}
		set:tUnescape tString = $zstrip($zconvert(tString, "I", "HTML"),"=W")
		set:tString'="" ^||%IK.HtmlConvDone(i) = tString
	}
	kill ^||%IK.HtmlConv
	
	// if there is still a pending would-be tag, we assume it's supposed to be left out
	
	quit $$$OK
}

/// Loop through the PPG again and return processed strings.
Method NextConvertedPart() As %String
{
	set tCurrentIndex = $g(^||%IK.HtmlConvDone)
	set tNextIndex = $order(^||%IK.HtmlConvDone(tCurrentIndex),1,tString)
	
	if (tNextIndex="") {
		kill ^||%IK.HtmlConvDone, ^||%IK.HtmlConv
		quit ""
	}
	set ^||%IK.HtmlConvDone = tNextIndex
	
	quit tString
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	kill ^||%IK.HtmlConv, ^||%IK.HtmlConvDone
	quit $$$OK
}

/// Utility method to strip HTML tags from the supplied string. See the class documentation
/// for more details on the available parameters.
ClassMethod StripHTML(ByRef pText As %String, pUnescape As %Boolean = 1, pSkipTags As %String = "script,style", pBreakLines As %Boolean = 1, Output pSC As %Status) As %String
{
	quit ..Test(.pText, $lb(pUnescape, pSkipTags, pBreakLines), .pSC)
}

}
