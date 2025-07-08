/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>To leverage the iFind synonym expansion functionality,
/// users have to create the class which extends <class> %iFind.Synonym </class>. </p>
/// <p>Users could define the synonym pair by inserting (FromTerm,ToTerm) pair into the synonym table.
/// Both FromTerm and ToTerm could be just single word or multuple words. If ToTerm consists of multiple word, it is implicitly treated as a iFind positional search phrase after expansion.
/// For Japanese, user should ensure the ToTerm is always an single valid term, since iFind do not support positional search for Japanese</p>
/// <p>For synonym pair like (New York,NY), "NY" is automatically expanded into your query phrase. 
/// For (ISC, Inter*System* Corp),the iFind positional search phrase (Inter*System* Corp) get expanded into the original query.</p>
/// <p>So if the text contains a phrase like "InterSystems Corp", it is a match.
/// One thing should be noted is that the minimum mathcing unit in the query is the single word or an valid positional search phrase.
/// This means iFind won't try to perform query expanion for the single word of the positioal phrase.
/// You have to explicitly specify the whole positional search phrase in the synonym table, (New York, NY) is an example here.</p>
/// <p>Users could use the default logic implemented in GetMatch() to decide where the term of the indexed text matches to FromTerm or not.
/// Users could also overwrite the default implementation in <method>GetMatch</method> to provide your own matching logic.</p>
/// <p>To supply the synonym tables during query, users should provide a comma seperated list which contain the full qualified name of those synonym tables to the fifth parameter of search_index().<br><br>
/// Suppose users define two synonym tables called "iFind.Sym1" and "iFind.Sym2",<br>
/// The query leveraing the single synonym table expansion could be like:<br>
/// select * from Sample.Tab where %ID %FIND search_index(iFind_Index,'query terms',,,'iFind.Sym1')<br><br>
/// The query leveraing multiple synonym tables expansion could be like:<br>
/// select * from Sample.Tab where %ID %FIND search_index(iFind_Index,'query terms',,,'iFind.Sym1,iFind.Sym2')
Class %iFind.Synonym Extends %Persistent [ NoExtent ]
{

Property FromTerm As %String [ Required ];

Property ToTerm As %String [ Required ];

Index FTIndex On (FromTerm) As %iFind.Index.Basic(LANGUAGE = "*", LOWER = 1);

/// <p>This function returns all the ToTerm in the synonym table in which the FromTerm is exactly identical with Source
/// The results are placed in Matches with the format Matches("ToTerm") = ""</p> 
/// <p>The IndexParam should contain all the parameters defined for the specific iFind index in which you would like to perform synonym expansion.
/// For example, if you define "LOWER" for this specific iFind index, the <method>GetMatch</method> would also follow the "LOWER" setting to decide
/// whether this match has be case sensitive or case insensitive.</p>
/// <p>Note: any wildcard in the Source would be treated as normal character.
/// For example, if the FromTerm is "InterSystems" and the Source is "InterSystem*", the Source would not match this FromTerm.
/// Also, <method>GetMatch</method> performs language independent exact match, this implies each FromTerm could belong to different languages.</p>
ClassMethod GetMatch(Source As %String, ByRef Matches, ByRef IndexParam) As %Status
{
	set Lower = $g(IndexParam("LOWER"),0)
	set search = "'"_$zconvert(Source,"L")_"'"
	set stat = ##class(%SQL.Statement).%New()
	set option = "0" ; 
	set query = "select FromTerm,ToTerm from "_$classname()_" where %ID %FIND search_index(FTIndex,"_search_","_option_")" 
	set res = stat.%Prepare(query)
	if res'=$$$OK quit res
	set rset = stat.%Execute()
	if rset.%SQLCODE'=0 {
		#Dim sc As %Status = $$$ERROR($$$SQLError, rset.%SQLCODE, $g(%msg))
		quit sc
	}
	
  	// Now check all the records which contain 'Source' and verify it only contains 'Source'
  	set:Lower'=0 Source = $zconvert(Source,"L") 
  	while rset.%Next() {
	  	if Lower = 1{
			set left = $zconvert(rset.FromTerm,"L")
			set right = $zconvert(Source,"L")		
		}
		else{
			set left = rset.FromTerm
			set right = Source
		}
		set:(left=right) Matches(rset.ToTerm) = ""
    }
	quit $$$OK
}

}
