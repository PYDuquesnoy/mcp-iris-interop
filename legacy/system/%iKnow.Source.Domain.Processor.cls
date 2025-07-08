/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This Processor implementation reads data from existing sources in a (typically different)
/// domain, as listed by the ExpandList method of the <class>%iKnow.Source.Domain.Lister</class>.
/// These Lister and Processor classes are at the core of the <class>%iKnow.Utils.CopyUtils</class>
/// and <class>%iKnow.Utils.UpgradeUtils</class> classes.</p>
/// 
/// <p><b>Processor parameters:</b></p>
/// <ol>
/// 	<li><b>srcDomainId</b> As <class>%Integer</class> - the domain where to copy data from. 
/// 					 (only required when specifying <var>metaFields</var>)</li>
/// 	<li><b>metaFields</b> As <class>%List</class> (optional) - the metadata fields to copy from the
/// 					 source domain into the target one.</li>
/// 	<li><b>overrideLanguage</b> As <class>%String</class> (optional) - the two-letter language
/// 					 code of a language to use overriding what can be derived from the 
/// 					 source domain. Leave blank to use source domain values and use
/// 					 "AUTO" to re-detect using normal configuration settings.</li>
/// 	<li><b>preserveSentences</b> As <class>%Boolean</class> (optional, defaults to 1) - whether or
/// 					 not to preserve the exact same sentence splittings as in the original
/// 					 indexation.</li>
/// </ol>
/// 
/// <p><b>Extracted metadata keys:</b> see <var>metaFields</var> Processor parameter.</p>
Class %iKnow.Source.Domain.Processor Extends %iKnow.Source.Processor [ Deprecated, System = 4 ]
{

Property SrcDomainId As %Integer [ Private ];

Property MetaFields As %List [ Private ];

Property MetaFieldIds As %List [ Internal, Private ];

Property OverrideLanguage As %String [ Private ];

Property PreserveSentences As %Boolean [ InitialExpression = 1, Private ];

Property LanguagesInUse [ Internal, MultiDimensional, Private ];

/// BDB317 - shorthand method to directly process / re-index a particular source ID with
/// this Processor instance's current settings. NOT TO BE USED BY CUSTOM CODE
Method ProcessDirect(pSrcId As %Integer) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tRef = $lb(,,, ..SrcDomainId, pSrcId)
		
		set tSC = ..FetchSource(0, tRef)
		quit:$$$ISERR(tSC)
		
    	set:..ConverterId tSC=..Convert()
	    quit:$$$ISERR(tSC)
        
		set tSC = ..Indexer.IndexBuffer(..DirectInput, ..GetKnownLanguage(0, tRef, 0))
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method FetchSource(loc As %Integer, ref As %List) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set srcDomainId = $li(ref,4), srcId = $li(ref,5), vSrcId = $s(srcId>0:0, 1:-srcId)
		
		set srcDetails = $s(vSrcId:^IRIS.IKV.SrcDetails(srcDomainId, vSrcId), 1:^IRIS.IK.SrcDetails(srcDomainId, srcId))
		set sentFrom = $li(srcDetails,1)+1
		set sentTo = sentFrom + $li(srcDetails,2) - 1
		for sentId = sentFrom:1:sentTo {
			
			set sentVal = ##class(%iKnow.Queries.SentenceAPI).GetValue(srcDomainId, sentId, .fullSent, vSrcId)
		
			if (fullSent) {
				set tSC = i%Buffer.BufferString(sentVal)
			} else {
				set i = ""
				for {
					set i = $o(fullSent(i),1,sentVal)
					quit:i=""
					
					set tSC = i%Buffer.BufferString(sentVal)
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
			// add two line breaks to ensure the sentence is split
			set tSC = i%Buffer.BufferString($c(13,10,13,10))
		}
			
		// metadata
		if 'vSrcId && (i%MetaFieldIds '= "") {
			set ptr = 0, values=""
			while $listnext(i%MetaFieldIds, ptr, fieldId) {
				continue:'fieldId
				set values = values _ $lb($g(^IRIS.IK.Mdt.Values(srcDomainId, srcId, fieldId)))
			}
			set tSC = ..SetCurrentMetadataValues(values)
			quit:$$$ISERR(tSC)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

Method SetParams(params As %String) As %Status [ ServerOnly = 1 ]
{
    set tSC = ##super(params)
    try {
	    set ..SrcDomainId = $lg(params,1)
	    set fields = $lg(params,2)
	    set ..OverrideLanguage = $$$LOWER($lg(params,3))
	    set ..PreserveSentences = $lg(params,4,1)
	    
	    // configure metadata fields
	    if $listvalid(fields) && (fields'="") {
		    set ptr = 0, ids="", names=""
	    	while $listnext(fields,ptr,fieldName) {
		    	set id = +##class(%iKnow.Queries.MetadataAPI).GetFieldId(i%SrcDomainId,fieldName)
		    	continue:'id
		    	set names = names _ $lb(fieldName)
		    	set ids = ids _ $lb(id)
	    	}
	    	set ..MetaFields = names
	    	set ..MetaFieldIds = ids
	    }
	    
	    // BDB303 - check language property
	    if (..OverrideLanguage'="") && (..OverrideLanguage'="auto") {
		    if '$lf($$$IKLANGUAGES, ..OverrideLanguage) {
			    set tSC = $$$ERROR($$$IKLanguageDoesNotExist, ..OverrideLanguage)
			    quit
		    }
	    }
	    kill ..LanguagesInUse
	    
	    // BDB303 - enable delimited sentence mode to prevent recalculating sentence splits
	    if (..PreserveSentences) {
		    set tSC = i%Indexer.EnableDelimitedSentences()
		    quit:$$$ISERR(tSC)
	    }
	    
    } catch (ex) {
	    set tSC = ex.AsStatus()
    }
    quit tSC
}

/// <p>Subclasses should override this method to identify those metadata keys that are
/// calculated or extracted by this Processor implementation and will be registered for every
/// source processed by calling <method>SetCurrentMetadataValues</method> during the
/// <method>FetchSource</method> execution.</p>
ClassMethod GetMetadataKeys(params As %String) As %List
{
    set srcDomId = $lg(params,1), fields = $lg(params,2), names = ""
    if $listvalid(fields) && (fields'="") {
	    set ptr = 0, ids="", names=""
    	while $listnext(fields,ptr,fieldName) {
	    	set id = +##class(%iKnow.Queries.MetadataAPI).GetFieldId(srcDomId,fieldName)
	    	continue:'id
	    	set names = names _ $lb(fieldName)
    	}
    }
    quit names
}

Method GetKnownLanguage(loc As %Integer, ref As %List, keyid As %Integer = "") As %String
{
	set tLang = ##super(loc, ref, keyid)
	quit:tLang'="" tLang
	
	// BDB303 - derive language based on ..OverrideLanguage property
	
	// "AUTO" means use normal Configuration behavior
	quit:..OverrideLanguage="auto" ""
	
	set tSC = $$$OK
	try {
		// any other non-null value means use this language
		if (..OverrideLanguage'="") {
			set tLang = ..OverrideLanguage
			if '$d(..LanguagesInUse(tLang)) {
				set tLangId = $lf($$$IKLANGUAGES,tLang)
				set tSC = ..Indexer.LoadLanguagebase(tLang, ##class(%iKnow.LB.Languagebase).GetByName(tLang))
				quit:$$$ISERR(tSC)
				set tSC = ..Indexer.LoadKnowledgebase(tLang, ##class(%iKnow.KB.Knowledgebase).GetByName(tLang))
				quit:$$$ISERR(tSC)
				set ..LanguagesInUse(tLang) = 1
			}
			quit
		}
	
		// otherwise, derive from source domain
		set tSrcDomainId = $li(ref,4), tSrcId = $li(ref,5), vSrcId = $s(tSrcId>0:0, 1:-tSrcId)
		
		set gSentDetails = $$$IKVGLOBNAME(tSrcDomainId,"SentDetails",vSrcId)
		set tSrcDetails = $s(vSrcId:^IRIS.IKV.SrcDetails(tSrcDomainId, vSrcId), 1:^IRIS.IK.SrcDetails(tSrcDomainId, tSrcId))
		set tSentFrom = $li(tSrcDetails,1)+1, tSentTo = tSentFrom + $li(tSrcDetails,2) - 1
		set tPrevLangId=0, tMixed=0
		for tSentId = tSentFrom:1:tSentTo {
			set tSentDetails = @gSentDetails@(tSentId)
			set tLangId=$li(tSentDetails,1), tConfidence=$li(tSentDetails,2)
			
			// ensure this language is loaded
			if '$d(..LanguagesInUse(tLangId)) {
				set tNewLang = $li($$$IKLANGUAGES,tLangId)
				set tSC = ..Indexer.LoadLanguagebase(tNewLang, ##class(%iKnow.LB.Languagebase).GetByName(tNewLang))
				quit:$$$ISERR(tSC)
				set tSC = ..Indexer.LoadKnowledgebase(tNewLang, ##class(%iKnow.KB.Knowledgebase).GetByName(tNewLang))
				quit:$$$ISERR(tSC)
				set ..LanguagesInUse(tLangId) = 1
			}
			quit:$$$ISERR(tSC)
			
			// if confidence=0, it means the language was hardcoded and safe to use
			// for the whole source
			quit:tConfidence=0 
			
			// if the language differs from the previous one, we have a multilingual
			// text and cannot hardcode the language for the whole source
			if tPrevLangId && (tPrevLangId'=tLangId) {
				set tMixed = 1
			}
			set tPrevLangId = tLangId
		}
		quit:$$$ISERR(tSC)
		
		set:'tMixed tLang = $li($$$IKLANGUAGES, tLangId)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	do:$$$ISERR(tSC) ..ReportWarning(ref, "Error while deriving language from source domain: " _ $$GetErrorText^%apiOBJ(tSC), "%iKnow.Source.Domain.Processor:GetKnownLanguage")
	quit tLang
}

}
