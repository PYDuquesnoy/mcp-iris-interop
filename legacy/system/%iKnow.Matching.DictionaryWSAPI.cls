/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Matching.DictionaryAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Matching.DictionaryAPI</class> for more information.</p>
Class %iKnow.Matching.DictionaryWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

///  Creates a Dictionary and returns its ID.
ClassMethod CreateDictionary(domainId As %Integer, name As %String, description As %String = "", defaultLanguage As %String = "en", defaultProfileId As %Integer = "") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set defaultLanguage = $s($g(defaultLanguage)="":"en", 1:defaultLanguage)

	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(domainId, name, description, defaultLanguage, defaultProfileId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Creates a Dictionary Format instance of the supplied <i>formatClass</i> and returns its ID.
ClassMethod CreateDictionaryFormat(domainId As %Integer, formatClass As %String, formatParams As %ListOfDataTypes = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryFormat(domainId, formatClass, ..ListToListBuild(formatParams), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Creates a Dictionary Item and returns its ID.
ClassMethod CreateDictionaryItem(domainId As %Integer, dictId As %Integer, name As %String, URI As %String, defaultLanguage As %String = "en") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set defaultLanguage = $s($g(defaultLanguage)="":"en", 1:defaultLanguage)

	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(domainId, dictId, name, .URI, defaultLanguage, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Shorthand method for creating a Dictionary Item and Term using the Item's name. Returns the Items ID.
ClassMethod CreateDictionaryItemAndTerm(domainId As %Integer, dictId As %Integer, name As %String, URI As %String, language As %String = "en") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set language = $s($g(language)="":"en", 1:language)

	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItemAndTerm(domainId, dictId, name, .URI, language, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Creates a Dictionary Term and returns its ID.</p>
///  <p>If <var>isProcessed</var> is 1 (default 0), the term will be marked as processed upon creation
///  and no Dictionary Elements will be created. This parameter is for internal use only and deprecated in 2013.1.</p>
ClassMethod CreateDictionaryTerm(domainId As %Integer, dictItemId As %Integer, string As %String, language As %String = "en", isProcessed As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set language = $s($g(language)="":"en", 1:language)
	set isProcessed = $s($g(isProcessed)="":0, 1:isProcessed)

	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(domainId, dictItemId, string, language, .sc, isProcessed)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Creates a Dictionary Term composed of a single Dictionary Format and returns the Terms ID.
ClassMethod CreateDictionaryTermFormat(domainId As %Integer, dictItemId As %Integer, formatClass As %String, formatParams As %ListOfDataTypes = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTermFormat(domainId, dictItemId, formatClass, ..ListToListBuild(formatParams), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Shorthand method to create a Dictionary Term composed of a single Dictionary Format of type
/// <class>%iKnow.Matching.Formats.RegularExpression</class>, matching <var>pRegularExpression</var> and
/// optionally producing output by replacing the matched parts of an entity with <var>pReplace</var>.
ClassMethod CreateRegularExpression(pDomainId As %Integer, pDictItemId As %Integer, pRegularExpression As %String, pReplace As %String = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateRegularExpression(pDomainId, pDictItemId, pRegularExpression, pReplace, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Drops all dictionary data, including matching results. 
/// This method will fail if there are managed dictionaries in this domain.
ClassMethod DropAllDictionaryData(domainId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropAllDictionaryData(domainId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Deletes a Dictionary and all related items, terms, elements and matches.
ClassMethod DropDictionary(domainId As %Integer, dictId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(domainId, dictId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Deletes a Dictionary Item with all related terms, elements and matches.
ClassMethod DropDictionaryItem(domainId As %Integer, dictItemId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryItem(domainId, dictItemId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Drops a single Dictionary Term and its matching results
ClassMethod DropDictionaryTerm(domainId As %Integer, dictTermId As %String) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryTerm(domainId, dictTermId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

///  Returns all Dictionaries in this domain.
///  If <var>pIncludeCrossDomain</var> = 1, any cross-domain dictionaries registered in "domain 0"
///  are also included in the result, using a negative value for their ID.
ClassMethod GetDictionaries(domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, pIncludeCrossDomain As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)
	set pIncludeCrossDomain = $s($g(pIncludeCrossDomain)="":0, 1:pIncludeCrossDomain)

	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetDictionaries")
	set tSC = data.Execute(domainId, page, pageSize, pIncludeCrossDomain)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

ClassMethod GetDictionaryCount(pDomainId As %Integer) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryCount(pDomainId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Looks up the Dictionary ID corresponding to the supplied Dictionary name.
ClassMethod GetDictionaryId(domainId As %Integer, name As %String) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(domainId, name, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Looks up the Dictionary Item ID corresponding to the supplied Dictionary Item URI.
ClassMethod GetDictionaryItemIdByURI(domainId As %Integer, URI As %String) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(domainId, URI, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  Returns all Dictionary Items for the given Dictionary ID.
ClassMethod GetDictionaryItems(domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetDictionaryItems")
	set tSC = data.Execute(domainId, dictId, page, pageSize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  Returns all Dictionary Items and their Terms for the given Dictionary ID.
ClassMethod GetDictionaryItemsAndTerms(domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetDictionaryItemsAndTerms")
	set tSC = data.Execute(domainId, dictId, page, pageSize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  Returns all the Dictionary Terms for the given Dictionary Item ID.
ClassMethod GetDictionaryTermsByItem(domainId As %Integer, dictItemId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetDictionaryTermsByItem")
	set tSC = data.Execute(domainId, dictItemId, page, pageSize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

ClassMethod GetItemCount(pDomainId As %Integer, pDictIds As %ListOfDataTypes = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetItemCount(pDomainId, ..ListToListBuild(pDictIds), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Note: <var>pFilter</var> is ignored when looking at cross-domain dictionaries
ClassMethod GetItemsByName(pDomainId As %Integer, pString As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pDictIds As %ListOfDataTypes = "", pMode As %Integer = {$$$USEPARTS}, pCheck As %String(VALUELIST="NAME,URI") = "NAME", pLang As %String = "en") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pMode = $s($g(pMode)="":$$$USEPARTS, 1:pMode)
	set pCheck = $s($g(pCheck)="":"NAME", 1:pCheck)
	set pLang = $s($g(pLang)="":"en", 1:pLang)

	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetItemsByName")
	set tSC = data.Execute(pDomainId, pString, pPage, pPageSize, pFilter, $lts(..ListToListBuild(pDictIds)), pMode, pCheck, pLang)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

ClassMethod GetTermCount(pDomainId As %Integer, pDictIds As %ListOfDataTypes = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetTermCount(pDomainId, ..ListToListBuild(pDictIds), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

ClassMethod GetTermCountByItem(pDomainId As %Integer, pDictItemIds As %ListOfDataTypes = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetTermCountByItem(pDomainId, ..ListToListBuild(pDictItemIds), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Retrieves the elements corresponding to a given <var>pDictionaryTermId</var>.
ClassMethod GetTermElements(pDomainId As %Integer, pDictionaryTermId As %Integer) As %XML.DataSet [ Internal, WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetTermElements")
	set tSC = data.Execute(pDomainId, pDictionaryTermId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Note: <var>pFilter</var> is ignored when looking at cross-domain dictionaries
ClassMethod GetTermsByName(pDomainId As %Integer, pString As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pDictIds As %ListOfDataTypes = "", pMode As %Integer = {$$$USEPARTS}, pLang As %String = "en") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pMode = $s($g(pMode)="":$$$USEPARTS, 1:pMode)
	set pLang = $s($g(pLang)="":"en", 1:pLang)

	set data = ##class(%XML.DataSet).%New("%iKnow.Matching.DictionaryQAPI:GetTermsByName")
	set tSC = data.Execute(pDomainId, pString, pPage, pPageSize, pFilter, $lts(..ListToListBuild(pDictIds)), pMode, pLang)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns whether or not there are any dictionaries in the domain
ClassMethod HasDictionaries(pDomainId As %Integer) As %Library.Boolean [ WebMethod ]
{
	quit ##class(%iKnow.Matching.DictionaryAPI).HasDictionaries(pDomainId)
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Matching/DictionaryWSAPI";

Parameter SERVICENAME = "iKnow.Matching.DictionaryWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
