/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %products)

/// This dialog lets the user Add a new iKnow domain or configuration definition.
Class %iKnow.UI.Dialog.addDomain Extends %CSP.UI.Portal.Dialog.WizardTemplate [ Deprecated, System = 4 ]
{

Parameter APPLYBUTTON = 0;

Parameter AUTONS As BOOLEAN = 1;

Parameter DOMAIN = "%iKnow";

/// Security requirement
Parameter RESOURCE = "%Development";

/// DOCBOOK Topic Id that offers help for this page.
Parameter HELPID As STRING;

Property mode As %ZEN.Datatype.string(ZENURL = "MODE") [ InitialExpression = "domain" ];

/// use this to indicate adding a domain or configuration
Property msgDomain As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a Domain name.")} ];

/// use this to indicate adding a domain or configuration
Property msgDomainDef As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a Domain Definition name.")} ];

XData Style
{
<style type="text/css">
/* @doc="Style for captions." */
a.multiSelectSetCaption {
	font-size: 12px;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:8px;padding-bottom:8px;">
<vgroup id="domainGroup" hidden="false" cellStyle="padding-bottom:8px;" valign="top">
<text id="domainName" label="Domain name" size="40" required="true" 
hint="Required. The domain name should be unique within the namespace."
onchange="zenPage.onChangeDomainName(zenThis.getValue());" />
<text id="domainDefinitionName" label="Definition class name" size="40" required="true" 
hint="Required. This is a wrapper class for managing the InterSystems Text Analytics domain."
onchange="zenPage.ValidateDomainDefName(zenThis.getValue());"/>
<checkbox id="chkAllowCustomUpdates" caption="Allow Custom Updates" captionClass="zenLabel"/>
<spacer height="2"/>
</vgroup>
</pane>
}

ClientMethod onChangeDomainName(name) [ Language = javascript ]
{
	var suggestedName = zenPage.ValidateDomainName(name);
	if (suggestedName=='') return;
	var v = zen('domainDefinitionName').getValue();
	if ((v==null) || (v=='')) {
		zen('domainDefinitionName').setValue(suggestedName);
	}
}

Method ValidateDomainName(pName As %String = "") As %String [ ZenMethod ]
{
	if (pName="") {
		&js<alert('Domain name cannot be empty!');>
		quit ""
	} elseif ($l(pName)>$$$IKHASHSIZE) {
		&js<alert('Domain name is too long');>
		quit ""
	} elseif ##class(%iKnow.Domain).NameIndexExists(pName) {
		&js<alert('Domain name already in use');>
		quit ""
	}
	set tClassName = "User."_$zstrip(pName,"*WCP",".")
	quit $s($zname(tClassName,4):tClassName, 1:"")
}

Method ValidateDomainDefName(pName As %String = "") As %Status [ ZenMethod ]
{
	if '$zname(pName,4) {
		&js<alert('Domain definition name is not a valid class name');>
	}
	quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$FormatText($$$Text("Create %1 Domain"),$$$PRODUCT5)
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var name = zen('domainDefinitionName').getValue();
	return encodeURIComponent(name);
}

/// Show definition based on type
ClientMethod changeType() [ Language = javascript ]
{
	var type = zen("Type").getValue();
	if (type == "domain") {
		zen("domainGroup").setHidden(false);
		zen("configGroup").setHidden(true);
		zen("domainName").focus();
	} else {
		zen("domainGroup").setHidden(true);
		zen("configGroup").setHidden(false);
		zen("txtConfigName").focus();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try 
	{
		//var Type = zen('Type').getValue();
		var domainName = zen('domainName');
		var tName = zenTrim(domainName.getValue());
		domainName.setValue(tName);
		if (tName == "") {
			alert(this.msgDomain);
			domainName.focus();
			return false;
		}
		var domainDefName = zen('domainDefinitionName');
		var tDefName = zenTrim(domainDefName.getValue());
		domainDefName.setValue(tDefName);
		if (tDefName == "") {
			alert(this.msgDomainDef);
			domainDefName.focus();
			return false;
		}
		var tAllowUpdate = zen("chkAllowCustomUpdates").getValue() ? 1 : 0;
		var tDisabled = 0;
		var ok = this.SaveDomain(tDefName,tName,tDisabled,tAllowUpdate);
		if (ok != 1) 
		{
			alert(ok);
			return false;
		} else {
			return true;	
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments, 'Error in ondialogFinish');
	}
	return false;
}

ClassMethod SaveDomain(pDomainDefName, pDomainName, pDisabled, pAllowCustomUpdate) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	try
	{
		Set tDomainObj = ##class(%iKnow.Model.domain).%New()
		Set tDomainObj.name = pDomainName
		Set tDomainObj.allowCustomUpdates = pAllowCustomUpdate 
		Set tDomainObj.disabled = pDisabled
		Set tSC = tDomainObj.%SaveToClass(pDomainDefName,1,0,0,"%iKnow.DomainDefinition")
	}
	catch(Ex)
	{
		Set tSC = Ex.AsStatus()
	}
	quit tSC
}

/// Save a configuration.
/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("domainName").focus();
}

}
