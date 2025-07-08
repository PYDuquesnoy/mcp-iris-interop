/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
///  This is the main entry point for driving the iKnow Smart Matching mechanisms
Class %iKnow.Matching.MatchingAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

///  <p>Match the unique entities in this domain to all Dictionary Terms and Formats in the list of
///  Dictionaries specified through <i>dictIds</i> that haven't been matched in earlier operations.
///  This method is called automatically at the start of a call to <method>MatchSource</method> or
///  <method>MatchSources</method>.</p>
///  <p>Specifying "" for <i>dictIds</i> will match against all Dictionaries in this domain.</p>
///  <p>If a Virtual Source is specified, the entities of this Virtual Source will be matched.</p>
ClassMethod MatchEntityUniques(domainId As %Integer, dictIds As %List = "", vSrcId As %Integer = 0) As %Status
{
	set tSC = $$$OK, lastError = $g(^IRIS.IKL.Mat.Errors(domainId))
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		if vSrcId && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
		$$$IKTEMPDOMID(domainId,tTempId)
		
		// BDB572 - disable journalling if applicable
		$$$IKDisableJournal(domainId)
		
		// BDB623
		set tUseStemming = ($$$GETPARAM(domainId,$$$IKPSTEMMING,0)'=0)
		
		$$$IKLOCKX(domainId,^IRIS.IKM.MATCH,tSC)
	    
	    do ..ClearTemps(domainId)
		
		// BDB385 - check if we're looking for cross-domain dictionaries
		$$$IKXDOMDICTS(dictIds,xDomDicts,xDomVersion,tSC)
		if (xDomDicts && domainId) {
			// if so, check if their version is compatible with this domain's
			$$$IKXDOMDICTCOMPATIBLEX(xDomVersion,$$$IKVERSION(domainId),tSC)
			
			// BDB623 - also verify if we're not trying to match against a mix of stemmed and
			// non-stemmed dictionaries if this domain uses stemming
			set xDomStemming = ##class(%iKnow.Domain).GetSystemParameter($$$IKPSTEMMING)
			set xDomStemming = $case(xDomStemming, 0:0, "":0, :1)
			if tUseStemming && 'xDomStemming {
				set tSC = $$$ERROR($$$GeneralError, "Cannot match against non-stemmed cross-domain dictionaries from a domain with stemming enabled.")
				quit
			}
			if xDomStemming && 'tUseStemming {
				set tSC = $$$ERROR($$$GeneralError, "Cannot match against stemmed cross-domain dictionaries from a domain with stemming disabled.")
				quit
			}
		}
	    
	    // first make sure all DTs are properly indexed
		set tSC = ..IndexDictionaryTerms($s(xDomDicts:0, 1:domainId), dictIds)
		quit:$$$ISERR(tSC)
	    
		//$$$IKQTIC("MatchEntityUniques")
		
		set maxDictElemId = +$o(^IRIS.IK.Mat.DictElementId($s(xDomDicts:0, 1:domainId),""),-1)
		
	    // find out which EU to start from
		if (vSrcId) {
			$$$CHECKVSRCIDEXISTSX(domainId,vSrcId,tSC)
			set dictIds = ..GetNonMatchedDictsForSource(domainId, -vSrcId, dictIds)
			quit:'$ll(dictIds)
			
			set maxProcs=1
			if tUseStemming {
				set maxEntUniId = $order(^IRIS.IKV.StemUniId(domainId, vSrcId, ""), -1)
			} else {
				set maxEntUniId = $order(^IRIS.IKV.EntUniId(domainId, vSrcId, ""), -1)
			}
		} else {
			set:dictIds="" dictIds = ..GetAllDictsAsList(domainId)
			set:dictIds=$$$ALLXDOMDICTIONARIES dictIds = ..GetAllDictsAsList(0)
			if tUseStemming { // BDB623
		    	set maxEntUniId = +$o(^IRIS.IK.StemUniId(domainId,""),-1)
			} else {
		    	set maxEntUniId = +$o(^IRIS.IK.EntUniId(domainId,""),-1)
			}
			
			// first find out which EU to start from
			set tSC = ..BuildInvertedEntUniMatchedIndex(domainId,dictIds,.needsMatching)
			quit:$$$ISERR(tSC)
			set minEntUniId = $order(needsMatching(""))-1
			for {
				set minEntUniId = $order(needsMatching(minEntUniId),1,dictsToGo)
				quit:minEntUniId=""
				
				set ptr=0, hasOverlap=0
				while $listnext(dictsToGo,ptr,d) {
					set:$lf(dictIds,d) hasOverlap=1
					quit:hasOverlap
				}
				quit:hasOverlap
			}
			quit:minEntUniId>=maxEntUniId
			
			// mark starting point for MatchEntityUniquesJob()
			set ^IRIS.Temp.IK.Mat.EUId(tTempId) = minEntUniId
			
			// BDB356 - if there's only few EUs to be processed, default to 1 process, otherwise
			// use the maximum number of available cores
			if ((maxEntUniId-minEntUniId)<100) { 
				set maxProcs = 1
			} else {
				$$$SETMAXJOBS(maxProcs,domainId,"MatchEUs",$system.Util.NumberOfCPUs(),maxProcsLimit)
			}
		}
		
	    if vSrcId || (maxProcs=1)  {
		
		    set tSC = ..MatchEntityUniquesJob(domainId, dictIds, maxEntUniId, 0, vSrcId, xDomDicts, tUseStemming)
		    if $$$ISERR(tSC) {
			    
			    // if things got messed up, we have to erase all EU-DE matches that were added,
			    // based on the current values in ^IRIS.IK.Mat.DictMatchStatus()
			    if 'vSrcId {
			    
				    do ..BuildInvertedEntUniMatchedIndex(domainId,dictIds,.neededMatching)
				    set minEU = ""
				    for {
					    set minEU = $order(neededMatching(minEU),1,dictIdsForMinEU)
					    quit:minEU=""
				    
					    set entUniId = minEU
					    for {
						    set entUniId = $order(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId))
						    quit:entUniId=""
					    
						    set deId = ""
						    for {
							    set deId = $order(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId,deId),1,d)
							    quit:deId
						    
							    if $lf(dictIdsForMinEU,$li(d,1)) {
								    kill ^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId,deId)
							    }
						    }
					    }
				    }
			    } else {
				    kill ^IRIS.IKV.Mat.EntUnitoDictElem(domainId, vSrcId)
			    }
		    }
	    
	    } else {
		    
	   		for p=1:1:maxProcs {
		    	job ..MatchEntityUniquesJob(domainId, dictIds, maxEntUniId, p, vSrcId, xDomDicts, tUseStemming)::10
		    	if '$test {
			    	// BDB633 - if we can't start more processes, just end here
			    	set maxProcs = p-1
			    	quit
		    	}
	    	}
	    	quit:$$$ISERR(tSC)
	    	
		    while 1 {
		    	quit:$bitcount(^IRIS.Temp.IK.Mat.EUProc(tTempId),1)=maxProcs
		        hang 0.5
		    }
		    
	    	//$$$IKQTIC("MergeEU2DE")
		    // now verify the results and merge into ^IRIS.IK.Mat.EntUniToDictElem
		    for p=1:1:maxProcs {
			    set tSC = ^IRIS.Temp.IK.Mat.EUProc(tTempId,p)
			    quit:$$$ISERR(tSC)
			    
				set globName = "^IRIS.IKT."_domainId_".Mat.EU2DE."_p
				merge ^IRIS.IK.Mat.EntUniToDictElem(domainId) = @globName
				kill @globName
			}
			quit:$$$ISERR(tSC)
			//$$$IKQTOC("MergeEU2DE")
	    }
	    quit:$$$ISERR(tSC)
	    
		// now update ^IRIS.IK.Mat.DictMatchStatus
		if 'vSrcId {
			set ptr=0
			while $listnext(dictIds, ptr, dictId) {
			    set $li(^IRIS.IK.Mat.DictMatchStatus(domainId, dictId),2) = maxEntUniId
			 	set $li(^IRIS.IK.Mat.DictMatchStatus(domainId, dictId),3) = maxDictElemId
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if $$$IKLOCKED(^IRIS.IKM.MATCH) {
		kill ^IRIS.Temp.IK.Mat.EUProc(tTempId)
		kill ^IRIS.Temp.IK.Mat.EUId(tTempId)
	}
	
	$$$IKUNLOCK(domainId,^IRIS.IKM.MATCH)
	
	$$$IKRestoreJournal // BDB572

	set:$$$ISERR(tSC) ^IRIS.IKL.Mat.Errors(domainId,$i(^IRIS.IKL.Mat.Errors(domainId))) = $lb("",tSC,$h)
		
	if $$$GETPARAMNODEF(domainId,$$$IKPSTATUS) && (lastError<$g(^IRIS.IKL.Mat.Errors(domainId))) {
	    w !,"Some errors occurred during the matching process. Check ..GetErrors() for more details"
    }
	
	//$$$IKQTOC("MatchEntityUniques")
	quit tSC
}

ClassMethod MatchEntityUniquesJob(domainId As %Integer, dictIds As %List, pMaxEntUniId As %Integer, procN As %Integer = 0, vSrcId As %Integer = 0, xDomDicts As %Boolean = 0, pUseStemming As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(domainId,tTempId)
		
		// BDB572 - if this is an async job and when requested, disable journalling
		if procN {
			$$$IKDisableJournal(domainId)
		}
		
		set tSC = ..BuildInvertedEntUniMatchedIndex(domainId,dictIds,.needsMatching)
	    quit:$$$ISERR(tSC)
	    
	    kill tDictIds
	    set ptr=0
	    while $listnext(dictIds,ptr,tDictId) { set tDictIds(tDictId)="" }
	
		if (vSrcId) {
			set globName = "^IRIS.IKV.Mat.EntUniToDictElem("_domainId_","_vSrcId_")"
		} elseif (procN) {
			set globName = "^IRIS.IKT."_domainId_".Mat.EU2DE."_procN
		} else {
			set globName = "^IRIS.IK.Mat.EntUniToDictElem("_domainId_")"
		}
		kill:vSrcId skipDEs, skipEUs
	
		set entUniIdGlo = $$$IKVGLOBNAME(domainId,$s(pUseStemming:"StemUniId", 1:"EntUniId"),vSrcId)
	
		if procN { $$$IKSORTBEGIN(@globName) }
	    
	    // BDB385 - cross-domain dictionaries
	    set tDictDomId = $s(xDomDicts:0, 1:domainId)
    
	    set fullMatchOnly = $$$IKFULLMATCHONLY(domainId)
	    set tNGramMatches = $$$GETPARAM(domainId,$$$IKPMATCHNGRAMS,0) // BDB686
	    set tUseStandardizedForm = $$$GETPARAMNODEF(tDictDomId,$$$IKPMATSTANDARDIZEDFORM)
	    
	    // first gather data on all formats to match
	    kill formatObjects, tDictFormatCache
	    set tDictId=""
	    for {
		    set tDictId = $order(tDictIds(tDictId))
		    quit:tDictId=""
		    
		    set dfId = ""
		    for {
			    set dfId = $o(^IRIS.IK.Mat.DictToFormat(tDictDomId,$zabs(tDictId),dfId))
			    quit:dfId=""
		    
			    set df = ^IRIS.IK.Mat.DictFormatId(tDictDomId,dfId)
			    set formatClassId = $li(df,1)
			    set tDictFormatCache(formatClassId,dfId) = $li(df,2)
			    set de = ""
			    for {
				    set de = $order(^IRIS.IK.Mat.DictFormatElements(tDictDomId, dfId, de))
				    quit:de=""
				    set tDictFormatCache(formatClassId,dfId,de)=tDictId
			    }
		    
			    if '$d(formatObjects(formatClassId)) {
				    set formatObjects(formatClassId) = $classmethod(^IRIS.IK.Sys.DictFormatD(formatClassId), "%New", domainId)
			    }
		    }
		}
		
	    // now apply those Formats with a MatchAll() if we're either the first or the single
	    // MatcheEntityUniquesJob() process, or just skip them if we're a second process
	    set tMinEntUniId = $g(^IRIS.Temp.IK.Mat.EUId(tTempId))
		set resultsGlo = "^||%IK.FormatResults"
		if pUseStemming { // BDB623
			set stringsGlo = $$$IKVGLOBNAME(domainId,"StemUni",vSrcId)
			set hashesGlo = $$$IKVGLOBNAME(domainId,"StemUniHash",vSrcId)
			set idsGlo = $$$IKVGLOBNAME(domainId,"StemUniId",vSrcId)
		} else {
			set stringsGlo = $$$IKVGLOBNAME(domainId,"EntUni",vSrcId)
			set hashesGlo = $$$IKVGLOBNAME(domainId,"EntUniHash",vSrcId)
			set idsGlo = $$$IKVGLOBNAME(domainId,"EntUniId",vSrcId)
		}
	    set formatClassId = ""
	    for {
		    set formatClassId = $order(formatObjects(formatClassId),1,formatObj)
		    quit:formatClassId=""
	    
		    continue:'formatObj.HasMatchAll()
		
			if (procN <= 1) {
			    set dfId = "", prevParams="", first=1
			    for {
				    set dfId = $order(tDictFormatCache(formatClassId, dfId),1,formatParams)
				    quit:dfId=""
		    
				    if first || '$ls(formatParams, prevParams) {
					    kill @resultsGlo
				    
					    set tSC = formatObj.MatchAll(stringsGlo,resultsGlo,formatParams,tMinEntUniId)
			    		quit:$$$ISERR(tSC)
		    		
			    		set tSC = formatObj.MatchAllHashes(hashesGlo,idsGlo,resultsGlo,formatParams,tMinEntUniId)
			    		quit:$$$ISERR(tSC)
				    }
				    set first=0, prevParams = formatParams
		    
				    // copy results from resultsGlo to globName
				    set deId = ""
				    for {
					    set deId = $order(tDictFormatCache(formatClassId,dfId,deId),1,dictId)
					    quit:deId=""
			    		
			    		set:xDomDicts dictId = -dictId
					    continue:'$d(tDictIds(dictId))
			    
					    set euId = ""
					    for {
						    set euId = $order(@resultsGlo@(euId),1,d)
						    quit:euId=""
				    
						    set @globName@(euId, $s(xDomDicts:-deId, 1:deId)) = d
					    }
				    }
			    }
			    quit:$$$ISERR(tSC)
				kill @resultsGlo
			}
	    
		    // we can finish off this formatObj as it's fully processed (either in this process
		    // if procN<=1 or another one if procN > 1)
		    do formatObj.Finalize()
		    kill formatObjects(formatClassId), tDictFormatCache(formatClassId)
	    }
	    quit:$$$ISERR(tSC)
	    
	    kill tOutMatches
		set tBatchSize = 1000
	    while 1 {
		    if (vSrcId) {
			    set tMin="", tMax=pMaxEntUniId
		    } else {
			    set tMax = $i(^IRIS.Temp.IK.Mat.EUId(tTempId),tBatchSize), tMin=tMax-tBatchSize
			    quit:tMin>pMaxEntUniId
		    }
			
			// BDB364: prefetch unique entities so we don't need that global onwards
			kill tEntUniCache
			set tEntUniId = tMin, tEntUniCached = 1
			for {
				set tEntUniId = $order(@entUniIdGlo@(tEntUniId),1,tEntUni)
				quit:tEntUniId=""
		        quit:tEntUniId>tMax
		        continue:tEntUni=""
		    
		    	if tEntUniCached {
			        set tEntUniCache(tEntUniId) = tEntUni
		    	} else {
			    	set ^||%IK.EntUniCache(tEntUniId) = tEntUni
		    	}
		        
		        // quit if running low on memory
		        if tEntUniCached && ($s<100000) {
			        set tEntUniCached = 0
			        kill ^||%IK.EntUniCache
			        $$$IKSORTBEGIN(^||%IK.EntUniCache)
			        merge ^||%IK.EntUniCache = tEntUniCache
			        kill tEntUniCache
			        quit
		        }
			}
			set:'tEntUniCached x = $sortend(^||%IK.EntUniCache)

		    // now loop over entUniIdGlo for the Formats without MatchAll() and Term matches
		    set prevNeedsMatchingIndex = -1, tLangCount=$ll($$$IKLANGUAGES)
		    set entUniId = "", tIndex=""
		    for {
			    if tEntUniCached {
			        set entUniId = $order(tEntUniCache(entUniId), 1, entUni)
			    } else {
			        set entUniId = $order(^||%IK.EntUniCache(entUniId), 1, entUni)
			    }
		        quit:entUniId=""
		        continue:entUni=""
		        
		        // check against which dictIds we still need to match wrt new DEs
				if 'vSrcId {
					set nextNeedsMatchingIndex = $o(needsMatching(entUniId),-1,dictIdsToGo)
					if (nextNeedsMatchingIndex '= prevNeedsMatchingIndex) {
						// update skipDEs wrt new index, as new EUs should skip no DEs
				        kill skipDEs
				        merge skipDEs = needsMatching(nextNeedsMatchingIndex)
				        set prevNeedsMatchingIndex = nextNeedsMatchingIndex
					}
				} else {
					kill skipDEs
		        	// for virtual sources, check if we can reuse something from the real EntUniId
		        	if (pUseStemming) { // BDB623
				        set realEntUniId = +$lg(^IRIS.IKV.StemUniDetails(domainId,vSrcId,entUniId),3)
		        	} else {
				        set realEntUniId = +$lg(^IRIS.IKV.EntUniDetails(domainId,vSrcId,entUniId),3)
		        	}
			        if (realEntUniId) {
				        // if so, we can reuse real match results and continue with the corresponding dictIdsToGo
						merge tOutMatches(entUniId) = ^IRIS.IK.Mat.EntUniToDictElem(domainId,realEntUniId)
						set t = $o(needsMatching(realEntUniId),-1,dictIdsToGo)
						merge skipDEs = needsMatching(t)
			        } else {
				        // if not, we'll have to match against all dictIds
				        set dictIdsToGo = dictIds
			        }
		        }
		        $$$IKLIST2ARR(dictIdsToGo,tDictIdsToGo)
		        continue:'$d(tDictIdsToGo)
		        
	        	// build an array of the standardized forms we'll be checking
	        	kill entUniForms
	        	set tHasHashes = 0 // BDB597
	        	if (tUseStandardizedForm'="") {
		        	for langId=1:1:tLangCount {
			        	set form = ..StandardizedForm(entUni, $li($$$IKLANGUAGES,langId), tUseStandardizedForm)
			        	set:form="" form = entUni
			        	if $l(form)>$$$IKHASHSIZE {
				        	set tHash = $zcrc(form,7), tHasHashes = 1
				        	set entUniForms(tHash) = $g(entUniForms(tHash))_$lb(langId)
				        	set entUniForms(tHash,0) = form
			        	} else {
				        	set entUniForms(form) = $g(entUniForms(form)) _ $lb(langId)
			        	}
		        	}
		        	// if all normalized to the same entry, simplify
		        	set form = $order(entUniForms(""),1,langs)
		        	set:($ll(langs)=tLangCount) entUniForms(form) = 0
	        	} else {
		        	if $l(entUni)>$$$IKHASHSIZE {
				        set tHash = $zcrc(entUni,7), tHasHashes = 1
			        	set entUniForms(tHash,0) = entUni
		        	} else {
		        		set entUniForms(entUni) = 0
		        	}
	        	}
		        
		        // now check simple element matches for each array entry
		        set form = ""
		        for {
			        set form = $order(entUniForms(form),1,langs)
			        quit:form=""
			        
			        // BDB597 - look up actual value for long strings
			        set tFormString = $s(tHasHashes&&$d(entUniForms(form,0),d):d, 1:form)
			        
			        set tSC = ..CheckDictionaryElementMatches(domainId, .tFormString, .tDictIdsToGo, fullMatchOnly, .skipDEs, 0,,xDomDicts, tNGramMatches)
			        quit:$$$ISERR(tSC)
	        
			        set m = ""
			        for {
			            set m = $order(^||%IK.DEMatches(m), 1, match)
			            quit:m=""
	            		
	            		if $listvalid(langs) {
		            		set l=0
		            		while $listnext(langs,l,langId) {
					            set tOutMatches(entUniId, $list(match,2), langId) = $list(match,3,5)
		            		}
	            		} else {
				            set tOutMatches(entUniId, $list(match,2)) = $list(match,3,5)
	            		}
		        
		        		// BDB610 - avoid STORE errors for entities appearing in MANY Dictionary Terms
				        if ($s<200000) {
							merge @globName = tOutMatches
							kill tOutMatches
				        }
			        }
		        }
		        quit:$$$ISERR(tSC)
		        
		        // and dictionary format matches using MatchSingle()
		        set formatClassId = ""
		        for {
			        set formatClassId = $order(formatObjects(formatClassId),1,formatObj)
			        quit:formatClassId=""
			    
				    set dfId = "", prevParams="", first=1
				    for {
					    set dfId = $order(tDictFormatCache(formatClassId, dfId), 1, formatParams)
					    quit:dfId=""
			    
					    if first || '$ls(formatParams, prevParams) {
						    kill matchScore, matchedWordBits, isScattered, formatOutput
						    set tSC = formatObj.MatchSingle(entUni,formatParams,.matchScore,.matchedWordBits,.isScattered,.formatOutput)
				    		quit:$$$ISERR(tSC)
					    }
					    set first=0, prevParams = formatParams
			    	
				    	continue:'matchScore
			    	
					    // store results
					    set deId = ""
					    for {
						    set deId = $order(tDictFormatCache(formatClassId,dfId,deId),1,dictId)
						    quit:deId=""
				    
						    continue:'$d(tDictIdsToGo(dictId))
				    
						    set tOutMatches(entUniId, $s(xDomDicts:-deId, 1:deId)) = $lb(matchScore, matchedWordBits, isScattered, formatOutput)
					    }
				    }
				    quit:$$$ISERR(tSC)
		        }
		        quit:$$$ISERR(tSC)
		        
		        if ($s<200000) {
					merge @globName = tOutMatches
					kill tOutMatches
		        }
		    }
		    quit:$$$ISERR(tSC)
		    quit:vSrcId
	    }
	    quit:$$$ISERR(tSC)
	    
    	merge @globName = tOutMatches
	    set:procN tSC2 = $sortend(@globName)
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	} 
	
	// clean up formatter objects
	set formatClassId = ""
	for {
		set formatClassid = $order(formatObjects(formatClassId),1,formatObj)
		quit:formatClassId=""
		
		continue:$isobject(formatObj)
		
		try {
			do formatObj.Finalize()
		} catch {
			// ignore errors
		}
	}
	kill formatObjects, tDictFormatCache, tEntUniIds
	
	set:$$$ISERR(tSC) ^IRIS.IKL.Mat.Errors(domainId,$i(^IRIS.IKL.Mat.Errors(domainId))) = $lb("",tSC,$h)
	
	// update status
	if (procN>0) {
		set ^IRIS.Temp.IK.Mat.EUProc(tTempId, procN) = tSC
		set $bit(^IRIS.Temp.IK.Mat.EUProc(tTempId),procN) = 1
	}
	
	quit tSC
}

///  Checks for a given string to which dictionary elements it matches and stores the result
///  in ^||%IK.DEMatches(i) = $lb(dictId, dictElementId, matchScore, matchedWordBits, isScattered[, language])
///  Using <var>append</var>=1 will leave existing values in ^||%IK.DEMatches untouched.
/// If <var>xDomDicts</var> = 1, we expect negative dictId indices in <var>dictIds</var> and
/// <var>skipDEs</var>, and will output negative dictIds and dictElementIds
ClassMethod CheckDictionaryElementMatches(domainId As %Integer, ByRef string As %String, ByRef dictIds, fullMatchOnly As %Integer = -1, skipDEs = "", append As %Boolean = 0, outVar As %String = "^||%IK.DEMatches", xDomDicts As %Boolean = 0, nGramMatches As %Boolean = 0) As %Status [ Internal ]
{
    kill:'append @outVar
    
    // check domain settings if not supplied
    set:fullMatchOnly<0 fullMatchOnly = $$$IKFULLMATCHONLY(domainId)
    set:nGramMatches<0 nGramMatches = $$$GETPARAM(domainId,$$$IKPMATCHNGRAMS,0)

    // make sure there's no double spaces
    set tString = $zstrip(string, "<=>W")
    
    set dictIds=$d(dictIds)
    set tDictDomainId = $s(xDomDicts:0, 1:domainId)
    
    if (fullMatchOnly) {
	    
	    // BDB295: we don't support dictionary elements over $$$IKHASHSIZE in length, so we
	    // cannot have a full match in this case either
	    quit:($length(tString)>$$$IKHASHSIZE) $$$OK
	    	
	    if $d(^IRIS.IK.Mat.DictElemString(tDictDomainId, " "_tString), deStringId) {
		    set matchedWordBits = ""
		    set wordCount = $length(tString, " ")
		    for i=1:1:wordCount { set $bit(matchedWordBits, i) = 1 }
		    
        	set deId = ""
            for {
        		set deId = $order(^IRIS.IK.Mat.DictElement(tDictDomainId, deStringId, deId), 1, dictId)
                quit:deId=""
                
                set:xDomDicts dictId = -$zabs(dictId)
                continue:+$g(skipDEs(dictId))>=deId
                continue:dictIds&&'$d(dictIds(dictId))
                
                set @outVar@($i(@outVar)) = $lb(dictId, $s(xDomDicts:-deId, 1:+deId), 1, matchedWordBits, 0)
            }
	    }
	    
	    quit $$$OK
    }
    
    // BDB686
    if nGramMatches {
	    
	    // create all possible substrings for the supplied string and check them
	    // against ^IRIS.IK.Mat.DictElemString
	    kill tSubstrings
	    set tStringLength = $l(string), tMinLength = nGramMatches, tSubstrings=0
	    for tPosStart = 1:1:tStringLength {
		    for tPosEnd = tPosStart+nGramMatches-1:1:tStringLength {
			    continue:(tPosEnd-tPosStart)>$$$IKHASHSIZE // BDB775
			    set tSubstrings($e(string, tPosStart, tPosEnd)) = $lb(tPosStart, tPosEnd)
		    }
	    }
	    
	    set tFragment = ""
	    for {
		    set tFragment = $order(tSubstrings(tFragment),1,tFragmentInfo)
		    quit:tFragment=""
			
		    if $d(^IRIS.IK.Mat.DictElemString(tDictDomainId, " "_tFragment), deStringId) {
			    set matchedWordBits = "", tPosStart=$li(tFragmentInfo,1), tPosEnd=$li(tFragmentInfo,2)
			    for i = tPosStart:1:tPosEnd {
				    set $bit(matchedWordBits,i) = 1
			    }
			    
	        	set deId = ""
	            for {
	        		set deId = $order(^IRIS.IK.Mat.DictElement(tDictDomainId, deStringId, deId), 1, dictId)
	                quit:deId=""
	                
	                set:xDomDicts dictId = -$zabs(dictId)
	                continue:+$g(skipDEs(dictId))>=deId
	                continue:dictIds&&'$d(dictIds(dictId))
	                
	                set @outVar@($i(@outVar)) = $lb(dictId, $s(xDomDicts:-deId, 1:+deId), ((tPosEnd-tPosStart+1)/tStringLength), $bitlogic(matchedWordBits, tStringLength), 0)
	            }
		    }    
	    }
	    
	    quit $$$OK
    }
    
    // initialize structures
    set stringLength = $length(tString)
    set nbOfWordsInString = $length(tString," ")
    kill tWordByPos, tPosByWord, tWordLength
    for i = 1:1:nbOfWordsInString { 
    	set tWord=$p(tString," ",i), wl=$l(tWord), tWordLength(i)=wl 
    	set:wl&&(wl<$$$IKHASHSIZE) tPosByWord(tWord) = i, tWordByPos(i)=tWord 
    }
    set trackPartials = 0, trackMatchedWords = ""

    // loop over all words in the supplied string to see whether there are partial matches
    kill tDES
    for i = 1:1:nbOfWordsInString {
        set word = $g(tWordByPos(i)), wordLength = $g(tWordLength(i))
        continue:word=""

        // loop over the dict entries starting with this word
        set index = $extract($order(^IRIS.IK.Mat.DictElemString(tDictDomainId, " "_word), -1), 2, *)
        for {
            set index = $order(^IRIS.IK.Mat.DictElemString(tDictDomainId, " "_index), 1, deStringId)
            quit:index=""
            
            // we're not going to check if we're hitting one of the required dictIds
            // as we'd only save a few CPU cycles but would have to do at least a few
            // global lookups which would probably cost more. The check is postponed
            // to the population of the matches return variable
            
            // remove the leading space (collation)
            set index = $extract(index, 2, *)
            set indexLength = $length(index)
            
            // skip if the index is longer than our total string length
            continue:(indexLength>stringLength)
        
            // quit if the index is shorter than our word, as there can't be any match
            quit:(indexLength<wordLength)
        
            // quit if the first word of the index no longer matches our word
            quit:($extract(index,1,wordLength)'=word)
        
            // otherwise, we can count how many words in this entry match words
            // in the supplied string and track whether they appear in the right 
            // order
            set wordsMatching = 0, wordsInOrder = 1, lastWordMatched = 0, matchScore=0
            set matchedWordBits = "", nbOfWordsInIndex = $l(index, " ")
            continue:nbOfWordsInIndex>nbOfWordsInString
            
            for j = 1:1:nbOfWordsInIndex {
                set indexWord = $p(index, " ", j)
                continue:indexWord=""
                set wordInString = +$g(tPosByWord(indexWord))
            
                if (wordInString) {
                    set $bit(matchedWordBits, wordInString) = 1
                
                    // we keep track of this count separately as the bitstring
                    // is not really resistant to words appearing twice or more
                    set wordsMatching = wordsMatching + 1
                
                    if (wordsInOrder && (wordInString < lastWordMatched)) {
                        set wordsInOrder = 0
                    }
                    set lastWordMatched = wordInString
                }
            }
            
            if ((wordsMatching = nbOfWordsInString) && (wordsMatching = nbOfWordsInIndex)) {
	            set matchScore = 1
            } elseif (wordsMatching = nbOfWordsInIndex) {
	            set matchScore = (wordsMatching/nbOfWordsInString)
            }
            
 			set:matchScore tDES(deStringId) = $lb(matchScore, $bitlogic(matchedWordBits, nbOfWordsInString), 'wordsInOrder)
        }
    }
    
    // now process DE Strings:
    set tDESId = ""
    for {
    	set tDESId = $order(tDES(tDESId), 1, tData)
    	quit:tDESId=""
    	
        set tDEId = ""
        for {
            set tDEId = $order(^IRIS.IK.Mat.DictElement(tDictDomainId, tDESId, tDEId), 1, tDictId)
            quit:tDEId=""
            
            set:xDomDicts tDictId = -$zabs(tDictId)
			continue:+$g(skipDEs(tDictId))>=tDEId
    		continue:dictIds&&'$d(dictIds(tDictId))
               
            set @outVar@($i(@outVar)) = $lb(tDictId, $s(xDomDicts:-tDEId, 1:+tDEId)) _ tData
        }
    }
    quit $$$OK
}

Parameter MatchSourcesEXP [ Internal ] = 1;

///  <p>Matches all sources in the domain, optionally restricted to those satisfying the criteria of a
///  <class>%iKnow.Filters.Filter</class> object provided as <i>filter</i>, against the list of 
///  Dictionary IDs passed in <i>dictIds</i>. Use negative numbers to mark cross-domain dictionaries.</p>
///  <p>A Matching Profile to calculate match scores can be specified either by passing in an
/// 	 <class>%iKnow.Matching.MatchingProfile</class> object, or a Matching Profile ID. When
///  passing in the ID, a negative number is treated as a namespace-wide profile, whereas
///  a positive ID will be looked up within the context of the domain.</p>
///  <p>Specifying "" for <i>dictIds</i> will match against all Dictionaries in this domain and
///  passing $$$ALLXDOMDICTIONARIES will match against all cross-domain dictionaries.</p>
ClassMethod MatchSources(domainId As %Integer, filter As %iKnow.Filters.Filter = "", dictIds As %List = "", overrideProfile As %iKnow.Matching.MatchingProfile = "") As %Status
{
	set tSC = $$$OK, lastError=$g(^IRIS.IKL.Mat.Errors(+domainId))
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		$$$CHECKDOMAINEXISTSX(domainId,tSC)
		$$$IKQFILTEROBJECTX(domainId,filter,tSC)
		$$$IKTEMPDOMID(domainId,tTempId)
		
		// BDB385 - check if we're looking for cross-domain dictionaries
		if (dictIds = "") {
			set dictIds = ..GetAllDictsAsList(domainId), xDomDicts = 0
		} elseif (dictIds = $$$ALLXDOMDICTIONARIES) {
			$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
			set dictIds = ..GetAllDictsAsList(0), xDomDicts = 1
		} else {
			$$$IKXDOMDICTS(dictIds,xDomDicts,xDomVersion,tSC)
		}
		if (xDomDicts) {
			// if so, check if they are compatible with this domain's version
			$$$IKXDOMDICTCOMPATIBLEX(xDomVersion,$$$IKVERSION(domainId),tSC)
		}
		
	    // first check if the EU mappings are up to date and eventually (re)build
	    set tSC = ..MatchEntityUniques(domainId, dictIds)
	    quit:$$$ISERR(tSC)
		
		// BDB572 - disable journalling if applicable
		$$$IKDisableJournal(domainId)
		
		$$$SETMAXJOBS(maxProcs,domainId,"MatchSources",$system.Util.NumberOfCPUs(),maxProcsLimit)
		set maxSrcId = +$o(^IRIS.IK.SrcId(domainId,""),-1)
		quit:'maxSrcId
		
		// BDB356 - if there's only few sources to be processed, default to 1 process, otherwise use all cores.
		// This source count is a pessimistic approximation, as the real calculation of which ones need
		// to be matched is part of MatchSourceJob
		set:(##class(%iKnow.Queries.SourceAPI).GetCountByDomain(domainId,filter)<50) maxProcs = 1
		
		// if we're launching jobs, make sure the profile object is saved and available for restore
		if ($isobject(overrideProfile) && (maxProcs>1)) {
			if overrideProfile.%IsModified() { set tSC = $$$ERROR($$$IKMatProfileModified) quit }
			set overrideProfile = overrideProfile.ProfileId
		}
		
	    $$$IKLOCKX(domainId,^IRIS.IKM.MATCH,tSC)
	    
	    do ..ClearTemps(domainId)
	    
		kill ^IRIS.Temp.IK.Mat.SrcId(tTempId)
		set:$isobject(filter) ^IRIS.Temp.IK.Mat.SrcId(tTempId) = filter.GetFirstFilteredSource()-1
		
		if (maxProcs=1) {
			
			set tSC = ..MatchSourceJob(domainId, $s($isobject(filter):filter.ToString(),1:""), dictIds, overrideProfile, 0, xDomDicts)
			quit:$$$ISERR(tSC)
			
		} else {
		
			kill ^IRIS.Temp.IK.Mat.SrcProc(tTempId)
			
			for i = 1:1:maxProcs {
				job ..MatchSourceJob(domainId, $s($isobject(filter):filter.ToString(), 1:filter), dictIds, overrideProfile, i, xDomDicts)::10
				if '$test {
					// BDB633 - if we cannot start any more processes, just stick to i-1
					set maxProcs = i-1
					quit
				}
			}
			quit:$$$ISERR(tSC)
			
			while 1 {
				quit:$bitcount(^IRIS.Temp.IK.Mat.SrcProc(tTempId),1)=maxProcs
				hang 0.5
			}
			
			for i = 1:1:maxProcs {
				set tSC = $g(^IRIS.Temp.IK.Mat.SrcProc(tTempId, i))
				quit:$$$ISERR(tSC)
				
				set tSC = ..MergeTempGlobals(domainId, i)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
		}
		
		// and update the bitstrings based on corresponding IKT globals
	    do ..GetCurrentDictElems(domainId, dictIds, .currentDictElemsArr)
		set tSC = ..UpdateBitStrings(domainId, .currentDictElemsArr,, xDomDicts)
		quit:$$$ISERR(tSC)
		
		// BDB624 - sync customizations
		set tTablesPackage = $$$GETPARAMNODEF(domainId,$$$IKPPACKAGE)
		if tTablesPackage'="" {
			set tSC = ##class(%iKnow.Tables.Utils).SyncDictionaryMatchCustomizations(domainId,tTablesPackage,0,,,filter)
			quit:$$$ISERR(tSC)
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if $$$IKLOCKED(^IRIS.IKM.MATCH) {
		kill ^IRIS.Temp.IK.Mat.SrcProc(tTempId)
		kill ^IRIS.Temp.IK.Mat.SrcId(tTempId)
	}

	$$$IKUNLOCK(domainId,^IRIS.IKM.MATCH)
	
	$$$IKRestoreJournal // BDB572
	
	set:$$$ISERR(tSC) ^IRIS.IKL.Mat.Errors(domainId,$i(^IRIS.IKL.Mat.Errors(domainId))) = $lb("",tSC,$h)
	
	if $$$GETPARAMNODEF(domainId,$$$IKPSTATUS) && (lastError<$g(^IRIS.IKL.Mat.Errors(domainId))) {
	    w !,"Some errors occurred during the matching process. Check ..GetErrors() for more details"
    }
	
	quit tSC
}

///  Merges the temporary globals generated by the different processes into the real ones
ClassMethod MergeTempGlobals(domainId As %Integer, procN As %Integer) As %Status [ Internal, Private ]
{
	set dictToMatchGlo = "^IRIS.IKT."_domainId_".Mat.D2M."_procN
	set dictToSrcGlo = "^IRIS.IKT."_domainId_".Mat.D2S."_procN
	set entOccToMatchGlo = "^IRIS.IKT."_domainId_".Mat.EO2M."_procN
	set dictItemToMatchGlo = "^IRIS.IKT."_domainId_".Mat.DI2M."_procN
	set srcToMatchGlo = "^IRIS.IKT."_domainId_".Mat.S2M."_procN
	set sentToMatchGlo = "^IRIS.IKT."_domainId_".Mat.S2MS."_procN
	
	// TODO: these can potentially be run in parallel
    merge ^IRIS.IKT.Mat.DictToMatch(domainId) = @dictToMatchGlo
    merge ^IRIS.IKT.Mat.DictToSrc(domainId) = @dictToSrcGlo
    merge ^IRIS.IK.Mat.EntOccToMatch(domainId) = @entOccToMatchGlo
    merge ^IRIS.IK.Mat.DictItemToMatch(domainId) = @dictItemToMatchGlo
    merge ^IRIS.IK.Mat.SrcToMatch(domainId) = @srcToMatchGlo
    merge ^IRIS.IK.Mat.SentToMatchScore(domainId) = @sentToMatchGlo
    
    kill @dictToMatchGlo
    kill @dictToSrcGlo
    kill @entOccToMatchGlo
    kill @dictItemToMatchGlo
    kill @srcToMatchGlo
    kill @sentToMatchGlo
	    
	quit $$$OK
}

Parameter MatchSourceEXP [ Internal ] = 1;

///  <p>Matches an individual source against the list of Dictionary IDs passed in <i>dictIds</i>.
///  Use negative numbers to identify any cross-domain dictionaries to match against.
///  A Matching Profile to calculate match scores can be specified either by passing in an
/// 	 <class>%iKnow.Matching.MatchingProfile</class> object, or a Matching Profile ID. When
///  passing in the ID, a negative number is treated as a namespace-wide profile, whereas
///  a positive ID will be looked up within the context of the domain.</p>
///  <p>Specifying "" for <i>dictIds</i> will match against all Dictionaries in this domain and
///  passing $$$ALLXDOMDICTIONARIES will match against all cross-domain dictionaries.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod MatchSource(domainId As %Integer, srcId As %Integer, dictIds As %List = "", overrideProfile As %iKnow.Matching.MatchingProfile = "") As %Status
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVWRITEX(tSC)
		if (srcId<0) && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
		$$$CHECKASRCIDEXISTSX(domainId,srcId,srcDetails,vSrcId,tSC)
		$$$IKTEMPDOMID(domainId,tTempId)
		
		// BDB385 - check if we're looking for cross-domain dictionaries
		if (dictIds = "") && domainId {
			set dictIds = ..GetAllDictsAsList(domainId), xDomDicts = 0
		} elseif (dictIds = $$$ALLXDOMDICTIONARIES) {
			$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
			set dictIds = ..GetAllDictsAsList(0), xDomDicts = 1
		} else {
			$$$IKXDOMDICTS(dictIds,xDomDicts,xDomVersion,tSC)
		}
		if (xDomDicts && domainId) {
			// if so, check if they are compatible with this domain's version
			$$$IKXDOMDICTCOMPATIBLEX(xDomVersion,$$$IKVERSION(domainId),tSC)
		}
		
		set lastError = $g(^IRIS.IKL.Mat.Errors(domainId))

	    // first check if the EU mappings are up to date and eventually (re)build
	    set tSC = ..MatchEntityUniques(domainId, dictIds, vSrcId)
	    quit:$$$ISERR(tSC)
		
		// BDB572 - disable journalling if applicable
		$$$IKDisableJournal(domainId)
		
	    $$$IKLOCKX(domainId,^IRIS.IKM.MATCH,tSC)
	    
	    do ..ClearTemps(domainId)
		
		// check if we still need to process this source
		set dictIds = ..GetNonMatchedDictsForSource(domainId, srcId, dictIds)
		quit:'$ll(dictIds)
	    
		set ^IRIS.Temp.IK.Mat.SrcId(tTempId) = $s(vSrcId:-vSrcId, 1:srcId-1)
	    set tSC = ..MatchSourceJob(domainId, $s(vSrcId:"", 1:##class(%iKnow.Filters.SourceIdFilter).%New(domainId,srcId)), dictIds, overrideProfile, 0, xDomDicts)
	    quit:$$$ISERR(tSC)
	    
	    // now get the latest
	    do ..GetCurrentDictElems(domainId, dictIds, .currentDictElemsArr)
	    set tSC = ..UpdateBitStrings(domainId, .currentDictElemsArr, vSrcId, xDomDicts)
	    quit:$$$ISERR(tSC)
		
		// BDB624 - sync customizations
		if 'vSrcId {
			set tTablesPackage = $$$GETPARAMNODEF(domainId,$$$IKPPACKAGE)
			if tTablesPackage'="" {
				set tSC = ##class(%iKnow.Tables.Utils).SyncDictionaryMatchCustomizations(domainId,tTablesPackage,0,srcId,srcId)
				quit:$$$ISERR(tSC)
			}
		}
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if $$$IKLOCKED(^IRIS.IKM.MATCH) {
		kill ^IRIS.Temp.IK.Mat.SrcId(tTempId)
	}
    
	$$$IKUNLOCK(domainId,^IRIS.IKM.MATCH)
		
	$$$IKRestoreJournal // BDB572
	
	set:$$$ISERR(tSC) ^IRIS.IKL.Mat.Errors(domainId,$i(^IRIS.IKL.Mat.Errors(domainId))) = $lb(srcId,tSC,$h)
	
	if $$$GETPARAMNODEF(domainId,$$$IKPSTATUS) && (lastError<$g(^IRIS.IKL.Mat.Errors(domainId))) {
	    w !,"Some errors occurred during the matching process. Check ..GetErrors() for more details"
    }
    
    quit tSC
}

ClassMethod MatchSourceJob(domainId As %Integer, filterString As %String = "", dictIds As %List = "", overrideProfile As %iKnow.Matching.MatchingProfile = "", procN As %Integer = 1, xDomDicts As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(domainId,tTempId)
		
		// BDB572 - if this is an async job, disable journalling
		if procN {
			$$$IKDisableJournal(domainId)
		}
		
		// BDB623
		set tUseStemming = ($$$GETPARAM(domainId,$$$IKPSTEMMING,0)'=0)
		
		$$$IKQFILTEROBJECTX(domainId,filterString,tSC)
		set tFilter = filterString
		
		set tFirstSrcId = $g(^IRIS.Temp.IK.Mat.SrcId(tTempId))
		set vSrcId = $s(tFirstSrcId<0:-tFirstSrcId, 1:0)
		set tDictDomainId = $s(xDomDicts:0, 1:domainId)
		
		// if the profile was passed in as an ID, restore it as an object
		if '$isobject(overrideProfile) && +overrideProfile {
			set overrideProfile = ##class(%iKnow.Matching.MatchingProfile).GetProfile(domainId, overrideProfile, .tSC)
			quit:$$$ISERR(tSC)
		}
	
		if (vSrcId) {
			set dictToMatchGlo = "^||%IKV.Mat.DictToMatch"
			set entOccToMatchGlo = "^IRIS.IKV.Mat.EntOccToMatch("_domainId_","_vSrcId_")"
			set dictItemToMatchGlo = "^IRIS.IKV.Mat.DictItemToMatch("_domainId_","_vSrcId_")"
			set sentToMatchGlo = "^IRIS.IKV.Mat.SentToMatchScore("_domainId_","_vSrcId_")"
			set dictToSrcGlo = "", srcToMatchGlo = ""
		} elseif (procN=0) {
			set dictToMatchGlo = "^IRIS.IKT.Mat.DictToMatch("_domainId_")"
			set entOccToMatchGlo = "^IRIS.IK.Mat.EntOccToMatch("_domainId_")"
			set dictItemToMatchGlo = "^IRIS.IK.Mat.DictItemToMatch("_domainId_")"
			set dictToSrcGlo = "^IRIS.IKT.Mat.DictToSrc("_domainId_")"
			set srcToMatchGlo = "^IRIS.IK.Mat.SrcToMatch("_domainId_")"
			set sentToMatchGlo = "^IRIS.IK.Mat.SentToMatchScore("_domainId_")"
		} else {
			set dictToMatchGlo = "^IRIS.IKT."_domainId_".Mat.D2M."_procN
			set entOccToMatchGlo = "^IRIS.IKT."_domainId_".Mat.EO2M."_procN
			set dictItemToMatchGlo = "^IRIS.IKT."_domainId_".Mat.DI2M."_procN
			set dictToSrcGlo = "^IRIS.IKT."_domainId_".Mat.D2S."_procN
			set srcToMatchGlo = "^IRIS.IKT."_domainId_".Mat.S2M."_procN
			set sentToMatchGlo = "^IRIS.IKT."_domainId_".Mat.S2MS."_procN
		}
		
		set entLevelMatchOnly = $$$GETPARAMNODEF(domainId,$$$IKPENTLEVELMATCHONLY)
		set matchScoreMargin = $$$GETPARAM(domainId,$$$IKPMATCHSCOREMARGIN,$$$IKPDEFMATCHSCOREMARGIN)
		set tUseStandardizedForm = $s(tUseStemming:"", 1:$$$GETPARAMNODEF(tDictDomainId,$$$IKPMATSTANDARDIZEDFORM))
		set ikpMatSkipRelations = $$$GETPARAM(domainId,$$$IKPMATSKIPRELATIONS,$$$IKPDEFMATSKIPRELATIONS)	

		$$$IKSORTBEGIN(@dictToMatchGlo) // ?
		$$$IKSORTBEGIN(@entOccToMatchGlo) // ?
		$$$IKSORTBEGIN(@dictItemToMatchGlo)
		$$$IKSORTBEGIN(@sentToMatchGlo)
		if 'vSrcId { 
			$$$IKSORTBEGIN(@srcToMatchGlo)
			$$$IKSORTBEGIN(@dictToSrcGlo) 
		}
                    
		// prepare the list of dictionaries to match and load their default profiles
		if $isobject(overrideProfile) {
			set dictProfiles = overrideProfile
		} else {
			set dictProfiles = ##class(%iKnow.Matching.MatchingProfile).GetProfile(domainId)
		}
		set ptr=0
		while $listnext(dictIds,ptr,dictId) {
			set dictInfo = $g(^IRIS.IK.Mat.DictId(tDictDomainId,$zabs(dictId)))
			continue:dictInfo=""
			set profileId = $lg(dictInfo,4,"")
			set tDictIds(dictId) = $lg($g(^IRIS.IK.Mat.DictMatchStatus(domainId,dictId)),3)
			if $isobject(overrideProfile) {
				set dictProfiles(dictId) = overrideProfile
			} else {
				set dictProfiles(dictId) = ##class(%iKnow.Matching.MatchingProfile).GetProfile(domainId, profileId, .tSC)
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		// clear caching and utility PPGs
	    kill %DictElemCache, %DictTermCache
	    kill ^||%IK.Mat.NewMatches, ^||%IK.Mat.DictToSrcInProgress, ^||%IK.Srces
		
		// set global names
		set sentDetailsGlo = $$$IKVGLOBNAME(domainId,"SentDetails",vSrcId)
		set entOccIdGlo = $$$IKVGLOBNAME(domainId,"EntOccId",vSrcId)
		set crcOccIdGlo = $$$IKVGLOBNAME(domainId,"CrcOccId",vSrcId)
		set pathEntOccGlo = $$$IKVGLOBNAME(domainId,"PathToEntOcc",vSrcId)
		set matchIncGlo = $$$IKVGLOBNAME(domainId,"Mat.MatchInc",vSrcId)
		set matchIdGlo = $$$IKVGLOBNAME(domainId,"Mat.MatchId",vSrcId)
		set entUniToDictElemGlo = $$$IKVGLOBNAME(domainId,"Mat.EntUniToDictElem",vSrcId)
		set gAttPath = $$$IKVGLOBNAME(domainId,"Att.Path",vSrcId)
		set gAttSent = $$$IKVGLOBNAME(domainId,"Att.Sent",vSrcId)
		
		set tFilterFirst = $isobject(tFilter) && (tFilter.Selectivity<0.5)
		set tBatchSize = 200, tMaxSrcId = $order(^IRIS.IK.SrcId(domainId,""),-1), tExit=0
		set:$isobject(tFilter)&&'tFilter.%IsA("%iKnow.Filters.SourceIdRangeFilter")&&(tFilter.Selectivity'=0) tBatchSize = (tBatchSize \ tFilter.Selectivity)
		while 1 {
			kill cSrcDetails, cSrcDictIdsToGo
			if 'vSrcId {
				set tMax = $i(^IRIS.Temp.IK.Mat.SrcId(tTempId),tBatchSize), tMin = tMax-tBatchSize
				quit:tMin>tMaxSrcId
				
				// prefetch tSrcDetails for this batch
				set tSrcId = tMin
				for {
					if 'tFilterFirst {
						set tScrId = $i(tSrcId)
					} else {
						set tSrcId = tFilter.GetNextSrcId(tSrcId)
						if tSrcId="" { set tExit=1  quit }
					}
					quit:tSrcId>tMax
					quit:tExit
					
					// check if filtered
					continue:$isobject(tFilter)&&'tFilter.IsFiltered(tSrcId)
					continue:'$d(^IRIS.IK.SrcDetails(domainId,tSrcId), tSrcDetails)
					
					// check which dictionaries still need matching
					set tDictId="", tIsOK=1
					for {
						set tDictId = $o(tDictIds(tDictId))
						quit:tDictId=""
						
						$$$IKBITOFFPOS(tSrcId,tSrcOff,tSrcPos)
						set tLastDE = ""
						for {
							set tLastDE = $o(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, tDictId, tLastDE), -1)
							quit:tLastDE=""
							
							quit:$bit(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, tDictId, tLastDE, tSrcOff), tSrcPos)
						}
						set tLastDE = +tLastDE
						
						if (tLastDE < tDictIds(tDictId)) {
							set tIsOK = 0
							set cSrcDictIdsToGo(tSrcId, tDictId) = tLastDE
							set ^||%IK.Mat.DictToSrcInProgress(tDictId, tSrcId) = "" // ???
						}
					}
					continue:tIsOK
					set cSrcDetails(tSrcId) = tSrcDetails, ^||%IK.Srces(tSrcId)=""
				}
				
			} else {
				set tDictId="",tIsOK=1
				for {
					set tDictId = $o(tDictIds(tDictId))
					quit:tDictId=""
					
					set tLastDE = +$g(^IRIS.IKV.Mat.DictToSrcMatched(domainId, vSrcId, tDictId))
					
					if 'tDictIds(tDictId) || (tLastDE < tDictIds(tDictId)) {
						set tIsOK = 0
						set cSrcDictIdsToGo(vSrcId, tDictId) = tLastDE
					}
				}
				
				set:'tIsOK cSrcDetails(vSrcId) = $g(^IRIS.IKV.SrcDetails(domainId,vSrcId))
			}
			
			// now loop through the cached details and process source by source
			set tSrcId=""
			for {
				set tSrcId = $order(cSrcDetails(tSrcId),1,tSrcDetails)
				quit:tSrcId=""
				
				//if 'vSrcId {
				//	set tSrcEOBase = $li(tSrcDetails,3), tSrcEOCount = $li(tSrcDetails,4)
				//	set x = $prefetchon(^IRIS.IK.EntOccId(domainId, tSrcEOBase+1),^IRIS.IK.EntOccId(domainId, tSrcEOBase+tSrcEOCount+1))
				//}
				
				set tSentBase = $list(tSrcDetails, 1), tSentCount = $list(tSrcDetails, 2)
				set tSentFrom = tSentBase+1, tSentTo = tSentBase+tSentCount
				
				// BDB396 - preload negation results
				set tPathBase = $lg(tSrcDetails,7), tPathCount = $lg(tSrcDetails,8)
				set tPathFrom = tPathBase+1, tPathTo = tPathBase+tPathCount
				kill tSentAttributes, tPathAttributes
				for tSentId = tSentFrom:1:tSentTo {
					set tPos=""
					for {
						set tPos = $order(@gAttSent@(tSentId, $$$IKATTNEGATION, tPos), 1, tInfo)
						quit:tPos=""
						
						set tEndPos = tPos+$lg(tInfo,1)-1
						for i = tPos:1:tEndPos {
							set tSentAttributes(tSentId, i) = ""
						}
					}
				}
				for tPathId = tPathFrom:1:tPathTo {
					set tPos=""
					for {
						set tPos = $order(@gAttPath@(tPathId, $$$IKATTNEGATION, tPos), 1, tInfo)
						quit:tPos=""
						
						set tEndPos = tPos+$lg(tInfo,1)-1
						for i = tPos:1:tEndPos {
							set tPathAttributes(tPathId, i) = ""
						}
					}
				}
				
		    	for sentId = tSentFrom:1:tSentTo {
		    		set sentDetails = $g(@sentDetailsGlo@(sentId))
		    		set sentLang = +$lg(sentDetails, 1)
		    		set tStdFormLangId = $s(tUseStandardizedForm:sentLang, 1:0)
			        set tPartBase = $lg(sentDetails, 4)
			        set tPartCount = $lg(sentDetails, 5)
			        
		    		kill ^||%IK.Mat.Candidate, ^||%IK.Mat.CandByScore, ^||%IK.Mat.CandByEntOcc
		    		kill ^||%IK.PathMatches, ^||%IK.CrcMatches, ^||%IK.SentMatches, ^||%IK.EntMatches
		    		kill ^||%IK.PathRels, ^||%IK.CrcRels, ^||%IK.SentRels
		    		
			        set pathId = 0, crcIdM=0, crcIdR=0, crcIdS=0
				    for tPartId = (tPartBase+1):1:(tPartBase+tPartCount) {
				        set entOccDetails = $g(@entOccIdGlo@(tPartId))
				        continue:entOccDetails=""
			        	
			            set role = $list(entOccDetails, 2)
			            
			            // BDB577
			            continue:role=$$$ENTTYPENONREL
			        
			        	// BDB623 - when using stemmed matching, look up the stem's ID and proceed as normal
			        	if (tUseStemming) {
				        	set entUniId = +$lg(entOccDetails, 10)
				        	continue:'entUniId
			        	} else {
				        	set entUniId = $list(entOccDetails, 1)
			        	}
			            
				        set sentId=+$lg(entOccDetails,3)
				        set posInSent=+$lg(entOccDetails,4)
				        set crcIdR=+$lg(entOccDetails,6)
				        set pathId=+$lg(entOccDetails,8)
				        set posInPath=+$lg(entOccDetails,9)
				        
				        // BDB396 - is this entity part of a negation?
				        set tEntNegated = $d(tSentAttributes(sentId, posInSent))
				        set:'tEntNegated&&pathId tEntNegated = $d(tPathAttributes(pathId, posInPath))
			            
			            // queue relation entities for later processing, as they would slow down
			            // the gathering of candidate matches significantly
			            if 'entLevelMatchOnly && ((role=$$$ENTTYPERELATION) || (role=$$$ENTTYPEPATHREL)) && ikpMatSkipRelations {
				            set ^||%IK.SentRels(sentId, tPartId) = $lb(entUniId, posInSent, tEntNegated, role)
				            set:pathId ^||%IK.PathRels(pathId, tPartId) = $lb(entUniId, posInPath, tEntNegated, role)
				            set:crcIdR ^||%IK.CrcRels(crcIdR, tPartId) = $lb(entUniId, 2, tEntNegated, role)
				            
				            // register role positions to calculate relationshiop lengths later on
				            set $bit(^||%IK.SentMatches(sentId),posInSent) = 1
				            set:pathId $bit(^||%IK.PathMatches(pathId),posInPath) = 1
				            continue
			            }
			            
			            //set:'vSrcId x = $prefetchon(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId))
		            
			            // now look at the matched DEs for this EU      
				        set deId = $s(xDomDicts:"", 1:0)
				        for {
					        set matchDetails=""
				            set deId = $order(@entUniToDictElemGlo@(entUniId, deId), 1, matchDetails)
				            quit:deId=""
				            quit:xDomDicts&&(deId>0)
				            
				            // fetch the DE info (from the cached local var if possible)
				            do ..GetCachedElement(tDictDomainId, deId, .de, .dtId, .diId, .dictId)
	            
				            // skip if we're not interested in this Dictionary
				            continue:'$d(cSrcDictIdsToGo(tSrcId, dictId),lastDE)
			            
				            // skip if we already have data for this DE
				            continue:$zabs(deId)<=+lastDE
			                
			                // if the required role is not met, skip
			                if (($list(de, 6) '= $$$DMROLEUNDEFINED) && ($list(de, 6) '= role)) {
			                    continue
			                }
			                
				            // BDB276: use standardized-form results if we have them
				            if (tUseStandardizedForm'="") && (tUseStandardizedForm'=$$$IKPMATSTANDARDIZEDFORMSTEMMING) {
				            	set:$d(@entUniToDictElemGlo@(entUniId,deId,sentLang),standardizedDetails) matchDetails = standardizedDetails
				            }
				            // skip if there is no result for this sentences language or the generic level
				            continue:matchDetails=""
			
			                set matchScore = $list(matchDetails,1)

			                // if the required match level is not met, skip
			                // TODO: this might have become obsolete
			                if (($list(de, 7) '= $$$DMSCOREUNDEFINED) && ($list(de, 7) > matchScore)) {
			                    continue
			                }
	                
	                		// pick the right profile
	                		#dim profile As %iKnow.Matching.MatchingProfile
			                set profile = $g(dictProfiles(dictId),dictProfiles)
	                
			                // calculate the entity-level score:
			                // 1. use the appropriate weight for this match level and dict element
			                set entLevelScore = matchScore * $lg(de,9,1)
			                
			                // punish scattered matches
			                set:$lg(matchDetails,3) entLevelScore = entLevelScore * profile.ScatteredMatchMultiplier
		    				
		    				// punish relationships
		    				set:role=$$$ENTTYPERELATION entLevelScore = entLevelScore * profile.RelationshipScoreMultiplier
		    				set:role=$$$ENTTYPEPATHREL entLevelScore = entLevelScore * profile.PathRelevantScoreMultiplier
		    				
		    				// BDB296 - punish negations
		    				set:tEntNegated entLevelScore = entLevelScore * profile.NegationMultiplier
		    				
			                // store the DE hit if there's only 1 part
			                set termLength = $list(de, 8)
			                if (termLength = 1) {
				                
				                continue:(entLevelScore<profile.MinimalMatchScore)
				                
		    					//$$$IKQTIC("StoreSingle")
		    					
			                    // store the MatchOcc
		    					// ^IRIS.IK.Mat.MatchId(domId, matchId) = $lb(dictId, diId, +dtId, targetType, targetId, totalScore, matchedConcepts, matchedRelations, partialMatchCount, firstPosInPath, lastPosInPath, isInOrder, negatedCount)
				                set matchInfo = $lb(dictId, diId, +dtId, $$$DMTARGETENTITY, tPartId, entLevelScore, $s(role=$$$ENTTYPECONCEPT:1, 1:0), $s(role=$$$ENTTYPERELATION:1, 1:0), (entLevelScore<1), 1, 1, 1, tEntNegated)
		                    	
		                    	if (matchScoreMargin<0) {
				                    set matchId = $i(@matchIncGlo)
				                    set ^||%IK.Mat.NewMatches(matchId)=""
				                    set @matchIdGlo@(matchId) = matchInfo
	                    
				                    // and also update the indices and staging parts
				                    set @dictToMatchGlo@(dictId, matchId) = ""
				                    set @dictItemToMatchGlo@(diId, matchId) = ""
				                    set @entOccToMatchGlo@(tPartId, matchId, deId) = entLevelScore
				                    set @sentToMatchGlo@(sentId, -matchScore, matchId) = ""
				                    set:'vSrcId @dictToSrcGlo@(dictId, tSrcId) = ""
				                    set:'vSrcId @srcToMatchGlo@(tSrcId, matchId) = ""
		    					} else {
		                    		set candId = $i(^||%IK.Mat.CandidByScore)
		                    		set ^||%IK.Mat.Candidate(candId) = $lb(dictId, entLevelScore, $lb(tPartId), matchInfo, $lb(tPartId))
		                    		set ^||%IK.Mat.CandByScore(dictId, -entLevelScore, candId) = ""
		                    		set ^||%IK.Mat.CandByEntOcc(dictId, tPartId, candId) = $lb(deId, entLevelScore)
		    					}
		    					//$$$IKQTOC("StoreSingle")
	            
			                // DE's with a single part never bubble up
			                } else {
			                
				                // skip storing parts for CRC and path levels if we only want 
				                // entity-level matches
				                continue:entLevelMatchOnly
			                    
			                    if (termLength >= profile.MinTermLengthForSent) {
				                    set ^||%IK.SentMatches(sentId, dtId, $li(de,5), tPartId, deId) = $lb(role, posInSent, entLevelScore, tEntNegated)
					                if (role=$$$ENTTYPECONCEPT) {
						                set ^||%IK.SentMatches(sentId, dtId, $li(de,5)) = 1
						                set $bit(^||%IK.SentMatches(sentId, dtId), posInSent) = (entLevelScore>0)
					                } else {
						                set $bit(^||%IK.SentRels(sentId, dtId), posInSent) = (entLevelScore>0)
					                }
			                    }
		                    
			                    // treat paths
			                    if pathId && (termLength >= profile.MinTermLengthForPath) {
					                set ^||%IK.PathMatches(pathId, dtId, $li(de,5), tPartId, deId) = $lb(role, posInPath, entLevelScore, tEntNegated)
					                if (role=$$$ENTTYPECONCEPT) {
						                set ^||%IK.PathMatches(pathId, dtId, $li(de,5)) = 1
						                set $bit(^||%IK.PathMatches(pathId, dtId), posInPath) = (entLevelScore>0)
					                } else {
						                set $bit(^||%IK.PathRels(pathId, dtId), posInPath) = (entLevelScore>0)
					                }
			                    }
		                    
			                    // treat CRCs
			                    if (termLength <= profile.MaxTermLengthForCrc) {
					                set crcIdM=+$lg(entOccDetails,5)
					                set crcIdR=+$lg(entOccDetails,6)
					                set crcIdS=+$lg(entOccDetails,7)
					                if crcIdM {
						                set ^||%IK.CrcMatches(crcIdM, dtId, $li(de,5)) = 1
			    	                	set ^||%IK.CrcMatches(crcIdM, dtId, $li(de,5), tPartId, deId) = $lb(role, 1, entLevelScore, tEntNegated)
			        	            	set $bit(^||%IK.CrcMatches(crcIdM, dtId),1) = (entLevelScore>0)
					                }
					                if crcIdR {
			    	                	set ^||%IK.CrcMatches(crcIdR, dtId, $li(de,5), tPartId, deId) = $lb(role, 2, entLevelScore, tEntNegated)
			    	                	set $bit(^||%IK.CrcRels(crcIdR, dtId),2) = (entLevelScore>0)
					                }
					                if crcIdS {
						                set ^||%IK.CrcMatches(crcIdS, dtId, $li(de,5)) = 1
			            	        	set ^||%IK.CrcMatches(crcIdS, dtId, $li(de,5), tPartId, deId) = $lb(role, 3, entLevelScore, tEntNegated)
			                		    set $bit(^||%IK.CrcMatches(crcIdS, dtId),3) = (entLevelScore>0)
					                }
			                    }
			                    
			                    // BDB787 - try composite terms mapping to a single multi-word entity
			                    set tMask = $lg(matchDetails,2)
			                    if $bitcount(tMask)>1 {
				                    // only bother if they add a contribution
				                    set tOldMask = $g(^||%IK.EntMatches(tPartId, dtId, "m")), tMask = $bitlogic(tOldMask | tMask)
				                    if $bitcount(tOldMask,1) < $bitcount(tMask,1) {
					                    set ^||%IK.EntMatches(tPartId) = $lb(role,posInPath,tEntNegated)
					                    set ^||%IK.EntMatches(tPartId, dtId, deId) = matchDetails
					                    set x=$i(^||%IK.EntMatches(tPartId, dtId))
					                    set ^||%IK.EntMatches(tPartId, dtId, "m") = tMask
				                    }
			                    }
			                }
			            }
			            
			            //set:'vSrcId x = $prefetchoff(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId))
			        }
			        
			        // BDB787 - process composite terms matching to a single entity
			        set tPartId=""
			        for {
				        set tPartId = $order(^||%IK.EntMatches(tPartId),1,tPartInfo)
				        quit:tPartId=""
				        
				        set tRole=$lg(tPartInfo,1), tPosInPath=$lg(tPartInfo,2),tEntNegated=$lg(tPartInfo,3)
				        set dtId=""
				        for {
					        set dtId = $order(^||%IK.EntMatches(tPartId,dtId),1,tCount)
					        quit:dtId=""
					     	continue:tCount<2
					     	
					     	kill deIds
					     	set tDictDomId = $s(dtId<0:0, 1:domainId),
					     		tMask=$g(^||%IK.EntMatches(tPartId,dtId,"m")), 
					     		tScattered=0, matchedEntOccs="", entOccsToSkip="",
					     		deId=""
					     	for {
						     	set deId = $order(^||%IK.EntMatches(tPartId,dtId,deId),1,tElemData)
						     	quit:deId=""
						     	continue:deId="m"
						     	set:'tScattered tScattered = +$lg(tElemData,3)
						     	set deIds(deId) = +$lg(tElemData,1)
						     	
						     	if (matchScoreMargin>=0) {
						            set matchedEntOccs = matchedEntOccs _ $lb(tPartId)
						            if ($d(matchedEOs(tPartId+1)) && $d(matchedEOs(tPartId-1))) {
							            set entOccsToSkip = entOccsToSkip _ $lb(tPartId)
						            }
						     	}
					     	}
					     	
					     	do ..GetCachedTerm(tDictDomId,dtId,.diId,.dictId,0)
					     	set profile = $g(dictProfiles(dictId),dictProfiles)
					     	set tTermLength = ..GetCachedTermLength(tDictDomId,dtId,profile,.termConceptCount)
					     	
					     	// skip if not containing "enough" concepts
					     	if profile.MinMatchedConceptFraction && termConceptCount && (tRole'=$$$ENTTYPECONCEPT) {
						     	continue
					     	}
					     	set tMatchedLength = tCount * $s(tRole=$$$ENTTYPECONCEPT:1, 1:profile.RelationshipLengthMultiplier)
					     	
					     	// build score from scratch looking at aggregate word mask + apply multipliers
					     	set tTotalScore = $bitcount(tMask,1) / $bitcount(tMask)
					     	set tTotalScore = tTotalScore * (tMatchedLength / tTermLength)
					     	set:tScattered tTotalScore = tTotalScore * profile.ScatteredMatchMultiplier
					     	set:tRole=$$$ENTTYPERELATION tTotalScore = tTotalScore * profile.RelationshipScoreMultiplier
					     	set:tRole=$$$ENTTYPEPATHREL tTotalScore = tTotalScore * profile.PathRelevantScoreMultiplier
					     	set:tEntNegated tTotalScore = tTotalScore * profile.NegationMultiplier
					     	continue:tTotalScore<profile.MinimalMatchScore
					     	set matchInfo = $lb(dictId, diId, +dtId, $$$DMTARGETENTITY, +tPartId, tTotalScore, tRole=$$$ENTTYPECONCEPT, tRole=$$$ENTTYPERELATION, 1, tPosInPath, tPosInPath, 1)
					     	
	                    	if (matchScoreMargin<0) {
			                    set matchId = $i(@matchIncGlo)
			                    set ^||%IK.Mat.NewMatches(matchId)=""
			                    set @matchIdGlo@(matchId) = matchInfo
                    
			                    // and also update the indices and staging parts
			                    set @dictToMatchGlo@(dictId, matchId) = ""
			                    set @dictItemToMatchGlo@(diId, matchId) = ""
			                    merge @entOccToMatchGlo@(tPartId, matchId) = deIds
			                    set @sentToMatchGlo@(sentId, -tTotalScore, matchId) = ""
			                    set:'vSrcId @dictToSrcGlo@(dictId, tSrcId) = ""
			                    set:'vSrcId @srcToMatchGlo@(tSrcId, matchId) = ""
	    					} else {
	                    		set candId = $i(^||%IK.Mat.CandByScore)
	                    		set ^||%IK.Mat.Candidate(candId) = $lb(dictId, tTotalScore, matchedEntOccs, matchInfo, entOccsToSkip)
	                    		set ^||%IK.Mat.CandByScore(dictId, -tTotalScore, candId) = ""
	                    		set ^||%IK.Mat.CandByEntOcc(dictId, tPartId, candId) = $lb($o(deIds(""),1,entLevelScore), entLevelScore)
	    					}
	    					
				        }
			        }
			        kill ^||%IK.EntMatches
		        
			        // process any queued paths and CRCs for this sentence
			        set pathId = ""
			        for {
				        set pathId = $o(^||%IK.PathMatches(pathId))
				        quit:pathId=""
				        do ..ProcessAggregate(domainId, $$$DMTARGETPATH, +pathId, .dictProfiles, tSrcId, vSrcId, .matchIdGlo, .matchIncGlo, .dictToMatchGlo, .entOccToMatchGlo, .dictItemToMatchGlo, .dictToSrcGlo, .srcToMatchGlo, $ll(@pathEntOccGlo@(pathId)), .sentToMatchGlo, sentId, matchScoreMargin, tStdFormLangId, ikpMatSkipRelations)
			        }
			        set crcId = ""
			        for {
				        set crcId = $o(^||%IK.CrcMatches(crcId))
				        quit:crcId=""
				        do ..ProcessAggregate(domainId, $$$DMTARGETCRC, +crcId, .dictProfiles, tSrcId, vSrcId, .matchIdGlo, .matchIncGlo, .dictToMatchGlo, .entOccToMatchGlo, .dictItemToMatchGlo, .dictToSrcGlo, .srcToMatchGlo, 3, .sentToMatchGlo, sentId, matchScoreMargin, tStdFormLangId, ikpMatSkipRelations)
			        }
			        kill ^||%IK.PathMatches, ^||%IK.CrcMatches
			        kill ^||%IK.PathRels, ^||%IK.CrcRels
			        
			        do ..ProcessAggregate(domainId, $$$DMTARGETSENT, +sentId, .dictProfiles, tSrcId, vSrcId, .matchIdGlo, .matchIncGlo, .dictToMatchGlo, .entOccToMatchGlo, .dictItemToMatchGlo, .dictToSrcGlo, .srcToMatchGlo, $lg(sentDetails,5), .sentToMatchGlo, sentId, matchScoreMargin, tStdFormLangId, ikpMatSkipRelations)
			        kill ^||%IK.SentMatches, ^||%IK.SentRels
			        
			        do:(matchScoreMargin>=0) ..ProcessCandidates(tSrcId, vSrcId, .matchIdGlo, .matchIncGlo, .dictToMatchGlo, .entOccToMatchGlo, .dictItemToMatchGlo, .dictToSrcGlo, .srcToMatchGlo, .sentToMatchGlo, sentId, matchScoreMargin)
		    		kill ^||%IK.Mat.Candidate, ^||%IK.Mat.CandByScore, ^||%IK.Mat.CandByEntOcc
		    	}

				//set:'vSrcId x = $prefetchon(^IRIS.IK.EntOccId(domainId, tSrcEOBase+1),^IRIS.IK.EntOccId(domainId, tSrcEOBase+tSrcEOCount+1))
			}
			
			quit:vSrcId
		}
	    kill %DictElemCache, %DictTermCache
	    kill ^||%IK.PathMatches, ^||%IK.CrcMatches, ^||%IK.SentMatches
	    kill ^||%IK.PathRels, ^||%IK.CrcRels, ^||%IK.SentRels
		
	    set x = $sortend(@dictToMatchGlo)
	    set x = $sortend(@entOccToMatchGlo)
		set x = $sortend(@dictItemToMatchGlo)
		set x = $sortend(@sentToMatchGlo)
	    set:'vSrcId x = $sortend(@srcToMatchGlo)
	    set:'vSrcId x = $sortend(@dictToSrcGlo)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
    // if everything went fine, we can store the InProgress list
    if $$$ISOK(tSC) {
		merge:'vSrcId ^IRIS.IKT.Mat.DictToSrcMatched(domainId) = ^||%IK.Mat.DictToSrcInProgress
    } else {
	    
		set ^IRIS.IKL.Mat.Errors(domainId, $i(^IRIS.IKL.Mat.Errors(domainId))) = $lb($g(srcId), tSC, $h)
	    
		try {
		    // if things went wrong, we need to clean up
		    if vSrcId || (procN>0) {
		    
			    // for multi-process or virtual runs, we can simply drop the globals
			    kill @dictToMatchGlo, @entOccToMatchGlo, @dictItemToMatchGlo, @sentToMatchGlo
			    kill:'vSrcId @dictToSrcGlo, @srcToMatchGlo
		    
			} else {
			
				// temp globals can be killed right away
				kill @dictToMatchGlo, @dictToSrcGlo
			
				// for srces and EOs, we'll have to dig deeper
				set srcId = ""
			    for {
				    set srcId = $order(^||%IK.Srces(srcId))
				    quit:srcId=""
			    
					$$$IKBITOFFPOS(srcId,off,pos)
				
				    if ($isobject(tFilter)) {
					    continue:'$bit(tFilter.GetSourceFilter(off),pos)
				    }
			    
				    kill @srcToMatchGlo@(srcId)
			    
				    // clean entOccToMatchGlo
				    set srcDetails = $g(^IRIS.IK.SrcDetails(domainId,srcId))
				    set eoBase = $list(srcDetails, 3)
		        	set eoCount = $list(srcDetails, 4)
			    	for entOccId = (eoBase+1):1:(eoBase+eoCount) {
				    	kill @entOccToMatchGlo@(entOccId)
			    	}
		    	
			    	set sentBase = $list(srcDetails, 1)
			    	set sentCount = $list(srcDetails, 2)
			    	for sentId = (sentBase+1):1:(sentBase+sentCount) {
				    	kill @sentToMatchGlo@(sentId)
			    	}
			    }
		    
			    // and finally dictItemToMatchGlo
			    set di=""
			    for {
				    set di = $order(@dictItemToMatchGlo@(di))
				    quit:di=""
			    
				    set m=""
				    for {
					    set m = $order(@dictItemToMatchGlo@(di,m))
					    quit:m=""
				    
					    kill:$d(^||%IK.Mat.NewMatches(m)) @dictItemToMatchGlo@(di,m)
				    }
			    }
			}
		    
		    // and drop all new matches
		    set m=""
		    for {
			    set m = $o(^||%IK.Mat.NewMatches(m))
			    quit:m=""
			    kill @matchIdGlo@(m)
		    }
		} catch (ex) {
			// ignore cleanup error as to not overwrite actual one
		}
    }
    
    // mark this process as finished
    if (procN) {
		set ^IRIS.Temp.IK.Mat.SrcProc(tTempId,procN) = tSC
		set $bit(^IRIS.Temp.IK.Mat.SrcProc(tTempId),procN) = 1
    }

    kill ^||%IK.Mat.DictToSrcInProgress, ^||%IK.Mat.NewMatches, ^||%IK.Srces
    
    $$$IKRestoreJournal // BDB572
    
    quit tSC
}

ClassMethod ProcessCandidates(srcId, vSrcId, ByRef matchIdGlo, ByRef matchIncGlo, ByRef dictToMatchGlo, ByRef entOccToMatchGlo, ByRef dictItemToMatchGlo, ByRef dictToSrcGlo, ByRef srcToMatchGlo, ByRef sentToMatchGlo, sentId, matchScoreMargin) As %Status [ Internal ]
{
  	//$$$IKQTIC("ProcessCandidates")	
	// goal:
	// ^||%IK.Mat.Candidate(candId) = $lb(dictId, score, $lb(matchedEntOccs...), $lb(matchInfo...), $lb(entOccsToSkip...))
	// ^||%IK.Mat.CandByScore(dictId,-score,candId) = ""
	// ^||%IK.Mat.CandByEntOcc(dictId,entOccId,id) = $lb(deId, eoScore)
	    		
	set dictId=""
	for {
		set dictId = $order(^||%IK.Mat.CandByScore(dictId))
		quit:dictId=""
		
		set xDomDicts = (dictId<0)
		
		kill highScores
		set score=""
		for {
			set score = $order(^||%IK.Mat.CandByScore(dictId,score))
			quit:score=""
			
			// now loop over and store all of these entries
			set candId = ""
			for {
				set candId = $order(^||%IK.Mat.CandByScore(dictId,score,candId))
				quit:candId=""
				
				set candInfo = ^||%IK.Mat.Candidate(candId)
				set matchInfo = $li(candInfo,4)
				
				// store the match candidate
		        set matchId = $i(@matchIncGlo)
		        set ^||%IK.Mat.NewMatches(matchId)=""
		        set @matchIdGlo@(matchId) = matchInfo

		        // and also update the indices and staging parts
		        set @dictToMatchGlo@(dictId, matchId) = ""
		        set @dictItemToMatchGlo@($li(matchInfo,2), matchId) = ""
		        set @sentToMatchGlo@(sentId, score, matchId) = ""
		        set:'vSrcId @dictToSrcGlo@(dictId, srcId) = ""
		        set:'vSrcId @srcToMatchGlo@(srcId, matchId) = ""
		        
		        set entOccs = $li(candInfo,3), eoLength = $ll(entOccs)
		        for i=1:1:eoLength {
		            set eo = $li(entOccs,i)
		            set eoInfo = ^||%IK.Mat.CandByEntOcc(dictId, eo, candId)
		            set @entOccToMatchGlo@(eo, matchId, $li(eoInfo,1)) = $li(eoInfo,2)
		            set:'$d(highScores(eo)) highScores(eo) = $zabs(score)
		        }
				
				// now delete all other matches for this Dictionary for these EOs if they
				// don't fall within the score margin of the highest score for this dict
				set skipEOs = $lg(candInfo,5), skipEOCount = $ll(skipEOs)
				for i=1:1:skipEOCount {
		            set eo = $li(skipEOs,i)
					
					set otherCandidate=""
					for {
						set otherCandidate = $order(^||%IK.Mat.CandByEntOcc(dictId, eo, otherCandidate))
						quit:otherCandidate=""
						
						set otherScore = $li(^||%IK.Mat.Candidate(otherCandidate),2)
						set bestScore = +$g(highScores(eo)) // BDB533
						
						continue:'bestScore
						if (otherScore < (bestScore-matchScoreMargin)) {
							set otherCandInfo = ^||%IK.Mat.Candidate(otherCandidate)
							set otherEOs = $li(otherCandInfo,3), otherEOCount=$ll(otherEOs)
							for j=1:1:otherEOCount {
								set otherEO = $li(otherEOs,j)
								kill ^||%IK.Mat.CandByEntOcc(dictId,otherEO,otherCandidate)
							}
							kill ^||%IK.Mat.CandByScore(dictId,-$li(otherCandInfo,2),otherCandidate)
							kill ^||%IK.Mat.Candidate(otherCandidate)
						}
					}
				}
			}
		}
		
		kill ^||%IK.Mat.CandByScore(dictId), ^||%IK.Mat.CandByEntOcc(dictId)
	}
  	//$$$IKQTOC("ProcessCandidates")
	quit $$$OK
}

/// domainId = 0 and deId < 0 for cross-domain dictionaries; returned ids are also <0
ClassMethod GetCachedElement(domainId, deId, Output deInfo, Output dtId = "", Output diId = "", Output dictId = "") As %Status [ Internal, Private ]
{
	if ($s<500000) {
		k %DictElemCache, %DictTermCache
	}
	
    if ('$data(%DictElemCache(deId), deInfo)) {
        set deInfo = ^IRIS.IK.Mat.DictElementId(domainId, $zabs(deId))
        set dictId = $li(deInfo,1), dtId = $li(deInfo,2)
        set:'domainId dictId = -dictId, $li(deInfo,1) = dictId, dtId = -dtId, $li(deInfo,2) = dtId
        do ..GetCachedTerm(domainId, dtId, .diId,, 0)
        set %DictElemCache(deId) = deInfo
        set %DictElemCache(deId, 0) = diId
    } else {
        set diId = %DictElemCache(deId, 0)
    	set dictId = $list(deInfo,1)
    	set dtId = $list(deInfo,2)
    }
    quit $$$OK
}

/// domainId = 0 and dtId < 0 for cross-domain dictionaries; returned ids are also <0
ClassMethod GetCachedTerm(domainId, dtId, Output diId = "", Output dictId = "", getElems, Output elems = "", Output relCount = "") As %Status [ Internal ]
{
	if ($s<500000) {
		k %DictElemCache, %DictTermCache
	}
	
    if ('$data(%DictTermCache(dtId), dt)) {
	    set dt = ^IRIS.IK.Mat.DictTermId(domainId, $zabs(dtId))
	    set diId = $li(dt,2), dictId = $li(dt,1)
	    set:'domainId diId=-diId, dictId=-dictId, $li(dt,2) = diId, $li(dt,1) = dictId
	    set dt = $lb(dictId, diId)
	    set %DictTermCache(dtId) = dt
    } else {
        set diId = $li(dt,2), dictId = $li(dt,1)
    }
    if (getElems) {
	    set elems = $lg(dt,3), relCount = $lg(dt,4,-1)
	    if (elems="") {
		    set elems = ^IRIS.IK.Mat.DictTermElems(domainId,$zabs(dtId))
		    if 'domainId { set p=0,els="" while $listnext(elems,p,e) { set els=els_$lb(-e) } set elems = els }
			set %DictTermCache(dtId) = $lb(dictId, diId, elems, -1)
	    }
    }
    quit $$$OK
}

ClassMethod GetCachedTermLength(domainId, dtId, profile, Output conceptCount As %Integer = -1, Output relCount As %Integer = -1) As %Integer [ Internal, Private ]
{
	//$$$IKQTIC("GetCachedTermLength")
	do ..GetCachedTerm(domainId, dtId,.diId,.dictId,1,.elems,.relCount)
	set termLength = $ll(elems)
	if (relCount<0) {
		set relCount=0
		for e=1:1:termLength {
			set eId = $li(elems,e)
			do ..GetCachedElement(domainId,eId,.eInfo)
			set:($lg(eInfo,6)=$$$ENTTYPERELATION) relCount = relCount+1
		}
		set %DictTermCache(dtId) = $lb(dictId, diId, elems, relCount)
	}
	set conceptCount = (termLength-relCount)
	//$$$IKQTOC("GetCachedTermLength")
	quit conceptCount + (relCount * profile.RelationshipLengthMultiplier)
}

ClassMethod ProcessAggregate(domainId, targetType, targetId, ByRef dictProfiles, srcId, vSrcId, ByRef matchIdGlo, ByRef matchIncGlo, ByRef dictToMatchGlo, ByRef entOccToMatchGlo, ByRef dictItemToMatchGlo, ByRef dictToSrcGlo, ByRef srcToMatchGlo, targetLength, ByRef sentToMatchGlo, sentId, matchScoreMargin, stdFormLangId, ikpMatSkipRelations) As %Status [ Internal, Private ]
{
	//$$$IKQTIC("ProcessAggregate")
	if (targetType = $$$DMTARGETSENT) {
		set aggMatchesGlo = "^||%IK.SentMatches("_targetId_")"
		set aggRelsGlo = "^||%IK.SentRels("_targetId_")"
		set relationPosBits = $g(@aggMatchesGlo)
	} elseif (targetType = $$$DMTARGETPATH) {
		set aggMatchesGlo = "^||%IK.PathMatches("_targetId_")"
		set aggRelsGlo = "^||%IK.PathRels("_targetId_")"
		set relationPosBits = $g(@aggMatchesGlo)
	} elseif (targetType = $$$DMTARGETCRC) {
		set aggMatchesGlo = "^||%IK.CrcMatches("_targetId_")"
		set aggRelsGlo = "^||%IK.CrcRels("_targetId_")"
		set relationPosBits="", $bit(relationPosBits,2)=1
	} else { quit $$$OK }
	
	set dtId = ""
    for {
	    // BDB318 - ensure matchedConceptsPos is reset
	    set matchedConceptsPos=""
	    
	    set dtId = $o(@aggMatchesGlo@(dtId),1,matchedConceptsPos)
    	quit:dtId=""
    	
    	set matchedConcepts = 0, termPos=""
    	for { 
    		set isMatched = 0
    		set termPos = $order(@aggMatchesGlo@(dtId,termPos),1,isMatched)
    		quit:termPos=""
    		continue:'isMatched
    		set matchedConcepts = matchedConcepts+1
    	}
    	set tDictDomId = $s(dtId<0:0, 1:domainId)
        
    	// load more info for this DictTerm
    	do ..GetCachedTerm(tDictDomId, dtId, .diId, .dictId, 1, .elems)
    	#dim profile As %iKnow.Matching.MatchingProfile
        set profile = $g(dictProfiles(dictId),dictProfiles)
        
        // BDB326 - check if MinMatchedConceptFraction condition is met, if any
        if profile.MinMatchedConceptFraction {
	        set x = ..GetCachedTermLength(tDictDomId,dtId,profile,.termConceptCount)
	        continue:termConceptCount&&((matchedConcepts/termConceptCount)<profile.MinMatchedConceptFraction)
        }
        
        // for paths and sentences, we need at least two concept matches
        if (targetType=$$$DMTARGETPATH) || (targetType=$$$DMTARGETSENT) {
	        set x = ..GetCachedTermLength(tDictDomId,dtId,profile,.termConceptCount)
	        continue:(termConceptCount>matchedConcepts)&&(matchedConcepts<2)
        } else {
	        continue:'matchedConcepts // is possible if $$$IKPMATSKIPRELATIONS=0
        }
    	
    	// now revisit relationships for this DT
    	//$$$IKQTIC("RevisitRelations")
    	if ikpMatSkipRelations {
	    	set entOccId="", elemCount=$ll(elems), matchedRelsPos=""
	    	for {
		    	set entOccId = $order(@aggRelsGlo@(entOccId),1,occDetails)
		    	quit:entOccId=""
	    	
		    	set entUniId = $li(occDetails,1)
		    	set pos = $li(occDetails,2)
		    	set negated = $li(occDetails,3)
		        set tRole = $lg(occDetails,4)
		    	for i=1:1:elemCount {
			    	set deId = $li(elems,i)
			    	if stdFormLangId {
				    	set details = $g(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId,deId,stdFormLangId))
				    	set:details="" details = $g(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId,deId))
			    	} else {
				    	set details = $g(^IRIS.IK.Mat.EntUniToDictElem(domainId,entUniId,deId))
			    	}
			    	if (details'="") {
				    	do ..GetCachedElement(tDictDomId, deId, .de)
			    	
				    	// skip if not looking for a relationship at this DE
		                continue:($list(de, 6) = $$$ENTTYPECONCEPT)
	                
		                // calculate entity-level score
		                set score = $li(details,1)
		                set score = score * $lg(de, 9, 1)
		                set:$li(details,3) score = score * profile.ScatteredMatchMultiplier
		                if tRole = $$$ENTTYPERELATION {
			                set score = score * profile.RelationshipScoreMultiplier
		                } elseif tRole = $$$ENTTYPEPATHREL {
			                set score = score * profile.PathRelevantScoreMultiplier
		                }
		                set:negated score = score * profile.NegationMultiplier
		                	                
				    	set @aggMatchesGlo@(dtId, $li(de,5), entOccId, deId) = $lb(tRole, pos, score, negated)
				    	set:(tRole=$$$ENTTYPERELATION) $bit(matchedRelsPos,pos)=(score>0)
			    	}
		    	}
	    	}
	    	//$$$IKQTOC("RevisitRelations")
    	} else {
	    	set matchedRelsPos = $g(@aggRelsGlo@(dtId))
    	}
	    set matchedRelations = $bitcount(matchedRelsPos,1)
    	
        // for CRCs, we still have to check if we have enough matches
        if (targetType=$$$DMTARGETCRC) {
	        continue:(matchedConcepts+matchedRelations)<2
        }
            
        // now calculate aggregate score and store as a path/CRC-level match.
        // When calculating a score, every EO-DE match contributes to the score,
        // even if multiple EOs match the same DE or multiple DEs match the same EO
        set gapCount=0, gapPosCount=0, isInOrder=1, prevPosInTerm=0, lowestPrevPosInPath=0
        set totalScore=0, firstPosInPath=0, lastPosInPath=0, partialMatchCount=0
        kill matchedEOs, posInTermScore
        set posInTerm = 0 // start from 0 to skip the concept count
        set tNegatedCount = 0 // BDB396
        for {
            set posInTerm = $o(@aggMatchesGlo@(dtId,posInTerm))
            quit:posInTerm=""
            
            // if the term position is undefined, we're OK for the order check
            set hasEntInOrderForPos=$s(posInTerm=$$$DMPOSUNDEFINED:1, 1:0)
            set lowestPosInPath=0
            
            set currEntOccId = ""
            for {
                set currEntOccId = $o(@aggMatchesGlo@(dtId,posInTerm,currEntOccId))
                quit:currEntOccId=""
                
                set deId = ""
                for {
                    set deId = $o(@aggMatchesGlo@(dtId,posInTerm,currEntOccId,deId),1,details)
                    quit:deId=""
                	
                	set role = $li(details,1)
                	set posInPath = $li(details,2)
                	set entLevelScore = $li(details,3)
                	set tNegatedCount = tNegatedCount+$lg(details,4)
                	set:entLevelScore<1 partialMatchCount = partialMatchCount+1
                	
                	// update firstPosInPath and lastPosInPath to track section length
                	set:'firstPosInPath||(firstPosInPath>posInPath) firstPosInPath = posInPath
                	set:'lastPosInPath||(lastPosInPath<posInPath) lastPosInPath = posInPath
                	
                	// update the score
                	set totalScore = totalScore + entLevelScore
                	set posInTermScore(posInTerm) = $g(posInTermScore(posInTerm)) + entLevelScore
                	
                	// register the match type for this EO
                	set matchedEOs(currEntOccId, deId) = entLevelScore
                    
                    // update the earliest candidate path pos for this term pos
                    if ('lowestPosInPath || (posInPath<lowestPosInPath)) && (posInPath>=lowestPrevPosInPath) {
	                    set lowestPosInPath = posInPath
                    }
                }
            }
            
            // check if we found a valid path position for this term pos
            set:'hasEntInOrderForPos hasEntInOrderForPos = lowestPosInPath>0
            set:'hasEntInOrderForPos isInOrder = 0
            
            // update gap counts since the previous path position, but only if
            // we found a decent path position
            set:lowestPosInPath gapPosCount = gapPosCount + $zabs(lowestPosInPath - (lowestPrevPosInPath+1))
            set:lowestPosInPath gapCount = gapCount + (lowestPosInPath'=(lowestPrevPosInPath+1))
            
            // update pointers for this pos
            set:lowestPosInPath lowestPrevPosInPath = lowestPosInPath
            set prevPosInTerm = posInTerm
        }
        
        // BDB787 - if we ended up matching only a single target EntOcc, skip (taken care of earlier)
        continue:firstPosInPath=lastPosInPath

        // apply order penalty if applicable
        if ('isInOrder) {
            set totalScore = totalScore * profile.DisorderMultiplier
        }
        
        // calculate total matched entity length
        set matchedLength = matchedConcepts + (matchedRelations * profile.RelationshipLengthMultiplier)
        
        // calculate matched path section length
        set matchedSectionLength=0
        for i=firstPosInPath:1:lastPosInPath {
	        if ($bit(matchedConceptsPos,i)) {
		        set matchedSectionLength = matchedSectionLength+1
	        } elseif ($bit(matchedRelsPos,i)) {
		        set matchedSectionLength = matchedSectionLength + profile.RelationshipLengthMultiplier
	        }
        }
        
        // multiply by [matchedLength] / [matched path section length]
        set totalScore = totalScore * (matchedLength / matchedSectionLength)
        
        // multiply by [matchedLength] / [total term length] 
        set totalScore = totalScore * (matchedLength / ..GetCachedTermLength(tDictDomId,dtId,profile))
        
        // multiply by aggregate multiplier
        set totalScore = totalScore * $case(targetType, $$$DMTARGETPATH:profile.PathTotalMultiplier, $$$DMTARGETCRC:profile.CrcTotalMultiplier, $$$DMTARGETSENT:profile.SentTotalMultiplier)

		// skip if we do not meet the lower tresholds
        continue:totalScore<profile.MinimalMatchScore
        
        // now store the path-level match
        set tMatchInfo = $lb(dictId, diId, +dtId, targetType, targetId, totalScore, matchedConcepts, matchedRelations, partialMatchCount, firstPosInPath, lastPosInPath, isInOrder, tNegatedCount)
        if (matchScoreMargin<0) {
	        set matchId = $i(@matchIncGlo)
	        set ^||%IK.Mat.NewMatches(matchId)=""
	        set @matchIdGlo@(matchId) = tMatchInfo

	        // and also update the indices and staging parts
	        set @dictToMatchGlo@(dictId, matchId) = ""
	        set @dictItemToMatchGlo@(diId, matchId) = ""
	        set @sentToMatchGlo@(sentId, -totalScore, matchId) = ""
	        set:'vSrcId @dictToSrcGlo@(dictId, srcId) = ""
	        set:'vSrcId @srcToMatchGlo@(srcId, matchId) = ""
	        set eo = ""
	        for {
	            set eo = $o(matchedEOs(eo))
	            quit:eo=""
	            set deId=""
	            for {
	                set deId = $o(matchedEOs(eo,deId),1,entLevelScore)
	                quit:deId=""
	                set @entOccToMatchGlo@(eo, matchId, deId) = entLevelScore
	            }
	        }
        } else {
		    set candId = $i(^||%IK.Mat.CandByScore)
	        set eo = "", matchedEntOccs = "", entOccsToSkip = ""
	        for {
	            set eo = $o(matchedEOs(eo))
	            quit:eo=""
	            set deId=""
	            for {
	                set deId = $o(matchedEOs(eo,deId),1,entLevelScore)
	                quit:deId=""
	                set ^||%IK.Mat.CandByEntOcc(dictId, eo, candId) = $lb(deId, entLevelScore)
	            }
	            set matchedEntOccs = matchedEntOccs _ $lb(eo)
	            if ($d(matchedEOs(eo+1)) && $d(matchedEOs(eo-1))) {
		            set entOccsToSkip = entOccsToSkip _ $lb(eo)
	            }
	        }
		    set ^||%IK.Mat.Candidate(candId) = $lb(dictId, totalScore, matchedEntOccs, tMatchInfo, entOccsToSkip)
		    set ^||%IK.Mat.CandByScore(dictId, -totalScore, candId) = ""
        }
    	kill matchedEOs, posInTermScore
    	
    	// if we just stored a Path or CRC match, check if we can
    	// drop the corresponding sentence level match if it doesn't have more matched concepts
    	if (targetType'=$$$DMTARGETSENT) && (matchedConcepts = $bitcount(^||%IK.SentMatches(sentId, dtId),1)) {
	    	kill ^||%IK.SentMatches(sentId, dtId)
    	}
    }
	//$$$IKQTOC("ProcessAggregate")
    quit $$$OK
}

///  Update the bitstrings based on IKT gobals generated in the MatchSource* methods
ClassMethod UpdateBitStrings(domainId As %Integer, currentDictElemsArray, vSrcId As %Integer = 0, xDomDicts As %Boolean = 0) As %Status [ Internal, Private ]
{
	// TODO: these can be run in parallel (async)
	set dictToMatchGlo = $s(vSrcId:"^||%IKV.Mat.DictToMatch", 1:"^IRIS.IKT.Mat.DictToMatch("_domainId_")")
	set dictToMatchBitGlo = $$$IKVGLOBNAME(domainId,"Mat.DictToMatchBit",vSrcId)
	set maxDE = $o(^IRIS.IK.Mat.DictElementId($s(xDomDicts:0, 1:domainId),""),-1)
	
    // now build the final indices from the basic ones
    set dictId = ""
    for {
        set dictId = $order(currentDictElemsArray(dictId))
        quit:dictId=""
        
        // build ^IRIS.IK.Mat.DictToMatchBit
        set prevOff = 0
        set bits = ""
        set dm = ""
        for {
            set dm = $order(@dictToMatchGlo@(dictId, dm))
            quit:dm=""
            
            $$$IKBITOFFPOS(dm,off,pos)
            if (off '= prevOff) { 
                set:prevOff @dictToMatchBitGlo@(dictId, prevOff) = $bitlogic(bits)
                set bits = $g(@dictToMatchBitGlo@(dictId, off))
            }
            set $bit(bits, pos) = 1
            set prevOff = off
        }
        set:prevOff @dictToMatchBitGlo@(dictId, prevOff) = $bitlogic(bits)
        
        if (vSrcId) {
	        // for a virtual source, we only have to update ^IRIS.IKV.Mat.DictToSrcMatched
	        // we can use the maximum DE id as currentDictElemsArray only counts for non-virtuals
	        merge ^IRIS.IKV.Mat.DictToSrcMatched(domainId, vSrcId, dictId) = maxDE
        	continue
        }
        
        // build ^IRIS.IK.Mat.DictToSrcBit
        set prevOff = 0, bits = "", src = ""
        for {
            set src = $order(^IRIS.IKT.Mat.DictToSrc(domainId, dictId, src))
            quit:src=""
        
            $$$IKBITOFFPOS(src,off,pos)
            if (off '= prevOff) { 
                set:prevOff ^IRIS.IK.Mat.DictToSrcBit(domainId, dictId, prevOff) = $bitlogic(bits)
                set bits = $g(^IRIS.IK.Mat.DictToSrcBit(domainId, dictId, off))
            }
            set $bit(bits, pos) = 1
            set prevOff = off
        }
        set:prevOff ^IRIS.IK.Mat.DictToSrcBit(domainId, dictId, prevOff) = $bitlogic(bits)
        
        // build ^IRIS.IK.Mat.DictToSrcMatchedBit
        set lastDictElemId = +$g(currentDictElemsArray(dictId))
        set bits = "", prevOff = 0
        set srcId = ""
        for {
            set srcId = $order(^IRIS.IKT.Mat.DictToSrcMatched(domainId, dictId, srcId))
            quit:srcId=""
        
            $$$IKBITOFFPOS(srcId,off,pos)
            if (off '= prevOff) { 
            	if (prevOff) {
                	set ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, dictId, lastDictElemId, prevOff) = $bitlogic(bits)
                	
                	// also erase older entries
                	set pde = lastDictElemId
                	for {
	                	set pde = $order(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde),-1)
	                	quit:pde=""
	                	set pb = $bitlogic(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde,prevOff) & ~bits)
	                	if $$$IKHASBIT(pb) {
		                	set ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde,prevOff) = pb
	                	} else {
		                	kill ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde,prevOff)
	                	}
                	}
            	}
                set bits = $g(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, dictId, lastDictElemId, off))
            }
            set $bit(bits, pos) = 1
            set prevOff = off
        }
        if (prevOff) {
        	set ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, dictId, lastDictElemId, prevOff) = $bitlogic(bits)
        
        	// also erase older entries
        	set pde = lastDictElemId
        	for {
            	set pde = $order(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde),-1)
            	quit:pde=""
            	set pb = $bitlogic(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde,prevOff) & ~bits)
            	if $$$IKHASBIT(pb) {
                	set ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde,prevOff) = pb
            	} else {
                	kill ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,pde,prevOff)
            	}
        	}
        }
    }
	
	kill ^IRIS.IKT.Mat.DictToSrc(domainId)
	kill ^IRIS.IKT.Mat.DictToMatch(domainId)
	kill ^IRIS.IKT.Mat.DictToSrcMatched(domainId)

    quit $$$OK
}

Parameter InvalidateMatchingResultsEXP [ Internal ] = 1;

///  <p>Deletes all current matching results for the list of Dictionary IDs passed in <var>dictIds</var>.</p>
///  <p>Specifying "" for <i>dictIds</i> will drop results for all Dictionaries in this domain.</p>
///  <p><var>pMode</var> can be used to specify whether to keep intermediary (not source-related)
///  matching results as follows:<ul><li>0: only source-related matching results are erased (default)</li>
///  <li>1: the matching results for unique entities are also erased</li><li>2: the matching
///  results for unique entities and indexing results for dictionary terms are all erased (only available if dictIds="")</li></ul>
///  This parameter is mostly for internal use.</p>
///  <p>Note: <var>pMode</var>=2 will not erase the indexing results for dictionary terms of
///  cross-domain dictionaries.<br/>
///  Note: matching results for virtual sources are always completely dropped, regardless of the 
///  value of <var>dictIds</var> and with the same effect as <var>pMode</var>=1</p>
ClassMethod InvalidateMatchingResults(domainId As %Integer, dictIds As %List = "", pMode As %Integer = 0) As %Status
{
	$$$IKCHECKPRIVWRITE
	if (domainId'=0) { $$$CHECKDOMAINEXISTS(domainId) }
	
    quit:(dictIds'="")&&(pMode=2) $$$ERROR($$$InvalidArgument)
    quit:'$lf($lb(0,1,2),pMode) $$$ERROR($$$InvalidArgument)
    
    // BDB572
    $$$IKDisableJournal(domainId)
	
	set tSC = $$$OK, tTLevel = $tlevel
	try {
		set tVersion20122 = $$$IKVERSIONBEFORE(domainId,$$$IKVERSIONMATCHING20131)
		
		tstart:'tDisableJournal
	    	
    	kill ^IRIS.IKV.Mat.EntUniToDictElem(domainId)
    	kill ^IRIS.IKV.Mat.EntOccToMatch(domainId)
    	kill ^IRIS.IKV.Mat.MatchId(domainId)
    	kill ^IRIS.IKV.Mat.MatchInc(domainId)
    	kill ^IRIS.IKV.Mat.DictItemToMatch(domainId)
    	kill ^IRIS.IKV.Mat.DictToMatchBit(domainId)
    	kill ^IRIS.IKV.Mat.DictToSrcMatched(domainId)
		
		if (dictIds'="") {
			
			$$$IKENSURELISTNUM(dictIds)
			
			// invalidate dictionary by dictionary
			set ptr=0
			while $listnext(dictIds,ptr,tDictId) {
				if (pMode=1) {
				    if tVersion20122 {
					    set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId,+tDictId))
					    continue:status=""
					    
					    set $li(status,3) = 0, $li(status,2) = 0
					    set ^IRIS.IK.Mat.DictMatchStatus(domainId,tDictId) = status
				    } else {
					    kill ^IRIS.IK.Mat.DictMatchStatus(domainId,tDictId)
				    }
				}
				
				set tSC = ..InvalidateMatchingResultsInternal(domainId, tDictId,, pMode)
		    	quit:$$$ISERR(tSC)
		    	
			    kill ^IRIS.IK.Mat.DictToSrcBit(domainId, tDictId)
			    kill ^IRIS.IK.Mat.DictToMatchBit(domainId, tDictId)
		    	kill ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId, tDictId)
			}
			
			tcommit:'tDisableJournal
			quit
		}
		
		// if dictIds = "", process all dictionaries
    	set dictIds = ..GetAllDictsAsList(domainId)
    	set:$$$IKVERSIONATLEAST(domainId,$$$IKVERSIONXDOMAIN) dictIds = dictIds _ ..GetAllDictsAsList(0)
		
	    if pMode=1 {
		    
	    	kill ^IRIS.IK.Mat.EntUniToDictElem(domainId)
	    
		    set ptr = 0
			while $listnext(dictIds,ptr,d) {
			    
			    if tVersion20122 {
				    set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId,d))
				    continue:status=""
				    
				    set $li(status,3) = 0, $li(status,2) = 0
				    set ^IRIS.IK.Mat.DictMatchStatus(domainId,d) = status
			    } else {
				    kill ^IRIS.IK.Mat.DictMatchStatus(domainId,d)
			    }
		    }
		    
	    } elseif pMode=2 {
		    
	    	kill ^IRIS.IK.Mat.EntUniToDictElem(domainId)
	    	kill ^IRIS.IK.Mat.DictMatchStatus(domainId)
	    	kill ^IRIS.IK.Mat.DictElement(domainId)
	    	kill ^IRIS.IK.Mat.DictElemString(domainId)
	    	kill ^IRIS.IK.Mat.DictElemStringId(domainId)
	    	
	    	// BDB549 - go through elements one by one to avoid dropping single-format-terms
	    	kill ^||%IK.TermsToKill
	    	set tElementId = ""
	    	for {
		    	set tElementId = $order(^IRIS.IK.Mat.DictElementId(domainId,tElementId), 1, tElement)
		    	quit:tElementId=""
		    	
			    set tTermId = $zabs($lg(tElement,2))
		    	if ($lg(tElement,3)=$$$DEFORMAT)  {
			    	
			    	set tFormatId = $lg(tElement,4)
			    	
			    	// verify if not in processeable @@@ syntax
			    	// (in which case they can and should be deleted)
			    	if ($lg(tElement,8)=1) && '$lg(^IRIS.IK.Mat.DictTermId(domainId,tTermId),4) {
				    	continue
			    	}
			    	
			    	// kill remaining format-to-element reference
			    	kill ^IRIS.IK.Mat.DictFormatElements(domainId,tFormatId,tElementId)
		    	}
			    
			    kill ^IRIS.IK.Mat.DictElementId(domainId,tElementId)
			    set ^||%IK.TermsToKill(tTermId)=""
	    	}
	    	set tTermId=""
	    	for {
		    	set tTermId = $order(^||%IK.TermsToKill(tTermId))
		    	quit:tTermId=""
		    	kill ^IRIS.IK.Mat.DictTermElems(domainId,tTermId)
	    	}
	    	kill ^||%IK.TermsToKill
	    	
	    	
	    	if tVersion20122 {
		    	set tDTId = ""
		    	for {
			    	set tDTId = $order(^IRIS.IK.Mat.DictTermId(domainId,tDTId))
			    	quit:tDTId=""
			    	set $li(^IRIS.IK.Mat.DictTermId(domainId,tDTId),5) = $$$DTUNPROCESSED
		    	}
	    	}
	    }
	    
   		kill ^IRIS.IK.Mat.EntOccToMatch(domainId)

	    kill ^IRIS.IK.Mat.MatchId(domainId)
	    kill ^IRIS.IK.Mat.MatchInc(domainId)

	    kill ^IRIS.IK.Mat.DictItemToMatch(domainId)
	    kill ^IRIS.IK.Mat.SrcToMatch(domainId)
	
	    kill ^IRIS.IK.Mat.DictToSrcBit(domainId)
	    kill ^IRIS.IK.Mat.DictToMatchBit(domainId)

    	kill ^IRIS.IK.Mat.DictToSrcMatchedBit(domainId)
    	
    
		// BDB624 - check if there are any customizations to sync
		set tTablesPackage = $s(domainId:$$$GETPARAMNODEF(domainId,$$$IKPPACKAGE),1:"")
		if (tTablesPackage'="") && $classmethod(tTablesPackage_".DictionaryMatch","%HasCustomizations") {
		    set tSC = $classmethod(tTablesPackage_".DictionaryMatch","%PurgeIndices")
		    quit:$$$ISERR(tSC)
		}
	    
		tcommit:'tDisableJournal
	} catch(ex) {
		set tSC = ex.AsStatus()
	}
	trollback:($tlevel>tTLevel)&&'tDisableJournal 1
	
	$$$IKRestoreJournal // BDB572
	
    quit tSC
}

/// Clears all the matching results for a particular Dictionary Item <var>pDictItemId</var> in
/// Dictionary <var>pDictId</var>, optionally narrowed down to a Dictionary Term <var>pDictTermId</var>.
/// <var>pMode</var> values: 0 drops source-level results, 1 drops EU mappings as well and 2
/// also drops the term's indexing results (dictionary elements).
/// If dropping the results for a cross-domain item in a specific domain, all IDs passed in should
/// be negative.
/// This method is for internal use only, as it does not update ^IRIS.IK.Mat.DictMatchStatus!
ClassMethod InvalidateMatchingResultsInternal(pDomainId As %Integer, pDictId As %Integer, pDictItemId As %Integer = "", pMode As %Integer = 0, pDictTermId As %Integer = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if (pDomainId'=0) {
			if (pMode=2) && (pDictItemId<0) { set tSC = $$$ERROR($$$InvalidArgument) quit }
			set tVersion20122 = $$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONMATCHING20131)
		} else {
			set tVersion20122 = ($g(^IRIS.IK.Mat.DictId) < $$$IKVERSIONMATCHING20131)
		}
		
		// BDB624 - check if there's any customizations to sync
		set tHasCustomizations = 0
		set tTablesPackage = $s(pDomainId:$$$GETPARAMNODEF(pDomainId,$$$IKPPACKAGE),1:"")
		if (tTablesPackage'="") {
			new %ikSafeDelete
			set %ikSafeDelete = 1
		    set tHasCustomizations = $classmethod(tTablesPackage_".DictionaryMatch","%HasCustomizations")
		}
		
	    // drop DI-level match results
	    set tMatchDomId = $s(pDomainId:pDomainId-1, 1:"")
	    set tMatchDictId = $s(pDomainId:pDictId, 1:-$zabs(pDictId))
	    set:pDictItemId tMatchDictItemId = $s(pDomainId:pDictItemId, 1:-$zabs(pDictItemId))
	    for {
		    set tMatchDomId = $order(^IRIS.IK.Mat.DictItemToMatch(tMatchDomId))
		    quit:tMatchDomId=""
		    quit:pDomainId&&(tMatchDomId'=pDomainId)
		    
		    set matchId = "", tMatchIdOffset="", tMatchIdPos=0, tMatchIdBits = ""
		    for {
			    if (pDictItemId) {
			        set matchId = $order(^IRIS.IK.Mat.DictItemToMatch(tMatchDomId, tMatchDictItemId, matchId))
			        quit:matchId=""
			    } else {
MatchIdBitLoop	    set tMatchIdPos = $bitfind(tMatchIdBits,1,tMatchIdPos+1)
				    if 'tMatchIdPos {
					    set tMatchIdOffset = $order(^IRIS.IK.Mat.DictToMatchBit(tMatchDomId,tMatchDictId,tMatchIdOffset), 1, tMatchIdBits)
					    quit:tMatchIdOffset=""
					    goto MatchIdBitLoop
				    }
				    $$$IKGETIDOFFPOS(matchId,tMatchIdOffset,tMatchIdPos)
			    }
	        
		        set tMatch = $g(^IRIS.IK.Mat.MatchId(tMatchDomId, matchId))
		        continue:tMatch=""
		        continue:pDictTermId&&($zabs($li(tMatch,3))'=$zabs(pDictTermId))
	        	
	        	if tHasCustomizations {
		        	set tSC = $classmethod(tTablesPackage_".DictionaryMatch", "%DeleteId", matchId, 0)
		        	quit:$$$ISERR(tSC)
	        	} else {
			        kill ^IRIS.IK.Mat.MatchId(tMatchDomId, matchId)
	        	}
	        
		        $$$IKBITOFFPOS(matchId,dmoOff,dmoPos)
		        $$$IKCLRBIT(^IRIS.IK.DictToMatchBit,tMatchDomId,pDictId,dmoOff,dmoPos)
	        
		        set occId = $list(tMatch, 5)
		        if ($list(tMatch, 4) = $$$DMTARGETENTITY) {
	            
		            kill ^IRIS.IK.Mat.EntOccToMatch(tMatchDomId, occId, matchId)
	            
		            set sentId = $list(^IRIS.IK.EntOccId(tMatchDomId, occId),3)
		            set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(tMatchDomId, sentId)
	            
		        } elseif ($list(tMatch, 4) = $$$DMTARGETPATH) {
	            
		            //kill ^IRIS.IK.PathToDictMatch(domainId, occId, matchId)
		            set pathEntOccs = ^IRIS.IK.PathToEntOcc(tMatchDomId, occId)
		            set ptr = 0
		            while ($listnext(pathEntOccs, ptr, entOccId)) {
			            kill ^IRIS.IK.Mat.EntOccToMatch(tMatchDomId, entOccId, matchId)
		            }
	            
		            set sentId = ##class(%iKnow.Queries.PathAPI).GetSentenceId(tMatchDomId, occId)
		            set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(tMatchDomId, sentId)
	            
		        } elseif ($list(tMatch, 4) = $$$DMTARGETSENT) {
	            
		            set sentDetails = ^IRIS.IK.SentDetails(tMatchDomId, occId)
		            set eoFrom = $lg(sentDetails,4)+1, eoTo = eoFrom + $lg(sentDetails,5)-1
		            for entOccId = eoFrom:1:eoTo {
			            kill ^IRIS.IK.Mat.EntOccToMatch(tMatchDomId, entOccId, matchId)
		            }
	            
		            set sentId = occId
		            set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(tMatchDomId, sentId)
	            
		        } else {
	            
		            set sentId = $list(^IRIS.IK.CrcOccId(tMatchDomId, occId), 5)
		            set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(tMatchDomId, sentId)
	            
		            set crc = ^IRIS.IK.CrcOccId(tMatchDomId, occId)
		            set eoM = +$lg(crc,2), eoR = +$lg(crc,3), eoS = +$lg(crc,4)
		            kill:eoM ^IRIS.IK.Mat.EntOccToMatch(tMatchDomId, eoM, matchId)
		            kill ^IRIS.IK.Mat.EntOccToMatch(tMatchDomId, eoR, matchId)
		            kill:eoS ^IRIS.IK.Mat.EntOccToMatch(tMatchDomId, eoS, matchId)
		        }
		        
		        // get rid of ^IRIS.IK.Mat.SentToMatchScore
		        set score = $li(tMatch,6)
		        kill ^IRIS.IK.Mat.SentToMatchScore(tMatchDomId, sentId, -score, matchId)
	        
		        // check whether we can get rid of this ^IRIS.IK.Mat.DictToSrcBit entry
		        kill ^IRIS.IK.Mat.SrcToMatch(tMatchDomId, srcId, matchId)
		        set otherDmo = ""
		        for {
		            set otherDmo = $order(^IRIS.IK.Mat.SrcToMatch(tMatchDomId, srcId, otherDmo))
		            quit:otherDmo=""
	            
		            quit:$list(^IRIS.IK.Mat.MatchId(tMatchDomId,otherDmo),1)=pDictId
		        }
		        if (otherDmo) {
		            $$$IKBITOFFPOS(srcId,srcOff,srcPos)
		            $$$IKCLRBIT(^IRIS.IK.Mat.DictToSrcBit,tMatchDomId,pDictId,srcOff,srcPos)
		        }
		        
		    	kill ^IRIS.IK.Mat.DictItemToMatch(tMatchDomId, $li(tMatch,2), matchId)
		    }
	    }
		quit:pMode=0
		
	    // drop all terms
	    kill ^||%IK.TrackDictElems
	    set tDictDomainId = $s(pDictId<0:0, 1:pDomainId)
	    set tDictItemId = $s(pDictItemId:$zabs(pDictItemId)-1, 1:"")
	    for {
		    set tDictItemId = $order(^IRIS.IK.Mat.DictItemTerms(tDictDomainId, tDictItemId), 1, terms)
		    quit:tDictItemId=""
		    quit:pDictItemId&&(tDictItemId'=$zabs(pDictItemId))
		    
		    set:pDictTermId terms = $lb(pDictTermId)
		    
		    set ptr1=0
		    while $listnext(terms,ptr1,dtId) {
	        
		        // drop term elements
		        set elems = $g(^IRIS.IK.Mat.DictTermElems(tDictDomainId, dtId)), ptr2=0
		        while $listnext(elems,ptr2,deId) {
		            set ^||%IK.TrackDictElems($s(tDictDomainId:deId, 1:-deId)) = ""
	            	continue:pMode=1
	            	
		            set elem = ^IRIS.IK.Mat.DictElementId(tDictDomainId, deId)
		            kill ^IRIS.IK.Mat.DictElementId(tDictDomainId, deId)
		            
		            // drop term or format references
		            if ($li(elem,3)=$$$DETERM) {
			            set entUniId = $li(elem,4)
		            	kill ^IRIS.IK.Mat.DictElement(tDictDomainId, entUniId, deId)
		            	if '$d(^IRIS.IK.Mat.DictElement(tDictDomainId, entUniId)) {
			            	set tString = $s(entUniId>0:$g(^IRIS.IK.EntUniId(pDomainId, entUniId)), 1:$g(^IRIS.IK.Mat.DictElemStringId(tDictDomainId, -entUniId)))
			            	kill ^IRIS.IK.Mat.DictElemString(tDictDomainId, " "_tString)
		            	}
		            } else {
			            set dfId = $list(elem,4)
			            kill ^IRIS.IK.Mat.DictFormatElements(tDictDomainId, dfId, deId)
			            
			            // we might have to update DictToFormat as well
			            set x = "", otherDEs = 0
			            for {
				            set x = $o(^IRIS.IK.Mat.DictFormatElements(tDictDomainId, dfId, x), 1, y)
				            quit:x=""
				            set otherDEs = (y=pDictId)
				            quit:otherDEs
			            }
			            kill:'otherDEs ^IRIS.IK.Mat.DictToFormat(tDictDomainId, dfId, dfId)
		            }
		        }
		        
		        if (pMode=2) {
		        	kill ^IRIS.IK.Mat.DictTermElems(tDictDomainId, dtId)
		        	set:tVersion20122 $li(^IRIS.IK.Mat.DictTermId(tDictDomainId,dtId),5) = $$$DTUNPROCESSED
		        }
		    }
	    }
	    
	    // drop mappings for these DEs
	    set tMatchDomId = $s(pDomainId:pDomainId-1, 1:"")
	    for {
		    set tMatchDomId = $order(^IRIS.IK.Mat.EntUniToDictElem(tMatchDomId))
		    quit:tMatchDomId=""
		    quit:pDomainId&&(tMatchDomId'=pDomainId)
		    
		    set eu=""
		    for {
			    set eu = $order(^IRIS.IK.Mat.EntUniToDictElem(tMatchDomId,eu))
			    quit:eu=""
			    
			    set de=""
			    for {
				    set de = $order(^||%IK.TrackDictElems(de))
				    quit:de=""
				    
				    kill ^IRIS.IK.Mat.EntUniToDictElem(tMatchDomId,eu,de)
			    }
		    }
	    }
	    kill ^||%IK.TrackDictElems
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  <p>Push Dictionary Terms for the given dictionaries through the engine and generate appropriate
///  Dictionary Elements, if the Term hadn't been processed before. If <var>domainId</var> = 0,
///  terms for all cross-domain dictionaries will be processed.</p>
///  <p>Internal method, not to be invoked by custom code.</p>
///  <p>NOTE: <var>pDictIds</var> is ignored as from 2013.1! (domain version >=3)</p>
ClassMethod IndexDictionaryTerms(domainId As %Integer, pDictIds As %List = "") As %Status [ Internal ]
{
	//$$$IKQTIC("IndexDictionaryTerms")
	set tSC = $$$OK
	try {
		if (domainId'=0) {
		    $$$CHECKDOMAINEXISTSX(domainId,tSC)
	    	set tVersion20122 = $$$IKVERSIONBEFORE(domainId,$$$IKVERSIONMATCHING20131)
		} else {
			$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
			set tVersion20122 = (xDomVersion < $$$IKVERSIONMATCHING20131) // always 0
		}
	    $$$IKTEMPDOMID(domainId,tTempId)
		
		// BDB572 - disable journalling if applicable
		$$$IKDisableJournal(domainId)
	    
	    $$$SETMAXJOBS(tMaxProcs,domainId,"MatchIdxTerms",$system.Util.NumberOfCPUs(),tMaxProcsLimit)
	    
	    // note: locking is taken care of by enclosing MatchEntityUniques()
	    
	    set tMaxDictTermId = +$order(^IRIS.IK.Mat.DictTermId(domainId,""),-1)
	    quit:'tMaxDictTermId
	    if tVersion20122 {
		    set tDictId="", tMinDictTermId = tMaxDictTermId
		    for {
			    set tDictId = $order(^IRIS.IK.Mat.DictId(domainId,tDictId),1,tStatus)
			    quit:tDictId=""
			    continue:(pDictIds'="")&&'$lf(pDictIds,tDictId)
			    set tDictTermId = $lg($g(^IRIS.IK.Mat.DictMatchStatus(domainId,tDictId)),1)
			    set:tDictTermId<tMinDictTermId tMinDictTermId = tDictTermId
			    quit:'tMinDictTermId
		    }
	    } else {
		    set tMinDictTermId = $lg($g(^IRIS.IK.Mat.DictMatchStatus(domainId)),1)
	    }
	    quit:tMinDictTermId=tMaxDictTermId
	    
	    set ^IRIS.Temp.IK.Mat.DTId(tTempId) = tMinDictTermId
		
	    if (tMaxProcs<=1) || ((tMaxDictTermId - tMinDictTermId)<1000) {
		    
		    set tSC = ..IndexDictionaryTermsJob(domainId, pDictIds, tMaxDictTermId, 0)
		    quit:$$$ISERR(tSC)
		    
	    } else {
		    
		    kill ^IRIS.Temp.IK.Mat.IdxProc(tTempId)
		    for i = 1:1:tMaxProcs {
			    
			    job ..IndexDictionaryTermsJob(domainId, pDictIds, tMaxDictTermId, i)::10
			    if '$test {
				    // BDB633 - if we cannot start this many processes, simply end here
				    set tMaxProcs = i-1
				    quit
			    }
		    }
		    quit:$$$ISERR(tSC)
		    
		    while 1 {
			    quit:($bitcount(^IRIS.Temp.IK.Mat.IdxProc(tTempId),1)=tMaxProcs)
			    hang 0.5
		    }
		    
		    for i = 1:1:tMaxProcs {
			    set tSC = $g(^IRIS.Temp.IK.Mat.IdxProc(tTempId,i))
			    quit:$$$ISERR(tSC)
			    
			    if tVersion20122 {
				    set tDictId=""
				    for {
					    set tDictId = $order(^IRIS.Temp.IK.Mat.IdxProc(tTempId,i,tDictId),1,tMaxDTId)
					    quit:tDictId=""
					    set tStatus = $g(^IRIS.IK.Mat.DictMatchStatus(domainId,tDictId))
					    set:$lg(tStatus,1)<tMaxDTId $li(^IRIS.IK.Mat.DictMatchStatus(domainId,tDictId),1) = tMaxDTId
				    }
			    }
		    }
		    quit:$$$ISERR(tSC)
	    }
	    
	    if 'tVersion20122 {
		    set $li(^IRIS.IK.Mat.DictMatchStatus(domainId),1) = tMaxDictTermId
	    }
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	    
	kill ^IRIS.Temp.IK.Mat.DTId(tTempId), ^IRIS.Temp.IK.Mat.IdxProc(tTempId)
	//$$$IKQTOC("IndexDictionaryTerms")
		
	$$$IKRestoreJournal // BDB572
	
	quit tSC
}

ClassMethod IndexDictionaryTermsJob(pDomainId As %Integer, pDictIds As %List = "", pMaxDictTermId As %Integer, pProcN As %Integer = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		$$$IKTEMPDOMID(pDomainId,tTempId)
		
		// BDB572 - if this is an async job, disable journalling
		if pProcN {
			$$$IKDisableJournal(pDomainId)
		}
		
		set tVersion20122 = $s(pDomainId:$$$IKVERSIONBEFORE(pDomainId,$$$IKVERSIONMATCHING20131), 1:0)
		
	    // initialize DI
	    set tDI=##class(%iKnow.Matching.DirectInputDict).%New(pDomainId, 0)
	    if '$isobject(tDI) { set tSC = $$$ERROR($$$IKFailedInitDirectInput) quit }

	    // initialize indexer object
	    set tIndexer=##class(%iKnow.Indexer).%New()
	    if '$isobject(tIndexer) { set tSC = $$$ERROR($$$IKFailedInitIndexer) quit }
	    
	    // BDB431 - load default configuration settings
	    set tConfigName = $$$GETPARAMNODEF(pDomainId,$$$IKPDEFAULTCONFIG)
	    if (tConfigName'="") {
		    set tConfig = ##class(%iKnow.Configuration).Open(tConfigName)
		    if (tConfig="") {
			    set tSC = $$$ERROR($$$IKConfigurationNotFound, tConfigName)
			    quit
		    }
		    
		    // only user dictionary and MaxConceptLength settings are applied!
		    if tConfig.MaxConceptLength {
			    set tSC = tIndexer.SetMaxConceptLength(tConfig.MaxConceptLength)
		    	quit:$$$ISERR(tSC)
		    }
		    if (tConfig.UserDictionary'="") {
			    set tUserDict = ##class(%iKnow.UserDictionary).OpenByName(tConfig.UserDictionary)
			    if '$isobject(tUserDict) {
					set tSC = $$$ERROR($$$IKNoUserDictWithName, tConfig.UserDictionary)
					quit
				}
		        set tSC = tIndexer.LoadUserDictionary(tConfig.UserDictionary, tUserDict)
		        quit:$$$ISERR(tSC)
		        set tSC =tIndexer.SetUserDictionary(tConfig.UserDictionary)
		        quit:$$$ISERR(tSC)
		        set tUserDict=""
		    }
	    }

	    // apply/override specific settings for dictionary terms
	    set tSC = tIndexer.EnableMergeRelations()
	    quit:$$$ISERR(tSC)
	    set tSC = tIndexer.DisableSummarizer()
	    quit:$$$ISERR(tSC)
	    set tSC = tIndexer.EnableDelimitedSentences()
	    quit:$$$ISERR(tSC)
	    
	    // BDB623 - use stemming if applicable
	    set tSC = ##class(%iKnow.Stemmer).GetByDomain(pDomainId, .tStemmer)
	    quit:$$$ISERR(tSC)
	    set tSC = tIndexer.SetStemmer(tStemmer)
	    quit:$$$ISERR(tSC)
	    
	    
	    // gather all DTs into a PPG indexed by language
	    kill tProcessed
	    set tBatchSize = 1000
	    while 1 {
		    // reserve another batch
		    set tMax = $i(^IRIS.Temp.IK.Mat.DTId(tTempId), tBatchSize), tMin = tMax-tBatchSize
		    quit:tMin>pMaxDictTermId
		    
		    kill tTermsByLang, tMaxByDict
		    set tDTId=tMin, tTermsByLangCached=1, tPrevLang=""
		    
		    // BDB506 - ensure we stop upon reaching the max term ID
		    set:tMax>pMaxDictTermId tMax = pMaxDictTermId
		    
		    for {
		        set tDTId = $o(^IRIS.IK.Mat.DictTermId(pDomainId,tDTId),1,tTerm)
		        quit:tDTId=""
		        quit:tDTId>tMax
		        
		        // skip dictionary formats, which have no language
		        continue:'$lg(tTerm,4)
		        
		        set tDictId = $li(tTerm,1)
		        if tVersion20122 {
		        	continue:($lg(tTerm,5)=$$$DTPROCESSED)
		        	set tMaxByDict(tDictId) = tDTId
		        }
		                
		        set tTermsByLang($list(tTerm,4),+tDTId) = $lb($li(tTerm,3),tDictId)
		        
		        if tTermsByLangCached && ($s<100000) {
			        set tTermsByLangCached = 0
			        kill ^||%IK.TermsByLang
			        $$$IKSORTBEGIN(^||%IK.TermsByLang)
			        merge ^||%IK.TermsByLang = tTermsByLang
			        kill tTermsByLang
		        }
		    }
		    set:'tTermsByLangCached x = $sortend(^||%IK.TermsByLang)
		    
		    // now loop through the languages and process each term
		    set tLangId=""
		    for {
			    if (tTermsByLangCached) {
				    set tLangId = $o(tTermsByLang(tLangId))
			    } else {
				    set tLangId = $o(^||%IK.TermsByLang(tLangId))
			    }
			    quit:tLangId=""
			    
			    // unload the previous language
			    set:tPrevLang'="" tSC = tIndexer.UnloadKnowledgebase(tPrevLang)
			    quit:$$$ISERR(tSC)
			    set tPrevLang = $li($$$IKLANGUAGES,tLangId)
			    
			    // load the KB for this language
			    set tKB = ##class(%iKnow.KB.Knowledgebase).GetByName(tPrevLang)
		    	set tSC = tIndexer.LoadKnowledgebase(tPrevLang, tKB)
		    	quit:$$$ISERR(tSC)
		    	
		    	set tDTId=""
		    	for {
			    	if tTermsByLangCached {
				    	set tDTId = $o(tTermsByLang(tLangId, tDTId), 1, tTerm)
			    	} else {
				    	set tDTId = $order(^||%IK.TermsByLang(tLangId, tDTId), 1, tTerm)
			    	}
			    	quit:tDTId=""
			    	
			    	//do tDI.Reset()
			    	
		            set tSC = tIndexer.ClearBuffer()
		            quit:$$$ISERR(tSC)
		            
		            set tSC = tIndexer.BufferString($li(tTerm,1))
		            quit:$$$ISERR(tSC)
		            
		            set tSC = tIndexer.IndexBuffer(tDI, tPrevLang)
		            quit:$$$ISERR(tSC)
		            
		            set tSC = tDI.ProcessTerm(tDTId, $li(tTerm,2), tPrevLang)
		            quit:$$$ISERR(tSC)
		            
		            set:tVersion20122 tProcessed(tDTId) = ""
		        }
		        quit:$$$ISERR(tSC)
		    }
		    quit:$$$ISERR(tSC)
		    
		    set tSC = tDI.PersistElements()
		    quit:$$$ISERR(tSC)
	    }
	    quit:$$$ISERR(tSC)
	    
	    if (tVersion20122) {
		    set tDTId = ""
		    for {
			  	set tDTId = $order(tProcessed(tDTId))
			  	quit:tDTId=""
			  	
			  	set $li(^IRIS.IK.Mat.DictTermId(pDomainId,tDTId),5) = $$$DTPROCESSED
		    }
		    
		    if pProcN {
			    merge ^IRIS.Temp.IK.Mat.IdxProc(tTempId, pProcN) = tMaxByDict
		    } else {
			    set tDictId=""
			    for {
				    set tDictId = $order(tMaxByDict(tDictId),1,tMaxDTId)
				    quit:tDictId=""
				    set tStatus = $g(^IRIS.IK.Mat.DictMatchStatus(pDomainId,tDictId))
				    set:$lg(tStatus,1)<tMaxDTId $li(^IRIS.IK.Mat.DictMatchStatus(pDomainId,tDictId),1) = tMaxDTId
			    }
		    }
	    }
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	set:$$$ISERR(tSC) ^IRIS.IKL.Mat.Errors(pDomainId,$i(^IRIS.IKL.Mat.Errors(pDomainId))) = $lb("",tSC,$h)
	
	if (pProcN) {
		set $bit(^IRIS.Temp.IK.Mat.IdxProc(tTempId), pProcN) = 1
		set ^IRIS.Temp.IK.Mat.IdxProc(tTempId, pProcN) = tSC
	}
	
	$$$IKRestoreJournal // BDB572
	
	quit tSC
}

/// <p>This method has been deprecated. Use GetHighlighted() in <class>%iKnow.Queries.SentenceAPI</class>.</p>
///  <p>Returns a HTML representation of the given sources sentences in which all matched elements are
///  highlighted according to the parameters specified in this method invocation. At lower subscript
///  levels, all composing parts, literals and matching result info is specified to enable custom
///  highlighting as well.</p>
///  <ul>
///  		<li>Setting <i>displayEveryMatch</i> to 1 will generate markup for every individual match,
///  		whereas 0 (the default) will display at most 1 match per entity to limit the complexity of the output</li>
///  		<li>Through the <i>entOccJSAction</i> and <i>matchJSAction</i> parameters, a JavaScript
///  		method name can be provided to be rendered as onclick actions for either the entity occurrences
///  	or individual matches, taking their respective IDs as arguments.</li>
///  		<li>The <i>dictStyles</i> and <i>matchScoreStyles</i> parameters can be used to supply local
///  		arrays specifying additional style classes to apply to matches for specific dictionaries
///  	and match score windows respectively.</li>
///  </ul>
///  <p>If a negative Source ID is supplied, it is interpreted as a Virtual Source.</p>
/// <p><b>Note:</b> if no JavaScript injection is required, the GetHighlighted() method in 
/// <class>%iKnow.Queries.SentenceAPI</class> is a more versatile alternative to this method,
/// supporting simultaneously highlighting matches, attributes, entities, etc. </p>
ClassMethod GetHighlightedSentences(ByRef result, domainId As %Integer, srcId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Matching.MatchFilter = "", displayEveryMatch = 0, entOccJSAction As %String = "", matchJSAction As %String = "", dictStyles = "", matchScoreStyles = "") As %Status [ Deprecated, Internal ]
{
    $$$IKQBEGINTRY(result,"",tSC)
	if (srcId<0) && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	$$$CHECKASRCIDEXISTSX(domainId,srcId,srcDetails,vSrcId,tSC)
	$$$IKENSUREISMATCHEDX(domainId,srcId,"",tSC)

    // set default MT styles
    if ('$o(matchScoreStyles(""))) {
        set matchScoreStyles(1) = "matchF"
        set matchScoreStyles(0) = "matchP"
    }

    // find out which sentences we need to visualize
    set sentFrom = $list(srcDetails,1)+1
    set sentTo = sentFrom + $list(srcDetails,2) - 1
    if (page*pageSize > 0) {
        set sentFrom = sentFrom + ((page-1)*pageSize)
        if ((sentFrom+pageSize-1) < sentTo) {
            set sentTo = sentFrom+pageSize-1
        }
    }
    
    set sentIdGlo = $$$IKVGLOBNAME(domainId,"SentId",vSrcId)
    set sentDetailsGlo = $$$IKVGLOBNAME(domainId,"SentDetails",vSrcId)
    set sentNonRelBitGlo = $$$IKVGLOBNAME(domainId,"SentNonRelBit",vSrcId)
    set entUniIdGlo = $$$IKVGLOBNAME(domainId,"EntUniId",vSrcId)
    set litUniIdGlo = $$$IKVGLOBNAME(domainId,"LitUniId",vSrcId)
    set entOccIdGlo = $$$IKVGLOBNAME(domainId,"EntOccId",vSrcId)
    set entOccToMatchGlo = $$$IKVGLOBNAME(domainId,"Mat.EntOccToMatch",vSrcId)
    set matchIdGlo = $$$IKVGLOBNAME(domainId,"Mat.MatchId",vSrcId)
    set pathToEntOccGlo = $$$IKVGLOBNAME(domainId,"PathToEntOcc",vSrcId)
    
    // BDB577
    set tVersionTables = $$$IKVERSIONATLEAST(domainId,$$$IKVERSIONTABLES)

    set n = 0
    for sentId = sentFrom:1:sentTo {
        
        // TODO: evt rewrite so this reuses GetParts from the SentenceAPI
        
        kill sentence, entOccPositions, entOccsWithEndings, bestMatch
        set ents = @sentIdGlo@(sentId)
        set sentDetails = @sentDetailsGlo@(sentId)
        set entOccBase = $lg(sentDetails, 4)
        
        set pos = 0, ptr = 0, entOccId = entOccBase, prevNonRelBitOffset = 0, nonRel = 0
        while ($listnext(ents, ptr, id)) {
            set pos = pos+1
		
			if 'tVersionTables {
				set nonRelBitOffset = pos\64000+1
				if (nonRelBitOffset '= prevNonRelBitOffset) {
					set nonRelBits = $g(@sentNonRelBitGlo@(sentId, nonRelBitOffset))
					set prevNonRelBitOffset = nonRelBitOffset
				}
			}
            
            // skip if this is an empty string
            continue:'id
            
            if (id>0) {
                
                // positive id means an entUniId
                set highlight = @entUniIdGlo@(id)
                set nonRel = 0
                set prependSpace = 1
                
            } else {
                
                // negative id means an entLitId
                set highlight = @litUniIdGlo@(-id)
                
				// literals starting with a space indicate they should not be prepended with one
				set prependSpace = ($e(highlight,1)'=" ")
				set:'prependSpace highlight = $e(highlight,2,*)
			
				set:'tVersionTables nonRel = $bit(nonRelBits, pos+1)
            }
            
            set sentence(pos) = highlight
            
            // derive entOccId
            if (tVersionTables || 'nonRel) {
                set entOccId = entOccId + 1
                
                // BDB577
                continue:tVersionTables&&$lg(@entOccIdGlo@(entOccId),2)=$$$ENTTYPENONREL
                
                set entOccPositions(entOccId) = pos
                
                kill matchesForEntOcc
                set matchId = ""
                for {
                    set matchId = $order(@entOccToMatchGlo@(entOccId, matchId))
                    quit:matchId=""
                    
                    set match = @matchIdGlo@(matchId)
                    set deId = $order(@entOccToMatchGlo@(entOccId, matchId, ""), 1, matchScore)
                    set dictId = $li(match, 1)
                    
                    if (filter'="") {
                        continue:'filter.MeetsCriteria(match)
                    }
                    
                    set matchesForEntOcc(-matchScore, matchId) = ""
                    set matchTarget = $li(match,4)
                    set sentence(pos, matchTarget, matchId) = match
                    set bestMatch(matchTarget, $li(match,5), -$li(match,6)) = matchId
                    
                    // now calculate where this CRC or path actually began or ended
                    if (matchTarget = $$$DMTARGETCRC) {
                        set crcId = $li(match, 5)
                        
                        // first put the CRCBEGIN marker at the master pos
                        set firstEO = entOccId
                        set:(entOccId>1)&&($lg(@entOccIdGlo@(entOccId-1),5)=crcId) firstEO = entOccId-1
                        set:(entOccId>2)&&($lg(@entOccIdGlo@(entOccId-2),5)=crcId) firstEO = entOccId-2
                        set sentence(entOccPositions(firstEO), "CRCBEGIN", matchId) = match
                        
                        // now put the CRCEND marker
                        set lastEO = entOccId
                        set:$lg($g(@entOccIdGlo@(entOccId+1)),5)=crcId lastEO = entOccId+1
                        set:$lg($g(@entOccIdGlo@(entOccId+2)),5)=crcId lastEO = entOccId+2
                        set entOccsWithEndings(lastEO, "CRCEND", matchId) = match
                        
                    } elseif (matchTarget = $$$DMTARGETPATH) {
	                    
                        set pathId = +$lg(match, 5)
                        set posInPath = +$lg(@entOccIdGlo@(entOccId), 9)
                        set pathLength = $listlength(@pathToEntOccGlo@(pathId))
                        
                        set sentence(entOccPositions(entOccId-posInPath+1), "PATHBEGIN", matchId) = match
                        set entOccsWithEndings(entOccId-posInPath+pathLength, "PATHEND", matchId) = match
                        
                    }
                }   
                
                if ($d(matchesForEntOcc)) {
                    set highlight = "<b>"_highlight_"</b>"
                    
                    // now see what we need to display for this EO
                    set matchScore = ""
                    for {
                        set matchScore = $order(matchesForEntOcc(matchScore))
                        quit:matchScore=""
                        
                        set matchId = ""
                        for {
                            set matchId = $order(matchesForEntOcc(matchScore, matchId))
                            quit:matchId=""
                            
                            set match = @matchIdGlo@(matchId)
                            set dictId = $list(match, 1)
                            set tDictDomId = $s(dictId<0:0, 1:domainId)
                            set dictItem = ^IRIS.IK.Mat.DictItemId(tDictDomId, $zabs($list(match, 2)))
                            
                            set styles = ""
                            set:'$d(matchScoreStyles(-matchScore),styles) level = $order(matchScoreStyles(-matchScore),-1,styles)
                            set styles = styles _ " " _ $g(dictStyles(dictId),dictStyles)
                            set span = "<span class=""" _ styles_ """ title=""" _ $list(dictItem,3) _ """"
                            set:matchJSAction'="" span = span _ " onclick=""" _ matchJSAction _ "(" _ matchId _ ");"""
                            set highlight = span _ ">" _ highlight _ "</span>"
                            
                            quit:'displayEveryMatch
                        }
                        quit:'displayEveryMatch
                    }
                }
                
                // now append anything saved temporarily in entOccsWithEndings
                merge sentence(pos) = entOccsWithEndings(entOccId)
                
                set:entOccJSAction'="" highlight = "<span onclick=""" _ entOccJSAction _ "(" _ entOccId _ ");"">" _ highlight _ "</span>"
            }
            
            // now store the highlighted stuff
            set sentence(pos, "H") = highlight
            set sentence(pos, "SPACE") = +$g(prependSpace)
        }
        
        // now go through it again to take into account CRC and Path highlights
        set pos = "", sentence = ""
        for {
            set pos = $order(sentence(pos))
            quit:pos=""
            
            if (pos>1) && (sentence(pos,"SPACE")) {
	            set sentence = sentence _ " "
            }
            kill sentence(pos,"SPACE")
            
            // add code for  CRCs & paths beginnings
            for mode = "PATHBEGIN", "CRCBEGIN" {
                set matchId = ""
                for {
                    set matchId = $order(sentence(pos, mode, matchId), 1, match)
                    quit:matchId=""
                    
                    if ('displayEveryMatch) {
                        set bestScore = $o(bestMatch($li(match,4),$li(match,5),""),1,bestmatchId)
                        continue:matchId'=bestmatchId
                    }
                    
                    set dictId = $li(match,1)
                    set tDictDomId = $s(dictId<0:0, 1:domainId)
                    set dictItem = ^IRIS.IK.Mat.DictItemId(tDictDomId, $zabs($li(match,2)))
                    set sentence = sentence _ "<" _ $s(mode="PATHBEGIN":"u", 1:"i") _ " class=""" _ $g(dictStyles(dictId),dictStyles) _ """ title=""" _ $li(dictItem,3) _ """"
                    set:matchJSAction'="" sentence = sentence _ " onclick=""" _ matchJSAction _ "(" _ matchId _ ");"""
                    set sentence = sentence _ ">"
                } 
            }
            
            set sentence = sentence _ sentence(pos, "H")
            
            // add code for CRCs & paths endings
            for i = 1:1:2 {
                set mode = $li($lb("PATHEND", "CRCEND"),i)
                set matchId = ""
                for {
                    set matchId = $order(sentence(pos, mode, matchId), 1, match)
                    quit:matchId=""
                    
                    if ('displayEveryMatch) {
                        set bestScore = $o(bestMatch($li(match,4),$li(match,5),""),1,bestmatchId)
                        continue:matchId'=bestmatchId
                    }
                    
                    // TODO: do proper styling
                    set sentence = sentence _ "</" _ $s(mode="PATHEND":"u", 1:"i") _ ">"
                } 
            }
            
            // clean up the temp saved highlighted stuff
            kill sentence(pos, "H")
        }
        
        $$$IKQMERGERESULT(result,$i(n),sentence)
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetMatchElementsRT = "position:%Integer,entOccId:%Integer,entUniId:%Integer,literal:%String,role:%Integer,matchScore:%Numeric,dictElementId:%Integer,dictElement:%String,matchedWordBits:%String,isScattered:%Boolean,formatOutput:%String,negated:%Boolean";

///  <p>Returns a detailed overview of all the elements in the match target, be it an entity-level,
///  CRC-level or path-level match. The elements that are matched get annotated with the matched
///  elements ID, value and eventually the output from a <class>%iKnow.Matching.Formats.Format</class>
///  class if it was responsible for the match.</p>
///  <p>If a Virtual Source ID is supplied, the query runs in the context of that virtual source.</p>
ClassMethod GetMatchElements(ByRef result, domainId As %Integer, matchId As %Integer, vSrcId As %Integer = 0) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
	if vSrcId && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	quit:'+matchId
	set vSrcId = $zabs(vSrcId)
	
	set matchIdGlo = $$$IKVGLOBNAME(domainId,"Mat.MatchId",vSrcId)
	set entUniIdGlo = $$$IKVGLOBNAME(domainId, "EntUniId", vSrcId)
	set sentIdGlo = $$$IKVGLOBNAME(domainId, "SentId", vSrcId)
	set sentDetailsGlo = $$$IKVGLOBNAME(domainId, "SentDetails", vSrcId)
	set sentNonRelBitGlo = $$$IKVGLOBNAME(domainId, "SentNonRelBit", vSrcId)
	set litUniIdGlo = $$$IKVGLOBNAME(domainId, "LitUniId", vSrcId)
	set entOccIdGlo = $$$IKVGLOBNAME(domainId, "EntOccId", vSrcId)
	set entOccToMatchGlo = $$$IKVGLOBNAME(domainId, "Mat.EntOccToMatch", vSrcId)
	set crcOccIdGlo = $$$IKVGLOBNAME(domainId, "CrcOccId", vSrcId)
	set pathToEntOccGlo = $$$IKVGLOBNAME(domainId, "PathToEntOcc", vSrcId)
	set entUniToDictElemGlo = $$$IKVGLOBNAME(domainId, "Mat.EntUniToDictElem", vSrcId)

    set match = $g(@matchIdGlo@(matchId))
    quit:match=""

    set targetType = $list(match, 4)
    
    if (targetType = $$$DMTARGETENTITY) {
	    set entOccIds = $list(match,5,5)
    } elseif (targetType = $$$DMTARGETCRC) {
	    set crcOccId = $list(match,5)
	    set crcOcc = @crcOccIdGlo@(crcOccId)
	    set entOccIds = $list(crcOcc,2,4)
    } elseif (targetType = $$$DMTARGETPATH) {
	    set pathId = $list(match,5)
	    set entOccIds = @pathToEntOccGlo@(pathId)
    } elseif (targetType = $$$DMTARGETSENT) {
	    set sentId = $list(match,5)
	    // BDB722
	    set entOccIdBase = $li(@sentDetailsGlo@(sentId),4), entOccId = entOccIdBase+1
	    set entOccIdMax = entOccIdBase + $li(@sentDetailsGlo@(sentId),5)
	    set entOccIds = ""
	    for i = entOccIdBase+1:1:entOccIdMax { set entOccIds = entOccIds_$lb(i) }
    }
    
    set tDictDomId = $s($li(match,1)<0:0, 1:domainId)
	set tUseStandardizedForm = $$$GETPARAMNODEF(tDictDomId,$$$IKPMATSTANDARDIZEDFORM)
	
	// BDB522 - when using stemming, we don't need to standardize any further as the 
	// stems are already in the EntUni globals
	set:tUseStandardizedForm=$$$IKPMATSTANDARDIZEDFORMSTEMMING tUseStandardizedForm=""
	
	// BDB577
	set tVersionTables = $$$IKVERSIONATLEAST(domainId,$$$IKVERSIONTABLES)
	
	// BDB720
	set tUseStemming = ($$$GETPARAM(domainId,$$$IKPSTEMMING,0)'=0)
	set:tUseStemming tUseStandardizedForm = ""
	
    set ptr = 0, i=0, pos=0
    while $listnext(entOccIds, ptr, id) {
        set pos = pos+1
        if 'tVersionTables && (targetType = $$$DMTARGETSENT)  {
	        $$$IKBITOFFPOS(pos,posOff,posPos)
	        set nonRel = $bit(@sentNonRelBitGlo@(sentId,posOff),posPos)
	        if (nonRel) {
		        $$$IKQADDRESULT(result,$i(i),$lb(pos,,, $zstrip(@litUniIdGlo@(-id),"<W"), $$$NONREL, 0,,,,,,)) 
		        continue
	        } else {
		        set entOccId = entOccId+1
	        }
        } else {
	        set entOccId = id
        }
        continue:'id
        set eo = @entOccIdGlo@(entOccId), entUniId = $lg(eo,$s(tUseStemming:10,1:1))
        
        set tNegated = ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(domainId, entOccId, $$$IKATTNEGATION, eo, vSrcId)
        
        set id = $li(@sentIdGlo@($li(eo, 3)), $li(eo, 4))
        set:(tUseStandardizedForm'="") sentLang = $li(@sentDetailsGlo@($li(eo,3)))
        set literal = $s(id>0:@entUniIdGlo@(id), id<0:$zstrip(@litUniIdGlo@(-id),"<W"), 1:"")
        set deId = "", hasNone=1
        for {
            set deId = $o(@entOccToMatchGlo@(entOccId, matchId, deId), 1, matchScore)
            quit:deId=""
        
            if (tUseStandardizedForm'="") {
	            set:'$d(@entUniToDictElemGlo@(entUniId,deId,sentLang), eumDetails) eumDetails = @entUniToDictElemGlo@(entUniId, deId)
            } else {
	            set eumDetails = @entUniToDictElemGlo@(entUniId, deId)
            }
            set matchedWordBits = "", bits = $lg(eumDetails,2)
			for j=1:1:$bitcount(bits) { set matchedWordBits = matchedWordBits _ $s($bit(bits,j):1, 1:0) }
        	
        	// BDB614
        	set tDE = $g(^IRIS.IK.Mat.DictElementId(tDictDomId, $zabs(deId)))
        	if $lg(tDE,3)=$$$DEFORMAT {
	        	set deFormatId = $li(tDE,4)
	        	set deFormatClassId = $lg(^IRIS.IK.Mat.DictFormatId(tDictDomId,deFormatId),1)
	        	set deStr = ^IRIS.IK.Sys.DictFormatD(deFormatClassId)
        	} else {
        		set deStrId = $li(tDE,4)
        		set deStr = $s(deStrId>0:^IRIS.IK.EntUniId(domainId, deStrId), 1:^IRIS.IK.Mat.DictElemStringId(tDictDomId, -deStrId))
        	}
        	
            $$$IKQADDRESULT(result,$i(i),$lb(pos, entOccId, entUniId, literal, $lg(eo,2), matchScore, +deId, deStr, matchedWordBits, $lg(eumDetails,3), $lg(eumDetails,4), tNegated))
            set hasNone = 0
        }

        if (hasNone) { $$$IKQADDRESULT(result,$i(i),$lb(pos, entOccId, $lg(eo,1), literal, $lg(eo,2), 0,,,,,,tNegated)) }
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetMatchesByEntOccRT = "matchId:%Integer,dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%Integer,targetType:%String,targetId:%Integer,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>Returns all the matches for the given Entity Occurrence. Use <i>includeCrcMatches</i>,
///  <i>includePathMatches</i> and <i>includeSentenceMatches</i> to also include any matches for the CRC, Path or Sentence in which this Entity
///  Occurrences participates.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetMatchesByEntOcc(ByRef result, domainId As %Integer, entOccId As %Integer, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10, includeCrcMatches As %Boolean = 1, includePathMatches As %Boolean = 1, includeSentenceMatches As %Boolean = 1, vSrcId As %Integer = 0) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
    if vSrcId && (domainId=0) { } else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
    
    // find source ID to ensure it's properly matched
    if 'vSrcId {
	    set eoObj = ##class(%iKnow.Objects.EntityOccurrence).PKINDEXOpen(domainId, entOccId)
    	set srcId = eoObj.Sentence.Source.SourceId
    } else {
	    set srcId = -vSrcId
    }
    
    $$$IKENSURELISTNUM(dictIds)
    $$$IKENSUREISMATCHEDX(domainId,srcId,dictIds,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)
	set gEntOccToMatch = $$$IKVGLOBNAME(domainId,"Mat.EntOccToMatch",vSrcId)
	set gMatchId = $$$IKVGLOBNAME(domainId,"Mat.MatchId",vSrcId)

    set matchId = ""
    for {
        set matchId = $o(@gEntOccToMatch@(entOccId, matchId))
        quit:matchId=""
        
        set match = @gMatchId@(matchId)
        set tDictId = $li(match,1)
        
        if (dictIds '= "") {
            continue:'$listfind(dictIds,tDictId)
        }
        
        set target = $li(match,4)
        continue:'includeCrcMatches&&(target=$$$DMTARGETCRC)
        continue:'includePathMatches&&(target=$$$DMTARGETPATH)
        continue:'includeSentenceMatches&&(target=$$$DMTARGETSENT)
            
	    set i = i+1
	    $$$IKCHECKPAGING(usePaging,first,last,i)
	    
	    set tDictDomId = $s(tDictId<0:0, 1:domainId)
        
        $$$IKQADDRESULT(result,i,$lb(+matchId) _ $li(match,1,2) _ $li(^IRIS.IK.Mat.DictItemId(tDictDomId,$zabs($li(match,2))),3,3) _ $li(match,3,13))
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetMatchesByPathRT = "matchId:%Integer,dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%Integer,targetType:%String,targetId:%Integer,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>Returns all the matches for the given Path. Use <i>includeEntityMatches</i>, 
///  <i>includeCRCMatches</i> and <i>includeSentenceMatches</i> to also include any matches for the Entities this path is composed of
///  and the CRCs or Sentences these Entities participate in.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetMatchesByPath(ByRef result, domainId As %Integer, pathId As %Integer, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10, includeEntityMatches As %Boolean = 1, includeCrcMatches As %Boolean = 1, includeSentenceMatches As %Boolean = 1) As %Status
{
    $$$IKQBEGINTRY(result,"^||%IK.matchList",tSC)
	$$$CHECKDOMAINEXISTSX(domainId,tSC)

    set path = $g(^IRIS.IK.PathToEntOcc(domainId, pathId))
    quit:path=""
    
    // find source ID to ensure it's properly matched
    set pathObj = ##class(%iKnow.Objects.Path).PKINDEXOpen(domainId, pathId)
    set srcId = pathObj.Source.SourceId
    
    $$$IKENSURELISTNUM(dictIds)
    $$$IKENSUREISMATCHEDX(domainId,srcId,dictIds,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)

    set ptr = 0
    while ($listnext(path, ptr, entOccId)) {
        set matchId = ""
        for {
            set matchId = $o(^IRIS.IK.Mat.EntOccToMatch(domainId, entOccId, matchId))
            quit:matchId=""
            
            continue:$d(^||%IK.matchList(matchId))
            set ^||%IK.matchList(matchId) = ""
            
            set match = ^IRIS.IK.Mat.MatchId(domainId, matchId) 
            set tDictId = $li(match,1)
            
            if (dictIds '= "") {
                continue:'$listfind(dictIds,tDictId)
            }
        
            set target = $li(match,4)
            continue:'includeEntityMatches&&(target=$$$DMTARGETENTITY)
            continue:'includeCrcMatches&&(target=$$$DMTARGETCRC)
            continue:'includeSentenceMatches&&(target=$$$DMTARGETSENT)
            
	        set i = i+1
	        $$$IKCHECKPAGING(usePaging,first,last,i)
	        
	        set tDictDomId = $s(tDictId<0:0, 1:domainId)
        
            $$$IKQADDRESULT(result,i,$lb(+matchId) _ $li(match,1,2) _ $li(^IRIS.IK.Mat.DictItemId(tDictDomId,$zabs($li(match,2))),3,3) _ $li(match,3,13))
        }
    }
    $$$IKQENDCATCH(result,"^||%IK.matchList",tSC)
}

Parameter GetMatchesBySentenceRT = "matchId:%Integer,dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%Integer,targetType:%String,targetId:%Integer,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>Returns all the matches for the given Sentence. Use <i>includeEntityMatches</i>,
///  <i>includeCrcMatches</i> and <i>includePathMatches</i> to control which (target) types of
///  matches should be included in the result.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetMatchesBySentence(ByRef result, domainId As %Integer, sentenceId As %Integer, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10, includeEntityMatches As %Boolean = 1, includeCrcMatches As %Boolean = 1, includePathMatches As %Boolean = 1) As %Status
{
    $$$IKQBEGINTRY(result,"^||%IK.matchList",tSC)
	$$$CHECKDOMAINEXISTSX(domainId,tSC)

    set sentDetails = $g(^IRIS.IK.SentDetails(domainId, sentenceId))
    quit:sentDetails=""
    
    // find source ID to ensure it's properly matched
    set sentObj = ##class(%iKnow.Objects.Sentence).PKINDEXOpen(domainId, sentenceId)
    set srcId = sentObj.Source.SourceId
    
    $$$IKENSURELISTNUM(dictIds)
    $$$IKENSUREISMATCHEDX(domainId,srcId,dictIds,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)

    set firstEO = $lg(sentDetails,4)+1
    set lastEO = $lg(sentDetails,4)+$lg(sentDetails,5)
    for entOccId = firstEO:1:lastEO {
        set matchId = ""
        for {
            set matchId = $o(^IRIS.IK.Mat.EntOccToMatch(domainId, entOccId, matchId))
            quit:matchId=""
            
            continue:$d(^||%IK.matchList(matchId))
            set ^||%IK.matchList(matchId) = ""
            
            set match = ^IRIS.IK.Mat.MatchId(domainId, matchId)
            set tDictId = $li(match,1)
            
            if (dictIds '= "") {
                continue:'$listfind(dictIds,tDictId)
            }
        
            set target = $li(match,4)
            continue:'includeEntityMatches&&(target=$$$DMTARGETENTITY)
            continue:'includeCrcMatches&&(target=$$$DMTARGETCRC)
            continue:'includePathMatches&&(target=$$$DMTARGETPATH)
            
	        set i = i+1
	        $$$IKCHECKPAGING(usePaging,first,last,i)
	        
	        set tDictDomId = $s(tDictId<0:0, 1:domainId)
        
            $$$IKQADDRESULT(result,i,$lb(+matchId) _ $li(match,1,2) _ $li(^IRIS.IK.Mat.DictItemId(tDictDomId,$zabs($li(match,2))),3,3) _ $li(match,3,13))
        }
    }
    $$$IKQENDCATCH(result,"^||%IK.matchList",tSC)
}

Parameter GetMatchesByCrcOccRT = "matchId:%Integer,dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%Integer,targetType:%String,targetId:%Integer,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>Returns all the matches for the given CRC Occurrence. Use <i>includeEntityMatches</i>,
///  <i>includePathMatches</i> and <i>includeSentenceMatches</i> to also include any matches for the Entities this CRC is composed of
///  and the Paths these Entities participate in.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetMatchesByCrcOcc(ByRef result, domainId As %Integer, crcOccId As %Integer, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10, includeEntityMatches As %Boolean = 1, includePathMatches As %Boolean = 1, includeSentenceMatches As %Boolean = 1) As %Status
{
    $$$IKQBEGINTRY(result,"^||%IK.matchList",tSC)
	$$$CHECKDOMAINEXISTSX(domainId,tSC)

    set crc = $g(^IRIS.IK.CrcOccId(domainId, crcOccId))
    quit:crc=""
    
    // find source ID to ensure it's properly matched
    set crcoObj = ##class(%iKnow.Objects.CrcOccurrence).PKINDEXOpen(domainId, crcOccId)
    set sentObj = ##class(%iKnow.Objects.Sentence).PKINDEXOpen(domainId, crcoObj.SentenceId)
    set srcId = sentObj.Source.SourceId
    
    $$$IKENSURELISTNUM(dictIds)
    $$$IKENSUREISMATCHEDX(domainId,srcId,dictIds,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)

    for pos = 1:1:3 {
        set entOccId = $list(crc,pos+1)
        continue:entOccId=0
        
        set matchId = ""
        for {
            set matchId = $o(^IRIS.IK.Mat.EntOccToMatch(domainId, entOccId, matchId))
            quit:matchId=""
            
            continue:$d(^||%IK.matchList(matchId))
            set ^||%IK.matchList(matchId) = ""
            
            set match = ^IRIS.IK.Mat.MatchId(domainId, matchId) 
            set tDictId = $li(match,1)
            
            if (dictIds '= "") {
                continue:'$listfind(dictIds,tDictId)
            }
        
            set target = $li(match,4)
            continue:'includeEntityMatches&&(target=$$$DMTARGETENTITY)
            continue:'includePathMatches&&(target=$$$DMTARGETPATH)
            continue:'includeSentenceMatches&&(target=$$$DMTARGETSENT)
            
	        set i = i+1
	        $$$IKCHECKPAGING(usePaging,first,last,i)
	        
	        set tDictDomId = $s(tDictId<0:0, 1:domainId)
            
            $$$IKQADDRESULT(result,i,$lb(+matchId) _ $li(match,1,2) _ $li(^IRIS.IK.Mat.DictItemId(tDictDomId,$zabs($li(match,2))),3,3) _ $li(match,3,13))
        }
    }
    $$$IKQENDCATCH(result,"^||%IK.matchList",tSC)
}

Parameter GetMatchesBySourceRT = "matchId:%Integer,dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%Integer,targetType:%String,targetId:%Integer,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>Returns all the matches for the given Source, as identified by its external ID.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetMatchesBySource(ByRef result, domainId As %Integer, externalId As %String, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainId)
	$$$CHECKEXTIDEXISTS(domainId,externalId,srcId)
	
	quit ..GetMatchesBySourceId(.result, domainId, srcId, dictIds, page, pageSize)
}

Parameter GetMatchesBySourceIdRT = "matchId:%Integer,dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%Integer,targetType:%String,targetId:%Integer,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>Returns all the matches for the given Source, as identified by its Source ID (interpreted as a Virtual Source if a negative
///  value is supplied).</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetMatchesBySourceId(ByRef result, domainId As %Integer, srcId As %Integer, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
	if (srcId<0) && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	$$$CHECKASRCIDEXISTSX(domainId,srcId,srcDetails,vSrcId,tSC)
	
	$$$IKENSURELISTNUM(dictIds)
	$$$IKENSUREISMATCHEDX(domainId,srcId,dictIds,tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)
    
    set srcToMatchGlo = $s(vSrcId:"^IRIS.IKV.Mat.MatchId("_domainId_","_vSrcId_")", 1:"^IRIS.IK.Mat.SrcToMatch("_domainId_","_srcId_")")

    set matchId = "", i = 0
    for {
        set matchId = $o(@srcToMatchGlo@(matchId),1,match)
        quit:matchId=""
        
        set:'vSrcId match = ^IRIS.IK.Mat.MatchId(domainId, matchId)
        
        set tDictId = $li(match,1)
        if (dictIds '= "") {
            continue:'$listfind(dictIds,tDictId)
        }
        
        set i = i+1
        $$$IKCHECKPAGING(usePaging,first,last,i)
	        
	    set tDictDomId = $s(tDictId<0:0, 1:domainId)
        
        $$$IKQADDRESULT(result,i,$lb(+matchId) _ $li(match,1,2) _ $li(^IRIS.IK.Mat.DictItemId(tDictDomId,$zabs($li(match,2))),3,3) _ $li(match,3,13))
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetDictionaryMatchesRT = "dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%String,dictTerm:%String,dictElementId:%String,type:%String,matchScore:%Numeric,matchedWordBits:%String,isScattered:%Boolean,formatOutput:%String";

///  <p>Returns all potential matches for a given string. This string is treated as if it
///  were a single entity and matched against single-entity Dictionary Terms. To find the
///  matches for a full sentence, first index it and then call <method>GetMatchesBySource</method>
///  using the source ID corresponding to the indexed sentence.</p>
///  <p>A Matching Profile to be used when calculating match scores can be specified either by passing in an
/// 	 <class>%iKnow.Matching.MatchingProfile</class> object, or a Matching Profile ID. When
///  passing in the ID, a negative number is treated as a namespace-wide profile, whereas
///  a positive ID will be looked up within the context of the domain. If no profile is 
///  specified, the default profile for this domain will be used.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetDictionaryMatches(ByRef result As %Integer, domainId As %Integer, string As %String, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10, fullMatchOnly As %Integer = -1, profile As %iKnow.Matching.MatchingProfile = "", language As %String = "", nGramMatches As %Integer = -1) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.DictFormatCache,^||%IK.DEMatches",tSC)
	if (domainId'=0) { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	
	// BDB385 - check if we're looking for cross-domain dictionaries
	if (dictIds = "") {
		set dictIds = ..GetAllDictsAsList(domainId), xDomDicts = (domainId=0)
	} elseif (dictIds = $$$ALLXDOMDICTIONARIES) {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
		set dictIds = ..GetAllDictsAsList(0), xDomDicts = 1
	} else {
		$$$IKXDOMDICTS(dictIds,xDomDicts,xDomVersion,tSC)
	}
	$$$IKLIST2ARR(dictIds,tDictIds)
	
	set tDictDomainId = $s(xDomDicts:0, 1:domainId)
	set tUseStandardizedForm = $$$GETPARAMNODEF(tDictDomainId,$$$IKPMATSTANDARDIZEDFORM)
	if (language'="") {
		if (tUseStandardizedForm="") { 
			set tSC = $$$ERROR($$$GeneralError,"language is only supported when "_$$$IKPMATSTANDARDIZEDFORM_" '= """"") 
			quit 
		}
		if '$lf($$$IKLANGUAGES, language) {
			set tSC = $$$ERROR($$$IKLanguageDoesNotExist, language)
			quit
		}
	}
	
	// revert to *ById version if this is a known EU
	set entId = +##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainId, .string)
	if (entId) {
		set tSC = ..GetDictionaryMatchesById(.result, domainId, entId, dictIds, page, pageSize, fullMatchOnly, profile, language)
		quit
	}
	
	// check match status for the given dictionaries
	set latestDT = +$o(^IRIS.IK.Mat.DictTermId(tDictDomainId,""),-1)
	if $$$IKVERSIONBEFORE(domainId,$$$IKVERSIONMATCHING20131) {
		set ptr = 0, toMatch = ""
		while $listnext(dictIds, ptr, dictId) {
			set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId, dictId), $lb(0,0,0))
			if ($li(status,1)<latestDT) {
				set toMatch = toMatch _ $lb(dictId)
			}
		}
		set:toMatch'="" tSC = ..IndexDictionaryTerms(domainId,dictIds)
		quit:$$$ISERR(tSC)
	} else {
		if (latestDT > $lg($g(^IRIS.IK.Mat.DictMatchStatus(tDictDomainId)),1)) {
			set tSC = ..IndexDictionaryTerms(tDictDomainId)
			quit:$$$ISERR(tSC)
		}
	}
    
    // check domain settings if not supplied
    set:fullMatchOnly<0 fullMatchOnly = $$$IKFULLMATCHONLY(domainId)
    set:nGramMatches<0 nGramMatches = $$$GETPARAM(domainId,$$$IKPMATCHNGRAMS,0) // BDB686
    set:'$isobject(profile) profile = ##class(%iKnow.Matching.MatchingProfile).GetProfile(domainId, profile, .tSC)
    quit:$$$ISERR(tSC)
    
    // treat case sensitivity
    //$$$IKCONVERTMATCHINGCASE(domainId,string)
    set string = $$$IKNORMALIZEDL(string,domainId,$lg($$$IKLANGUAGES,+language))
	
	// first grab all simple term matches
	// if not standardizing just call CheckDictionaryElementMatches() once
	if (tUseStandardizedForm="") {
		set tSC = ..CheckDictionaryElementMatches(domainId, .string, .tDictIds, fullMatchOnly,,,, xDomDicts, nGramMatches)
		quit:$$$ISERR(tSC)
	} else {
		// or call it once using the standardized form if requesting a specific language
		if (language'="") {
			set standardized = ..StandardizedForm(string, language, tUseStandardizedForm)
			set tSC = ..CheckDictionaryElementMatches(domainId, .standardized, .tDictIds, fullMatchOnly,, 1,, xDomDicts, nGramMatches)
			quit:$$$ISERR(tSC)
		} else {
			// otherwise, we'll do it for every language and then clear out any duplicates
			set l = 0
			kill ^||%IK.DEMatches, standardizedForms
			while $listnext($$$IKLANGUAGES,l,lang) {
				set standardized = ..StandardizedForm(string, lang, tUseStandardizedForm)
				continue:$d(standardizedForms(standardized))
				set tSC = ..CheckDictionaryElementMatches(domainId, .standardized, .tDictIds, fullMatchOnly,, 1,, xDomDicts, nGramMatches)
				quit:$$$ISERR(tSC)
				set standardizedForms(standardized)=""
			}
			kill standardizedForms
			
			// now clear any duplicates
			kill desMatched
			set i=""
			for {
				set i = $order(^||%IK.DEMatches(i),1,m)
				quit:i=""
				set de=$li(m,2), score=$li(m,3)
				if $d(desMatched(de),prevDetails) {
					set prevScore = $li(prevDetails,2)
					if prevScore>=score {
						kill ^||%IK.DEMatches(i)
					} else {
						kill ^||%IK.DEMatches($li(prevDetails,1))
					}
				}
				set desMatched(de) = $lb(i,score)
			}
			kill desMatched
		}
	}
	
	// now gather data on all formats to match
    kill formatObjects, ^||%IK.DictFormatCache
    set ptr=0
    while $listnext(dictIds,ptr,dictId) {
	    set dfId = ""
	    for {
		    set dfId = $o(^IRIS.IK.Mat.DictToFormat(tDictDomainId,dictId,dfId))
		    quit:dfId=""
		    
		    set df = ^IRIS.IK.Mat.DictFormatId(tDictDomainId,dfId)
		    set formatClassId = $li(df,1)
		    set ^||%IK.DictFormatCache(formatClassId,dfId) = $li(df,2)
		    merge ^||%IK.DictFormatCache(formatClassId,dfId) = ^IRIS.IK.Mat.DictFormatElements(tDictDomainId,dfId)
		    
		    if '$d(formatObjects(formatClassId)) {
			    set formatObjects(formatClassId) = $classmethod(^IRIS.IK.Sys.DictFormatD(formatClassId), "%New", domainId)
		    }
	    }
	}
	
    // now loop through formats and use MatchSingle()
    set i = $order(^||%IK.DEMatches(""),-1)
    set formatClassId = ""
    for {
        set formatClassId = $order(formatObjects(formatClassId),1,formatObj)
        quit:formatClassId=""
	    
	    set dfId = "", prevParams="", first=1
	    for {
		    set dfId = $order(^||%IK.DictFormatCache(formatClassId, dfId), 1, formatParams)
		    quit:dfId=""
	    
		    if first || '$ls(formatParams, prevParams) {
			    kill matchScore, matchedWordBits, isScattered, formatOutput
			    set tSC = formatObj.MatchSingle(string,formatParams,.matchScore,.matchedWordBits,.isScattered,.formatOutput)
	    		goto:$$$ISERR(tSC) end
		    }
		    set first=0, prevParams = formatParams
	    	
	    	continue:'matchScore
	    	continue:fullMatchOnly&&(matchScore<1)
	    	
		    set deId = ""
		    for {
			    set deId = $order(^||%IK.DictFormatCache(formatClassId,dfId,deId),1,dictId)
			    quit:deId=""
		    	
		    	set:xDomDicts dictId = -dictId
			    continue:$d(tDictIds)&&'$d(tDictIds(dictId))
		    
		    	set ^||%IK.DEMatches($i(i)) = $lb(dictId, $s(xDomDicts:-deId, 1:+deId), matchScore, matchedWordBits, isScattered, formatOutput)
		    }
	    }
	    
	    // clean up
	    do formatObj.Finalize()
    }
    kill formatObjects
	
	// now build a proper result list
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
	set i = ""
	for {
		set i = $o(^||%IK.DEMatches(i),1,d)
		quit:i=""
		
		set dictId = $li(d,1)
		set xDom = $s(dictId<0:-1, 1:1)
		set dictElementId = $li(d,2)
		set matchScore = $li(d,3)
	    continue:matchScore<profile.MinimalMatchScore
		
		set count = count+1
		$$$IKCHECKPAGING(usePaging,first,last,count)
	    	
		set bits = $li(d,4)
		set isScattered = $li(d,5)
		set output = $lg(d,6)
		set matchedWordBits = ""
		for j=1:1:$bitcount(bits) { set matchedWordBits = matchedWordBits _ $s($bit(bits,j):1, 1:0) }
		set dictElement = ^IRIS.IK.Mat.DictElementId(tDictDomainId, $zabs(dictElementId))
		set dictTermId = $li(dictElement,2) * xDom
		set type = $s($li(dictElement,3)=$$$DETERM:"term", $li(dictElement,3)=$$$DEFORMAT:"format", 1:"unknown")
		set dictTerm = ^IRIS.IK.Mat.DictTermId(tDictDomainId, $zabs(dictTermId))
		set dictItemId = $li(dictTerm, 2) * xDom
		set dictTermStr = $li(dictTerm, 3)
		set dictItemURI = $li(^IRIS.IK.Mat.DictItemId(tDictDomainId, $zabs(dictItemId)),3)
		
		$$$IKQADDRESULT(result,count,$lb(dictId, dictItemId, dictItemURI, dictTermId, dictTermStr, dictElementId, type, matchScore, matchedWordBits, isScattered, output))
	}
	$$$IKQENDCATCH(result,"^||%IK.DictFormatCache,^||%IK.DEMatches",tSC)
}

Parameter GetDictionaryMatchesByIdRT = "dictId:%Integer,dictItemId:%Integer,dictItemURI:%String,dictTermId:%String,dictTerm:%String,dictElementId:%String,type:%String,matchScore:%Numeric,matchedWordBits:%String,isScattered:%Boolean,formatOutput:%String";

///  <p>Returns all potential matches for the given entity ID.</p>
///  <p>A Matching Profile to be used when calculating match scores can be specified either by passing in an
/// 	 <class>%iKnow.Matching.MatchingProfile</class> object, or a Matching Profile ID. When
///  passing in the ID, a negative number is treated as a namespace-wide profile, whereas
///  a positive ID will be looked up within the context of the domain. If no profile is 
///  specified, the default profile for this domain will be used.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetDictionaryMatchesById(ByRef result As %Integer, domainId As %Integer, entUniId As %Integer, dictIds As %List = "", page As %Integer = 1, pageSize As %Integer = 10, fullMatchOnly As %Integer = -1, profile As %iKnow.Matching.MatchingProfile = "", language As %String = "") As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainId,tSC)
	
	// BDB385 - check if we're looking for cross-domain dictionaries
	if (dictIds = "") {
		set dictIds = ..GetAllDictsAsList(domainId), xDomDicts = 0
	} elseif (dictIds = $$$ALLXDOMDICTIONARIES) {
		$$$IKXDOMDICTVERSIONX(xDomVersion,tSC)
		set dictIds = ..GetAllDictsAsList(0), xDomDicts = 1
	} else {
		$$$IKENSURELISTNUM(dictIds)
		$$$IKXDOMDICTS(dictIds,xDomDicts,xDomVersion,tSC)
	}
	$$$IKLIST2ARR(dictIds,tDictIds)
	
	set tDictDomainId = $s(xDomDicts:0, 1:domainId)
	set tUseStandardizedForm = $$$GETPARAMNODEF(tDictDomainId,$$$IKPMATSTANDARDIZEDFORM)
	
	// BDB522 - if we are working with stemmed matching, just look for plain matches of the stem
	if (tUseStandardizedForm=$$$IKPMATSTANDARDIZEDFORMSTEMMING) {
		set entUniId = ##class(%iKnow.Queries.EntityAPI).GetBaseFormId(domainId,entUniId,0)
		set tUseStandardizedForm = "", language=""
	}
	
	if (language'="") {
		if (tUseStandardizedForm="") { 
			set tSC = $$$ERROR($$$GeneralError,"language is only supported when "_$$$IKPMATSTANDARDIZEDFORM_" '= """"") 
			quit 
		}
		if '$lf($$$IKLANGUAGES, language) {
			set tSC = $$$ERROR($$$IKLanguageDoesNotExist, language)
			quit
		}
	}
	
	// check match status for the given dictionaries
	set latestDT = +$o(^IRIS.IK.Mat.DictTermId(tDictDomainId,""),-1)
	set tVersion20122 = $$$IKVERSIONBEFORE(domainId,$$$IKVERSIONMATCHING20131)
	if (tVersion20122) {
		set ptr = 0, toMatch = ""
		while $listnext(dictIds, ptr, dictId) {
			set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId, dictId),$lb(0,0,0))
			if ($li(status,1)<latestDT) || (+$lg(status,2)<entUniId) {
				set toMatch = toMatch _ $lb(dictId)
			}
		}
		set:toMatch'="" tSC = ..MatchEntityUniques(domainId,toMatch)
		quit:$$$ISERR(tSC)
	} else {
		if (latestDT > $lg($g(^IRIS.IK.Mat.DictMatchStatus(tDictDomainId)),1)) {
			set tSC = ..MatchEntityUniques(domainId, dictIds)
			quit:$$$ISERR(tSC)
		} else {
			set ptr = 0, toMatch = ""
			while $listnext(dictIds, ptr, dictId) {
				set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId, dictId),$lb(0,0,0))
				if (+$lg(status,2)<entUniId) {
					set toMatch = toMatch _ $lb(dictId)
				}
			}
			set:toMatch'="" tSC = ..MatchEntityUniques(domainId, toMatch)
			quit:$$$ISERR(tSC)
		}
	}
    
    // check domain settings if not supplied
    set:fullMatchOnly<0 fullMatchOnly = $$$IKFULLMATCHONLY(domainId)
    set:'$isobject(profile) profile = ##class(%iKnow.Matching.MatchingProfile).GetProfile(domainId, profile, .tSC)
    quit:$$$ISERR(tSC)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
	
	// BDB796 - when looking for cross-domain dictionaries, need to look for DEs in the
	// negative range. start from 0 for in-domain dictionaries
	set de = $s(xDomDicts:"", 1:0)
	for {
		set d = ""
		set de = $o(^IRIS.IK.Mat.EntUniToDictElem(domainId, entUniId, de),1,d)
		quit:de=""
		
		// BDB796 - when looking for cross-domain dictionaries, we can end early if we're
		// beyond the negative DE range.
		quit:xDomDicts&&(de>0)
		
		// if we're in standardizing mode, select the best standardized match for this DE
		if (tUseStandardizedForm'="") {
			if (language'="") {
				set langId = $lf($$$IKLANGUAGES, language)
				set langDetails = $g(^IRIS.IK.Mat.EntUniToDictElem(domainId, entUniId, de, langId))
				set:$lg($g(d),1)<$lg(langDetails,1) d = langDetails
			} else {
				set langId=""
				for {
					set langId = $order(^IRIS.IK.Mat.EntUniToDictElem(domainId, entUniId, de, langId),1,langDetails)
					quit:langId=""
					set:$lg($g(d),1)<$lg(langDetails,1) d = langDetails
				}
			}
		}
		continue:$g(d)=""
		
		set matchScore = $li(d,1)
    	continue:'matchScore
    	continue:fullMatchOnly&&(matchScore<1)
    	continue:(matchScore<profile.MinimalMatchScore)
		
		set count = count+1
		$$$IKCHECKPAGING(usePaging,first,last,count)
		
		set bits = $li(d,2)
		set matchedWordBits = ""
		for j=2:1:$bitcount(bits) { set matchedWordBits = matchedWordBits _ $s($bit(bits,j):1, 1:0) }
		set dictElement = ^IRIS.IK.Mat.DictElementId(tDictDomainId, $zabs(de))
		set xDom = $s(de<0:-1, 1:1)
		set dictId = $li(dictElement,1) * xDom
		continue:'$lf(dictIds,dictId)
		set dictTermId = $li(dictElement,2) * xDom
		set type = $s($li(dictElement,3)=$$$DETERM:"term", $li(dictElement,3)=$$$DEFORMAT:"format", 1:"unknown")
		set dictTerm = ^IRIS.IK.Mat.DictTermId(tDictDomainId, $zabs(dictTermId))
		set dictItemId = $li(dictTerm, 2) * xDom
		set dictTermStr = $li(dictTerm, 3)
		set dictItemURI = $li(^IRIS.IK.Mat.DictItemId(tDictDomainId, $zabs(dictItemId)),3)
		
		$$$IKQADDRESULT(result,count,$lb(dictId, dictItemId, dictItemURI, dictTermId, dictTermStr, +de, type, matchScore, matchedWordBits)_$li(d,3,4))
	}
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetTotalDictionaryScoresBySourceRT = "dictId:%Integer,dictionary:%String,matchCount:%Integer,totalScore:%Numeric";

///  Returns summary information for all matches in a given source (identified by External ID), organized per Dictionary.
ClassMethod GetTotalDictionaryScoresBySource(ByRef result, domainId As %Integer, externalId As %String, sortType As %Integer = {$$$SORTBYFREQUENCY}) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainId)
	$$$CHECKEXTIDEXISTS(domainId,externalId,srcId)
	
	quit ..GetTotalDictionaryScoresBySourceId(.result, domainId, srcId, sortType)
}

Parameter GetTotalDictionaryScoresBySourceIdRT = "dictId:%Integer,dictionary:%String,matchCount:%Integer,totalScore:%Numeric";

///  Returns summary information for all matches in a given source (identified by Source ID), organized per Dictionary.
ClassMethod GetTotalDictionaryScoresBySourceId(ByRef result, domainId As %Integer, srcId As %Integer, sortType As %Integer = {$$$SORTBYFREQUENCY}) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.Scores,^||%IK.ScoresSorted",tSC)
	if (srcId<0) && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	$$$CHECKASRCIDEXISTSX(domainId,srcId,srcDetails,vSrcId,tSC)
	$$$IKENSUREISMATCHEDX(domainId,srcId,"",tSC)
	$$$IKCHECKSORTTYPEX(domainId,sortType,$lb($$$SORTBYFREQUENCY,$$$SORTBYSCORE),tSC)
    
    set srcToMatchGlo = $s(vSrcId:"^IRIS.IKV.Mat.MatchId("_domainId_","_vSrcId_")", 1:"^IRIS.IK.Mat.SrcToMatch("_domainId_","_srcId_")")
	
	set matchId = ""
	for {
        set matchId = $o(@srcToMatchGlo@(matchId),1,matchInfo)
		quit:matchId=""
		
		set:'vSrcId matchInfo = ^IRIS.IK.Mat.MatchId(domainId, matchId)
		
		set dictId = $li(matchInfo,1)
		set matchScore = $li(matchInfo,6)
		
		set scores = $g(^||%IK.Scores(dictId), $lb(0,0))
		
		set $li(scores,1) = $li(scores,1) + 1
		set $li(scores,2) = $li(scores,2) + matchScore
		
		set ^||%IK.Scores(dictId) = scores
	}
	
	set dictId = "", sortIndex = $s(sortType=$$$SORTBYSCORE:2,1:1)
	for {
		set dictId = $order(^||%IK.Scores(dictId),1,scores)
		quit:dictId=""
		
		$$$IKQADDRESULTSORT(^||%IK.ScoresSorted,-$li(scores,sortIndex),$lb(+dictId) _ $li(^IRIS.IK.Mat.DictId($s(dictId<0:0, 1:domainId), $zabs(dictId)),1,1) _ $li(scores,1,2))
	}
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.ScoresSorted",0,0,0)
	$$$IKQENDCATCH(result,"^||%IK.Scores,^||%IK.ScoresSorted",tSC)
}

Parameter GetTotalItemScoresBySourceRT = "dictId:%Integer,dictionary:%String,dictItemId:%Integer,item:%String,URI:%String,matchCount:%Integer,totalScore:%Numeric";

///  <p>Returns summary information for all matches in a given source (identified by External ID), organized per Dictionary Item.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetTotalItemScoresBySource(ByRef result, domainId As %Integer, externalId As %String, dictIds As %List = "", sortType As %Integer = {$$$SORTBYFREQUENCY}) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainId)
	$$$CHECKEXTIDEXISTS(domainId,externalId,srcId)
	
	quit ..GetTotalItemScoresBySourceId(.result, domainId, srcId, dictIds, sortType)
}

Parameter GetTotalItemScoresBySourceIdRT = "dictId:%Integer,dictionary:%String,dictItemId:%Integer,item:%String,URI:%String,matchCount:%Integer,totalScore:%Numeric";

///  <p>Returns summary information for all matches in a given source (identified by Source ID), organized per Dictionary Item.</p>
///  <p>Specifying "" for <i>dictIds</i> will return results for all Dictionaries in this domain.</p>
ClassMethod GetTotalItemScoresBySourceId(ByRef result, domainId As %Integer, srcId As %Integer, dictIds As %List = "", sortType As %Integer = {$$$SORTBYFREQUENCY}) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.Scores,^||%IK.ScoresSorted",tSC)
	if (srcId<0) && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	$$$CHECKASRCIDEXISTSX(domainId,srcId,srcDetails,vSrcId,tSC)
	
	$$$IKENSURELISTNUM(dictIds)
	$$$IKENSUREISMATCHEDX(domainId,srcId,dictIds,tSC)
	
	$$$IKCHECKSORTTYPEX(domainId,sortType,$lb($$$SORTBYFREQUENCY,$$$SORTBYSCORE),tSC)
    
    set srcToMatchGlo = $s(vSrcId:"^IRIS.IKV.Mat.MatchId("_domainId_","_vSrcId_")", 1:"^IRIS.IK.Mat.SrcToMatch("_domainId_","_srcId_")")
	
	set matchId = ""
	for {
		set matchId = $order(@srcToMatchGlo@(matchId),1,matchInfo)
		quit:matchId=""
		
		set:'vSrcId matchInfo = ^IRIS.IK.Mat.MatchId(domainId, matchId)
		
		set dictId = $li(matchInfo,1)
		continue:(dictIds'="")&&'$lf(dictIds,dictId)
		
		set dictItemId = $li(matchInfo,2)
		set matchScore = $li(matchInfo,6)
		
		set scores = $g(^||%IK.Scores(dictItemId), $lb(dictId,0,0))
		
		set $li(scores,2) = $li(scores,2) + 1
		set $li(scores,3) = $li(scores,3) + matchScore
		
		set ^||%IK.Scores(dictItemId) = scores
	}
	
	set dictItemId = "", sortIndex = $s(sortType=$$$SORTBYSCORE:3,1:2)
	for {
		set dictItemId = $order(^||%IK.Scores(dictItemId),1,scores)
		quit:dictItemId=""
		
		set dictId = $li(scores,1)
		set tDictDomId = $s(dictId<0:0, 1:domainId)
		
		$$$IKQADDRESULTSORT(^||%IK.ScoresSorted,-$li(scores,sortIndex),$lb(dictId) _ $li(^IRIS.IK.Mat.DictId(tDictDomId,$zabs(dictId)),1,1) _ $lb(+dictItemId) _ $li(^IRIS.IK.Mat.DictItemId(tDictDomId,$zabs(dictItemId)),2,3) _ $li(scores,2,3))
	}
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.ScoresSorted",0,0,0)
	$$$IKQENDCATCH(result,"^||%IK.Scores,^||%IK.ScoresSorted",tSC)
}

///  Checks which of the supplied dictionary IDs still needs matching for this source and returns
///  the remaining ones in a %List. If "" is supplied as the list of dictionary IDs, it will
///  check against all dictionaries for this domain. Supports virtual sources (negative sourceId).
ClassMethod GetNonMatchedDictsForSource(domainId As %Integer, srcId As %Integer, dictIds As %List = "") As %List [ Internal ]
{
	set vSrcId = $s(srcId>0:0, 1:$zabs(srcId))
	
	if ('vSrcId) { $$$IKBITOFFPOS(srcId,srcOffset,srcPos) }
	set:domainId&&(dictIds="") dictIds = ..GetAllDictsAsList(domainId)
	
	set ptr=0, dictIdsToGo=""
	while $listnext(dictIds,ptr,d) {
		if (vSrcId) {
			set:'+$g(^IRIS.IKV.Mat.DictToSrcMatched(domainId,vSrcId,d)) dictIdsToGo = dictIdsToGo _ $lb(d)
		} else {
			set matchStatus =  $g(^IRIS.IK.Mat.DictMatchStatus(domainId,d),$lb(0,0,0))
			set lastDE = $lg(matchStatus,3)
			if (lastDE) {
				set lastDE = lastDE-1
				for {
					set lastDE = $o(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,d,lastDE))
					quit:lastDE=""
					
					quit:$bit(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,d,lastDE,srcOffset),srcPos) 
				}
			}
			set:'+lastDE dictIdsToGo = dictIdsToGo _ $lb(d)
		}
	}
	quit dictIdsToGo
}

Parameter GetTopItemsRT = "dictId:%Integer,dictItemId:%Integer,name:%String,URI:%String,frequency:%Integer,spread:%Integer,score:%Numeric";

///  <p>Returns the Dictionary Items for which most matches have been found in this domain (optionally
///  narrowed down through a <class>%iKnow.Filters.Filter</class> object passed in through <var>filter</var>).
///  Result sort order is controlled by <var>sortType</var>:</p>
///  <ul>
///  		<li>$$$SORTBYFREQUENCY will sort by the number of actual matches for a Dictionary Item</li>
///  		<li>$$$SORTBYSPREAD will sort by the number of distinct documents in which at least one match for the Dictionary Item occurs.</li>
///  		<li>$$$SORTBYSCORE will sort by the total match score of all matches for a Dictionary Item</li>
///  </ul>
///  <p>Specifying "" for <var>dictIds</var> will return results for all Dictionaries in this domain.</p>
ClassMethod GetTopItems(ByRef result, domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Filters.Filter = "", dictIds As %List = "", sortType As %Integer = {$$$SORTBYFREQUENCY}, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if vSrcId && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	$$$IKQFILTEROBJECTX(domainId,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainId,sortType,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD,$$$SORTBYSCORE),tSC)
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
	
	if (dictIds=$$$ALLXDOMDICTIONARIES) { set dictIds = ..GetAllDictsAsList(0) }
	$$$IKENSURELISTNUM(dictIds)
	
	// BDB328 - adding support for result cache
	if ('vSrcId) { $$$IKQRCCHECK(domainId,filter,"GetTopItems",$lb(domainId,,,filter,dictIds,sortType,vSrcId),page,pageSize,result)	}
	
	kill aItemFreq, aItemSpread, aItemScore
	set vSrcId = $zabs(vSrcId)
	if (vSrcId) {
		
		set matchId=""
		for {
			set matchId = $order(^IRIS.IKV.Mat.MatchId(domainId, vSrcId, matchId),1,matchInfo)
			quit:matchId=""

			set dictId = $li(matchInfo,1)
			if (dictIds'="") && '$lf(dictIds,dictId) {
				continue
			}
			set dictItemId = $li(matchInfo,2)
			set matchScore = $li(matchInfo,6)

			set x = $i(aItemFreq(dictItemId))
			set x = $i(aItemScore(dictItemId),matchScore)
			set aItemSpread(dictItemId) = 1
		}
		
	} else {
		
		// go through this slowly but thoroughly
		set srcOffset = ""
		for {
			if $isobject(filter) {
				set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
			} else {
				set srcOffset = $order(^IRIS.IK.SrcExistsBit(domainId, srcOffset),1,srcBits)
			}
			quit:srcOffset=""
		
			set srcPos = 0
			for {
				set srcPos = $bitfind(srcBits,1,srcPos+1)
				quit:srcPos=0
			
				$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
				
				set matchId=""
				for {
					set matchId = $order(^IRIS.IK.Mat.SrcToMatch(domainId, srcId, matchId))
					quit:matchId=""
				
					set matchInfo = ^IRIS.IK.Mat.MatchId(domainId, matchId)
		
					set dictId = $li(matchInfo,1)
					if (dictIds'="") && '$lf(dictIds,dictId) {
						continue
					}
					set dictItemId = $li(matchInfo,2)
					set matchScore = $li(matchInfo,6)
		
					set x = $i(aItemFreq(dictItemId))
					set x = $i(aItemScore(dictItemId), matchScore)
					set aItemSpread(dictItemId, srcId)=""
				}
			}
		}
	}
	
	// now sort
	set tItemId=""
	for {
		set tItemId = $o(aItemFreq(tItemId),1,tFreq)
		quit:tItemId=""
		
		set tSpread=0, tSrcId=""
		for {
			set tSrcId = $order(aItemSpread(tItemId,tSrcId))
			quit:tSrcId=""
			set x = $i(tSpread)
		}
		
		set tScores = $lb(tFreq,tSpread,aItemScore(tItemId))
		set tSort = $li(tScores, $case(sortType, $$$SORTBYFREQUENCY:1, $$$SORTBYSPREAD:2, $$$SORTBYSCORE:3))
		set aSort(-tSort,tItemId) = tScores
	}
	
	// now display results
	set tSort = "", tCount=0
	for {
		set tSort = $order(aSort(tSort))
		quit:tSort=""
		
		set tItemId = ""
		for {
			set tItemId = $order(aSort(tSort,tItemId),1,tScores)
			quit:tItemId=""
			
	        set x = $i(tCount)
	        $$$IKCHECKPAGING(usePaging,first,last,tCount)
			
			set xDom = $s(tItemId<0:-1, 1:1)
			set tItem = ^IRIS.IK.Mat.DictItemId($s(tItemId<0:0, 1:domainId), $zabs(tItemId))
			
			$$$IKQADDRESULT(result,tCount,$lb($li(tItem,1)*xDom, +tItemId) _ $li(tItem,2,3) _ tScores)
		}
	}
	
	// BDB328 - updating result cache
	if ('vSrcId) { $$$IKQRCSTORE(domainId,filter,"GetTopItems",$lb(domainId,,,filter,dictIds,sortType,vSrcId),page,pageSize,result,tSC)	}
	
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetTopTermsByItemIdRT = "dictTermId:%Integer,name:%String,frequency:%Integer,spread:%Integer,score:%Numeric";

///  <p>For a given Dictionary Item, returns all its Dictionary Terms sorted by the number of 
///  matches they have, optionally narrowed down through a <class>%iKnow.Filters.Filter</class>
///  object passed in through <var>pFilter</var>).
///  Result sort order is controlled by <var>pSortType</var>:</p>
///  <ul>
///  		<li>$$$SORTBYFREQUENCY will sort by the number of actual matches for the Dictionary Term
///  		<li>$$$SORTBYSPREAD will sort by the number of distinct documents in which at least one match for the Dictionary Term occurs.</li>
///  		<li>$$$SORTBYSCORE will sort by the total match score of all matches for a Dictionary Term</li>
///  </ul>
ClassMethod GetTopTermsByItemId(ByRef pResult, pDomainId As %Integer, pDictItemIds As %List, pFilter As %iKnow.Filters.Filter = "", pSortType As %Integer = {$$$SORTBYFREQUENCY}, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	$$$IKCHECKSORTTYPEX(pDomainId,pSortType,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD,$$$SORTBYSCORE),tSC)
	$$$IKENSURELISTNUM(pDictItemIds)
	
	kill aTermFreq, aTermSpread, aTermScore
	set vSrcId=$zabs(vSrcId)
	if (vSrcId) {
		
		set matchId=""
		for {
			set matchId = $order(^IRIS.IKV.Mat.MatchId(pDomainId, vSrcId, matchId),1,matchInfo)
			quit:matchId=""

			set dictItemId = $li(matchInfo,2)
			continue:'$lf(pDictItemIds,dictItemId)
			
			set dictTermId = $li(matchInfo,3)
			set matchScore = $li(matchInfo,6)

			set scores = $g(aTerms(dictTermId), $lb(0,1,0))
			set x = $i(aTermFreq(dictTermId))
			set x = $i(aTermScore(dictTermId),matchScore)
			set aTermSpread(dictTermId,vSrcId) = ""
		}
		
	} else {
		
		// go through this slowly but thoroughly
		// structure aTerms(dictTermId) = $lb(frequency, score)
		//			 aTermsSpread(dictTermId) = spread
		kill aMatches
		set ptr=0
		while $listnext(pDictItemIds,ptr,tDictItemId) {
			merge aMatches = ^IRIS.IK.Mat.DictItemToMatch(pDomainId,tDictItemId)
		}
		
		set tMatchId = ""
		for {
			set tMatchId = $order(aMatches(tMatchId))
			quit:tMatchId=""
			
			set tMatch = ^IRIS.IK.Mat.MatchId(pDomainId,tMatchId)
			set tSrcId = ..GetSourceIdForMatchTarget(pDomainId,$li(tMatch,4),$li(tMatch,5))
			continue:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId)
			
			set tDictTermId = $li(tMatch,3), tMatchScore = $li(tMatch,6)
			set x = $i(aTermFreq(tDictTermId))
			set x = $i(aTermScore(tDictTermId),tMatchScore)
			set aTermSpread(tDictTermId,tSrcId)=""
		}
	}
	
	// now sort
	kill aSort
	set tDictTermId=""
	for {
		set tDictTermId = $o(aTermFreq(tDictTermId),1,tFreq)
		quit:tDictTermId=""
		
		set tSpread=0, tSrcId=""
		for { 
			set tSrcId=$order(aTermSpread(tDictTermId,tSrcId))
			quit:tSrcId=""
			set x = $i(tSpread)
		}
		
		set tScores = $lb(tFreq,tSpread,aTermScore(tDictTermId))
		set tSort = $li(tScores, $case(pSortType, $$$SORTBYFREQUENCY:1, $$$SORTBYSPREAD:2, $$$SORTBYSCORE:3))
		set aSort(-tSort,tDictTermId) = tScores
	}
	
	// now display results
	set tSort = "", tCount=0
	for {
		set tSort = $order(aSort(tSort))
		quit:tSort=""
		
		set tDictTermId = ""
		for {
			set tDictTermId = $order(aSort(tSort,tDictTermId),1,tScores)
			quit:tDictTermId=""
			
	        set x = $i(tCount)
			
			set tTerm = ^IRIS.IK.Mat.DictTermId($s(tDictTermId<0:0, 1:pDomainId), $zabs(tDictTermId))
			
			$$$IKQADDRESULT(pResult,tCount,$lb(+tDictTermId, $li(tTerm,3)) _ tScores)
		}
	}
	$$$IKQENDCATCH(pResult,"",tSC)
}

///  Builds an inverse index of the form index(entUniId) = $lb(dictIds,...) containing all dictionaries
///  that still need to be matched to EUs for entUniId values. The index also contains a second
///  subscript level index(entUniId, dictId) = lastDictElemId indicating that all DEs <= lastDictElemId
///  for that dictId can be skipped while treating larger entUniId values, UP TO the next entUniId entry.
///  For cross-domain dictionaries, dictIds are negative, but corresponding lastDictElemId are positive.
/// Note that this will be StemUniIds when $$$IKPSTEMMING '= 0 !!!
ClassMethod BuildInvertedEntUniMatchedIndex(domainId As %Integer, dictIds As %List, Output index) As %Status [ Internal, Private ]
{
	kill index, skipDEs
	set ptr = 0, index(0) = "", xDomDicts = ($lg(dictIds,1)<0)
	set maxDEinDom = +$o(^IRIS.IK.Mat.DictElementId(domainId,""),-1)
	set maxDExDom = +$o(^IRIS.IK.Mat.DictElementId(0,""),-1)
	while $listnext(dictIds,ptr,d) {
		set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId,d),$lb(0,0,0))
		set minEU = +$lg(status,2), minDE = +$lg(status,3)
		set maxDE = $s(d<0:maxDExDom, 1:maxDEinDom)
		if (minDE>=maxDE) {
			// if no new dictionary elements were added, we can use minEU
			set index(minEU) = $g(index(minEU)) _ $lb(d)
		} else {
			// if there were new ones, we need to start from the beginning
			set index(0) = $g(index(0)) _ $lb(d)
		}
		set skipDEs(minEU, d) = minDE
	}
	
	// first merge the dictionaries to match upwards
	set i = "", allDicts = ""
	for {
		set i = $o(index(i),1,dicts)
		quit:i=""
		set allDicts = allDicts _ dicts
		set index(i) = allDicts
	}
	
	// now merge skipDEs downwards
	kill skip
	set i = "", prevI = 0
	for {
		set i = $o(index(i),-1,dicts)
		quit:i=""
		
		merge:prevI index(i) = skip
		merge skip = skipDEs(i)
		set prevI = i
	}
	
	quit $$$OK
}

ClassMethod GetAllDictsAsList(domainId As %Integer) As %List [ Internal ]
{
	set d="", dictIds=""
	for {
		set d = $o(^IRIS.IK.Mat.DictId(domainId, d))
		quit:d=""
		set dictIds = dictIds _ $lb($s(domainId:+d, 1:-d))
	}
	quit dictIds
}

ClassMethod GetAllDictsAsArray(pDomainId As %Integer, Output pDicts) As %Status [ Internal, Private ]
{
	kill pDicts
	set d=""
	for {
		set d = $o(^IRIS.IK.Mat.DictId(pDomainId, d))
		quit:d=""
		set pDicts($s(pDomainId:+d, 1:-d))=""
	}
	quit $$$OK
}

ClassMethod GetCurrentDictElems(domainId As %Integer, dictIds As %List, Output asArray = "") As %Status [ Internal, Private ]
{
	kill asArray
	set ptr = 0
	while $listnext(dictIds,ptr,d) {
		set status = $g(^IRIS.IK.Mat.DictMatchStatus(domainId,d),$lb(0,0,0))
		set lastDE = $lg(status,3)
		set asArray(d) = lastDE
	}
	quit $$$OK
}

ClassMethod IsFullyMatched(domainId As %Integer, srcId As %Integer, dictIds As %List = "", Output details = "") As %Boolean [ Internal ]
{
	kill details
	set vSrcId = $s(srcId<0:-srcId, 1:0)
	$$$IKBITOFFPOS(srcId,srcOffset,srcPos)
	
	set:(dictIds=$$$ALLXDOMDICTIONARIES) dictIds = ..GetAllDictsAsList(0) 
	set:(dictIds="") dictIds = ..GetAllDictsAsList(domainId) _ ..GetAllDictsAsList(0)
	
	set ptr = 0, isFullyMatched = 1
	while $listnext(dictIds, ptr, dictId) {
		
		if ('vSrcId) {
			set lastMatchedDE = ""
			for {
				set lastMatchedDE = $o(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,lastMatchedDE),-1)
				quit:lastMatchedDE=""
				
				quit:$bit(^IRIS.IK.Mat.DictToSrcMatchedBit(domainId,dictId,lastMatchedDE,srcOffset),srcPos)
			}
			set details(dictId) = +lastMatchedDE
		} else {
			set details(dictId) = +$g(^IRIS.IKV.Mat.DictToSrcMatched(domainId, vSrcId, dictId))
		}
		
		set dictStatus = $g(^IRIS.IK.Mat.DictMatchStatus(domainId,dictId), $lb(0,0,0))
		set lastDictDE = +$lg(dictStatus,3)
		// TODO: check if lastDictDE is actually the last DE added!
		if 'lastDictDE || (details(dictId) < lastDictDE) {
			set isFullyMatched = 0
		}
	}
	
	quit isFullyMatched
}

Parameter GetErrorsRT = "sourceId:%Integer,externalId:%String,errorMessage:%String,date:%Date";

///  Returns any errors registered during the Matching process
ClassMethod GetErrors(ByRef result, domainId As %Integer, since As %Date = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainId,tSC)
	set i = "", j = 0
	for {
		set i = $order(^IRIS.IKL.Mat.Errors(domainId, i),1,data)
		quit:i=""
		
		set date = $lg(data,3)
		continue:date<since
		
		set srcId = $lg(data,1)
		set extId = $s(+srcId:##class(%iKnow.Queries.SourceAPI).GetExternalId(domainId,srcId), 1:"")
		set error = $lg(data,2)
		set:$$$ISERR(error) error = $$GetErrorText^%apiOBJ(error)
		$$$IKQADDRESULT(result,$i(j),$lb(srcId,extId,error,date))
	}
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter ClearLogsEXP [ Internal ] = 1;

///  Clears any matching-related logfiles for the specified domain.
ClassMethod ClearLogs(domainId As %Integer) As %Status
{
	$$$IKCHECKPRIVWRITE
	kill ^IRIS.IKL.Mat.Errors(domainId)
	quit $$$OK
}

///  Clears any temp globals used during previous runs, including aborted ones
///  (processes finishing successfully would clean up themselves)
ClassMethod ClearTemps(domainId As %Integer) As %Status [ Internal ]
{
	// domain-indexed globals
	for glob = "DictToMatch","DictToSrc","DictToSrcMatched" {
		kill @("^IRIS.IKT.Mat."_glob)@(domainId)
	}
	
	// process-specific globals
	set maxProcs = $$$GETPARAM(domainId,$$$IKPJOBS,1)
	for glob = "EU2DE","D2M","D2S","EO2M","DI2M","S2M","S2MS" {
		for i=1:1:maxProcs {
			kill @("^IRIS.IKT."_domainId_".Mat."_glob_"."_i)
		}
	}
	
	// cachetemp globals
	$$$IKTEMPDOMID(domainId,tTempId)
	kill ^IRIS.Temp.IK.Mat.EUProc(tTempId)
	kill ^IRIS.Temp.IK.Mat.SrcProc(tTempId)
	
	// ppgs (usually emptied automatically)
	kill ^||%IK.DictFormatCache, ^||%IK.DEMatches, ^||%IKV.Mat.DictToMatch
    kill ^||%IK.Mat.DictElemCache, ^||%IK.Mat.DictTermCache
    kill ^||%IK.Mat.NewMatches, ^||%IK.Mat.DictToSrcInProgress
    kill ^||%IK.PathMatches, ^||%IK.CrcMatches
	
	quit $$$OK
}

Parameter GetMatchesByDictionaryItemURIRT = "matchId:%Integer,dictTermId:%Integer,sourceId:%Integer,externalId:%String,targetType:%String,targetId:%Integer,targetUniId:%Integer,targetValue:%String,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>This query returns all the match occurrences for the Dictionary Item
///  specified through <var>dictItemURI</var>.</p>
///  <p>Specifying a <class>%iKnow.Filters.Filter</class> object as <var>filter</var> will
///  restrict the search space to only those sources satisfying the filters criteria. 
///  Through <var>targetTypes</var>, the desired target types can be specified in a %List
///  (defaults to all types).</p>
ClassMethod GetMatchesByDictionaryItemURI(ByRef result, domainId As %Integer, dictItemURI As %String, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Filters.Filter = "", targetTypes As %List = "", xDomDicts As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	set tDictDomId = $s(xDomDicts:0, 1:domainId)
	set dictItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(tDictDomId, dictItemURI, .tSC)
	quit:$$$ISERR(tSC) tSC
	quit:'dictItemId $$$ERROR($$$IKDictItemDoesNotExist, dictItemURI)
	
	quit ..GetMatchesByDictionaryItemId(.result, domainId, $s(xDomDicts:-dictItemId, 1:dictItemId), page, pageSize, filter, targetTypes)
}

Parameter GetMatchesByDictionaryItemIdRT = "matchId:%Integer,dictTermId:%Integer,sourceId:%Integer,externalId:%String,targetType:%String,targetId:%Integer,targetUniId:%Integer,targetValue:%String,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>This query returns all the match occurrences for the Dictionary Item
///  specified through <var>dictItemId</var>.</p>
///  <p>Specifying a <class>%iKnow.Filters.Filter</class> object as <var>filter</var> will
///  restrict the search space to only those sources satisfying the filters criteria. 
///  Through <var>targetTypes</var>, the desired target types can be specified in a %List
///  (defaults to all types).</p>
ClassMethod GetMatchesByDictionaryItemId(ByRef result, domainId As %Integer, dictItemId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Filters.Filter = "", targetTypes As %List = "", ensureMatched As %Boolean = 1) As %Status
{
    $$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainId,tSC)
	set tDictDomId = $s(dictItemId<0:0, 1:domainId)
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mat.DictItemId,tDictDomId,$zabs(dictItemId),itemDetails,$$$IKDictItemDoesNotExist,tSC)
	$$$IKQFILTEROBJECTX(domainId,filter,tSC)
	
	$$$IKENSURELISTNUM(targetTypes)
	set:targetTypes="" targetTypes = $lb($$$DMTARGETENTITY,$$$DMTARGETCRC,$$$DMTARGETPATH,$$$DMTARGETSENT)
	
	// ensure sources are matched
	if (ensureMatched) {
		set tDictId = $li(itemDetails,1), tDictId = $s(tDictDomId:tDictId, 1:-tDictId)
		set tSC = ..MatchSources(domainId, filter, $lb(tDictId))
		quit:$$$ISERR(tSC)
	}
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,i)
    
    set matchId = "", i = 0
    for {
        set matchId = $o(^IRIS.IK.Mat.DictItemToMatch(domainId, dictItemId, matchId))
        quit:matchId=""
        
        set match = ^IRIS.IK.Mat.MatchId(domainId, matchId)
        set targetType = $li(match,4), targetId = $li(match,5)
        continue:'$listfind(targetTypes,targetType)
        
        set srcId = ..GetSourceIdForMatchTarget(domainId, targetType, targetId)
        continue:$isobject(filter)&&'filter.IsFiltered(srcId,$$$IKFSOURCE)
        
        set i = i+1
        $$$IKCHECKPAGING(usePaging,first,last,i)
        
        set extId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainId, srcId)
        
        // derive display string
        if (targetType=$$$DMTARGETENTITY) {
	        set targetUniId = $li(^IRIS.IK.EntOccId(domainId,targetId),1)
	        set targetValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainId, targetUniId)
        } elseif (targetType=$$$DMTARGETCRC) {
	        set targetUniId = $li(^IRIS.IK.CrcOccId(domainId,targetId),1)
	        set targetValue = ##class(%iKnow.Queries.CrcAPI).GetValueInternal(domainId, targetUniId)
	        set targetValue = $lts(targetValue," - ")
        } elseif (targetType=$$$DMTARGETPATH) {
	        set targetUniId = targetId
	        set targetValue = ##class(%iKnow.Queries.PathAPI).GetValue(domainId, targetUniId)
	        set targetValue = $lts(targetValue," - ")
        } elseif (targetType=$$$DMTARGETSENT) {
	        set targetValue = ##class(%iKnow.Queries.SentenceAPI).GetValue(domainId, targetId)
	        set targetUniId = targetId
        }
        $$$IKQADDRESULT(result,i,$lb(+matchId, $li(match,3), srcId, extId, targetType, targetId, targetUniId, targetValue) _ $li(match,6,13))
    }
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetMatchesByDictionaryTermIdRT = "matchId:%Integer,sourceId:%Integer,externalId:%String,targetType:%String,targetId:%Integer,targetUniId:%Integer,targetValue:%String,matchScore:%Numeric,matchingConceptCount:%Integer,matchingRelationCount:%Integer,partialMatchCount:%Integer,firstMatchedPosInPath:%Integer,lastMatchedPosInPath:%Integer,isOrdered:%Boolean,negatedEntityCount:%Integer";

///  <p>This query returns all the match occurrences for the Dictionary Term
///  specified through <var>pDictTermId</var>.</p>
///  <p>Specifying a <class>%iKnow.Filters.Filter</class> object as <var>pFilter</var> will
///  restrict the search space to only those sources satisfying the filters criteria. 
///  Through <var>pTargetTypes</var>, the desired target types can be specified in a %List
///  (defaults to all types).</p>
ClassMethod GetMatchesByDictionaryTermId(ByRef pResult, pDomainId As %Integer, pDictTermId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pTargetTypes As %List = "", pEnsureMatched As %Boolean = 1) As %Status
{
    $$$IKQBEGINTRY(pResult,"",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	set tDictDomId = $s(pDictTermId<0:0, 1:pDomainId)
	$$$IKCHECKIDEXISTSX(^IRIS.IK.Mat.DictTermId,tDictDomId,$zabs(pDictTermId),tTerm,$$$IKDictTermDoesNotExist,tSC)
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	
	$$$IKENSURELISTNUM(pTargetTypes)
	set:pTargetTypes="" pTargetTypes = $lb($$$DMTARGETENTITY,$$$DMTARGETCRC,$$$DMTARGETPATH,$$$DMTARGETSENT)
	
	// ensure sources are matched
	if (pEnsureMatched) {
		set tDictId = $li(tTerm,1), tDictId = $s(tDictDomId:tDictId, 1:-tDictId)
		set tSC = ..MatchSources(pDomainId, pFilter, $lb(tDictId))
		quit:$$$ISERR(tSC)
	}
	
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
    
    set tMatchId="", tCount=0, tDictItemId=$s(tDictDomId:$li(tTerm,2), 1:-$li(tTerm,2))
    for {
        set tMatchId = $o(^IRIS.IK.Mat.DictItemToMatch(pDomainId, tDictItemId, tMatchId))
        quit:tMatchId=""
        
        set tMatch = ^IRIS.IK.Mat.MatchId(pDomainId, tMatchId)
        continue:$li(tMatch,3)'=pDictTermId
        set tTargetType = $li(tMatch,4), tTargetId = $li(tMatch,5)
        continue:'$listfind(pTargetTypes,tTargetType)
        
        set tSrcId = ..GetSourceIdForMatchTarget(pDomainId, tTargetType, tTargetId)
        continue:$isobject(pFilter)&&'pFilter.IsFiltered(tSrcId,$$$IKFSOURCE)
        
        set x = $i(tCount)
        $$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
        
        set tExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(pDomainId, tSrcId)
        
        // derive display string
        if (tTargetType=$$$DMTARGETENTITY) {
	        set tTargetUniId = $li(^IRIS.IK.EntOccId(pDomainId,tTargetId),1)
	        set tTargetValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tTargetUniId)
        } elseif (tTargetType=$$$DMTARGETCRC) {
	        set tTargetUniId = $li(^IRIS.IK.CrcOccId(pDomainId,tTargetId),1)
	        set tTargetValue = ##class(%iKnow.Queries.CrcAPI).GetValueInternal(pDomainId, tTargetUniId)
	        set tTargetValue = $lts(tTargetValue," - ")
        } elseif (tTargetType=$$$DMTARGETPATH) {
	        set tTargetUniId = tTargetId
	        set tTargetValue = ##class(%iKnow.Queries.PathAPI).GetValue(pDomainId, tTargetUniId)
	        set tTargetValue = $lts(tTargetValue," - ")
        } elseif (tTargetType=$$$DMTARGETSENT) {
	        set tTargetValue = ##class(%iKnow.Queries.SentenceAPI).GetValue(pDomainId, tTargetId)
	        set tTargetUniId = tTargetId
        }
        $$$IKQADDRESULT(pResult,tCount,$lb(+tMatchId, tSrcId, tExtId, tTargetType, tTargetId, tTargetUniId, tTargetValue) _ $li(tMatch,6,13))
    }
	$$$IKQENDCATCH(pResult,"",tSC)
}

Parameter GetTopMatchesByDictionaryItemURIRT = "targetType:%Integer,targetUniId:%Integer,targetValue:%String,frequency:%Integer,spread:%Integer,bestScore:%Numeric";

///  <p>This query returns the "best" matching results for the Dictionary Item
///  specified through <var>dictItemURI</var>, aggregated by matched unique target
///  (entity, CRC, path or sentence). The meaning of "best" is defined by <var>sortType</var>:
///  if set to $$$SORTBYFREQUENCY or $$$SORTBYSPREAD, results are sorted by decreasing
///  number of matched occurrences, whereas $$$SORTBYSCORE will rank them according to the
///  highest match score. The first two options will yield the most relevant results for
///  entities and CRCs, with the score ranking a better fit for paths and sentences, as they
///  inherently have frequency and spread equal to 1.</p>
///  <p>Specifying a <class>%iKnow.Filters.Filter</class> object as <var>filter</var> will
///  restrict the search space to only those sources satisfying the filters criteria. 
///  Through <var>targetTypes</var>, the desired target types can be specified in a %List
///  (defaults to all types).</p>
ClassMethod GetTopMatchesByDictionaryItemURI(ByRef result, domainId As %Integer, dictItemURI As %String, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Filters.Filter = "", targetTypes As %List = "", sortType As %Integer = {$$$SORTBYFREQUENCY}, xDomDicts As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	set dictItemId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI($s(xDomDicts:0, 1:domainId), dictItemURI, .tSC)
	quit:$$$ISERR(tSC) tSC
	quit:'dictItemId $$$ERROR($$$IKDictItemDoesNotExist, dictItemURI)
	
	quit ..GetTopMatchesByDictionaryItemId(.result, domainId, $s(xDomDicts:-dictItemId, 1:dictItemId), page, pageSize, filter, targetTypes)
}

Parameter GetTopMatchesByDictionaryItemIdRT = "targetType:%Integer,targetUniId:%Integer,targetValue:%String,frequency:%Integer,spread:%Integer,bestScore:%Numeric";

///  <p>This query returns the "best" matching results for the Dictionary Item
///  specified through <var>dictItemId</var>, aggregated by matched unique target
///  (entity, CRC, path or sentence). The meaning of "best" is defined by <var>sortType</var>:
///  if set to $$$SORTBYFREQUENCY or $$$SORTBYSPREAD, results are sorted by decreasing
///  number of matched occurrences, whereas $$$SORTBYSCORE will rank them according to the
///  highest match score. The first two options will yield the most relevant results for
///  entities and CRCs, with the score ranking a better fit for paths and sentences, as they
///  inherently have frequency and spread equal to 1.</p>
///  <p>Specifying a <class>%iKnow.Filters.Filter</class> object as <var>filter</var> will
///  restrict the search space to only those sources satisfying the filters criteria. 
///  Through <var>targetTypes</var>, the desired target types can be specified in a %List
///  (defaults to all types).</p>
ClassMethod GetTopMatchesByDictionaryItemId(ByRef result, domainId As %Integer, dictItemId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, filter As %iKnow.Filters.Filter = "", targetTypes As %List = "", sortType As %Integer = {$$$SORTBYDOMAINDEFAULT}) As %Status
{
    $$$IKQBEGINTRY(result,"^||%IK.MValues,^||%IK.MFreq,^||%IK.MSpread,^||%IK.MSort,^||%IK.MScore,^||%IKQ.MatchesByItem",tSC)
	$$$IKQFILTEROBJECTX(domainId,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainId,sortType,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD,$$$SORTBYSCORE),tSC)
    
    set tSC = ..GetMatchesByDictionaryItemId("^||%IKQ.MatchesByItem", domainId, dictItemId, 0, 0, filter, targetTypes)
	quit:$$$ISERR(tSC)
	
	$$$IKSORTBEGIN(^||%IK.MValues)
	$$$IKSORTBEGIN(^||%IK.MFreq)
	$$$IKSORTBEGIN(^||%IK.MSpread)
	set i = ""
	for {
		set i = $order(^||%IKQ.MatchesByItem(i),1,match)
		quit:i=""
		
		// identifier: "[targetType],[targetUniId]"
		set id = $li(match,5)_","_$li(match,7)
		
		set ^||%IK.MValues(id) = $li(match,8)
		set ^||%IK.MFreq(id,$li(match,6)) = ""
		set ^||%IK.MSpread(id,$li(match,3)) = ""
		
		set score = $li(match,9)
		set:($g(^||%IK.MScore(id))<score) ^||%IK.MScore(id) = score
	}
	set x = $sortend(^||%IK.MValues)
	set x = $sortend(^||%IK.MFreq)
	set x = $sortend(^||%IK.MSpread)
	
	// now gather data for each ID
	$$$IKSORTBEGIN(^||%IK.MSort)
	set id = ""
	for {
		set id = $order(^||%IK.MValues(id), 1, value)
		quit:id=""
		
		set score = ^||%IK.MScore(id)
		
		// freq
		set i="", freq=0
		for {
			set i = $order(^||%IK.MFreq(id,i))
			quit:i=""
			set x = $i(freq)
		}
		
		// spread
		set i="", spread=0
		for {
			set i = $order(^||%IK.MSpread(id,i))
			quit:i=""
			set x = $i(spread)
		}
		
		set sort = $case(sortType, $$$SORTBYFREQUENCY:freq, $$$SORTBYSPREAD:spread, $$$SORTBYSCORE:score, :freq)
		set secondSort = $case(sortType, $$$SORTBYFREQUENCY:spread, :freq)
		set ^||%IK.MSort(-sort, -secondSort) = $lb(+$p(id,",",1), +$p(id,",",2), value, freq, spread, score)
	}
	set x = $sortend(^||%IK.MSort)
	
	$$$IKSETPAGINGVARS(page,pageSize,usePaging,first,last,count)
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.MSort",usePaging,first,last)
	
	$$$IKQENDCATCH(result,"^||%IK.MValues,^||%IK.MFreq,^||%IK.MSpread,^||%IK.MSort,^||%IK.MScore,^||%IKQ.MatchesByItem",tSC)
}

/// Utility method to retrieve the Sentence ID for a given match target, as specified by its target type
/// (either of $$$DMTARGETENTITY, $$$DMTARGETCRC, $$$DMTARGETPATH or $$$DMTARGETSENT) and ID.
ClassMethod GetSentenceIdForMatchTarget(domainId As %Integer, targetType As %Integer, targetId As %Integer, vSrcId As %Integer = 0) As %Integer
{
	set domainId=+$g(domainId), targetType=+$g(targetType), targetId=+$g(targetId)
	if (targetType = $$$DMTARGETENTITY) {
		quit $s(vSrcId:$lg($g(^IRIS.IKV.EntOccId(domainId, vSrcId, targetId)),3) , 1:$lg($g(^IRIS.IK.EntOccId(domainId, targetId)), 3))
	} elseif (targetType = $$$DMTARGETCRC) {
		quit $s(vSrcId:$lg($g(^IRIS.IKV.CrcOccId(domainId, vSrcId, targetId)), 5), 1:$lg($g(^IRIS.IK.CrcOccId(domainId, targetId)), 5))
	} elseif (targetType = $$$DMTARGETPATH) {
		quit ##class(%iKnow.Queries.PathAPI).GetSentenceId(domainId, targetId,, vSrcId)
	} elseif (targetType = $$$DMTARGETSENT) {
		quit targetId
	}
	quit ""
}

/// Utility method to retrieve the Source ID for a given match target, as specified by its target type
/// (either of $$$DMTARGETENTITY, $$$DMTARGETCRC, $$$DMTARGETPATH or $$$DMTARGETSENT) and ID.
ClassMethod GetSourceIdForMatchTarget(domainId As %Integer, targetType As %Integer, targetId As %Integer) As %Integer
{
	set domainId=+$g(domainId), targetType=+$g(targetType), targetId=+$g(targetId)
	quit ##class(%iKnow.Queries.SentenceAPI).GetSourceId(domainId, +..GetSentenceIdForMatchTarget(domainId,targetType,targetId))
}

ClassMethod StandardizedForm(pString As %String, pLanguage As %String, pFunction As %String = {$$$IKPMATSTANDARDIZEDFORMTEXT}) As %String [ Internal ]
{
	if (pFunction=$$$IKPMATSTANDARDIZEDFORMTEXT) {
		set cls = "%Text."_$case(pLanguage, "en":"English", "fr":"French", "de":"German", "es":"Spanish", "pt":"Portuguese","ja":"Japanese", "it":"Italian", :"Text")
		quit $zstrip($classmethod(cls, "Standardize", pString), "<>W")
	} elseif (pFunction=$$$IKPMATSTANDARDIZEDFORMSTEMMING) { // BDB600
		quit ##class(%iKnow.Queries.EntityAPI).GetStem(,pString,pLanguage)
	} else {
		quit $classmethod($p(pFunction,":",1), $p(pFunction,":",2), pString, pLanguage)
	}
}

Parameter GetTopSourcesByDictionaryRT = "srcId:%Integer,externalId:%String,matchCount:%Integer,totalScore:%Numeric";

/// <p>Returns the sources best matching a given list of dictionaries specified through
/// <var>pDictIds</var>, optionally filtered through <var>pFilter</var>. "Best matching" is
/// defined as having the highest number of matches (if <var>pSortType</var> = $$$SORTBYFREQUENCY)
/// or the highest total match score (if <var>pSortType</var> = $$$SORTBYSCORE).</p>
/// <p>If <var>pNormalizeLength</var> is set to a nonzero value, this number is used as the power
/// of the sources length in entities (occurrences) to normalize the score.</p>
ClassMethod GetTopSourcesByDictionary(ByRef pResult, pDomainId As %Integer, pDictIds As %List, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pSortType As %Integer = {$$$SORTBYFREQUENCY}, pNormalizeLength As %Numeric = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.SourcesBit,^||%IK.SrcSort",tSC)
	$$$CHECKDOMAINEXISTSX(pDomainId,tSC)
	$$$IKENSURELISTNUM(pDictIds)
	$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
	$$$IKCHECKSORTTYPEX(pDomainId,pSortType,$lb($$$SORTBYFREQUENCY,$$$SORTBYSCORE),tSC)
	
	// first gather the sources we'll be looking at
	set ptr=0
	while $listnext(pDictIds,ptr,tDictId) {
		set gFrom = $name(^IRIS.IK.Mat.DictToSrcBit(pDomainId,tDictId))
		$$$IKMERGEBITSOR(gFrom,"^||%IK.SourcesBit")
	}
	
	// apply filter, if any
	if ($isobject(pFilter)) {
		set tSC = pFilter.MergeBits("^||%IK.SourcesBit")
		quit:$$$ISERR(tSC)
	}
	
	// now loop through these sources and their match results
	set x = $sortbegin(^||%IK.SrcSort)
	set tOffset = ""
	for {
		set tOffset = $order(^||%IK.SourcesBit(tOffset),1,tBits)
		quit:tOffset=""
		
		set tPos=0
		for {
			set tPos = $bitfind(tBits,1,tPos+1)
			quit:'tPos
			
			$$$IKGETIDOFFPOS(tSrcId,tOffset,tPos)
			
			set tMatchId="", tCount=0, tScore=0
			for {
				set tMatchId = $order(^IRIS.IK.Mat.SrcToMatch(pDomainId, tSrcId, tMatchId))
				quit:tMatchId=""
				
				set tMatch = ^IRIS.IK.Mat.MatchId(pDomainId, tMatchId)
				continue:'$lf(pDictIds,$li(tMatch,1))
				
				set x = $i(tCount)
				set x = $i(tScore, $lg(tMatch,6))
			}
			
			set tSort = $case(pSortType, $$$SORTBYFREQUENCY:tCount, $$$SORTBYSCORE:tScore)
			set:pNormalizeLength tSort = tSort / ($li(^IRIS.IK.SrcDetails(pDomainId,tSrcId),4)**pNormalizeLength)
			set ^||%IK.SrcSort(-tSort, tSrcId) = $lb(tCount, $normalize(tScore,4))
		}
	}
	set x = $sortend(^||%IK.SrcSort)
	
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	set tSort = ""
	for {
		set tSort = $order(^||%IK.SrcSort(tSort))
		quit:tSort=""
		
		set tSrcId = ""
		for {
			set tSrcId = $order(^||%IK.SrcSort(tSort,tSrcId),1,tData)
			quit:tSrcId=""
			
			set x = $i(tCount)
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			
			set tData = $lb(+tSrcId, ##class(%iKnow.Queries.SourceAPI).GetExternalId(pDomainId,tSrcId)) _ tData
			$$$IKQADDRESULT(pResult,tCount,tData)
		}
		$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.SourcesBit,^||%IK.SrcSort",tSC)
}

}
