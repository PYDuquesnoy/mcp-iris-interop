/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Applications.DocDB Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Doc DB";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Applications.DocDBList.zen";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.DocDB.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Edit Doc DB Application";

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
<group labelPosition="left" cellStyle="padding:4px;">
<text id="Name" label="Name" size="64" onchange="zenPage.doModified();" hint="Required." title="Enter the name of your Doc DB application"/>
<select id="Namespace" label="Namespace" title="Specifies a namespace for the Doc DB application." onchange="zenPage.doModified(); " hint="Required."/>
<text id="Description" label="Description" size="40" onchange="zenPage.doModified();"/>
<checkbox id="Enabled" label="Enabled" value="1" onchange="zenPage.doModified();"/>
<select id="Resource" label="Resource used to run the application" title="Specifies a resource for which users must have permission on (enabled as part of a privilege in a role) in order to run the application." onchange="zenPage.doModified();"/>
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
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Namespace'),pass,"S")) pass = false;

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
		
		if (this.PID == "&") {
			if (!this.validate()) {
				this.afterValidate();
				return;
			}
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.Name = zen('Name').getValue();
		proxy.Namespace = zen('Namespace').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.Enabled = zen('Enabled').getValue();
		proxy.Resource = zen('Resource').getValue();
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

		Set Properties("Description") = pProxy.Description
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("Resource") = pProxy.Resource
		If pProxy.PID = "&" {			
			Set tSC = ##class(Security.DocDBs).Create(pProxy.Name,pProxy.Namespace,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(Security.DocDBs).Modify(pProxy.Name,pProxy.Namespace,.Properties)
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

	Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the form below to create a new Doc DB Application:")
	// Populate the Namespace dropdown
	Set tType = 4   		// 4 - Returns array of all namespaces
	Set tRemote = 1 		// 1 - Return remote namespaces as well
	Set tDontConnect = 1	// 1 - Do not attempt to connect 
	Do List^%SYS.NAMESPACE(.Namespaces,tType,tRemote,tDontConnect)
	Set nms = $O(Namespaces(""))
	Set valueList = ""
	While nms '= "" {
	  	If valueList = "" {
			Set valueList = nms
		} Else {
			Set valueList = valueList_","_nms
		}
  		Set nms = $O(Namespaces(nms))
	}
	Set (..%GetComponentById("Namespace").displayList,..%GetComponentById("Namespace").valueList) = valueList

	If ..PID = "&" {
	} Else {
		Set ..%GetComponentById("Text1").value = $$$FormatText($$$TextHTML("Use the form below to edit Doc DB Application %1 in namespace %2"),$p(..PID,"&",1),$p(..PID,"&",2,*))
		Set Name=$p(..PID,"&",1)
		Set Namespace=$p(..PID,"&",2,*)
		s Status=##Class(Security.DocDBs).Get(Name,Namespace,.Properties)
		i '$$$ISOK(Status) q Status
		s Properties("Name")=Name
		s Properties("Namespace")=Namespace
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
		Set Component = ..%GetComponentById("Name")
		Set Component.disabled = 1
		Set Component = ..%GetComponentById("Namespace")
		Set Component.disabled = 1
	}

	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Doc DB Application")
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
	
	Set tPageName = $$$Text("Doc DB Applications","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// Subclass can override.
Method %OnGetTitle() As %String
{
	If ..IsEditForm,..PID'="&" Quit $$$FormatText($$$Text("Edit: %1 in namespace %2"),$zconvert($p(..PID,"&",1),"O","HTML"),$zconvert($p(..PID,"&",2,*),"O","HTML"))
	Quit ..LocatorHeader
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
