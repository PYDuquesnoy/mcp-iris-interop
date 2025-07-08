/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for pivot analysis types.
/// Subclasses of this are displayed as options in the Analysis dialog. 
Class %DeepSee.UI.Analysis.AbstractAnalysis Extends %ZEN.Component.page [ System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// Set this to false to prevent this analysis from being listed.
Parameter PUBLISHED As Boolean = 1;

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal";

Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property queryKey As %ZEN.Datatype.string(ZENURL = "KEY");

Property selectedRange As %ZEN.Datatype.string(ZENURL = "RANGE");

Property sortColumn As %ZEN.Datatype.integer(ZENURL = "SORTCOL") [ InitialExpression = 0 ];

Property sortDir As %ZEN.Datatype.string(ZENURL = "SORTDIR") [ InitialExpression = "ASC" ];

/// Measure to use for analysis.
Property measureName As %ZEN.Datatype.string(ZENURL = "MEASURE");

/// WITH clause for query
Property withClause As %ZEN.Datatype.string(ZENURL = "WITH");

/// Array of values to plot.
Property values As list Of %ZEN.Datatype.float;

/// Array of x axis labels.
Property xLabels As list Of %ZEN.Datatype.string;

/// Return an array of information about this analysis:<br/>
/// pInfo("caption") - localized caption for this item.<br/>
/// pInfo("tooltip") - localized tooltip for this item.<br/>
/// pInfo("icon") - icon for this item.<br/>
/// pInfo("rank") - optional rank; lower numbers are displayed first.<br/>
ClassMethod %GetAnalysisInfo(Output pInfo) As %Status
{
	Set pInfo("caption") = $$$Text("Abstract Analysis")
	Set pInfo("tooltip") = $$$Text("Display the Abstract Analysis chart")
	Set pInfo("icon") = ""
	Set pInfo("rank") = ""
	Quit $$$OK
}

XData Style
{
<style type="text/css">

body {
	background: #E0E0E0;
	font-family: arial, sans-serif;
}

#body {
	padding: 3px;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" >
<pane paneName="dialogBody" id="body" />
</page>
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Final, Language = javascript ]
{
	if (load && this.ondialogStart) {
		this.ondialogStart();
	}
	this.adjustSize();
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Abstract, Language = javascript ]
{
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
}

}
