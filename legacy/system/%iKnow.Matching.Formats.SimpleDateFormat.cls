/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a very simple example of a <class>%iKnow.Matching.Formats.Format</class> implementation, simply checking whether the supplied
/// strings can be converted to a proper date and optionally returning it as output. </p>
/// 
/// <p><b>Format parameters:</b></p>
/// <ol>
/// 	<li><b>dateFormat</b> (<class>%Integer</class>, default -1): the dformat parameter passed to $zdateh or $zdatetimeh</li>
/// 	<li><b>timeFormat</b> (<class>%Integer</class>, default 0): the tformat parameter passed to $zdatetimeh, 0 means no time is checked</li>
/// 	<li><b>output</b> (<class>%Boolean</class>, default 0): whether or not to output the identified date</li>
/// </ol>
Class %iKnow.Matching.Formats.SimpleDateFormat Extends %iKnow.Matching.Formats.Format [ Deprecated, System = 4 ]
{

Method MatchSingle(string As %String, formatParams As %List, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status
{
	set matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
	
	set string = $zstrip(string, "<>=W")
	set wordCount = $length(string," ")
	
	set dateFormat = +$lg(formatParams,1,-1)
	set timeFormat = +$lg(formatParams,2,0)
	set output = +$lg(formatParams,3,0)
	
	set date = $s(timeFormat:$zdatetimeh(string, dateFormat, timeFormat,,,,,,,-1),
						1:$zdateh(string, dateFormat,,,,,,,-1))
	
	if (date>0) {
		set matchScore = 1
		for i=1:1:wordCount { set $bit(matchedWordBits,i) = 1 }
		set:output formatOutput = date
	} else {
	
		// if the full string is not a date, try substrings hoping we can find a partial match
		set words = $lfs(string," ")
		for i=1:1:wordCount {
			for j=i:1:wordCount {
				set substring = $lts($li(words,i,j)," ")
				set date = $s(timeFormat:$zdatetimeh(substring, dateFormat, timeFormat,,,,,,,-1),
									1:$zdateh(substring, dateFormat,,,,,,,-1))
				if (date>0) {
					for k=1:1:wordCount { set $bit(matchedWordBits,k) = ((k>=i)&&(k<=j)) }
					set matchScore = $bitcount(matchedWordBits,1) / wordCount
					set:output formatOutput = date
					quit
				}
			}
			quit:matchScore>0
		}
		
	}
	
	quit $$$OK
}

}
