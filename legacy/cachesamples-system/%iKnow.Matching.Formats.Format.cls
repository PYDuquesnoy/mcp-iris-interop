/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This abstract class describes the interface to be implemented by an actual Dictionary Format
/// matching object. Subclasses of this class can for example introduce regular expression matching,
/// date matching, number checking or something more domain-specific.</p>
/// <p>Subclasses should at least override <method>MatchSingle</method> and optionally provide a
/// format-specific implementation for <method>MatchAll</method>.</p>
/// <p>Format implementations can be parameterized through a number of parameters the Format class
/// defines, which will get passed to the <method>MatchSingle</method> and <method>MatchAll</method>
/// methods as a <i>formatParams</i> parameter of type <class>%List</class>.</p>
Class %iKnow.Matching.Formats.Format Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

Property DomainId As %Integer [ ReadOnly ];

/// <p>Implementations of this method check whether an individual <i>string</i> complies with the format
/// this class represents, returning a <i>matchScore</i> (0..1) and optional <i>matchedWordBits</i>,
/// <i>isScattered</i> and <i>formatOutput</i> through output parameters.</p>
Method MatchSingle(string As %String, formatParams As %List, Output matchScore As %Numeric, Output matchedWordBits, Output isScattered As %Boolean, Output formatOutput) As %Status [ Abstract ]
{
	quit $$$OK
}

/// <p>Whether or not this Format class has a <method>MatchAll</method> function that deals with a set of
/// strings directly. Subclasses should make sure to override this method (to make it return true) 
/// if they override <method>MatchAll</method>.</p>
Method HasMatchAll() As %Boolean
{
	quit 0
}

/// <p>This method loops through @stringsGlobalName@(" "_string) = id and matches all global entries,
/// storing the results in @resultGlobalName@(id) = $lb(matchScore, matchedWordBits, isScattered, formatOutput).
/// The implementation should ignore all ids &lt; minEntUniId and should not store any results if
/// the matchScore is 0.</p>
/// <p>Implementing this method only makes sense if the specific format this class represents can
/// exploit the inverse global structure of @stringsGlobalName.</p>
/// 
/// <p><b>Note:</b> entries in @stringsGlobalName are all in lowercase and prefixed with a space</p>
/// 
/// <p><b>Warning:</b> an implementation for this method does not replace <method>MatchSingle</method>.
/// There should still be a MatchSingle alternative, for example to process strings longer than
/// $$$IKHASHSIZE that would not appear in @stringsGlobalName.</p>
/// 
/// <!-- Warning: the strings received through @stringsGlobalName should still be converted using 
/// ..ConvertFormatCase() when using a $$$IKMATCHINGCASE setting different from 
/// $$$IKMATCHINGCASELOWER (system default)! -->
Method MatchAll(stringsGlobalName As %String, resultGlobalName As %String, formatParams As %List, minEntUniId As %Integer = 0) As %Status
{
	quit $$$ERROR($$$NotImplemented)
}

/// <p>As <method>MatchAll</method> can only tackle those strings shorter than $$$IKHASHSIZE, this
/// method complements it by looping through the corresponding global structures for longer strings
/// and checking them manually using <method>MatchSingle</method>.</p>
Method MatchAllHashes(hashGlobalName As %String, idGlobalName As %String, resultGlobalName As %String, formatParams As %List, minEntUniId As %Integer = 0) As %Status [ Final ]
{
	set tSC = $$$OK
	
	set hash = ""
	for {
		set hash = $order(@hashGlobalName@(hash))
		quit:hash=""
		
		set id = minEntUniId-1
		for {
			set id = $order(@hashGlobalName@(hash,id))
			quit:id=""
			
			set value = ..ConvertFormatCase(@idGlobalName@(id))
			
			set matchScore=0, matchedWordBits="", isScattered=0, formatOutput=""
			set tSC = ..MatchSingle(value, formatParams, .matchScore, .matchedWordBits, .isScattered, .formatOutput)
			goto:$$$ISERR(tSC) end
			
			continue:'matchScore
			
			set @resultGlobalName@(id) = $lb(matchScore, matchedWordBits, isScattered, formatOutput)
		}
	}

end	
	quit tSC
}

/// <p>This method is called after matching has finished to clean up eventual memory structures
/// generated while executing <method>MatchSingle</method> or <method>MatchAll</method> calls
/// and can be overridden in subclasses to perform any required cleanup operations.</p>
Method Finalize() As %Status
{
	quit $$$OK
}

/// <p>Utility method to ensure a string used in the format matching process is in the same case set
/// as the strings supplied to the <method>MatchSingle</method> method.</p>
/// <!--Warning: the strings received through MatchAll() should still be converted using this method if
/// using a $$$IKMATCHINGCASE setting different from $$$IKMATCHINGCASELOWER (system default)!-->
Method ConvertFormatCase(formatString As %String) As %String [ Internal ]
{
	//$$$IKCONVERTMATCHINGCASE2(i%CaseType,formatString)
	set formatString = $$$IKNORMALIZED(formatString,i%DomainId)
	quit formatString
}

Method %OnNew(domainId As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTS(domainId)
	}
	set i%DomainId = domainId
	//set i%CaseType = $$$IKMATCHINGCASE(domainId)
	Quit $$$OK
}

/// Utility method subclasses can implement to verify user-supplied format parameters are
/// valid. The default implementation instantiates an object of this matching format class and
/// calls its <method>MatchSingle</method> method for "test string". The <class>%Status</class>
/// object returned by that call is returned for this method.
ClassMethod TestParams(pFormatParams As %List, pDomainId As %Integer = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		set tFormat = ..%New(pDomainId)
		set tSC = tFormat.MatchSingle("test string", pFormatParams)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
