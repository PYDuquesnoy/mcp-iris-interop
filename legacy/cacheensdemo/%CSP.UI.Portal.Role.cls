/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Edit Role
Class %CSP.UI.Portal.Role Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

///  Displayed name of this page.
Parameter PAGENAME = "Edit Role";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Role.zen";

Parameter HELPADDRESS = "System Administration,Security,Users,Edit Role";

Parameter EMSSERVICE = "Security";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Roles.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property CurrResources As %String;

Property CurrTab As %Integer [ InitialExpression = 0 ];

Property EditDisabled As %Boolean;

Property IsDB As %Boolean [ InitialExpression = 0 ];

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property IsNewSave As %Integer(ZENURL = "new");

Property IsSystem As %Boolean [ InitialExpression = 0 ];

Property NumTabs As %Integer [ InitialExpression = 9 ];

XData Style
{
<style type="text/css">
.Text2:first-letter {
    font-size:1.4em;
}
.Text2 {
    font-size:13px;
    max-width:575px;
    margin-bottom:5px;
}
.sectionLabel {
	font-size:13px;
	font-weight:normal;
	color:black;
	margin-top:15px;
}
.innerTable {
	border:1px solid #888;
}
.arrowButton {
	cursor:pointer;
	margin:5px 0;
}
.fieldHint {
    color:gray;
    font-size:12px;
    padding-left:10px;
}
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
</style>
}

XData SVGStyle
{
<style type="text/css">
.tabBarBackground {
	fill:white;
	stroke:white;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<link id="newLink" href="%25CSP.UI.Portal.Role.zen?PID=" caption="Click here to create a new role." hidden="true" containerStyle="padding-bottom:4px;"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Members:Assigned To:SQL Admin Privileges:SQL Tables:SQL Views:SQL Procedures:SQL ML Configurations:SQL Foreign Servers"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<!-- Page 1: Role Edit -->
<vgroup id="page_1" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">
<form id="fld">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="Name" label="Name" size="30" hint="Required." onchange="zenPage.doModified();"/>
<select id="CopyRole"
label="Copy from"
onchange="zenPage.doCopyRole(zenThis.getValue());zenPage.doModified();"
title="Choose an existing role to copy"
/>
<text id="Description" label="Description" size="60" onchange="zenPage.doModified();"/>
<checkbox id="EscalationOnly" label="Escalation Only" onchange="zenPage.doModified();"/>
<html id="Privileges" label="Privileges" OnDrawContent="DrawResources"/>
</group>
</form>
</vgroup>

<!-- Page 2: Members -->
<vgroup id="page_2" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<RoleMemberTab PID="#(%page.PID)#" readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 3: Assigned To -->
<vgroup id="page_3" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<UserRoles PID="#(%page.PID)#" type="RoleRole" readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 4: SQL Privileges -->
<vgroup id="page_4" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLPrivs"/>
<SQLPrivileges id="SQLPrivs" PID="#(%page.PID)#"/>
</vgroup>

<!-- Page 5: SQL Tables -->
<vgroup id="page_5" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLTables"/>
<SQLTables id="SQLTables" pageType="Roles" type="TABLE" tab="4" PID="#(%page.PID)#" showSystemBox="true"/>
</vgroup>

<!-- Page 6: SQL Views -->
<vgroup id="page_6" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLViews"/>
<SQLTables id="SQLViews" pageType="Roles" type="VIEW" tab="5" PID="#(%page.PID)#" showSystemBox="true"/>
</vgroup>

<!-- Page 7: SQL Procedures -->
<vgroup id="page_7" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLProcs"/>
<SQLTables id="SQLProcs" pageType="Roles" type="STORED PROCEDURE" tab="6" PID="#(%page.PID)#" showSystemBox="true"/>
</vgroup>

<!-- Page 8: SQL ML Configurations -->
<vgroup id="page_8" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLMLConfigs"/>
<SQLTables id="SQLMLConfigs" pageType="Roles" type="ML CONFIGURATION" tab="7" PID="#(%page.PID)#" showSystemBox="false"/>
</vgroup>

<!-- Page 9: SQL Foreign Servers -->
<vgroup id="page_9" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;">
<html OnDrawContent="DrawTabHeader" seed="SQLForeignServers"/>
<SQLTables id="SQLForeignServers" pageType="Roles" type="FOREIGN SERVER" tab="8" PID="#(%page.PID)#" showSystemBox="false"/>
</vgroup>

</pane>
}

/// Set focus to the Name or Description field, disable fields if DispatchClass is defined.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.PID) {
		if (this.EditDisabled) {
			this.disableCommandButton("btnSave");
			return;
		} else {
			zen("Description").focus();
		}
	} else {
		zen("Name").focus();
	}
	
	if (this.IsNewSave != 0) {
		this.showMsg($$$Text('Role saved.'),false);
		var newLink = zen('newLink');
		newLink.setHidden(false);
		return;
	}
	
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		this.CurrTab = hash;
		zen('tabBar').tabClicked(hash);
	}
	
	this.resetMsg();
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
		// find size of window
		var winWidth = zenGetWindowWidth();	
		// set the svg and tabs the right size
		zen("svgTabArea").setProperty("width",winWidth-50);
		zen("tabBar").setProperty("width",winWidth-50);
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((popupName == 'ResourceAdd') || (popupName == 'ResourceEdit')) {
			this.CurrResources = value;
			zen('Privileges').refreshContents();
		} else if (popupName == 'ResourceEditCopyFrom') {
			this.setModified(false);
			var newPID = encodeURIComponent(zenTrim(zen('Name').getValue()));
			var url = zenLink('%25CSP.UI.Portal.Role.zen?PID='+newPID+'&new=1');
			this.gotoPage(url);
		} else {
			var tabType = popupName.slice(0,popupName.indexOf("-"));
			switch(tabType) {
				case 'TABLE':
					zen('SQLTables').refreshContents();
					break;
				case 'VIEW':
					zen('SQLViews').refreshContents();
					break;
				case 'STORED PROCEDURE':
					zen('SQLProcs').refreshContents();
					break;
				case 'ML CONFIGURATION':
					zen('SQLMLConfigs').refreshContents();
					break;
				case 'FOREIGN SERVER':
					zen('SQLForeignServers').refreshContents();
					break;
				default:
					break;
			}
		}
	} catch (ex) {
		alert("Error: " + ex);
	}

	return true;
}

ClientMethod tabChanged(index) [ Language = javascript ]
{
	this.resetMsg();
	zen('newLink').setHidden(true);
	for (var i=0;i<this.NumTabs;i++) {
		var option = i + 1;
		if (i == index) {
			zen("page_"+option).setHidden(false);
		} else {
			zen("page_"+option).setHidden(true);
		}				
	}
	if (index == 0) {
		if (!this.EditDisabled) {
			this.enableCommandButton("btnSave");
		}
	} else {
		this.disableCommandButton("btnSave");
	}
	document.location.hash = index;
	this.CurrTab = index;
}

ClientMethod changeNS(ns) [ Language = javascript ]
{
	var tabArray = ["SQLPrivs","SQLTables","SQLViews","SQLProcs","SQLMLConfigs","SQLForeignServers"];
	for (var i = 0; i < tabArray.length; i++) {
		var tab = zen(tabArray[i]);
		tab.namespace = ns;
		tab.refreshContents();
	}
}

ClientMethod doEditResource(resource, permissions) [ Language = javascript ]
{
	var popupName = 'ResourceEdit';
	if (this.PID == '') {
		if (!this.validate()) {
			this.afterValidate();
			return false;
		}
		popupName = 'ResourceEditCopyFrom';
	}
	
	var url = zenLink('%CSP.UI.Portal.Dialog.RoleResourceEdit.zen?PID='+encodeURIComponent(this.PID)+'&resource='+encodeURIComponent(resource)+'&permissions='+encodeURIComponent(permissions));
	if (this.PID == '') {
		var copyFromPID = encodeURIComponent(zen('CopyRole').getValue());
		var copyNewPID = encodeURIComponent(zenTrim(zen('Name').getValue()));
		var copyNewDesc = encodeURIComponent(zenTrim(zen('Description').getValue()));
		var escalationOnly = encodeURIComponent(zen("EscalationOnly").getValue()? 1: 0);
		url += '&copyFromPID='+copyFromPID+'&copyNewPID='+copyNewPID+'&copyNewDesc='+copyNewDesc+'&escalationOnly='+escalationOnly;
	}
	zenLaunchPopupWindow(url,popupName,'status,scrollbars,resizable=yes,width=600,height=400');
}

ClientMethod doAddResource() [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Dialog.RoleResourceNew.zen?PID='+encodeURIComponent(this.PID));
	zenLaunchPopupWindow(url,'ResourceAdd','status,scrollbars,resizable=yes,width=400,height=600');
}

ClientMethod doDeleteResource(resource) [ Language = javascript ]
{
	this.resetMsg();
	
	var msg = $$$Text('Are you sure you want to delete resource %1?');
	msg = msg.replace(/%1/g,resource);
	if (!confirm(msg)) return;
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	
	var copyFrom = false;
	if (this.PID == '') {
		if (!this.validate()) {
			this.afterValidate();
			return;
		}
		proxy.Name = zen('Name').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.CopyRole = zen("CopyRole").getValue();
		proxy.EscalationOnly = zen('EscalationOnly').getValue();

		var result = this.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			return;
		}
		proxy.PID = proxy.Name;
		copyFrom = true;
	}

	proxy.ResourceName = resource;
	proxy.CurrResources = this.CurrResources;	
	var result = this.DeleteResource(proxy);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage,true);
	} else {
		if (copyFrom) {
			this.setModified(false);
			var url = zenLink('%25CSP.UI.Portal.Role.zen?PID='+encodeURIComponent(proxy.Name)+'&new=1');
			this.gotoPage(url);
			return;
		} else {
			this.CurrResources = result.NewResourceList;
			zen('Privileges').refreshContents();
		}
	}
}

ClientMethod doCopyRole(role) [ Language = javascript ]
{
	if (role != '') {
		zenPage.CopyRole(role);
		zen('Privileges').refreshContents();
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSave")) return;
	this.resetMsg();
	zen('newLink').setHidden(true);
	
	if (!this.validate()) {
		this.afterValidate();
		return;
	}
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zen('Name').getValue();
	proxy.Description = zen('Description').getValue();
	proxy.CurrResources = this.CurrResources;
	proxy.CopyRole = zen("CopyRole").getValue();
	proxy.EscalationOnly = zen("EscalationOnly").getValue();
	
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		// error case
		this.showMsg(result.ErrorMessage,true);
		return;
	}
	this.setModified(false);
	if (proxy.PID == '') {
		var url = zenLink('%25CSP.UI.Portal.Role.zen?PID='+encodeURIComponent(proxy.Name)+'&new=1');
		this.gotoPage(url);
		return;
	}
	// saved existing app
	this.showMsg($$$Text('Role saved.'),false);
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var pass = true;
	try {
		var oldSynchronousMode = zenSynchronousMode;
		zenSynchronousMode = true;
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		zenSynchronousMode = oldSynchronousMode;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	
	return pass;
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		If pProxy.PID = "" {
			If pProxy.CopyRole '= "" {
				Set tSC = ##class(Security.Roles).Copy(pProxy.CopyRole,pProxy.Name,pProxy.Description, pProxy.EscalationOnly)
			} Else {
				Set tSC = ##class(Security.Roles).Create(pProxy.Name,pProxy.Description,pProxy.CurrResources,,pProxy.EscalationOnly)
			}
		} Else {
			Set Properties("Description") = pProxy.Description
			Set Properties("EscalationOnly") = pProxy.EscalationOnly
			Set tSC = ##class(Security.Roles).Modify(pProxy.Name,.Properties)
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		If ($G(inTrans) = 1) TROLLBACK 1
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod DeleteResource(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ErrorMessage = ""
	
	Try {
		// rebuild the resource list, removing the deleted resource
		Set Properties("Resources") = ""
		For i=1:1:$LENGTH(pProxy.CurrResources,",") {
			Set Resource = $P(pProxy.CurrResources,",",i)
			If ($P(Resource,":",1) = pProxy.ResourceName) {
				// matched resource
				continue
			}
			If Properties("Resources") '= "" Set Properties("Resources") = Properties("Resources")_","
			Set Properties("Resources") = Properties("Resources")_Resource
		}
		Set tProxy.NewResourceList = Properties("Resources")
		
		Set tSC = ##class(Security.Roles).Modify(pProxy.PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If tProxy.ErrorMessage = "" {
			Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		}
	}
	Quit tProxy
}

Method CopyRole(Role As %String) As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.Roles).Get(Role,.Properties)
	Kill Properties("Name")
	Do ..PopulateFields(.Properties)
	Quit $$$OK
}

Method DrawResources(pSeed As %String) As %Status
{
	Set Resources = ..CurrResources
	&html<
		<div>
		<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">
		<thead class="tpHead">
			<th nowrap>#($$$TextHTML("Resource"))#</th>
			<th nowrap>#($$$TextHTML("Permission"))#</th>
			<th>&nbsp;</th><th>&nbsp;</th>
		</thead>
		<tbody class="tpBody">>
	Set nRow = 0
	If Resources = "" {
		&html<<tr><td colspan="4">#($$$TextHTML("None defined"))#.</td></tr>>
	} Else {
		For nRow=1:1:$LENGTH(Resources,",") {
			Set sData = $P(Resources,",",nRow)
			Set rowClass = $CASE(nRow#2,1:"tpOdd",:"tpEven")
			Set rid0 = "rid0_"_nRow
			Set rid1 = "rid1_"_nRow
			Set rid2 = "rid2_"_nRow
			Set data1 = $P(sData,":",1)
			Set data2 = $P(sData,":",2)
			&html<
			<tr id="#(rid0)#" class="#(rowClass)#">
				<td id="#(rid1)#" class="tpStr" nowrap>#(..EscapeHTML(data1))#</td>
				<td id="#(rid2)#" class="tpStr" nowrap>#($S(data2="":"&nbsp;",1:..EscapeHTML(data2)))#</td>>
			If ((+..IsDB=0) && '..IsEMSReadOnly) {
				&html<
				<td class="tpAction" style="text-align:center;"><a href="##(..CurrTab)#" onclick="zenPage.doEditResource('#(data1)#','#(data2)#')">#($$$TextHTML("Edit"))#</a></td>
				<td class="tpAction" style="text-align:center;"><a href="##(..CurrTab)#" onclick="zenPage.doDeleteResource('#(data1)#')">#($$$TextHTML("Delete"))#</a></td>>
			} Else {
				&html<
				<td style="text-align:center;"> - </td><td style="text-align:center;"> - </td>>
			}
			&html<
			</tr>>	
		}
	}
	&html<<input type="hidden" name="TotalResource" id="TotalResource" value="#(nRow)#">>
	If ..PID'="",..PID'="%All",+..IsDB=0,'..IsEMSReadOnly {
		Set addCaption = $$$TextHTML("Add...")
		&html<<tr><td colspan="4" align="center"><input type="button" name="Add" value="#(addCaption)#" onclick="zenPage.doAddResource();"></td></tr>>
	}
 	&html<</tbody></table>>
 	
 	Quit $$$OK
}

/// Fill in form fields. Used when loading the page for edit or when choosing a copy from role during creation
Method PopulateFields(ByRef Properties As %String) As %Status
{
	// Loop to set all field values
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			Set Component.value = Properties(tProperty)
			If (..IsEMSReadOnly || ..EditDisabled) Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Set ..CurrResources = $G(Properties("Resources"))
		
	Quit $$$OK
}

Method DrawTabHeader(pSeed As %String) As %Status
{
	&html<<div class="Text2">>
	If pSeed = "SQLPrivs" {
		Write $$$FormatText($$$TextHTML("Role %1 is assigned the following SQL administrative privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLTables" {
		Write $$$FormatText($$$TextHTML("Role %1 is assigned the following SQL table privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLViews" {
		Write $$$FormatText($$$TextHTML("Role %1 is assigned the following SQL view privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLProcs" {
		Write $$$FormatText($$$TextHTML("Role %1 is assigned the following SQL procedure privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLMLConfigs" {
		Write $$$FormatText($$$TextHTML("Role %1 is assigned the following SQL ML Configuration privileges:"),..EscapeHTML(..PID))
	} ElseIf pSeed = "SQLForeignServers" {
		Write $$$FormatText($$$TextHTML("Role %1 is assigned the following SQL Foreign Server privileges:"),..EscapeHTML(..PID))
	}
	
	&html<</div>>
	Quit $$$OK
}

Method PopulateNSDropdown(Type As %Integer, Output displayList As %String, Output valueList As %String) As %Status
{
	Set (displayList,valueList) = ""
	
	Do List^%SYS.NAMESPACE(.Namespaces,Type)
	Set name = $O(Namespaces(""))
  	While name '= "" {
	  	#; Exclude the ones that are no longer enabled
		If $lg(Namespaces(name),1) '= 1 {
			Set name = $O(Namespaces(name))
			Continue
		}
	  	If valueList = "" {
			Set valueList = name
			Set displayList = ..EscapeHTML(name)
		} Else {
			Set valueList = valueList_","_name
			Set displayList = displayList_","_..EscapeHTML(name)
		}
   		Set name = $O(Namespaces(name))
  	}
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ..PopulateNSDropdown(5,.displayList,.valueList)
	If $$$ISERR(tSC) Quit tSC
	Set (..%GetComponentById("SQLPrivs").nsDisplayList,..%GetComponentById("SQLTables").nsDisplayList,..%GetComponentById("SQLViews").nsDisplayList,..%GetComponentById("SQLProcs").nsDisplayList,..%GetComponentById("SQLMLConfigs").nsDisplayList,..%GetComponentById("SQLForeignServers").nsDisplayList) = displayList
	Set (..%GetComponentById("SQLPrivs").nsValueList,..%GetComponentById("SQLTables").nsValueList,..%GetComponentById("SQLViews").nsValueList,..%GetComponentById("SQLProcs").nsValueList,..%GetComponentById("SQLMLConfigs").nsValueList,..%GetComponentById("SQLForeignServers").nsValueList) = valueList
	
	If ..PID = "" {
		// Creating new role
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the following form to create a new role definition:")
		Set ..%GetComponentById("svgTabArea").hidden = 1
		Set ..%GetComponentById("svgTabArea").height = 0
		
		// Populate the Copy From dropdown
		Set tRS = ##class(%ResultSet).%New("Security.Roles:List")
		Do tRS.Execute()
		Set valueList = ""
		While tRS.Next() {
			Set name = tRS.GetData(1)
			If valueList = "" {
				Set valueList = name
			} Else {
				Set valueList = valueList_","_name
			}
		}
		Set (..%GetComponentById("CopyRole").displayList,..%GetComponentById("CopyRole").valueList) = valueList
	} Else {
		// Editing existing role
		
		// System defined roles can't have the description modified
		If ($$$IsSystemRole(..PID)||$$$IsSystemLegacyRole(..PID)) {
			Set ..IsSystem = 1
		}
		If ($e(..PID,1,$L($$$DBResourcePrefix))=$$$DBResourcePrefix) {
			Set ..IsDB = 1
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("View system defined role definition %1:"),..PID)
		} Else {
			Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Edit definition for role %1:"),..PID)
		}
		
		If ..IsSystem || ..IsDB {
			Set ..EditDisabled = 1
		}
		
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("Name").disabled = 1
		Set ..%GetComponentById("EscalationOnly").disabled = 1
		
		Set tSC = ##class(Security.Roles).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ..%GetComponentById("svgTabArea").hidden = 1
			Set ..%GetComponentById("svgTabArea").height = 0
			Quit $$$OK
		}

		Do ..PopulateFields(.Properties)
		
		Set ..%GetComponentById("CopyRole").hidden = 1
		Set ..%GetComponentById("CopyRole").containerStyle = "padding:0;"
		If ..EditDisabled {
			Set ..%GetComponentById("Description").disabled = 1
		}
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

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Roles","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Role")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
