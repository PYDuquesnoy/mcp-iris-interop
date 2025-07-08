/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
///  Main entry point for managing Dictionary contents to be used by the Matching APIs
Class %iKnow.Matching.DictionaryAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

///  Creates a Dictionary and returns its ID.
ClassMethod CreateDictionary(domainId As %Integer, name As %String, description As %String = "", defaultLanguage As %String = "en", defaultProfileId As %Integer = "", Output sc As %Status = {$$$OK}) As %Integer
{
	quit ..CreateDictionaryInternal(domainId, name, description, defaultLanguage, defaultProfileId,, .sc)
}

ClassMethod CreateDictionaryInternal(domainId As %Integer, name As %String, description As %String = "", defaultLanguage As %String = "en", defaultProfileId As %Integer = "", mgrClass As %String = "", Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
		$$$IKCHECKDOMMGRR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKNOTNULLR(name,sc,-1)
	$$$IKCHECKSTRINGLENGTHR(name,sc,-1)
	
	// BDB397 - case insensitive names
	set tNameIndex = $s('domainId||$$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(name), 1:name)
	$$$IKCHECKIDNOTEXISTSR(^IRIS.IK.Mat.Dict,domainId,tNameIndex,$$$IKDictExists,sc,-1)
	
    set languageId = $listfind($$$IKLANGUAGES, defaultLanguage)
    if ('languageId) {
	    set sc = $$$ERROR($$$InvalidArgument, "defaultLanguage")
	    quit -1
    }
    if (defaultProfileId) {
	    quit:##class(%iKnow.Matching.MatchingProfile).GetProfile(domainId, defaultProfileId,.sc)=""
    }
	
	$$$IKLOCKR(domainId,^IRIS.IK.Mat.DictId,sc,-1)
	
	// check again if it wasn't added in the meantime
	if $d(^IRIS.IK.Mat.Dict(domainId,tNameIndex)) {
		$$$IKUNLOCK(domainId,^IRIS.IK.Mat.DictId)
		set sc = $$$ERROR($$$IKDictExists, name)
		quit -1
	}
	
	set tTLevel = $tlevel
	try {
		tstart
	    set dictId = $i(^IRIS.IK.Mat.DictId(domainId))
   		set ^IRIS.IK.Mat.DictId(domainId, dictId) = $lb(name, description, languageId, defaultProfileId, mgrClass)
   		set ^IRIS.IK.Mat.Dict(domainId, tNameIndex) = dictId
   		set:domainId ^IRIS.IK.Mat.DictMatchStatus(domainId, dictId) = $lb(0,0,0)
   		
   		// BDB385 - store version number for cross-domain dictionaries
   		set:($g(^IRIS.IK.Mat.DictId)="")&&'domainId ^IRIS.IK.Mat.DictId = $$$IKCURRENTVERSION
   		
		tcommit
   		
   		// BDB624 - trigger customizations
   		set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE), 1:"")
   		if (tTablesPackage'="") && $classmethod(tTablesPackage_".Dictionary","%HasCustomizations") {
	   		set tSC = $classmethod(tTablesPackage_".Dictionary", "%BuildCustomFields", dictId, dictId)
	   		quit:$$$ISERR(tSC)
	   		set tSC = $classmethod(tTablesPackage_".Dictionary", "%BuildCustomIndices", 0, dictId, dictId)
	   		quit:$$$ISERR(tSC)
   		}
	} catch(ex) {
		set sc = ex.AsStatus(), dictId=-1
	}
	trollback:($tlevel>tTLevel) 1
	
	$$$IKUNLOCK(domainId,^IRIS.IK.Mat.DictId)
	
    quit dictId
}

///  Looks up the Dictionary ID corresponding to the supplied Dictionary name.
ClassMethod GetDictionaryId(domainId As %Integer, name As %String, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	set sc = $$$OK
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKNOTNULLR(name,sc,-1)
	$$$IKCHECKSTRINGLENGTHR(name,sc,-1)
	
	// BDB397 - case insensitive names
	set tNameIndex = $s('domainId||$$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(name), 1:name)
	quit $g(^IRIS.IK.Mat.Dict(domainId, tNameIndex))
}

/// Returns whether or not there are any dictionaries in the domain
ClassMethod HasDictionaries(pDomainId As %Integer) As %Boolean
{
	quit ($d(^IRIS.IK.Mat.DictId(pDomainId))>=10)
}

Parameter DropDictionaryEXP [ Internal ] = 1;

///  Deletes a Dictionary and all related items, terms, elements and matches.
ClassMethod DropDictionary(domainId As %Integer, dictId As %Integer) As %Status
{
	set tSC = $$$OK, tTLevel = $tlevel
	$$$IKCHECKPRIVWRITE
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTS(domainId)
		$$$IKCHECKDOMMGR(domainId)
	} else {
		$$$IKXDOMDICTVERSION(xDomVersion)
	}
	$$$IKCHECKIDEXISTS(^IRIS.IK.Mat.DictId,domainId,+dictId,dictDetails,$$$IKDictionaryDoesNotExist)
	
	// BDB385 - check manager class
	set tMgrClass = $lg(dictDetails,5)
	$$$IKCHECKMGR("Dictionary",dictId,tMgrClass)
	
	$$$IKLOCK(domainId,^IRIS.IK.Mat.DictId)
	
	try {
		tstart
	    // first delete all items within
	    set dictItemId = ""
	    for {
	        set dictItemId = $order(^IRIS.IK.Mat.DictToItem(domainId, dictId, dictItemId))
	        quit:dictItemId=""
        
	        set tSC = ..DropDictionaryItem(domainId, dictItemId)
	        quit:$$$ISERR(tSC)
	    }
	    quit:$$$ISERR(tSC)

	    // remove all dictionary-level match results
	    if (domainId) {
		    kill ^IRIS.IK.Mat.DictMatchStatus(domainId, dictId)
		    kill ^IRIS.IK.Mat.DictToMatchBit(domainId, dictId)
	    	kill ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, dictId)
	    } else {
		    
		    // BDB385 - for cross-domain dictionaries, remove results in all domains
		    set d = ""
		    for {
			  	set d = $order(^IRIS.IK.Mat.DictMatchStatus(d))
			  	quit:d=""
			  	 
			    kill ^IRIS.IK.Mat.DictMatchStatus(d, -dictId)
			    kill ^IRIS.IK.Mat.DictToMatchBit(d, -dictId)
		    	kill ^IRIS.IK.Mat.DictToSrcMatchedBit(d, -dictId)
		    }
	    }
	    
	    // remove dictionary format references
	    kill ^IRIS.IK.Mat.DictToFormat(domainId, dictId)	    

	    // now remove the dict entry
	    // BDB624 - verify if we need to sync customizations and go through the object
	    set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE), 1:"") 
	    if (tTablesPackage'="") && $classmethod(tTablesPackage_".Dictionary","%HasCustomizations") {
		    new %ikSafeDelete
		    set %ikSafeDelete = 1
		    set tSC = $classmethod(tTablesPackage_".Dictionary", "%DeleteId", dictId, 0)
		    quit:$$$ISERR(tSC)
	    } else {
		    kill ^IRIS.IK.Mat.Dict(domainId, $$$UPPER($li(dictDetails,1)))
		    kill ^IRIS.IK.Mat.DictId(domainId, dictId)
	    }
	    kill ^IRIS.IK.Mat.DictToItem(domainId, dictId)
	    
	    // BDB385 - also drop version info if this was the last cross-domain dictionary
	    if 'domainId && ($d(^IRIS.IK.Mat.DictId(0))<10) {
		    zkill ^IRIS.IK.Mat.DictId
	    }
	    
		tcommit
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	$$$IKUNLOCK(domainId,^IRIS.IK.Mat.DictId)

    quit tSC
}

///  Creates a Dictionary Item and returns its ID.
ClassMethod CreateDictionaryItem(domainId As %Integer, dictId As %Integer, name As %String, ByRef URI As %String, defaultLanguage As %String = "en", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
		$$$IKCHECKDOMMGRR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKNOTNULLR(name,sc,-1)
	$$$IKCHECKIDEXISTSR(^IRIS.IK.Mat.DictId,domainId,+dictId,dictDetails,$$$IKDictionaryDoesNotExist,sc,-1)
	if $g(URI)'="" {
		$$$IKCHECKSTRINGLENGTHR(URI,sc,-1)
		$$$IKCHECKIDNOTEXISTSR(^IRIS.IK.Mat.DictItemURI,domainId,URI,$$$IKDictItemURIExists,sc,-1)
	}
	
	// BDB385 - check manager class
	set tMgrClass = $lg(dictDetails,5)
	$$$IKCHECKMGRR("Dictionary",dictId,tMgrClass,sc,-1)
	
    set languageId = $listfind($$$IKLANGUAGES, defaultLanguage)
    if ('languageId) { set sc = $$$ERROR($$$InvalidArgument, "defaultLanguage")  quit -1 }
	
	$$$IKLOCKR(domainId,^IRIS.IK.Mat.DictItemId,sc,-1)
	
	// BDB440: if no URI was supplied, generate one
	if $g(URI)="" {
		set tBaseURI = ":"_dictId_":"_$e(name,1,50), URI = tBaseURI, tDeDup=0
		while $d(^IRIS.IK.Mat.DictItemURI(domainId,URI)) {
			set URI = tBaseURI_":"_$i(tDeDup)
		}
	}	
	// otherwise, check again if it wasn't added in the meantime
	elseif $d(^IRIS.IK.Mat.DictItemURI(domainId,URI)) {
		$$$IKUNLOCK(domainId,^IRIS.IK.Mat.DictItemId)
		set sc = $$$ERROR($$$IKDictItemURIExists, URI)
		quit -1
	}
	
	set tTLevel = $tlevel
	try {
		tstart
	    set dictItemId = $i(^IRIS.IK.Mat.DictItemId(domainId))
	    set ^IRIS.IK.Mat.DictItemId(domainId, dictItemId) = $lb(dictId, name, URI, languageId)
	    set ^IRIS.IK.Mat.DictItemURI(domainId, URI) = dictItemId
	    set ^IRIS.IK.Mat.DictToItem(domainId, dictId, dictItemId) = ""
	    
		tcommit
   		
   		// BDB624 - trigger customizations
   		set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE), 1:"")
   		if (tTablesPackage'="") && $classmethod(tTablesPackage_".DictionaryItem","%HasCustomizations") {
	   		set tSC = $classmethod(tTablesPackage_".DictionaryItem", "%BuildCustomFields", dictItemId, dictItemId)
	   		quit:$$$ISERR(tSC)
	   		set tSC = $classmethod(tTablesPackage_".DictionaryItem", "%BuildCustomIndices", 0, dictItemId, dictItemId)
	   		quit:$$$ISERR(tSC)
   		}
	} catch(ex) {
		set sc = ex.AsStatus(), dictItemId=-1
	}
	trollback:($tlevel>tTLevel) 1
	
	$$$IKUNLOCK(domainId,^IRIS.IK.Mat.DictItemId)
	
    quit dictItemId
}

///  Looks up the Dictionary Item ID corresponding to the supplied Dictionary Item URI.
ClassMethod GetDictionaryItemIdByURI(domainId As %Integer, URI As %String, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKNOTNULLR(URI,sc,-1)
	$$$IKCHECKSTRINGLENGTHR(URI,sc,-1)
	quit $g(^IRIS.IK.Mat.DictItemURI(domainId, URI))
}

Parameter DropDictionaryItemEXP [ Internal ] = 1;

///  Deletes a Dictionary Item with all related terms, elements and matches.
ClassMethod DropDictionaryItem(domainId As %Integer, dictItemId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTS(domainId)
		$$$IKCHECKDOMMGR(domainId)
	} else {
		$$$IKXDOMDICTVERSION(xDomVersion)
	}
	$$$IKCHECKIDEXISTS(^IRIS.IK.Mat.DictItemId,domainId,+dictItemId,item,$$$IKDictItemDoesNotExist)
	
	// BDB385 - check manager class
	set tDictId = $li(item,1), tMgrClass = $lg(^IRIS.IK.Mat.DictId(domainId,tDictId),5)
	$$$IKCHECKMGR("Dictionary",tDictId,tMgrClass)
	
	// BDB624 - check if there are any customizations to sync
	set tHasTermCustomizations = 0, tHasItemCustomizations = 0
	set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE),1:"")
	if (tTablesPackage'="") { 
		new %ikSafeDelete set %ikSafeDelete = 1 
		set tHasTermCustomizations = $classmethod(tTablesPackage_".DictionaryTerm","%HasCustomizations")
		set tHasItemCustomizations = $classmethod(tTablesPackage_".DictionaryItem","%HasCustomizations")
	}
	
	$$$IKLOCK(domainId,^IRIS.IK.Mat.DictItemId)
	
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		tstart
	    set dictId = $list(item,1)
	    
	    set tSC = ##class(%iKnow.Matching.MatchingAPI).InvalidateMatchingResultsInternal(domainId, dictId, dictItemId, 2)
	    quit:$$$ISERR(tSC)

	    // drop all terms
	    set terms = $g(^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId)), ptr1=0
	    while $listnext(terms,ptr1,dtId) {
		    if tHasTermCustomizations {
			    set tSC = $classmethod(tTablesPackage_".DictionaryTerm", "%DeleteId", dtId, 0)
			    quit:$$$ISERR(tSC)
		    } else {
		        kill ^IRIS.IK.Mat.DictTermId(domainId, dtId)
		    }
	    }
	    quit:$$$ISERR(tSC)
	    kill ^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId)
    
	    // drop the item itself
	    if tHasItemCustomizations {
		    set tSC = $classmethod(tTablesPackage_".DictionaryItem", "%DeleteId", dictItemId, 0)
		    quit:$$$ISERR(tSC)
	    } else {
		    kill ^IRIS.IK.Mat.DictItemId(domainId, dictItemId)
	    }
	    kill ^IRIS.IK.Mat.DictItemURI(domainId, $list(item, 3))
	    kill ^IRIS.IK.Mat.DictToItem(domainId, $list(item, 1), dictItemId)
		tcommit
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	
	$$$IKUNLOCK(domainId,^IRIS.IK.Mat.DictItemId)

    quit tSC
}

///  Shorthand method for creating a Dictionary Item and Term using the Item's name. Returns the Items ID.
ClassMethod CreateDictionaryItemAndTerm(domainId As %Integer, dictId As %Integer, name As %String, ByRef URI As %String, language As %String = "en", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
    set dictItemId = ..CreateDictionaryItem($g(domainId), $g(dictId), $g(name), .URI, $g(language), .sc)
    quit:$$$ISERR(sc) -1
	set dictTermId = ..CreateDictionaryTerm($g(domainId), dictItemId, $g(name), $g(language), .sc)
	quit:$$$ISERR(sc) -1
	quit dictItemId
}

///  <p>Creates a Dictionary Term and returns its ID.</p>
///  <p>If <var>isProcessed</var> is 1 (default 0), the term will be marked as processed upon creation
///  and no Dictionary Elements will be created. This parameter is for internal use only and deprecated in 2013.1.</p>
ClassMethod CreateDictionaryTerm(domainId As %Integer, dictItemId As %Integer, string As %String, language As %String = "en", Output sc As %Status = {$$$OK}, isProcessed As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
		$$$IKCHECKDOMMGRR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKIDEXISTS(^IRIS.IK.Mat.DictItemId,domainId,+dictItemId,dictItem,$$$IKDictItemDoesNotExist)
	
	// BDB385 - check manager class
	set tDictId = $li(dictItem,1), tMgrClass = $lg(^IRIS.IK.Mat.DictId(domainId,tDictId),5)
	$$$IKCHECKMGRR("Dictionary",tDictId,tMgrClass,sc,-1)
	
	set languageId = ""
    set:language'="" languageId = $listfind($$$IKLANGUAGES, language)
    if ('languageId && 'isProcessed) { set sc = $$$ERROR($$$InvalidArgument, "language")  quit -1 }
    
    $$$IKLOCK(domainId_"|"_dictItemId,^IRIS.IK.Mat.DictItemId)
	
	set tTLevel = $tlevel
	try {
	    // first look if the term already exists
	    set terms = $g(^IRIS.IK.Mat.DictItemTerms(domainId,dictItemId)), ptr=0, dictTermId=0
	    while $listnext(terms, ptr, termId) {
		    if ($lg($g(^IRIS.IK.Mat.DictTermId(domainId,termId)),3)=string) {
			    set dictTermId = termId
			    quit
		    }
	    }
	    quit:dictTermId
    
		tstart
		
	    set dictTermId = $i(^IRIS.IK.Mat.DictTermId(domainId))
	    set dictId = $list(dictItem, 1)
	    set tDomVersion = $s(domainId:$$$IKVERSION(domainId), 1:xDomVersion)
		if '(tDomVersion>=$$$IKVERSIONMATCHING20131) {
		    set ^IRIS.IK.Mat.DictTermId(domainId, dictTermId) = $lb(dictId, dictItemId, string, languageId, $s(isProcessed:$$$DTPROCESSED, 1:$$$DTUNPROCESSED))
		} else {
		    set ^IRIS.IK.Mat.DictTermId(domainId, dictTermId) = $lb(dictId, dictItemId, string, languageId)
		}

	    // add to DI terms list
	    set ^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId)=$g(^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId))_$lb(dictTermId)
		tcommit
   		
   		// BDB624 - trigger customizations
   		set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE), 1:"")
   		if (tTablesPackage'="") && $classmethod(tTablesPackage_".DictionaryTerm","%HasCustomizations") {
	   		set tSC = $classmethod(tTablesPackage_".DictionaryTerm", "%BuildCustomFields", dictTermId, dictTermId)
	   		quit:$$$ISERR(tSC)
	   		set tSC = $classmethod(tTablesPackage_".DictionaryTerm", "%BuildCustomIndices", 0, dictTermId, dictTermId)
	   		quit:$$$ISERR(tSC)
   		}
	} catch(ex) {
		set sc = ex.AsStatus(), dictTermId = -1
	}
	trollback:($tlevel>tTLevel) 1
	$$$IKUNLOCK(domainId_"|"_dictItemId,^IRIS.IK.Mat.DictItemId)
    quit dictTermId
}

Parameter DropDictionaryTermEXP [ Internal ] = 1;

///  Drops a single Dictionary Term and its matching results
ClassMethod DropDictionaryTerm(domainId As %Integer, dictTermId As %String) As %Status
{
	$$$IKCHECKPRIVWRITE
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTS(domainId)
		$$$IKCHECKDOMMGR(domainId)
	} else {
		$$$IKXDOMDICTVERSION(xDomVersion)
	}
	$$$IKCHECKIDEXISTS(^IRIS.IK.Mat.DictTermId,domainId,+dictTermId,term,$$$IKDictTermDoesNotExist)
	
	// BDB385 - check manager class
	set tDictId = $li(term,1), tMgrClass = $lg(^IRIS.IK.Mat.DictId(domainId,tDictId),5)
	$$$IKCHECKMGR("Dictionary",tDictId,tMgrClass)
	
	set dictId = $list(term,1), dictItemId = $list(term,2)
	$$$IKLOCK(domainId_"|"_dictItemId,^IRIS.IK.Mat.DictItemId)
	
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		tstart
	    
	    set tSC = ##class(%iKnow.Matching.MatchingAPI).InvalidateMatchingResultsInternal(domainId, dictId, dictItemId, 2, dictTermId)
	    quit:$$$ISERR(tSC)
	    
	    // BDB624 - verify if we need to sync customizations and go through the object
	    set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE), 1:"") 
	    if (tTablesPackage'="") && $classmethod(tTablesPackage_".DictionaryTerm","%HasCustomizations") {
		    new %ikSafeDelete
		    set %ikSafeDelete = 1
		    set tSC = $classmethod(tTablesPackage_".DictionaryTerm", "%DeleteId", dictTermId, 0)
		    quit:$$$ISERR(tSC)
	    } else {
		    kill ^IRIS.IK.Mat.DictTermId(domainId, dictTermId)
	    }
	    
	    // drop from ^IRIS.IK.Mat.DictItemTerms
	    set terms = $g(^IRIS.IK.Mat.DictItemTerms(domainId,dictItemId))
	    set newTerms = "", ptr=0
	    while $listnext(terms,ptr,t) {
		    continue:(t=dictTermId)
		    set newTerms = newTerms _ $lb(t)
	    }
	    set ^IRIS.IK.Mat.DictItemTerms(domainId,dictItemId) = newTerms
	    
		tcommit
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	
	$$$IKUNLOCK(domainId_"|"_dictItemId,^IRIS.IK.Mat.DictItemId)

    quit tSC
}

///  Creates a Dictionary Format instance of the supplied <i>formatClass</i> and returns its ID.
ClassMethod CreateDictionaryFormat(domainId As %Integer, formatClass As %String, formatParams As %List = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK, dictFormatId=-1
	$$$IKCHECKPRIVWRITER(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
		$$$IKCHECKDOMMGRR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKNOTNULLR(formatClass,sc,-1)
	if (##class(%Dictionary.CompiledClass).%OpenId(formatClass)="") { set sc = $$$ERROR($$$IKDFClassDoesNotExist, formatClass)  quit -1 }
	
	// BDB440: verify parameters
	set sc = $classmethod(formatClass, "TestParams", formatParams, domainId)
	quit:$$$ISERR(sc) -1
	
	set tTLevel = $tlevel
	try {
		
		// derive or define formatClassId
		if '$d(^IRIS.IK.Sys.DictFormatI(formatClass), formatClassId) {
			
			$$$IKLOCKGX(^IRIS.IK.Sys.DictFormatD,sc)
			
			// check again after acquiring the lock
			tstart
			if '$d(^IRIS.IK.Sys.DictFormatI(formatClass), formatClassId) {
				set formatClassId = $i(^IRIS.IK.Sys.DictFormatD)
				set ^IRIS.IK.Sys.DictFormatD(formatClassId) = formatClass
				set ^IRIS.IK.Sys.DictFormatI(formatClass) = formatClassId
			}
			$$$IKUNLOCKG(^IRIS.IK.Sys.DictFormatD)
			
		} else {
			tstart
		}
		
	    // check if the format already exists
	    set formatParamsHash = $zcrc(formatParams, 7)
	    set dictFormatId = ""
	    for {
		    set dictFormatId = $order(^IRIS.IK.Mat.DictFormat(domainId, formatClassId, formatParamsHash, dictFormatId))
		    quit:dictFormatId=""
		    
		    set params = $lg(^IRIS.IK.Mat.DictFormatId(domainId, dictFormatId),2)
		    quit:$ls(params,formatParams)
	    }
	    
	    // if there still is no dictFormatId, we'll have to create a new one
	    if (dictFormatId="") {
		    set dictFormatId = $i(^IRIS.IK.Mat.DictFormatId(domainId))
			set ^IRIS.IK.Mat.DictFormatId(domainId, dictFormatId) = $lb(formatClassId, formatParams)
			set ^IRIS.IK.Mat.DictFormat(domainId, formatClassId, formatParamsHash, dictFormatId) = ""
	    }
	    
		tcommit
	} catch(ex) {
		set sc = ex.AsStatus(), dictFormatId = -1
	}
	trollback:($tlevel>tTLevel) 1
	$$$IKUNLOCKG(^IRIS.IK.Sys.DictFormatD)
	
	quit +dictFormatId
}

/// Shorthand method to create a Dictionary Term composed of a single Dictionary Format of type
/// <class>%iKnow.Matching.Formats.RegularExpression</class>, matching <var>pRegularExpression</var> and
/// optionally producing output by replacing the matched parts of an entity with <var>pReplace</var>.
ClassMethod CreateRegularExpression(pDomainId As %Integer, pDictItemId As %Integer, pRegularExpression As %String, pReplace As %String = "", Output pSC As %Status) As %Integer
{
	quit ..CreateDictionaryTermFormat(pDomainId, pDictItemId, "%iKnow.Matching.Formats.RegularExpression", $lb(pRegularExpression, pReplace), .pSC)
}

///  Creates a Dictionary Term composed of a single Dictionary Format and returns the Terms ID.
ClassMethod CreateDictionaryTermFormat(domainId As %Integer, dictItemId As %Integer, formatClass As %String, formatParams As %List = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
		$$$IKCHECKDOMMGRR(domainId,sc,-1)
	} else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKIDEXISTSR(^IRIS.IK.Mat.DictItemId,domainId,+dictItemId,dictItem,$$$IKDictItemDoesNotExist,sc,-1)
	
	// BDB385 - check manager class
	set tDictId = $li(dictItem,1), tMgrClass = $lg(^IRIS.IK.Mat.DictId(domainId,tDictId),5)
	$$$IKCHECKMGRR("Dictionary",tDictId,tMgrClass,sc,-1)
	
	set tTLevel = $tlevel
	try {
		tstart
	    set dictTermId = $i(^IRIS.IK.Mat.DictTermId(domainId))
	    set dictId = $list(dictItem, 1)
		if $$$IKVERSIONBEFORE(domainId,$$$IKVERSIONMATCHING20131) {
		    set ^IRIS.IK.Mat.DictTermId(domainId, dictTermId) = $lb(dictId, dictItemId, formatClass _ "[" _ $lts(formatParams) _ "]", "", $$$DTPROCESSED)
		} else {
		    set ^IRIS.IK.Mat.DictTermId(domainId, dictTermId) = $lb(dictId, dictItemId, formatClass _ "[" _ $lts(formatParams) _ "]", "")
		}
		
	    // get format id and store element
	    set dfId = ..CreateDictionaryFormat(domainId, formatClass, formatParams, .sc)
	    if $$$ISERR(sc) { set dictTermId = -1  quit }
	    set deId = ..CreateDictionaryElement(domainId, $$$DEFORMAT, dictTermId, dfId, $$$DMPOSUNDEFINED, $$$DMROLEUNDEFINED, $$$DMSCOREUNDEFINED, 1, 0, sc)
	    if $$$ISERR(sc) { set dictTermId = -1  quit }

	    // add to DI terms list
	  	set ^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId)=$g(^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId))_$lb(dictTermId)
		tcommit
   		
   		// BDB624 - trigger customizations
   		set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE), 1:"")
   		if (tTablesPackage'="") && $classmethod(tTablesPackage_".DictionaryTerm","%HasCustomizations") {
	   		set tSC = $classmethod(tTablesPackage_".DictionaryTerm", "%BuildCustomFields", dictTermId, dictTermId)
	   		quit:$$$ISERR(tSC)
	   		set tSC = $classmethod(tTablesPackage_".DictionaryTerm", "%BuildCustomIndices", 0, dictTermId, dictTermId)
	   		quit:$$$ISERR(tSC)
   		}
	} catch(ex) {
		set sc = ex.AsStatus(), dictTermId = -1
	}
	trollback:($tlevel>tTLevel) 1

    quit dictTermId
}

///  Creates a Dictionary Element
/// NOTE: if $$$IKPSTANDARDIZEDFORM="Stem", the input is assumed to be stemmed already
ClassMethod CreateDictionaryElement(domainId As %Integer, type As %String = {$$$DETERM}, dictTermId As %Integer, value As %String, position As %Integer = {$$$DMPOSUNDEFINED}, role As %Integer = {$$$DMROLEUNDEFINED}, matchScore As %Integer = {$$$DMSCOREUNDEFINED}, nbOfEntries As %Integer = -1, useTransaction As %Boolean = 1, elementWeight As %Numeric = 1, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set sc = $$$OK, tTLevel = $tlevel
	//$$$CHECKDOMAINEXISTSR(domainId,sc,-1) // not required for Internal methods
	$$$IKCHECKIDEXISTSR(^IRIS.IK.Mat.DictTermId,domainId,+dictTermId,dictTerm,$$$IKDictTermDoesNotExist,sc,-1)
	
	try {
		tstart:useTransaction
	    // derive dictId
	    set dictId = $list(dictTerm, 1)

	    set dictElementId = $i(^IRIS.IK.Mat.DictElementId(domainId))

	    // derive the number of entries if not specified
	    if (nbOfEntries = -1) {
	        set elems = $g(^IRIS.IK.Mat.DictTermElems(domainId, dictTermId))
	        set nbOfEntries = $listlength(elems)+1
	        for i = 1:1:(nbOfEntries-1) {
	            set $list(^IRIS.IK.Mat.DictElementId(domainId, $list(elems, i)), 8) = nbOfEntries
	        }
	    }

	    // store in the other DE-based globals
	    if (type = $$$DETERM) {
        
	        // treat case sensitivity
	        //$$$IKCONVERTMATCHINGCASE(domainId,value)
	        set value = $$$IKNORMALIZED(value,domainId)
	        set tStandardizedForm = $$$GETPARAMNODEF(domainId,$$$IKPMATSTANDARDIZEDFORM)
	        if (tStandardizedForm'="") && (tStandardizedForm'=$$$IKPMATSTANDARDIZEDFORMSTEMMING) {
	        	set value = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(value, $lg($$$IKLANGUAGES, $lg(dictTerm,4)), tStandardizedForm)
	        }
        	
        	set deStringId = ..GetDictElemStringId(domainId, value)
        	
	        set ^IRIS.IK.Mat.DictElement(domainId, deStringId, dictElementId) = dictId
	        set ^IRIS.IK.Mat.DictElementId(domainId, dictElementId) = $lb(+dictId, +dictTermId, type, deStringId, +position, +role, +matchScore, nbOfEntries)
        
	    } else {
		    set dictFormatId = value
	        set ^IRIS.IK.Mat.DictFormatElements(domainId, dictFormatId, dictElementId) = dictId
	        set ^IRIS.IK.Mat.DictElementId(domainId, dictElementId) = $lb(+dictId, +dictTermId, type, dictFormatId, +position, +role, +matchScore, nbOfEntries)
	    	set ^IRIS.IK.Mat.DictToFormat(domainId, dictId, dictFormatId) = "" 
	    }
	    
	    // we only store weights if they're not equal to 1 to save space
	    if (elementWeight'=1) {
		    set $list(^IRIS.IK.Mat.DictElementId(domainId, dictElementId), 9) = elementWeight
	    }
        
	    set ^IRIS.IK.Mat.DictTermElems(domainId, dictTermId) = $g(^IRIS.IK.Mat.DictTermElems(domainId, dictTermId)) _ $lb(dictElementId)
		tcommit:useTransaction
	} catch(ex) {
		set sc = ex.AsStatus(), dictElementId = -1
	}
	trollback:($tlevel>tTLevel) 1

    quit dictElementId
}

Parameter GetDictionariesRT = "dictId:%Integer,name:%String,description:%String,defaultLanguage:%String";

///  Returns all Dictionaries in this domain.
///  If <var>pIncludeCrossDomain</var> = 1, any cross-domain dictionaries registered in "domain 0"
///  are also included in the result, using a negative value for their ID.
ClassMethod GetDictionaries(ByRef result, domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, pIncludeCrossDomain As %Boolean = 0) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    if (domainId'=0) {
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
    }
    if 'domainId {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
    } elseif (pIncludeCrossDomain) {
	    $$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
	    $$$IKXDOMDICTCOMPATIBLEX(xDomVersion,$$$IKVERSION(domainId),tSC)
	}

	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)

    set dictId = ""
    for {
        set dictId = $order(^IRIS.IK.Mat.DictId(domainId, dictId), 1, d)
        quit:dictId=""
            
        set i = i+1
        $$$IKCHECKPAGING(usePaging,first,last,i)
                                
        $$$IKQADDRESULT(result,i,$lb(+dictId) _ $li(d,1,2) _ $lb($li($$$IKLANGUAGES,$li(d,3))))
    }

	if (pIncludeCrossDomain && domainId) {
	    set dictId = ""
	    for {
	        set dictId = $order(^IRIS.IK.Mat.DictId(0, dictId), 1, d)
	        quit:dictId=""
	            
	        set i = i+1
	        $$$IKCHECKPAGING(usePaging,first,last,i)
	                                
	        $$$IKQADDRESULT(result,i,$lb(-dictId) _ $li(d,1,2) _ $lb($li($$$IKLANGUAGES,$li(d,3))))
	    }
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetDictionaryItemsRT = "dictItemId:%Integer,name:%String,URI:%String,defaultLanguage:%String";

///  Returns all Dictionary Items for the given Dictionary ID.
ClassMethod GetDictionaryItems(ByRef result, domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    if (domainId'=0) {
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
    } else {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
	}
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mat.DictId,domainId,+dictId,dictInfo,$$$IKDictionaryDoesNotExist,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)

    set diId = ""
    for {
        set diId = $order(^IRIS.IK.Mat.DictToItem(domainId, dictId, diId))
        quit:diId=""
        
            
	    set i = i+1
	    $$$IKCHECKPAGING(usePaging,first,last,i)
	        
        set d = ^IRIS.IK.Mat.DictItemId(domainId, diId)
        $$$IKQADDRESULT(result,i,$lb(+diId) _ $li(d,2,3) _ $lb($li($$$IKLANGUAGES,$li(d,4))))
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetDictionaryItemsAndTermsRT = "dictItemId:%Integer,name:%String,URI:%String,dictTermId:%Integer,string:%String,language:%String,isProcessed:%Boolean";

///  Returns all Dictionary Items and their Terms for the given Dictionary ID.
ClassMethod GetDictionaryItemsAndTerms(ByRef result, domainId As %Integer, dictId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    if (domainId'=0) {
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
    } else {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
	}
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mat.DictId,domainId,+dictId,dictInfo,$$$IKDictionaryDoesNotExist,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)

    set diId = ""
    for {
        set diId = $order(^IRIS.IK.Mat.DictToItem(domainId, dictId, diId))
        quit:diId=""
        
        set di = $lb(+diId) _ $li(^IRIS.IK.Mat.DictItemId(domainId, diId),2,3)
        set terms = $g(^IRIS.IK.Mat.DictItemTerms(domainId, diId))
        continue:terms=""
        
        set ptr = 0
        while ($listnext(terms, ptr, dtId)) {
            
	        set i = i+1
	        $$$IKCHECKPAGING(usePaging,first,last,i)
	        
            set d = ^IRIS.IK.Mat.DictTermId(domainId,dtId)
            $$$IKQADDRESULT(result,i,di _ $lb(dtId, $li(d,3), $s($ld(d,4,l)&&l:$li($$$IKLANGUAGES,l),1:""), $lg(d,5)=$$$DTPROCESSED))
        }
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetDictionaryTermsByItemRT = "dictTermId:%Integer,string:%String,language:%String,isProcessed:%Boolean";

///  Returns all the Dictionary Terms for the given Dictionary Item ID.
ClassMethod GetDictionaryTermsByItem(ByRef result, domainId As %Integer, dictItemId As %Integer, page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
    if (domainId'=0) {
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
    } else {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
	}
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mat.DictItemId,domainId,+dictItemId,details,$$$IKDictItemDoesNotExist,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)
	set ptr = 0, terms = $g(^IRIS.IK.Mat.DictItemTerms(domainId, dictItemId))
	while ($listnext(terms, ptr, dtId)) {
		set i = i+1
		$$$IKCHECKPAGING(usePaging,first,last,i)
		
		set d = ^IRIS.IK.Mat.DictTermId(domainId,dtId)
		$$$IKQADDRESULT(result,i,$lb(dtId, $li(d,3), $s($ld(d,4,l)&&l:$li($$$IKLANGUAGES,l),1:""), $lg(d,5)=$$$DTPROCESSED))
	}
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter DropAllDictionaryDataEXP [ Internal ] = 1;

/// Drops all dictionary data, including matching results. 
/// This method will fail if there are managed dictionaries in this domain.
ClassMethod DropAllDictionaryData(domainId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		if (domainId'=0) {
			$$$CHECKDOMAINEXISTSX(domainId,tSC)
			$$$IKCHECKDOMMGRX(domainId,tSC)
	    } else {
			$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
		}
		
		// BDB385 - check manager class
		set tDictId = ""
		for {
			set tDictId = $order(^IRIS.IK.Mat.DictId(domainId,tDictId), 1, tDictInfo)
			quit:tDictId=""
			
			set tMgrClass = $lg(^IRIS.IK.Mat.DictId(domainId,tDictId),5)
			$$$IKCHECKMGRX("Dictionary",tDictId,tMgrClass,tSC)
		}
		quit:$$$ISERR(tSC)
		
		if (domainId) {
			set tSC = ##class(%iKnow.Matching.MatchingAPI).InvalidateMatchingResults(domainId,"",2)
		} else {
			set tXDictIds = ##class(%iKnow.Matching.MatchingAPI).GetAllDictsAsList(0)
			set tDomainId = ""
			for {
				set tDomainId = $order(^IRIS.IK.Mat.DictMatchStatus(tDomainId))
				quit:tDomainId=""
				continue:'tDomainId
				
				set tSC = ##class(%iKnow.Matching.MatchingAPI).InvalidateMatchingResults(tDomainId,tXDictIds,1)
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		set tGlobs = $lb(
	        "^IRIS.IK.Mat.DictId",
	        "^IRIS.IK.Mat.Dict",
	        "^IRIS.IK.Mat.DictToItem",
	        "^IRIS.IK.Mat.DictItemId",
	        "^IRIS.IK.Mat.DictItemURI",
	        "^IRIS.IK.Mat.DictItemTerms",
	        "^IRIS.IK.Mat.DictTermId",
	        "^IRIS.IK.Mat.DictTermElems",
	        "^IRIS.IK.Mat.DictElementId",
	        "^IRIS.IK.Mat.DictElement",
	        "^IRIS.IK.Mat.DictElemString",
	        "^IRIS.IK.Mat.DictElemStringId",
	        "^IRIS.IK.Mat.DictFormatId",
	        "^IRIS.IK.Mat.DictFormat",
	        "^IRIS.IK.Mat.DictFormatElements",
	        "^IRIS.IK.Mat.DictToFormat",
	        "^IRIS.IK.Mat.DictMatchStatus"
	    )
	    set ptr = 0
	    while $listnext(tGlobs,ptr,tGlob) {
		    kill @tGlob@(domainId)
	    }
	    
	    // BDB385 - also kill root node with cross-domain version info
	    zkill:'domainId ^IRIS.IK.Mat.DictId
	    
	    // BDB624 - purge custom indices
		set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE),1:"")
		if (tTablesPackage'="") {
			do $classmethod(tTablesPackage_".Dictionary", "%PurgeIndices")
			do $classmethod(tTablesPackage_".DictionaryItem", "%PurgeIndices")
			do $classmethod(tTablesPackage_".DictionaryTerm", "%PurgeIndices")
		}
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns whether or not a given Dictionary Term <var>pTermId</var> contains at least one
/// Dictionary Format element.
ClassMethod ContainsFormat(pDomainId As %Integer, pTermId As %Integer, Output pSC As %Status = {$$$OK}) As %Boolean [ Internal ]
{
	set pSC = $$$OK, tContainsFormat = 0
	try {
		//$$$CHECKDOMAINEXISTSX(pDomainId,pSC) // internal, so don't check
		set tElems = $g(^IRIS.IK.Mat.DictTermElems(pDomainId, pTermId)), ptr = 0
		while $listnext(tElems,ptr,tElemId) {
			if ($lg($g(^IRIS.IK.Mat.DictElementId(pDomainId,tElemId)),3)=$$$DEFORMAT) {
				set tContainsFormat = 1
				quit
			}
		}
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tContainsFormat
}

Parameter GetTermElementsRT [ Internal ] = "dictElemId:%Integer,type:%Integer,valueId:%Integer,value:%String,position:%Integer,role:%Integer,minMatchScore:%Numeric,scoreMultiplier:%Numeric";

/// Retrieves the elements corresponding to a given <var>pDictionaryTermId</var>.
ClassMethod GetTermElements(ByRef pResult, pDomainId As %Integer, pDictionaryTermId As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(pResult,"",tSC)
    if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
    } else {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
	}
	
	set ptr=0, tElems=$g(^IRIS.IK.Mat.DictTermElems(pDomainId, pDictionaryTermId))
	while $listnext(tElems,ptr,tElemId) {
		set tElem = $g(^IRIS.IK.Mat.DictElementId(pDomainId, tElemId))
		if ($li(tElem,3)=$$$DETERM) {
			set tValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId,$li(tElem,4))
		} else {
			set tSC = ..GetFormatDetails(pDomainId, $li(tElem,4), .tClass, .tParams)
			quit:$$$ISERR(tSC)
			set tValue = tClass_"["_$lts(tParams)_"]"
		}
		set tData = $lb(tElemId) _ $li(tElem,3,4) _ $lb(tValue) _ $li(tElem,5,7) _ $lb($lg(tElem,9,1))
		$$$IKQADDRESULT(pResult,$i(tCount),tData)
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

/// Retrieves the Dictionary format class and parameters for a given <var>pDictionaryFormatId</var>
ClassMethod GetFormatDetails(pDomainId As %Integer, pDictionaryFormatId As %Integer, Output pFormatClass As %String, Output pFormatParams As %List) As %Status
{
	$$$IKCHECKPRIVREAD
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTS(pDomainId)
	} else {
		$$$IKXDOMDICTVERSION(xDomVersion)
	}
	set tFormat = $g(^IRIS.IK.Mat.DictFormatId(pDomainId, +pDictionaryFormatId))
	set pFormatClass = $g(^IRIS.IK.Sys.DictFormatD(+$lg(tFormat,1)))
	set pFormatParams = $lg(tFormat,2)
	quit $$$OK
}

ClassMethod GetDictionaryCount(pDomainId As %Integer, Output pSC As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("",pSC,-1)
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSR(pDomainId,pSC,-1)
    } else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,pSC,-1)
	}
	
	set tDictId = "", tCount=0
	for {
		set tDictId = $order(^IRIS.IK.Mat.DictId(pDomainId,tDictId))
		quit:tDictId=""
		set x = $i(tCount)
	}
	$$$IKQEND("",tCount)
}

ClassMethod GetItemCount(pDomainId As %Integer, pDictIds As %List = "", Output pSC As %Status) As %Integer
{
	$$$IKQBEGINR("",pSC,-1)
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSR(pDomainId,pSC,-1)
    } else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,pSC,-1)
	}
	
	$$$IKENSURELISTABS(pDictIds)
	set tCount=0
	if pDictIds'="" {
		set ptr=0
		while $listnext(pDictIds,ptr,tDictId) {
			set tDictItemId = ""
			for {
				set tDictItemId = $order(^IRIS.IK.Mat.DictToItem(pDomainId, tDictId, tDictItemId))
				quit:tDictItemId=""
				set x = $i(tCount)
			}
		}
	} else {
		set tDictItemId = ""
		for {
			set tDictItemId = $order(^IRIS.IK.Mat.DictItemId(pDomainId,tDictItemId))
			quit:tDictItemId=""
			set x = $i(tCount)
		}
	}
	$$$IKQEND("",tCount)
}

ClassMethod GetTermCount(pDomainId As %Integer, pDictIds As %List = "", Output pSC As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("",pSC,-1)
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSR(pDomainId,pSC,-1)
    } else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,pSC,-1)
	}
	
	$$$IKENSURELISTABS(pDictIds)
	set tDictTermId="", tCount=0
	for {
		set tDictTermId = $order(^IRIS.IK.Mat.DictTermId(pDomainId,tDictTermId),1,tTerm)
		quit:tDictTermId=""
		continue:(pDictIds'="")&&'$lf(pDictIds,$li(tTerm,1))
		set x = $i(tCount)
	}
	$$$IKQEND("",tCount)
}

ClassMethod GetTermCountByItem(pDomainId As %Integer, pDictItemIds As %List = "", Output pSC As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("",pSC,-1)
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSR(pDomainId,pSC,-1)
    } else {
		$$$IKXDOMDICTVERSIONR(xDomVersion,pSC,-1)
	}
	
	$$$IKENSURELISTABS(pDictItemIds)
	
	set tDictTermId = "", tCount = 0
	for {
		set tDictTermId = $order(^IRIS.IK.Mat.DictTermId(pDomainId,tDictTermId),1,tTerm)
		quit:tDictTermId=""
		continue:(pDictItemIds'="")&&'$lf(pDictItemIds,$li(tTerm,2))
		set x = $i(tCount)
	}
	$$$IKQEND("",tCount)
}

Parameter GetItemsByNameRT = "dictId:%Integer,dictName:%String,itemId:%Integer,itemName:%String,URI:%String,language:%String";

/// Note: <var>pFilter</var> is ignored when looking at cross-domain dictionaries
ClassMethod GetItemsByName(ByRef pResult, pDomainId As %Integer, pString As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pDictIds As %List = "", pMode As %Integer = {$$$USEPARTS}, pCheck As %String(VALUELIST="NAME,URI") = "NAME", pLang As %String = "en") As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.Items,^||%IK.Matches",tSC)
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	} else {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
		set pFilter=""
	}
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	$$$IKENSURELISTABS(pDictIds)
	
	set pString = $$$IKNORMALIZED(pString,pDomainId)
	set tUseStandardizedForm = $$$GETPARAMNODEF(pDomainId,$$$IKPMATSTANDARDIZEDFORM)
	set:tUseStandardizedForm'="" pString = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(pString, pLang, tUseStandardizedForm)
	
	set tStringLength = $length(pString)
	
	if $isobject(pFilter) && (pFilter.Selectivity<0.1) {
		
		set tOff=""
		for {
			set tOff = pFilter.GetNextSourceFilterOffset(tOff, .tBits)
			quit:tOff=""
			
			set tPos=0
			for {
				set tPos = $bitfind(tBits,1,tPos+1)
				quit:'tPos
				$$$IKGETIDOFFPOS(tSrcId,tOff,tPos)
				merge ^||%IK.Matches = ^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId)
			}
		}
		
		set tMatchId=""
		for {
			set tMatchId = $order(^||%IK.Matches(tMatchId))
			quit:tMatchId=""
			
			set ^||%IK.Items($li(^IRIS.IK.Mat.MatchId(pDomainId,tMatchId),2))= ""
		}
		
		set tItemId=""
		for {
			set tItemId = $order(^||%IK.Items(tItemId))
			quit:tItemId=""
			
			set tItem = ^IRIS.IK.Mat.DictItemId(pDomainId, tItemId)
			continue:(pDictIds'="")&&'$lf(pDictIds,$li(tItem,1))
			
			set tItemName = $li(tItem, $case(pCheck, "NAME":2, "URI":3))
			set tItemLang = $lg($$$IKLANGUAGES,$lg(tItem,4))
			set tItemName = $$$IKNORMALIZEDL(tItemName,pDomainId,tItemLang)
			set:(tUseStandardizedForm'="")&&(pCheck="NAME") tItemName = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(tItemName, $lg(tItem,4,pLang), tUseStandardizedForm)
			if (pMode=$$$USENGRAMS) {
				continue:'$find(tItemName,pString)
			} else {
				set tPos = $find(tItemName,pString)
				continue:'tPos
				continue:$zstrip($e(tItemName,tPos-tStringLength-1),"*PWC")'=""
				continue:(pMode=$$$USEWORDS)&&($zstrip($e(tItemName,tPos),"*PWC")'="")
			}
			
			set x = $i(tCount)
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			$$$IKQADDRESULT(pResult,tCount,$lb($li(tItem,1),$li(^IRIS.IK.Mat.DictId(pDomainId,$li(tItem,1))),+tItemId)_$li(tItem,2,4))
		}
		
	} else {
		
		set tItemId = ""
		for {
			set tItemId = $order(^IRIS.IK.Mat.DictItemId(pDomainId,tItemId),1,tItem)
			quit:tItemId=""
			
			continue:(pDictIds'="")&&'$lf(pDictIds,$li(tItem,1))
			
			set tItemName = $li(tItem, $case(pCheck, "NAME":2, "URI":3))
			set tItemLang = $lg($$$IKLANGUAGES,$lg(tItem,4))
			set tItemName = $$$IKNORMALIZEDL(tItemName,pDomainId,tItemLang)
			set:(tUseStandardizedForm'="")&&(pCheck="NAME") tItemName = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(tItemName, $lg(tItem,4,pLang), tUseStandardizedForm)
			if (pMode=$$$USENGRAMS) {
				continue:'$find(tItemName,pString)
			} else {
				set tPos = $find(tItemName,pString)
				continue:'tPos
				continue:$zstrip($e(tItemName,tPos-tStringLength-1),"*PWC")'=""
				continue:(pMode=$$$USEWORDS)&&($zstrip($e(tItemName,tPos),"*PWC")'="")
			}
			
			if $isobject(pFilter) {
				set tItems(tItemId) = tItem
			} else {
				set x = $i(tCount)
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb($li(tItem,1),$li(^IRIS.IK.Mat.DictId(pDomainId,$li(tItem,1))),+tItemId)_$li(tItem,2,4))
			}
		}
		quit:'$isobject(pFilter)
		
		set tItemId="" 
		for {
			set tItemId=$order(tItems(tItemId),1,tItem)
			quit:tItemId=""
			
			set tMatchId=""
			for {
				set tMatchId = $order(^IRIS.IK.Mat.DictItemToMatch(pDomainId,tItemId,tMatchId))
				quit:tMatchId=""
				
				set tMatch = ^IRIS.IK.Mat.MatchId(pDomainId,tMatchId)
				set tTargetType = $li(tMatch,4), tTargetId = $li(tMatch,5)
				set tSrcId = ##class(%iKnow.Matching.MatchingAPI).GetSourceIdForMatchTarget(pDomainId,tTargetType,tTargetId)
				continue:'pFilter.IsFiltered(tSrcId)
				
				set x = $i(tCount)
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb($li(tItem,1),$li(^IRIS.IK.Mat.DictId(pDomainId,$li(tItem,1))),+tItemId)_$li(tItem,2,4))
				quit
			}
		}
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.Items,^||%IK.Matches",tSC)
}

Parameter GetTermsByNameRT = "dictId:%Integer,dictName:%String,itemId:%Integer,itemName:%String,URI:%String,termId:%Integer,term:%String,language:%String";

/// Note: <var>pFilter</var> is ignored when looking at cross-domain dictionaries
ClassMethod GetTermsByName(ByRef pResult, pDomainId As %Integer, pString As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pDictIds As %List = "", pMode As %Integer = {$$$USEPARTS}, pLang As %String = "en") As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.Items,^||%IK.Matches,^||%IK.Terms",tSC)
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
		$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	} else {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
		set pFilter=""
	}
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	$$$IKENSURELISTNUM(pDictIds)
	
	set pString = $$$IKNORMALIZED(pString,pDomainId)
	set tUseStandardizedForm = $$$GETPARAMNODEF(pDomainId,$$$IKPMATSTANDARDIZEDFORM)
	set:tUseStandardizedForm'="" pString = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(pString, pLang, tUseStandardizedForm)
	
	set tStringLength = $length(pString)
	
	if $isobject(pFilter) && (pFilter.Selectivity<0.1) {
		
		set tOff=""
		for {
			set tOff = pFilter.GetNextSourceFilterOffset(tOff, .tBits)
			quit:tOff=""
			
			set tPos=0
			for {
				set tPos = $bitfind(tBits,1,tPos+1)
				quit:'tPos
				$$$IKGETIDOFFPOS(tSrcId,tOff,tPos)
				merge ^||%IK.Matches = ^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId)
			}
		}
		
		set tMatchId=""
		for {
			set tMatchId = $order(^||%IK.Matches(tMatchId))
			quit:tMatchId=""
			
			set ^||%IK.Terms($li(^IRIS.IK.Mat.MatchId(pDomainId,tMatchId),3))= ""
		}
		
		set tTermId=""
		for {
			set tTermId = $order(^||%IK.Terms(tTermId))
			quit:tTermId=""
			
			set tTerm = ^IRIS.IK.Mat.DictTermId(pDomainId, tTermId)
			set tDictId=$li(tTerm,1), tItemId=$li(tTerm,2)
			continue:(pDictIds'="")&&'$lf(pDictIds,tDictId)
			
			set tTermLang = $lg($$$IKLANGUAGES,$lg(tTerm,4))
			set tTermName = $$$IKNORMALIZEDL($li(tTerm, 3),pDomainId,tTermLang)
			set:(tUseStandardizedForm'="") tTermName = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(tTermName, $lg(tTerm,4,pLang), tUseStandardizedForm)
			if (pMode=$$$USENGRAMS) {
				continue:'$find(tTermName,pString)
			} else {
				set tPos = $find(tTermName,pString)
				continue:'tPos
				continue:$zstrip($e(tTermName,tPos-tStringLength-1),"*PWC")'=""
				continue:(pMode=$$$USEWORDS)&&($zstrip($e(tTermName,tPos),"*PWC")'="")
			}
			
			set x = $i(tCount)
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			$$$IKQADDRESULT(pResult,tCount,$lb(tDictId,$li(^IRIS.IK.Mat.DictId(pDomainId,tDictId)),tItemId)_$li(^IRIS.IK.Mat.DictItemId(pDomainId,tItemId),2,3)_$lb(+tTermId)_$li(tTerm,2,4))
		}
		
	} else {
		
		set tTermId = ""
		for {
			set tTermId = $order(^IRIS.IK.Mat.DictTermId(pDomainId,tTermId),1,tTerm)
			quit:tTermId=""
			
			set tDictId=$li(tTerm,1), tItemId=$li(tTerm,2)
			continue:(pDictIds'="")&&'$lf(pDictIds,tDictId)
			
			set tTermLang = $lg($$$IKLANGUAGES,$lg(tTerm,4))
			set tTermName = $$$IKNORMALIZEDL($li(tTerm, 3),pDomainId,tTermLang)
			set:(tUseStandardizedForm'="") tTermName = ##class(%iKnow.Matching.MatchingAPI).StandardizedForm(tTermName, $lg(tTerm,4,pLang), tUseStandardizedForm)
			if (pMode=$$$USENGRAMS) {
				continue:'$find(tTermName,pString)
			} else {
				set tPos = $find(tTermName,pString)
				continue:'tPos
				continue:$zstrip($e(tTermName,tPos-tStringLength-1),"*PWC")'=""
				continue:(pMode=$$$USEWORDS)&&($zstrip($e(tTermName,tPos),"*PWC")'="")
			}
			
			if $isobject(pFilter) {
				set tTerms(tTermId) = tTerm
			} else {
				set x = $i(tCount)
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb(tDictId,$li(^IRIS.IK.Mat.DictId(pDomainId,tDictId)),tItemId)_$li(^IRIS.IK.Mat.DictItemId(pDomainId,tItemId),2,3)_$lb(+tTermId)_$li(tTerm,2,4))
			}
		}
		quit:'$isobject(pFilter)
		
		set tTermId="" 
		for {
			set tTermId=$order(tTerms(tTermId),1,tTerm)
			quit:tTermId=""
			
			set tMatchId="", tDictId=$li(tTerm,1), tItemId=$li(tTerm,2)
			for {
				set tMatchId = $order(^IRIS.IK.Mat.DictItemToMatch(pDomainId,tItemId,tMatchId))
				quit:tMatchId=""
				
				set tMatch = ^IRIS.IK.Mat.MatchId(pDomainId,tMatchId)
				continue:$li(tMatch,3)'=tTermId
				set tTargetType = $li(tMatch,4), tTargetId = $li(tMatch,5)
				set tSrcId = ##class(%iKnow.Matching.MatchingAPI).GetSourceIdForMatchTarget(pDomainId,tTargetType,tTargetId)
				continue:'pFilter.IsFiltered(tSrcId)
				
				set x = $i(tCount)
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb(tDictId,$li(^IRIS.IK.Mat.DictId(pDomainId,tDictId)),tItemId)_$li(^IRIS.IK.Mat.DictItemId(pDomainId,tItemId),2,3)_$lb(+tTermId)_$li(tTerm,2,4))
				quit
			}
		}
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

/// Returns an identifier for the string value <var>pString</var> of a dictionary element.
/// If this string exists as a real Unique Entity, the corresponding entUniId is returned. 
/// Otherwise, the string is added to ^IRIS.IK.Mat.DictElemStringId (if it didn't exist already)
/// and the corresponding dictElemStringId is returned.
/// In either case, a lookup entry in ^IRIS.IK.Mat.DictElemString is added if it didn't exist already.
ClassMethod GetDictElemStringId(pDomainId As %Status, pString As %String, Output pSC As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set pSC = $$$OK, tDEStringId = ""
	try {
		set tIndex = " "_pString
		
		if pDomainId && $d(^IRIS.IK.EntUni(pDomainId, tIndex), tDEStringId) {
			set:'$d(^IRIS.IK.Mat.DictElemString(pDomainId, tIndex)) ^IRIS.IK.Mat.DictElemString(pDomainId, tIndex) = tDEStringId
			quit
		}
		
		set tDEStringId = $g(^IRIS.IK.Mat.DictElemString(pDomainId, tIndex))
		quit:tDEStringId
		
		$$$IKLOCKX(pDomainId,^IRIS.IK.Mat.DictElemStringId,pSC)
		set tDEStringId = $g(^IRIS.IK.Mat.DictElemString(pDomainId, tIndex))
		quit:tDEStringId
		
		set tTLevel = $tlevel
		try {
			tstart
			set tDEStringId = $i(^IRIS.IK.Mat.DictElemStringId(pDomainId))
			set ^IRIS.IK.Mat.DictElemStringId(pDomainId, tDEStringId) = pString
			set ^IRIS.IK.Mat.DictElemString(pDomainId, tIndex) = -tDEStringId
			tcommit
		} catch (ex) {
			set pSC = ex.AsStatus()
		}
		trollback:($tlevel>tTLevel) 1
		
		set tDEStringId = -tDEStringId
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	$$$IKUNLOCK(pDomainId,^IRIS.IK.Mat.DictElemStringId)
	
	quit tDEStringId
}

}
