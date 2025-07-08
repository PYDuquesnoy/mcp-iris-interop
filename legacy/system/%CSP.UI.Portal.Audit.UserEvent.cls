/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Audit.UserEvent Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Audit Event";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Audit.UserEvents.zen";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.UserEvent.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Configure User Events,Edit Audit Event";

Parameter EMSSERVICE = "Security";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<group id="newInstructions" hidden="true">
<label label="An audit event name consists of three parts: Event Source, Event Type and Event Name."/>
<label label="You may select an existing one from the list or enter a new one."/>
</group>
<group labelPosition="left" cellStyle="padding:4px;">
<fieldSet label="Audit Event Name" id="newFieldSet" hidden="true" labelPosition="left" cellStyle="padding:4px;">
<hgroup label="Event Source" cellStyle="padding:0 4px;">
<text id="Source" size="30" hint="Required." onchange="zenPage.doModified();"/>
<select id="SourceSelect" containerStyle="vertical-align:top;" showEmpty="false" onchange="zenPage.selectChanged('Source',zenThis.getValue());"/>
</hgroup>
<hgroup label="Event Type" cellStyle="padding:0 4px;">
<text id="Type" size="30" hint="Required." onchange="zenPage.doModified();"/>
<select id="TypeSelect" containerStyle="vertical-align:top;" showEmpty="false" onchange="zenPage.selectChanged('Type',zenThis.getValue());"/>
</hgroup>
<hgroup label="Event Name" cellStyle="padding:0 4px;">
<text id="Name" size="30" hint="Required." onchange="zenPage.doModified();"/>
<select id="NameSelect" containerStyle="vertical-align:top;" showEmpty="false" onchange="zenPage.selectChanged('Name',zenThis.getValue());"/>
</hgroup>
</fieldSet>
<label id="lblName" label="Audit Event Name" value="#(%page.PID)#" controlClass="normal" hidden="true"/>
<text id="Description" label="Description" size="40" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="Enabled" value="1" onchange="zenPage.doModified();"/>
</group>
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zen('errmsg').getProperty('hidden') == false) {
		this.disableCommandButton('btnSave');
	}
}

ClientMethod selectChanged(which, newVal) [ Language = javascript ]
{
	zen(which).setValue(newVal);
	this.doModified();
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	try {
		var pass = true;
		if (!this.validateRequired(zen('Source'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Type'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;

		return pass;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
}

/// Save current item.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		// if user has not changed anything but hit Save, then we can just close out.
		if (!this.pageModified) {
			this.doCancel();
			return;
		}
		
		if (this.PID == "") {
			if (!this.validate()) {
				this.afterValidate();
				return;
			}
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.Source = zen('Source').getValue();
		proxy.Type = zen('Type').getValue();
		proxy.Name = zen('Name').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.Enabled = zen('Enabled').getValue();
		
		var ok = this.SaveData(proxy);
		this.afterSave(ok);
	} catch (ex) {
		alert("Error doSave: " + ex);
	}
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		If (pProxy.PID '= "") {
			Set Properties("Description") = pProxy.Description
			Set Properties("Enabled") = pProxy.Enabled
			Set tSC = ##Class(Security.Events).Modify($P(pProxy.PID,"/",1),$P(pProxy.PID,"/",2),$P(pProxy.PID,"/",3),.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Security.Events).Create(pProxy.Source,pProxy.Type,pProxy.Name,pProxy.Description,pProxy.Enabled)
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

	If ..PID = "" {
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the form below to create a new audit event:")
		Set ..%GetComponentById("newInstructions").hidden = 0
		Set ..%GetComponentById("newFieldSet").hidden = 0
		
		Set tSC = ..LoadList("Source")
		Set tSC = ..LoadList("Type")
		Set tSC = ..LoadList("Name")
	} Else {
		Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Use the form below to edit audit event %1:"),..PID)
		Set ..%GetComponentById("lblName").hidden = 0
		
		Set tSC = ##class(Security.Events).Get($P(..PID,"/",1),$P(..PID,"/",2),$P(..PID,"/",3),.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Quit $$$OK
		}		

		If $zb(Properties("Flags"),$$$EventFlagSystem,1)=$$$EventFlagSystem {
			Set ..%GetComponentById("errmsg").value = $$$FormatText($$$TextHTML("Cannot modify system event %1"),..PID)
			Set ..%GetComponentById("errmsg").hidden = 0
			Set ..%GetComponentById("fld").hidden = 1
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
	}

	Quit $$$OK
}

Method LoadList(Name As %String) As %Status
{
	Set valueList = ""
	Set displayList = $$$Text("Select One")
 	Set Query = "List"_Name
 	Set tRS = ##class(%ResultSet).%New("Security.Events:"_Query)
 	Do tRS.Execute()
 	While tRS.Next() {
 		Set tName = tRS.GetData(1)
 		If $E(tName) '= "%" {
	 		Set valueList = valueList_","_tName
	 		Set displayList = displayList_","_..EscapeHTML(tName)
 		}
 	}
 	Set Component = ..%GetComponentById(Name_"Select")
 	Set Component.displayList = displayList
 	Set Component.valueList = valueList
 	
 	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Audit Event")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = $$$Text("User-Defined Audit Events")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
