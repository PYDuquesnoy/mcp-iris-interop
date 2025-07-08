/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Contact page for customer to report a new WRC issue<br>
Class %CSP.UI.Portal.Contact Extends %ZEN.Portal.standardPage [ System = 4 ]
{

/// Do not include "zenMenusSMP.js" from %ZEN.Portal.standardPage
Parameter JSINCLUDES;

/// Displayed name of this page.
Parameter PAGENAME = "Contact WRC";

Property buttonsPage As %String [ InitialExpression = {..Link("op/UtilSysButtons.csp",,1)} ];

Property WRCNumber As %ZEN.Datatype.string(ZENURL = "WRCNumber");

Property contactPage As %ZEN.Datatype.string [ InitialExpression = {$$$TextHTML("Contact WRC")} ];

XData Style
{
<style type="text/css">
a:link {
	color: #333695; /* ISC blue */
}
.mt-10 {
	margin-top: 10px;
}
.mt-20 {
	margin-top: 20px;
}
.mr-6 {
	margin-right:6px;	
}
.subheader {
	color: #000000;
	display: inline-block;
	font-size: 16px;
    max-width: 100%;
    margin-bottom: 5px;
    font-weight: 700;
}
.portalLogoBox {
	padding: 18px 40px;	
}
.wrcLogo {
	width:	210px;
	height: 50px;
	background-image: url("csp_broker/portal/WRCLogo210x50.png");
	background-repeat: no-repeat;
}
.portalTitleText {
	clear: left;
	padding: 20px 20px;
}
.header {
	font-size: 18px;
	line-height: 24px;
	padding-bottom: 4px;
}
body {
 	font-family: Futura,Arial,sans-serif;
 	font-size: 14px;
}
.portalTitle {
	border: 2px solid white;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);	
}
.phoneBox {
	font-size:12px;
	padding:20px;
}
.bodyBox {
	border-top: 1px solid #CBCBCB;
	margin: 4px 20px;	
}
.formBox {
	border: 1px solid #CBCBCB;
	border-radius: 4px;
	padding: 10px 30px;
}
input[type=text],input[type=email] {
	border: 1px solid #979797;
	border-radius: 4px;
	height: 25px;	
}
input[type=radio], input[type=checkbox] {
	display:none;
}
input[type=radio] + label, input[type=checkbox] + label {
    width:80px;
	display:inline-block;
	margin:-2px;
	padding: 4px 20px;
	margin-bottom: 0;
	font-size: 14px;
	line-height: 20px;
	color: #333695;
	text-align: center;
	text-shadow: 0 1px 1px rgba(255,255,255,0.75);
	vertical-align: middle;
	cursor: pointer;
	background: #FFFFFF;
	border: 1px solid #333695;
	border-radius: 1px;
}
input[type=radio]:checked + label, input[type=checkbox]:checked + label{
	background-image: none;
	outline: 1;
	outline-style: solid;
	outline-color: #000000;
	outline-width: 3px;
	-webkit-box-shadow: inset 0 2px 4px rgba(0,0,0,0.15),0 1px 2px rgba(0,0,0,0.05);
	-moz-box-shadow: inset 0 2px 4px rgba(0,0,0,0.15),0 1px 2px rgba(0,0,0,0.05);
	box-shadow: inset 0 2px 4px rgba(0,0,0,0.15),0 1px 2px rgba(0,0,0,0.05);
	background:#FFFFFF;
	border: 1px solid #00AFA9;
	color: #00AFA9;
	border-radius: 1px;
}
.row {
	line-height: 24px;
    padding: 5px;
}
.col-sm-8 {
	position: absolute;
	left: 200px;
}
.btn {
  display: inline-block;
  padding: 6px 12px;
  margin-bottom: 0;
  font-size: 14px;
  font-weight: 400;
  line-height: 1.42857143;
  text-align: center;
  white-space: nowrap;
  vertical-align: middle;
  -ms-touch-action: manipulation;
  touch-action: manipulation;
  cursor: pointer;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  background-image: none;
  border: 1px solid transparent;
  border-radius: 4px;
}
.btn-primary {
  color: #FFFFFF;
  background: #333695;
  border: 2px solid #333695;
  border-radius: 4px;
  font-size: 12px;
  letter-spacing: 0.75px;
}
.btn-primary:hover {
  color: #FFFFFF;
  background-color: #00A09A;
  border-color: #00A09A;
}
.btn-default {
  color: #333695;
  background: #FFFFFF;
  border: 1px solid #333695;
  border-radius: 4px;
}
.btn-default:hover, input[type=radio] + label:hover, input[type=checkbox] + label:hover {
  color: #00A09A;
  border-color: #00A09A;
}
.btn-default.active {
   background-color: #64B5AA;
}
.topLine {
	border-top: 4px solid #333695;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" layout="none" title="#(%page.contactPage)#">
<jsonProvider id="jsonSystemInfo" OnGetTargetObject="GetSystemProperties">
 </jsonProvider>

<html>
<head>
<title>
Send issue to WRC
</title>
</head>

<body>
<div class="container topLine">
<div class="portalTitle">
	<div class="portalLogoBox">
	<div class="wrcLogo"></div>
	</div>
	</div>
</div>
<table>
<tr><td class="portalTitleText ribbonTitle" id="headerTitle">
	Request to Open a New WRC Issue
</td><td class="phoneBox">
<div id="directContact">You may contact InterSystems Worldwide Response Center directly at:</div>
<ul>
<li>+1-617-621-0700</li>
<li>+44 (0) 844 854 2917</li>
<li>support@intersystems.com</li>
</ul>
</td></tr>
</table>
<div class="bodyBox">
<h1 class="header" id="msgHeader">Please let us know how we can help you:</h1>
<div class="formBox">
<p><a href="#" onclick="zenPage.gotoButtons();"><span id="accessButtons">Click here to run a diagnostic report and send to WRC.</span></a></p>
<form id="contactForm" name="contactForm">
<div class="mt-10 subheader" id="contactTitle">
How should WRC contact you?
</div>
<div class="contactGroup">
<div class="row">
<label id="lblContactName" for="ContactName">Contact name</label>
<input class="col-sm-8" type="text" id="ContactName" size="40"></input>
</div>
<div class="row">
<label id="lblEmail" for="Email">Email address</label>
<input class="col-sm-8" type="text" id="Email" size="40"></input>
</div>
<div class="row">
<label id="lblPhone" for="Phone">Phone</label>
<input class="col-sm-8" type="text" id="Phone" size="40"></input>
</div>
</div> <!-- end of contact group -->

<div class="mt-10 subheader" id="lblDescription">Description</div>
<div>
<textarea id="Description" name="Description" rows="10" cols="100">Please describe your issue.</textarea>
</div>

<div id="lblWRCNumber" class="mt-10 subheader">WRC issue number (if known)</div>
<div>
<input id="WRCNumber" type="text"/>
</div>

<div class="mt-10 subheader" id="lblPriority">Select the Priority</div>

<table cellpadding="4" cellspacing="4">
<tr><td>
<input type="radio" id="radioPriority1" checked="" name="Priority" value="Medium" onclick="zenPage.priorityChanged(this.value);"></input>
<label for="radioPriority1"><div id="lblPriority1">Medium</div></label>
</td><td>
<input type="radio" id="radioPriority2" name="Priority" value="High" onclick="zenPage.priorityChanged(this.value);"></input>
<label for="radioPriority2" ><div id="lblPriority2">High</div></label>
</td><td>
<input type="radio" id="radioPriority3" name="Priority" value="Crisis" onclick="zenPage.priorityChanged(this.value);"></input>
<label for="radioPriority3" ><div id="lblPriority3">Crisis</div></label>
</td></tr>
</table>

<div class="mt-20">
<button type="button" class="btn btn-primary mr-6" id="button-send" onclick="zenPage.sendEmail();">Send Email to WRC</button>
<button type="button" class="btn btn-default" id="button-cancel" onclick="history.back();">Close</button>
</div>
<div class="mt-10" id="msgButtonsHint"></div>
</form>
</div>
</div>
</body>
</html>
</page>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.loadLocalizedStrings();
	var json = zen('jsonSystemInfo').getContentObject();
	this._systemInfo = json;
	this._priority = "Medium";
	document.getElementById('ContactName').value = json.Username;
	document.getElementById('WRCNumber').value = encodeURIComponent(this.WRCNumber);
}

ClientMethod priorityChanged(value) [ Language = javascript ]
{
	this._priority = value;
}

ClientMethod gotoButtons() [ Language = javascript ]
{
	document.location = this.buttonsPage;
}

ClientMethod loadLocalizedStrings() [ Language = javascript ]
{
	document.getElementById("accessButtons").innerHTML = zenText("accessButtons");
	document.getElementById("button-send").innerHTML = zenText("button-send");
	document.getElementById("button-cancel").innerHTML = zenText("button-cancel");
	document.getElementById("contactTitle").innerHTML = zenText("contactTitle");
	document.getElementById("headerTitle").innerHTML = zenText("headerTitle");
	document.getElementById("lblContactName").innerHTML = zenText("lblContactName");
	document.getElementById("lblDescription").innerHTML = zenText("lblDescription");
	document.getElementById("lblEmail").innerHTML = zenText("lblEmail");
	document.getElementById("Description").innerHTML = zenText("Description");
	document.getElementById("lblPhone").innerHTML = zenText("lblPhone");
	document.getElementById("lblPriority").innerHTML = zenText("lblPriority");
	document.getElementById("lblWRCNumber").innerHTML = zenText("lblWRCNumber");
	document.getElementById("msgButtonsHint").innerHTML = zenText("msgButtonsHint");
	document.getElementById("msgHeader").innerHTML = zenText("msgHeader");
	document.getElementById("directContact").innerHTML = zenText("msgLink");
	document.getElementById("radioPriority1").innerHTML = zenText("radioPriority1");
	document.getElementById("radioPriority2").innerHTML = zenText("radioPriority2");
	document.getElementById("radioPriority3").innerHTML = zenText("radioPriority3");
}

ClientMethod sendEmail() [ Language = javascript ]
{
	/// prepare for the unexpected
	var json = (this._systemInfo) ? this._systemInfo : zen('jsonSystemInfo').getContentObject();
	if (!json) {
		alert($$$Text("Cannot find jsonSystemInfo. Please call InterSystems WRC to report this problem."));
		return false;	
	}
	var description = document.getElementById("Description").value;
	if (description.length < 1) {
		alert($$$Text("Please enter a description of the issue you wish to report."));
		return false;
	}
	var minib = json.minib;
	var m_email = json.mailto;
	var m_body = "[description] %0D";
	var contact = "[contact_info] %0D" + document.getElementById("ContactName").value;
	var email = document.getElementById("Email").value;
	var phone = document.getElementById("Phone").value;
	if (email.length > 0) {
		contact += "%0D" + email;
	}
	if (phone.length > 0) {
		contact += "%0D" + phone;
	}
	m_body += "%0D" + description.replace(/\n/g,"%0D");
	m_body += "%0D%0D";
	m_body += "[wrc_number] %0D" + document.getElementById("WRCNumber").value;;
	m_body += "%0D%0D";
	m_body += contact + "%0D%0D";
	m_body += minib;
	m_body += "[priority] " + this._priority + "%0D";
	var m_subject = "Create New WRC";
	var mailto_link = 'mailto:' + m_email + '?subject=' + m_subject + '&body=' + m_body;
	var emailWindow = window.open(mailto_link);
	setTimeout(function() { emailWindow.close() }, 60);
	setTimeout(function() { history.back() }, 60);
	;
	return true;
}

Method GetSystemProperties(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.API).GetInfoForContactWRC(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
		
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
	Set pResources("accessButtons") = $$$TextHTML("Click here to run a diagnostic report and send to WRC.")
	Set pResources("button-send") = $$$TextHTML("Send Email to WRC")
	Set pResources("button-cancel") = $$$TextHTML("Close")
	Set pResources("contactTitle") = $$$TextHTML("How should WRC contact you?")
	Set pResources("headerTitle") = $$$TextHTML("Request to Open a New WRC Issue")
	Set pResources("Description") = $$$TextHTML("Please describe your issue")
	Set pResources("lblContactName") = $$$TextHTML("Contact name")
	Set pResources("lblDescription") = $$$TextHTML("Description")
	Set pResources("lblEmail") = $$$TextHTML("Email address")
	Set pResources("lblPhone") = $$$TextHTML("Phone")
	Set pResources("lblPriority") = $$$TextHTML("Select the Priority")
	Set pResources("lblWRCNumber") = $$$TextHTML("WRC issue number (if known)")
	Set pResources("radioPriority1") = $$$TextHTML("Medium")
	Set pResources("radioPriority2") = $$$TextHTML("High")
	Set pResources("radioPriority3") = $$$TextHTML("Crisis")
	Set pResources("msgButtonsHint") = $$$TextHTML("(Basic system information will be included. You will be able to attach files to your email before sending)")
	Set pResources("msgHeader") = $$$TextHTML("Please let us know how we can help you")
	Set msgWRC = "<a href='http://www.intersystems.com/services-support/worldwide-response-center/'>"_$$$TextHTML("Worldwide Response Center")_"</a>"
	Set pResources("msgLink") = $$$FormatText($$$Text("You may contact InterSystems %1 directly at:"),msgWRC)
	Quit $$$OK
}

}
