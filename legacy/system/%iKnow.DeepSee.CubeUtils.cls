/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %DeepSee)

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// This class offers a number of utility options for interacting with DeepSee-managed domains.
Class %iKnow.DeepSee.CubeUtils Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Parameter CHECKSUMFIELDNAME [ Internal ] = "CheckSum";

/// Returns the domain ID for the supplied combination of cube name (<var>pCube</var>) and
/// iKnow measure name (<var>pMeasure</var>).
ClassMethod GetDomainId(pCube As %String, pMeasure As %String, Output pSC As %Status = {$$$OK}) As %Integer [ SqlProc ]
{
	set pSC = $$$OK, tDomId = 0
	try {
		
		// BDB323 - check if there are any cube relationships involved
		while $find(pMeasure,".") {
			set tRelationship = $piece(pMeasure,".",1), pMeasure = $piece(pMeasure,".",2,999)
			set pCube = ##class(%DeepSee.Utils).%GetRelatedCube(pCube, tRelationship)
			if (pCube="") {
				set tSC = $$$ERROR($$$GeneralError, "Cube '"_pCube_"' does not have a relationship '"_tRelationship_"'")
				quit
			}
		}
		quit:$$$ISERR(pSC)
		
		// first check if this is a normal, DeepSee-generated iKnow domain, which
		// should be a single global lookup
		set tDomName = ..GetDeepSeeDomainName(pCube, pMeasure)
		if (##class(%iKnow.Domain).Exists(tDomName)) {
			
			set tDomId = ##class(%iKnow.Domain).Open(tDomName).Id
			
		} else {
			
			// if the default name does not exist, check if this was a manually hooked-up
			// domain in the cube definition based on the measure info
			set pSC = ..GetMeasureInfo(pCube, pMeasure,,.tDomId)
			
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tDomId
}

/// Returns the default generated domain name for a DeepSee-managed domain
ClassMethod GetDeepSeeDomainName(pCube As %String, pMeasure As %String) As %String [ Internal ]
{
	// BDB313: retrieve the base cube name if this is a Subject Area
	set pCube = $$$DeepSeeIndex(pCube)
	
	quit "DeepSee@" _ $$$UPPER(pCube) _ "@" _ $$$UPPER(pMeasure)
}

/// <p>This method will create a DeepSee-managed iKnow domain for storing the indexation 
/// results of an iKnow measure (<var>pMeasure</var>) in a DeepSee cube (<var>pCube</var>).
/// Apart from the default DeepSee-driven parameters, <var>pParams</var> can contain a semicolon-
/// delimited list of additional parameters supplied through the cube definition, but these should
/// be parameters a user is allowed to configure through the <method>SetParameter</method>
/// method in the <class>%iKnow.Domain</class> class.</p>
/// <p>If a domain for this iKnow measure already exists, both the default DeepSee parameters
/// and the user-defined parameters supplied through <var>pParams</var> will be applied,
/// regardless of any existing settings that have been made outside of DeepSee.</p>
/// <p>Warning: this method should never be called by custom code!</p>
ClassMethod CreateDomain(pCube As %String, pMeasure As %String, pParams As %String, pDictionaries As %String, ByRef pDomainName As %String = "", Output pSC As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set pSC = $$$OK, tDomainId = ""
	try {
		set:pDomainName="" pDomainName = ..GetDeepSeeDomainName(pCube, pMeasure)
		
		// BDB384 - DeepSee build flag resolution
		set tBuildFlags = $$$DEFBUILDFLAGS
		if $find(pParams,$$$IKPDSBUILDFLAGS) {
			set tBuildFlags = $p($p(pParams,$$$IKPDSBUILDFLAGS_"::",2),";",1)
		}
		set tBuildFlags = $$$IKBUILDFLAGSFLAGS(tBuildFlags)
		
		set tIsNew = '##class(%iKnow.Domain).NameIndexExists(pDomainName)
		if 'tIsNew {
			
			set tDomain = ##class(%iKnow.Domain).NameIndexOpen(pDomainName)
			if (tDomain="") { set pSC = %objlasterror quit }
			
			// BDB384 - if the build flags changed, the domain needs to be recreated
			if ($$$IKBUILDFLAGSFLAGS(tDomain.BuildFlags) '= tBuildFlags) {
				set pSC = ..DropDomain(pDomainName)
				quit:$$$ISERR(pSC)
				set tIsNew = 1
			}
		}
		
		if (tIsNew) {
			set tDomain = ##class(%iKnow.Domain).%New(pDomainName, tBuildFlags)
			if (tDomain="") { set pSC = %objlasterror quit }	
			set pSC = tDomain.%Save()
			quit:$$$ISERR(pSC)
		}
		set tDomainId = tDomain.Id
		
		// set default DeepSee parameters
		if (tDomain.IsEmpty()) {
			do tDomain.SetParameter($$$IKPSORTFIELD,$$$SORTBYSPREAD)
			do tDomain.SetParameter($$$IKPSIMPLEEXTIDS,1)
			do tDomain.SetParameter($$$IKPMETADATAAPI,"%iKnow.DeepSee.MetadataAPI")
			
			// BDB381 - get rid of DateIndexed field, if it's still around
			set tFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomain.Id, "DateIndexed")
			do:tFieldId ##class(%iKnow.Queries.MetadataAPI).RemoveFieldById(tDomain.Id, tFieldId)
		}
		do tDomain.SetParameter($$$IKPIGNOREEMPTYBATCH,1)
		
		// system parameters not accessible through SetParameter()
		set ^IRIS.IK.Sys.Params(tDomainId, $$$IKPDEEPSEEDOMAIN) = 1
		set ^IRIS.IK.Sys.Params(tDomainId, $$$IKPMANAGEDBY) = $classname()
		set ^IRIS.IK.Sys.Params(tDomainId, $$$IKPDSCUBE) = pCube
		set ^IRIS.IK.Sys.Params(tDomainId, $$$IKPDSMEASURE) = pMeasure
		
		// apply user-defined parameters
		if (pParams'="") {
			set tParamCount = $length(pParams,";")
			for i = 1:1:tParamCount {
				set tParamDef = $piece(pParams,";",i)
				set tParamName = $piece(tParamDef,"::",1)
				set tParamValue = $piece(tParamDef,"::",2)
				
				// BDB384 - this is not a real domain parameter!
				continue:(tParamName=$$$IKPDSBUILDFLAGS)||(tParamName="$$$IKPDSBUILDFLAGS")
			
				set pSC = tDomain.SetParameter(tParamName, tParamValue)
				quit:$$$ISERR(pSC)
			}
			quit:$$$ISERR(pSC)
		}
		
		// create default metadata field if it doesn't exist yet
		set mdfId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomainId, ..#CHECKSUMFIELDNAME)
		set:mdfId<=0 mdfId = ##class(%iKnow.Queries.MetadataAPI).AddField(tDomainId, ..#CHECKSUMFIELDNAME, $lb(), $$$MDDTNUMBER, 0,,,, 1)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	
	// BDB485
	if $$$ISERR(pSC) {
		set tFile = "DeepSeeUpdate"_pCube
		set tMsg = $system.Status.GetOneErrorText(pSC)
		do ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
	}
	
	quit tDomainId
}

/// <p>Notification that our cube has been killed.</p>
/// <p>NOTE: This method is called from generated cube code and should never be invoked by
/// custom code.</p>
ClassMethod %OnKillFacts(pCube As %String, ByRef pMsrList As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tMsr = ""
		for {
			set tMsr = $order(pMsrList(tMsr))
			quit:tMsr=""
		
			set tSC = ..GetMeasureInfo(pCube, tMsr, .tSourceType, .tDomainId, .tDomainName, .tDomainType, .tParams, .tDictionaries)
			continue:'tDomainId
			
			kill $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikDI")
			
			continue:(tDomainType'="DeepSee")
			
			// BDB402 - recreate domain if system version changed
			if ($$$IKVERSION(tDomainId) '= $$$IKCURRENTVERSION) {
				
				set tSC = ..DropDomain(tDomainName)
				quit:$$$ISERR(tSC)
				set tDomainId = ..CreateDomain(pCube, tMsr, tParams, tDictionaries, tDomainName, .tSC)
				quit:$$$ISERR(tSC)
				
			} else {
				
				// if still in the same version, just purge all data
				set dom = ##class(%iKnow.Domain).%OpenId(tDomainId)
				set:$isobject(dom) tSC = dom.DropData(0, 1, 1, 1)
				quit:$$$ISERR(tSC)
				
			}
		}
		
		// clear any existing source-to-fact mappings for iKnow-managed domains
		kill $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcId")
		kill $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcIdReverse")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// BDB485
	if $$$ISERR(tSC) {
		set tFile = "DeepSeeUpdate"_pCube
		set tMsg = $system.Status.GetOneErrorText(tSC)
		do ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
	}
	
	quit tSC
}

///  This method is called when a fact within a DeepSee cube is inserted, updated, or deleted.<br/>
///  <var>pCube</var> is the name of the DeepSee cube.<br/>
///  <var>pBatchMode</var> is true for batch mode.<br/>
///  <var>pFlag</var> is "I" for insert, "U" for update, "D" for delete, and "K" when the entire cube is killed.<br/>
///  <var>pFactId</var> is the ID of the current record in the fact table.<br/>
///  <var>pSourceType</var> is "string","file", or "stream".<br/>
///  <var>pProp</var> is the name of the property.<br/>
///  <var>pValue</var> is the value of the property.<br/>
/// <p>NOTE: This method is called from generated cube code and should never be invoked by
/// custom code.</p>
ClassMethod %ProcessIKnowFact(pCube As %String, pBatchMode As %Boolean, pFlag As %String, pFactId As %String, pMeasure As %String, pValue As %String = "", pSourceType As %String = "string") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tSC = ..GetMeasureInfo(pCube, pMeasure, .tSourceType, .tDomainId, .tDomainName, .tDomainType, .tParams, .tDictionaries)
		quit:$$$ISERR(tSC)
		
		// if the domain ID is empty, this means the domain was not created through 
		// %DeepSee.CubeDefinition.%GetModel() when compiling the cube
		if 'tDomainId {
			set tSC = $$$ERROR($$$GeneralError, "iKnow domain was not created when compiling the cube. Please verify license and recompile cube.")
			quit
		}
		
		$$$IKTEMPDOMID(tDomainId,tTempId)
		
		// for domains of type iKnow, we only have to store the link to the iKnow ExtId/SrcId
		if (tDomainType="iKnow") {
			
			if (pFlag="U") || (pFlag="D") {
				set tOldSrcId = $g($$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcIdReverse", $$$UPPER(pMeasure), pFactId))
				kill:tOldSrcId $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcId", $$$UPPER(pMeasure), tOldSrcId, pFactId)
				kill $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcIdReverse", $$$UPPER(pMeasure), pFactId)
			}
			
			quit:pValue=""
			set tSrcId = ##class(%iKnow.Queries.SourceAPI).GetSourceId(tDomainId, pValue)
			quit:'tSrcId
			
			if (pFlag="U") || (pFlag="I") {
				set $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcId", $$$UPPER(pMeasure), tSrcId, pFactId) = ""
				set $$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcIdReverse", $$$UPPER(pMeasure), pFactId) = tSrcId
			}
			
		} else {
			
			kill ^||%IK.FactValue
			if (tSourceType="string") {
				
				set tCheckSum = $zcrc(pValue,7)
				set pValue = $zstrip(pValue, "<>W")
				set:(pValue'="") ^||%IK.FactValue($i(^||%IK.FactValue)) = pValue
				
			} elseif (tSourceType="file") {
				
				set tFile = ##class(%Stream.FileCharacter).%New()
				set tFile.Filename = pValue
				set tCheckSum = ""
				while 'tFile.AtEnd {
					set tLine = tFile.ReadLine(,.tSC)
					quit:$$$ISERR(tSC)
					continue:tLine=""
					set ^||%IK.FactValue($i(^||%IK.FactValue)) = tLine
					set tCheckSum = $zcrc(tLine, 7, tCheckSum)
				}
				quit:$$$ISERR(tSC)
				
			} elseif (tSourceType="stream") {
				
				// if pValue or tStream is null, this means there's no text contents
				set tStream = ##class(%Stream.Object).%Open(pValue, 0)
				if $isobject(tStream) {
					set tCheckSum = ""
					while 'tStream.AtEnd {
						set tLength = 32000
						set tLine = tStream.Read(.tLength,.tSC)
						quit:$$$ISERR(tSC)
						continue:tLine=""
						set ^||%IK.FactValue($i(^||%IK.FactValue)) = tLine
						set tCheckSum = $zcrc(tLine, 7, tCheckSum)
					}
				}
				quit:$$$ISERR(tSC)
				
			}
			
			// when updating, check if the new string differs from the existing value
			if (pFlag = "U") {
				set tOldCheckSum = +##class(%iKnow.Queries.MetadataAPI).GetValue(tDomainId, ..#CHECKSUMFIELDNAME, pFactId, .tSC)
				
				// we assume checksum collisions between two versions of the same fact are highly unlikely
				quit:(tOldCheckSum=tCheckSum)
			}
				
			if ((pFlag = "U")||(pFlag = "D")) {
				if (pBatchMode) {
					set ^IRIS.Temp.IKDS.DeleteFacts(tTempId, pFactId) = ""
				} else {
					// NOTE: ReplaceSource() will be added at some point!
					set tSC = ##class(%iKnow.Source.Loader).DeleteSource(tDomainId, pFactId)
					quit:$$$ISERR(tSC)
				}
			}

			if ((pFlag = "I")||(pFlag = "U")) && +$g(^||%IK.FactValue) {
				
				merge ^IRIS.Temp.IKDS.NewFacts(tTempId, pFactId) = ^||%IK.FactValue
				set ^IRIS.Temp.IKDS.NewFactsChecksum(tTempId, pFactId) = tCheckSum
				
				if 'pBatchMode {
					
					set tLister = ##class(%iKnow.DeepSee.Lister).%New(tDomainId)
					set tSC = tLister.SetProcessor("%iKnow.Source.Global.Processor", $lb(1,$c(13,10)))
					quit:$$$ISERR(tSC)
					
					set tSC = tLister.ProcessList("")
					quit:$$$ISERR(tSC)
					
					kill ^IRIS.Temp.IKDS.NewFacts(tTempId, pFactId)
					kill ^IRIS.Temp.IKDS.NewFactsChecksum(tTempId, pFactId)
					
					set tSC = ..UpdateMatchingInternal(tDomainId, tDictionaries, pFactId)
					quit:$$$ISERR(tSC)
				}
			}
			
			// BDB791 - update additional indices
			if 'pBatchMode {
				set tSC = ..%SyncAdditionalIndices($$$UPPER(pCube), $$$UPPER(pMeasure), tDomainId, tDomainType, tDictionaries, pFactId, $s(tDomainType="iKnow":tSrcId,1:pFactId), pFlag)
				quit:$$$ISERR(tSC)
			}
		}
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	
	kill ^||%IK.FactValue
	
	// BDB485
	if $$$ISERR(tSC) {
		set tFile = "DeepSeeUpdate"_pCube
		set tMsg = $system.Status.GetOneErrorText(tSC)
		do ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
	}
	
	quit tSC
}

///  Notification at the start of a "batch of updates".
/// <p>NOTE: This method is called from generated cube code and should never be invoked by
/// custom code.</p>
ClassMethod %StartIKnowBatch(pCube As %String, ByRef pMsrList As %String, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tMsr = ""
		for {
			set tMsr = $order(pMsrList(tMsr))
			quit:tMsr=""
			
			// check if domain exists
			set tSC = ..GetMeasureInfo(pCube, tMsr, .tSourceType, .tDomainId, .tDomainName, .tDomainType, .tParams, .tDictList)
			quit:$$$ISERR(tSC)
		
			// if the domain ID is empty, this means the domain was not created through 
			// %DeepSee.CubeDefinition.%GetModel() when compiling the cube
			if 'tDomainId {
				set tSC = $$$ERROR($$$GeneralError, "iKnow domain was not created when compiling the cube. Please verify license and recompile cube.")
				quit
			}
			
			$$$IKTEMPDOMID(tDomainId,tTempId)
			
			// kill temporary global structures
			kill ^IRIS.Temp.IKDS.DeleteFacts(tTempId)
			kill ^IRIS.Temp.IKDS.NewFacts(tTempId)
			kill ^IRIS.Temp.IKDS.NewFactsChecksum(tTempId)
			
			if (tDomainType="iKnow") {
				
				// call $sortbegin() to improve performance building %ikSrcId* indices
				$$$IKSORTBEGIN($$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcId", $$$UPPER(tMsr)))
				$$$IKSORTBEGIN($$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcIdReverse", $$$UPPER(tMsr)))

			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// BDB485
	if $$$ISERR(tSC) {
		set tFile = "DeepSeeUpdate"_pCube
		set tMsg = $system.Status.GetOneErrorText(tSC)
		do ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
	}
	
	quit tSC
}

/// Per-record version of %BuildAdditionalIndices()
ClassMethod %SyncAdditionalIndices(pCube As %String, pMeasure As %String, pDomainId As %Integer, pDomainType As %String, pDictionaries As %String, pFactId As %Integer, pSrcId As %Integer, pFlag As %String) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		$$$IKBITOFFPOS(pFactId,tOffset,tPos)
		
		$$$IKLOCKGX($$$DeepSeeIndexGLVN(pCube, $c(0), pMeasure),tSC)
		
		// first clear old data
		if (pFlag="U") || (pFlag="D") {
			set tDictItemId=""
			for {
				set tDictItemId = $order($$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId))
				quit:tDictItemId=""
				if $d($$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tOffset), tBits) {
					set $bit(tBits,tPos)=0
					if $bitcount(tBits,1) {
						set $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tOffset) = $bitlogic(tBits)
					} else {
						kill $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tOffset)
					}
				}
			}
		}
		
		// then add new
		if (pFlag = "U") || (pFlag = "I") {

			// turn dictionary list into an array
			set tDictList = $s($$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONXDOMAIN):"", 1:..GetDictionaryIds(pDictionaries)), ptr=0
			while $listnext(tDictList,ptr,tDictId) {
				set tDictIds(tDictId) = ""
			}
			
			// find dictids for this record
			merge tMatches = ^IRIS.IK.Mat.SrcToMatch(pDomainId,pSrcId)
			set tMatchId = ""
			for {
				set tMatchId = $order(tMatches(tMatchId))
				quit:tMatchId=""
				
				set tMatchInfo = ^IRIS.IK.Mat.MatchId(pDomainId, tMatchId)
				continue:(tDictList'="")&&'$d(tDictIds(+$lg(tMatchInfo,1)))
				set tDictItemIds(+$lg(tMatchInfo,2))=""
			}
			
			set tDictItemId=""
			for {
				set tDictItemId = $order(tDictItemIds(tDictItemId))
				quit:tDictItemId=""
				set tBits = $g($$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tOffset))
				set $bit(tBits,tPos)=1
				set $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tOffset) = $bitlogic(tBits)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	$$$IKUNLOCKG($$$DeepSeeIndexGLVN(pCube, $c(0), pMeasure))
	quit tSC
}

/// Builds the following additional indices
/// 	- $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, [tDictItemId], [factIdOffset]) = $bitstring([factId])
ClassMethod %BuildAdditionalIndices(pCube As %String, pMeasure As %String, pDomainId As %Integer, pDomainType As %String, pDictionaries As %String = "") As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		set tDictList = $s($$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONXDOMAIN):"", 1:..GetDictionaryIds(pDictionaries))
		
		$$$IKTEMPDOMID(pDomainId,tTempId)
		kill:pDomainType="iKnow" ^IRIS.Temp.IKDS.DictIdToFactId(tTempId)
		
		#dim tQueue as %SYSTEM.WorkMgr
		set tQueue = $system.WorkMgr.Initialize("",.tSC)
		quit:$$$ISERR(tSC)
		set tMaxSrcIdOffset = $order(^IRIS.IK.SrcExistsBit(pDomainId,""),-1)
		for i = 1:1:tMaxSrcIdOffset {
			set tSC = tQueue.Queue("##class(%iKnow.DeepSee.CubeUtils).%BuildAdditionalIndexDIJob",pCube,pMeasure,pDomainId,pDomainType,tDictList,i)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		set tSC = tQueue.Sync()
		quit:$$$ISERR(tSC)
		
		// for iKnow-managed domains, we still need to aggregate results into the bitmap
		if pDomainType="iKnow" {
			
			set tDictItemId = ""
			for {
				set tDictItemId = $order(^IRIS.Temp.IKDS.DictIdToFactId(tTempId,tDictItemId))
				quit:tDictItemId=""
				
				set tFactId="", tPrevOffset=0, tBits=""
				for {
					set tFactId = $order(^IRIS.Temp.IKDS.DictIdToFactId(tTempId,tDictItemId,tFactId))
					quit:tFactId=""
					$$$IKBITOFFPOS(tFactId,tOffset,tPos)
					if (tOffset'=tPrevOffset) {
						set:tPrevOffset $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tPrevOffset) = $bitlogic(tBits)
						set tBits="", tPrevOffset=tOffset
					}
					set $bit(tBits,tPos)=1
				}
				set:tPrevOffset $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, tPrevOffset) = $bitlogic(tBits)
			}
			kill ^IRIS.Temp.IKDS.DictIdToFactId(tTempId)
		}
		 
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %BuildAdditionalIndexDIJob(pCube, pMeasure, pDomainId, pDomainType, pDictIdList, pSrcIdOffset) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(pDomainId,tTempId)
		
		// turn pDictIdList into an array
		set ptr=0
		while $listnext(pDictIdList,ptr,tDictId) {
			set tDictIds(tDictId) = ""
		}
		
		$$$IKGETIDOFFPOS(tStartId,pSrcIdOffset,1)
		$$$IKGETIDOFFPOS(tEndId,(pSrcIdOffset+1),0)
		
		// first preload fact ids
		if (pDomainType="iKnow") {
			set tSrcId = tStartId-1
			for {
				set tSrcId = $order($$$DeepSeeIndexGLVN(pCube,"%ikSrcId",pMeasure,tSrcId))
				quit:tSrcId=""
				quit:tSrcId>tEndId
				set tFactIds(tSrcId) = $order($$$DeepSeeIndexGLVN(pCube,"%ikSrcId",pMeasure,tSrcId,""))
			}
		}
		
		// now go through matches
		set tSrcId = tStartId-1
		for {
			set tSrcId = $order(^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId))
			quit:tSrcId=""
			quit:tSrcId>tEndId
			
			kill tMatches
			merge tMatches = ^IRIS.IK.Mat.SrcToMatch(pDomainId,tSrcId)
			set tMatchId = ""
			for {
				set tMatchId = $order(tMatches(tMatchId))
				quit:tMatchId=""
				
				set tMatchInfo = ^IRIS.IK.Mat.MatchId(pDomainId, tMatchId)
				continue:(pDictIdList'="")&&'$d(tDictIds(+$lg(tMatchInfo,1)))
				set tDictItemId = +$lg(tMatchInfo,2)
				if (pDomainType="iKnow") {
					continue:'$d(tFactIds(tSrcId),tFactId)
					set ^IRIS.Temp.IKDS.DictIdToFactId(tTempId,tDictItemId,tFactId)=""
				} else {
					$$$IKBITOFFPOS(tSrcId,tOffset,tPos)
					set $bit(tBits(tDictItemId),tPos)=1
				}
			}
			kill tMatches
		}
		
		if (pDomainType="DeepSee") {
			set tDictItemId=""
			for {
				set tDictItemId = $order(tBits(tDictItemId),1,tBitstring) 
				quit:tDictItemId=""
				set $$$DeepSeeIndexGLVN(pCube, "%ikDI", pMeasure, tDictItemId, pSrcIdOffset) = $bitlogic(tBitstring)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  This method is called after a large number of facts has been processed in batch mode, to 
///  execute any queued iKnow processing in a single iKnow batch
///  Notification at the end of a "batch of updates".
/// <p>NOTE: This method is called from generated cube code and should never be invoked by
/// custom code.</p>
ClassMethod %EndIKnowBatch(pCube As %String, ByRef pMsrList As %String, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK, tErrorsLogged = 0
	try {
		set tMsr = ""
		for {
			set tMsr = $order(pMsrList(tMsr))
			quit:tMsr=""
			
			set tSC = ..GetMeasureInfo(pCube, tMsr, .tSourceType, .tDomainId, .tDomainName, .tDomainType, .tParams, .tDictionaries)
			quit:$$$ISERR(tSC)
			
			// BDB622 - skip if domain ID is present (ie, when not licensed).
			// 			a warning will have been displayed earlier on
			continue:'tDomainId
			
			$$$IKTEMPDOMID(tDomainId,tTempId)
			
			if (tDomainType="iKnow") {

				set x = $sortend($$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcId", $$$UPPER(tMsr)))
				set x = $sortend($$$DeepSeeIndexGLVN($$$UPPER(pCube), "%ikSrcIdReverse", $$$UPPER(tMsr)))

			} else {
				
				// BDB395 - save tTempId for kill command
				set tKillStaging($i(tKillStaging)) = tTempId
				
				// first treat delete operations
				set tFactId = ""
				for {
					set tFactId = $order(^IRIS.Temp.IKDS.DeleteFacts(tTempId, tFactId))
					quit:tFactId=""
					
					// NOTE: there is no batch delete functionality yet
					set tSC = ##class(%iKnow.Source.Loader).DeleteSource(tDomainId, tFactId)
					quit:$$$ISERR(tSC)
				}
				
				// now load queued entries
				set loader = ##class(%iKnow.Source.Loader).%New(tDomainId)
				set lister = ##class(%iKnow.DeepSee.Lister).%New(tDomainId)
				set tSC = lister.SetProcessor("%iKnow.Source.Global.Processor", $lb(1,""))
				quit:$$$ISERR(tSC)
				set tSC = lister.AddListToBatch("")
				quit:$$$ISERR(tSC)
				set tSC = loader.ProcessBatch()
				if $$$ISERR(tSC) {
					do loader.GetErrors(.tErrors, 0)
					if $d(tErrors(1), tError) {
						
						// BDB485 - log individual errors
						set tFile = "DeepSeeUpdate"_pCube
						set i = ""
						for {
							set i = $order(tErrors(i), 1, tErrorInfo)
							quit:i=""
							set tMsg = $system.Status.GetOneErrorText($lg(tErrorInfo,1))
							do:tMsg'="" ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
						}
						set tErrorsLogged = 1
						
						set tSC = $$$ERROR($$$GeneralError, "Errors processing iKnow measure. Last error message: '"_$lg(tError,1)_"'")
						quit
					}
					do loader.GetFailed(.tErrors, 0)
					if $d(tErrors(1), tError) {
						
						// BDB485 - log individual errors
						set tFile = "DeepSeeUpdate"_pCube
						set i = ""
						for {
							set i = $order(tErrors(i), 1, tErrorInfo)
							quit:i=""
							set tMsg = $system.Status.GetOneErrorText($lg(tErrorInfo,1))
							do:tMsg'="" ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
						}
						set tErrorsLogged = 1
						
						set tSC = $$$ERROR($$$GeneralError, "Errors processing at least one iKnow measure values. Last error message: '"_$lg(tError,4)_"'")
						quit
					}
				}
				quit:$$$ISERR(tSC)
				
				// update (append) and match against dictionaries, if any
				if (tDictionaries'="") {
					
					set tDictCount = $l(tDictionaries,",")
					for i = 1:1:tDictCount {
						set tDictName = $p(tDictionaries,",",i)
						set tSC = ..LoadTermListAsDictionary(pCube, tMsr, tDictName, 0, 0)
						quit:$$$ISERR(tSC)
					}
					
					set tSC = ..UpdateMatchingInternal(tDomainId, tDictionaries)
					quit:$$$ISERR(tSC)
				}
				
				// update Skiplist, if any
				set tSkipList = $$$GETIKPDSSKIPLIST(tDomainId)
				if (tSkipList'="") {
					set tSC = ..LoadTermListAsSkipList(pCube, tMsr, tSkipList)
					quit:$$$ISERR(tSC)
				}
			}
				
			// BDB791 - build additional indices
			set tSC = ..%BuildAdditionalIndices($$$UPPER(pCube), $$$UPPER(tMsr), tDomainId, tDomainType, tDictionaries)
			quit:$$$ISERR(tSC)
			
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
			
	// kill temporary global structures
	for i = 1:1:$g(tKillStaging) {
		set tTempId = tKillStaging(i)
		kill ^IRIS.Temp.IKDS.DeleteFacts(tTempId)
		kill ^IRIS.Temp.IKDS.NewFacts(tTempId)
		kill ^IRIS.Temp.IKDS.NewFactsChecksum(tTempId)
		kill ^IRIS.Temp.IKDS.DictIdToFactId(tTempId)
	}
	
	// BDB485
	if $$$ISERR(tSC) && 'tErrorsLogged {
		set tFile = "DeepSeeUpdate"_pCube
		set tMsg = $system.Status.GetOneErrorText(tSC)
		do ##class(%DeepSee.Utils).%WriteToLog("UPDATE", tMsg, tFile)
	}
	
	quit tSC
}

/// <p>This method creates a new DeepSee Cube definition representing the entities
/// occurring in the textual contents of an iKnow measure <var>pIKnowMeasure</var> in
/// cube <var>pCube</var>. The generated cube will have a set of meaningful dimensions for
/// this <i>entity occurrence</i> level as well as a relationship to <var>pCube</var>, so
/// all of its dimensions are also available for the new cube. The name of this cube will
/// be "<var>pCube</var> &gt; <var>pIKnowMeasure</var> &gt; <i>Entity Occurrences</i>" and
/// can be used or modified just like any other DeepSee cube after creation.</p>
/// <p>Setting <var>pBuild</var> to 1 will automatically build the cube.</p>
/// <p>NOTE: some of the functionality exposed by this cube can be achieved by using the
/// iKnow plugin exposing numerical query results <class>%DeepSee.PlugIn.iKnow</class> as a
/// calculated measure, without the need to create any additional cubes.</p>
ClassMethod CreateEOCube(pCube As %String, pIKnowMeasure As %String, pBuild As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tCubeName = ##class(%DeepSee.Utils).%GetCubeName(pCube)
		set tSC = ..GetMeasureInfo(pCube, pIKnowMeasure, .tSourceType, .tDomainId, .tDomainName, .tDomainType)
		quit:$$$ISERR(tSC)
		if 'tDomainId { set tSC = $$$ERROR($$$GeneralError, "No domain exists for "_tCubeName_"."_pIKnowMeasure)  quit }
		
		set tCubeClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube)
		
		// first create an object class wrapping the EOs for this domain
		set tEOClassName = tCubeClassName_"."_pIKnowMeasure_".EntityOccurrence"
		set tSC = ##class(%iKnow.Utils.GeneratorUtils).GenerateObjectForDomain(tDomainId, "EntityOccurrence", tEOClassName, 1, .errors, tCubeClassName_".cls")
		quit:$$$ISERR(tSC)
		
		// now create the cube definition using %DeepSee.Model classes
		set tEOCubeName = tCubeName_pIKnowMeasure_"EO"
		set tEOCubeClassName = tCubeClassName_"."_pIKnowMeasure_".EOCube"
		set tEOCube = ##class(%DeepSee.Model.cube).%New()
		set tEOCube.name = tEOCubeName
		set tEOCube.description = "Generated cube representing all the matching results for the contents of iKnow measure "_pIKnowMeasure_" in cube "_pCube
		set tEOCube.sourceClass = tEOClassName
		set tEOCube.displayName = ##class(%DeepSee.Utils).%GetCubeCaption(pCube) _ " > " _ pIKnowMeasure _ " > Entity Occurrences"
		set tEOCube.buildRestriction = "EntTypeId IN ("_$$$ENTTYPECONCEPT_","_$$$ENTTYPERELATION_")"
		
		// entity dimension
		set tEUDim = ##class(%DeepSee.Model.dimension).%New()
		set tEUDim.name = "EntityValueDim"
		set tEUDim.displayName = "Entity Value"
		set tEUDim.type = "computed"
		set tEUDim.hasAll = 1
		set tEUDim.allDisplayName = "All entities"
		set tEUDim.dimensionClass = "%iKnow.DeepSee.Dimensions.EntitiesEO"
		set tEUHier = ##class(%DeepSee.Model.hierarchy).%New()
		set tEUHier.name = "H1"
		set tEULevel = ##class(%DeepSee.Model.level).%New()
		set tEULevel.name = "EntityValue"
		set tEULevel.displayName = "Entity Value"
		set tEULevel.sourceExpression = tDomainId
		//set tEULevel.sourceProperty = "Entity.EntityValue"
		do tEUHier.levels.Insert(tEULevel)
		do tEUDim.hierarchies.Insert(tEUHier)
		do tEOCube.dimensions.Insert(tEUDim)
		
		// entity role dimension
		set tRoleDim = ##class(%DeepSee.Model.dimension).%New()
		set tRoleDim.name = "RoleDim"
		set tRoleDim.displayName = "Role"
		set tRoleDim.hasAll = 1
		set tRoleDim.allDisplayName = "All roles"
		set tRoleHier = ##class(%DeepSee.Model.hierarchy).%New()
		set tRoleHier.name = "H1"
		set tRoleLevel = ##class(%DeepSee.Model.level).%New()
		set tRoleLevel.name = "Role"
		set tRoleLevel.rangeExpression = "0:concept;1:relation;"
		set tRoleLevel.sourceProperty = "EntTypeId"
		do tRoleHier.levels.Insert(tRoleLevel)
		do tRoleDim.hierarchies.Insert(tRoleHier)
		do tEOCube.dimensions.Insert(tRoleDim)
		
		// relationship to other cube
		set tRelationship = ##class(%DeepSee.Model.relationship).%New()
		set tRelationship.name = "source"
		set tRelationship.displayName = "Main cube"
		set tRelationship.relatedCube = pCube
		set tRelationship.cardinality = "one"
		set tRelationship.sourceExpression = "##class("_tEOCubeClassName_").GetSourceId(%source.EntOccId)"
		do tEOCube.relationships.Insert(tRelationship)
		
		// listing
		set tListing = ##class(%DeepSee.Model.listing).%New()
		set tListing.name = "DefaultListing"
		set tListing.fieldList = "EntOccId As OccurrenceId, CASE EntTypeId WHEN "_$$$ENTTYPECONCEPT_" THEN 'concept' WHEN "_$$$ENTTYPERELATION_" THEN 'relation' ELSE 'other' END AS EntityRole, Entity->EntityValue, Sentence->Source->ExternalId, Sentence->SentenceValue"
		do tEOCube.listings.Insert(tListing)
		set tEOCube.defaultListing = "DefaultListing"
		
		// write the cube definition to a class
		set tSC = ##class(%DeepSee.Utils).%SaveCubeDefinition(tEOCubeClassName,,"Entity Occurrence cube for iKnow measure "_tCubeName_"."_pIKnowMeasure, tEOCube)
		quit:$$$ISERR(tSC)
		
		// add a GetSourceId() method
		set tEOCubeClass = ##class(%Dictionary.ClassDefinition).%OpenId(tEOCubeClassName)
		do ##class(%Dictionary.MethodDefinition).%DeleteId(tEOCubeClassName_"||GetSourceId")
		set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		set tMethod.Name = "GetSourceId"
		set tMethod.ClassMethod = 1
		set tMethod.ReturnType = "%Integer"
		set tMethod.FormalSpec = "pEntOccId:%Integer"
		do tMethod.Implementation.WriteLine("	set tFactId = ##class("_tEOClassName_").PKINDEXOpen(pEntOccId).Sentence.Source.SourceId")
		do:tDomainType="iKnow" tMethod.Implementation.WriteLine("	set tFactId = $g($$$DeepSeeIndexGLVN("""_$$$UPPER(pCube)_""", ""%ikSrcIdReverse"", """_$$$UPPER(pIKnowMeasure)_""", tFactId))")
		do tMethod.Implementation.WriteLine("	quit ##class(%iKnow.DeepSee.CubeUtils).GetSourceObjectId("""_pCube_""",tFactId)")
		do tEOCubeClass.Methods.Insert(tMethod)
		do tEOCubeClass.%Save()
		set tEOCubeClass = ""
		
		// compile and build
		set tSC = $SYSTEM.OBJ.Compile(tEOCubeClassName, "crkf", .compileErrors)
		quit:$$$ISERR(tSC)
		
		if (pBuild) {
			set tSC = ##class(%DeepSee.Utils).%BuildCube(tEOCubeName)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This method creates a new DeepSee Cube definition representing the matching results
/// occurring in the textual contents of an iKnow measure <var>pIKnowMeasure</var> in
/// cube <var>pCube</var>. The generated cube will have a set of meaningful dimensions for
/// this <i>dictionary match</i> level as well as a relationship to <var>pCube</var>, so
/// all of its dimensions are also available for the new cube. The name of this cube will
/// be "<var>pCube</var> &gt; <var>pIKnowMeasure</var> &gt; <i>Matching Results</i>" and
/// can be used or modified just like any other DeepSee cube after creation.</p>
/// <p>Setting <var>pBuild</var> to 1 will automatically build the cube.</p>
/// <p>NOTE: most of the functionality exposed by this cube can be achieved by using the
/// iKnow plugin for Dictionaries <class>%DeepSee.PlugIn.iKnowDictionary</class> as a
/// calculated measure, without the need to create any additional cubes.</p>
ClassMethod CreateMRCube(pCube As %String, pIKnowMeasure As %String, pBuild As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tCubeName = ##class(%DeepSee.Utils).%GetCubeName(pCube)
		set tSC = ..GetMeasureInfo(pCube, pIKnowMeasure, .tSourceType, .tDomainId, .tDomainName, .tDomainType)
		quit:$$$ISERR(tSC)
		if 'tDomainId { set tSC = $$$ERROR($$$GeneralError, "No domain exists for "_tCubeName_"."_pIKnowMeasure)  quit }
		
		set tCubeClassName = ##class(%DeepSee.Utils).%GetCubeClass(pCube)
		
		// first create an object class wrapping the matches for this domain
		set tMRClassName = tCubeClassName_"."_pIKnowMeasure_".MatchingResults"
		set tSC = ##class(%iKnow.Utils.GeneratorUtils).GenerateObjectForDomain(tDomainId, "DictionaryMatch", tMRClassName, 1, .errors, tCubeClassName_".cls")
		quit:$$$ISERR(tSC)
		
		// now create the cube definition using %DeepSee.Model classes
		set tMRCubeName = tCubeName_pIKnowMeasure_"MR"
		set tMRCubeClassName = tCubeClassName_"."_pIKnowMeasure_".MRCube"
		set tMRCube = ##class(%DeepSee.Model.cube).%New()
		set tMRCube.name = tMRCubeName
		set tMRCube.description = "Generated cube representing all the matching results for the contents of iKnow measure "_pIKnowMeasure_" in cube "_pCube
		set tMRCube.sourceClass = tMRClassName
		set tMRCube.displayName = ##class(%DeepSee.Utils).%GetCubeCaption(pCube) _ " > " _ pIKnowMeasure _ " > Dictionary Matches"
		
		// score measure
		set tScoreMsr = ##class(%DeepSee.Model.measure).%New()
		set tScoreMsr.name = "Score"
		set tScoreMsr.description = "Total match score"
		set tScoreMsr.aggregate = "SUM"
		set tScoreMsr.sourceProperty = "MatchScore"
		do tMRCube.measures.Insert(tScoreMsr)
		
		// dictionary dimension
		set tDictDim = ##class(%DeepSee.Model.dimension).%New()
		set tDictDim.name = "DictionaryDim"
		set tDictDim.description = "Information about the Dictionary (Term List) item matched"
		set tDictDim.displayName = "Dictionary"
		set tDictDim.hasAll = 1
		set tDictDim.allDisplayName = "All dictionaries"
		set tDictHier = ##class(%DeepSee.Model.hierarchy).%New()
		set tDictHier.name = "H1"
		set tDictLevel = ##class(%DeepSee.Model.level).%New()
		set tDictLevel.name = "Dictionary"
		set tDictLevel.description = "Dictionary (Term List name) of the matched item"
		set tDictLevel.sourceProperty = "Dictionary.Name"
		do tDictHier.levels.Insert(tDictLevel)
		set tDictItemLevel = ##class(%DeepSee.Model.level).%New()
		set tDictItemLevel.name = "Dictionary Item"
		set tDictItemLevel.description = "Dictionary Item (Term List value) of the matched item"
		set tDictItemLevel.sourceProperty = "DictionaryItem.Name"
		do tDictHier.levels.Insert(tDictItemLevel)
		do tDictDim.hierarchies.Insert(tDictHier)
		do tMRCube.dimensions.Insert(tDictDim)
		
		// target type dimension
		set tTypeDim = ##class(%DeepSee.Model.dimension).%New()
		set tTypeDim.name = "TypeDim"
		set tTypeDim.description = "The type of element matched"
		set tTypeDim.displayName = "Type"
		set tTypeDim.hasAll = 1
		set tTypeDim.allDisplayName = "All types"
		set tTypeHier = ##class(%DeepSee.Model.hierarchy).%New()
		set tTypeHier.name = "H1"
		set tTypeLevel = ##class(%DeepSee.Model.level).%New()
		set tTypeLevel.name = "TargetType"
		set tTypeLevel.displayName = "Target Type"
		set tTypeLevel.sourceProperty = "TargetType"
		set tTypeLevel.rangeExpression = "[0,0]:entity;[1,1]:CRC;[2,2]:path;[3,3]:sentence;"
		do tTypeHier.levels.Insert(tTypeLevel)
		do tTypeDim.hierarchies.Insert(tTypeHier)
		do tMRCube.dimensions.Insert(tTypeDim)
		
		// relationship to other cube
		set tRelationship = ##class(%DeepSee.Model.relationship).%New()
		set tRelationship.name = "source"
		set tRelationship.displayName = "Main cube"
		set tRelationship.relatedCube = pCube
		set tRelationship.cardinality = "one"
		set tRelationship.sourceExpression = "##class("_tMRCubeClassName_").GetSourceId(%source.DictionaryMatchId)"
		do tMRCube.relationships.Insert(tRelationship)
		
		// default listing
		set tListing = ##class(%DeepSee.Model.listing).%New()
		set tListing.name = "default"
		set tListing.fieldList = "DictionaryMatchId, DictionaryItem->Name As Item, DictionaryItem->URI As URI, MatchScore, Sentence->SentenceValue As Sentence"
		do tMRCube.listings.Insert(tListing)
		set tMRCube.defaultListing = "default"
		
		// write the cube definition to a class
		set tSC = ##class(%DeepSee.Utils).%SaveCubeDefinition(tMRCubeClassName,,"Dictionary Match cube for iKnow measure "_tCubeName_"."_pIKnowMeasure, tMRCube)
		quit:$$$ISERR(tSC)
		
		// add a GetSourceId() method
		set tMRCubeClass = ##class(%Dictionary.ClassDefinition).%OpenId(tMRCubeClassName)
		do ##class(%Dictionary.MethodDefinition).%DeleteId(tMRCubeClassName_"||GetSourceId")
		set tMethod = ##class(%Dictionary.MethodDefinition).%New()
		set tMethod.Name = "GetSourceId"
		set tMethod.ClassMethod = 1
		set tMethod.ReturnType = "%Integer"
		set tMethod.FormalSpec = "pMatchId:%Integer"
		do tMethod.Implementation.WriteLine("	set tFactId = ##class("_tMRClassName_").PKINDEXOpen(pMatchId).Sentence.Source.SourceId")
		do:tDomainType="iKnow" tMethod.Implementation.WriteLine("	set tFactId = $g($$$DeepSeeIndexGLVN("""_$$$UPPER(pCube)_""", ""%ikSrcIdReverse"", """_$$$UPPER(pIKnowMeasure)_""", tFactId))")
		do tMethod.Implementation.WriteLine("	quit ##class(%iKnow.DeepSee.CubeUtils).GetSourceObjectId("""_pCube_""",tFactId)")
		do tMRCubeClass.Methods.Insert(tMethod)
		do tMRCubeClass.%Save()
		set tMRCubeClass = ""
		
		// compile and build
		set tSC = $SYSTEM.OBJ.Compile(tMRCubeClassName, "crkf", .compileErrors)
		quit:$$$ISERR(tSC)
		
		if (pBuild) {
			set tSC = ##class(%DeepSee.Utils).%BuildCube(tMRCubeName)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This method will update matching results for the Term List identified by <var>pTermList</var>
/// to reflect the changes made to the Term List entries. If <var>pCube</var> is left blank,
/// this method will be invoked for all cubes in this namespace. If <var>pMeasure</var> is
/// left blank, it will be called for all <i>iKnow measures</i> in <var>pCube</var>.</p>
/// <p>Using <var>pClearFirst</var>, the user can specify whether or not the existing
/// dictionary should first be dropped before reloading it from the Term List. Leave 
/// <var>pClearFirst</var> at 0 if you only appended to the Term List and use 1 if any
/// existing terms were changed or removed.</p>
ClassMethod UpdateDictionary(pTermList As %String, pCube As %String = "", pMeasure As %String = "", pClearFirst As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		if '##class(%DeepSee.TermList).%TermListExists(pTermList, .tSC) {
			set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError, "Term List '"_pTermList_"' does not exist")
			quit
		}
		
		// BDB387 - if there is a cross-domain dictionary for this Term List, update it
		// (this should always be the case as from 2013.2)
		set tXDictName = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetDictionaryName(pTermList)
		set tXDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(0, tXDictName)
		if (tXDictId>0) {
			set tSC = ..LoadTermListAsDictionary(pCube, pMeasure, pTermList, 1, pClearFirst)
			quit
		}
		
		if (pCube="") {
			
			// if no cube is defined, invoke again for all cubes 
			set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tCubes, "cubes", 1)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tCubes(i),1,tCube)
				quit:i=""
				set tSC = ..UpdateDictionary(pTermList, $li(tCube,1), pMeasure, pClearFirst)
				quit:$$$ISERR(tSC)
			}
			quit
			
		}
		
		quit:'##class(%DeepSee.Utils).%CubeExists(pCube,.tSC)
		
		if (pMeasure="") {
			
			// if no measure is defined, invoke again for all cubes 
			set tSC = ..GetIKnowMeasures(pCube,.tMeasures)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tMeasures(i),1,tMeasure)
				quit:i=""
				continue:$li(tMeasure,2)="domain"
				set tSC = ..UpdateDictionary(pTermList, pCube, $li(tMeasure,1), pClearFirst)
				quit:$$$ISERR(tSC)
			}
			quit
			
		}
		
		// first check if it's in the list of dictionaries
		set tSC = ..GetMeasureInfo(pCube, pMeasure,,,, .tDomainType,, .tDictionaries)
		quit:$$$ISERR(tSC)
		quit:tDomainType'="DeepSee"
		
		quit:'$find(","_$$$UPPER(tDictionaries)_",", ","_$$$UPPER(pTermList)_",")
		
		set tSC = ..LoadTermListAsDictionary(pCube, pMeasure, pTermList, 1, pClearFirst)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  <p>Loads the elements of a TermList as Dictionary Terms into a given iKnow measures domain,
///  taking the key as the Term string and value as the items name. The Terms will all be added
///  to a single dictionary named after this TermList.<br/>
///  The following fields will be interpreted along the way, if present:</p>
///  <ul>
///  		<li>"URI": the unique identifier for the Item level the value field refers to.
///  				If not present, a URI of the form :<var>pTermList</var>:<i>value</i> will be created.</li>
///  		<li>"language": the two-letter language code to use for this term.
///  				Defaults to English ("en") if not present. </li>
///  </ul>
///  <p>If <var>pMatch</var> is 1, the newly created dictionary will be matched against the
///  contents of the domain. If set to 2, all existing dictionaries will be matched and if 
///  set to 0, no matching will occur as part of this method invocation.</p>
///  <p>If <var>pClear</var> is 1, any existing dictionary named <var>pTermList</var> will be
///  deleted prior to loading this Term List. If set to 0, none will be dropped. The option
///  to clear all dictionaries using the value 2 is discontinued as from 2013.2.</p>
ClassMethod LoadTermListAsDictionary(pCube As %String, pMeasure As %String, pTermList As %String, pMatch As %Integer = 1, pClear As %Integer = 1) As %Status
{
	set tSC = $$$OK
	try {
		if '##class(%DeepSee.TermList).%TermListExists(pTermList, .tSC) {
			set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError, "Term List '"_pTermList_"' does not exist")
			quit
		}
		
		// BDB427 - if this refers to a specific iKnow measure, get its domain ID first
		if (pCube'="") && (pMeasure'="") {
			set tDomainId = ..GetDomainId(pCube, pMeasure, .tSC)
			quit:$$$ISERR(tSC)
		
			if $$$IKVERSIONATLEAST(tDomainId,$$$IKVERSIONXDOMAIN) {
				set tDictDomainId = 0, tDictName = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetDictionaryName(pTermList)
			} else {
				set tDictDomainId = tDomainId, tDictName = pTermList
			}
		} else {
			
			// if not, treat this as a cross-domain dictionary
			set tDictName = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetDictionaryName(pTermList)
			set tDictDomainId = 0, tDomainId = 0
			
		}
		
		if (pClear=1) {
			set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDictDomainId, tDictName)
			do:tDictId ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(tDictDomainId, tDictId)
		} elseif (pClear=2) {
			if (tDictDomainId) {
				do ##class(%iKnow.Matching.DictionaryAPI).DropAllDictionaryData(tDictDomainId)
			} else {
				set tSC = $$$ERROR($$$InvalidArgument)
				quit
			}
		}
		
		// get the dict ID and default language for this TL
		set tTL = $$$UPPER(pTermList)
		set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDictDomainId, tDictName)
		
		// BDB518 - default language resolution
		set tDefaultConfig = $$$GETPARAM(tDomainId,$$$IKPDEFAULTCONFIG,$$$DEFAULTCONFIG)
		if ##class(%iKnow.Configuration).NameIndexExists(tDefaultConfig) {
			set tDefaultLang = $lg(##class(%iKnow.Configuration).NameIndexOpen(tDefaultConfig).Languages,1,"en")
		} else {
			set tDefaultLang = "en"
		}
		set tDefaultLang = $g(^DeepSee.TermList(tTL,"language"),tDefaultLang) // TODO: new TL attribute?
		
		set:'tDictId tDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryInternal(tDictDomainId, tDictName, $g(^DeepSee.TermList(tTL,"description")), tDefaultLang,, $classname(), .tSC)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%DeepSee.TermList).%GetValueArray(pTermList, .tTerms)
		quit:$$$ISERR(tSC)
		set tSC = ##class(%DeepSee.TermList).%GetValueArray(pTermList, .tURIs, "URI")
		quit:$$$ISERR(tSC)
		set tSC = ##class(%DeepSee.TermList).%GetValueArray(pTermList, .tLanguages, "language")
		quit:$$$ISERR(tSC)
		
		set tTerm=""
		for {
			set tTerm = $order(tTerms(tTerm),1,tItem)
			quit:tTerm=""
			
			// first find the language and URI
			set tLang = $g(tLanguages(tTerm)), tLang = $s(tLang="":tDefaultLang, 1:tLang)
			set tURI = $g(tURIs(tTerm)), tURI = $s(tURI="":":"_pTermList_":"_tItem, 1:tURI)
			set tURI = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetDictionaryItemURI(tURI)
			
			// now find the item ID
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(tDictDomainId, tURI)
			set:'tItemId tItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(tDictDomainId, tDictId, tItem, tURI,, .tSC)
			quit:$$$ISERR(tSC)
			
			// and add the term
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(tDictDomainId, tItemId, tTerm, tLang, .tSC)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		
		// match if requested
		if pMatch {
			
			// if no cross-domain dictionaries are involved, just match tDomain
			if (tDictDomainId) {
				set tDicts = $case(pMatch, 1:$lb(tDictId), 2:"")
				set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tDomainId,,tDicts)
				quit:$$$ISERR(tSC)
				
			// if a specific domain is provided, just match tDomain
			} elseif (tDomainId) {
				set:pMatch=2 tSC = ..GetMeasureInfoInternal(pCube, pMeasure,,,,,,.tDictionaries)
				quit:$$$ISERR(tSC)
				set tDicts = $case(pMatch, 1:$lb(-tDictId), 2:..GetDictionaryIds(tDictionaries))
				set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tDomainId,,tDicts)
				quit:$$$ISERR(tSC)
				
			// if not, we'll have to find all iKnow measures referring this dictionary
			} else {
				
				set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tCubes, "cubes", 1)
				quit:$$$ISERR(tSC)
				set i = ""
				for {
					set i = $order(tCubes(i),1,tCube)
					quit:i=""
					
					set tCubeName = $li(tCube,1)
					set tSC = ..GetIKnowMeasures(tCubeName, .tMeasures)
					quit:$$$ISERR(tSC)
					set j = ""
					for {
						set j = $order(tMeasures(j), 1, tMeasure)
						quit:j=""
						continue:$li(tMeasure,2)="domain"
						
						set tSC = ..GetMeasureInfo(tCubeName, $li(tMeasure,1),, .tDomainId,,,, .tDictList)
						quit:$$$ISERR(tSC)
						
						set tDictIds = ..GetDictionaryIds(tDictList)
						continue:'$lf(tDictIds,-tDictId)
						
						set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tDomainId,,$case(pMatch, 1:$lb(-tDictId), 2:tDictIds))
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
				
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  <p>Loads the elements of a Term List as a SkipList into a given iKnow measures domain,
///  using just the key as a string to be Skiplisted. The Terms will all be added
///  to a single Skiplist named after this Term List.<br/>
///  If a SkipList with the given name already exists, its contents will be replaced by the
///  contents of the supplied Term List. If no value is supplied for <var>pTermList</var>,
///  its value will be derived from the value of the domain parameter $$$IKPDSSKIPLIST.</p>
ClassMethod LoadTermListAsSkipList(pCube As %String, pMeasure As %String, pTermList As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		if '##class(%DeepSee.TermList).%TermListExists(pTermList, .tSC) {
			set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError, "Term List '"_pTermList_"' does not exist")
			quit
		}
		
		set tDomainId = ..GetDomainId(pCube, pMeasure, .tSC)
		quit:$$$ISERR(tSC)
		
		set:pTermList="" pTermList=$$$GETIKPDSSKIPLIST(tDomainId)
		quit:pTermList=""
		
		// BDB387 - store as a cross-domain Skiplist
		if $$$IKVERSIONATLEAST(tDomainId,$$$IKVERSIONXDOMAIN) {
			set tDomainId = 0
		}
		
		if '##class(%DeepSee.TermList).%TermListExists(pTermList, .tSC) {
			set:$$$ISOK(tSC) tSC = $$$ERROR($$$GeneralError, "Term List '"_pTermList_"' does not exist")
			quit
		}
		set tTL = $$$UPPER(pTermList)
		
		// get the Skiplist ID for this TL
		set tBL = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(tDomainId, pTermList)
		set:'tBL tBL = ##class(%iKnow.Utils.MaintenanceAPI).CreateSkipListInternal(tDomainId, pTermList, $g(^DeepSee.TermList(tTL,"description")), $classname(), .tSC)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).ClearSkipList(tDomainId, tBL)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%DeepSee.TermList).%GetValueArray(pTermList, .tTerms)
		quit:$$$ISERR(tSC)
		
		set tTerm=""
		for {
			set tTerm = $order(tTerms(tTerm))
			quit:tTerm=""
			
			set tSC = ##class(%iKnow.Utils.MaintenanceAPI).AddStringToSkipList(tDomainId, tBL, tTerm)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod LoadTermListAsBlackList(pCube As %String, pMeasure As %String, pTermList As %String = "") As %Status [ Deprecated, Internal ]
{
	quit ..LoadTermListAsSkipList(pCube, pMeasure, pTermList)
}

///  Returns all iKnow Measures for cube <var>pCube</var> in the form
///  		pList(n) = $lb(measureName, iKnowSourceType, cubeCaption)
ClassMethod GetIKnowMeasures(pCube As %String, Output pList, pIncludeRelatedToOne As %Boolean = 0, pIncludeRelatedToMany As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		kill pList
		
		quit:'##class(%DeepSee.Utils).%CubeExists(pCube,.tSC)
		
		set pCube = $$$UPPER(pCube)
		
		set i = ""
		for {
			set i = $order($$$DeepSeeMetaGLVN("cubes", pCube, "mbr#", 0, i))
			quit:i=""
			
			set tMeasure = $g($$$DeepSeeMetaGLVN("cubes", pCube, "mbr#", 0, i, 0))
			continue:tMeasure=""
			continue:$lg(tMeasure,1)'="m"
			continue:$lg(tMeasure,8)'="iKnow"
			
			do ..GetMeasureInfo(pCube, $li(tMeasure,3), .tSourceType)
			
			set pList($i(pList)) = $lb($li(tMeasure,3),tSourceType, ##class(%DeepSee.Utils).%GetCubeCaption(pCube))
		}
		
		// BDB323 - now find all related cubes
		quit:'pIncludeRelatedToMany&&'pIncludeRelatedToOne
		kill tRelated,tDone
		set tRelated(pCube) = "", tFoundMore=1
		while tFoundMore {
			set tFoundMore = 0
			
			set tCube = ""
			for {
				set tCube = $order(tRelated(tCube),1,tRelation)
				quit:tCube=""
				continue:$d(tDone(tCube))
				
				set tRelName = ""
				for {
					set tRelName = $order($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelName))
					quit:tRelName=""
					
					set tCardinality = $$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelName,"cardinality")
					continue:'pIncludeRelatedToMany&&(tCardinality="many")
					continue:'pIncludeRelatedToOne&&(tCardinality="one")
					
					set tRelCube = $$$UPPER($$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelName,"relatedCube"))
					continue:$d(tRelated(tRelCube))
					
					set tRelated(tRelCube)=tRelation_$$$DeepSeeMetaGLVN("cubes",tCube,"relations",tRelName,"name")_"."
					set tFoundMore=1
				}
				set tDone(tCube)=1
			}
		}
		
		// Now add all iKnow measures for each of them
		kill tRelated(pCube)
		set tCube = ""
		for {
			set tCube = $order(tRelated(tCube),1,tRelation)
			quit:tCube=""
			
			set i = ""
			for {
				set i = $order($$$DeepSeeMetaGLVN("cubes", tCube, "mbr#", 0, i))
				quit:i=""
				
				set tMeasure = $g($$$DeepSeeMetaGLVN("cubes", tCube, "mbr#", 0, i, 0))
				continue:tMeasure=""
				continue:$lg(tMeasure,1)'="m"
				continue:$lg(tMeasure,8)'="iKnow"
				
				do ..GetMeasureInfo(tCube, $li(tMeasure,3), .tSourceType)
				
				set pList($i(pList)) = $lb(tRelation_$li(tMeasure,3),tSourceType, ##class(%DeepSee.Utils).%GetCubeCaption(tCube))
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Shorthand method to retrieve a summary of the iKnow measure value for <var>pMeasure</var>
/// in cube <var>pCube</var> for the record identified by <var>pSourceObjectId</var>. Using
/// <var>pLength</var>, the user can supply a desired summary length (in sentences).</p>
/// <p>This method is available as a SQL stored procedure and can be invoked in a Listing
/// through using the $$$IKSUMMARY keyword.</p>
ClassMethod GetSummary(pCube As %String, pMeasure As %String, pSourceObjectId As %String, pLength As %Integer = 5) As %String [ SqlProc ]
{
	set tSummary = "", tSC = $$$OK
	try {
		if ($g(pMeasure)="") || (pMeasure=$c(0)) {
			set tSC = ..GetIKnowMeasures(pCube, .tMeasures)
			quit:$$$ISERR(tSC)
			set pMeasure = $lg($g(tMeasures(1)),1)
		}
		
		set tSC = ..GetMeasureInfo(pCube, pMeasure, .tSourceType, .tDomainId, .tDomainName, .tDomainType)
		quit:$$$ISERR(tSC)
		
		set tFactId = ..GetFactId(pCube, pSourceObjectId, $piece(pMeasure,".",1,$l(pMeasure,".")-1), .tSC)
		quit:$$$ISERR(tSC)
		
		// BDB313 - make sure to look at a base cube (rather than a subject area)
		set tBaseCube = $$$DeepSeeIndex(pCube)
		
		set tSrcId = $s(tDomainType="DeepSee":tFactId, 1:$g($$$DeepSeeIndexGLVN(tBaseCube,"%ikSrcIdReverse",$$$UPPER(pMeasure),tFactId)))
		set tSummary = ##class(%iKnow.Queries.SourceAPI).GetSummaryDirect(tDomainId, tSrcId, pLength)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit:$$$ISERR(tSC) $$GetErrorText^%apiOBJ(tSC)
	quit tSummary
}

///  This method translates the source objects OID into the corresponding Fact ID, which is
///  identical to the iKnow source ID for a DeepSee-managed domain.
ClassMethod GetFactId(pCube As %String, pSourceObjectId As %String, pRelations As %String = "", pSC As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set tFactId = 0, pSC = $$$OK
	try {
		// BDB313 - make sure to look at a base cube (rather than a subject area)
		set tBaseCube = $$$DeepSeeIndex(pCube)
	
		set tFactId = $o($$$DeepSeeIndexGLVN(tBaseCube, "%sourceId", pSourceObjectId, ""))
		
		// BDB323 - treat any cube relationships involved to resolve the fact ID
		while $find(pRelations,".") {
			set tRelationship = $piece(pRelations,".",1), pRelations = $piece(pRelations,".",2,999)
			set tRelFact = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"relations",$$$UPPER(tRelationship),"fact")
			
			// we cannot do this for to-many relationships!
			if ($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"relations",$$$UPPER(tRelationship),"cardinality")="many") {
				set pSC = $$$ERROR($$$GeneralError, "Cannot get a summary for a to-Many relationship")
				quit
			}
			set tFactId = $order($$$DeepSeeRelationGLVN($$$UPPER(pCube),$$$UPPER(tRelFact),tFactId,""))
			set pCube = ##class(%DeepSee.Utils).%GetRelatedCube(pCube, tRelationship)
		}
		quit:$$$ISERR(pSC)
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit $s($$$ISERR(pSC):0, 1:tFactId)
}

///  This method translates a fact ID (= iKnow source ID in a DeepSee-managed domain)
/// into the corresponding source object OID.
ClassMethod GetSourceObjectId(pCube As %String, pFactId As %Integer) As %Integer [ Internal ]
{
	// BDB313 - make sure to look at a base cube (rather than a subject area)
	set tBaseCube = $$$DeepSeeIndex(pCube)
	
	quit $g($$$DeepSeeIndexGLVN(tBaseCube, "%sourceIdReverse", pFactId))
}

///  <p>Fetches measure info from the cube definition:</p>
///  <ul>
///  		<li>pSourceType: the value of the iKnowSource attribute</li>
///  		<li>pDomainId: the iKnow domain (ID) containing the data for this measure</li>
///  		<li>pDomainName: the iKnow domain (name) containing the data for this measure</li>
///  		<li>pDomainType: "iKnow" for an iKnow-managed domain, "DeepSee" for a DeepSee-managed one</li>
///  		<li>pParams: the semicolon-delimited list of domain parameter name/value pairs
/// 					 to use apply to the domain instantiated for this measure</li>
///  		<li>pDictionaries: the comma-delimited list of Term Lists to match against.</li>
///  </ul>
ClassMethod GetMeasureInfo(pCube As %String, pMeasure As %String, Output pSourceType As %String = "", Output pDomainId As %Integer = "", Output pDomainName As %Integer = "", Output pDomainType As %String = "", Output pParams As %String = "", Output pDictionaries As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		
		quit:'##class(%DeepSee.Utils).%CubeExists(pCube,.tSC)
		
		// BDB323 - check if there are any cube relationships involved
		while $find(pMeasure,".") {
			set tRelationship = $piece(pMeasure,".",1), pMeasure = $piece(pMeasure,".",2,999)
			set pCube = ##class(%DeepSee.Utils).%GetRelatedCube(pCube, tRelationship)
			if (pCube="") {
				set tSC = $$$ERROR($$$GeneralError, "Cube '"_pCube_"' does not have a relationship '"_tRelationship_"'")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ..GetMeasureInfoInternal(pCube, pMeasure, .pSourceType, .pDomainId, .pDomainName, .pDomainType, .pParams, .pDictionaries)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetMeasureInfoInternal(pCube As %String, pMeasure As %String, Output pSourceType As %String = "", Output pDomainId As %Integer = "", Output pDomainName As %Integer = "", Output pDomainType As %String = "", Output pParams As %String = "", Output pDictionaries As %String = "") As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		set dimInfo = $g($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"mbrs","MEASURES",$$$UPPER(pMeasure)))
		if (dimInfo="") {
			set tSC = $$$ERROR($$$GeneralError, "Cube '"_pCube_"' does not have a measure '"_pMeasure_"'")
			quit
		}
		
		set msrInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"mbr#",$li(dimInfo,1),$li(dimInfo,2),$li(dimInfo,3))
		if ($lg(msrInfo,8)'="iKnow") {
			set tSC = $$$ERROR($$$GeneralError, "Measure '"_pMeasure_"' in cube '"_pCube_"' is not an iKnow measure")
			quit
		}
		
		set factNo = $lg(msrInfo,5)
		set msrPropName = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"msr#",factNo)
		set indexInfo = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube),"fact","prop",msrPropName,"index")
		
		set pSourceType = $piece(indexInfo,":",2)
		set pDomainName = $piece(indexInfo,":",3)
		if (pDomainName="") {
			set pDomainName = ..GetDeepSeeDomainName(pCube, pMeasure)
			set:##class(%iKnow.Domain).Exists(pDomainName) pDomainId = ##class(%iKnow.Domain).Open(pDomainName).Id
		} elseif (##class(%iKnow.Domain).Exists(pDomainName)) {
			set tDomain = ##class(%iKnow.Domain).Open(pDomainName, .tSC)
			quit:$$$ISERR(tSC)
			set pDomainId = tDomain.Id
		} else {
			set pDomainId = 0
		}
		set pDomainType = $case(pSourceType, "domain":"iKnow", :"DeepSee")
		set pDictionaries = $piece(indexInfo,":",4)
		set pParams = $piece(indexInfo,":",5,9999)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Translates a bitstring based on iKnow source IDs into one based on DeepSee fact IDs
/// for an iKnow-managed domain when <var>pToFactIDs</var> = 1, or vice versa otherwise.
ClassMethod TranslateIKnowBitstring(pCubeName As %String, pMeasureName As %String, pGlobFrom As %String, pGlobTo As %String = "", pToFactIDs As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tSC = ..GetMeasureInfo(pCubeName, pMeasureName, .tSourceType, .tDomainId, .tDomainName, .tDomainType)
		quit:$$$ISERR(tSC)
		
		if (tDomainType'="iKnow") { set tSC = $$$ERROR($$$GeneralError, "This is only supported for an iKnow-managed domain") quit }
		
		set pCubeName = $$$UPPER(pCubeName), pMeasureName = $$$UPPER(pMeasureName)
		
		set tInPlace = ((pGlobTo=pGlobFrom) || (pGlobTo=""))
		set:tInPlace pGlobTo = "^||%IKDS.Translate"
		
		kill @pGlobTo
		set tOffsetFrom = "", tPrevOffsetTo=0, tBitsTo=""
		for {
			set tOffsetFrom = $order(@pGlobFrom@(tOffsetFrom), 1, tBitsFrom)
			quit:tOffsetFrom=""
			
			set tPosFrom = 0
			for {
				set tPosFrom = $bitfind(tBitsFrom, 1, tPosFrom+1)
				quit:'tPosFrom
				
				$$$IKGETIDOFFPOS(tIdFrom,tOffsetFrom,tPosFrom)
				
				if (pToFactIDs) {
				
					set tFactId = ""
					for {
						set tFactId = $order($$$DeepSeeIndexGLVN(pCubeName, "%ikSrcId", pMeasureName, tIdFrom, tFactId))
						quit:tFactId=""
					
						$$$IKBITOFFPOS(tFactId,tOffsetTo,tPosTo)
					
						if (tPrevOffsetTo'=tOffsetTo) {
							set:tPrevOffsetTo @pGlobTo@(tPrevOffsetTo) = $bitlogic(tBitsTo)
							set tPrevOffsetTo=tOffsetTo, tBitsTo = $g(@pGlobTo@(tOffsetTo))
						}
						set $bit(tBitsTo,tPosTo) = 1
					}
					
				} else {
					
					set tSrcId = $g($$$DeepSeeIndexGLVN(pCubeName, "%ikSrcIdReverse", pMeasureName, tIdFrom))
					continue:'tSrcId
					
					$$$IKBITOFFPOS(tSrcId,tOffsetTo,tPosTo)
					
					if (tPrevOffsetTo'=tOffsetTo) {
						set:tPrevOffsetTo @pGlobTo@(tPrevOffsetTo) = $bitlogic(tBitsTo)
						set tPrevOffsetTo=tOffsetTo, tBitsTo = $g(@pGlobTo@(tOffsetTo))
					}
					set $bit(tBitsTo,tPosTo) = 1
					
				}
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set:tPrevOffsetTo @pGlobTo@(tPrevOffsetTo) = $bitlogic(tBitsTo)
		
		if (tInPlace) {
			kill @pGlobFrom
			merge @pGlobFrom = ^||%IKDS.Translate
			kill ^||%IKDS.Translate
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IKDS.Translate
	quit tSC
}

/// Wrapper method to support domains managed solely by DeepSee
ClassMethod RenameDomain(pFrom As %String, pTo As %String) As %Status [ Internal ]
{
	quit ##class(%iKnow.Domain).Rename(pFrom, pTo)
}

/// Wrapper method to support domains managed solely by DeepSee
ClassMethod DropDomain(pDomainName As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tDomainId = $system.iKnow.GetDomainId(pDomainName)
		quit:'tDomainId  // domain already gone..
		
		set tSC = ##class(%iKnow.Domain).Delete(pDomainName)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Wrapper method to support cross-domain dictionaries managed through a Term List
ClassMethod DropDictionary(pTermList As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tXDictName = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetDictionaryName(pTermList)
		set tXDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(0, tXDictName)
		if (tXDictId>0) {
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(0, tXDictId)
			quit
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Given the names of the term lists to match against, return a %List containing
/// the corresponding dictionary IDs to supply to MatchSource[s]()
/// Note: assumes version >= 3 (for cross-domain dictionary use)!
ClassMethod GetDictionaryIds(pDictionaries As %String) As %List [ Internal, Private ]
{
	set tCount = $length(pDictionaries,","), tList = ""
	for i = 1:1:tCount {
		set tTermList = $piece(pDictionaries,",",i)
		set tXDictName = ##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetDictionaryName(tTermList)
		set tXDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(0, tXDictName)
		continue:'tXDictId
		set tList = tList _ $lb(-tXDictId)
	}
	quit tList
}

ClassMethod UpdateMatching(pCubeName As %String, pMeasureName As %String) As %Status
{
	set tSC = ..GetMeasureInfo(pCubeName, pMeasureName,, .tDomainId,,,, .tDictionaries)
	quit:$$$ISERR(tSC)
	quit ..UpdateMatchingInternal(tDomainId, tDictionaries)
}

ClassMethod UpdateMatchingInternal(pDomainId As %Integer, pDictionaries As %String, pFactId As %Integer = "") As %Status [ Internal ]
{
	quit:pDictionaries="" $$$OK
	
	set tDictList = $s($$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONXDOMAIN):"", 1:..GetDictionaryIds(pDictionaries))
	
	if (pFactId) {
		quit ##class(%iKnow.Matching.MatchingAPI).MatchSource(pDomainId, pFactId, tDictList)
	} else {
		quit ##class(%iKnow.Matching.MatchingAPI).MatchSources(pDomainId,, tDictList)
	}
}

}
