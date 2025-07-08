/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

Class %iKnow.UI.KnowledgePortal Extends Styles [ Deprecated, System = 4 ]
{

Parameter AUTONS = 1;

Parameter DOMAIN = "%iKnow";

Parameter RESOURCE = "%Development";

Parameter JSINCLUDES = "jquery-3.5.1.min.js,bootstrap-4-4-1/dist/js/bootstrap.bundle.min.js";

Parameter CSSINCLUDES = "bootstrap-4-4-1/dist/css/bootstrap.min.css";

Property domain As %ZEN.Datatype.integer(ZENURL = "domain");

Property term As %ZEN.Datatype.string(ZENURL = "term");

Property source As %ZEN.Datatype.integer(ZENURL = "source");

Property summaryPct As %ZEN.Datatype.integer [ InitialExpression = 100 ];

Property filter As %ZEN.Datatype.string(ZENURL = "filter");

Property filtermode As %ZEN.Datatype.integer(ZENURL = "filtermode") [ InitialExpression = {$$$FILTERALLANDSORT} ];

Property skiplists As %ZEN.Datatype.string(ZENURL = "skiplists");

Property languageMode As %ZEN.Datatype.string(VALUELIST = ",en,ja", ZENURL = "langmode") [ InitialExpression = "en" ];

Property pageSize As %ZEN.Datatype.integer(ZENURL = "pagesize") [ InitialExpression = 10 ];

Property drill As %ZEN.Datatype.string;

Property includeOtherNamespaces As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property enableAutocomplete As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property useStemming As %ZEN.Datatype.boolean;

Property useRepresentationForm As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Interpret path data as Entity Vectors
Property useEntityVectors As %ZEN.Datatype.boolean(ZENURL = "useEntityVectors") [ Internal ];

XData Style
{
<style type="text/css">

body {
    font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
    font-size: 14px;
}
a {
    color: #337ab7;
}
label {
  font-weight: 700
}
h4 {
	font-size: 1.2rem;
}

.panel {
    margin-bottom: 20px;
    border: 1px solid transparent;
    border-radius: 4px;
	border-color: #337ab7
}
.panel-heading {
    padding: 10px 15px;
	color: #fff;
    background-color: #337ab7;
    border-color: #337ab7;
}
.panel-footer {
    padding: 5px;
	line-height: 1.6;
    background-color: #f5f5f5;
    border-bottom-right-radius: 3px;
    border-bottom-left-radius: 3px;
}
.panel > .table {
  margin-bottom: 0;
}
.panel-body-table > .table {
    margin-bottom: 0px;
}
.panel.with-nav-tabs .panel-heading{
    padding: 5px 5px 0 5px;
}
.panel.with-nav-tabs .nav-tabs{
	border-bottom: none;
}

.modal-header {
	display: block;
}

.btn {
	font-size: 14px;
}
.btn-primary {
    background-color: #337ab7;
    border-color: #2e6da4;
}
.btn-secondary {
    color: #333;
    background-color: #fff;
    border-color: #ccc;
}
.btn-secondary.disabled {
	background-color: #eee;
	border-color: #eee;
}
.btn-success > .icon {
	filter: brightness(0) saturate(100%) invert(87%) sepia(100%) saturate(0%) hue-rotate(172deg) brightness(104%) contrast(105%);
}
.btn-group-sm > .btn {
    padding: 1px 5px;
    font-size: 12px;
}

.icon {
	height: 18px;
}
.icon-filter {
	height: 22px;
}
.icon-skiplist {
	height: 14px;
}
.icon-play {
	height: 16px;
}
.eye {
	padding: 0;
	margin: 0;
}
.remove-filter {
	cursor: pointer;
}

.well {
    padding: 19px;
    margin-bottom: 20px;
    background-color: #f5f5f5;
    border: 1px solid #e3e3e3;
    border-radius: 4px;
}

.pull-right {
    float: right !important;
}

.input-group-append {
    padding: 6px 12px;
    font-size: 18px;
    line-height: 1;
    background-color: #eee;
    border: 1px solid #ccc;
		border-left: 0;
    border-top-right-radius: 4px;
	border-bottom-right-radius: 4px;
}

.input-group-btn {
    z-index: 2;
	border-left: 2px;
	border-left-color #bfcedc;
	border-top-left-radius: 0px;
	border-bottom-left-radius: 0px;
}

.table td {
  padding: 8px;
  border-top: 0;
  border-bottom: 1px solid #dee2e6;
}
.table-condensed > tbody > tr > td {
	padding: 5px;
}

.with-nav-tabs.panel-primary .nav-tabs > li > a {
    position: relative;
    display: block;
    padding: 10px 15px;
	cursor: pointer;
	border-radius: 4px 4px 0 0;

}
.with-nav-tabs.panel-primary .nav-tabs > .open > a,
.with-nav-tabs.panel-primary .nav-tabs > .open > a:hover,
.with-nav-tabs.panel-primary .nav-tabs > .open > a:focus,
.with-nav-tabs.panel-primary .nav-tabs > li > a:hover,
.with-nav-tabs.panel-primary .nav-tabs > li > a:focus {
	background-color: #3071a9;
	border-color: transparent;
}
.with-nav-tabs.panel-primary .nav-tabs > li.active > a,
.with-nav-tabs.panel-primary .nav-tabs > li.active > a:hover,
.with-nav-tabs.panel-primary .nav-tabs > li.active > a:focus {
	color: #428bca;
	background-color: #fff;
}

.form-control {
	font-size: 14px;
}
.form-inline > .form-control {
	margin: .1rem;
}

.sources-badge {
	border: 1px solid #ccc;
	background-color: #eee;
	border-top-left-radius: 4px;
	border-bottom-left-radius: 4px;
	padding: 6px;
}

.sources-badge > .badge {
	color: #555;
	font-size: 16px;
}

.opacity-50 {
	opacity: 0.50;
	filter: ~"alpha(opacity=50)"; //IE
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	 title="Domain Explorer" width="100%" height="100%">
<hgroup width="100%">
<hgroup>
<assistedText id="txtSearch" controlWidth="350px" controlClass="form-control"
controlType="custom"  isSuggestedDataComplete="true" triggerChars="" hideGhost="true" 
	onUpdateDataClient="zenPage.inputTermClient(base)" placeholder="Explore..."
  	onchange="zenPage.explore(zenThis.getValue(), true);return;" 
 	onkeyup="zenPage.onTermKeyUp();return;" />
 </hgroup>
 <spacer width="20" />
 <html id="htmlFilterB" OnDrawContent="DrawButtons" />
 <html id="modalFilter" OnDrawContent="DrawFilterPane" enclosingClass="modal" />
 <html id="modalSkiplist" OnDrawContent="DrawSkiplistsPane" enclosingClass="modal" />
 <html id="modalSettings" OnDrawContent="DrawSettingsPane" enclosingClass="modal" />
</hgroup>
<spacer height="20" />
<hgroup width="100%" cellVAlign="top">
<html id="htmlTop" width="30%" OnDrawContent="DrawTopEntities" />
<spacer width="5" />
<html id="htmlSim" width="30%" OnDrawContent="DrawSimEntities" />
<spacer width="5" />
<html id="htmlRel" width="30%" OnDrawContent="DrawRelEntities" />
</hgroup>
<html id="htmlPaths" width="100%" OnDrawContent="DrawPaths" />

<html id="modalSource" OnDrawContent="DrawSourceModal" enclosingClass="modal" onrefresh="zenPage.fixHighlighting(zen('modalSource').seed);" />
<html id="modalSourceList" OnDrawContent="DrawSourceListModal" enclosingClass="modal" />

<html id="modalInfo" enclosingClass="modal" >
<div class="modal-dialog">
<div class="modal-content">
<div class="modal-header">
About this page
</div>
<div class="modal-body">
<p>This page is a sample interface to navigate a Text Analytics domain. It is meant for demo purposes only and may suffer from panel response timeouts and other GUI glitches when used on very large domains.</p>
<p>Enter a string or click an entity in the list to start navigating to its similar and related entities and show more context. You can filter the results according to source-level criteria using the filter button: <image src="/csp/sys/iknow/img/icon-filters.svg" class="icon icon-filter" style="cursor: auto;" /></p>
<p>To filter the list of entities being retrieved, apply skiplists using the skiplist button: <image src="/csp/sys/iknow/img/icon-skiplist.svg" class="icon icon-skiplist" style="cursor: auto;" /></p>
</div>
<div class="modal-footer">
<button class="btn btn-primary" onclick="zenPage.closeInfo();">OK</button>
</div>
</div>
</div>
</html>

<html id="modalLegend" enclosingClass="modal" OnDrawContent="DrawLegend" />
</page>
}

Method %OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		do ..ResetPages()
		
		set i="t:"
		for {
			set i = $order(%session.Data(i))
			quit:$e(i,2)'="t:"
			set %session.Data(i) = 1
		}
	
		set:'..domain ..%GetComponentById("modalSettings").enclosingClass = "modal",
					..%GetComponentById("modalSettings").enclosingStyle = "display: block;" 
		
		
		// language mode
		if '$d(%request.Data("langmode",1)) {
			set tDefaultConfig = $$$GETPARAM(+..domain,$$$IKPDEFAULTCONFIG,$$$DEFAULTCONFIG)
			set tDefaultConfig = ##class(%iKnow.Configuration).NameIndexOpen(tDefaultConfig)
			if $isobject(tDefaultConfig) && $ls(tDefaultConfig.Languages,$lb("ja")) {
				set ..languageMode = "ja"
			}
		}
		
		// BDB804
		if ..useStemming="" {
			set ..useStemming = ($$$GETPARAM(+..domain,$$$IKPSTEMMING,0)'=0)
		}
		
		// DP-404807 - pick whether to show vectors or paths
		// given the complexity / cost of inferring what to do from the text and catering to the
		// rare combined scenario, we'll allow the user to define this through the URL if they
		// want to override the default, which is to follow the value of $$$IKPUSEENTITYVECTORS
		// when the language mode is Japanese
		set:..useEntityVectors="" ..useEntityVectors = (..languageMode="ja") && $$$GETPARAM(+..domain,$$$IKPUSEENTITYVECTORSJP,$$$IKPDEFUSEENTITYVECTORSJP)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method InputTerm(pBase As %String) As %String [ ZenMethod ]
{
	quit:'..enableAutocomplete ""	
	
	if ..useStemming && ..useRepresentationForm {
		set pBase = ##class(%iKnow.Queries.EntityAPI).GetStem(..domain, pBase)
	}
	
	set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.tResult, ..domain, pBase,,, ..GetFilter(), $$$FILTERONLY,,,,..useStemming)
	quit:$$$ISERR(tSC) ""
	
	set tResultString = "", i="", tBaseLength = $length(pBase)
	for {
		set i = $order(tResult(i),1,tData)
		quit:i=""
		set tResultString = tResultString_","_$li(tData,2)
	}
	quit tResultString
}

ClientMethod inputTermClient(text) [ Language = javascript ]
{
	// quit if input string is too short
	if ((text == null) || (text.length < 2))
		return '';
		
	return zenPage.InputTerm(text);
}

ClientMethod onTermKeyUp() [ Language = javascript ]
{
	if (zenEvent && ((zenEvent.keyCode==13) || (zenEvent.which==13))) {
		zenPage.explore(zen('txtSearch').getValue(), true);
	}
	return true;
}

ClientMethod explore(string, fromField) [ Language = javascript ]
{
	var sc = zenPage.setProperty('term', string);
	var sc = zenPage.ResetPages();
	if (!fromField) { $('#txtSearch').children().first().children().filter('input').first().val(string); }
	zenPage.refreshAll();
}

ClientMethod refreshAll() [ Language = javascript ]
{
	zen('htmlTop').refreshContents();
	zen('htmlSim').refreshContents();
	zen('htmlRel').refreshContents();
	zen('htmlPaths').refreshContents();
	zen('htmlFilterB').refreshContents();
}

Method DrawTopEntities(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		if $g(%session.Data("t:htmlTop"),1)=1 {
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.tResult, ..domain, $g(%session.Data("p:htmlTop"),1), ..pageSize, ..GetFilter(), ..filtermode,,,, ..GetSkiplists(),..useStemming)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetTop(.tResult, ..domain, $g(%session.Data("p:htmlTop"),1), ..pageSize, ..GetFilter(),, $s(..useStemming:$$$SDSTEMCONCEPT,1:$$$SDCONCEPT), ..GetSkiplists())
			quit:$$$ISERR(tSC)
		}
		
		set tDomain = ##class(%iKnow.Domain).%OpenId(..domain)
		if $isobject(tDomain) && (tDomain.GetParameter($$$IKPSORTFIELD)=$$$SORTBYSPREAD) {
			set tSort = "spread"
		} else { 
			set tSort = "frequency"
		}
		
		set tPanes($i(tPanes)) = $lb(tSort, $s(..languageMode="ja":$$$Text("Top Entities"), ..useStemming:$$$Text("Top Stems"), 1:$$$Text("Top Concepts")))
		set tPanes($i(tPanes)) = $lb("dominance", $s(..languageMode="ja":$$$Text("Dominant Entities"), ..useStemming:$$$Text("Dominant Stems"), 1:$$$Text("Dominant Concepts")))
		
		set tSC = ..DrawEntities(.tResult, "htmlTop", .tPanes)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawSimEntities(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		// BDB804
		if (..useStemming && ..useRepresentationForm) {
			set tString = ##class(%iKnow.Queries.EntityAPI).GetStem(..domain, ..term)
		} else {
			set tString = ..term
		}
		
		set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.tResult, ..domain, tString, $g(%session.Data("p:htmlSim"),1), ..pageSize, ..GetFilter(), ..filtermode,, ..GetSkiplists(), $s(..languageMode="ja":$$$ENTTYPECONCEPT, 1:$$$ENTTYPEANY), ..useStemming)
		quit:$$$ISERR(tSC)
		
		set tPanes($i(tPanes)) = $lb("similar", $s(..useStemming:$$$Text("Similar Stems"), 1:$$$Text("Similar Entities")))
		
		set tSC = ..DrawEntities(.tResult, "htmlSim", .tPanes)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawRelEntities(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		set:(..languageMode'="ja")&&'..useStemming tPanes($i(tPanes)) = $lb("related", $$$Text("Related Concepts"))
		set tPanes($i(tPanes)) = $lb("proximity", $$$Text("Proximity Profile"))
		
		set tPaneIndex = $g(%session.Data("t:htmlRel"),1)
		if $lg($g(tPanes(tPaneIndex),tPanes(1)),1)="related" {
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetRelated(.tResult, ..domain, ..term, $g(%session.Data("p:htmlRel"),1), ..pageSize, ..GetFilter(), ..filtermode,,,,,..GetSkiplists())
			quit:$$$ISERR(tSC)
		} else {
			
			// BDB804
			if (..useStemming && ..useRepresentationForm) {
				set tString = ##class(%iKnow.Queries.EntityAPI).GetStem(..domain, ..term)
			} else {
				set tString = ..term
			}
			
			set tSC = ##class(%iKnow.Semantics.ProximityAPI).GetProfile(.tResult, ..domain, tString, $g(%session.Data("p:htmlRel"),1), ..pageSize, ..GetFilter(),..GetSkiplists(),..useStemming)
			quit:$$$ISERR(tSC)
		}
		
		set tSC = ..DrawEntities(.tResult, "htmlRel", .tPanes)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawEntities(ByRef pEntities, pID As %String, ByRef pPanes) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		// cap current pane to max, which may be needed after switching domains or settings
		set tCurrent = $g(%session.Data("t:"_pID),1)
		set tCurrent = $s(tCurrent>pPanes:pPanes, 1:tCurrent)
		
		write !,"<div class=""panel panel-primary"">"
		write !,"<div class=""panel-heading""><b>",$lg(pPanes(tCurrent),2),"</b>"
		
		if $g(pPanes)>1 {
			write !,"<div class=""btn-group btn-group-sm pull-right"" role=""group"">"
			for i = 1:1:pPanes {
				write !,"<button type=""button"" class=""btn ",$s(i=tCurrent:"btn-info", 1:"btn-secondary"),""" onclick=""zenPage.TogglePane('",pID,"',",i,");"" title=""",$lg(pPanes(i),2),""">",$lg(pPanes(i),1),"</button>"
			}
			write !,"</div>"
		}

		write !,"</div>"
		write !,"<table class=""table table-hover table-condensed"">"
		
		set i = "", cnt=0
		for {
			set i = $order(pEntities(i),1,tEntData)
			quit:i=""
			
			// BDB804
			if ..useRepresentationForm && ..useStemming {
				set tRepFormId = ##class(%iKnow.Queries.EntityAPI).GetRepresentationFormId(..domain, $lg(tEntData,1))
				set tEntity = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(..domain,tRepFormId)
			} else {
				set tEntity = $lg(tEntData,2)
			}

			set:$lv(tEntity) tEntity = $lg(tEntity) // dominance query fetches $lb's
			
			write !,"<tr>"
			write !,"<td><a href=""javascript:zenPage.explore('",$zcvt(tEntity,"O","JS"),"');"""_$s(..useStemming&&..useRepresentationForm:" title=""stem: "_$lg(tEntData,2)_"""",1:"")_">",$zcvt(tEntity,"O","HTML"),"</a></td>"
			write !,"<td align=""right"">",$lg(tEntData,3),"</td>"
			write:$ld(tEntData,4) !,"<td align=""right"">",$lg(tEntData,4),"</td>"
			write !,"</tr>"
			
			set cnt = cnt+1
		}
		write !,"</table>"
		
		do ..DrawPagingFooter(pID, cnt)
		
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetSkiplists() As %RawString [ Private ]
{
	if $e(..skiplists,1,6)="SELECT" {
		quit ..skiplists
	} else {
		quit $lfs(..skiplists)
	}
}

Method DrawPaths(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		write !,"<div class=""panel with-nav-tabs panel-primary"">"
	    write !,"<div class=""panel-heading"">"
	    write !,"<ul class=""nav nav-tabs"">"
	    write !,"<li",$s($g(%session.Data("t:htmlPaths"),1)=1:" class=""active""",1:""),"><a onclick=""zenPage.TogglePane('htmlPaths',1);"">"_$$$Text("Sources")_"</a></li>"
	    write !,"<li",$s($g(%session.Data("t:htmlPaths"),1)=2:" class=""active""",1:""),"><a onclick=""zenPage.TogglePane('htmlPaths',2);"">"_$s(..useEntityVectors:$$$Text("Entity Vectors"), 1:$$$Text("Paths"))_"</a></li>"
	    write:(..languageMode'="ja")&&'..useStemming !,"<li",$s($g(%session.Data("t:htmlPaths"),1)=3:" class=""active""",1:""),"><a onclick=""zenPage.TogglePane('htmlPaths',3);"">"_$$$Text("CRCs")_"</a></li>"
	    write:(..languageMode'="ja")&&'..useStemming !,"<li",$s($g(%session.Data("t:htmlPaths"),1)=4:" class=""active""",1:""),"><a onclick=""zenPage.TogglePane('htmlPaths',4);"">"_$$$Text("CCs")_"</a></li>"
	    write !,"</ul>"
	    write !,"</div>"
	             
	    write !,"<div class=""panel-body panel-body-table"" >"
	    write !,"<table class=""table table-hover"">"
	    
		set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(..domain, $lfs(..term), .tEntIds,,,$s(..useStemming:1, 1:0))
		quit:$$$ISERR(tSC)


		set tEntUniId = "", tEntIds=""
		for {
			set tEntUniId = $order(tEntIds(tEntUniId))
			quit:tEntUniId=""
			set tEntIds = tEntIds_$lb(tEntUniId)
		}
	    
	    set cnt=0
	    if ($g(%session.Data("t:htmlPaths"),1)=1) {
		    
		    set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.tResult, ..domain, ..term, $g(%session.Data("p:htmlPaths"),1), ..pageSize, ..GetFilter())
		    quit:$$$ISERR(tSC)
		    
		    set i = ""
		    for {
			    set i = $order(tResult(i),1,tSrcData)
			    quit:i=""
			    
			    set tSrcId = $lg(tSrcData,1)
			    
			    set tClickStyle = " style=""cursor:pointer;"" onclick=""zenPage.openSource("_tSrcId_");"""
			    write !,"<tr><td",tClickStyle,">",tSrcId,"</td><td",tClickStyle,">",$lg(tSrcData,2),"</td><td",tClickStyle,">"
				
				// BDB824
				do ..GetDefaultHighlightSpec(.tHighlight, "minimal", .tEntIds)
		
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByEntityIds(.res, ..domain, tEntIds, $lb(tSrcId))
				set j = ""
				for {
					set j = $order(res(j),-1,sent)
					quit:j=""
					
					write ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(..domain, $li(sent,3), .tHighlight,,, .tSC)
					quit:$$$ISERR(tSC)
					write " ... "
				}
				quit:$$$ISERR(tSC)
			    
			    write !,"</td>"
			    write !,"<td><button type=""button"" class=""btn eye"" onclick=""zenPage.openSource(",tSrcId,");""><image src=""/csp/sys/iknow/img/icon-status-privacy.svg"" class=""icon icon-eye"" /></button></td>"
			    write !,"<td><a href=""_iKnow.UI.IndexingResults.zen?$NAMESPACE="_$namespace_"&domain=",..domain,"&source=",tSrcId,""" target=""_new""><image src=""/csp/sys/iknow/img/icon-play.svg"" class=""icon icon-play"" style=""margin-right:5px;"" /></a></td>"
			    write !,"</tr>"
			    
			    set cnt = cnt+1
		    }

	    } elseif ($g(%session.Data("t:htmlPaths"),1)=2) { // Paths
	    
	    	// BDB824		
			do ..GetDefaultHighlightSpec(.tHighlight, "full", .tEntIds)
			set tHighlight("ROLE",$$$ENTTYPENONREL) = "<font style=""display: none;"">"
			set tHighlight("ROLE",$$$ENTTYPEPATHREL) = "<font style=""display: none;"">"

		    
		    set tSC = ##class(%iKnow.Queries.PathAPI).GetByEntities(.tResult, ..domain, ..term, $g(%session.Data("p:htmlPaths"),1), ..pageSize, ..GetFilter())
		    quit:$$$ISERR(tSC)
		    
		    set i = ""
		    for {
			    set i = $order(tResult(i),1,tPathData)
			    quit:i=""
			    
			    write !,"<tr><td style=""line-height: 2"">"
			    
			    set tPathId = $lg(tPathData,1)
				set tSourceId = ##class(%iKnow.Queries.PathAPI).GetSourceId(..domain, tPathId)

			    #define ENDTAG(%t) $e(%t,1)_"/"_$p($e(%t,2,*-1)," ",1)_$e(%t,*)

			    // DP-404807
			    if ..useEntityVectors {
				    
				    // draw as Entity Vector, which means just concepts and sentence-level attribute highlighting
				    // (path-level attributes are not possible as they require path-based positions, which aren't
				    // available when the domain is configured to use EVs)
				    set tSC = ##class(%iKnow.Queries.PathAPI).GetEntities(.tEntities, ..domain, tPathId)
				    quit:$$$ISERR(tSC)
		    
				    set tConceptTagStart = $g(tHighlight("ROLE",$$$ENTTYPECONCEPT)), 
				    	tConceptTagEnd = $$$ENDTAG(tConceptTagStart)
				    set j = ""
				    for {
					    set j = $order(tEntities(j), 1, tEntData)
					    quit:j=""
					    
					    set tTagStart = tConceptTagStart,
					    	tTagEnd = tConceptTagEnd,
					    	tEntValue = $lg(tEntData,$s(..useStemming:8, 1:4))
					    
					    if $d(tHighlight("ENTITY", $lg(tEntData,3)), tSelectedTagStart) {
						    set tTagStart = tTagStart_tSelectedTagStart,
						    	tTagEnd = $$$ENDTAG(tSelectedTagStart)_tTagEnd
					    }
					    
					    set tSC = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceAttributes(.tAttributes, ..domain, $lg(tEntData,2))
					    quit:$$$ISERR(tSC)
					    
					    // first build a map with per-character attributes, as they may overlap
					    kill tAttMap
					    set k = ""
					    for {
						    set k = $order(tAttributes(k),1,tAttData)
						    quit:k=""
						    
						    set tAttTypeId = $lg(tAttData,1), 
						    	tAttLevel = $lg(tAttData,3)
						    	
						    // can't do paths because we don't have the right positions
						    continue:tAttLevel=$$$IKATTLVLPATH
						    
						    if $d(tHighlight("ATTRIBUTEWORDS",tAttTypeId),tAttTagStart) {
						    	
						    	set tAttProps = "", tAttPropKey=""
						    	for {
							    	set tAttPropKey = $order(tAttributes(k,tAttPropKey),-1,tAttPropValue)
							    	quit:tAttPropKey=""
							    	set tAttProps = $s(tAttProps="":"",1:tAttProps_", ")_tAttPropKey_": "_tAttPropValue
						    	}
						    	set tAttTagStart = $replace(tAttTagStart, "$$$PROPERTIES", tAttProps)
							    
								// these apply at the character level
								set tMask = $lg(tAttData,4), 
									tMaskLength = $l(tMask)
								for l = 1:1:tMaskLength {
									if $e(tMask,l)=1 {
										set tAttMap(l, tAttTypeId) = tAttTagStart
									}
								}
						    }
					    }
					    
					    // note that this may look bad for stems!
					    if $d(tAttMap) {
						    set tNewEntValue = ""
						    for l = 1:1:$l(tEntValue) {
							    set tAttTypeId = "", tAttTagStart="", tAttTagEnd=""
							    for {
								    set tAttTypeId = $order(tAttMap(l,tAttTypeId),1,tTag)
								    quit:tAttTypeId=""
								    set tAttTagStart = tAttTagStart_tTag, 
								    	tAttTagEnd = $$$ENDTAG(tTag)_tAttTagEnd
							    }
							    set tNewEntValue = tNewEntValue_tAttTagStart_$e(tEntValue,l)_tAttTagEnd
						    }
						    set tEntValue = tNewEntValue
					    }
					    
					    write tTagStart _ tEntValue _ tTagEnd _ " "
				    }
				    
			    } else {
				    
				    // draw as regular paths, with full highlighting
				    set tSentenceId = ##class(%iKnow.Queries.PathAPI).GetSentenceId(..domain, tPathId)
					write ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(..domain, tSentenceId, .tHighlight)
					
			    }

			    write !,"</td>"
			    write !,"<td><button type=""button"" class=""btn eye"" onclick=""zenPage.openSource(",tSourceId,");""><image src=""/csp/sys/iknow/img/icon-status-privacy.svg"" class=""icon icon-eye"" /></button></td>"
			    write !,"<td><a href=""_iKnow.UI.IndexingResults.zen?$NAMESPACE="_$namespace_"&domain=",..domain,"&source=",tSourceId,""" target=""_new""><image src=""/csp/sys/iknow/img/icon-play.svg"" class=""icon icon-play"" style=""margin-right:5px;"" /></a></td>"
			    write !,"</tr>"
			    
			    set cnt = cnt+1
		    }
		    
	    } elseif ($g(%session.Data("t:htmlPaths"),1)=3) { // CRCs
	    
		    set tSC = ##class(%iKnow.Queries.CrcAPI).GetByEntities(.tResult, ..domain, ..term, $g(%session.Data("p:htmlPaths"),1), ..pageSize, ..GetFilter(), ..filtermode)
		    quit:$$$ISERR(tSC)
		    
		    set i = ""
		    for {
			    set i = $order(tResult(i),1,tCRCData)
			    quit:i=""
			    
			    write !,"<tr><td>"
			    
			    set tHead = $lg(tCRCData,2)
			    if (tHead'="") {
				    write "<span class="""
					write $s(tHead=..term:"ik-selected", 1:"ik-concept")
					write """ onclick=""zenPage.explore('",$zcvt(tHead,"O","JS"),"');"">"
					write $zcvt(tHead,"O","HTML"),"</span>"
			    }
			    
			    set tRelation = $lg(tCRCData,3)
			    write "<span class="""
				write $s(tRelation=..term:"ik-selected", 1:"ik-relation")
				write """ onclick=""zenPage.explore('",$zcvt(tRelation,"O","JS"),"');"">"
				write $zcvt(tRelation,"O","HTML"),"</span>"
			    
			    set tTail = $lg(tCRCData,4)
			    if (tTail'="") {
				    write "<span class="""
					write $s(tTail=..term:"ik-selected", 1:"ik-concept")
					write """ onclick=""zenPage.explore('",$zcvt(tTail,"O","JS"),"');"">"
					write $zcvt(tTail,"O","HTML"),"</span>"
			    }
			    
			    write !,"</td><td>",$lg(tCRCData,5),"</td><td>",$lg(tCRCData,6),"</td>"
			    write !,"<td><button type=""button"" class=""btn eye"" onclick=""zenPage.drillSources('CRC:",$lg(tCRCData,1),"');""><image src=""/csp/sys/iknow/img/icon-status-privacy.svg"" class=""icon icon-eye"" /></button></td>"
			    write !,"</tr>"
			    
			    set cnt = cnt+1
		    }
		    
	    } elseif ($g(%session.Data("t:htmlPaths"),1)=4) { // CCs
	    
		    set tSC = ##class(%iKnow.Queries.CcAPI).GetByEntities(.tResult, ..domain, ..term, $g(%session.Data("p:htmlPaths"),1), ..pageSize, ..GetFilter(), ..filtermode)
		    quit:$$$ISERR(tSC)
		    
		    set i = ""
		    for {
			    set i = $order(tResult(i),1,tCCData)
			    quit:i=""
			    
			    write !,"<tr><td>"
			    
			    set tHead = $lg(tCCData,2)
			    if (tHead'="") {
				    write "<span class="""
					write $s(tHead=..term:"ik-selected", 1:"ik-concept")
					write """ onclick=""zenPage.explore('",$zcvt(tHead,"O","JS"),"');"">"
					write $zcvt(tHead,"O","HTML"),"</span>"
			    }
			    
			    set tTail = $lg(tCCData,4)
			    if (tTail'="") {
				    write "<span class="""
					write $s(tTail=..term:"ik-selected", 1:"ik-concept")
					write """ onclick=""zenPage.explore('",$zcvt(tTail,"O","JS"),"');"">"
					write $zcvt(tTail,"O","HTML"),"</span>"
			    }
			    
			    write !,"</td><td>",$lg(tCCData,5),"</td><td>",$lg(tCCData,6),"</td>"
			    write !,"<td><button type=""button"" class=""btn eye"" onclick=""zenPage.drillSources('CC:",$lg(tCCData,1),":",$lg(tCCData,3),"');""><image src=""/csp/sys/iknow/img/icon-status-privacy.svg"" class=""icon icon-eye"" /></button></td>"
			    write !,"</tr>"
			    
			    set cnt = cnt+1
		    }
	    }
	    
		write !,"</table>"
		write !,"</div>"
		
		do ..DrawPagingFooter("htmlPaths", cnt, $g(%session.Data("t:htmlPaths"),1)<=2)
		
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod drillSources(spec) [ Language = javascript ]
{
	var sc = zenPage.setProperty('drill', spec);
	zen('modalSourceList').refreshContents();
	$('#modalSourceList').modal('show');
}

ClientMethod openSource(srcID) [ Language = javascript ]
{
	var sc = zenPage.setProperty('source', srcID);
	zen('modalSource').refreshContents();
	$('#modalSource').modal('show');
}

ClientMethod summarize(pct) [ Language = javascript ]
{
	var sc = zenPage.setProperty('summaryPct', pct);
	zen('modalSource').refreshContents();
}

Method DrawSourceListModal(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:..drill=""
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		set tDrillType = $piece(..drill,":",1)
		set tDrill = $case(tDrillType,
			"CRC":$$$Text("Sources with selected CRCs"),
			"CC":$$$Text("Sources with selected CCs"),
			"Similar":$$$Text("Similar Sources"))
		
		write !,"<div class=""modal-dialog modal-dialog-scrollable"">"
		write !,"<div class=""modal-content"">"
		write !,"<div class=""modal-header"">"
		write !,"<button type=""button"" class=""close"" onclick=""$('#modalSourceList').modal('hide');"">&times;</button>"
		write !,"<h4 class=""modal-title"">",tDrill,"</h4>"
		write !,"</div>"
		write !,"<div class=""modal-body"" style=""padding: 0px;"">"
		write !,"<table class=""table table-hover"">"
		
		if (tDrillType="CRC") {
			
			set tCRCIDs = $lfs($piece(..drill,":",2))
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByCrcIds(.tSources, ..domain, tCRCIDs, $g(%session.Data("p:modalSourceList"),1), ..pageSize, ..GetFilter())
			quit:$$$ISERR(tSC)
			
			// BDB824
			do ..GetDefaultHighlightSpec(.tHighlight, "minimal", tCRCIDs, "CRC")
			
		} elseif (tDrillType="CC") {
			
			set tEntIDs = $lfs($piece(..drill,":",2,*),":")
			set tHead = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(..domain, $lg(tEntIDs,1))
			set tTail = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(..domain, $lg(tEntIDs,2))
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByCrcMask(.tSources, ..domain, tHead,, tTail, $g(%session.Data("p:modalSourceList"),1), ..pageSize, ..GetFilter())
			quit:$$$ISERR(tSC)
			
			do ..GetDefaultHighlightSpec(.tHighlight, "minimal", tEntIDs, "ENTITY")
			
		} elseif (tDrillType="Similar") {
			
			set tSourceId = $piece(..drill,":",2)
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetSimilar(.tSources, ..domain, tSourceId, $g(%session.Data("p:modalSourceList"),1), ..pageSize, ..GetFilter())
			quit:$$$ISERR(tSC)
			
			do ..GetDefaultHighlightSpec(.tHighlight, "minimal")
			
		}
		
		set i = "", tCnt=0
		for {
			set i = $order(tSources(i),1,tSrcData)
			quit:i=""
			
			set tSrcId = $lg(tSrcData,1)
			
			// BDB736
			set tClickStyle = " style=""cursor:pointer;"" onclick=""zenPage.openSource("_tSrcId_"); $('#modalSourceList').modal('hide');"""
		    
		    write !,"<tr><td",tClickStyle,">",tSrcId,"</td><td",tClickStyle,">"
			
			if (tDrillType="CRC") {
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByCrcIds(.res, ..domain, tCRCIDs, $lb(tSrcId))
				quit:$$$ISERR(tSC)
				set tSentIdIndex = 3, tSentOrder = -1
			} elseif (tDrillType="CC") {
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetByCrcMask(.res, ..domain, tHead,, tTail, $lb(tSrcId))
				quit:$$$ISERR(tSC)
				set tSentIdIndex = 3, tSentOrder = -1
			} elseif (tDrillType="Similar") {
				set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.res, ..domain, tSrcId, 3)
				quit:$$$ISERR(tSC)
				set tSentIdIndex = 1, tSentOrder = 1
			}
			set j = ""
			for {
				set j = $order(res(j),tSentOrder,sent)
				quit:j=""
				
				write ##class(%iKnow.Queries.SentenceAPI).GetHighlighted(..domain, $li(sent,tSentIdIndex), .tHighlight,,, .tSC)
				quit:$$$ISERR(tSC)
				write " ... "
			}
			
			write !,"</td>"
				
			// BDB914 - show score
			write:tDrillType="Similar" !,"<td",tClickStyle,">",($lg(tSrcData,3)*100),"%</td>"
				
		    write !,"<td><button type=""button"" class=""btn eye"" onclick=""zenPage.openSource(",tSrcId,"); $('#modalSourceList').modal('hide');""><image src=""/csp/sys/iknow/img/icon-status-privacy.svg"" class=""icon icon-eye"" /></button></td>"
		    write !,"<td><span style=""margin-right:5px;"" onclick=""location.href='_iKnow.UI.IndexingResults.zen?domain=",..domain,"&source=",tSrcId,"';""><image src=""/csp/sys/iknow/img/icon-play.svg"" class=""icon-play"" /></span></td>"
			write !,"</tr>"
			
			set tCnt = tCnt+1
		}
		
		write !,"</table>"
		write !,"</div>"
		
		do ..DrawPagingFooter("modalSourceList", tCnt)
		
		write !,"</div>"
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawSourceModal(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:'..source
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		set tExternalID = ##class(%iKnow.Queries.SourceAPI).GetExternalId(..domain, ..source)
		
		write !,"<div class=""modal-dialog modal-dialog-scrollable"">"
		write !,"<div class=""modal-content"">"
		write !,"<div class=""modal-header"">"
		write !,"<button type=""button"" class=""close"" onclick=""$('#modalSource').modal('hide');"">&times;</button>"
		write !,"<h4 class=""modal-title"">",tExternalID,"</h4>"
		write !,"</div>"
		write !,"<div class=""modal-body"" style=""max-height: 400px; overflow-y: auto; line-height: 2; font-size: 12px;"">"
		
		if pSeed = "metadata" {
			
			write !,"<div class=""form-horizontal"">"
			
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.tMetadata, ..domain, ..source)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tMetadata(i), 1, tData)
				quit:i=""
				write !,"<div class=""form-group"">"
				write !,"<label class=""col-sm-2 control-label"">",$lg(tData,2),"</label>"
				do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfoById(..domain, $lg(tData,1), .tInfo)
				set tValue = $case(tInfo("DataType"),"DATE":$zdt($lg(tData,3)), :$lg(tData,3))
				write !,"<div class=""col-sm-10""><p class=""form-control-static"">",tValue,"</p></div>"
				write !,"</div>"
			}
			
			write !,"</div>"
		} else {
			
			write !,"<p>"
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(..domain, $lfs(..term), .tEntIds,,,$s(..useStemming:2, 1:0))
			quit:$$$ISERR(tSC)
			
			// BDB824
			if pSeed = "highlight" {
				do ..GetDefaultHighlightSpec(.tHighlight, "full", .tEntIds)
			} elseif pSeed = "dictionaries" {
				do ..GetDefaultHighlightSpec(.tHighlight, "minimal",,, 1)
			} else {
				do ..GetDefaultHighlightSpec(.tHighlight, "minimal", .tEntIds)
			}
			
			if (..summaryPct = 100) {
				set tSC = ##class(%iKnow.Queries.SentenceAPI).GetBySource(.tSent, ..domain, ..source, 0, 0)
				quit:$$$ISERR(tSC)
			} else {
				set tSource = ##class(%iKnow.Objects.Source).PKINDEXOpen(..domain, ..source)
				set tSentCount = tSource.SentenceCount * ..summaryPct / 100
				set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.tSent, ..domain, ..source, tSentCount)
				quit:$$$ISERR(tSC)
			}
			
			set i = ""
			for {
				set i = $order(tSent(i), 1, tSentData)
				quit:i=""
				write !,##class(%iKnow.Queries.SentenceAPI).GetHighlighted(..domain, $lg(tSentData,1), .tHighlight)," "
			}
			
			write !,"</p>"
		}
		
		write !,"</div>"
		write !,"<div class=""modal-footer"" style=""padding: 5px;"">"
		write !,"<button type=""button"" class=""btn btn-sm ",$s(pSeed="metadata":"btn-primary", 1:"btn-secondary"),""" style=""margin: 5px;"" onclick=""zen('modalSource').setProperty('seed','",$s(pSeed="metadata":"",1:"metadata"),"'); var sc = zen('modalSource').refreshContents(true);"" title="""_$$$Text("show metadata")_""">"_$$$Text("metadata")_"</button>"
		write !,"<button type=""button"" class=""btn btn-sm btn-secondary"" style=""margin: 5px;"" onclick=""zenPage.drillSources('Similar:",..source,"'); $('#modalSource').modal('hide');"" title="""_$$$Text("similar sources")_""">"_$$$Text("similar")_"</button>"
		write !,"<div class=""btn-group btn-group-sm"" role=""group"" style=""margin: 5px;"">"
		write !,"<button type=""button"" class=""btn btn-secondary"" >"_$$$Text("highlight")_": </button>"
		write !,"<button type=""button"" class=""btn ",$s(pSeed="highlight":"btn-primary", 1:"btn-secondary"),""" onclick=""zenPage.toggleHighlighting('highlight');"" title="""_$$$Text("toggle highlighting")_""">"_$$$Text("indexing")_"</button>"
		write !,"<button type=""button"" class=""btn ",$s(pSeed="dictionaries":"btn-primary", 1:"btn-secondary"),""" onclick=""zenPage.toggleHighlighting('dictionaries');"" title="""_$$$Text("toggle highlighting")_""">"_$$$Text("dictionaries")_"</button>"
		write !,"</div>"
		write !,"<div class=""input-group pull-right input-sm"" style=""width: 100px;"">"
		write !,"<input type=""text"" id=""txtPct"" class=""form-control input-sm"" placeholder=""100"" value=""",..summaryPct,""" onchange=""zenPage.summarize($('#txtPct').val());"" title="""_$$$Text("Summary size")_""">"
		write !,"<div class=""input-group-append"">%</div>"
		write !,"</div>"
		write !,"</div>"
		write !,"</div>"
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod toggleHighlighting(type) [ Language = javascript ]
{
	if (zen('modalSource').getProperty('seed') == type) { type = '' };
	var sc = zen('modalSource').setProperty('seed', type); 
	sc = zen('modalSource').refreshContents(true);
}

ClientMethod fixHighlighting(type) [ Language = javascript ]
{
	// BDB736 - move in separate method to ensure it is called AFTER rendering source modal
	
	// some additional highlighting fixes
	switch (type) {
		case 'highlight':
			//$('.highlighted-x').parent().addClass('btn-warning');
			$('button.isc-hl:empty').remove();
			break;
		case 'dictionaries':
			$('button.isc-hl:empty').append('<span class="glyphicon glyphicon-option-horizontal" ></span>');
			break;
	}
}

Method DrawPagingFooter(pID, pCount As %Integer = 0, pLegend As %Boolean = 0) [ Private ]
{
	write !,"<div class=""panel-footer"">&nbsp;"
	write !,"<div class=""btn-group-sm pull-right"" role=""group"">"
	
	write:pLegend !,"<button type=""button"" class=""btn btn-secondary"" onclick=""$('#modalLegend').modal('show');"" title="""_$$$Text("legend")_""">legend</button>"

	s p = ($g(%session.Data("p:"_pID),1)-1), p = $s(p:p,1:1)
	write !,"<button type=""button"" class=""btn btn-secondary ",$s($g(%session.Data("p:"_pID),1)=1:"disabled",1:""),""" onclick=""zenPage.NextPage('",pID,"',",p,");"" title="""_$$$Text("show next")_"""><image src=""/csp/sys/iknow/img/icon-arrow-left.svg"" class=""icon icon-arrow"" /></button>"
	write !,"<button type=""button"" class=""btn btn-secondary ",$s(..pageSize>pCount:"disabled",1:""),""" onclick=""zenPage.NextPage('",pID,"',",($g(%session.Data("p:"_pID),1)+1),");"" title="""_$$$Text("show previous")_"""><image src=""/csp/sys/iknow/img/icon-arrow-right.svg"" class=""icon icon-arrow"" /></button>"
	write !,"</div>"
	write !,"</div>"
}

Method ResetPages() As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set i="p:"
		for {
			set i = $order(%session.Data(i))
			quit:$e(i,1,2)'="p:"
			set %session.Data(i) = 1
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method NextPage(pID As %String, pPage As %Integer) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set %session.Data("p:"_pID) = pPage
		&js<zen('#(pID)#').refreshContents();>
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method TogglePane(pID As %String, pPane As %Integer) As %Status [ ZenMethod ]
{
	set %session.Data("t:"_pID) = pPane
	set %session.Data("p:"_pID) = 1
	&js<zen('#(pID)#').refreshContents();>
	quit $$$OK
}

Method DrawButtons(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(..domain, ..GetFilter())
		set:tSourceCount<0 tSourceCount = ""
		
		// draw buttons
		write !,"<div class=""pull-right"" role=""group"" style=""width: 192px;"">"
		write !,"<span class=""btn-group"">"
		write !,"<div class=""sources-badge"" title="" ",tSourceCount,$s(..filter="":$$$Text("sources in domain"), 1:$$$Text("sources selected by filter")),""" readonly=""readonly""><span class=""badge"">",tSourceCount,"</span></div>"
		write !,"<button type=""button"" class=""btn ",$s(..filter="":"btn-secondary",1:"btn-success"),""" title="""_$$$Text("Apply filters")_""" onclick=""$('#modalFilter').modal('show');""><image src=""/csp/sys/iknow/img/icon-filters.svg"" class=""icon icon-filter"" /></button>"
		if (##class(%iKnow.Utils.MaintenanceAPI).HasSkipLists(+..domain) || ##class(%iKnow.Utils.MaintenanceAPI).HasSkipLists(0)) {
			write !,"<button type=""button"" class=""btn ",$s(..skiplists="":"btn-secondary",1:"btn-success"),""" title="""_$$$Text("Apply skiplists")_""" onclick=""$('#modalSkiplist').modal('show');""><image src=""/csp/sys/iknow/img/icon-skiplist.svg"" class=""icon icon-skiplist"" /></button>"
		}
		write !,"<button type=""button"" class=""btn btn-secondary"" title="""_$$$Text("Select domain and other settings")_""" onclick=""$('#modalSettings').modal('show');""><image src=""/csp/sys/iknow/img/icon-settings.svg"" class=""icon icon-gear"" /></button>"
		write !,"</span>"
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawFilterPane(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		write !,"<div class=""modal-dialog"">"
		write !,"<div class=""modal-content"">"
		write !,"<div class=""modal-header"">"
		write !,"<button type=""button"" class=""close"" onclick=""zenPage.applyPane('modalFilter');"">&times;</button>"
		write !,"<h4 class=""modal-title"">"_$$$Text("Filters")_"</h4>"
		write !,"</div>"
		
		write !,"<div class=""modal-body"" style=""max-height: 400px; overflow-y: auto;"">"
		
		// current filter
		write !,"<div class=""well""><input type=""hidden"" id=""hidLocation"" value="""" />"
		do DrawFilter(..filter,"")
		write !,"</div>"
		
		// add filter form
		write !,"<form class=""form-inline"">"
		
		set tFilterType = $piece(pSeed,":",1)
		set:tFilterType="" tFilterType = "MD"
		write !,"<select id=""selFilterType"" class=""form-control input-sm"" required=""true"" style=""vertical-align: top;"" onchange=""zenPage.updateFilter($('#selFilterType').val());"" >"
		write !,"<option value=""MD""",$s(tFilterType="MD":" selected=""selected""", 1:""),">"_$$$Text("metadata")_"</option>"
		write !,"<option value=""SQL""",$s(tFilterType="SQL":" selected=""selected""", 1:""),">SQL</option>"
		write !,"<option value=""SrcId""",$s(tFilterType="SrcId":" selected=""selected""", 1:""),">"_$$$Text("Source IDs")_"</option>"
		write !,"<option value=""ExtId""",$s(tFilterType="ExtId":" selected=""selected""", 1:""),">"_$$$Text("External IDs")_"</option>"
		write !,"<option value=""Range""",$s(tFilterType="Range":" selected=""selected""", 1:""),">"_$$$Text("Source ID range")_"</option>"
		
		set tSC = ..GetCustomFilterTypes(.tCustomTypes)
		quit:$$$ISERR(tSC)
		set tType = ""
		for {
			set tType = $order(tCustomTypes(tType),1,tTypeLabel)
			quit:tType=""
			write !,"<option value=""Custom:"_tType_"""",$s(tFilterType="Custom":" selected=""selected""", 1:""),">"_tTypeLabel_"</options>"
		}
		
		write !,"</select>"
		
		if (tFilterType="MD") {
			set tFieldName = $piece(pSeed,":",2)
			write !,"<select id=""selMDField"" class=""form-control input-sm"" required=""true"" onchange=""zenPage.updateFilter('MD:'+$('#selMDField').val());"" >"
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.tFields, ..domain)
			quit:$$$ISERR(tSC)
			set i = ""
			for {
				set i = $order(tFields(i),1,tFieldData)
				quit:i=""
				write !,"<option",$s(tFieldName=$lg(tFieldData,2):" selected=""selected""",1:""),">",$lg(tFieldData,2),"</option>"
			}
			write !,"</select>"
			
			set tOperator = $piece(pSeed,":",3)
			do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfo(..domain, tFieldName, .tInfo)
			write !,"<select id=""selMDOperator"" class=""form-control input-sm"" required=""true"" onchange=""zenPage.updateFilter('MD:'+$('#selMDField').val()+':'+$('#selMDOperator').val()+':'+$('#selMDValue').val());"" >"
			for i = 1:1:$l(tInfo("SupportedOperators"),",") {
				set tOp = $piece(tInfo("SupportedOperators"),",",i)
				write !,"<option",$s(tOp=tOperator:" selected=""selected""",1:""),">",$zcvt(tOp,"O","HTML"),"</option>"
			}
			write !,"</select>"
			
			if (tOperator'="IS NULL") && (tOperator'="IS NOT NULL") {
				set tValue = $s(tOperator="BETWEEN":$piece(pSeed,":",4), 1:$piece(pSeed,":",4,*))
				if (tInfo("HasBitstringStorage")) {
					write !,"<select id=""selMDValue"" class=""form-control input-sm"" required=""true"" >"
					set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFieldValues(.tValues, ..domain, tFieldName, 0, 0)
					quit:$$$ISERR(tSC)
					set i = ""
					for {
						set i = $order(tValues(i),1,tValueData)
						quit:i=""
						write !,"<option",$s(tValue=$lg(tValueData,1):" selected=""selected""",1:""),">",$zcvt($lg(tValueData,1),"O","HTML"),"</option>"
					}
					write !,"</select>"
				} else {
					write !,"<input id=""selMDValue"" type="""_$case(tInfo("DataType"),"NUMBER":"number","DATE":"date",:"text")_""" value=""",$zcvt(tValue,"O","HTML"),""" class=""form-control input-sm"" />"
				}
				if (tOperator="BETWEEN") {
					set tValue2 = $piece(pSeed,":",5)
					write !," "_$$$Text("and")_" "
					if (tInfo("HasBitstringStorage")) {
						write !,"<select id=""selMDValue2"" class=""form-control input-sm"" required=""true"" >"
						set i = ""
						for {
							set i = $order(tValues(i),1,tValueData)
							quit:i=""
							write !,"<option",$s(tValue2=$lg(tValueData,1):" selected=""selected""",1:""),">",$zcvt($lg(tValueData,1),"O","HTML"),"</option>"
						}
						write !,"</select>"
					} else {
						write !,"<input id=""selMDValue2"" type="""_$case(tInfo("DataType"),"NUMBER":"number","DATE":"date",:"text")_""" value=""",$zcvt(tValue2,"O","HTML"),""" class=""form-control input-sm"" />"
					}
				}
			}
			
		} elseif (tFilterType="SQL") {
			
			set tFilterSQL = $piece(pSeed,":",2,*)
			write !,"<textarea id=""txtFilterSQL"" placeholder=""SELECT ... AS SourceId FROM ..."" value=""",tFilterSQL,""" class=""form-control input-sm"" title="""_$$$Text("Query must return a 'SourceId' or 'ExternalId' column")_""" rows=""3"" cols=""50"" ></textarea>"
			
		} elseif (tFilterType="SrcId") {
			
			set tSrcIds = $piece(pSeed,":",2)
			write !,"<input id=""txtFilterSrcIds"" type=""text"" value=""",tSrcIds,""" class=""form-control input-sm"" placeholder=""123, 654, ..."" />"
			
		} elseif (tFilterType="ExtId") {
			
			set tExtIds = $piece(pSeed,":",2,*)
			write !,"<input id=""txtFilterExtIds"" type=""text"" value=""",tExtIds,""" class=""form-control input-sm"" placeholder=""ExtID1,ExtID2,..."" />"
			
		} elseif (tFilterType="Range") {
			
			write !,$$$Text("from")_" <input id=""txtFilterSrcIdFrom"" type=""text"" value=""",$piece(pSeed,":",2),""" class=""form-control input-sm"" placeholder=""123"" /> "_$$$Text("to")_" "
			write !,"<input id=""txtFilterSrcIdTo"" type=""text"" value=""",$piece(pSeed,":",3),""" class=""form-control input-sm"" placeholder=""456"" />"
			
		} elseif (tFilterType="Custom") {
			
			set tSC = ..DrawCustomFilterInputs($piece(pSeed,":",2), $piece(pSeed,":",3,*))
			quit:$$$ISERR(tSC)
			
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Unknown filter type: '"_tFilterType_"'")
			quit
		}
		
		write !,"<button type=""button"" class=""btn btn-primary btn-sm"" style=""vertical-align: top;"" onclick=""zenPage.submitFilter();"">"_$$$Text("add")_"</button>"
		write !,"</form>"
		
		
		write !,"</div>"
		
		write !,"<div class=""modal-footer"">"
		write !,"<button class=""btn btn-secondary"" onclick=""zenPage.resetFilter();"">"_$$$Text("Clear")_"</button>"
		write !,"<button class=""btn btn-primary"" onclick=""zenPage.applyPane('modalFilter');"">"_$$$Text("Apply")_"</button>"
		write !,"</div>"
		write !,"</div>"

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
	
DrawFilter(tFilter, tLocation)
	if (tFilter="") {
		write "[no filter]"
		quit
	}
	if '$isobject(tFilter) {
		do ##class(%iKnow.Filters.Filter).FromString(..domain, tFilter, .tObj)
		set tFilter = tObj
	}
	if (tFilter.%IsA("%iKnow.Filters.GroupFilter")) {
		write !,"<table><tr><td rowspan=""",(tFilter.GetSubFilterCount()+1),""" style=""padding: 5px;"">"
		
		set tLogic = $case(tFilter.GroupLogic, $$$GROUPFILTERAND:"AND", $$$GROUPFILTEROR:"OR", :tFilter.GroupLogic)
		write !,"<div class=""dropdown"">"
		write !,"<button type=""button"" class=""btn btn-sm ",$s(tFilter.Negated:"btn-danger",1:"btn-primary"),""""
		write " id=""menu-",tLocation,""" data-toggle=""dropdown"" aria-haspopup=""true"" >"
		write $s(tFilter.Negated:"NOT ",1:""),tLogic,"&nbsp; <span class=""caret""></span></button>"
		write !,"<div class=""dropdown-menu"" aria-labelledby=""menu-",tLocation,""">"
    	write !,"<a class=""dropdown-item"" href=""#"" onclick=""var sc = zenPage.ToggleFilter('",tLocation,"','AND',0); zen('modalFilter').refreshContents();"">AND</a></li>"
    	write !,"<a class=""dropdown-item"" href=""#"" onclick=""var sc = zenPage.ToggleFilter('",tLocation,"','OR',0); zen('modalFilter').refreshContents();"">OR</a></li>"
    	write !,"<a class=""dropdown-item"" href=""#"" onclick=""var sc = zenPage.ToggleFilter('",tLocation,"','AND',1); zen('modalFilter').refreshContents();"">NOT AND</a></li>"
		write !,"<a class=""dropdown-item"" href=""#"" onclick=""var sc = zenPage.ToggleFilter('",tLocation,"','OR',1); zen('modalFilter').refreshContents();"">NOT OR</a></li>"
		write !,"</div></div></td>"
		
		for i = 1:1:tFilter.GetSubFilterCount() {
			write:i>1 !,"<tr>"
			write "<td style=""padding: 5px 2px;"">"
			do DrawFilter(tFilter.GetSubFilterAt(i), tLocation_$s(tLocation="":"",1:"-")_i)
			write !,"</td></tr>"
		}
		write !,"<tr><td><button id=""location-",tLocation,""" class=""btn btn-sm btn-secondary opacity-50"" title="""_$$$Text("add new filters here")_""" onclick=""zenPage.setFilterLocation('",tLocation,"');"">"_$$$Text("add filter here")_"</button></td></tr>"
		write !,"</table>"
	} else {
		if (tFilter.%IsA("%iKnow.Filters.SimpleMetadataFilter")) {
			set tField = ##class(%iKnow.Queries.MetadataAPI).GetFieldInfoById(..domain, tFilter.FieldId, .tInfo)
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px;"">",tInfo("Name"),"</button>"
			write !,"<button type=""button"" class=""btn btn-sm btn-secondary"" style=""margin-right: 5px; padding: 2px 10px;"">",tFilter.FilterOperator,"</button>"
			set tDisplayValue = $case(tInfo("DataType"),"DATE":$zdate(tFilter.FilterValue),:tFilter.FilterValue)
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px;"">",tDisplayValue,"</button>"
		} elseif (tFilter.%IsA("%iKnow.Filters.SqlFilter")) {
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px; text-align: left;"">SQL: ",$e(tFilter.SqlQuery,1,40),$s($l(tFilter.SqlQuery)>40:"... ",1:""),"</button>"
		} elseif (tFilter.%IsA("%iKnow.Filters.SourceIdRangeFilter")) {
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px; text-align: left;"">Source IDs: ",tFilter.From,"..",tFilter.To,"</button>"
		} elseif (tFilter.%IsA("%iKnow.Filters.SourceIdFilter")) {
			set tSrcId=0, c=0, tString=""
			for {
				set tSrcId = tFilter.GetNextSrcId(tSrcId)
				quit:'tSrcId
				set tString = tString_$s(c:", ",1:"")_tSrcId
				quit:$i(c)>=3
			}
			if tSrcId && tFilter.GetNextSrcId(tSrcId) {
				set tString = tString_", ..."
			}
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px; text-align: left;"">Source IDs: ",tString,"</button>"		} elseif (tFilter.%IsA("%iKnow.Filters.SourceIdFilter")) {
		} elseif (tFilter.%IsA("%iKnow.Filters.ExternalIdFilter")) {
			set tSrcId=0, c=0, tString=""
			for {
				set tSrcId = tFilter.GetNextSrcId(tSrcId)
				quit:'tSrcId
				set tString = tString_$s(c:", ",1:"")_##class(%iKnow.Queries.SourceAPI).GetExternalId(..domain, tSrcId)
				quit:$i(c)>=2
			}
			if tSrcId && tFilter.GetNextSrcId(tSrcId) {
				set tString = tString_", ..."
			}
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px; text-align: left;"">External IDs: ",tString,"</button>"
		} else {
			try {
				set tLabel = tFilter.GetLabel()
			} catch {
				set tLabel = "[other filter type]"
			}
			write !,"<button type=""button"" class=""btn btn-sm btn-info"" style=""margin-right: 5px; padding: 2px 10px; text-align: left;"">",tLabel,"</button>"
		}
		write:tLocation'="" !,"<button id=""location-",tLocation,""" class=""btn btn-sm btn-secondary opacity-50"" title="""_$$$Text("add new filters here")_""" onclick=""zenPage.setFilterLocation('",tLocation,"');"">"_$$$Text("add filter here")_"</button>"
		write !,"<span class=""remove-filter"" onclick=""var sc = zenPage.RemoveFilter('",tLocation,"'); zen('modalFilter').refreshContents();"">&times</span>"
	}
}

/// Subclasses can override this method to supply custom filter types to be displayed
/// in the filter type dropdown in the following format:
/// pCustomFilterTypes(typeName) = typeLabel
ClassMethod GetCustomFilterTypes(Output pCustomFilterTypes) As %Status
{
	kill pCustomFilterTypes
	// set pCustomFilterTypes("MyFilter") = "my filter"
	quit $$$OK
}

/// Subclasses can override this method to draw the input fields specific to a custom
/// filter type added through <method>GetCustomFilterTypes</method>.
/// <var>pSettings</var> is the string capturing user input, as assembled by <method>getCustomFilterSettings</method>.
Method DrawCustomFilterInputs(pFilterType As %String, pSettings As %String) As %Status
{
	// sample code:
	// write !,"<select id=""selCustomFilterSetting"" class=""form-control input-sm"" required=""true"" > ... </select>"
	quit $$$ERROR($$$GeneralError, "Unknown custom filter type: '"_pFilterType_"'")
}

/// Subclasses can override this method to pick up the values of the input fields
/// specific to a custom filter type as draw in <method>DrawCustomFilterIntputs</method>
/// and concatenate them into a settings string.
ClientMethod getCustomFilterSettings(filterType) [ Language = javascript ]
{
	// sample code:
	// return zen('selCustomFilterSetting').getValue();
	return '';
}

/// Subclasses can override this method to instantiate an actual <class>%iKnow.Filters.Filter</class> 
/// object based on the supplied settings.
/// <var>pSettings</var> is the string capturing user input, as assembled by <method>getCustomFilterSettings</method>.
Method CreateCustomFilter(pFilterType As %String, pSettings As %String) As %iKnow.Filters.Filter
{
	// sample code:
	// &SQL(SELECT SQL INTO :tSQL FROM SomePackage.SavedFilters WHERE ID = :pSettings)
	// quit ##class(%iKnow.Filters.SqlFilter).%New(..domain, tSQL)
	quit ""
}

ClientMethod resetFilter() [ Language = javascript ]
{
	var sc = zenPage.AddFilter('CLEAR'); 
	zen('modalFilter').refreshContents();
}

ClientMethod submitFilter() [ Language = javascript ]
{
	var spec = $('#selFilterType').val();
	if (spec == 'SQL') {
		spec = 'SQL:'+$('#txtFilterSQL').val();
	} else if (spec == 'SrcId') {
		spec = 'SrcId:'+$('#txtFilterSrcIds').val();
	} else if (spec == 'Range') {
		spec = 'Range:'+$('#txtFilterSrcIdFrom').val()+':'+$('#txtFilterSrcIdTo').val();
	} else if (spec == 'ExtId') {
		spec = 'ExtId:'+$('#txtFilterExtIds').val();
	} else if (spec == 'MD') {
		spec = 'MD:'+$('#selMDField').val()+':'+$('#selMDOperator').val()+':'+$('#selMDValue').val();
		if ($('#selMDOperator').val()=='BETWEEN') { spec += ';'+$('#selMDValue2').val(); } // $$$MDVALUESEPARATOR=";"
	} else if (spec.substring(0,6) == 'Custom') {
		spec = spec+':'+zenPage.getCustomFilterSettings(spec.substring(7));
	}
	var sc = zenPage.AddFilter(spec, $('#hidLocation').val()); 
	zen('modalFilter').refreshContents();
}

ClientMethod setFilterLocation(location) [ Language = javascript ]
{
	var current = $('#hidLocation').val();
	if (current != null) {
		$('#location-'+current).removeClass("btn-success");
		$('#location-'+current).addClass("btn-secondary");
	}
	if (location == current) {
		$('#hidLocation').val('');
	} else {
		$('#hidLocation').val(location);
		$('#location-'+location).removeClass("btn-secondary");
		$('#location-'+location).addClass("btn-success");
	}
}

Method ErrorHandler(pSC As %Status) As %Status
{
	if $$$ISERR(pSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(pSC),"O","JS")
		&js<console.log('ERROR: #(tMessage)#')>
		&js<alert('#(tMessage)#')>
	}
	quit pSC
}

Method ToggleFilter(pLocation As %String, pLogic As %String = "", pNegation As %Boolean = -1) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:..filter=""
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		set tSC = ##class(%iKnow.Filters.Filter).FromString(..domain, ..filter, .tCurrentFilter)
		quit:$$$ISERR(tSC)
		
		if (pLocation="") {
			set tFilter = tCurrentFilter
		} else {
			set tFilter = ..GetSubFilter(tCurrentFilter, pLocation)
		}
		set:pLogic'="" tFilter.GroupLogic = pLogic
		set:pNegation>-1 tFilter.Negated = pNegation
		set ..filter = tCurrentFilter.ToString()

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method RemoveFilter(pLocation As %String = "") As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:..filter=""
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		set tSC = ##class(%iKnow.Filters.Filter).FromString(..domain, ..filter, .tCurrentFilter)
		quit:$$$ISERR(tSC)
		
		if ('tCurrentFilter.%IsA("%iKnow.Filters.GroupFilter")) {
			set ..filter = ""
			quit
		}
		
		set tParentLocation = $piece(pLocation,"-",1,*-1)
		if (tParentLocation'="") {
			set tParent = ..GetSubFilter(tCurrentFilter, tParentLocation)
			do tParent.RemoveSubFilterAt($piece(pLocation,"-",*))
		} else {
			do tCurrentFilter.RemoveSubFilterAt(pLocation)
		}
		set ..filter = tCurrentFilter.ToString()
			
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method AddFilter(pString As %String, pLocation As %String = "") As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		if pString="CLEAR" {
			set ..filter = ""
			quit
		}
		
		if $piece(pString,":",1)="MD" {
			do ##class(%iKnow.Queries.MetadataAPI).GetFieldInfo(..domain,$piece(pString,":",2),.tInfo)
			set tFilterValue = $case($g(tInfo("DataType")), "DATE":$zdateh($piece(pString,":",4,*),3), :$piece(pString,":",4,*))
			set tNewFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(..domain, $piece(pString,":",2), $piece(pString,":",3), tFilterValue)
		} elseif $piece(pString,":",1) = "SQL" {
			set tNewFilter = ##class(%iKnow.Filters.SqlFilter).%New(..domain, $piece(pString,":",2,*))
		} elseif $piece(pString,":",1) = "SrcId" {
			set tSrcIds = $zstrip($piece(pString,":",2,*),"*W")
			set tNewFilter = ##class(%iKnow.Filters.SourceIdFilter).%New(..domain, tSrcIds)
		} elseif $piece(pString,":",1) = "ExtId" {
			set tNewFilter = ##class(%iKnow.Filters.ExternalIdFilter).%New(..domain, $piece(pString,":",2,*))
		} elseif $piece(pString,":",1) = "Range" {
			set tNewFilter = ##class(%iKnow.Filters.SourceIdRangeFilter).%New(..domain, $piece(pString,":",2), $piece(pString,":",3))
		} elseif $piece(pString,":",1) = "Custom" {
			set tNewFilter = ..CreateCustomFilter($piece(pString,":",2), $piece(pString,":",3,*))
		} else {
			set tSC = $$$ERROR($$$GeneralError, "unsupported filter type")
			quit
		}
		
		if '$isobject(tNewFilter) {
			set tSC = $g(%objlasterror, $$$ERROR($$$GeneralError, "unexpected error instantiating filter object"))
			quit
		}
		
		if ..filter="" {
			set ..filter = tNewFilter.ToString()
		} else {
			set tSC = ##class(%iKnow.Filters.Filter).FromString(..domain, ..filter, .tCurrentFilter)
			quit:$$$ISERR(tSC)
			
			if ('tCurrentFilter.%IsA("%iKnow.Filters.GroupFilter")) {
				
				set tFilter = ##class(%iKnow.Filters.GroupFilter).%New(..domain, "AND")
				do tFilter.AddSubFilter(tCurrentFilter)
				do tFilter.AddSubFilter(tNewFilter)
				set ..filter = tFilter.ToString()
				
			} elseif (pLocation="") {
				
				do tCurrentFilter.AddSubFilter(tNewFilter)
				set ..filter = tCurrentFilter.ToString()
				
			} else {
				
				set tFilter = ..GetSubFilter(tCurrentFilter, pLocation)
				set tSC = tFilter.AddSubFilter(tNewFilter)
				quit:$$$ISERR(tSC)
				set ..filter = tCurrentFilter.ToString()
				
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method GetSubFilter(pFilter As %iKnow.Filters.GroupFilter, pLocation As %String) As %iKnow.Filters.Filter [ Internal, Private ]
{
	set tLocNum = $piece(pLocation,"-",1)
	set tSubFilter = pFilter.GetSubFilterAt(tLocNum)
	quit:tSubFilter="" pFilter
	if tSubFilter.%IsA("%iKnow.Filters.GroupFilter") {
		if $find(pLocation,".") {
			quit ..GetSubFilter(tSubFilter, $piece(pLocation,"-",2,*))
		} else {
			quit tSubFilter
		}
	} else {
		set tSwap = tSubFilter
		set tGroupFilter = ##class(%iKnow.Filters.GroupFilter).%New(..domain, "AND")
		do tGroupFilter.AddSubFilter(tSwap)
		do pFilter.ReplaceSubFilterAt(tLocNum, tGroupFilter)
		quit tGroupFilter
	}
}

ClientMethod updateFilter(seed) [ Language = javascript ]
{
	var sc = zen('modalFilter').setProperty('seed',seed);
	zen('modalFilter').refreshContents();
}

ClientMethod applyPane(pane) [ Language = javascript ]
{
	$('#'+pane).modal('hide');
	zenPage.refreshAll();
}

Method GetFilter() As %iKnow.Filters.Filter
{
	do ##class(%iKnow.Filters.Filter).FromString(..domain, ..filter, .tFilterObj)
	quit tFilterObj
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// apply bootstrap class to assistedText control
	var input = $('#txtSearch').children().first().children().filter('input').first();
	input.addClass('form-control').css('borderTopLeftRadius','3px').css('borderBottomLeftRadius','3px');
	input.parent().addClass('input-group');
	input.parent().append('<button type="button" class="btn btn-secondary input-group-btn" onclick="zenPage.explore(zen(\"txtSearch\").getValue(), true);">Explore!</button>');
	
	if (zenPage.ShowInfo()) {
		$('#modalInfo').modal('show');
	}
}

ClientMethod closeInfo() [ Language = javascript ]
{
	zenPage.DisableInfo();
	$('#modalInfo').modal('hide');
}

Method ShowInfo() As %Boolean [ ZenMethod ]
{
	quit ..domain && '$g(%session.Data("disableInfo"),0)
}

Method DisableInfo() [ Internal, ZenMethod ]
{
	set %session.Data("disableInfo")=1
}

Method DrawSkiplistsPane(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:('..domain)||'##class(%iKnow.Domain).%ExistsId(..domain)
		
		write !,"<div class=""modal-dialog"">"
		write !,"<div class=""modal-content"">"
		write !,"<div class=""modal-header"">"
		write !,"<button type=""button"" class=""close"" onclick=""zenPage.applyPane('modalSkiplist');"">&times;</button>"
		write !,"<h4 class=""modal-title"">"_$$$Text("Skiplists")_"</h4>"
		write !,"</div>"
		
		write !,"<div class=""modal-body"" style=""max-height: 400px; overflow-y: auto;"">"
		
		set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipLists(.tResult, ..domain, 1)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tResult(i),1,tData)
			quit:i=""
			write !,"<div class=""checkbox""><label>"
			write "<input type=""checkbox"" onclick=""zenPage.toggleSkiplist('",$lg(tData,1),"');"">"
			write $lg(tData,2),"</label></div>"
		}
		
		write !,"</div>"

		write !,"<div class=""modal-footer"">"
		write !,"<button class=""btn btn-primary"" onclick=""zenPage.applyPane('modalSkiplist');"">"_$$$Text("Apply")_"</button>"
		write !,"</div>"
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod toggleSkiplist(id) [ Language = javascript ]
{
	var current = zenPage.getProperty('skiplists').split(',');
	var idx = current.indexOf(id);
	if (idx == -1) { current[current.length] = id; }
	else {
		var arr = current.slice(0,idx);
		current = arr.concat(current.slice(idx+1));
	}
	zenPage.setProperty('skiplists',current.join(','));
}

Method DrawSettingsPane(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		
		write !,"<div class=""modal-dialog"">"
		write !,"<div class=""modal-content"">"
		write !,"<div class=""modal-header"">"
		write !,"<button type=""button"" class=""close"" onclick=""zenPage.applyPane('modalSettings');"">&times;</button>"
		write !,"<h4 class=""modal-title"">"_$$$Text("Settings")_"</h4>"
		write !,"</div>"
		
		write !,"<div class=""modal-body"" style=""max-height: 400px; overflow-y: auto;"">"
		
		write !,"<form>"
		
		write !,"<div class=""form-group"">"
		write !,"<input type=""checkbox"" id=""chkDisableAC"" ",$s(..enableAutocomplete:" checked=""checked""",1:""),"onclick=""var sc = zenPage.setProperty('enableAutocomplete',"_$s(..enableAutocomplete:"false", 1:"true")_"); zen('modalSettings').refreshContents();"">"
		write !,"<label for=""chkDisableAC"">"_$$$Text("Enable autocomplete feature")_"</label>"
		write !,"</div>"
		
		write !,"<div class=""form-group"">"
		write !,"<label for=""selDomain"">"_$$$Text("Switch domain")_"</label>"
		write !,"<select id=""selDomain"" class=""form-control"" onchange=""if ($('#selDomain').val()) location.href=$('#selDomain').val();"">"
		write !,"<option class=""text-muted"" value="""">-- "_$$$Text("select a domain")_" --</option>"
		
		set tResult = ##class(%ResultSet).%New("%iKnow.Domain:GetAllDomains")
		set tSC = tResult.%Execute('..includeOtherNamespaces)
		quit:$$$ISERR(tSC)
		
		while tResult.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			set tURL = "/csp/"_tResult.%Get("namespace")_"/"_$tr($classname(),"%","_")_".zen?$NAMESPACE=" _ tResult.%Get("namespace") _ "&domain=" _ tResult.%Get("domainId")
			write !,"<option value=""",tURL,""""
			if (tResult.%Get("namespace")=$namespace) && (tResult.%Get("domainId")=..domain) {
				write " selected=""selected"""
			}
			write ">",tResult.%Get("domainName"),"</option>"
		}
		quit:$$$ISERR(tSC)
		write !,"</select>"
		write !,"</div>"
		
		write !,"<div class=""form-group"">"
		write !,"<input type=""checkbox"" id=""chkOtherNS"" ",$s(..includeOtherNamespaces:" checked=""checked""",1:""),"onclick=""var sc = zenPage.setProperty('includeOtherNamespaces',",$s(..includeOtherNamespaces:"false", 1:"true"),"); zen('modalSettings').refreshContents();"">"
		write !,"<label for=""chkOtherNS"">"_$$$Text("Include other namespaces")_"</label>"
		write !,"</div>"
		
		// BDB804
		if ($$$GETPARAM(..domain,$$$IKPSTEMMING,0)'=0) {
			write !,"<div class=""form-group"">"
			write !,"<input type=""checkbox"" id=""chkStemming"" ",$s(..useStemming:" checked=""checked""",1:""),"onclick=""var sc = zenPage.setProperty('useStemming',",$s(..useStemming:"false", 1:"true"),"); zen('modalSettings').refreshContents();"">"
			write !,"<label for=""chkStemming"">"_$$$Text("Use stems instead of entities")_"</label>"
			write !,"</div>"
			write !,"<div class=""form-group"">"
			write !,"<input type=""checkbox"" id=""chkRepForm"" ",$s(..useRepresentationForm:" checked=""checked""",1:""),"onclick=""var sc = zenPage.setProperty('useRepresentationForm',",$s(..useRepresentationForm:"false", 1:"true"),"); zen('modalSettings').refreshContents();"">"
			write !,"<label for=""chkRepForm"">"_$$$Text("Show representation form for stems")_"</label>"
			write !,"</div>"
		}
		
		write !,"</form>"
		write !,"</div>"
		

		write !,"<div class=""modal-footer"">"
		write !,"<button class=""btn btn-primary"" onclick=""zenPage.applyPane('modalSettings');"">"_$$$Text("Apply")_"</button>"
		write !,"</div>"
		write !,"</div>"
	

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawLegend(pSeed As %String) As %Status
{
	&html<<div class="modal-dialog">
		<div class="modal-content">
		<div class="modal-header">
		<h3>Legend<h3>
		</div>
		<div class="modal-body">>
	do ..WriteLegend("full")
	&html<</div>
	<div class="modal-footer">
	<button class="btn btn-primary" onclick="$('#modalLegend').modal('hide');">OK</button>
	</div>
	</div>
	</div>>
	quit $$$OK
}

}
