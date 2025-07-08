/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IFInclude, %IKInclude)

IncludeGenerator (%IFInclude, %IKInclude)

/// <p>This class offers a subset of the full-text search capabilities brought by 
/// <class>%iFind.Index.Basic</class> with a minimal storage footprint. The following Basic
/// features are <u>not</u> available for a Minimal index:</p>
/// <ul>
/// <li>Positional search: e.g. "[five tickets]", "[aspirin ? daily]</li>
/// <li>Cooccurence search: e.g. "[ketchup, mayonaise, 5]"</li>
/// <li>Highlighting search results</li>
/// <li>Ranking search results</li>
/// </ul>
/// <p>See the class reference of <class>%iFind.Index.Basic</class> for a detailed overview
/// of available search capabilities.</p>
Class %iFind.Index.Minimal Extends (%Library.FunctionalIndex, %Compiler.Type.Embedded) [ EmbeddedClass = %iFind.Find.Minimal, System = 2 ]
{

Parameter FILER [ Internal ] = "%iFind.Filer.Minimal";

/// This parameter can be set to 1 if the implementation of the filing interface and the SQL query interface can be 
/// executed on a shard server.  The default is 0.  If a sharded class attempts to use a functional index where 
/// SUPPORTSSHARDING = 0, a class compiler error will be returned.
Parameter SUPPORTSSHARDING = 1;

/// Language to use when indexing records. 
/// Use "*" to enable automatic language detection. 
Parameter LANGUAGE As STRING = "en";

/// Specific indexing options to use when processing records.
/// <ul><li>0 = Do not store compounds or stems</li>
/// <li>1 = Store word-level stems</li>
/// <li>2 = Store word-level compounds and stems</li></ul>
/// <p>See also <class>%iKnow.Stemmer</class> and <class>%iKnow.Stemming.DecompoundUtils</class>
/// for more details on stemming or decompounding, or <parameter>TRANSFORMATIONSPEC</parameter>
/// for advanced options to use custom transformations.</p>
Parameter INDEXOPTION [ Constraint = "0,1,2" ] = 0;

/// Whether or not to convert content to lowercase before indexing. 
/// When set to 1 (default), searches are always case-insensitive. 
/// When set to 0, searching will be case-sensitive.
Parameter LOWER As BOOLEAN = 1;

/// <p>This parameter controls which user dictionary should be used to rewrite or annotate text before
/// it is processed by the NLP engine. See 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25iFind.Index.Minimal+USERDICTIONARY">NLP User Dictionaries</a>
/// in the NLP documentation.</p>
/// <p>This parameter is for advanced use only and empty by default.</p>
Parameter USERDICTIONARY As STRING;

/// <p>This parameter can be used to override the default stemming implementation when 
/// <parameter>INDEXOPTION</parameter> &gt; 0. To do so, set this parameter to a saved
/// <class>%iKnow.Stemming.Configuration</class> instance. This parameter has no effect if 
/// <parameter>INDEXOPTION</parameter> = 0.</p>
/// <p>This parameter is for advanced use only and empty by default.</p>
Parameter STEMMINGCONFIG As STRING;

/// <p>When this parameter is set to 1, additional SQL projections will be created upon compiling
/// the class. These are accessible as read-only tables in a package named [<i>package_name</i>]_[<i>class_name</i>]
/// and have names starting with [<i>class_name</i>]_[<i>index_name</i>] (which can be overridden
/// through <parameter>IFINDADVANCEDSQLPREFIX</parameter>).<p>
/// <p>By default, the following mappings are generated for an %iFind.Index.Minimal index:</p>
/// <ul>
/// <li><b>[<i>class_name</i>]_[<i>index_name</i>]_WordRec</b>: stores which words appear in each
/// record in this index. See also <class>%iFind.Index.AbstractWordRec</class>.</li>
/// </ul>
/// <p>Additional classes will be generated automatically, based on your index class and parameters.
/// See the class reference for subclasses for more details.<p>
Parameter IFINDMAPPINGS As BOOLEAN = 0;

/// <p>When generating SQL projections of iFind index data using the <parameter>IFINDMAPPINGS</parameter>),
/// this parameter overrides the naming of those classes, using this parameter's value instead of the default
/// [<i>class_name</i>]_[<i>index_name</i>] prefix. The projections will still be created in the 
/// [<i>package_name</i>]_[<i>class_name</i>] package.</p>
Parameter IFINDADVANCEDSQLPREFIX As STRING;

/// This parameter enables specifying whether words, entities and similar data should be written
/// to the shared %iFind.Word, %iFind.Entity and similar tables (<parameter>IFINDSHAREDDATALOCATION</parameter>="NAMESPACE",
/// default), or whether it should be stored in index-specific tables (<parameter>IFINDSHAREDDATALOCATION</parameter>="INDEX").
/// In the latter case, mappings will be generated for these tables if <parameter>IFINDMAPPINGS</parameter>
/// is set to 1.
Parameter IFINDSHAREDDATALOCATION As STRING [ Constraint = "NAMESPACE,INDEX" ];

/// <p>This parameter defines the word transformation(s) to apply to input text, such as stemming, decompounding
/// and other operations for "normalizing" words, so searches can scan these normalized forms rather
/// than the literal forms. <br/>This parameter cannot be set in conjunction with the <parameter>INDEXOPTION</parameter>
/// and/or <parameter>STEMMINGCONFIG</parameter> parameters, which are shorthands for configuring stemming
/// and decompounding options and overriding the default configurations for those.<br />
/// This parameter also allows using custom transformations by specifying the name of a class that
/// inherits from <class>%iFind.Transformation.Abstract</class>, optionally followed by a colon and 
/// string that will be passed onto the Transform method of the transformation class if it accepts
/// any parameters.</p>
Parameter TRANSFORMATIONSPEC As STRING;

/// <p>If the class you wish to add an iFind index on does not have an bitmap-compatible IDKEY 
/// (composed of a single positive integer property), use this parameter to refer to another property
/// in this class that has is bitmap-compatible. This will allow you to use iFind as usual, with the
/// exception that this property (rather than %ID or ID) should be passed to the %FIND operator in 
/// SQL statements querying the index:</p>
/// <example language="SQL">SELECT * FROM ThePackage.MyClass
/// 	WHERE MyIntProp %FIND search_index(MyBasicIndex, 'interesting')</example>
/// <p>Note that the regular ID column should still be used when invoking the <method>Rank</method>
/// and <method>Highlight</method> methods for these indices.</p>
Parameter INTKEYPROPERTY As STRING [ Deprecated, Internal ];

/// <p>This parameter controls whether leading and trailing punctuation is ignored in its 
/// entirety or not for this index and associated searches. If set to 0, the index will also
/// track words with adjacent punctuation to enable specifically searching for those
/// occurrences.</p>
Parameter IGNOREPUNCTUATION As BOOLEAN = 1;

/// 	Inserts the iFind index for the row
/// THROW: This method throws exceptions.
ClassMethod InsertIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, ServerOnly = 1 ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit $$$OK")
			quit $$$OK
		}
	
		if $get($$$EXTIDXGLOBAL($$$pEXT,%class,%property,$$$IFGLOBALINDEXLOC)) = "" { do ##class(%Compiler.iFind.Index).GenerateGlobalNames(%class,%property) } 
		set tIndexLocation = $$$EXTIDXGLOBAL($$$pEXT,%class,%property,$$$IFGLOBALINDEXLOC)
		set tIndexLocationQ = $$$QUOTE(tIndexLocation)

		// Parse index properties
		do parseIndexProperties^%occStorageCompiler(%class,%property,.prop,.issubval)
		
			// Get index property names and types
		set propNames = prop
		for p=1:1:prop {
			set propNames(p) = $listbuild(prop(p),$get($$$EXTPROPtype($$$pEXT,%class,prop(p))))
		}
		
		set tIndex = ##class(%Dictionary.CompiledIndex).IDKEYOpen(%class,%property)
		if $isobject(tIndex) {									
			set tKey = ""
			set tIndexProperty = tIndex.PropertyCollection.GetNext(.tKey)
			set tIndexVars=""
			
			while $isobject(tIndexProperty) {
				set tIndexVars = tIndexVars_"pArg("_tIndexProperty.Name_"),"
				set tIndexProperty = tIndex.PropertyCollection.GetNext(.tKey)
			}
		}

		// BDB541 - get index parameters
		$$$GENERATE($char(9)_"do .."_%property_"GetIndexParams(.tParams)")
		
		
		// resolve filer
		set filer=$get(%parameter("FILER"))
		set:filer="" filer="%iFind.Filer."_$piece($classname(),".",*)
		
		// BDB593 - use NoEngine filer when we can
		// BDB688 - never use NoEngine for Japanese
		if $e(filer)="%" {
			set tNoEngine = ((filer="%iFind.Filer.Minimal") || (filer="%iFind.Filer.Basic")) && ($g(%parameter("USERDICTIONARY"))="") && ($g(%parameter("LANGUAGE"))'="*") && ($g(%parameter("LANGUAGE"))'[",") && ($g(%parameter("LANGUAGE"))'="ja")
			set:tNoEngine filer = filer_"NE", %parameter("FILER")=filer, %parameter("FILER:NoIndex")=1
		} else {
			// BDB864 - custom filers are always NoEngine
			set tNoEngine = 1, %parameter("FILER:NoIndex")=1
		}
		
		// BDB675 - if this class customizes storage, we need to create a separate filer class
		set tSharedDataLocation = $g(%parameter("IFINDSHAREDDATALOCATION"))
		set:tSharedDataLocation="" tSharedDataLocation = "NAMESPACE"
		if tSharedDataLocation'="NAMESPACE" {
			try {
				set tFilerClassName = ##class(%iFind.Index.ClassGenerator.Abstract).GenerateClassName(%class,%property_"Filer",.tHasLock,.tSC)
				quit:$$$ISERR(tSC)
				if tFilerClassName="" { set tSC = $$$ERROR($$$GeneralError,"Unable to create filer class") quit }
				
				set tFilerClass = ##class(%Dictionary.ClassDefinition).%New()
				set tFilerClass.Name = tFilerClassName
				set tFilerClass.Super = filer
				set tFilerClass.Hidden = 1
				set tFilerClass.ProcedureBlock = 1
				set tFilerClass.GeneratedBy = %class_".CLS"
				set tFilerClass.Description = "INTERNAL CLASS - DO NOT INVOKE"
				
				set tParam = ##class(%Dictionary.ParameterDefinition).%New()
				set tParam.Name = "INDEXLOCATIONSHARED"
				$$$GetSharedLocation(tSharedDataLocation,tIndexLocation,tSharedDataLocationGlo)
				set tParam.Default = tSharedDataLocationGlo
				do tFilerClass.Parameters.Insert(tParam)
				
				set tSC = tFilerClass.%Save()
				quit:$$$ISERR(tSC)
				
				// register as dependent class and queue for compilation
				$$$comClassArraySet(%class,$$$cCLASSclasses,tFilerClassName_".CLS","")
				do QueueClass^%occCompile(tFilerClassName)
				
			} catch (ex) {
				set tSC = ex.AsStatus()
			}
			set:$g(tHasLock) x = $$UnlockOneClass^%occLock(tFilerClassName,3,1)
			if $$$ISERR(tSC) { 
				set:$d(tFilerClassName)&&$$$defClassDefined(tFilerClassName) x = $$Delete^%apiOBJ(tFilerClassName,"-d")
				$$$ThrowStatus(tSC)
			}
			
			set (filer,%parameter("FILER")) = tFilerClassName
		}
		
		// BDB668 - translate to integer prop if required
		if $d(%parameter("INTKEYPROPERTY"),tIntKeyProp) && (tIntKeyProp'="") {
			$$$GENERATE("	set pID = ##class("_%class_").%OpenId(pID)."_tIntKeyProp)
		}
		
		if (propNames=1) {
			if 'tNoEngine {
				$$$GENERATE($char(9)_"set tLanguage = tParams(""LANGUAGE"")")
				$$$GENERATE($char(9)_"do ($system.Context.iFind()).GetIndexer(tLanguage,.tDirect,.tIndexer)")
				
				if ($g(%parameter("USERDICTIONARY"))'="") {
					$$$GENERATE($c(9)_"if (tIndexer.UserDictionaryName'=tParams(""USERDICTIONARY"")) {")
					$$$GENERATE($c(9,9)_"do tIndexer.ClearUserDictionary()")
					$$$GENERATE($c(9,9)_"if (tParams(""USERDICTIONARY"")'="""") {")
					$$$GENERATE($c(9,9,9)_"set tUserDict=##class(%iKnow.UserDictionary).OpenByName(tParams(""USERDICTIONARY""))")
					$$$GENERATE($c(9,9,9)_"do tIndexer.LoadUserDictionary(tParams(""USERDICTIONARY""), tUserDict)")
					$$$GENERATE($c(9,9,9)_"do tIndexer.SetUserDictionary(tParams(""USERDICTIONARY""))")
					$$$GENERATE($c(9,9)_"}")
					$$$GENERATE($c(9)_"}")
				} else {
					$$$GENERATE($c(9)_"do:(tIndexer.UserDictionaryName'="""") tIndexer.ClearUserDictionary()")
				}
			}
			
	    	if ($$$comClassKeyGet($list(propNames(1),2),$$$cCLASSsqlcategory)=$$$cCLASSSQLCATEGORYSTRING) {
		    	if tNoEngine {
			    	$$$GENERATE($char(9)_"do ##class("_filer_").FileIndexString("_$extract(tIndexVars,1,*-1)_","_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	} else {
					$$$GENERATE($char(9)_"do tIndexer.exBufferString("_$extract(tIndexVars,1,*-1)_")")
					$$$GENERATE($char(9)_"do ##class("_filer_").FileIndex(tDirect,tIndexer,"_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	}
			}
			elseif $$$getClassType($list(propNames(1),2))=$$$cCLASSCLASSTYPESTREAM {
				
				
				// test for calculated stream example ^oddDEF("User.Expand","a","Text",23)	= 	1
				// or test for ^oddDEF("User.Expand","a","Text",45) cPROPsqlcomputed 
				if ($$$defMemberKeyDefined(%class,$$$cCLASSproperty,$list(propNames(1),1),$$$cPROPcalculated))
				||($$$defMemberKeyDefined(%class,$$$cCLASSproperty,$list(propNames(1),1),$$$cPROPsqlcomputed)) {
				
					 $$$GENERATE($char(9)_"set tStream="_ $extract(tIndexVars,1,*-1))
				}
				else {
				   $$$GENERATE($char(9)_"set tStream = ##class("_%class_")."_$list(propNames(1),1)_"Open("_$extract(tIndexVars,1,*-1)_")")
				}
				$$$GENERATE($char(9)_"if tStream '= $$$NULLOREF {")
				if tNoEngine {
			    	$$$GENERATE($char(9,9)_"do ##class("_filer_").FileIndexStream(tStream,"_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	} else {
					$$$GENERATE($char(9,9)_"do tIndexer.exBufferStream(tStream)")
					$$$GENERATE($char(9,9)_"do ##class("_filer_").FileIndex(tDirect,tIndexer,"_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	}
				$$$GENERATE($char(9)_"}")
			}
			else {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Invalid datatype: "_$list(propNames(1),2)))
			}
		}
		else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Too many properties "))
		}
	}
	quit $$$OK
}

/// Updates the iFind index for the row
ClassMethod UpdateIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, GenerateAfter = InsertIndex, ServerOnly = 1 ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit $$$OK")
			quit $$$OK
		}
		
		// Parse index properties
		do parseIndexProperties^%occStorageCompiler(%class,%property,.prop,.issubval)
		
		// Get index property names and types
		set propNames = prop
		for p=1:1:prop {
			set propNames(p)=$listbuild(prop(p),$get($$$EXTPROPtype($$$pEXT,%class,prop(p))))
		}
		
		set tIndex = ##class(%Dictionary.CompiledIndex).IDKEYOpen(%class,%property)
		if $isobject(tIndex) {			
			set tKey = ""
			set tIndexProperty = tIndex.PropertyCollection.GetNext(.tKey)
			set tIndexVars=""
			while $isobject(tIndexProperty) {
				set tIndexVars = tIndexVars_"pArg("_tIndexProperty.Name_"),"
				set tIndexProperty = tIndex.PropertyCollection.GetNext(.tKey)
			}
		}

		set tIndexLocation = $$$EXTIDXGLOBAL($$$pEXT,%class,%property,$$$IFGLOBALINDEXLOC)
		set tIndexLocationMLS = $select(tIndexLocation="":"",$extract(tIndexLocation,*) = ")":$extract(tIndexLocation,1,*-1)_",",1:tIndexLocation_"(")
		set tIndexLocationQ = $$$QUOTE(tIndexLocation)

		// BDB541 - get index parameters
		$$$GENERATE($char(9)_"do .."_%property_"GetIndexParams(.tParams)")
		
		
		// BDB675 - Filer has been resolved in InsertIndex
		set filer=$get(%parameter("FILER"))
		set tNoEngine = $g(%parameter("FILER:NoIndex"),0)
		
		
		// BDB668 - translate to integer prop if required
		if $d(%parameter("INTKEYPROPERTY"),tIntKeyProp) && (tIntKeyProp'="") {
			$$$GENERATE("	set pID = ##class("_%class_").%OpenId(pID)."_tIntKeyProp)
		}
		
		
		if (propNames=1) {
			
			// BDB676
			$$$GENERATE($char(9)_"do ##class("_filer_").Delete(pID,"_tIndexLocationQ_",.tParams)")
				
			if 'tNoEngine {
				$$$GENERATE($char(9)_"set tLanguage = tParams(""LANGUAGE"")")
				$$$GENERATE($char(9)_"do ($system.Context.iFind()).GetIndexer(tLanguage,.tDirect,.tIndexer)")
				
				if ($g(%parameter("USERDICTIONARY"))'="") {
					$$$GENERATE($c(9,9)_"if (tIndexer.UserDictionaryName'=tParams(""USERDICTIONARY"")) {")
					$$$GENERATE($c(9,9,9)_"do tIndexer.ClearUserDictionary()")
					$$$GENERATE($c(9,9,9)_"if (tParams(""USERDICTIONARY"")'="""") {")
					$$$GENERATE($c(9,9,9,9)_"set tUserDict=##class(%iKnow.UserDictionary).OpenByName(tParams(""USERDICTIONARY""))")
					$$$GENERATE($c(9,9,9,9)_"do tIndexer.LoadUserDictionary(tParams(""USERDICTIONARY""), tUserDict)")
					$$$GENERATE($c(9,9,9,9)_"do tIndexer.SetUserDictionary(tParams(""USERDICTIONARY""))")
					$$$GENERATE($c(9,9,9)_"}")
					$$$GENERATE($c(9,9)_"}")
				} else {
					$$$GENERATE($c(9,9)_"do:(tIndexer.UserDictionaryName'="""") tIndexer.ClearUserDictionary()")
				}
			}
			
	    	if ($$$comClassKeyGet($list(propNames(1),2),$$$cCLASSsqlcategory)=$$$cCLASSSQLCATEGORYSTRING) {
		    	if tNoEngine {
			    	$$$GENERATE($char(9)_"do ##class("_filer_").FileIndexString("_$extract(tIndexVars,1,*-1)_","_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	} else {
					$$$GENERATE($char(9)_"do tIndexer.exBufferString("_$extract(tIndexVars,1,*-1)_")")
					$$$GENERATE($char(9)_"do ##class("_filer_").FileIndex(tDirect,tIndexer,"_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	}
			}
			elseif $$$getClassType($list(propNames(1),2))=$$$cCLASSCLASSTYPESTREAM {
				
				// test for calculated stream example ^oddDEF("User.Expand","a","Text",23)	= 	1
				// or test for ^oddDEF("User.Expand","a","Text",45) cPROPsqlcomputed 
				if ($$$defMemberKeyDefined(%class,$$$cCLASSproperty,$list(propNames(1),1),$$$cPROPcalculated))
				||($$$defMemberKeyDefined(%class,$$$cCLASSproperty,$list(propNames(1),1),$$$cPROPsqlcomputed))
				{
					 $$$GENERATE($char(9)_"set tStream="_ $extract(tIndexVars,1,*-1))
				}
				else {
				   $$$GENERATE($char(9)_"set tStream = ##class("_%class_")."_$list(propNames(1),1)_"Open("_$extract(tIndexVars,1,*-1)_")")
				}
				$$$GENERATE($char(9)_"if tStream '= $$$NULLOREF {")
				if tNoEngine {
			    	$$$GENERATE($char(9,9)_"do ##class("_filer_").FileIndexStream(tStream,"_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	} else {
					$$$GENERATE($char(9,9)_"do tIndexer.exBufferStream(tStream)")
					$$$GENERATE($char(9,9)_"do ##class("_filer_").FileIndex(tDirect,tIndexer,"_$$$QUOTE(%property)_"," _ tIndexLocationQ_",pID,.tParams)")
		    	}
				$$$GENERATE($char(9)_"}")
			}
			else {
				throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Invalid datatype: "_$list(propNames(1),2)))
			}
		}
		else {
			throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"To many properties "))
		}		
	}
	quit $$$OK
}

/// 		Deletes the iFind index for the row
ClassMethod DeleteIndex(pID As %RawString, pArg... As %Binary) [ CodeMode = generator, GenerateAfter = InsertIndex, ServerOnly = 1 ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit $$$OK")
			quit $$$OK
		}
		
		// BDB675 - Filer has been resolved in InsertIndex
		set filer=$get(%parameter("FILER"))
		
		if $Get($$$EXTIDXGLOBAL($$$pEXT,%class,%property,$$$IFGLOBALINDEXLOC)) = "" { do ##class(%Compiler.iFind.Index).GenerateGlobalNames(%class,%property) } 
		set tIndexLocationQ = $$$QUOTE($$$EXTIDXGLOBAL($$$pEXT,%class,%property,$$$IFGLOBALINDEXLOC))
		$$$GENERATE($c(9)_"do .."_%property_"GetIndexParams(.tParams)")
		
		// BDB668 - translate to integer prop if required
		if $d(%parameter("INTKEYPROPERTY"),tIntKeyProp) && (tIntKeyProp'="") {
			$$$GENERATE("	set pID = ##class("_%class_").%OpenId(pID)."_tIntKeyProp)
		}
		
		$$$GENERATE($c(9)_"do ##class("_filer_").Delete(pID,"_tIndexLocationQ_",.tParams)")
	}
	quit $$$OK
}

/// 		Purges the iFind index
ClassMethod PurgeIndex() [ CodeMode = generator, GenerateAfter = InsertIndex, ServerOnly = 1 ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit $$$OK")
			quit $$$OK
		}
		
		set tIndexLocation = $$$EXTIDXGLOBAL($$$pEXT,%class,%property,$$$IFGLOBALINDEXLOC)
		$$$GENERATE($c(9)_"set settings=$g("_tIndexLocation_")")
		$$$GENERATE($c(9)_"kill "_tIndexLocation)
		$$$GENERATE($c(9)_"set:settings'="""" "_tIndexLocation_"=settings")
	}
	quit $$$OK
}

ClassMethod SortBeginIndex() [ ServerOnly = 1 ]
{
	quit $$$OK
}

ClassMethod SortEndIndex() [ ServerOnly = 1 ]
{
	quit $$$OK
}

/// Searches for matches based on the iFind index. This function can be accessed more conveniently
/// through the following syntax:
/// <example language="SQL">SELECT * FROM MyPackage.Table WHERE 
/// %ID %FIND search_index(<i>index_name</i>, <var>pSearch</var> [, <var>pOption</var> [, <var>pLanguage</var>]])</example>
ClassMethod Find(pSearch As %Library.Binary, pOption As %Integer = 0, pLanguage As %String = "", pSynonymOption As %String = "") As %Library.Binary [ CodeMode = generator, PublicList = (SQLCODE, %msg), ServerOnly = 1, SqlProc ]
{
	if %mode '= "method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		
		$$$GENERATE($char(9)_"try {")
		$$$GENERATE($char(9,9)_"set tSearcher = .."_%pqname_"Embedded()")
		$$$GENERATE($char(9,9)_"do tSearcher.PrepareFind(pSearch,pOption,pLanguage,pSynonymOption)")
		$$$GENERATE($char(9)_"}")
		$$$GENERATE($char(9)_"catch tException {")
		$$$GENERATE($char(9,9)_"set %sqlcontext.%SQLCODE = tException.AsSQLCODE(), %sqlcontext.%Message = tException.AsSQLMessage()")
		$$$GENERATE($char(9,9)_"THROW tException")
		$$$GENERATE($char(9)_"}")
		$$$GENERATE($char(9)_"quit tSearcher")
	}
	quit $$$OK
}

/// This method will normalize the query of %iFind.Find.Basic based on the dictionary defined %iFind.Index.Basic
ClassMethod Normalize(pQuery As %String = "", pLanguage As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	Set st = $$$OK
	try {
		quit:%mode="method"
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit
		}
		
		// BDB767 - delegate to %iFind.Utils
		$$$GENERATE($c(9)_"do .."_%property_"GetIndexParams(.tParams)")
		$$$GENERATE($c(9)_"set:pLanguage="""" pLanguage = $g(tParams(""LANGUAGE""),""en"")")
		$$$GENERATE($c(9)_"quit ##class(%iFind.Utils).NormalizeString(pQuery, pLanguage, .tParams)")
	}
	catch(ex)
	{
		Set st = ex.AsStatus()
	}
	quit st
}

/// Internal helper method for retrieving runtime index parameter values
ClassMethod GetIndexParams(Output pParams) As %Status [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		quit:%mode="method"
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit $$$OK")
			quit
		}
		
		$$$GENERATE($char(9)_"kill pParams")
		$$$GENERATE($char(9)_"set pParams(""COMPILEDVERSION"")="""_$system.Version.GetNumber()_"""")
		
		// first write simple parameters
		set tParam = ""
		for {
			set tParam = $order(%parameter(tParam),1,tParamValue)
			quit:tParam=""
			
			// skip internal ones
			continue:tParam="FILER"
			
			// skip customizable ones
			continue:tParam="LANGUAGE"
			continue:tParam="LOWER"
			continue:tParam="INDEXOPTION"
			continue:tParam="USERDICTIONARY"
			continue:tParam="STEMMINGCONFIG"
			continue:tParam="KEEPCHARS"
			continue:tParam="TRANSFORMATIONSPEC"
			continue:tParam=$$$IFPIgnorePunctuation
			
			$$$GENERATE($c(9)_"set pParams("_$$$QUOTE(tParam)_") = "_$$$QUOTE(tParamValue))
		}
		
		
		// LANGUAGE (default: "en", fallback: "*")
		set tLanguage = $get(%parameter("LANGUAGE"))
		if (tLanguage = "") || (tLanguage = "*") {
			
			// use Automatic Language Identification
			$$$GENERATE($char(9)_"set pParams(""LANGUAGE"") = ""*""")
			
		} elseif $$$IFGetLangId(tLanguage) || ($l(tLanguage)=2) {
			
			// when a known language is being supplied, use it
			$$$GENERATE($char(9)_"set pParams(""LANGUAGE"") = "_$$$QUOTE(tLanguage))
			
		} else {
			
			// if not, we're looking at custom code
			$$$GENERATE($char(9)_"try {")
			$$$GENERATE($char(9,9)_"set pParams(""LANGUAGE"") = "_$$ResolveNames(tLanguage))
			$$$GENERATE($char(9,9)_"if '$$$IFGetLangId(pParams(""LANGUAGE"")) { set pParams(""LANGUAGE"") = ""*"" }")
			$$$GENERATE($char(9)_"} catch { set pParams(""LANGUAGE"") = ""*"" }")
		}


		// LOWER (default: 1)
		set tLower = $g(%parameter("LOWER"))
		set:tLower="" tLower = 1
		if (tLower=0) || (tLower=1) {
			$$$GENERATE($c(9)_"set pParams(""LOWER"") = "_tLower)
		} else {
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams(""LOWER"") = "_$$ResolveNames(tLower))
			$$$GENERATE($c(9,9)_"set:(pParams(""LOWER"")'=0)&&(pParams(""LOWER"")'=1) pParams(""LOWER"") = 1")
			$$$GENERATE($c(9)_"} catch (ex) { set pParams(""LOWER"") = 1 }")
		}
		

		// INDEXOPTION (default: 0)
		set tIndexOption = $g(%parameter("INDEXOPTION"))
		set:tIndexOption="" tIndexOption = 0
		if (tIndexOption=0) || (tIndexOption=1) || (tIndexOption=2) {
			$$$GENERATE($c(9)_"set pParams(""INDEXOPTION"") = "_tIndexOption)
		} else {
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams(""INDEXOPTION"") = "_$$ResolveNames(tIndexOption))
			$$$GENERATE($c(9,9)_"set:(pParams(""INDEXOPTION"")'=0)&&(pParams(""INDEXOPTION"")'=1)&&(pParams(""INDEXOPTION"")'=2) pParams(""INDEXOPTION"") = 0")
			$$$GENERATE($c(9)_"} catch (ex) { set pParams(""INDEXOPTION"") = 0 }")
		}
		
		
		// USERDICTIONARY (default: "")
		set tUserDictionary = $g(%parameter("USERDICTIONARY"))
		if ($e(tUserDictionary)="{") && ($e(tUserDictionary,*)="}") {
			
			// if wrapped with {}, this is customization code
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams(""USERDICTIONARY"") = "_$$ResolveNames(tUserDictionary))
			$$$GENERATE($c(9)_"} catch (ex) { set pParams(""USERDICTIONARY"") = """" }")
			
		} else {
			
			// otherwise, this is just the name of / path to the user dictionary itself
			$$$GENERATE($c(9)_"set pParams(""USERDICTIONARY"") = "_$$$QUOTE(tUserDictionary))
		}
		
		
		// STEMMINGCONFIG (default: "")
		set tStemmingConfig = $g(%parameter("STEMMINGCONFIG"))
		if ($e(tStemmingConfig)="{") && ($e(tStemmingConfig,*)="}") {
			
			// if wrapped with {}, this is customization code
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams(""STEMMINGCONFIG"") = "_$$ResolveNames(tStemmingConfig))
			$$$GENERATE($c(9)_"} catch (ex) { set pParams(""STEMMINGCONFIG"") = """" }")
			
		} else {
			
			// otherwise, this is just the name of / path to the stemming config itself
			$$$GENERATE($c(9)_"set pParams(""STEMMINGCONFIG"") = "_$$$QUOTE(tStemmingConfig))
		}
		
		
		
		// BDB594
		// KEEPCHARS (default: $$$STRIPKEEP)
		set tKeepChars = $g(%parameter("KEEPCHARS"))
		if ($e(tKeepChars)="{") && ($e(tKeepChars,*)="}") {
			
			// if wrapped with {}, this is customization code
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams(""KEEPCHARS"") = "_$$ResolveNames(tKeepChars))
			$$$GENERATE($c(9)_"} catch (ex) { set pParams(""KEEPCHARS"") = """" }")
			
		} else {
			
			// otherwise, this is just a sequence of characters
			$$$GENERATE($c(9)_"set pParams(""KEEPCHARS"") = "_$$$QUOTE(tKeepChars))
		}
		
		
		// BDB675 - TRANSFORMATIONSPEC (default = "")
		set tTransformationSpec = $g(%parameter("TRANSFORMATIONSPEC"))
		if (tTransformationSpec'="") && ((tIndexOption'=0) || (tStemmingConfig'="")) {
			set tSC = $$$ERROR($$$GeneralError, "'TRANSFORMATIONSPEC' index parameter cannot be used when 'INDEXOPTION' or 'STEMMINGCONFIG' is set")
			quit
		}
		if ($e(tTransformationSpec)="{") && ($e(tTransformationSpec,*)="}") {
			
			// if wrapped with {}, this is customization code
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams(""TRANSFORMATIONSPEC"") = "_$$ResolveNames(tTransformationSpec))
			$$$GENERATE($c(9)_"} catch (ex) { set pParams(""TRANSFORMATIONSPEC"") = """" }")
			
		} else {
			
			// otherwise, this is just the name of / path to the transformation spec itself
			$$$GENERATE($c(9)_"set pParams(""TRANSFORMATIONSPEC"") = "_$$$QUOTE(tTransformationSpec))
		}
		
		// BDB857
		// IGNOREPUNCTUATION (default: 1 for Minimal, 0 beyond)
		set tIgnorePunctuation = $g(%parameter($$$IFPIgnorePunctuation))
		if (tIgnorePunctuation=0) || (tIgnorePunctuation=1) {
			$$$GENERATE($c(9)_"set pParams($$$IFPIgnorePunctuation) = "_tIgnorePunctuation)
		} else {
			$$$GENERATE($c(9)_"try {")
			$$$GENERATE($c(9,9)_"set pParams($$$IFPIgnorePunctuation) = "_$$ResolveNames(tIgnorePunctuation))
			$$$GENERATE($c(9,9)_"set:(pParams($$$IFPIgnorePunctuation)'=0)&&(pParams($$$IFPIgnorePunctuation)'=1) pParams($$$IFPIgnorePunctuation) = 0")
			$$$GENERATE($c(9)_"} catch (ex) { set pParams($$$IFPIgnorePunctuation) = 0 }")
		}
		
		$$$GENERATE($c(9)_"quit $$$OK")

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	throw:$$$ISERR(tSC) ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"Error processing index parameters",tSC))
	quit $$$OK
	
ResolveNames(tString) // strips wrapping {} and replaces {%INDEX} and {%CLASS}
	set tString = $replace(tString,"{%CLASS}",$$$QUOTE(%class))
	set tString = $replace(tString,"{%INDEX}",$$$QUOTE(%property))
	set:($e(tString)="{")&&($e(tString)="{") tString = $e(tString,2,*-1)
	quit tString
}

/// Return an instance of the embedded Find class, initialized with the index' parameters
ClassMethod Embedded() As %RegisteredObject [ CodeMode = generator, ServerOnly = 1 ]
{
	if %mode'="method" {
		
		// BDB682 - exit if we don't need an extent
		if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
			$$$GENERATE($c(9)_"quit """"")
			quit $$$OK
		}
		
		$$$comMemberKeyGetLvar(embeddedclass,%class,$$$cCLASSindex,%pqname,$$$cXXXXembeddedname)
		$$$GENERATE($char(9)_"do .."_%pqname_"GetIndexParams(.tParams)")
		$$$GENERATE($char(9)_"quit ##class("_embeddedclass_").%New(.tParams)")
	}
	quit $$$OK
}

/// Retrieves the full string value processed by this index.
ClassMethod GetStringValue(pRecordID As %RawString) As %String [ CodeMode = generator, Internal, ServerOnly = 1 ]
{
	if %mode = "method" quit $$$OK
	
	if $$$defClassKeyGet(%class,$$$cCLASSnoextent) {
		$$$GENERATE($c(9)_"quit """"")
		quit $$$OK
	}
		
	$$$GENERATE($char(9)_"set pSC=$$$OK, tObj = ##class("_%class_").%OpenId(pRecordID,,.pSC)")
	$$$GENERATE($char(9)_"quit:tObj=$$$NULLOREF """"")
	
	do parseIndexProperties^%occStorageCompiler(%class,%property,.prop,.issubval)
	set tPropType = $get($$$EXTPROPtype($$$pEXT,%class,prop(1)))
	$$$GENERATE($char(9)_"set tFullText=""""")
	if ($$$comClassKeyGet(tPropType,$$$cCLASSsqlcategory)=$$$cCLASSSQLCATEGORYSTRING) {
		$$$GENERATE($char(9)_"set tFullText = tObj."_prop(1))
	} else { // stream
		$$$GENERATE($char(9)_"quit:tObj."_prop(1)_"=$$$NULLOREF """"")
		$$$GENERATE($char(9)_"set tFullText=""""")
		$$$GENERATE($char(9)_"do tObj."_prop(1)_".Rewind()")
		$$$GENERATE($char(9)_"while 'tObj."_prop(1)_".AtEnd {")
		$$$GENERATE($char(9,9)_"set tLen=32656, tFullText = tFullText_tObj."_prop(1)_".Read(.tLen, .pSC)")
		$$$GENERATE($char(9,9)_"quit:$$$ISERR(pSC)")
		$$$GENERATE($char(9)_"}")
		$$$GENERATE($char(9)_"quit:$$$ISERR(pSC) """"")
	}
	$$$GENERATE($char(9)_"quit tFullText")
	quit $$$OK
}

}
