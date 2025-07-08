/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This <class>%iKnow.Matching.Formats.Format</class> implementation enables users to use the
/// iFind search syntax as a pattern to locate matching entities in an iKnow domain. Please bear in
/// mind that iFind is meant for search scenario's (when looking up records matching the search string),
/// whereas iKnow matching is meant for annotation scenario's (to identify all matches of a search
/// string in a full domain).</p>
/// <p>Note: matches are only detected <i>within</i> entities and are case-insensitive.</p>
/// <p><b>Format parameters:</b></p>
/// <ol>
/// 	<li><b>iFind expression</b> (<class>%String</class>, mandatory): </li>
/// </ol>
Class %iKnow.Matching.Formats.iFind Extends Format [ Deprecated, System = 4 ]
{

Method MatchSingle(string As %String, formatParams As %List, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status
{
	set tSC = $$$OK, matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
	try {
		
		set tExpression = $s($lv(formatParams):$li(formatParams,1), 1:formatParams)
		set tExpression = $$$LOWER($zstrip(tExpression,"<>=W"))
		
		if ($e(tExpression)="(") && ($e(tExpression,*)=")") {
			
			// position-based
			set tExpression = $zstrip($e(tExpression,2,*-1),"<>W")
			set tExpressionWords = $length(tExpression," ")
			set tStringWords = $length(string," ")
			quit:tExpressionWords>tStringWords
			set tPosInString = 1, tIsMatch = 1
			for i = 1:1:tExpressionWords {
				set tWord = $piece(tExpression," ",i)
				if (tWord="?") { // wildcard: skip
					set tPosInString = tPosInString+1
					continue
				}
check			if (tWord'=$piece(string," ",tPosInString)) {
					if (i=1) && (tPosInString<=tStringWords) { // still looking for the first word!
						set tPosInString = tPosInString+1
						goto check
					}
					set tIsMatch = 0
				}
				set $bit(matchedWordBits,tPosInString) = 1
				set tPosInString = tPosInString+1
			}
			if (tIsMatch) {
				set matchScore = 1
			} else {
				set matchedWordBits=""
			}
			
		} elseif ($e(tExpression)="{") && ($e(tExpression,*)="}") {
			
			// entity-based
			set tExpression = $zstrip($e(tExpression,2,*-1),"<>W")
			set tExpandBefore = ($e(tExpression,1)="<")
			set tExpandAfter = ($e(tExpression,*)=">")
			set:tExpandBefore tExpression = $e(tExpression,2,*)
			set:tExpandAfter tExpression = $e(tExpression,1,*-1)
			
			if 'tExpandBefore && 'tExpandAfter {
				if (string=tExpression) {
					set matchScore = 1
					for i = 1:1:$l(string," ") { set $bit(matchedWordBits,i) = 1 }
				}
				quit
			}
			
			set tExpressionLength = $l(tExpression)
			set tExpressionWords = $l(tExpression," ")
			set tStringWords = $l(string," ")
			if tExpandBefore && 'tExpandAfter {
				if ($e(string,*-tExpressionLength,*)=(" "_tExpression)) {
					set matchScore = 1
					for i = tStringWords-tExpressionWords+1:1:tStringWords { set $bit(matchedWordBits,i) = 1}
				}
			} elseif tExpandBefore && tExpandAfter {
				set tCharInString = $find(string, " "_tExpression_" ")
				if tCharInString {
					set matchScore = 1
					set tFirstMatchedWordPos = $l($e(string,1,tCharInString-tExpressionLength-2)," ")
					for i = tFirstMatchedWordPos:1:tFirstMatchedWordPos+tExpressionWords-1 { set $bit(matchedWordBits,i) = 1 }
				}
			} elseif 'tExpandBefore && tExpandAfter {
				if $e(string,1,tExpressionLength+1)=(tExpression_" ") {
					set matchScore = 1
					for i = 1:1:tExpressionWords { set $bit(matchedWordBits,i) = 1 }
				}
			}
			
			
		} else { 
		
			// word-based
			set tExpandBefore = ($e(tExpression,1)="<")
			set tExpandAfter = ($e(tExpression,*)=">")
			set:tExpandBefore tExpression = $e(tExpression,2,*)
			set:tExpandAfter tExpression = $e(tExpression,1,*-1)
			set tWildBefore = ($e(tExpression,1)="*")
			set tWildAfter = ($e(tExpression,*)="*")
			set:tWildBefore tExpression = $e(tExpression,2,*)
			set:tWildAfter tExpression = $e(tExpression,1,*-1)
			set tExpressionWords = $l(tExpression," ")
			set tStringWords = $l(string," ")
			
			set tPosInString = $find(string, tExpression)
			quit:'tPosInString
			
			// check ending
			set tEndPos = tPosInString, tEndChar = $e(string,tEndPos)
			if (tEndChar="") { // matches end of string
				quit:tExpandAfter // no match if expecting expansion
				set tLastMatchedWord = tStringWords
			} else {
				if (tEndChar'=" ") { // has trailing characters
					quit:'tWildAfter // no match if no wildcard
					quit:tExpandAfter&&'$find(string," ",tEndPos+1) // no match if expecting expansion but none found
				}
				set tLastMatchedWord = $l($e(string,1,tPosInString-1)," ")
			}
			
			// check beginning
			set tStartPos = tPosInString-$l(tExpression)-1
			if ('tStartPos) { // match beginning of string
				quit:tExpandBefore
				set tFirstMatchedWord = 1 
			} else {
				if ($e(string,tStartPos)'=" ") {
					quit:'tWildBefore
					quit:tExpandBefore&&'$find($e(string,1,tStartPos)," ")
				}
				set tFirstMatchedWord = $l($e(string,1,tStartPos)," ")
			}
			
			set matchScore = 1
			for i = tFirstMatchedWord:1:tLastMatchedWord { set $bit(matchedWordBits,i) = 1 }
		} 
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
