/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Resource Assign dialog used by Management Portal Home Page.
Class %CSP.Portal.ResourceDialog Extends %CSP.Portal.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// User must have USE permissions on %Admin_Secure to access this popup.
Parameter RESOURCE = "%Admin_Secure:USE";

/// Name of page we are assigning a resource to.
Property pageName As %ZEN.Datatype.string(ZENURL = "NAME");

/// Link to page we are assigning a resource to.
Property pageLink As %ZEN.Datatype.string(ZENURL = "LINK");

/// If true, auto-switch namespace to whatever $NAMESPACE is passed in.
Parameter AUTONS As BOOLEAN = 1;

/// Canonical class name of page we are assigning a resource to.
Property pageID As %ZEN.Datatype.string;

Property CurrentResource As %ZEN.Datatype.string;

/// Property to hold an error message
Property isError As %ZEN.Datatype.boolean;

XData Style
{
<style type="text/css">
.readOnly {
	background: lightgray;
}
.errorMsg {
	border: 1px solid gray;
	padding: 5px;
	color: red;
	font-weight: bold;
	background-color: white;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<html OnDrawContent="DrawHelp"/>

<text id="pageName" label="Page Name" value="#(%page.pageName)#" readOnly="true" size="50" controlClass="readOnly"/>

<text id="pageLink" label="Page Link" value="#(%page.pageLink)#" readOnly="true" size="80" controlClass="readOnly"/>

<text id="pageID" label="Page Class" readOnly="true" size="80" controlClass="readOnly" />

<select id="resourceName" label="Custom Resource Name" />

</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Assign Custom Resource")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Assign a custom resource to a page within the Portal")
}

/// Draw help text.
Method DrawHelp(pSeed As %String) As %Status
{
	Write "<div id=""helpDiv"""
	If ..isError {
		Write " class=""errorMsg"">"
		Write $$$TextHTML("This page is not available for protection by a custom resource.")
	}
	Else {
		Write ">"
		Write $$$TextHTML("This dialog lets you assign an additional custom resource to a page within the Portal.")
		Write "<br/>"
		Write $$$TextHTML("In addition to the system resource assigned to the page, users must have USE privileges for this resource in order to view the page.")
		Write "<br/>"
		Write "<br/>"
	}
	Write "</div>"
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = $$$OK
	Try {
		
		// Resolve supplied link back to destination class
		Set ..pageID = ""
		If ##class(%CSP.Portal.Utils).%IsPortalPage(..pageLink,.tNormPage) {
			Set ..pageID = $get(tNormPage)
		}
		If ..pageID = "" {
			Set ..isError = 1
			Set resourceControl = ..%GetComponentById("resourceName")
			Set resourceControl.disabled = 1
		}
		Else {
			Set ctrlPageID = ..%GetComponentById("pageID")
			Set ctrlPageID.value = ..pageID
		}
		
		// fill in values
		Set ctrlRsc = ..%GetComponentById("resourceName")

		Set tResource = ##class(%CSP.Portal.Utils).%GetCustomResource($zconvert(..pageID,"O","URL"))
		Set ctrlRsc.value = tResource
		Set %page.CurrentResource = tResource
		Set tSC = ##class(%ZEN.Portal.ContextSearch).CustomResource(.tCaption,.tTopResults,.tResults,.tParms,tResource)
		Set n = 1
		Set valueList = $G(tResults(n))
		For  Set n = $O(tResults(n)) Quit:n=""  Set valueList = valueList _","_tResults(n)
		Set ctrlRsc.valueList = valueList
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (!this.isError) {
			var pageLink = encodeURI(zen('pageID').getValue()) ;
			var resource = zen('resourceName').getValue();
			// apply change
			if (resource != this.CurrentResource) {
				var msg = this.SetResource(pageLink,resource);
				if ('' != msg) {
					alert(msg);
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Set the resource name.
ClassMethod SetResource(pPageLink As %String, pResource As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(%CSP.Portal.Utils).%SetCustomResource(pPageLink,pResource)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

}
