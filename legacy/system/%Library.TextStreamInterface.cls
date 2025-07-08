/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occUtility

Class %Library.TextStreamInterface Extends %Compiler.Type.StreamEmbedded [ System = 2 ]
{

/// <p>The <PARAMETER>LANGUAGECLASS</PARAMETER> parameter specifies the fully qualified name of the language
/// implementation class.  Optionally, he <PARAMETER>LANGUAGECLASS</PARAMETER> may be set to the name of a global
/// that indirectly defines the language class name. If a global name is specified, then the global must be 
/// defined and available at index build time and at SQL query execution time.</p>
Parameter LANGUAGECLASS = "%Text.English";

/// Specify the <PARAMETER>SIMILARITYINDEX</PARAMETER> parameter when you intend to use
/// the %SIMILARITY SQL operator to rank query results by relevance.
/// <p>
/// The <PARAMETER>SIMILARITYINDEX</PARAMETER> parameter specifies the name of an index on the current
/// property that has the structure expected by the SimilarityIdx class method of the class specified in 
/// the LANGUAGECLASS parameter.  The SimilarityIdx class method in the %Text.Text class requires the index
/// global to have the structure: ^textIndexGlobal([constantSubscripts,]key,ID) = value.  An index with this
/// structure can be created by compiling an index specification such as:</p>
/// <EXAMPLE LANGUAGE=UDL>
/// PROPERTY myDocument As User.TextStream (LANGUAGECLASS = "%Text.English", SIMILARITYINDEX = "myIndex");
/// INDEX myIndex ON myDocument(KEYS) DATA [ myDocument(VALUES) ];
/// </EXAMPLE>
/// The SimilarityIdx method of the %Text.Text class requires the index specified in the SIMILARITYINDEX parameter
/// to have exactly this structure.  The index may not be a bitmap index, additional subscripts or data values
/// may not be added to the Index specification, and the index must inherit the collation of the property.
/// <p>
Parameter SIMILARITYINDEX;

ClassMethod BuildValueArray(document As %Binary, ByRef valueArray As %Binary) As %Status [ CodeMode = generator, ProcedureBlock = 1, ServerOnly = 1 ]
{
	s %code=0
	QUIT:%mode="method" $$$OK
	if %parameter("LANGUAGECLASS")="" QUIT $$$OK
	$$$GENERATE(" Set oref=$s(document="""":"""_$$$NULLOREF_""",1:##class("_%class_")."_%property_"Open(document))") 
	$$$GENERATE(" Quit:oref="""_$$$NULLOREF_""" "_$$$OK)
	$$$GENERATE(" Set offsetKeyword=""#offset"" // ##class("_%parameter("LANGUAGECLASS")_").GetOffsetKeyword()")
	$$$GENERATE(" For  Set len="_($$$MaxLocalLength * 98 \ 100)_",sc=$classmethod("""_%parameter("LANGUAGECLASS")_""",""BuildValueArray"",oref.ReadPassage(.len,.sc),.valueArray),valueArray(offsetKeyword)=$g(valueArray(offsetKeyword))+len+1 quit:oref.AtEnd")
	$$$GENERATE(" Kill valueArray(offsetKeyword)")
	$$$GENERATE(" Quit sc")
	QUIT $$$OK
}

ClassMethod Similarity(document As %String, qList As %List) As %Numeric [ CodeMode = generator ]
{
	s %code=0
	QUIT:%mode="method" $$$OK
	if %parameter("LANGUAGECLASS")="" QUIT $$$OK
	$$$GENERATE(" Set oref=$s(document="""":"""_$$$NULLOREF_""",1:##class("_%class_")."_%property_"Open(document))") 
	$$$GENERATE(" Quit:oref="""_$$$NULLOREF_""" 0")
	$$$GENERATE(" Set maxSim=0 // ##class("_%parameter("LANGUAGECLASS")_").GetOffsetKeyword()")
	$$$GENERATE(" For  Set len="_($$$MaxLocalLength * 98 \ 100)_",sim=$classmethod("""_%parameter("LANGUAGECLASS")_""",""Similarity"",oref.ReadPassage(.len,.sc),qList) Set:sim>maxSim maxSim=sim quit:oref.AtEnd")
	$$$GENERATE(" Quit maxSim")
	QUIT $$$OK
}

ClassMethod SimilarityIdx(ID As %String, textIndex As %String, qList As %List) As %Numeric [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code = "$classmethod("""_%parameter("LANGUAGECLASS")_""",""SimilarityIdx"",ID,textIndex,qList)"
	QUIT $$$OK
}

ClassMethod ChooseSearchKey(searchString As %String) As %String [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code="$classmethod("""_%parameter("LANGUAGECLASS")_""",""ChooseSearchKey"",searchString)"
	QUIT $$$OK
}

ClassMethod Standardize(document As %String, origtext As %Boolean = 0) As %String [ CodeMode = generator ]
{
	s %code=0
	QUIT:%mode="method" $$$OK
	if %parameter("LANGUAGECLASS")="" QUIT $$$OK
	$$$GENERATE(" Set oref=$s(document="""":"""_$$$NULLOREF_""",1:##class("_%class_")."_%property_"Open(document))") 
	$$$GENERATE(" Quit:oref="""_$$$NULLOREF_""" """"")
	$$$GENERATE(" Set std="""" // ##class("_%parameter("LANGUAGECLASS")_").GetOffsetKeyword()")
	$$$GENERATE(" For  Set len="_($$$MaxLocalLength * 98 \ 100)_",std=std_$classmethod("""_%parameter("LANGUAGECLASS")_""",""Standardize"",oref.ReadPassage(.len,.sc)) quit:oref.AtEnd")
	$$$GENERATE(" Quit std")
	QUIT $$$OK
}

ClassMethod CreateQList(searchPattern As %String, collationExpr As %String) As %List [ CodeMode = generator ]
{
	s %code=0
	QUIT:%mode="method" $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %code="$classmethod("""_%parameter("LANGUAGECLASS")_""",""CreateQList"",searchPattern,collationExpr)"
	QUIT $$$OK
}

ClassMethod MakeSearchTerms(searchPattern As %String, ngramlen As %Integer = 0) As %List [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code="$classmethod("""_%parameter("LANGUAGECLASS")_""",""MakeSearchTerms"",searchPattern,ngramlen)"
	QUIT $$$OK
}

}
