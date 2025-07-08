/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %IKPublic)

/// <p><b>Deprecation note</b>: Direct use of this class is still supported, but it is recommended to use either
/// Domain Definitions (cf <class>%iKnow.DomainDefinition</class>) to manage a domain's contents
/// or use the shorthand methods in <class>%SYSTEM.iKnow</class> to work with an existing
/// domain not managed through a domain definition class.</p>
/// <p>This class coordinates the loading process.</p>
/// <p>For <b>Batch Loading</b>, use the <method>ProcessBatch</method>
/// after one or more <class>%iKnow.Source.Lister</class> instances have been used to register
/// one or more lists of sources to load into the domain using their
/// <method class="%iKnow.Source.Lister">AddListToBatch</method> methods.</p>
/// <p>For <b>Direct Loading</b>, register a <class>%iKnow.Source.Lister</class> instance with this
/// Loader instance and call <method>ProcessList</method> or <method>ProcessVirtualList</method>
/// to add a small number of sources to the domain directly (in the same process).</p>
/// <p>For <b>Direct Text Loading</b>, you can simply queue <class>%String</class> data using the
/// <method>BufferSource</method> and then add these directly (in the same process) to the domain
/// using either <method>ProcessBuffer</method> or <method>ProcessVirtualBuffer</method>.</p>
/// <p>With both Direct Loading options, the IDs of the sources added in the last execution are
/// available through <method>GetSourceIds</method>
Class %iKnow.Source.Loader Extends %RegisteredObject [ Deprecated, Final, System = 4 ]
{

Property DomainId As %Integer;

/// surrogate domain ID for use in IRIS.Temp
/// guaranteed to be unique across namespaces
Property TempId As %Integer [ Private ];

Property KeyId As %Integer [ Private ];

Property Lister As %iKnow.Source.Lister [ Private ];

Property ListerData As %List [ Internal, Private ];

Property Processor As %iKnow.Source.Processor [ Private ];

Property Indexer As %iKnow.Indexer [ Private ];

Property DirectInput As %iKnow.DirectInput [ Private ];

Property MetaData As %iKnow.Queries.MetadataI [ Private ];

Property ListGlo As %String [ Internal, Private ];

Property SrcInc As %String [ Internal, Private ];

Property SrcData As %String [ Internal, Private ];

Property LastErrBeforeLoad As %Integer [ InitialExpression = 0, Internal, Private ];

Property LastFailBeforeLoad As %Integer [ InitialExpression = 0, Internal, Private ];

Property LastWarnBeforeLoad As %Integer [ InitialExpression = 0, Internal, Private ];

Method %OnNew(domId As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
    $$$IKCHECKPRIVWRITE
    if (domId'=0) { // BDB464
	    $$$CHECKDOMAINEXISTS(domId)
    }
    Set i%DomainId=domId
    
    // BDB500 - fetch system-wide unique domain ID
    $$$IKTEMPDOMID(domId,tTempId)
    set i%TempId = tTempId
    
    Set pref="^IRIS.Temp.IK."_tTempId_"."
    Set i%ListGlo=pref_"List"
    Set i%SrcInc=pref_"SrcInc"
    Set i%SrcData=pref_"SrcData"
    Set i%MetaData=$classmethod($$$IKMETADATAAPI(domId), "%New")
    Quit $$$OK
}

/// <p>This call registers the supplied <class>%iKnow.Source.Lister</class> object to be used for Direct Loading by 
/// subsequent calls to <method>ProcessList</method>.</p>
/// <p>The supplied Lister object should be fully configured, but cannot have any lists already
/// scheduled for it (through calls to its AddListToBatch method).</p>
Method SetLister(lister As %iKnow.Source.Lister) As %Status
{
    set sc=$$$OK, domId=i%DomainId, oldLister=i%Lister
    try {
	    if lister="" {
		    set i%Lister="", i%DirectInput="", i%Indexer="", i%Processor="", i%KeyId=0, i%ListerData=""
		    quit
	    }
	    
        if lister.SrcList'="",lister.MaxListId()>0 { 
            set sc = $$$ERROR($$$IKLoaderIsNotClean)
            quit
        }
        
        // Initialize DI and Indexer
        set i%DirectInput=##class(%iKnow.DirectInputOne).%New(domId,1)
        if i%DirectInput="" { set sc=$$$ERROR($$$IKFailedInitDirectInput) quit }
        set i%Indexer=##class(%iKnow.Indexer).%New()
        if i%Indexer="" { set sc=$$$ERROR($$$IKFailedInitIndexer) quit }
        
        // update internal references
        set i%Lister=lister, i%Processor="", i%KeyId=0, i%ListerData=""
        
        // apply the Lister's configuration
        set cfg=lister.Configuration
        set objCfg=##class(%iKnow.Configuration).Open(cfg)
        if objCfg="" { set sc=$$$ERROR($$$IKConfigurationNotFound,cfg) quit }
        set sc=objCfg.ConfigureIndexer(i%Indexer)
        set objCfg=""
    
	    // BDB600 - load stemmer object for this domain
	    set sc = ##class(%iKnow.Stemmer).GetByDomain(i%DomainId,.tStemmer)
	    quit:$$$ISERR(sc)
	    set sc = i%Indexer.SetStemmer(tStemmer)
	    quit:$$$ISERR(sc)
        
    } catch (ex) {
        set sc = ex.AsStatus()
    }
    
    // log error and restore original lister
    If $$$ISERR(sc) {
        $$$IKERROR(domId,sc,..%ClassName(1)_":SetLister")
		Set i%Lister = oldLister
    }
    
    quit sc
}

/// <p>Same As <method>ProcessList</method>, but listed sources will be added as Virtual Sources.</p>
Method ProcessVirtualList(listargs...) As %Status
{
	// BDB572 - check if we should disable journalling and track if we need to restore it afterwards
	$$$IKDisableJournal(i%DomainId)
  	
#define PHASE ProcessVirtualList
    New %domainId Set %domainId=i%DomainId
    New $$$IKSTAGE
    $$$INITFLAGS
    do ..SetCurrentErrors()
    
    Set list=""
    For i=1:1:+$g(listargs) { Set list=list_$lb(listargs(i)) }
    
    Do i%Lister.SetBatchMode(0)
    Set srclist=i%Lister.SrcList
    Kill ^||%IK.SrcIds,@srclist

    Set srcdata=i%Lister.GetListerData()
    
    // BDB303 - check if ListerData is any different from previous invocations.
    // NOTE: $listsame() might return false negatives on the nested listbuilds for params in case
    // their string representations aren't identical, but re-instantiating the Processor
    // and Converter in those cases isn't too much of a cost
    If '$ls(srcdata,i%ListerData) || (i%Processor="") {
	    
        // BDB303 - switch off eventual DelimitedSentence mode
		Set prevProcessorId = $lg(i%ListerData,2)
		If prevProcessorId,^IRIS.IK.Sys.ProcessorD(prevProcessorId)="%iKnow.Source.Domain.Processor" {
		    Set sc = i%Indexer.DisableDelimitedSentences()
		    Goto:$$$ISERR(sc) err
		}
        Set params=$lg(srcdata,3),convId=+$lg(srcdata,4),convparams=$lg(srcdata,5)
        Set i%Processor=$classmethod(^IRIS.IK.Sys.ProcessorD($lg(srcdata,2)),"%New",%domainId,i%Indexer,i%DirectInput)
        If i%Processor="" { Set sc=$$$ERROR($$$IKUnableOpenProcessorId, $lg(srcdata,2)) Goto err }
        Set sc=i%Processor.SetParams($lg(srcdata,3))
        Goto:$$$ISERR(sc) err
        Set sc=i%Processor.SetConverter(convId,convparams)
        Goto:$$$ISERR(sc) err
        Do i%Processor.SetBatchMode(0)
        set i%ListerData = srcdata
    }
    Set:'$d(^IRIS.IKL.Timings(%domainId),bastim) bastim=$zh,^IRIS.IKL.Timings(%domainId)=bastim

    Set sc=i%Lister.ExpandList(list)
    Goto:$$$ISERR(sc) err

    Set $ZT="ERRORTRAP"

    $$$STARTTIMINGS(%domainId)
    
    Set maxval=i%Lister.MaxListId()
    
    Set statusmsg="Loading "_$s(maxval=1:"single source",1:maxval_" sources")
    $$$IKDISPSTART(statusmsg,%IKStatus,begtim,bastim)

    For i=1:1:maxval {
        Set srcinfo=@srclist@(i)
        
        // Reinitialize for single source
        Do i%DirectInput.Initialize()
        Set sc=i%Processor.ProcessVirtualListElement(i,$li(srcinfo))
        // Make sure this gets closed
        Do i%DirectInput.Finalize()
	
        If $$$ISOK(sc) {
	        $$$STARTTIMINGSNEST
	        $$$STARTTIMINGS(%domainId)
            Set SrcId=0
            Set offset=""
            LOCK +^IRIS.IKV.SrcIdAlloc:5
	    	If '$T { Set sc=$$$ERROR($$$GeneralError,"Failed to aquire lock for virtual source") Quit }
            // Find lowest virtual src
            For {
                Set prevOffset=offset
                Set offset=$o(^IRIS.IKV.SrcExistsBit(%domainId,offset),1,bitstring)
                // New bitstring
                If (offset="") {
                    Set offset=prevOffset+1,pos=(offset=1)+1
                    Quit
                }
                // Find empty spot
                // Skip first bit at first offset
                Set pos=$bitfind(bitstring,0,(offset=1)+1)
				Quit:pos		// Found free place
				Set count=$bitcount(bitstring)
				If count<64000 {       // Append to end of bitstring
				    Set pos=count+1
				    Quit
				}
            }
	    	Set $bit(^IRIS.IKV.SrcExistsBit(%domainId,offset),pos)=1
            LOCK -^IRIS.IKV.SrcIdAlloc
	    	$$$IKGETIDOFFPOS(SrcId,offset,pos)
            $$$ENDTIMINGSP(%domainId,"Loader:AssignVSrcId")
            $$$STARTTIMINGSUNNEST
            
            $$$STARTTIMINGSNEST
            Set sc=$$Virtual^%iKnow.BuildVirtualGlobals(%domainId,SrcId)
            $$$ENDTIMINGSP(%domainId,"Loader:BuildVirtualGlobals")
            $$$STARTTIMINGSUNNEST
            
            Set dateCreated = $h
            If $$$ISERR(sc) {
	        	Do ..DeleteVirtualSource(%domainId,SrcId)
            } Else {
	        	Set ^IRIS.IKV.SrcId(%domainId,SrcId)=$lb(dateCreated,"",i%DirectInput.Source,0,0,0)
				Set ^IRIS.IKV.SrcCreated(%domainId,$p(dateCreated,","),$p(dateCreated,",",2),SrcId)=""
                Set ^||%IK.SrcIds(SrcId)=""
            }
        }
        If %IKStatus {
            Set per=i/maxval*100 Set:per>100 per=100 Set per=$j(per,7,0)_"% "
            if $g(%IKVerbose)<0 {
	            $$$IKDISPBGR($$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals(i)_per)
            } else {
                Write $c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals(i),per,$c(13)
            }
        }
    }
    
    Set $ZT=""
    $$$ENDTIMINGSP(%domainId,"Loader:ProcessVirtualList")
    Do ..Reset()
    Do ..CheckErrors(.sc)
	$$$IKRestoreJournal  // BDB572
    Quit sc
    
ERRORTRAP
    Set $ZT=""
    Set sc=$$$ERROR($$$IKCaughtError,"ProcessVirtualList",$ZE)
    Do ..Reset()
    
err $$$IKERROR(%domainId,sc,..%ClassName(1)_":ProcessVirtualList")
    Do ..CheckErrors(.sc)
	$$$IKRestoreJournal // BDB572
    Quit sc
}

/// <p>This method initiates a Direct Load, indexing the sources identified by the Lister registered
/// with <method>SetLister</method>. The <b>Lister Parameters</b> passed as listargs to this method
/// should correspond in type and number to what the currently registered Lister expects as its 
/// (implementation-specific) Lister Parameters.</p>
/// <p>All operations will execute within the current process and therefore has superior performance
/// over Batch Loading when used for small numbers of sources.</p>
/// <p>After this method has finished, the generated source IDs can be retrieved through
/// <method>GetSourceIds</method>.</p>
Method ProcessList(listargs...) As %Status
{
	// BDB464 - ensure we're not adding *real* sources to the system domain
	quit:'i%DomainId $$$ERROR($$$IKSysDomVirtualOnly)
	
#define PHASE ProcessList
    Quit:'$isobject(i%Lister) $$$ERROR($$$IKNoListerRegistered)
    Set sc=i%Lister.TestParams(listargs...)
    Quit:$$$ISERR(sc) sc
    New %IKInitLoc
    New %domainId Set %domainId=i%DomainId
    $$$IKCHECKDOMMGR(%domainId)
 	
    If $$$GETPARAMNODEF(%domainId,$$$IKPDEEPSEEDOMAIN),i%Lister.%ClassName(1)'="%iKnow.DeepSee.Lister" {
        Quit $$$ERROR($$$IKCannotLoadInDSDomain)
    }

	// BDB572 - check if we should disable journalling and track if we need to restore it afterwards
	$$$IKDisableJournal(%domainId)
			
    New $$$IKSTAGE
    $$$INITFLAGS
    do ..SetCurrentErrors()
    
    Set list=""
    For i=1:1:+$g(listargs) { Set list=list_$lb(listargs(i)) }
    
    Do i%Lister.SetBatchMode(0)
    Set srclist=i%Lister.SrcList,srctempmeta=i%Lister.SrcTempMeta,srcmeta=i%Lister.SrcMeta
    Kill ^||%IK.SrcIds,@srclist,@srctempmeta,@srcmeta,^||%ik.MetaIds

    // First, set up indices for default keys
    Set defkeys=##class(%iKnow.Source.Processor).GetSystemMetadataKeys()
    Set defids=$$GetFieldIds^%iKnow.BuildGlobals(defkeys,i%MetaData)
 
    Set srcdata=i%Lister.GetListerData()
    
    // BDB303 - check if ListerData is any different from previous invocations.
    // NOTE: $listsame() might return false negatives on the nested listbuilds for params in case
    // their string representations aren't identical, but re-instantiating the Processor
    // and Converter in those cases isn't too much of a cost
    If '$ls(srcdata,i%ListerData) || (i%Processor="") {
        // BDB303 - switch off eventual DelimitedSentence mode
		Set prevProcessorId = $lg(i%ListerData,2)
		If prevProcessorId,^IRIS.IK.Sys.ProcessorD(prevProcessorId)="%iKnow.Source.Domain.Processor" {
		    Set sc = i%Indexer.DisableDelimitedSentences()
		    Goto:$$$ISERR(sc) err
		}
	    
        Set params=$lg(srcdata,3),convId=+$lg(srcdata,4),convparams=$lg(srcdata,5)
        Set i%Processor=$classmethod(^IRIS.IK.Sys.ProcessorD($lg(srcdata,2)),"%New",%domainId,i%Indexer,i%DirectInput)
        If i%Processor="" { Set sc=$$$ERROR($$$IKUnableOpenProcessorId, $lg(srcdata,2)) Goto err }
        Set sc=i%Processor.SetParams($lg(srcdata,3))
        Goto:$$$ISERR(sc) err
        Set sc=i%Processor.SetConverter(convId,convparams)
        Goto:$$$ISERR(sc) err
        Do i%Processor.SetBatchMode(0)
        set i%ListerData = srcdata
        
        // save the metadata keys as fetched by the processor and converter
        Set keys = i%Processor.GetMetadataKeys(params)
        Set:convId convClass=^IRIS.IK.Sys.ConverterD(convId),keys=keys_$classmethod(convClass,"GetMetadataKeys")
		If keys="" {
		    Set i%KeyId=0
		} Else {
		    Set i%KeyId=$i(@srcmeta),
		        @srcmeta@(i%KeyId)=keys,
				^||%ik.MetaIds(i%KeyId)=$$GetFieldIds^%iKnow.BuildGlobals(keys,i%MetaData)
		}
    }
    Set:'$d(^IRIS.IKL.Timings(%domainId),bastim) bastim=$zh,^IRIS.IKL.Timings(%domainId)=bastim
	
	// BDB375 - ensure fixed metadata keys/values are picked up
    Set sc = i%Lister.RegisterMetadataKeysInternal("",1)
    Goto:$$$ISERR(sc) err
	
    Set sc=i%Lister.ExpandList(list)
    Goto:$$$ISERR(sc) err

    Set $ZT="ERRORTRAP"

    LOCK +^IRIS.IKM.LOAD(%domainId)#"S":2
    If '$TEST {
        Set sc=$$$ERROR($$$IKFailedLockDomain,%domainId)
        Goto fin
    }

    $$$STARTTIMINGS(%domainId)
    
    Set maxval=+$g(@srclist)
    
    Set isDSDomain = +$$$GETPARAMNODEF(%domainId,$$$IKPDEEPSEEDOMAIN), maxSrcId=0
    Set statusmsg="Loading "_$s(maxval=1:"single source",1:maxval_" sources")
    $$$IKDISPSTART(statusmsg,%IKStatus,begtim,bastim)
    Set sumTime=0

    Set prevListerKeyId=0, combinedKeyId=0
    For i=1:1:maxval {
		Set begProcTime=$zh
        Set srcinfo=@srclist@(i)
        Set keyid=$lg(srcinfo,3)
        If 'keyid {
            // If no keyid was set in the listing phase, then we can just pick up the keys
            // based on the Processor and Converter parameters and store them as a new key
            // list
            Set keyid=i%KeyId
        } Else {
            // If there is a lister-based keyid, check whether it's the same as the previous one
            If keyid'=prevListerKeyId {	// If so, reuse combinedKeyId
                // Create a new key, combining Lister and Processor/Converter metadata
				Set prevListerKeyId=keyid
				If i%KeyId {
				    Set keys=@srcmeta@(keyid)_@srcmeta@(i%KeyId),
				        keyid=$i(@srcmeta),
						@srcmeta@(keyid)=keys
				} Else {
				    Set keys=@srcmeta@(keyid)
				}
				Set ^||%ik.MetaIds(keyid)=$$GetFieldIds^%iKnow.BuildGlobals(keys,i%MetaData)
            }
        }

        // We are handling each source in a separate transaction
		Set %IKInitLoc=$lb(^IRIS.IK.SrcId(%domainId),^IRIS.IK.SentId(%domainId),^IRIS.IK.EntUniId(%domainId),^IRIS.IK.CrcUniId(%domainId),^IRIS.IK.EntOccId(%domainId),^IRIS.IK.CrcOccId(%domainId),^IRIS.IK.PathId(%domainId),^IRIS.IK.StemUniId(%domainId))
        // Reinitialize for single source
        Do i%DirectInput.Initialize()
        Set sc=i%Processor.ProcessListElement(i,$li(srcinfo),keyid,$g(@srctempmeta@(i)),.skipped)
        // Make sure this gets closed
        Do i%DirectInput.Finalize()
        // Don't try to generate globals if error during loading
        Continue:$$$ISERR(sc)
        Continue:skipped

        If ('isDSDomain) {
	    	Set SrcId=$i(^IRIS.IK.SrcId(%domainId))
        } Else {
		    // In a DS Domain, srcID = extID
		    Set SrcId=+$li(i%DirectInput.Source,3)
		    Set:maxSrcId<SrcId maxSrcId = SrcId
        }
        Set ^IRIS.IK.SrcId(%domainId,SrcId)=i%DirectInput.Source
		Set sumTime=sumTime+($zh-begProcTime)
        Set sc=$$Single^%iKnow.BuildSingle(%domainId,SrcId,i%MetaData,defids)
        If '$$$ISERR(sc) {
            Set ^||%IK.SrcIds(SrcId)=""
            Set:isDSDomain ^IRIS.IK.SrcId(%domainId) = maxSrcId
        }
        If %IKStatus {
            Set per=i/maxval*100 Set:per>100 per=100 Set per=$j(per,7,0)_"% "
            if $g(%IKVerbose)<0 {
	            $$$IKDISPBGRI(-2,$$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals(i)_per)
            } else {
	            Write $c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals(i),per,$c(13)
            }
        }
    }
    Kill ^||%ik.MetaIds
    Set $ZT=""
    // update the lastSourceUpdate field for this domain
    $$$IKDOMAINCHANGED(%domainId)

	if %IKStatus {
		if $g(%IKVerbose)<0 {
		    $$$IKDISPBGRI(-2,$$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals($g(^IRIS.IK.SrcId(%domainId)))_"Finished "_statusmsg)
		} else {
		    Write $c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals($g(^IRIS.IK.SrcId(%domainId))),"Finished ",statusmsg
		}
	}
    If '$$$ISDATAAPPEND(%domainId) { $$$MARKDATALOADED(%domainId) }
    
    // BDB304: reset the current ref on the Lister
    do ..Lister.ResetRef()
    
    Do ..Reset()
    LOCK -^IRIS.IKM.LOAD(%domainId)#"SI"
    $$$ENDTIMINGS(%domainId)
    Set:%IKTimings sumTime=$i(^IRIS.IKL.Timings(%domainId,"Process"),sumTime)

    Do ..CheckErrors(.sc)
	$$$IKRestoreJournal  // BDB572
    Quit sc
    
ERRORTRAP
    Set $ZT=""
    Set sc=$$$ERROR($$$IKCaughtError,"ProcessList",$ZE)
    Do ..Reset()
err LOCK -^IRIS.IKM.LOAD(%domainId)#"SI"
fin $$$IKERROR(%domainId,sc,..%ClassName(1)_":ProcessList")
    do ..CheckErrors(.sc)
	$$$IKRestoreJournal  // BDB572
    Quit sc
}

/// <p>This method deletes a single source from the domain, including all its entity and CRC occurrences,
/// sentences and paths. Unique entities and CRCs occurring in this source will have their frequency
/// and spread updated.</p>
/// <p>If there's any metadata or matching results associated with this source, 
/// it will also be deleted.</p>
ClassMethod DeleteSource(domId As %Integer, internalId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	
	// BDB464 - redirect to DeleteVirtualSource for the system domain
	if (domId=0) {
		quit ..DeleteVirtualSource(0, $zabs(internalId))
	}
	
	$$$CHECKDOMAINEXISTS(domId)
	quit:(internalId<0) ..DeleteVirtualSource(domId, $zabs(internalId))
	$$$IKCHECKDOMMGR(domId)
	
	// BDB572
	$$$IKDisableJournal(domId)
	
	set tlevel = $TLevel
	
    LOCK +^IRIS.IKM.LOAD(domId):2

    If '$TEST {
        Set sc=$$$ERROR($$$IKFailedLockDomain,domId)
        $$$IKERROR(domId,sc,..%ClassName(1)_":DeleteSource")
        Quit sc
    }
    Set $ZT="ERRORTRAP"

    $$$IKBITOFFPOS(internalId,idOff,idPos)
    If ($bit(^IRIS.IK.SrcExistsBit(domId,idOff),idPos)=1) {
        TStart:'tDisableJournal
        Set sc=$$Delete^%iKnow.DeleteSource(domId,internalId)
    } Else {
        Set sc=$$$ERROR($$$IKSourceDoesNotExist,internalId)
    }
    Goto:$$$ISERR(sc) err
 
    // update the lastSourceUpdate field for this domain
    $$$IKDOMAINCHANGED(domId)

    Set $ZT=""
    TCommit:$TLEVEL&&'tDisableJournal  // Check if transaction is opened and commit it if so
    LOCK -^IRIS.IKM.LOAD(domId)
    $$$IKRestoreJournal // BDB572
    Quit $$$OK
    
ERRORTRAP
    BREAK:$$$ENABLEDEBUG(domId)
    Set sc=$$$ERROR($$$IKCaughtError,"DeleteSource",$ZE)
    Goto err
    
err Set $ZT=""
    if ($TLevel > tlevel) && 'tDisableJournal { TROLLBACK 1 }
    $$$IKERROR(domId,sc,..%ClassName(1)_":DeleteSource")
    LOCK -^IRIS.IKM.LOAD(domId)
    $$$IKRestoreJournal // BDB572
    Quit sc
}

/// <p>This method deletes a single Virtual Source from the domain, including all its entity and
/// CRC occurrences, sentences and paths.</p>
ClassMethod DeleteVirtualSource(domId As %Integer, vSrcId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	
	if (domId'=0) { // BDB464
		$$$CHECKDOMAINEXISTS(domId)
	}
	
	// BDB572
	$$$IKDisableJournal(domId)
	
	set tSC = $$$OK
	try {
	    // DP-405780 - use static list to get all iKnow-related globals
	    do ##class(%iKnow.Domain).GetIKnowGlobals(.lst)
	    
	    Set b="^IRIS.IKV.", glob=b, vSrcId = $zabs(vSrcId)
	    Set dc=$lg($g(^IRIS.IKV.SrcId(domId,vSrcId)))
	    Kill:dc'="" ^IRIS.IKV.SrcCreated(domId,$p(dc,","),$p(dc,",",2),vSrcId)
	    // Don't kill exceptions, where second subscript is not srcId
	    For n="SrcExistsBit","SrcCreated" { Kill lst(b_n) }
	    For {
	        Set glob=$o(lst(glob))
	        Quit:$e(glob,1,$l(b))'=b
	        Kill @glob@(domId,vSrcId)
	    }
	    LOCK +^IRIS.IKV.SrcIdAlloc:5
	    If $T {
		    $$$IKBITOFFPOS(vSrcId,offset,pos)
	        Set $bit(^IRIS.IKV.SrcExistsBit(domId,offset),pos)=0
			LOCK -^IRIS.IKV.SrcIdAlloc
	    }
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
    $$$IKRestoreJournal // BDB572
    Quit tSC
}

/// <p>Deletes all Virtual Sources associated with this domain.</p>
ClassMethod DeleteAllVirtualSources(domId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	
	if (domId'=0) { // BDB464
		$$$CHECKDOMAINEXISTS(domId)
	}
	
    // DP-405780 - use static list to get all iKnow-related globals
    do ##class(%iKnow.Domain).GetIKnowGlobals(.lst)
    Set b="^IRIS.IKV.", glob=b
    For {
        Set glob=$o(lst(glob))
        Quit:$e(glob,1,$l(b))'=b
        Kill @glob@(domId)
    }
    Quit $$$OK
}

/// <p>This method resets the internal globals used during the load process.</p>
Method Reset() As %Status
{
    Kill @i%ListGlo
    Kill @i%SrcInc
    Kill @i%SrcData
    do ..ClearBuffer()
    Set pref="^IRIS.Temp.IK."_i%TempId_"."
    Kill @(pref_"List"),@(pref_"SrcData")
    For n="SrcList","SrcMeta","SrcTemp","SrcTempMeta" {
        Kill @(pref_n),@("^||%ik."_n)
    }
    Set i%KeyId = ""
    Quit $$$OK
}

/// <p>Lines up the data supplied to this method to be indexed as a new source with the provided reference
/// in a subsequent call to	<method>ProcessBuffer</method> or <method>ProcessVirtualBuffer</method>.</p>
/// <p>Multiple calls to this method using the same ref before calling the Process* method, will
/// result in the data being appended to what was previously buffered for that ref. All buffering and
/// processing operations should happen within the same process.</p> 
Method BufferSource(ref As %String, data As %String) As %Status
{
    Set ^||%ik.Buffer(ref,$i(^||%ik.Buffer(ref)))=data
    Quit $$$OK
}

/// <p>Same As <method>ProcessBuffer<method>, but buffered sources will be added as Virtual Sources.</p>
Method ProcessVirtualBuffer(cfg As %String = "") As %Status
{
    quit ..ProcessBufferInternal(cfg, 1)
}

/// <p>Indexes all data buffered within this process through previous calls to 
/// <method>BufferSource</method> using the Direct Loading approach. This includes calling
/// <method>SetLister</method> with a <class>%iKnow.Source.Temp.Lister</class> instance and
/// initiating the Direct Load through <method>ProcessList</method>. The buffer is cleaned
/// automatically at the end of successfully processing the data.</p>
/// <p>After this method has finished, the generated source IDs can be retrieved through
/// <method>GetSourceIds</method>.</p>
Method ProcessBuffer(cfg As %String = "") As %Status
{
	// BDB464 - ensure we're not adding *real* sources to the system domain
	quit:'i%DomainId $$$ERROR($$$IKSysDomVirtualOnly)
	
	quit ..ProcessBufferInternal(cfg, 0)
}

Method ProcessBufferInternal(pConfig As %String = "", pVirtual As %Boolean = 0) As %Status [ Internal ]
{
    Set sc=$$$OK, oldLister=i%Lister
    try {
	    set:(pConfig="") pConfig = $$$GETPARAM(..DomainId,$$$IKPDEFAULTCONFIG,$$$DEFAULTCONFIG)
    
	    // If current lister is not set up for Temp.Lister, save it and set up Temp.Lister
	    If (i%Lister="") || (i%Lister.%ClassName(1)'="%iKnow.Source.Temp.Lister") || (i%Lister.Configuration'=pConfig) {
	        Set lister=##class(%iKnow.Source.Temp.Lister).%New(i%DomainId)
	        Set sc = lister.SetConfig(pConfig)
	        quit:$$$ISERR(sc)
	        Set sc=..SetLister(lister)
	        quit:$$$ISERR(sc)
	    }
	    if (pVirtual) {
		    set sc = ..ProcessVirtualList()
	    } else {
		    set sc = ..ProcessList()
	    }
	    quit:$$$ISERR(sc)
	    
	    do ..ClearBuffer()
    } catch (ex) {
	    set sc = ex.AsStatus()
    }
    do ..SetLister(oldLister)
    quit sc
}

/// <p>This method clears any data supplied so far through calls to <method>BufferSource</method></p>
Method ClearBuffer() As %Status
{
	kill ^||%ik.Buffer
	quit $$$OK
}

/// <p>This method returns all the data currently in the buffer, as entered through calls to
/// <method>BufferSource</method>, since the last call to <method>ProcessBuffer</method> or
/// <method>ClearBuffer</method>. Data is returned in a two-level array structure:
/// <blockquote>pBuffer(<i>reference</i>) = <i>numberOfEntries</i><br/>
/// pBuffer(<i>reference</i>, <i>n</i>) = <i>data</i></blockquote></p>
Method GetBuffer(Output pBuffer) As %Status
{
	kill pBuffer
	merge pBuffer = ^||%ik.Buffer
	quit $$$OK
}

/// args(1) = number of sources.
/// args(2) = the status global to log the process for LoadSources.
/// args(3) = the time to queue work into the queue.
ClassMethod LogProcess(domainId As %Integer, procId As %Integer, args As %List) As %Status
{
	If %IKStatus {
		set maxval = $li(args,1)
		set statusGlo = $li(args,2)
		set begtim = $li(args,3)
  
        set val=+$g(@statusGlo)
        If maxval { Set per=val/maxval*100 Set:per>100 per=100 Set msg=$j(per,7,0)_"% " }
        Else { Set msg=" Running " }
        if $g(%IKVerbose)<0 {
	        $$$IKDISPBGRI(-2,$$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals(val)_msg)
        } else {
	        Write $c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals(val),msg,$c(13)
        }
     }
     quit $$$OK
}

/// <p>This is the primary method for starting a Batch Load. When executed, this method will first
/// go through the lists registered through AddListToBatch() calls on <class>%iKnow.Source.Lister</class>
/// objects and call their ExpandList() method to get a complete list of all the sources to index.
/// Then, it will instantiate the appropriate <class>%iKnow.Source.Processor</class> objects to
/// read their contents and forward it to the iKnow engine (optionally through a <class>%iKnow.Source.Converter</class>
/// instance). Finally, it will invoke the ^%iKnow.BuildGlobals routine to transform the output
/// of the iKnow engine into the persistent domain data structures.</p>
Method ProcessBatch() As %Status
{
	// BDB464 - ensure we're not adding *real* sources to the system domain
	quit:'i%DomainId $$$ERROR($$$IKSysDomVirtualOnly)
    
	// BDB572 - check if we should disable journalling and track if we need to restore it afterwards
	$$$IKDisableJournal(i%DomainId)
	
#define PHASE ProcessBatch
    New %domainId, %tempId
    Set %domainId=i%DomainId, %tempId=i%TempId
    $$$INITFLAGS
    do ..SetCurrentErrors()

    Set bastim=$zh,^IRIS.IKL.Timings(%domainId)=bastim
    Set sc=..ProcessLists()
    goto:$$$ISERR(sc) err
    
    LOCK +^IRIS.IKM.LOAD(%domainId):2
    If '$TEST {
        Set sc=$$$ERROR($$$IKFailedLockDomain,%domainId)
        goto err
    }
    Set $ZT="ERRORTRAP"

    // Reset loading position
    Kill @i%SrcInc
    
    Goto:$g(^IRIS.IKT.Skip(%domainId)) staging

    $$$STARTTIMING(%domainId,0)
    
    // BDB635
    set ^IRIS.IKT.InitLoc(%domainId,"srcMin") = $g(^IRIS.IK.SrcId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"sentMin") = $g(^IRIS.IK.SentId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"entMin") = $g(^IRIS.IK.EntUniId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"crcMin") = $g(^IRIS.IK.CrcUniId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"ccMin") = $g(^IRIS.IK.CcUniId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"eoMin") = $g(^IRIS.IK.EntOccId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"crcoMin") = $g(^IRIS.IK.CrcOccId(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"pathMin") = $g(^IRIS.IK.PathToEntOcc(%domainId)),
    	^IRIS.IKT.InitLoc(%domainId,"stemMin") = $g(^IRIS.IK.StemUniId(%domainId))
    
    Set maxval=+$g(@("^IRIS.Temp.IK."_i%TempId_".SrcList"))

    If 'maxval {
        Set sc=$s($$$GETPARAMNODEF(%domainId,$$$IKPIGNOREEMPTYBATCH):$$$OK, 1:$$$ERROR($$$IKNothingToProcess))
        if (%IKStatus) {
        	if $g(%IKVerbose)<0 {
	        	$$$IKDISPBGR("Nothing to process")
        	} else { Write !,"Nothing to Process" }
        }
        Set $ZT=""
        Do ..ClearTemps()
        LOCK -^IRIS.IKM.LOAD(%domainId)
        $$$IKRestoreJournal  // BDB572 // BDB781
        Quit sc
    } Else {
        $$$SETMAXJOBS(maxProcs,%domainId,"Load",$System.CPU.%New().nThreads,maxjobs)

		Set queue=$system.WorkMgr.Initialize("",.sc) If $$$ISERR(sc) quit sc
		
		Set maxval=+$g(@("^IRIS.Temp.IK."_i%TempId_".SrcList"))
		
        Set statusmsg="Loading"_" ("_maxProcs_" jobs)"
        $$$IKDISPSTART(statusmsg,%IKStatus,begtim,bastim)

		if %IKDebug {
	        do ..Execute(maxProcs)
        } 
        else{
			set tActualJobs = 0
        	For p=1:1:maxProcs{
            
            	//set sc=queue.Queue( "##class(%iKnow.Source.Loader).BackExecute",%domainId,p)
      
            	set sc=queue.QueueCallback( "##class(%iKnow.Source.Loader).BackExecute","##class(%iKnow.Source.Loader).LogProcess",%domainId,p,$lb(maxval,i%SrcInc,begtim))
            	If $$$ISERR(sc) goto err
            	set ^IRIS.Temp.IK.Processes(%tempId,p)=$lb($$$IKPROCRUNNING,$ZCHILD)
    	    	set tActualJobs = tActualJobs+1    
        	}
        }
           
        set sc=queue.Sync() If $$$ISERR(sc) goto err
        
        if %IKStatus {
	        if $g(%IKVerbose)<0 {
		        $$$IKDISPBGRI(-2,$$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals($g(^IRIS.IK.SrcId(%domainId)))_"Finished "_statusmsg)
	        } else {
		        Write $c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals($g(^IRIS.IK.SrcId(%domainId))),"Finished ",statusmsg
	        }
        }

        $$$ENDTIMING(%domainId,0)
    
staging ; skip loading globals for testing purposes
        Set sc=..ProcessStagingGlobals()
        goto:$$$ISERR(sc) err
    }
    
    // update the lastSourceUpdate field for this domain
    $$$IKDOMAINCHANGED(%domainId)
    
    $$$MARKDATALOADED(%domainId)
    Set $ZT=""
    Do ..ClearTemps()
    LOCK -^IRIS.IKM.LOAD(%domainId)

	do ..CheckErrors(.sc)
	$$$IKRestoreJournal  // BDB572
    Quit sc
    
PROCFAIL 
    Set $ZT=""
    Set sc=$$$ERROR($$$IKIndexerProcFailed)
    Goto err
    
ERRORTRAP
    Set $ZT=""
    Set sc=$$$ERROR($$$IKCaughtError,"ProcessBatch",$ZE)
err 
    Set $ZT=""
    Do ..ClearTemps()
    LOCK -^IRIS.IKM.LOAD(%domainId)
    $$$IKERROR(%domainId,sc,..%ClassName(1)_":ProcessBatch")
	do ..CheckErrors(.sc)
	$$$IKRestoreJournal // BDB572
    do:$isobject($g(queue)) queue.Clear()
    Quit sc
}

/// <p>This method returns the Source IDs of the sources created in the last call to
/// <method>ProcessList</method>, <method>ProcessBuffer</method>, <method>ProcessVirtualList</method>
/// or <method>ProcessVirtualBuffer</method>.</p>
Method GetSourceIds() As %List
{
    Set SrcId=""
    Set list=""
    For {
        Set SrcId=$o(^||%IK.SrcIds(SrcId))
        Quit:SrcId=""
        Set list=list_$lb(+SrcId)
    }
    Quit list
}

/// Clears the logs, as directed by the boolean parameters.
Method ClearLogs(clearErrors As %Boolean = 1, clearFailed As %Boolean = 1, clearWarnings As %Boolean = 1) As %Status
{
	kill:clearErrors ^IRIS.IKL.ErrorLog(i%DomainId)
	kill:clearErrors ^IRIS.IKL.Errors(i%DomainId) // secondary global for DirectInput-logged errors
	kill:clearFailed ^IRIS.IKL.Failed(i%DomainId)
	kill:clearWarnings ^IRIS.IKL.Warning(i%DomainId)
	quit $$$OK
}

Method ProcessLists() As %Status [ Internal, Private ]
{
	$$$IKCHECKDOMMGR(i%DomainId)
	
    Set curlst=0,sc=$$$OK,begtim=$zh, isDSDomain=$$$GETPARAMNODEF(%domainId,$$$IKPDEEPSEEDOMAIN)
    Quit:'$d(@i%ListGlo,maxLists) $s($$$GETPARAMNODEF(%domainId,$$$IKPIGNOREEMPTYBATCH):$$$OK, 1:$$$ERROR($$$IKNothingToProcess))
    For i=1:1:maxLists {
	    if %IKStatus {
		    if $g(%IKVerbose)<0 {
	    		$$$IKDISPBGRI(-2,$$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals(i)_$j((100*(i-1)/maxLists),7,0)_"% "_"Expanding lists")
		    } else {
	    		write !,$c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals(i),$j((100*(i-1)/maxLists),7,0)_"% ","Expanding lists",$c(13)
		    }
	    }
        Set lst=@i%ListGlo@(i)
        Set lstid=$li(lst),dataid=$li(lst,2),params=$li(lst,3)
        If lstid'=curlst {
            Set lister=$classmethod(^IRIS.IK.Sys.ListerD(lstid),"%New",i%DomainId),curlst=lstid
            If lister="" { Set sc=$$$ERROR($$$IKUnableOpenListerId,lstid) Quit }
            if isDSDomain && (lister.%ClassName(1)'="%iKnow.DeepSee.Lister") { set sc=$$$ERROR($$$IKCannotLoadInDSDomain)  quit }
            Do lister.SetBatchMode(1)
        }
        Do lister.SetDataId($li(lst,2))
        Set sc=lister.ExpandList($li(lst,3))
        Quit:$$$ISERR(sc)
    }
    if %IKStatus {
	    if $g(%IKVerbose)<0 {
			$$$IKDISPBGRI(-2,$$ShowTime^%iKnow.BuildGlobals($zh-begtim)_$$ShowCount^%iKnow.BuildGlobals(maxLists)_"Finished expanding lists")
	    } else {
			write $c(13,9),$$ShowTime^%iKnow.BuildGlobals($zh-begtim),$$ShowCount^%iKnow.BuildGlobals(maxLists),"Finished expanding lists",$c(13)
	    }
    }
fin Quit:$$$ISOK(sc) $$$OK
    $$$IKERROR(i%DomainId,sc,..%ClassName(1)_":ProcessLists")
    Quit sc
}

Method ProcessStagingGlobals() As %Status [ Internal, Private ]
{
#define PHASE ProcessStagingGlobals
    Set domId=i%DomainId, tTempId=i%TempId
    
    $$$STARTTIMING(domId,0)
    
    Kill ^IRIS.Temp.IK.ProcessStatus(tTempId)
    
    Set listToProcess=""
    
    Set p=""
    For {
        Set p=$o(^IRIS.Temp.IK.Processes(tTempId,p))
        Quit:p=""
        
        Set listToProcess=listToProcess_$lb(p)
    }
    
    If (listToProcess="") {
        Quit:$$$GETPARAMNODEF(%domainId,$$$IKPIGNOREEMPTYBATCH) $$$OK
        Set sc=$$$ERROR($$$IKNothingToProcess)
        $$$IKERROR(domId,sc,..%ClassName(1)_":ProcessStagingGlobals")
        Quit sc
    }

    Set ^IRIS.IKT.ProcessList(domId)=listToProcess
    // Set up last source to batch process
    set ^IRIS.IKT.InitLoc(domId,"srcMax")=+$g(^IRIS.IK.SrcId(domId))

    If ('$$$ISDATAAPPEND(domId)) {
        // INITIAL LOAD
        Set sc=$$FromBatch^%iKnow.BuildGlobals(domId)
    } Else {
        // DATA APPEND
        TStart
        Set sc=$$FromUpdate^%iKnow.BuildGlobals(domId)
        If ('sc) {
            Do Rewind^%iKnow.BuildGlobals(domId)
        } Else {
            TCommit
        }
    }
    
    $$$ENDTIMING(domId,0)
    
    Quit sc
}

Method ClearTemps(OverrideSaveTemp As %Boolean = 0) As %Status [ Internal ]
{
    do ..Reset()
    quit ..ClearTempsStatic(i%DomainId, OverrideSaveTemp)
}

ClassMethod ClearTempsStatic(domId, OverrideSaveTemp As %Boolean = 0) As %Status [ Internal ]
{
    If 'OverrideSaveTemp,$$$SAVETEMPDATA(domId) { Quit $$$OK }

    Set glo=""
    For {
        Set glo=$o(^IRIS.IKT.Globals(domId,glo))
	Quit:glo=""
	Kill @glo
    }
    Kill ^IRIS.IKT.Globals(domId)
    Set glo=""
    For {
        Set glo=$o(^IRIS.IKS.Globals(domId,glo))
	Quit:glo=""
	Kill @glo
    }
    Kill ^IRIS.IKS.Globals(domId)
    
    // BDB500 - fetch system-wide unique domain ID
    $$$IKTEMPDOMID(domId,tTempId)
    Kill ^IRIS.Temp.IK.Processes(tTempId)
    Kill ^IRIS.Temp.IK.Mat.SrcProc(tTempId)
    Kill ^IRIS.Temp.IK.Mat.EntUniProc(tTempId)
    
    quit $$$OK
}

ClassMethod BackExecute(domId As %Integer, processNr As %Integer, args As %List = "") As %Status [ Internal ]
{
    Set loader=..%New(domId)
    Quit:loader="" $$$ERROR($$$IKCannotCreateLoader)
	 
	// BDB572 - check if we need to disable journalling
	// There's no need to register the current journalling behavior as this method is 
	// only called asynchroneously and the process ends afterwards.
	$$$IKDisableJournal(domId)	    

  	quit loader.Execute(processNr, 1)
}

Method Execute(processNr As %Integer, async As %Boolean = 0) As %Status [ Internal, Private ]
{
    Set sc=$$$OK, $ztrap="err"
    Set domId=i%DomainId, tTempId = i%TempId
    Try {
        Set objDI=##class(%iKnow.DirectInputDO).%New(domId,processNr)
        If objDI="" { Set sc=$$$ERROR($$$IKFailedInitDirectInput) Goto err }
        
        Set objIDX=##class(%iKnow.Indexer).%New()
        If objIDX="" { Set sc=$$$ERROR($$$IKFailedInitIndexer) Goto err }
        
        Set sc=..LoadSources(objIDX,objDI)
    } Catch {
        Set sc=$$$ERROR($$$IKCaughtError,"Execute",$ZE)
        Goto err
    }

    // Make sure these get closed before we mark this as done
    Do objDI.Finalize()
    Kill objDI
    Kill objIDX
    
    // Mark as done, but ensure the process status marker has been initialized by the
    // launching job (..ProcessBatch())
    if async { while '$d(^IRIS.Temp.IK.Processes(tTempId,processNr)) { hang 1 } }
    Set $list(^IRIS.Temp.IK.Processes(tTempId,processNr))=$$$IKPROCDONE
    Quit sc

    // Error exit
err $$$IKERROR(domId,sc,..%ClassName(1)_":Execute")
    Kill objDI
    Kill objIDX
    if async { while '$d(^IRIS.Temp.IK.Processes(tTempId,processNr)) { hang 1 } }
    Set $list(^IRIS.Temp.IK.Processes(tTempId,processNr))=$$$IKFAIL
    Quit sc
}

Method LoadSources(objIdx As %iKnow.Indexer, objDi As %iKnow.DirectInputDO) As %Status [ Internal ]
{
    Set domId=i%DomainId
    Set pref="^IRIS.Temp.IK."_i%TempId_".",
        srclist=pref_"SrcList",srcmeta=pref_"SrcMeta",srctempmeta=pref_"SrcTempMeta"
    Set maxloc=+$g(@srclist)
    Set curclassid=0,curcfg=0,srcArr=0,curparams="",curconvparams="",curconvId=0,curloc=0
    set procConvKeys="", prevProcConvKeys="", listerKeyId=0, prevListerKeyId=0, prevKeyId=0
    Set errloc=..%ClassName(1)_":LoadSources"
    
    // BDB600 - load stemmer object for this domain
    set sc = ##class(%iKnow.Stemmer).GetByDomain(i%DomainId,.tStemmer)
    quit:$$$ISERR(sc) sc
    set sc = objIdx.SetStemmer(tStemmer)
    quit:$$$ISERR(sc)
    
    For {
        Set loc=$i(@i%SrcInc)
        Quit:loc>maxloc

        Set sc=$$$OK
        Try {
            Set srcinfo=@srclist@(loc)
            Set ref=$list(srcinfo),dsloc=$list(srcinfo,2),listerKeyId=+$lg(srcinfo,3)

            // If any of the configuration, or processor class, converter class, or parameters have changed,
            // get the updated ones
            Set newkeyid=0
            If dsloc'=curloc {
                // Get configuration id, processor class id, processor parameters, converter class id, converter parameters
                Set srcdata=@i%SrcData@(dsloc)
                Set cfg=$lg(srcdata),srcclassid=$lg(srcdata,2),params=$lg(srcdata,3),convId=+$lg(srcdata,4),convparams=$lg(srcdata,5)

                // Get the configuration
                If cfg'=curcfg {
                    Set objCfg=##class(%iKnow.Configuration).OpenId(cfg)
                    If objCfg="" { Set sc=$$$ERROR($$$IKConfigurationNotFound,cfg) Quit }
                    Set sc=objCfg.ConfigureIndexer(objIdx)
                    Set objCfg=""
                    Quit:$$$ISERR(sc)
                    Set curcfg=cfg
                }

                // Get the processor class, set any parameters if they've changed
                If srcclassid'=curclassid {
                    If $Data(srcInd(srcclassid),ind) {
                        Set objSrc=srcArr(ind)
                    } Else {
	                    
	                    // BDB303 - switch off delimited sentence mode
	                    if (curclassid && (^IRIS.IK.Sys.ProcessorD(curclassid)="%iKnow.Source.Domain.Processor")) {
	                    	set sc = objIdx.DisableDelimitedSentences()
	                    	quit:$$$ISERR(sc)
	                    }
	                    
                        Set objSrc=$classmethod(^IRIS.IK.Sys.ProcessorD(srcclassid),"%New",domId,objIdx,objDi)
                        If objSrc="" { Set sc=$$$ERROR($$$IKUnableOpenProcessorId, srcclassid) Quit }
                        Set srcArr=srcArr+1,srcArr(srcArr)=objSrc,srcInd(srcclassid)=srcArr
                        Do objSrc.SetBatchMode(1)
                    }
                    Set curclassid=srcclassid
                    Set sc=objSrc.SetParams(params)
                    Quit:$$$ISERR(sc)
                    Set sc=objSrc.SetConverter(convId,convparams)
                    Quit:$$$ISERR(sc)
                    Set curparams=params,curcurconvparams=convparams,newkeyid=1
                } Else {
                    If params'=curparams {
                        Set sc=objSrc.SetParams(params)
                        Quit:$$$ISERR(sc)
                        Set curparams=params,newkeyid=1
                    }
                    If convId=curconvId,convparams=curconvparams {}
                    Else {
                        Set sc=objSrc.SetConverter(convId,convparams)
                        Quit:$$$ISERR(sc)
                        Set curconvId=convId,curconvparams=convparams,newkeyid=1
                    }
                }
                Set curloc=dsloc
            }
            
            // check if, after the processor and or converter changed, this really means new keys
            If newkeyid {
                Set procConvKeys = objSrc.GetMetadataKeys(params)
                Set:convId convClass=^IRIS.IK.Sys.ConverterD(convId),procConvKeys=procConvKeys_$classmethod(convClass,"GetMetadataKeys",convparams)
                Set:$ls(prevProcConvKeys,procConvKeys) newkeyid=0
                Set prevProcConvKeys=procConvKeys
            }
             
            // if we still need a new key, combine procConvKeys with the lister keys
            Set keyid=0
            If newkeyid {
                Set keys = procConvKeys
                Set:listerKeyId keys = @srcmeta@(listerKeyId) _ keys
                Set keyid=$i(@srcmeta), @srcmeta@(keyid)=keys
            } Else {
                // if the procConvKeys haven't changed, check whether the listerKeyId did
                If (prevListerKeyId=listerKeyId) {
                    // if still the same, reuse the previous keyid
                    set keyid = prevKeyId
                } Else {
                    // if they changed, build a new id if we have a valid listerKeyId
                    If (listerKeyId) {
                        Set keys = @srcmeta@(listerKeyId) _ procConvKeys
                        Set:keys'="" keyid=$i(@srcmeta), @srcmeta@(keyid)=keys
                    } Else {
                        Set keyid=0
                    }
                }
            }
            Set prevListerKeyId=listerKeyId, prevKeyId=keyid
            
            Set sc=objSrc.ProcessListElement(loc,ref,keyid,$g(@srctempmeta@(loc)))
            // For now, allocation of SrcId happens in DirectInputDO, but not DirectInputOne
        } Catch {
            Set sc=$$$ERROR($$$IKCaughtError,errloc,$ZE)
        }
        // Log failed sources if this error was not already logged by ProcessListElement()
        if $$$ISERR(sc) {
	        set lastErr = $g(^IRIS.IKL.Failed(domId,+$g(^IRIS.IKL.Failed(domId))))
	        set isNew = ($ls($lg(lastErr,1),ref) && ($lg(lastErr,3)=sc))
	        set:'isNew ^IRIS.IKL.Failed(domId,$I(^IRIS.IKL.Failed(domId)))=$lb(ref,errloc,sc,,$h)
        }
    }
    Quit $$$OK
}

Method SetCurrentErrors() As %Status [ Internal, Private ]
{
	set i%LastErrBeforeLoad = +$g(^IRIS.IKL.ErrorLog(i%DomainId))
	set i%LastFailBeforeLoad = +$g(^IRIS.IKL.Failed(i%DomainId))
	set i%LastWarnBeforeLoad = +$g(^IRIS.IKL.Warning(i%DomainId))
	quit $$$OK
}

Method CheckErrors(ByRef sc As %Status) As %Status [ Internal, Private ]
{
    if ($g(^IRIS.IKL.ErrorLog(i%DomainId)) > i%LastErrBeforeLoad) {
	    set message = "WARNING: some errors occurred during the loading process, call Loader.GetErrors() for details"
	    if %IKStatus && $g(%IKVerbose)<0 {
	        $$$IKDISPBGR($s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:"")_message)
	    } elseif %IKStatus {
	        write !,$s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:""),message
	    }
        set:$$$ISOK(sc) sc = $$$ERROR($$$GeneralError, message)
    } elseif ($g(^IRIS.IKL.Failed(i%DomainId)) > i%LastFailBeforeLoad) {
	    set message = "WARNING: some sources were not processed successfully, call Loader.GetFailed() for details"
	    if %IKStatus && $g(%IKVerbose)<0 {
	        $$$IKDISPBGR($s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:"")_message)
	    } elseif %IKStatus {
	        write !,$s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:""),message
	    }
        set:$$$ISOK(sc) sc = $$$ERROR($$$GeneralError, message)
    } elseif ($g(^IRIS.IKL.Warning(i%DomainId)) > i%LastWarnBeforeLoad) {
	    if %IKStatus && $g(%IKVerbose)<0 {
	        $$$IKDISPBGR($s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:"")_"WARNING: some sources were not processed successfully, call Loader.GetWarnings() for details")
	    } elseif %IKStatus {
	        write !,$s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:""),"WARNING: some sources were not processed successfully, call Loader.GetWarnings() for details"
	    }
    } else {
	    if %IKStatus && $g(%IKVerbose)<0 {
	        $$$IKDISPBGR($s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:"")_"All sources were processed successfully")
	    } elseif %IKStatus {
	        write !,$s($g(%IKVerbose):$zt($p($h,",",2))_": ",1:""),"All sources were processed successfully"
	    }
    }
	quit $$$OK
}

/// <p>Simple utility method to retrieve an overview of all Lists as currently scheduled through 
/// AddListToBatch calls on <class>%iKnow.Source.Lister</class> objects for this Loaders domain.</p>
Method GetCurrentLists(ByRef result) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    Set listId = "", i=0
    For {
        Set listId = $order(@i%ListGlo@(listId),1,tData)
        Quit:listId=""
        Continue:tData=""
        
        Set listerId = $lg(tData)
        Set listerClass = ^IRIS.IK.Sys.ListerD(listerId)
        Set listerAlias = $classmethod(listerClass,"GetAlias")
        Set listerParams = $classmethod(listerClass,"FormatParams",$lg(tData,3))
 
        Set infoId = $lg(tData,2)
        Set info = @i%SrcData@(infoId)
        Set configId = $lg(info,1)
        Set configName = $lg(^IRIS.IK.Sys.ConfigD(configId),1)
                
        Set processorId = $lg(info,2)
        If (processorId="") { 
            Set processorName = $classmethod(listerClass,"DefaultProcessor")
            Set processorId = ^IRIS.IK.Sys.ProcessorI(processorName)
        } Else {
            Set processorName = ^IRIS.IK.Sys.ProcessorD(processorId)
        }
        Set processorParams = $lts($lg(info,3))
                
        Set convertorId = $lg(info,4), convertorName=""
        Set:convertorId'="" convertorName = ^IRIS.IK.Sys.ConverterD(convertorId)
        Set convertorParams = $lg(info,5)
                
        $$$IKQADDRESULT(result,$i(i),$lb(+listId, listerId, listerClass, listerAlias, listerParams, configId, configName, processorId, processorName, processorParams, convertorId, convertorName, convertorParams))
    }
    $$$IKQENDCATCH(result,"",tSC)
}

/// <p>Returns all logged errors for this domain. By default only the errors logged since this
/// Loader object's last load operation are returned, unless the returnAll parameter is set to 1.
/// The returned result contains the following columns:</p>
/// <ol>
/// 	<li>Error message</li>
/// 	<li>Location: indication of the class and method where the error occurred</li>
/// 	<li>Timestamp: in $horolog format</li>
/// </ol>
Method GetErrors(ByRef result, returnAll As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	
	set j = $s(returnAll:"", 1:i%LastErrBeforeLoad), i=0
	for {
		set j = $order(^IRIS.IKL.ErrorLog(i%DomainId,j),1,data)
		quit:j=""
		
		set errormsg = $lg(data,1)
		set:$$$ISERR(errormsg) errormsg = $$GetErrorText^%apiOBJ(errormsg)
		set location = $lg(data,2)
		set timestamp = $lg(data,3)
		$$$IKQADDRESULT(result,$i(i),$lb(errormsg,location,timestamp))
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

/// <p>Returns all logged source failures for this domain. By default only the failures logged since this
/// Loader object's last load operation are returned, unless the returnAll parameter is set to 1.
/// The returned result contains the following columns:</p>
/// <ol>
/// 	<li>Composite reference: elements used to generate the external ID (in case it didn't get generated)</li>
/// 	<li>External ID</li>
/// 	<li>Location: indication of the class and method where the error occurred</li>
/// 	<li>Error message</li>
/// 	<li>Internal error ID: Contact WRC if this is a positive integer.</li>
/// 	<li>Timestamp: in $horolog format</li>
/// </ol>
Method GetFailed(ByRef result, returnAll As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	
	set j = $s(returnAll:"", 1:i%LastFailBeforeLoad), i=0
	for {
		set j = $order(^IRIS.IKL.Failed(i%DomainId,j),1,data)
		quit:j=""
		
		// SPJ!!! This should not be taking compRef to be either a $list or something else!
		set compRef = $lg(data)
		if $listvalid(compRef) {
		    set extId = ##class(%iKnow.Source.Lister).BuildExtId(i%DomainId,$lg(compRef),$lg(compRef,2),$lg(compRef,3))
		} else {
		    set extId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(i%DomainId,+compRef)
		}
		set location = $lg(data,2)
		set errormsg = $lg(data,3)
		set:$$$ISERR(errormsg) errormsg = $$GetErrorText^%apiOBJ($lg(data,3))
		set errorId = $lg(data,4)
		set timestamp = $lg(data,5)
		set return = $lb(compRef,extId,location,errormsg,errorId,timestamp)
		$$$IKQADDRESULT(result,$i(i),return)
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

/// <p>Returns all logged warnings for this domain. By default only the warnings logged since this
/// Loader object's last load operation are returned, unless the returnAll parameter is set to 1.
/// The returned result contains the following columns:</p>
/// <ol>
/// 	<li>Composite reference: elements used to generate the external ID (in case it didn't get generated)</li>
/// 	<li>External ID</li>
/// 	<li>Location: indication of the class and method where the error occurred</li>
/// 	<li>Error message</li>
/// 	<li>Timestamp: in $horolog format</li>
/// </ol>
Method GetWarnings(ByRef result, returnAll As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	
	set j = $s(returnAll:"", 1:i%LastWarnBeforeLoad), i=0
	for {
		set j = $order(^IRIS.IKL.Warning(i%DomainId,j),1,data)
		quit:j=""
		
		// SPJ!!! This should not be taking compRef to be either a $list or something else!
		set compRef = $lg(data)
		if $listvalid(compRef) {
		    set extId = ##class(%iKnow.Source.Lister).BuildExtId(i%DomainId,$lg(compRef),$lg(compRef,2),$lg(compRef,3))
		} else {
		    set extId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(i%DomainId,+compRef)
		}
		set location = $lg(data,2)
		set errormsg = $lg(data,3)
		set:$$$ISERR(errormsg) errormsg = $$GetErrorText^%apiOBJ($lg(data,3))
		set timestamp = $lg(data,3)
		set return = $lb(compRef,extId,location,errormsg,timestamp)
		$$$IKQADDRESULT(result,$i(i),data)
	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

}
