/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a ZEN Report Launch Page
Class %ZEN.Report.launcher Extends %ZEN.Component.page [ Deprecated, System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION;

/// Displayed name of this page.
Parameter PAGENAME;

/// Domain used for localization.
Parameter DOMAIN;

Property ReportClass As %String(MAXLEN = 255, ZENURL = "REPORT");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">

<dataController id="report"/>
<!--
<form controllerId="report">
<text label="Month" dataBinding="Month"/>
<submit caption="Run" nextPage="ZENApp.MyReport.cls"/>
</form>
-->

<dynaForm controllerId="report" injectControls="before">
<submit id="submit" caption="Run"/>
</dynaForm>

</page>
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	// Point controller and submit button to correct
	// report page
	Set tController = ..%GetComponentById("report")
	Set tController.modelClass = ..ReportClass
	
	Set tSubmit = ..%GetComponentById("submit")
	Set tSubmit.nextPage = ..ReportClass_".cls"

	Quit $$$OK
}

}
