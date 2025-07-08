/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %IKPublic)

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25iKnow.Domain">NLP Domains</a>.</p>
///  This class represents a domain registered in this namespace.
/// <p>When creating a domain, you should pass a value for <property>Name</property>
/// to its <method>%New</method> method.</p>
Class %iKnow.Domain Extends %Persistent [ Deprecated, Final, StorageStrategy = iKnowStorage, System = 4 ]
{

///  The automatically generated ID for this domain, which is unique across namespaces
Property Id As %Integer [ ReadOnly ];

///  The name of this domain, which should be unique within the namespace (case-insensitive)
Property Name As %String [ ReadOnly ];

/// Stores the iKnow data structure version number for this domain.
Property Version As %String [ InitialExpression = {$$$IKCURRENTVERSION}, ReadOnly ];

/// Describes which data structures are built and maintained when adding data to the domain.
/// This propery is for internal use only.
Property BuildFlags As %String [ Internal, ReadOnly ];

/// The name of the Domain Definition class managing this domain, if any.
/// See also <class>%iKnow.DomainDefinition</class>.
Property DefinitionClass As %String [ Calculated, ReadOnly, SqlComputeCode = { set {*} = ##class(%iKnow.Domain).%OpenId({Id}).GetParameter($$$IKPDEFINITIONCLASS)}, SqlComputed ];

Index PKINDEX On Id [ IdKey, PrimaryKey, Unique ];

Index NameIndex On Name [ Unique ];

/// <p>Shorthand method to get the domain ID for a specific domain name, creating it if it does not
///  yet exist in this namespace.</p>
/// <p>Deprecated: use regular <method>%New</method> and <method>%Save</method> methods instead.
ClassMethod GetOrCreateId(name As %String, sortField As %Integer = {$$$SORTBYFREQUENCY}, Output sc As %Status = {$$$OK}) As %Integer [ Deprecated ]
{
    Set sc=$$$OK
    Set domain=$s(..Exists(name):..Open(name, .sc),1:..Create(name, sortField, .sc))
    If domain="" {
        // TODO: treat $ze thrown
    }
    Set id=domain.Id, domain=""
    Quit id
}

///  Creates a domain with the specified domain name in the given namespace. If no value is
///  supplied for <var>sortField</var>, it will assume the system-wide defaults. <var>buildFlags</var>
///  is either of "ALL" or "MINIMAL". An empty value will assume the system default.
///  <p><b>Deprecated</b>: use <method>%New</method> instead (supplying only the <var>name</var> parameter)</p>
ClassMethod Create(name As %String, sortField As %Integer = -1, Output sc As %Status = {$$$OK}, buildFlags As %String = "") As %iKnow.Domain [ Deprecated ]
{
	set tDomain = ..%New(name, buildFlags)
	
	if ($g(tDomain)="") {
		// something went wrong, so capture the error and quit
		set sc = %objlasterror
		quit ""
	}
	
	// save
	set sc = tDomain.%Save()
	quit:$$$ISERR(sc) ""
	
	// try to set the sort field parameter
	if (sortField '= -1) {
		set sc = tDomain.SetParameter("SortField", sortField)
	}
	
	quit tDomain
}

///  Opens a domain object with the specified name
///  <p><b>Deprecated</b>: use <method>NameIndexOpen</method> instead</p>
ClassMethod Open(name As %String, Output sc As %Status = {$$$OK}) As %iKnow.Domain [ Deprecated ]
{
	set sc = $$$OK
    quit ..NameIndexOpen(name)
}

///  Opens a domain object with the specified ID
///  <p><b>Deprecated</b>: use <method>%OpenId</method> instead</p>
ClassMethod OpenId(id As %Integer, Output sc As %Status = {$$$OK}) As %iKnow.Domain [ Deprecated ]
{
	set sc = $$$OK
    quit ..PKINDEXOpen(id)
}

///  Checks whether a domain with the given name already exists within the namespace
///  <p><b>Deprecated</b>: use <method>NameIndexExists</method> instead</p>
ClassMethod Exists(name As %String) As %Boolean [ Deprecated ]
{
    quit ..NameIndexExists(name)
}

/// Instantiates a new Domain object iwth the given domain name.
/// <var>pBuildFlags</var> is either of "ALL" or "MINIMAL". An emtpy value will result in the
/// system default being used.
Method %OnNew(pName As %String, pBuildFlags As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVADMINX(tSC)
		$$$IKCHECKNOTNULLX(pName,tSC)
		$$$IKCHECKSTRINGLENGTHX(pName,tSC)
		
		// check for name uniqueness right away, as it's a read-only propery
		// and the index is only validated after %OnBeforeSave() otherwise
		if ..NameIndexExists(pName) {
			set tSC = $$$ERROR($$$IKDomainExists, pName)
			quit
		}
		
        set i%Name = pName
        set i%Version = $$$IKCURRENTVERSION
        
        // BDB354 - translate build flag string to flag sequence
        set:pBuildFlags="" pBuildFlags = $$$DEFBUILDFLAGS
        set tBuildFlags = $$$IKBUILDFLAGSFLAGS(pBuildFlags)
        for i = 1:1:$l(tBuildFlags) {
	        if $case($a(tBuildFlags,i), $$$IKBFNEVER:0, $$$IKBFINIT:0, $$$IKBFBATCH:0, $$$IKBFALWAYS:0, :1) {
		        set tSC = $$$ERROR($$$IKIllegalDomainParamVal, "BuildFlags", pBuildFlags)
		        quit
	        }
        }
        quit:$$$ISERR(tSC)
        
        set i%BuildFlags = tBuildFlags
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVADMIN
	
	set tSC = $$$OK
	try {
        if (insert) {
	        set tDomainId = $s(..Id:..Id, 1:($o(^IRIS.IK.Sys.DomainD(""),-1)+1))
	        while 1 {
		        if '$d(^IRIS.IK.Sys.DomainD(tDomainId)) {
			        lock +^IRIS.IK.Sys.DomainD(tDomainId):0
			        quit:$test
		        }
		        set tDomainId = tDomainId+1
	        }
	        set i%Id = tDomainId
        } else {
        	$$$IKCHECKDOMMGRX(..Id,tSC)
        }
	} catch (ex) {
		set tSC = ex.AsStatus()
		lock:$g(tDomainId) -^IRIS.IK.Sys.DomainD(tDomainId)
	}
	quit tSC
}

Method %OnAfterSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
        
        if (insert) {
	        lock -^IRIS.IK.Sys.DomainD(i%Id)
	        
	        // Setup default metadata fields
	        set tSC = ##class(%iKnow.Queries.MetadataAPI).AddField(i%Id, "DateIndexed", $lb($$$MDOPEQUAL, $$$MDOPNOTEQUAL, $$$MDOPSMALLER, $$$MDOPSMALLEROREQUAL, $$$MDOPLARGER, $$$MDOPLARGEROREQUAL),$$$MDDTDATE)
	        quit:$$$ISERR(tSC)
        
	        // Ensure there's a default configuration
	        do ##class(%iKnow.Configuration).CreateDefaultConfig()
        }
        
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  This method will drop all sources and subsequent indexes from this domain.
/// <p>Note that it is recommended to call this method separately, before dropping the domain 
/// through <method>%Delete</method> or <method>%DeleteId</method>.</p>
Method DropData(dropMetadataDefinitions As %Boolean = 0, dropDictionaries As %Boolean = 0, dropTempGlobals As %Boolean = 1, dropSkipLists As %Boolean = 1, dropMetricDefinitions As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVADMINX(tSC)
	
		if (..%IsModified()) {
			set tSC = $$$ERROR($$$IKObjectModified, "Domain")
			quit
		}
		
		$$$IKCHECKDOMMGRX(..Id,tSC)
		
		// BDB572 - check if we should disable journalling and track if we need to restore it afterwards
		$$$IKDisableJournal(..Id)
		
	    If (dropTempGlobals) {
	        Set loader = ##class(%iKnow.Source.Loader).%New(..Id)
	        Set tSC = loader.ClearTemps(1)
	        Quit:$$$ISERR(tSC)
	        set loader = ""
	        
	        set tSC = ##class(%iKnow.Filters.Filter).ClearCachedFilters(..Id)
	        quit:$$$ISERR(tSC)
	    }
	    
	    set domainId = i%Id
	    $$$IKLOCKLOADX(domainId,tSC)
	    $$$IKLOCKUPGRX(domainId,tSC)
	    
	    // DP-405780 - use static list to get all iKnow-related globals
	    do ..GetIKnowGlobals(.lst)
	    
	    // System globals that should never be dropped
	    Set nok=$lb("^IRIS.IK.Sys.Params","^IRIS.IK.Sys.Costs","^IRIS.IK.Sys.DomainD","^IRIS.IK.Sys.DomainI",
	    	        "^IRIS.IK.Sys.ConfigD","^IRIS.IK.Sys.ConfigI","^IRIS.IK.Sys.ListerD","^IRIS.IK.Sys.ListerI",
			"^IRIS.IK.Sys.ListerAlias","^IRIS.IK.Sys.ConverterD","^IRIS.IK.Sys.ConverterI","^IRIS.IK.Sys.NSParams",
			"^IRIS.IK.Sys.ProcessorD","^IRIS.IK.Sys.ProcessorI","^IRIS.IK.Sys.UserDictD","^IRIS.IK.Sys.UserDictI",
			"^IRIS.IK.Sys.UserDictEntry","^IRIS.IK.Sys.DictFormatD","^IRIS.IK.Sys.DictFormatI","^IRIS.IK.Sys.Definition",
			"^IRIS.IK.Sys.StemmerConfigI", "^IRIS.IK.Sys.StemmerConfigD")
	    For n=1:1:$ll(nok) {
		  Kill lst($li(nok,n))
	    }
	    // metadata globals
	    Kill:'dropMetadataDefinitions lst("^IRIS.IK.Mdt.Field"),lst("^IRIS.IK.Mdt.FieldId")
	    
	    // dictionary globals
	    set tHasDictionaries = ($d(^IRIS.IK.Mat.DictElementId(domainId))>1)
	    If 'dropDictionaries {
	        Set nok=$lb("^IRIS.IK.Mat.DictId","^IRIS.IK.Mat.Dict","^IRIS.IK.Mat.DictToItem",
		            "^IRIS.IK.Mat.DictItemId","^IRIS.IK.Mat.DictItemURI","^IRIS.IK.Mat.DictItemTerms",
			    "^IRIS.IK.Mat.DictTermId","^IRIS.IK.Mat.DictTermElems","^IRIS.IK.Mat.DictElementId","^IRIS.IK.Mat.DictElement",
			    "^IRIS.IK.Mat.DictElemString","^IRIS.IK.Mat.DictFormatId","^IRIS.IK.Mat.DictFormat",
			    "^IRIS.IK.Mat.DictFormatElements","^IRIS.IK.Mat.DictToFormat","^IRIS.IK.Mat.Profile",
			    "^IRIS.IK.Mat.DictMatchStatus", "^IRIS.IK.Mat.EntUniToDictElem", "^IRIS.IK.Mat.DictElemStringId")
			For n=1:1:$ll(nok) { Kill lst($li(nok,n)) }
	    }
	    
	    // Skiplists
	    set tHasSkiplists = ($d(^IRIS.IK.BlackListElements(domainId))>1)
	    kill:'dropSkipLists lst("^IRIS.IK.BlackListId"), lst("^IRIS.IK.BlackList"), lst("^IRIS.IK.BlackListElements")
	    
	    // BDB572 - leave EntUni globals only in place if we're not dropping dictionaries or Skiplists
	    // 			AND they are actually in use!
	    if ('dropDictionaries && tHasDictionaries) || ('dropSkipLists && tHasSkiplists) {
	    	kill lst("^IRIS.IK.EntUniId"), lst("^IRIS.IK.EntUni"), lst("^IRIS.IK.EntUniHash"), lst("^IRIS.IK.DataLoaded")
	    }
	    			
	    // metrics
	   	kill:'dropMetricDefinitions lst("^IRIS.IK.Mtr.MetricId"), lst("^IRIS.IK.Mtr.Metric"), lst("^IRIS.IK.Mtr.MetricTarget")
	   	
	   	
	    Set (glob,gg)="^IRIS.IK"
	    For {
	        set glob=$o(lst(glob))
	        quit:$e(glob,1,$l(gg))'=gg
	        
	        set prefix = $e(glob,1,9)
	        
	        // these are taken care of earlier
	        continue:prefix="^IRIS.IKT" 
	        continue:prefix="^IRIS.IKS"
	        
	        if (prefix="^IRIS.IK.") || (prefix="^IRIS.IKV") || (prefix="^IRIS.IKL") {
		        kill @glob@(domainId)
	        }
	    }
	    
	    if 'dropDictionaries || 'dropSkipLists {
		    // restore ^IRIS.IK.EntUniDetails
		    $$$IKSORTBEGIN(^IRIS.IK.EntUniDetails(domainId))
		    set entUniId = "", zeroes = $lb(0,0,0,0,0,0,0)
		    for {
			    set entUniId = $order(^IRIS.IK.EntUniId(domainId,entUniId))
			    quit:entUniId=""
			    set ^IRIS.IK.EntUniDetails(domainId, entUniId) = zeroes
		    }
		    set x = $sortend(^IRIS.IK.EntUniDetails(domainId))
	    }
	    
	    // BDB608 - reset ^IRIS.IK.DomainDetails
	    set ^IRIS.IK.DomainDetails(domainId) = $lb(0,0,0,0,0,0,0,0,0,0)
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	$$$IKRestoreJournal // BDB572
    
    if $g(domainId) {
	    $$$IKDOMAINCHANGED(domainId)
   	 	$$$IKUNLOCKLOAD(domainId)
   	 	$$$IKUNLOCKUPGR(domainId)
    }
    
    quit tSC
}

///  Utility method to delete a domain from the system, including its data, settings
///  and system global entries. 
///  <p><b>Deprecated</b>: use <method>%DeleteId</method> instead (accepts domain ID)</p>
ClassMethod Delete(domainName As %String) As %Status [ Deprecated ]
{
	set dom = ..Open(domainName)
	quit:dom="" $$$ERROR($$$IKDomainNotExists, domainName)
	quit ..%DeleteId(dom.Id)
}

///  Utility method to delete a domain from the system, including its data, settings
///  and system global entries. 
/// <p><b>Deprecated</b>: use <method>%DeleteId</method> instead</p>
ClassMethod DeleteId(domainId As %Integer) As %Status [ Deprecated ]
{
	$$$IKCHECKDOMMGR(domainId)
	quit ..%DeleteId(domainId)
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVADMIN
	
	set tSC = $$$OK
	try {
		set tDomain = ..%Open(oid)
		if '$isobject(tDomain) { set tSC = $$$ERROR($$$IKNoDomainWithId, oid)  quit  }
		
		$$$IKCHECKDOMMGRX(tDomain.Id,tSC)
		
		set tSC = tDomain.DropData(1, 1, 1, 1, 1)
		quit:$$$ISERR(tSC)
		
		// BDB563 - drop associated tables
		set tPackageName = tDomain.GetParameter($$$IKPPACKAGE)
		if (tPackageName'="") {
			set tSC = ##class(%iKnow.Tables.Utils).DropDomainTables(tPackageName)
			quit:$$$ISERR(tSC)
		}
    	
		// drop this domain's settings
		kill ^IRIS.IK.Sys.Params(tDomain.Id)
		
		// BDB608 - drop additional details
		kill ^IRIS.IK.DomainDetails(tDomain.Id)
		
		set tDomain=""
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the current namespace-wide value for a domain parameter if there is one registered.
/// See <method>GetParameter</method> for more details on how to fetch the current
/// APPLICABLE parameter for a domain, as this method does not take any domain-specific
/// settings or hardcoded defaults into account.
ClassMethod GetSystemParameter(paramName As %String) As %String
{
	$$$IKCHECKPRIVREAD
	
	// BDB321 - also accept macro names
	set:$e(paramName,1,6)="$$$IKP" paramName = $system.iKnow.GetDomainParameterName(paramName)
	
	quit:(paramName="") $$$ERROR($$$IKIllegalDomainParameter, paramName)
	
	quit $g(^IRIS.IK.Sys.NSParams(paramName))
}

/// Removes a namespace-level default parameter value for the given parameter name.
ClassMethod UnsetSystemParameter(paramName As %String) As %Status
{
	$$$IKCHECKPRIVADMIN
	
	// BDB321 - also accept macro names
	set:$e(paramName,1,6)="$$$IKP" paramName = $system.iKnow.GetDomainParameterName(paramName)
	
	quit:'$$$IKALLOWUSERSET(paramName) $$$ERROR($$$IKIllegalDomainParameter, paramName)
	quit:(paramName="") $$$ERROR($$$IKIllegalDomainParameter, paramName)
	
	if $$$IKONLYCHANGEWHENEMPTY(paramName) {
		quit:$d(^IRIS.IK.DataLoaded)>9 $$$ERROR($$$IKEmptyDomainParamForSys, paramName)
	}
	
	kill ^IRIS.IK.Sys.NSParams(paramName)
	quit $$$OK
}

/// Registers a domain parameter at the namespace level, for all domains in the current namespace.
/// If there is already a value registered, call <method>UnsetSystemParameter</method>
/// first to explicitly clear the current value.
ClassMethod SetSystemParameter(paramName As %String, paramValue As %String) As %Status
{
	$$$IKCHECKPRIVADMIN
	
	// BDB321 - also accept macro names
	set:$e(paramName,1,6)="$$$IKP" paramName = $system.iKnow.GetDomainParameterName(paramName)
	
	quit:(paramName="") $$$ERROR($$$IKIllegalDomainParameter, paramName)
	
	set currentValue = ..GetSystemParameter(paramName)
	quit:currentValue'="" $$$ERROR($$$IKSysParameterSet, currentValue)
	
	set tSC = ..CheckParameterValue(paramName, $g(paramValue), "")
	quit:$$$ISERR(tSC) tSC
	
	set ^IRIS.IK.Sys.NSParams(paramName) = paramValue
	quit $$$OK
}

ClassMethod CheckParameterValue(paramName As %String, paramValue As %String, domain As %iKnow.Domain = "") As %Status [ Internal, Private ]
{
	quit:'$$$IKALLOWUSERSET(paramName) $$$ERROR($$$IKIllegalDomainParameter, paramName)
	
	if ($$$IKONLYCHANGEWHENEMPTY(paramName)) {
		if $isobject(domain) {
			quit:'domain.IsEmpty() $$$ERROR($$$IKDomainNonEmptyForParam, paramName)
		} else {
			quit:$d(^IRIS.IK.DataLoaded)>9 $$$ERROR($$$IKEmptyDomainParamForSys, paramName)
		}
	}
	
	// parameter-specific checks
	set tDomainId = $s($isobject(domain):domain.Id, 1:0)
	if (paramName = $$$IKPMETADATAAPI) {
		
		quit:'##class(%Dictionary.CompiledClass).%ExistsId(paramValue) $$$ERROR($$$CompiledClassDoesNotExist, paramValue)
		
		if '$classmethod(paramValue, "%Extends", "%iKnow.Queries.MetadataI") {
			quit $$$ERROR($$$InvalidArgument)
		}
		
	} elseif (paramName = $$$IKPLANGUAGEFIELDNAME) && $isobject(domain) {
		
		quit:'##class(%iKnow.Queries.MetadataAPI).GetFieldId(domain.Id, paramValue) $$$ERROR($$$IKMDFieldDoesNotExistE, paramValue)
		
	} elseif (paramName = $$$IKPMATDEFAULTPROFILE) {
		
		if $isobject(paramValue) {
			quit:paramValue.%IsModified() $$$ERROR($$$IKMatProfileModified)
			set paramValue = paramValue.DomainId _":"_ paramValue.Name
		}
		quit:'$isobject(##class(%iKnow.Matching.MatchingProfile).GetProfileByName($s($isobject(domain):domain.Id, 1:0), paramValue)) $$$ERROR($$$IKMatProfileDoesNotExist, paramValue, $s($isobject(domain):domain.Id, 1:0))
		
	} elseif (paramName = $$$IKPDEFAULTCONFIG) {
		
		quit:'##class(%iKnow.Configuration).NameIndexExists(paramValue) $$$ERROR($$$IKConfigurationNotFound, paramValue)
		
	} elseif (paramName = $$$IKPSORTFIELD) {
		
		quit:(paramValue'=$$$SORTBYFREQUENCY)&&(paramValue'=$$$SORTBYSPREAD) $$$ERROR($$$IKIllegalDomainParamVal, paramName, paramValue)
		
	} elseif (paramName = $$$IKPMATSTANDARDIZEDFORM) {
		
		set tUseStemming = ($$$GETPARAM(tDomainId,$$$IKPSTEMMING,0)'=0)
		
		if (paramValue = $$$IKPMATSTANDARDIZEDFORMSTEMMING) {
			
			if 'tUseStemming {
				quit $$$ERROR($$$GeneralError, "Stemming should be enabled through the $$$IKPSTEMMING parameter for this option")
			}
			
		} elseif tUseStemming {
			
			quit $$$ERROR($$$GeneralError, "Standardized form matching is no longer available as a separate option when using stemming")
			
		} elseif (paramValue '= $$$IKPMATSTANDARDIZEDFORMTEXT)
			 && (paramValue '= $$$IKPMATSTANDARDIZEDFORMSTEMMING)
			 && '##class(%Dictionary.CompiledMethod).%ExistsId($p(paramValue,":",1)_"||"_$p(paramValue,":",1)) {
			quit $$$ERROR($$$IKIllegalDomainParamVal, paramName, paramValue)	
		}
		
	} elseif (paramName = $$$IKPSTEMMING) { // BDB600
		
		if '$lf($lb(0,1,"",$$$DEFAULTCONFIG),paramValue) && // system values
				'##class(%iKnow.Stemming.Configuration).NameIndexExists(paramValue) && // saved configs
				'##class(%Dictionary.CompiledClass).%ExistsId($piece(paramValue,":",1)) { // explicit configs
			quit $$$ERROR($$$GeneralError, "Stemming configuration '"_paramValue_"' does not exist")
		}
		
		// check if compatible with domain version
		if $isobject(domain) {
			$$$IKCHECKVERSIONATLEAST(tDomainId,$$$IKVERSIONSTEMMING)
		}
		
		if $$$GETPARAMNODEF(tDomainId,$$$IKPMATSTANDARDIZEDFORM)'="" {
			quit $$$ERROR($$$GeneralError, "Standardized form matching cannot be combined with $$$IKPSTEMMING")
		}
		
		if '$isobject(domain) && ($d(^IRIS.IK.Mat.DictElementId(0))>1) { // BDB623
			quit $$$ERROR($$$GeneralError, "Cannot change namespace default for stemming if cross-domain dictionaries indexing results are present.")
		}
		
	}
	
	quit $$$OK
}

///  Sets a domain-specific parameter, overriding the system default
Method SetParameter(paramName As %String, paramValue As %String) As %Status
{
	$$$IKCHECKPRIVADMIN
	
	quit:..%IsModified() $$$ERROR($$$IKObjectModified, "Domain")
	$$$IKCHECKDOMMGR(..Id)
	
	// BDB321 - also accept macro names
	set:$e(paramName,1,6)="$$$IKP" paramName = $system.iKnow.GetDomainParameterName(paramName)
	
	set tSC = ..CheckParameterValue(paramName, $g(paramValue), $this)
	quit:$$$ISERR(tSC) tSC
	
    set ^IRIS.IK.Sys.Params(..Id, paramName) = paramValue
    quit $$$OK
}

///  Unsets a domain-specific parameter, so it will use the system default again
Method UnsetParameter(paramName As %String) As %Status
{
	quit:..%IsModified() $$$ERROR($$$IKObjectModified, "Domain")
	$$$IKCHECKDOMMGR(..Id)
	
	// BDB321 - also accept macro names
	set:$e(paramName,1,6)="$$$IKP" paramName = $system.iKnow.GetDomainParameterName(paramName)
	
	quit:'$$$IKALLOWUSERSET(paramName) $$$ERROR($$$IKIllegalDomainParameter, paramName)
	
	quit:$$$IKONLYCHANGEWHENEMPTY(paramName)&&'..IsEmpty() $$$ERROR($$$IKDomainNonEmptyForParam, paramName)
	
    kill ^IRIS.IK.Sys.Params(..Id, paramName)
    quit $$$OK
}

///  Returns the value used for parameter <var>paramName</var> for this domain. This can be a
/// domain-specific override (<var>definedAt</var> = "DOMAIN"), a namespace-wide default
/// (<var>definedAt</var> = "NAMESPACE") or the hardcoded default (<var>definedat</var> = "DEFAULT")  
Method GetParameter(paramName As %String, Output definedAt As %String = "DOMAIN") As %String
{
	$$$IKCHECKPRIVREAD
	
	quit:..%IsModified() ""
	
	// BDB321 - also accept macro names
	set:$e(paramName,1,6)="$$$IKP" paramName = $system.iKnow.GetDomainParameterName(paramName)
	
	if $d(^IRIS.IK.Sys.Params(..Id, paramName), value) {
		set definedAt = "DOMAIN"
	} elseif $d(^IRIS.IK.Sys.NSParams(paramName), value) {
		set definedAt = "NAMESPACE"
	} else {
		set definedAt = "DEFAULT"
		set value = $$$GETPARAMDEFAULT(paramName)
	}
    quit value
}

///  Utility query to retrieve a list of all registered Domains
/// <p><b>Deprecated</b>: Please use normal SQL queries to approach this class.</p>
Query GetAllDomains(pCurrentNamespaceOnly As %Boolean = 0, pIncludeRemote As %Boolean = 0) As %Query(ROWSPEC = "domainId:%Integer,domainName:%String,namespace:%String,version:%String") [ Deprecated, SqlProc ]
{
}

ClassMethod GetAllDomainsExecute(ByRef qHandle As %Binary, pCurrentNamespaceOnly As %Boolean = 0, pIncludeRemote As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVREADX(tSC)
	
		kill tNamespaces
		if pCurrentNamespaceOnly {
			set tNamespaces($namespace) = ""
		} else {
			do List^%SYS.NAMESPACE(.tNamespaces,0,pIncludeRemote)
			quit:$$$ISERR(tSC)
		}
		
		kill ^||%IK.DomainList
		set tNamespace = ""
		for {
			set tNamespace = $order(tNamespaces(tNamespace))
			quit:tNamespace=""
			continue:$e(tNamespace,1,2)="^^"
			
			try {
				continue:'$d(^[tNamespace]IRIS.IK.Sys.DomainD)
			} catch (ex) {
				continue // skip the ones we cannot connect to
			}
			
			set tDomainId = ""
			for {
				set tDomainId = $order(^[tNamespace]IRIS.IK.Sys.DomainD(tDomainId), 1, tDomainInfo)
				quit:tDomainId=""
				
				set ^||%IK.DomainList($i(^||%IK.DomainList)) = $lb(tDomainId, $li(tDomainInfo,1), tNamespace, $li(tDomainInfo,3))
			}
		}
		
   		set qHandle = $lb("")
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
    quit tSC
}

ClassMethod GetAllDomainsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetAllDomainsExecute ]
{
	kill ^||%IK.DomainList
  	quit $$$OK
}

ClassMethod GetAllDomainsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetAllDomainsExecute ]
{
	set tSC = $$$OK
	try {
		set Row=""
		set tIndex = $order(^||%IK.DomainList($lg(qHandle,1)),1,Row)
		set qHandle = $lb(tIndex)
		set AtEnd = (tIndex="")
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// This method has been deprecated. There is no need for "registering" or otherwise marking
/// domains that have been imported from globals or data files.
ClassMethod RegisterImportedDomain(domainId As %Integer) As %Status [ Deprecated ]
{
	quit $$$OK
}

///  Returns whether or not a domain is empty. If there are any entities or remnants of (virtual)
///  sources, this method will return false.
Method IsEmpty() As %Boolean
{
	quit:..%IsModified() 1
	
	quit:(##class(%iKnow.Queries.EntityAPI).GetCountByDomain(..Id,,,,1)>0) 0
	quit:(##class(%iKnow.Queries.SourceAPI).GetCountByDomain(..Id)>0) 0
	quit:($d(^IRIS.IKV.SrcId(..Id))>1) 0
	quit 1
}

/// This method renames an existing domain named <var>pFrom</var> to <var>pTo</var>, 
/// if there isn't already a domain with that name in this namespace. The domain ID does
/// not change.
ClassMethod Rename(pFrom As %String, pTo As %String) As %Status
{
	$$$IKCHECKPRIVADMIN
	
	set tSC = $$$OK
	try {
        lock +^IRIS.IK.Sys.DomainD:2
    	if '$test { set tSC = $$$ERROR($$$IKFailedLockDomain, name)  goto err }
    	
		if '..NameIndexExists(pFrom) { set tSC = $$$ERROR($$$IKDomainNotExists, pFrom)  goto err }
		if ..NameIndexExists(pTo) && ($$$UPPER(pFrom)'=$$$UPPER(pTo)) { set tSC = $$$ERROR($$$IKDomainExists, pTo)  goto err }
		
		set tDomainId = ..NameIndexOpen(pFrom).Id
		$$$IKCHECKDOMMGRX(tDomainId,tSC)
		
		// update local globals
		kill ^IRIS.IK.Sys.DomainI($$$UPPER(pFrom))
		set $li(^IRIS.IK.Sys.DomainD(tDomainId),1) = pTo
		set ^IRIS.IK.Sys.DomainI($$$UPPER(pTo)) = tDomainId
		
		// BDB557 - Update any orefs of the corresponding domain
		set tObj = ..%OpenId(tDomainId)
		set tSC = tObj.%Reload()
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
		goto err
	}
	lock -^IRIS.IK.Sys.DomainD
	quit tSC
	
err
	lock -^IRIS.IK.Sys.DomainD
    $$$IKERROR(0,sc,..%ClassName(1)_":Rename")
	quit tSC
}

/// <p>Returns an array <var>pParams</var> containing all the domain parameters registered
/// for this instance in the form: pParams(<i>paramName</i>) = <i>paramValue</i>.</p>
/// NOTE: this might include parameters that cannot be modified by end users, but will not
/// include values defined at the namespace level.
Method GetParameters(Output pParams) As %Status
{
	$$$IKCHECKPRIVREAD
	
	quit:..%IsModified() $$$ERROR($$$IKObjectModified, "Domain")
	
	set tSC = $$$OK
	try {
		kill pParams
		merge pParams = ^IRIS.IK.Sys.Params(..Id)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Returns the current version of this InterSystems IRIS instance, which is the version of any
/// newly created domain in this instance. Domains already created in this instance
/// before it was last upgraded or which were imported from other instances through other
/// means, may have earlier versions. To check the version of a particular domain, use
/// the <property>Version</property> property of a <class>%iKnow.Domain</class> instance.</p>
ClassMethod GetCurrentSystemVersion() As %String
{
	quit $$$IKCURRENTVERSION
}

/// Internal method to retrieve all raw ^IRIS.IK* global names to avoid having to list them
/// dynamically. 
/// This excludes the global names that include domain/temp IDs and process IDs managed entirely
/// within the domain build process and tracked through ^IRIS.IKS.Globals / ^IRIS.IKT.Globals
ClassMethod GetIKnowGlobals(Output list) As %Status [ Internal ]
{
	// primary domain contents
	set list("^IRIS.IK.Att.Path")=""
	set list("^IRIS.IK.Att.Sent")=""
	set list("^IRIS.IK.BlackList")=""
	set list("^IRIS.IK.BlackListElements")=""
	set list("^IRIS.IK.BlackListId")=""
	set list("^IRIS.IK.CcEntCombiFreq")=""
	set list("^IRIS.IK.CcEntCombiSpread")=""
	set list("^IRIS.IK.CcUni")=""
	set list("^IRIS.IK.CcUniDet")=""
	set list("^IRIS.IK.CcUniExistsBit")=""
	set list("^IRIS.IK.CcUniId")=""
	set list("^IRIS.IK.CcUniIdFreq")=""
	set list("^IRIS.IK.CcUniIdSpread")=""
	set list("^IRIS.IK.CcUniToOccBit")=""
	set list("^IRIS.IK.CcUniToSentBit")=""
	set list("^IRIS.IK.CcUniToSrcBit")=""
	set list("^IRIS.IK.CrcEntUniFreq")=""
	set list("^IRIS.IK.CrcEntUniSpread")=""
	set list("^IRIS.IK.CrcOccId")=""
	set list("^IRIS.IK.CrcSrcDetails")=""
	set list("^IRIS.IK.CrcUni")=""
	set list("^IRIS.IK.CrcUniDetails")=""
	set list("^IRIS.IK.CrcUniExistsBit")=""
	set list("^IRIS.IK.CrcUniFreq")=""
	set list("^IRIS.IK.CrcUniSpread")=""
	set list("^IRIS.IK.CrcUniId")=""
	set list("^IRIS.IK.CrcUniIdFreq")=""
	set list("^IRIS.IK.CrcUniIdSpread")=""
	set list("^IRIS.IK.CrcUniToOccBit")=""
	set list("^IRIS.IK.CrcUniToSentBit")=""
	set list("^IRIS.IK.CrcUniToSrcBit")=""
	set list("^IRIS.IK.DataLoaded")=""
	set list("^IRIS.IK.DomainDetails")=""
	set list("^IRIS.IK.DomProf")=""
	set list("^IRIS.IK.EntOccId")=""
	set list("^IRIS.IK.EntParts")=""
	set list("^IRIS.IK.EntSrcDetails")=""
	set list("^IRIS.IK.EntTypeToOccBit")=""
	set list("^IRIS.IK.EntUni")=""
	set list("^IRIS.IK.EntUniDetails")=""
	set list("^IRIS.IK.EntUniExistsBit")=""
	set list("^IRIS.IK.EntUniId")=""
	set list("^IRIS.IK.EntUniIdFreq")=""
	set list("^IRIS.IK.EntUniIdSpread")=""
	set list("^IRIS.IK.EntUniMToCcUniBit")=""
	set list("^IRIS.IK.EntUniMToCrcUniBit")=""
	set list("^IRIS.IK.EntUniMToEntUniSBit")=""
	set list("^IRIS.IK.EntUniRToCrcUniBit")=""
	set list("^IRIS.IK.EntUniSToCcUniBit")=""
	set list("^IRIS.IK.EntUniSToCrcUniBit")=""
	set list("^IRIS.IK.EntUniSToEntUniMBit")=""
	set list("^IRIS.IK.EntUniToOccBit")=""
	set list("^IRIS.IK.EntUniToPathBit")=""
	set list("^IRIS.IK.EntUniToSentBit")=""
	set list("^IRIS.IK.EntUniToSrcBit")=""
	set list("^IRIS.IK.EntUniToStemUni")=""
	set list("^IRIS.IK.Ext.Group")=""
	set list("^IRIS.IK.Ext.GroupId")=""
	set list("^IRIS.IK.Ext.LocalRef")=""
	set list("^IRIS.IK.LitUni")=""
	set list("^IRIS.IK.LitUniId")=""
	set list("^IRIS.IK.PathDetails")=""
	set list("^IRIS.IK.PathId")=""
	set list("^IRIS.IK.PathToEntOcc")=""
	set list("^IRIS.IK.PathToSent")=""
	set list("^IRIS.IK.PathToSrc")=""
	set list("^IRIS.IK.SD.DomProf")=""
	set list("^IRIS.IK.SD.Profile")=""
	set list("^IRIS.IK.SP.SrcDist")=""
	set list("^IRIS.IK.SP.Value")=""
	set list("^IRIS.IK.SentDetails")=""
	set list("^IRIS.IK.SentId")=""
	set list("^IRIS.IK.SentToSrc")=""
	set list("^IRIS.IK.SrcDetails")=""
	set list("^IRIS.IK.SrcExistsBit")=""
	set list("^IRIS.IK.SrcId")=""
	set list("^IRIS.IK.SrcToCcUniBit")=""
	set list("^IRIS.IK.SrcToCrcUniBit")=""
	set list("^IRIS.IK.SrcToEntUniBit")=""
	set list("^IRIS.IK.SrcToStemUniBit")=""	 
 	set list("^IRIS.IK.StemNgrams")=""	 
 	set list("^IRIS.IK.StemParts")=""	 
 	set list("^IRIS.IK.StemSrcDetails")=""	 
 	set list("^IRIS.IK.StemUni")=""	 
 	set list("^IRIS.IK.StemUniDetails")=""	 
 	set list("^IRIS.IK.StemUniExistsBit")=""	 
 	set list("^IRIS.IK.StemUniId")=""	 
 	set list("^IRIS.IK.StemUniIdFreq")=""	 
 	set list("^IRIS.IK.StemUniIdSpread")=""	 
 	set list("^IRIS.IK.StemUniRep")=""	 
 	set list("^IRIS.IK.StemUniToEntUni")=""	 
 	set list("^IRIS.IK.StemUniToOccBit")=""	 
 	set list("^IRIS.IK.StemUniToPathBit")=""	 
 	set list("^IRIS.IK.StemUniToSentBit")=""	 
 	set list("^IRIS.IK.StemUniToSrcBit")=""	
	
	// matching
	set list("^IRIS.IK.Mat.Dict")=""
	set list("^IRIS.IK.Mat.DictElemString")=""
	set list("^IRIS.IK.Mat.DictElemStringId")=""
	set list("^IRIS.IK.Mat.DictElement")=""
	set list("^IRIS.IK.Mat.DictElementId")=""
	set list("^IRIS.IK.Mat.DictFormat")=""
	set list("^IRIS.IK.Mat.DictFormatElements")=""
	set list("^IRIS.IK.Mat.DictFormatId")=""
	set list("^IRIS.IK.Mat.DictId")=""
	set list("^IRIS.IK.Mat.DictItemId")=""
	set list("^IRIS.IK.Mat.DictItemTerms")=""
	set list("^IRIS.IK.Mat.DictItemToMatch")=""
	set list("^IRIS.IK.Mat.DictItemURI")=""
	set list("^IRIS.IK.Mat.DictMatchStatus")=""
	set list("^IRIS.IK.Mat.DictTermElems")=""
	set list("^IRIS.IK.Mat.DictTermId")=""
	set list("^IRIS.IK.Mat.DictToFormat")=""
	set list("^IRIS.IK.Mat.DictToItem")=""
	set list("^IRIS.IK.Mat.DictToMatchBit")=""
	set list("^IRIS.IK.Mat.DictToSrcBit")=""
	set list("^IRIS.IK.Mat.DictToSrcMatchedBit")=""
	set list("^IRIS.IK.Mat.EntOccToMatch")=""
	set list("^IRIS.IK.Mat.EntUniToDictElem")=""
	set list("^IRIS.IK.Mat.MatchId")=""
	set list("^IRIS.IK.Mat.MatchInc")=""
	set list("^IRIS.IK.Mat.Profile")=""
	set list("^IRIS.IK.Mat.SentToMatchScore")=""
	set list("^IRIS.IK.Mat.SrcToMatch")=""
	
	// metadata
	set list("^IRIS.IK.Mdt.Field")=""
	set list("^IRIS.IK.Mdt.FieldId")=""
	set list("^IRIS.IK.Mdt.LovId")=""
	set list("^IRIS.IK.Mdt.LovValue")=""
	set list("^IRIS.IK.Mdt.UniValue")=""
	set list("^IRIS.IK.Mdt.UniValueId")=""
	set list("^IRIS.IK.Mdt.UniValueToSrc")=""
	set list("^IRIS.IK.Mdt.UniValueToSrcBit")=""
	set list("^IRIS.IK.Mdt.ValueToSrc")=""
	set list("^IRIS.IK.Mdt.ValueToSrcBit")=""
	set list("^IRIS.IK.Mdt.Values")=""
	
	// table customizations
	set list("^IRIS.IK.Idx.CRCO")=""
	set list("^IRIS.IK.Idx.EO")=""
	set list("^IRIS.IK.Idx.MD")=""
	set list("^IRIS.IK.Idx.MDI")=""
	set list("^IRIS.IK.Idx.MDT")=""
	set list("^IRIS.IK.Idx.MM")=""
	set list("^IRIS.IK.Idx.Path")=""
	set list("^IRIS.IK.Idx.Sent")=""
	
	// metrics (deprecated)
	set list("^IRIS.IK.Mtr.CcGrpValues")=""
	set list("^IRIS.IK.Mtr.CcSrcValues")=""
	set list("^IRIS.IK.Mtr.CcUniValues")=""
	set list("^IRIS.IK.Mtr.CrcGrpValues")=""
	set list("^IRIS.IK.Mtr.CrcSrcValues")=""
	set list("^IRIS.IK.Mtr.CrcUniValues")=""
	set list("^IRIS.IK.Mtr.EntGrpValues")=""
	set list("^IRIS.IK.Mtr.EntSrcValues")=""
	set list("^IRIS.IK.Mtr.EntUniValues")=""
	set list("^IRIS.IK.Mtr.Metric")=""
	set list("^IRIS.IK.Mtr.MetricId")=""
	set list("^IRIS.IK.Mtr.MetricTarget")=""
	set list("^IRIS.IK.Mtr.PathGrpValues")=""
	set list("^IRIS.IK.Mtr.PathSrcValues")=""
	set list("^IRIS.IK.Mtr.PathValues")=""
	set list("^IRIS.IK.Mtr.SentGrpValues")=""
	set list("^IRIS.IK.Mtr.SentSrcValues")=""
	set list("^IRIS.IK.Mtr.SentValues")=""
	set list("^IRIS.IK.Mtr.Sorted")=""
	set list("^IRIS.IK.Mtr.SrcGrpValues")=""
	set list("^IRIS.IK.Mtr.SrcSrcValues")=""
	set list("^IRIS.IK.Mtr.SrcValues")=""
	
	// system (cross-domain)
	set list("^IRIS.IK.Sys.ConfigD")=""
	set list("^IRIS.IK.Sys.ConfigI")=""
	set list("^IRIS.IK.Sys.Definition")=""
	set list("^IRIS.IK.Sys.DictFormatD")=""
	set list("^IRIS.IK.Sys.DictFormatI")=""
	set list("^IRIS.IK.Sys.DomainD")=""
	set list("^IRIS.IK.Sys.DomainI")=""
	set list("^IRIS.IK.Sys.DomainU")=""
	set list("^IRIS.IK.Sys.ListerAlias")=""
	set list("^IRIS.IK.Sys.ListerD")=""
	set list("^IRIS.IK.Sys.ListerI")=""
	set list("^IRIS.IK.Sys.NSParams")=""
	set list("^IRIS.IK.Sys.Params")=""
	set list("^IRIS.IK.Sys.ProcessorD")=""
	set list("^IRIS.IK.Sys.ProcessorI")=""
	set list("^IRIS.IK.Sys.StemmerConfigD")=""
	set list("^IRIS.IK.Sys.StemmerConfigI")=""
	set list("^IRIS.IK.Sys.UserDictD")=""
	set list("^IRIS.IK.Sys.UserDictEntry")=""
	set list("^IRIS.IK.Sys.UserDictI")=""
	
	// log
	set list("^IRIS.IKL.ErrorLog")=""
	set list("^IRIS.IKL.Errors")=""
	set list("^IRIS.IKL.Failed")=""
	set list("^IRIS.IKL.Log")=""
	set list("^IRIS.IKL.Mat.Errors")=""
	set list("^IRIS.IKL.QueryTimes")=""
	set list("^IRIS.IKL.SortTimings")=""
	set list("^IRIS.IKL.Timings")=""
	set list("^IRIS.IKL.Warning")=""
	
	// staging/temp
	set list("^IRIS.IKS.Globals")=""
	set list("^IRIS.IKT.Globals")=""
	set list("^IRIS.IKT.EntLocToUniId")=""
	set list("^IRIS.IKT.EntUniDetOld")=""
	set list("^IRIS.IKT.EntUniSToEntUniM")=""
	set list("^IRIS.IKT.EntUniToOcc")=""
	set list("^IRIS.IKT.InitLoc")=""
	set list("^IRIS.IKT.KeyCounter")=""
	set list("^IRIS.IKT.KeyInfo")=""
	set list("^IRIS.IKT.LitCounter")=""
	set list("^IRIS.IKT.LitInfo")=""
	set list("^IRIS.IKT.LitLocToUniId")=""
	set list("^IRIS.IKT.Mat.DictToMatch")=""
	set list("^IRIS.IKT.Mat.DictToSrc")=""
	set list("^IRIS.IKT.Mat.DictToSrcMatched")=""
	set list("^IRIS.IKT.NewEnts")=""
	set list("^IRIS.IKT.NewStems")=""
	set list("^IRIS.IKT.ProcessList")=""
	set list("^IRIS.IKT.SD.Ord")=""
	set list("^IRIS.IKT.StemCounter")=""
	
	// virtual source data
	set list("^IRIS.IKV.Att.Path")=""
	set list("^IRIS.IKV.Att.Sent")=""
	set list("^IRIS.IKV.BlackList")=""
	set list("^IRIS.IKV.BlackListElements")=""
	set list("^IRIS.IKV.BlackListId")=""
	set list("^IRIS.IKV.CcEntCombiFreq")=""
	set list("^IRIS.IKV.CcEntCombiSpread")=""
	set list("^IRIS.IKV.CcUni")=""
	set list("^IRIS.IKV.CcUniDet")=""
	set list("^IRIS.IKV.CcUniExists")=""
	set list("^IRIS.IKV.CcUniId")=""
	set list("^IRIS.IKV.CcUniIdFreq")=""
	set list("^IRIS.IKV.CcUniIdSpread")=""
	set list("^IRIS.IKV.CcUniToOcc")=""
	set list("^IRIS.IKV.CcUniToSent")=""
	set list("^IRIS.IKV.CcUniToSrc")=""
	set list("^IRIS.IKV.CrcEntUniFreq")=""
	set list("^IRIS.IKV.CrcEntUniSpread")=""
	set list("^IRIS.IKV.CrcOccId")=""
	set list("^IRIS.IKV.CrcSrcDetails")=""
	set list("^IRIS.IKV.CrcUni")=""
	set list("^IRIS.IKV.CrcUniDetails")=""
	set list("^IRIS.IKV.CrcUniExists")=""
	set list("^IRIS.IKV.CrcUniId")=""
	set list("^IRIS.IKV.CrcUniIdFreq")=""
	set list("^IRIS.IKV.CrcUniIdSpread")=""
	set list("^IRIS.IKV.CrcUniToOcc")=""
	set list("^IRIS.IKV.CrcUniToSent")=""
	set list("^IRIS.IKV.CrcUniToSrc")=""
	set list("^IRIS.IKV.DataLoaded")=""
	set list("^IRIS.IKV.DomainDetails")=""
	set list("^IRIS.IKV.EntOccId")=""
	set list("^IRIS.IKV.EntParts")=""
	set list("^IRIS.IKV.EntSrcDetails")=""
	set list("^IRIS.IKV.EntTypeToOcc")=""
	set list("^IRIS.IKV.EntUni")=""
	set list("^IRIS.IKV.EntUniDetails")=""
	set list("^IRIS.IKV.EntUniId")=""
	set list("^IRIS.IKV.EntUniIdFreq")=""
	set list("^IRIS.IKV.EntUniIdSpread")=""
	set list("^IRIS.IKV.EntUniMToCcUni")=""
	set list("^IRIS.IKV.EntUniMToCrcUni")=""
	set list("^IRIS.IKV.EntUniMToEntUniS")=""
	set list("^IRIS.IKV.EntUniRToCrcUni")=""
	set list("^IRIS.IKV.EntUniSToCcUni")=""
	set list("^IRIS.IKV.EntUniSToCrcUni")=""
	set list("^IRIS.IKV.EntUniSToEntUniM")=""
	set list("^IRIS.IKV.EntUniToOcc")=""
	set list("^IRIS.IKV.EntUniToPath")=""
	set list("^IRIS.IKV.EntUniToSent")=""
	set list("^IRIS.IKV.EntUniToSrc")=""
	set list("^IRIS.IKV.EntUniToStemUni")=""
	set list("^IRIS.IKV.Ext.Group")=""
	set list("^IRIS.IKV.Ext.GroupId")=""
	set list("^IRIS.IKV.Ext.LocalRef")=""
	set list("^IRIS.IKV.LitUni")=""
	set list("^IRIS.IKV.LitUniId")=""
	set list("^IRIS.IKV.Mat.Dict")=""
	set list("^IRIS.IKV.Mat.DictElemString")=""
	set list("^IRIS.IKV.Mat.DictElemStringId")=""
	set list("^IRIS.IKV.Mat.DictElement")=""
	set list("^IRIS.IKV.Mat.DictElementId")=""
	set list("^IRIS.IKV.Mat.DictId")=""
	set list("^IRIS.IKV.Mat.DictItemId")=""
	set list("^IRIS.IKV.Mat.DictItemTerms")=""
	set list("^IRIS.IKV.Mat.DictItemToMatch")=""
	set list("^IRIS.IKV.Mat.DictItemURI")=""
	set list("^IRIS.IKV.Mat.DictMatchStatus")=""
	set list("^IRIS.IKV.Mat.DictTermElems")=""
	set list("^IRIS.IKV.Mat.DictTermId")=""
	set list("^IRIS.IKV.Mat.DictToItem")=""
	set list("^IRIS.IKV.Mat.DictToMatchBit")=""
	set list("^IRIS.IKV.Mat.DictToSrcBit")=""
	set list("^IRIS.IKV.Mat.DictToSrcMatched")=""
	set list("^IRIS.IKV.Mat.EntOccToMatch")=""
	set list("^IRIS.IKV.Mat.EntUniToDictElem")=""
	set list("^IRIS.IKV.Mat.MatchId")=""
	set list("^IRIS.IKV.Mat.MatchInc")=""
	set list("^IRIS.IKV.Mat.Profile")=""
	set list("^IRIS.IKV.Mat.SentToMatchScore")=""
	set list("^IRIS.IKV.Mat.SrcToMatch")=""
	set list("^IRIS.IKV.Mdt.Field")=""
	set list("^IRIS.IKV.Mdt.FieldId")=""
	set list("^IRIS.IKV.Mdt.ValueToSrc")=""
	set list("^IRIS.IKV.Mdt.Values")=""
	set list("^IRIS.IKV.PathDetails")=""
	set list("^IRIS.IKV.PathId")=""
	set list("^IRIS.IKV.PathToEntOcc")=""
	set list("^IRIS.IKV.PathToSent")=""
	set list("^IRIS.IKV.PathToSrc")=""
	set list("^IRIS.IKV.RealCcUniMap")=""
	set list("^IRIS.IKV.RealCrcUniMap")=""
	set list("^IRIS.IKV.RealEntUniMap")=""
	set list("^IRIS.IKV.RealStemUniMap")=""
	set list("^IRIS.IKV.SD.DomProf")=""
	set list("^IRIS.IKV.SD.Profile")=""
	set list("^IRIS.IKV.SP.SrcDist")=""
	set list("^IRIS.IKV.SP.Value")=""
	set list("^IRIS.IKV.SentDetails")=""
	set list("^IRIS.IKV.SentId")=""
	set list("^IRIS.IKV.SentToSrc")=""
	set list("^IRIS.IKV.SrcCreated")=""
	set list("^IRIS.IKV.SrcDetails")=""
	set list("^IRIS.IKV.SrcExistsBit")=""
	set list("^IRIS.IKV.SrcId")=""
	set list("^IRIS.IKV.SrcToCcUniBit")=""
	set list("^IRIS.IKV.SrcToCrcUniBit")=""
	set list("^IRIS.IKV.SrcToEntUniBit")=""
	set list("^IRIS.IKV.SrcToStemUniBit")=""
	set list("^IRIS.IKV.StemUni")=""	 
 	set list("^IRIS.IKV.StemUniDetails")=""	 
 	set list("^IRIS.IKV.StemUniId")=""	 
 	set list("^IRIS.IKV.StemUniIdFreq")=""	 
 	set list("^IRIS.IKV.StemUniRep")=""	 
 	set list("^IRIS.IKV.StemUniToEntUni")=""	 
 	set list("^IRIS.IKV.StemUniToPath")=""
 	
 	// older SD globals used in deprecated %iKnow.Semantics.DominanceAPI queries
 	set list("^IRIS.IK.SD.BreakingSrcs")=""
 	set list("^IRIS.IK.SD.BreakingSrcsOrd")=""
 	set list("^IRIS.IK.SD.Overlap")=""
 	set list("^IRIS.IK.SD.OverlapVal")=""
 	set list("^IRIS.IK.SD.SrcOverlap")=""
 	set list("^IRIS.IK.SD.TypicalSrcs")=""
 	set list("^IRIS.IK.SD.TypicalSrcsOrd")=""
	
	quit $$$OK
}

/// Is used to get the value of an unknown property, redirecting to the domain parameter.
Method %DispatchGetProperty(Property As %String) [ ServerOnly = 1 ]
{
	set tValue = ..GetParameter(Property, .tDefinedAt)
	quit:tDefinedAt="DOMAIN" tValue
	quit ""
}

/// is used to set the value of an unknown property, redirecting to the domain parameter.
Method %DispatchSetProperty(Property As %String, Val) [ ServerOnly = 1 ]
{
	quit ..SetParameter(Property, Val)
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ ServerOnly = 0 ]
{
	quit "" // not supported!
}

ClassMethod %DeleteExtent(concurrency As %Integer = -1, ByRef deletecount, ByRef instancecount, pInitializeExtent As %Integer = 1) As %Status [ ServerOnly = 0 ]
{
	quit $$$ERROR($$$MethodNotImplemented,"%iKnow.Domain:%DeleteExtent")
}

ClassMethod %KillExtentData(killstreams As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	quit $$$ERROR($$$MethodNotImplemented,"%iKnow.Domain:%KillExtentData")
}

/// This method assigns <var>pDomainId</var> as this domain's desired <property>Id</property> property,
/// if no value has been set so far. If the value is already taken when calling this method, an error
/// will be returned. If the value has already been taken by the time this domain object is saved,
/// the next available ID value will be assigned.
Method AssignId(pDomainId As %Integer) As %Status [ Internal ]
{
	quit:..Id $$$ERROR($$$GeneralError, "ID for this domain has already been set")
	quit:..%ExistsId(pDomainId) $$$ERROR($$$GeneralError, "ID already taken")
	set i%Id = pDomainId
	quit $$$OK
}

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="BuildFlags">
<Piece>4</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Data name="Version">
<Piece>3</Piece>
</Data>
<Global>^IRIS.IK.Sys.DomainD</Global>
<Subscript name="1">
<Expression>{Id}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="NameIndex">
<Data name="Id"/>
<Global>^IRIS.IK.Sys.DomainI</Global>
<RowIdSpec name="1">
<Expression>{Id}</Expression>
<Field>Id</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>$$$UPPER({Name})</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Sys.DomainS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
