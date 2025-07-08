/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - InterSystems IRIS Public Key Infrastructure
Class %CSP.UI.Portal.PKI Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.PKI.zen";

Parameter HELPADDRESS = "System Administration,Security,Public Key Infrastructure";

/// Displayed name of this page.
Parameter PAGENAME = "Public Key Infrastructure";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// Indicate whether the local Certificate Authority server has been defined.
Property isCAServerDefined As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicate whether the local Certificate Authority client has been defined.
Property isCAClientDefined As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
a.link {
	font-size: 11px;	
}
a.link:hover {
	border: 1px solid #3a5162;
	padding: 2px;
}
/* @doc="cusomize element around node image and caption." */
.expandoNode a {
	padding: 5px;
	font-weight: bold;
}

/* @doc="Mouse over expando caption." */
.expandoNode a:hover {
	background: #eeeeee;
	color: black;
	padding: 5px;
}
/* @doc="cusomize menu item." */
.menuTable {
	border: 0px solid white;
}
a.menuItem {
	color: #3a5162;
	font-size: 0.8em;
	font-weight: bold;
}
/* @doc="cusomize mouse over menu item." */
a.menuItem:hover {
	background: #215772;
	color: white;
}
a.menuItemDisabled {
	font-size: 0.8em;
	background: white;
}
/* additional style for option on the menu item */
.optionSelected {
	background-image: url('#(..Link("/csp/broker/images/grad-halfgray-10x30.png"))#');
	background-repeat: repeat-x;
}
.optionUnselected {
	background-image: url('#(..Link("/csp/broker/images/spacer.gif"))#');
	background-repeat: repeat-x;
}

/* style for Process Pending Certificate Singing Requrest */
table.PendTable		{ font-size: 12px; }			 
table.PendTable td.Header {
	font-size: 12px;
	font-weight: bold;
	text-align: left;
	padding: 4px;
}
table.PendTable td.Data {
	font-size: 12px;
	text-align: left;
	padding: 4px;
}
tr.LiteRow { background: #FFFFFF; }
tr.DarkRow { background: #DDEEEE; }

/* Progress message style */
.progress { 
	color: green; 
	font-weight: bold;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;" cellVAlign="top">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<hgroup valign="top">
<vgroup valign="top">
<expando id="expClient" caption="Certificate Authority Client" childIndent="24px" imageContracted="/csp/broker/images/contracted.gif" imageExpanded="/csp/broker/images/expanded.gif" expanded="true" 
title="Select an option below to configure Certificate Authority Client" valign="top">
<spacer height="4"/>
<menu id="menuClient" layout="vertical">
<menuItem id="option1" caption="Submit Certificate Signing Request to Certificate Authority server"
link="javascript:zenPage.doDetails('1');" image="/csp/broker/images/disclosure-contracted.gif" imageHeight="9" imageWidth="9"
title="This option is available when local Certificate Authority client is defined." />
<menuItem id="option2" caption="Get Certificate(s) from Certificate Authority server"
link="javascript:zenPage.doDetails('2');" image="/csp/broker/images/disclosure-contracted.gif" imageHeight="9" imageWidth="9"
title="This option is available when local Certificate Authority client is defined." />
<menuItem id="option3" caption="Configure local Certificate Authority client"
link="javascript:zenPage.doDetails('3');" image="/csp/broker/images/disclosure-contracted.gif" imageHeight="9" imageWidth="9"
title="This option is available when local Certificate Authority server is defined."
/>
</menu>
</expando>
<spacer height="6"/>
<expando id="expServer" caption="Certificate Authority Server" childIndent="24px" imageContracted="/csp/broker/images/contracted.gif" imageExpanded="/csp/broker/images/expanded.gif" expanded="true"
title="Select an option below to configure Certificate Authority Server" valign="top">
<spacer height="4"/>
<menu id="menuServer" layout="vertical">
<menuItem id="option4" caption="Process pending Certificate Signing Requests"
link="javascript:zenPage.doDetails('4');" image="/csp/broker/images/disclosure-contracted.gif" imageHeight="9" imageWidth="9"
/>
<menuItem id="option5" caption="Configure local Certificate Authority server"
link="javascript:zenPage.doDetails('5');" image="/csp/broker/images/disclosure-contracted.gif" imageHeight="9" imageWidth="9"
/>
</menu>
</expando>
</vgroup>

<spacer width="20px"/>

<vgroup valign="top">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<form id="form1" hidden="true" label="Submit Certificate Signing Request to Certificate Authority server" 
autocomplete="false"
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top" >
<text id="SubmitFilename" label="File name root for local Certificate and Private Key files (without extension)" size="58"
hint="Required. Valid characters: alphanumeric, hyphen or underscore." onchange="zenPage.doModified();"/>
<vgroup id="idSubmitPassword" labelPosition="left">
<text inputtype="password" id="SubmitPassword" label="Password for Private Key file"
autocomplete="new-password" onchange="zenPage.doModified();"/>
<text inputtype="password" id="SubmitPassword1" label="Confirm Password" 
autocomplete="new-password" onchange="zenPage.doModified();"/>
</vgroup>
<fieldSet id="idSubmitSubjectDN" label="Subject Distinguished Name: " 
containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="left">
<html id="htmlSubmitSubjectDN" OnDrawContent="DrawSubjectDN"/>
</fieldSet>
<hgroup>
<button id="btnSave1" caption="Submit" controlClass="commandButton" onclick="zenPage.doSave('1');"/>
<button id="btnCancel1" caption="Cancel" title="Discard changes." controlClass="commandButton" onclick="zenPage.doCancel();"/>
</hgroup>
</form>

<form id="form2" hidden="true" label="Get Certificate(s) from Certificate Authority server" 
autocomplete="false"
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top">
<hgroup labelPosition="left">
<button id="btnGetCert0" caption="Get Certificate Authority Certificate" controlClass="commandButton" onclick="zenPage.doGetCertificate(0);"/>
</hgroup>

<html id="htmlGetCAList" OnDrawContent="DrawGetCAList" seed="" onrefresh="zenPage.drawDone('2');"/>
<label id="idProgress2" label="Retrieving data. Please wait..." labelClass="progress" hidden="true"/>

</form>

<form id="form3" hidden="true" label="Configure local Certificate Authority client" 
autocomplete="false"
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top">
<text id="ConfigServer" label="Certificate Authority server hostname" size="58"
hint="Required. " onchange="zenPage.doModified();"/>
<hgroup>
<checkbox id="UseTLS" label="Use SSL/TLS" value="false" onchange="zenPage.showTLS(!zenThis.getValue());"/>
<select id="TLSConfiguration" label="SSL/TLS Configuration" hidden="true" containerStyle="padding-left:15px" />
</hgroup>
<text id="ConfigPort" label="Certificate Authority WebServer port number" size="5"
hint="Required. " onchange="zenPage.doModified();"/>
<hgroup cellStyle="padding-bottom:2px;" >
<text id="ConfigPath" label="Certificate Authority server path" size="58"
hint="Required. " />
<button id="btnBrowse3" caption="Browse..." hidden="true" onclick="zenPage.browseSelect('ConfigPath');" valign="middle"/>
</hgroup>
<fieldSet id="idContact" label="Local technical contact" 
containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" cellStyle="padding:5px;" labelPosition="left">
<text id="ConfigContactName" label="Name" size="40" onkeyup="zenPage.changeContact(zenThis.getValue());"
hint="Required. " onchange="zenPage.doModified();"/>
<text id="ConfigContactPhone" label="Phone number" size="40"
onchange="zenPage.doModified();"/>
<text id="ConfigContactEmail" label="Email address" size="40"
onchange="zenPage.doModified();"/>
</fieldSet>
<hgroup>
<button id="btnSave3" caption="Save" controlClass="commandButton" onclick="zenPage.doSave('3');"/>
<button id="btnCancel3" caption="Cancel" title="Discard changes." controlClass="commandButton" onclick="zenPage.doCancel();"/>
</hgroup>
</form>

<form id="form4" hidden="true" label="Process pending Certificate Signing Requests" 
autocomplete="false"
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top">
<tablePane id="table" 
queryClass="PKI.CSR" 
queryName="List" 
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="5000"
showValueInTooltip="true"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
>
<column colName="Name" hidden="true"/>
<column colName="Hostname" header="Hostname"/>
<column colName="Instance" header="Instance"/>
<column colName="Filename" header="Filename"/>
<column linkCaption="Process" link="#" onclick="zenPage.doProcess('#(%query.Name)#');return false;" />
<column linkCaption="Delete" link="#" onclick="zenPage.doProcessDelete('#(%query.Name)#');return false;" />
</tablePane>

<vgroup id="idProcessPending" hidden="true">
<html id="htmlProcessPending" OnDrawContent="DrawProcessPending" onrefresh="document.getElementById('btnIssueCancel').focus();"/>
<hgroup id="idProcessPassword" hidden="true">
<text inputtype="password" id="ProcessPassword" label="Password for Certificate Authority's Private Key file"/>
<button id="btnProcessFinish" caption="Finish" controlClass="commandButton" onclick="zenPage.doProcessFinish();" valign="bottom"/>
</hgroup>
</vgroup>
</form>

<form id="form5" hidden="true" label="Configure local Certificate Authority server " 
autocomplete="false"
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top" >
<link id="linkReinitialize" caption="Reinitialize" href="#" align="right" onclick="zenPage.doReinitialize();return false;"
title="Delete the existing configuration and all pending requests and start over."/>
<text id="ConfigCAFilename" label="File name root for Certificate Authority's Certificate and Private Key files (without extension)" size="58"
hint="Required. Valid characters: alphanumeric, hyphen or underscore." onchange="zenPage.doModified();"/>
<hgroup id="idCAPath" cellStyle="padding-bottom:2px;" >
<text id="ConfigCAPath" label="Directory for Certificate Authority's Certificate and Private Key files" size="58"
 autocomplete="new-password"
hint="Required. " onchange="zenPage.doModified();"/>
<button id="btnBrowse5" caption="Browse..." onclick="zenPage.browseSelect('ConfigCAPath');" valign="middle"/>
</hgroup>
<label id="lblRequired" label="[Existing files will be used]" hidden="true"/>
<!-- the following fields are required and are shown when user is not using existing files above -->
<group id="idRequired" hidden="true">
<vgroup id="idConfigPassword" labelPosition="left">
<text inputtype="password" id="ConfigPassword" label="Password to Certificate Authority's Private Key file"
autocomplete="new-password" onchange="zenPage.doModified();"/>
<text inputtype="password" id="ConfigPassword1" label="Confirm Password" 
autocomplete="new-password" onchange="zenPage.doModified();"/>
</vgroup>
<fieldSet id="idSubjectDN" label="Certificate Authority Subject Distinguished Name: " 
containerStyle="font-size:12px;padding-left:4px;padding-right:4px;" labelPosition="left">
<html id="htmlSubjectDN" OnDrawContent="DrawSubjectDN"/>
</fieldSet>
<hgroup id="idConfigDays" labelPosition="left" enclosingStyle="padding-top:4px;">
<text id="ConfigDays" label="Validity period for Certificate Authority's Certificate (days)" size="5"
 onchange="zenPage.doModified();"/>
</hgroup>
</group>
<hgroup labelPosition="left">
<text id="ConfigDaysIssued" label="Validity period for Certificates issued by Certificate Authority (days)" size="5" hidden="true"
 onchange="zenPage.doModified();"/>
</hgroup>

<!-- end of Requird fields -->

<fieldSet id="idEMail" label="Configure email" hidden="true"
containerStyle="font-size:12px;padding-left:4px;padding-right:4px;">
<hgroup showLabel="false">
<text id="ConfigSMTPServer" label="SMTP server" size="20" onchange="zenPage.doModified();" onkeyup="zenPage.changeSMTP(zenThis.getValue());"/>
<text id="ConfigSMTPUsername" label="SMTP username" size="20"  onchange="zenPage.doModified();"/>
</hgroup>
<hgroup showLabel="false">
<text inputtype="password" id="ConfigSMTPPassword" label="SMTP password" onchange="zenPage.doModified();"/>
<text inputtype="password" id="ConfigSMTPPassword1" label="Confirm password" onchange="zenPage.doModified();"/>
</hgroup>
<text id="ConfigAdminEmail" label="Certificate Authority server administrator's email address" size="46"
 onchange="zenPage.doModified();"/>
</fieldSet>

<hgroup id="idSave5">
<button id="btnBack" caption="Back" hidden="true" controlClass="commandButton" title="Back to the first two required fields." onclick="zenPage.doBack();"/>
<button id="btnNext" caption="Next" controlClass="commandButton" title="Enter the first two required fields and then click here to continue." onclick="zenPage.doNext();"/>
<button id="btnSave5" caption="Save" hidden="true" controlClass="commandButton" onclick="zenPage.doSave('5');"/>
<button id="btnCancel5" caption="Cancel" title="Discard changes." controlClass="commandButton" onclick="zenPage.doCancel();"/>
</hgroup>

</form>
</vgroup>
</hgroup>
</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&showdirectoryonly=1');
	zenLaunchPopupWindow(url,name,'resizable,width=600,height=700');
}

/// User clicked the Back button for CA Server form. Hide the required fields and show the first two.
ClientMethod doBack() [ Language = javascript ]
{
	zen("ConfigCAFilename").setHidden(false);
	zen("idCAPath").setHidden(false);
	zen("btnNext").setHidden(false);
	zen("btnBack").setHidden(true);
	zen("btnSave5").setHidden(true);
	zen("lblRequired").setHidden(true);
	zen("idRequired").setHidden(true);
	zen("ConfigDaysIssued").setHidden(true);
	zen("idEMail").setHidden(true);
}

/// User clicked Continue for CA Server form. Validate the first two required fields and decide whether to show the rest of required fields.
ClientMethod doNext() [ Language = javascript ]
{
	var pass = true;	
	if (!this.validateRequired(zen("ConfigCAFilename"),pass,"S")) pass = false;
	if (!this.validateRequired(zen("ConfigCAPath"),pass,"S")) pass = false;
	/// if any of the required fields is not filled then prompt those first.
	if (!pass) {
		this.showMsg($$$Text("Please enter required field(s)."),1);
		return pass;
	}
	this.resetMsg("");
	/// check if they exist
	var ConfigCAFilename = zen("ConfigCAFilename").getValue();
	var ConfigCAPath = zen("ConfigCAPath").getValue();
	zen("ConfigCAFilename").setHidden(true);
	zen("ConfigDaysIssued").setHidden(false);	
	zen("idCAPath").setHidden(true);
	zen("btnNext").setHidden(true);
	zen("btnBack").setHidden(false);
	zen("btnSave5").setHidden(false);
	var exists = this.Exist(ConfigCAPath,ConfigCAFilename);
	if (exists) {
		zen("idRequired").setHidden(true);
		zen("lblRequired").setHidden(false);
		zen("idEMail").setHidden(false);		
	} else {
		zen("idRequired").setHidden(false);
		zen("lblRequired").setHidden(true);
		zen("idEMail").setHidden(false);
	}
	zen("ConfigPassword").focus();
}

/// User clicked Cancel on an option.
ClientMethod doCancel() [ Language = javascript ]
{
	this.resetMsg("");
	this.setModified(false);
	for (var i=1; i<=5; i++) {
		formId = "form" + i;
		optionId = "option" + i;
		zen(formId).setHidden(true);
		opclass="optionUnselected";
		zen(optionId).setProperty("enclosingClass",opclass);		
	}
}

ClientMethod doDetails(option) [ Language = javascript ]
{
	if (this.pageModified) {
        alert($$$Text("Changes have not been saved. Please click an action button on this form before navigating away."));
		return;
	}
	this.resetMsg("");
	this.FirstFailed = '';
	var formId = "";
	var optionId = "";
	var opclass = "";
	for (var i=1; i<=5; i++) {
		formId = "form" + i;
		optionId = "option" + i;
		zen(formId).setHidden((option!=i)?true:false);
		if (option == i) opclass = "optionSelected";
		else opclass="optionUnselected";
		zen(optionId).setProperty("enclosingClass",opclass);		
	}
	setTimeout(function() {zen(formId).undoAutofill();},500);
	switch(option) {
		case '1':
			if (!this.isCAClientDefined) {
				this.showMsg($$$Text("Certificate Authority client not configured."));
				break;
			}
			zen("SubmitFilename").setValue('');
			// make sure the password fields and ServerSubject fields are cleared
			zen("SubmitPassword").setValue('');
			zen("SubmitPassword1").setValue('');
			for (var n=1; n<=6; n++) {
				id = "ClientSubject"+n;
				if (document.getElementById(id)) {
					document.getElementById(id).value = '';
				}
			}
			// load SubjectDN
			zen("htmlSubmitSubjectDN").setProperty("seed","Client");
			zen("SubmitFilename").setProperty("hintClass","helpText");
			zen("SubmitFilename").focus();
			break;

		case '2':
			zen("idProgress2").setHidden(false);
			var html = zen("htmlGetCAList");
			html.seed = "showall";
			html.refreshContents();
			break;
				
		case '3':
			zen("ConfigServer").setProperty("hintClass","helpText");
			zen("ConfigPort").setProperty("hintClass","helpText");
			zen("ConfigPath").setProperty("hintClass","helpText");
			zen("ConfigContactName").setProperty("hintClass","helpText");

			this.isCAClientDefined = this.LoadClientConfigure();
			this.changeContact(zen("ConfigContactName").getValue());
			zen("ConfigServer").focus();
			break;
				
		case '4':
			this.doProcessRefresh();
			break;
				
		case '5':
			this.isCAServerDefined = this.LoadServerConfigure();
			var flag = this.isCAServerDefined;
			zen("ConfigCAFilename").setProperty("disabled",flag);
			zen("ConfigCAPath").setProperty("disabled",flag);
			zen("btnBrowse5").setHidden(flag);
			zen("idConfigDays").setHidden(flag);
			zen("idConfigPassword").setHidden(flag);
			zen("idSubjectDN").setHidden(flag);
			zen("linkReinitialize").setHidden(!flag);
			this.changeSMTP(zen("ConfigSMTPServer").getValue());
			this.doBack();
			if (this.isCAServerDefined == false) {
				// make sure the password fields and ServerSubject fields are cleared
				zen("ConfigPassword").setValue('');
				zen("ConfigPassword1").setValue('');
				for (var n=1; n<=6; n++) {
					id = "ServerSubject"+n;
					if (document.getElementById(id)) {
						document.getElementById(id).value = '';
					}
				}
				// load SubjectDN
				zen("htmlSubjectDN").setProperty("seed","Server");
				zen("ConfigCAFilename").focus();
			} else {
				zen("ConfigDaysIssued").focus();
			}
			break;
		default:
	}
}

/// This method is fired up after onDrawContent is finished. Hide progress message and display error if exists.
ClientMethod drawDone(tab) [ Language = javascript ]
{
	var result = this.GetStatus(tab);
	if (result.Status == "Done") {
		if (result.Error != "") {
			this.showMsg(result.Error,1);
		}
		var id = "idProgress"+tab;
		zen(id).setHidden(true);
	} 
	else {
		var error = $$$Text("Unexpected error occurred. Loading did not finish as expected.");
		this.showMsg(error,1);
	}
}

ClientMethod doGetCertificate(number) [ Language = javascript ]
{
	this.resetMsg('');
	var result = this.GetCertificate(number);
	this.afterSave(result);
}

/// User clicked a Process link on the "Process pending Certificate Singing Requests" table.
ClientMethod doIssue(name) [ Language = javascript ]
{
	this.resetMsg("");
	zen("idProcessPassword").setHidden(false);
	zen("ProcessPassword").setValue('');
}

/// User clicked a Process link on the "Process pending Certificate Singing Requests" table.
ClientMethod doProcess(name) [ Language = javascript ]
{
	this.resetMsg("");
	// show Process pending html
	zen("idProcessPending").setHidden(false);
	// reset password fields
	zen("idProcessPassword").setHidden(true);
	zen("ProcessPassword").setValue('');
	// load process pending table with new name
	var html = zen("htmlProcessPending");
	html.seed = name;
	html.refreshContents();
}

ClientMethod doProcessRefresh() [ Language = javascript ]
{
	// hide the process details html
	zen("idProcessPending").setHidden(true);
	// refresh table
	var table = zen("table");
	table.executeQuery(0);
}

ClientMethod doProcessCancel() [ Language = javascript ]
{
	this.resetMsg("");
	this.doProcessRefresh();
}

/// User clicked a Delete link on the "Process pending Certificate Singing Requests" table.
ClientMethod doProcessDelete(name) [ Language = javascript ]
{
	var msg = $$$Text("Are you sure you want to delete this pending request?");
	if (confirm(msg)==false) return;
	var result = this.DeletePendingProcess(name);
	/// if delete is successful, write out the message and refresh table
	this.resetMsgColor();
	if (result.ok == 1) {
		this.showMsg(result.Message);
		// hide the process details html, in case user viewed it before delete.
		this.doProcessRefresh();
	} else {
		if (result.ErrorMessage != "") this.showMsg(result.ErrorMessage,1);
		if (result.Message != "") this.showMsg(result.Message);			
	}
}

ClientMethod doProcessFinish() [ Language = javascript ]
{
	var name = zen("table").getValue();
	var password = zen("ProcessPassword").getValue();
	if (password == "") {
		this.showMsg($$$Text("Please enter a password and try again."),1);
		zen("ProcessPassword").focus();
		return;	
	} 
	var certType = 1;
	if (document.getElementById("radCertUsage2").checked) certType = 2;
	if (document.getElementById("radCertUsage3").checked) certType = 3;
	var result = this.SignProcess(name,password,certType);
	/// if Finish is successful, write out the message and refresh table
	this.resetMsgColor();
	if (result.ok == 1) {
		this.showMsg(result.Message);
		this.doProcessRefresh();
	} else {
		if (result.ErrorMessage != "") this.showMsg(result.ErrorMessage,1);
		if (result.Message != "") this.showMsg(result.Message);			
	}
}

ClientMethod doReinitialize() [ Language = javascript ]
{
	var msg = $$$Text("WARNING!");
	    msg = msg + "\n\n" + $$$Text("This will delete the Certificate Authority server configuration and all stored Certificates and pending Certificate Signing Requests.");
	    msg = msg + "\n\n"   + $$$Text("Are you sure you want to do this?");
	if (confirm(msg) == false) return;
	var result = this.Reinitialize();
	this.resetMsgColor();
	if (result.ok == 1) {
		zenPage.setModified(false);
		zen("ConfigPassword").setValue('');
		zen("ConfigPassword1").setValue('');
		this.doDetails('5');
		this.showMsg(result.Message);
		// disable Process pending option
		zen("option4").setDisabled(true);
	} else {
		if (result.ErrorMessage != "") this.showMsg(result.ErrorMessage,1);
		if (result.Message != "") this.showMsg(result.Message);			
	}
}

ClientMethod doSave(option) [ Language = javascript ]
{
	this.resetMsg();
	if (!this.validate(option)) {
		return;
	}
	var proxy = new zenProxy();
	switch(option) {
		case '1':
			proxy.Filename = zen("SubmitFilename").getValue();
			proxy.Password = zen("SubmitPassword").getValue();
			for (var n=1; n<=6; n++) {
				id = "ClientSubject"+n;
				if (document.getElementById(id)) {
					value =	document.getElementById(id).value;
					this.setSubjectDN(proxy, n, value);
				}
			}
			var result = this.SubmitCSR(proxy);
			this.afterSave(result);
			break;

		case '2':
			break;
				
		case '3':
			proxy.Server = zen("ConfigServer").getValue();
			proxy.Port = zen("ConfigPort").getValue();
			proxy.Path = zen("ConfigPath").getValue();
			proxy.ContactName = zen("ConfigContactName").getValue();
			proxy.ContactPhone = zen("ConfigContactPhone").getValue();
			proxy.ContactEmail = zen("ConfigContactEmail").getValue();
			proxy.UseTLS = zen("UseTLS").getValue();
			if (proxy.UseTLS) {
				proxy.TLSConfiguration = zen("TLSConfiguration").getValue();
			}
			var defined = (this.isCAClientDefined) ? 1 : 0;
			var result = this.SaveClientConfigure(defined,proxy);
			this.afterSave(result);
			if (result && (result.ok == 1)) {
				this.isCAClientDefined = true;
				zen("option1").setDisabled(false);
				zen("option2").setDisabled(false);
			}
			break;
				
		case '4':
			break;
				
		case '5':
			proxy.CAFilename = zen("ConfigCAFilename").getValue();
			proxy.CAPath = zen("ConfigCAPath").getValue();
			proxy.Days = zen("ConfigDays").getValue();
			proxy.DaysIssued = zen("ConfigDaysIssued").getValue();
			for (var n=1; n<=6; n++) {
				id = "ServerSubject"+n;
				if (document.getElementById(id)) {
					value =	document.getElementById(id).value;
					this.setSubjectDN(proxy, n, value);
				}
			}
			proxy.ConfigPassword = "";
			if (this.isCAServerDefined == false) {
				proxy.ConfigPassword = zen("ConfigPassword").getValue();
			}
			proxy.SMTPServer = zen("ConfigSMTPServer").getValue();
			proxy.SMTPUsername = zen("ConfigSMTPUsername").getValue();
			proxy.SMTPPassword = zen("ConfigSMTPPassword").getValue();
			proxy.AdminEmail = zen("ConfigAdminEmail").getValue();
			var defined = (this.isCAServerDefined) ? 1 : 0;
			var result = this.SaveServerConfigure(defined,proxy);
			this.afterSave(result);
			if (result && (result.ok == 1)) {
				// enable Process pending option
				zen("option4").setDisabled(false);
			}
			break;
		default:
	}
}

/// On the Get Certificate option, show all certificates or show certificate for this instance only.
/// showflag is equal to "showall" or "showinstance". Default is "showall" when the option is opened.
ClientMethod doShowGetList(showflag) [ Language = javascript ]
{
	var html = zen("htmlGetCAList");
	html.seed = showflag;
	html.refreshContents();
}

ClientMethod resetMsgColor() [ Language = javascript ]
{
	zen("idRespond").setProperty("enclosingClass","note");
}

/// Write out result message and refresh option when appopriate.
ClientMethod afterSave(result As %ZEN.proxyObject) [ Language = javascript ]
{
	this.resetMsgColor();
	if (result) {
		if (result.ok == 1) {
			this.doCancel();
			this.showMsg(result.Message);
		} else {
			if (result.ErrorMessage != "") this.showMsg(result.ErrorMessage,1);
			if (result.Message != "") this.showMsg(result.Message);			
		}
	} else {
		this.showMsg($$$Text("Unexpected error while attempting to save"),1);
	}
}

/// Enable/disable Contact Phone and Email depending on whether the Contact Name is null.
ClientMethod changeContact(namevalue) [ Language = javascript ]
{
	zen("ConfigContactPhone").setDisabled(namevalue=="");
	zen("ConfigContactEmail").setDisabled(namevalue=="");
}

/// Enable/disable SMTP related fields depending on whether the SMTP Server is null.
ClientMethod changeSMTP(namevalue) [ Language = javascript ]
{
	zen("ConfigSMTPUsername").setDisabled(namevalue=="");
	zen("ConfigSMTPPassword").setDisabled(namevalue=="");
	zen("ConfigSMTPPassword1").setDisabled(namevalue=="");
	zen("ConfigAdminEmail").setDisabled(namevalue=="");
}

ClientMethod validate(option) [ Language = javascript ]
{
	var proxy = new zenProxy();
	var pass = true;
	switch(option) {
		case '1':
			if (!this.validateRequired(zen("SubmitFilename"),pass,"S")) {
				return false;
			}
			var ConfigPassword = zen("SubmitPassword").getValue();
			var ConfigPassword1 = zen("SubmitPassword1").getValue();
			if (ConfigPassword != ConfigPassword1) {
				this.showMsg($$$Text("The two Passwords for Private Key files are not the same. Please type them again."),1);
				zen("ConfigPassword").focus();
				return false;
			}
			var attrlist = "";
			var id = "ClientSubject1";
			var value;
			if (document.getElementById(id)) {
				if (document.getElementById(id).value != "" && document.getElementById(id).value.length != 2) {
					this.showMsg($$$Text("Country value must be exactly two characters long."),1);
					document.getElementById(id).focus();
					return false;
				}	
			}
			for (var n=1; n<=6; n++) {
				id = "ClientSubject"+n;
				if (document.getElementById(id)) {
					value =	document.getElementById(id).value;
					if (value != "") attrlist = attrlist + n + "#" + value + "^";
					this.setSubjectDN(proxy, n, value);
				}
			}
			if (attrlist == "") {
				this.showMsg($$$Text("'Subject Distinguished Name' is empty. Please enter at least one Attribute Value."),1);
				document.getElementById("ClientSubject1").focus();
				return false;
			}			
			break;

		case '2':
			break;
				
		case '3':
			if (!this.validateRequired(zen("ConfigServer"),pass,"S")) pass = false;
			if (!this.validateRequired(zen("ConfigPort"),pass,"S")) pass = false;
			if (!this.validateRequired(zen("ConfigPath"),pass,"S")) pass = false;
			if (!this.validateRequired(zen("ConfigContactName"),pass,"S")) pass = false;
			if (zen("UseTLS").getValue() && !this.validateRequired(zen("TLSConfiguration"),pass,"S")) pass = false;
			break;
		case '4':
			break;
				
		case '5':
			if (!this.validateRequired(zen("ConfigCAFilename"),pass,"S")) pass = false;
			if (!this.validateRequired(zen("ConfigCAPath"),pass,"S")) pass = false;
			/// if any of the required fields is not filled then prompt those first.
			if (!pass) return pass;
			this.FirstFailed = '';
			var exists = this.Exist(zen("ConfigCAPath").getValue(),zen("ConfigCAFilename").getValue());
			if (this.isCAServerDefined == false) {
				if (exists == false) {
					var ConfigPassword = zen("ConfigPassword").getValue();
					var ConfigPassword1 = zen("ConfigPassword1").getValue();
					if (ConfigPassword == "" && ConfigPassword1 == "") {
						this.showMsg($$$Text("Password is required!"),1);
						zen("ConfigPassword").focus();
						return false;
					}
					if (ConfigPassword != ConfigPassword1) {
						this.showMsg($$$Text("The two passwords for the CA's private key file are not the same. Please type them again."),1);
						zen("ConfigPassword").focus();
						return false;
					}
					var attrlist = "";
					var id = "ServerSubject1";
					var value;
					if (document.getElementById(id)) {
						if (document.getElementById(id).value != "" && document.getElementById(id).value.length != 2) {
							this.showMsg($$$Text("Country value must be exactly two characters long."),1);
							document.getElementById(id).focus();
							return false;
						}	
					}
					for (var n=1; n<=6; n++) {
						id = "ServerSubject"+n;
						if (document.getElementById(id)) {
							value =	document.getElementById(id).value;
							if (value != "") attrlist = attrlist + n + "#" + value + "^";
							this.setSubjectDN(proxy, n, value);
						}
					}
					if (attrlist == "") {
						this.showMsg($$$Text("'Certificate Authority Subject Distinguished Name' is empty. Please enter at least one Attribute Value."),1);
						document.getElementById("ServerSubject1").focus();
						return false;
					}
					if (!this.validateNumeric(zen("ConfigDays"))) {
						this.showMsg($$$Text("Please enter a number for Validity period."),1);
						zen("ConfigDays").focus();
						return false;
					}
				}			
			}
			if (!this.validateNumeric(zen("ConfigDaysIssued"))) {
				this.showMsg($$$Text("Please enter a number for Validity period."),1);
				zen("ConfigDaysIssued").focus();
				return false;
			}
			var ConfigPassword = zen("ConfigSMTPPassword").getValue();
			var ConfigPassword1 = zen("ConfigSMTPPassword1").getValue();
			if (ConfigPassword != ConfigPassword1) {
				this.showMsg($$$Text("The two Passwords for SMTP are not the same. Please type them again."),1);
				zen("ConfigSMTPPassword").focus();
				return false;
			}
			break;
		default:
	}		
	return pass;
}

/// validate the control value. pass is either "true" or "false" indicating if there is already a field failed pass validation.
ClientMethod validateRequired(ctl, pass, type) As %Boolean [ Language = javascript ]
{
	var ok = true;
	var value = ctl.getValue();
	var ctlid = ctl.getProperty("id");
	switch (type) {
		/// contains at least one numeric character
		case "N":
			if (!(value.match(/\d/))) {
				ok = false;
			}
			break;
		case "S":
		/// contains at least one character after striping all blanks
			if (zenTrim(value) == "") {
				ok = false;
			} else {
				if (ctlid == "ConfigCAFilename" || ctlid == "SubmitFilename") {
					var isVal = this.ValidateFile(value);
					if (isVal) {
						if (isVal != 1) {
							this.showMsg(isVal,1);
							ok = false;
						}
					} else {
						this.showMsg($$$Text("Unexpected error while attempting to validate form fields"),1);
						return false;
					}
				}
			}
			break;
	}
	if (ok == false) {
		ctl.setProperty("hintClass","redText");
		ctl.setProperty("controlClass","zenInvalid");
		if (pass) {
			this.FirstFailed = ctlid;
		}
	} else {
		ctl.setProperty("hintClass","helpText");
		ctl.setProperty("controlClass","");
	}
	return ok;
}

/// This method validate the following:
/// 1) value must not be null, AND
/// 2) value must be only numeric
ClientMethod validateNumeric(ctl) As %Boolean [ Language = javascript ]
{
	var value = ctl.getValue();
	if (zenTrim(value) == "") return false;
	if (isNaN(value)) return false;
	return true;
}

/// prepare proxy for transporting SubjectDN's value from page to server.
ClientMethod setSubjectDN(proxy As %ZEN.proxyObject, n, value) [ Language = javascript ]
{
  //C,ST,L,O,OU,CN
	if (n == 1) proxy.C	= value;
	if (n == 2) proxy.ST = value;
	if (n == 3) proxy.L = value;
	if (n == 4) proxy.O = value;
	if (n == 5) proxy.OU = value;
	if (n == 6) proxy.CN = value;
	return proxy
}

ClientMethod showTLS(flag) [ Language = javascript ]
{
	var tls = zen('TLSConfiguration');
	tls.setHidden(flag);
	
	// reset style
	tls.setProperty('hintClass','helpText');
	tls.setProperty('controlClass','');
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set (isCAClientDefined,isCAServerDefined) = 1
	Set client = ##class(PKI.CAClient).%OpenId("IRIS CA")
	If '$ISOBJECT(client) Set isCAClientDefined = 0
	Set server = ##class(PKI.CAServer).%OpenId("IRIS CA")
	If '$ISOBJECT(server) Set isCAServerDefined = 0
	Set %page.isCAClientDefined = isCAClientDefined
	Set %page.isCAServerDefined = isCAServerDefined
	
	If 'isCAClientDefined {
		Set ..%GetComponentById("option1").disabled = 1
		Set ..%GetComponentById("option2").disabled = 1
	}
	If 'isCAServerDefined {
		Set ..%GetComponentById("option4").disabled = 1
	}
	Quit $$$OK
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

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 0
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Public Key Infrastructure")
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			ctrl = zen(popupName);
			ctrl.setValue(value);
			this.doModified();
			ctrl.focus();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Return 1 if both cer and key files exist; 0 otherwise.
ClassMethod Exist(CAPath, CAFilename) As %Boolean [ ZenMethod ]
{
	Set CAPath = ##class(%File).NormalizeDirectory(CAPath)
	Set cafiles = CAPath_CAFilename
	Quit (##class(%File).Exists(cafiles_".cer") && ##class(%File).Exists(cafiles_".key"))
}

/// Load CA Client configure properties into form
ClassMethod LoadClientConfigure() As %Boolean [ ZenMethod ]
{
#dim server as PKI.CAServer
	Set isCAClientDefined = 1
	Set client = ##class(PKI.CAClient).%OpenId("IRIS CA")
	If '$ISOBJECT(client) {
		Set client = ##class(PKI.CAClient).%New()
		Set isCAClientDefined = 0
	}
	Set Server = client.Server
	Set Port = client.Port
	Set Path = client.Path
	Set ContactName = client.ContactName
	Set ContactPhone = client.ContactPhone
	Set ContactEmail = client.ContactEmail
	Set TLSConfiguration = client.TLSConfiguration
	Set UseTLS = client.UseTLS
	
	// build list of available SSL/TLS configurations
	Set TLSConfList = ""
	Set stmt=##class(%SQL.Statement).%New()
	Set sc = stmt.%PrepareClassQuery("Security.SSLConfigs","List")
	Set rs = stmt.%Execute("*")
	While rs.%Next() {
		set TLSConfList = TLSConfList_rs.%Get("Name")_","
	}
	set TLSConfList = $extract(TLSConfList,1,*-1)
	
	&js<zen("ConfigServer").setValue('#($ZCVT(Server,"O","JS"))#');>
	&js<zen("ConfigPort").setValue('#($ZCVT(Port,"O","JS"))#');>
	&js<zen("ConfigPath").setValue('#($ZCVT(Path,"O","JS"))#');>
	&js<zen("ConfigContactName").setValue('#($ZCVT(ContactName,"O","JS"))#');>
	&js<zen("ConfigContactPhone").setValue('#($ZCVT(ContactPhone,"O","JS"))#');>
	&js<zen("ConfigContactEmail").setValue('#($ZCVT(ContactEmail,"O","JS"))#');>
	&js<zen("UseTLS").setValue('#($ZCVT(UseTLS,"O","JS"))#');>
	&js<var tls = zen("TLSConfiguration");
		tls.setProperty('valueList','#($ZCVT(TLSConfList,"O","JS"))#');
		tls.setValue('#($ZCVT(TLSConfiguration,"O","JS"))#');
		zenPage.showTLS(#($select(UseTLS:"false",1:"true"))#);>
	
	
	Quit isCAClientDefined
}

/// Load CA Server configure properties into form
ClassMethod LoadServerConfigure() As %Boolean [ ZenMethod ]
{
#dim server as PKI.CAServer
	Set isCAServerDefined = 1
	Set server = ##class(PKI.CAServer).%OpenId("IRIS CA")
	If '$ISOBJECT(server) {
		Set server = ##class(PKI.CAServer).%New()
		Set isCAServerDefined = 0
	}
	Set CAFilename = server.CAFilename
	Set CAPath = server.CAPath
	Set Days = server.Days * 10
	Set DaysIssued = server.Days
	Set SMTPServer = server.SMTPServer
	Set SMTPUsername = server.SMTPUsername
	Set SMTPPassword = server.SMTPPassword
	Set AdminEmail = server.AdminEmail
	&js<zen("ConfigCAFilename").setValue('#($ZCVT(CAFilename,"O","JS"))#');>
	&js<zen("ConfigCAPath").setValue('#($ZCVT(CAPath,"O","JS"))#');>
	 
	&js<zen("ConfigDays").setValue('#($ZCVT(Days,"O","JS"))#');>
	&js<zen("ConfigDaysIssued").setValue('#($ZCVT(DaysIssued,"O","JS"))#');>

	&js<zen("ConfigSMTPServer").setValue('#($ZCVT(SMTPServer,"O","JS"))#');>
	&js<zen("ConfigSMTPUsername").setValue('#($ZCVT(SMTPUsername,"O","JS"))#');>
	&js<zen("ConfigSMTPPassword").setValue('#($ZCVT(SMTPPassword,"O","JS"))#');>
	&js<zen("ConfigSMTPPassword1").setValue('#($ZCVT(SMTPPassword,"O","JS"))#');>
	&js<zen("ConfigAdminEmail").setValue('#($ZCVT(AdminEmail,"O","JS"))#');>

	Quit isCAServerDefined
}

ClassMethod DeletePendingProcess(pName) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tSC = ##class(PKI.CSR).%DeleteId(pName)
	If $$$ISOK(tSC) Set tProxy.ok = 1,tProxy.Message = $$$FormatText($$$Text("%1 deleted."),pName)
	Else  Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")	
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

ClassMethod GetCertificate(pNumber) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set client = ##class(PKI.CAClient).%OpenId("IRIS CA")
	Set tSC = client.GetCertificate(pNumber)
	#; tSC returned here is a $$$Text message or ##class(%SYSTEM.Status).GetErrorText(st).
	Set tProxy.Message = $ZCVT(tSC,"O","HTML")
	Set tProxy.ok = 1
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// tab = 2: Draw is finished, Status is "Done".
ClassMethod GetStatus(tab) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.Status = $G(^IRIS.Temp.PKI($Username,"Status"))
	Set proxy.Error = $G(^IRIS.Temp.PKI($Username,"Error"))
	Quit proxy
}

/// This method deletes the Certificate Authority server configuration and 
/// all pending Certificate Signing Requests and issued Certificates, allowing user to start over.
ClassMethod Reinitialize() As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Do ##class(PKI.CAServer).%DeleteId("IRIS CA")
	Do ##class(PKI.CSR).%DeleteExtent()
	Do ##class(PKI.Certificate).%DeleteExtent()
	Set tProxy.ok = 1
	Set tProxy.Message = $$$Text("Reinitialization complete.")
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

ClassMethod SaveClientConfigure(pIsCAClientDefined, pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#dim server as PKI.CAServer
	Set $ZT="Error"	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	If pIsCAClientDefined {
		Set client = ##class(PKI.CAClient).%OpenId("IRIS CA")
	} Else {
		Set client = ##class(PKI.CAClient).%New()
	}
	Set client.Server = pProxy.Server
	Set client.Port = pProxy.Port
	Set client.Path = pProxy.Path
	Set client.ContactName = pProxy.ContactName
	Set client.ContactPhone = pProxy.ContactPhone
	Set client.ContactEmail = pProxy.ContactEmail
	Set client.UseTLS = pProxy.UseTLS
	If client.UseTLS {
		Set client.TLSConfiguration = pProxy.TLSConfiguration
	} else {
		Set client.TLSConfiguration = ""
	}
	Set tSC = ##class(PKI.CAClient).Configure(client,.st)
	#; tSC returned here is a $$$Text message or ##class(%SYSTEM.Status).GetErrorText(st).
	If $$$ISOK(st) {
		Set tProxy.Message = $ZCVT(tSC,"O","HTML")
		Set tProxy.ok = 1
	} Else {
		Set tProxy.ErrorMessage = ##class(%SYSTEM.Status).GetErrorText(st)
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

ClassMethod SaveServerConfigure(pIsCAServerDefined, pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#dim server as PKI.CAServer
	Set $ZT="Error"	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set password = ""
	Set attrlist = ""
	If pIsCAServerDefined {
		Set server = ##class(PKI.CAServer).%OpenId("IRIS CA")
	} Else {
		Set server = ##class(PKI.CAServer).%New()
		Set server.CAFilename = pProxy.CAFilename
		Set server.CAPath = pProxy.CAPath
		Set password = pProxy.ConfigPassword
		//C,ST,L,O,OU,CN
		If pProxy.C '= "" Set $LIST(attrlist,1) = pProxy.C
		If pProxy.ST '= "" Set $LIST(attrlist,2) = pProxy.ST
		If pProxy.L '= "" Set $LIST(attrlist,3) = pProxy.L
		If pProxy.O '= "" Set $LIST(attrlist,4) = pProxy.O
		If pProxy.OU '= "" Set $LIST(attrlist,5) = pProxy.OU
		If pProxy.CN '= "" Set $LIST(attrlist,6) = pProxy.CN
	}
	Set server.Days = pProxy.DaysIssued
	Set server.SMTPServer = pProxy.SMTPServer
	Set server.SMTPUsername = pProxy.SMTPUsername
	Set server.SMTPPassword = pProxy.SMTPPassword
	Set server.AdminEmail = pProxy.AdminEmail
	Set tSC = ##class(PKI.CAServer).Configure(server,attrlist,password,pProxy.Days,.st)
	#; tSC returned here is a $$$Text message or ##class(%SYSTEM.Status).GetErrorText(st).
	If $$$ISOK(st) {
		Set tProxy.Message = $ZCVT(tSC,"O","HTML")
		Set tProxy.ok = 1
	} Else {
		Set tProxy.ErrorMessage = $ZCVT(##class(%SYSTEM.Status).GetErrorText(st),"O","HTML")
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

ClassMethod SignProcess(pName, pPassword, pCertType) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
 	Set server = ##class(PKI.CAServer).%OpenId("IRIS CA")
 	If '$ISOBJECT(server) {
	 	Set tProxy.ErrorMessage = $$$Text("Certificate Authority server not configured.")
	 	Quit tProxy
	}
 	Set tSC = server.Sign(pName,pPassword,pCertType,.st)
	#; tSC returned here is a $$$Text message or ##class(%SYSTEM.Status).GetErrorText(st).
	If $$$ISOK(st) {
		Set tProxy.ok = 1
		Set tProxy.Message = $ZCVT(tSC,"O","HTML")
	} Else {
		Set tProxy.ErrorMessage = $ZCVT(##class(%SYSTEM.Status).GetErrorText(st),"O","HTML")
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

ClassMethod SubmitCSR(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#dim server as PKI.CAServer
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set password = pProxy.Password
	//C,ST,L,O,OU,CN
	If pProxy.C '= "" Set $LIST(attrlist,1) = pProxy.C
	If pProxy.ST '= "" Set $LIST(attrlist,2) = pProxy.ST
	If pProxy.L '= "" Set $LIST(attrlist,3) = pProxy.L
	If pProxy.O '= "" Set $LIST(attrlist,4) = pProxy.O
	If pProxy.OU '= "" Set $LIST(attrlist,5) = pProxy.OU
	If pProxy.CN '= "" Set $LIST(attrlist,6) = pProxy.CN
	Set client = ##class(PKI.CAClient).%OpenId("IRIS CA")
	Set tSC = client.SubmitCSR(pProxy.Filename,attrlist,password,.st)
	#; tSC returned here is a $$$Text message or ##class(%SYSTEM.Status).GetErrorText(st).
	If $$$ISOK(st) {
		Set tProxy.Message = $ZCVT(tSC,"O","HTML")
		Set tProxy.ok = 1
	} ElseIf ($ZE["<ZSOAP>") && $ISOBJECT(st) {
		Set tProxy.ErrorMessage = $ZCVT(st.faultstring,"O","HTML")
	} Else {
		Set tProxy.ErrorMessage = $ZCVT(##class(%SYSTEM.Status).GetErrorText(st),"O","HTML")
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// Draw Subject Disignated Name for "Server" and "Client" (passed in as pConfigType)
ClassMethod DrawSubjectDN(pConfigType As %String) As %Status
{
	Quit:pConfigType="" $$$OK
	If pConfigType = "Server" Set thisObj = ##class(PKI.CAServer).%New()
	Else  Set thisObj = ##class(PKI.CAClient).%New()
	Set tAttributePrompt = thisObj.AttributePrompt
	&html<<table class="DetailTable" cellspacing="2" cellpadding="2">
	<tr>
	<th>#($$$TextHTML("Attribute Type"))#</th>
	<th>#($$$TextHTML("Attribute Value"))#</th>
	</tr>>
	Set LBLMSG("Country") = $$$TextHTML("Country")
	Set LBLMSG("State or Province") = $$$TextHTML("State or Province")
	Set LBLMSG("Locality") = $$$TextHTML("Locality")
	Set LBLMSG("Organization") = $$$TextHTML("Organization")
	Set LBLMSG("Organizational Unit") = $$$TextHTML("Organizational Unit")
	Set LBLMSG("Common Name") = $$$TextHTML("Common Name")
	Set tRow = 1
	Set tType = $P(tAttributePrompt,",",tRow)
	While tType '= "" {
		Set tId = pConfigType_"Subject"_tRow
		Set tSize = "40",tHelp = ""
		If tType= "Country" Set tSize = 2,tHelp = $$$TextHTML("(Enter the two character country code only)")
		Set tCaption = $S($G(LBLMSG(tType)):LBLMSG(tType),1:$ZCVT(tType,"O","HTML"))
		&html<<tr><td>#(tCaption)#</td><td><input type="text" id="#(tId)#" size="#(tSize)#">&nbsp;#(tHelp)#</td></tr>>
		Set tRow = tRow + 1
		Set tType = $P(tAttributePrompt,",",tRow)
	}
	Set msg = $$$TextHTML("* Please enter at least one Attribute Value")
	&html<<tr><td colspan="2">#(msg)#</td></tr>>
	&html<</table>>

	Quit $$$OK
}

/// Draw html code for Get Certificate(s) from Certificate Authority server
/// The pType determines if we are going to (showall) List all issued certificates, or (showinstance) List certificates issued for this instance
ClassMethod DrawGetCAList(pType As %String) As %Status
{
	Set tSC = $$$OK
	Quit:pType="" tSC
	Set ^IRIS.Temp.PKI($Username,"Status") = ""
	Set ^IRIS.Temp.PKI($Username,"Error") = ""
	Set client = ##class(PKI.CAClient).%OpenId("IRIS CA")
	If '$ISOBJECT(client) {
		Do ..DrawGetCAListError($$$Text("Certificate Authority client not configured."))
		Quit tSC
	}
	Set btnGet = $$$Text("Get")
	Set tGetTooltip = $$$TextJS("click to get certificates for this serial number")
	If pType = "showinstance" {
		Set hostname = ##class(%SYS.System).GetNodeName()
		Set instance = ##class(%SYS.System).GetInstanceName()
		Set tRS = client.ListCertificates(hostname, instance)		
		If '$$$ISOK(tRS) {
			Do ..DrawGetCAListError($SYSTEM.Status.GetErrorText(%objlasterror))
			Quit tSC
		}
		Set HasCer = 1
		If 'tRS.Next() {
			Write "<h4>",$$$TextHTML("No Certificates issued for this instance"),"</h4>"
			Set ^IRIS.Temp.PKI($Username,"Status") = "Done"
			Set HasCer = 0
		}
		Set btnShow = $$$Text("show all certificates")
		Set tTooltip = $$$Text("click to show all certificates")
		&html<<div align="right"><input type="button" value="#(btnShow)#" title="#(tTooltip)#" onclick="zenPage.doShowGetList('showall');"></div>>
		If HasCer = 0 Quit tSC
		Write "<h4>",$$$FormatText($$$Text("Certificates issued for instance %1 on node %2:"), $zconvert(instance,"O","HTML"),$zconvert(hostname,"O","HTML")),"</h4>"
		#; Serial number, Hostname, Instance, and Filename
		#; Hostname and Instance are shown for "showinstance" only
		&html<<table border="0">>
		&html<<tr style="font-size:12px;">
		<th>#($$$TextHTML("Serial Number"))#</th>
		<th>#($$$TextHTML("Filename"))#</th>
		<th></th>
		</tr>>
		Do {
			&html<<tr style="background:#FFFFFF;font-size:12px;">>
			&html<<td style="padding:3px;" align="right">#($ZCVT(tRS.GetData(1),"O","HTML"))#</td>>
			&html<<td style="padding:3px;">#($ZCVT(tRS.GetData(2),"O","HTML"))#</td>>
			&html<<td><input type="button" value="#(btnGet)#" title="#(tGetTooltip)#" onclick="zenPage.doGetCertificate('#(tRS.GetData(1))#');"></td></tr>>
		} While tRS.Next()
	} Else {
		Set tRS = client.ListCertificates()
		If '$$$ISOK(tRS) {
			Do ..DrawGetCAListError($SYSTEM.Status.GetErrorText(%objlasterror))
			Quit tSC
		}
		If 'tRS.Next() {
			Write "<h4>",$$$TextHTML("No Issued Certificates"),"</h4>"
			Set ^IRIS.Temp.PKI($Username,"Status") = "Done"
			Quit tSC
		}
		Set btnShow = $$$Text("show certificates for this instance")
		Set tTooltip = $$$Text("click to show certificates for this instnace only")
		&html<<div align="right"><input type="button" value="#(btnShow)#" title="#(tTooltip)#" onclick="zenPage.doShowGetList('showinstance');"></div>>
		Write "<h4>",$$$TextHTML("Issued Certificates"),"</h4>"
		&html<<table border="0">>
		&html<<tr style="font-size:12px;">
		<th>#($$$TextHTML("Serial Number"))#</td>
		<th>#($$$TextHTML("Hostname"))#</th>
		<th>#($$$TextHTML("Instance"))#</th>
		<th>#($$$TextHTML("Filename"))#</th>
		<th></th>
		</tr>>
		Do {
			&html<<tr style="background:#FFFFFF;font-size:12px;">>
			&html<<td style="padding:2px;" align="right">#($ZCVT(tRS.GetData(1),"O","HTML"))#</td>>
			For n = 2:1:4 &html<<td style="padding:2px;">#($ZCVT(tRS.GetData(n),"O","HTML"))#</td>>
			&html<<td><input type="button" value="#(btnGet)#" title="#(tGetTooltip)#" onclick="zenPage.doGetCertificate('#(tRS.GetData(1))#');"></td></tr>>
		} While tRS.Next()
	}

	&html<</table>>

	Set ^IRIS.Temp.PKI($Username,"Status") = "Done"
	Quit $$$OK
}

ClassMethod DrawGetCAListError(ErrorMsg)
{
	&html<<div class="ErrorBox">#($ZCVT(ErrorMsg,"O","HTML"))#</div>>
	Set ^IRIS.Temp.PKI($Username,"Status") = "Done"
	Quit
}

/// Draw html code for Pending Certificate Signing Request
ClassMethod DrawProcessPending(pName As %String) As %Status
{
	Set tSC = $$$OK
	Quit:pName="" tSC
	Set csr = ##class(PKI.CSR).%OpenId(pName)
	If '$ISOBJECT(csr) {
		&html<<div class="ErrorBox">#($$$FormatText($$$Text("Cannot open class for %1."),$zconvert(pName,"O","HTML")))#</div>>
		Quit tSC
	}
	Set tHostname = csr.Hostname 				//"SHAMBROOM6520.ISCINTERNAL.COM"
	Set tInstnace = csr.Instance 				//"CACHE122"
	Set tFilename = csr.Filename  				//"wds1"
	Set tSubjectDN = csr.GetSubject()  			//"/C=US/ST=MA"
	Set tFingerprint = csr.GetSHA256Fingerprint()	//"DA:39:A3:EE:5E:6B:4B:0D:32:55:BF:EF:95:60:18:90:AF:D8:07:09"
	Set tContactName = csr.ContactName  		//"David S"
	Set tContactPhone = csr.ContactPhone  		//"61739809878"
	Set btnIssue = $$$Text("Issue Certificate")
	Set btnCancel = $$$Text("Cancel")

	&html<<table class="PendTable" cellspacing="2" cellpadding="2">>
	&html<<tr class="DarkRow"><td class="Header" valign="top">#($$$TextHTML("Request Source"))#</td>>
	&html<<td><table><tr><td class="Data">#($$$TextHTML("Hostname:"))#</td><td class="Data">#($ZCVT(tHostname,"O","HTML"))#</td></tr>
	<tr><td class="Data">#($$$TextHTML("Instance:"))#</td><td class="Data">#($ZCVT(tInstnace,"O","HTML"))#</td></tr>
	<tr><td class="Data">#($$$TextHTML("Filename:"))#</td><td class="Data">#($ZCVT(tFilename,"O","HTML"))#</td></tr>
	</table>>
	
	&html<</tr><tr class="LiteRow"><td class="Header" valign="top">#($$$TextHTML("Request Content"))#</td>>
	&html<<td><table><tr><td class="Data">#($$$TextHTML("Subject Distinguished Name:"))#>
	For n = 1:1:$L(tSubjectDN,"/") Set tDN = $P(tSubjectDN,"/",n) If tDN '= "" &html<<br>&nbsp;&nbsp;&nbsp;&nbsp;#($ZCVT(tDN,"O","HTML"))#>
	&html<</td></tr>
	<tr><td class="Data">#($$$TextHTML("SHA-256 Fingerprint:"))#<br>&nbsp;&nbsp;&nbsp;&nbsp;#($ZCVT(tFingerprint,"O","HTML"))#</td></tr>
	</table>>
	
	&html<</tr><tr class="DarkRow"><td class="Header" valign="top">#($$$TextHTML("Technical Contact"))#</td>>
	&html<<td><table><tr><td class="Data">#($$$TextHTML("Name:"))#</td><td class="Data">#($ZCVT(tContactName,"O","HTML"))#</td></tr>
	<tr><td class="Data">#($$$TextHTML("Phone number:"))#</td><td class="Data">#($ZCVT(tContactPhone,"O","HTML"))#</td></tr>
	</table>>
	
	&html<</tr><tr class="LiteRow"><td class="Header" valign="top">#($$$TextHTML("Certificate Usage"))#</td>>
	&html<<td class="Data"><input type="radio" name="radCertUsage" id="radCertUsage1" value="1" checked>#($$$TextHTML("TLS/SSL and XML security"))#<br/>
	<input type="radio" name="radCertUsage" id="radCertUsage2" value="2">#($$$TextHTML("Intermediate Certificate Authority"))#<br/>
	<input type="radio" name="radCertUsage" id="radCertUsage3" value="3">#($$$TextHTML("Code signing"))#
	</td></tr>
	</table>>
	
	&html<</td></tr><tr><td colspan="10">
	<h3>#($$$TextHTML("WARNING!"))#</h3>
	<div class="caption">#($$$TextHTML("Before issuing a Certificate you must speak with the Technical Contact listed above, and verify:"))#</div>
	<ol>
	<li class="normal">#($$$TextHTML("Their identity."))#</li>
	<li class="normal">#($$$TextHTML("Their authority to hold a certificate containing the Subject Distinguished Name shown above, signed by this Certificate Authority."))#</li>
	<li class="normal">#($$$TextHTML("That the SHA-256 Fingerprint shown above matches the one reported to them when they submitted the Certificate Signing Request."))#</li>
	</ol>
	<div>
	<input type="button" id="btnIssue" class="commandButton" value="#(btnIssue)#" onclick="zenPage.doIssue();"/>
	<input type="button" id="btnIssueCancel" class="commandButton" value="#(btnCancel)#" onclick="zenPage.doProcessCancel();"/>
	</div>
	>
	&html<</td></tr></table>>

	Quit $$$OK
}

/// Advanced security is always enabled now so the redirection when disabled is no longer necessary.
/// I don't know whether the do nothing %OnPreHTTP method is still needed.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit 1
}

/// validate file name root.
ClassMethod ValidateFile(pValue As %String) As %String [ ZenMethod ]
{
	If '(pValue?.(1AN,1"_",1"-")) Quit $$$Text("Illegal characters in file name root.","%Utility")
	If ($ZCONVERT(pValue,"L")="iris") Quit $$$FormatText($$$Text("%1 is a reserved file name root.","%Utility"),pValue)
	Quit 1
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
