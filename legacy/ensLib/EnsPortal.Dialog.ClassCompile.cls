/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.ClassCompile Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on one of the listed resources to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE,%Ens_BPL:WRITE,%Ens_DTL:WRITE,%Ens_RecordMap:WRITE";

Parameter APPLYBUTTON = 0;

Parameter CANCELBUTTON = 0;

Parameter CLOSEONESC = 2;

Parameter CLOSEONENTER = 1;

Parameter PAGENAME = "Compile Class";

Property classname As %ZEN.Datatype.className(ZENURL = "CLASSNAME");

Property classtype As %ZEN.Datatype.string(ZENURL = "TYPE");

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $Case(..classtype,
			"BPL"  : $$$TextHTML("Compile BPL"),
			"DTL"   : $$$TextHTML("Compile DTL"),
			"RecordMap" : $$$TextHTML("Compile RecordMap"),
			: $ZCVT($$$FormatText($$$Text("ERROR '%1'"),..classtype),"O","HTML"))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod applyDetails() [ Language = javascript ]
{
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" align="left" valign="middle" >
<label id="classname" enclosingClass="label" value="" enclosingStyle="padding-left: 10px;" />
<iframe id="outputFrame" frameBorder="false" height="400" width="600"/>
</pane>
}

XData Style
{
<style type="text/css">
.label {
	font-weight: bold;
}
</style>
}

/// Update label and set source for frame object
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set tNameLabel = ..%GetComponentById("classname")
	If $IsObject(tNameLabel) Set tNameLabel.value = ..classname
	
	Set tOutputFrame = ..%GetComponentById("outputFrame")
	If $IsObject(tOutputFrame) {
		Set tQuery("CLASS") = ..classname
		Set tQuery("TYPE") = ..classtype
		Set tOutputFrame.src = ..Link("EnsPortal.CompileClass.cls", .tQuery)
	}
	Quit $$$OK
}

/// Check permissions
ClassMethod %OnBeforeCreatePage() As %Status
{
	Set tType = $get(%request.Data("TYPE",1))
	If $case(tType, "BPL": 0, "DTL": 0, "RecordMap": 0, : 1) Quit $$$ERROR($$$AccessDenied)
	Set tResource = "%Ens_" _ tType
	If '($system.Security.Check("%Ens_Code","WRITE") || $system.Security.Check(tResource, "WRITE")) {
		Quit $$$ERROR($$$AccessDenied)
	}
	Quit $$$OK
}

}
