/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Machine Learning Configurations
Class %CSP.UI.Portal.ML.Configurations Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Class name of application this page belongs to.
/// Parameter APPLICATION = "%CSP.UI.Portal.Application";
/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "ML Configurations";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ML.Configurations.zen";

Parameter HELPADDRESS = "System Administration,Configurations,Machine Learning Configurations";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property DefaultConfig As %String [ InitialExpression = {##class(%SYS.ML.Configuration).%GetSystemDefault()} ];

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.ML.Configuration.zen",,1)} ];

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

Property colDetails As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Details")} ];

Property colEdit As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Edit")} ];

XData Style
{
<style type="text/css">
.title { 
	color: #000000;
	font-weight: 600;
	font-size: 18px;
	text-align: center;
	padding-bottom: 4px;
}
.caption { 
	font-weight: bold;	
	font-size: 14px;
	padding-top: 10px;
	border-top: #CBCBCB solid 1px; 
}
.data { 
	font-size: 14px;
	padding: 8px 20px;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<hgroup id="thisPage">
<vgroup id="tableGroup" valign="top">
<hgroup labelPosition="left" cellStyle="padding:6px;" >
<select id="defaultConfig" label="System Default ML Configuration" 
queryClass="%SQL.Manager.Catalog" queryName="MLConfigurations"
showEmpty="false" 
 onchange="zenPage.changeDefault();"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>
</hgroup>
<vgroup id="idTable" valign="top">
<tableNavBar id="tableBar" showFilter="true" showMaxRows="true" showPageSize="true" tablePaneId="table" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" cellSpacing="2"
queryClass="%SQL.Manager.Catalog"
queryName="MLConfigurationsFull"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
multiSelect="false"
showValueInTooltip="true"
showZebra="true"
valueColumn="NAME"
useSnapshot="true"
pageSize="0"
>
<parameter value="#(%page.Filter)#"/>
<column colName="NAME" header="Name" id="NameCol" link="#" title="Click a Name to edit" onclick="javascript:zenPage.doEdit('#(%query.NAME)#');"/>
<column colName="TYPE" header="Provider"/>
<column colName="DESCRIPTION" header="Description"/>
<column colName="OWNER" header="Owner"/>
<column colName="USING" header="Using" title="USING clause for this configuration"/>
<column linkCaption="Details" link="javascript:zenPage.doDetails('#(%query.NAME)#');" />
<column id="colDelete" linkCaption="Delete" link="javascript:zenPage.deleteSetting('#(%query.NAME)#');" linkConfirm="Are you sure you want to delete configuration '%1'?" />
 
<!-- While Type is H2O or DataRobot, there are extra fields that can be viewed through Details -->
<condition colName="TYPE" predicate="EQ" value="AutoML" cellStyle="disabled" targetCol="#(%page.colDetails)#"/> 
<condition colName="TYPE" predicate="EQ" value="H2O" cellStyle="disabled" targetCol="#(%page.colDetails)#"/> 
<condition colName="TYPE" predicate="EQ" value="PMML" cellStyle="disabled" targetCol="#(%page.colDetails)#"/> 

 </tablePane>
</vgroup>
</vgroup>  <!-- end of tableGroup -->
<spacer width="10px"/>
<vgroup id="detailGroup" hidden="true" valign="top">
<jsonProvider id="jsonConfig" OnGetTargetObject="GetMLConfig"/>
<form id="form1"
autocomplete="false"
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top" >
<html>
<div id="htmlContent">
</div>
</html>
</form>
</vgroup>  <!-- end of formGroup -->
</hgroup>
</pane>
}

ClientMethod changeDefault() [ Language = javascript ]
{
	var ok = this.SaveDefault(zen('defaultConfig').getValue());
	if (ok != 1) {
		this.showMsg(ok,1);
	} else {
		this.showMsg($$$Text("Default ML Configuration saved successfully."),2);	
	}
}

ClassMethod SaveDefault(defaultConfig As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(%SYS.ML.Configuration).%SetSystemDefault(defaultConfig)
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of machine learning configurations:")
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Machine Learning Configurations")
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnAdd",$$$Text("Create New Configuration"),$$$Text("Create a new machine learning configuration"),"zenPage.doNew(0);")

	Quit $$$OK
}

ClientMethod doDetails(name) [ Language = javascript ]
{
	try {
		var json = this._json;
	 	if (name.length > 0) {
		 	//alert(JSON.stringify(json));
		 	var html = [];
		 	var children = json.children;
		 	if (children) {
			 	for (i=0;i<children.length;i++) {
				 	var config = children[i];
				 	if (config.Name == name) {
					 	var displayList = ["AutoML","H2O","DataRobot","PMML"];
					 	var typeText = displayList[config.Type];
					 	html.push('<div class="title">'+$$$FormatText($$$Text("Configuration Details for %1 "), name)+'</div>');
					 	html.push('<div class="caption">'+$$$Text("Provider") + '</div><div class="data">'+typeText+'</div>');
					 	html.push('<div class="caption">'+$$$Text("Description") + '</div><div class="data">'+config.Description+'</div>');
					 	html.push('<div class="caption">'+$$$Text("Owner") + '</div><div class="data">'+config.Owner+'</div>');
					 	if (config.Type == 1) {
						 	html.push('<div class="caption">'+$$$Text("Java TLS Configuration File") + '</div><div class="data">'+config.javaTlsConfigFile+'</div>');
					 	} else if (config.Type == 2) {
					 		html.push('<div class="caption">'+$$$Text("URL") + '</div><div class="data">'+config.url+'</div>');
					 		html.push('<div class="caption">'+$$$Text("API Token") + '</div><div class="data">'+config.apiToken+'</div>');
					 	}
				 	}	
			 	}	
		 	}
		 	document.getElementById('htmlContent').innerHTML = html.join('');
		 	zen('detailGroup').setHidden(false);
	 	} else {
		 	zen('detailGroup').setHidden(true);
	 	}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(name) [ Language = javascript ]
{
	try {	
		var url = this.EditPage+"PID="+encodeURIComponent(name);
		document.location = url;
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doNew() [ Language = javascript ]
{
	try {
		this.gotoPage(this.EditPage+"?isNew=1");
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Delete existing configuration.
ClientMethod deleteSetting(PID) [ Language = javascript ]
{
	try {
		// need to temparily make changesMade to false so that onunload will not prompt
		var ok = this.DeleteItem(PID);
		if (ok == 1) {
			var table = zenPage.getComponentById('table');
			table.setProperty("selectedIndex",-1);
			table.executeQuery();
		} else {
			alert(ok);
		}
	} catch (ex) {
		alert("Error: ");	
	}
}

/// Call server delete method.
ClassMethod DeleteItem(PID) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	Set tSC = ##class(%SYS.ML.Configuration).%Remove(PID)
	If $$$ISERR(tSC) {
		Set ok = $System.Status.GetErrorText(tSC)
	} Else {
		Set ok = 1
	}
	Quit ok
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","JS")
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	table.parameters[0].value = value;
	this.Filter = value;
	table.executeQuery();
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

/// Disable save button for EMS-managed pages.
/// Be sure to use this.invokeSuper('onloadHandler',arguments); when overriding.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');
 	zen('defaultConfig').setValue(this.DefaultConfig);
 	zen('defaultConfig').setProperty('originalValue',this.DefaultConfig);
 	this._json = zen('jsonConfig').getContentObject();
}

/// Return config data if a configname is given. 
Method GetMLConfig(ByRef pParms As %String, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.ML.API).GetMLConfigs(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
