/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %ems)

/// Template for System Management Portal (used by System Operation, System Explorer, System Administration).
Class %CSP.UI.Portal.Template Extends %CSP.Portal.Template [ Abstract, System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter EMSSERVICE As STRING;

Parameter PAGENAME = "System Management Portal Template";

Parameter PARENTPAGE As STRING = "/csp/sys/%CSP.Portal.Home.zen";

/// Each SMP page should set this link which points to the documentation anchor name.
Parameter HELPADDRESS As STRING;

/// This property overrides %CSP.Portal.Template to use parameter HELPADDRESS that every SMP pages has.
Property HelpAddress As %ZEN.Datatype.string [ InitialExpression = {..#HELPADDRESS} ];

/// Keeps track of the first form field that failed during validation.
Property FirstFailed As %String;

/// Set to 1 in %OnAfterCreatePage if a URI parameter is invalid. Used to disable command buttons in onloadHandler().
Property InvalidParam As %Boolean [ InitialExpression = 0 ];

/// If set to 1 then the generic Save and Cancel button will be shown on the ribbon bar.
Property IsEditForm As %Boolean [ InitialExpression = 0 ];

/// 1 if we are on an EMS manager and viewing group data or on a managed instance, 0 otherwise.
/// Property IsEMSReadOnly As %Boolean [ InitialExpression = {##class(%SYS.EMS).IsReadOnly($classname())} ];
Property IsEMSReadOnly As %Boolean [ InitialExpression = 0 ];

/// Keeps track of currently disabled buttons' onclick events.
Property OnclickArray As %ArrayOfDataTypes;

/// Parent URL that Cancel and Save should return to
Property ParentURL As %String [ InitialExpression = {..Link($ZCVT(..#PARENTPAGE,"O","URL"))} ];

/// ID for edit.
Property PID As %String(ZENURL = "PID");

Property ValidationErrorMsg As %String [ InitialExpression = {$$$Text("There was a problem with the form. See the highlighted fields below.")} ];

XData Style
{
<style type="text/css">
/* light purple for Administration pages. 
   See %CSP.UI.Portal.Utils for Operations
   See %CSP.UI.Template.List and %CSP.UI.Template.Property for Explorer pages 
.ribbonTitle {
	background: #D2CFDF;
}*/
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
</style>
}

/// This method is used by SMP to return home page. Set home to %session if not null for later use.
ClassMethod %GetHomePage() As %String
{
	#; Need to set the home so that the Cancel can return to home page with sub menu.
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set homePage = $P(..Link("/csp/sys/%25CSP.Portal.Home.zen"),"?",1)_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$zconvert(NAMESPACE,"O","URL"))
	Quit homePage
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
/// Subclasses with extra layers of locator links or other than "Configuration" please override.
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$zconvert(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	If ..IsEditForm = 0 Quit $$$OK
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes"),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")

	Quit $$$OK
}

/// trim space from both outside and inside a string of a passed in zen property
/// and then set back into the zen property
ClientMethod trimSpace(zenProp) [ Language = javascript ]
{
	var string = zenTrim(zenProp.getValue());
	zenProp.setValue(string.replace(/\s+/g, ''));
}

/// This method can be called by the doSave() function to handle what the ZenMethod of server Save returned. 
/// The method expects a proxy object to be passed.
/// result.ok = 1 indicates save is successful. result.Message is a message (not an error message) that should be displayed.
/// result.ok = 0 indicates save has failed. result.ErrorMessage should be displayed.
/// If result.ok = 1 and result.Message is null then the edit form is closed and the ParentURL is displayed.
ClientMethod afterSave(result As %ZEN.proxyObject) [ Language = javascript ]
{
	if (result) {
		if (result.ok == 1){
			this.setModified(false);
			if ((typeof(result.Message) != "undefined") && (result.Message != "")) {
				this.showMsg(result.Message,0);
			} else {
				this.doCancel();
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
		}
	} else {
		this.showMsg($$$Text("Unexpected error while attempting to save"),1);
	}
}

/// This method can be called after validation (where validateRequired has failed) fails. 
/// Display standard error message and set focus to the FirstFailed field.
ClientMethod afterValidate() [ Language = javascript ]
{
	this.showMsg(this.ValidationErrorMsg,1);
	if (this.FirstFailed) {
		var field = this.FirstFailed;
		zen(field).focus();
	}
}

/// This method resets the modified indicator and return user to the parent page. 
ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	self.document.location = this.ParentURL;
}

/// This method is called when a field is modified. setModified(true) will cause the modified indicator (a star) to show next to the page name. 
ClientMethod doModified() [ Language = javascript ]
{
	this.resetMsg('');
	this.setModified(true);
}

/// This method returns true if a ribbon button is disabled; false otherwise.
ClientMethod isButtonDisabled(buttonName) [ Language = javascript ]
{
	return (self.document.getElementById("command_"+buttonName).className == "commandButtonDisabled");
}

/// Clear message from idRespond html (usually placed above the editing portion of the page, but could be anywhere).
ClientMethod resetMsg() [ Language = javascript ]
{
	zen("idRespond").setValue('');
 	zen("idRespond").setHidden(true);
}

/// Display message in idRespond html (usually placed above the editing portion of the page, but could be anywhere).
/// isErr: if 1 is passed in then the color will be changed to red; 
///        If 0 is passed in then the color is changed to #4D3926;
/// 	   If 2 is passed in then the color is changed to green, i.e. success
///        If nothing is passed in, then the color is unchanged. This allows developers to set their own style/class and still be able to use showMsg.
ClientMethod showMsg(msg, isErr) [ Language = javascript ]
{
	try {
	 	if (typeof(isErr) != "undefined") {
		 	var noteClass = (isErr == 1) ? "errorNote" : "note";
		 	if (isErr == 2) {
			 	noteClass = 'successNote';	
		 	}
		 	zen("idRespond").setProperty("enclosingClass",noteClass);
	 	}
		zen("idRespond").setValue(msg);
	 	zen("idRespond").setHidden(false);
	}
  	catch(ex) {
		alert("showMsg ERROR: " + ex);
	}
}

/// Validate the control value. pass is either "true" or "false" indicating if there is already a field that failed validation. 
/// Type is "N" for numeric or "S" for string. If numeric, if checkRange is true, we additionally validate that the number is 
/// between minVal and maxVal, inclusive.
ClientMethod validateRequired(ctl, pass, type, checkRange, minVal, maxVal) As %Boolean [ Language = javascript ]
{
	var ok = true;
	var value = ctl.getValue();
	switch (type) {
		/// contains at least one numeric character
		case "N":
			if (!(value.match(/\d/))) {
				ok = false;
			} else if (checkRange == true) {
				if (isNaN(value)) {
					// fail if not numeric
					ok = false;
				} else if ((value < minVal) || (value > maxVal)) {
					// fail if not in range
					ok = false;
				}
			}
			break;
		case "S":
		/// contains at least one character after striping all blanks
			if (zenTrim(value) == '') {
				ok = false;
			}
			break;
	}
	if (ok == false) {
		ctl.setProperty("hintClass","redText");
		ctl.setProperty("controlClass","zenInvalid");
		if (pass) {
			this.FirstFailed = ctl.getProperty("id");
		}
	} else {
		ctl.setProperty("hintClass","helpText");
		ctl.setProperty("controlClass","");
	}
	return ok;
}

/// Get the (localized) title string for the page.
/// Subclass can override.
Method %OnGetTitle() As %String
{
	If ..IsEditForm,..PID'="" Quit $$$FormatText($$$Text("Edit: %1"),..PID)
	Quit ..LocatorHeader
}

/// Disable save button for EMS-managed pages.
/// Be sure to use this.invokeSuper('onloadHandler',arguments); when overriding.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');
	if (this.IsEMSReadOnly || this.InvalidParam) {
		this.disableCommandButton('btnSave');
		this.disableCommandButton('btnNew');
	}
}

/// Be sure to do ##super() when overriding.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ..BuildMenu()
	If $$$ISERR(tSC) Quit tSC
	
	Set (..LocatorHeader,..StdTitle) = ..%OnGetPageName()
	
	Do ..RegisterRecent(..StdTitle)

	If ..CheckEnterpriseManager() {
		Set %zenPageError = $$$ERROR($$$EMSNoSMP)
	}
	
	Quit $$$OK
}

}
