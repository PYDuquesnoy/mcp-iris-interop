/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This is a sample User Interface built on top of the iKnow query APIs, displaying the results 
/// of the iKnow Smart Matching API by highlighting matched entities (bold, colored), CRCs (italic) 
/// and paths (underlined). Select a source from the dropdown list to see all matched elements in 
/// the box below. Clicking any highlighted entity will bring up a detail overview of the 
/// matched elements.</p>
Class %iKnow.UI.MatchingResults Extends %iKnow.UI.AbstractSourceViewer [ Deprecated, System = 4 ]
{

Parameter PAGENAME = "iKnow Matching Results";

Property dictionaries As %ZEN.Datatype.string(ZENURL = "DICTIONARIES");

Property targets As %ZEN.Datatype.string(ZENURL = "TARGETS");

XData Style
{
<style type="text/css">
body {
	font-family: Verdana, Arial;
	font-size: 12px;
	padding: 20px;
}

a {
	color: #a00000;
}

.resultBox {
	border: 1px solid black;
	width: 100%;
	padding: 15px;
}

.match,.matchF {
	background-color: #ff9966;
	border: solid #ff9966 2px;
	padding-left: 2px;
	padding-right: 2px;
}
.matchP {
	border: solid #ff9966 2px;
	background-color: transparent;
	padding-left: 2px;
	padding-right: 2px;
}

table.colorpicker {
}
table.colorpicker td {
	border: 1px solid black;
	width: 13px;
	height: 13px;
	text-align: center;
	vertical-align: middle;
	padding: 1px;
	font-size: 10px;
}

</style>
}

Property virtualSource As %Integer [ Internal ];

Method virtualSourceGet() As %Integer [ Internal, ServerOnly = 1 ]
{
	quit $s(..source<0:$zabs(..source), 1:0)
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="iKnow - Matching Results" width="100%" height="100%">
<modalGroup id="matchDetailsBox" groupTitle="Match details">
<vgroup enclosingStyle="background-color: #eeeeee; padding: 10px;" >
<html id="matchInfo" OnDrawContent="DrawInfo" />
<tablePane id="matchDetailsTable" autoExecute="false" showRowSelector="false"
queryClass="%iKnow.Matching.MatchingQAPI" queryName="GetMatchElements" 
OnExecuteResultSet="ExecuteQuerySys" rowSelect="false" >
<parameter value="#(%page.domain)#" />
<parameter value="#(%session.dmo)#" />
<parameter value="#(%page.virtualSource)#" />
<column colName="position" />
<column colName="entOccId" hidden="true" />
<column colName="entUniId" hidden="true" />
<column colName="literal" OnDrawCell="DrawElementLiteral" />
<column colName="role" OnDrawCell="DrawElementRole" style="text-align:left;" />
<column colName="matchScore" style="text-align:left;" header="match score" />
<column colName="dictElementId" hidden="true" />
<column colName="dictElement" header="matched element" />
<column colName="isScattered" hidden="true" />
<column colName="matchedWordBits" hidden="true" />
<column colName="formatOutput" header="format output" />
</tablePane>
<hgroup align="right">
<button id="prevMatchButton" caption="&lt;&lt;" onclick="zenPage.prevMatch();" disabled="true" title="previous match for this entity" />
<spacer width="5" />
<button id="nextMatchButton" caption="&gt;&gt;" onclick="zenPage.nextMatch();" title="previous match for this entity" />
<spacer width="20" />
<button caption="close" onclick="zenPage.endModal();" />
</hgroup>
</vgroup>
</modalGroup>

<modalGroup id="dictionaryListBox" onshowGroup="zenPage.onShowDictBox();" groupTitle="Dictionaries to highlight">
<vgroup enclosingStyle="padding:5px; background-color: #eeeeee;">
<tablePane id="tblDictionaries" multiSelect="true" showRowSelector="false"
 valueColumn="dictId" onmultiselect="zenPage.updateHighlights();"
 queryClass="%iKnow.Matching.DictionaryQAPI" queryName="GetDictionaries">
<parameter value="#(%page.domain)#" />
<parameter value="0" />
<parameter value="0" />
<parameter value="0" />
<column colName="dictId" hidden="true" />
<column colName="name" OnDrawCell="DrawDictName" />
<column colName="description" hidden="true" />
<column colName="defaultLanguage" hidden="true" />
<column OnDrawCell="DrawColorPicker" seed="0" />
</tablePane>
<label label="Dictionaries with an * are available across domains" hidden="true" id="lblXDomain" />
<spacer height="10" />
<titleBox title="Targets" />
<multiSelectSet id="chkTargets" layout="vertical" onchange="zenPage.updateHighlights();"
	valueList="entities,CRCs,paths,sentences" value="entities,CRCs,paths,sentences" />
<spacer height="10" />
<button caption="close" onclick="zenPage.endModal();" />
</vgroup>
</modalGroup>

<vgroup height="100%" width="100%">
<pane paneName="logoPane" />
<hgroup width="100%">
<pane paneName="optSourcePane" />
<spacer width="10" />
<pane paneName="btnInputPane" />
<spacer width="10" />
<button caption="dictionaries" onclick="zen('dictionaryListBox').show();" />
<spacer width="40%" />
<pane paneName="optDomainPane" />
</hgroup>
<pane paneName="infoPane" />
<spacer height="20" />
<titleBox title="Matching results" />
<spacer height="10" />
<html id="matchingResults" enclosingClass="resultBox" OnDrawContent="DrawResult" />
<spacer height="20" />
</vgroup>
</page>
}

Method OnUpdateDomain(domainId As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		kill %session.Data("dmo"), %session.Data("entoccid"), %session.Data("dmolist"), %session.Data("dictColors")
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method MakeEntityLink(entity As %String) As %String
{
	quit "<a href=""_iKnow.UI.KnowledgePortal.cls?domain=" _ ..domain _ "&term=" _ entity _ """>"_entity_"</a>"
}

Method OnUpdateSource(sourceId As %Integer) As %Status
{
	kill %session.Data("dmo"), %session.Data("entoccid"), %session.Data("dmolist")
	quit $$$OK
}

Method UpdateDMO(dmoId As %Integer) As %Status [ ZenMethod ]
{
	set %session.Data("dmo") = dmoId
	quit $$$OK
}

Method UpdateEntOccId(entOccId As %Integer) As %Status [ ZenMethod ]
{
	set %session.Data("entoccid") = entOccId
	kill %session.Data("dmo"), %session.Data("dmolist")
	
	set vSrcId = $s(..source<0:$zabs(..source), 1:0)
	set domainId = ..GetSourceDomainId()
	set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchesByEntOcc(.result, domainId, entOccId,,,, 1, 1, 1, vSrcId)
	set i = "", dmoList = ""
	for {
		set i = $order(result(i),1,d)
		quit:i=""
		set dmoList = dmoList _ $li(d,1,1)
	}
	
	set %session.Data("dmolist") = $lts(dmoList)
		
	quit $$$OK
}

ClientMethod onUpdateSourceClient() [ Language = javascript ]
{
	zen("matchingResults").refreshContents();
}

Method DrawResult(seed As %ZEN.Datatype.string) As %Status
{
	set tSC = $$$OK
	try {
		set tDomainId = ..GetSourceDomainId()
		
		if ('..source) {
			write $$$Text("no source selected")
			quit
		}
		
		// first write class info
		write !,"<style type=""text/css"" >"
		kill dictStyles
		set dictId=""
		for {
			set dictId = $order(%session.Data("dictColors",dictId),1,color)
			quit:dictId=""
			write !,".dict",dictId," { background-color: #",color,"; border-color: #",color,"; }"
			set dictStyles(dictId) = "dict"_dictId
		}
		// extra override for partial match background
		write !,".matchP { background-color: white }"
		write !,"</style>"
		
		
		if (..source>0) {
			write "<h1>"_##class(%iKnow.Queries.SourceAPI).GetExternalId(..domain, ..source) _ "</h1>"
		} else {
			write "<h1>"_$$$Text("User input")_"</h1>"
		}
		
		write "<p>"
		
		set filter = ##class(%iKnow.Matching.MatchFilter).%New()
		set tDictCount = $length(..dictionaries,","), tXDictIds=""
		for i=1:1:tDictCount {
			set tDictId = $piece(..dictionaries,",",i)
			continue:'tDictId
			set filter.AllowedDictionaries(tDictId) = ""
			set:tDictId<0 tXDictIds = tXDictIds_$lb(tDictId)
		}
		set:$find(..targets,"entities") filter.AllowedTargetTypes($$$DMTARGETENTITY) = ""
		set:$find(..targets,"CRCs") filter.AllowedTargetTypes($$$DMTARGETCRC) = ""
		set:$find(..targets,"paths") filter.AllowedTargetTypes($$$DMTARGETPATH) = ""
		set:$find(..targets,"sentences") filter.AllowedTargetTypes($$$DMTARGETSENT) = ""
		
		// if there are X-domain dictionaries, we have to ensure they are matched explicitly
		set:tXDictIds'="" tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(tDomainId, ..source, tXDictIds)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Matching.MatchingAPI).GetHighlightedSentences(.result, tDomainId, ..source, 0, 0, filter,, "zenPage.clickEntOccClient",, .dictStyles)
		quit:$$$ISERR(tSC)
		set n = ""
		for {
			set n = $order(result(n), 1, sentence)
			quit:n=""
			
			write sentence _ " "
		}
		
		write "</p>"
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetNextMatchForEO(forward As %String) As %Integer [ ZenMethod ]
{
	set domainId = ..GetSourceDomainId()
	set entOccId = %session.Data("entoccid")
	set dmoId = +$g(%session.Data("dmo"))
	set dmoList = $g(%session.Data("dmolist"))
	quit:dmoList="" -1
	set dmoList = $lfs(dmoList)
	
	set prevPos = $listfind(dmoList, dmoId)
	set length = $listlength(dmoList)
	
	if (+forward) {
		set nextPos = prevPos+1
	} else {
		set nextPos = prevPos-1
	}
	
	set:nextPos<1 nextPos = 1
	set:nextPos>length nextPos = length
		
	set ..%GetComponentById("nextMatchButton").disabled = $s(length=nextPos:"true", 1:"false")
	set ..%GetComponentById("prevMatchButton").disabled = $s(nextPos=1:"true", 1:"false")
	
	quit $lg(dmoList, nextPos)
}

ClientMethod prevMatch() [ Language = javascript ]
{
	var dmo = zenPage.GetNextMatchForEO(0)
	if (dmo<0) return;
	var sc = zenPage.displayMatchClient(dmo);
	zen("prevMatchButton").refreshContents();
	zen("nextMatchButton").refreshContents();
}

ClientMethod nextMatch() [ Language = javascript ]
{
	var dmo = zenPage.GetNextMatchForEO(1)
	if (dmo<0) return;
	var sc = zenPage.displayMatchClient(dmo);
	zen("prevMatchButton").refreshContents();
	zen("nextMatchButton").refreshContents();
}

ClientMethod clickEntOccClient(entOccId) [ Language = javascript ]
{
	var sc = zenPage.UpdateEntOccId(entOccId);
	zenPage.nextMatch();
}

ClientMethod displayMatchClient(dmo) [ Language = javascript ]
{
	var sc = zenPage.UpdateDMO(dmo);
	zen("matchDetailsBox").show();
	zen("matchDetailsTable").refreshContents();
	zen("matchInfo").refreshContents();
	
	return 1
}

Method DrawInfo(seed As %ZEN.Datatype.string) As %Status
{
	quit:'..domain $$$OK
	set dmoId = +$g(%session.Data("dmo"))
	quit:'dmoId $$$OK
	
	write "<p>"
	
	if (..virtualSource) {
		set dmo = ##class(%iKnow.Objects.VirtualDictionaryMatch).PKINDEXOpen(..GetSourceDomainId(), ..virtualSource, dmoId)
	} else {
		set dmo = ##class(%iKnow.Objects.DictionaryMatch).PKINDEXOpen(..domain, dmoId)
	}
	
	write $$$Text("Dictionary")_": <span title=""" _ dmo.Dictionary.Description _ """>" _ dmo.Dictionary.Name _ "</span><br/>"
	write $$$Text("Matched item")_": " _ dmo.DictionaryItem.Name _ " [" _ dmo.DictionaryItem.URI _ "]<br/>"
	write $$$Text("Matched term")_": " _ dmo.DictionaryTerm.String _ "<br/>"
	
	write "</p><p>"
	
	write $$$Text("Match score")_": " _ dmo.MatchScore _ "</br>"
	write $$$Text("Matched elements")_": " _ (dmo.MatchedEntityCount-dmo.PartialMatchCount)
	write " " _ $$$Text("full") _ " " _$$$Text("and")_ " " _ dmo.PartialMatchCount _ " " _ $$$Text("partial")_"</br>"
	write $$$Text("Matched roles")_": " _ dmo.MatchedConceptCount _ " " _ $$$Text("concept(s)") 
	write " "_$$$Text("and")_" " _ dmo.MatchedRelationCount _ " " _ $$$Text("relation(s)") _ "</br>"
	
	write "</p>"
	
	quit $$$OK
}

Method DrawElementRole(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set role = %query(pName)
	write $case(role, $$$ENTTYPECONCEPT:$$$Text("concept"), $$$ENTTYPERELATION:$$$Text("relation"), $$$ENTTYPENONREL:$$$Text("non-relevant"), $$$ENTTYPEPATHREL:$$$Text("path-relevant"), :$$$Text("other"))
	quit $$$OK
}

Method DrawElementLiteral(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set ms = +%query("matchScore")
	write $s(ms=1:"<b>", 1:"") _ %query(pName) _ $s(ms=1:"</b>", 1:"")
	quit $$$OK
}

ClientMethod onProcessInputClient() [ Language = javascript ]
{
	var sc = zenPage.MatchVirtualSource();
	zen('matchingResults').refreshContents();
}

Method MatchVirtualSource() As %Status [ ZenMethod ]
{
	quit ##class(%iKnow.Matching.MatchingAPI).MatchSource(..GetSourceDomainId(), ..source)
}

Method GetInfoPaneText() As %String
{
	quit "<p>This is a sample User Interface built on top of the iKnow query APIs, displaying the results "_
			"of the iKnow Smart Matching API by highlighting matched entities (bold, colored), CRCs (italic) "_
			"and paths (underlined). Select a source from the dropdown list to see all matched elements in " _
			"the box below. Clicking any highlighted entity will bring up a detail overview of the " _
			"matched elements.</p>"
}

ClientMethod updateHighlights() [ Language = javascript ]
{
	var dicts = zen('tblDictionaries').getProperty('selectedRows');
	var targets = zen('chkTargets').getValue();
	if ((targets == null) || (targets == '')) { targets=''; alert($$$Text('Please select at least 1 target type')); }
	if ((dicts == null) || (dicts == '')) { dicts=''; alert($$$Text('Please select at least 1 dictionary')); }
	var sc = zenPage.SetHighlights(dicts, targets);
	zen('matchingResults').refreshContents();
	return true;
}

Method SetHighlights(pDictionaries, pTargets) As %Status [ ZenMethod ]
{
	set ..dictionaries = $zstrip(pDictionaries,"*W")
	set ..targets = pTargets
	quit $$$OK
}

Method DrawDictName(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	write %query("name")
	write:%query("dictId")<0 " *"
	quit $$$OK
}

Method DrawColorPicker(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set tDictId = %query("dictId")
	write !,"<table cellspacing=""2"" class=""colorpicker""><tr>"
	//write !,"<td style=""background-color: white;"
	//write:'$d(%session.Data("dictColors",tDictId)) "border: solid red 2px;"
	//write """ onclick=""zenPage.selectColorClient(",tDictId,",'none');"" >x</td>"
	for col="ffffff","ffff66","ff9966","ff99ff","9999ff","99ffff","99ff99" {
		write !,"<td style=""background-color: #",col,";"
		write:$g(%session.Data("dictColors",tDictId))=col "border: solid red 2px;"
		write """ onclick=""zenPage.selectColorClient(",tDictId,",'",col,"');"" >&nbsp;</td>"
	}
	write !,"</tr></table>"
	quit $$$OK
}

ClientMethod selectColorClient(pDictId, pColor) [ Language = javascript ]
{
	var sc = zenPage.SelectColor(pDictId, pColor);
	zen('tblDictionaries').refreshContents();
	zenPage.updateHighlights();
}

Method SelectColor(pDictId As %Integer, pColor As %String) As %Status [ ZenMethod ]
{
	if (pColor="none") {
		kill %session.Data("dictColors",pDictId)
	} else {
		set %session.Data("dictColors",pDictId) = pColor
	}
	quit $$$OK
}

ClientMethod onShowDictBox() [ Language = javascript ]
{
	var dicts = zenPage.getProperty('dictionaries');
	var sc = zen('tblDictionaries').setProperty('selectedRows', dicts);
	zen('tblDictionaries').refreshContents();
}

Method OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		
		if ##class(%iKnow.Matching.DictionaryAPI).HasDictionaries(0) {
			set ..%GetComponentById("lblXDomain").hidden = 0
			set ..%GetComponentById("tblDictionaries").parameters.GetAt(4).value = 1
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
