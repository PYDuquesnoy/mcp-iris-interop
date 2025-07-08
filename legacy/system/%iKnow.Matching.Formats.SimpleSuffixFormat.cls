/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This sample <class>%iKnow.Matching.Formats.Format</class> implementation checks whether any word in a string ends with the supplied
/// suffix and optionally returns the fragment (or just the word) preceding the suffix. If the suffix
/// is preceded by only a single word (directly or separated with a space), it is considered a full
/// match.</p>
/// 
/// <p><b>Format parameters:</b></p>
/// <ol>
/// 	<li><b>suffix</b> (<class>%String</class>, no default) - the suffix to check for (cannot contain spaces)</li>
/// 	<li><b>lastWordOnly</b> (<class>%Boolean</class>, default 0) - whether to check for the last word of the entity only</li>
/// 	<li><b>outputType</b> (<class>%Integer</class>, default 0) - what to supply in terms of output:
/// 			<ul>
/// 			<li>0: no output</li>
/// 			<li>1: the remainder of the word preceding the (first occurrence of the) suffix</li>
/// 			<li>2: same as 1, but if there is a space preceding the suffix, returns the word before</li>
/// 			<li>3: the whole entity up to the (first occurrence of the) suffix</li>
/// 			</ul></li>
/// </ol>
Class %iKnow.Matching.Formats.SimpleSuffixFormat Extends %iKnow.Matching.Formats.Format [ Deprecated, System = 4 ]
{

Method MatchSingle(string As %String, formatParams As %List, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status
{
	set matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
	
	set suffix = ..ConvertFormatCase($lg(formatParams,1))
	quit:suffix="" $$$ERROR($$$InvalidArgument)
	
	set lastWordOnly = $lg(formatParams,2,0)
	set outputType = +$lg(formatParams,3,0)
	quit:outputType>3 $$$ERROR($$$InvalidArgument)
	
	set string = $zstrip(string, "=<>W")
	set suffixLength = $length(suffix)
	set stringLength = $length(string)
	
	// derive matched word bits and first occurrence position
	set hasOcc = 0
	set stringList = $lfs(string," ")
	set wordCount = $ll(stringList)
	for i=1:1:wordCount {
		set word = $li(stringList,i), wordLength = $length(word)
		set suffixed = ($e(word, wordLength-suffixLength+1, wordLength)=suffix)
		set $bit(matchedWordBits, i) = suffixed
		set:'hasOcc hasOcc = suffixed*i
	}
	quit:'hasOcc $$$OK
	quit:lastWordOnly&&'$bit(matchedWordBits,wordCount) $$$OK
	
	// derive match type
	set spaceBefore = $length($li(stringList,hasOcc))=suffixLength
	if (wordCount-1-spaceBefore) <= 0 {
		set matchScore = 1
	} else {
		set matchScore = 0.75
	}
	
	// build output
	if (outputType=1) {
		set formatOutput = $e($li(stringList,hasOcc), 1, *-suffixLength)
	} elseif (outputType=2) {
		set formatOutput = $s(spaceBefore:$li(stringList,hasOcc-1), 1:$e($li(stringList,hasOcc), 1, *-suffixLength))
	} elseif (outputType=3) {
		set formatOutput = $e($lts($li(stringList,1,hasOcc)," "),1,*-suffixLength)
	}
	
	quit $$$OK
}

}
