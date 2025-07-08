/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This utility class groups a few methods to easily copy the contents of a domain into
/// another one (which doens't necessarily have to be empty).</p>
/// <p>Please note any domain elements copied will be created using the version of the
/// target domain, regardless of the source domain's version number.</p>
Class %iKnow.Utils.CopyUtils Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// <p>Copies all contents from the domain named <var>pFromDomain</var> into the domain
/// <var>pToDomain</var>. If <var>pToDomain</var> does not yet exist, it will be created
/// automatically. The copy flags represent the following domain elements:
/// <ul>
///  	<li><var>pCopySources</var> includes regular source content as well as metadata (if 
/// 			the corresponding metadata fields exist in <var>pToDomain</var> or are created
/// 			through <var>pCopySettings</var>. 
/// 				See also <class>%iKnow.Source.Domain.Lister</class></li>
///  	<li><var>pCopySettings</var> includes domain parameters, metadata, LOVs and SkipLists</li>
///  	<li><var>pCopyDictionaries</var> includes dictionaries, their items and terms and
/// 			any domain-specific matching profiles. If <var>pMatchCopy</var> is 1 as well,
/// 			all sources in the target domain will be matched against all dictionaries.</li>
///  	<li><var>pCopySettings</var> includes domain parameters, metadata and SkipLists</li>
/// 		<li>if <var>pCopyMetrics</var>&gt;0, all metric definitions are copied and if 
/// 			<var>pCopyMetrics</var>&gt;1, all metric values are copied along</li>
/// </ul>
/// <p>This method relies on the other class methods in this class and uses a value of 1 for
/// pIgnoreDuplciates when calling these methods.</p>
/// <p>If required, a specific iKnow Configuration name (cf <class>%iKnow.Configuration</class>)
/// can be supplied through <var>pUseConfiguration</var> to use while re-indexing the data.
/// If this parameter is left blank (default), the default configuration of the original domain
/// (configured using the $$$IKPDEFAULTCONFIG domain parameter) or $$$DEFAULTCONFIG will be
/// used.</p>
/// <p><b>Note</b>: if <var>pCopySettings</var> is true, only domain parameters a user is allowed to modify
/// will be copied!!</p>
ClassMethod CopyDomain(pFromDomain As %String, pToDomain As %String, pCopySources As %Boolean = 1, pCopySettings As %Boolean = 1, pCopyDictionaries As %Boolean = 1, pMatchCopy As %Boolean = 1, pVerbose As %Boolean = 1, pUseConfiguration As %String = "", pCopyMetrics As %Integer = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tFromDomain = ##class(%iKnow.Domain).NameIndexOpen(pFromDomain, .tSC)
		quit:$$$ISERR(tSC)
		if (tFromDomain.GetParameter($$$IKPDEEPSEEDOMAIN)) {
			set tSC = $$$ERROR($$$GeneralError, "This feature is not supported for a DeepSee Domain")
			quit
		}
		
		if ##class(%iKnow.Domain).Exists(pToDomain) {
			set tToDomain = ##class(%iKnow.Domain).NameIndexOpen(pToDomain, .tSC)
		} else {
			set tToDomain = ##class(%iKnow.Domain).%New(pToDomain)
			set tSC = tToDomain.%Save()
		}
		quit:$$$ISERR(tSC)
		if (tToDomain.GetParameter($$$IKPDEEPSEEDOMAIN)) {
			set tSC = $$$ERROR($$$GeneralError, "This feature is not supported for a DeepSee Domain")
			quit
		}
		
		write:pVerbose !,$zdatetime($h),":  Copying from domain """,pFromDomain,""" (",tFromDomain.Id,") to domain """,pToDomain,""" (",tToDomain.Id,")"
		
		if (pCopySettings) {
			
			write:pVerbose !!,$zdatetime($h),":  Copying settings..."
			
			// start with domain parameters
			write:pVerbose !!,$zdatetime($h),":  Copying Domain parameters..."
			set tSC = tFromDomain.GetParameters(.tParams)
			quit:$$$ISERR(tSC)
			kill tPostponedParams
			set tParam = ""
			for {
				set tParam = $order(tParams(tParam),1,tParamValue)
				quit:tParam=""
				
				if '$$$IKALLOWUSERSET(tParam) {
					write !,$zdatetime($h),":  WARNING: parameter """,tParam,""" cannot be modified by end users and will not be copied."
					continue
				} elseif $$$IKONLYCHANGEWHENEMPTY(tParam) && 'tToDomain.IsEmpty() {
					write !,$zdatetime($h),":  WARNING: parameter """,tParam,""" can only be set on empty domains and will not be copied."
					continue
				} elseif (tParam=$$$IKPMATDEFAULTPROFILE) {
					// postpone these setting until other content has been copied
					set tPostponedParams(tParam) = tParamValue
					continue
				}
				
				set tSC = tToDomain.SetParameter(tParam, tParamValue)
				quit:$$$ISERR(tSC)
				write:pVerbose !,$zdatetime($h),":  	Copied domain parameter """,tParam,""": ",tParamValue
			}
			quit:$$$ISERR(tSC)
			
			// copy metadata field definitions and LOVs
			set tSC = ..CopyMetadataFields(tFromDomain.Id, tToDomain.Id, pVerbose, 1)
			quit:$$$ISERR(tSC)
			
			// and finally SkipLists
			set tSC = ..CopySkipLists(tFromDomain.Id, tToDomain.Id, pVerbose, 1)
			quit:$$$ISERR(tSC)
		}
		
		if (pCopySources) {
			set tSrcCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tFromDomain.Id)
			write:pVerbose !!,$zdatetime($h),":  Copying ",tSrcCount," sources..."
			
			// instantiate loader objects
			set tLoader = ##class(%iKnow.Source.Loader).%New(tToDomain.Id)
			set tLister = ##class(%iKnow.Source.Domain.Lister).%New(tToDomain.Id)
			
			// if supplied, use pUseConfiguration to override default configuration choices
			if (pUseConfiguration '= "") {
				set tSC = tLister.SetConfig(pUseConfiguration)
				quit:$$$ISERR(tSC)
			}
			
			// configure Processor if we need to copy metadata
			if (pCopySettings) {
				set tMetaFields = ""
				set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tResult, tFromDomain.Id)
				quit:$$$ISERR(tSC)
				set i = ""
				for {
					set i = $order(tResult(i),1,tField)
					quit:i=""
					set tMetaFields = tMetaFields _ $li(tField,2,2)
				}
				set tSC = tLister.SetProcessor("%iKnow.Source.Domain.Processor", $lb(tFromDomain.Id, tMetaFields))
				quit:$$$ISERR(tSC)
			}
			
			// schedule and launch batch
			set tSC = tLister.AddListToBatch(tFromDomain.Id)
			quit:$$$ISERR(tSC)
			set tSC = tLoader.ProcessBatch()
			quit:$$$ISERR(tSC)
			set tNewSrcCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tFromDomain.Id)
			write:pVerbose !,$zdatetime($h),":  	Copied ",tNewSrcCount," sources."
		}
		
		if (pCopyDictionaries) {
			set tSC = ..CopyDictionaries(tFromDomain.Id,tToDomain.Id, pVerbose, 1, 1)
			quit:$$$ISERR(tSC)
		}
		
		// resume copying of postponed parameters
		if (pCopySettings) {
			set tParam = ""
			for {
				set tParam = $order(tPostponedParams(tParam),1,tParamValue)
				quit:tParam=""
				
				set tSC = tToDomain.SetParameter(tParam, tParamValue)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
		if (pCopyDictionaries && pMatchCopy) {
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tToDomain.Id)
			quit:$$$ISERR(tSC)
		}
		
		if (pCopyMetrics) {
			set tSC = ..CopyMetrics(tFromDomain.Id, tToDomain.Id, (pCopyMetrics>1), pVerbose)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Copies any metadata field definitions and List of Values from the domain identified by ID
/// <var>pFromDomainId</var> into domain <var>pToDomainId</var>. If a field with the same
/// name already exists in the target domain, <var>pIgnoreDuplicates</var>=0 will cause an
/// error to be thrown, whereas <var>pIgnoreDuplicates</var>=1 will mean the metadata field
/// in the target domain will be left as is.</p> 
ClassMethod CopyMetadataFields(pFromDomainId As %Integer, pToDomainId As %Integer, pVerbose As %Boolean = 1, pIgnoreDuplicates As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		write:pVerbose !!,$zdatetime($h),":  Copying Metadata fields from domain ",pFromDomainId," to ",pToDomainId
		
		// Copy LOVs first
		kill tLovMap
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetLovs(.tResult, pFromDomainId)
		quit:$$$ISERR(tSC)
		set i=""
		for {
			set i = $order(tResult(i),1,tLov)
			quit:i=""
			
			set tLovId = ##class(%iKnow.Queries.MetadataAPI).AddListOfValues(pToDomainId, $li(tLov,2), $li(tLov,3), .tSC)
			quit:$$$ISERR(tSC)
			set tLovMap($li(tLov,1)) = tLovId
			
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetLovValues(.tLovValues, pFromDomainId, $li(tLov,1))
			quit:$$$ISERR(tSC)
			set j="", tCount = 0
			for {
				set j = $order(tLovValues(j),1,tValue)
				quit:j=""
				
				set tSC = ##class(%iKnow.Queries.MetadataAPI).AddLovValue(pToDomainId, tLovId, $li(tValue))
				quit:$$$ISERR(tSC)
				set x = $i(tCount)
			}
			
			write:pVerbose !,$zdatetime($h),":  	Copied LOV """,$li(tLov,2),""" with ",tCount," values"
		}
		quit:$$$ISERR(tSC)
		
		
		// copy 
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tResult, pFromDomainId, 1)
		quit:$$$ISERR(tSC)
		set i=""
		for {
			set i = $order(tResult(i),1,tField)
			quit:i=""
			
			set tFieldId = ##class(%iKnow.Queries.MetadataAPI).AddField(pToDomainId,$li(tField,2),$li(tField,3),$li(tField,4),$li(tField,5),$li(tField,6),$g(tLovMap($li(tField,7)),-1),$li(tField,8),$li(tField,9),.tSC)
			if $$$ISERR(tSC) {
				if ($system.Status.Equals(tSC,$$$ERRORCODE($$$IKMDFieldExists))) && pIgnoreDuplicates {
					write:pVerbose !,$zdatetime($h),":  	Metadata field """,$li(tField,2),""" already exists in target domain, skipping."
					set tSC = $$$OK
				} else {
					quit
				}
			} else {
				write:pVerbose !,$zdatetime($h),":  	Copied metadata field """,$li(tField,2),""""
			}
		}
		quit:$$$ISERR(tSC)
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Copies any SkipList definitions and their contents from the domain identified by ID
/// <var>pFromDomainId</var> into domain <var>pToDomainId</var>. If a SkipList with the same
/// name already exists in the target domain, <var>pIgnoreDuplicates</var>=0 will cause an
/// error to be thrown, whereas <var>pIgnoreDuplicates</var>=1 will mean the SkipList
/// in the target domain will be extended with the strings in the SkipList from the source
/// domain.</p> 
ClassMethod CopySkipLists(pFromDomainId As %Integer, pToDomainId As %Integer, pVerbose As %Boolean = 1, pIgnoreDuplicates As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		write:pVerbose !!,$zdatetime($h),":  Copying SkipLists from domain ",pFromDomainId," to ",pToDomainId
		
		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipLists(.tResult, pFromDomainId)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tResult(i), 1, tSkipList)
			quit:i=""
			
			set tSkipListName = $li(tSkipList,2)
			
			set tSkipListId = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(pToDomainId, tSkipListName)
			if (tSkipListId>0) {
				if (pIgnoreDuplicates) {
					write:pVerbose !,$zdatetime($h),":  	SkipList """,tSkipListName,""" already exists, appending contents"
				} else {
					set tSC = $$$ERROR($$$IKSkipListExists, tSkipListName)
					quit
				}
			} else {
				set tSkipListId = ##class(%iKnow.Utils.MaintenanceAPI).CreateSkipList(pToDomainId, tSkipListName, $li(tSkipList,3), .tSC)
				quit:$$$ISERR(tSC)
			}
			
			// copy SkipList contents
			set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListElements(.tElements, pFromDomainId, $li(tSkipList,1))
			quit:$$$ISERR(tSC)
			set j = ""
			for {
				set j = $order(tElements(j),1,tElement)
				quit:j=""
				
				set tSC = ##class(%iKnow.Utils.MaintenanceAPI).AddStringToSkipList(pToDomainId, tSkipListId, $li(tElement,2))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Copies any dictionaries and matching profiles (if <var>pCopyProfiles</var> is true)
/// from the domain identified by ID <var>pFromDomainId</var> into domain
/// <var>pToDomainId</var>. If a dictionary, item or profile with the same name already
/// exists, <var>pIgnoreDuplicates</var>=0 will cause an error to be thrown, whereas
/// <var>pIgnoreDuplicates</var>=1 will mean the element in the target domain will be left
/// as is, but extended with the items and terms of the element in the source domain.</p> 
ClassMethod CopyDictionaries(pFromDomainId As %Integer, pToDomainId As %Integer, pVerbose As %Boolean = 1, pIgnoreDuplicates As %Boolean = 1, pCopyProfiles As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		if (pCopyProfiles) {
			write:pVerbose !!,$zdatetime($h),":  Copying Matching Profiles from domain ",pFromDomainId," to ",pToDomainId
			kill tProfileMap
			set tStatement = ##class(%SQL.Statement).%New()
			set tSC = tStatement.%Prepare("SELECT ProfileId FROM %iKnow_Matching.MatchingProfile WHERE DomainId = ?")
			quit:$$$ISERR(tSC)
			set tResult = tStatement.%Execute(pFromDomainId)
			while (tResult.%Next(.tSC)) {
				quit:$$$ISERR(tSC)
				set tProfileId = tResult.%GetData(1)
				set tSC = ..CopyMatchingProfile(pFromDomainId, pToDomainId, tProfileId, pVerbose, .tNewProfileId)
				quit:$$$ISERR(tSC)
				set tProfileMap(tProfileId) = tNewProfileId
			}
			quit:$$$ISERR(tSC)
			kill tResult, tStatement
		}
		
		write:pVerbose !!,$zdatetime($h),":  Copying Dictionaries from domain ",pFromDomainId," to ",pToDomainId
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaries(.tResult, pFromDomainId, 0, 0)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tResult(i),1,tDict)
			quit:i=""
			
			set tSC = ..CopyDictionary(pFromDomainId, pToDomainId, $li(tDict,1), pVerbose, pIgnoreDuplicates, .tProfileMap)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Copies a single dictionary (identified by <var>pDictionaryId</var>
/// from the domain identified by ID <var>pFromDomainId</var> into domain
/// <var>pToDomainId</var>. If a dictionary or item with the same name already
/// exists, <var>pIgnoreDuplicates</var>=0 will cause an error to be thrown, whereas
/// <var>pIgnoreDuplicates</var>=1 will mean the element in the target domain will be left
/// as is, but extended (in the case of a dictionary or item) with the items and terms of
/// the element in the source domain.</p> 
/// <p>An array of matching profile IDs can be passed in through <var>pProfileMap</var> to
/// map any default matching profiles from the source domain to IDs of the corresponding
/// profiles in the target domain.</p>
ClassMethod CopyDictionary(pFromDomainId As %Integer, pToDomainId As %Integer, pDictionaryId As %Integer, pVerbose As %Boolean = 1, pIgnoreDuplicates As %Boolean = 1, ByRef pProfileMap = "") As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		set tDictionary = ##class(%iKnow.Objects.Dictionary).PKINDEXOpen(pFromDomainId, pDictionaryId)
		if (tDictionary="") {
			set tSC = $$$ERROR($$$IKDictionaryDoesNotExist, pDictionaryId)
			quit
		}
		
		write:pVerbose !,$zdatetime($h),":  	Copying Dictionary """,tDictionary.Name,""" from domain ",pFromDomainId," to ",pToDomainId
		
		set tNewDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(pToDomainId, tDictionary.Name)
		if (tNewDictId) {
			if (pIgnoreDuplicates) {
				write:pVerbose !,$zdatetime($h),":  		Dictionary """,tDictionary.Name,""" already exists, adding contents"
			} else {
				set tSC = $$$ERROR($$$IKDictExists, tDictionary.Name)
				quit
			}
		} else {
			set tProfileId = $g(pProfileMap(+tDictionary.DefaultProfileId))
			if tDictionary.DefaultProfileId && 'tProfileId {
				write !,$zdatetime($h),":  		WARNING: The default profile of Dictionary """,tDictionary.Name,""" was not found in the target domain"
			}
			set tNewDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(pToDomainId, tDictionary.Name, tDictionary.Description, $s(tDictionary.DefaultLanguage="":"en", 1:tDictionary.DefaultLanguage), tProfileId, .tSC)
			quit:$$$ISERR(tSC)
		}
		
		// now process contents
		set tItemCount=0, tTermCount=0
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItems(.tItems, pFromDomainId, pDictionaryId, 0, 0)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tItems(i),1,tItem)
			quit:i=""
			
			set tItemId = $li(tItem,1)
			set tItemName = $li(tItem,2)
			set tItemURI = $li(tItem,3)
			set tItemLanguage = $li(tItem,4)
			
			set tNewItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(pToDomainId, tItemURI)
			if (tNewItemId>0) {
				if (pIgnoreDuplicates) {
					write:pVerbose !,$zdatetime($h),":  		Dictionary Item with URI """,tItemURI,""" already exists, appending terms"
				} else {
					set tSC = $$$ERROR($$$IKDictItemURIExists, tItemURI)
					quit
				}
			} else {
				set tNewItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(pToDomainId, tNewDictId, tItemName, tItemURI, tItemLanguage, .tSC)
				quit:$$$ISERR(tSC)
				set x = $i(tItemCount)
			}
			
			// now load terms
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryTermsByItem(.tTerms, pFromDomainId, tItemId, 0, 0)
			quit:$$$ISERR(tSC)
			set j = ""
			for {
				set j = $order(tTerms(j),1,tTerm)
				quit:j=""
				
				set tTermId = $li(tTerm,1)
				set tTermString = $li(tTerm,2)
				set tTermLanguage = $li(tTerm,3)
				
				// check for formats, as they need to be processed per element 
				if (##class(%iKnow.Matching.DictionaryAPI).ContainsFormat(pFromDomainId,tTermId)) {
					set tNewTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pToDomainId,tNewItemId,tTermString,tTermLanguage,.tSC, 1)
					quit:$$$ISERR(tSC)
					
					set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetTermElements(.tElems, pFromDomainId, tTermId)
					quit:$$$ISERR(tSC)
					set k = ""
					for {
						set k = $order(tElems(k),1,tElem)
						quit:k=""
						
						if ($li(tElem,2)=$$$DETERM) {
							set tValue = $li(tElem,4)
						} else {
							set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetFormatDetails(pFromDomainId, $li(tElem,3), .tFormatClass, .tFormatParams)
							quit:$$$ISERR(tSC)
							set tValue = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryFormat(pToDomainId, tFormatClass, tFormatParams, .tSC)
							quit:$$$ISERR(tSC)
						}
						do ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryElement(pToDomainId, $li(tElem,2), tNewTermId, tValue, $li(tElem,5), $li(tElem,6), $li(tElem,7),,,$li(tElem,8),.tSC)
						quit:$$$ISERR(tSC)
					}
					
				} else {
					set tNewTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pToDomainId,tNewItemId,tTermString,tTermLanguage,.tSC)
					quit:$$$ISERR(tSC)
				}
				set x = $i(tTermCount)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		write:pVerbose !,$zdatetime($h),":  	Copied Dictionary """,tDictionary.Name,""": ",tItemCount," items and ",tTermCount," terms"
		
		quit:$$$ISERR(tSC)
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Copies a single Matching Profile (identified by <var>pProfileId</var>) from the
/// domain identified by ID <var>pFromDomainId</var> into domain <var>pToDomainId</var>.
/// If a profile with the same name already exists in the target domain,
/// <var>pIgnoreDuplicates</var>=0 will cause an error to be thrown, whereas
/// <var>pIgnoreDuplicates</var>=1 will mean the metadata field in the target domain
/// will be left as is.</p> 
ClassMethod CopyMatchingProfile(pFromDomainId As %Integer, pToDomainId As %Integer, pProfileId As %Integer, pVerbose As %Boolean = 1, Output pNewProfileId As %Integer = 0) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		set tProfile = ##class(%iKnow.Matching.MatchingProfile).PKINDEXOpen(pFromDomainId,pProfileId)
		quit:tProfile=""
		
		set tNewProfile = ##class(%iKnow.Matching.MatchingProfile).%New(pToDomainId, tProfile.Name)
		set tSC = tNewProfile.ApplyProperties(tProfile)
		quit:$$$ISERR(tSC)
		set tSC = tNewProfile.%Save()
		quit:$$$ISERR(tSC)
		
		set pNewProfileId = tNewProfile.ProfileId
		
		write:pVerbose !,$zdatetime($h),":  	Copied Profile ",tProfile.Name," from domain ",pFromDomainId," to ",pToDomainId
		
		quit:$$$ISERR(tSC)
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Copies all metric definitions from one domain to another, optionally including their
/// 	values.</p>
/// <p>WARNING: only Entity-, CRC-, CC- and source-based metric data can be copied from one domain
/// to another. Use the metrics' builder class to (re-)generate metric values for path- or 
/// sentence-based metrics.</p>
ClassMethod CopyMetrics(pFromDomainId As %Integer, pToDomainId As %Integer, pCopyValues As %Boolean = 0, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		$$$IKTEMPDOMID(pToDomainId,tTempId)
		
		set tBatchCopy = pCopyValues && '($d(^IRIS.IK.Mtr.MetricId(pToDomainId))>1)
		
		// first copy metric definitions
		set tSC = ##class(%iKnow.Metrics.MetricAPI).GetMetrics(.tTargets, pFromDomainId)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tTargets(i),1,tData)
			quit:i=""
			
			set tSC = ..CopyMetric(pFromDomainId, pToDomainId, $li(tData,1),, pVerbose)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		quit:'pCopyValues
		
		write:pVerbose !,$zdatetime($h),":  	Copying Metric data from domain ",pFromDomainId," to ",pToDomainId
		
		$$$IKLOCKX(pToDomainId,^IRIS.IK.Mtr.MetricId,tSC)
		
		// now copy metric values using jobs
		// first set up parameters
		$$$SETMAXJOBS(tMaxJobs,pToDomainId,"Metrics",$system.Util.NumberOfCPUs(),tMaxJobsLimit)
		kill ^IRIS.Temp.IK.Mtr.Process(tTempId)
		kill ^IRIS.Temp.IK.Mtr.Ids(tTempId)
		kill ^IRIS.Temp.IK.Mtr.OffsetMap(tTempId)
		
		set ^IRIS.Temp.IK.Mtr.Ids(tTempId,$$$IKMTRENTITY) = 0
		set ^IRIS.Temp.IK.Mtr.Ids(tTempId,$$$IKMTRCRC) = 0
		set ^IRIS.Temp.IK.Mtr.Ids(tTempId,$$$IKMTRCC) = 0
		set ^IRIS.Temp.IK.Mtr.Ids(tTempId,$$$IKMTRSOURCE) = 0
		
		set tSC = ##class(%iKnow.Metrics.MetricAPI).GetMetrics(.tMetrics, pFromDomainId)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tMetrics(i), 1, tMetric)
			quit:i=""
			
			set tMetricId = $li(tMetric,1)
			set tOldMetric = ##class(%iKnow.Metrics.Metric).PKINDEXOpen(pFromDomainId, tMetricId)
			set tNewMetric = ##class(%iKnow.Metrics.Metric).NameIndexOpen(pToDomainId, tOldMetric.Name)
			continue:tNewMetric=""
			
			set tTarget = ""
			for {
				set tTarget = $order(^IRIS.IK.Mtr.MetricTarget(pFromDomainId, tMetricId, tTarget), 1, tFromOffset)
				quit:tTarget=""
				
				if (tTarget = $$$IKMTRPATH) || (tTarget = $$$IKMTRSENTENCE) {
					write:pVerbose !,$zdatetime($h),": WARNING 	Metric data for $$$IKMTRPATH and $$$IKMTRSENTENCE cannot be copied from one domain to another (metric: '"_tOldMetric.Name_"')"
				}
				
				set:'tBatchCopy ^IRIS.Temp.IK.Mtr.OffsetMap(tTempId, tOldMetric.Type, tTarget, tFromOffset) = ^IRIS.IK.Mtr.MetricTarget(pToDomainId, tNewMetric.MetricId, tTarget)
			}
		}
	
		if tMaxJobs <= 1 {
			
			set tSC = ..CopyMetricValuesJob(pFromDomainId, pToDomainId, tBatchCopy, 0)
			quit:$$$ISERR(tSC)
			
		} else {
			
			for i = 1:1:tMaxJobs {
				job ..CopyMetricValuesJob(pFromDomainId, pToDomainId, tBatchCopy, i)::10
				if '$test {
					set tSC = $$$ERROR($$$IKFailedJobStart)
					quit
				}
			}
			quit:$$$ISERR(tSC)
			
			// wait for jobs to complete
			while 1 {
				quit:($bitcount(^IRIS.Temp.IK.Mtr.Process(tTempId),1)=tMaxJobs)
				hang 1
			}
			for i = 1:1:tMaxJobs {
				set tSC = $g(^IRIS.Temp.IK.Mtr.Process(tTempId,i))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if pCopyValues {
		kill ^IRIS.Temp.IK.Mtr.Process(tTempId)
		kill ^IRIS.Temp.IK.Mtr.Ids(tTempId)
		kill ^IRIS.Temp.IK.Mtr.OffsetMap(tTempId)
		$$$IKUNLOCK(pToDomainId,^IRIS.IK.Mtr.MetricId)
	}
	quit tSC
}

/// <p>Internal method used by <method>CopyMetrics</method> to copy custom metric values from 
/// one domain to another through multiple jobs.</p>
/// <p>WARNING: only Entity-, CRC-, CC- and source-based metrics can be copied from one domain
/// to another!</p>
ClassMethod CopyMetricValuesJob(pFromDomainId As %Integer, pToDomainId As %Integer, pBatchCopy As %Boolean, pProcNumber As %Integer) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(pToDomainId,tTempId)
		
		// if not in batch copy, map old offsets to new offsets
		if ('pBatchCopy) {
			merge tOffsetMap = ^IRIS.Temp.IK.Mtr.OffsetMap(tTempId)
		}
		
		set x = $sortbegin(^IRIS.IK.Mtr.EntUniValues(pToDomainId))
		set x = $sortbegin(^IRIS.IK.Mtr.EntSrcValues(pToDomainId))
		set x = $sortbegin(^IRIS.IK.Mtr.CrcUniValues(pToDomainId))
		set x = $sortbegin(^IRIS.IK.Mtr.CrcSrcValues(pToDomainId))
		set x = $sortbegin(^IRIS.IK.Mtr.CcUniValues(pToDomainId))
		set x = $sortbegin(^IRIS.IK.Mtr.CcSrcValues(pToDomainId))
		set x = $sortbegin(^IRIS.IK.Mtr.SrcValues(pToDomainId))
	
		for tTarget = $$$IKMTRENTITY, $$$IKMTRCRC, $$$IKMTRCC, $$$IKMTRSOURCE {
			set tBatchSize = $s(tTarget=$$$IKMTRSOURCE:100, 1:4096) 
			set gTargetId = $case(tTarget, $$$IKMTRENTITY:"^IRIS.IK.Mtr.EntUniValues", $$$IKMTRCRC:"^IRIS.IK.Mtr.CrcUniValues",
									$$$IKMTRCC:"^IRIS.IK.Mtr.CcUniValues", $$$IKMTRSOURCE:"^IRIS.IK.SrcId")
			set tMaxId = $order(@gTargetId@(pFromDomainId,""),-1)
			
			while 1 {
				set tTo = $i(^IRIS.Temp.IK.Mtr.Ids(tTempId,tTarget),tBatchSize), tFrom = tTo-tBatchSize
				quit:tFrom>tMaxId
				
				set tId = tFrom-1
				for {
					set tId = $order(@gTargetId@(pFromDomainId,tId), 1, tData)
					quit:tId=""
					quit:tId>tTo
				
					kill tNewId
					if (tTarget = $$$IKMTRENTITY) {
						set tNewId = ##class(%iKnow.Queries.EntityAPI).GetId(pToDomainId, ^IRIS.IK.EntUniId(pFromDomainId,tId))
					} elseif (tTarget = $$$IKMTRCRC) {
						set tCrc = ^IRIS.IK.CrcUniId(pFromDomainId,tId)
						set tNewId(1) = $s('$li(tCrc,1):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCrc,1)))
						set tNewId(2) = $s('$li(tCrc,2):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCrc,2)))
						set tNewId(3) = $s('$li(tCrc,3):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCrc,3)))
						set tNewId = ##class(%iKnow.Queries.CrcAPI).GetId(pToDomainId,tNewId(1),tNewId(2),tNewId(3))
					} elseif (tTarget = $$$IKMTRCC) {
						set tCc = ^IRIS.IK.CcUniId(pFromDomainId,tId)
						set tNewId(1) = $s('$li(tCc,1):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCc,1)))
						set tNewId(2) = $s('$li(tCc,2):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCc,2)))
						set tNewId = ##class(%iKnow.Queries.CcAPI).GetId(pToDomainId,tNewId(1),tNewId(2))
					} elseif (tTarget = $$$IKMTRSOURCE) {
						set tExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(pFromDomainId, tId)
						set tNewId = ##class(%iKnow.Queries.SourceAPI).GetSourceId(pToDomainId,tExtId)
					}
					continue:tNewId<=0
					
					if (tTarget = $$$IKMTRSOURCE) {
						set tData = $g(^IRIS.IK.Mtr.SrcValues(pFromDomainId, tId))
					}
					
					if tData'="" {
						if pBatchCopy {
							if (tTarget = $$$IKMTRSOURCE) {
								set ^IRIS.IK.Mtr.SrcValues(pToDomainId, tNewId) = tData
							} else {
								set @gTargetId@(pToDomainId, tNewId) = tData
							}
						} else {
							set tNewData = $lb(), tLen = $ll(tData)
							for i=1:1:tLen {
								set $li(tNewData,tOffsetMap($$$IKMTRTYPEDOMAIN,tTarget,i)) = $li(tData,i)
							}
							if (tTarget = $$$IKMTRSOURCE) {
								set ^IRIS.IK.Mtr.SrcValues(pToDomainId, tNewId) = tData
							} else {
								set @gTargetId@(pToDomainId, tNewId) = tNewData
							}
						}
					}
					
					// if this is $$$IKMTRSOURCE, also process intra-source elements
					quit:(tTarget'=$$$IKMTRSOURCE)
					
					for tSrcTarget = $$$IKMTRENTITY, $$$IKMTRCRC, $$$IKMTRCC {
						set gSrcTargetId = $case(tSrcTarget, $$$IKMTRENTITY:"^IRIS.IK.Mtr.EntSrcValues", 
									$$$IKMTRCRC:"^IRIS.IK.Mtr.CrcSrcValues", $$$IKMTRCC:"^IRIS.IK.Mtr.CcSrcValues")
						set tInSrcId = ""
						for {
							set tInSrcId = $order(@gSrcTargetId@(pFromDomainId, tId, tInSrcId), 1, tData)
							quit:tInSrcId=""
							
							kill tNewInSrcId
							if (tSrcTarget = $$$IKMTRENTITY) {
								set tNewInSrcId = ##class(%iKnow.Queries.EntityAPI).GetId(pToDomainId, ^IRIS.IK.EntUniId(pFromDomainId,tInSrcId))
							} elseif (tTarget = $$$IKMTRCRC) {
								set tCrc = ^IRIS.IK.CrcUniId(pFromDomainId,tInSrcId)
								set tNewInSrcId(1) = $s('$li(tCrc,1):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCrc,1)))
								set tNewInSrcId(2) = $s('$li(tCrc,2):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCrc,2)))
								set tNewInSrcId(3) = $s('$li(tCrc,3):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCrc,3)))
								set tNewInSrcId = ##class(%iKnow.Queries.CrcAPI).GetId(pToDomainId,tNewInSrcId(1),tNewInSrcId(2),tNewInSrcId(3))
							} elseif (tTarget = $$$IKMTRCC) {
								set tCc = ^IRIS.IK.CcUniId(pFromDomainId,tInSrcId)
								set tNewInSrcId(1) = $s('$li(tCc,1):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCc,1)))
								set tNewInSrcId(2) = $s('$li(tCc,2):"", 1:^IRIS.IK.EntUniId(pFromDomainId,$li(tCc,2)))
								set tNewInSrcId = ##class(%iKnow.Queries.CcAPI).GetId(pToDomainId,tNewInSrcId(1),tNewInSrcId(2))
							}
							
							if pBatchCopy {
								set @gSrcTargetId@(pToDomainId, tId, tNewInSrcId) = tData
							} else {
								set tNewData = $lb(), tLen = $ll(tData)
								for i=1:1:tLen {
									set $li(tNewData,tOffsetMap($$$IKMTRTYPESOURCE,tSrcTarget,i)) = $li(tData,i)
								}
								set @gSrcTargetId@(pToDomainId, tId, tNewInSrcId) = tNewData
							}
						}
					}
				}
			}
		}
		
		set x = $sortend(^IRIS.IK.Mtr.EntUniValues(pToDomainId))
		set x = $sortend(^IRIS.IK.Mtr.EntSrcValues(pToDomainId))
		set x = $sortend(^IRIS.IK.Mtr.CrcUniValues(pToDomainId))
		set x = $sortend(^IRIS.IK.Mtr.CrcSrcValues(pToDomainId))
		set x = $sortend(^IRIS.IK.Mtr.CcUniValues(pToDomainId))
		set x = $sortend(^IRIS.IK.Mtr.CcSrcValues(pToDomainId))
		set x = $sortend(^IRIS.IK.Mtr.SrcValues(pToDomainId))
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if pProcNumber {
		set ^IRIS.Temp.IK.Mtr.Process(tTempId,pProcNumber) = tSC
		set $bit(^IRIS.Temp.IK.Mtr.Process(tTempId),pProcNumber) = 1
	}
	quit tSC
}

/// Copies a Metric Definition from one domain to another. No values are copied.
/// WARNING: only use <var>pPreserveOffsets</var> when copying metrics into a domain that didn't
/// have any metric targets registered.
ClassMethod CopyMetric(pFromDomainId As %Integer, pToDomainId As %Integer, pMetricId As %Integer, pPreserveOffsets As %Boolean = 0, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		$$$CHECKDOMAINEXISTSX(pFromDomainId,tSC)
		$$$CHECKDOMAINEXISTSX(pToDomainId,tSC)
		quit:pFromDomainId=pToDomainId
		
		$$$IKCHECKIDEXISTSX(^IRIS.IK.Mtr.MetricId,pFromDomainId,pMetricId,tMetric,$$$IKMetricIDDoesNotExist,tSC)
		
		// copying metric definition
		set tOldMetric = ##class(%iKnow.Metrics.Metric).PKINDEXOpen(pFromDomainId,pMetricId)
		set tNewMetric = ##class(%iKnow.Metrics.Metric).%New(pToDomainId, tOldMetric.Name, tOldMetric.Type, tOldMetric.DefinitionClass)
		set tNewMetric.Description = tOldMetric.Description
		set tNewMetric.BuilderClass = tOldMetric.BuilderClass
		set tSC = tNewMetric.%Save()
		quit:$$$ISERR(tSC)
		
		if (pPreserveOffsets) {
			merge ^IRIS.IK.Mtr.MetricTarget(pToDomainId, tNewMetric.MetricId) = ^IRIS.IK.Mtr.MetricTarget(pFromDomainId, pMetricId)
		} else {
			set tSC = ##class(%iKnow.Metrics.MetricAPI).GetTargets(.tTargets, pFromDomainId, pMetricId)
			quit:$$$ISERR(tSC)
			
			set i = ""
			for {
				set i = $order(tTargets(i),1,tData)
				quit:i=""
				set tSC = tNewMetric.AddTargetType($li(tData,1), .tNewOffset)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
		write:pVerbose !,$zdatetime($h),":  	Copied Metric definition ",tNewMetric.Name," from domain ",pFromDomainId," to ",pToDomainId
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
