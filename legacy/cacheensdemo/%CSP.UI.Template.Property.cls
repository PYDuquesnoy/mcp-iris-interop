/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// <p>This is the template for SMP pages where the Property pane is on the right side.
/// It contains css styles for using the SVG's tabBar and the propertyPane.</p>
Class %CSP.UI.Template.Property Extends %CSP.UI.Portal.Template [ Abstract, System = 4 ]
{

/// local namespace property. Set to $NAMESPACE is present.
Property NAMESPACE As %String;

/// If true, the property area is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

/// This Style block contains page-specific CSS style definitions.
XData CSS3Style
{
<style type="text/css">
body { font-size: 12px; }
/* light green for Explorer pages 
.ribbonTitle {
	background: #C5E5C9;
}*/
.svgFrame { border: none; }
/* note/message style*/
.note {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 11px;
	background: #F2F1EC;
	border: 1px solid #4D3926;
	color: #4D3926;
	padding: 10px;
	text-align: left;
	font-weight: bold;
}
/* additonal style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
.detailLabel {
	font-weight: bold;
	color: rgb(71,72,67);
	font-size: 10pt;
	margin: 10px;
}
#propertyTitle {
	height: 6px;
	width: 40px;
}
#propertyPane {
	position: relative;
	background: rgb(156,154,141);
	height: 449px;
	width: 350px;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	display: none;
}
/* styles for tabs */
#tabDetails,#tabTools {
	overflow: auto;
	padding-left: 3px;
	color: #404040;
}

td.tabGroupButtonOff:hover {
	color: #346c8d;
}

.tabGroupBody {
	background: #E0E0D0;
	width: 399px;
	min-height: 300px;
}

td.tabGroupButtonOn {
	height: 30px;
	color: #404040;
	background: #E0E0D0;
	font-size: 10pt;
}

td.tabGroupButtonOn {
	background: linear-gradient(top, #F8F8FF, #E0E0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	height: 30px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff {
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled {
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

.tabGroupGap {
	width: 0px;
}
#propertyTitle {
	height: 40px;
	width: 40px;
}
#spanArrow {
	padding-left: 10px;
	color: white;
	font-size: 20pt;
	text-shadow: black 1px 1px 1px;
}

</style>
}

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body { font-size: 12px; }
/* light green for Explorer pages 
.ribbonTitle {
	background: #C5E5C9;
}*/
.svgFrame { border: none; }
/* note/message style*/
.note {
	font-family: Arial, Helvetica, sans-serif;
	font-size: 11px;
	background: #F2F1EC;
	border: 1px solid #4D3926;
	color: #4D3926;
	padding: 10px;
	text-align: left;
	font-weight: bold;
}
/* additonal style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
.detailLabel {
	font-weight: bold;
	color: rgb(71,72,67);
	font-size: 10pt;
	margin: 10px;
}
#propertyTitle {
	height: 6px;
	width: 40px;
}
#propertyPane {
	position: relative;
	background: rgb(156,154,141);
	height: 449px;
	width: 350px;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	display: none;
}
/* styles for tabs */
#tabDetails,#tabTools {
	overflow: auto;
	padding-left: 3px;
	color: #404040;
}

td.tabGroupButtonOff:hover {
	color: #346c8d;
}

.tabGroupBody {
	background: #E0E0D0;
	width: 399px;
	min-height: 300px;
}

td.tabGroupButtonOn {
	height: 30px;
	color: #404040;
	background: #E0E0D0;
	font-size: 10pt;
}

td.tabGroupButtonOn:not([ie]) {
	background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#F8F8FF), color-stop(1.0,#E0E0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	height: 30px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff:not([ie]) {
	background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled:not([ie]) {
	background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

.tabGroupGap {
	width: 0px;
}
#propertyTitle {
	height: 40px;
	width: 40px;
}
#spanArrow {
	padding-left: 10px;
	color: white;
	font-size: 20pt;
	text-shadow: black 1px 1px 1px;
}

</style>
}

/// Toggle display of property pane.
ClientMethod toggleSettings() [ Language = javascript ]
{
	this.settingsExpanded = !this.settingsExpanded;
	this.showExpand();
	this.adjustSizes();
}

/// Note that this arrow is the opposite of search.
ClientMethod showExpand() [ Language = javascript ]
{
	var span = self.document.getElementById('spanArrow');
	if (this.settingsExpanded) {
		// right arrow - click to hide
		span.innerHTML = '&#187;';
		span.title = $$$Text("Hide the property box");
	}
	else {
		// left arrow - click to show
		span.innerHTML = '&#171;';
		span.title = $$$Text("Show the property box");
	}
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tNamespace = "?$NAMESPACE="_$G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_tNamespace))
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	#; If namespace has been "Switched" then make sure %session.Data is saved (same as %CSP.UI.Portla.Template.List).
	Set:$G(%request.Data("$NAMESPACE",1))'="" %session.Data("$NAMESPACE") = %request.Data("$NAMESPACE",1)
	Quit $$$OK
}

}
