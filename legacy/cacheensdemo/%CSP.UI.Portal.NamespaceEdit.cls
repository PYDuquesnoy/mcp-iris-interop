/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Edit Namespace
Class %CSP.UI.Portal.NamespaceEdit Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Namespace";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.NamespaceEdit.zen";

Parameter HELPADDRESS = "Home,Configuration,Namespaces,New Namespace";

Parameter EMSSERVICE = "Namespace";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Namespaces.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<text id="Name" label="Name" hint="Required."/>
<select id="Globals" label="Default Database for Globals" queryClass="Config.Databases" queryName="List" choiceColumn="1" showEmpty="false" maxRows="100000" onchange="zenPage.doModified();">
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
</select>
<select id="Routines" label="Default Database for Routines" queryClass="Config.Databases" queryName="List" choiceColumn="1" showEmpty="false" maxRows="100000" onchange="zenPage.doModified();">
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
</select>
<select id="TempGlobals" label="Default Database for Temporary Storage" queryClass="Config.Databases" queryName="List" choiceColumn="1" showEmpty="false" maxRows="100000" onchange="zenPage.doModified();">
<parameter value="*"/>
<parameter value=""/>
<parameter value="0"/>
<parameter value="0"/>
</select>
</group>
</form>
</pane>
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zenTrim(zen('Name').getValue());
	proxy.Globals = zen('Globals').getValue();
	proxy.Routines = zen('Routines').getValue();
	proxy.TempGlobals = zen('TempGlobals').getValue();
	
	var ok = this.validate(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);
	this.afterSave(result);
}

ClientMethod validate(proxy) [ Language = javascript ]
{
	if (!this.validateRequired(zen('Name'),true,"S")) {
		zen("Name").focus();
		return false;
	}
	
	if (proxy.Name.toUpperCase() != proxy.PID) {
		var msg = $$$FormatText($$$Text("Are you sure you want to change the namespace name to %1?"),proxy.Name);
		
		var warn = zenPage.GiveRenameWarning(proxy.PID,proxy.Name);
		if (warn) {
			//MES445 update message for IRIS family products only
			var isInterop = zenPage.IsEnsembleNamespace(proxy.PID);
			var feature = isInterop? $$$Text("analytics and interoperability") : $$$Text("analytics");
			msg = msg + $$$FormatText($$$Text("\n\nWARNING: This change disables %1 features.\n\nRename the web application for this namespace to re-enable these features."),feature);
		}
		
		if (!confirm(msg)) {
			zen("Name").setValue(this.PID);
			zen("Name").focus();
			return false;
		}	
	}
	if (proxy.Globals == '') {
		this.showMsg($$$Text("Please select a database for globals."));
		zen("Globals").focus();
		return false;
	}
	if (proxy.Routines == '') {
		this.showMsg($$$Text("Please select a database for routines."));
		zen("Routines").focus();
		return false;
	}
	if (proxy.TempGlobals == '') {
		this.showMsg($$$Text("Please select a database for temporary storage."));
		zen("TempGlobals").focus();
		return false;
	}
	return true;
}

/// Evaluate whether changing the name of this namespace could cause Interoperability and Analytics to become unusable in this namespace
/// based on whether the instance is Interoperability or Analytics enabled and whether there is a web app with a name matching the namespace name
Method GiveRenameWarning(pOldNamespace As %String, pNewNamespace As %String) As %Boolean [ ZenMethod ]
{
	Quit:(pOldNamespace="DOCBOOK") 0
	Quit:'(##class(%Library.EnsembleMgr).IsEnsembleNamespace(pOldNamespace)||($$$comClassDefined("%DeepSee.Utils")&&##class(%DeepSee.Utils).%IsDeepSeeEnabled(pOldNamespace))) 0
	Set tAppName=$case(##class(%Library.EnsembleMgr).IsHealthShareNamespace(pOldNamespace),0:"/csp/",:"/csp/healthshare/")_$translate($zconvert(pNewNamespace,"l"),"%")
	Set tAppSpec=$get($$$SecurityGlobalApplications(tAppName))
	Quit ((tAppSpec="")||($$$GetSecurityApplicationsEnabled(tAppSpec)=0)||($zconvert($$$GetSecurityApplicationsNameSpace(tAppSpec),"U")'=$zconvert(pOldNamespace,"U")))
}

Method IsEnsembleNamespace(pNamespace) As %Boolean [ CodeMode = expression, ZenMethod ]
{
##class(%Library.EnsembleMgr).IsEnsembleNamespace(pNamespace)
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.Message (save successful, with warning message: require restart)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to Database list page.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Config.Namespaces).Get(pProxy.PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set Properties("Globals") = pProxy.Globals
		Set Properties("Routines") = pProxy.Routines
		Set Properties("TempGlobals") = pProxy.TempGlobals
		Set tSC = ##Class(Config.Namespaces).Modify(pProxy.PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If ($ZCVT(pProxy.Name,"U") '= pProxy.PID) {
			Set tSC = ##class(Config.Namespaces).Rename(pProxy.PID,pProxy.Name)
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

	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("Edit Properties for Namespace %1"),..PID)
			
	If ..PID = "%SYS" {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	Set tSC = ##Class(Config.Namespaces).Get(..PID,.Properties)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("fld").hidden = 1
		Set ..InvalidParam = 1
		Quit $$$OK
	}
	
	Set ..%GetComponentById("Name").value = ..PID
	If (..PID = "IRISLIB") Set ..%GetComponentById("Name").disabled = 1
	
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
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Namespace")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Namespaces","%Utility")
	Set tURL = ..Link(%page.ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

}
