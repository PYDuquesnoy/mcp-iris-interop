/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

IncludeGenerator %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25iKnow.DomainDefinition">NLP Domains</a>.</p>
/// <p>Subclasses of this class declaratively define an iKnow domain and its contents using an
/// XML representation in the <xdata>Domain</xdata> XData block. Compiling this class will
/// automatically create the iKnow domain and any static elements or settings within, such as
/// metadata fields, domain parameters and metrics. Using <method>%Build</method>) users can
/// then "build" the contents of the domain, loading any sources from the locations referred
/// to in <xdata>Domain</xdata> and populating relevant metadata, matching and metrics.</p>
/// <p>For a detailed reference of the available elements and attributes of this XData block, consult the class
/// reference for <class>%iKnow.Model.domain</class> and other classes in the <package>%iKnow.Model</package>
/// package.</p>
Class %iKnow.DomainDefinition Extends %RegisteredObject [ Abstract, CompileAfter = %iKnow.Model.domain, Deprecated, System = 4 ]
{

Projection DomainProjection As %iKnow.DomainProjection [ Internal ];

/// <p>An XML representation of the domain this class defines.</p>
/// <p>For a detailed reference of the available elements and attributes, consult the class
/// reference for <class>%iKnow.Model.domain</class> and other classes in the <package>%iKnow.Model</package>
/// package.</p>
XData Domain [ XMLNamespace = "http://www.intersystems.com/iknow" ]
{
}

/// Main method to process the contents of <xdata>Domain</xdata> at compile-time and return
/// a <class>%iKnow.Model.domain</class> representation of it at runtime, as well as generating
/// a number of other artefacts (code and static iKnow domain entries) for this domain.
ClassMethod %GetModel() As %iKnow.Model.domain [ CodeMode = objectgenerator, Final, GenerateAfter = %DropManagedConfiguration, Internal ]
{
	set tSC = $$$OK
	try {
		
		// exit if we're not in an actual DomainDefinition
		if (%class.Abstract || (%class.Name = "%iKnow.DomainDefinition")) {
			do %code.WriteLine(" quit """"")
			quit
		}
		
		do %code.WriteLine("	set pSC = $$$OK, dmn1 = """"")
		do %code.WriteLine("	try {")
		
		// first locate the Domain XData block
		set tXDataIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Domain")
		if (tXDataIndex="") {
			set tSC = $$$ERROR($$$GeneralError, "No Domain XData block in DomainDefinition class")
			quit
		}
		set tXDataStream = %compiledclass.XDatas.GetAt(tXDataIndex).Data
		do tXDataStream.Rewind()
		if (tXDataStream.Size <= 0) {
			set tSC = $$$ERROR($$$GeneralError, "Domain XData block in DomainDefinition class is empty")
			quit
		}
		
		// correlate the XData stream with %iKnow.Model.domain
		set tReader = ##class(%XML.Reader).%New()
		set tSC = tReader.OpenStream(tXDataStream)
		quit:$$$ISERR(tSC)
		
		do tReader.Correlate("domain","%iKnow.Model.domain")
		
		do tReader.Next(.tDomain,.tSC)
		quit:$$$ISERR(tSC)
		
		#dim tDomain As %iKnow.Model.domain
		if '$isobject(tDomain) {
			set tSC = $$$ERROR($$$GeneralError,"No <domain> element in Domain Definition XData.")
			quit
		}
		
		// generate code to reproduce this %iKnow.Model.domain instance
		do tDomain.%GenerateCode(%code, 0)
		
		if 'tDomain.disabled {
			
			// BDB544 - translate build flags from [0-9] to corresponding char string
			set tBuildFlags = ""
			if (tDomain.buildFlags="MINIMAL") {
				set tBuildFlags = $$$MINBUILDFLAGS
			} elseif (tDomain.buildFlags="") {
				set tBuildFlags = $$$DEFBUILDFLAGS
			} else {
				for i = 1:1:$l(tDomain.buildFlags) {
					set tCharacter = $e(tDomain.buildFlags,i)
					set tBuildFlags = tBuildFlags_$c($case(tCharacter, 0:$$$IKBFNEVER, 1:$$$IKBFINIT, 2:$$$IKBFBATCH, :$$$IKBFALWAYS))
				}
			}
		
			// validate the domain definition itself
			set tSC = tDomain.%Validate()
			quit:$$$ISERR(tSC)
			
			// first check if this class was already managing another domain, which should therefore
			// be renamed
			set tPrevDomainName = $g(^IRIS.IK.Sys.Definition(%compiledclass.Name))
			set tIsNewDomain = 0
			if tPrevDomainName'="" {
				
				if (tPrevDomainName=tDomain.name) {
					
					// this means we're just "updating" an existing domain, so no action required
					
				} else {
					
					// the name changed, so rename the existing domain, but ensure the
					// (managing) domain definition class is calling it
					set tSC = $classmethod(%compiledclass.Name, "%Rename", tPrevDomainName, tDomain.name)
					quit:$$$ISERR(tSC)
					
					set ^IRIS.IK.Sys.Definition(%compiledclass.Name) = tDomain.name
				}
			}	
			
			// instantiate an %iKnow.Domain object
			set tDomainObj = ##class(%iKnow.Domain).NameIndexOpen(tDomain.name)
			if $isobject(tDomainObj) {
				
				// if the domain exists, verify it's indeed managed by this class
				if (%compiledclass.Name'=tDomainObj.GetParameter($$$IKPDEFINITIONCLASS)) {
					set tSC = $$$ERROR($$$GeneralError,"Domain """_tDomain.name_""" is not managed by class "_%compiledclass.Name)
					quit
				}
				
				// BDB544 - if the domain was created in an older verison, is empty and has
				// compatible build flags, upgrade it silently
				if (tDomainObj.Version < $$$IKCURRENTVERSION) && (tDomainObj.IsEmpty()) && 
					($e(tBuildFlags,1,$l(tDomainObj.BuildFlags)) = tDomainObj.BuildFlags) {
					set $li(^IRIS.IK.Sys.DomainD(tDomainObj.Id),3) = $$$IKCURRENTVERSION
					do tDomainObj.%Reload()
				}
				
				// BDB544 - apply updated build flags
				if (tBuildFlags'="") && (tDomainObj.BuildFlags'=tBuildFlags) {
					
					// if this is an upgrade from a previous version with shorter but identical
					// build flag string (up to the truncation), we can simply ignore as it
					// will be picked up by an eventual upgrade
					if (tDomainObj.Version < $$$IKCURRENTVERSION) && 
						($e(tBuildFlags,1,$l(tDomainObj.BuildFlags))=tDomainObj.BuildFlags) {
						// OK
					} elseif 'tDomainObj.IsEmpty() {
						set tSC = $$$ERROR($$$GeneralError, "Cannot update build flags for non-empty domain")
						quit
					} else {
						// otherwise we can set new build flags
						set $li(^IRIS.IK.Sys.DomainD(tDomainObj.Id),4) = tBuildFlags
					}
				}
				
				
			} else {
				
				// otherwise, create a new domain
				set tDomainObj = ##class(%iKnow.Domain).%New(tDomain.name, tBuildFlags)
				if '$isobject(tDomainObj) {
					set tSC = $g(%objlasterror,$$$ERROR($$$GeneralError, "Error creating domain"))
					quit
				}
				set tSC = tDomainObj.%Save()
				quit:$$$ISERR(tSC)
				
				// register this class as the managing definition
				set ^IRIS.IK.Sys.Params(tDomainObj.Id, $$$IKPDEFINITIONCLASS) = %compiledclass.Name
				set ^IRIS.IK.Sys.Definition(%compiledclass.Name) = tDomain.name
				
				set tIsNewDomain = 1
			}
			
			// register or unregister manager class if appropriate
			if (tDomain.allowCustomUpdates) {
				kill ^IRIS.IK.Sys.Params(tDomainObj.Id, $$$IKPMANAGEDBY)
			} else {
				set ^IRIS.IK.Sys.Params(tDomainObj.Id, $$$IKPMANAGEDBY) = %compiledclass.Name
			}
			
			// validate static elements
			set tSC = tDomain.%ValidateStatic(tDomainObj.Id)
			quit:$$$ISERR(tSC)
			
			// create Domain class
			set tSC = ..%CreateDomainClass(%compiledclass.Name, tDomain)
			quit:$$$ISERR(tSC)
		}
		
		do %code.WriteLine("	} catch (ex) {")
		do %code.WriteLine("		set pSC = ex.AsStatus()")
		do %code.WriteLine("	}")
		do %code.WriteLine("	quit dmn1")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %OnCompileDomain() As %Status [ ForceGenerate, GenerateAfter = %GetCustomizations, Internal ]
{
	set tSC = $$$OK
	try {
		#dim tDomain As %iKnow.Model.domain = ..%GetModel()
		quit:tDomain.disabled
		set tDomainId = ..%GetDomainId()
		
		merge tOldParams = ^IRIS.IK.Sys.Params(tDomainId)
		
		// BDB563: drop old package if no longer required
		if ($g(tOldParams($$$IKPPACKAGE))'="") && (tOldParams($$$IKPPACKAGE)'=tDomain.objectsPackage) {
			set tSC = ##class(%iKnow.Tables.Utils).DropDomainTables(tOldParams($$$IKPPACKAGE))
			quit:$$$ISERR(tSC)
			
			kill ^IRIS.IK.Sys.Params(tDomainId,$$$IKPPACKAGE)
		}
		
		set tSC = ..%CreateStaticElements(tDomain, tDomainId)
		quit:$$$ISERR(tSC)
		
		// now validate the contents of the domain
		set tSC = tDomain.%ValidateContent(tDomainId)
		quit:$$$ISERR(tSC)
		
		
		// BDB563: generate objects package if requested
		if (tDomain.objectsPackage'="") {
			
			// if there's only a single table source, add a reference to it
			set tRefClass = ""
			if $isobject(tDomain.data) && (tDomain.data.lists.Count()=1) && (tDomain.data.lists.GetAt(1).%IsA("%iKnow.Model.listTable")) {
				set tRefTable = tDomain.data.lists.GetAt(1).tableName
				do $system.SQL.TableExists(tRefTable, .tTableMetadata)
				set tRefClass = $lg(tTableMetadata,3)
			}
			
			// retrieve defined customizations
			set tSC = ..%GetCustomizations(.tCustomizations, .tMetaFields)
			quit:$$$ISERR(tSC)
			
			
			// include all metadata fields if nothing specific requested
			set tMetaFields = $g(tMetaFields)
			if (tDomain.metadata'="") && (tMetaFields="") {
				for i = 1:1:tDomain.metadata.fields.Count() {
					set tMetaFields = tMetaFields _ $lb(tDomain.metadata.fields.GetAt(i).name)
				}
			}
			
			set tSC = ##class(%iKnow.Tables.Utils).CreateDomainTables(tDomainId, tDomain.objectsPackage, tRefClass, tMetaFields, .tCustomizations,, 0, 1)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Wrapper method to ensure the managing domain definition class will be executing
/// this privileged action.
ClassMethod %Rename(pFrom, pTo) As %Status [ CodeMode = objectgenerator, ForceGenerate, Internal ]
{
	do %code.WriteLine("	quit ##class(%iKnow.Domain).Rename(pFrom, pTo)")
}

/// Applies any domain parameters registered as &lt;parameter&gt; elements in the <var>pDomain</var>
/// model passed in.
ClassMethod %ApplyDomainParametersInternal(pDomain As %iKnow.Model.domain) As %Status [ Internal ]
{
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		set tDomainObj = ##class(%iKnow.Domain).NameIndexOpen(pDomain.name)
		
		// first look up what was set in the latest round of %ApplyDomainParameters
		merge tOldParams = ^IRIS.IK.Sys.Definition($classname(),"params")
		
		// BDB810 - ensure we're validating against the ACTUAL values rather than 
		// the ones last saved
		set tName = ""
		for {
			set tName = $order(tOldParams(tName),1,tValue)
			quit:tName=""
			set tOldParams(tName) = tDomainObj.GetParameter(tName)
		}
		
		// build a key-value map of all new parameters
		if $isobject(pDomain.parameters) {
			for i=1:1:pDomain.parameters.Count() {
				set tParam = pDomain.parameters.GetAt(i)
				if ($e(tParam.name,1,3) = "$$$") {
					set tName = $system.iKnow.GetDomainParameterName(tParam.name)
				} else {
					set tName = tParam.name
				}
				set tNewParams(tParam.name) = tParam.GetValue()
			}
			quit:$$$ISERR(tSC)
		}
		
		tstart
		
		// first unset old parameters that are no longer in use
		set tName = ""
		for {
			set tName = $order(tOldParams(tName),1,tValue)
			quit:tName=""
			
			if '$d(tNewParams(tName)) {
				set tSC = tDomainObj.UnsetParameter(tName)
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		// now go through the new set
		set tName = ""
		for {
			set tName = $order(tNewParams(tName),1,tValue)
			quit:tName=""
			
			if (tValue'=$g(tOldParams(tName))) {
				set tSC = tDomainObj.SetParameter(tName, tValue)
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		kill ^IRIS.IK.Sys.Definition($classname(),"params")
		merge ^IRIS.IK.Sys.Definition($classname(),"params") = tNewParams
		
		tcommit
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel) 1
	quit tSC
}

/// Internal method invoking <method>%ApplyDomainParametersInternal</method> using the 
/// runtime result of <method>%GetModel</method>
ClassMethod %ApplyDomainParameters() As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		
		quit:($classname()="%iKnow.DomainDefinition")
		
		set tSC = ..%ApplyDomainParametersInternal(..%GetModel())
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the domain name as defined in <xdata>Domain</xdata>
ClassMethod %GetDomainName() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	do %code.WriteLine("	quit "_$$$QUOTE($g(^IRIS.IK.Sys.Definition(%compiledclass.Name))))
}

/// Returns the domain ID corresponding to the domain defined in <xdata>Domain</xdata>
ClassMethod %GetDomainId() As %Integer [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	// exit if we're not in an actual DomainDefinition
	if (%class.Abstract || (%class.Name = "%iKnow.DomainDefinition")) {
		do %code.WriteLine("	quit """"")
	} else {
		set tDomainName = $g(^IRIS.IK.Sys.Definition(%compiledclass.Name))
		do %code.WriteLine("	quit "_$system.iKnow.GetDomainId(tDomainName))
	}
}

/// Creates an <class>%iKnow.AbstractDomain</class> class containing utility methods for building
/// the various domain elements described in <xdata>Domain</xdata>
ClassMethod %CreateDomainClass(pDomDefClassName As %String, pDomain As %iKnow.Model.domain) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		
		set tClassDefName = pDomDefClassName_".Domain"
		
		if $$$defClassDefined(tClassDefName) {
		    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
		    If $$$ISERR(tSC) Quit
		}
		
		set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
		if tClassDef="" { set tSC = $$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition")  quit }
		
		set tClassDef.Name = tClassDefName
		set tClassDef.ProcedureBlock = 1
		set tClassDef.Final = 1
		set tClassDef.GeneratedBy = pDomDefClassName
		set tClassDef.Super = "%iKnow.AbstractDomain"
		set tClassDef.Description = "This class contains code generated for the domain defined in '"_pDomDefClassName_"'. Do not invoke methods in this class directly."
		
		set tParamDef = ##class(%Dictionary.ParameterDefinition).%New()
		set tParamDef.Name = "DOMAINNAME"
		set tParamDef.Default = pDomain.name
		do tClassDef.Parameters.Insert(tParamDef)
		
		set tMethodDef = ##class(%Dictionary.MethodDefinition).%New()
		set tMethodDef.Name = "%Build"
		set tMethodDef.ClassMethod = 1
		set tMethodDef.FormalSpec = "pVerbose:%Boolean=1,&pParams,pAsync:%Boolean=0"
		set tMethodDef.ReturnType = "%Status"
		do tClassDef.Methods.Insert(tMethodDef)
		
		#define ParseExpression(%x,%c) set tSC = ..%ParseExpression(pDomDefClassName, %x, .%c) quit:$$$ISERR(tSC)
		#define WriteLine(%s) do tMethodDef.Implementation.WriteLine(%s)
		#define SkipLine do tMethodDef.Implementation.WriteLine()
		#define QuoteN(%s) $s(%s="":"", 1:$$$QUOTE(%s))
		#define WriteBgr(%m) "set ^IRIS.Temp.IK.DomainBuild(+$j,""out"",$i(^IRIS.Temp.IK.DomainBuild(+$j,""out""))) = "_%m		
		#define WriteEmptyMessage $$$WriteLine("		if pVerbose && 'pAsync { write:pVerbose ! }")
		#define WriteMessage(%s) $$$WriteLine("		if pVerbose { if pAsync { "_$$$WriteBgr("$zt($p($h,"","",2))_"": "_%s_"""")_" } else { write !,$zt($p($h,"","",2)),"": "_%s_""" } }")
		#define WriteMessageVar(%s) $$$WriteLine("		if pVerbose { if pAsync { "_$$$WriteBgr("$zt($p($h,"","",2))_"": ""_"_%s)_" } else { write !,$zt($p($h,"","",2)),"": ""_"_%s_" } }")
		#define WriteMessageC(%s,%c) $$$WriteLine("		if pVerbose && (%c) { if pAsync { "_$$$WriteBgr("$zt($p($h,"","",2))_"": "_%s_"""")_" } else { write !,$zt($p($h,"","",2)),"": "_%s_""" } }")
		
		$$$WriteLine("	new %IKVerbose")
		$$$WriteLine("	set %IKVerbose = $s(pAsync:-''pVerbose, 1:pVerbose)")
		
		$$$WriteLine("	set tSC = $$$OK")
		$$$WriteLine("	try {")
		$$$WriteLine("		kill:pAsync ^IRIS.Temp.IK.DomainBuild(+$j,""out"")")
		$$$SkipLine
		$$$WriteLine("		set tSC = ..%LoadExpressions(.pParams)")
		$$$WriteLine("		quit:$$$ISERR(tSC)")
		$$$SkipLine
		$$$WriteLine("		set tDomainId = $system.iKnow.GetDomainId(..#DOMAINNAME)")
		$$$SkipLine
		
		// drop data
		set tDropData = $s($isobject(pDomain.data):pDomain.data.dropBeforeBuild&&'pDomain.data.disabled, 1:0)
		set tDropDict = $s($isobject(pDomain.matching):pDomain.matching.dropBeforeBuild&&'pDomain.matching.disabled, 1:0)
		if tDropData {
			$$$WriteLine("		set tSC = ##class(%iKnow.Domain).%OpenId(tDomainId).DropData(0,"_tDropDict_",1,0)")
			$$$WriteLine("		quit:$$$ISERR(tSC)")
			$$$SkipLine
		}
		
		// %OnBeforeBuild callback
		$$$WriteLine("		// %OnBeforeBuild() callback")
		$$$WriteLine("		set tSC = ##class("_pDomDefClassName_").%OnBeforeBuild(tDomainId)")
		$$$WriteLine("		quit:$$$ISERR(tSC)")
		$$$SkipLine
		$$$SkipLine
		
		// process <data>
		if $isobject(pDomain.data) && 'pDomain.data.disabled {
			
			// instantiate Loader
			$$$WriteLine("		// Processing <data> element")
			$$$WriteMessage("Loading data...")
			$$$WriteLine("		set tSrcCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomainId)")
			$$$WriteLine("		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomainId)")
			
			// BDB708 - ensure any stale data from previous runs that got aborted is cleaned up
			$$$WriteLine("		set tSC = tLoader.Reset()")
			$$$WriteLine("		quit:$$$ISERR(tSC)")
			$$$SkipLine
			
			// instantiate registered Lister objects
			set (tBatchCount,tBatch) = 0
			#dim tList As %iKnow.Model.list
			#define WriteLister(%c) if ('tList.batchMode) { $$$WriteLine(%c) } else { set tBatch($i(tBatch)) = %c }
			for i = 1:1:pDomain.data.lists.Count() {
				set tList = pDomain.data.lists.GetAt(i)
				
				if tList.disabled { $$$WriteLister("		/*  This list is marked disabled ") }
				$$$WriteLister("		set tLister"_i_" = ##class("_tList.listerClass_").%New(tDomainId)")
				
				if (tList.configuration'="") {
					$$$ParseExpression(tList.configuration,tCode)
					$$$WriteLister("		set tSC = tLister"_i_".SetConfig("_tCode_")")
					$$$WriteLister("		quit:$$$ISERR(tSC)")
				}
				
				if $isobject(tList.processor) {
					$$$WriteLister("		set tSC = tLister"_i_".SetProcessor("_$$$QuoteN(tList.processor.processorClass)_","_..%GetParamsAsString(tList.processor.parameters, 1, pDomDefClassName, .tSC)_")")
					quit:$$$ISERR(tSC)
					$$$WriteLister("		quit:$$$ISERR(tSC)")
				}
				
				if $isobject(tList.converter) {
					$$$WriteLister("		set tSC = tLister"_i_".SetConverter("_$$$QUOTE(tList.converter.converterClass)_","_..%GetParamsAsString(tList.converter.parameters, 1, pDomDefClassName, .tSC)_")")
					quit:$$$ISERR(tSC)
					$$$WriteLister("		quit:$$$ISERR(tSC)")
				}
				
				// BDB375 - add fixed metadata values (even if none are enabled, to overwrite older ones)
				if (tList.metadataValues.Count()) {
					set tMetaKeys = "", tMetaValues = ""
					for j = 1:1:tList.metadataValues.Count() {
						set tMetaValue = tList.metadataValues.GetAt(j)
						continue:tMetaValue.disabled
						set tMetaKeys = $s(tMetaKeys="":"", 1:tMetaKeys_",")_$$$QUOTE(tMetaValue.field)
						
						// BDB544 - parse expression
						$$$ParseExpression(tMetaValue.value,tMetaCode)
						set tMetaValues = $s(tMetaValues="":"", 1:tMetaValues_",")_tMetaCode
					}
					$$$WriteLister("		set tSC = tLister"_i_".RegisterFixedMetadata($lb("_tMetaKeys_"), $lb("_tMetaValues_"))")
					$$$WriteLister("		quit:$$$ISERR(tSC)")
				}
				
				// schedule as batch or process as list directly
				if (tList.batchMode) {
					set:'tList.disabled x = $i(tBatchCount)
					set tBatch($i(tBatch)) = "		set tSC = tLister"_i_".AddListToBatch("_..%GetParamsAsString(tList.parameters,, pDomDefClassName, .tSC)_")"
				} else {
					$$$WriteLine("		set tSC = tLister"_i_".ProcessList("_..%GetParamsAsString(tList.parameters,, pDomDefClassName, .tSC)_")")
					$$$WriteLine("		do:pVerbose ..%PrintLoadErrors(tSC,tLoader,0,pAsync)")
				}
				quit:$$$ISERR(tSC)
				$$$WriteLister("		quit:$$$ISERR(tSC)")
				
				if tList.disabled { $$$WriteLister("		*/") }
				$$$WriteLister("")
			}
			quit:$$$ISERR(tSC)
			
			if (tBatch) {
				for i = 1:1:tBatch {
					$$$WriteLine(tBatch(i))
				}
				kill tBatch
				
				if (tBatchCount) { // if there are non-disabled batches
					$$$WriteLine("		set tSC = tLoader.ProcessBatch()")
					$$$WriteLine("		do:pVerbose ..%PrintLoadErrors(tSC,tLoader,1,pAsync)")
					$$$WriteLine("		quit:$$$ISERR(tSC)")
					$$$SkipLine
				}
			}
			
			$$$WriteLine("		set tSrcCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomainId) - tSrcCount")
			$$$WriteMessage("Finished loading ""_tSrcCount_"" sources")
			$$$WriteEmptyMessage
			$$$SkipLine
			$$$SkipLine
		}
		
		
		// match sources, if required
		if $isobject(pDomain.matching) && 'pDomain.matching.disabled {
			$$$WriteLine("		// Processing <matching> element")
			$$$WriteLine("		set tSC = ..%CreateDictionaries("_tDropDict_", pVerbose, .pParams, pAsync)")
			$$$WriteLine("		quit:$$$ISERR(tSC)")
		
			if (pDomain.matching.autoExecute) {
				$$$SkipLine
				$$$WriteMessage("Matching sources...")
				$$$WriteLine("		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tDomainId)")
				$$$WriteLine("		quit:$$$ISERR(tSC)")
				$$$WriteMessage("Finished matching sources")
			}
			$$$WriteEmptyMessage
			$$$SkipLine
			$$$SkipLine
		}
		
		
		// build metrics, if required
		if $isobject(pDomain.metrics) && 'pDomain.metrics.disabled && pDomain.metrics.autoExecute {
			$$$WriteLine("		// Processing <metrics> element")
			$$$WriteMessage("Building metrics...")
			$$$WriteLine("		set tSC = ##class(%iKnow.Metrics.MetricBuilder).BuildAll(tDomainId,,, pVerbose&&'pAsync)")
			$$$WriteLine("		quit:$$$ISERR(tSC)")
			$$$WriteMessage("Finished Building metrics")
			$$$WriteEmptyMessage
			$$$SkipLine
			$$$SkipLine
		}
		
		
		// %OnAfterBuild callback
		$$$WriteLine("		// %OnAfterBuild() callback")
		$$$WriteLine("		set tSC = ##class("_pDomDefClassName_").%OnAfterBuild(tDomainId)")
		$$$WriteLine("		quit:$$$ISERR(tSC)")
		$$$SkipLine
		
		$$$WriteLine("	} catch (ex) {")
		$$$WriteLine("		set tSC = ex.AsStatus()")
		$$$WriteLine("	}")
		$$$SkipLine
		$$$WriteLine("	if pVerbose {")
		$$$WriteLine("		if $$$ISERR(tSC) {")
		$$$WriteMessage("An error occurred while building domain '"_pDomain.name_"':")
		$$$WriteMessageVar("$system.Status.GetErrorText(tSC)")
		$$$WriteEmptyMessage
		$$$WriteLine("		} else {")
		$$$WriteMessage("Successfully built domain '"_pDomain.name_"'")
		$$$WriteLine("		}")
		$$$WriteLine("	}")
		$$$WriteEmptyMessage
		$$$SkipLine
		$$$WriteLine("	kill %expression")
		$$$WriteLine("	quit tSC")
		
		
		// %CreateDictionaries method
		set tMethodDef = ##class(%Dictionary.MethodDefinition).%New()
		set tMethodDef.Name = "%CreateDictionaries"
		set tMethodDef.ClassMethod = 1
		set tMethodDef.FormalSpec = "pDropFirst:%Boolean=0,pVerbose:%Boolean=1,&pParams,pAsync:%Boolean=0"
		set tMethodDef.ReturnType = "%Status"
		do tClassDef.Methods.Insert(tMethodDef)
		
		$$$WriteLine("	set tSC = $$$OK")
		$$$WriteLine("	try {")
		$$$WriteLine("		set tSC = ..%LoadExpressions(.pParams)")
		$$$WriteLine("		quit:$$$ISERR(tSC)")
		$$$SkipLine
		$$$WriteLine("		set tDomainId = $system.iKnow.GetDomainId(..#DOMAINNAME)")
		$$$SkipLine
		
		$$$WriteLine("		set:pDropFirst tSC = ##class(%iKnow.Matching.DictionaryAPI).DropAllDictionaryData(tDomainId)")
		$$$WriteLine("		quit:$$$ISERR(tSC)")
		$$$SkipLine
		
		#dim tMatching As %iKnow.Model.matching
		set tMatching = pDomain.matching
		if $isobject(tMatching) {
			
			$$$WriteMessage("Creating dictionaries and profiles...")
			$$$SkipLine
			
			// create profiles first
			$$$WriteLine("		// Processing <profile> elements")
			for i = 1:1:tMatching.profiles.Count() {
				#dim tProfile As %iKnow.Model.matchingProfile
				set tProfile = tMatching.profiles.GetAt(i)
				continue:tProfile.disabled
				
				$$$ParseExpression(tProfile.name,tCode)
				$$$WriteLine("		set tProfileName = "_tCode)
				$$$WriteLine("		set tProfile = ##class(%iKnow.Matching.MatchingProfile).GetProfileByName(tDomainId, tProfileName, .tSC)")
				$$$WriteLine("		quit:$$$ISERR(tSC)")
				$$$WriteMessageC("Overwriting matching profile '""_tProfileName_""'",$isobject(tProfile))
				$$$WriteLine("		set:'$isobject(tProfile) tProfile = ##class(%iKnow.Matching.MatchingProfile).%New(tDomainId, tProfileName)")
				$$$WriteLine("		set tProfile.ScatteredMatchMultiplier = "_tProfile.scatteredMatchMultiplier)
				$$$WriteLine("		set tProfile.RelationshipLengthMultiplier = "_tProfile.relationshipLengthMultiplier)
				$$$WriteLine("		set tProfile.RelationshipScoreMultiplier = "_tProfile.relationshipScoreMultiplier)
				$$$WriteLine("		set tProfile.PathRelevantScoreMultiplier = "_tProfile.pathRelevantScoreMultiplier)
				$$$WriteLine("		set tProfile.DisorderMultiplier = "_tProfile.disorderMultiplier)
				$$$WriteLine("		set tProfile.MinimalMatchScore = "_tProfile.minimalMatchScore)
				$$$WriteLine("		set tProfile.PathTotalMultiplier = "_tProfile.pathTotalMultiplier)
				$$$WriteLine("		set tProfile.CrcTotalMultiplier = "_tProfile.crcTotalMultiplier)
				$$$WriteLine("		set tProfile.SentTotalMultiplier = "_tProfile.sentTotalMultiplier)
				$$$WriteLine("		set tProfile.MinMatchedConceptFraction = "_tProfile.minMatchedConceptFraction)
				$$$WriteLine("		set tProfile.NegationMultiplier = "_tProfile.negationMultiplier)
				$$$WriteLine("		set tSC = tProfile.%Save()")
				$$$WriteLine("		set tProfiles(tProfile.Name) = tProfile.ProfileId, x = $i(tProfiles)")
				$$$WriteLine("		quit:$$$ISERR(tSC)")
				$$$SkipLine
			}
			
			if (tMatching.profiles.Count()) {
				$$$WriteMessageC("Finished creating ""_tProfiles_"" matching profiles",$g(tProfiles))
				$$$SkipLine
			}
			
			// register default profile, if any
			if (tMatching.defaultProfile'="") {
				$$$ParseExpression(tMatching.defaultProfile,tCode)
				$$$WriteLine("		set tSC = ##class(%iKnow.Domain).%OpenId(tDomainId).SetParameter($$$IKPMATDEFAULTPROFILE, "_tCode_")")
				$$$WriteLine("		quit:$$$ISERR(tSC)")
				$$$SkipLine
			}
			
			$$$SkipLine
			
			// create dictionaries, items and terms
			$$$WriteLine("		// Processing <dictionary> elements")
			$$$WriteLine("		set (tDictCount,tItemCount,tTermCount,tFormatCount) = 0")
			$$$SkipLine
		
			#define WriteErrorHandler(%i) $$$WriteMessageC("""_$system.Status.GetErrorText(tSC)_""",$$$ISERR(tSC)) ##continue
				if (tMatching.ignoreDictionaryErrors) { $$$WriteLine("			set:$$$ISERR(tSC) tSC = $$$OK") } else { $$$WriteLine("			quit:$$$ISERR(tSC)") }
			
			for i = 1:1:tMatching.dictionaries.Count() {
				#dim tDictionary As %iKnow.Model.dictionary
				set tDictionary = tMatching.dictionaries.GetAt(i)
				continue:tDictionary.disabled
				
				$$$ParseExpression(tDictionary.name,tNameCode)
				$$$ParseExpression(tDictionary.description,tDescCode)
				$$$WriteLine("		set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDomainId, "_tNameCode_")")
				$$$WriteLine("		if tDictId'>0 {")
				$$$WriteLine("			set tDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(tDomainId, "_tNameCode_", "_tDescCode_", "_$$$QuoteN($$$LOWER(tDictionary.language))_","_$s(tDictionary.profile'="":" tProfiles("_$$$QUOTE(tDictionary.profile)_")", 1:"")_", .tSC)")
				$$$WriteLine("			set:$$$ISOK(tSC) tDictCount = tDictCount+1")
				$$$WriteErrorHandler(1)
				$$$WriteLine("		}")
				$$$SkipLine
				$$$WriteLine("		if (tDictId>0) {")
				
				for j = 1:1:tDictionary.items.Count() {
					#dim tItem As %iKnow.Model.dictionaryItem
					set tItem = tDictionary.items.GetAt(j)
					continue:tItem.disabled
					
					$$$ParseExpression(tItem.name,tNameCode)
					$$$ParseExpression(tItem.uri,tURICode)
					$$$WriteLine("			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(tDomainId, "_tURICode_")")
					$$$WriteLine("			if tItemId'>0 {")
					$$$WriteLine("				set tItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(tDomainId, tDictId, "_tNameCode_", "_tURICode_", "_$$$QuoteN($$$LOWER(tItem.language))_", .tSC)")
					$$$WriteLine("				set:$$$ISOK(tSC) tItemCount = tItemCount+1")
					$$$WriteErrorHandler(2)
					$$$WriteLine("			}")
					$$$WriteLine("			if (tItemId>0) {")
					
					for k = 1:1:tItem.terms.Count() {
						#dim tTerm As %iKnow.Model.dictionaryTerm
						set tTerm = tItem.terms.GetAt(k)
						continue:tTerm.disabled
						
						$$$ParseExpression(tTerm.string,tCode)
						$$$WriteLine("				set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(tDomainId, tItemId, "_tCode_", "_$$$QuoteN($$$LOWER(tTerm.language))_", .tSC)")
						$$$WriteLine("				set:$$$ISOK(tSC) tTermCount = tTermCount+1")
						$$$WriteErrorHandler(2)
					}
					
					for k = 1:1:tItem.formats.Count() {
						#dim tFormat As %iKnow.Model.dictionaryFormat
						set tFormat = tItem.formats.GetAt(k)
						continue:tFormat.disabled
						
						$$$ParseExpression(tFormat.formatParams,tCode)
						if tCode '= "" set tCode="$s($lv("_tCode_"):"_tCode_", 1:$lfs("_tCode_"))"
						
						$$$WriteLine("				set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTermFormat(tDomainId, tItemId, "_$$$QUOTE(tFormat.formatClass)_", "_tCode_", .tSC)")
						$$$WriteLine("				set:$$$ISOK(tSC) tFormatCount = tFormatCount+1")
						$$$WriteErrorHandler(2)
					}
					$$$WriteLine("			}")
					$$$SkipLine
				}
				$$$WriteLine("		}")
				$$$SkipLine
			}
			
			for i = 1:1:tMatching.external.Count() {
				#dim tExternal As %iKnow.Model.dictionaryExternal
				set tExternal = tMatching.external.GetAt(i)
				
				$$$WriteLine("		// loading from external source") 
				for j = 1:1:tExternal.columns.Count() {
					set tCol = tExternal.columns.GetAt(j)
					continue:tCol.fixedValue=""
					$$$ParseExpression(tCol.fixedValue,tCode)
					$$$WriteLine("		set tFixed("_$$$QUOTE(tCol.role)_") = "_tCode)
				}
				$$$SkipLine
				
				if (tExternal.sql'="") {
					
					// query source
					$$$ParseExpression(tExternal.sql,tSQL)
					$$$WriteMessage("Loading dictionary content from SQL: """_tSQL_"""")
					$$$WriteLine("		set tStatement = ##class(%SQL.Statement).%New()")
					$$$WriteLine("		set tSC = tStatement.%Prepare("_tSQL_")")
					$$$WriteLine("		quit:$$$ISERR(tSC)")
					$$$WriteLine("		set tResult = tStatement.%Execute()")
					$$$SkipLine
					$$$WriteLine("		while tResult.%Next(.tSC) {")
					$$$WriteLine("			quit:$$$ISERR(tSC)")
					$$$SkipLine
					$$$WriteLine("			kill tValues")
					$$$WriteLine("			merge tValues = tFixed")
					
					for j = 1:1:tExternal.columns.Count() {
						set tCol = tExternal.columns.GetAt(j)
						continue:tCol.fixedValue'=""
						$$$WriteLine("			set tValues("_$$$QUOTE(tCol.role)_$s(tCol.role="term":",$i(tValues(""term""))", 1:"")_") = tResult.%GetData("_tCol.position_")")
					}
					
				} else {
					
					// BDB784 - parse delimiter
					set tDelimiter = tExternal.delimiter
					if ##class(%Regex.Matcher).%New("^\$(c|char)\([0-9,]+\)$",tDelimiter).Locate() {
						// keep explicit $char references
					} else {
						set tDelimiter = $$$QUOTE(tDelimiter)
					}
					
					// file source
					$$$ParseExpression(tExternal.file,tFile)
					$$$WriteMessage("Loading dictionary content from file: """_tFile_"""")
					$$$WriteLine("		set tFile = ##class(%Stream.FileCharacter).%New()")
					$$$WriteLine("		set tFile.Filename = "_tFile)
					$$$SkipLine
					if (tExternal.headerRows) {
						$$$WriteLine("		// skip "_tExternal.headerRows_" header rows")
						$$$WriteLine("		for i = 1:1:"_tExternal.headerRows_" { do tFile.ReadLine() }")
					}
					$$$WriteLine("		while 'tFile.AtEnd {")
					$$$WriteLine("			set tLine = tFile.ReadLine(,.tSC)")
					$$$WriteLine("			quit:$$$ISERR(tSC)")
					$$$WriteLine("			continue:tLine=""""")
					$$$SkipLine
					$$$WriteLine("			kill tValues")
					$$$WriteLine("			merge tValues = tFixed")
					
					for j = 1:1:tExternal.columns.Count() {
						set tCol = tExternal.columns.GetAt(j)
						continue:tCol.fixedValue'=""
						if (tCol.stripQuotes) {
							$$$WriteLine("			set tValue = $piece(tLine,"_tDelimiter_","_tCol.position_"), tIsQuoted = (($e(tValue)="""""""")&&($e(tValue,*)="""""""")) || (($e(tValue)=""'"")&&($e(tValue)=""'""))")
							$$$WriteLine("			set tValues("_$$$QUOTE(tCol.role)_$s(tCol.role="term":",$i(tValues(""term""))", 1:"")_") = $s(tIsQuoted:$e(tValue,2,*-1), 1:tValue)")
						} else {
							$$$WriteLine("			set tValues("_$$$QUOTE(tCol.role)_$s(tCol.role="term":",$i(tValues(""term""))", 1:"")_") = $piece(tLine,"_tDelimiter_","_tCol.position_")")
						}
					}
					
				}
				$$$SkipLine
				
				$$$WriteLine("			set tLanguage = $g(tValues(""language""),""en"")")
				$$$SkipLine
				$$$WriteLine("			set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDomainId, tValues(""dictionary name""))")
				$$$WriteLine("			set:'tDictId tDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(tDomainId, tValues(""dictionary name""), $g(tValues(""dictionary description"")), tLanguage,, .tSC), tDictCount=tDictCount+1")
				$$$WriteErrorHandler(1)
				$$$SkipLine
				$$$WriteLine("			set tDictItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(tDomainId, tValues(""item URI""))")
				$$$WriteLine("			set:'tDictItemId tDictItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(tDomainId, tDictId, $g(tValues(""item name""), tValues(""item URI"")), tValues(""item URI""), tLanguage, .tSC), tItemCount = tItemCount+1")
				$$$WriteErrorHandler(1)
				$$$SkipLine
				$$$WriteLine("			for i = 1:1:tValues(""term"") {")
				$$$WriteLine("				set tValue = tValues(""term"",i)")
				$$$WriteLine("				continue:tValue=""""")
				$$$WriteLine("				set tDictTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(tDomainId, tDictItemId, tValue, tLanguage, .tSC), tTermCount = tTermCount+1")
				$$$WriteErrorHandler(2)
				$$$WriteLine("			}")
				$$$WriteLine("			quit:$$$ISERR(tSC)")
				
				$$$WriteLine("		}")
				$$$WriteLine("		quit:$$$ISERR(tSC)")
				$$$SkipLine
			}
			
			$$$WriteMessage("Finished creating ""_tDictCount_"" dictionaries, ""_tItemCount_"" items, ""_tTermCount_"" terms and ""_tFormatCount_"" formats")
			$$$WriteEmptyMessage
		}
		
		$$$WriteLine("	} catch (ex) {")
		$$$WriteLine("		set tSC = ex.AsStatus()")
		$$$WriteLine("	}")
		$$$WriteLine("	kill %expression")
		$$$WriteLine("	quit tSC")
		
		
		// %LoadExpressions method
		set tMethodDef = ##class(%Dictionary.MethodDefinition).%New()
		set tMethodDef.Name = "%LoadExpressions"
		set tMethodDef.ClassMethod = 1
		set tMethodDef.FormalSpec = "&pParams"
		set tMethodDef.ReturnType = "%Status"
		set tMethodDef.Internal = 1
		do tClassDef.Methods.Insert(tMethodDef)
		$$$WriteLine("	set tSC = $$$OK")
		$$$WriteLine("	try {")
		$$$WriteLine("		kill %expression")
		
		#dim tExpression As %iKnow.Model.expression
		for i = 1:1:pDomain.expressions.Count() {
			set tExpression = pDomain.expressions.GetAt(i)
			set tSC = ..%ParseExpression(pDomDefClassName, tExpression.value, .tCode)
			quit:$$$ISERR(tSC)
			if tExpression.acceptRuntimeParameter {
				$$$WriteLine("		set %expression("_$$$QUOTE(tExpression.name)_") = $g(pParams("_$$$QUOTE(tExpression.name)_"), "_tCode_")")
			} else {
				$$$WriteLine("		set %expression("_$$$QUOTE(tExpression.name)_") = "_tCode)
			}
		}
		quit:$$$ISERR(tSC)
		
		$$$WriteLine("	} catch (ex) {")
		$$$WriteLine("		set tSC = ex.AsStatus()")
		$$$WriteLine("	}")
		$$$WriteLine("	quit tSC")
		
		
		
		set tSC = tClassDef.%Save()
		quit:$$$ISERR(tSC)
		
		// queue class to be compiled along
		do QueueClass^%occCompile(tClassDefName)
		
		// mark class for deletion when DomainDefinition is deleted
	    $$$comClassArraySet(pDomDefClassName,$$$cCLASSclasses,tClassDefName_".CLS","")
	    $$$defClassKeySet(tClassDefName,$$$cCLASSgeneratedby,pDomDefClassName_".CLS")
	}
	catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GetParamsAsString(pParams As %ListOfObjects, pWrapList As %Boolean = 0, pDomDefClassName As %String = "", Output pSC As %Status) As %String [ Internal, Private ]
{
	set tParams="", pSC = $$$OK
	if (pParams.Count()) {
		for j = 1:1:pParams.Count() {
			set tParam = pParams.GetAt(j)
			if $isobject(tParam) && 'tParam.isNull {
				if (tParam.isList) {
					set tParams = tParams _ "$lb(", tCount = $l(tParam.value,",")
					for k = 1:1:tCount {
						set:k>1 tParams = tParams _ ", "
						set pSC = ..%ParseExpression(pDomDefClassName, $p(tParam.value,",",k), .tValueCode)
						quit:$$$ISERR(pSC)
						set tParams = tParams _ tValueCode
					}
					quit:$$$ISERR(pSC)
					set tParams = tParams _ ")"
				} elseif(tParam.value'="") {
					set pSC = ..%ParseExpression(pDomDefClassName, tParam.value, .tValueCode)
					quit:$$$ISERR(pSC)
					set tParams = tParams _ tValueCode
				}
			}
			set tParams = tParams _ ","
		}
		set tParams = $e(tParams,1,*-1)
		set:pWrapList tParams = "$lb("_tParams_")"
	}
	quit tParams
}

/// <p>Invoking this method will <i>build</i> the domain described in <xdata>Domain</xdata>,
/// which includes loading data and dictionaries, matching dictionaries and building metrics,
/// depending on the various settings of the &lt;domain&gt; element and its sub-elements.</p>
/// <p>The <var>pVerbose</var> argument controls whether status output is provided to stdev
/// (if <var>pAsync</var>=0) or written to a global for GUI pickup (<var>pAsync</var>=1, for
/// internal use only).</p>
ClassMethod %Build(pVerbose As %Boolean = 1, ByRef pParams, pAsync As %Boolean = 0) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel ]
{
	// exit if we're not in an actual DomainDefinition
	if (%class.Abstract || (%class.Name = "%iKnow.DomainDefinition")) {
		do %code.WriteLine("	quit $$$OK")
	} else {
		do %code.WriteLine("	quit:..%GetModel().disabled $$$ERROR($$$GeneralError, ""Domain is disabled"")")
		do %code.WriteLine("	quit ##class("_%compiledclass.Name_".Domain).%Build(pVerbose, .pParams, pAsync)")
	}
}

/// <p>This method will update dictionaries based on the current contents of the &lt;matching&gt; 
/// element in <xdata>Domain</xdata>, without making any changes to the current data (in terms
/// of sources) already stored in the domain. If <var>pMatch</var> is 1, all sources in the domain
/// will be matched after the dictionaries are updated. If <var>pDropFirst</var> is 1, the
/// current dictionaries will first be dropped from the domain, otherwise only new dictionary
/// entries will be added (no updates or deletions of existing entries).</p>
/// <p>Build parameters passed through <var>pParams</var> will be used to override default
/// expression values used in the dictionary definitions in the same way as in <method>%Build</method>.</p>
/// <p>The <var>pVerbose</var> argument controls whether status output is provided to stdev
/// (if <var>pAsync</var>=0) or written to a global for GUI pickup (<var>pAsync</var>=1, for
/// internal use only).</p>
ClassMethod %UpdateDictionaries(pDropFirst As %Boolean = 0, pMatch As %Boolean = 1, pVerbose As %Boolean = 1, ByRef pParams, pAsync As %Boolean = 0) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel ]
{
	// exit if we're not in an actual DomainDefinition
	if (%class.Abstract || (%class.Name = "%iKnow.DomainDefinition")) {
		do %code.WriteLine("	quit $$$OK")
	} else {
		do %code.WriteLine("	quit:..%GetModel().disabled $$$ERROR($$$GeneralError, ""Domain is disabled"")")
		do %code.WriteLine("	set tSC = $$$OK")
		do %code.WriteLine("	try {")
		do %code.WriteLine("		set tSC = ##class("_%compiledclass.Name_".Domain).%CreateDictionaries(pDropFirst, pVerbose, .pParams, pAsync)")
		do %code.WriteLine("		quit:$$$ISERR(tSC)")
		do %code.WriteLine()
		do %code.WriteLine("		if (pMatch) {")
		do %code.WriteLine("			write:pVerbose !,$zt($p($h,"","",2)),"": Matching sources...""")
		do %code.WriteLine("			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(..%GetDomainId())")
		do %code.WriteLine("			quit:$$$ISERR(tSC)")
		do %code.WriteLine("			write:pVerbose !,$zt($p($h,"","",2)),"": Finished matching sources""")
		do %code.WriteLine("		}")
		do %code.WriteLine("	} catch (ex) {")
		do %code.WriteLine("		set tSC = ex.AsStatus()")
		do %code.WriteLine("	}")
		do %code.WriteLine("	kill %expression")
		do %code.WriteLine("	quit tSC")
	}
}

/// <p>This method will explicitly rebuild all metrics in the domain described in <xdata>Domain</xdata>,
/// optionally dropping any existing values first if <var>pDropFirst</var> is 1.</p>
/// <p>See also the BuildAll() method in <class>%iKnow.Metrics.MetricBuilder</class>.</p>
ClassMethod %UpdateMetrics(pDropFirst As %Boolean = 1, pVerbose As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		if (..%GetModel().disabled) {
			set tSC = $$$ERROR($$$GeneralError, "Domain is disabled")
			quit
		}
		
		set:pDropFirst tSC = ##class(%iKnow.Metrics.MetricAPI).ClearAllValues(..%GetDomainId())
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Metrics.MetricBuilder).BuildAll(..%GetDomainId(),,, pVerbose)
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Callback invoked at the start of <method>%Build</method>. Subclasses can implement this
/// method to execute custom code at the start of a domain build operation.</p>
ClassMethod %OnBeforeBuild(pDomainId As %Integer) As %Status
{
	quit $$$OK
}

/// <p>Callback invoked at the end of <method>%Build</method>. Subclasses can implement this
/// method to execute custom code at the end of a domain build operation.</p>
ClassMethod %OnAfterBuild(pDomainId As %Integer) As %Status
{
	quit $$$OK
}

/// <p>Callback invoked at the start of <method>%DropData</method>. Subclasses can implement this
/// method to execute custom code at the start of a drop data operation.</p>
ClassMethod %OnBeforeDropData(pDomainId As %Integer, pDropDictionaries As %Boolean = 1, pDropSkipLists As %Boolean = 1) As %Status
{
	quit $$$OK
}

/// <p>Callback invoked at the end of <method>%DropData</method>. Subclasses can implement this
/// method to execute custom code at the end of a drop data operation.</p>
ClassMethod %OnAfterDropData(pDomainId As %Integer, pDropDictionaries As %Boolean = 1, pDropSkipLists As %Boolean = 1) As %Status
{
	quit $$$OK
}

/// Drops all non-static data from the domain defined by this class.
/// Depending on the values of <var>pDropDictionaries</var> and <var>pDropSkipLists</var>, dictionary
/// info and Skiplists are purged as well.
ClassMethod %DropData(pDropDictionaries As %Boolean = 1, pDropSkipLists As %Boolean = 0) As %Status [ Final, ForceGenerate ]
{
	set tSC = $$$OK
	try {
		set tDomainId = ..%GetDomainId()
		set tSC = ..%OnBeforeDropData(tDomainId, pDropDictionaries, pDropSkipLists)
		quit:$$$ISERR(tSC)
		set tSC = ##class(%iKnow.Domain).%OpenId(tDomainId).DropData(0, pDropDictionaries, 1, pDropSkipLists, 0)
		quit:$$$ISERR(tSC)
		set tSC = ..%OnAfterDropData(tDomainId, pDropDictionaries, pDropSkipLists)
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Evaluates the expression named <var>pName</var> and returns the result by reference.
ClassMethod %GetExpressionValue(pName As %String, Output pValue As %String, ByRef pParams) As %Status
{
	set tSC = $$$OK
	try {
		if (pName="") {
			set tSC = $$$ERROR($$$InvalidArgument)
			quit
		}
		
		set tSC = $classmethod($classname()_".Domain","%LoadExpressions", .pParams)
		quit:$$$ISERR(tSC)
		
		set pValue = $g(%expression(pName))
		kill %expression
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// INTERNAL METHOD - DO NOT INVOKE
/// Drops the underlying domain as part of %iKnow.DomainProjection.RemoveProjection()
ClassMethod %DropDomain() As %Status [ Final, ForceGenerate, Internal ]
{
	set tSC = ##class(%iKnow.Domain).%OpenId(..%GetDomainId()).DropData(1, 1, 1, 1, 1)
	quit:$$$ISERR(tSC) tSC
	quit ##class(%iKnow.Domain).%DeleteId(..%GetDomainId())
}

/// INTERNAL METHOD - DO NOT INVOKE
/// Drops a configuration managed by this domain as part of %iKnow.DomainProjection.RemoveProjection()
ClassMethod %DropManagedConfiguration(pConfigId As %Integer) As %Status [ Final, ForceGenerate, Internal ]
{
	quit ##class(%iKnow.Configuration).%DeleteId(pConfigId)
}

/// INTERNAL METHOD - DO NOT INVOKE
/// Drops a user dictionary managed by this domain as part of %iKnow.DomainProjection.RemoveProjection()
ClassMethod %DropManagedUserDictionary(pUserDictId As %Integer) As %Status [ Final, ForceGenerate, Internal ]
{
	quit ##class(%iKnow.UserDictionary).%DeleteId(pUserDictId)
}

/// INTERNAL METHOD - DO NOT INVOKE
ClassMethod %CreateStaticElements(pDomain As %iKnow.Model.domain, pDomainId As %Integer) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		quit:pDomain.disabled
		
		
		// 1: USER DICTIONARIES
		
		// generate any user dictionary objects listed in this domain definition
		// first drop all old user dictionaries managed by this definition
		kill tStillThere
		set tUDId = ""
		for {
			set tUDId = $order(^IRIS.IK.Sys.Definition($classname(),"userdict",tUDId))
			quit:tUDId=""
			
			set tUserDictObj = ##class(%iKnow.UserDictionary).%OpenId(tUDId)
			continue:tUserDictObj=""
			
			// check if this name still occurs
			set tStillThere(tUserDictObj.Name) = 0
			if $isobject(pDomain) {
				for i = 1:1:pDomain.userDictionaries.Count() {
					set tStillThere(tUserDictObj.Name) = (tUserDictObj.Name=pDomain.userDictionaries.GetAt(i).name)
					quit:tStillThere(tUserDictObj.Name)
				}
			}
			
			do:'tStillThere(tUserDictObj.Name) ##class(%iKnow.UserDictionary).%DeleteId(tUserDictObj)
		}
		kill ^IRIS.IK.Sys.Definition($classname(),"userdict")
		if $isobject(pDomain.userDictionaries) {
			for i = 1:1:pDomain.userDictionaries.Count() {
				#dim tUserDict As %iKnow.Model.userDictionary
				set tUserDict = pDomain.userDictionaries.GetAt(i)
				
				if $g(tStillThere(tUserDict.name)) {
					set tUserDictObj = ##class(%iKnow.UserDictionary).NameIndexOpen(tUserDict.name)
					set tUserDictObj.Description = tUserDict.description
				} else {
					set tUserDictObj = ##class(%iKnow.UserDictionary).%New(tUserDict.name, tUserDict.description)
				}
				set tSC = tUserDictObj.%Save()
				quit:$$$ISERR(tSC)
				
				// erase old entries
				set tSC = tUserDictObj.ClearEntries()
				quit:$$$ISERR(tSC)
				
				// add entries
				for j = 1:1:tUserDict.entries.Count() {
					set tEntry = tUserDict.entries.GetAt(j)
					if (tEntry.assignLabel'="") {
						set tSC = tUserDictObj.AddAttribute(tEntry.rewriteFrom, tEntry.assignLabel,, tEntry.metadata)
					} else {
						set tSC = tUserDictObj.AddEntry(tEntry.rewriteFrom, tEntry.rewriteTo)
					}
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
				
				set ^IRIS.IK.Sys.Definition($classname(),"userdict", tUserDictObj.Id) = ""
			}
			quit:$$$ISERR(tSC)
		}
		
		
		// 2: CONFIGURATIONS
		
		// generate any configuration objects listed in this domain definition
		// first drop all old configurations managed by this definition
		kill tStillThere
		set tConfigId = ""
		for {
			set tConfigId = $order(^IRIS.IK.Sys.Definition($classname(),"config",tConfigId))
			quit:tConfigId=""
			
			set tConfigObj = ##class(%iKnow.Configuration).%OpenId(tConfigId)
			continue:tConfigObj=""
			
			// check if this name still occurs
			set tStillThere(tConfigObj.Name) = 0
			if $isobject(pDomain.configurations) {
				for i = 1:1:pDomain.configurations.Count() {
					set tStillThere(tConfigObj.Name) = (tConfigObj.Name=pDomain.configurations.GetAt(i).name)
					quit:tStillThere(tConfigObj.Name)
				}
			}
			
			do:'tStillThere(tConfigObj.Name) ##class(%iKnow.Configuration).%DeleteId(tConfigId)
		}
		kill ^IRIS.IK.Sys.Definition($classname(),"config")
		if $isobject(pDomain.configurations) {
			for i = 1:1:pDomain.configurations.Count() {
				#dim tConfig As %iKnow.Model.configuration
				set tConfig = pDomain.configurations.GetAt(i)
				
				if $g(tStillThere(tConfig.name)) {
					set tConfigObj = ##class(%iKnow.Configuration).NameIndexOpen(tConfig.name)
					set tConfigObj.DetectLanguage = tConfig.detectLanguage
					set tConfigObj.Languages = $lfs($$$LOWER(tConfig.languages))
					set tConfigObj.UserDictionary = tConfig.userDictionary
					set tConfigObj.Summarize = tConfig.summarize
					set tConfigObj.MaxConceptLength = tConfig.maxConceptLength
				} else {
					set tConfigObj = ##class(%iKnow.Configuration).%New(tConfig.name, tConfig.detectLanguage, $lfs($$$LOWER(tConfig.languages)), tConfig.userDictionary, tConfig.summarize, tConfig.maxConceptLength)
				}
				set tSC = tConfigObj.%Save()
				quit:$$$ISERR(tSC)
				
				set ^IRIS.IK.Sys.Definition($classname(),"config", tConfigObj.Id) = ""
			}
			quit:$$$ISERR(tSC)
		}
		
		
		// 3: METADATA FIELDS
		
		// generate any metadata fields listed in this domain definition
		// first drop all old fields managed by this domain
		kill tStillThere
		set tFieldId = ""
		for {
			set tFieldId = $order(^IRIS.IK.Sys.Definition($classname(),"metaField",tFieldId))
			quit:tFieldId=""
			
			set tFieldObj = ##class(%iKnow.Objects.MetadataField).PKINDEXOpen(pDomainId, tFieldId)
			continue:tFieldObj=""
			
			// check if this name still occurs
			set tStillThere(tFieldObj.Name) = 0
			if $isobject(pDomain.metadata) && 'pDomain.metadata.disabled {
				for i = 1:1:pDomain.metadata.fields.Count() {
					set tField = pDomain.metadata.fields.GetAt(i)
					if (tFieldObj.Name=tField.name) {
						// check if these are properties we can still update, otherwise we'll have to delete and replace
						if (tFieldObj.DataType=tField.dataType) && (tFieldObj.IsCaseSensitive=tField.caseSensitive) {
							set tStillThere(tFieldObj.Name) = tFieldId
						}
						quit
					}
				}
			}
			
			do:'tStillThere(tFieldObj.Name) ##class(%iKnow.Queries.MetadataAPI).RemoveFieldById(pDomainId, tFieldId)
		}
		kill ^IRIS.IK.Sys.Definition($classname(),"metaField")
		if $isobject(pDomain.metadata) && 'pDomain.metadata.disabled {
			for i = 1:1:pDomain.metadata.fields.Count() {
				#dim tField As %iKnow.Model.metadataField
				set tField = pDomain.metadata.fields.GetAt(i)
				continue:tField.disabled
				
				set tOperators = $s(tField.operators="ALL":$$$MDALLOPERATORS, 1:$lfs(tField.operators))
				if $d(tStillThere(tField.name),tFieldId) && tFieldId {
					set tSC = ##class(%iKnow.Queries.MetadataAPI).UpdateField(pDomainId, tField.name, tOperators, tField.storage)
				} else {
					set tFieldId = ##class(%iKnow.Queries.MetadataAPI).AddField(pDomainId, tField.name, tOperators, tField.dataType, tField.storage, tField.caseSensitive,,,,.tSC)
				}
				quit:$$$ISERR(tSC)
				
				set ^IRIS.IK.Sys.Definition($classname(),"metaField", tFieldId) = ""
			}
			quit:$$$ISERR(tSC)
		}
		
		
		// 4: DOMAIN PARAMETERS
		
		// apply any defined domain parameters
		set tSC = ..%ApplyDomainParametersInternal(pDomain)
		quit:$$$ISERR(tSC)
		
		
		// 5: METRICS
		
		// register any metrics defined in this domain definition
		kill tStillThere
		set tMetricId = ""
		for {
			set tMetricId = $order(^IRIS.IK.Sys.Definition($classname(),"metric",tMetricId))
			quit:tMetricId=""
			
			set tMetricObj = ##class(%iKnow.Metrics.Metric).PKINDEXOpen(pDomainId, tMetricId)
			continue:tMetricObj=""
			
			// check if this name still occurs
			set tStillThere(tMetricObj.Name) = 0
			if $isobject(pDomain.metrics) && 'pDomain.metrics.disabled {
				for i = 1:1:pDomain.metrics.metrics.Count() {
					set tMetric = pDomain.metrics.metrics.GetAt(i)
					set tStillThere(tMetricObj.Name) = (tMetricObj.Name=tMetric.name)
					quit:tStillThere(tMetricObj.Name)
				}
			}
			
			do:'tStillThere(tMetricObj.Name) ##class(%iKnow.Metrics.Metric).%Delete(tMetricObj.%Oid())
		}
		kill ^IRIS.IK.Sys.Definition($classname(),"metrics")
		if $isobject(pDomain.metrics) && 'pDomain.metrics.disabled {
			
			// delegate metric declaration to MetricDefinition class
			set tSC = ##class(%iKnow.Metrics.MetricDefinition).RegisterInternal(pDomainId, pDomain.metrics, $classname(), 0)
			quit:$$$ISERR(tSC)
			
			// but also register in ^IRIS.IK.Sys.Definition
			for i=1:1:pDomain.metrics.metrics.Count() {
				set tMetric = pDomain.metrics.metrics.GetAt(1)
				continue:tMetric.disabled
				set tMetricName = tMetric.name
				set tMetricObj = ##class(%iKnow.Metrics.Metric).NameIndexOpen(pDomainId, tMetricName)
				continue:tMetricObj=""  // ?
				set ^IRIS.IK.Sys.Definition($classname(),"metrics",tMetricObj.MetricId) = ""
			}
		}
		
		
		// 6: SKIPLISTS
		
		// generate any skiplists listed in this domain definition
		// first drop all old lists managed by this domain
		kill tStillThere
		set tBLId = ""
		for {
			set tBLId = $order(^IRIS.IK.Sys.Definition($classname(),"blacklist",tBLId))
			quit:tBLId=""
			
			set tBLObj = ##class(%iKnow.Objects.SkipList).PKINDEXOpen(pDomainId, tBLId)
			continue:tBLObj=""
			
			// check if this name still occurs
			set tStillThere(tBLObj.Name) = 0
			for i = 1:1:pDomain.skiplists.Count() {
				set tBL = pDomain.skiplists.GetAt(i)
				if (tBLObj.Name=tBL.name) {
					if (tBLObj.Description=tBL.description) {
						set tStillThere(tBLObj.Name) = tBLId
					}
					quit
				}
			}
			
			do:'tStillThere(tBLObj.Name) ##class(%iKnow.Utils.MaintenanceAPI).DropSkipList(pDomainId, tBLId)
		}
		kill ^IRIS.IK.Sys.Definition($classname(),"blacklist")
		for i = 1:1:pDomain.skiplists.Count() {
			#dim tBL As %iKnow.Model.skiplist
			set tBL = pDomain.skiplists.GetAt(i)
			
			if $d(tStillThere(tBL.name),tBLId) && tBLId {
				set tSC = ##class(%iKnow.Utils.MaintenanceAPI).ClearSkipList(pDomainId,tBLId)
			} else {
				set tBLId = ##class(%iKnow.Utils.MaintenanceAPI).CreateSkipListInternal(pDomainId, tBL.name, tBL.description, $classname(), .tSC)
			}
			quit:$$$ISERR(tSC)
			
			set tEntryCount = tBL.entries.Count()
			for j = 1:1:tEntryCount {
				set tSC = ##class(%iKnow.Utils.MaintenanceAPI).AddStringToSkipList(pDomainId, tBLId, tBL.entries.GetAt(j))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
			set ^IRIS.IK.Sys.Definition($classname(),"blacklist", tBLId) = ""
		}
		quit:$$$ISERR(tSC)
	}
	catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %IsProperCode(pExpression As %String) As %Boolean [ Internal ]
{
	set tIsCode = 0
	
	// simple strings and numbers are fine
	quit:$zname(pExpression) 0
	quit:$isvalidnum(pExpression) 0
	
	// we only care about values with actual expression references or code that's already
	// put in code form through previous $$$QUOTE() calls (such as in listTable)
	quit:('$find(pExpression,"%expression."))&&('$find(pExpression,"%domain.")) 0
	
	// straight %expression and %domain references are clear too
	quit:($e(pExpression,1,12)="%expression.")&&$zname($e(pExpression,13,*)) 1
	quit:($e(pExpression,1,8)="%domain.")&&($e(pExpression,*-1,*)="()")&&$zname($e(pExpression,9,*-2),5) 1
	
	// for others, check if they result in valid syntax
	try {
		set x = ##class(%ZEN.proxyObject).%New()
		xecute ("(%expression, %domain) { set str = ("_pExpression_") }", x, x)
		set tIsCode = 1
	} catch (ex) {
		if (ex.Name="<SYNTAX>") || (ex.Name="<UNDEFINED>") {
			set tIsCode = 0
		} else { // such as <INVALID OREF>
			set tIsCode = 1 
		}
	}
	quit tIsCode
}

/// Returns the code to populate a variable with a value for <var>pExpression</var>. The code 
/// returned can be used as if it were a quoted string
ClassMethod %ParseExpression(pDomDefClassName As %String, pExpression As %String, Output pCode As %String, Output pDependencies) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pDependencies
		set pCode=""
		quit:(pExpression="")
		
		// for backwards compatibilty, check if this already *is* a quoted string
		if '..%IsProperCode(pExpression) {
			set pExpression = $$$QUOTE(pExpression)
		}
		
		set tState=0, tPos=0, tLength=$l(pExpression), tQuoted=0, tBrackets=0
		while tPos <= tLength {
			set tChar = $e(pExpression,$i(tPos))
			if tChar="""" {
				if ($e(pExpression,tPos+1)="""") { // double quotes don't matter
					set tPos=tPos+1
					set pCode = pCode_""""""
					continue
				} else { // switch between quoted and non-quoted mode
					set tQuoted=(1-tQuoted)
					set pCode = pCode_""""
					continue
				}
			} elseif tChar="%" {
				if ($e(pExpression,tPos,tPos+7)="%domain.") {
					
					set tBracketPos = $find(pExpression,"(",tPos)
					set:tQuoted pCode = pCode_"""_"
					set pCode = pCode_"##class("_pDomDefClassName_")"_$e(pExpression,tPos+7,tBracketPos-1)
					set tPos=tBracketPos-1
					set:tQuoted tBrackets($i(tBrackets))=1 // if quoted, track brackets so we can close
					continue
					
				} elseif ($e(pExpression,tPos,tPos+11)="%expression.") {
					
					set tExprName="", tPos=tPos+11, tChar=""
					while 1 {
						set tPos=tPos+1, tChar=$e(pExpression,tPos)
						if '$zname(tExprName_tChar) {
							set tPos=tPos-1
							quit
						} 
						set tExprName = tExprName_tChar
						quit:(tPos=tLength)
					}
					set pDependencies(tExprName)=""
					set:tQuoted pCode = pCode_"""_"
					set pCode = pCode_"%expression("_$$$QUOTE(tExprName)_")"
					set:tQuoted&&(tPos'=tLength) pCode = pCode_"_"""
					continue
					
				} else {
					set pCode = pCode_tChar
					continue
				}
			} elseif (tChar="(") {
				set:tBrackets tBrackets(tBrackets)=tBrackets(tBrackets)+1
				set pCode = pCode_tChar
				continue
			} elseif (tChar=")") {
				set:tBrackets tBrackets(tBrackets)=tBrackets(tBrackets)-1
				if tBrackets && (tBrackets(tBrackets)=0) {
					kill tBrackets(tBrackets)
					set tBrackets = tBrackets-1
					set:'tBrackets pCode = pCode_tChar_"_"""
				} else {
					set pCode = pCode_tChar
					continue
				}
			} else {
				set pCode = pCode_tChar
				continue
			}
		}
		/*
		set:$extract(pCode,1,3)="""""_" pCode = $e(pCode,4,*)
		set:$extract(pCode,*-2,*)="_""""" pCode = $e(pCode,1,*-3)
		*/
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Callback method to define customizations of the generated table structures if objectsPackage'=""
/// See also CreateDomainTables() in <class>%iKnow.Tables.Utils</class>
ClassMethod %GetCustomizations(Output pCustomizations, Output pMetadata As %List) As %Status [ Internal ]
{
	kill pCustomizations
	set pMetadata=""
	quit $$$OK
}

}
