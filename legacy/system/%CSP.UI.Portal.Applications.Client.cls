/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Edit Client Application
Class %CSP.UI.Portal.Applications.Client Extends %CSP.UI.Portal.Applications.EditTemplate [ System = 4 ]
{

///  Displayed name of this page.
Parameter PAGENAME = "Edit Client Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.Client.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Client Applications";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Applications.ClientList.zen";

Property ApplicationType As %Integer [ InitialExpression = {$$$AppTypeExecutable} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<link id="newLink" href="%25CSP.UI.Portal.Applications.Client.zen?PID=" caption="Click here to create a new client application." hidden="true" containerStyle="padding-bottom:4px;"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Application Roles:Matching Roles"
 onChange="zenPage.tabChanged(index);"/>
</svgFrame>

<!-- Page 1: Application Edit -->
<vgroup id="page_1" hidden="false" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">
<form id="fld">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">

<hgroup label="Application path and name">
<text id="Name" size="40" onchange="zenPage.doModified();" hint="Required." title="Enter the path and name of your executable application"/>
<button id="NameBrowseBtn" caption="Browse..." onclick="zenPage.doBrowse('Name','*.exe',0);" valign="top"/>
</hgroup>
<text id="Description" label="Description" size="80" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="Enabled" value="1" onchange="zenPage.doModified();"/>

<select id="Resource" label="Resource required to run the application"
title="Specifies a resource for which users must have the Use permission (enabled as part of a privilege in a role) in order to run the application."
onchange="zenPage.doModified();"
/>

<html id="registeredApps" label="Registered executables" OnDrawContent="DrawAppList" hidden="true"/>

</group>
</form>
</vgroup>

<!-- Page 2: Application Roles -->
<vgroup id="page_2" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
<ApplicationRoles id="AppRoleComponent" type="ApplicationRole" PID="#(%page.PID)#"/>
</vgroup>

<!-- Page 3: Match Roles -->
<vgroup id="page_3" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
<ApplicationRoles id="MatchRoleComponent" type="MatchRole" PID="#(%page.PID)#"/>
</vgroup>

</pane>
}

/// Set focus to the Name or Description field, disable fields if DispatchClass is defined.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.PID == "") {
		zen("Name").focus();
	} else {
		zen("Description").focus();
	}
	if (this.IsNewSave != 0) {
		this.showMsg($$$Text('Application saved.'),false);
		zen('newLink').setHidden(false);
		return;
	}
	
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		zen('tabBar').tabClicked(hash);
	}
	
	this.resetMsg();
}

ClientMethod doRegister() [ Language = javascript ]
{
	document.getElementById('idRespond2').innerHTML = "";
	var dir = document.getElementById('NewName').value;
	if (dir == "") {
		document.getElementById('idRespond2').innerHTML = $$$Text("Please enter a directory.");
		return;
	}
	var st = this.Register(this.PID,dir);
	if (st != 1) {
		document.getElementById('idRespond2').innerHTML = st;
		return;
	}
	zen('registeredApps').refreshContents();
}

ClientMethod doUnregister(rowNum) [ Language = javascript ]
{
	document.getElementById('idRespond2').innerHTML = "";
	var st = this.Unregister(this.PID,rowNum);
	if (st != 1) {
		document.getElementById('idRespond2').innerHTML = st;
		return;
	}
	zen('registeredApps').refreshContents();
}

/// Returning from file select and setting the value into the appropriate field.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	this.invokeSuper('onPopupAction',arguments);
	if (action == "ok") {
		document.getElementById('NewName').value = value;
	}
}

ClientMethod doNewBrowse(fieldID, wildcard, onlyDir) [ Language = javascript ]
{
	var Dir = document.getElementById(fieldID).value;
	var url = zenLink("%ZEN.Dialog.fileSelect.zen?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=" + onlyDir);
	zenLaunchPopupWindow(url,fieldID,'status,scrollbars,resizable,width=600,height=700');
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
	proxy.Enabled = zen('Enabled').getValue();
	proxy.Resource = zen('Resource').getValue();
	proxy.ApplicationType = this.ApplicationType;
	
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		// error case
		this.showMsg(result.ErrorMessage,true);
		return;
	}
	this.setModified(false);
	if (proxy.PID == '') {
		var url = zenLink('%25CSP.UI.Portal.Applications.Client.zen?PID='+encodeURIComponent(result.shortName)+'&new=1');
		this.gotoPage(url);
		return;
	}
	// saved existing app
	this.showMsg($$$Text('Application saved.'),false);
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
	Set tProxy.shortName = pProxy.Name

	Try {
		Set Properties("Description") = pProxy.Description
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("Resource") = pProxy.Resource
		

		If pProxy.PID = "" {
			Set Properties("Type") = pProxy.ApplicationType
			Set tSC = ##Class(Security.Applications).GetClientApplicationHash(pProxy.Name,.Hash)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			Set Properties("ClientApplications") = Hash
			
			Set tSC = ##class(Security.Applications).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			
			Set tProxy.shortName = ##class(%Library.File).GetFilename(pProxy.Name)
		} Else {
			Set tSC = ##class(Security.Applications).Modify(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod Unregister(PID As %String, DeleteIndex As %Integer) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set ClientApplications = ""
		For i=1:1:$LENGTH(Properties("ClientApplications"),",") {
			If (i '= DeleteIndex) {
				Set ClientApplications = ClientApplications_$PIECE(Properties("ClientApplications"),",",i)_","
			}
		}
		Kill Properties
		Set Properties("ClientApplications") = $E(ClientApplications,1,$l(ClientApplications)-1)
		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set tSC = ..EvalResult(Error.AsStatus())
	}
	
	Quit tSC
}

ClassMethod Register(PID As %String, Directory As %String) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set ClientApplication = ##Class(%Library.File).NormalizeDirectory(Directory)_PID
		Set tSC = ##Class(Security.Applications).GetClientApplicationHash(ClientApplication,.Hash)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tSC = ##class(Security.Applications).Get(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set ClientApplications = ""
		For i=1:1:$LENGTH(Properties("ClientApplications"),",") {
			If ($PIECE(Properties("ClientApplications"),",",i) = Hash) {
				Set errMsg = $$$TextHTML("Application already registered, please re-enter")
				Throw
			}
			Set ClientApplications = ClientApplications_$PIECE(Properties("ClientApplications"),",",i)_","
		}

		Kill Properties
		Set Properties("ClientApplications") = ClientApplications_Hash
		Set tSC = ##class(Security.Applications).Modify(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		If ($G(errMsg) '= "") {
			Set tSC = errMsg
		} Else {
			Set tSC = ..EvalResult(Error.AsStatus())
		}
	}
	
	Quit tSC
}

Method DrawAppList(pSeed As %String) As %Status
{
	If ..PID = "" Quit $$$OK
	Set tSC = ##class(Security.Applications).Get(..PID,.Properties)
	If $$$ISERR(tSC) Quit $$$OK
	
	&html<
		<div>
		<table class="tpTable" cellspacing="2" cellpadding="0" border="1" style="table-layout:auto;" width="100%">
		<thead class="tpHead">
			<th nowrap>#($$$TextHTML("Executable Date"))#</th>
			<th>&nbsp;</th>
		</thead>
		<tbody class="tpBody">>
	Set nRow = 0
	
	Set ClientApplications = Properties("ClientApplications")
	If ClientApplications = "" {
		&html<<tr><td colspan="2">#($$$TextHTML("No executables registered."))#</td></tr>>
	} Else {
		For nRow=1:1:$LENGTH(ClientApplications,",") {
			Set ClientApplication = $PIECE(ClientApplications,",",nRow)
			Set time = $PIECE(ClientApplication,"^",1)
			Set rowClass = $CASE(nRow#2,1:"tpOdd",:"tpEven")
			&html<
			<tr class="#(rowClass)#">
				<td class="tpStr" nowrap>#(..EscapeHTML(time))#</td>
				<td class="tpAction" style="text-align:center;"><a href="#" onclick="zenPage.doUnregister('#(nRow)#');return false;">#($$$TextHTML("Remove"))#</a></td>
			</tr>>
		}
	}
	&html<<tr><td colspan="2"><span id="idRespond2" class="rednote"></span></td></tr>>
	Set label = $$$FormatText($$$TextHTML("Directory of new %1 executable"),..PID)
	Set browseCaption = $$$TextHTML("Browse...")
	Set addCaption = $$$TextHTML("Register")
	&html<<tr><td colspan="2"><span class="zenLabel">#(label)#</span><input id="NewName" type="text" size="40"><input type="button" value="#(browseCaption)#" onclick="zenPage.doNewBrowse('NewName','*.exe',1);" style="margin:0 3px;"/><input type="button" name="Add" value="#(addCaption)#" onclick="zenPage.doRegister();"></td></tr>>
 	&html<</tbody></table>>
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	// Populate the Resource dropdown
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$ServiceResourceType+$$$ApplicationResourceType+$$$UserResourceType)
	Set valueList = ""
	While tRS.Next() {
		Set name = tRS.GetData(1)
		If valueList = "" {
			Set valueList = name
		} Else {
			Set valueList = valueList_","_name
		}
	}
	Set (..%GetComponentById("Resource").displayList,..%GetComponentById("Resource").valueList) = valueList

	If ..PID = "" {
		// Creating new application
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the following form to create a new client application:")
		Set ..%GetComponentById("svgTabArea").hidden = 1
		Set ..%GetComponentById("svgTabArea").height = 0
		
		Set ..%GetComponentById("Name").value = "NewApp.EXE"
	} Else {
		// Editing existing application
		Set ..EditHeader = $$$FormatText($$$Text("Edit definition for client application %1:"),..PID)
		Set ..RolesHeader = $$$FormatText($$$Text("Edit roles for client application %1:"),..PID)
		Set ..%GetComponentById("Text1").value = ..EditHeader
		
		Kill Properties
		Set tSC = ##class(Security.Applications).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ..%GetComponentById("svgTabArea").hidden = 1
			Set ..%GetComponentById("svgTabArea").height = 0
			Quit $$$OK
		}
		
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("Name").disabled = 1
		
		Set ..%GetComponentById("registeredApps").hidden = 0
		
		// Loop to set all field values
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		Set ..%GetComponentById("NameBrowseBtn").hidden = 1
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

	Set tPageName = $$$Text("Client Applications","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_NAMESPACE)))
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Client Application")
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
