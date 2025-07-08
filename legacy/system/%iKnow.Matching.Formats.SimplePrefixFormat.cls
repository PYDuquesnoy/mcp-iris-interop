/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This sample <class>%iKnow.Matching.Formats.Format</class> implementation checks whether a string starts with a given character sequence,
/// offering a meaningful <method>MatchAll</method> example.</p>
/// 
/// <p><b>Format parameters:</b></p>
/// <ol>
/// 	<li><b>prefix</b> (<class>%String</class>, no default) - the prefix to check for, with no double, starting or trailing spaces</li>
/// 	<li><b>outputType</b> (<class>%Integer</class>, default 0) - what to supply in terms of output:
/// 			<ul>
/// 			<li>0: no output</li>
/// 			<li>1: the remainder of the word following the (first occurrence of the) prefix</li>
/// 			<li>2: same as 1, but if there is a space following the prefix, returns the next word</li>
/// 			<li>3: the whole entity starting right after the (first occurrence of the) prefix</li>
/// 			</ul></li>
/// </ol>
Class %iKnow.Matching.Formats.SimplePrefixFormat Extends %iKnow.Matching.Formats.Format [ Deprecated, System = 4 ]
{

/// <!-- This only works if the $$$IKMATCHINGCASELOWER is used -->
Method HasMatchAll() As %Boolean
{
	quit 1 //(..CaseType=$$$IKMATCHINGCASELOWER)
}

Method MatchAll(stringsGlobalName As %String, resultGlobalName As %String, formatParams As %List, minEntUniId As %Integer = 0) As %Status
{
	set prefix = ..ConvertFormatCase($zstrip($lg(formatParams,1),"=<>W"))
	quit:prefix="" $$$ERROR($$$InvalidArgument)
	
	set outputType = +$lg(formatParams,2,0)
	quit:outputType>3 $$$ERROR($$$InvalidArgument)

	set prefixLength = $length(prefix)
	
	set tSC = $$$OK
	set string = $order(@stringsGlobalName@(" "_prefix),-1)
	for {
		set string = $order(@stringsGlobalName@(string),1,id)
		quit:string=""
		quit:($e(string,2,prefixLength+1)'=prefix)
		
		set matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
		set tSC = ..CalculateOutParams($e(string,2,*), prefix, outputType, .matchScore, .matchedWordBits, .isScattered, .formatOutput)
		quit:$$$ISERR(tSC)
		
		continue:'matchScore
		
		set @resultGlobalName@(id) = $lb(matchScore, matchedWordBits, isScattered, formatOutput)
	}
	
	quit tSC
}

Method MatchSingle(string As %String, formatParams As %List, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status
{
	set matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
	
	set prefix = ..ConvertFormatCase($zstrip($lg(formatParams,1),"=<>W"))
	quit:prefix="" $$$ERROR($$$InvalidArgument)
	
	set outputType = +$lg(formatParams,2,0)
	quit:outputType>3 $$$ERROR($$$InvalidArgument)
	
	set string = $zstrip(string, "=<>W")
	set prefixLength = $length(prefix)
	
	quit:($e(string,1,prefixLength)'=prefix) $$$OK
	
	quit ..CalculateOutParams(string, prefix, outputType, .matchScore, .matchedWordBits, .formatOutput)
}

Method CalculateOutParams(string As %String, prefix As %String, outputType As %Integer, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status [ Private ]
{
	set isScattered = 0
	
	set prefixLength = $length(prefix)
	set stringLength = $length(string)
	set prefixWordCount = $length(prefix," ")
	
	set stringList = $lfs(string," ")
	set wordCount = $ll(stringList)
	for i=1:1:wordCount {
		set $bit(matchedWordBits,i) = (i<=prefixWordCount)
	}
	
	// derive match type
	set spaceAfter = ($e(string,prefixLength+1)=" ")
	if (prefixWordCount+spaceAfter = wordCount) {
		set matchScore = 1
	} else {
		set matchScore = 0.75
	}
	
	// build output
	if (outputType=1) {
		set formatOutput = $e(string, prefixLength+1, $find(string," ",prefixLength)-2)
	} elseif (outputType=2) {
		set formatOutput = $s(spaceAfter:$li(stringList,prefixWordCount+1), 1:$e(string, prefixLength+1, $find(string," ",prefixLength)-2))
	} elseif (outputType=3) {
		set formatOutput = $e(string, prefixLength+1, *)
	}
	
	quit $$$OK
}

}
