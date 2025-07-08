/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.REST.Base Extends %CSP.REST [ Abstract, Deprecated, System = 4 ]
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter HandleCorsRequest = 1;

Parameter PAGESIZE As INTEGER = 200;

Parameter IKLATESTVERSION As STRING = "%iKnow.REST.v1dot1";

ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
	Set tSC = $$$OK
	try {
		
		// Set the return type according to the Accept type in the request. Default is application/json.
		if ('..AcceptsContentType(..#CONTENTTYPEJSON)) {
			set tSC = ..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE), pContinue=0
			quit 
        } else {   
			// This always returns json
			set %response.ContentType=..#CONTENTTYPEJSON
        }
        
        
        // read request object into %DynamicObject format
		if (pMethod'="POST") || (%request.Content="") {
			set %request.Content = {}
		} else {
			if '$isobject(%request.Content) {
				set tContent = %request.Content
			} else {
				set tContent = ""
				while '%request.Content.AtEnd {
					set tContent = tContent_%request.Content.Read()
				}
			}
			if (tContent="") {
				set %request.Content = {}
			} else {
				set tContent = $zconvert(tContent, "I", "UTF8")
				set %request.Content = ##class(%Library.DynamicObject).%FromJSON(tContent)
			}
		}
        
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit ##class(%iKnow.REST.Base).%ErrorHandler(tSC, .pContinue)
}

ClassMethod %ErrorHandler(pSC As %Status, ByRef pContinue As %Boolean) As %Status
{
	set pContinue = $$$ISOK(pSC)
	quit:pContinue $$$OK
	quit ..%ProcessResult(pSC)
}

ClassMethod %ProcessResult(pSC As %Status, pResult As %DynamicObject = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	if $$$ISERR(pSC) {
		set tSC = ..StatusToJSON(pSC, .tJSON)
		if $isobject(tJSON) {
			set pResult = tJSON
		} else {
			set pResult = { "errors": [ { "error": "Unknown error parsing status code" } ] }
		}
	} elseif '$isobject(pResult) {
		set pResult = {}
	}
	if $g(%debug)'="" {
		$$$IKRESTSTOPTIMER(total)
		set tIterator = %debug.timerStart.%GetIterator()
		while tIterator.%GetNext(.n,.s) {
			do %debug.timer.%Set(n, ($zh-s)_" (unfinished)")
		}
		do %debug.%Remove("timerStart")
		set pResult.debug = %debug
	}
	// BDB879
	if ($classname()'=..#IKLATESTVERSION) {
		set pResult.warnings = [ { "warning": "You are not accessing the latest version of this REST API. Use /api/iKnow/latest/* to access the most up-to-date version" } ]
	}
	write pResult.%ToJSON()
	quit tSC
}

/// If the supplied domain ID is not a valid integer, verify if it happens to be a domain name
/// and update pDomainId to that domain's ID
ClassMethod ResolveDomainId(ByRef pDomainId As %RawString) As %Status
{
	if $isvalidnum(pDomainId) {
		if '##class(%iKnow.Domain).%ExistsId(pDomainId) {
			$$$ThrowStatus($$$ERROR($$$IKNoDomainWithId, pDomainId))
		}
		quit $$$OK
	}
	set tDomain = ##class(%iKnow.Domain).NameIndexOpen(pDomainId)
	if '$isobject(tDomain) { $$$ThrowStatus($$$ERROR($$$IKDomainNotExists, pDomainId)) }
	set pDomainId = tDomain.Id
	quit $$$OK
}

/// Parse a few common arguments out of %request.Content
ClassMethod ParseArgs(pDomainId As %Integer = 0, Output pPage As %Integer, Output pPageSize As %Integer, Output pFilter As %iKnow.Filters.Filter, Output pFilterMode As %Integer, Output pSkiplists As %List) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if ('%request.Content.%IsDefined("page")) && ('%request.Content.%IsDefined("pageSize")) {
			set pPage = 1, pPageSize = ..#PAGESIZE
		} else {
			set pPage = %request.Content.page, pPageSize = %request.Content.pageSize
		}
		
		if '%request.Content.%IsDefined("filter") {
			set pFilter=""
		} elseif '$isobject(%request.Content.filter) {
			set tSC = ##class(%iKnow.Filters.Filter).FromString(pDomainId, %request.Content.filter, .pFilter)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = ..ParseFilter(pDomainId, %request.Content.filter, .pFilter)
			quit:$$$ISERR(tSC)
		}
		
		if '%request.Content.%IsDefined("filterMode") {
			set pFilterMode = $$$FILTERALLANDSORT
		} else {
			set pFilterMode = +%request.Content.filterMode
		}
		
		set pSkiplists = ""
		if %request.Content.%IsDefined("skiplists") {
			set tSpec = %request.Content.skiplists
			if '$isobject(tSpec) && ($e(tSpec,1,6)="SELECT") {
				set pSkiplists = tSpec
			} else {
				set:'$isobject(tSpec) tSpec = [ (tSpec) ]
				set tIterator = tSpec.%GetIterator()
				while tIterator.%GetNext(,.tValue) {
					if $isvalidnum(tValue) {
						set pSkiplists = pSkiplists_$lb(+tValue)
					} else {
						// accept names too
						set pSkiplists = pSkiplists_$lb(##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(pDomainId, tValue))
					}
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// { ids: [ srcID1, srcID2, ...] } --> SourceIdFilter
/// { extIds: [ extID1, extID2, ...] } --> ExternalIdFilter
/// { field: "fieldName", operator: "<", value: "value" } --> SimpleMetadataFilter
/// { operator: "AND"|"OR", negate : false, filters: [...] } --> GroupFilter
/// { className: "RandomClass", arguments : [ all args except domainID] }
ClassMethod ParseFilter(pDomainId As %Integer, pObject As %DynamicObject, Output pFilter As %iKnow.Filters.Filter) As %Status
{
	set tSC = $$$OK, pFilter = ""
	try {
		
		if pObject.%IsDefined("ids") { 
			set tIterator = pObject.ids.%GetIterator()
			while tIterator.%GetNext(,.tID) {
				set tIDs(tID)=""
			}
			set pFilter = ##class(%iKnow.Filters.SourceIdFilter).%New(pDomainId, .tIDs)
		} elseif pObject.%IsDefined("extIds") {
			set tIterator = pObject.extIds.%GetIterator()
			while tIterator.%GetNext(,.tID) {
				set tIDs(tID)=""
			}
			set pFilter = ##class(%iKnow.Filters.ExternalIdFilter).%New(pDomainId, .tIDs)
		} elseif pObject.%IsDefined("field") {
			set pFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(pDomainId, pObject.field, pObject.operator, pObject.value)
		} elseif pObject.%IsDefined("operator") {
			set pFilter = ##class(%iKnow.Filters.GroupFilter).%New(pDomainId, pObject.operator, pObject.negate)
			set tIterator = pObject.filters.%GetIterator()
			while tIterator.%GetNext(,.tFilterObj) {
				set tSC = ..ParseFilter(pDomainId, tFilterObj, .tFilter)
				quit:$$$ISERR(tSC)
				do pFilter.AddSubFilter(tFilter)
			}
			quit:$$$ISERR(tSC)
		} elseif pObject.%IsDefined("className") {
			set tIterator = pObject.arguments.%GetIterator()
			while tIterator.%GetNext(,.tArg) {
				set tArgs($i(tArgs)) = tArg
				if $isobject(tArgs(tArgs)) {
					set tList = ""
					set tIterator2 = tArgs.%GetIterator()
					while tIterator2.%GetNext(,.tVal) {
						set tList = tList_$lb(tVal)
					}
				}
			}
			set pFilter = $classmethod(pObject.className, "%New", pDomainId, tArgs...)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Unknown filter spec: "_pObject.%ToJSON())
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// { highlight: [
/// 	{ style: "...", entities : ["..."] }, --> ENTITY
/// 	{ style: "...", role : "concept"|"relation"|"nonRelevant"|"pathRelevant" } --> ROLE
/// 	{ style: "...", attribute : "negation"|"positiveSentiment"|"negativeSentiment"|id } --> ATTRIBUTE
/// 	{ style: "...", attributeWords : "negation"|"positiveSentiment"|"negativeSentiment"|id } --> ATTRIBUTEWORDS
/// 	{ style: "...", anyMatch: true [, matchType:"partial"|"full"] } --> MATCH
/// 	{ style: "...", dictionaries: [ dictIDs... ] [, matchType:"partial"|"full"] } --> MATCH
/// 	{ style: "...", dictionaryItems: [ dictItemIDs... ] [, matchType:"partial"|"full"] } --> MATCHITEM
/// 	{ style: "...", start: ##, end: ## } --> CHARS
/// 	{ style: "...", stems : ["..."] }, --> STEMS
/// 	{ style: "...", crcs : ["..."] }, --> CRC
/// 	{ style: "...", paths : ["..."] }, --> PATH
/// ] ... }
ClassMethod ParseHighlight(Output pHighlight) As %Status
{
	kill pHighlight
	quit:'%request.Content.%IsDefined("highlight") $$$OK
	
	set tIterator = %request.Content.highlight.%GetIterator()
	while tIterator.%GetNext(,.tSpec) {
		if tSpec.%IsDefined("start") {
			set pHighlight("CHARS", +tSpec.start, +tSpec.end) = tSpec.style
		} elseif tSpec.%IsDefined("role") {
			set pHighlight("ROLE", $case(tSpec.role,"concept":$$$ENTTYPECONCEPT, "relation":$$$ENTTYPERELATION, "nonRelevant":$$$ENTTYPENONREL, "pathRelevant":$$$ENTTYPEPATHREL, :tSpec.role)) = tSpec.style
		} elseif tSpec.%IsDefined("entities") {
			set tIterator2 = tSpec.entities.%GetIterator()
			while tIterator2.%GetNext(,.tEnt) {
				set pHighlight("ENTITY", tEnt) = tSpec.style
			}
		} elseif tSpec.%IsDefined("stems") {
			set tIterator2 = tSpec.stems.%GetIterator()
			while tIterator2.%GetNext(,.tEnt) {
				set pHighlight("STEM", tEnt) = tSpec.style
			}
		} elseif tSpec.%IsDefined("crcs") {
			set tIterator2 = tSpec.crcs.%GetIterator()
			while tIterator2.%GetNext(,.tID) {
				set pHighlight("CRC", tID) = tSpec.style
			}
		} elseif tSpec.%IsDefined("paths") {
			set tIterator2 = tSpec.paths.%GetIterator()
			while tIterator2.%GetNext(,.tID) {
				set pHighlight("PATH", tID) = tSpec.style
			}
		} elseif tSpec.%IsDefined("attribute") {
			set pHighlight("ATTRIBUTE", $case(tSpec.attribute, "negation":$$$IKATTNEGATION, "positiveSentiment":$$$IKATTSENPOSITIVE, "negativeSentiment":$$$IKATTSENNEGATIVE, :tSpec.attribute)) = tSpec.style
		} elseif tSpec.%IsDefined("attributeWords") {
			set pHighlight("ATTRIBUTEWORDS", $case(tSpec.attributeWords, "negation":$$$IKATTNEGATION, "positiveSentiment":$$$IKATTSENPOSITIVE, "negativeSentiment":$$$IKATTSENNEGATIVE, :tSpec.attribute)) = tSpec.style
		} elseif tSpec.%IsDefined("anyMatch") {
			if tSpec.%IsDefined("matchType") {
				set pHighlight("MATCH", tSpec.matchType) = tSpec.style
			} else {
				set pHighlight("MATCH") = tSpec.style
			}
		} elseif tSpec.%IsDefined("dictionaries") {
			set tIterator2 = tSpec.dictionaries.%GetIterator()
			while tIterator2.%GetNext(,.tID) {
				if tSpec.%IsDefined("matchType") {
					set pHighlight("MATCH", tID, $$$UPPER(tSpec.matchType)) = tSpec.style
				} else {
					set pHighlight("MATCH", tID) = tSpec.style
				}
			}
		} elseif tSpec.%IsDefined("dictionaryItems") {
			set tIterator2 = tSpec.dictionaryItems.%GetIterator()
			while tIterator2.%GetNext(,.tID) {
				if tSpec.%IsDefined("matchType") {
					set pHighlight("MATCHITEM", tID, $$$UPPER(tSpec.matchType)) = tSpec.style
				} else {
					set pHighlight("MATCHITEM", tID) = tSpec.style
				}
			}
		}
	}
	quit $$$OK
}

ClassMethod ParseList(pObjectProp As %String, pRequestParam As %RawString = "") As %List
{
	set tList = ""
	if %request.Content.%IsDefined(pObjectProp) {
		if $isobject(%request.Content.%Get(pObjectProp)) {
			set tList = "", tIterator = %request.Content.%Get(pObjectProp).%GetIterator()
			while tIterator.%GetNext(,.tEnt) {
				set tList = tList_$lb(tEnt)
			}
		} elseif (%request.Content.%Get(pObjectProp)="") && (pRequestParam'="") {
			set tList = $lfs(pRequestParam)
		} else {
			set tList = $lfs(%request.Content.%Get(pObjectProp))
		}
	} else {
		set tList = $lfs(pRequestParam)
	}
	quit tList
}

ClassMethod ParseStringArray(pObjectProp As %String, pRequestParam As %RawString = "") As %DynamicArray
{
	if %request.Content.%IsDefined(pObjectProp) && $isobject(%request.Content.%Get(pObjectProp)) && (%request.Content.%Get(pObjectProp)'=[]) {
		quit %request.Content.%Get(pObjectProp)
	} elseif %request.Content.%IsDefined(pObjectProp) {
		set pRequestParam = %request.Content.%Get(pObjectProp)
	}
	set tArray = []
	for i = 1:1:$l(pRequestParam,",") {
		do tArray.%Push($piece(pRequestParam,",",i))
	}
	quit tArray
}

/// Use this method
ClassMethod CreateDomainAPI(pDomainId As %Integer, pClassname As %String, pVersion As %String = "%iKnow.REST.v1") As %Status
{
	set tSC = $$$OK
	try {
		set tAPI = ##class(%Dictionary.ClassDefinition).%OpenId(pVersion)
		if '$isobject(tAPI) { set tSC = $$$ERROR($$$GeneralError, "Could not find REST API class '"_pVersion_"'") quit }
		
		set tClass = ##class(%Dictionary.ClassDefinition).%New()
		set tClass.Name = pClassname
		set tClass.Super = pVersion
		set tClass.ProcedureBlock = 1
		set tClass.Description = "auto-generated REST API for domain "_pDomainId_$c(13,10)_"DO NOT EDIT"
		
		set tParam = ##class(%Dictionary.ParameterDefinition).%New()
		set tParam.parent = tClass
		set tParam.Name = "DOMAINID"
		set tParam.SequenceNumber = $i(tSeq)
		set tParam.Default = pDomainId
		
		set tXData = ##class(%Dictionary.XDataDefinition).%New()
		set tXData.parent = tClass
		set tXData.Name = "UrlMap"
		set tXData.SequenceNumber = $i(tSeq)
		set tXData.XMLNamespace = "http://www.intersystems.com/urlmap"
		for i=1:1:tAPI.XDatas.Count() {
			if (tAPI.XDatas.GetAt(i).Name="UrlMap") {
				set tUrlMap = tAPI.XDatas.GetAt(i)
				quit
			}
		}
		set tRegExp = ##class(%Regex.Matcher).%New("Url=""/domain/:domain(.+)Call=""([a-zA-Z0-9]+)""")
		do tUrlMap.Data.Rewind()
		while 'tUrlMap.Data.AtEnd {
			set tRegExp.Text = tUrlMap.Data.ReadLine()
			do tXData.Data.WriteLine(tRegExp.ReplaceAll("Url=""$1Call=""$2DD"""))
		}
		
		for i = 1:1:tAPI.Methods.Count() {
			set tMethod = tAPI.Methods.GetAt(i)
			continue:$e(tMethod.FormalSpec,1,9)'="pDomainId"
			
			set tStub = ##class(%Dictionary.MethodDefinition).%New()
			set tStub.parent = tClass
			set tStub.Name = tMethod.Name_"DD"
			set tStub.SequenceNumber = $i(tSeq)
			set tStub.ClassMethod = tMethod.ClassMethod
			set tStub.ReturnType = tMethod.ReturnType
			set tStub.FormalSpec = $piece(tMethod.FormalSpec,",",2,*)
			set tCode = "	quit .."_tMethod.Name_"(..#DOMAINID"
			if (tStub.FormalSpec'="") {
				for j = 1:1:$l(tStub.FormalSpec,",") {
					set tCode = tCode_", "_$piece($piece(tStub.FormalSpec,",",j),":",1)
				}
			}
			do tStub.Implementation.WriteLine(tCode_")")
		}
		
		set tSC = tClass.%Save()
		quit:$$$ISERR(tSC)
		set (tClass,tMethod,tParam,tXData) = ""
		
		set tSC = $system.OBJ.Compile(pClassname,"crkfd")
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = $$$OK
	}
	quit tSC
}

}
