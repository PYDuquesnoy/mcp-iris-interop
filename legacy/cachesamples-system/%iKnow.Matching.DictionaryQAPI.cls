/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Matching.DictionaryAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Matching.DictionaryAPI</class> for more information.</p>
Class %iKnow.Matching.DictionaryQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

///  Creates a Dictionary and returns its ID.
ClassMethod CreateDictionary(domainId As %Integer, name As %String(MAXLEN=32767), description As %String(MAXLEN=32767) = "", defaultLanguage As %String(MAXLEN=32767) = "en", defaultProfileId As %Integer = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(domainId, name, description, defaultLanguage, defaultProfileId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Creates a Dictionary Format instance of the supplied <i>formatClass</i> and returns its ID.
ClassMethod CreateDictionaryFormat(domainId As %Integer, formatClass As %String(MAXLEN=32767), formatParams As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryFormat(domainId, formatClass, $lfs(formatParams), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Creates a Dictionary Item and returns its ID.
ClassMethod CreateDictionaryItem(domainId As %Integer, dictId As %Integer, name As %String(MAXLEN=32767), ByRef URI As %String(MAXLEN=32767), defaultLanguage As %String(MAXLEN=32767) = "en", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(domainId, dictId, name, .URI, defaultLanguage, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Shorthand method for creating a Dictionary Item and Term using the Item's name. Returns the Items ID.
ClassMethod CreateDictionaryItemAndTerm(domainId As %Integer, dictId As %Integer, name As %String(MAXLEN=32767), ByRef URI As %String(MAXLEN=32767), language As %String(MAXLEN=32767) = "en", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItemAndTerm(domainId, dictId, name, .URI, language, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Creates a Dictionary Term and returns its ID.</p>
///  <p>If <var>isProcessed</var> is 1 (default 0), the term will be marked as processed upon creation
///  and no Dictionary Elements will be created. This parameter is for internal use only and deprecated in 2013.1.</p>
ClassMethod CreateDictionaryTerm(domainId As %Integer, dictItemId As %Integer, string As %String(MAXLEN=32767), language As %String(MAXLEN=32767) = "en", Output scText As %String = "", isProcessed As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(domainId, dictItemId, string, language, .sc, isProcessed)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Creates a Dictionary Term composed of a single Dictionary Format and returns the Terms ID.
ClassMethod CreateDictionaryTermFormat(domainId As %Integer, dictItemId As %Integer, formatClass As %String(MAXLEN=32767), formatParams As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTermFormat(domainId, dictItemId, formatClass, $lfs(formatParams), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Shorthand method to create a Dictionary Term composed of a single Dictionary Format of type
/// <class>%iKnow.Matching.Formats.RegularExpression</class>, matching <var>pRegularExpression</var> and
/// optionally producing output by replacing the matched parts of an entity with <var>pReplace</var>.
ClassMethod CreateRegularExpression(pDomainId As %Integer, pDictItemId As %Integer, pRegularExpression As %String(MAXLEN=32767), pReplace As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).CreateRegularExpression(pDomainId, pDictItemId, pRegularExpression, pReplace, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Drops all dictionary data, including matching results. 
/// This method will fail if there are managed dictionaries in this domain.
ClassMethod DropAllDictionaryData(domainId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropAllDictionaryData(domainId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Deletes a Dictionary and all related items, terms, elements and matches.
ClassMethod DropDictionary(domainId As %Integer, dictId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(domainId, dictId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Deletes a Dictionary Item with all related terms, elements and matches.
ClassMethod DropDictionaryItem(domainId As %Integer, dictItemId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryItem(domainId, dictItemId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Drops a single Dictionary Term and its matching results
ClassMethod DropDictionaryTerm(domainId As %Integer, dictTermId As %String(MAXLEN=32767)) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryTerm(domainId, dictTermId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

///  Returns all Dictionaries in this domain.
///  If <var>pIncludeCrossDomain</var> = 1, any cross-domain dictionaries registered in "domain 0"
///  are also included in the result, using a negative value for their ID.
Query GetDictionaries(domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, pIncludeCrossDomain As %Boolean = 0) As %Library.Query(ROWSPEC = "dictId:%Integer,name:%String(MAXLEN=32767),description:%String(MAXLEN=32767),defaultLanguage:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetDictionariesExecute(ByRef qHandle As %Binary,  domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, pIncludeCrossDomain As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaries("^||%IKQ.Result("_r_")", domainId, page, pageSize, pIncludeCrossDomain)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetDictionariesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetDictionariesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetDictionariesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetDictionariesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

ClassMethod GetDictionaryCount(pDomainId As %Integer, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryCount(pDomainId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Looks up the Dictionary ID corresponding to the supplied Dictionary name.
ClassMethod GetDictionaryId(domainId As %Integer, name As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(domainId, name, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Looks up the Dictionary Item ID corresponding to the supplied Dictionary Item URI.
ClassMethod GetDictionaryItemIdByURI(domainId As %Integer, URI As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(domainId, URI, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  Returns all Dictionary Items for the given Dictionary ID.
Query GetDictionaryItems(domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Library.Query(ROWSPEC = "dictItemId:%Integer,name:%String(MAXLEN=32767),URI:%String(MAXLEN=32767),defaultLanguage:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetDictionaryItemsExecute(ByRef qHandle As %Binary,  domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItems("^||%IKQ.Result("_r_")", domainId, dictId, page, pageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetDictionaryItemsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetDictionaryItemsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetDictionaryItemsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetDictionaryItemsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  Returns all Dictionary Items and their Terms for the given Dictionary ID.
Query GetDictionaryItemsAndTerms(domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Library.Query(ROWSPEC = "dictItemId:%Integer,name:%String(MAXLEN=32767),URI:%String(MAXLEN=32767),dictTermId:%Integer,string:%String(MAXLEN=32767),language:%String(MAXLEN=32767),isProcessed:%Boolean") [ SqlProc ]
{
}

ClassMethod GetDictionaryItemsAndTermsExecute(ByRef qHandle As %Binary,  domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemsAndTerms("^||%IKQ.Result("_r_")", domainId, dictId, page, pageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetDictionaryItemsAndTermsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetDictionaryItemsAndTermsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetDictionaryItemsAndTermsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetDictionaryItemsAndTermsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  Returns all the Dictionary Terms for the given Dictionary Item ID.
Query GetDictionaryTermsByItem(domainId As %Integer, dictItemId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Library.Query(ROWSPEC = "dictTermId:%Integer,string:%String(MAXLEN=32767),language:%String(MAXLEN=32767),isProcessed:%Boolean") [ SqlProc ]
{
}

ClassMethod GetDictionaryTermsByItemExecute(ByRef qHandle As %Binary,  domainId As %Integer, dictItemId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryTermsByItem("^||%IKQ.Result("_r_")", domainId, dictItemId, page, pageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetDictionaryTermsByItemFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetDictionaryTermsByItemExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetDictionaryTermsByItemClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetDictionaryTermsByItemExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

ClassMethod GetItemCount(pDomainId As %Integer, pDictIds As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetItemCount(pDomainId, $lfs(pDictIds), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Note: <var>pFilter</var> is ignored when looking at cross-domain dictionaries
Query GetItemsByName(pDomainId As %Integer, pString As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pDictIds As %String(MAXLEN=32767) = "", pMode As %Integer = {$$$USEPARTS}, pCheck As %String(VALUELIST="NAME,URI") = "NAME", pLang As %String(MAXLEN=32767) = "en") As %Library.Query(ROWSPEC = "dictId:%Integer,dictName:%String(MAXLEN=32767),itemId:%Integer,itemName:%String(MAXLEN=32767),URI:%String(MAXLEN=32767),language:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetItemsByNameExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pString As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pDictIds As %String(MAXLEN=32767) = "", pMode As %Integer = {$$$USEPARTS}, pCheck As %String(VALUELIST="NAME,URI") = "NAME", pLang As %String(MAXLEN=32767) = "en") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetItemsByName("^||%IKQ.Result("_r_")", pDomainId, pString, pPage, pPageSize, pFilter, $lfs(pDictIds), pMode, pCheck, pLang)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetItemsByNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetItemsByNameExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetItemsByNameClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetItemsByNameExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

ClassMethod GetTermCount(pDomainId As %Integer, pDictIds As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetTermCount(pDomainId, $lfs(pDictIds), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

ClassMethod GetTermCountByItem(pDomainId As %Integer, pDictItemIds As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Matching.DictionaryAPI).GetTermCountByItem(pDomainId, $lfs(pDictItemIds), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Retrieves the elements corresponding to a given <var>pDictionaryTermId</var>.
Query GetTermElements(pDomainId As %Integer, pDictionaryTermId As %Integer) As %Library.Query(ROWSPEC = "dictElemId:%Integer,type:%Integer,valueId:%Integer,value:%String(MAXLEN=32767),position:%Integer,role:%Integer,minMatchScore:%Numeric,scoreMultiplier:%Numeric") [ Internal, SqlProc ]
{
}

ClassMethod GetTermElementsExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pDictionaryTermId As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements("^||%IKQ.Result("_r_")", pDomainId, pDictionaryTermId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTermElementsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTermElementsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTermElementsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTermElementsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Note: <var>pFilter</var> is ignored when looking at cross-domain dictionaries
Query GetTermsByName(pDomainId As %Integer, pString As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pDictIds As %String(MAXLEN=32767) = "", pMode As %Integer = {$$$USEPARTS}, pLang As %String(MAXLEN=32767) = "en") As %Library.Query(ROWSPEC = "dictId:%Integer,dictName:%String(MAXLEN=32767),itemId:%Integer,itemName:%String(MAXLEN=32767),URI:%String(MAXLEN=32767),termId:%Integer,term:%String(MAXLEN=32767),language:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetTermsByNameExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pString As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pDictIds As %String(MAXLEN=32767) = "", pMode As %Integer = {$$$USEPARTS}, pLang As %String(MAXLEN=32767) = "en") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Matching.DictionaryAPI).GetTermsByName("^||%IKQ.Result("_r_")", pDomainId, pString, pPage, pPageSize, pFilter, $lfs(pDictIds), pMode, pLang)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTermsByNameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTermsByNameExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTermsByNameClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTermsByNameExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns whether or not there are any dictionaries in the domain
ClassMethod HasDictionaries(pDomainId As %Integer) As %Library.Boolean [ SqlProc ]
{
	quit ##class(%iKnow.Matching.DictionaryAPI).HasDictionaries(pDomainId)
}

}
