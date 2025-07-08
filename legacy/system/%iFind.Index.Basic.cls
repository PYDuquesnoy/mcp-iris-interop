/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IFInclude, %IKInclude)

IncludeGenerator (%IFInclude, %IKInclude)

/// <p>This index class provides text search capabilities to perform word-level searches through text in the
/// %String or %Stream properties being indexed, for persistent classes using default storage.</p>
/// 
/// <h2>Defining an iFind index</h2>
/// <p>An iFind index can be defined in the class as follows:</p>
/// <example language="UDL">Class ThePackage.MyClass Extends %Persistent
/// {
/// 	Property MyStringProperty As %String;
/// 	
/// 	Index MyBasicIndex On (MyStringProperty) As %iFind.Index.Basic;
/// }</example>
/// <p>A number of <a href="#Anchor_Parameters">parameters</a> can be configured in order to refine
/// the indexing behavior, such as whether to support case-sensitive search (<parameter>LOWER</parameter>),
/// which language to use when indexing the text (<parameter>LANGUAGE</parameter>)
/// or whether to enable stemming or decompounding (<parameter>INDEXOPTION</parameter>).</p>
/// 
/// <h2>Querying an iFind index</h2>
/// <p>Classes with an iFind index can subsequently be queried in SQL using the following syntax:</p>
/// <example language="SQL">SELECT * FROM ThePackage.MyClass WHERE %ID %FIND search_index(MyBasicIndex, 'interesting')</example>
/// <p>This will return all the records containing the word "interesting". The following table lists a
/// few sample search strings illustrating more advanced iFind search syntax.</p>
/// <table class="DetailTable" cellpadding="0" cellspacing="0">
/// <tr><th width="250">Search string</th><th>What will be retrieved</th></tr>
/// <tr><td width="250">structure</td><td>All records containing the word "structure"</td></tr>
/// <tr><td width="250">logical structure</td><td>All records containing both the words "logical" and "structure" (implicit AND)</td></tr>
/// <tr><td width="250">logical structure*</td><td>Same, but with anything that starts with "structure" (wildcard search)</td></tr>
/// <tr><td width="250">"logical structure"</td><td>All records containing the word "structure" right behind "logical" (positional search)</td></tr>
/// <tr><td width="250">"logical ? structure"</td><td>All records containing the words "logical" and "structure" with exactly one word in between (positional search)</td></tr>
/// <tr><td width="250">"logical [0-5] structure"</td><td>Positional again, but with up to 5 words between</td></tr>
/// <tr><td width="250">[logical, structure, 5]"</td><td>All records containing the words "logical" and "structure", but with up to 5 words between</td></tr>
/// <tr><td width="250">[logical structure, diagram, 3-6]"</td><td>All records containing the phrase "logical structure" and the word "diagram" again, with between 3 and 6 words between</td></tr>
/// </table>
/// <p>It's also possible to use AND, OR and NOT, as well as parentheses to combine words into more
/// complex search strings, other than the implicit AND which is the default behavior for multi-word search:</p>
/// <table class="DetailTable" cellpadding="0" cellspacing="0">
/// <tr><th width="250">Search string</th><th>What will be retrieved</th></tr>
/// <tr><td width="250">Fixed</td><td>All records containing the word "fixed"</td></tr>
/// <tr><td width="250">Fixed and stored</td><td>All records containing "fixed" and "stored"</td></tr>
/// <tr><td width="250">Fixed and not stored</td><td>All records containing "fixed" but not "stored"</td></tr>
/// <tr><td width="250">Fixed and not "stored procedure"</td><td>All records containing "fixed" but not the positional string "stored procedure"</td></tr>
/// <tr><td width="250">fixed and ("stored procedure" or "default parameters")</td><td>All records containing "fixed" and either "stored procedure" or "default parameters"</td></tr>
/// <tr><td width="250">Fixed and \not</td><td>All records containing the words "fixed" and "not"</td></tr>
/// <tr><td width="250">Fixed \and \not</td><td>All records containing "fixed", "and" and "not"</td></tr>
/// <tr><td width="250">not generated</td><td>All records not containing "generated"</td></tr>
/// <tr><td width="250">\not generated</td><td>Implicit AND of "not" and "generated"</td></tr>
/// </table>
/// <p>Besides the name of the iFind index and the search string, the search_index() function supports
///  two more optional parameters: <blockquote><pre>search_index(<i>index_name</i>, <i>search_string</i> [, <i>search_option</i> [, <i>search_language</i>]]</pre></blockquote></p>
///  <p>The <i>search_option</i> defines whether to search for exact occurrences of words in the search string
///  (<i>search_option</i>=0), which is the default, to look for words that correspond to the same
/// "normalized" form, based on a particular transformation. For example, stemming will normalize
/// conjugated words to their base form and allow you to search for any conjugated form that corresponds
/// to the same base form. Similarly, decompounding will normalize words even further by splitting up 
/// compound words in the atomic words it consists of (see also <class>%iKnow.Stemming.DecompoundUtils</class>).
/// The following values can be used for <i>search_option</i>:
/// <ul>
/// <li><i>search_option</i> = 0 will perform a regular search, without any transformations. This is the default.</li>
/// <li><i>search_option</i> = 1 is a shorthand for stemmed search, using the default stemmer for the
/// current language (see also <class>%iKnow.Stemmer</class>), optionally overridden by the <parameter>STEMMINGCONFIG</parameter></li>
/// <li><i>search_option</i> = 2 is a shorthand for decompounded search, relying on the same settings as stemming described in the previous bullet</li>
/// <li><i>search_option</i> = 3 is a shorthand for fuzzy search, which will match any word that has at most 2 characters
/// differing from the search term. (Note that this is not a transformation, strictly speaking).</li>
/// <li><i>search_option</i> = '3:<i>n</i>' will also perform fuzzy search, but the maximum edit distance (different characters) is now <i>n</i></li>
/// <li><i>search_option</i> = 4 will perform a regular expression search</li>
/// <li><i>search_option</i> = '*' is a shorthand for searching based on all the transformations defined for this index</li>
/// <li><i>search_option</i> = '<i>string</i>' will perform the tranformation identified by <i>string</i> (see also <parameter>TRANSFORMATIONSPEC</parameter>)</li>
/// </ul>
/// Which values are available for a given index depends on the values of the <parameter>INDEXOPTION</parameter>
/// or <parameter>TRANSFORMATIONSPEC</parameter> parameters.</p>
///  <p>The <i>search_language</i> argument enables filtering records to those in a particular language,
///  in cases where the indexed property contains text in multiple languages (<parameter>LANGUAGE</parameter> = "*").
///  This language is also passed on to an eventual word transformation method when <i>search_option</i> != 0.</p>
/// 
/// <p>If the <parameter>IFINDMAPPINGS</parameter> index is set to 1, the following additional SQL projections
/// will be generated:</p>
/// <ul>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_WordSpread</b>: stores the total number of records
/// in which this word appears in this index. See also <class>%iFind.Index.AbstractWordSpread</class>.</li>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_WordPos</b> stores which word occurs at which position
/// in a record, so it can be joined to the AttributePos table. See also <class>%iFind.Index.AbstractWordPos</class>.</li>
/// </ul>
/// 
Class %iFind.Index.Basic Extends %iFind.Index.Minimal [ EmbeddedClass = %iFind.Find.Basic, System = 2 ]
{

Parameter FILER [ Internal ] = "%iFind.Filer.Basic";

Parameter IGNOREPUNCTUATION As BOOLEAN = 0;

/// <p>This parameter controls which characters are retained at the start and end of a word when calculating
/// the "stripped" version of a word that will be indexed along with the original word as it appeared in the text.</p>
/// <p>This parameter only applies if <parameter>IGNOREPUNCTUATION</parameter> is set to false (the default for Basic,
/// Semantic and Analytic indices).</p>
Parameter KEEPCHARS As STRING = {$$$STRIPKEEP};

/// <p>The <class>%iFind.Rank.Abstract</class> implementation to use for ranking search results
/// using the auto-generated rank SQL procedure "[package name].[class name]_[index name]Rank"</p>
Parameter RANKERCLASS As STRING = {$$$IFDEFAULTRANKER};

/// Utility method stripping punctuation characters from the start and end of a word, according to 
/// the value of the <parameter>KEEPCHARS</parameter> index parameter for this index.
ClassMethod StripCharacters(pWord As %String) As %String [ CodeMode = generator ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		$$$GENERATE($char(9)_"do .."_%property_"GetIndexParams(.tParams)")
		$$$GENERATE($char(9)_"quit $zstrip(pWord,""<>P"",,tParams(""KEEPCHARS""))")
	}
	quit $$$OK
}

/// Returns the Word ID for <var>pWord</var>, after stripping off any punctuation at the start and end of
/// the word, according to the value of <parameter>KEEPCHARS</parameter> for this index.
ClassMethod StrippedWordId(pWord As %String) As %String [ CodeMode = generator ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		
		$$$GetIndexLocations(%class,%property,tIndexLocation,tDataLocation,"")
		$$$GENERATE($char(9)_"do .."_%property_"GetIndexParams(.tParams)")
   		$$$GENERATE($char(9)_"set tWord = $zstrip(pWord,""<>P"",,tParams(""KEEPCHARS""))")
   		$$$GENERATE($char(9)_"quit $s(tWord="""":"""", 1:$g("_$$$DataLocation("WordI",tDataLocation)_""" ""_tWord)))")
	}
	quit $$$OK
}

/// Returns the Entity ID for <var>pEntity</var>, after stripping off any punctuation at the start and end of
/// the words making up the entity, according to the value of <parameter>KEEPCHARS</parameter> for this index.
ClassMethod StrippedEntityId(pEntity As %String) As %String [ CodeMode = generator ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		
		$$$GetIndexLocations(%class,%property,tIndexLocation,tDataLocation,"")
		$$$GENERATE($char(9)_"do .."_%property_"GetIndexParams(.tParams)")
		$$$GENERATE($char(9)_"set tNumWords = $length(pEntity,"" ""), tHasStripped=0")
		$$$GENERATE($char(9)_"kill tStrippedWords")
		$$$GENERATE($char(9)_"for i = 1:1:tNumWords {")
		$$$GENERATE($char(9)_"	set tWord = $piece(pEntity,"" "",i)")
		$$$GENERATE($char(9)_"	set tStrippedWords(i)=$zstrip(tWord,""<>P"",,tParams(""KEEPCHARS""))")
		$$$GENERATE($char(9)_"	set:'tHasStripped tHasStripped=(tStrippedWords(i)'=tWord)")
		$$$GENERATE($char(9)_"}")
		$$$GENERATE($char(9)_"set tEntityKey=""""")
		$$$GENERATE($char(9)_"for i = 1:1:tNumWords {")
		$$$GENERATE($char(9)_"	set tWord = tStrippedWords(i)")
		$$$GENERATE($char(9)_"	continue:tWord=""""")
		$$$GENERATE($char(9)_"	if '$d("_$$$DataLocation("WordI",tDataLocation)_""" ""_tWord),tWordId) {")
		$$$GENERATE($char(9)_"		return pOriginalId")
		$$$GENERATE($char(9)_"	}")
		$$$GENERATE($char(9)_"	set:tEntityKey'="""" tEntityKey=tEntityKey_"",""")
		$$$GENERATE($char(9)_"	set tEntityKey=tEntityKey_tWordId")
		$$$GENERATE($char(9)_"}")
		$$$GENERATE($char(9)_"quit $s(tEntityKey="""":"""", 1:$g("_$$$DataLocation("EntityI",tDataLocation)_"tEntityKey)))")
	}
	quit $$$OK
}

/// <p>This SQL procedure returns the score expressing how well the record identified by <var>pRecordID</var>
/// matches <var>pSearchString</var>, based on the ranking algorithm defined by <parameter>RANKERCLASS</parameter>.</p>
/// <example language="SQL">SELECT %ID, 
/// 	Title,
/// 	FullText,
/// 	SomePackage.TheTable_MyIndexRank(%ID, 'cocktail* OR (hammock AND NOT bees)')
/// FROM SomePackage.TheTable
/// WHERE %ID %FIND search_index(MyIndex, 'cocktail* OR (hammock AND NOT bees)')
/// ORDER BY 4 DESC</example>
/// <p><var>pSearchOption</var> can be used as in other iFind search operations,
/// for example to also accept fuzzy matches or stem matches when calculating the rank score.</p>
ClassMethod Rank(pRecordID As %RawString, pSearchString As %String, pSearchOption As %String = {$$$IFSEARCHNORMAL}) As %Float [ CodeMode = generator, PublicList = (SQLCODE, %msg), ServerOnly = 1, SqlProc ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		
		$$$GENERATE($char(9)_"quit ##class(%iFind.Utils).Rank("_$$$QUOTE(%parameter("RANKERCLASS"))_","_$$$QUOTE(%class)_","_$$$QUOTE(%pqname)_",pRecordID,pSearchString,pSearchOption)")
	}
	quit $$$OK
}

/// <p>This SQL procedure returns the text indexed by <var>pRecordID</var>, in which all matches of the
/// supplied <var>pSearchString</var> are highlighted using <var>pTags</var>.</p>
/// <example language="SQL">SELECT %ID, 
/// 	Title,
/// 	SomePackage.TheTable_MyIndexHighlight(%ID, 'cocktail* OR (hammock AND NOT bees)')
/// FROM SomePackage.TheTable
/// WHERE %ID %FIND search_index(MyIndex, 'cocktail* OR (hammock AND NOT bees)')
/// ORDER BY 4 DESC</example>
/// <p><var>pTags</var> is a comma-separated list of tags to use for highlighting. If only a single one
/// is supplied, it will be used to highlight all matches of search terms. If a second one is supplied,
/// it will be used for all terms in a NOT node of the search tree (such as 'bees' in the above example),
/// while the first will be used for all other terms.</p> 
/// <p><var>pLimit</var> can be used to limit the text to a maximum number of hits rather than returning
/// the entire, highlighted text. <var>pSearchOption</var> can be used as in other iFind search operations,
/// for example to also mark fuzzy matches or stem matches.</p>
ClassMethod Highlight(pRecordID As %RawString, pSearchString As %String, pSearchOption As %String = {$$$IFSEARCHNORMAL}, pTags As %String = {$$$IFDEFAULTHLTAGS}, pLimit As %Integer = 0, Output pSC As %Status) As %String [ CodeMode = generator, ForceGenerate, GenerateAfter = InsertIndex, PublicList = (SQLCODE, %msg), ServerOnly = 1, SqlProc ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		
		
		$$$GENERATE($char(9)_"set pSC=$$$OK, tFullText = .."_%property_"GetStringValue(pRecordID)")
		$$$GetIndexLocations(%class,%property,tIndexLocation,tDataLocation,"")
		$$$comMemberKeyGetLvar(tFinderClass,%class,$$$cCLASSindex,%property,$$$cXXXXembeddedname)
		$$$GENERATE($char(9)_"do .."_%property_"GetIndexParams(.tParams)")
		
		// BDB668 - translate to integer key used in index globals
		if $d(%parameter("INTKEYPROPERTY"),tIntKeyProp) && (tIntKeyProp'="") {
			$$$GENERATE("	set pRecordID = ##class("_%class_").%OpenId(pRecordID)."_tIntKeyProp)
		}
		
		$$$GENERATE($char(9)_"quit ##class(%iFind.Utils).HighlightInternal("_$$$QUOTE(tIndexLocation)_","_$$$QUOTE(tDataLocation)_","_$$$QUOTE(tFinderClass)_", pRecordID, tFullText, pSearchString, pSearchOption, pTags, pLimit, .tParams, .pSC)")
	}
	quit $$$OK
}

}
