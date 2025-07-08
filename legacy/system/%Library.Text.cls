/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// <p>
/// The %Text data type class represents a content-addressable document that supports word-based searching
/// and relevance ranking.  When you specify %Text as the type class of a property, you must also specify 
/// the maximum length of the document in the <parameter>MAXLEN</parameter> parameter, and the language of 
/// the document in the <parameter>LANGUAGECLASS</parameter> parameter.  You 
/// may also specify the name of the index that will be used to compute the relevance ranking metric.</p>
/// <p>
/// For detailed usage information, see the class documentation for the <CLASS>%Text.Text</CLASS> class.</p>
/// <p>
/// Efficient content-based document retrieval requires the use of an index.  The type of index you create depends on
/// the type query that the application requires.  The simplest type of content-based query is the <i>Boolean query</i>.
/// A Boolean query is comprised of a set of search <i>terms</i>, or words, that are combined with AND/OR/NOT operations
/// to identify the documents of interest.  SQL provides the %CONTAINS operator to search for an ANDed list
/// of search terms.  %CONTAINS operations may be combined with OR and NOT to specify any Boolean text query.  The terms
/// need not be adjacent in the document, although queries can be restricted to adjacent terms such as "White House" by
/// setting <property>NGRAMLEN</property>=2 in the class specified in the <property>LANGUAGECLASS</property> property.
/// <p>
/// To create an English Text property named <i>myDocument</i> with a full text index suitable for Boolean queries you could specify:</p>
/// <EXAMPLE LANGUAGE=UDL>
/// PROPERTY myDocument As %Text (MAXLEN = 256, LANGUAGECLASS = "%Text.English");
/// INDEX myIndex ON myDocument(KEYS) [ TYPE=BITMAP ];
/// </EXAMPLE>
/// <p>
/// An issue with Boolean queries is that it can be difficult to specify a query that returns all of the relevant
/// documents, but only those documents.  Almost invariably the results will either omit some of the relevant documents
/// because the query is too specific, or will include some non-relevant documents because the query is too general.
/// For example, to locate information about full text indexing in a set of documentation, the terms
/// <EXAMPLE>
/// text document search query SQL SELECT index similarity ranking Boolean %CONTAINS 'full text'
/// </EXAMPLE>
/// all seem to be reasonably descriptive terms for the topic, but simply ANDing all these terms together in a single
/// %CONTAINS operator is likely to find no documents (other than this document).  In SQL you can address
/// this sort of problem by casting a wider net with the %CONTAINS operator, then ranking the results with the 
/// %SIMILARITY operator, and finally limiting the results to the TOP n rows.  For example, a query that finds a relevant
/// set of documents might be:
/// <EXAMPLE LANGUAGE=SQL>
/// SELECT TOP 20 document FROM OnlineDocs 
/// 	WHERE document %CONTAINS ('SQL', 'full text', 'query')
/// 	ORDER BY %SIMILARITY (document, 'text document search query SQL SELECT index similarity ranking Boolean %CONTAINS') DESC
/// </EXAMPLE>
/// This query finds all documents containing the terms 'SQL', 'full text', and 'query' anywhere within the document,
/// then ranks the documents based on similarity with the terms listed in the %SIMILARITY operator, and returns the
/// top 20 results that are deemed to be the most relevant.
/// <p>
/// Similarity queries are much more computationally expensive than Boolean queries.  Performing similarity queries
/// efficiently requires an index that contains additional information with each indexed term, and so bitmap indexes 
/// cannot be used.  The structure of an index that can be used for similarity 
/// queries is determined by the <method>SimilarityIdx</method> class method of the specified <parameter>LANGUAGECLASS</parameter>.
/// If you use one of the predefined language classes in the %Text package, then you would declare your 
/// property and index as follows:</p>
/// <EXAMPLE LANGUAGE=UDL>
/// PROPERTY myDocument As %Text (MAXLEN = 256, LANGUAGECLASS = "%Text.English", SIMILARITYINDEX = "mySimilarityIndex");
/// INDEX mySimilarityIndex ON myDocument(KEYS) [ DATA = myDocument(ELEMENTS) ];
/// </EXAMPLE>
Class %Library.Text Extends %Library.String [ System = 4 ]
{

/// <p>The <PARAMETER>LANGUAGECLASS</PARAMETER> parameter specifies the fully qualified name of the language
/// implementation class.  Optionally, he <PARAMETER>LANGUAGECLASS</PARAMETER> may be set to the name of a global
/// that indirectly defines the language class name. If a global name is specified, then the global must be 
/// defined and available at index build time and at SQL query execution time.</p>
Parameter LANGUAGECLASS = "%Text.English";

/// The <PARAMETER>SIMILARITYINDEX</PARAMETER> parameter specifies the name of an index on the current
/// property that has the structure expected by the SimilarityIdx class method of the class specified in 
/// the LANGUAGECLASS parameter.  The SimilarityIdx class method in the %Text.Text class requires the index
/// global to have the structure: ^textIndexGlobal([constantSubscripts,]key,ID) = value.  An index with this
/// structure can be created by compiling an index specification such as:</p>
/// <EXAMPLE LANGUAGE=UDL>
/// PROPERTY myDocument As %Text (MAXLEN = 256, LANGUAGECLASS = "%Text.English", SIMILARITYINDEX = "myIndex");
/// INDEX myIndex ON myDocument(KEYS) DATA [ myDocument(VALUES) ];
/// </EXAMPLE>
/// The SimilarityIdx method of the %Text.Text class requires the index specified in the SIMILARITYINDEX parameter
/// to have exactly this structure.  The index may not be a bitmap index, additional subscripts or data values
/// may not be added to the Index specification, and the index must inherit the collation of the property.
/// <p>
Parameter SIMILARITYINDEX;

/// <p>The <PARAMETER>MAXLEN</PARAMETER> parameter specifies the maximum length of the %Text property in bytes.
/// Note that, unlike the %String class, the MAXLEN parameter must be explicitly set to a positive integer on each 
/// %Text property.
Parameter MAXLEN;

ClassMethod BuildValueArray(serialProp As %Binary, ByRef valueArray As %Binary) As %Status [ CodeMode = generator ]
{
	if %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""BuildValueArray"",serialProp,.valueArray)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").BuildValueArray(serialProp,.valueArray)" }
	QUIT $$$OK
}

ClassMethod Similarity(document As %String, qList As %List) As %Numeric [ CodeMode = generator ]
{
	if %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""Similarity"",document,qList)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").Similarity(document,qList)" }
	QUIT $$$OK
}

ClassMethod SimilarityIdx(ID As %String, textIndex As %String, qList As %List) As %Numeric [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""SimilarityIdx"",ID,textIndex,qList)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").SimilarityIdx(ID,textIndex,qList)" }

	QUIT $$$OK
}

ClassMethod ChooseSearchKey(searchString As %String) As %String [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""ChooseSearchKey"",searchString)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").ChooseSearchKey(searchString)" }
	QUIT $$$OK
}

ClassMethod Standardize(searchString As %String, origtext As %Boolean = 0) As %String [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""Standardize"",searchString,origtext)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").Standardize(searchString,origtext)" }

	QUIT $$$OK
}

ClassMethod CreateQList(document As %String, collationExpr As %String) As %List [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""CreateQList"",document,collationExpr)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").CreateQList(document,collationExpr)" }

	QUIT $$$OK
}

ClassMethod MakeSearchTerms(searchPattern As %String, ngramlen As %Integer = 0) As %List [ CodeMode = generator ]
{
	i %parameter("LANGUAGECLASS")="" QUIT $$$OK
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	if $e(%parameter("LANGUAGECLASS"))="^"
	{	s %code="$classmethod("_%parameter("LANGUAGECLASS")_",""MakeSearchTerms"",searchPattern,ngramlen)" }
	else
	{	s %code="##class("_%parameter("LANGUAGECLASS")_").MakeSearchTerms(searchPattern,ngramlen)" }

	QUIT $$$OK
}

/// Tests if the logical value <var>%val</var>, which is a string, is valid.
/// The validation is based on the class parameter settings used for the class attribute this data type is associated with.
/// In this case, <a href="#MINLEN">MINLEN</a>, <a href="#MAXLEN">MAXLEN</a>, <a href="#VALUELIST">VALUELIST</a>, and <a href="#PATTERN">PATTERN</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; Validate MAXLEN parameter - must be a positive integer
	If (%mode'="method") && (('$isvalidnum(%parameter("MAXLEN"),,1)) || (((+%parameter("MAXLEN")\1)) '= +%parameter("MAXLEN"))) { Quit $$$ERROR($$$DatatypeParameterIntegerNotPositive,%class_"::"_%property,"MAXLEN",%parameter("MAXLEN")) }
	// n sep,str,flag
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="$select(%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))"
	s str="",err=""
	If %parameter("MINLEN")'="" {
		Set str=str_"($s(%val'=$c(0):$length(%val),1:0)'<"_(+%parameter("MINLEN"))_")"
		If %parameter("PATTERN")="",%parameter("MAXLEN")=""||(%parameter("TRUNCATE")) {
			Set err="1"
		} Else {
			Set err="$s(%val'=$c(0):$length(%val),1:0)<"_(+%parameter("MINLEN"))
		}
		Set err=err_":$$$ERROR($$$DTMinLen,%val,"_(+%parameter("MINLEN"))_")"
	}
	If '%parameter("TRUNCATE"),%parameter("MAXLEN")'="" {
		Set str=str_"&&($length(%val)'>"_(+%parameter("MAXLEN"))_")"
		If %parameter("PATTERN")="" {
			Set err=err_$select(err="":"",1:",")_"1"
		} Else {
			Set err=err_$select(err="":"",1:",")_"$length(%val)>"_(+%parameter("MAXLEN"))
		}
		Set err=err_":$$$ERROR($$$DTMaxLen,%val,"_(+%parameter("MAXLEN"))_")"
	}
	If %parameter("PATTERN")'="" Set str=str_"&&(%val?"_%parameter("PATTERN")_")",err=err_$select(err="":"",1:",")_"1:$$$ERROR($$$DTPattern,%val,"_$$$quote(%parameter("PATTERN"))_")"
	i str="" s %code=1 QUIT $$$OK
	i $e(str,1,2)="&&" s str=$e(str,3,*)
	s %code="$select("_str_":1,"_err_")"
	QUIT $$$OK
}

}
