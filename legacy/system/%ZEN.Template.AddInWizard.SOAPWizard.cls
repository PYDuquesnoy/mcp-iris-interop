/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// The SOAP Wizard reads a WSDL (<i>Web Services Description Language</i>) document and creates one or more SOAP client or service classes.<br>
/// Each SOAP Client class contains one or more methods that, when invoked, remotely call the corresponding Web Method of the Web Service.<br> 
/// Each SOAP Service class contains one or more methods that may be remotely invoked.
Class %ZEN.Template.AddInWizard.SOAPWizard Extends %ZEN.Template.AddInWizard.Template [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "SOAP Wizard";

Parameter TEMPLATETITLE = "SOAP Wizard";

Parameter TEMPLATETYPE = "cls";

Parameter TEMPLATEDESCRIPTION = "creates one or more SOAP client or service classes from a WSDL document.";

/// Display title of this page <title></title>
Parameter PAGETITLE = "SOAP Wizard";

Parameter HELPID = "GSOAP_soapwizard";

Property IsEnsemble As %ZEN.Datatype.boolean;

/// Internally reconstructed URL with user entered username and password.
/// This url will not be saved into recent list.
Property InternalURL As %String;

/// Internal username to be used for HTTP authentication.
Property InternalUsername As %String;

/// Internal password to be used for HTTP authentication.
Property InternalPassword As %String;

/// Number of total Namespaces which is the same as total packages
Property TotalPackages As %ZEN.Datatype.integer;

/// String that contains package names delimited by comma.
Property Packages As %ZEN.Datatype.string;

Property lblFile As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Enter the path and name of a WSDL File:")} ];

Property lblURL As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Enter a WSDL URL:")} ];

XData CSS3Style
{
<style type="text/css">
/* style for Namespace/Packages table */
table.NSTable		{ border: black solid 1px; font-size: 1.0em; }			 
table.group td.Name { font-size: 0.8em; padding: 4px;}
tr.Header th	{ border-bottom: black solid 1px;
				text-align: left;
				color: white;
				background: rgb(91,164,220); 
				padding: 4px;
		  }
tr.DarkRow { background: #FFFFFF; }
tr.LightRow { background: #DDEEEE; }

span.filename { font-size: 0.8em; font-weight: bold; }

td.label { font-size: 0.8em;  }
			 
table.SchemaTable		{ border: black solid 1px; font-size: 1.0em; }

th.Row	{ border-bottom: black solid 1px;
				text-align: left;
				background: #3b84bc; color: white;
				padding: 4px;
		  }
th.Data	{ border-left: gray solid 1px; 
				border-bottom: black solid 1px;
				text-align: left;
				background: #3b84bc; color: white;
				padding: 4px;
		  }

td.Row 	{ border-bottom: black solid 1px; padding-right: 3px;}
td.Data 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding-left: 4px; 
				padding-right: 4px; 
			}

td.Desc 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding-left: 4px; 
				padding-right: 4px;
				font-size: 0.8em;
			}

tr.Preview { background: #FFFFFF; }

.sourceLabel {
	padding-right: 10px;
}
#iframePreview {
	background-color: white;
}
.errMsg {
	color: #404040;
	font-size: 1.0em;
	padding: 6px;
}
.normal.sslCaption {
	max-width: 100px;
	display: inline-block;
}
</style>
}

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for Namespace/Packages table */
table.NSTable		{ border: black solid 1px; font-size: 1.0em; }			 
table.group td.Name { font-size: 0.8em; padding: 4px;}
tr.Header th	{ border-bottom: black solid 1px;
				text-align: left;
				color: white;
				background: rgb(91,164,220); 
				padding: 4px;
		  }
tr.DarkRow { background: #FFFFFF; }
tr.LightRow { background: #DDEEEE; }

span.filename { font-size: 0.8em; font-weight: bold; }

td.label { font-size: 0.8em;  }
			 
table.SchemaTable		{ border: black solid 1px; font-size: 1.0em; }

th.Row	{ border-bottom: black solid 1px;
				text-align: left;
				background: #3b84bc; color: white;
				padding: 4px;
		  }
th.Data	{ border-left: gray solid 1px; 
				border-bottom: black solid 1px;
				text-align: left;
				background: #3b84bc; color: white;
				padding: 4px;
		  }

td.Row 	{ border-bottom: black solid 1px; padding-right: 3px;}
td.Data 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding-left: 4px; 
				padding-right: 4px; 
			}

td.Desc 	{ border-left: gray solid 1px; border-bottom: black solid 1px; 
				padding-left: 4px; 
				padding-right: 4px;
				font-size: 0.8em;
			}

tr.Preview { background: #FFFFFF; }
.sourceLabel {
	padding-right: 10px;
}
#iframePreview {
	background-color: white;
}
.errMsg {
	color: #404040;
	font-size: 1.0em;
	padding: 6px;
}
.normal.sslCaption {
	max-width: 100px;
	display: inline-block;
}
</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" cellStyle="padding-left:10px;">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="groupLogin" hidden="true">
<html OnDrawContent="%DrawErrNote" seed="err1"/>
<vgroup id="idLoginType" labelPosition="left" width="100%">
<radioButton id="LoginIRIS" name="LOGIN" caption="IRIS user name and password" optionValue="LoginIRIS" value="LoginIRIS"/>
<radioButton id="LoginHTTP" name="LOGIN" caption="HTTP authentication user name and password" optionValue="LoginHTTP"/>
</vgroup>
<hgroup labelPosition="left">
<text id="IRISUsername" label="Username:"/>
<text inputtype="password" id="IRISPassword" label="Password:"/>
<button caption="Try again" onclick="zenPage.doLogin();"/>
</hgroup>
<html OnDrawContent="%DrawErrNote" seed="err2"/></group>

<tabGroup id="tabGroup">

<!-- First Page -->
<tab id="tab1" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="1"/>
 <radioSet id="FileType" label="Select a WSDL file or URL:" labelClass="zenRequired" valueList="URL,FILE" displayList="URL,FILE" value="URL" captionClass="normal"
containerStyle="padding-bottom:4px;"
 onchange="zenPage.changedFileType(zenThis);"/>
 <group id="idFileName" label="Enter the path and name of a WSDL File:" labelClass="zenRequired" cellVAlign="top" >
   <hgroup id="idFile" cellVAlign="top" hidden="true">
  <text id="txtFile" showLabel="false" size="90"
 value="" hint="Required. Select a WSDL document." hintClass="helpText" onchange="this.InternalURL='';"/>
 <button id="btnBrowse" caption="Browse" onclick="zenPage.doBrowse();"/>
 </hgroup>
 <vgroup id="urlGroup" cellStyle="padding:4px;">
 <text id="txtURL" size="90" value=""
  hint="Required. Enter address of a WSDL document." hintClass="helpText" onchange="this.InternalURL='';"/>
  <select id="sslConfig" label="SSL Configuration:" value="" valueList="" showEmpty="true" hint="SSL Configuration to use when connecting to the server that is hosting this WSDL." hintClass="helpText" />
  <checkbox id="sslCheckServerId" caption="When making an SSL connection check that the server identity in the server certificate matches the name of the system being connected to" value="1" captionClass="normal"/>
 </vgroup>
</group>
 <group containerStyle="padding-top:10px;">
<select id="lstRecentList" label="Recently Used URLs:" hidden="true" showEmpty="false"
onchange="zenPage.updateURL(zenThis.getValue());"/>
<select id="lstRecentListFile" label="Recently Used Files:" hidden="true" showEmpty="false"
onchange="zenPage.updateFile(zenThis.getValue());"/>
</group>
 
</tab>

<!-- Second Page -->
<tab id="tab2" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="2"/>
<vgroup id="idMake" label="Options to control class generation and compilation:" labelClass="zenRequired" labelPosition="left">
<checkbox id="MakeClient" caption="Create Client for Web Service" captionClass="normal" value="1" onclick="zenPage.changeClient(zenThis.getValue());"/>
<checkbox id="MakeService" caption="Create Web Service" captionClass="normal"/>
<hgroup labelPosition="left">
<checkbox id="COMPILE" caption="Compile generated classes" captionClass="normal" value="1"
containerStyle="padding-top:10px;padding-bottom:10px;"/>
<spacer width="20"/>
<text id="CompileFlags" label="Compile flags:" labelClass="normal" size="2" value="dk"/>
</hgroup>
<spacer height="2"/>
<hgroup cellAlign="even">
<vgroup id="idClassType" labelPosition="left" width="100%">
<radioButton id="persistentInput" name="CLASSTYPE" label="Class Type:" labelClass="normal" caption="Persistent" optionValue="persistent" onclick="zenPage.changeClassType();"/>
<radioButton id="relationshipsInput" name="CLASSTYPE" caption="Persistent using one-many relationships" optionValue="relationships" onclick="zenPage.changeClassType();"/>
<radioButton id="relationshipsInputI" name="CLASSTYPE" caption="Persistent using indexed one-many relationships" optionValue="relationships-index" onclick="zenPage.changeClassType();"/>
<radioButton id="relationshipsInputPC" name="CLASSTYPE" caption="Persistent using parent-child relationships" optionValue="relationships-parentchild" onclick="zenPage.changeClassType();"/>
<radioButton id="serialInput" name="CLASSTYPE" caption="Serial" optionValue="serial" onclick="zenPage.changeClassType();"/>
<radioButton id="registeredInput" name="CLASSTYPE" caption="Registered" optionValue="registered" value="registered" onclick="zenPage.changeClassType();"/>
<checkbox id="CascadeDeletes" caption="Add delete trigger to classes in order to cascade deletes" hidden="true" captionClass="normal" showLabel="false"/>
<text id="Package" label="Proxy Class Package" labelClass="normal" />
<text id="SSLConfiguration" label="SSL Configuration name" hidden="true"/>
<checkbox id="SSLCheckServerIdentity" caption="When making an SSL connection check that the server identity in the server certificate matches the name of the system being connected to" captionClass="normal sslCaption" hidden="true"/>
</vgroup>
<!-- EnsembleDiv is shown only if this is an Ensemble instance -->
<vgroup id="EnsembleDiv" labelPosition="left" hidden="true" containerStyle="padding-left:40px;" cellStyle="padding-right:4px;">
<checkbox id="BusinessOperation" caption="Create Business Operation" captionClass="normal" showLabel="false" onclick="zenPage.changeBusOp(zenThis.getValue());"/>
<text id="OperationPackage" label="Business Operation Package" labelClass="normal" value="Operation"/>
<text id="RequestPackage" label="Request Object Package" labelClass="normal" value="Request"/>
<text id="ResponsePackage" label="Response Object Package" labelClass="normal" value="Response"/>
</vgroup>
</hgroup>
</vgroup>
<html><hr/></html>
 <vgroup labelPosition="left">
 <label id="lblURL" label="WSDL Document:" labelClass="caption sourceLabel"/>
 </vgroup>
<iframe id="iframePreview" showLabel="false"/>
</tab>

<!-- Third Page -->
<tab id="tab3" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;" layout="none">
<html OnDrawContent="DrawPageTitle" seed="3"/>
<checkbox id="NAMESPACE" caption="Add NAMESPACE class parameter" captionClass="normal" showLabel="false" value="1"/>
<checkbox id="MESSAGE" caption="Use unwrapped message format for document style web methods" captionClass="normal" showLabel="false"/>
<checkbox id="NOARRAY" caption="Do not create array properties" captionClass="normal" showLabel="false"/>
<checkbox id="XMLNIL" caption="Generate XMLNIL property parameter for nillable elements" captionClass="normal" showLabel="false"/>
<checkbox id="XMLNILNOOBJECT" caption="Generate XMLNILNOOBJECT property parameter for nillable elements" captionClass="normal" showLabel="false"/>
<checkbox id="NOSEQUENCE" caption="Set XMLSEQUENCE parameter to 0" captionClass="normal" showLabel="false"/>
<checkbox id="IGNORENULL" caption="Generate XMLIGNORENULL parameter set to 1" captionClass="normal" showLabel="false"/>
<checkbox id="BINARYASSTREAM" caption="Use Streams for Binary" captionClass="normal" showLabel="false"/>
<checkbox id="SUPPRESSNAMESPACE" caption="Suppress NAMESPACE in serialization" captionClass="normal" showLabel="false"/>
<checkbox id="OUTPUTTYPEATTRIBUTE" caption="Enable OutputTypeAttribute class parameter" captionClass="normal" showLabel="false" value="1"/>
<checkbox id="CLIENTURLESCAPESOAPACTION" caption="Enable Client URL Escape SOAPAction parameter" captionClass="normal" showLabel="false" value="1"/>

<group labelPosition="left" cellStyle="padding-bottom:10px;padding-right:4px;">
<select id="SECURITYIN" label="Specify SECURITYIN class parameter" labelClass="normal" valueList=",ALLOW,IGNORE,IGNOREALL,REQUIRE" displayList="(do not set),ALLOW,IGNORE,IGNOREALL,REQUIRE" value="ALLOW" showEmpty="false"/>
</group>
<html id="htmlNS" OnDrawContent="DrawNS" seed="" onrefresh="zenPage.drawDone(3);" />
<label id="idProgress3" label="Finding Namespaces..." labelClass="progress" hidden="true"/>
</tab>

<!-- Fouth Page -->
<tab id="tab4" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="4"/>
<iframe id="output"/>
<label id="idProgress4" label="Creating SOAP Classes..." labelClass="progress" hidden="true"/>
</tab>

</tabGroup>
</pane>
}

/// User typed in Username and Password. Re-construct url and try again.
ClientMethod doLogin() [ Language = javascript ]
{
	var username = zen("IRISUsername").getValue();
	var password = zen("IRISPassword").getValue();
	if (username == "") {
		alert($$$Text("Please enter Username and try again."));
		zen("IRISUsername").focus(); 
		return;
	}

	if (zen("LoginIRIS").getValue() == "LoginIRIS") {
		var type = zen("FileType").getValue();
		var obj = (type == "FILE") ? zen("txtFile") : zen("txtURL");
		var url = obj.getValue();
		if (url.indexOf("?") == -1) url = url + "?";
		else url = url + "&";
		url = url +"CacheUserName=" + username + "&CachePassword=" + password;
		this.InternalURL = url;
		this.InternalUsername = ''
		this.InternalPassword = '';
	} else {
		this.InternalUsername = username
		this.InternalPassword = password;
	}

	// hide login box again
	zen("groupLogin").setHidden(true);
	// hide error message
	this.resetMsg();
	// reset current tab back to 1 so we can re-do page 2.
	zen("tabGroup").setProperty("currTab",1);
	// redo page 2
	this.nextPage();
}

/// User changed file type. Change label. Show filename and browse button if type is FILE.
ClientMethod changedFileType(thisObj) [ Language = javascript ]
{
	var type = thisObj.getValue();
	var hasText = 0;
	if (type == "FILE") {
		var idName = this.lblFile;
		zen("urlGroup").setHidden(true);
		zen("idFile").setHidden(false);
		zen("txtFile").focus();
		zen("lstRecentList").setHidden(true);
		var recent = zen("lstRecentListFile");
	} else {
		var idName = this.lblURL;
		zen("idFile").setHidden(true);
		zen("urlGroup").setHidden(false);
		zen("txtURL").focus();
		zen("lstRecentListFile").setHidden(true);
		var recent = zen("lstRecentList");
	}
	if (recent.getProperty("valueList") != "") recent.setHidden(false);
	zen("idFileName").setProperty("label",idName);
}

/// Load the recently used url into textbox
ClientMethod updateURL(url) [ Language = javascript ]
{
	zen("txtURL").setValue(url);
	this.InternalURL = '';
	this.InternalUsername = '';
	this.Internalpassword = '';
}

/// Load the recently used file into textbox
ClientMethod updateFile(file) [ Language = javascript ]
{
	zen("txtFile").setValue(file);
	this.InternalURL = '';
	this.InternalUsername = '';
	this.Internalpassword = '';
}

/// User clicked "Create Business Operation". If it's checked default Class Type to Serial; Else default to Registered.
ClientMethod changeBusOp(ischecked) [ Language = javascript ]
{
	if (ischecked == true) {
		if (zen("registeredInput").getValue() == "registered") {
			zen("serialInput").setValue("serial");
		}
		zen("registeredInput").setHidden(true);
	} else {
		zen("registeredInput").setHidden(false);
		zen("registeredInput").setValue("registered");
	}
}

/// User clicked class type radio button. Hide cascaded deltes check box if not persistent class type.
ClientMethod changeClassType(ischecked) [ Language = javascript ]
{
	if ((zen("persistentInput").getValue() == "registered") || (zen("persistentInput").getValue() == "serial")) {
		zen("CascadeDeletes").setHidden(true);
	} else {
		zen("CascadeDeletes").setHidden(false);
	}
}

/// User clicked "Create Client for Web Service"
ClientMethod changeClient(ischecked) [ Language = javascript ]
{
	if (this.IsEnsemble) {
		zen("EnsembleDiv").setHidden(!ischecked);
	}
}

/// Launching a file selector window. 
ClientMethod doBrowse() [ Language = javascript ]
{
	var Dir = zen("txtFile").getValue();
	var wildcard = "*.wsdl";
	var url = "%ZEN.Dialog.fileSelect.cls?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=0&CSPCHD=" + this.CSPSessionCookie + "&CSPSHARE=1";
	zenLaunchPopupWindow(url,'FileSelection','status,scrollbars,resizable,width=600,height=700');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("txtFile").setValue(value);
		this.InternalURL = '';
		this.InternalUsername = '';
		this.Internalpassword = '';
		zenPage.updateState();
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set %page.IsEnsemble = ##class(%Library.EnsembleMgr).IsEnsembleInstalled()
	If %page.IsEnsemble = 1 Set ..%GetComponentById("EnsembleDiv").hidden = 0
	
	Set ..%GetComponentById("sslConfig").valueList = $$ListSSLConfigs^%SYS.SECURITY("Client")
	For filetype = "URL","FILE" {
		Set valueList = ..GetRecentList(filetype)
		If valueList '= "" {
			Set tComboId = $select(filetype = "URL": "lstRecentList", 1: "lstRecentListFile")
			Set tCombo = ..%GetComponentById(tComboId)
			Set tCombo.valueList = valueList
			Set tLastURI = $G(^ISC.SOAPClientWizard($Username,"Last",filetype))
			Set tCombo.value = tLastURI
			If (filetype = "URL") {
				Do ..%SetValueById("txtURL",tLastURI)
				Set tLastSSL = $get(^ISC.SOAPClientWizard($Username,"Recent",filetype,tLastURI,"SSLConfig"))
				Do ..%SetValueById("sslConfig",tLastSSL)
				Set tLastSSLCheckServerId = $get(^ISC.SOAPClientWizard($Username,"Recent",filetype,tLastURI,"SSLCheckServerId"))
				If tLastSSLCheckServerId="" Set tLastSSLCheckServerId=1
				Do ..%SetValueById("sslCheckServerId",tLastSSLCheckServerId)
				
			}
			ElseIf (filetype = "FILE") {
				Do ..%SetValueById("txtFile",tLastURI)
			}
		}		
	}
	#; Default file type: The last one selected. If none, then URL.
	Set LastFileType = $G(^ISC.SOAPClientWizard($Username,"Last"),"URL")
	Set ..%GetComponentById("FileType").value = LastFileType

	Quit $$$OK
}

/// Get recent list for URLs or Files. filetype = "FILE" or "URL".
ClassMethod GetRecentList(filetype) As %String [ ZenMethod ]
{
	Set valueList = ""
	Set tRecent = $order(^ISC.SOAPClientWizard($Username,"Recent",filetype,""))
	While (tRecent '= "") {
		Set valueList = valueList_$S(valueList'="":",",1:"")_tRecent
		Set tRecent = $order(^ISC.SOAPClientWizard($Username,"Recent",filetype,tRecent))
	}
	Quit valueList
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		flag = true;
		break;
	case 2:
		flag = true;
		break;
	case 3:
		flag = true;
		break;
	case 4:
		//flag = true;
		break;
	}
	return flag;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		flag = false;
		break;
	case 2:
		break;
	case 3:
		break;
	case 4:
		flag = false;
		break;
	}	
	return flag
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		break;
	case 2:
		break;
	case 3:
		break;
	case 4:
		break;
	}	
	zen("btnCancel").setDisabled(false);	
	
	return flag;
}

/// This is called when the template is first displayed;
/// This provides a chance to load the last filetype, etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	this.changedFileType(zen("FileType"));
	this.onresizeHandler();
	// To avoid displaying template tags consumed by legacy Studio Client ( Expect wrapping IE11 )
	// update the finish and cancel buttons to redirect to start
	if ((navigator!==null)&&(navigator.userAgent.search(/.*Mozilla\/4\..*MSIE 7\..*/)<0)) {
		// Not IE11 so expect launched from VS Code
		// Window close is not possible so fallback displays the wizard start page
		try {
			document.getElementById("btnFinish").firstElementChild.onclick = function (){window.status = "finished";window.open(window.location, "_self");};
			document.getElementById("btnCancel").firstElementChild.onclick = function (){window.status = "cancelled";window.open(window.location, "_self");};
		} catch(e) { 
			// Ignore future browser changes
		}
	}
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var filetype = zen("FileType").getValue();
	var url = zen("txtURL").getValue();
	var fileName = zen("txtFile").getValue();
	var proxy = new zenProxy();
	var sslConfig = zen("sslConfig").getValue();
	var sslCheckServerId = zen("sslCheckServerId").getValue();
	var isHTTPS = false;
	switch(tabNo) {
	case 1:
		// Start Region - fix up Request "Namespace"
		// Compensation where VSCode launches with URL with "NAMESPACE" ( Uppercase ) instead of "Namespace"
		if ((this.Namespace=='')&&(((location.toString().search('NAMESPACE='))>=0))) {
			tmpNamespaceLoc=location.toString()
			tmpNamespaceStartPos=tmpNamespaceLoc.indexOf('NAMESPACE=')+10
			tmpNamespaceEndPos=tmpNamespaceLoc.indexOf('&',tmpNamespaceStartPos)
			// Using URL decode to convert for example "%25SYS" into "%SYS"
			// "Namespace can start with an alphabetic character or a percent sign (%);
			// the remainder can include alphanumeric characters, dashes, or underscores."
			if (tmpNamespaceEndPos>tmpNamespaceStartPos) {
				this.Namespace=decodeURIComponent(tmpNamespaceLoc.substring(tmpNamespaceStartPos,tmpNamespaceEndPos))
			} else {
				this.Namespace=decodeURIComponent(tmpNamespaceLoc.substring(tmpNamespaceStartPos))
			}
		}
		// End Region - fix up Request "Namespace"
		if (filetype == "FILE") {
			fileName = zenTrim(fileName);
			zen("txtFile").setValue(fileName);
			if (fileName == '') {
				this.showMsg($$$Text("Please select a WSDL file."));
				zen("txtFile").focus();
				return false;
			} else {
				if (!this.FileExists(fileName)) {
					this.showMsg($$$Text("Unable to find this file: ") + fileName);
 					return false;
				}
			}
		} else {
			fileName = url;
			fileName = zenTrim(fileName);
			zen("txtURL").setValue(fileName);
			if (fileName == '') {
				this.showMsg($$$Text("Please enter URL for a WSDL document."));
				zen("txtURL").focus();
				return false;
			}
			if (url.toLowerCase().substring(0,8) == "https://") {
				isHTTPS = true;
				if (sslConfig == '') {
					this.showMsg($$$Text("Please enter an SSL Configuration for the current HTTPS URL."));
					zen("sslConfig").focus();
					return false;
				}
			}
		}
		this.resetMsg();
		zen("lblURL").setValue(fileName);
		
		if (isHTTPS) {
			zen("SSLConfiguration").setHidden(false);
			zen("SSLConfiguration").setValue(sslConfig);
			zen("SSLCheckServerIdentity").setHidden(false);
			zen("SSLCheckServerIdentity").setValue(sslCheckServerId);
		} else {
			zen("SSLConfiguration").setHidden(true);
			zen("SSLCheckServerIdentity").setHidden(true);
		}
		sslCheckServerId = sslCheckServerId ? 1 : 0;
		tabGroup.showNextTab();
		// if URL, then find out if it can actually connect.
		if (filetype == "URL") {
			proxy.url = (this.InternalURL.length > 0) ? this.InternalURL : url;
			proxy.ssl = sslConfig;
			proxy.sslCheckServer = sslCheckServerId;
			proxy.username = this.InternalUsername;
			proxy.password = this.InternalPassword;
			var multiple = this.PreProcess(proxy);
			// if error then show error and quit
			if (multiple.length > 1) {
				this.showMsg(multiple);
				zen("groupLogin").setHidden(false);
				zen("tab2").setHidden(true);
				break;
			}		
	
		} 
		if (this.InternalURL.length > 0) fileName = this.InternalURL;
		var isrc = this.GetSRC(filetype,fileName,sslConfig,sslCheckServerId,this.InternalUsername,this.InternalPassword);
		zen("iframePreview").setHidden(false);
		zen("iframePreview").setProperty("src",isrc);
		break;
	case 2:	
		proxy.url = (filetype == "FILE") ? fileName : url;
		if (this.InternalURL.length > 0) proxy.url = this.InternalURL;
		proxy.ssl = zen("SSLConfiguration").getValue();
		proxy.sslCheckServer = zen("SSLCheckServerIdentity").getValue() ? 1 : 0;
		proxy.username = this.InternalUsername;
		proxy.password = this.InternalPassword;
		proxy.package = zen("Package").getValue();
		proxy.classtype = zen("persistentInput").getValue();
		proxy.CascadeDeletes = zen("CascadeDeletes").getValue() ? 1 : 0;
		proxy.compile = (zen("COMPILE").getValue()) ? 1 : 0;
		proxy.MakeClient = (zen("MakeClient").getValue()) ? 1 : 0;
		proxy.MakeService = (zen("MakeService").getValue()) ? 1 : 0;
		proxy.businessOperation = (zen("BusinessOperation").getValue()) ? 1 : 0;
		proxy.bopackage = zen("OperationPackage").getValue();
		proxy.reqpackage = zen("RequestPackage").getValue();
		proxy.respackage = zen("ResponsePackage").getValue();
		var multiple = this.PreProcess(proxy);
		if (multiple == 1) {
			// if it is multiple, set NAMESPACE to be checked and disable the checkbox so user cannot modify
			zen("NAMESPACE").setValue(1);
			zen("NAMESPACE").setDisabled(true);
		} else {
			// if error then show error and quit
			if (multiple.length > 1) {
				this.showMsg(multiple);
				zen("groupLogin").setHidden(false);
				break;
			}		
		}
		// we passed preprocess and now load namespace content
		var html = zen("htmlNS");
		// use setProperty('seed') here so that if seed is identical to the previous one it won't reload.
		html.setProperty('seed',proxy);
		zen("idProgress3").setHidden(false);
		tabGroup.showNextTab();
		break;
	case 3:
		this.resetMsg();
		var packages = this.getPackages();
		if (packages == 0) return;
		proxy.url = (filetype == "FILE") ? fileName : url;
		if (this.InternalURL.length > 0) proxy.url = this.InternalURL;
		proxy.ssl = zen("SSLConfiguration").getValue();
		proxy.sslCheckServer = zen("SSLCheckServerIdentity").getValue() ? 1 : 0;
		proxy.username = this.InternalUsername;
		proxy.password = this.InternalPassword;
		proxy.package = zen("Package").getValue();
		proxy.classtype = zen("persistentInput").getValue();
		proxy.CascadeDeletes = zen("CascadeDeletes").getValue() ? 1 : 0;
		proxy.compile = (zen("COMPILE").getValue()) ? 1 : 0;
		proxy.compileflags = zen("CompileFlags").getValue();
		proxy.MakeClient = (zen("MakeClient").getValue()) ? 1 : 0;
		proxy.MakeService = (zen("MakeService").getValue()) ? 1 : 0;
		proxy.businessOperation = (zen("BusinessOperation").getValue()) ? 1 : 0;
		proxy.bopackage = zen("OperationPackage").getValue();
		proxy.reqpackage = zen("RequestPackage").getValue();
		proxy.respackage = zen("ResponsePackage").getValue();
		proxy.ClientPackage = ""
		proxy.ServicePackage = ""
		if (proxy.MakeClient) proxy.ClientPackage = document.getElementById("ClientPackage").value;
		if (proxy.MakeService) proxy.ServicePackage = document.getElementById("ServicePackage").value;
		proxy.ConfigPackage = document.getElementById("ConfigPackage").value;
		proxy.makeNamespace = (zen("NAMESPACE").getValue()) ? 1 : 0;
		proxy.makeMessage = (zen("MESSAGE").getValue()) ? 1 : 0;
		proxy.noarray = (zen("NOARRAY").getValue()) ? 1 : 0;
		proxy.xmlnil = (zen("XMLNIL").getValue()) ? 1 : 0;
		proxy.xmlnilnoobject = (zen("XMLNILNOOBJECT").getValue()) ? 1 : 0;
		proxy.nosequence = (zen("NOSEQUENCE").getValue()) ? 1 : 0;
		proxy.ignorenull = (zen("IGNORENULL").getValue()) ? 1 : 0;
		proxy.binaryasstream = (zen("BINARYASSTREAM").getValue()) ? 1 : 0;
		proxy.suppressNamespace = (zen("SUPPRESSNAMESPACE").getValue()) ? 1 : 0;
		proxy.outputTypeAttribute = (zen("OUTPUTTYPEATTRIBUTE").getValue()) ? 1 : 0;
		proxy.clientUrlEscapeSoapAction = (zen("CLIENTURLESCAPESOAPACTION").getValue()) ? 1 : 0;
		proxy.securityin = zen("SECURITYIN").getValue();
		var param = "url=" + encodeURIComponent(proxy.url) + "&ssl=" + encodeURIComponent(proxy.ssl) + "&sslCheckServer=" + encodeURIComponent(proxy.sslCheckServer) + "&username=" + encodeURIComponent(proxy.username) + "&password=" + encodeURIComponent(proxy.password);
		param = param + "&package=" + encodeURIComponent(proxy.package) + "&classtype=" + encodeURIComponent(proxy.classtype) + "&compile=" + proxy.compile + "&compileflags=" + proxy.compileflags;
		param = param + "&MakeClient=" + proxy.MakeClient + "&MakeService=" + proxy.MakeService + "&businessOperation=" + proxy.businessOperation;
		param = param + "&CascadeDeletes=" + proxy.CascadeDeletes;
		param = param + "&bopackage=" + proxy.bopackage + "&reqpackage=" + proxy.reqpackage + "&respackage=" + proxy.respackage;
		param = param + "&ClientPackage=" + proxy.ClientPackage + "&ServicePackage=" + proxy.ServicePackage + "&ConfigPackage=" + proxy.ConfigPackage;
		param = param + "&makeNamespace=" + proxy.makeNamespace + "&makeMessage=" + proxy.makeMessage + "&noarray=" + proxy.noarray + "&xmlnil=" + proxy.xmlnil + "&xmlnilnoobject=" + proxy.xmlnilnoobject;
		param = param + "&nosequence=" + proxy.nosequence + "&ignorenull=" + proxy.ignorenull + "&binaryasstream=" + proxy.binaryasstream + "&securityin=" + proxy.securityin;
		param = param + "&suppressNamespace=" + proxy.suppressNamespace + "&outputTypeAttribute=" + proxy.outputTypeAttribute
		param = param + "&clientUrlEscapeSoapAction=" + proxy.clientUrlEscapeSoapAction
		param = param + "&Packages=" + encodeURIComponent(packages) + "&TotalPackages=" + this.TotalPackages;
			
		zen("idProgress4").setHidden(false);
		tabGroup.showNextTab();

		// send selections to output page
		zen('output').setProperty('src','_ZEN.Template.AddInWizard.SOAPWizardOutput.cls?Namespace=' + encodeURIComponent(this.Namespace) + '&' + param);
		
		break;
	case 4:
		tabGroup.showNextTab();	
		break;
	}
	zenPage.updateState();
}

/// this method is only called from SWT browser of Atelier
ClientMethod retrieveSoapClasses() [ Language = javascript ]
{
	var output = document.getElementById('output').children[0];
	var ret = "";
	if(output)
	{
		var innerDoc = output.contentDocument || output.contentWindow.document;
		if(innerDoc){
			
			var prefixes = ["soapclass_","soapensclass_","soaptypeclass_"] 
			for(i=0;i<prefixes.length;i++){
				var idx = 1;
				var prefix = prefixes[i];
				while(innerDoc.getElementById(prefix+idx))
				{
					var soap = innerDoc.getElementById(prefix+idx);
					if(soap['textContent'] && soap['textContent'].length > 0)
						ret = ret + ":" +soap['textContent'];
					idx+=1;
				} 
			}
		}
	}
	return ret;
}

/// this method is only called from SWT browser of Atelier
ClientMethod ConfirmAddSoap() [ Language = javascript ]
{
	var ok = confirm('add these classes to selected project?');
	if(!ok){ return 'N';}
	return 'Y'
}

/// this method is only called from SWT browser of Atelier
ClientMethod startMonitorFinishButton() [ Language = javascript ]
{
	document.getElementById("btnFinish").children[0].onclick = function (){window.status = "finished";};
	document.getElementById("btnCancel").children[0].onclick = function (){window.status = "cancelled";};
}

/// Validate and return packages string. If a package name is empty, display message and return 0.
ClientMethod getPackages() [ Language = javascript ]
{
	var len = this.TotalPackages;
	var packages = "";
	var rowid;
	var item;
	for (var i=1; i<len; i++) {
		rowid = "row" + i;
		item = document.getElementById(rowid).value;
		/// strip off surrounding write spaces
		if (document.getElementById(rowid).type != "hidden") {
			item = zenTrim(item);
			if (item == "") {
				this.showMsg($$$Text("Please provide a package name for every namespace."));
				packages = 0;
				break;
			}
		}
		packages = packages + item + ",";
	}
	return packages;
}

ClientMethod showMsg(msg) [ Language = javascript ]
{
	zen("idRespond").setValue(msg);
 	zen("idRespond").setHidden(false);
}

ClientMethod resetMsg() [ Language = javascript ]
{
	zen("idRespond").setValue('');
 	zen("idRespond").setHidden(true);
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
	this.resetMsg();
	zen("groupLogin").setHidden(true);
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		break;
	case 2:
		tabGroup.showPreviousTab();
		/// reload the Recent URL list
		var filetype = zen("FileType").getValue();
		var RecentURLs = this.GetRecentList(filetype);
		if (filetype == "URL") lst = zen("lstRecentList");
		else lst = zen("lstRecentListFile");
		lst.setProperty("valueList",RecentURLs);
		lst.refreshContents(0);
		lst.setHidden(false);
		break;
	case 3:
		tabGroup.showPreviousTab();
		break;
	case 4:
		tabGroup.showPreviousTab();
		break;
	case 5:
		tabGroup.showPreviousTab();
		break;
	}
	zenPage.updateState();
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = ""
	If pSeed = 1 {
		Set tPageTitle = $$$Text("The SOAP Wizard reads a WSDL (<i>Web Services Description Language</i>) document and creates one or more SOAP client or service classes. Each SOAP Client class contains one or more methods that, when invoked, remotely call the corresponding Web Method of the Web Service.  Each SOAP Service class contains one or more methods that may be remotely invoked.")_"<br><br>"_
		$$$Text("The Wizard will also create any additional classes needed to represent any complex types (objects) used by the Web Service. These additional classes are placed within a package named after the Service Name.")_"<br><br>"_
		$$$Text("To start, enter the location of the WSDL document that describes the Web Service and then press <span CLASS='guibutton'>Next</span>.")
	} ElseIf pSeed = 2 {
		Set tPageTitle = $$$Text("The WSDL you have selected is displayed below. If this is correct, select options as wanted and press <span class='guibutton'>Next</span>.")
	} ElseIf pSeed = 3 {
		Set tPageTitle = $$$Text("The SOAP Wizard has determined that that your WSDL uses the following XML namespaces.")_"<br><br>"_ 
		$$$Text("The Wizard will generate all the classes for an XML namespace within the same class package. You can specify the package name used for each XML namespace using the fields below.")_"<br>"_
		$$$Text("Afterwards, press <span class='guibutton'>Next</span>.")
	} ElseIf pSeed = 4 {
		Set tPageTitle = $$$Text("The SOAP Wizard is generating and saving the new class definitions to the database.")_"<br><br>"_
		$$$Text("Press the <span class='guibutton'>Finish</span> button when generation is complete.")
	}
	Set tStep = ""
	Set:pSeed>1 tStep = $$$FormatText($$$Text("Step %1"),pSeed)_" - "
	&html<<div class="Description">#(tStep)##(tPageTitle)#
	</div><hr>>
	Quit $$$OK
}

ClassMethod %DrawErrNote(pSeed) As %Status
{
	If pSeed = "err1" {
		Set tString = "<br>"_$$$TextHTML("This error can occur if the WSDL server requires you to provide a user name and password.")
		Set tString=tString_"<br>"_$$$TextHTML("If the WSDL server is an InterSystems IRIS server, enter a suitable IRIS user name and password and try again:")
		Set tString=tString_"<br>"_$$$TextHTML("If the WSDL server requires HTTP authentication, enter a suitable user name and password for HTTP authentication and try again:")_"<hr/>"
	} Else {
		Set tString = "<hr/>"_$$$TextHTML("Note that errors can also occur for other reasons. For example, the server could require an SSL connection or the WSDL might not be a valid XML document.")
	}
	&html<<div class="errMsg">#(tString)#
	</div>>
	Quit $$$OK
}

/// This method is fired up after onDrawContent is finished. Hide progress message and display error if exists.
ClientMethod drawDone(tab) [ Language = javascript ]
{
	var result = this.GetStatus(tab);
	if (result.Status == "Done") {
		if (result.Error != "") {
			this.showMsg(result.Error);
		}
		var id = "idProgress"+tab;
		zen(id).setHidden(true);
	} 
	else {
		var error = $$$Text("Unexpected error occurred. Loading did not finish as expected.");
		this.showMsg(error);
	}
}

/// Given the url or file, load the file.
/// Save the url or file to ^ISC.SOAPClientWizard.
ClassMethod GetSRC(filetype As %String, url As %String, sslConfig As %String = "", sslCheckServerId As %Boolean, username As %String = "", password As %String = "") As %String [ ZenMethod ]
{
	Set src = ""
	Do {
		Set pos=$find(url,"%3F")
		If pos'=0 set $extract(url,pos-3,pos-1)="?"
	} While pos'=0

	Do ..SaveLast(filetype, url, sslConfig, sslCheckServerId)
	
	// Use schema server for all URLs
	Set src = "_XML.Utils.SchemaServer.cls?"
 	If filetype = "FILE" {
	 	// If file radio button was checked, then assume file.
	 	Set src = src _ "FILE=" _ ..Encrypt($zcvt(url,"O","UTF8"))
 	} Else {
	 	// To maintain compatability continue to check for possible Windows or file:// file in URL box.
		If $zcvt($extract(url,1,7),"L")="file://" {
			Set url=$extract(url,8,$length(url))
			Set src = src _ "FILE=" _ ..Encrypt($zcvt(url,"O","UTF8"))
		} ElseIf $extract(url,1,3)?1.1A1.1":"1.1(1.1"\",1.1"/") {
			Set src = src _ "FILE=" _ ..Encrypt($zcvt(url,"O","UTF8"))
		} Else {
			Set src = src _ "URL=" _ ..Encrypt($zcvt(url,"O","UTF8")) 
			If (sslConfig '= "") {
				Set src = src _ "&SSLCONFIG=" _ ..Encrypt($zcvt(sslConfig,"O","UTF8"))
				Set src = src _ "&SSLCHECKSERVER=" _ ..Encrypt(sslCheckServerId)
			}
			If username'="" {
				Set src = src _ "&USERNAME=" _ ..Encrypt($zcvt(username,"O","UTF8"))
				Set src = src _ "&PASSWORD=" _ ..Encrypt($zcvt(password,"O","UTF8"))
			}
		}
 	}
 	
	Quit src
}

/// FileType is either "FILE" or "URL".
ClassMethod SaveLast(filetype, url, sslConfig = "", sslCheckServerId) [ ZenMethod ]
{
	// remember settings 
	If filetype = "URL" {
		Set query=$piece(url,"?",2,*)
		If query'="" {
			Set url=$piece(url,"?",1)_"?"
			For i=1:1:$length(query,"&") {
				Set param=$piece(query,"&",i)
				If $case($piece(param,"=",1),"IRISUsername":0,"IRISPassword":0,"CacheUserName":0,"CachePassword":0,:1) {
					Set url=url_param_"&"
				}
			}
			Set url=$extract(url,1,*-1)
		}
	}
	Set ^ISC.SOAPClientWizard($Username,"Last") = filetype
	Set ^ISC.SOAPClientWizard($Username,"Last",filetype) = url
	Set ^ISC.SOAPClientWizard($Username,"Recent",filetype,url) = $zdt($h,3)
	If (filetype = "URL") && (sslConfig '= "") {
		Set ^ISC.SOAPClientWizard($Username,"Recent",filetype,url,"SSLConfig") = sslConfig
		Set ^ISC.SOAPClientWizard($Username,"Recent",filetype,url,"SSLCheckServerId") = sslCheckServerId
	}
	
 
	// clean up recent URL list
	// sort list by time, delete oldest...
	Set tCount = 0
	Set tRecent = $order(^ISC.SOAPClientWizard($Username,"Recent",filetype,""))
	While (tRecent '= "") {
		Set tCount = tCount + 1
		Set tSort(^ISC.SOAPClientWizard($Username,"Recent",filetype,tRecent)) = tRecent
		Set tRecent = $order(^ISC.SOAPClientWizard($Username,"Recent",filetype,tRecent))
	}
	
	// remove oldest items (there are up to 10)
	While (tCount > 10) {
		Set tOld = $order(tSort(""))
		Kill ^ISC.SOAPClientWizard($Username,"Recent",filetype,tSort(tOld))
		Set tCount = tCount - 1
	}
}

/// Check if file exists
ClassMethod FileExists(filename) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(filename)
}

/// For page 3, do preprocess to find out whether it is multiple
ClassMethod PreProcess(proxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set url = proxy.url
	Set ssl = proxy.ssl
	Set sslCheckServer = proxy.sslCheckServer
	Set username = proxy.username
	Set password = proxy.password
	Set schemaid = $G(%session.Data("schemaid"))

	If (schemaid '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
		Set schemaid = ""
 	}
 
 	// Workaround bug in $zcvt(s,"I","URL")
	do {
		set pos=$find(url,"%3F")
		if pos'=0 set $extract(url,pos-3,pos-1)="?"
	} while pos'=0
	
 	Set multiple = 0
 	
 	// use URL
	Set WSDLreader = ##class(%SOAP.WSDL.Reader).%New()
	Set WSDLreader.SSLConfiguration = ssl
	Set WSDLreader.SSLCheckServerIdentity = sslCheckServer
	If username'="" {
		Set http=##class(%Net.HttpRequest).%New() 
		Set http.Username=username 
		Set http.Password=password 
		Set WSDLreader.HttpRequest=http 
	}

	Set sc = WSDLreader.PreProcess(url,.multiple)
	If $$$ISERR(sc) {
		Do $System.Status.DecomposeStatus(sc,.err)
		Set multiple = "<h3>"_$$$TextHTML("Error Reading WSDL")_"</h3><br>"_..EscapeHTML(err(1))
	} ElseIf $order(WSDLreader.SchemaReader.NSInfo(""))="" {
		Set multiple = "<h3>"_$$$TextHTML("No WSDL definition was found.")_"</h3><br>"
	}
	Kill WSDLreader
	Quit multiple
}

/// Draw page 3, namespaces
ClassMethod DrawNS(proxy As %ZEN.proxyObject) As %Status
{
 
	Set tSC = $$$OK
	Quit:proxy="" tSC
	Set ^ISC.SOAPClientWizard($Username,"Status") = ""
	Set ^ISC.SOAPClientWizard($Username,"Error") = ""
	Set error = ""
	Set package = proxy.package
	Set classtype = proxy.classtype
	Set CascadeDeletes = proxy.CascadeDeletes
	Set compile = proxy.compile
	Set MakeClient = proxy.MakeClient
	Set MakeService = proxy.MakeService
	If MakeClient {
		Set businessOperation = proxy.BusinessOperation '= ""
		Set bopackage = proxy.OperationPackage
		If bopackage="" Set bopackage="Operation"
		Set reqpackage = proxy.RequestPackage
		If reqpackage="" Set reqpackage="Request"
		Set respackage = proxy.ResponsePackage
		If respackage="" Set respackage="Response"
	} Else {
		Set businessOperation = 0
		Set bopackage = ""
		Set reqpackage = ""
		Set respackage = ""
	}
	Set url = proxy.url
	Set ssl = proxy.ssl
	Set sslCheckServer = proxy.sslCheckServer
	Set username = proxy.username
	Set password = proxy.password
	Set schemaid = $G(%session.Data("schemaid"))
	// Workaround bug in $zcvt(s,"I","URL")
	do {
		set pos=$find(url,"%3F")
		if pos'=0 set $extract(url,pos-3,pos-1)="?"
	} while pos'=0
	Set schemaid = $G(%session.Data("schemaid"))
	If (schemaid '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
		Set schemaid = ""
 	}
 	
 	Set multiple=0
 		
 	// use URL
	Set WSDLreader = ##class(%SOAP.WSDL.Reader).%New()
	Set WSDLreader.SSLConfiguration = ssl
	Set WSDLreader.SSLCheckServerIdentity = sslCheckServer
	If username'="" {
		Set http=##class(%Net.HttpRequest).%New() 
		Set http.Username=username 
		Set http.Password=password 
		Set WSDLreader.HttpRequest=http 
	}
	Set sc = WSDLreader.PreProcess(url,.multiple)
	If $$$ISERR(sc) {
		Do $System.Status.DecomposeStatus(sc,.err)
		Set error = err(1)
	}

 	// Save the schema info for later use
 	Set reader = WSDLreader.SchemaReader
	Set schemaid = $select(error="":reader.Save(),1:"")
	Set %session.Data("schemaid") = schemaid
	Set ^ISC.SOAPClientWizard($Username,"schemaid")=schemaid
	
	Set th1 = $$$Text("XML Namespace")
	Set th2 = $$$Text("Package Name")
	Set serviceName = $$$Text("[service name]")
	Set lblWebClient = $$$Text("Web Client Package")
	Set lblWebService = $$$Text("Web Service Package")	
	Set proxyPackage = $select(package="":serviceName_".",1:"")

	&html<<table class="NSTable" cellspacing="2" cellpadding="5">
		<tr class="Header">
		<th>&nbsp;</th>
		<th>#(th2)#</th>
		</tr>>
	If MakeClient {
		&html<<tr class="DarkRow">
		<td class="Name">#(lblWebClient)#</td>
		<td class="Name" nowrap>#(proxyPackage)#<input type="text" id="ClientPackage" name="ClientPackage" value="#(package)#"></td>
		</tr>>
	}
	If MakeService {
		&html<<tr class="DarkRow">
			<td class="Name">#(lblWebService)#</td>
			<td class="Name" nowrap>#(proxyPackage)#<input type="text" id="ServicePackage" name="ServicePackage" value="#(package_$select(package'="":".",1:""))#Service"></td>
		</tr>>
	}
	Set lblConfig = $$$Text("Configuration Sub-Package. If not specified, append 'Config' to class name in same package.")
	&html<<tr class="DarkRow">
		<td class="Name" width="70%">#(lblConfig)#</td>
		<td class="Name"><input type="text" id="ConfigPackage" name="ConfigPackage" value=""></td>
	</tr>>
	If businessOperation {
		Set lblOP1 = $$$Text("Business Operation Package")
		Set lblOP2 = $$$Text("Request Object Package")
		Set lblOP3 = $$$Text("Response Object Package")
		&html<<tr><td class="label">#(lblOP1)#</td><td class="label">#(bopackage)#</td></tr>
		<tr><td class="label">#(lblOP2)#</td><td class="label">#(reqpackage)#</td></tr>
		<tr><td class="label">#(lblOP3)#</td><td class="label">#(respackage)#</td></tr>>
	}
	&html<<tr><td colspan="3">&nbsp;</td></tr>
	<tr class="Header">
		<th>#(th1)#</th>
		<th>#(th2)#</th>
	</tr>>
		
	// find out if we need to get a Default Package name...
	// this is only if there is no explicit default namespace
	Set hasDefault = 0
	Set n = $order(reader.NSInfo(""))
	While (n '= "") {
		Set pkg = $get(reader.NSInfo(n,"Package"))
		If (pkg = "$defaultNS") {
			Set hasDefault = 1
			Quit
		}
		
		Set n = $order(reader.NSInfo(n))
	}
	
	// list the namespaces found by the reader
	Set n = $order(reader.NSInfo(""))
	Set row = 1
	set basepkg=package_$select(package="":"",1:".")
	While (n '= "") {
		Set uri = $get(reader.NSInfo(n,"uri"))
		Set pkg = $get(reader.NSInfo(n,"Package"))
		Set label = uri
		Set ctrl = "NSINFO"
		
		If (uri = "$defaultNS") {
			If ('hasDefault) {
				// special case for default NS
				Set label = $$$Text("Default Namespace")
				Set ctrl = "DEFNS"
			}
		}
		
		If (pkg = "$defaultNS") {
			// use default name
			Set pkg = $get(^JSchema.LastPackage)
		}
		
		// special check for WSDL namespace
		If ((uri [ "schemas.xmlsoap.org/wsdl/") && (pkg = "")) {
			Set pkg = "wsdl"
		}
		
		Set rowid = "row"_row

		If (##class(%XML.Utils.SchemaReader).IsXMLSchemaNS(uri)) {
			// skip the XML schema namespace... (place holder)
			&html<<tr><td><input type="hidden" id="#(rowid)#" name="NSINFO" value=""></td><td></td></tr>>
		}
		Else {
			If (hasDefault && (ctrl = "DEFNS")) {
				// skip this
			}
			Else {
				&html<<tr class="#($select((row#2=0):"DarkRow",1:"LightRow"))#">
				<td class="Name">#(label)#</td>
				<td class="Name" nowrap>#(proxyPackage)#<input type="text" id="#(rowid)#" name="#(ctrl)#" value="#(basepkg_pkg)#">
				</td>
				</tr>>
			}
		}
		Set n = $order(reader.NSInfo(n))
		Set row = row + 1
	}

	&html<</table>>
	Set ^ISC.SOAPClientWizard($Username,"Error") = error
	Set ^ISC.SOAPClientWizard($Username,"Status") = "Done"

	Set %page.TotalPackages = row

	Quit tSC
}

/// tab = 3: NS - when DrawNS is finished, Status is "Done".
ClassMethod GetStatus(tab) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.Status = $G(^ISC.SOAPClientWizard($Username,"Status"))
	Set proxy.Error = $G(^ISC.SOAPClientWizard($Username,"Error"))
	Quit proxy
}

/// class loading finished. Enable Finish button and hide progress message.
ClientMethod outputDone() [ Language = javascript ]
{
	zen('btnFinish').setDisabled(false);
	zen('btnFinish').setProperty("controlClass","commandButton");
	zen("idProgress4").setHidden(true);
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("iframePreview");
	var wd = (document.documentElement.clientWidth ? document.documentElement.clientWidth : document.body.clientWidth) - 20;
	var ht = (document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight) - 500;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
	// resize the output frame
	var tabNo = zen('tabGroup').getCurrTabNo();
	var ht = (document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight) - 250;
	zen("output").setProperty("width",wd);
	zen("output").setProperty("height",ht);
}

/// Zen page notification of an HTTP request. This method can be overwritten
/// by subclasses.<br/>
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Set %response.Timeout = 3600
	Quit 1
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.<br/>
/// (1) adding classes to the project;
/// (2) classes may be opened if Studio's option "Open file to added project" is checked.
Method %OnTemplateAction() As %Status
{
	Set cls = $order(%session.Data("ClassList",""))
	While (cls '= "") {
		Do ..%AddToProject(cls _ ".cls")
		Do ..%AddToSourceControl(cls _ ".cls")
		Set cls = $order(%session.Data("ClassList",cls))
	}
	If ($get(%session.Data("schemaid")) '= "") {
		Do ##class(%XML.Utils.SchemaReader).Delete(%session.Data("schemaid"))
	}
	Kill %session.Data("ClassList")
	Kill %session.Data("schemaid")
	// delete temp data
	Set schemaid = $G(^ISC.SOAPClientWizard($Username,"schemaid"))
	Do ##class(%XML.Utils.SchemaReader).Delete(schemaid)
	
	Quit 1
}

}
