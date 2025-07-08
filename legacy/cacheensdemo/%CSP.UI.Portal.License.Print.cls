/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page allows to print current active license and user selected license file to a printer.
Class %CSP.UI.Portal.License.Print Extends (%CSP.Portal.standardDialog, %CSP.UI.Portal.License.Utils) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter RESOURCE = "%Admin_Manage:USE";

/// Displayed name of this page.
Parameter PAGENAME = "PrintLicense";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.License.Print.zen";

/// Display title of this page <title></title>
Parameter PAGETITLE = "Print License";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Switch namespace for this page: 
Parameter AUTONS As BOOLEAN = 0;

/// Schema name passed in from URL.
Property Filename As %String(ZENURL = "Filename");

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<vgroup cellStyle="padding-top:2px;" containerStyle="padding:10px;">
<hgroup cellStyle="padding-right:2px;">
<button caption="Print" onclick="zenPage.doPrint();"/>
<button caption="Close" onclick="zenPage.doCancel();"/>
</hgroup>
<html label="Active license key information for this system:" OnDrawContent="DrawLicense"/>
<spacer height="4px"/>
<vgroup id="fileContainer" label="License Key File:" enclosingStyle="padding:2px; border:1px solid lightgray;">
<html id="idFileName" OnDrawContent="PrintFile" seed="#(%page.Filename)#"/>
</vgroup>
<spacer height="4px"/>
<html OnDrawContent="DrawDate"/>
</vgroup>
</page>
}

/// Prepare to start printing
ClientMethod doPrint() [ Language = javascript ]
{
	window.print();
}

ClientMethod doCancel() [ Language = javascript ]
{
	this.cancelPopup();
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	If (..Filename = "") {
		Set ..%GetComponentById("fileContainer").hidden = 1
	} Else {
		Set ..%GetComponentById("fileContainer").label = $$$FormatText($$$Text("Contents of %1:"),..Filename)
	}
	Quit $$$OK
}

ClassMethod DrawDate(pSeed As %String) As %Status
{
	&html<<div class="normal">#($$$FormatText($$$Text("Printed by %1 on %2."),$Username,$ZDT($H)))#>
	Quit $$$OK
}

ClassMethod PrintFile(pFile As %String) As %Status
{
	If (pFile '= "") {
		Quit ..DrawFile(pFile,1)
	}
	Quit $$$OK
}

}
