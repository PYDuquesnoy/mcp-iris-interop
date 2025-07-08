/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - New Namespace
Class %CSP.UI.Portal.Namespace Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "New Namespace";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Namespace.zen";

Parameter HELPADDRESS = "Home,Configuration,Namespaces,New Namespace";

Parameter EMSSERVICE = "Namespace";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Namespaces.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Is this instance InterSystems IRIS or HealthShare? If so, CSP application creation is handled differently.
Property IsEnsemble As %Boolean [ InitialExpression = {$S(##class(%Library.EnsembleMgr).IsEnsembleInstalled():1,##class(%Library.EnsembleMgr).IsHealthShareInstalled():1,1:0)} ];

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// The new namespace's name cannot be in the list
Property ReservedNames As %String [ InitialExpression = ",BIN,BROKER,DOCUMATIC,SYS," ];

/// Currently set namespace name.
Property CurrentNamespace As %String;

/// Label for type of namespace to make
Property productLbl As %ZEN.Datatype.caption;

/// Parent URL that Cancel and Save should return to
Property ParentURL As %ZEN.Datatype.string [ InitialExpression = {..Link($ZCVT($case($get(%request.Data("SRC",1)), "SHARD":"/csp/sys/mgr/%CSP.UI.Portal.Sharding.Configuration.zen", :..#PARENTPAGE),"O","URL"))} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-left:4px;padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:6px;" labelPosition="left">
<hidden id="DBField"/>
<spacer height="2"/>
<text id="NamespaceName" label="Name of the namespace" size="30" hint="Required." onchange="zenPage.changeNamespace(zenThis.getValue());zenPage.doModified();"/>
<select id="CopyFrom" label="Copy from" queryClass="Config.Namespaces" queryName="List" onchange="zenPage.changeCopy(zenThis.getValue());zenPage.doModified();" choiceColumn="1">
<parameter value="*"/>
<parameter value=""/>
<parameter value=""/>
<parameter value=""/>
</select>
<radioSet id="IsRemote" label="The default database for Globals in this namespace is a" valueList="0,1" displayList="Local Database,Remote Database" value="0" onchange="zenPage.changeRemote(zenThis.getValue());" layout="vertical"/>
<hgroup id="nameGroup" label="Select an existing database for Globals" >
<dataCombo id="DBName" queryClass="Config.Databases" queryName="List" displayColumns="1,2" choiceColumn="1" dropdownWidth="500px" dropdownHeight="200px" size="30" hint="Required."  onchange="zenPage.doModified();" maxRows="100000">
<parameter value="*"/>
<parameter value=""/>
<parameter id="DBFlagParam" value="1"/>
<parameter value=""/>
</dataCombo>
<button caption="Create New Database..." containerStyle="padding-left:2px;" onclick="zenPage.doNew(zen('IsRemote').getValue(),'DBName');" valign="top"/>
</hgroup>
<spacer height="3"/>
<radioSet id="IsRemoteRtns" label="The default database for Routines in this namespace is a" valueList="0,1" displayList="Local Database,Remote Database" value="0" onchange="zenPage.changeRemoteRtns(zenThis.getValue());" layout="vertical"/>
<hgroup id="nameGroupRtns" label="Select an existing database for Routines" >
<dataCombo id="DBNameRtns" queryClass="Config.Databases" queryName="List" displayColumns="1,2" choiceColumn="1" dropdownWidth="500px" dropdownHeight="200px" size="30" onchange="zenPage.doModified();" maxRows="100000">
<parameter value="*"/>
<parameter value=""/>
<parameter id="DBFlagParam1" value="1"/>
<parameter value=""/>
</dataCombo>
<button caption="Create New Database..." containerStyle="padding-left:2px;" onclick="zenPage.doNew(zen('IsRemoteRtns').getValue(),'DBNameRtns');" valign="top"/>
</hgroup>
<checkbox id="DefineCSP" label="Create a default Web application for this namespace" value="1"  onchange="zenPage.doModified();"/>
<select id="CopyMapsFrom" label="Copy namespace mappings from" queryClass="Config.Namespaces" queryName="List" onchange="zenPage.doModified();" choiceColumn="1">
<parameter value="*"/>
<parameter value=""/>
<parameter value=""/>
<parameter value=""/>
</select>
<checkbox id="EnsembleEnable" hidden="true" label='#(%page.productLbl)#' value="1" onchange="zenPage.doEnsChange();"/>
<spacer height="2"/>
</group>
</form>
</pane>
}

ClientMethod changeNamespace(Namespace) [ Language = javascript ]
{
	if (Namespace == "%ALL") {
		zen('DBName').setValue("%DEFAULTDB");
		zen('DBNameRtns').setValue("%DEFAULTDB");
		zen('IsRemote').setHidden(true);
		zen('IsRemoteRtns').setHidden(true);
		zen('nameGroup').setProperty('disabled',true);
		zen('nameGroup').setProperty('labelClass','zenLabelDisabled');
		zen('nameGroupRtns').setProperty('disabled',true);
		zen('nameGroupRtns').setProperty('labelClass','zenLabelDisabled');
		zen('CopyMapsFrom').setDisabled(true);
		zen('CopyFrom').setDisabled(true);
		zen('DefineCSP').setValue(0);
		zen('DefineCSP').setDisabled(true);
		zen('EnsembleEnable').setHidden(true);
	} else if (this.CurrentNamespace == "%ALL") {
		zen('DBName').setValue("");
		zen('DBNameRtns').setValue("");
		zen('IsRemote').setHidden(false);
		zen('IsRemoteRtns').setHidden(false);
		zen('nameGroup').setProperty('disabled',false);
		zen('nameGroup').setProperty('labelClass','zenLabel');
		zen('nameGroupRtns').setProperty('disabled',false);
		zen('nameGroupRtns').setProperty('labelClass','zenLabel');
		zen('CopyMapsFrom').setDisabled(false);
		zen('CopyFrom').setDisabled(false);
		zen('DefineCSP').setValue(1);
		zen('DefineCSP').setDisabled(false);
		zen('EnsembleEnable').setHidden(!this.IsEnsemble);
	}
	this.CurrentNamespace = Namespace;
}

ClientMethod changeCopy(copyFrom) [ Language = javascript ]
{
	if (copyFrom == "") {
		zen('IsRemote').setHidden(false);
		zen('IsRemoteRtns').setHidden(false);
		zen('nameGroup').setProperty('disabled',false);
		zen('nameGroup').setProperty('labelClass','zenLabel');
		zen('nameGroupRtns').setProperty('disabled',false);
		zen('nameGroupRtns').setProperty('labelClass','zenLabel');
		zen('CopyMapsFrom').setDisabled(false);
	} else {
		zen('IsRemote').setHidden(true);
		zen('IsRemoteRtns').setHidden(true);
		var proxy = this.GetDBName(copyFrom);
		zen('DBName').setValue(proxy.Globals);
		zen('DBNameRtns').setValue(proxy.Routines);
		zen('nameGroup').setProperty('disabled',true);
		zen('nameGroup').setProperty('labelClass','zenLabelDisabled');
		zen('nameGroupRtns').setProperty('disabled',true);
		zen('nameGroupRtns').setProperty('labelClass','zenLabelDisabled');
		zen('CopyMapsFrom').setValue(copyFrom);
		zen('CopyMapsFrom').setDisabled(true);
	}
}

ClientMethod changeRemote(isRemote) [ Language = javascript ]
{
	isRemote = parseInt(isRemote);
	if (isRemote) {
		zen('DBFlagParam').value = 2;
	} else {
		zen('DBFlagParam').value = 1;
	}
	var DBselect = zen('DBName');
	DBselect.setValue('');
	DBselect.refreshContents(true);
}

ClientMethod changeRemoteRtns(isRemote) [ Language = javascript ]
{
	isRemote = parseInt(isRemote);
	if (isRemote) {
		zen('DBFlagParam1').value = 2;
	} else {
		zen('DBFlagParam1').value = 1;
	}
	var DBselect = zen('DBNameRtns');
	DBselect.setValue('');
	DBselect.refreshContents(true);
}

ClientMethod doNew(isRemote, dbField) [ Language = javascript ]
{
	zen("DBField").setValue(dbField);
	if (parseInt(isRemote) == 0) {
		var url = zenLink('%CSP.UI.Portal.Dialog.DatabaseWizard.zen');
		var popupName = 'DatabaseWizard';
	} else {
		var url = zenLink('%CSP.UI.Portal.Dialog.RemoteDatabase.zen')
		var popupName = 'RemoteDatabase';
	}
	zenLaunchPopupWindow(url,popupName,'status,scrollbars,resizable=yes,width=900,height=700');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	try {
		if ((popupName == 'DatabaseWizard') || (popupName == 'RemoteDatabase')) {
			zen("DBName").refreshContents(true);
			zen("DBNameRtns").refreshContents(true);
			var DBField = zen("DBField").getValue();
			zen(DBField).setValue(value.toUpperCase());
			this.doModified();
		}
	} catch (ex) {
		alert("Error: " + ex);
	}

	return true;
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	proxy.NamespaceName = zen('NamespaceName').getValue().toUpperCase();
	proxy.CopyFrom = zen('CopyFrom').getValue();
	proxy.DBName = zen('DBName').getValue();
	proxy.DBNameRtns = zen('DBNameRtns').getValue();
	proxy.DefineCSP = zen('DefineCSP').getValue();
	proxy.CopyMapsFrom = zen('CopyMapsFrom').getValue();
	proxy.IsEnsemble = (this.IsEnsemble && zen('EnsembleEnable').getValue());

	var ok = this.validate(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);
	if (result.ok == 1) {
		this.setModified(false);
		if (result.WebAppStatus != 1) {
			alert(result.WebAppStatus);
		}
		if (result.Message == 'EnableEnsNamespace') {
			var url = '%25CSP.UI.System.ExpResultPage.cls?Mode=EnableEnsNamespace&Namespace='+encodeURIComponent(proxy.NamespaceName)+'&CopyMapsFrom='+encodeURIComponent(proxy.CopyMapsFrom)+'&refreshpage='+encodeURIComponent('%CSP.UI.Portal.Namespaces.zen');
			this.gotoPage(url);
		} else if (result.Message == 'CopyMapsFrom') {
			var url = '%25CSP.UI.System.ExpResultPage.cls?Mode=CopyMapsFrom&Namespace='+encodeURIComponent(proxy.NamespaceName)+'&CopyMapsFrom='+encodeURIComponent(proxy.CopyMapsFrom)+'&refreshpage='+encodeURIComponent('%CSP.UI.Portal.Namespaces.zen');
			this.gotoPage(url);
		} else {
			this.doCancel();
		}
	} else {
		this.showMsg(result.ErrorMessage,1);
	}
}

ClientMethod validate(proxy) [ Language = javascript ]
{
	this.resetMsg('');
	var pass = true;
	if (!this.validateRequired(zen('NamespaceName'),pass,"S")) pass = false;
	if (!this.validateRequired(zen('DBName'),pass,"S")) pass = false;
	if (!pass) {
		this.afterValidate();
		return pass;
	}

	if (this.ReservedNames.indexOf(','+proxy.NamespaceName+',') > -1) {
		var msg = $$$Text("'%1' is a system reserved word. Please enter a different name.");
		msg = msg.replace(/%1/g,proxy.NamespaceName);
		this.showMsg(msg,1);
		zen("NamespaceName").focus();
		return false;
	}
	if (proxy.NamespaceName == "%ALL") {
		var msg = $$$Text("Namespace '%ALL' is designated to apply all the mappings set up for it to every namespace defined on the system.");
		var msg2 = $$$Text("Are you sure this is what you want to do?");
		if (!confirm(msg + "\n\n" + msg2)) {
			return false;
		}
	}
	if (proxy.CopyFrom != '') {
		var msg = $$$Text("Are you sure you want to copy all properties and mappings from the selected namespace to the new namespace?");
		if (!confirm(msg)) {
			zen("CopyFrom").focus();
			return false;
		}
	} else if (proxy.CopyMapsFrom != '') {
		var msg = $$$Text("Are you sure you want to copy all mappings from the selected namespace to the new namespace?");
		if (!confirm(msg)) {
			zen("CopyMapsFrom").focus();
			return false;
		}
	}
	return true;
}

ClassMethod GetDBName(Namespace As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tSC = ##class(Config.Namespaces).Get(Namespace,.Properties)
	Set tProxy.Globals = ..EscapeHTML($G(Properties("Globals"),""))
	Set tProxy.Routines = ..EscapeHTML($G(Properties("Routines"),""))
	Quit tProxy
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
	Set tProxy.ok = 1
	Set tProxy.Message = ""
	Set tProxy.WebAppStatus = $$$OK

	Try {
		Set NamespaceName = pProxy.NamespaceName
		Set LowName = $ZCVT(NamespaceName,"L")

		If pProxy.CopyFrom '= "" {
			Set tSC = ##class(Config.Namespaces).Copy(pProxy.CopyFrom,NamespaceName,,,0)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set nsProperties("Globals") = pProxy.DBName
			Set nsProperties("Library") = "IRISLIB"
			Set nsProperties("Routines") = $S(pProxy.DBNameRtns'="":pProxy.DBNameRtns,1:pProxy.DBName)
			Set nsProperties("SysGlobals") = "IRISSYS"
			Set nsProperties("SysRoutines") = "IRISSYS"
			Set nsProperties("TempGlobals") = "IRISTEMP"
			Set tSC = ##Class(Config.Namespaces).Create(NamespaceName,.nsProperties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}

		If (pProxy.DefineCSP && 'pProxy.IsEnsemble) {
			// Set the default authentication options to be the same as the system's
			Set tSC = ##Class(Security.System).Get(,.secProperties)
			Set cspProperties("AutheEnabled") = secProperties("AutheEnabled")
			Set cspProperties("NameSpace") = NamespaceName
			Set cspProperties("Path") = LowName
			Set tSC = ##Class(Security.Applications).Create("/csp/"_LowName,.cspProperties)
			Set tProxy.WebAppStatus = ..EvalResult(tSC)
		}

		// If Ensemble is installed then enable Ensemble for namespace
		// (EnableNamespace of %EnsembleMgr is run in the background)
		If (pProxy.IsEnsemble && (NamespaceName '= "%ALL")) {
			Set tProxy.Message = "EnableEnsNamespace"
		} ElseIf (pProxy.CopyMapsFrom '= "") {
			// If user selected to copy mapping from another namespace, do it in the background
			Set tProxy.Message = "CopyMapsFrom"
		}
	} Catch Error {
		Set Message = ..EvalResult(Error.AsStatus())
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Use the form below to create a new namespace")_":"

	// If IRIS/HealthShare then disable the CSP checkbox because CSP is required
	// Also show option to not have maps to integration library. This value is only used later if IsEnsemble is true.
	If ..IsEnsemble {
		Set cspBox = ..%GetComponentById("DefineCSP")
		Set cspBox.disabled = 1
		Set ..productLbl = $$$TextHTML("Enable namespace for interoperability productions")

		Set ensembleEnable = ..%GetComponentById("EnsembleEnable")
		Set ensembleEnable.hidden = 0
	}

	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("New Namespace")
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
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

ClientMethod doEnsChange() [ Language = javascript ]
{
	try {
		/* Toggle DefineCSP enabled based on EnsembleEnable */
		var  ensembleEnable = zen('EnsembleEnable').getValue();
		
		zen('DefineCSP').setDisabled(ensembleEnable);
		if (ensembleEnable) {zen('DefineCSP').setValue(1)};
		zenPage.doModified();
	} catch (ex) {}
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
