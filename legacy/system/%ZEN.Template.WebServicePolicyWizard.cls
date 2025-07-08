/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template: New Web Service/Client Configuration.
Class %ZEN.Template.WebServicePolicyWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Web Service/Client Configuration";

Parameter TEMPLATETITLE = "Web Service/Client Configuration Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Web Service/Client Configuration.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "new";

Parameter TEMPLATEGROUP = "General";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

Parameter HELPID = "GSOAPSEC_wsp_creating_policies";

/// If NumSOAPClasses is greater than 1, then the Config Class field and Finish button are disabled.<br/>
/// If NumSOAPClasses is 1, then the Config Class is set to the first piece of ConfigId found, and modification of it is not allowed.<br/>
/// Else the Config Class is set to TargetClass_"Config"
Property NumSOAPClasses As %ZEN.Datatype.integer [ InitialExpression = 0 ];

Property ConfigClass As %ZEN.Datatype.string;

Property IsClient As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property lblNONE As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("(No security is required.)")} ];

Property lblSEC As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("(Click [Next] to specify more policy details.)")} ];

Property FINALRESULTS As %String;

XData CSS3Style
{
<style type="text/css">
body {
	overflow: hidden;
}
.zenLabel {
	font-weight: bold;	
}
/* this is the same as zenLabel except the color */
.disabledLabel {
	font-size: 0.8em;
	vertical-align: middle;
	color: #808080;
	padding-left: 4px;	
}
/* style for idRespond message */
.note {
	color: #da4848;
	font-size: 1.0em;
	font-weight: bold;
	padding: 6px;
	border: 1px gray solid;
}
/* style for title instruction of Next button */
span.guibutton { 
	color: green;
	font-weight: bold;
}
.normal {
	font-size: 0.8em;
	text-decoration: none;
	vertical-align: middle;
}
/* style for Policy Create page */
td.desc 	{ 	padding-left: 4px; 
				padding-right: 4px;
				font-size: 0.8em;
			}

div.section { display: block; font-size: 0.8em; margin-bottom: 10px; }

div.Description2	{	font-size: 0.8em; margin-bottom: 10px; font-weight: bold; }
div.DescriptionErr	{	font-size: 1.0em; margin-bottom: 10px; font-weight: bold; color: #da4848; }

</style>
}

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	overflow: hidden;
}
.zenLabel {
	font-weight: bold;	
}
<!-- this is the same as zenLabel except the color -->
.disabledLabel {
	font-size: 0.8em;
	vertical-align: middle;
	color: #808080;
	padding-left: 4px;	
}
/* style for idRespond message */
.note {
	color: #da4848;
	font-size: 1.0em;
	font-weight: bold;
	padding: 6px;
	border: 1px gray solid;
}
<!-- style for title instruction of Next button -->
span.guibutton { 
	color: green;
	font-weight: bold;
}
.normal {
	font-size: 0.8em;
	text-decoration: none;
	vertical-align: middle;
}
<!-- style for Policy Create page -->
td.desc 	{ 	padding-left: 4px; 
				padding-right: 4px;
				font-size: 0.8em;
			}

div.section { display: block; font-size: 0.8em; margin-bottom: 10px; }

div.Description2	{	font-size: 0.8em; margin-bottom: 10px; font-weight: bold; }
div.DescriptionErr	{	font-size: 1.0em; margin-bottom: 10px; font-weight: bold; color: #da4848; }

</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" cellStyle="padding-left:10px;">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<tabGroup id="tabGroup">
<!-- First Page -->
<tab id="tab1" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="1" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:730px;"/>
<radioSet id="CLASS" name="CLASS" label="Select" labelClass="zenRequired" valueList="SERVICE,CLIENT" displayList="Web Service,Web Service Client" value="SERVICE" captionClass="normal"
containerStyle="padding-bottom:4px;" onchange="zenPage.changeService(zenThis.getValue());"
/>
 <group cellStyle="padding-left:20px;">
 <select id="SERVICELIST" name="SERVICELIST" showEmpty="false"/>
 <select id="CLIENTLIST" name="CLIENTLIST" hidden="true" showEmpty="false"/>
 </group>
</tab>
<!-- Second Page -->
<tab id="tab2" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="2" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:730px;"/>
<vgroup labelPosition="left">
<text id="TARGETCLASS" name="TARGETCLASS" label="Web Service" size="80" readOnly="true" controlStyle="background:lightgray;"/>
<text id="CONFIGCLASS" name="CONFIGCLASS" label="Configuration Class Name" labelClass="zenRequired" size="80" disabled="false"/>
<html id="idNumSOAPClasses" name="idNumSOAPClasses" OnDrawContent="DrawNumSOAPClasses" seed=""/>
<hidden name="TARGETTYPE" id="TARGETTYPE"/>
</vgroup>
<html><hr size="1"/></html>
<vgroup labelPosition="left" label="Choose a Policy and Specify Details" labelClass="zenRequired">
<select id="POLICYTYPE" name="POLICYTYPE" label="Security Policy" valueList="NONE,SSL,SSLUSER,SSLCERT,SYMMETRIC,SYMMETRICCERT,MUTUAL,SSLSAML,SAMLMUTUAL"
displayList="No Security Policy,SSL/TLS Connection Security,Username Authentication over SSL/TLS,
X.509 Certificate Authentication over SSL/TLS,Authentication with Symmetric Keys,Symmetric Keys with Endorsing Certificate,
Mutual X.509 Certificates Security,SAML Authorization over SSL/TLS,SAML Authorization with X.509 Certificates"
onchange="zenPage.changePolicy(zenThis.getValue());" showEmpty="false"
/>
</vgroup>
<html id="htmlMessage" OnDrawContent="DrawMessage" seed=""/>
<label id="idNONE" label="(No security is required.)"/>
<html><hr size="1"/></html>
<checkbox id="ADDRESSING" name="ADDRESSING" caption="Enable WS-Addressing" captionClass="zenLabel" value="1"/>
<checkbox id="MTOM" name="MTOM" caption="Optimize Transfer of Binary Data (MTOM)" captionClass="zenLabel"/>
<html><hr size="1"/></html>
<!-- the following fields are shown when policy is not NONE -->
<vgroup id="SCSELECT" labelPosition="left" cellStyle="padding:2px;" hidden="true">
<checkbox id="SECURECONVERSATION" name="SECURECONVERSATION" value="0" caption="Establish Secure Session (Secure Conversation)" captionClass="zenLabel" showLabel="false" onclick="zenPage.changeSecConv(zenThis.getValue());"/>
<html OnDrawContent="DrawMessage" seed="Secure1"/>
<checkbox id="DERIVEDKEYS" name="DERIVEDKEYS" value="0" caption="Require Derived Keys" captionClass="disabledLabel" containerStyle="padding-left:20px;" showLabel="false" disabled="true"/>
<checkbox id="RELIABLEMESSAGING" name="RELIABLEMESSAGING" caption="Reliable Message Delivery" value="0" captionClass="zenLabel" showLabel="false"/>
<select id="ALGO" name="ALGO" label="Algorithm Suite" valueList="Basic128,Basic192,Basic256,Basic128Sha256,Basic192Sha256,Basic256Sha256" value="Basic128"/>
<checkbox id="STRICTLAYOUT" name="STRICTLAYOUT" caption="Strict Security Header Layout" value="1" captionClass="zenLabel" showLabel="false"/>
</vgroup>
<!-- the following hidden fields are needed for Finish -->
<hidden id="ConfigList" name="ConfigList"/>
<hidden id="RequireCert" name="RequireCert"/>
<hidden id="CredentialType" name="CredentialType"/>
<hidden id="CredentialList" name="CredentialList"/>
<hidden id="CredentialField" name="CredentialField"/>
<hidden id="CredentialValue" name="CredentialValue"/>
<hidden id="ICredentialType" name="ICredentialType"/>
<hidden id="ICredentialList" name="ICredentialList"/>
<hidden id="ICredentialField" name="ICredentialField"/>
<hidden id="ICredentialValue" name="ICredentialValue"/>
<hidden id="RCredentialType" name="RCredentialType"/>
<hidden id="RCredentialList" name="RCredentialList"/>
<hidden id="RCredentialField" name="RCredentialField"/>
<hidden id="RCredentialValue" name="RCredentialValue"/>
<hidden id="EncryptToken" name="EncryptToken"/>
<hidden id="EncryptBody" name="EncryptBody"/>
<hidden id="EncryptBeforeSign" name="EncryptBeforeSign"/>
<hidden id="TokenProtect" name="TokenProtect"/>
</tab>
<!-- Third Page -->
<tab id="tab3" enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="3" enclosingStyle="padding-bottom:6px;border-bottom:1px solid teal; width:730px;"/>
<group labelPosition="left"><label id="idSECPOL" label="Security Policy:" enclosingClass="zenLabel"/></group>
<html id="htmlContent" OnDrawContent="DrawDetailsContent" seed=""/>
</tab>
</tabGroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	#; Load drop-down lists on the first tab
	Set Clients = ..LoadList(.Services)
	Set ..%GetComponentById("SERVICELIST").valueList = Services
	Set ..%GetComponentById("CLIENTLIST").valueList = Clients
			
	Quit $$$OK
}

/// user changed SERVER <=> CLIENT. need to reset any policy selection back to NONE.
ClientMethod changeService(CLASS) [ Language = javascript ]
{
	this.IsClient = (CLASS=="CLIENT") ? 1 : 0;
	zen("SERVICELIST").setHidden(CLASS!="SERVICE");
	zen("CLIENTLIST").setHidden(CLASS=="SERVICE");
	// when Service is changed, always reset the policy selection back to NONE
	zen("POLICYTYPE").setValue("NONE");
	this.changePolicy("NONE");
}

/// prepare for tab 2.
ClientMethod changeType(type, targetclass) [ Language = javascript ]
{
	zen("SERVICELIST").setHidden(type!="SERVICE");
	zen("CLIENTLIST").setHidden(type=="SERVICE");
	var TARGETCLASS = zen("TARGETCLASS");
	if (type == "SERVICE") {
		var targettype = $$$Text("Web Service");
		TARGETCLASS.setProperty("label",targettype);
	} else {
		var targettype = $$$Text("Web Service Client")
		TARGETCLASS.setProperty("label",targettype);
	}
	if (this.NumSOAPClasses<1) this.ConfigClass = targetclass+"Config";
	TARGETCLASS.setValue(targetclass);
	zen("CONFIGCLASS").setValue(this.ConfigClass);
	zen("CONFIGCLASS").setProperty("readOnly", (this.NumSOAPClasses>0));
	zen("TARGETTYPE").setValue(targettype);
}

/// load, show/hide fiels based on policy selected.
ClientMethod changePolicy(policy) [ Language = javascript ]
{
	var isNone = (policy=="NONE");
	var label = (isNone) ? this.lblNONE : this.lblSEC;
	var policyindex = zen("POLICYTYPE").getSelectedIndex();
	zen("idNONE").setProperty("label",label);
	// show the description below the policy drop-down if it's not NONE
	zen("htmlMessage").setProperty("seed",policy);
	// display selected Policy on tab 3 as a reference
	zen("idSECPOL").setValue(policy + " - " + zen("POLICYTYPE").getOptionText(policyindex));
	// show or hide the common Security and Algorithm fields
	zen("SCSELECT").setHidden(isNone);
	// load more policy fields for tab 3
	zen("htmlContent").setProperty("seed",policy);
	this.updateState();
	return;
}

/// enable/disable DERIVEDKEYS based on Secure Conversation
ClientMethod changeSecConv(flag) [ Language = javascript ]
{
	zen("DERIVEDKEYS").setDisabled(!flag);
	if (flag==false) {
		zen("DERIVEDKEYS").setValue(false);
		zen("DERIVEDKEYS").setProperty("captionClass","disabledLabel");
	} else {
		zen("DERIVEDKEYS").setProperty("captionClass","zenLabel");
	}
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	zen("CLASS").focus();
}

/// This is called when the template is finished - gather selected values and put into hidden Zen fields for %OnTemplateAction.<br/>
/// The extra work is needed because most policy specific fields are html controls rather than Zen controls.
ClientMethod onfinishHandler() [ Language = javascript ]
{
	var policy = zen("POLICYTYPE").getValue();
	if (policy == "NONE") return true;
	zen("ConfigList").setValue(this.getFinalValue(policy+"_CONFIGLIST","list"));
	zen("RequireCert").setValue(this.getFinalValue(policy+"_REQUIRECERT","checkbox"));
	zen("CredentialType").setValue(this.getFinalValue(policy+"_CREDTYPE","radio"));
	zen("CredentialList").setValue(this.getFinalValue(policy+"_CREDLIST","list"));
	zen("CredentialField").setValue(this.getFinalValue(policy+"_FIELD","list"));	
	zen("CredentialValue").setValue(this.getFinalValue(policy+"_VALUE","text"));
	zen("ICredentialType").setValue(this.getFinalValue(policy+"_I_CREDTYPE","radio"));
	zen("ICredentialList").setValue(this.getFinalValue(policy+"_I_CREDLIST","list"));
	zen("ICredentialField").setValue(this.getFinalValue(policy+"_I_FIELD","list"));
	zen("ICredentialValue").setValue(this.getFinalValue(policy+"_I_VALUE","text"));	
	zen("RCredentialType").setValue(this.getFinalValue(policy+"_R_CREDTYPE","radio"));	
	zen("RCredentialList").setValue(this.getFinalValue(policy+"_R_CREDLIST","list"));
	zen("RCredentialField").setValue(this.getFinalValue(policy+"_R_FIELD","list"));
	zen("RCredentialValue").setValue(this.getFinalValue(policy+"_R_VALUE","text"));
	zen("EncryptToken").setValue(this.getFinalValue(policy+"_ETOKEN","checkbox"));
	if ((policy.indexOf("MUTUAL")>-1) || (policy.indexOf("SYMMETRIC")>-1)) {
		zen("EncryptBody").setValue(this.getFinalValue(policy+"_EBODY","checkbox"));
		zen("EncryptBeforeSign").setValue(this.getFinalValue(policy+"_EBEFORES","checkbox"));
		zen("TokenProtect").setValue(this.getFinalValue(policy+"_TOKENPROTECT","checkbox"));
	}
	return true;
}

/// Return value of the given html field name and type. 
ClientMethod getFinalValue(fieldName, fieldType) [ Language = javascript ]
{
	try {
		var returnValue = "";
		//It is possible that a field is not defined if the policy does not apply. In that case just return null.
		if (document.getElementById(fieldName)) {
			var fieldObj = document.getElementById(fieldName);
			switch (fieldType) {
			case "list":
				returnValue = fieldObj.options[fieldObj.selectedIndex].value;	
				break;
			case "radio":
				// it is either "LIST" or "FIND".
				if (fieldObj.checked) {
					returnValue = fieldObj.value;
				} else {
					returnValue = "FIND";
				}
				break;
			case "text":
				returnValue = fieldObj.value;
				break;
			case "checkbox":
				returnValue = (fieldObj.checked) ? 1 : 0;
				break;
			}			
		}
 		return returnValue;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in getFinalValue');
	}
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		break;
	case 2:
		if (zen("POLICYTYPE").getValue()=="NONE") flag=false;
		break;
	case 3:
		flag = false;
	}
	return flag;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var CLASS = zen("CLASS").getValue();
	var TargetClass = "";
	if (CLASS == "SERVICE") {
		TargetClass = zen("SERVICELIST").getValue();
		if (TargetClass == "") {
			this.showMsg($$$Text("Cannot find Web Service class. Unable to continue."));
			return;
		}
	} else {
		TargetClass = zen("CLIENTLIST").getValue();
		if (TargetClass == "") {
			this.showMsg($$$Text("Cannot find Web Service Client class. Unable to continue."));
			return;
		}
	}
	switch(tabNo) {
	case 1:
		this.resetMsg();
		zen("idNumSOAPClasses").setProperty("seed",TargetClass);
		this.changeType(CLASS,TargetClass);
		tabGroup.showNextTab();
		break;
	case 2:
		tabGroup.showNextTab();
		break;
	}
	this.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showPreviousTab();
	this.updateState();
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	
	var tabGroup = zenPage.getComponentById('tabGroup');
	return (tabGroup.getCurrTabNo() > 1);
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
		//flag = (this.NumSOAPClasses<2) ? true : false;
		if (zen("POLICYTYPE").getValue()=="NONE") flag = true;
		break;
	case 3:
		flag = true;
		break;
	}		
	return flag;
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	var CONFIGCLASS = zen("CONFIGCLASS").getValue();
	if (CONFIGCLASS == '') {
		alert('#($$$TextJS("Please enter the Configuration Class Name."))#');
		zen("CONFIGCLASS").focus();
		return false;
	}
	
	var rep = (this.NumSOAPClasses==1) ? 1 : 0;
	var err = this.validateConfigurationName(CONFIGCLASS,rep);

	if (err == '') {
		return true;
	} else {
		if (err.charAt(0) == '>') {
			return confirm(err.substr(1));
		} else {
			alert(err);
			return false;
		}
	}
	return true;
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

ClassMethod validateConfigurationName(classname As %String, replace As %Boolean) As %String [ ZenMethod ]
{
	If ('$zname(classname,4)) {
		// invalid class name
		Quit $$$Text("Invalid Configuration Class Name.")
	}
	
	If 'replace,##class(%Dictionary.CompiledClass).%ExistsId($$$NormalizeClassname(classname)) {
		// duplicate class name
		Quit ">"_$$$Text("Click OK to replace existing class.")
	}
	
	Quit ""
}

/// Return Services and Clients valueList to be loaded into drop-downs.
ClassMethod LoadList(Output Services) As %String
{
	Do GetAllDerivedClasses^%occLibrary("%SOAP.WebBase",.WSclasses)
    Set (class,Services,Clients) = ""
    For {
	    Set class = $order(WSclasses(class))
	    If class = "" Quit
	    If '($extract(class)="%") || ($$$comClassKeyGet(class,$$$cCLASShidden)) {
		    Try {
			    If $classmethod(class,"%Extends","%SOAP.WebService") {
				    Set Services = Services _ $S(Services'="":",",1:"")_class
			    } Else {
				    Set Clients = Clients _ $S(Clients'="":",",1:"")_class 
			    }
		    } Catch {
			    Kill WSclasses(class)
		    }
	    }
    }
    Quit Clients
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = ""
	If pSeed = 1 {
		Set tPageTitle = $$$Text("This wizard creates a configuration class that applies to your selected Web service or Web service client class. This configuration contains WS-Policy expressions that describe the capabilities and requirements of that service or client. These expressions can refer to WS-Security, WS-Addressing, and MTOM.")_"<br/><br/>"_
	    $$$Text("To start, select the Web service or Web service client to configure and then press <span CLASS='guibutton'>Next</span>.")

	} ElseIf pSeed = 2 {
		Set tPageTitle = $$$Text("To create the configuration class, choose a policy and specify details.")
	} ElseIf pSeed = 3 {
		Set tPageTitle = $$$Text("Specify policy details below and then press <span class='guibutton'>Finish</span>.")_"<br/><br/>"_
		$$$Text("The class is not automatically compiled and is not in effect until you compile it.")
	} 

	Set tStep = ""
	Set:pSeed>1 tStep = $$$FormatText($$$Text("Step %1"),pSeed)_" - "
	&html<<div class="Description">#(tStep)##(tPageTitle)#
	</div>>
	Quit $$$OK
}

/// This method is processed when user selects a CLASS type and clicks Next. TargetClass is passed in.
ClassMethod DrawNumSOAPClasses(pSeed As %String) As %Status
{
	Quit:pSeed="" 1
	Set TargetClass = pSeed
	#; Determine Number of SOAP classes
	Set NumSOAPClasses = 0
	Set ConfigId = ##class(%SOAP.Configuration).GetConfigId(TargetClass)
	If ConfigId '= "" {
		Do ##class(%SOAP.Configuration).GetSOAPClasses(ConfigId,.SOAPClasses)
		Set class=""
		For {
			Set class = $order(SOAPClasses(class))
			If class = "" Quit
			Set NumSOAPClasses = NumSOAPClasses+1
		}
	}
	Set %page.NumSOAPClasses = NumSOAPClasses
	If NumSOAPClasses > 1 {
		&html<<div class="DescriptionErr">#($$$Text("The Existing Configuration Class contains configurations for more than one SOAP class.  Configuration class cannot be replaced."))#<br></div>>
	} ElseIf NumSOAPClasses = 1 {
		Set %page.ConfigClass = $piece(ConfigId,":",1)
		&html<<div class="DescriptionErr">#($$$Text("The Existing Configuration Class will be replaced by this new configuration."))#<br></div>>
	}

	Quit 1
}

ClassMethod GetPolicyMessage(pCode As %String) As %String
{
	Set tMessage = ""
	If pCode = "SSL" {
		Set tMessage = $$$Text("This policy requires use of http over SSL/TLS (https).")_"&nbsp;"_
		$$$Text("It provides confidentiality and integrity of the data stream, authentication of the server, and optional authentication of the client.")
	} ElseIf pCode = "SSLUSER" {
		Set tMessage = $$$Text("This policy requires the client to send a Username Token (with username and password).")_"&nbsp;"_
		$$$Text("This policy also requires use of http over SSL/TLS (https).")_"&nbsp;"_
		$$$Text("It provides confidentiality and integrity of the data stream, authentication of the server, and optional authentication of the client.")
	} ElseIf pCode = "SSLCERT" {
		Set tMessage = $$$Text("This policy requires the client to send messages with signed timestamp and the X.509 certificate that can verify the signature.")_"&nbsp;"_
		$$$Text("This policy also requires use of http over SSL/TLS (https).")_"&nbsp;"_
		$$$Text("It provides confidentiality and integrity of the data stream, authentication of the server, and optional authentication of the client.")
	} ElseIf pCode = "SYMMETRIC" {
		Set tMessage = $$$Text("This policy requires a single, shared secret key that is used to both sign and encrypt the message.")_" "_
		$$$Text("For this mechanism, the client does not possess any certificate/key of his own, but instead may optionally send a username/password for authentication.")_"&nbsp;"_
		$$$Text("The client shares a secret key with the server. The shared, symmetric key is generated at runtime and encrypted using the service's certificate.")
	} ElseIf pCode = "SYMMETRICCERT" {
		Set tMessage = $$$Text("This policy requires a single, shared secret key that is used to both sign and encrypt the message.")_"&nbsp;"_
		$$$Text("The client shares a secret key with the server. The shared, symmetric key is generated at runtime and encrypted using the service's certificate.")_"&nbsp;"_
		$$$Text("This mechanism uses an endorsing client certificate to augment the claims provided by the token associated with the message signature.")
	} ElseIf pCode = "MUTUAL" {
		Set tMessage = $$$Text("This policy requires all peers to sign the message body and timestamp, as well as WS-Addressing headers, if included.")_"&nbsp;"_
		$$$Text("It also optionally encrypts the message body with the public key of the peer's certificate.")
	} ElseIf pCode = "SSLSAML" {
		Set tMessage = $$$Text("This policy requires the client to send a SAML token which contains an X.509 certificate or public key.")_"&nbsp;"_
		$$$Text("The corresponding private key is used to sign the timestamp.")_"&nbsp;"_
		$$$Text("This policy also requires use of http over SSL/TLS (https).")_"&nbsp;"_
		$$$Text("It provides confidentiality and integrity of the data stream, authentication of the server, and optional authentication of the client.")
	} ElseIf pCode = "SAMLMUTUAL" {
		Set tMessage = $$$Text("This policy requires the client to send a SAML token that has been signed using the private key corresponding to the certificate contained in the initiator token.")_"&nbsp;"_
		$$$Text("This policy also requires all peers to sign the message body and timestamp, as well as WS-Addressing headers, if included.")_"&nbsp;"_
		$$$Text("It also optionally encrypts the message body with the public key of the peer's certificate.")
	}
	Quit tMessage
}

/// Passing in code or policy type, display description of it.
ClassMethod DrawMessage(pSeed As %String) As %Status
{
	Set tMessage = ""
	If pSeed = "Secure1" {
		Set tMessage = $$$Text("Secure Conversation enables a consumer and provider to establish a shared security context when a multiple-message-exchange sequence is first initiated.") _"&nbsp;"_ 
			$$$Text("Subsequent messages use (possibly derived) session keys that increase the overall security while reducing the security processing overhead for each message.") _"&nbsp;"_
 			$$$Text("When this option and Require Derived Keys are both enabled, a derived key will be used. If not, the original session key will be used.")
	} Else {
		Set tMessage = ..GetPolicyMessage(pSeed)
	}
	&html<<div class="normal">#(tMessage)#</div>>	
	Quit 1
}

/// This method draws policy detailed content. 
ClassMethod DrawDetailsContent(code As %String) As %Status
{
	If code = "" Quit 1
	Set IsClient = %page.IsClient
	If code = "SSL" {
		&html<<div class="section" id="SSL">
		#(..GetPolicyMessage(code))#
		>
		Do ..GetSSLInfo(code)
		&html<</div>>
	}
	ElseIf code = "SSLUSER" {
		&html<<div class="section" id="SSLUSER">
		#(..GetPolicyMessage(code))#
		<br><br>
		#($$$Text("The <b>Username Token</b> must be specified at runtime."))#
		#($$$Text("To specify the Username Token, set the Username and Password properties or"))#
		#($$$Text("add an instance of %SOAP.Security.UsernameToken to the Security header with the default $$$SOAPWSPasswordText type."))#
		>
		Do ..GetSSLInfo(code)
		&html<</div>>
	}
	ElseIf code = "SSLCERT" {
		&html<<div class="section" id="SSLCERT">
		#(..GetPolicyMessage(code))#
		>
		Do ..GetSSLInfo(code)
		If IsClient Do ..GetX509Info("SSLCERT")
		&html<</div>>
	}
	ElseIf code = "SYMMETRIC" {
		&html<<div class="section" id="SYMMETRIC">
		#(..GetPolicyMessage(code))#
		<br>>
		Do ..GetProtectionInfo("SYMMETRIC")
		&html<<br>
		#($$$Text("This policy may optionally require the client to send a <b>Username Token</b> (with username and password)."))#
		#($$$Text("The Username Token must be specified at runtime."))#
		#($$$Text("To specify the Username Token, set the Username and Password properties or"))#
		#($$$Text("add an instance of %SOAP.Security.UsernameToken to the Security header with the default $$$SOAPWSPasswordText type."))#
		<br>
		<b><input type="checkbox" id="SYMMETRIC_ETOKEN" name="SYMMETRIC_ETOKEN" value="1">#($$$Text("Include Encrypted UsernameToken"))#</b>
		<br>
		>
		Do ..GetSymmetricInfo("SYMMETRIC")
		&html<</div>>
	}
	ElseIf code = "SYMMETRICCERT" {
		&html<<div class="section" id="SYMMETRICCERT">
		#(..GetPolicyMessage(code))#
		<br>>
		Do ..GetProtectionInfo("SYMMETRICCERT")
		Do ..GetSymmetricInfo("SYMMETRICCERT")
		Set endorsingdesc = $$$Text("<b>Endorsing Token</b>")
		If IsClient Do ..GetX509Info("SYMMETRICCERT",endorsingdesc)
		&html<</div>>
	}
	ElseIf code = "MUTUAL" {
		&html<<div class="section" id="MUTUAL">
		#(..GetPolicyMessage(code))#
		<br>>
		Do ..GetProtectionInfo("MUTUAL")
		&html<<br>
		#($$$Text("This policy may optionally require the client to send a <b>Username Token</b> (with username and password)."))#
		#($$$Text("The Username Token must be specified at runtime."))#
		#($$$Text("To specify the Username Token, set the Username and Password properties or"))#
		#($$$Text("add an instance of %SOAP.Security.UsernameToken to the Security header with the default $$$SOAPWSPasswordText type."))#
		<br>
		<b><input type="checkbox" id="MUTUAL_ETOKEN" name="MUTUAL_ETOKEN" value="1">#($$$Text("Include Encrypted UsernameToken"))#</b>
		<br>>
		Do ..GetMutualInfo("MUTUAL")
		&html<</div>>
	}
	ElseIf code = "SSLSAML" {
		&html<<div class="section" id="SSLSAML">
		#(..GetPolicyMessage(code))#
		<br><br>
		#($$$Text("The <b>SAML Token</b> must be specified at runtime by adding a %SAML.Assertion instance to the Security header."))#
		>
		Do ..GetSSLInfo("SSLSAML")
		&html<</div>>
	}
	ElseIf code = "SAMLMUTUAL" {
		&html<<div class="section" id="SAMLMUTUAL">
		#(..GetPolicyMessage(code))#
		<br>>
		Do ..GetProtectionInfo("SAMLMUTUAL")
		&html<<br>
		#($$$Text("The <b>SAML Token</b> must be specified at runtime by adding a %SAML.Assertion instance to the Security header."))#<br>
		<b><input type="checkbox" name="SAMLMUTUAL_ETOKEN" value="1">#($$$Text("Encrypt SAML Token"))#</b>
		<br>
		>
		Do ..GetMutualInfo("SAMLMUTUAL")
		&html<</div>>
	}
	Quit 1
}

/// code passed in is the Security Policy code.
ClassMethod GetSSLInfo(code As %String)
{
	If code = "" Quit 1
	Set isClient = %page.IsClient
	Set lblNone = $$$Text("[ none selected ]")
	&html<<br><br>>
	If isClient {
		// Get list of SSL configurations
		Do GetSSLConfigList^%SYS.SECURITY1(.SSLConfigs)
		&html<
		<b>#($$$Text("SSL Configuration"))#:</b>
			<select id="#(code)#_CONFIGLIST" name="#(code)#_CONFIGLIST">
			<option selected value="">#(lblNone)#>
			For i=1:1:SSLConfigs {
				If $G(SSLConfigs(i)) '= "" &html<<option value="#(SSLConfigs(i))#">#($ZCVT(SSLConfigs(i),"O","HTML"))#>
		    }
		&html<</select>
		<br><i>#($$$Text("If none selected, specify the SSLConfiguration property of the web client at runtime."))#</i>
		<br><br>>
	}
	&html<
	<b><input type="checkbox" id="#(code)#_REQUIRECERT" name="#(code)#_REQUIRECERT" checked value="1">#($$$Text("SSL/TLS Connection Requires Client Certificate"))#</b>
	<br>>	
	Quit
}

/// code passed may contain code_R_ or code_I (if IsClient).
ClassMethod GetX509Info(code As %String, desc As %String)
{
	&html<<br>>
	If $data(desc) {
		Write desc,!
	}
	Set lblNone = $$$Text("[ none selected ]")
	&html<<table><tr>
	<td class="desc"><b><input type="radio" checked id="#(code)#_CREDTYPE" name="#(code)#_CREDTYPE" value="LIST">#($$$Text("X.509 Credentials"))#</b>
    <select id="#(code)#_CREDLIST" name="#(code)#_CREDLIST">
	<option selected value="">#(lblNone)#>
	Set rs = ##class(%ResultSet).%New("%SYS.X509Credentials:ListDetails")
	Do rs.Execute()
	While rs.Next() {
		Set c = $get(rs.Data("Alias"))
		If c '= "" &html<<option value="#(c)#">#($ZCVT(c,"O","HTML"))#>
	}
	&html<</select></td></tr>
	<tr>
	<td class="desc"><b><input type="radio" id="#(code)#_CREDTYPE" name="#(code)#_CREDTYPE" value="FIND">#($$$Text("Select Credentials by Certificate Field Value"))#</b></td>
	</tr>
	<tr>
    <td class="desc"><b>#("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"_$$$Text("Field"))#</b>
    	<select id="#(code)#_FIELD" name="#(code)#_FIELD">
        <option selected value="">#(lblNone)#>
    Write "<option value=""Alias"">Alias",!
    Write "<option value=""SubjectKeyIdentifier"">SubjectKeyIdentifier",!
    Write "<option value=""Thumbprint"">Thumbprint",!
    Write "<option value=""SerialNumber"">SerialNumber",!
    Write "<option value=""IssuerDN"">IssuerDN",!
    Write "<option value=""IssuerName"">IssuerName",!
    Write "<option value=""SubjectDN"">SubjectDN",!
    Write "<option value=""SubjectName"">SubjectName",!
    &html<</select>
	&nbsp;=&nbsp;<input type="text" size="40" id="#(code)#_VALUE" name="#(code)#_VALUE" value=""></td></tr>
	</table>
	<i>#($$$Text("If neither is specified, create an instance of %SOAP.Security.BinarySecurityToken at runtime from an instance of %SYS.X509Credentials."))#</i><br>
	>
}

ClassMethod GetProtectionInfo(code As %String)
{
	&html<<br>
	<b><input type="checkbox" id="#(code)#_EBODY" name="#(code)#_EBODY" value="1">#($$$Text("Encrypt SOAP Body"))#</b>
	<br>
	<b><input type="checkbox" id="#(code)#_EBEFORES" name="#(code)#_EBEFORES" value="1">#($$$Text("Encrypt Before Signing"))#</b>
	<br>
	<b><input type="checkbox" id="#(code)#_TOKENPROTECT" name="#(code)#_TOKENPROTECT" value="1">#($$$Text("Token Protection - Signature must cover the token used to generate the signature"))#</b>
	<br>
	>
}

ClassMethod GetSymmetricInfo(code As %String)
{
	Set servicedesc=$$$Text("<b>Protection Token</b> - The client uses the public key in the certificate contained in the protection token to encrypt the symmetric key.")
	If %page.IsClient Do ..GetX509Info(code_"_R",servicedesc)
}

ClassMethod GetMutualInfo(code As %String)
{
	Set clientdesc=$$$Text("<b>Initiator Token</b> - The client uses the private key corresponding to the certificate contained in the initiator token for message signing, and sends the initiator token to the service to enable the service to verify signatures and optionally encrypt the response.")
	Set servicedesc=$$$Text("<b>Recipient Token</b> - The client uses the public key in the certificate contained in the recipient token to encrypt the outbound message body and timestamp. The service uses the private key corresponding to the certificate contained in the recipient token for message signing.")
	If %page.IsClient Do ..GetX509Info(code_"_I",clientdesc)
	Do ..GetX509Info(code_"_R",servicedesc)
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set TargetType = ..%GetValueByName("TARGETTYPE")
	Set TargetClass = ..%GetValueByName("TARGETCLASS")
	Set ConfigClass = ..%GetValueByName("CONFIGCLASS")
	Set %session.Data("Template","CLASS") = ConfigClass

	Set def = ##class(%SOAP.ConfigurationDefinition).%New()
	Set def.SOAPClassName = TargetClass
	Set def.ConfigName = ConfigClass

	Set def.PolicyType = ..%GetValueByName("POLICYTYPE")

	Set def.ConfigList = ..%GetValueByName("ConfigList")   				; Can be ""
	Set def.RequireCert = ..%GetValueByName("RequireCert")
	Set def.CredentialType = ..%GetValueByName("CredentialType") 		; Can be LIST or FIND
	Set def.CredentialList = ..%GetValueByName("CredentialList") 		; Can be ""
	Set def.CredentialField = ..%GetValueByName("CredentialField")  	; Can be ""
	Set def.CredentialValue = ..%GetValueByName("CredentialValue")
	Set def.ICredentialType = ..%GetValueByName("ICredentialType") 		; Can be LIST or FIND
	Set def.ICredentialList = ..%GetValueByName("ICredentialList") 		; Can be ""
	Set def.ICredentialField = ..%GetValueByName("ICredentialField") 	; Can be ""
	Set def.ICredentialValue = ..%GetValueByName("ICredentialValue")
	Set def.RCredentialType = ..%GetValueByName("RCredentialType") 		; Can be LIST or FIND
	Set def.RCredentialList = ..%GetValueByName("RCredentialList") 		; Can be ""
	Set def.RCredentialField = ..%GetValueByName("RCredentialField")   	; Can be ""
	Set def.RCredentialValue = ..%GetValueByName("RCredentialValue")
	Set def.EncryptToken = ..%GetValueByName("EncryptToken")
	If (def.PolicyType["MUTUAL") || (def.PolicyType["SYMMETRIC") {
		Set def.EncryptBody = ..%GetValueByName("EncryptBody")
		Set def.EncryptBeforeSign = ..%GetValueByName("EncryptBeforeSign")
		Set def.TokenProtect = ..%GetValueByName("TokenProtect")
	} Else {
		Set def.EncryptBody = ""
		Set def.EncryptBeforeSign = ""
		Set def.TokenProtect = ""
	}
	Set def.SecureConversation = ..%GetValueByName("SECURECONVERSATION")
	Set def.DerivedKeys = ..%GetValueByName("DERIVEDKEYS")
	Set def.ReliableMessaging = ..%GetValueByName("RELIABLEMESSAGING")
	Set def.Addressing = ..%GetValueByName("ADDRESSING")
	Set def.MTOM = ..%GetValueByName("MTOM")
	Set def.Algorithm = ..%GetValueByName("ALGO")
	Set def.StrictLayout = ..%GetValueByName("STRICTLAYOUT")
	
	Do def.MakeConfiguration()

	Quit 1
}

}
