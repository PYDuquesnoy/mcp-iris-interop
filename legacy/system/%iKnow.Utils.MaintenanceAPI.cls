/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

///  <p>This API groups a number of utility and maintenance operations and queries.</p>
Class %iKnow.Utils.MaintenanceAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

///  <p>Adds a string as a new entity to the domain with frequency and spread equal to 0, returning the
///  ID of the new entity. If the string already exists as an entity in the domain, this method will
///  simply return its ID.</p>
///  <p><var>pLanguage</var> is only used when this domain is enabled for stemming.</p>
///  <p>Note: This method is intended for internal use only.</p>
ClassMethod AddEntity(domainId As %Integer, value As %String, Output sc As %Status = {$$$OK}, pLanguage As %String = "en") As %Integer [ Internal ]
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	$$$IKCHECKDOMMGRR(domainId,sc,-1)
	
	// normalize value
	set value = $system.iKnow.Normalize(value,domainId,,,.sc)
	quit:$$$ISERR(sc)
	
	// first check if the entity already exists
	if ($length(value)>$$$IKHASHSIZE) {
		set entUniId = "", hash = $zcrc(value,7)
		for {
			set entUniId = $order(^IRIS.IK.EntUniHash(domainId, hash, entUniId))
			quit:entUniId=""
			quit:(value=^IRIS.IK.EntUniId(domainId,entUniId))
		}
		set entUniId=+entUniId
	} else {
		set entUniId = +$g(^IRIS.IK.EntUni(domainId, " "_value))
	}
	quit:entUniId entUniId
	
	// we should lock for LOAD, as that's the lock taken by BuildGlobals' EntUni additions
	$$$IKLOCKLOADR(domainId,sc,-1)
	
	// test again, it might have been added between the first check and the lock
	if ($length(value)>$$$IKHASHSIZE) {
		set entUniId = "", hash = $zcrc(value,7)
		for {
			set entUniId = $order(^IRIS.IK.EntUniHash(domainId, hash, entUniId))
			quit:entUniId=""
			quit:(value=^IRIS.IK.EntUniId(domainId,entUniId))
		}
		set entUniId=+entUniId
	} else {
		set entUniId = +$g(^IRIS.IK.EntUni(domainId, " "_value))
	}
	if (entUniId) {
		$$$IKUNLOCKLOAD(domainId)
		quit entUniId
	}
	
	set tTLevel = $tlevel
	try {
		tstart
    
		set entUniId = $i(^IRIS.IK.EntUniId(domainId))
		set ^IRIS.IK.EntUniId(domainId, entUniId) = value
		set ^IRIS.IK.EntUniDetails(domainId, entUniId) = $lb(0,0,0,0,0,0,0)
		$$$MARKDATALOADED(domainId)
		
		if ($length(value)>$$$IKHASHSIZE) {
			set ^IRIS.IK.EntUniHash(domainId, $zcrc(value,7), entUniId) = ""
		} else {
			set ^IRIS.IK.EntUni(domainId, " "_value) = entUniId
		}
		
		// BDB522 - update stemming data
		if $$$GETPARAMNODEF(domainId,$$$IKPSTEMMING) {
			set tLangId = $lf($$$IKLANGUAGES, pLanguage)
			if 'tLangId {
				set tSC = $$$ERROR($$$IKLanguageDoesNotExist,pLanguage)
				quit
			}
			set tStemmed = ##class(%iKnow.Queries.EntityAPI).GetStem(domainId,value, pLanguage, .tSC)
			quit:$$$ISERR(tSC)
			if tStemmed=value {
				set tStemUniId = entUniId
			} else {
				set tStemUniId = ..AddEntity(domainId, tStemmed, .tSC)
				quit:$$$ISERR(tSC)
			}
			set $bit(^IRIS.IK.EntUniActual(domainId,tStemUniId,entUniId),tLangId)=1
			set $bit(^IRIS.IK.EntUniBase(domainId,entUniId,tStemUniId),tLangId)=1
			
			// verify if this is a new representation form
			set tCurrentRepId = $g(^IRIS.IK.EntUniRep(domainId,tStemUniId,tLangId))
			if ((tCurrentRepId '= "") && (tCurrentRepId'=tStemUniId)) {
				set tCurrentRepString = ^IRIS.IK.EntUniId(domainId,tCurrentRepId)
				set tCurrentDist = ##class(%iKnow.Queries.EntityAPI).GetLevenshteinDistance(tCurrentRepString,tStemmed,.tSC,domainId)
				quit:$$$ISERR(tSC)
				set tNewDist = ##class(%iKnow.Queries.EntityAPI).GetLevenshteinDistance(value,tStemmed,.tSC,domainId)
				quit:$$$ISERR(tSC)
				if (tCurrentDist > tNewDist) {
					set ^IRIS.IK.EntUniRep(domainId,tStemUniId,tLangId) = entUniId
				}
			}
		}
	
		tcommit
	} catch (e) {
		set sc = e.AsStatus(), entUniId = -1
	}
	trollback:($tlevel>tTLevel) 1
		
	$$$IKUNLOCKLOAD(domainId)
	
	quit entUniId
}

///  <p>Create a new SkipList with the given name and description</p>
ClassMethod CreateSkipList(domainId As %Integer, name As %String, description As %String = "", Output sc As %Status = {$$$OK}) As %Integer
{
	quit ..CreateSkipListInternal(domainId, name, description,, .sc)
}

ClassMethod CreateBlackList(domainId As %Integer, name As %String, description As %String = "", Output sc As %Status = {$$$OK}) As %Integer [ Deprecated, Internal ]
{
	quit ..CreateSkipList(domainId, name, description, .sc)
}

ClassMethod CreateSkipListInternal(domainId As %Integer, name As %String, description As %String = "", mgrClass As %String = "", Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set sc = $$$OK
	$$$IKCHECKPRIVWRITER(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
		$$$IKCHECKDOMMGRR(domainId,sc,-1)
	} else {
		$$$IKXDOMBLVERSIONR(xDomVersion,sc,-1)
	}
	$$$IKCHECKNOTNULLR(name,sc,-1)
	$$$IKCHECKSTRINGLENGTHR(name,sc,-1)
	
	// BDB397 - case insensitive names
	set tNameIndex = $s('domainId||$$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(name), 1:name)
	$$$IKCHECKIDNOTEXISTSR(^IRIS.IK.BlackList,domainId,tNameIndex,$$$IKSkipListExists,sc,-1)
	
	$$$IKLOCKR(domainId,^IRIS.IK.BlackListId,sc,-1)
	
	// check again, somebody might have added a BL with this name in the meantime
	if $d(^IRIS.IK.BlackList(domainId, tNameIndex)) {
		$$$IKUNLOCK(domainId,^IRIS.IK.BlackListId)
		set sc = $$$ERROR($$$IKSkipListExists, name)
		quit -1
	}
	
	set tTLevel = $tlevel
	try {
		tstart
		set skipListId = $i(^IRIS.IK.BlackListId(domainId))
		set ^IRIS.IK.BlackListId(domainId, skipListId) = $lb(name, description, mgrClass)
		set ^IRIS.IK.BlackList(domainId, tNameIndex) = skipListId
		
		// BDB386 - store version info for cross-domain SkipLists
		set:'domainId ^IRIS.IK.BlackListId = xDomVersion
		
		tcommit
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	
	$$$IKUNLOCK(domainId,^IRIS.IK.BlackListId)
	
	quit skipListId
}

Parameter DropSkipListEXP [ Internal ] = 1;

///  Drops a SkipList (entities part of the list will not be deleted from the domain)
ClassMethod DropSkipList(domainId As %Integer, skipListId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTS(domainId)
		$$$IKCHECKDOMMGR(domainId)
	} else {
		$$$IKXDOMBLVERSION(xDomainVersion)
	}
	$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist)
	
	// BDB386 - check SkipList manager
	set tMgrClass = $lg(details,5)
	$$$IKCHECKMGR("SkipList",skipListId,tMgrClass)
	
	$$$IKLOCK(domainId,^IRIS.IK.BlackListId)
	set tTLevel = $tlevel
	try {
		tstart
		kill ^IRIS.IK.BlackListElements(domainId, skipListId)
		kill ^IRIS.IK.BlackList(domainId, $$$UPPER($li(details,1)))
		kill ^IRIS.IK.BlackListId(domainId, skipListId)
		
		// BDB386 - if this was the last cross-domain one, drop version info
		if 'domainId && ($d(^IRIS.IK.BlackListId(0))<10) {
			zkill ^IRIS.IK.BlackListId
		}
		
		tcommit
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	$$$IKUNLOCK(domainId,^IRIS.IK.BlackListId)
	quit $$$OK
}

ClassMethod DropBlackList(domainId As %Integer, blackListId As %Integer) As %Status [ Deprecated, Internal ]
{
	quit ..DropSkipList(domainId, blackListId)
}

Parameter ClearSkipListEXP [ Internal ] = 1;

/// Clears the contents of a single SkipList.
ClassMethod ClearSkipList(pDomainId As %Integer, pSkipListId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	
	if (pDomainId'=0) {
		$$$CHECKDOMAINEXISTS(pDomainId)
		$$$IKCHECKDOMMGR(pDomainId)
	} else {
		$$$IKXDOMBLVERSION(xDomainVersion)
	}
	$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,pDomainId,pSkipListId,tDetails,$$$IKSkipListDoesNotExist)
	
	// BDB386 - check SkipList manager
	set tMgrClass = $lg(tDetails,5)
	$$$IKCHECKMGR("SkipList",pSkipListId,tMgrClass)
	
	kill ^IRIS.IK.BlackListElements(pDomainId,pSkipListId)
	
	quit $$$OK
}

ClassMethod ClearBlackList(pDomainId As %Integer, pSkipListId As %Integer) As %Status [ Deprecated, Internal ]
{
	quit ..ClearSkipList(pDomainId, pSkipListId)
}

///  Finds the SkipList ID corresponding to the supplied name.
ClassMethod GetSkipListId(domainId As %Integer, name As %String, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	} else {
		$$$IKXDOMBLVERSIONR(xDomainVersion,sc,-1)
	}
	$$$IKCHECKSTRINGLENGTHR(name,sc,-1)
	
	// BDB397 - case insensitive names
	set tNameIndex = $s('domainId||$$$IKVERSIONATLEAST(domainId,$$$IKVERSIONCASEINSENSITIVENAMES):$$$UPPER(name), 1:name)
	quit $g(^IRIS.IK.BlackList(domainId, tNameIndex))
}

ClassMethod GetBlackListId(domainId As %Integer, name As %String, Output sc As %Status = {$$$OK}) As %Integer [ Deprecated, Internal ]
{
	quit ..GetSkipListId(domainId, name, .sc)
}

/// Returns whether or not there are any SkipLists in the domain
ClassMethod HasSkipLists(pDomainId As %Integer) As %Boolean
{
	quit ($d(^IRIS.IK.BlackListId(pDomainId))>=10)
}

ClassMethod HasBlackLists(pDomainId As %Integer) As %Boolean [ Deprecated, Internal ]
{
	quit ..HasSkipLists(pDomainId)
}

Parameter GetSkipListsRT = "skipListId:%Integer,name:%String,description:%String";

///  Retrieves a list of all the SkipLists registered in this domain.
ClassMethod GetSkipLists(ByRef result, domainId As %Integer, pIncludeCrossDomain As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
	}
    if ('domainId || pIncludeCrossDomain) {
	    $$$IKXDOMBLVERSIONX(xDomVersion,tSC)
	}
	
	set skipListId = "", i = 0
	for {
		set skipListId = $order(^IRIS.IK.BlackListId(domainId, skipListId),1,d)
		quit:skipListId=""
		$$$IKQADDRESULT(result,$i(i),$lb(+skipListId) _ $li(d,1,2))
	}
	
	if (pIncludeCrossDomain && domainId) {
		set skipListId = ""
		for {
			set skipListId = $order(^IRIS.IK.BlackListId(0, skipListId),1,d)
			quit:skipListId=""
			$$$IKQADDRESULT(result,$i(i),$lb(-skipListId) _ $li(d,1,2))
		}
	}
	$$$IKQENDCATCH(result,"",tSC)
}

ClassMethod GetBlackLists(ByRef result, domainId As %Integer, pIncludeCrossDomain As %Boolean = 0) As %Status [ Deprecated, Internal ]
{
	quit ..GetSkipLists(.result, domainId, pIncludeCrossDomain)
}

Parameter GetSkipListElementsRT = "entUniId:%Integer,entity:%String";

///  Retrieves a list of all the strings in the specified SkipList
ClassMethod GetSkipListElements(ByRef result, domainId As %Integer, skipListId As %Integer) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
	} else {
		$$$IKXDOMBLVERSIONX(xDomVersion,tSC)
	}
	$$$IKCHECKIDEXISTSX(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist,tSC)
	set entUniId = "", i=0
	for {
		set entUniId = $order(^IRIS.IK.BlackListElements(domainId, skipListId, entUniId),1,d)
		quit:entUniId=""
		
		if (domainId) {
			$$$IKQADDRESULT(result,$i(i),$lb(+entUniId, ^IRIS.IK.EntUniId(domainId, entUniId)))
		} else {
			$$$IKQADDRESULT(result,$i(i),$lb("",entUniId))
		}
	}
	$$$IKQENDCATCH(result,"",tSC)
}

ClassMethod GetBlackListElements(ByRef result, domainId As %Integer, blackListId As %Integer) As %Status [ Deprecated, Internal ]
{
	quit ..GetSkipListElements(.result, domainId, blackListId)
}

/// Returns whether or not the SkipList identified by <var>skipListId</var> contains the
/// supplied entity.
ClassMethod SkipListContainsElement(domainId As %Integer, skipListId As %Integer, entUniId As %Integer, Output pSC As %Status = {$$$OK}) As %Boolean
{
	set pSC = $$$OK
	$$$IKCHECKPRIVREADR(pSC,0)
	if (skipListId>0) {
		$$$CHECKDOMAINEXISTSR(domainId,pSC,0)
		set tDomainId = domainId
	} else {
		$$$IKXDOMBLVERSION(xDomVersion)
		set entUniId = ##class(%iKnow.Queries.EntityAPI).GetValue(domainId, entUniId)
		quit:entUniId<=0 0
		set domainId=0, skipListId=$zabs(skipListId)
	}
	$$$IKCHECKIDEXISTSR(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist,pSC,0)
	quit $data(^IRIS.IK.BlackListElements(domainId,skipListId,entUniId))
}

ClassMethod BlacklistContainsElement(domainId As %Integer, blackListId As %Integer, entUniId As %Integer, Output pSC As %Status = {$$$OK}) As %Boolean [ Deprecated, Internal ]
{
	quit ..SkipListContainsElement(domainId, blackListId, entUniId, .sc)
}

/// Returns whether or not the SkipList identified by <var>skipListId</var> contains the
/// supplied entity.
ClassMethod SkipListContainsString(domainId As %Integer, skipListId As %Integer, entity As %String, Output pSC As %Status = {$$$OK}) As %Boolean
{
	set pSC = $$$OK
	$$$IKCHECKPRIVREADR(pSC,0)
	if (skipListId>0) {
		$$$CHECKDOMAINEXISTSR(domainId,pSC,0)
		set tDomainId = domainId
		set entity = ##class(%iKnow.Queries.EntityAPI).GetId(domainId, entity)
	} else {
		$$$IKXDOMBLVERSION(xDomVersion)
		$$$IKCHECKSTRINGLENGTH(entity)
		set domainId=0, skipListId=$zabs(skipListId)
	}
	$$$IKCHECKIDEXISTSR(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist,pSC,0)
	quit $data(^IRIS.IK.BlackListElements(domainId,skipListId,entity))
}

ClassMethod BlacklistContainsString(domainId As %Integer, blackListId As %Integer, entity As %String, Output pSC As %Status = {$$$OK}) As %Boolean [ Deprecated, Internal ]
{
	quit ..SkipListContainsString(domainId, blackListId, entity, .pSC)
}

Parameter AddEntityToSkipListEXP [ Internal ] = 1;

///  Adds an existing entity (by ID) to a SkipList.
/// For cross-domain SkipLists, use <method>AddStringToSkipList</method>
ClassMethod AddEntityToSkipList(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	$$$CHECKDOMAINEXISTS(domainId)
	$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist)
	
	// BDB386 - check SkipList manager
	set tMgrClass = $lg(details,5)
	$$$IKCHECKMGR("SkipList",skipListId,tMgrClass)
	
	set ^IRIS.IK.BlackListElements(domainId, skipListId, entUniId) = ""
	quit $$$OK
}

ClassMethod AddEntityToBlackList(domainId As %Integer, blackListId As %Integer, entUniId As %Integer) As %Status [ Deprecated, Internal ]
{
	quit ..AddEntityToSkipList(domainId, blackListId, entUniId)
}

Parameter AddStringToSkipListEXP [ Internal ] = 1;

///  Adds a string to a SkipList, adding it as an entity if it didn't exist in the domain before.
ClassMethod AddStringToSkipList(domainId As %Integer, skipListId As %Integer, string As %String) As %Status
{
	$$$IKCHECKPRIVWRITE
	$$$IKCHECKNOTNULL(string)
	if (domainId'=0) {
		set entUniId = ..AddEntity(domainId, string, .tSC)
		quit:$$$ISERR(tSC) tSC
		quit ..AddEntityToSkipList(domainId, skipListId, entUniId)
	} else {
		$$$IKXDOMBLVERSION(xDomVersion)
		$$$IKCHECKSTRINGLENGTH(string)
		$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,0,$zabs(skipListId),details,$$$IKSkipListDoesNotExist)
		
		// BDB386 - check SkipList manager
		set tMgrClass = $lg(details,5)
		$$$IKCHECKMGR("SkipList",skipListId,tMgrClass)
		
		set ^IRIS.IK.BlackListElements(0, $zabs(skipListId), string) = ""
		quit $$$OK
	}
}

ClassMethod AddStringToBlackList(domainId As %Integer, blackListId As %Integer, string As %String) As %Status [ Deprecated, Internal ]
{
	quit ..AddStringToSkipList(domainId, blackListId, string)
}

Parameter RemoveEntityFromSkipListEXP [ Internal ] = 1;

///  Removes an entity (by ID) from a SkipList (but not from the domain)
/// For cross-domain SkipLists, use <method>RemoveStringFromSkipList</method>
ClassMethod RemoveEntityFromSkipList(domainId As %Integer, skipListId As %Integer, entUniId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	$$$CHECKDOMAINEXISTS(domainId)
	$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist)
	
	// BDB386 - check SkipList manager
	set tMgrClass = $lg(details,5)
	$$$IKCHECKMGR("SkipList",skipListId,tMgrClass)
	
	kill ^IRIS.IK.BlackListElements(domainId, skipListId, entUniId)
	quit $$$OK
}

ClassMethod RemoveEntityFromBlackList(domainId As %Integer, blackListId As %Integer, entUniId As %Integer) As %Status [ Deprecated, Internal ]
{
	quit ..RemoveEntityFromSkipList(domainId, blackListId, entUniId)
}

Parameter RemoveStringFromSkipListEXP [ Internal ] = 1;

///  Removes a string from a SkipList (but not from the domain)
ClassMethod RemoveStringFromSkipList(domainId As %Integer, skipListId As %Integer, string As %String) As %Status
{
	$$$IKCHECKPRIVWRITE
	if (domainId'=0) {
		$$$CHECKDOMAINEXISTS(domainId)
		$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,domainId,skipListId,details,$$$IKSkipListDoesNotExist)
		
		// BDB386 - check SkipList manager
		set tMgrClass = $lg(details,5)
		$$$IKCHECKMGR("SkipList",skipListId,tMgrClass)
		
		set entUniId = +##class(%iKnow.Queries.EntityAPI).GetId(domainId, string)
		quit:entUniId<=0
		kill ^IRIS.IK.BlackListElements(domainId, skipListId, entUniId)
		quit $$$OK
	} else {
		$$$IKXDOMBLVERSION(xDomVersion)
		$$$IKCHECKSTRINGLENGTH(string)
		$$$IKCHECKIDEXISTS(^IRIS.IK.BlackListId,0,$zabs(skipListId),details,$$$IKSkipListDoesNotExist)
		
		// BDB386 - check SkipList manager
		set tMgrClass = $lg(details,5)
		$$$IKCHECKMGR("SkipList",skipListId,tMgrClass)
	
		kill ^IRIS.IK.BlackListElements(0, $zabs(skipListId), string)
		quit $$$OK
	}
}

ClassMethod RemoveStringFromBlackList(domainId As %Integer, blackListId As %Integer, string As %String) As %Status [ Deprecated, Internal ]
{
	quit ..RemoveStringFromSkipList(domainId, blackListId, string)
}

ClassMethod GetStemId(pDomainId As %Integer, pEntId As %Integer, vSrcId As %Integer = 0) As %Integer [ Internal ]
{
	set entIdList = $listbuild(pEntId)
	kill ids
	set i = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(pDomainId,entIdList,.ids,vSrcId,0,2)
	set stemId = ""
	set stemId = $o(ids(stemId))
	quit stemId
}

/// Internal method building the required data structures for runtime SkipList use.
ClassMethod BuildSkipList(pDomainId As %Integer, pSkipListSpec As %String, vSrcId As %Integer = 0, pUseStem = 0) [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKCLEANSKIPLIST
		set ^||%IK.SkipLists=0
		quit:(pSkipListSpec="")
		set ^||%IK.SkipLists=1 
		
		// if this is a SQL query
		if ($e(pSkipListSpec,1,6)="SELECT") {
			
			#dim tResult As %SQL.StatementResult
			set tStatement = ##class(%SQL.Statement).%New()
			set tSC = tStatement.%Prepare(pSkipListSpec)
			quit:$$$ISERR(tSC)
			
			// check if this is really a SELECT statement
			if (tStatement.%Metadata.statementType'=1) {
				set tSC = $$$ERROR($$$GeneralError, "Only regular SELECT statements are supported for populating SkipLists")
				quit
			}
			
			// derive column to fetch
			set tHasIDs = $d(tStatement.%Metadata.columnIndex("ENTUNIID"),tColInfo)
			if (tHasIDs) {
				set tColNumber = $lg(tColInfo,1)
			} elseif $d(tStatement.%Metadata.columnIndex("ENTITY"),tColInfo) {
				set tColNumber = $lg(tColInfo,1)
			} elseif $d(tStatement.%Metadata.columnIndex("ENTITYVALUE"),tColInfo) {
				set tColNumber = $lg(tColInfo,1)
			} elseif $d(tStatement.%Metadata.columnIndex("VALUE"),tColInfo) {
				set tColNumber = $lg(tColInfo,1)
			} else {
				set tColNumber = 1
			}
			
			if 'tHasIDs {
				kill ^||%IKT.SkipListStrings
				$$$IKSORTBEGIN(^||%IKT.SkipListStrings)
			}
			
			set tResult = tStatement.%Execute()
			while tResult.%Next() {
				if tHasIDs {
					set tEntUniId = tResult.%GetData(tColNumber)
					set:tEntUniId ^||%IK.SkipLists(tEntUniId)=""
				} else {
					set tStringValue = tResult.%GetData(tColNumber)
					continue:(tStringValue="")||($l(tStringValue)>$$$IKHASHSIZE)
					set ^||%IKT.SkipListStrings(" "_tStringValue)=""
				}
			}
			quit:tHasIDs
			
			set x = $sortend(^||%IKT.SkipListStrings)
			set tStringValue=""
			for {
				set tStringValue = $order(^||%IKT.SkipListStrings(tStringValue))
				quit:tStringValue=""
				continue:'$d(^IRIS.IK.EntUni(pDomainId,tStringValue),tEntUniId)
				if (pUseStem) && ($d(^IRIS.IK.StemUniId(pDomainId)))  
				{
					set tStemId = ..GetStemId(pDomainId,tEntUniId) 
					set ^||%IK.SkipLists(tStemId)=""
				}
				else
				{
					set ^||%IK.SkipLists(tEntUniId)=""
				} 	
			}
			
		} else { 
		
			// regular ID or list of IDs
			$$$IKENSURELISTNUM(pSkipListSpec)
			
			set ptr=0  
			while $listnext(pSkipListSpec,ptr,tSkipListId) {
				continue:'tSkipListId 
				set tBLDomainId = $s((tSkipListId<0):0, 1:pDomainId), tSkipListId=$zabs(tSkipListId) 
				continue:'$d(^IRIS.IK.BlackListElements(tBLDomainId, tSkipListId))  
				if ('vSrcId && tBLDomainId) { 
					if (pUseStem) && ($d(^IRIS.IK.StemUniId(tBLDomainId))){
						set tBLEntId = ""
						for{
							set tBLEntId = $o(^IRIS.IK.BlackListElements(tBLDomainId,tSkipListId,tBLEntId),1,val)
							quit:tBLEntId=""
							set stemId = ..GetStemId(tBLDomainId,tBLEntId)
							if stemId '= ""{
								set ^||%IK.SkipLists(stemId) = "" 
							}
						}
					}
					else
					{
						merge ^||%IK.SkipLists = ^IRIS.IK.BlackListElements(tBLDomainId, tSkipListId)
					}
					//
				} else {
					merge tSkipListElements = ^IRIS.IK.BlackListElements(tBLDomainId, tSkipListId)
					set e="" 
					for {
						set (e,tEntUniId) = $o(tSkipListElements(e),1,tValue) 
						quit:e=""
						
						// for cross-domain BLs, the subscript is the string value
						if 'tBLDomainId { set tEntUniId = $g(^IRIS.IK.EntUni(pDomainId," "_e))  continue:'tEntUniId }
						if (pUseStem) && ($d(^IRIS.IK.StemUniId(pDomainId))){
							set tEntUniId = ..GetStemId(pDomainId,tEntUniId)
						}
						
						// for virtual sources, we still need to translate to actual entity IDs
						if vSrcId { set tEntUniId = $g(^IRIS.IKV.RealEntUniMap(tBLDomainId,vSrcId,e))  continue:'tEntUniId }
						if (pUseStem) && ($d(^IRIS.IK.StemUniId(tBLDomainId))){
							set tEntUniId = ..GetStemId(tBLDomainId,tEntUniId,vSrcId)
						}
						
						set ^||%IK.SkipLists(tEntUniId) = tValue 
					} 
				} 
			} 
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IKT.SkipListStrings
	if $$$ISERR(tSC) $$$ThrowStatus(tSC)
}

///  <p>This method creates a User Dictionary with a given <var>name</var> and optional <var>description</var> and
///  returns the created user dictionary ID afterwards. This method will return -1 if an error occurred,
///  which is passed by reference as <var>sc</var>.</p>
///  <p><b>Deprecated</b>: please use %New() in <class>%iKnow.UserDictionary</class></p>
ClassMethod CreateUserDictionary(name As %String, description As %String = "", Output sc As %Status) As %Integer [ Deprecated ]
{
	set sc = $$$OK
	$$$IKCHECKNOTNULLR(name,sc,-1)
	$$$IKCHECKSTRINGLENGTHR(name,sc,-1)
	
	set tUserDict = ##class(%iKnow.UserDictionary).%New(name,description)
	
	if tUserDict="" {
		set sc = %objlasterror
		quit -1
	}
	
	set sc = tUserDict.%Save()
	quit:$$$ISERR(sc) -1
	
	quit tUserDict.Id
}

Parameter DropUserDictionaryEXP [ Internal ] = 1;

///  This method drops the User Dictionary identified by the supplied <var>userDictId</var>,
///  including all its entries.
///  <p><b>Deprecated</b>: please use %DeleteId() in <class>%iKnow.UserDictionary</class></p>
ClassMethod DropUserDictionary(userDictId As %Integer) As %Status [ Deprecated ]
{
	quit ##class(%iKnow.UserDictionary).%DeleteId(userDictId)
}

///  Returns the ID corresponding to the supplied User Dictionary <var>name</var>.
///  <p><b>Deprecated</b>: please use NameIndexOpen() <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaryId(name As %String) As %Integer [ Deprecated ]
{
	set tUserDict = ##class(%iKnow.UserDictionary).NameIndexOpen(name)
	quit:tUserDict="" ""
	quit tUserDict.Id
}

Parameter GetUserDictionariesRT = "userDictId:%Integer,name:%String,description:%String";

///  Returns a list of all the User Dictionaries in this namespace.
///  <p><b>Deprecated</b>: please use <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaries(ByRef result) As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	
	set id = ""
	for {
		set id = $order(^IRIS.IK.Sys.UserDictD(id),1,tData)
		quit:id=""
		$$$IKQADDRESULT(result,$i(i),$lb(id)_tData)
	}
	
	$$$IKQENDCATCH(restult,"",tSC)
}

Parameter AddUserDictionaryEntryEXP [ Internal ] = 1;

///  <p>Adds a single entry to a User Dictionary at <var>position</var>. If <var>position</var> <= 0 (default),
///  it is added at the bottom of the list, otherwise at the requested position, shifting
///  existing entries down if it was already taken.</p>
///  <p><b>Deprecated</b>: please use AddEntry() in <class>%iKnow.UserDictionary</class></p>
ClassMethod AddUserDictionaryEntry(userDictId As %Integer, rewriteFrom As %String, rewriteTo As %String, ByRef position As %Integer = 0) As %Status [ Deprecated ]
{
	set tUserDict = ##class(%iKnow.UserDictionary).%OpenId(userDictId)
	quit:tUserDict="" $$$ERROR($$$IKNoUserDictWithId, userDictId)
	
	quit tUserDict.AddEntry(rewriteFrom, rewriteTo, position)
}

Parameter RemoveUserDictionaryEntryEXP [ Internal ] = 1;

///  <p>Removes the User Dictionary entry registered at <var>position</var>. This method will
///  not impact the order or position of any remaning entries.</p>
///  <p><b>Deprecated</b>: please use RemoveEntry() in <class>%iKnow.UserDictionary</class></p>
ClassMethod RemoveUserDictionaryEntry(userDictId As %Integer, position As %Integer) As %Status [ Deprecated ]
{
	set tUserDict = ##class(%iKnow.UserDictionary).%OpenId(userDictId)
	quit:tUserDict="" $$$ERROR($$$IKNoUserDictWithId, userDictId)
	
	quit tUserDict.RemoveEntry(position)
}

Parameter GetUserDictionaryEntriesRT = "position:%Integer,rewriteFrom:%String,rewriteTo:%String";

///  <p>Returns the contents of a User Dictionary.</p>
///  <p><b>Deprecated</b>: please use GetEntries() in <class>%iKnow.UserDictionary</class></p>
ClassMethod GetUserDictionaryEntries(ByRef result, userDictId As %Integer) As %Status [ Deprecated ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	
	set tUserDict = ##class(%iKnow.UserDictionary).%OpenId(userDictId)
	if (tUserDict="") { set tSC = $$$ERROR($$$IKNoUserDictWithId, userDictId) quit }
	
	set tSC = tUserDict.GetEntries(.tEntries)
	quit:$$$ISERR(tSC)
	
	set tPos = ""
	for {
		set tPos = $order(tEntries(tPos),1,tData)
		quit:tPos=""
		$$$IKQADDRESULT(result,$i(i),$lb(tPos)_tData)
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

}
