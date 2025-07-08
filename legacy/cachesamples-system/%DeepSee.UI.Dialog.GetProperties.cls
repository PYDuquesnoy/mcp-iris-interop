/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user add or edit a list for definition.<br>
/// An existing list (delimited by comma) may be passed in.
Class %DeepSee.UI.Dialog.GetProperties Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property ELEMENT As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property Expression As %ZEN.Datatype.string(ZENURL = "VALUE");

Property WHAT As %ZEN.Datatype.string(ZENURL = "WHAT");

Property dataSource As %ZEN.Datatype.string(ZENURL = "DATASOURCE");

Property itemNumber As %ZEN.Datatype.integer [ InitialExpression = "1" ];

Property msgHasEmpty As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("There is at least one empty field. Proceed?")} ];

Property lblProperty As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Enter a data source Property:")} ];

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup labelPosition="left">
<label id="cubeName" label="Cube name:" enclosingClass="zenLabel"/>
<label id="ELEMENT" label="Element name:" enclosingClass="zenLabel"/>
</vgroup>
<label id="titleText" label="Select a property from the tree below:" enclosingStyle="padding:2px;"/>
<dynaTree id="dataSource" 
 imageContracted="images/disclosure-contracted.gif"
 imageExpanded="images/disclosure-expanded.gif"
 imageNode="images/spacer.gif"
 ondblclick="zenPage.dialogFinish();"
	showLines="false" showFolders="false" dragEnabled="true" 
	OnGetTreeInfo="GetDataSourceInfo">
<parameter id="sourceP1" paramName="dataSource" value="#(%page.dataSource)#" />
</dynaTree>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set value = $$$TextHTML("Unknown")
	If ..WHAT = "MemberList" Set value = $$$TextHTML("Member List")
	Else  If ..WHAT [ "Source" Set value = $$$TextHTML("Data Source Property")
	Else  If ..WHAT [ "ListingField" Set value = $$$TextHTML("Listing Field") // JSL4436
	Quit value
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Set value = ""
	If ..WHAT [ "Source" Set value = $$$TextHTML("Select data source property for Architect.")
	If ..WHAT [ "ListingField" Set value = $$$TextHTML("Select data source property for Architect.") // JSL4436
	Quit value
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	try {	
		var values = zen('dataSource').getValue();
		if (this.WHAT && this.WHAT.toString().indexOf('ListingField')>=0) {
			values=this.transformToSQLExpression(values);
		}
		return encodeURIComponent(values);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

ClientMethod transformToSQLExpression(expr) [ Language = javascript ]
{
	// current implementation is a hack, does not take care of delimited identifiers
	components = expr.split(".");
	return components.join("->")
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var isok = true;
		var hasEmpty = 0;
		if (zen("dataSource").getValue()=="") hasEmpty=1;
		if (hasEmpty == 1) {
			if (confirm(this.msgHasEmpty)== false) {
				isok = false;
			}
		}

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return isok;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("ELEMENT").value = ..ELEMENT
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide contents of the data source tree.
ClassMethod GetDataSourceInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Set tDataSource = $G(pParms("dataSource"))
	If (tDataSource '= "") {
		If $$$comClassDefined(tDataSource) {
			Set tSC = ##class(%DeepSee.Utils).%GetDataSourceTree(tDataSource,.pTree,,,,pRoot)
		}
	}
	Quit tSC
}

}
