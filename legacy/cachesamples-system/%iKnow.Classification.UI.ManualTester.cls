/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

Class %iKnow.Classification.UI.ManualTester Extends (%ZEN.Component.page, TestUtils) [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%iKnow";

Parameter AUTONS = 1;

Property classifier As %ZEN.Datatype.string(ZENURL = "CLASSIFIER");

Property text As %ZEN.Datatype.string;

Property config As %ZEN.Datatype.string(ZENURL = "CONFIG") [ InitialExpression = {$$$DEFAULTCONFIG} ];

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page title="Text Categorization test page" width="100%">
<vgroup width="400" align="center">
<vgroup id="grpInput">
<titleBox title="Text input" />
<spacer height="10" />
<textarea id="txtText" rows="10" cols="50" />
<spacer height="10" />
<hgroup labelPosition="left" width="100%">
<button caption="Categorize!" onclick="zenPage.categorize();" align="left" />
<spacer width="20" />
<link caption="configure" style="font-size: 12px; color: #999999" align="right"
onclick="zenThis.setProperty('hidden',true);zen('selConfig').setProperty('hidden',false);return false;" />
<select id="selConfig" hidden="1" sql="SELECT Name FROM %iKnow.Configuration" align="right" emptyText="-- select a configuration --" />
</hgroup>
</vgroup>
<vgroup id="grpResults" hidden="true">
<titleBox id="ttlResults" title="Text Categorization results" />
<spacer height="10" />
<pane paneName="textInputDetails" />
<spacer height="10" />
<link caption="reset" onclick="zenPage.reset();" align="right" style="font-size: 12px; color: #999999" />
</vgroup>
</vgroup>
</page>
}

ClientMethod reset() [ Language = javascript ]
{
	zen('grpInput').setProperty('hidden', false);
	zen('grpResults').setProperty('hidden', true);
}

ClientMethod categorize() [ Language = javascript ]
{
	var sc = zenPage.setProperty('text', zen('txtText').getValue());
	zen('grpInput').setProperty('hidden', true);
	zen('grpResults').setProperty('hidden', false);
	
	zenPage.refreshDetails();
	/*zen('htmlText').refreshContents();
	zen('htmlCategories').refreshContents();
	sc = zen('htmlTrace').setProperty('seed', '');
	zen('htmlTrace').refreshContents();*/
}

Method GetClassifierClass() As %String [ Private ]
{
	quit ..classifier
}

Method GetDetailInput(Output pText As %String, Output pConfig As %String, Output pDomainId As %Integer, Output pSrcId As %Integer) As %Status [ Private ]
{
	set pText = ..text
	set pConfig = ..config
	set pSrcId = 0, pDomainId = 0
	quit $$$OK
}

/// Default style for Zen pages
XData Style
{
<style type="text/css">

body {
	margin: 30px;
	font-family: Arial;
}
.tabGroupBody {
	padding: 10px;
	min-height: 0px;
}

.highlightedTextPane {
	background-color: white;
	overflow-y: scroll;
	height: 250px;
	width: 400px;
}

span.highlightedTerm {
	background-color: #ccccff; 
	border: 1px solid #ccccff; 
	border-left: 2px solid #ccccff; 
	border-right: 2px solid #ccccff; 
	padding-left: 1px; 
	padding-right: 1px;
}

</style>
}

Method %OnAfterCreatePage() As %Status
{
	quit ..%OnAfterCreateDetailPane()
}

}
