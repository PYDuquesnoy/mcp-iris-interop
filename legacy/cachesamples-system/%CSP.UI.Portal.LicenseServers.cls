/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %LMF

/// System Management Portal - System Administration - License Key 
Class %CSP.UI.Portal.LicenseServers Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.LicenseServers.zen";

Parameter HELPADDRESS = "Home,Licensing,License Server";

Parameter EMSSERVICE = "License";

/// Displayed name of this page.
Parameter PAGENAME = "License Servers";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property TitleCreate As %ZEN.Datatype.string [ InitialExpression = {$$$Text("Create New License Server")} ];

Property TitleEdit As %ZEN.Datatype.string [ InitialExpression = {$$$Text("Edit License Server")} ];

XData Style
{
<style type="text/css">
table.tpTable td {
	border-bottom: 1px solid #F1F0E7;
}
table.tpTable td.caption {
	border-bottom: 1px solid #F1F0E7;
	border-right: 1px solid #F1F0E7;
}
.editTitle {
	font-size: 14px;
	font-weight: bold;	
}
.note {
	font-size: 12px;
	background: #F2F1EC;
	border: 1px solid #4D3926;
	color: #4D3926;
	padding: 10px;
	text-align: left;
	font-weight: bold;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<hgroup>
<vgroup id="idTable" valign="top">
<tableNavBar id="tableBar" showFilter="true" showMaxRows="true" showPageSize="true" tablePaneId="table" 
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter the leading characters of a license server name followed by [Tab] to filter the list. For example: C for all license server names starting with letter 'C'."
containerStyle="padding-bottom:4px;"/>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="Config.LicenseServers"
queryName="List"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
>
<column colName="Name" header="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#','#(%query.Address)#','#(%query.Port)#','#(%query.KeyDirectory)#');"/>
<column colName="Address" header="Host Name/IP Address"/>
<column colName="Port" header="Port"/>
<column colName="KeyDirectory" header="KeyDirectory"/>
<column linkCaption="Delete" link="javascript:zenPage.doDelete('#(%query.Name)#','#(%query.Address)#','#(%query.Port)#');" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
</tablePane>
 <label id="idMultiNote" enclosingClass="note" value="" hidden="true"/>
</vgroup>
<vgroup valign="top" cellStyle="padding-left:10px;">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-left:10px;padding-bottom:2px;"/>
<form id="editForm" hidden="true" cellStyle="padding:5px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="top">
<label id="lblEditTitle" controlClass="editTitle" value=""/>
<text id="txtName" label="Name" hint="Required. Enter a license server name." hintClass="helpText"/>
<text id="txtAddress" label="Host Name/IP Address" hint="Required. Enter a license name (IP address or host name)." hintClass="helpText"/>
<text id="txtPort" label="Port" size="5" hint="Required. Enter a license port." hintClass="helpText"/>
<hgroup id="grpDirectory">
<text id="txtKeyDirectory" label="KeyDirectory" size="50" hint="Enter a directory with key files to be loaded for a local License Server." hintClass="helpText"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('txtKeyDirectory');"/>
</hgroup>
<hidden id="oldName"/>
<html><hr/></html>
<hgroup valign="top">
<button id="btnSave" caption="Save" onclick="zenPage.doSave();"/>
<button id="btnCancel" caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</form>
</vgroup>
</hgroup>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	if (value.indexOf("*") == -1) {
		value += "*";
	}
	table.parameters[0].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);	
	this.doCancel();
}

/// Edit an existing one - load current values
ClientMethod doEdit(name, address, port, dir) [ Language = javascript ]
{
	this.resetMsg('');
	if (name == "") {
		zen("lblEditTitle").setValue(this.TitleCreate);
	} else {
		zen("lblEditTitle").setValue(this.TitleEdit);
	}
	zen("editForm").setHidden(false);
	
	zen("txtName").setValue(name);
	zen("oldName").setValue(name);
	zen("txtAddress").setValue(address);
	zen("txtPort").setValue(port);
	zen("txtKeyDirectory").setValue(dir);
	
	zen("txtName").setProperty("hintClass","helpText");
	zen("txtAddress").setProperty("hintClass","helpText");
	zen("txtPort").setProperty("hintClass","helpText");
	zen("txtKeyDirectory").setProperty("hintClass","helpText");
	zen("txtName").focus();
}

/// Cancel the current edit - hide edit form.
ClientMethod doCancel() [ Language = javascript ]
{
	this.resetMsg();
	zen("editForm").setHidden(true);
}

ClientMethod afterSave(result As %ZEN.proxyObject) [ Language = javascript ]
{
	this.invokeSuper('afterSave',arguments);
	if (result && (result.ok == 1)) {
		zen("table").executeQuery(0);
	}
}

/// Delete a license server.
ClientMethod doDelete(name, address, port) [ Language = javascript ]
{
	this.resetMsg();
	var msg = $$$Text("Are you sure you want to delete this license server?");
	if (confirm(msg+"\n("+name+" / "+address+" / "+port+")")) {
		var result = this.DeleteData(name);
		this.afterSave(result);
	}
}

/// Save edit
ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	if (!this.validate()) {
		this.afterValidate();
		return;
	}
	var proxy = new zenProxy();
	proxy.OldName = zen("oldName").getValue();
	proxy.Name = zen("txtName").getValue();
	proxy.Address = zen("txtAddress").getValue();
	proxy.Port = zen("txtPort").getValue();
	proxy.KeyDirectory = zen("txtKeyDirectory").getValue();
	var result = this.SaveData(proxy);
	this.afterSave(result);
}

ClientMethod validate() [ Language = javascript ]
{
	this.resetMsg('');
	var pass = true;
	if (!this.validateRequired(zen("txtName"),pass,"S")) pass = false;
	if (!this.validateRequired(zen("txtAddress"),pass,"S")) pass = false;
	if (!this.validateRequired(zen("txtPort"),pass,"S")) pass = false;
	return pass;
}

/// User clicked the Browse button.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	var wildcard = "*";
	var Dir = zen(name).getValue();
	var showdirectoryonly = 1;
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard+'&showdirectoryonly='+showdirectoryonly,'FileSelect','resizable,width=680,height=750');
}

/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		if (popupName == "FileSelect") {
			zen("txtKeyDirectory").setValue(value);
			// work around IE bug which disables text boxes by setting focus here
			zen("txtKeyDirectory").focus();
		}
	}
}

ClassMethod DeleteData(Name As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set tSC = ##Class(Config.LicenseServers).Delete(Name)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Saves license server. pProxy.OldName not null indicate this is a modify.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set Properties("Address") = pProxy.Address
		Set Properties("Port") = pProxy.Port
		Set Properties("KeyDirectory") = pProxy.KeyDirectory
		
		If pProxy.OldName = "" {
			Set tSC = ##Class(Config.LicenseServers).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} ElseIf (pProxy.Name '= pProxy.OldName) {
			Set tSC = ##Class(Config.LicenseServers).Delete(pProxy.OldName)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			Set tSC = ##Class(Config.LicenseServers).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##Class(Config.LicenseServers).Modify(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of license servers:")
		
	If $$$EVALKEY {
		Set ..%GetComponentById("idMultiNote").value = $$$TextHTML("NOTE: License servers are not used with Evaluation licenses.")
		Set ..%GetComponentById("idMultiNote").hidden = 0
	}

	If ..IsEMSReadOnly {
		Set column = ..%GetComponentById("NameCol")
		Set column.link = ""
		Set column.onclick = ""
	}

	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Licensing","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE))))
	
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Set pCommands(1) = $LB("btnNew",$$$Text("Create License Server"),$$$Text("Create a new license server"),"zenPage.doEdit('','','','');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("License Servers")
}

}
