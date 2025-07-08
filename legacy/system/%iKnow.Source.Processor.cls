/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This is the base class for any Processor implementations. Processor classes are developed to
/// read source data as referenced (or stored temporarily) by <class>%iKnow.Source.Lister</class>
/// classes in their <method class="%iKnow.Source.Lister">ExpandList</method> methods.
/// It is up to the Lister to make sure the references they
/// store in this stage refer to the proper Processor implementation and contain the details it
/// needs to find and read that source while executing <method>FetchSource</method>.</p>
/// <p>Each Processor implementation tackles a specific type of location where source data can be
/// read from, such as a filesystem for <class>%iKnow.Source.File.Processor</class> or a global for
/// <class>%iKnow.Source.Global.Processor</class>.</p>
/// <p>Processor objects are handled by the loading framework automatically and custom code should
/// never instantiate a Processor object or call any of its methods directly.</p>
Class %iKnow.Source.Processor Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

Property DomainId As %Integer [ Private ];

/// surrogate domain ID for use in IRIS.Temp
/// guaranteed to be unique across namespaces
Property TempId As %Integer [ Private ];

Property Indexer As %iKnow.Indexer [ Private ];

Property DirectInput As %iKnow.DirectInput [ Private ];

Property Converter As %iKnow.Source.Converter [ Private ];

Property Buffer As %RegisteredObject [ Private ];

Property ListerId As %Integer [ Private ];

Property Params As %String [ Private ];

Property ConverterId As %Integer [ Private ];

Property ConvParams As %String [ Private ];

Property MetaData As %List [ Internal, Private ];

Property SrcTemp As %String [ Internal, Private ];

Property SrcMeta As %String [ Internal, Private ];

Property DPSkipExtIdCheck As %Boolean [ Internal, Private ];

Property DPSimpleExtIds As %Boolean [ Internal, Private ];

Property DPLanguageFieldName As %String [ Internal, Private ];

Property DPIgnoreDupExtIds As %Boolean [ Internal, Private ];

Method %OnNew(domainId As %Integer, indexer As %iKnow.Indexer, directInput As %iKnow.DirectInput) As %Status [ Private, ServerOnly = 1 ]
{
    Set i%DomainId=domainId
    
    // BDB500 - fetch system-wide unique domain ID
    $$$IKTEMPDOMID(domainId,tTempId)
    Set i%TempId = tTempId
    
    Set i%Indexer=indexer
    // This is used for buffering in the processor
    Set i%Buffer=indexer
    Set i%DirectInput=directInput
    
    set i%DPSkipExtIdCheck = $$$GETPARAMNODEF(domainId,$$$IKPSKIPEXTIDCHECK)
    set i%DPSimpleExtIds = $$$GETPARAMNODEF(domainId,$$$IKPSIMPLEEXTIDS)
    set i%DPLanguageFieldName = $$$GETPARAMNODEF(domainId,$$$IKPLANGUAGEFIELDNAME)
    set i%DPIgnoreDupExtIds = $$$GETPARAMNODEF(domainId,$$$IKPIGNOREDUPLICATEEXTIDS)
    
    Quit $$$OK
}

Method SetBatchMode(BatchMode As %Integer) [ Internal ]
{
    Set i%SrcTemp=$s($g(BatchMode):"^IRIS.Temp.IK."_i%TempId,1:"^||%ik")_".SrcTemp"
    Set i%SrcMeta=$s($g(BatchMode):"^IRIS.Temp.IK."_i%TempId,1:"^||%ik")_".SrcMeta"
}

/// <p>This method stores the Processor parameters in the <property>Params</property> property,
/// from where they can be referenced in the <method>FetchSource</method> implementation.</p>
/// <p><b>NOTE:</b> If this method is overridden by a subclass, it should make sure to either 
/// call this method via ##super, or set <property>Params</property> itself.</p>
Method SetParams(params As %String) As %Status [ ServerOnly = 1 ]
{
    Set i%Params=$g(params)
    Quit $$$OK
}

/// <p>Registers the Converter to be used by this Processor onwards.</p>
Method SetConverter(convId As %Integer, convParams As %String) As %Status [ Final ]
{
    Set convParams=$g(convParams)
    If i%ConverterId'=convId {
        Set i%ConverterId=convId
        If convId {
            Set i%Converter=$classmethod(^IRIS.IK.Sys.ConverterD(convId),"%New",convParams)
            If i%Converter="" { Set sc=$$$ERROR($$$IKUnableOpenConverterId, convId) Quit }
            Set i%Buffer=i%Converter, i%ConvParams=convParams
        } Else {
            Set i%Converter="", i%Buffer=i%Indexer, i%ConvParams=""
        }
    } ElseIf convId,convParams'=i%ConvParams {
        Do i%Converter.SetParams(convParams)
        Set i%ConvParams=convParams
    }
    Quit $$$OK
}

/// <p>Returns the metadata keys that are made available and taken care of automatically
/// for every Processor implementation.</p>
ClassMethod GetSystemMetadataKeys() As %List [ Final, Internal ]
{
    Quit $lb("DateIndexed")
}

/// <p>Subclasses should override this method to identify those metadata keys that are
/// calculated or extracted by this Processor implementation and will be registered for every
/// source processed by calling <method>SetCurrentMetadataValues</method> during the
/// <method>FetchSource</method> execution.</p>
ClassMethod GetMetadataKeys(params As %String) As %List
{
    Quit ""
}

/// <p>Instance method to invoke the static <method>GetMetadataKeys</method> using this instances params</p>
Method GetCurrentMetadataKeys() As %List [ Final, Internal ]
{
    Quit ..GetMetadataKeys(i%Params)
}

/// <p>Stores the metadata values for the source currently being processed. Their order and
/// number should correspond to the keys returned by <method>GetMetadataKeys</method>.</p>
Method SetCurrentMetadataValues(metaValues As %List) As %Status [ Final, Private ]
{
    Quit:$ll(metaValues)'=$ll(..GetCurrentMetadataKeys()) $$$ERROR($$$IKMDValueCountMismatch, $ll(metaValues), $ll(..GetCurrentMetadataKeys()))
    Set i%MetaData = i%MetaData _ metaValues
    Quit $$$OK
}

/// <p>This is the primary method that will need to be implemented by subclasses. It gets the local ID
/// of the source being processed (as assigned by the lister) and the Composite Reference in %List
/// format. Data read by the Processor should be buffered through calling ..Buffer.BufferString(), 
/// which will automatically forward the data to the iKnow Indexing engine or, if configured,
/// a <class>%iKnow.Source.Converter</class> object that will in turn push converted data through
/// to the engine.</p>
/// <p>If this Processor also extracts metadata while reading (as specified in its 
/// <method>GetMetadataKeys</method> implementation), it should make sure to invoke
/// <method>SetCurrentMetadataValues</method> at some point in this methods execution.</p>
Method FetchSource(loc As %Integer, ref As %List) As %Status [ Private ]
{
   Quit $$$OK
}

/// <p>This is the primary method that will be called from the <class>%iKnow.Source.Loader</class>
/// for each source identified by the <class>%iKnow.Source.Lister</class> objects involved in this
/// loading process. It will buffer what's read in the <method>FetchSource</method> implementation,
/// trigger the <class>%iKnow.Source.Converter</class> if one is configured, and then instruct the
/// Indexer to process the resulting plain text, directing its output to the appropriate DirectInput
/// object.</p>
/// <p>Also, this method will gather any metadata set by the Lister, combine it with metadata
/// calculated by the Processor or Converter and push it to the DirectInput object as well.</p>
Method ProcessListElement(loc As %Integer, ref As %List, keyid As %Integer, metadata As %String, Output skipped As %Boolean = 0) As %Status [ Final ]
{
	set skipped = 0
    Set sc=i%Indexer.ClearBuffer()
    Goto:$$$ISERR(sc) err
    
    // BDB723
    $$$STARTTIMINGS(i%DomainId)
    
    // if we're in a SimpleExtIds domain, calculate the fullRef only once
    if (i%DPSimpleExtIds) {
	    set simpleRef = ##class(%iKnow.Source.Lister).BuildSimpleRefFromComposite(i%DomainId, ref, .sc)
    	goto:$$$ISERR(sc) err
    }
    
    // first check if this ext ID already exists
    If ('i%DPSkipExtIdCheck) {
        If i%DPSimpleExtIds {
	        set l=0, g=0, r=simpleRef
        } else {
	        set l=+$lg(ref,1), g=+$lg(ref,2), r=$lg(ref,3)
        }
        if ($l(r)>$$$IKHASHSIZE) {
	        set h = $zcrc(r,7), s=""
	        for {
		        set s = $order(^IRIS.IK.Ext.LocalRefHash(i%DomainId, l, g, h, s))
		        quit:s=""
		        goto:($lg(^IRIS.IK.SrcId(i%DomainId,s),3)=r) duperr
	        }
        } else {
            goto:$d(^IRIS.IK.Ext.LocalRef(i%DomainId, l, g, r)) duperr
        }
    }

    // Initialize meta data
    Set i%MetaData=$g(metadata)

    // Save source ref
    if (i%DPSimpleExtIds) {
	    set i%DirectInput.Source = $lb(0, 0, simpleRef)
	    do:i%ConverterId i%Buffer.SetContext(i%DomainId, $lb(0, 0, simpleRef))
    } else {
	    Set i%DirectInput.Source=$li(ref,1,3)
	    do:i%ConverterId i%Buffer.SetContext(i%DomainId, $li(ref,1,3))
    }

	// FetchSource is always passed the original ref, not the simplified one if SimpleExtIds=1
    Set sc=..FetchSource(loc,ref)
    Goto:$$$ISERR(sc) err

    Set convMD=""
    If i%ConverterId { 
        Set sc=..Convert() Goto:$$$ISERR(sc) err
        Set convMD=i%Converter.GetMetadataValues()
        Set sc=i%Converter.ResetMetadataValues() Goto:$$$ISERR(sc) err
    }
    Set:convMD'="" i%MetaData=i%MetaData_convMD
	
	try {
		$$$STARTTIMINGSNEST
	    Set sc=i%Indexer.IndexBuffer(i%DirectInput, ..GetKnownLanguage(loc, ref, keyid))
	    $$$ENDTIMINGSP(i%DomainId,"Processor:IndexBuffer")
	    $$$STARTTIMINGSUNNEST
	} catch (ex) {
		set sc = ex.AsStatus()
		goto fin
	}

    // Save metadata
    Set time=$zts,time=$p(time,",")_","_($p(time,",",2)\1)
    Set sc=i%DirectInput.AddMetaData($lb(keyid, time)_i%MetaData)
    Goto:$$$ISERR(sc) err
    $$$ENDTIMINGSP(i%DomainId,"Processor:ProcessListElement") // BDB723
    Quit sc

duperr // Duplicate id error
	set skipped = 1
	quit:i%DPIgnoreDupExtIds $$$OK
    Set sc=$$$ERROR($$$IKDuplicateExternalId,ref)
    // Log failed sources
err do ..ReportError(ref,sc,..%ClassName(1)_":ProcessListElement")
	set skipped=1
    $$$ENDTIMINGSP(i%DomainId,"Processor:ProcessListElement") // BDB723
    Quit sc

fin Do i%DirectInput.RollBackCurrentSource(ref)
    Set errid=i%DirectInput.ErrorId
    Set errloc=$s(errid:i%DirectInput.%ClassName(1)_":AddData",1:i%Indexer.%ClassName(1)_":IndexBuffer")
    do ..ReportError(ref,sc,errloc,errid)
    $$$ENDTIMINGSP(i%DomainId,"Processor:ProcessListElement") // BDB723
    Quit sc
}

/// Same as <method>ProcessListElement</method>, but for Virtual Sources.
Method ProcessVirtualListElement(loc As %Integer, ref As %List) As %Status [ Final ]
{
    Set sc=i%Indexer.ClearBuffer()
    Goto:$$$ISERR(sc) err
    
    $$$STARTTIMINGS(i%DomainId) // BDB723
    
    // Save source ref
    if (i%DPSimpleExtIds) {
	    set simpleRef = ##class(%iKnow.Source.Lister).BuildSimpleRefFromComposite(i%DomainId, ref, .sc)
    	goto:$$$ISERR(sc) err
	    set i%DirectInput.Source = $lb(0, 0, simpleRef)
	    do:i%ConverterId i%Buffer.SetContext(i%DomainId, $lb(0, 0, simpleRef))
    } else {
	    Set i%DirectInput.Source=ref
	    do:i%ConverterId i%Buffer.SetContext(i%DomainId, ref)
    }

    Set sc=..FetchSource(loc,ref)
    Goto:$$$ISERR(sc) err

    If i%ConverterId {
        Set sc=..Convert()
        Goto:$$$ISERR(sc) err
    }

	$$$STARTTIMINGSNEST
    Set sc=i%Indexer.IndexBuffer(i%DirectInput, ..GetKnownLanguage(loc,ref))
    $$$ENDTIMINGSP(i%DomainId,"Processor:IndexBuffer") // BDB723
    $$$STARTTIMINGSUNNEST
    
    If $$$ISERR(sc) {
        Do i%DirectInput.RollBackCurrentSource(ref)
        Set errid=i%DirectInput.ErrorId
        Set errloc=$s(errid:i%DirectInput.%ClassName(1)_":AddData",1:i%Indexer.%ClassName(1)_":IndexBuffer")
        do ..ReportError(ref,sc,errloc,errid)
    }
    $$$ENDTIMINGSP(i%DomainId,"Processor:ProcessListElement") // BDB723
    Quit sc

    // Log failed sources
err do ..ReportError(ref,sc,..%ClassName(1)_":ProcessVirtualListElement")
    $$$ENDTIMINGSP(i%DomainId,"Processor:ProcessListElement") // BDB723
    Quit sc
}

/// Utility method to report failures for a given source (identified through a Composite Reference)
Method ReportError(ref As %List, message As %String, location As %String = "", errorId As %String = "") As %Status [ Final, Private ]
{
	set:location="" location = ..%ClassName(1)
    set ^IRIS.IKL.Failed(i%DomainId,$i(^IRIS.IKL.Failed(i%DomainId)))=$lb(ref,location,message,errorId,$h)
    quit $$$OK
}

/// Utility method to report warnings for a given source (identified through a Composite Reference)
Method ReportWarning(ref As %List, message As %String, location As %String = "") As %Status [ Final, Private ]
{
	set:location="" location = ..%ClassName(1)
    Set ^IRIS.IKL.Warning(i%DomainId,$i(^IRIS.IKL.Warning(i%DomainId)))=$lb(ref,location,message,$h)
    Quit $$$OK
}

Method Convert() As %Status [ Final, Internal, Private ]
{
    Quit:'i%ConverterId $$$OK
    Set sc=i%Converter.Convert()
    Quit:$$$ISERR(sc) sc
    For {
        Set data=i%Converter.NextConvertedPart()
        Quit:data=""
        Set sc=i%Indexer.BufferString(.data)
        Quit:$$$ISERR(sc)
    }
    Quit sc
}

/// TODO: can we get rid of this one? or should we call it at the end of ProcessListElement?
Method CleanTemp() As %Status [ Final, Internal, Private ]
{
   quit $$$OK
}

/// <p>This method is called from <method>ProcessListElement</method> and <method>ProcessVirtualListElement</method>
/// right before calling on the Indexer to process the data read by this Processor instance. 
/// It returns the language (two-letter ISO code) for the source being processed, if there
/// is any means to derive it from known facts about the source. If no language can be
/// derived with enough certainty, this method returns "".</p>
/// <p>The default implementation looks if there is a $$$IKPLANGUAGEFIELDNAME parameter defined
/// pointing to a metadata field containing the language code. Subclasses may override and/or
/// extend this method if they have access to additional information.</p>
Method GetKnownLanguage(loc As %Integer, ref As %List, keyid As %Integer = "") As %String
{
	set tLang = ""
	
    // if a metadata field specifying the source language exists, read its value
    if (i%DPLanguageFieldName'="") && (keyid'="") {
	    set tMetaFields = $g(@i%SrcMeta@(keyid))
	    set tLangFieldPos = $s($listvalid(tMetaFields):$lf(tMetaFields,i%DPLanguageFieldName), 1:0)
	    set:tLangFieldPos tLang = $zconvert($lg(i%MetaData,tLangFieldPos),"L")
    }
    quit tLang
}

}
