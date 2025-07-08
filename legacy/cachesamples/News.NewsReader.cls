Include %IKInclude

/// <p>This ZEN page presents a simple News Aggregator UI in which a number of iKnow features
/// are demonstrated. Call the %Build() method on <class>News.NewsDomain</class> to populate 
/// the domain based on a number of RSS feeds and then run this page to get started.</p>
/// <p>To keep the code simple, the central table on this page just queries a simple SQL table 
/// <class>News.Results.Sources</class> that holds the results for the current user action. By
/// default the table will be populated with the most recent articles, but depending on filter 
/// selections or buttons clicked by the user, different queries (iKnow or SQL) will be used to
/// fill this table.</p>
Class News.NewsReader Extends %ZEN.Component.page
{

/// ID of the domain used by this demo
Property Domain As %Integer [ InitialExpression = {##class(News.NewsDomain).%GetDomainId()} ];

/// Name of the domain used by this demo
Property DomainName As %String [ InitialExpression = {##class(News.NewsDomain).%GetDomainName()} ];

/// Current page of results
Property CurrentPage As %Integer [ InitialExpression = 1 ];

/// Current action, as selected by the user
Property CurrentAction As %String;

/// Source ID as selected by the user when clicking on an action
Property SelectedSource As %Integer;

/// Agency filter, if selected by the user (Module 3, exercise 4)
Property Agency As %String;

/// Length of the summary to be displayed in the article reading pane (Module 3, exercise 6)
Property SummaryLength As %Integer [ InitialExpression = 0 ];

/// Entity ID as selected by the user when clicking on an entity (Module 3, exercise 6)
Property SelectedEntity As %Integer;

/// Topic filter, if selected by the user (Module 4, exercise 4)
Property Topic As %String;

/// Name of the dictionary containing "favorite terms" (Module 4, exercise 5)
Property FavoritesDictionary As %String [ InitialExpression = "My Favorites" ];

/// Subtitle, as derived by <method>RefreshTables</method>
Property Subtitle As %String [ InitialExpression = "Recent articles" ];

/// Name of the configuration to use for indexing manual input
Property InputConfig As %String [ InitialExpression = "AllLanguages" ];

/// IFind search string as provided by the user (Module 5, exercise 5)
Property IFindSearchString As %String;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page title="News reader" layout="vertical" width="100%" height="100%" >
<titleBox title="News reader" titleStyle="font-size: 28px;" />
<hgroup width="100%" cellVAlign="middle">
<label id="lblSubtitle" label="#(%page.Subtitle)#" width="80%"
labelStyle="font-size: 20px;" />

<select label="Agency" id="selAgency"
queryClass="%iKnow.Queries.MetadataQAPI" queryName="GetFieldValues"
onchange="zenPage.onChangeFilters();">
<parameter value="#(%page.Domain)#" />
<parameter value="Agency" />
</select>
<spacer width="10" />

<select label="Topic" id="selTopic"
queryClass="%iKnow.Matching.DictionaryQAPI" queryName="GetDictionaries"
onchange="zenPage.onChangeFilters();">
<parameter value="#(%page.Domain)#" />
</select>
<spacer width="10" />

<text onkeyup="zenPage.onTypeSearch(zenThis.getValue());return;" width="100" 
title="Enter iFind search string and press enter" label="Full-text search" />
<spacer width="10" />

<image src="deepsee/ds2_compose_44.png" enclosingStyle="padding-top:5px;"
   onclick="zen('modInput').show();" height="40" />
<spacer width="10" />
<image src="deepsee/ds2_house_44.png" enclosingStyle="padding-top:5px;"
   onclick="zenPage.reset();" height="40" />
</hgroup>
<spacer height="20" />

<tablePane id="tblSources" caption="Articles" rowSelect="false" showRowSelector="false"
sql="SELECT SourceId, ExternalId FROM NEWS_RESULTS.Sources" width="100%">
<column colName="ID" hidden="true" />
<column colName="ExternalId" hidden="true" />
<column header="Title" OnDrawCell="DrawSource" style="padding:5px; white-space:normal;" />
<column header="Agency" OnDrawCell="DrawSourceMeta" seed="Agency" />
<column header="Actions" OnDrawCell="DrawSourceActions" style="text-align:center;" />
</tablePane>

<hgroup width="100%" cellAlign="right">
<button caption="&lt;&lt;" onclick="zenPage.nextPage(-1);" />
<spacer width="5" />
<button caption="&gt;&gt;" onclick="zenPage.nextPage(+1);" />
</hgroup>

<modalGroup id="modArticle" >
<titleBox id="titArticle" />
<vgroup enclosingClass="articleText">
<html id="htmlArticle" OnDrawContent="DrawArticle" />
<hgroup cellAlign="right" width="100%" labelPosition="left">
<text title="Summary length" size="2" id="txtSummaryLength" onkeyup="zenPage.summarize();" />
<spacer width="20" />
<image src="deepsee/ds2_notepad_44.png" height="22" title="Indexing results"
	onclick="zenPage.goToUI('IndexingResults');" />
<spacer width="10" />
<image src="deepsee/ds2_palette_44.png" height="22" title="Matching results"
	onclick="zenPage.goToUI('MatchingResults');" />
</hgroup>
</vgroup>
</modalGroup>

<modalGroup id="modInput" labelPosition="left" cellStyle="padding-bottom:8px">
<titleBox title="Manual input" />
<text id="txtInputTitle" label="Title" size="50" />
<textarea id="txtInputText" cols="40" rows="10" label="Article" />
<hgroup cellAlign="right" width="100%">
<button caption="save" onclick="zenPage.submitInput();" />
</hgroup>
</modalGroup>

<modalGroup id="modMatches" >
<titleBox title="Matching results" />
<spacer height="10" />
<tablePane id="tblDictScores" 
queryClass="%iKnow.Matching.MatchingQAPI" queryName="GetTotalDictionaryScoresBySourceId">
<parameter value="#(%page.Domain)#" />
<parameter value="#(%page.SelectedSource)#" />
</tablePane>
</modalGroup>

</page>
}

/// Refreshes the contents of the main sources table based on the values of the different page
/// properties containing the current action, user selections and filter criteria
Method RefreshTables() As %Status [ ZenMethod ]
{
	set tSC = $$$OK, tTitle = ""
	try {
		kill ^News.Results.Sources
		
		// for iFind, we'll build the results from a SQL query
		if (..CurrentAction = "iFind") && (..IFindSearchString'="") {
			
			// try to identify whether this is a regular expression search
			set tSearchString = ..IFindSearchString
			set tSearchOption = $s($find(tSearchString,"["):4, 1:0)
			
			// build SQL query
			set tQuery = "INSERT INTO News_Results.Sources (SourceId, ExternalId, ResultId) " _
							"SELECT SourceId, ExternalId, SourceId FROM News.Article " _
							"WHERE %ID %FIND search_index(News.Article.TxtIdx, ?, ?)"
			set tTitle = "iFind search results for '"_tSearchString_"'"
			
			// append Agency filter condition, if any (we'll ignore topic filters)
			if (..Agency'="") {
				set tQuery = tQuery _ " AND Agency = '"_..Agency_"'"
				set tTitle = tTitle _ " (" _ ..Agency _ ")"
			}
			
			set tStatement = ##class(%SQL.Statement).%New()
			set tSC = tStatement.%Prepare(tQuery)
			
			do tStatement.%Execute(tSearchString, tSearchOption)
			quit
		}
		
		// create filter object (Module 3, exercise 4)
		set tFilter = ""
		if (..Agency'="") {
			set tFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(..Domain, "Agency", "=", ..Agency)
			set tTitle = " ("_..Agency_")"
		}
		
		// append a topic filter if required (Module 4, exercise 4)
		if (..Topic'="") {
			
			set tFilter2 = ##class(%iKnow.Filters.SimpleMatchFilter).%New(..Domain, ..Topic, 1)
			
			// combine filters
			if (tFilter="") {
				set tFilter = tFilter2
			} else {
				set tGrpFilter = ##class(%iKnow.Filters.GroupFilter).%New(..Domain, 1)
				do tGrpFilter.AddSubFilter(tFilter)
				do tGrpFilter.AddSubFilter(tFilter2)
				set tFilter = tGrpFilter
			}
			
			// retrieve dictionary name
			set tDict = ##class(%iKnow.Objects.Dictionary).PKINDEXOpen(..Domain, ..Topic)
			set tTitle = tTitle _ " ("_tDict.Name_")"
			
		}
		
		// populate sources table
		if (..Topic'="") && (tDict.Name = ..FavoritesDictionary) {
			
			set tSC = ##class(%iKnow.Matching.MatchingAPI).GetTopSourcesByDictionary("^News.Results.Sources", ..Domain, ..Topic, ..CurrentPage,, tFilter)
			set tTitle = "Favorite articles "_tTitle
			
		} elseif (..CurrentAction = "similarSources") && ..SelectedSource {
			
			set tSelSourceExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(..Domain, ..SelectedSource)
			set tSelSourceTitle = ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, "Title", tSelSourceExtId)
			
			// show the sources similar to ..SelectedSource (Module 3, exercise 4)
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetSimilar("^News.Results.Sources", ..Domain, ..SelectedSource, ..CurrentPage,, tFilter)
			set tTitle = "Articles related to ""<i>"_tSelSourceTitle_"</i>"""_tTitle
			
		} elseif (..CurrentAction = "byEntity") && ..SelectedEntity {
			
			// show the sources containing a particular entity (Module 3, exercise 6)
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntityIds("^News.Results.Sources", ..Domain, ..SelectedEntity, ..CurrentPage,, tFilter)
			set tTitle = "Articles containing ""<i>"_##class(%iKnow.Queries.EntityAPI).GetValue(..Domain, ..SelectedEntity)_"</i>"""_tTitle
			
		} else {
			
			// by default, just display the most recent articles
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByDomain("^News.Results.Sources", ..Domain, ..CurrentPage,, tFilter)
			set tTitle = "Recent articles"_tTitle
			
		}
		quit:$$$ISERR(tSC)
		
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:tTitle)
}

/// Draws the main characteristics of a source in the main table
Method DrawSource(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set tSourceId = %query("SourceId")
	set tExtId = %query("ExternalId")
	
	// by default, just output the article's title
	set tTitle = ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, "Title", tExtId)
	
	// if no title specified, take the first sentence
	if (tTitle="") {
		do ##class(%iKnow.Queries.SentenceAPI).GetBySource(.tSentences, ..Domain, tSourceId, 1, 1)
		set tTitle = $lg($g(tSentences(1)),2)
	}
	write "<span style=""white-space:normal;"">",tTitle,"</span>"
		
	// now write key entities / clusters (Module 3, exercise 6)
	//set tSC = ##class(%iKnow.Semantics.ProximityAPI).GetClustersBySource(.tEntities, ..Domain, tSourceId, 1, 5)
	//set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetProfileBySource(.tEntities, ..Domain, tSourceId, 1, 5, $$$SDCONCEPT)
	set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.tEntities, ..Domain, 1, 5, tSourceId)
	quit:$$$ISERR(tSC)
	if ($d(tEntities)) {
		write "<div class=""srcProfile"" >"
		set i = ""
		for {
			set i = $order(tEntities(i),1,tEntData)
			quit:i=""
			
			set tEntId = $li(tEntData,1)
			set tEntValue = $li(tEntData,2)
			
			// Gather related entities for this entity
			set tRelEntities = ""
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetRelatedById(.tRelEnts, ..Domain, tEntId, 1, 5)
			quit:$$$ISERR(tSC)
			set j = ""
			for {
				set j = $order(tRelEnts(j), 1, tRelEntData)
				quit:j=""
				set:j>1 tRelEntities = tRelEntities _ " - "
				set tRelEntities = tRelEntities _ $li(tRelEntData,2)
			}
		
			write:i>1 " -"
			write " <a title=""",tRelEntities,""" href=""javascript:zenPage.showByEntity(",tEntId,");"">", tEntValue, "</a>"
			
			// Display "add as favorite" button
			write:..FavoritesDictionary'="" "<a href=""#"" onclick=""zenPage.addFavorite('",tEntValue,"', 'entity');""><img src=""deepsee/ds2_star_44.png"" height=""15"" title=""Add as a favorite"" /></a>"
		}
		write "</div>"
	}
	
	quit $$$OK
}

/// Draws a metadata field (passed in through <var>pSeed</var>) for a source in the main table
Method DrawSourceMeta(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set tExtId = %query("ExternalId")
	
	write ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, pSeed, tExtId)
	
	quit $$$OK
}

/// Draws the action buttons for a source in the main table
Method DrawSourceActions(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set tExtId = %query("ExternalId"), tSrcId = %query("SourceId")
	
	write "<a href=""#"" onclick=""zenPage.readArticle(" _ tSrcId _ ");"" title=""Show article""><img src=""deepsee/ds2_glasses_44.png"" class=""action"" /></a>"
	write "&nbsp;&nbsp;<a href=""#"" onclick=""zenPage.showSimilar(" _ tSrcId _ ");"" title=""Show similar articles""><img src=""deepsee/ds2_radar_44.png"" class=""action"" /></a>"
	write "&nbsp;&nbsp;<a href=""#"" onclick=""zenPage.showMatches(" _ tSrcId _ ");"" title=""Show matches""><img src=""deepsee/ds2_palette_44.png"" class=""action"" /></a>"
	
	set tLink = ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, "Link", tExtId)
	if (tLink '= "") {
		write "&nbsp;&nbsp;<a href=""" _ tLink _ """ title=""Go to website""><img src=""deepsee/ds2_action_44.png"" class=""action"" /></a>"
	}
	
	if (..FavoritesDictionary'="") {
		write "&nbsp;&nbsp;<a href=""#"" onclick=""zenPage.addFavorite("_tSrcId_", 'source');"" title=""Add as favourite""><img src=""deepsee/ds2_star_44.png"" class=""action"" /></a>"
	}
	
	quit $$$OK
}

/// Display the article contents in the article reading popup
Method DrawArticle(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:'..SelectedSource
		
		// If a summary length is specified, display a summary instead (Module 3, exercise 6)
		if ('..SummaryLength) {
			set tSC = ##class(%iKnow.Queries.SentenceAPI).GetBySource(.tSentences, ..Domain, ..SelectedSource, 0, 0)
		} else {
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetSummary(.tSentences, ..Domain, ..SelectedSource, ..SummaryLength)
		}
		quit:$$$ISERR(tSC)
		
		// translate sentence IDs to positions (Module 4, exercise 3)
		set tSource = ##class(%iKnow.Objects.Source).PKINDEXOpen(..Domain, ..SelectedSource)
		for tSentPos = 1:1:tSource.FirstSentenceId+tSource.SentenceCount {
			set tSentId = tSource.FirstSentenceId + tSentPos - 1
			set tSentMap(tSentId) = tSentPos
		} // TODO: WHY?
		
		set:..SelectedEntity tHighlights("ENTITY", ..SelectedEntity) = "<b>"
		set tHighlights("MATCH") = "<span class=""matchF"">"
		set tHighlights("MATCH", "PARTIAL") = "<span class=""matchP"">"
		
		write "<p>"
		
		set i = ""
		for {
			set i = $order(tSentences(i), 1, tSentData)
			quit:i=""
			
			set tSentID = $li(tSentData,1)
			
			// Get the highlighted version of a sentence (Module 4, exercise 3)
			write !,##class(%iKnow.Queries.SentenceAPI).GetHighlighted(..Domain, tSentID, .tHighlights,,,.tSC)
			quit:$$$ISERR(tSC)
		}
		
		write "</p>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// This method is called by <method>submitInput</method> and will index the submitted text
/// <var>pText</var> using direct text loading.
Method IndexArticle(pTitle As %String, pText As %String) As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		
		// Process input text (Module 2, Exercise 4)
		set tSC = $system.iKnow.IndexString(..DomainName, pTitle, pText, ..InputConfig, 0, .tSourceId)
		quit:$$$ISERR(tSC)
		
		// Retrieve the External ID of the newly created source
		set tNewExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(..Domain, tSourceId)
		
		// Set appropriate metadata values (Module 3, Exercise 4)
		set tSC = ##class(%iKnow.Queries.MetadataAPI).SetValue(..Domain, "Title", tNewExtId, pTitle)
		quit:$$$ISERR(tSC)
		set tSC = ##class(%iKnow.Queries.MetadataAPI).SetValue(..Domain, "Agency", tNewExtId, "Manual input")
		quit:$$$ISERR(tSC)
		set tSC = ##class(%iKnow.Queries.MetadataAPI).SetValue(..Domain, "PubDate", tNewExtId, $horolog)
		quit:$$$ISERR(tSC)
		
		// Match the source (Module 4, Exercise 3)
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(..Domain, tSourceId)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:"OK")
}

/// Add favorite term to the Favorites dictionary, indexing all sources at the end
/// Module 4, exercise 5
Method AddFavoriteTerm(pTerm As %String, pMatch As %Boolean = 1) As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:..FavoritesDictionary=""
		set tURI = ":favorites:"_$$$LOWER(pTerm)
		
		// find the ID for the "My Favorites" dictionary and add pTerm as an item and term,
		/// using tURI as its URI
		set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(..Domain, ..FavoritesDictionary, .tSC)
		set:tDictId<=0 tDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionary(..Domain, ..FavoritesDictionary,,,, .tSC)
		quit:$$$ISERR(tSC)
		
		set tExists = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(..Domain, tURI, .tSC)
		quit:$$$ISERR(tSC)
		if 'tExists {
			set tDictItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItemAndTerm(..Domain, tDictId, pTerm, tURI,, .tSC)
			quit:$$$ISERR(tSC)
		}
		
		if (pMatch) {
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(..Domain)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:"OK")
}

/// Add the top entities in a whole source as favorite terms to the Favorites dictionary
/// Module 4, exercise 5
Method AddFavoriteSource(pSourceId As %Integer, pCount As %Integer = 5) As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:..FavoritesDictionary=""
		
		// find the top <pCount> entities for a source and add them to the favorites
		// dictionary using AddFavoriteTerm()
		set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.tEntities, ..Domain, 1, pCount, pSourceId)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tEntities(i), 1, tEntData)
			quit:i=""
			
			set tRes = ..AddFavoriteTerm($li(tEntData,2), 0)
			if (tRes'="OK") { set tSC = $$$ERROR($$$GeneralError, tRes) quit }
		}
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(..Domain)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISERR(tSC):$system.Status.GetErrorText(tSC), 1:"OK")
}

/// Ensure the main table is refreshed when opening the page a first time
Method %OnAfterCreatePage() As %Status
{
	do ..RefreshTables()
	Quit $$$OK
}

/// Utility method: return information about the current source as a proxy object
Method GetArticleInfo() As %ZEN.proxyObject [ ZenMethod ]
{
	set tObj = ##class(%ZEN.proxyObject).%New()
	set tObj.sourceId = ..SelectedSource
	set tObj.externalId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(..Domain, ..SelectedSource)
	set tObj.title = ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, "Title", tObj.externalId)
	set tObj.pubDate = ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, "PubDate", tObj.externalId)
	set tObj.Agency = ##class(%iKnow.Queries.MetadataAPI).GetValue(..Domain, "Agency", tObj.externalId)
	quit tObj
}

/// Resets the current action
ClientMethod reset() [ Language = javascript ]
{
	var sc = zenPage.setProperty('CurrentAction', '');
	sc = zenPage.setProperty('Agency', '');
	sc = zenPage.setProperty('Topic', '');
	sc = zenPage.setProperty('CurrentPage', 1);
	sc = zenPage.setProperty('IFindSearchString', '');
	zen('selAgency').setValue('');
	zen('selTopic').setValue('');
	zenPage.refreshAll();
}

/// Triggers the "similarSources" action
ClientMethod showSimilar(srcId) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedSource', srcId);
	sc = zenPage.setProperty('CurrentPage', 1);
	sc = zenPage.setProperty('CurrentAction', 'similarSources');
	zenPage.refreshAll();
}

/// Triggers the "byEntity" action
ClientMethod showByEntity(entId) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedEntity', entId);
	sc = zenPage.setProperty('CurrentPage', 1);
	sc = zenPage.setProperty('CurrentAction', 'byEntity');
	zenPage.refreshAll();
}

/// Browse to the next page
ClientMethod nextPage(direction) [ Language = javascript ]
{
	var page = parseInt(zenPage.getProperty('CurrentPage')) + direction;
	if (page<=0) { page = 1 }
	var sc = zenPage.setProperty('CurrentPage', page);
	zenPage.refreshAll();
}

/// Opens the article reading popup
ClientMethod readArticle(srcId) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedSource', srcId);
	var obj = zenPage.GetArticleInfo();
	zen('titArticle').setProperty('title', obj.title);
	zen('titArticle').refreshContents();
	zen('htmlArticle').refreshContents();
	zen('modArticle').show();
}

/// Opens the matches detail popup
ClientMethod showMatches(srcId) [ Language = javascript ]
{
	var sc = zenPage.setProperty('SelectedSource', srcId);
	zen('tblDictScores').refreshContents();
	zen('modMatches').show();
}

/// In the article reading pane, refresh the article to display a summary of the selected length
ClientMethod summarize() [ Language = javascript ]
{
	var sc = zenPage.setProperty('SummaryLength', zen('txtSummaryLength').getValue());
	zen('htmlArticle').refreshContents();
}

/// This method is called when manual input is being submitted
ClientMethod submitInput() [ Language = javascript ]
{
	var title = zen('txtInputTitle').getValue();
	var text = zen('txtInputText').getValue();
	var sc = zenPage.IndexArticle(title, text);
	if (sc != 'OK') { alert(sc); }
	zenPage.endModal();
	zenPage.refreshAll();
}

/// Drives adding favourites
ClientMethod addFavorite(favorite, type) [ Language = javascript ]
{
	if (type == 'entity') {
		var sc = zenPage.AddFavoriteTerm(favorite, 1);
	} else {
		var sc = zenPage.AddFavoriteSource(favorite);
	}
	if (sc != 'OK') { alert(sc); }
	zenPage.refreshAll();
}

/// Utility method: refresh current view based on current filter values
ClientMethod onChangeFilters() [ Language = javascript ]
{
	var sc = zenPage.setProperty('Agency', zen('selAgency').getValue());
	var sc = zenPage.setProperty('Topic', zen('selTopic').getValue());
	zenPage.refreshAll();
}

/// Utility method: refresh the main sources table and page subtitle
ClientMethod refreshAll() [ Language = javascript ]
{
	var title = zenPage.RefreshTables();
	zen('lblSubtitle').setProperty('label', title);
	zen('tblSources').refreshContents();
}

/// Utility method: browse to a %iKnow.UI page
ClientMethod goToUI(page) [ Language = javascript ]
{
	var url = '_iKnow.UI.'+page+'.zen?&domain=' + zenPage.Domain + '&source=' + zenPage.SelectedSource;
	location.href = url;
}

/// Utility method: launch iFind search from the search box
ClientMethod onTypeSearch(text) [ Language = javascript ]
{
	if (zenEvent && ((zenEvent.keyCode==13) || (zenEvent.which==13))) {
		var sc = zenPage.setProperty('IFindSearchString', text);
		sc = zenPage.setProperty('CurrentAction', 'iFind');
		zenPage.refreshAll();
	}
	return true;
}

/// Additional CSS styling for this page
XData Style
{
<style type="text/css">
body {
	padding: 20px;
	font-family: Calibri, Verdana;
}

.tpAction a:link {
	color: #A00000;
	text-decoration: none;
}
.tpAction a:hover {
	text-decoration: underline;
}

img.action {
	height: 22px;
}

.articleText {
	margin-top: 10px;
	margin-bottom: 10px;
	padding: 10px;
	border: 1px solid black;
	background: #ffffff;
}

.articleText p {
	margin-top: 10px;
	line-height: 1.3;
}

.matchF {
	border: 2px solid #FF9966;
	padding-right: 2px;
	padding-left: 2px;
	background: #FF9966;
}
.matchP {
	border: 2px solid #FF9966;
	padding-right: 2px;
	padding-left: 2px;
}

.srcProfile {
	margin-top: 10px;
	text-align: right;
	white-space: normal;
}

</style>
}

}

