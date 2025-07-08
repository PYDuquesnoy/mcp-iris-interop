/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Settings page.
/// 
Class %DeepSee.UI.Settings Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Property currSetting As %Integer;

Property currIcon As %Integer;

Parameter PAGENAME = "Settings";

Parameter RESOURCE = "%DeepSee_Admin,%Development";

Parameter DOCBOOKID = "D2GS_uis_settings";

Property btnNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("New")} ];

Property btnApply As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Apply")} ];

Property btnRemove As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove")} ];

XData Style
{
<style type="text/css">

body {
	background: #F0F0F0;
}

#sTitle {
	color: #404060;
	font-size: 20px;
	margin-bottom: 2px;
}

#sTitleSub {
	color: #404040;
	font-size: 12px;
	margin-bottom: 10px;
}

#udSettings {
}

.udSettingsDiv {
	height: 260px;
	overflow-y: auto;
	overflow-x: hidden;
	border: 1px solid #606060;
}

table.udSettingsForm {
	font-size: 10pt;
	color: #404040;
}

table.udSettingsTable {
	color: #404040;
	background: #F8F8FF;
	font-size: 10pt;
}

table.udSettingsTable th {
	background: #D0D0D0;
	padding: 2px;
	color: #606060;
	text-align: left;
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
}

table.udSettingsTable td {
	padding: 1px;
	padding-left: 3px;
	padding-right: 5px;
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
}

.zenHint {
	color: #606060;
}

.zenLabel {
	color: #404040;
	font-size: 13px;
}

.checkboxCaption {
	color: #404040;
	font-size: 13px;
}

.optTitle {
	color: #606060;
	font-size: 14px;
	margin-top: 10px;
	margin-bottom: 5px;
	border-bottom: 1px solid #808080;
}

</style>
}

/// This XML defines the contents of the contents pane for this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee"
>
<jsonProvider id="udContent" OnGetArray="GetUserSettings"/> 
<jsonProvider id="udIconContent" OnGetArray="GetUserIcons"/> 

<spacer height="5"/>
<hgroup cellVAlign="top">
<spacer width="50"/>
<vgroup>
<html id="sTitle"></html>
<html id="sTitleSub"></html>
</vgroup>
</hgroup>
<hgroup cellVAlign="top">
<spacer width="50"/>
<tabGroup showTabBar="true">
<tab caption="General" title="General settings for User Portal">
<form id="settingsForm">
<vgroup cellStyle="padding:5px;">
<hgroup cellVAlign="top">
<select label="General Color Scheme" id="Scheme" showEmpty="false" name="Scheme"/>
<spacer width="20"/>
<select label="Chart Series Color Scheme" id="ChartSeriesScheme" showEmpty="false" name="ChartSeriesScheme"/>
</hgroup>
<text label="Home page title" id="PageTitle" name="PageTitle"  size="40" hint="Title for Portal Home page" />
<text label="Company Name" id="CompanyName" name="CompanyName"  size="40" hint="Company name to display in Portal title." />
<text label="Company Logo" id="CompanyLogo" name="CompanyLogo" size="40" hint="URL of icon to display in Portal title."/>
<text label="Company Link" id="CompanyLink" name="CompanyLink" size="40" hint="URL to navigate to when user clicks on Company name or logo in the portal."/>
<text label="Google Maps API Key" id="GoogleMapsKey" name="GoogleMapsKey" size="40" hint="Key to authorize use of the Google Maps Widget."/>
<select id="MailEnabled" name="MailEnabled" label="Dashboard email: Specify whether users can send email and how" valueList="1,2,0" displayList="Use server-side email,Use client-side email,Disabled" showEmpty="false" hint="For server-side, you must configure an email server using the Task Manager Email Settings."/>
<combobox label="Default Resource" id="DefaultResource" name="DefaultResource" editable="true" unrestricted="true" hint="Default resource to use for all new folder items."/>
<hgroup cellVAlign="top">
<checkbox caption="No Dashboard Titles" id="DbNoTitle" name="DbNoTitle"/>
<spacer width="20"/>
<checkbox caption="No Dashboard Borders" id="DbNoBorder" name="DbNoBorder"/>
</hgroup>
<hgroup cellVAlign="top">
<checkbox caption="Show Calculated Members in Filters" id="ctrlShowCalc" name="ctrlShowCalc"/>
</hgroup>
<hgroup cellVAlign="top">
<!--><checkbox caption="Autosave" id="autosave" name="autosave"/><-->
<fieldSet legend="Autosave">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox caption="Analyzer" id="autosaveAnalyzer" name="autosaveAnalyzer"/>
<checkbox caption="User Portal Settings" id="autosaveUserPortal" name="autosaveUserPortal"/>
</hgroup>
</fieldSet>
</hgroup>
</vgroup>
</form>
</tab>
<tab caption="Worklists" cellStyle="padding:5px;" title="Customize contents of worklists within the User Portal">
<checkbox id="CustomWorklist" name="CustomWorklist" caption="Customized worklists" onchange="zenPage.customChange(zenThis.getValue());"/>
<vgroup id="optionWorklist"/>
</tab>
<tab caption="Run-time Variables" cellStyle="padding:5px;" title="Define and edit run-time variables">
<html id="udSettings"></html>
</tab>
<tab caption="User-defined Icons" cellStyle="padding:5px;" title="Add / remove user-defined icons">
<html id="udIconList"></html>
</tab>
</tabGroup>

<spacer width="50"/>
<vgroup>
</vgroup>
</hgroup>

</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Settings","%DeepSee")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Settings","%DeepSee")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = $$$Text("Portal Settings")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save settings"),"zenPage.saveSettings();")
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			this.renderSettings();
			this.renderIconList();
		}
		
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Save settings.
ClientMethod saveSettings() [ Language = javascript ]
{
	var form = zen('settingsForm');
	var data = form.getValuesAsObject();
	var msg = zenPage.SaveToServer(data);
	if ('' != msg) {
		alert(msg);
	}
}

/// Save settings to the settings global.
ClassMethod SaveToServer(pData As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set ^DeepSee.UserPortalSettings("Scheme") = pData.Scheme
		Set ^DeepSee.UserPortalSettings("ChartSeriesScheme") = pData.ChartSeriesScheme
		Set ^DeepSee.UserPortalSettings("CompanyName") = pData.CompanyName
		Set ^DeepSee.UserPortalSettings("CompanyImage")= pData.CompanyLogo
		Set ^DeepSee.UserPortalSettings("CompanyLink") = pData.CompanyLink
		Set ^DeepSee.UserPortalSettings("GoogleMapsKey") = pData.GoogleMapsKey		// DTB472 - Add google maps API key
		Set ^DeepSee.UserPortalSettings("PageTitle") = pData.PageTitle
		Set ^DeepSee.UserPortalSettings("MailEnabled") = pData.MailEnabled
		Set ^DeepSee.UserPortalSettings("DefaultResource") = pData.DefaultResource
		Set ^DeepSee.UserPortalSettings("DashboardNoTitle") = pData.DbNoTitle
		Set ^DeepSee.UserPortalSettings("DashboardNoBorder") = pData.DbNoBorder
		Set ^DeepSee.UserPortalSettings("Controls","showCalculated") = pData.ctrlShowCalc		// DTB743 - Toggle Calculated Member display for searchBox
		
		// + WAL053
		Set ^DeepSee.UserPortalSettings("autosaveAnalyzer") = pData.autosaveAnalyzer
		Set ^DeepSee.UserPortalSettings("autosaveUserPortal") = pData.autosaveUserPortal
		// - WAL053
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		Set ..%GetComponentById("sTitle").content = $$$FormatText($$$Text("User Portal settings for namespace %1."),$namespace)
		Set ..%GetComponentById("sTitleSub").content = $$$FormatText($$$Text("Press Save to apply changes."),$namespace)

		Set tCustom = +$G(^DeepSee.UserPortalSettings("Worklist"))

		// get list of color schemes
 		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetColorSchemes(.tSchemes)
 		Set tValueList = ""
 		Set tDisplayList = ""
 		Set k = $O(tSchemes(""))
 		While (k'="") {
	 		Set tName = $LG(tSchemes(k),1)
	 		Set tCaption = $LG(tSchemes(k),2)
	 		Set:tCaption="" tCaption = tName
			Set $P(tValueList,",",k) = tName
			Set $P(tDisplayList,",",k) = tCaption
	 		Set k = $O(tSchemes(k))
 		}
		Set ..%GetComponentById("Scheme").valueList = tValueList
		Set ..%GetComponentById("Scheme").displayList = tDisplayList
 		Set ..%GetComponentById("Scheme").value = $G(^DeepSee.UserPortalSettings("Scheme"),"simple")

		// get list of chart series schemes
 		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetChartSeriesSchemes(.tSchemes)
 		Set tValueList = ""
 		Set tDisplayList = ""
 		Set k = $O(tSchemes(""))
 		While (k'="") {
	 		Set tName = $LG(tSchemes(k),1)
	 		Set tCaption = $LG(tSchemes(k),2)
	 		Set:tCaption="" tCaption = tName
			Set $P(tValueList,",",k) = tName
			Set $P(tDisplayList,",",k) = tCaption
	 		Set k = $O(tSchemes(k))
 		}
		Set ..%GetComponentById("ChartSeriesScheme").valueList = tValueList
		Set ..%GetComponentById("ChartSeriesScheme").displayList = tDisplayList
 		Set ..%GetComponentById("ChartSeriesScheme").value = $G(^DeepSee.UserPortalSettings("ChartSeriesScheme"),"")

		Set ..%GetComponentById("CompanyName").value = $G(^DeepSee.UserPortalSettings("CompanyName"))
		Set ..%GetComponentById("CompanyLink").value = $G(^DeepSee.UserPortalSettings("CompanyLink"))
		Set ..%GetComponentById("CompanyLogo").value = $G(^DeepSee.UserPortalSettings("CompanyImage"))
		Set ..%GetComponentById("GoogleMapsKey").value = $G(^DeepSee.UserPortalSettings("GoogleMapsKey"))		// DTB472 - Add google maps API key
		Set ..%GetComponentById("PageTitle").value = $G(^DeepSee.UserPortalSettings("PageTitle"))
		Set ..%GetComponentById("CustomWorklist").value = tCustom
		Set ..%GetComponentById("MailEnabled").value = +$G(^DeepSee.UserPortalSettings("MailEnabled"))
		Set ..%GetComponentById("DefaultResource").value = $G(^DeepSee.UserPortalSettings("DefaultResource"))
		Set ..%GetComponentById("DefaultResource").valueList = ##class(%DeepSee.Utils).GetResourceList()

		// JMD1260
		Set ..%GetComponentById("DbNoBorder").value = $G(^DeepSee.UserPortalSettings("DashboardNoBorder"))
		Set ..%GetComponentById("DbNoTitle").value = $G(^DeepSee.UserPortalSettings("DashboardNoTitle"))
		
		Set ..%GetComponentById("ctrlShowCalc").value = $G(^DeepSee.UserPortalSettings("Controls","showCalculated"))		// DTB743
		
		// + WAL053
		Set ..%GetComponentById("autosaveAnalyzer").value = $G(^DeepSee.UserPortalSettings("autosaveAnalyzer"))
		Set ..%GetComponentById("autosaveUserPortal").value = $G(^DeepSee.UserPortalSettings("autosaveUserPortal"))	
		// - WAL053

		// create controls to define worklist contents

		Set tOptions($I(n)) = "%DeepSee.UserPortal.FavoritesList"
		Set tOptions($I(n)) = "%DeepSee.UserPortal.RecentList"
		Set tOptions($I(n)) = "%DeepSee.UserPortal.AlertList"
		Set tOptions($I(n)) = "%DeepSee.UserPortal.DetailsList"

		Set tGroup = ..%GetComponentById("optionWorklist")
		Set tGroup.hidden = 'tCustom

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "optTitle"
		Set tHTML.content = $$$Text("Home Page Top Panel")
		Do tGroup.%AddChild(tHTML)
		
		Set tSC = ..%CreateOptions("Home",1,tGroup,.tOptions)
		If $$$ISERR(tSC) Quit

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "optTitle"
		Set tHTML.content = $$$Text("Home Page Bottom Panel")
		Do tGroup.%AddChild(tHTML)

		Set tSC = ..%CreateOptions("Home",2,tGroup,.tOptions)
		If $$$ISERR(tSC) Quit

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "optTitle"
		Set tHTML.content = $$$Text("Dashboard Page Top Panel")
		Do tGroup.%AddChild(tHTML)

		Set tCheckbox = ##class(%ZEN.Component.checkbox).%New()
		Set tCheckbox.caption = "Filters"
		Set tCheckbox.value = 1
		Set tCheckbox.readOnly = 1
		Do tGroup.%AddChild(tCheckbox)

		Set tSC = ..%CreateOptions("DashboardViewer",1,tGroup,.tOptions)
		If $$$ISERR(tSC) Quit

		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.enclosingClass = "optTitle"
		Set tHTML.content = $$$Text("Dashboard Page Bottom Panel")
		Do tGroup.%AddChild(tHTML)

		Set tSC = ..%CreateOptions("DashboardViewer",2,tGroup,.tOptions)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Create list of worklist option controls.
Method %CreateOptions(pPage As %String, pWorklist As %Integer, pGroup As %ZEN.Component.group, ByRef pOptions) As %Status
{
	Set tSC = $$$OK
	Try {
		Set n = $O(pOptions(""))
		While (n'="") {
			Set tClass = pOptions(n)
			Set tCaption = $zobjclassmethod(tClass,"%GetName")
			Set tCheckbox = ##class(%ZEN.Component.checkbox).%New()
			Set tCheckbox.caption = tCaption
			Set tCheckbox.onchange = "zenPage.optionChange('"_pPage_"','"_pWorklist_"',"_n_",'"_tClass_"',zenThis.getValue());"
			Set tCheckbox.value = +$D(^DeepSee.UserPortalSettings("Worklist",pPage,pWorklist,n))
			Do pGroup.%AddChild(tCheckbox)
			Set n = $O(pOptions(n))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Click on worklist option.
ClientMethod optionChange(page, worklist, n, cls, value) [ Language = javascript ]
{
	zenPage.SetOption(page,worklist,cls,n,value?1:0);
}

/// Click on worklist option.
ClassMethod SetOption(pPage As %String, pWorklist As %String, pClass As %String, pNum As %Integer, pValue As %Boolean) [ ZenMethod ]
{
	If (pValue) {
		Set ^DeepSee.UserPortalSettings("Worklist",pPage,pWorklist,pNum) = pClass
	}
	Else {
		Kill ^DeepSee.UserPortalSettings("Worklist",pPage,pWorklist,pNum)
	}
}

/// Click on custom option.
ClientMethod customChange(value) [ Language = javascript ]
{
	value = value ? true : false;
	zen('optionWorklist').setHidden(!value)
	zenPage.SetCustom(value?1:0);
}

/// Set custom worklist option.
ClassMethod SetCustom(pValue As %Boolean) [ ZenMethod ]
{
	If (pValue) {
		Set ^DeepSee.UserPortalSettings("Worklist") = 1
	}
	Else {
		Kill ^DeepSee.UserPortalSettings("Worklist")
	}
}

/// Return the current user icons for the JSON provider.<br/>
Method GetUserIcons(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("name","path")
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetUserIconList(.pData)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the current user settings for the JSON provider.<br/>
Method GetUserSettings(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// eval is evaluated value
		Set pMetaData = $LB("name","value","comment","context","eval","error")

		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetUserSettingsList(.pData)
		If $$$ISERR(tSC) Quit

		Set n = $O(pData(""))
		While (n'="") {
			// evaluate each setting to see its value
			Set tName = $LG(pData(n),1)
			Set tEval = ##class(%DeepSee.UserPortal.Utils).%GetUserSetting(tName,.tSC2)
			If $$$ISERR(tSC2) {
				Set tError = $System.Status.GetErrorText(tSC2)
				Set tError = "<"_$P(tError,"<",2)
				Set tError = $P(tError,">",1)_">"
			}
			Else {
				Set tError = ""
			}
			Set $List(pData(n),5) = tEval
			Set $List(pData(n),6) = tError
			Set n = $O(pData(n))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw list of user icons.
ClientMethod renderIconList() [ Language = javascript ]
{
	var udSettings = zen('udIconList');
	var settings = zen('udIconContent').getContentObject();
	var html = new Array();

	if (settings && settings.children) {
		html[html.length] = '<div class="udSettingsDiv">';
		html[html.length] = '<table class="udSettingsTable" width="100%" border="0" cellspacing="0">';
		html[html.length] = '<tr>';
		html[html.length] = '<th>'+$$$Text('Name')+'</th>';
		html[html.length] = '<th>'+$$$Text('Path')+'&nbsp;</th>';
		html[html.length] = '<th>'+$$$Text('Icon')+'&nbsp;</th>';
		html[html.length] = '<th>'+'&nbsp;</th>';
		html[html.length] = '</tr>';

		// table
		for (var n = 0; n < settings.children.length; n++) {
			var setting = settings.children[n];

			var style = '';

			if (n===this.currIcon) {
				style += "background:#D0D0FF;";
			}

			html[html.length] = '<tr style="'+style+'" onclick="zenPage.selectIcon('+n+');">';
			html[html.length] = '<td nowrap="1">'+zenEscapeXML(setting.name)+'</td>';
			html[html.length] = '<td>'+zenEscapeXML(setting.path)+'&nbsp;</td>';
			html[html.length] = '<td>'+'<image src="'+setting.path+'">'+'</td>';
			html[html.length] = '<td>'+'<image title="'+$$$Text('Remove this item')+'" src="deepsee/close_a_16.png" onclick="zenPage.removeIcon('+n+');">'+'</td>';

			html[html.length] = '</tr>';
		}
		html[html.length] = '</table>';
		html[html.length] = '</div>';
	}

	// edit form
	// 
	var dis = (''===this.currIcon) ? 'disabled="1"' : '';
	var item = (''===this.currIcon) ? null : settings.children[this.currIcon];
	var disNew = (item && item._isnew) ? 'disabled="1"' : '';
	var clsNew = disNew ? 'commandButtonDisabled' : 'commandButton';
	var clsBtn = dis ? 'commandButtonDisabled' : 'commandButton';

	html[html.length] = '<br/>';
	html[html.length] = '<table class="udSettingsForm" border="0" cellspacing="5">';
	html[html.length] = '<tr>';
	html[html.length] = '<td>' + $$$Text('Name') + '</td>';
	html[html.length] = '<td title="'+$$$Text('Name of the icon')+'">' + '<input id="iconName" '+dis+' type="text" value="'+zenEscapeXML(item?item.name:'')+'"/>' + '</td>';
	html[html.length] = '</tr>';
	html[html.length] = '<tr>';
	html[html.length] = '<td>' + $$$Text('Path') + '</td>';
	html[html.length] = '<td title="'+$$$Text('URL for the icon')+'">' + '<input id="iconPath" '+dis+' size="40" type="text" value="'+zenEscapeXML(item?item.path:'')+'"/>' + '</td>';
	html[html.length] = '</tr>';

	html[html.length] = '<tr>';
	html[html.length] = '<td>' + '&nbsp;' + '</td>';
	html[html.length] = '<td>' + '<input class="'+clsNew+'" title="'+$$$Text('Add a new item to the list')+'" type="button" '+disNew+' value="'+this.btnNew+'" onclick="zenPage.addIcon();"/>' + '&nbsp;' +'<input '+dis+' class="'+clsBtn+'" type="button" value="'+this.btnApply+'" title="'+$$$Text('Apply changes')+'" onclick="zenPage.applyIcon();"/>' + '&nbsp;' + '<input '+dis+' class="'+clsBtn+'" type="button" value="'+this.btnRemove+'" title="'+$$$Text('Remove item from the list')+'" onclick="zenPage.removeIcon();"/>' + '</td>';
	html[html.length] = '</tr>';

	html[html.length] = '</table>';

	udSettings.setContent(html.join(''));
}

/// Draw list of user settings.
ClientMethod renderSettings() [ Language = javascript ]
{
	var udSettings = zen('udSettings');
	var settings = zen('udContent').getContentObject();
	var html = new Array();
	
	if (settings && settings.children) {
		html[html.length] = '<div class="udSettingsDiv">';
		html[html.length] = '<table class="udSettingsTable" width="100%" border="0" cellspacing="0">';
		html[html.length] = '<tr>';
		html[html.length] = '<th>'+$$$Text('Name')+'</th>';
		html[html.length] = '<th>'+$$$Text('Value')+'&nbsp;</th>';
		html[html.length] = '<th>'+$$$Text('Context')+'&nbsp;</th>';
		html[html.length] = '<th>'+$$$Text('Comment')+'&nbsp;</th>';
		html[html.length] = '<th>'+$$$Text('Evaluates to')+'&nbsp;</th>';
		html[html.length] = '<th>'+'&nbsp;</th>';
		html[html.length] = '</tr>';

		// table
		for (var n = 0; n < settings.children.length; n++) {
			var setting = settings.children[n];
			var style = (''===setting.error)?"":"color: red;";

			if (n===this.currSetting) {
				style += "background:#D0D0FF;";
			}

			html[html.length] = '<tr style="'+style+'" onclick="zenPage.selectSetting('+n+');">';
			html[html.length] = '<td nowrap="1">'+zenEscapeXML(setting.name)+'</td>';
			html[html.length] = '<td>'+zenEscapeXML(setting.value)+'&nbsp;</td>';
			html[html.length] = '<td>'+zenEscapeXML(setting.context)+'&nbsp;</td>';
			html[html.length] = '<td>'+zenEscapeXML(setting.comment)+'&nbsp;</td>';
			if (''===setting.error) {
				html[html.length] = '<td>'+zenEscapeXML(setting.eval)+'&nbsp;</td>';
			}
			else {
				html[html.length] = '<td>'+zenEscapeXML(setting.error)+'&nbsp;</td>';
			}
			html[html.length] = '<td>'+'<image title="'+$$$Text('Remove this item')+'" src="deepsee/close_a_16.png" onclick="zenPage.removeSetting('+n+');">'+'</td>';
			html[html.length] = '</tr>';
		}
		html[html.length] = '</table>';
		html[html.length] = '</div>';
	}

	// edit form
	var dis = (''===this.currSetting) ? 'disabled="1"' : '';
	var item = (''===this.currSetting) ? null : settings.children[this.currSetting];
	var disNew = (item && item._isnew) ? 'disabled="1"' : '';
	var clsNew = disNew ? 'commandButtonDisabled' : 'commandButton';
	var clsBtn = dis ? 'commandButtonDisabled' : 'commandButton';

	html[html.length] = '<br/>';
	html[html.length] = '<table class="udSettingsForm" border="0" cellspacing="5">';
	html[html.length] = '<tr>';
	html[html.length] = '<td>' + $$$Text('Name') + '</td>';
	html[html.length] = '<td title="'+$$$Text('Name of the variable')+'">' + '<input id="itemName" '+dis+' type="text" value="'+zenEscapeXML(item?item.name:$$$Text('Select an item to edit'))+'"/>' + '</td>';
	html[html.length] = '</tr>';
	html[html.length] = '<tr>';
	html[html.length] = '<td>' + $$$Text('Value') + '</td>';
	html[html.length] = '<td title="'+$$$Text('ObjectScript expression that provides the value of the variable')+'">' + '<input id="itemValue" '+dis+' size="40" type="text" value="'+zenEscapeXML(item?item.value:'')+'"/>' + 
	'<div style="color:#606060; font-size:8pt;">' + 'E.g., "&[key]"' + '</div>' + 
	'</td>';
	html[html.length] = '</tr>';

	html[html.length] = '<tr>';
	html[html.length] = '<td>' + $$$Text('Context') + '</td>';

	html[html.length] = '<td title="'+$$$Text('Context in which this variable is used')+'">' + '<select id="itemContext" '+dis+'>';
	html[html.length] = '<option value="">' + '' + '</option>';

	var contextList = ['DefaultFilterValue','Other'];
	for (var n= 0; n < contextList.length; n++) {
		html[html.length] = '<option value="'+contextList[n]+'" '+(item&&(contextList[n]==item.context)?'selected="1"':'')+'>' + contextList[n] + '</option>';
	}
	html[html.length] = '</select></td>';
	html[html.length] = '</tr>';

	html[html.length] = '<tr>';
	html[html.length] = '<td>' + $$$Text('Comment') + '</td>';
	html[html.length] = '<td title="'+$$$Text('Description of the variable')+'">' + '<input id="itemComment" '+dis+' size="40" type="text" value="'+zenEscapeXML(item?item.comment:'')+'"/>' + '</td>';
	html[html.length] = '</tr>';

	html[html.length] = '<tr>';
	html[html.length] = '<td>' + '&nbsp;' + '</td>';
	html[html.length] = '<td>' + '<input class="'+clsNew+'" type="button" '+disNew+' value="'+this.btnNew+'" onclick="zenPage.addSetting();"/>' + '&nbsp;' +'<input '+dis+' class="'+clsBtn+'" type="button" value="'+this.btnApply+'" onclick="zenPage.applySetting();"/>' + '&nbsp;' + '<input '+dis+' class="'+clsBtn+'" type="button" value="'+this.btnRemove+'" onclick="zenPage.removeSetting();"/>' + '</td>';
	html[html.length] = '</tr>';
	html[html.length] = '</table>';

	udSettings.setContent(html.join(''));
}

/// Select an icon.
ClientMethod selectIcon(n) [ Language = javascript ]
{
	var settings = zen('udIconContent').getContentObject();

	// cancel unsaved new item
	if ('' !== this.currIcon) {
		var item = settings.children[this.currIcon];
		if (item._isnew) {
			settings.children.splice(this.currIcon,1);
		}
	}
	
	this.currIcon = n;
	this.renderIconList();
	var ctrl = self.document.getElementById('iconName');
	if (ctrl) {
		try {
			ctrl.focus();
			ctrl.select();
		}
		catch(ex) {
		}
	}
}

/// Select a setting.
ClientMethod selectSetting(n) [ Language = javascript ]
{
	var settings = zen('udContent').getContentObject();

	// cancel unsaved new item
	if ('' !== this.currSetting) {
		var item = settings.children[this.currSetting];
		if (item._isnew) {
			settings.children.splice(this.currSetting,1);
		}
	}

	this.currSetting = n;
	this.renderSettings();
	var ctrl = self.document.getElementById('itemValue');
	if (ctrl) {
		try {
			ctrl.focus();
			ctrl.select();
		}
		catch(ex) {
		}
	}
}

/// Add a new user icon.
ClientMethod addIcon() [ Language = javascript ]
{
	var udSettings = zen('udIconList');
	var settings = zen('udIconContent').getContentObject();
	if (!settings) {
		settings = new Object();
		settings.children = new Array();
		zen('udIconContent').setContentObject(settings);
	}

	if (!settings.children) {
		settings.children = new Array();
	}

	var item = new Object();
	item._isnew = true;
	item.name = 'New Icon ' + (settings.children.length + 1);
	item.path = '';
	settings.children[settings.children.length] = item;
	this.currIcon = settings.children.length - 1;

	this.renderIconList();
	var ctrl = self.document.getElementById('iconName');
	if (ctrl) {
		try {
			ctrl.focus();
			ctrl.select();
		}
		catch(ex) {
		}
	}
}

/// Add a new setting.
ClientMethod addSetting() [ Language = javascript ]
{
	var udSettings = zen('udSettings');
	var settings = zen('udContent').getContentObject();
	if (!settings) {
		settings = new Object();
		settings.children = new Array();
		zen('udContent').setContentObject(settings);
	}
	
	if (!settings.children) {
		settings.children = new Array();
	}

	var item = new Object();
	item._isnew = true;
	item.name = 'New Setting ' + (settings.children.length + 1);
	item.comment = '';
	item.context = '';
	item.value = '';
	item.eval = '';
	item.error = '';
	settings.children[settings.children.length] = item;
	this.currSetting = settings.children.length - 1;

	this.renderSettings();
	var ctrl = self.document.getElementById('itemName');
	if (ctrl) {
		try {
			ctrl.focus();
			ctrl.select();
		}
		catch(ex) {
		}
	}
}

/// Apply current icon.
ClientMethod applyIcon() [ Language = javascript ]
{
	var udSettings = zen('udIconList');
	var settings = zen('udIconContent').getContentObject();

	var item = settings.children[this.currIcon];
	var oldName = item.name;
	item.name = self.document.getElementById('iconName').value;
	item.path = self.document.getElementById('iconPath').value;

	// test for duplicate name
	for (var n = 0; n < settings.children.length; n++) {
		if (n != this.currIcon) {
			var test = settings.children[n];
			if (test && test.name == item.name) {
				// reset name (but not in control)
				item.name = '';
				alert($$$Text('An item with this name already exists.'));
				return;
			}
		}
	}

	var ok = this.ApplyIconToServer(item.name,item.path,oldName);
	if ('' !== ok) {
		alert(ok);
	}
	this.currIcon = '';

	zen('udIconContent').reloadContents();
	zen('udIconList').refreshContents(true);
	this.renderIconList();
}

/// Apply current setting.
ClientMethod applySetting() [ Language = javascript ]
{
	var udSettings = zen('udSettings');
	var settings = zen('udContent').getContentObject();

	var item = settings.children[this.currSetting];
	var oldName = item.name;
	item.name = self.document.getElementById('itemName').value;
	item.value = self.document.getElementById('itemValue').value;
	item.comment = self.document.getElementById('itemComment').value;
	item.context = self.document.getElementById('itemContext').value;

	// test for duplicate name
	for (var n = 0; n < settings.children.length; n++) {
		if (n != this.currSetting) {
			var test = settings.children[n];
			if (test && test.name == item.name) {
				// reset name (but not in control)
				item.name = '';
				alert($$$Text('An item with this name already exists.'));
				return;
			}
		}
	}

	var ok = this.ApplySettingToServer(item.name,item.value,item.comment,item.context,oldName);
	if ('' !== ok) {
		alert(ok);
	}
	this.currSetting = '';

	zen('udContent').reloadContents();
	zen('udSettings').refreshContents(true);
	this.renderSettings();
}

/// Remove current icon.
ClientMethod removeIcon(idx) [ Language = javascript ]
{
	var idx = 'undefined' == typeof idx ? this.currIcon : idx;
	var settings = zen('udIconContent').getContentObject();

	var name = settings.children[idx].name;
	var ok = this.ApplyIconToServer('','',name);
	if ('' !== ok) {
		alert(ok);
	}
	this.currIcon = '';

	zen('udIconContent').reloadContents();
	zen('udIconList').refreshContents(true);
	this.renderIconList();
}

/// Remove current setting.
ClientMethod removeSetting(idx) [ Language = javascript ]
{
	var idx = 'undefined' == typeof idx ? this.currSetting : idx;
	var settings = zen('udContent').getContentObject();

	var name = settings.children[idx].name;
	var ok = this.ApplySettingToServer('','','','',name);
	if ('' !== ok) {
		alert(ok);
	}
	this.currSetting = '';

	zen('udContent').reloadContents();
	zen('udSettings').refreshContents(true);
	this.renderSettings();
}

/// Apply a user icon value (if <var>pName</var> is not "").
/// If <var>pOldName</var> is non-"", delete it.
ClassMethod ApplyIconToServer(pName As %String, pPath As %String, pOldName As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		If (pOldName'="") {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%RemoveUserIcon(pOldName)
			If $$$ISERR(tSC) Quit
		}

		If (pName'="") {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%SetUserIcon(pName,pPath)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Apply a setting value (if <var>pName</var> is not "").
/// If <var>pOldName</var> is non-"", delete it.
ClassMethod ApplySettingToServer(pName As %String, pValue As %String, pComment As %String, pContext As %String, pOldName As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		If (pOldName'="") {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%RemoveUserSetting(pOldName)
			If $$$ISERR(tSC) Quit
		}

		If (pName'="") {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%SetUserSetting(pName,pValue,pComment,pContext)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.Settings.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;
	}
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $System.Security.Check("%DeepSee_Admin","USE")||
		 $System.Security.Check("%Development","USE")
}

}
