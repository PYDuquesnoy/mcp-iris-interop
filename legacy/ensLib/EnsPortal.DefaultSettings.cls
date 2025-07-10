/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Zen based UI for InterSystems IRIS Interoperability 
Class EnsPortal.DefaultSettings Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// User needs READ permissions on the %Ens_SystemDefaultConfig resource to view this page.
Parameter RESOURCE = "%Ens_SystemDefaultConfig:READ";

/// User needs WRITE permissions on the %Ens_SystemDefaultConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_SystemDefaultConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "System Default Settings";

/// The text that is shown in TitlePane 
Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Configuration Defaults")} ];

/// Message that is built with the namespace in it.
Property msgTable As %ZEN.Datatype.caption;

Property msgRestrictedSetting As %ZEN.Datatype.caption [ InitialExpression = {##class(EnsPortal.DefaultSettings).restrictedMessage()} ];

XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup valign="top">
<spacer width="20"/>
<vgroup>
<spacer height="10" />
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<spacer height="10" />
<vgroup>
<tablePane id="table"
cellSpacing="2"
fixedHeaders="false"
queryClass="EnsPortal.DefaultSettings"
queryName="Enumerate"
maxRows="5000"
showZebra="true"
valueColumn="ID"
useSnapshot="false"
rowSelect="true"
extraColumnWidth="10"

>
<parameter id="filter" value=""/>
<parameter id="queryMethod" value="EnumerateSettings"/>
<parameter id="queryClass" value="Ens.Config.DefaultSettings"/>
<column colName="ID" hidden="true"/>
<column colName="ProductionName" header="Production Name" />
<column colName="ItemName" header="Item Name" />
<column colName="HostClassName" header="Host Class Name" />
<column colName="SettingName" header="Setting Name" />
<column colName="SettingValue" header="Setting Value" />
<column colName="Deployable" header="Deployable" OnDrawCell="FormatDeployable" />
</tablePane>
</vgroup>
<spacer height="10"/>
</vgroup>
</hgroup>
</pane>
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "ID,ProductionName,ItemName,HostClassName,SettingName,SettingValue,Deployable") [ SqlProc ]
{
}

XData Style
{
<style type="text/css">

table.tpTable {
	font-size: 13px;
}

table.tpTable tr.tpEven {
	background: white;
}

table.tpTable tr.tpOdd {
	background: #F1F0E7;
}

table.tpTable td {
	padding-right: 20px;
	padding-left: 2px;
	text-align: left;
}

</style>
}

/// Method to convert the Deployable field from 0/1 to "No/Yes".
Method FormatDeployable(table As %ZEN.Component.tablePane, depl As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
 	Set val = %query(depl)
 	If val {
	 	Write "Yes"
 	}
 	Else {
	 	Write "No"
 	}
	Quit $$$OK
}

/// Enable edit fields. Clear table selection and initialize all fields.
ClientMethod addSetting() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }

	var page = "EnsPortal.DefaultSetting.cls?isNew=1";
	this.gotoPage(page);
}

/// Delete existing Setting definition.
ClientMethod deleteSetting() [ Language = javascript ]
{
	try {
		if (!this.checkEdit()) {
			return false;
		}

		var pid = zenPage.checkTable();
		if (pid == '') {
			return false;
		}

		if (!confirm($$$Text("Are you sure you want to delete this System Default Setting?"))) {
			return false;
		}

		var ok = this.DeleteData(pid);
		if (ok == 1) {
			zenPage.getComponentById("table").setProperty("selectedIndex",-1);
			this.refreshTable();
		} else {
			alert(ok);
		}
	} catch (ex) {
		alert("Error in deleteSetting: " + ex);
	}
}

/// Edit existing Setting definition.
ClientMethod editSetting() [ Language = javascript ]
{
	try {
		if (!this.checkEdit()) {
			return false;
		}

		var pid = zenPage.checkTable();
		if (pid == '') {
			return false;
		}

		var page = "EnsPortal.DefaultSetting.cls?PID="+encodeURIComponent(pid);
		this.gotoPage(page);
	} catch (ex) {
		alert("Error in editSetting: " + ex);
	}
}

/// Check if table is populated and there is a row selected.
ClientMethod checkTable() [ Language = javascript ]
{
	var tbl = zenPage.getComponentById('table');
	if (tbl.rowCount == 0) {
		alert($$$Text("There are no System Default Settings defined"));
		return "";
	}
	if (tbl.getProperty('selectedIndex') == -1) {
		alert($$$Text("Please select a row first"));
		return "";
	}
	if (!this.CanEditSettingBasedOnId(tbl.getProperty('value'))) {
		alert(this.msgRestrictedSetting);
		return "";
	}

	return tbl.getProperty('value');
}

/// This method is called after a Setting is saved or deleted.
ClientMethod refreshTable() [ Language = javascript ]
{
	var table = zenPage.getComponentById("table");
	table.executeQuery();
}

/// This callback is called after the server-side page
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set msgTable = $$$FormatText($$$Text("System Default Settings currently defined in namespace %1:"),$Namespace)
	Set ..%GetComponentById("Text1").value = msgTable
	Set %page.msgTable = msgTable

	Quit $$$OK
}

/// Delete an association context
ClassMethod DeleteData(pid) As %String [ ZenMethod ]
{
	#dim tSC = $$$OK
	#dim ok = 1

	Set $ZT="Error"
	If '$system.Security.Check("%Ens_SystemDefaultConfig","WRITE") {
		Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
		Quit $ZCVT($system.Status.GetErrorText(tSC),"O","JS")
	}

	#; JS checks before calling this method but re-check 
	If '##class(EnsPortal.DefaultSettings).canEditAllSettings() && '##class(EnsPortal.DefaultSettings).CanEditSettingBasedOnId(pid) {
		Quit ..restrictedMessage()
	}

	Set tSC = ##class(Ens.Config.DefaultSettings).%DeleteId(pid)
	If $$$ISERR(tSC) {
		Set ok = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	}

	Quit ok
Error	//
	Set $ZT=""
	Set tSC = $$$SystemError
	Quit $ZCVT($system.Status.GetErrorText(tSC),"O","JS")
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("System Default Settings","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,disabled)
	Set pCommands(1) = $LB("btnAdd",$$$Text("New"),$$$Text("Add a new System Default Setting definition"),"zenPage.addSetting();")
	Set pCommands(2) = $LB("btnEdit",$$$Text("Edit"),$$$Text("Edit an existing System Default Setting definition"),"zenPage.editSetting();")
	Set pCommands(3) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Remove an existing System Default Setting definition"),"zenPage.deleteSetting();")

	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	self.document.getElementById("command_btnDelete").className = "commandButtonRemove";
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "DeleteData": ..#EDITRESOURCE, : "")
}

ClassMethod checkIfAllSettings(Output pAllSettings As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC = $$$OK
	#dim twebSession = ($Data(%session)#2) && $IsObject(%session)

	If twebSession && ($Data(%session.Data("EnsUIRestrict","SDS","AllSettings"),pAllSettings)#2) {

		 Quit tSC

	}

	If $$$IOwnAllRole {

		If twebSession Set %session.Data("EnsUIRestrict","SDS","AllSettings") = 1
		Quit tSC

	}

	If '$SYSTEM.Security.Check("%Ens_RestrictedUI_SystemDefaultSettings","USE") {

		If twebSession Set %session.Data("EnsUIRestrict","SDS","AllSettings") = 1

	} Else {

		Set pAllSettings = 0
		If twebSession Set %session.Data("EnsUIRestrict","SDS","AllSettings") = 0

	}

	Quit tSC
}

ClassMethod canEditSettingRow(pRow As %String) As %Boolean [ Internal ]
{
	#dim tSettingName = $ListGet(pRow,5)
	Quit ..canEditSettingName(tSettingName)
}

/// This checks if canEditAllSettings
ClassMethod canEditSettingName(pSettingName As %String) As %Boolean [ Internal ]
{
	#dim tYes = 1
	#dim tNo = 0
	#dim tAnswer = 1

	#dim twebSession = ($Data(%session)#2) && $IsObject(%session)

	If (pSettingName'="") {

		If pSettingName = "Enabled" && '$SYSTEM.Security.Check("%Ens_ConfigItemRun","USE") Quit tNo

		If twebSession {

			If ..canEditAllSettings() {

				#;Allows this API to be called on own
				Quit tYes

			} ElseIf pSettingName = "*" {

				#; A restricted user cannot see or set  wild card setting name
				Quit tNo

			} ElseIf ($Data(%session.Data("EnsUIRestrict","SDS","AllowedSettings",pSettingName),tAnswer)#2) {

				Quit tAnswer

			} ElseIf '($SYSTEM.Security.Check("%Ens_SystemDefaultSettings_"_pSettingName,"USE")) {

				Set %session.Data("EnsUIRestricted","SDS","AllowedSettings",pSettingName) = tNo
				Quit tNo

			} Else {

				Set %session.Data("EnsUIRestricted","SDS","AllowedSettings",pSettingName) = tYes
				Quit tYes

			}

		} Else {

			#; No Web session caching
			#dim tAllSettings
			#dim tSC = ..checkIfAllSettings(.tAllSettings)

			If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)

			If tAllSettings Quit tYes

			If pSettingName = "*" Quit tNo

			Quit $SYSTEM.Security.Check("%Ens_SystemDefaultSettings_"_pSettingName,"USE")

		}

	}

	#; Return yes for empty string even though empty string cannot be set
	Quit tYes
}

/// Web Session method only
ClassMethod canEditAllSettings() As %Boolean [ Internal ]
{
	#dim tSC = $$$OK
	#dim tAllSettings

	If '$Data(%session.Data("EnsUILimit","SDS","AllSettings"),tAllSettings) {

		Set tSC = ..checkIfAllSettings(.tAllSettings)

		If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)

	}

	Quit tAllSettings
}

ClassMethod CanEditSettingBasedOnId(ID) As %Boolean [ Internal, ZenMethod ]
{
	Try {

		#dim tSettingName = ##class(Ens.Config.DefaultSettings).%OpenId(ID).SettingName

	} Catch {

		Return 0

	} 

	Quit ..canEditSettingName(tSettingName)
}

ClassMethod restrictedMessage() As %String [ Internal ]
{
	Quit $$$TextJS("Your System Administrator has not allowed you to edit this Setting Name")
}

}
