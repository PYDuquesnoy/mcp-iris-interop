/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility dialog window displays a search page.
/// The results of an SQL query are displayed and the user can make a selection.
Class %ZEN.Dialog.searchDialog Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter AUTONS = 1;

/// No Apply button.
Parameter APPLYBUTTON = 0;

/// SQL statement used to populate the search form.
/// This cannot be passed in via URL; instead applications should subclass this
/// component and provide the search query using server-side logic.
Property query As %ZEN.Datatype.sql;

/// List names to display for parameters in the search form.
Property paramNames As %ZEN.Datatype.csv(ZENURL = "paramNames");

/// Number of parameters in the current query.
Property paramCount As %ZEN.Datatype.integer(ZENSETTING = 0);

XData Style
{
<style type="text/css">
/* div around table */
#resultsTable {
	width: 500px;
}

/* Main table for tablePane */
#resultsTable .tpTable {
	table-layout: auto;
	width: 100%;
}

/* Column header. */
table.tpTable th {
	background: #C5D6D6;
}


</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup>
<html id="desc" OnDrawContent="%GetDescHTML"/>
<vgroup id="searchParms" labelPosition="left" />
<spacer height="5"/>
<tablePane id="resultsTable" 
	fixedHeaders="true"
	bodyHeight="400px"
	useSnapshot="false"
	showZebra="true"
	showFilters="true"
	maxRows="10000"
	pageSize="1000"
	initialExecute="false"
	ondblclick="zenPage.dialogFinish();"
	useKeys="true"/>
<tableNavigatorBar tablePaneId="resultsTable" width="100%"/>
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Search Dialog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select an item from the list below.")
}

/// Set up the table pane.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Set tSQL = ..query
	Set tValueCol = "ID"

	#; set up table pane
	Set tTable = ..%GetComponentById("resultsTable")
	Set tTable.sql = tSQL
	Set tTable.valueColumn = tValueCol

	If (tSQL '= "") {
		#; create search form
		Set tGroup = ..%GetComponentById("searchParms")
	
		#; parms for table
		#Dim tRS As %ResultSet
		Set tRS = ##class(%ResultSet).%New()
		Set tSC = tRS.Prepare(tSQL)
		If $$$ISERR(tSC) Quit tSC
	
		Set tParamCount = tRS.GetParamCount()
		Set ..paramCount = tParamCount
		For n=1:1:tParamCount {
			Set tParm = tTable.%AddParameter()
			Set tParm.value = ""
			Set tParm.id = "parm"_n
	
			Set tCtrl = ##class(%ZEN.Component.text).%New()
			Do tGroup.%AddChild(tCtrl)
			Set tCtrl.id = "ctrl"_n
			Set tCtrl.label = $P(..paramNames,",",n)
			Set tCtrl.value = ""
		}

		Set tCtrl = ##class(%ZEN.Component.button).%New()
		Do tGroup.%AddChild(tCtrl)
		Set tCtrl.id = "searchButton"
		Set tCtrl.caption = $$$Text("Search")
		Set tCtrl.onclick = "zenPage.execSearch();"
	}

	Quit tSC
}

/// Return the value that should be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var table = zenPage.getComponentById('resultsTable');
	return table.getValue();
}

/// User has pressed the search button.
ClientMethod execSearch() [ Language = javascript ]
{
	var table = zenPage.getComponentById('resultsTable');

	// Get parameter values
	for (var n = 1; n <= this.paramCount; n++) { 
		var ctrl = zenPage.getComponentById('ctrl' + n);
		var parm = zenPage.getComponentById('parm' + n);
		if (ctrl && parm) {
			parm.setProperty('value',ctrl.getValue());
		}
	}
	table.executeQuery();
}

}
