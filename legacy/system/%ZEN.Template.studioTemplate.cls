/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for Zen-based Studio Templates.<br>
/// Zen-based Studio Templates extend this class.
Class %ZEN.Template.studioTemplate Extends %ZEN.Component.page [ Abstract, Deprecated, System = 4 ]
{

/// Users must have %Development:USE to access any Studio templates.
Parameter RESOURCE = "%Development:USE";

/// Do not use AutoLogout logic for template pages.
Parameter AUTOLOGOUT = 0;

/// Prevent IE issues with non-UTF8 char-sets.
Parameter CHARSET = "UTF-8";

Parameter VALIDATEXML = 0;

/// This projection is used to keep track of when this page is
/// compiled or uncompiled. In this case, this notifies the
/// Studio Template Manager about the existence of this template.
Projection Template As %ZEN.Template.TemplateProjection;

/// Name of the template to show in Studio.<br>
/// If <parameter>DOMAIN</parameter> is defined this will be localized.
Parameter TEMPLATENAME As STRING;

/// If auto-switch namespace to whatever $NAMESPACE is passed in
Parameter AUTONS = 1;

/// Title of the template to show in the template window.
Parameter TEMPLATETITLE As STRING;

/// Short description of the template to show in Studio.<br>
/// If <parameter>DOMAIN</parameter> is defined this will be localized.
Parameter TEMPLATEDESCRIPTION As STRING;

/// Comma separated list of 'CSP', 'CSR', 'MAC', 'INT', 'INC', 
/// 'BAS', 'CLS' to say what type of code this template 
/// generates; CSP, CSR, Routine, or Class code. 
/// You can also specify '*' for all types.
Parameter TEMPLATETYPE As STRING = "*";

/// Accelerator key for this template in Studio, 0-9.<br>
/// User will press Ctrl+Shift+key to activate.
Parameter TEMPLATEACCELERATOR As STRING [ Constraint = ",0,1,2,3,4,5,6,7,8,9", Flags = ENUM ];

/// Set this true (1) if this template does not generate any 
/// output, only applies to 'template' types but it prevents 
/// Studio from needing to make the current file writable.
Parameter TEMPLATENOOUTPUT As BOOLEAN = 0;

/// DOCBOOK Topic Id that offers help for this template.
Parameter HELPID As STRING;

/// Specifies what type of template this is: 'template', 'new', or 'addin'.
/// 'template' is the default and this 
/// creates code that is inserted into the current document,
/// 'new' is a template that appears on the dialog when you 
/// click the new button, 'addin' is a template that appears 
/// on the addin menu which does not generate any output.
Parameter TEMPLATEMODE As STRING [ Constraint = ",template,new,addin", Flags = ENUM ] = "template";

/// If this is a TEMPLATEMODE="new" then this is the name of the tab
/// in Studio this template is dispayed on. If none specified then
/// it displays on 'Custom' tab.
Parameter TEMPLATEGROUP As STRING;

/// If this is true then even if this template is tied to a specific namespace it
/// will be available in any namespace and it will be up to the template to make sure
/// it looks for any specific data in the target namespace.
Parameter GLOBALTEMPLATE As BOOLEAN = 1;

/// Internal value used for communication back to Studio.
Parameter DELIM [ Final, Internal ] = "##www.intersystems.com:template_delimiter##";

/// Current project within Studio.
Property Project As %ZEN.Datatype.string(ZENURL = "Project");

/// Name of current document within Studio.
Property DocumentName As %ZEN.Datatype.string(ZENURL = "Name");

/// Current selected text within Studio.
Property SelectedText As %ZEN.Datatype.string(ZENURL = "SelectedText");

/// Current namespace within Studio.
Property Namespace As %ZEN.Datatype.string(ZENURL = "Namespace");

/// Current user within Studio.
Property User As %ZEN.Datatype.string(ZENURL = "User");

/// Current language within Studio (e.g., "cache").
Property Language As %ZEN.Datatype.string(ZENURL = "Language");

/// Namespace of current document within Studio.
Property DocumentNamespace As %ZEN.Datatype.string(ZENURL = "DocumentNamespace");

/// DocBook topic id used to show help for this template.
Property helpId As %ZEN.Datatype.string [ InitialExpression = {..#HELPID} ];

XData CSS3Style
{
<style type="text/css">
body {
	background: #E0E0E0;
	font-family: arial, sans-serif;
	padding: 0px;
	margin: 0px;
}

.zenLabel {
	color: #404040;
	padding-left: 4px;
	font-size: 0.8em;
	vertical-align: middle;
}

.zenRequired {
	color: darkblue;
	padding-left: 4px;
	font-size: 0.8em;
	vertical-align: middle;
}

.hintText {
	font-size: 0.8em;
	vertical-align: middle;
	color: #808080;
}

#header {
	position: relative;
}

/* the height of the body will be adjusted on the client */
#body {
	background: none;
	padding: 0px;
	overflow: auto;
}

/* this must have 0 padding or sizing logic will fail */
#footer {
	position: absolute;
	bottom: 0;

	color: #404040;
	background: rgb(232,231,226);
	background-image: none;
	width: 100%;
	padding: 0px;
	border-top: 1px solid gray;
}

/* nested group lets us define some padding */
#buttonHolder {
	padding: 5px;
	margin: 0px;
}

#desc,#desc2 {
	padding: 0px;
	padding-top: 3px;
	padding-bottom: 3px;
	margin: 0px;
	margin-bottom: 5px;
	line-height: 120%;
	font-size: 0.8em;
}

.stdTitle {
	color: white;
	background: rgb(53,107,141);
	background-image: none;
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid gray;
	font-size: 1.4em;
	font-family: arial;
	text-align: center;
	white-space: nowrap;
}

/* UserName etc. */
.stdTitleInfo {
	color: black;
	width: 100%;
	padding: 0px;
	font-family: arial;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo td {
	color: black;
	padding-left: 5px;
	padding-right: 10px;
	font-size: 8pt;
	font-weight: bold;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo th {
	color: white;
	padding: 0px;
	font-size: 8pt;
	font-weight: normal;
	text-align: right;
	white-space: nowrap;
}

/* buttons in footer */
#btnFinish input,#btnCancel input,#btnBack input,#btnNext input,#btnHelp input{
	width: 6.0em;
}
/* command button styles */
.commandButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonDisabled {
	background: white;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
}

#btnBack input:hover,
#btnNext input:hover,
#btnFinish input:hover,
#btnCancel input:hover,
#btnHelp input:hover,
.commandButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}
</style>
}

/// The standard template has three main divs: header,body, and footer.
/// Subclasses typically place their content within the body div (pane).
XData Style
{
<style type="text/css">
body {
	background: #E0E0E0;
	font-family: arial, sans-serif;
	padding: 0px;
	margin: 0px;
}

.zenLabel {
	color: #404040;
	padding-left: 4px;
	font-size: 0.8em;
	vertical-align: middle;
}

.zenRequired {
	color: darkblue;
	padding-left: 4px;
	font-size: 0.8em;
	vertical-align: middle;
}

.hintText {
	font-size: 0.8em;
	vertical-align: middle;
	color: #808080;
}

#header {
	position: relative;
}

/* the height of the body will be adjusted on the client */
#body {
	background: none;
	padding: 0px;
	overflow: auto;
}

/* this must have 0 padding or sizing logic will fail */
#footer {
	position: absolute;
	bottom: 0;

	color: #404040;
	background: rgb(232,231,226);
	background-image: none;
	width: 100%;
	padding: 0px;
	border-top: 1px solid gray;
}

/* nested group lets us define some padding */
#buttonHolder {
	padding: 5px;
	margin: 0px;
}

#desc,#desc2 {
	padding: 0px;
	padding-top: 3px;
	padding-bottom: 3px;
	margin: 0px;
	margin-bottom: 5px;
	line-height: 120%;
	font-size: 0.8em;
}

.stdTitle {
	color: white;
	background: rgb(53,107,141);
	background-image: none;
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid gray;
	font-size: 1.4em;
	font-family: arial;
	text-align: center;
	white-space: nowrap;
}

/* UserName etc. */
.stdTitleInfo {
	color: black;
	width: 100%;
	padding: 0px;
	font-family: arial;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo td {
	color: black;
	padding-left: 5px;
	padding-right: 10px;
	font-size: 8pt;
	font-weight: bold;
	text-align: left;
	white-space: nowrap;
}

.stdTitleInfo th {
	color: white;
	padding: 0px;
	font-size: 8pt;
	font-weight: normal;
	text-align: right;
	white-space: nowrap;
}

/* buttons in footer */
#btnFinish input,#btnCancel input,#btnBack input,#btnNext input,#btnHelp input{
	width: 6.0em;
}
/* command button styles */
.commandButton {
	background: rgb(53,107,141);
	color: #E0E0E0;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	-moz-border-radius: 5px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonDisabled {
	background: white;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	-moz-border-radius: 5px;
}

#btnBack input:hover,
#btnNext input:hover,
#btnFinish input:hover,
#btnCancel input:hover,
#btnHelp input:hover,
.commandButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}
</style>
}

/// Contents of standard template page;
/// Subclasses can override this if they wish or
/// (more typically) implement the "body" pane with the desired content.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" >
<html id="header" OnDrawContent="%DrawTitle" />
<form id="templateForm" groupStyle=""
onvalidate="return zenPage.formValidationHandler();">
<hidden id="templateFinal" name="$FINAL" value="0" />
<pane paneName="templateBody" id="body"/>
</form>
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnBack" controlClass="commandButton" caption="Back" onclick="zenPage.previousPage();" hidden="true"/>
<spacer width="5" />
<button id="btnNext" controlClass="commandButton" caption="Next" onclick="zenPage.nextPage();" hidden="true"/>
<spacer width="15" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.finishTemplate();" />
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.cancelTemplate();" />
<spacer width="15" />
<button id="btnHelp" controlClass="commandButton" caption="Help" onclick="zenPage.showHelp();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// Provide HTML for standard template html title box.
Method %DrawTitle(pSeed As %String) As %Status
{
	#; draw html title box
	Set tName = $$$Text("Server Template","%ZEN")
	Set tTitle = ..#TEMPLATETITLE
	Set tUserName = $$$Text("User","%ZEN")
	Set tNamespace = $$$Text("Namespace","%ZEN")

	&html<<table class="stdTitle" border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left" width="58"><img width="30" height="30" src="#(..Link("portal/icon_sysexplore.png"))#"/></td>
		<td align="left" width="90%" style="padding-left:20px;">
		<div style="font-size: 0.6em;">#(tName)#</div>
		<div>#(tTitle)#</div></td>
		<td valign="top">&nbsp;
		<table class="stdTitleInfo" border="0" cellpadding="0" cellspacing="2">
		<tr><th>#(tUserName)#:</th><th>#($UserName)#</th></tr>
		<tr><th>#(tNamespace)#:</th><th>#($namespace)#</th></tr>
		</table>
		</td>
		</tr></table>>
	Quit $$$OK
}

/// Localize the name and description for this template.
ClassMethod LocalizeName(id As %String, ByRef name As %String, ByRef description As %String) As %Status [ CodeMode = objectgenerator ]
{
#define quote(%val) $zutil(144,1,%val)

	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Set DOMAIN = $G(%parameter("DOMAIN"))
	Set TEMPLATENAME = $G(%parameter("TEMPLATENAME"))
	Set DESCRIPTION = $G(%parameter("TEMPLATEDESCRIPTION"))

	If (TEMPLATENAME '= "") {
		If (DOMAIN '= "") {
			Do %code.WriteLine(" Set name = $$$Text(" _ $$$quote(TEMPLATENAME) _ ")")
		}
		Else {
			Do %code.WriteLine(" Set name = " _ $$$quote(TEMPLATENAME))
		}
	}
	If (DESCRIPTION '= "") {
		If (DOMAIN '= "") {
			Do %code.WriteLine(" Set description = $$$Text(" _ $$$quote(DESCRIPTION) _ ")")
		}
		Else {
			Do %code.WriteLine(" Set description = " _ $$$quote(DESCRIPTION))
		}
	}
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// Return false from this method to disable this template (for example based on the server platform)
ClassMethod IsEnabled() As %Boolean
{
	Quit 1
}

/// Close the template window.
ClientMethod cancelTemplate() [ Language = javascript ]
{
	// submit the template form
	var ctrlFinal = zenPage.getComponentById('templateFinal');
	zenASSERT(ctrlFinal,'Unable to find hidden control: ctrlFinal',arguments);
	ctrlFinal.setValue(0);

	var form = zenPage.getComponentById('templateForm');
	zenASSERT(form,'Unable to find form to submit',arguments);

	// turn off form validation
	form.setProperty('autoValidate',false);
	form.submit('cancel');
}

/// Finish the template: fire the template action code
ClientMethod finishTemplate() [ Language = javascript ]
{
	if (!this.onfinishHandler()) {
		return;
	}

	// submit the template form
	var ctrlFinal = zenPage.getComponentById('templateFinal');
	zenASSERT(ctrlFinal,'Unable to find hidden control: ctrlFinal',arguments);
	ctrlFinal.setValue(1);

	var form = zenPage.getComponentById('templateForm');
	zenASSERT(form,'Unable to find form to submit',arguments);

	form.submit('finish');
}

/// Update the state of the template buttons.
/// Subclasses should call this method when they need to 
/// update the state of the footer buttons.
ClientMethod updateState() [ Language = javascript ]
{
	var btnBack = zen('btnBack');
	var btnNext = zen('btnNext');
	var btnFinish = zen('btnFinish');
	var btnHelp = zen('btnHelp');

	var multi = this.hasMultiplePages();

	if (btnBack) {
		btnBack.setProperty('hidden',!multi);
		btnBack.setProperty('disabled',!this.canGoBack());
		btnBack.setProperty('controlClass',	(this.canGoBack() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnNext) {
		btnNext.setProperty('hidden',!multi);
		btnNext.setProperty('disabled',!this.canGoNext());
		btnNext.setProperty('controlClass',	(this.canGoNext() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnFinish) {
		btnFinish.setProperty('disabled',!this.canFinish());
		btnFinish.setProperty('controlClass', (this.canFinish() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnHelp) {
		btnHelp.setProperty('hidden',(''==this.helpId));
		btnHelp.setProperty('controlClass',	(this.helpId != '' ? 'commandButton' :'commandButtonDisabled'));
	}
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
}

/// This is called when the template is finished;
ClientMethod onfinishHandler() [ Language = javascript ]
{
	return true;
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return true;
}

/// Return true if this template has more than one "page".
/// This will display Back and Next buttons.
/// This is implemented by subclasses.
ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
/// This is implemented by subclasses.
ClientMethod canFinish() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
/// This is implemented by subclasses.
ClientMethod canGoNext() [ Language = javascript ]
{
	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	return false;
}

/// Go to the next page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod nextPage() [ Language = javascript ]
{
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
}

/// Show the help message for this template.
/// This opens a browser and goes to the DocBook application
/// using the value given by helpId.
ClientMethod showHelp() [ Language = javascript ]
{
	this.showDocumentation(this.helpId);
}

/// Open a browser window to show documentation.
ClientMethod showDocumentation(topic) [ Language = javascript ]
{
	var url = '/csp/docbook/DocBook.UI.Page.cls?KEY=' + cspEncodeUTF8(topic);
	var win = window.open(url,'docbook','status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
	win.focus();
}

/// Validate that the given class name is valid.<br>
/// Returns an error message if invalid.
Method IsValidClassName(pCls As %String) As %String [ ZenMethod ]
{
	If '$ZNAME(pCls,4) {
		Quit $$$Text("The class name is invalid.","%ZEN")
	}

	#; test for existence
	If ##class(%Dictionary.ClassDefinition).%ExistsId(pCls) {
		Quit $$$Text("The class name is already in use.","%ZEN")
	}
	
	Quit ""
}

ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	#; bypass normal submit logic
	#; so that we can serve the Studio Template response
	Set pSubmit.%SkipProcessing = 1

	#; create a page object to use later
	If (pSubmit.%Action = "finish") {
		Set %page = ..%CreatePage()
		
		#; copy submit values into the page
		Set tID = $O(pSubmit.%Data(""))
		While (tID '= "") {
			Do %page.%SetValueByName(tID,pSubmit.%Data(tID))
			Set tID = $O(pSubmit.%Data(tID))
		}
	}

	Quit $$$OK
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
/// This is implemented by subclasses.
Method %OnTemplateAction() As %Status
{
	Quit $$$OK
}

/// Add this named item to the current project in Studio. If you have multiple items
/// then call this method multiple times. The <var>Name</var> must contain the type of
/// the item e.g. 'User.Test.cls' is a class, and 'TEST.mac' is a MAC routine.
ClassMethod %AddToProject(Name As %String) As %Status
{
	If Name="" Quit $$$OK
	Set %session.Data("Template","AddToProject",Name)=""
	Quit $$$OK
}

/// Add this item to source control. If you have multiple items then call this method
/// multiple times. The <var>Name</var> must contain the type of the item to add e.g.
/// 'User.Test.cls'.
ClassMethod %AddToSourceControl(Name As %String) As %Status
{
	If Name="" Quit $$$OK
	Set %session.Data("Template","AddToSourceControl",Name)=""
	Quit $$$OK
}

/// If you are making a new class template then Studio needs to be told the
/// name of this class. This is done by calling this method in the final
/// page passing the name of the class.
ClassMethod %SetClassName(Name As %String) As %Status
{
	Set %session.Data("Template","CLASS")=Name
	Quit $$$OK
}

/// Internal method to output the start of the XML data section
ClassMethod %TemplateHeader()
{
	Write "<?xml version=""1.0""?>",!
	Write "<template><![CDATA[BODY"_..#DELIM
	Kill %session.Data("Template")
	Quit
}

Method %OnDrawHTMLMeta() As %Status
{
	/// Force IE to run in its newest version.
	&html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	Quit $$$OK
}

/// Render the contents of this ZEN page.
ClassMethod OnPage() As %Status
{
	Set tFinal = $G(%request.Data("$V_$FINAL",1))

	If (tFinal="") {  // !!! check for errors
		#; normal page processing
		Quit ##super()
	}
	
	#; Template final page
	Set tSC = $$$OK
	If ((tFinal = 1) && $IsObject($G(%page))) {
		Set tSC = %page.%OnTemplateAction()
	}

	Quit tSC
}

/// Make sure template runs in correct namespace.
ClassMethod OnPreHTTP() As %Boolean
{
	Set tSC = $$$OK
	Do {
		#; remember parameters passed in from Studio
		Set %response.Context("Project") = $G(%request.Data("Project",1))
		Set %response.Context("Name") = $G(%request.Data("Name",1))
		Set %response.Context("SelectedText") = $G(%request.Data("SelectedText",1))
		Set %response.Context("User") = $G(%request.Data("User",1))
		Set %response.Context("Language") = $G(%request.Data("Language",1))
		Set %response.Context("DocumentNamespace") = $G(%request.Data("DocumentNamespace",1))

		#; set up namespace
		If $G(%request.Data("Namespace",1))'="" {
			#; first page, we get Namespace from Studio URL
			Set tNamespace = %request.Data("Namespace",1)
			Set %response.Context("$NAMESPACE") = tNamespace
	
			#; cache in session also
			Set %session.Data("$NAMESPACE") = tNamespace
			Set tSC = ##class(%ZEN.Controller).%ChangeNS(tNamespace)
			If $$$ISERR(tSC) Quit
		}
		ElseIf $G(%request.Data("$NAMESPACE",1))'="" {
			#; later pages, $NAMESPACE is set, keep it in context
			Set tNamespace = %request.Data("$NAMESPACE",1)
			Set %response.Context("$NAMESPACE") = tNamespace
			Set %session.Data("$NAMESPACE") = tNamespace
			Set tSC = ##class(%ZEN.Controller).%ChangeNS(tNamespace)
			If $$$ISERR(tSC) Quit
		}
		ElseIf $G(%session.Data("$NAMESPACE"))'="" {
			Set tNamespace = %session.Data("$NAMESPACE")
			Set %response.Context("$NAMESPACE") = tNamespace
			Set %session.Data("$NAMESPACE") = tNamespace
			Set tSC = ##class(%ZEN.Controller).%ChangeNS(tNamespace)
			If $$$ISERR(tSC) Quit
		}
	} While(0)

	If $$$ISERR(tSC) Quit 0

	// dispatch to controller
	Quit ##class(%ZEN.Controller).OnPreHTTP(..%ClassName(1),+..#CLIENTCACHE,+..#AUTONS,..#RESOURCE)
}

/// Make sure template generates correct format output.
ClassMethod OnHTTPHeader(ByRef OutputBody As %Boolean) As %Status
{
	If $get(%request.Data("Namespace",1))'="" {
		Set %session.Data("Namespace")=%request.Data("Namespace",1)
		If '..#GLOBALTEMPLATE {
			Set %session.RunNamespace=%request.Data("Namespace",1)
			Do $zutil(5,%session.RunNamespace)
		}
	}

	Set tFinal = $G(%request.Data("$V_$FINAL",1))
	If (tFinal'="") {
		Set %response.ContentType="text/xml"
	}
	Do %response.WriteHTTPHeader(.OutputBody)
	If (tFinal'="") {
		Do ..%TemplateHeader()
	}
	Quit $$$OK
}

/// For final page, make sure we send the correct info to the Studio.
ClassMethod OnPostHTTP()
{
	If ($D(%request.Data("$V_$FINAL",1))) {
		Write ..#DELIM
		Set name=$order(%session.Data("Template",""))
		While name'="" {
			If (name="AddToProject") || (name="AddToSourceControl") {
				Write name,..#DELIM
				Set first=1
				Set item=$order(%session.Data("Template",name,""))
				While item'="" {
					Write $select(first:"",1:",")_item
					Set item=$order(%session.Data("Template",name,item)),first=0
				}
				Write ..#DELIM
			} Else {
				Set val=$get(%session.Data("Template",name))
				If val'="" Write name,..#DELIM,val,..#DELIM
			}
			Set name=$order(%session.Data("Template",name))
		}
		Write "]]></template>",!
	}
	Quit
}

/// This client event, if present, is fired when a keydown event occurs on the page.
ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	// prevent backpage via keyboard in templates
	return evt.altKey ? false : true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.updateState();
	this.onstartHandler();
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSize();
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	var header = zenPage.getComponentById('header');
	var body = zenPage.getComponentById('body');
	var footer = zenPage.getComponentById('footer');

	if (header && body && footer) {
		var divHeader = header.getEnclosingDiv();
		var divBody = body.getEnclosingDiv();
		var divFooter = footer.getEnclosingDiv();
		var winHeight = zenGetWindowHeight();
		
		var sz = winHeight - (parseInt(divHeader.offsetHeight) + parseInt(divFooter.offsetHeight));
		sz = sz < 10 ? 10 : sz;
		divBody.style.height = sz + "px";
	}
}

}
