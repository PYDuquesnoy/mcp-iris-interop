/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p><b>Deprecation note</b>: Direct use of this class is still supported, but it is recommended to use either
/// Domain Definitions (cf <class>%iKnow.DomainDefinition</class>) to manage a domain's contents
/// or use the shorthand methods in <class>%SYSTEM.iKnow</class> to work with an existing
/// domain not managed through a domain definition class.</p>
/// <p>This is the base class for any Lister implementations. Lister classes are used at the start of the
/// load process to identify the sources that need to be loaded. 
/// Each Lister implemenation is specifically designed to be able to scan a certain type of source
/// locations, for example a filesystem for <class>%iKnow.Source.File.Lister</class> and a SQL query for 
/// <class>%iKnow.Source.SQL.Lister</class></p>
/// <p>Each Lister implementation class defines a set of <b>Lister Parameters</b>, specifying how to
/// reach the sources in the particular type of location this Lister class is designed to work with.
/// For a file lister, this would include parameters such as the directory where to look and the type
/// of files to load from that directory. These <b>Lister Parameters</b> are documented by each
/// Lister implementation in its class documentation.</p>
/// <p>These Lister Parameters are to be provided to the <method>AddListToBatch</method> method, when
/// configuring a list for Batch Loading, or to the <method>ProcessList</method> method when executing
/// Direct Loads.</p>
Class %iKnow.Source.Lister Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

Property DomainId As %Integer [ Private ];

/// surrogate domain ID for use in IRIS.Temp
/// guaranteed to be unique across namespaces
Property TempId As %Integer [ Private ];

Property ListerClassId As %Integer [ Private ];

Property Configuration As %String;

Property ConfigurationId As %Integer [ Private ];

Property Processor As %String [ Private ];

Property ProcessorId As %Integer [ Private ];

Property ProcessorParams As %String [ Private ];

Property Converter As %String [ Private ];

Property ConverterId As %Integer [ Private ];

Property ConvParams As %String [ Private ];

Property CurrentRef As %String [ Private ];

Property ListId As %Integer [ Private ];

Property DataId As %Integer [ Internal, Private ];

Property CurData As %Integer [ Internal, Private ];

Property SrcList As %String [ Internal ];

Property SrcData As %String [ Internal, Private ];

Property MetaId As %Integer [ Internal, Private ];

Property CurMetaLength As %Integer [ Internal, Private ];

Property SrcMeta As %String [ Internal ];

Property SrcTemp As %String [ Internal, Private ];

Property SrcTempMeta As %String [ Internal ];

Property ListGlo As %String [ Internal, Private ];

Property BatchMode As %Integer [ Internal, Private ];

Property FixedMetaKeys As %List [ Internal, Private ];

Property FixedMetaValues As %List [ Internal, Private ];

/// Utility local Loader instance for the <method>ProcessList</method> wrapper call
Property Loader As %iKnow.Source.Loader [ Internal, Private ];

Method %OnNew(domId As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	$$$IKCHECKPRIVWRITE
	if (domId'=0) { // BDB464
	    $$$CHECKDOMAINEXISTS(domId)
	}
 
    Set i%DomainId=domId
    
    // BDB500 - fetch system-wide unique domain ID
    $$$IKTEMPDOMID(domId,tTempId)
    Set i%TempId = tTempId

    // Get the lister Class #id#, interning it if necessary
    Set Lister=..%ClassName(1)
    If '$d(^IRIS.IK.Sys.ListerI(Lister),id) {
        // Do this while locked, so we don't get duplicates if multiple listers see the same class
        Lock +^IRIS.IK.Sys.ListerD
        If '$d(^IRIS.IK.Sys.ListerI(Lister),id) {
	        set alias=..GetAlias()
	        if (alias'="") && $d(^IRIS.IK.Sys.ListerAlias(alias), aliasData) {
		        lock -^IRIS.IK.Sys.ListerD
		        quit $$$ERROR($$$IKListerAliasInUse, alias, $li(aliasData,2))
	        }
            Set id=$i(^IRIS.IK.Sys.ListerD),^IRIS.IK.Sys.ListerD(id)=Lister,^IRIS.IK.Sys.ListerI(Lister)=id
            Set:alias'="" ^IRIS.IK.Sys.ListerAlias(alias)=$lb(id,Lister)
        }
        Lock -^IRIS.IK.Sys.ListerD
    }
    Set i%ListerClassId=id
    quit ..Init("", ..DefaultProcessor())
}

Method SetBatchMode(BatchMode As %Integer) [ Internal ]
{
    Set BatchMode=''$g(BatchMode)
    If i%SrcList'="",i%BatchMode=BatchMode { Quit }
    Set i%BatchMode=BatchMode
    If BatchMode {
        Set pref="^IRIS.Temp.IK."_i%TempId_"."
        // Only used in Batch mode
        Set i%ListGlo=pref_"List"
        Set i%SrcData=pref_"SrcData"
    } Else {
        Set pref="^||%ik."
        Set i%ListGlo=""
        Set i%SrcData=""
    }
    Set i%SrcList=pref_"SrcList"
    Set i%SrcMeta=pref_"SrcMeta"
    Set i%SrcTemp=pref_"SrcTemp"
    set i%SrcTempMeta=pref_"SrcTempMeta"
}

/// <p>Shorthand method invoking <method>SetConfig</method>, <method>SetProcessor</method> and
/// <method>SetConverter</method> in one call. A Lister can be re-initialized between calls to
/// <method>AddListToBatch</method> or <method>ProcessList</method>, resulting in different
/// settings to be used for the respective lists.</p>
Method Init(config As %String, processor As %String, processorParams As %List = "", converter As %String = "", converterParams As %List = "") As %Status [ ServerOnly = 1 ]
{
    Set sc=..SetConfig(.config)
    Quit:$$$ISERR(sc) sc
    Set sc=..SetProcessor(.processor,.processorParams)
    Quit:$$$ISERR(sc) sc
    Set sc=..SetConverter(.converter,.converterParams)
    Quit:$$$ISERR(sc) sc
    
    quit $$$OK
}

Method SetDataId(dataId As %Integer) As %Status [ Final, Internal, ServerOnly = 1 ]
{
    Set i%DataId=dataId
    
    // BDB375 - we'll take this opportunity to load the fixed metadata keys/values for this
    // DataId, as we can then consider these fixed keys/values as part of ordinary Lister
    // metadata. We're calling ..RegisterMetadataKeys() to ensure the keys are picked up, 
    // but they can be extended through subsequent ..RegisterMetadataKeys() calls in 
    // ..ExpandList()
    set tData = $g(@i%SrcData@(dataId)), i%FixedMetaKeys = $lg(tData,6), i%FixedMetaValues = $lg(tData,7)
    quit ..RegisterMetadataKeysInternal("",1)
}

/// <p>Registers the <class>%iKnow.Source.Configuration</class> name to use when indexing sources
/// from from the lists registered through <method>AddListToBatch</method> or
/// <method>ProcessList</method> calls onwards.
/// Using this method to set a different Configuration between two <method>AddListToBatch</method>
/// calls will not impact any lists already registered in earlier calls.</p>
Method SetConfig(ByRef config As %String) As %Status [ Final ]
{
    if $g(config)="" {
	    set config=$$$GETPARAM(..DomainId,$$$IKPDEFAULTCONFIG,$$$DEFAULTCONFIG)
	    
    }
    
    // make sure the default exists
    if (config=$$$DEFAULTCONFIG) {
           do ##class(%iKnow.Configuration).CreateDefaultConfig()
    }
    
    Set i%CurrentRef=""
    If config'=i%Configuration {
	    set tConfig = ##class(%iKnow.Configuration).NameIndexOpen(config)
        quit:tConfig="" $$$ERROR($$$IKConfigurationNotFound,config)
        
        set i%Configuration=config,i%ConfigurationId=tConfig.Id
    }
    quit $$$OK
}

/// <p>Registers the <class>%iKnow.Source.Processor</class> class and parameters to use when indexing sources
/// from from the lists registered through <method>AddListToBatch</method> or
/// <method>ProcessList</method> calls onwards.
/// Using this method to set a different Processor between two <method>AddListToBatch</method>
/// calls will not impact any lists already registered in earlier calls.</p>
Method SetProcessor(processor As %String, processorParams As %List) As %Status [ Final ]
{
    // Get the processor id#, interning it if necessary
    Set:$g(processor)="" processor=..DefaultProcessor()
    Set i%ProcessorParams=$g(processorParams)
    Quit:processor=i%Processor $$$OK
    If '$d(^IRIS.IK.Sys.ProcessorI(processor),id) {
	        
        // check if this is a valid Processor class
        quit:(##class(%Dictionary.CompiledClass).%OpenId(processor)="") $$$ERROR($$$IKInvalidProcessor, processor)
        quit:'$classmethod(processor,"%Extends","%iKnow.Source.Processor") $$$ERROR($$$IKInvalidProcessor, processor)
	        
        // Do this while locked, so we don't get duplicates if multiple listers see the same class
        Lock +^IRIS.IK.Sys.ProcessorD
        Set:'$d(^IRIS.IK.Sys.ProcessorI(processor),id) id=$i(^IRIS.IK.Sys.ProcessorD),^IRIS.IK.Sys.ProcessorD(id)=processor,^IRIS.IK.Sys.ProcessorI(processor)=id
        Lock -^IRIS.IK.Sys.ProcessorD
    }
    Set i%ProcessorId=id, i%Processor=processor
    Quit $$$OK
}

/// <p>Registers the <class>%iKnow.Source.Converter</class> class and parameters to use when indexing sources
/// from from the lists registered through <method>AddListToBatch</method> or
/// <method>ProcessList</method> calls onwards.
/// Using this method to set a different Converter between two <method>AddListToBatch</method>
/// calls will not impact any lists already registered in earlier calls.</p>
Method SetConverter(converter As %String, convparams As %List) As %Status [ Final ]
{
    Set converter=$g(converter)
    Set i%ConvParams=$g(convparams)
    If converter'=i%Converter {
        If '$d(^IRIS.IK.Sys.ConverterI(converter),id) {
	        
	        // check if this is a valid Converter class
	        quit:(##class(%Dictionary.CompiledClass).%OpenId(converter)="") $$$ERROR($$$IKInvalidConverter, converter)
	        quit:'$classmethod(converter,"%Extends","%iKnow.Source.Converter") $$$ERROR($$$IKInvalidConverter, converter)
	        
            // Do this while locked, so we don't get duplicates if multiple listers see the same class
            Lock +^IRIS.IK.Sys.ConverterD
            Set:'$d(^IRIS.IK.Sys.ConverterI(converter),id) id=$i(^IRIS.IK.Sys.ConverterD),^IRIS.IK.Sys.ConverterD(id)=converter,^IRIS.IK.Sys.ConverterI(converter)=id
            Lock -^IRIS.IK.Sys.ConverterD
        }
        Set i%Converter=converter,i%ConverterId=id
    }
    Set i%CurrentRef=""
    Quit $$$OK
}

/// <p>This method returns the default <class>%iKnow.Source.Processor</class> class to use
/// (without any parameters) if none was registered explicitly through calls to
/// <method>SetProcessor<method>. By default, this selects (if it exists)
/// a class called Processor in the same package as this Lister implementation, but subclasses
/// might wish to override this and hardcode a specific default Processor to use.</p>
ClassMethod DefaultProcessor() As %String
{
    Set clsname=..%ClassName(1)
    If ($e(clsname,*-6,*)=".Lister") {
        Set procClsName = $e(clsname,1,*-6)_"Processor"
        Quit:##class(%Dictionary.CompiledClass).%ExistsId(procClsName) procClsName
    }
    quit ""
}

/// <p>This method is used to register a list the Lister implementation will later on scan through
/// as part of the execution of the <class>%iKnow.Source.Loader</class> ProcessBatch process.
/// This method takes this Lister implementations <b>Lister Parameters</b> as its arguments, as
/// specified in the class documentation of this Lister implementation.</p>
Method AddListToBatch(listargs...) As %Status [ Final ]
{
	// BDB464 - ensure we're not adding *real* sources to the system domain
	quit:'i%DomainId $$$ERROR($$$IKSysDomVirtualOnly)
	
	set tSC = ..TestParams(listargs...)
	quit:$$$ISERR(tSC) tSC
	
    Set list=""
    For i=1:1:listargs { Set list=list_$lb(listargs(i)) }
    Do ..SetBatchMode(1)
    set data=..GetListerData()
    // if this is a new set of parameters or the previous was erased with Loader.Reset()
    if ('$LS(data,i%CurData) || '$d(@i%SrcData@(+i%DataId))) {
	    set i%DataId=$i(@i%SrcData),@i%SrcData@(i%DataId)=data,i%CurData=data
    }
    Set loc=$i(@i%ListGlo),@i%ListGlo@(loc)=$lb(i%ListerClassId,i%DataId,list)
    Quit $$$OK
}

/// <p>This method should be overridden by subclasses, implementing how they scan through the particular
/// type of source location or structures they specialize in. The arguments for this method are the
/// same Lister Parameters as those used when issuing the corresponding <method>AddListToBatch</method>
/// call and are specified and documented by the Lister implementation.</p>
/// <p>When expanding the list, the Lister should build a "Composite reference": a %List containing the lister
/// ID, the group ID and the local reference for each (candidate) source it found and pass that to
/// either a <method>StoreRef</method>, <method>StoreTemp</method> or <method>StoreTempStream</method>
/// call. Optionally, it can store metadata for each of these refs using the
/// <method>SetMetadataValues</method> method.</p>
/// <p><b>NOTE:</b> This method is used by the iKnow loading frameworkand should never be called by
/// custom code.</p>
Method ExpandList(listparams As %List) As %Status
{
    Quit $$$OK
}

/// Utility method to report failures for a given source (identified through a Composite Ref)
Method ReportError(ref As %List, message As %String, location As %String = "") As %Status [ Final, Private ]
{
	set:location="" location = ..%ClassName(1)
    set ^IRIS.IKL.Failed(i%DomainId,$i(^IRIS.IKL.Failed(i%DomainId)))=$lb(ref,location,message,,$h)
    quit $$$OK
}

/// Utility method to report warnings for a given source (identified through a Composite Ref)
Method ReportWarning(ref As %List, message As %String, location As %String = "") As %Status [ Final, Private ]
{
	set:location="" location = ..%ClassName(1)
    Set ^IRIS.IKL.Warning(i%DomainId,$i(^IRIS.IKL.Warning(i%DomainId)))=$lb(ref,location,message,$h)
    Quit $$$OK
}

/// <p>Stores the supplied reference for a source to be loaded, along with the sources contents
/// passed in through 'data' as a <class>%String</class>
/// to be processed by <class>%iKnow.Source.Temp.Processor</class> (make sure it is set using 
/// <method>SetProcessor</method> at runtime or <method>DefaultProcessor</method> as the overall
/// default!).</p>
/// <p>This method can be called with the same ref multiple times, which will append the
/// <class>%String</class> data passed in.</p>
Method StoreTemp(ref As %List, data As %String) As %Status [ Final, Private ]
{
    set tSC = ..StoreRef(ref) // make sure ..ListId points to the supplied ref
    quit:$$$ISERR(tSC) tSC
    Set inc=$i(@i%SrcTemp@(i%ListId)),@i%SrcTemp@(i%ListId,inc)=data
    Quit $$$OK
}

/// <p>Stores the supplied reference for a source to be loaded, along with the sources contents
/// passed in through 'data' in the form of a <class>%Stream.GlobalCharacter</class>
/// to be processed by <class>%iKnow.Source.Temp.Processor</class>.</p>
/// <p>See also <method>StoreTemp</method></p>
Method StoreTempStream(ref As %List, streamOID As %String) As %Status [ Final, Private ]
{
    set tSC = ..StoreRef(ref) // make sure ..ListId points to the supplied ref
    quit:$$$ISERR(tSC) tSC
    
    // BDB271: actions like selecting from remote tables can yield objects straight away,
    // so only objectize if it isn't already an object.
    if $isobject(streamOID) {
	    quit:streamOID.IsNull() tSC
	    set streamObj = streamOID
    } else {
    	quit:##class(%Stream.GlobalCharacter).StreamOIDIsNull(streamOID) tSC
    	set streamObj = ##class(%Stream.GlobalCharacter).%Open(streamOID)
    }
    quit:streamObj="" $$$ERROR($$$LoadObjectNotFound, "%Stream.GlobalCharacter", streamOID)
    while ('streamObj.AtEnd) {
    	set len = 32000
    	set text = streamObj.Read(.len, .tSC)
    	quit:$$$ISERR(tSC)
        set inc=$i(@i%SrcTemp@(i%ListId)), @i%SrcTemp@(i%ListId,inc)=text
    }
    set streamObj = ""
    quit tSC
}

/// <p>Stores the supplied metadata values for the source being listed identified by ref.
/// The values in metavalues should correspond positionally to the metadata field names
/// passed in the most recent call to <method>RegisterMetadataKeys</method> for this
/// Lister instance.</p>
Method SetMetadataValues(ref As %List, metaValues As %List) As %Status [ Final, Private ]
{
    quit:$ll(metaValues)'=i%CurMetaLength $$$ERROR($$$IKMDValueCountMismatch, $ll(metaValues), ..CurMetaLength)
    set tSC = ..StoreRef(ref) // make sure ..ListId points to the supplied ref
    quit:$$$ISERR(tSC) tSC
    Set @i%SrcTempMeta@(i%ListId)=metaValues_i%FixedMetaValues
    Quit $$$OK
}

/// <p>Registers the specified list of metadata field names to be used for all subsequent calls
/// to <method>SetMetadataValues</method> until <method>RegisterMetadataKeys</method> is called again.</p>
/// <p>The entries in the supplied %List have to be existing metadata field names for the current
/// domain, otherwise they will be ignored.</p>
Method RegisterMetadataKeys(metaFieldNames As %List) As %Status [ Final, Private ]
{
	quit ..RegisterMetadataKeysInternal(metaFieldNames, 0)
}

/// Internal method. Allows explicitly updating the current metadata list to ensure new values
/// for fixed fields are picked up.
Method RegisterMetadataKeysInternal(metaFieldNames As %List, forceRefresh As %Boolean = 0) As %Status [ Final, Internal ]
{
	set tCombinedKeys = metaFieldNames_i%FixedMetaKeys
	quit:tCombinedKeys="" $$$OK
    set:forceRefresh||'$LS(tCombinedKeys,$g(@i%SrcMeta@(+i%MetaId))) i%MetaId=$i(@i%SrcMeta), @i%SrcMeta@(i%MetaId)=tCombinedKeys, i%CurMetaLength=$ll(metaFieldNames)
    quit $$$OK
}

/// Registers fixed metadata values <var>pValues</var> for the metadata fields in <var>pKeys</var>,
/// for all sources to be listed as part of the next <method>ProcessList</method> or 
/// <method>AddListToBatch</method> calls, until the next call to <method>RegistereFixedMetadata</method>.
/// The keys and values in <var>pKeys</var> and <var>pValues</var> should correspond positionally.
Method RegisterFixedMetadata(pKeys As %List, pValues As %List) As %Status [ Final ]
{
	quit:$ll(pKeys)'=$ll(pValues) $$$ERROR($$$IKMDValueCountMismatch, $ll(pKeys), $ll(pValues))
	set ..FixedMetaKeys = pKeys, ..FixedMetaValues = pValues
	quit $$$OK
}

Method GetListerData() As %List [ Final, Internal ]
{
    Quit $lb(i%ConfigurationId,i%ProcessorId,i%ProcessorParams,i%ConverterId,i%ConvParams,i%FixedMetaKeys,i%FixedMetaValues)
}

/// Stores the supplied reference for a source to be processed.
Method StoreRef(ref As %List) As %Status [ Final, Private ]
{
	quit:(i%CurrentRef'="")&&$ls(ref,i%CurrentRef) $$$OK
    Set i%ListId=$i(@i%SrcList),@i%SrcList@(i%ListId)=$lb(ref,i%DataId,i%MetaId),i%CurrentRef=ref
    
    // BDB609 - when there is fixed metadata registered, but this lister hasn't got any
    // 			metadata automatically retrieved metadata of its own, ensure we're saving
    //			the fixed ones' values for this source.
    if (i%FixedMetaKeys'="") && 'i%CurMetaLength {
    	set @i%SrcTempMeta@(i%ListId)=i%FixedMetaValues
    }
    
    Quit $$$OK
}

/// <p>Basic method to check if a given reference exists already in the domain, which can be
/// used in the Lister process to take appropriate action, such as skipping this particular
/// ref or raising an error. If checkStaging is set to 1, it will also loop through the sources
/// listed so far (by <method>ExpandList</method> calls) to see if there is no name conflict
/// with these either.</p>
Method RefExists(groupName As %String, localRef As %String, checkStaging As %Boolean = 0) As %Boolean [ Private ]
{
    Set groupId = ..GetGroupId(i%DomainId,i%ListerClassId,groupName)
    Quit:'groupId 0
        
    Set srcId = ##class(%iKnow.Queries.SourceAPI).GetSourceId(i%DomainId, ..BuildExtIdFromName(i%DomainId, groupName, localRef))
        
    Quit:srcId>0 1
    Quit:'checkStaging 0
        
    Set listerId="", ref=$lb(i%ListerClassId, groupId, localRef)
    For {
        Set listerId = $o(@i%SrcList@(listerId),1,stage)
        Quit:listerId=""
        Goto:$ls($li(stage),ref) fnd
    }
    Quit 0
fnd Quit 1
}

/// <p>This method will split a complete External ID into the lister reference, group name and local
/// reference and return the corresponding lister ID, group ID and local reference.</p>
/// <p>The exact implementation of splitting the full reference into a group name and local reference
/// is delegated to <method>SplitFullRef</method> method of the specific Lister implementation as
/// referenced by the lister reference, which is the first part of the full External ID.</p>
ClassMethod SplitExtId(domainId As %Integer, extId As %String, Output listerId As %Integer, Output groupId As %Integer, Output localRef As %String) As %Status [ Final ]
{
    If $$$SIMPLEEXTIDS(domainId) { Set groupId=0,localRef=extId Quit }
    If $e(extId)=":" {
        Set alias=$p(extId,":",2),x=$s(alias="":"", 1:$g(^IRIS.IK.Sys.ListerAlias(alias)))
        Quit:x="" $$$ERROR($$$IKUnknownLister, alias)
        Set ref=$e(extId,$l(alias)+3,*),listerId=$lg(x),listerClass=$lg(x,2)
    } Else {
        Set listerClass=$p(extId,":"),listerId=$s(listerClass="":"", 1:$g(^IRIS.IK.Sys.ListerI(listerClass)))
        Quit:listerId="" $$$ERROR($$$IKUnknownLister, listerClass)
        Set ref=$e(extId,$l(listerClass)+2,*)
    }
    // now split the remainder of the external ID in groupName and localRef
    Set tSC = $classmethod(listerClass, "SplitFullRef", domainId, ref, .groupName, .localRef)
    Quit:$$$ISERR(tSC) $$$ERROR($$$IKFailedSplitExtId, externalId)
    Set groupId=..GetGroupId(domainId,listerId,groupName)
    Quit $$$OK
}

/// <p>This method will assemble an External ID, starting from the lister ID, group ID and local
/// reference.</p>
/// <p>The exact implementation of combining the group name and local reference into a full reference
/// is delegated to <method>BuildFullRef</method> method of the specific Lister implementation
/// referenced by the listerId.</p>
ClassMethod BuildExtId(domainId As %Integer, listerId As %Integer, groupId As %Integer, localRef As %String, Output sc As %Status = {$$$OK}) As %String [ Final ]
{
	set sc = $$$OK
	
    // if we're in SimpleExtId mode, the external ID is just the local reference
    Quit:$$$SIMPLEEXTIDS(domainId) localRef
    
    // make sure the lister class corresponding to the supplied lister ID is used
    Set listerClass = $g(^IRIS.IK.Sys.ListerD(listerId))
    if (listerClass="") { set sc = $$$ERROR($$$IKUnableOpenListerId, listerId)  quit "" }
    
    // if we are in the right class, use quick .. syntax
    if (listerClass=..%ClassName(1)) {
	    set groupName = ..GetGroupName(domainId, listerId, groupId, .sc)
	    quit:$$$ISERR(sc) ""
	    quit ..GetExtidPrefix() _ ..BuildFullRef(domainId, groupName, localRef)
    }
    
    // otherwise, we'll have to resort to $classmethod() invocations
    set groupName = $classmethod(listerClass, "GetGroupName", domainId, listerId, groupId, .sc)
    quit:$$$ISERR(sc) ""
    Quit $classmethod(listerClass, "GetExtidPrefix") _
         $classmethod(listerClass, "BuildFullRef", domainId, groupName, localRef)
}

/// <p>This method will, assuming it is called for the appropriate Lister class, build the External ID
/// based on the group name and local reference.</p>
/// <p><b>WARNING:</b> this method will throw an error if called from the abstract Lister class,
/// as this combination of groupName and localRef is specific to the Lister implementation class.</p>
ClassMethod BuildExtIdFromName(domainId As %Integer, groupName As %String, localRef As %String, Output sc As %Status = {$$$OK}) As %String [ Final ]
{
	set sc = $$$OK
	
    // if we're in SimpleExtId mode, the external ID is just the local reference
    Quit:$$$SIMPLEEXTIDS(domainId) localRef
    
    if (..%ClassName(1)="%iKnow.Source.Lister") { 
    	set sc = $$$ERROR($$$IKBuildExtIdFromNameRoot)  
    	quit "" 
    }
    
    Quit ..GetExtidPrefix() _ ..BuildFullRef(domainId, groupName, localRef)
}

/// <p>This method should be implemented by subclasses, taking into account the Full Reference structure
/// for this particular Lister implementation. It derives the Group Name and Local Reference from the supplied
/// Full Reference.</p>
ClassMethod SplitFullRef(domainId As %Integer, fullRef As %String, Output groupName As %String, Output localRef As %String) As %Status [ Private ]
{
    // default implementation does not identify a group name
    Set groupName="",localRef=fullRef
    Quit $$$OK
}

/// <p>This method should be implemented by subclasses, taking into account the Full Reference structure
/// for this particular Lister. It builds the Full Reference based on a Group Name and Local Reference.</p>
ClassMethod BuildFullRef(domainId As %Integer, groupName As %String, localRef As %String) As %String [ Private ]
{
    // default implementation just concatenates group name and local ref
    Quit groupName _ localRef
}

/// Builds a reference for use in $$$IKPSIMPLEEXTIDS domains. Defaults to the Local Ref
ClassMethod BuildSimpleRefFromComposite(domainId As %Integer, ref As %List, Output sc As %Status = {$$$OK}) As %String [ Internal ]
{
	set sc = $$$OK
	quit $lg(ref, 3)
}

ClassMethod BuildFullRefFromComposite(domainId As %Integer, ref As %List, Output sc As %Status = {$$$OK}) As %String [ Final, Internal ]
{
	set sc = $$$OK
    set listerClass = $g(^IRIS.IK.Sys.ListerD($li(ref,1)))
    if (listerClass="") { set sc = $$$ERROR($$$IKUnableOpenListerId, listerId)  quit "" }
    
    set groupName = $classmethod(listerClass, "GetGroupName", domainId, $li(ref,1), $li(ref,2), .sc)
    quit:$$$ISERR(sc) ""
    
    quit $classmethod(listerClass, "BuildFullRef", domainId, groupName, $li(ref,3))
}

/// <p>Utility method to retrieve the group ID corresponding to a partiular Group Name, for a given
/// domain and lister ID, or zero when the group name is not recognized.</p>
ClassMethod GetGroupId(domId As %Integer, listerId As %Integer, groupName As %String) As %Integer [ Final ]
{
    // now find the groupId based on the groupName
    Quit:groupName="" 0
    Quit:$length(groupName)'>$$$IKHASHSIZE +$g(^IRIS.IK.Ext.Group(domId, listerId, groupName))
    Set groupId="",hash=$ZCRC(groupName,7)
    For {
        Set groupId=$order(^IRIS.IK.Ext.GroupHash(domId,listerId,hash,groupId))
        Quit:groupId=""
        Quit:groupName=$g(^IRIS.IK.Ext.GroupId(domId,listerId,groupId))
    }
    Quit +groupId
}

/// <p>Utility method to retrieve the Group Name corresponding to a particular group ID, for a given
/// domain and lister ID. An error is passed through the sc output parameter if no group was
/// found for this ID.</p>
ClassMethod GetGroupName(domId As %Integer, listerId As %Integer, groupId As %Integer, Output sc As %Status = {$$$OK}) As %String [ Final ]
{
	quit:domId=0 ""
	
	set sc = $$$OK
	quit:'+groupId "" // fe the Temp Lister does not use groups
	if '$d(^IRIS.IK.Ext.GroupId(domId,listerId,groupId), groupName) {
    	set sc = $$$ERROR($$$IKGroupDoesNotExist, groupId)
		quit ""
   	}
   	quit groupName
}

/// <p>Utility method to store a (new) Group Name for this Lister, returning the corresponding ID.
/// If the Group Name already exists for this domain and lister ID, it returns the existing
/// groups ID.</p>
Method AddGroup(groupName As %String) As %Integer [ Final, Private ]
{
	quit ..AddGroupStatic(i%DomainId, i%ListerClassId, groupName)
}

/// <p>Static version of <method>AddGroup</method>.</p>
ClassMethod AddGroupStatic(domainId As %Integer, listerId As %Integer, groupName As %String) As %Integer [ Final, Internal ]
{
	// BDB464 - ignore groups for the system domain
	quit:'domainId 0
	
	$$$IKCHECKPRIVWRITE
	
    // now find the groupId based on the groupName
    If $length(groupName)'>$$$IKHASHSIZE {
        Goto:$d(^IRIS.IK.Ext.Group(domainId,listerId,groupName),groupId) fin
        // Lock so that we can support listers working simultaneously
        Lock +^IRIS.IK.Ext.Group(domainId,listerId)
        // Found it while locked
        Goto:$d(^IRIS.IK.Ext.Group(domainId,listerId,groupName),groupId) fnd
        // Not found, even locked, so go ahead and create new
        Set groupId=$i(^IRIS.IK.Ext.GroupId(domainId,listerId))
        Set ^IRIS.IK.Ext.Group(domainId,listerId,groupName)=groupId
    } Else {
        Set groupId="",hash=$ZCRC(groupName,7)
        For {
            Set groupId=$order(^IRIS.IK.Ext.GroupHash(domainId,listerId,hash,groupId))
            Quit:groupId=""
            Goto:groupName=$g(^IRIS.IK.Ext.GroupId(domainId,listerId,groupId)) fin
        }
        // Lock so that we can support listers working simultaneously
        Lock +^IRIS.IK.Ext.Group(domainId,listerId)
        For {
            Set groupId=$order(^IRIS.IK.Ext.GroupHash(domainId,listerId,hash,groupId))
            Quit:groupId=""
            Goto:groupName=$g(^IRIS.IK.Ext.GroupId(domainId,listerId,groupId)) fnd
        }
        // Not found, even locked, so go ahead and create new
        Set groupId=$i(^IRIS.IK.Ext.GroupId(domainId,listerId))
        Set ^IRIS.IK.Ext.GroupHash(domainId,listerId,hash,groupId)=""
    }
    Set ^IRIS.IK.Ext.GroupId(domainId,listerId,groupId)=groupName
fnd Lock -^IRIS.IK.Ext.Group(domainId,listerId)
fin Quit +groupId
}

/// <p>This method returns the simple alias for this Lister class, to be prefixed with a colon. 
/// If this method returns the empty string, the Lister Reference will start with the full Lister
/// class name rather than this alias (prefixed with a colon)</p>
ClassMethod GetAlias() As %String
{
    Quit ""
}

/// This utility method provides the prefix that is prepended to the Full Reference
ClassMethod GetExtidPrefix() As %String [ Final ]
{
    Set alias=..GetAlias()
    Quit $s(alias="":..%ClassName(1)_":",1:":"_alias_":")
}

Method MaxListId() As %Integer [ Final, Internal ]
{
    Quit +$get(@i%SrcList)
}

/// <p>Utility method to format the parameter string passed in AddList for display by
/// the %iKnow.Source.Loader.GetCurrentLists() method. Defaults to $lts() but should
/// be overridden to nicen up complex datatypes in the parameter list.</p>
ClassMethod FormatParams(listerParams As %List) As %String
{
       quit $lts(listerParams)
}

/// <p>Wrapper method to process a single List in one call. This method instantiates a
/// <class>%iKnow.Source.Loader</class> object, registers itself with it and then calls
/// the ProcessList methodon the Loader with the supplied parameters.</p>
/// <p>This method takes the <b>Lister Parameters</b> for this particular Lister implementation.</p>
Method ProcessList(listerParams...) As %Status [ Final ]
{
	// BDB464 - ensure we're not adding *real* sources to the system domain
	quit:'i%DomainId $$$ERROR($$$IKSysDomVirtualOnly)
	
	if i%Loader="" {
		set i%Loader = ##class(%iKnow.Source.Loader).%New(i%DomainId)
		quit:i%Loader="" $$$ERROR($$$IKCaughtError, $ze)
	
		set tSC = i%Loader.SetLister(##this)
		quit:$$$ISERR(tSC) tSC
	}
	
	quit i%Loader.ProcessList(listerParams...)
}

/// <p>Same as <method>ProcessList</method>, but sources will be added as Virtual Sources.</p>
Method ProcessVirtualList(listerParams...) As %Status [ Final ]
{
	set:i%Loader="" i%Loader = ##class(%iKnow.Source.Loader).%New(i%DomainId)
	quit:i%Loader="" $$$ERROR($$$IKCaughtError, $ze)
	
	set tSC = i%Loader.SetLister(##this)
	quit:$$$ISERR(tSC) tSC
	
	quit i%Loader.ProcessVirtualList(listerParams...)
}

/// <p>This method is called at the start of <method>ProcessList</method> and <method>AddListToBatch</method>
/// to validate the supplied Lister Parameters. Subclasses should override this method to execute
/// the validation logic specific to their Lister Parameters.</p>
Method TestParams(listerParams...) As %Status
{
	quit $$$OK
}

/// BDB304 - Reset the current ref, to be run after Loader.ProcessList()
Method ResetRef() As %Status [ Internal ]
{
	set i%CurrentRef="", i%ListId="", i%MetaId=""
	quit $$$OK
}

}
