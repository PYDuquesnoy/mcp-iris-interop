/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Archive Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Edit Archive Target";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As %Boolean = 0;

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Archive.zen";

Parameter HELPADDRESS = "System Administration, Configuration, System Configuration, Archive Target Settings, Add Archive Target";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Archives.zen";

Parameter RECENT = 0;

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %String(ZENURL = "isNew") [ InitialExpression = "0" ];

/// Archive for edit. Null if adding new archive.
Property PID As %String(ZENURL = "PID");

XData Style
{
<style type="text/css">
.zenLabelDisabled,a.radioSetCaptionDisabled { color:black; }
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
 <!-- block to show result -->
 <form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="Name" label="Name" hint="Required." onchange="zenPage.doModified();"/>
<radioSet id="Type" label="Type" valueList="s3,rsync,noop" displayList="AWS S3,rsync or robocopy,no-op (for test only)" value="s3" onchange="zenPage.changeType(zenThis.getValue());" layout="horizontal"/>
<text id="Location" label="Location" hint="Required." title="'s3://dir/' for s3, '/dir' or 'server:/dir/' for rsync (Unix/Linux) and 'drive:\dir\' or '\\server\share\dir\' for robocopy (Windows)" size="70" onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod changeType(newvalue) [ Language = javascript ]
{
        this.doModified();
        zen('Location').setValue("");
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		;if (!this.validateRequired(zen('Type'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Location'),pass,"S")) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

/// Save current item. Subclass to override.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		if (!this.validate()) {
			zenPage.afterValidate();
			return;
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.Name = zenEscapeJS(zen("Name").getValue());
		proxy.Type = zenEscapeJS(zen("Type").getValue());
		proxy.Location = zenEscapeJS(zen("Location").getValue());
		
		var ok = this.SaveData(proxy);
		zenPage.afterSave(ok);
	} catch (ex) {
		alert("Error: " + ex);
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("Type") = pProxy.Type
		Set Properties("Location") = pProxy.Location
		
		Set tMethod = $S(pProxy.PID="":"Create",1:"Modify")
		Set tSC = $classmethod("Config.Archives",tMethod,pProxy.Name,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Do ..%GetNavTableState(..%GetPageName()_" "_..PID)

	Set ..lblTitle = $S(..isNew=1:$$$Text("Use the form below to create a new archive target:"),1:$$$Text("Use the form below to edit a archive target:"))
	
	If ..PID '= "" {
		Set ..%GetComponentById("Name").disabled = 1
		
		Set tSC = ##class("Config.Archives").Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Quit $$$OK
		}
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If ..IsEMSReadOnly Set Component.disabled = 1
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		Set ..%GetComponentById("Name").value = ..PID
		Set ..%GetComponentById("Type").value = Properties("Type")
		Set ..%GetComponentById("Location").value = Properties("Location")
		If ..IsEMSReadOnly {
			Set ..%GetComponentById("Name").disabled = 1
			Set ..%GetComponentById("Type").disabled = 1
			Set ..%GetComponentById("Location").disabled = 1
		}
	} Else {
	}

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..isNew {
		Quit $$$Text("Create Archive Target")
	} ElseIf ..IsEMSReadOnly {
		Quit $$$Text("View Archive Target")
	} Else {
		Quit $$$Text("Edit Archive Target")
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = $$$GetHomePage
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Archive Target Settings")
	Set tURL = ..ParentURL
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen?PID="_$ZCVT(%page.PID,"O","URL"))
	Quit $$$OK
}

/// Overriden to add PID to the page name to distinguish the specific page.
ClientMethod navPageSizeChanged(value) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows,this.PID);
}

/// Overriden to add PID to the page name to distinguish the specific page.
ClientMethod navMaxRowsChanged(value) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value,this.PID);
}

/// Used to Save tableNavBar values, add PID to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, pPID As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName()_" "_pPID,"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
