/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Configure Devices
Class %CSP.UI.Portal.ML.Configuration Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ML.Configuration.zen";

Parameter HELPADDRESS = "System Administration,Configurations,Machine Learning Configurations,Configuration";

/// Displayed name of this page.
Parameter PAGENAME = "ML Configuration";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ML.Configurations.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

/// Existing Config for edit. 
Property PID As %String(ZENURL = "PID");

Property Subject As %String [ InitialExpression = "ML Configuration" ];

XData Style
{
<style type="text/css">
.EditForm { width:800px; }
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<hidden name="browseselect" id="browseselect"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<vgroup labelPosition="left" cellStyle="padding:4px;" >
<hidden id="oldType"/>
<hidden id="d_url"/>
<hidden id="d_dataURL"/>

<text id="Name" label="Name" size="60" hint="Required." maxlength="256" onchange="zenPage.doModified();"/>

<select id="Type" label="Provider" 
displayList="AutoML,H2O,DataRobot,PMML" 
valueList="0,1,2,3" hint="Required." showEmpty="false"
 onchange="zenPage.changeType(0);zenPage.doModified();" value="0" originalValue="0" hidden="true"/>
<label id="warningType" controlClass="errorNote" value="" hidden="true"/>
<textarea id="Description" label="Description" cols="80" rows="5" onchange="zenPage.doModified();"/>
<textarea id="Using" label="Using Clause" cols="80" rows="5" hint="Default USING clause for the provider." onchange="zenPage.doModified();"/>
<text id="Owner" label="Owner" size="60" maxlength="160" onchange="zenPage.doModified();"/>
 <!-- URL is for DataRobot only -->
<text id="url" label="URL" hidden="true" size="60" onchange="zenPage.doModified();"/>
<text id="dataURL" label="URL" hidden="true" size="60" hint="Required." onchange="zenPage.doModified();"/>

<!-- apiToken is for DataRobot only -->
<text id="apiToken" label="API Token" hidden="true" size="60" hint="Required." onchange="zenPage.doModified();"/>
 
<!-- javaTlsConfigFile is for H2O only -->
<hgroup id="idJavaTlsConfigFile" cellVAlign="bottom" hidden="true" label="TLS Configuration File" hint="Path to Java client TLS configuration file to connect to superserver. Required if superserver requires TLS. Leave blank otherwise.">
<text id="javaTlsConfigFile" size="60" onchange="zenPage.doModified();"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('javaTlsConfigFile', '*.properties');"/>
</hgroup>
 
 </vgroup>
<hidden id="d_apiToken"/>

 </group>
</form>
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zen('browseselect').setValue(name);
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// This client event is fired when a popup page launched from this page
/// fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zenPage.getComponentById("browseselect").getValue();
			zenPage.getComponentById(name).setValue(value);
			this.doModified();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod changeType(onload) [ Language = javascript ]
{
	var type = zen('Type').getValue();
	var oldtype = zen('oldType').getValue();
	zen('Type').setHidden(false)
	if (!onload) {
		if (this.PID != '' && oldtype != type) {
			// show warning for changing Provider
			var display = ["AutoML","H2O","DataRobot","PMML"]
			var msg = $$$FormatText($$$Text("Change Provider from '%1' to '%2' - If this is a mistake, hit Cancel to discard."),display[oldtype],display[type]);
			zen('warningType').setValue(msg);
			zen('warningType').setHidden(false);
				// fill in defaults if any
				if (type == 2) {
					if (zen('dataURL').getValue() == '') {
						zen('dataURL').setValue(zen('d_dataURL').getValue());
					}
					if (zen('apiToken').getValue() == '') {
						zen('apiToken').setValue(zen('d_apiToken').getValue());
					}
				}
		} else {
			zen('warningType').setHidden(true);	
		}
	}
	zen('url').setHidden(true);
	zen('dataURL').setHidden(true);
	zen('apiToken').setHidden(true);
	zen('idJavaTlsConfigFile').setHidden(true);
	
	if (type == 1) {
		zen('idJavaTlsConfigFile').setHidden(false);
	} else if (type == 2) {
		zen('dataURL').setHidden(false);
		zen('apiToken').setHidden(false);
	}
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen("Name"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("Type"),pass,"S")) pass = false;
		if ((zen('oldType').getValue() != '') && (zen('oldType').getValue() != zen("Type").getValue())) {
			if (!confirm($$$Text("Are you sure you want to change the Provider?"))) {					
				pass = false;	
			}
		}
		return pass;
	} catch (ex) {
		alert("Error: " + ex);
		return pass;
	}
}

ClientMethod getProxy() [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		proxy.Name = zen('Name').getValue();
		proxy.Type = zen('Type').getValue();
		proxy.Description = zen('Description').getValue();
		proxy.Using = zen('Using').getValue();
		proxy.Owner = zen('Owner').getValue();
		proxy.url = (proxy.Type != 2) ? zen('url').getValue() : zen('dataURL').getValue();
		proxy.apiToken = zen('apiToken').getValue();
		proxy.javaTlsConfigFile = zen('javaTlsConfigFile').getValue();
		return proxy;
	} catch (ex) {
		alert("Error getProxy: " + ex);
		return proxy;
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	
	if (!this.validate()) {
		this.afterValidate();
		return;
	}
	
	var proxy = this.getProxy();
	proxy.PID = this.PID;
	proxy.oldType = zen("oldType").getValue();
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		// error case
		this.showMsg(result.ErrorMessage,true);
		return;
	} else {
		this.doCancel();
	}
}

ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	self.document.location = this.ParentURL;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var PID = this.PID;
	if (PID != "") {
		var ok = this.UpdateDetails(PID);		
		if (ok != 1) {
			this.showMsg(ok);
		} 
	}
	this.changeType(1);
}

/// This method is called when page is loaded.
/// Load existing data into the fields.
ClassMethod UpdateDetails(pid) As %String [ ZenMethod ]
{
	Set ok = 1
	Set tContainer = ##class(%CSP.UI.Portal.ML.API).GetMLConfig(pid)

	If '$IsObject(tContainer) {
		Set ok = $System.Status.GetErrorText(tSC)
	} Else {
		Set tType = tContainer.Type
		&js<
		zen('Name').setValue('#($ZCVT(tContainer.Name,"O","JS"))#');	
		zen('Type').setValue('#($ZCVT(tType,"O","JS"))#');
		zen('oldType').setValue('#(tType)#');
		zen('Description').setValue('#($ZCVT(tContainer.Description,"O","JS"))#');
		zen('Using').setValue('#($ZCVT(tContainer.Using,"O","JS"))#');
		zen('Owner').setValue('#($ZCVT(tContainer.Owner,"O","JS"))#');
		>
		If tType = 1 {
			&js<
			zen('javaTlsConfigFile').setValue('#($ZCVT(tContainer.javaTlsConfigFile,"O","JS"))#');
			>
		} Elseif tType = 2 {
			&js<
			zen('dataURL').setValue('#($ZCVT(tContainer.url,"O","JS"))#');
			zen('apiToken').setValue('#($ZCVT(tContainer.apiToken,"O","JS"))#');
			>
		}
	}
	Quit ok
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tConfig = ##class(%SYS.ML.DataRobot.Configuration).%New()
	Set ..%GetComponentById("d_dataURL").value = tConfig.url
	Set ..%GetComponentById("d_apiToken").value = tConfig.apiToken
	Kill tConfig	
	If ..PID '= "" {
		Set ..lblTitle = $$$Text("Use the form below to edit a machine learning configuration:")
		Set ..%GetComponentById("Name").disabled = 1
	} Else {
		Set ..lblTitle = $$$Text("Use the form below to create a new machine learning configuration:")
		// set defaults for new config
		Set ..%GetComponentById("Owner").value = $Username
		Set ..%GetComponentById("url").value = ..%GetComponentById("d_url").value
		Set tConfig = ##class(%SYS.ML.DataRobot.Configuration).%New()
		Set ..%GetComponentById("dataURL").value = ..%GetComponentById("d_dataURL").value
		Set ..%GetComponentById("apiToken").value = ..%GetComponentById("d_apiToken").value
	}	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	If ..PID '= "" {
		Quit $$$Text("Edit Configuration")
	} Else {
		Quit $$$Text("New Configuration")
	}
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

	Set tPageName = $$$Text("Machine Learning Configurations")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list with parameters
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Try {
		If pProxy.PID = "" {
			If pProxy.Type = 0 {
				Set tSC = ##class(%SYS.ML.AutoML.Configuration).%Create(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner)
			} ElseIf pProxy.Type = 1 {
				Set tSC = ##class(%SYS.ML.H2O.Configuration).%Create(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner,pProxy.javaTlsConfigFile)
			} ElseIf pProxy.Type = 2 {
				Set tSC = ##class(%SYS.ML.DataRobot.Configuration).%Create(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner,pProxy.url,pProxy.apiToken)
			} ElseIf pProxy.Type = 3 {
				Set tSC = ##class(%SYS.ML.PMML.Configuration).%Create(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner)			
			}
		} Else {
			set tSC=$$$OK
			if pProxy.Type=1 { set javaTlsConfigFile=pProxy.javaTlsConfigFile }
			elseif pProxy.Type=2 { set url=pProxy.url,apiToken=pProxy.apiToken }
			if pProxy.Owner'="" { set owner=pProxy.Owner }
			set SQLCODE=##class(%SYS.ML.Configuration).%SQLAlter(pProxy.Name,$case(pProxy.Type,0:"AutoML",1:"H2O",2:"DataRobot",:"PMML"),pProxy.Description,pProxy.Using,javaTlsConfigFile,.url,.apiToken,.owner,.%msg)
			if SQLCODE<0 { set tSC=$$$ERROR($$$SQLError,SQLCODE,%msg) }
#;			If pProxy.Type = 0 {
#;				Set tSC = ##class(%SYS.ML.AutoML.Configuration).%Modify(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner)
#;			} ElseIf pProxy.Type = 1 {
#;				Set tSC = ##class(%SYS.ML.H2O.Configuration).%Modify(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner)
#;			} ElseIf pProxy.Type = 2 {
#;				Set tSC = ##class(%SYS.ML.DataRobot.Configuration).%Modify(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner,pProxy.url,pProxy.apiToken)
#;			} ElseIf pProxy.Type = 3 {
#;				Set tSC = ##class(%SYS.ML.PMML.Configuration).%Modify(pProxy.Name,pProxy.Description,pProxy.Using,pProxy.Owner)			
#;			}			
		}
		If $$$ISOK(tSC) {
			Set tProxy.ok = 1
		} Else {
			Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
		}
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
