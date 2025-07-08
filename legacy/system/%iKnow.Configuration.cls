/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This class groups the configuration parameters to drive the iKnow Smart Indexing algorithm
/// as executed by the iKnow engine (external libraries). Configurations are referred to by name
/// and can be used across domains within the same namespace.</p>
/// <p>When creating a configuration, you can pass initial values for the following properties
/// to its <method>%New</method> method:
/// <ol>
/// 	<li><property>Name</property> (required)</li>
/// 	<li><property>DetectLanguage</property></li>
/// 	<li><property>Languages</property></li>
/// 	<li><property>UserDictionary</property></li>
/// 	<li><property>Summarize</property></li>
/// </ol>
/// Check the respective property descriptions for more details.</p>
Class %iKnow.Configuration Extends %Persistent [ Deprecated, Final, StorageStrategy = iKnowStorage, System = 4 ]
{

Property Id As %Integer [ Internal, ReadOnly ];

/// The name of this configuration, which should be unique within the namespace (case-insensitive)
Property Name As %String [ ReadOnly ];

/// Whether or not to use Automatic Language Identification
Property DetectLanguage As %Boolean;

/// The list of languages the engine should take into account when processing the text.
Property Languages As %List;

/// The name to the User Dictionary to use for rewriting and standardizing input as it is
/// read by the engine. See also <class>%iKnow.UserDictionary</class>.
/// Alternatively, the path to a file-based User Dictionary can be supplied.
Property UserDictionary As %String(MAXLEN = 1000);

/// This setting is deprecated. Summaries are now generated at query time.
Property Summarize As %Integer [ Deprecated, InitialExpression = 1 ];

/// Maximum cluster length. Advanced use only.
Property MaxConceptLength As %Integer(MINVAL = 0) [ Internal ];

Property IsTransient As %Boolean [ Internal, Private, Transient ];

Index PKINDEX On Id [ IdKey, PrimaryKey, Unique ];

Index NameIndex On Name [ Unique ];

/// Private Indexer object for <method>Normalize</method> method.
Property Indexer As %iKnow.Indexer [ Internal, Private, Transient ];

/// Automatically (re)create the default configuration
ClassMethod CreateDefaultConfig() As %Status [ Internal ]
{
	quit:..NameIndexExists($$$DEFAULTCONFIG) $$$OK
	set tConfig = ##class(%iKnow.Configuration).%New($$$DEFAULTCONFIG)
	quit $s($isobject(tConfig):tConfig.%Save(), ..NameIndexExists($$$DEFAULTCONFIG):$$$OK, 1:$g(%objlasterror))
}

/// Create a new Configuration object using the specified parameters
/// <p><b>Deprecated</b>: Please use <method>%New</method> and <method>%Save</method></p>
ClassMethod Create(name As %String, DetectLanguage As %Integer = 0, languages As %List = {$lb("en")}, userDictionary As %String = "", summarize As %Integer = 1, maxConceptLength As %Integer = 0, Output sc As %Status = {$$$OK}) As %iKnow.Configuration [ Deprecated ]
{
	set tConfig = ..%New(name, DetectLanguage, languages, userDictionary, summarize, maxConceptLength)
	
	if ($g(tConfig)="") {
		set sc = %objlasterror
		quit ""
	}
	
	set sc = tConfig.%Save()
	quit:$$$ISERR(sc) ""
	
	quit tConfig
}

/// Opens the Configuration object with the supplied name.
/// When requesting the default configuration ($$$DEFAULTCONFIG), it will be created if it didn't
/// exist yet for this namespace.
ClassMethod Open(name As %String, Output pSC As %Status = {$$$OK}) As %iKnow.Configuration
{
	set pSC = $$$OK
	set:(name=$$$DEFAULTCONFIG) pSC = ..CreateDefaultConfig()
	quit ..NameIndexOpen(name)
}

/// Opens the Configuration object with the supplied ID
/// <p><b>Deprecated</b>: Please use <method>%OpenId</method></p>
ClassMethod OpenId(id As %Integer) As %iKnow.Configuration [ Deprecated ]
{
    quit ..%OpenId(id)
}

/// Checks whether a Configuration object exists with the given name
/// <p><b>Deprecated</b>: Please use <method>NameIndexExists</method></p>
ClassMethod Exists(name As %String) As %Boolean [ Deprecated ]
{
    quit ..NameIndexExists(name)
}

/// Deletes a named configuration
/// <p><b>Deprecated</b>: Please use <method>NameIndexOpen</method> and <method>%DeleteId</method></p>
ClassMethod Delete(configName As %String) As %Status [ Deprecated ]
{
	set config = ##class(%iKnow.Configuration).Open(configName)
	quit:config="" $$$ERROR($$$IKConfigurationNotFound, configName)
	quit ..DeleteId(config.Id)
}

/// Deletes a configuration specified by ID
/// <p><b>Deprecated</b>: Please use <method>%DeleteId</method></p>
ClassMethod DeleteId(configId As %String) As %Status [ Deprecated ]
{
	quit ..%DeleteId(configId)
}

/// Creates a Configuration object with the specified parameters.
/// <p>Note: Use of the <var>pMaxConceptLength</var> parameter is deprecated as from 2013.2</p>.
Method %OnNew(pName As %String, pDetectLanguage As %Integer = 0, pLanguages As %List = {$lb("en")}, pUserDictionary As %String = "", pSummarize As %Integer = 1, pMaxConceptLength As %Integer = 0, pTransient As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		if 'pTransient { $$$IKCHECKPRIVADMINX(tSC) }
		$$$IKCHECKNOTNULLX(pName,tSC)
		$$$IKCHECKSTRINGLENGTHX(pName,tSC)
		
		// check for name uniqueness right away, as it's a read-only propery
		// and the index is only validated after %OnBeforeSave() otherwise
		if ..NameIndexExists(pName) {
			set tSC = $$$ERROR($$$IKConfigurationExists, pName)
			quit
		}
        
	    set i%Name = pName
	    set i%DetectLanguage = pDetectLanguage
        $$$IKENSURELISTSTR(pLanguages)
	    set i%Languages = pLanguages
	    set i%UserDictionary = pUserDictionary
	    set i%Summarize = pSummarize
	    set i%MaxConceptLength = pMaxConceptLength
	    set i%IsTransient = pTransient
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
    quit tSC
}

Method ResolveLanguage(tLanguage) As %String [ Internal ]
{
	set tLangId = $lf($$$IKLANGUAGES,$$$LOWER(tLanguage))
	quit:tLangId $list($$$IKLANGUAGES,tLangId)
	set tLanguage = $tr(tLanguage,"_ ","--"), tLangId=0
	for i = 1:1:$l(tLanguage,"-") {
		set tLangCode = $p(tLanguage,"-",i)
		continue:$l(tLangCode)'=2
		set:tLangCode="jp" tLangCode = "ja"
		set tLangId = $lf($$$IKLANGUAGES,tLangCode)
		quit:tLangId
	}
	quit:tLangId $list($$$IKLANGUAGES,tLangId)
	quit ""
}

/// Configures an %iKnow.Indexer object with the settings stored in this Configuration object
Method ConfigureIndexer(indexer As %iKnow.Indexer) As %Status [ Internal ]
{
    set tSC = $$$OK
    try {
    
	    // Setup indexer
	    set sc=indexer.EnableMergeRelations()
	    quit:$$$ISERR(sc)
    
	    // clear previously loaded languages and User Dictionary
		set sc = indexer.UnloadAllKnowledgebases()
		quit:$$$ISERR(sc)
		set sc = indexer.UnloadAllLanguagebases()
		quit:$$$ISERR(sc)
	    Set sc=indexer.ClearUserDictionary()
	    quit:$$$ISERR(sc)
    
	    // load new user dictionary, if required
	    if i%UserDictionary'="" {
	    
	    	// BDB309 - use OpenByName() method, which will revert to file-based UDs
	    	// if no appropriately named persistent %iKnow.UserDictionary entry is found.
		    set tUserDict = ##class(%iKnow.UserDictionary).OpenByName(i%UserDictionary)
		    if '$isobject(tUserDict) {
				set sc = $$$ERROR($$$IKNoUserDictWithName, i%UserDictionary)
				quit
			}
		
	        set sc=indexer.LoadUserDictionary(i%UserDictionary, tUserDict)
	        quit:$$$ISERR(sc)
	        set sc=indexer.SetUserDictionary(i%UserDictionary)
	        quit:$$$ISERR(sc)
	        set tUserDict=""
		}
    
    	// whether or not ALI is switched on, load all languages supplied as they
    	// might be referenced through $$$IKPLANGUAGEFIELDNAME
		for i=1:1:$listlength(i%Languages) {
	        set lang=$list(i%Languages,i)
	        
	        // load the knowledge base
	        set sc=indexer.LoadKnowledgebase(lang,##class(%iKnow.KB.Knowledgebase).GetByName(lang))
	        quit:$$$ISERR(sc)
	        
	        // if ALI is switched on, load the language base as well
	        if (i%DetectLanguage) {
		        set sc=indexer.LoadLanguagebase(lang,##class(%iKnow.LB.Languagebase).GetByName(lang))
		        quit:$$$ISERR(sc)
	        }
	    }
	    quit:$$$ISERR(sc)
    
    	// configure the summary flag
	    if 'i%Summarize {
	        set sc=indexer.DisableSummarizer()
	    } else {
	        set sc=indexer.EnableSummarizer()
	    }
	    quit:$$$ISERR(sc)
    
    	// configure the MaxConceptLength flag if set
	    if +i%MaxConceptLength {
		    set sc=indexer.SetMaxConceptLength(i%MaxConceptLength)
	    }
		quit:$$$ISERR(sc)
   
    } catch (ex) {
	    set sc = ex.AsStatus()
    }
    
    // log any configuration errors
	if $$$ISERR(sc) {
		$$$IKERROR(0,sc,..%ClassName(1)_":ConfigureIndexer")
	}
	
    quit sc
}

/// Simple class query to retrieve all the configurations for this Namespace.
/// <p><b>Deprecated</b>: Please use normal SQL queries to approach this class.</p>
Query GetAllConfigurations() As %Query(ROWSPEC = "configId:%Integer,configName:%String,detectLanguage:%Integer,languages:%String,userDictionary:%String,summarize:%Integer,maxConceptLength:%Integer") [ Deprecated, SqlProc ]
{
}

ClassMethod GetAllConfigurationsExecute(ByRef qHandle As %Binary) As %Status [ Internal ]
{
	$$$IKCHECKPRIVREAD
	
    Set qHandle = ""
    Quit $$$OK
}

ClassMethod GetAllConfigurationsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetAllConfigurationsExecute ]
{
   Quit $$$OK
}

ClassMethod GetAllConfigurationsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetAllConfigurationsExecute ]
{
    Set tData = ""
    Set qHandle = $order(^IRIS.IK.Sys.ConfigD(qHandle),1,tData)
    If qHandle = "" {
        Set AtEnd = 1, Row = ""
        Quit $$$OK
    }
    While qHandle '= "" {
        If (tData '= "") {
            Set Row = $lb(qHandle, $lg(tData,1), $lg(tData,2), $lts($lg(tData,3)), $lg(tData,4), $lg(tData,5), $lg(tData,6))
            Quit
        }

        Set tData = ""
        Set qHandle = $order(^IRIS.IK.Sys.ConfigD(qHandle),1,tData)
    }
    If qHandle = "" Set AtEnd = 1
    Quit $$$OK
}

Method %OnBeforeSave(insert As %Boolean) As %Status [ Private, ServerOnly = 1 ]
{
	if i%IsTransient {
		quit $$$ERROR($$$GeneralError, "Cannot save a transient config!")
	}
	
	$$$IKCHECKPRIVADMIN
	
	set tSC = $$$OK
	try {
		
		if (insert) {
	        // if OK, fetch new ID and populate properties
    	    set i%Id = $i(^IRIS.IK.Sys.ConfigD)
		} else {
			set tSC = ..CheckIfManaged(##this)
			quit:$$$ISERR(tSC)
		}
        
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod LanguagesIsValid(pLanguages As %String) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
        
        // check if a valid list of languages is supplied
        if '$listvalid(pLanguages) || (pLanguages="") {
            set tSC = $$$ERROR($$$IKLanguagesMustBeList)
            quit
        }  
        
        // check if we recognize all language codes
        kill tSupportedLangs
        set i=""
        for {
         	set i = $order(^%iKnow("KB","KnowledgebaseD",i),1,tLangInfo)
         	quit:i=""
         	set tLanguage = $lg(tLangInfo,2)
         	continue:tLanguage=""
         	set tSupportedLangs(tLanguage) = ""
        }
        set ptr=0
        while $listnext(pLanguages,ptr,tLanguage) {
            if '$d(tSupportedLangs(tLanguage)) {
	            set tSC = $$$ERROR($$$IKLanguageDoesNotExist,tLanguage)
	            quit
            }
        }
        quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %ConstructClone(deep As %Boolean = 0, ByRef cloned As %String, location As %String) As %RegisteredObject [ ServerOnly = 0 ]
{
	quit "" // not supported!
}

ClassMethod %DeleteExtent(concurrency As %Integer = -1, ByRef deletecount, ByRef instancecount, pInitializeExtent As %Integer = 1) As %Status [ ServerOnly = 0 ]
{
	quit $$$ERROR($$$MethodNotImplemented,"%iKnow.Configuration:%DeleteExtent")
}

ClassMethod %KillExtentData(killstreams As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
	quit $$$ERROR($$$MethodNotImplemented,"%iKnow.Configuration:%KillExtentData")
}

ClassMethod CheckIfManaged(pConfig As %iKnow.Configuration) As %Status [ Internal ]
{
	set tSC = $$$OK
		try {
		set tManager = ""
		for {
			set tManager = $order(^IRIS.IK.Sys.Definition(tManager))
			quit:tManager=""
			quit:$d(^IRIS.IK.Sys.Definition(tManager,"config",pConfig.Id))
		}
		quit:tManager=""
		$$$IKCHECKMGRX("Configuration",pConfig.Name,tManager,tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVADMIN
	
	set tSC = $$$OK
	try {
		set tConfig = ..%Open(oid)
		if tConfig="" { set tSC = $$$ERROR($$$IKNoConfigWithId, oid)  quit }
		
		set tSC = ..CheckIfManaged(tConfig)
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Takes an input string <var>pString</var> and returns its normalized form as returned by the
/// iKnow engine. Using this method will ensure a string has the same form as any results (entities)
/// returned by the engine as a result of iKnow indexing with this Configuration object.</p>
/// <p>More specifically, this normalization takes into account the following properties:</p>
/// <ul>
/// 	<li>User Dictionary literal input substitutions.</li>
/// 	<li>Language model preprocess filters.</li>
/// 	<li>Character normalization (lower casing and some punctuation separation)</li>
/// 	<li>Whitespace compression.</li>
/// 	<li>Entity filters.</li>
/// </ul>
/// <p>Input substitution adheres to the User Dictionary as specified in the <property>UserDictionary</property>
/// property of this Configuration. If not specified through <var>pLanguage</var> (as a two-letter
/// language code), the language will be randomly selected by the engine from the list specified
/// in this Configuration's <property>Languages</property> property, so it's recommended to
/// supply a value for <var>pLanguage</var> if <property>Languages</property> contains more than
/// one entry. If specified, <var>pLanguage</var> should appear in <property>Languages</property></p>
/// <p>See also <method>NormalizeWithParams</method> to normalize without a Configuration object.</p>
Method Normalize(pString As %String, pLanguage As %String = "", Output pSC As %Status = {$$$OK}, pCleanPunctuation As %Boolean = 1) As %String
{
	set pSC = $$$OK, tNormalized = ""
	try {
		
		if (..Indexer="") {
			set ..Indexer = ##class(%iKnow.Indexer).%New()
			if (..Indexer="") { set pSC = %objlasterror quit }
			
			set pSC = ..ConfigureIndexer(..Indexer)
			quit:$$$ISERR(pSC)
		}
		
		// BDB765 - Explicitly pass language to normalize method to avoid it picking the UD
		set:(pLanguage="") pLanguage = $lg(i%Languages,1)
		
		set pSC = ..Indexer.Normalize(pString, .tNormalized, pLanguage,, pCleanPunctuation)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tNormalized
}

/// <p>Takes an input string <var>pString</var> and returns its normalized form as returned by the
/// iKnow engine. Using this method will ensure a string has the same form as any results (entities)
/// returned by the engine as a result of indexing operations.</p>
/// <p>More specifically, this normalization takes into account the following properties:</p>
/// <ul>
/// 	<li>User Dictionary literal input substitutions.</li>
/// 	<li>Language model preprocess filters.</li>
/// 	<li>Character normalization (lower casing and some punctuation separation)</li>
/// 	<li>Whitespace compression.</li>
/// 	<li>Entity filters.</li>
/// </ul>
/// <p>Input substitution adheres to the User Dictionary as specified through <var>pUserDictionary</var>
/// and the preprocess filters for language <var>pLanguage</var> are used.</p>
/// <p>See also <method>Normalize</method> to normalize using an existing Configuration object.</p>
ClassMethod NormalizeWithParams(pString As %String, pLanguage As %String = "en", pUserDictionary As %String = "", Output pSC As %Status = {$$$OK}, pCleanPunctuation As %Boolean = 1) As %String
{
	set pSC = $$$OK, tNormalized = ""
	try {
		// create transient object
		set tConfig = ..CreateTransientConfig(pLanguage, pUserDictionary, .pSC)
		quit:$$$ISERR(pSC)
		
		set tNormalized = tConfig.Normalize(pString, pLanguage, .pSC, pCleanPunctuation)
		set tConfig = ""
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tNormalized
}

ClassMethod CreateTransientConfig(pLanguage As %String = "en", pUserDictionary As %String = "", Output pSC As %Status = {$$$OK}) As %iKnow.Configuration [ Internal ]
{
	set pSC = $$$OK, tConfig = $$$NULLOREF
	try {
		set pLanguage = $$$LOWER(pLanguage)
		if '$lf($$$IKLANGUAGES, pLanguage) {
			set pSC = $$$ERROR($$$IKLanguageDoesNotExist, pLanguage)
			quit
		}
		
		// create object
		set tConfig = ..%New("TempConfig"_$r(9999999), 0, $lb(pLanguage), pUserDictionary,,,1)
		if (tConfig="") { set pSC = %objlasterror  quit }
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tConfig
}

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="MainMap">
<Data name="DetectLanguage">
<Piece>2</Piece>
</Data>
<Data name="Languages">
<Piece>3</Piece>
</Data>
<Data name="MaxConceptLength">
<Piece>6</Piece>
</Data>
<Data name="Name">
<Piece>1</Piece>
</Data>
<Data name="Summarize">
<Piece>5</Piece>
</Data>
<Data name="UserDictionary">
<Piece>4</Piece>
</Data>
<Global>^IRIS.IK.Sys.ConfigD</Global>
<Subscript name="1">
<Expression>{Id}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="NameIndex">
<Data name="Id"/>
<Global>^IRIS.IK.Sys.ConfigI</Global>
<RowIdSpec name="1">
<Expression>{Id}</Expression>
<Field>Id</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>$$$UPPER({Name})</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Sys.ConfigS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
