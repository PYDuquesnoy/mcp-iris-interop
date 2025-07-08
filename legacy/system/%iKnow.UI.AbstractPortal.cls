/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKPublic, %IKInclude)

/// <p>This is the base class for the sample iKnow Portal pages, which is available to be subclassed
/// by custom Zen pages exposing iKnow content and/or functionality. Some of the convenience services
/// provided by this page include:</p>
/// <ul>
/// 		<li>methods and widgets to select and manage a 'current' domain, source and term for the session, which can be used by queries and operations on this page.</li>
/// 		<li>a pane featuring a modalGroup widget for the user to specify a filter based on metadata criteria (showing all visible metadat fields for the current domain).</li>
/// 		<li>utility methods to page through results from iKnow queries.</li>
/// </ul>
Class %iKnow.UI.AbstractPortal Extends Styles [ Abstract, Deprecated, System = 4 ]
{

/// If true, auto-switch namespace to whatever $NAMESPACE is passed in.
Parameter AUTONS = 1;

Parameter APPLICATION;

Parameter DOMAIN = "%iKnow";

/// All pages in <package>%iKnow.UI</package> require at least the %Development resource
Parameter RESOURCE = "%Development";

Property domain As %ZEN.Datatype.integer(ZENURL = "domain");

Property term As %ZEN.Datatype.string(ZENURL = "string");

Property source As %ZEN.Datatype.integer(ZENURL = "source");

Property filter As %ZEN.Datatype.string(ZENURL = "filter");

Property filtermode As %ZEN.Datatype.integer(ZENURL = "filtermode") [ InitialExpression = {$$$FILTERALLANDSORT} ];

Property skiplists As %ZEN.Datatype.string(ZENURL = "skiplists");

Property languageMode As %ZEN.Datatype.string(VALUELIST = ",en,ja", ZENURL = "langmode") [ InitialExpression = "en" ];

/// Simple pane containing the iKnow logo
XData logoPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup width="100%">
<!-- <image src="/csp/sys/iknow/img/iknow.jpg" height="70" id="imgLogoPane" /> -->
<image src="portal/InterSystems IRIS.png" height="50" id="imgLogoPane" />
</hgroup>
</pane>
}

/// Initializes some of the panes and session variables used by this page, fetching domain, 
/// source and term variables from the request (if present).
/// If certain activities need to be performed in a subclass, override
/// <method>OnAfterCreatePage</method> rather than this method.
Method %OnAfterCreatePage() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##super()
		quit:$$$ISERR(tSC)
	
		// populate optDomain
		set tOptDomain = ..%GetComponentById("optDomain")
		if $isobject(tOptDomain) {
			set tResult = ##class(%ResultSet).%New("%iKnow.Domain:GetAllDomains")
			set tSC = tResult.%Execute()
			quit:$$$ISERR(tSC)
			
			set tValueList = "", tDisplayList = ""
			while tResult.%Next(.tSC) {
				quit:$$$ISERR(tSC)
				set tURL = "?$NAMESPACE=" _ tResult.%Get("namespace") _ "&domain=" _ tResult.%Get("domainId")
				set tValueList = tValueList _ $s(tValueList="":"", 1:",") _ tURL
				set tDisplayList = tDisplayList _ $s(tDisplayList="":"", 1:",") _ tResult.%Get("domainName")
			}
			quit:$$$ISERR(tSC)
			set tOptDomain.displayList = tDisplayList
			set tOptDomain.valueList = tValueList
			k tResult
		}
		
		// initialize paged components starting page
		set tSC = ..InitPages()
		quit:$$$ISERR(tSC)
		
		// initialize domain
		set:'..domain ..domain = +$o(^IRIS.IK.SrcId(""))
		set:$system.iKnow.GetDomainName(..domain)="" ..domain = ""
		if (..domain) {
			
			// if we have a domain, it's OK to populate the optSource list
			set tOptSource = ..%GetComponentById("optSource")
			if $isobject(tOptSource) {
				set tOptSource.queryClass = "%iKnow.Queries.SourceQAPI"
				set tOptSource.queryName = "GetByDomain"
			}
			
			set tSC = ..OnUpdateDomain(..domain)
			quit:$$$ISERR(tSC)
			set:$isobject(tOptDomain) tOptDomain.value = "?$NAMESPACE="_$namespace_"&domain="_..domain
		}
	
		// initialize term
		if (..term'="") {
			set tSC = ..UpdateTerm(..term)
			quit:$$$ISERR(tSC)
			do:..%GetComponentById("txtTerm")'="" ..%SetValueById("txtTerm", ..term)
		}
	
		// initialize source
		if (..source) {
			set tSC = ..UpdateSource(..source)
			quit:$$$ISERR(tSC)
			do:..%GetComponentById("optSource")'="" ..%SetValueById("optSource", ..source)
		}
		set %session.Data("pageoptSource") = 1
	
		// initialize filter parameters
		set ..filtermode = $$$FILTERALLANDSORT
		set tSC = ..OnUpdateFilter()
		quit:$$$ISERR(tSC)
	
		// initialize info panel
		set tSC = ..BuildInfoPane()
		quit:$$$ISERR(tSC)
		
		// enable skiplists button if there are any
		set tBtnSkiplists = ..%GetComponentById("btnSkiplists")
		if (tBtnSkiplists'="") {
			set tHasXDom = ##class(%iKnow.Utils.MaintenanceAPI).HasSkipLists(0)
			set tSC = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipLists(.tResult, +..domain, tHasXDom)
			quit:$$$ISERR(tSC)
			if $o(tResult("")) {
				set tBtnSkiplists.disabled = 0, i="", tValueList="", tDisplayList=""
				for {
					set i = $order(tResult(i),1,tData)
					quit:i=""
					set tValueList = tValueList _ "," _ $li(tData,1)
					set tDisplayList = tDisplayList _ "," _ $li(tData,2) 
					set:($li(tData,1)<0) tDisplayList = tDisplayList _ " *"
				}
				set ..%GetComponentById("selSkiplists").valueList = $e(tValueList,2,*)
				set ..%GetComponentById("selSkiplists").displayList = $e(tDisplayList,2,*)
				set:tHasXDom ..%GetComponentById("lblXDomainBL").hidden = 0
			}
			
			set:(..skiplists'="") tBtnSkiplists.caption = "skiplists*"
		}
		
		// enable metadata filters
		set tMetaFields = ..%GetComponentById("selFilterMDField")
		if $isobject(tMetaFields) && ..domain {
			set tMetadataAPI = $$$GETPARAM(..domain,$$$IKPMETADATAAPI,$$$IKPDEFMETADATAAPI)
			set tSC = $classmethod(tMetadataAPI, "GetFields", .tResult, ..domain)
			quit:$$$ISERR(tSC)
			set i = "", tMetaFieldIds = "", tMetaFieldNames = ""
			for {
				set i = $order(tResult(i), 1, tFieldData)
				quit:i=""
				set tMetaFieldIds = $s(tMetaFieldIds="":"", 1:tMetaFieldIds_",") _ $li(tFieldData,1)
				set tMetaFieldNames = $s(tMetaFieldNames="":"", 1:tMetaFieldNames_",") _ $li(tFieldData,2)
			}
			set tMetaFields.valueList = tMetaFieldIds
			set tMetaFields.displayList = tMetaFieldNames
		}
		
		// enable DeepSee domain specific filters
		if $$$GETPARAMNODEF(+..domain,$$$IKPDEEPSEEDOMAIN) {
			set selFilterTypes = ..%GetComponentById("selFilterType")
			if (selFilterTypes '= "") {
				set selFilterTypes.valueList = selFilterTypes.valueList _ ",deepsee,mdx"
				set selFilterTypes.displayList = selFilterTypes.displayList _ ",DS dimensions,MDX"
				
				set selFilterDSDims = ..%GetComponentById("selFilterDSDims")
				set cubeName = $$$GETPARAMNODEF(+..domain,$$$IKPDSCUBE)
				if (selFilterDSDims'="") && (cubeName'="") {
					do ##class(%DeepSee.Utils).%GetCubeLevels(cubeName,.levels)
					set i="", valueList="", displayList=""
					for {
						set i = $order(levels(i),1,level)
						quit:i=""
						continue:$li(level,1)'="l"
						set valueList = valueList _ ",[" _ $lts($li(level,2,4),"].[") _ "]"
						do ##class(%DeepSee.Utils).%GetMemberCaption(cubeName,$li(level,2),,,.d)
						do ##class(%DeepSee.Utils).%GetMemberCaption(cubeName,$li(level,2),$li(level,3),,.h)
						do ##class(%DeepSee.Utils).%GetMemberCaption(cubeName,$li(level,2),$li(level,3),$li(level,4),.l)
						set displayList = displayList _ "," _ d _ " > " _ h _ " > " _ l
					}
					set selFilterDSDims.valueList = $e(valueList,2,*)
					set selFilterDSDims.displayList = $e(displayList,2,*)
				}
			}
		}
		quit:$$$ISERR(tSC)
		
		
		// BDB526 - check if we can derive the language mode from the default configuration
		if '$d(%request.Data("langmode",1)) {
			set tDefaultConfig = $$$GETPARAM(+..domain,$$$IKPDEFAULTCONFIG,$$$DEFAULTCONFIG)
			set tDefaultConfig = ##class(%iKnow.Configuration).NameIndexOpen(tDefaultConfig)
			if $isobject(tDefaultConfig) && $ls(tDefaultConfig.Languages,$lb("ja")) {
				set ..languageMode = "ja"
			}
		}
		set tSC = ..OnChangeLanguageMode()
		quit:$$$ISERR(tSC)
		
		
		set tSC = ..OnAfterCreatePage()
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method OnAfterCreatePage() As %Status
{
	quit $$$OK
}

/// Utility method to avoid executing queries when no domain is specified (which could lead to
/// noisy errors in the UI).
Method ExecuteQuery(pRS As %Library.ResultSet, ByRef tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	merge p = pInfo.parms
	set:'p(1) p(1) = ..domain
	quit:'p(1) 1
	
	set p = $o(p(""),-1)
	set tSC = pRS.Execute(p...)
	
	quit 1
}

/// Same as ExecuteQuery, but will use the system domain (ID=0) if ..source<0
Method ExecuteQuerySys(pRS As %Library.ResultSet, ByRef tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	merge p = pInfo.parms
	set p(1) = $s(..source<0:0, 1:..domain)
	set p = $o(p(""),-1)
	set tSC = pRS.Execute(p...)
	quit 1
}

/// Utility method to end the session from the client.
Method EndSession() As %Status [ Final, ZenMethod ]
{
	do %session.Kill()
	quit $$$OK
}

/// Simple pane containing a dropdown field with all domains in the current instance. Selecting a
/// domain will reload the page in the namespace of the selected domain, with the domain=# as a 
/// URL parameter to be picked up by <method>%OnAfterCreatePage</method>.
/// <p>Selecting a domain from this list will update the "current domain" selection and trigger
/// <method>updateDomainClient</method>.</p>
XData optDomainPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<select id="optDomain" required="true" onchange="location.href = zen('optDomain').getValue();" />
</pane>
}

/// Returns the currently selected domain ID.
/// <p>NOTE: this method is deprecated. Please access <property>domain</property> directly instead.</p>
Method GetDomain() As %Integer [ Deprecated, Final, Internal, ZenMethod ]
{
	quit ..domain
}

/// ZenMethod to take appropriate cleanup action if the domain is updated. Will in turn call 
/// <method>OnUpdateDomain</method>, which can be overridden by subclasses.
Method UpdateDomain(domainId As %Integer) As %Status [ Final, ZenMethod ]
{
	set ..domain = domainId
	set ..source = "", ..filter = "", ..skiplists = ""
	do ..ResetPages()
	quit ..OnUpdateDomain(domainId)
}

/// This method can be overridden at the subclass level to take any additional server-side
/// actions when the domain is changed.
Method OnUpdateDomain(domainId As %Integer) As %Status
{
	quit $$$OK
}

/// <p>Auto-complete field linked to the GetSimilar query in <class>%iKnow.Queries.EntityQAPI</class>,
/// which will provide all entities similar to the entered string in the current domain as 
/// auto-complete suggestions.</p>
/// <p>Selecting a value from this list of suggestions, pressing enter or clicking the start button
/// displayed next to the intput field will update the "current term" and trigger
/// <method>updateTermClient</method>.</p>
XData txtTermPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup>
<label label="Start from: " width="200" />
<assistedText id="txtTerm" name="txtTerm" controlType="custom" onUpdateDataClient="zenPage.inputTermClient(base)"
  	onchange="zenPage.updateTermClient();return;" isSuggestedDataComplete="true"  
  	triggerChars="" controlWidth="200px" hideGhost="true" onkeyup="zenPage.onTermKeyUp();return;" />
<spacer width="5" />
<button caption="start" onclick="zenPage.updateTermClient();return;" />
</hgroup>
</pane>
}

Method InputTerm(pBase As %String) As %String [ ZenMethod ]
{
	set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.tResult, ..domain, pBase,,, ..GetCurrentFilterObject(), ..filtermode)
	quit:$$$ISERR(tSC) ""
	
	set tResultString = "", i="", tBaseLength = $length(pBase)
	for {
		set i = $order(tResult(i),1,tData)
		quit:i=""
		//set tResultString = tResultString_","_$e($li(tData,2),tBaseLength+1,*)
		set tResultString = tResultString_","_$li(tData,2)
	}
	quit tResultString
}

ClientMethod inputTermClient(text) [ Language = javascript ]
{
	// clear timeout if running
	//if (this.inputTermTimer != null) {
	//	clearTimeout(this.inputTermTimer);
	//}
	
	// quit if input string is too short
	if ((text == null) || (text.length < 3))
		return '';
		
	return zenPage.InputTerm(text);
	
	// set timeout
	//this.inputTermTimer = setTimeout(function() { zenPage.inputTermDeferred(text); }, 1000);
	//return '';
}

ClientMethod inputTermDeferred(text) [ Language = javascript ]
{
	var assistedText = zen('txtTerm');
	var data = zenPage.InputTerm(text);
	if ((data == null) || (data.length <= 1)) {
		return;
	}
	assistedText.propertyListFiltered = new Array();
	assistedText.separator = data.charAt(0);
	assistedText.propertyListFiltered = data.substr(1).split(data.charAt(0));
	
	if (assistedText.iFrameCreated) {
		assistedText.findElement("selectorIFrame").style.display = "block";
	}
	assistedText.setSelectorStyle();
	assistedText.findElement("selector").style.display = "block";
		
	assistedText.deferredComboUpdate();
}

/// Returns the currently selected term.
/// <p>NOTE: this method is deprecated. Please access <property>term</property> directly instead.</p>
Method GetTerm() As %String [ Deprecated, Final, Internal, ZenMethod ]
{
	quit ..term
}

/// Client-side method which will explicitly select a certain term, updating the txtTerm input field in
/// <xdata>txtTermPane</xdata> and then call <method>updateTermClient</method>.
ClientMethod useTermClient(term) [ Final, Language = javascript ]
{
	var sc = zen("txtTerm").setValue(term);
	this.updateTermClient(term);
}

/// Client-side method to be called when the user selects a new term, which will call 
/// <method>UpdateTerm</method> and <method>onUpdateTermClient</method>.
ClientMethod updateTermClient(term) [ Final, Language = javascript ]
{
	if ((term == null) || (term == ''))
		term = zenPage.getComponentById('txtTerm').value;
		
	var sc = zenPage.ResetPages();
	sc = zenPage.UpdateTerm(term);
	zenPage.onUpdateTermClient(term);
}

/// Client-side method subclasses can override to take additional actions when the user selects
/// a new term.
ClientMethod onUpdateTermClient(term) [ Language = javascript ]
{
}

/// Key capture method to trigger <method>updateTermClient</method> when the enter key is pressed.
ClientMethod onTermKeyUp() [ Language = javascript ]
{
	if (zenEvent && ((zenEvent.keyCode==13) || (zenEvent.which==13))) {
		zenPage.updateTermClient();
	}
	return true;
}

/// ZenMethod taking appropriate server-side cleanup and update actions when a new term is selected.
/// Calls <method>OnUpdateTerm</method> afterwards.
Method UpdateTerm(term As %String) As %Status [ Final, ZenMethod ]
{
	set ..term = term
	quit ..OnUpdateTerm(term)
}

/// Server-side methods subclasses can override to take additional actions when the user selects
/// a new term.
Method OnUpdateTerm(term As %String) As %Status
{
	quit $$$OK
}

/// Utility method to return the "current page" stored in the session for the supplied component
/// name, or 1 if no page was registered so far.
Method GetPage(componentName As %String) As %Integer [ Final ]
{
	quit $g(%session.Data("page"_componentName), 1)
}

/// Client-side method to trigger a components query to be re-executed for the next page of results.
ClientMethod nextPageClient(componentName) As %Status [ Final, Language = javascript ]
{
	var p = zenPage.NextPage(componentName);
	zen(componentName).refreshContents();
}

/// Updates the current page for the supplied component to the next integer value.
Method NextPage(componentName As %String) As %Integer [ Final, ZenMethod ]
{
	set p = ..GetPage(componentName)+1
	set %session.Data("page"_componentName) = p
	quit p
}

/// Client-side method to trigger a components query to be re-executed for the previous page of results.
ClientMethod previousPageClient(componentName) As %Status [ Final, Language = javascript ]
{
	zenPage.PreviousPage(componentName);
	zen(componentName).refreshContents();
}

/// Updates the current page for the supplied component to the previous integer value (minimum value is 1).
Method PreviousPage(componentName As %String) As %Integer [ Final, ZenMethod ]
{
	set p = ..GetPage(componentName)-1
	set:p<=0 p = 1
	set %session.Data("page"_componentName) = p
	quit p
}

/// This method should to be implemented by subclasses using the paging functions, giving all paged
/// components a meaningful initial page value (usually 1).
Method InitPages() As %Status
{
	set %session.Data("pageoptSources") = 1
	quit $$$OK
}

/// Resets all page information in the session.
Method ResetPages() As %Integer [ ZenMethod ]
{
	set pageName = "page"
	for {
		set pageName = $o(%session.Data(pageName))
		quit:pageName=""
		quit:$extract(pageName,1,4)'="page"
		
		set %session.Data(pageName) = 1
	}
	quit 1
}

/// <p>Simple pane containing a dropdown list of the 100 most recent sources (trough the GetByDomain 
/// query in <method>%iKnow.Queries.SoureQAPI</method>) and buttons to page through more results.</p>
/// <p>Selecting a source from this list will update the "current source" selection and triggger
/// <method>updateSourceClient</method>.</p>
XData optSourcePane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup>
<select id="optSource" required="true" onchange="zenPage.updateSourceClient();" >
<parameter value="#(%page.domain)#" />
<parameter value="#(%session.pageoptSource)#" />
<parameter value="100" />
</select>
<spacer width="10" />
<button caption="&lt;&lt;" onclick="javascript:zenPage.previousPageClient('optSource');" />
<button caption="&gt;&gt;" onclick="javascript:zenPage.nextPageClient('optSource');" />
</hgroup>
</pane>
}

/// Returns the currently selected source ID.
/// <p>NOTE: this method is deprecated. Please access <property>source</property> directly instead.</p>
Method GetSource() As %Integer [ Deprecated, Final, ZenMethod ]
{
	quit ..source
}

Method GetSourceDomainId() As %Integer [ Private ]
{
	quit $s(..source>0:+..domain, 1:0)
}

/// Returns the currently selected source as a <class>%iKnow.Objects.Source</class> or
/// <class>%iKnow.Objects.VirtualSource</class> object.
Method GetSourceObject() As %iKnow.Objects.Source [ Final ]
{
	quit:'..source ""
	if (..source > 0) {
		quit ##class(%iKnow.Objects.Source).PKINDEXOpen(..domain, ..source)
	} else {
		quit ##class(%iKnow.Objects.VirtualSource).PKINDEXOpen(..GetSourceDomainId(), -..source)
	}
}

/// Server-side method updating the source pointers and taking any other appropriate actions. Invokes
/// <method>OnUpdateSource</method> afterwards.
Method UpdateSource(sourceId As %Integer) As %Status [ Final, ZenMethod ]
{
	set ..source = sourceId
	
	// BDB526 - update language mode if not hardcoded through URL
	if '$d(%request.Data("langmode",1)) {
		set tLanguage = ##class(%iKnow.Queries.SourceAPI).GetTopLanguage(..GetSourceDomainId(), sourceId, .tConfidence)
		set ..languageMode = $case(tLanguage, "ja":"ja", :"en")
		set tSC = ..OnChangeLanguageMode()
		quit:$$$ISERR(tSC) tSC
	}
	
	quit ..OnUpdateSource(sourceId)
}

/// This method is called whenever the language mode changes, as part of <method>UpdateSource</method>
/// or <method>%OnAfterCreatePage</method>
Method OnChangeLanguageMode() As %Status
{
	quit $$$OK
}

/// Server-side method subclasses can override to take additional actions upon a change in the
/// current source.
Method OnUpdateSource(sourceId As %Integer) As %Status
{
	quit $$$OK
}

/// Client-side method updating the source pointers and taking any other appropriate actions. In turn
/// invokes <method>Updatesource</method> and <method>onUpdateSourceClient</method>.
ClientMethod updateSourceClient(source) [ Final, Language = javascript ]
{
	if (source == null)
		source = zenPage.getComponentById('optSource').value;
		
	if ((source == null) || (source == 0)) return;
	
	var sc = zenPage.UpdateSource(source);
	zenPage.onUpdateSourceClient(source);
}

/// Client-side method subclasses can override to take additional actions upon a change in the
/// current source.
ClientMethod onUpdateSourceClient(source) [ Language = javascript ]
{
}

/// This pane contains a modalGroup popup window displaying the current filter and form fields
/// to add additional filter criteria. Clicking the filter button will invoke <method>updateFilterClient</method>.
XData filterPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<button id="btnFilters" caption="filters" onclick="zenPage.showFilterForm();" />
<modalGroup id="popFilter" width="400" onhideGroup="zen('selFilterType').setValue('');return;" >
<vgroup width="100%">
<titleBox title="Current filters" />
<spacer height="10" />
<hidden id="hidFilterGroup" value="0" />
<html id="htmlCurrentFilters" OnDrawContent="DrawFilter" seed="MANAGE" />
<spacer height="20" />
<titleBox title="Add filter" />
<spacer height="10" />
<vgroup labelPosition="left" width="100%" id="grpFilterForm" >
<select id="selFilterType" label="Filter type" valueList="metadata,extid,sql,srcid,matching,entity" 
displayList="Metadata,External IDs,SQL Query,Source IDs,Matching results,Contains entity"
showEmpty="true" originalValue="extid" required="" 
hint="Select a filter type to see relevant options"
onchange="zenPage.changeFilterTypeClient();return;" />
 
 <!-- metadata filters -->
<select id="selFilterMDField" label="Field" required="true" hidden="true"
onchange="zenPage.changeFilterMDFieldClient();return;" />
<select id="selFilterMDOp" label="Operator" showEmpty="false" hidden="true"
onchange="zenPage.changeFilterMDOpClient();return;" />
<text id="txtFilterMDValue" label="Value" hidden="true" />
<text id="txtFilterMDValue2" label="Value 2" disabled="true" hidden="true" />
<dateText id="datFilterMDValue" label="Value" hidden="true" />
<dateText id="datFilterMDValue2" label="Value 2" hidden="true" disabled="true" />
<select id="selFilterMDValue" label="Value" hidden="true" showEmpty="false"
  queryClass="%iKnow.Queries.MetadataQAPI" queryName="GetFieldValuesById" >
  <parameter value="#(%page.domain)#" />
  <parameter value="1" />
  <parameter value="0" />
  <parameter value="0" />
</select>
<select id="selFilterMDValue2" label="Value 2" hidden="true" disabled="true" showEmpty="false"
  queryClass="%iKnow.Queries.MetadataQAPI" queryName="GetFieldValuesById" >
  <parameter value="#(%page.domain)#" />
  <parameter value="1" />
  <parameter value="0" />
  <parameter value="0" />
</select>

 <!-- SqlFilter fields -->
<textarea id="txtFilterSQL" label="SQL query" hidden="true" rows="5" cols="50" />
 
 <!-- SourceIDFilter fields -->
<text id="txtFilterSrcIds" label="Source IDs" hidden="true" />
 
 <!-- ExternalIDFilter fields -->
<text id="txtFilterExtIds" label="External IDs" hidden="true" />
 
 <!-- DictionaryMatchFilter fields -->
<select id="selFilterMatchDicts" label="Dictionary" hidden="true"
 queryClass="%iKnow.Matching.DictionaryQAPI" queryName="GetDictionaries">
<parameter value="#(%page.domain)#" />
</select>
<text id="txtFilterMatchMin" label="Minimum" hidden="true" value="-1" />
<text id="txtFilterMatchMax" label="Maximum" hidden="true" value="-1" />
<select id="selFilterMatchMetric" label="Metric" hidden="true" showEmpty="false"
valueList="COUNT,SCORE" displayList="count,score"/>

 <!-- MDXFilter fields -->
<textarea id="txtFilterMDX" label="MDX where clause" hidden="true" rows="5" cols="50" />

<!-- DeepSee fields -->
<select id="selFilterDSDims" label="Dimension" hidden="true" 
  onchange="zenPage.changeFilterDSDimFieldClient();return;" />
<select id="selFilterDSValue" label="Member" hidden="true" />
 
 <!-- Contains Entity fields -->
 <text id="txtFilterEntity" label="String" hidden="true" />
 <checkbox id="chkFilterEntitySimilar" label="Include similar entitites" hidden="true" />
 
<button id="btnAddFilter" onclick="zenPage.addFilterClient();return;" caption="add" />
</vgroup>
<spacer height="20" />
<titleBox title="Filter mode" />
<spacer height="10" />
<label label="Recalculate: " />
<multiSelectSet id="mdFilterMode" valueList="frequency,spread,order" layout="horizontal" value="frequency,spread,order" />
<hgroup width="100%">
<button onclick="zenPage.updateFilterClient();return;" caption="close" />
<button onclick="zenPage.clearFilterClient();return;" caption="clear" />
</hgroup>
</vgroup>
</modalGroup>
</pane>
}

/// Simple pane reflecting the number of sources satisfying the current filter.
XData filterCountPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<label id="lblFilterCount" title="Number of sources selected" width="100" />
</pane>
}

ClientMethod changeFilterTypeClient() [ Language = javascript ]
{
	var type = zen('selFilterType').getValue()
	var sc = zenPage.ChangeFilterType(type);
	zen('grpFilterForm').refreshContents();
	if (type == "metadata") {
		zenPage.changeFilterMDFieldClient();
	}
}

Method ChangeFilterType(pFilterType As %String) As %Status [ ZenMethod ]
{
	set tControls = $lb("selFilterType","btnAddFilter") _
		$case(pFilterType, "metadata":$lb("selFilterMDField", "selFilterMDOp", "txtFilterMDValue", "txtFilterMDValue2"),
							"srcid":$lb("txtFilterSrcIds"), 
							"extid":$lb("txtFilterExtIds"),
							"sql":$lb("txtFilterSQL"),
							"matching":$lb("selFilterMatchDicts","txtFilterMatchMin","txtFilterMatchMax","selFilterMatchMetric"),
							"mdx":$lb("txtFilterMDX"),
							"deepsee":$lb("selFilterDSDims","selFilterDSValue"),
							"entity":$lb("txtFilterEntity","chkFilterEntitySimilar"),
							:$lb())
	
	set tChildren = ..%GetComponentById("grpFilterForm").children
	for i=1:1:tChildren.Count() {
		set tChild = tChildren.GetAt(i)
		set tChild.hidden = '$lf(tControls, tChild.id)
	}
	quit $$$OK
}

ClientMethod changeFilterMDFieldClient() [ Language = javascript ]
{
	var field = zen('selFilterMDField').getValue();
	if ((field == null) || (field == "")) return;
	var sc = zenPage.ChangeFilterMDField(field);
	zenPage.changeFilterMDOpClient();
}

ClientMethod changeFilterMDOpClient() [ Language = javascript ]
{
	var sc = zenPage.ChangeFilterMDOp(zen('selFilterMDOp').getValue());
	zenPage.refreshMDFilterFields();
}

ClientMethod changeFilterDSDimFieldClient() [ Language = javascript ]
{
	var sc = zenPage.ChangeFilterDSDimField(zen('selFilterDSDims').getValue());
	zen('selFilterDSValue').refreshContents();
}

Method ChangeFilterDSDimField(pDimSpec As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tCubeName = $$$GETPARAM(..domain,$$$IKPDSCUBE,"")
		set tSC = ##class(%DeepSee.Utils).%GetDimensionMembers(tCubeName, pDimSpec,, .tMembers)
		quit:$$$ISERR(tSC)
		
		set i="", tValues="", tDisplay=""
		for {
			set i = $order(tMembers(i),1,tMember)
			quit:i=""
			
			set tValues = tValues_","_$lg(tMember,1)
			set tDisplay = tDisplay_","_$lg(tMember,2)
		}
		
		set tSelect = ..%GetComponentById("selFilterDSValue")
		set tSelect.valueList = $e(tValues,2,*), tSelect.displayList = $e(tDisplay,2,*)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod refreshMDFilterFields() [ Language = javascript ]
{
	zen('grpFilterForm').refreshContents();
	zen('selFilterMDOp').refreshContents();
	zen('txtFilterMDValue').refreshContents();
	zen('txtFilterMDValue2').refreshContents();
	zen('datFilterMDValue').refreshContents();
	zen('datFilterMDValue2').refreshContents();
	zen('selFilterMDValue').refreshContents();
	zen('selFilterMDValue2').refreshContents();
}

Method ChangeFilterMDField(pFieldId As %Integer) As %Status [ ZenMethod ]
{
	set tMetadataAPI = $$$GETPARAM(..domain,$$$IKPMETADATAAPI,$$$IKPDEFMETADATAAPI)
	set tSC = $classmethod(tMetadataAPI, "GetFieldInfoById", ..domain, pFieldId, .tInfo)
	quit:$$$ISERR(tSC)
	set ..%GetComponentById("selFilterMDOp").valueList = $g(tInfo("SupportedOperators"),$$$MDOPEQUAL)
	
	set tIsDate = ($g(tInfo("DataType"))=$$$MDDTDATE)
	
	if ($g(tInfo("HasBitstringStorage"))) {
		set ..%GetComponentById("txtFilterMDValue").hidden = 1
		set ..%GetComponentById("txtFilterMDValue2").hidden = 1
		set ..%GetComponentById("datFilterMDValue").hidden = 1
		set ..%GetComponentById("datFilterMDValue2").hidden = 1
		//set ..%GetComponentById("selFilterMDValue").hidden = 0
		//set ..%GetComponentById("selFilterMDValue2").hidden = 0
		
		for tName = "selFilterMDValue","selFilterMDValue2" {
			set tComp = ..%GetComponentById(tName)
			set tComp.hidden = 0
			set tComp.parameters.GetAt(2).value = pFieldId
			
			set tParam = ##class(%ZEN.Auxiliary.parameter).%New()
			do ..%AddChild(tParam)
			set tParam.value = pFieldId
			do tComp.parameters.SetAt(tParam, 2)
		}
		/*do ##class(%iKnow.Queries.MetadataAPI).GetFieldValuesById("^||%IKQ.FieldValues", ..domain, pFieldId, 0, 0)
		set i = "", values=""
		for {
			set i = $order(^||%IKQ.FieldValues(i), 1, data)
			quit:i=""
			set values = values _ "," _ $$$QUOTE($li(data))
		}
		set ..%GetComponentById("selFilterMDValue").valueList = $e(values,2,*)
		set ..%GetComponentById("selFilterMDValue2").valueList = $e(values,2,*)*/
		
	} else {
		set ..%GetComponentById("txtFilterMDValue").hidden = tIsDate
		set ..%GetComponentById("txtFilterMDValue2").hidden = tIsDate
		set ..%GetComponentById("datFilterMDValue").hidden = 'tIsDate
		set ..%GetComponentById("datFilterMDValue2").hidden = 'tIsDate
		set ..%GetComponentById("selFilterMDValue").hidden = 1
		set ..%GetComponentById("selFilterMDValue2").hidden = 1
	}
	quit $$$OK
}

Method ChangeFilterMDOp(pOperator As %Integer) As %Status [ ZenMethod ]
{
	set disabled = (..%GetValueById("selFilterType")="metadata") && ($$$UPPER(pOperator)'=$$$MDOPBETWEEN)
	set ..%GetComponentById("txtFilterMDValue2").disabled = disabled
	set ..%GetComponentById("datFilterMDValue2").disabled = disabled
	set ..%GetComponentById("selFilterMDValue2").disabled = disabled
	quit $$$OK
}

ClientMethod clearFilterClient() [ Language = javascript ]
{
	var sc = zenPage.ClearFilter();
	zen('hidFilterGroup').setValue(0);
	zen('htmlCurrentFilters').refreshContents();
}

Method ClearFilter() As %Status [ ZenMethod ]
{
	set ..filter = ""
	quit $$$OK
}

ClientMethod addFilterClient() [ Language = javascript ]
{
	var msg = zenPage.AddFilter(zen("hidFilterGroup").getValue());
	if (msg != "OK") {
		alert(msg);
		return;
	}
	zen('htmlCurrentFilters').refreshContents();
}

Method AddFilter(pGroup As %String = 0) As %String [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tType = ..%GetValueById("selFilterType")
		set tDomainId = ..domain
		
		if (tType = "metadata") {
			
			set tFieldId = ..%GetValueById("selFilterMDField")
			if (+tFieldId) {
				set tField = ##class(%iKnow.Objects.MetadataField).PKINDEXOpen(tDomainId, tFieldId)
				if (tField="") { set tSC = $$$ERROR($$$IKMDFieldDoesNotExist, tFieldId) quit }
				set tValuesFromSelect = tField.HasBitstringStorage, tIsDate = (tField.DataType=$$$MDDTDATE)
				set tFieldName = tField.Name
			} else {
				set tValuesFromSelect = 0, tIsDate = 0, tFieldName = tFieldId
			}
			
			set tOp = ..%GetValueById("selFilterMDOp")
			if ('tValuesFromSelect) {
				set tValue = $s(tIsDate:..%GetValueById("datFilterMDValue"), 1:..%GetValueById("txtFilterMDValue"))
				if (tOp=$$$MDOPBETWEEN) {
					set tValue2 = $s(tIsDate:..%GetValueById("datFilterMDValue2"), 1:..%GetValueById("txtFilterMDValue2"))
					set tValue = tValue _ $$$MDVALSEPARATOR _ tValue2
				}
			} else {
				set tValue = ..%GetValueById("selFilterMDValue")
				if (tOp=$$$MDOPBETWEEN) {
					set tValue2 = ..%GetValueById("selFilterMDValue2")
					set tValue = tValue _ $$$MDVALSEPARATOR _ tValue2
				}
			}
			
			set tMetadataAPI = $$$GETPARAM(tDomainId, $$$IKPMETADATAAPI, $$$IKPDEFMETADATAAPI)
			set tFilter = $classmethod(tMetadataAPI, "CreateFilter", tDomainId, tFieldName, tOp, tValue, .tSC)
			quit:$$$ISERR(tSC)
			
		} elseif (tType = "srcid") {
			
			set tFilter = ##class(%iKnow.Filters.SourceIdFilter).%New(tDomainId, ..%GetValueById("txtFilterSrcIds"))
			
		} elseif (tType = "extid") {
			
			set tFilter = ##class(%iKnow.Filters.ExternalIdFilter).%New(tDomainId, ..%GetValueById("txtFilterExtIds"))
			
		} elseif (tType = "sql") {
			
			set tFilter = ##class(%iKnow.Filters.SqlFilter).%New(tDomainId, ..%GetValueById("txtFilterSQL"))
			
		} elseif (tType = "matching") {
			
			set tFilter = ##class(%iKnow.Filters.DictionaryMatchFilter).%New(tDomainId, ..%GetValueById("selFilterMatchDicts"), ..%GetValueById("txtFilterMatchMin"), ..%GetValueById("txtFilterMatchMax"), ..%GetValueById("selFilterMatchMetric"))
			
		} elseif (tType = "mdx") {
			
			set tFilter = ##class(%iKnow.DeepSee.MDXFilter).%New(tDomainId, ..%GetValueById("txtFilterMDX"))
			
		} elseif (tType = "deepsee") {
			
			set tFilter = ##class(%iKnow.DeepSee.MDXFilter).%New(tDomainId, ..%GetValueById("selFilterDSDims")_"."_..%GetValueById("selFilterDSValue"))
			
		} elseif (tType = "entity") {
			
			set tFilter = ##class(%iKnow.Filters.ContainsEntityFilter).%New(tDomainId, ..%GetValueById("txtFilterEntity"), ..%GetValueById("chkFilterEntitySimilar"))
			
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Unknown filter type: "_tType)
			quit
		}
		
		if '$isobject(tFilter) {
			set tSC = %objlasterror
			quit
		}
		
		set tCurrentFilter = ..GetCurrentFilterObject()
		set tRootFilter = tCurrentFilter, tPosInParent = 0
		if '$isobject(tCurrentFilter) {
			set ..filter = tFilter.ToString()
		} else {
			if (pGroup'=0) {
				for tDepth = 1:1:$length(pGroup,"x") {
					set tParentFilter = tCurrentFilter, tPosInParent = $piece(pGroup,"x",tDepth)
					set tCurrentFilter = tCurrentFilter.GetSubFilterAt(tPosInParent)
				}
			} 
			if ($classname(tCurrentFilter) = "%iKnow.Filters.GroupFilter") {
				set tSC = tCurrentFilter.AddSubFilter(tFilter)
			} else {
				set tNewFilter = ##class(%iKnow.Filters.GroupFilter).%New(tDomainId,,,0)
				set tSC = tNewFilter.AddSubFilter(tCurrentFilter)
				set tSC = tNewFilter.AddSubFilter(tFilter)
				if (tPosInParent) {
					set tSC = tParentFilter.ReplaceSubFilterAt(tPosInParent, tNewFilter)
				} else {
					set tRootFilter = tNewFilter
				}
			}
			set ..filter = tRootFilter.ToString()
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $s($$$ISOK(tSC):"OK", 1:$$GetErrorText^%apiOBJ(tSC))
}

/// This method draws the filter in the filter popup screen
Method DrawFilter(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tFilter = ..GetCurrentFilterObject()
		if '$isobject(tFilter) {
			write $$$Text("[no filter]")
			quit
		}
		
		// draw filters recursively
		set tSC = ..DrawFilterObject(tFilter, 0, pSeed)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawFilterObject(pFilter As %iKnow.Filters.Filter, pDepth As %String, pMode As %String = "VIEW") As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tClass = $classname(pFilter)
		if (tClass = "%iKnow.Filters.GroupFilter") {
			
			write "<table><tr valign=""middle""><td style='border-right:1px solid black;padding-right:5px;'>"
			write:pFilter.Negated "NOT "
			
			write:(pMode="MANAGE") "<a href=""javascript:zenPage.toggleGroupLogicClient('"_pDepth_"');"">"
			write $case(pFilter.GroupLogic, $$$GROUPFILTERAND:"AND", $$$GROUPFILTEROR:"OR")
			write:(pMode="MANAGE") "</a>"
			
			write:pDepth&&(pMode="MANAGE") " <a href=""javascript:zenPage.removeFilterClient('"_pDepth_"');"" title="""_$$$Text("remove this filter")_""">x</a>"
			
			write "</td><td><table>"
			
			for i = 1:1:pFilter.GetSubFilterCount() {
				write "<tr><td>"
				do ..DrawFilterObject(pFilter.GetSubFilterAt(i), $s(pDepth:pDepth_"x"_i, 1:i), pMode)
				write "</td></tr>"
			}
			
			if (pMode="MANAGE") {
				write "<tr><td>>> <a id=""fltGrpLink"_pDepth_""""
				write:(..%GetValueById("hidFilterGroup")=pDepth) " style=""font-weight:bold;"""
				write " href=""javascript:zenPage.setCurrentGroupClient('"_pDepth_"');"">"_$$$Text("add filter here")_"</a></td></tr>"
			}
			
			write "</table></td></tr></table>"
			
		} else {
			if (tClass = "%iKnow.Filters.SimpleMetadataFilter") {
			
				set tField = ##class(%iKnow.Objects.MetadataField).PKINDEXOpen(..domain, pFilter.FieldId)
				set tOp = pFilter.FilterOperator
				set tValue = pFilter.FilterValue
				set:tOp=$$$MDOPBETWEEN tValue = $replace(tValue, $$$MDVALSEPARATOR, " AND ")
				write tField.Name _ " " _ tOp _ " " _ tValue
			
			} elseif (tClass = "%iKnow.Filters.DictionaryMatchFilter") {
				
				set tDictName = $lg(^IRIS.IK.Mat.DictId(..domain, $li(pFilter.DictIds)),1) 
				if (pFilter.Min = -1) {
					if (pFilter.Max) {
						write $$$FormatText($$$Text("has at most %1"),pFilter.Max)
					} else {
						write $$$Text("has no")
					}
				} elseif (pFilter.Max = -1) {
					write $$$FormatText($$$Text("has at least %1"),pFilter.Min)
				} else {
					write $$$FormatText($$$Text("has between %1 and %2"),pFilter.Min,pFilter.Max)
				}
				write " " _ $s(pFilter.Metric="COUNT":$$$Text("matches"), 1:$$$Text("total match score")) _ " " _ $$$Text("with")_ " """ _ tDictName _ """"
			
			} elseif (tClass = "%iKnow.Filters.SourceIdFilter") {
			
				write "SourceID IN ("_$lts(pFilter.SourceIds)_")"
			
			} elseif (tClass = "%iKnow.Filters.ExternalIdFilter") {
			
				write "ExternalID IN ("_$lts(pFilter.ExternalIds)_")"
			
			} elseif (tClass = "%iKnow.Filters.SqlFilter") {
			
				write "SQL: " _ pFilter.SqlQuery
			
			} elseif (tClass = "%iKnow.DeepSee.MDXFilter") {
			
				write "MDX: " _ pFilter.MDXWhereClause
			
			} elseif (tClass = "%iKnow.Filters.ContainsEntityFilter") {
				
				write "CONTAINS: """ _ $lts(pFilter.Entities) _ """" _ $s(pFilter.IncludeSimilar:" "_$$$Text("(or similar)"), 1:"")
				
			} else {
				write pFilter.ToString()
			}
			
			write:(pMode="MANAGE") " <a href=""javascript:zenPage.removeFilterClient('"_pDepth_"');"" title="""_$$$Text("remove this filter") _ """>x</a>"
			write:(pMode="VIEW") " <a href=""javascript:zenPage.drillFilterClient('"_$zconvert(pFilter.ToString(),"O","JS")_"');"" title="""_$$$Text("drill")_""" >"_pFilter.FilteredSourceCount_"</a>"
			
			if (pMode="MANAGE") {
				write "<br/>&nbsp;&nbsp;&nbsp;>> <a id=""fltGrpLink"_pDepth_""""
				write:(..%GetValueById("hidFilterGroup")=pDepth) " style=""font-weight:bold;"""
				write " href=""javascript:zenPage.setCurrentGroupClient('"_pDepth_"');"">"_$$$Text("add filter here")_"</a>"
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClientMethod toggleGroupLogicClient(depth) [ Language = javascript ]
{
	var sc = zenPage.ToggleGroupLogic(depth);
	zen('htmlCurrentFilters').refreshContents();
}

Method ToggleGroupLogic(pGroup As %String) As %Status [ ZenMethod ]
{
	set tCurrentFilter = ..GetCurrentFilterObject(), tRootFilter = tCurrentFilter
	quit:'$isobject(tCurrentFilter) $$$OK
	
	if (pGroup'=0) {
		for tDepth = 1:1:$length(pGroup,"x") {
			set tPosInParent = $piece(pGroup,"x",tDepth)
			set tCurrentFilter = tCurrentFilter.GetSubFilterAt(tPosInParent)
		}
	}
	set tCurrentFilter.GroupLogic = $s(tCurrentFilter.GroupLogic=$$$GROUPFILTERAND:$$$GROUPFILTEROR, 1:$$$GROUPFILTERAND)
	
	set ..filter = tRootFilter.ToString()
	
	quit $$$OK
}

ClientMethod setCurrentGroupClient(depth) [ Language = javascript ]
{
	document.getElementById('fltGrpLink' + zen('hidFilterGroup').getValue()).style.fontWeight = 'normal';
	zen('hidFilterGroup').setValue(depth);
	document.getElementById('fltGrpLink' + depth).style.fontWeight = 'bold';
}

ClientMethod removeFilterClient(depth) [ Language = javascript ]
{
	if (depth == 0) {
		zenPage.clearFilterClient();
		return;
	}
	var sc = zenPage.RemoveFilterAt(depth);
	zen('hidFilterGroup').setValue(0);
	zen('htmlCurrentFilters').refreshContents();
}

Method RemoveFilterAt(pGroup) As %Status [ ZenMethod ]
{
	if (pGroup=0) {
		quit ..ClearFilter()
	}
	
	set tCurrentFilter = ..GetCurrentFilterObject()
	quit:'$isobject(tCurrentFilter) $$$OK
	
	set tRootFilter = tCurrentFilter, tPosInParent = 0
	for tDepth = 1:1:$length(pGroup,"x") {
		set tParentFilter = tCurrentFilter, tPosInParent = $piece(pGroup,"x",tDepth)
		set tCurrentFilter = tCurrentFilter.GetSubFilterAt(tPosInParent)
	}
	
	set tSC = tParentFilter.RemoveSubFilterAt(tPosInParent)
	quit:$$$ISERR(tSC) tSC
	
	set ..filter = tRootFilter.ToString()
	
	quit $$$OK
}

/// Returns the current filter string, if any
/// <p>NOTE: this method is deprecated. Please access <property>filter</property> directly instead.</p>
Method GetCurrentFilterString() As %String [ Deprecated ]
{
	quit ..filter
}

/// Returns the current filter object, if any
Method GetCurrentFilterObject() As %iKnow.Filters.Filter
{
	quit ##class(%iKnow.Filters.Filter).RestoreFilterFromString(..filter)
}

/// Returns the current filter mode, if any
Method GetCurrentFilterMode() As %Integer
{
	quit ..filtermode
}

/// Display the filter popup window.
ClientMethod showFilterForm() [ Final, Language = javascript ]
{
	var formBox = this.getComponentById('popFilter');
	formBox.show();
	zen('htmlCurrentFilters').refreshContents();
}

/// Client-side method called when the user commits his filter criteria in the filter popup window.
/// This will call <method>OnUpdateFilter</method> on the server, close the popup and call
/// <method>onUpdateFilterClient</method> afterwards.
ClientMethod updateFilterClient() [ Final, Language = javascript ]
{
	var sc = zenPage.OnUpdateFilter();
	zenPage.endModal();
	zen('btnFilters').refreshContents();
	var lblFilters = zen('lblFilterCount');
	if (lblFilters != null) lblFilters.refreshContents();
	zenPage.onUpdateFilterClient();
}

Method OnUpdateFilter() As %Status [ ZenMethod ]
{
	quit:..%GetComponentById("btnFilters")="" $$$OK
	
	set tFilter = ..GetCurrentFilterObject()
	if $isobject(tFilter) {
		set ..%GetComponentById("btnFilters").caption = $$$Text("filters")_"*"
		set tFilterCount = ..%GetComponentById("lblFilterCount")
		set:$isobject(tFilterCount) tFilterCount.label = tFilter.FilteredSourceCount
	} else {
		set ..%GetComponentById("btnFilters").caption = $$$Text("filters")
		set tFilterCount = ..%GetComponentById("lblFilterCount")
		if $isobject(tFilterCount) {
			set tSrcCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(..domain)
			set tFilterCount.label = $s(tSrcCount<0:"", 1:tSrcCount)
		}
	}
	quit $$$OK
}

/// Client-side method subclasses can override to execute additional logic when the user has changed
/// filter criteria.
ClientMethod onUpdateFilterClient() [ Language = javascript ]
{
}

/// Client-side method called when the "drill" link next to a filter (in VIEW mode) is clicked
ClientMethod drillFilterClient(filterString) [ Language = javascript ]
{
}

/// Simple informative pane that can be included to display additional help/details about this page.
/// The displayed text is provided through <method>GetInfoPaneText</method>.
XData infoPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup id="grpInfoPane" hidden="#(%session.hideInfoPane)#" enclosingStyle="padding:30px" cellStyle="border:1px dashed #777777;padding:10px;">
<vgroup>
<html id="htmlInfoPane" containerStyle="color:#777777;" />
<link caption="hide" width="100%" onclick="zenPage.hideInfoPaneClient(1);return false;" enclosingStyle="text-align:right;margin-top:10px;" />
</vgroup>
</vgroup>
</pane>
}

/// Builds <xdata>infoPane</xdata>.
Method BuildInfoPane() As %Status [ Final ]
{
	set state = $g(%session.Data("hideInfoPane"),0)
	set info = ..%GetComponentById("htmlInfoPane")
	quit:info="" $$$OK
	set text = ..GetInfoPaneText()
	quit:text="" $$$OK
	set info.content = text
	set %session.Data("hideInfoPane") = state
	
	// let the logo serve as a <help> button
	set imgLogo = ..%GetComponentById("imgLogoPane")
	quit:imgLogo="" $$$OK
	set imgLogo.onclick = "zenPage.hideInfoPaneClient(0);return false;"
	quit $$$OK
}

/// Returns the text to be displayed in <xdata>infoPane</xdata>. To be overridden by the subclass using it.
Method GetInfoPaneText() As %String
{
	quit ""
}

ClientMethod hideInfoPaneClient(hide) [ Final, Internal, Language = javascript ]
{
	var sc = zenPage.HideInfoPane(hide);
	zen('grpInfoPane').setProperty('hidden',hide);
}

Method HideInfoPane(hide As %Boolean = 1) As %Status [ Final, Internal, ZenMethod ]
{
	set %session.Data("hideInfoPane") = hide
	quit $$$OK
}

XData skiplistPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<button id="btnSkiplists" caption="skiplists" onclick="zenPage.showSkiplists();" disabled="true" />
<modalGroup id="popSkiplists" width="400">
<vgroup width="400">
<titleBox title="Skiplists" width="100%" />
<spacer height="10" />
<multiSelectSet id="selSkiplists" />
<spacer height="10" />
<label id="lblXDomainBL" label="SkipLists with an * are available across domains" hidden="true" enclosingStyle="padding-bottom:10px" />
<button caption="apply" onclick="zenPage.setSkiplistsClient();return;" />
</vgroup>
</modalGroup>
</pane>
}

ClientMethod showSkiplists() [ Language = javascript ]
{
	var blBox = this.getComponentById('popSkiplists');
	blBox.show();
}

ClientMethod setSkiplistsClient() [ Language = javascript ]
{
	var value = zen('selSkiplists').getValue();
	var sc = zenPage.setProperty('skiplists',value);
	zenPage.endModal();
	var btn = zen('btnSkiplists')
	if (btn != null) {
		btn.setProperty('caption', $$$Text('skiplists')+ (((value == null) || (value == '')) ? '' : '*'));
	}
	zenPage.onUpdateFilterClient();
}

Method SetSkiplists(skipListIds As %String) [ ZenMethod ]
{
	set ..skiplists = skipListIds
	quit $$$OK
}

}
