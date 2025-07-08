/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class implements Regular Expression matching as an implementation for <class>%iKnow.Matching.Formats.Format</class>,
/// leveraging the ICU implementation in <class>%Regex.Matcher</class>. This implementation does
/// not support matched word indicators, scattered match detection or anything but boolean match
/// scores. Also, it will only verify <i>within</i> entities and therefore never find matches that
/// cross an entity boundary.</p> 
/// <p><b>Format parameters:</b></p>
/// <ol>
/// 	<li><b>regular expression</b> (<class>%String</class>, mandatory): the regular expression to pass to the <class>%Regex.Matcher</class> object.</li>
/// 	<li><b>replacement string</b> (<class>%String</class>, default ""): if supplied, <var>formatOutput</var> will be populated by running this replacement string against the text and expression pair</li>
/// 	<li><b>replace all</b> (<class>%Boolean</class>, default 1): if set to 0, <var>formatOutput</var> will contain the result of ReplaceFirst() rather than ReplaceAll() when using replace functionality</li>
/// </ol>
Class %iKnow.Matching.Formats.RegularExpression Extends Format [ Deprecated, System = 4 ]
{

Property Matcher As %Regex.Matcher;

Method MatchSingle(string As %String, formatParams As %List, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status
{
	set tSC = $$$OK, matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
	try {
		
		if $lv(formatParams) {
			set tExpression = $li(formatParams,1)
			set tReplacement = $lg(formatParams,2)
			set tReplaceAll = +$lg(formatParams,3,1)
		} else {
			set tExpression = formatParams
			set tReplacement = ""
			set tReplaceAll = 0
		}
		
		if '$isobject(..Matcher) {
			set ..Matcher = ##class(%Regex.Matcher).%New(tExpression)
			if '$isobject(..Matcher) {
				set tSC = %objlasterror
				quit
			}
		} elseif (..Matcher.Pattern'=tExpression) {
			set ..Matcher.Pattern = tExpression
		}
		
		set matchScore = ..Matcher.Match(string)
		if (tReplacement'="") {
			if (tReplaceAll) {
				set formatOutput = ..Matcher.ReplaceAll(tReplacement)
			} else {
				set formatOutput = ..Matcher.ReplaceFirst(tReplacement)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
