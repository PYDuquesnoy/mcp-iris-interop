/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.UI.TestUtils [ Abstract, Deprecated, System = 4 ]
{

Property highlightedSentencesOnly As %ZEN.Datatype.boolean;

XData textInputDetails [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<tabGroup id="tgrDetails" showTabBar="true">

<tab caption="Text" enclosingStyle="padding: 12px;">
<html id="htmlText" OnDrawContent="DrawCategorizedText" enclosingClass="highlightedTextPane" />
<spacer height="10" />
<hgroup>
<checkbox onchange="zenPage.setProperty('highlightedSentencesOnly',zenThis.getValue()); zen('htmlText').refreshContents();" />
<label label="Matching sentences only" />
</hgroup>
</tab>

<tab caption="Categories" enclosingStyle="padding: 12px;">
<html id="htmlCategories" OnDrawContent="DrawCategorizedScores" enclosingClass="highlightedTextPane" />
</tab>

<tab caption="Trace info" enclosingStyle="padding: 12px;">
<vgroup labelPosition="left">
<select id="selTraceCategories" label="Weights for category" 
   onchange="var sc = zen('htmlTrace').setProperty('seed',zenThis.getValue()); zen('htmlTrace').refreshContents();" >
<parameter value="#(%page.testId)#" />
</select>
</vgroup>
<spacer height="10" />
<html id="htmlTrace" OnDrawContent="DrawCategorizedTrace" enclosingClass="highlightedTextPane" />
</tab>

</tabGroup>
</pane>
}

ClientMethod refreshDetails() [ Language = javascript ]
{
	zen('htmlText').refreshContents();
	zen('htmlCategories').refreshContents();
	zen('htmlTrace').setProperty('seed', '');
	zen('htmlTrace').refreshContents();
}

Method GetDetailInput(Output pText As %String, Output pConfig As %String, Output pDomainId As %Integer, Output pSrcId As %Integer) As %Status [ Abstract, Private ]
{
}

Method GetClassifierClass() As %String [ Abstract, Private ]
{
}

Method %OnAfterCreateDetailPane() As %Status
{
	set tSC = $$$OK
	try {
		set tClassifierClass = ..GetClassifierClass()
		if (tClassifierClass'="") {
			set tSC = $classmethod(tClassifierClass, "%GetCategories", .tCategories)
			quit:$$$ISERR(tSC)
			
			set (tValueList, tDisplayList) = ""
			for i = 1:1:tCategories {
				set tValueList = tValueList _ $s(i=1:"", 1:",") _ i
				set tDisplayList = tDisplayList _ $s(i=1:"", 1:",") _ $lg(tCategories(i),1)
			}
			set ..%GetComponentById("selTraceCategories").valueList = tValueList
			set ..%GetComponentById("selTraceCategories").displayList = tDisplayList
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawCategorizedText(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..GetDetailInput(.tText, .tConfig, .tDomainId, .tSrcId)
		quit:$$$ISERR(tSC)
		
		if ('tSrcId) {
			quit:tText=""
			set tSC = $system.iKnow.IndexString("", "ref", tText, tConfig, 1, .tSrcId)
			quit:$$$ISERR(tSC)
		}
		set vSrcId = $s(tSrcId<0:$zabs(tSrcId), 1:0)
		
		#dim tClassifier As %iKnow.Classification.Classifier
		set tClassifier = $classmethod(..GetClassifierClass(),"%New")
		
		// build highlight array
		set tStyle = "<span class=""highlightedTerm"">"
		set tSC = tClassifier.%GetIKnowDictionaryMapping(.tDictId)
		quit:$$$ISERR(tSC)
		
		set tSC = tClassifier.%BuildIKTermMap(tDomainId, .tTermMap, vSrcId)
		quit:$$$ISERR(tSC)
		set tVirtualize = $s(vSrcId:-1, 1:1)
		
		// entities
		set tEntUniId = ""
		for {
			set tEntUniId = $order(tTermMap(0, tEntUniId))
			quit:tEntUniId=""
			set tHighlight("ENTITY", tEntUniId*tVirtualize) = tStyle
		}
		set tCrcUniId = ""
		for {
			set tCrcUniId = $order(tTermMap(1, tCrcUniId))
			quit:tCrcUniId=""
			set tHighlight("CRC", tCrcUniId*tVirtualize) = tStyle
		}
		set tCoocId = ""
		for {
			set tCoocId = $order(tTermMap(2, tCoocId), 1, tCoocInfo)
			quit:tCoocId=""
			set tEntUniIds = $lg(tCoocInfo,3), ptr=0
			while $listnext(tEntUniIds, ptr, tEntUniId) {
				set tHighlight("ENTITY", tEntUniId*tVirtualize) = tStyle
			}
		}
		
		if (tDictId) {
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(tDomainId, tSrcId, $lb(-tDictId))
			quit:$$$ISERR(tSC)
			set tHighlight("MATCH",-tDictId) = tStyle
		}
		
		if (vSrcId) {
			set tSource = ##class(%iKnow.Objects.VirtualSource).PKINDEXOpen(tDomainId, vSrcId)
		} else {
			set tSource = ##class(%iKnow.Objects.Source).PKINDEXOpen(tDomainId, tSrcId)
		}
			
		set tPrevSentId = 0
		for tSentId = tSource.FirstSentenceId:1:tSource.FirstSentenceId+tSource.SentenceCount-1 {
			set tHighlightedValue = ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(tDomainId, tSentId, .tHighlight, vSrcId,, .tSC)
			if (..highlightedSentencesOnly) {
				continue:'(tHighlightedValue[$p(tStyle," ",1))
				write:(tPrevSentId<(tSentId-1)) "... "
				write tHighlightedValue," "
			} else {
				write tHighlightedValue," "
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// clean up
		do:vSrcId ##class(%iKnow.Source.Loader).DeleteVirtualSource(tDomainId, vSrcId)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	try {
		if $g(vSrcId) {
			do ##class(%iKnow.Source.Loader).DeleteVirtualSource(tDomainId, vSrcId)
		}	
	} catch (ex) {}
	quit tSC
}

Method DrawCategorizedScores(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		#dim tClassifier As %iKnow.Classification.Classifier
		set tClassifier = $classmethod(..GetClassifierClass(),"%New")
		
		set tSC = ..GetDetailInput(.tText, .tConfig, .tDomainId, .tSrcId)
		quit:$$$ISERR(tSC)
		
		if (tSrcId) {
			set tDomainName = $system.iKnow.GetDomainName(tDomainId)
			set tSC = tClassifier.%Categorize(.tCats, tSrcId, "iKnow", tDomainName)
			quit:$$$ISERR(tSC)
		} else {
			quit:tText=""
			set tSC = tClassifier.%CategorizeText(.tCats, tText, tConfig)
			quit:$$$ISERR(tSC)
		}
		
		if '$d(tCats) {
			write "<p>No results for this input string.</p>"
			quit
		}
		
        set tMaxWeight = "", tMinWeight = ""
        set tHasPos = 0, tHasNeg = 0
        for i = 1:1:$g(tCats) {
	        set tWeight = +$lg(tCats(i),2)
	        if (tWeight > 0) {
		        set tHasPos = 1
	        } else {
		        set tHasNeg = 1
	        }
	        set tWeights(tWeight) = ""
	        set tWeight = $zabs(tWeight)
	        set:(tMaxWeight="")||(tMaxWeight<tWeight) tMaxWeight = tWeight
	        set:(tMaxWeight="")||(tMaxWeight<tWeight) tMaxWeight = tWeight
        }
    	
        set tMaxBarWidth = 100, tMinBarWidth = 5
        if tHasPos && tHasNeg {
	        set tMax = $o(tWeights(""),-1), tMin = $o(tWeights(""))
	        set tMaxPosBarWidth = (tMaxBarWidth * tMax / (tMax + $zabs(tMin))) \ 1
	        set tMaxNegBarWidth = (tMaxBarWidth * $zabs(tMin) / (tMax + $zabs(tMin))) \ 1
        }
	
		&html<<table cellspacing="0" cellpadding="0">>
		&html<<tr><th width="200">Category</th><th width=200>Score</th></tr>>
		
		for i = 1:1:$g(tCats) {
			set tWeight = $li(tCats(i),2)
	        if (tHasPos && tHasNeg) {
		        if tWeight>0 {
			        set tWidth = tMaxPosBarWidth * tWeight / tMax
			        set tWeight = "<td width="""_(tMaxNegBarWidth+tMinBarWidth+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_((tWidth+tMinBarWidth)\1)_""" title="""_tWeight_""" style=""background-color: #9cfa7d; border-left:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxPosBarWidth-(tWidth\1)+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td>"
		        } else {
			        set tWidth = tMaxNegBarWidth * tWeight / $zabs(tMin)
			        set tWeight = "<td width="""_(tMaxNegBarWidth-$zabs(tWidth\1)+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_($zabs(tWidth\1)+tMinBarWidth)_""" title="""_tWeight_""" style=""background-color: #eea17d; border-right:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxPosBarWidth+tMinBarWidth)_""" ><img src=""images/spacer.gif"" border=""0"" /></td>"
		        }
	        } else {
		        set tWidth = (tMaxBarWidth * tWeight / (tMaxWeight-tMinWeight)) \ 1
		        set tWeight = "<td width="""_($zabs(tWidth)+tMinBarWidth)_""" title="""_tWeight_""" style=""background-color: "_$s(tWidth>0:"#9cfa7d;", 1:"#eea17d;")_"; border-left:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxBarWidth-tWidth+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td>"
	        }
	        set tWeight = "<table height=""15""><tr>"_tWeight_"</tr></table>"
	        
			&html<<tr><td>#($li(tCats(i),1))#</td><td>#(tWeight)#</td></tr>>
		}
		quit:$$$ISERR(tSC)
		
		&html<<table>>
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawCategorizedTrace(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		#dim tClassifier As %iKnow.Classification.Classifier
		set tClassifier = $classmethod(..GetClassifierClass(),"%New")
		
		set tCategoryIdx = +pSeed
		
		set tSC = ..GetDetailInput(.tText, .tConfig, .tDomainId, .tSrcId)
		quit:$$$ISERR(tSC)
		
		if (tSrcId) {
			set tDomainName = $system.iKnow.GetDomainName(tDomainId)
			set tSC = tClassifier.%Categorize(.tCats, tSrcId, "iKnow", tDomainName)
			quit:$$$ISERR(tSC)
		} else {
			quit:tText=""
			set tSC = tClassifier.%CategorizeText(.tCats, tText, tConfig)
			quit:$$$ISERR(tSC)
		}
		
		set tWeightType = tClassifier.%GetTraceWeightType()
		if (tWeightType = "none") {
			write "No trace information available for this classifier"
			quit
		}
		
		set tSC = tClassifier.%GetTraceInfo(.tTrace, tCategoryIdx)
		quit:$$$ISERR(tSC)
		set tSC = tClassifier.%GetTerms(.tTerms)
		quit:$$$ISERR(tSC)
		
        set tMaxWeight = "", tMinWeight = ""
        set tHasPos = 0, tHasNeg = 0
        set i = ""
        for {
	        set i = $order(tTrace(i), 1, tWeight)
	        quit:i=""
	        
	        if (tWeightType = "probability") {
		        set tWeight = tWeight-0.5
	        } else {
		        continue:'tWeight
	        }
	        
	        continue:'tWeight
	        if (tWeight > 0) {
		        set tHasPos = 1
	        } else {
		        set tHasNeg = 1
	        }
	        set tWeights(tWeight) = ""
	        set tWeight = $zabs(tWeight)
	        set:(tMaxWeight="")||(tMaxWeight<tWeight) tMaxWeight = tWeight
	        set:(tMaxWeight="")||(tMaxWeight<tWeight) tMaxWeight = tWeight
        }
    	
        set tMaxBarWidth = 150, tMinBarWidth = 5
        if tHasPos && tHasNeg {
	        set tMax = $o(tWeights(""),-1), tMin = $o(tWeights(""))
	        set tMaxPosBarWidth = (tMaxBarWidth * tMax / (tMax + $zabs(tMin))) \ 1
	        set tMaxNegBarWidth = (tMaxBarWidth * $zabs(tMin) / (tMax + $zabs(tMin))) \ 1
        }
	
		&html<<table cellspacing="0" cellpadding="0" width="100%">>
		&html<<tr><th width="200">Term</th><th>Relative weight (#(tWeightType)#)</th></tr>>
		
		set i = ""
		for {
			set i = $order(tTrace(i), 1, tRealWeight)
			quit:i=""
			
	        if (tWeightType = "probability") {
		        set tWeight = tRealWeight-0.5
	        } else {
		        set tWeight = tRealWeight
				continue:'tWeight
	        }
			
	        if (tHasPos && tHasNeg) {
		        if tWeight>0 {
			        set tWidth = tMaxPosBarWidth * tWeight / tMax
			        set tWeight = "<td width="""_(tMaxNegBarWidth+tMinBarWidth+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_((tWidth+tMinBarWidth)\1)_""" title="""_tRealWeight_""" style=""background-color: #9cfa7d; border-left:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxPosBarWidth-(tWidth\1)+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td>"
		        } else {
			        set tWidth = tMaxNegBarWidth * tWeight / $zabs(tMin)
			        set tWeight = "<td width="""_(tMaxNegBarWidth-$zabs(tWidth\1)+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_($zabs(tWidth\1)+tMinBarWidth)_""" title="""_tRealWeight_""" style=""background-color: #eea17d; border-right:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxPosBarWidth+tMinBarWidth)_""" ><img src=""images/spacer.gif"" border=""0"" /></td>"
		        }
	        } else {
		        set tWidth = (tMaxBarWidth * tWeight / (tMaxWeight-tMinWeight)) \ 1
		        set tWeight = "<td width="""_($zabs(tWidth)+tMinBarWidth)_""" title="""_tRealWeight_""" style=""background-color: "_$s(tWidth>0:"#9cfa7d;", 1:"#eea17d;")_"; border-left:1px solid #333333;""><img src=""images/spacer.gif"" border=""0"" /></td><td width="""_(tMaxBarWidth-tWidth+1)_"""><img src=""images/spacer.gif"" border=""0"" /></td>"
	        }
	        set tWeight = "<table height=""15""><tr>"_tWeight_"</tr></table>"
	        
			&html<<tr><td>#($li(tTerms(i),5))#</td><td>#(tWeight)#</td></tr>>
		}
		quit:$$$ISERR(tSC)
		
		&html<<table>>
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
