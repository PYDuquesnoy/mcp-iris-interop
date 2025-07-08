/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %DeepSee)

Class %iKnow.DeepSee.UI.MeasureValue Extends %DeepSee.UI.Dialog.standardDialog [ Deprecated, System = 4 ]
{

Parameter APPLYBUTTON = 0;

Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Measure to use for analysis.
Property measureName As %ZEN.Datatype.string(ZENURL = "MEASURE");

/// Summary length
Property summaryLength As %ZEN.Datatype.string(ZENURL = "LENGTH");

/// Object ID of the source object instance to display
Property objectIds As %ZEN.Datatype.string(ZENURL = "OBJIDS");

Property highlight As %ZEN.Datatype.string(ZENURL = "HIGHLIGHT") [ InitialExpression = "nothing" ];

Property dictionaries As %ZEN.Datatype.string(ZENURL = "DICTIONARIES");

Property dominants As %ZEN.Datatype.string(ZENURL = "DOMINANTS") [ InitialExpression = {$$$SDCONCEPT_","_$$$SDCRC_","_$$$SDPATH} ];

Property entities As %ZEN.Datatype.string(ZENURL = "ENTITIES");

Property domain As %Integer [ Internal, Private ];

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
cellStyle="padding-bottom:8px;">
<vgroup cellVAlign="top">
<tabGroup showTabBar="true" id="tabGroup" />
<spacer height="20" />
<hgroup labelPosition="left" cellVAlign="top">
<text id="txtLength" value="all" hint="number of sentences to display" label="Summary length: " />
<spacer width="20" />
<button caption="summarize" onclick="zenPage.summarize();" />
</hgroup>
<spacer height="10" />
<hgroup labelPosition="left" cellVAlign="top">
<multiSelectSet id="chkHighlight" label="Highlight" value="negation,sentiment,attributes,dictionary terms" layout="vertical"
	valueList="negation,sentiment,attributes,dictionary terms,dominant terms" onchange="zenPage.setHighlights();"
	 displayList="negation,sentiment,other attributes,dictionary terms,dominant terms" />
<spacer width="20" />
<multiSelectSet id="chkDictionaries" label="Dictionaries" disabled="true" layout="vertical"
	onchange="zenPage.setHighlights();" />
<spacer width="20" />
<multiSelectSet id="chkDominants" label="Dominant" disabled="true" layout="vertical"
	onchange="zenPage.setHighlights();" />
</hgroup>
</vgroup>
</pane>
}

ClientMethod setHighlights() [ Language = javascript ]
{
	var what = zen('chkHighlight').getValue();
	var sc = zenPage.SetHighlighting(what, zen('chkDictionaries').getValue(), zen('chkDominants').getValue());
	zen('chkDictionaries').setDisabled((what.indexOf("dictionary terms")<0));
	zen('chkDominants').setDisabled((what.indexOf("dominant terms")<0));
	zen('tabGroup').refreshContents();
}

Method SetHighlighting(pHighlight, pDictIds, pDominants) As %Status [ ZenMethod ]
{
	set ..highlight = pHighlight
	set ..dictionaries = pDictIds
	set ..dominants = pDominants
	quit $$$OK
}

ClientMethod summarize() [ Language = javascript ]
{
	var sc = zenPage.SetSummaryLength(zen('txtLength').getValue());
	zen('tabGroup').refreshContents();
}

Method SetSummaryLength(length) As %Status [ ZenMethod ]
{
	set ..summaryLength = +length
	quit $$$OK
}

Method DrawContent(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(..cubeName, ..measureName,, .tDomainId,, .tDomainType)
		quit:$$$ISERR(tSC)
		
		set ..domain = tDomainId // DP-407811
		
		set tFactId = ##class(%iKnow.DeepSee.CubeUtils).GetFactId(..cubeName, pSeed)
		set tBaseCube = $$$DeepSeeIndex(..cubeName)
		set tSrcId = $s(tDomainType="DeepSee":tFactId, 1:$g($$$DeepSeeIndexGLVN(tBaseCube,"%ikSrcIdReverse",$$$UPPER(..measureName),tFactId)))
		
		// BDB333: first check if the source exists (non-empty iKnow measure value)
		set srcObj = ##class(%iKnow.Objects.Source).PKINDEXOpen(tDomainId, tSrcId)
		if (srcObj="") {
			write "<p>"_$$$Text("No content for iKnow Measure")_"</p>"
			quit
		}
		
		// DP-407811 - get fancy highlighting spec
		do ##class(%iKnow.UI.Styles).GetDefaultHighlightSpecStatic(.tHighlight, "light", $s(..entities'="":$lfs(..entities),1:""))
		do ##class(%iKnow.UI.Styles).WriteStyle()
		
		// negation highlighting
		if '$find(..highlight,"negation") {
			kill tHighlight("ATTRIBUTE", $$$IKATTNEGATION), 
				 tHighlight("ATTRIBUTEWORDS", $$$IKATTNEGATION)
		}
		
		// BDB536: sentiment highlighting
		if '$find(..highlight,"sentiment") {
			kill tHighlight("ATTRIBUTEWORDS", $$$IKATTSENPOSITIVE),
				 tHighlight("ATTRIBUTEWORDS", $$$IKATTSENNEGATIVE),
				 tHighlight("ATTRIBUTE", $$$IKATTSENPOSITIVE),
				 tHighlight("ATTRIBUTE", $$$IKATTSENNEGATIVE)
		}
		
		// DP-407811 - other attributes
		if '$find(..highlight,"attributes") {
			for l = "ATTRIBUTES", "ATTRIBUTEWORDS" {
				set t = ""
				for {
					set t = $order(tHighlight(l,t))
					quit:t=""
					continue:t=$$$IKATTNEGATION
					continue:t=$$$IKATTSENPOSITIVE
					continue:t=$$$IKATTSENNEGATIVE
					kill tHighlight(l,t)
				}
			}
		}
		
		// dictionary highlighting
		if $find(..highlight,"dictionary terms") && (..dictionaries'="") {
			set tDictCount = $length(..dictionaries, ",")
			for i = 1:1:tDictCount { 
				set tHighlight("MATCH", +$p(..dictionaries,",",i)) = "<span class=""ikDict"" title=""$$$DICT >> $$$ITEM"">"
				set tHighlight("MATCH", +$p(..dictionaries,",",i), "PARTIAL") = "<span class=""ikDictPartial"" title=""$$$DICT >> $$$ITEM"">"
			}
		}
		
		// dominant terms highlighting
		if $find(..highlight, "dominant terms") && (..dominants'="") {
			set tPercent = 0.10, tDomCount = $length(..dominants,",")
			for i = 1:1:tDomCount {
				set tType = $piece(..dominants,",",i)
				continue:tType=""
				if (tType=$$$SDCONCEPT) {
					set tCount = ##class(%iKnow.Queries.EntityAPI).GetCountBySource(tDomainId, tSrcId,,,, $$$ENTTYPECONCEPT)
				} elseif (tType=$$$SDRELATION) {
					set tCount = ##class(%iKnow.Queries.EntityAPI).GetCountBySource(tDomainId, tSrcId,,,, $$$ENTTYPERELATION)
				} elseif (tType=$$$SDCRC) {
					set tCount = ##class(%iKnow.Queries.CrcAPI).GetCountBySource(tDomainId, tSrcId)
				} else {
					set tCount = ##class(%iKnow.Queries.PathAPI).GetCountBySource(tDomainId, tSrcId)
				}
				set tPageSize = tCount * tPercent
				set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetProfileBySource(.tProfile, tDomainId, tSrcId, 1, tPageSize, tType)
				quit:$$$ISERR(tSC)
				
				set j = ""
				set tHType = $case(tType, $$$SDCRC:"CRC", $$$SDPATH:"PATH", :"ENTITY") 
				set tHTag = $case(tType, $$$SDPATH:"<span class=""ikDomPath"">", $$$SDCRC:"<font class=""ikDomCrc"">", :"<b class=""ikDomEnt"">")
				for {
					set j = $order(tProfile(j), 1, tData)
					quit:j=""
					set tHighlight(tHType,$li(tData,1)) = tHTag
				}
			}
		}
		
		set srcObj = ##class(%iKnow.Objects.Source).PKINDEXOpen(tDomainId, tSrcId)
		set sentBase = srcObj.FirstSentenceId-1
			
		if (..summaryLength>0) {
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.res, tDomainId, tSrcId, ..summaryLength)
			quit:$$$ISERR(tSC)
		} else {
			kill res
			for i=1:1:srcObj.SentenceCount { set res(i) = $lb(sentBase+i) }
		}
		
		set i = "", prevPos=0
		for {
			set i = $o(res(i),1,d)
			quit:i=""
			
			set tSentId = $li(d,1), sentPos = tSentId-sentBase
			w:(sentPos>(prevPos+1)) " ... "
			
			set tSentValue = ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(tDomainId, tSentId, .tHighlight,,, .tSC)
			
			w !,"<p>",tSentValue,"</p>"
			quit:$$$ISERR(tSC)
			
			set prevPos = sentPos
		}
		w:(prevPos=(sentBase+srcObj.SentenceCount)) " ..."
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("iKnow measure value")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Display the full measure value for a single fact.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
	}
	catch(ex) {
	}
	return true;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in ondialogFinish');
	}
	return true;
}

Method %OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		// BDB420: use first iKnow measure for this cube if none specified
		if (..measureName="") {
			set tSC = ##class(%iKnow.DeepSee.CubeUtils).GetIKnowMeasures(..cubeName, .tMeasures)
			quit:$$$ISERR(tSC)
			set ..measureName = $lg($g(tMeasures(1)),1)
		}
		
		set tTabs = ..%GetComponentById("tabGroup")
		
		set tCount = $length(..objectIds,",")
		for i=1:1:tCount {
			set tID = $piece(..objectIds,",",i)
			continue:tID=""
			
			set tTab = ##class(%ZEN.Component.tab).%New()
			set tTab.caption = "Record #"_i  // or other useful identifier?
			set tTab.id = "tab"_$zconvert(tID,"O","HTML")
			
			set tHTML = ##class(%ZEN.Component.html).%New()
			do tTab.%AddChild(tHTML)
			set tHTML.seed = tID
			set tHTML.OnDrawContent = "DrawContent"
			set tHTML.containerStyle = "padding:5px;"
			
			do tTabs.%AddChild(tTab)
		}
		
		
		// populate chkDictionaries
		set tChkDicts = ..%GetComponentById("chkDictionaries")
		do ##class(%iKnow.DeepSee.CubeUtils).GetMeasureInfo(..cubeName, ..measureName,,.tDomainId,,.tDomainType,,.tDictionaries)
		set tHasXDict = $$$IKVERSIONATLEAST(tDomainId,$$$IKVERSIONXDOMAIN) && ##class(%iKnow.Matching.DictionaryAPI).HasDictionaries(0)
		set tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaries(.tDicts, tDomainId, 0, 0, tHasXDict)
		set i="", tValueList="", tDisplayList="", tDictionaries = $lfs(tDictionaries)
		for {
			set i = $order(tDicts(i),1,tData)
			quit:i=""
			set tDictionaryName = $li(tData,2), tDictionaryId = $li(tData,1)
			set tTermListName = $s(tDictionaryId<0:##class(%iKnow.DeepSee.Dimensions.Dictionaries).GetTermListName(tDictionaryName), 1:tDictionaryName)
			if (tDomainType="DeepSee") {
				continue:'$lf(tDictionaries,tTermListName)
			} else {
				// for iKnow-managed domains, only include cross-domain dictionaries if they
				// have any matches
				continue:'##class(%iKnow.Filters.DictionaryMatchFilter).%New(tDomainId,$lb(tDictionaryId),1).FilteredSourceCount
			}
			set tValueList = tValueList _ "," _ $li(tData,1)
			set tDisplayList = tDisplayList _ "," _ tTermListName
		}
		set tChkDicts.valueList = $e(tValueList,2,*)
		set tChkDicts.displayList = $e(tDisplayList,2,*)
		
		set tChkDoms = ..%GetComponentById("chkDominants")
		set tChkDoms.valueList = $$$SDCONCEPT_","_$$$SDRELATION_","_$$$SDCRC_","_$$$SDPATH
		set tChkDoms.displayList = $$$Text("concepts")_","_$$$Text("relations")_","_$$$Text("CRCs")_","_$$$Text("paths")
		
		// set default values
		do ..%SetValueById("chkHighlight", $$$Text("nothing"))
		do ..%SetValueById("chkDictionaries", $e(tValueList,2,*))
		do ..%SetValueById("chkDominants", $$$SDCONCEPT_","_$$$SDCRC_","_$$$SDPATH)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	Quit tSC
}

XData Style
{
<style type="text/css">
.ikDomPath {
	text-decoration: underline;
}

.ikDomCrc {
	font-style: italic;
}

.ikDomEnt {
	font-weight: bold;
}

.ikDict {
	background-color: LightSkyBlue;
	border: solid LightSkyBlue 2px;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
}
.ikDictPartial {
	border: solid LightSkyBlue 2px;
	background-color: transparent;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
}

</style>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	sc = zen('chkHighlight').setValue('negation,dictionary terms');
	zenPage.setHighlights();
}

}
