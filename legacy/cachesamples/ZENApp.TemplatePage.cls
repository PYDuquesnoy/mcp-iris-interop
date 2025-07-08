/// ZENApp.TemplatePage
/// This a template page that provides a standard
/// template for subclasses within the HelpDesk application
Class ZENApp.TemplatePage Extends %ZEN.Component.page [ Abstract ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENApp.SampleApp";

/// Displayed name of this page.
Parameter PAGENAME = "TemplatePage";

/// Domain used for localization.
/// Parameter DOMAIN = "";
/// Define the title that will be displayed within subclasses
Property StdTitle As %ZEN.Datatype.string [ InitialExpression = {..#PAGENAME} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* default styles */
body {
	background: #C0C0EE;
	font-family: verdana;
}

table.helpDeskTitle {
	color: black;
	background: #c5d6d6;
	width: 100%;
	padding: 0px;
	margin: 0px;
	border-bottom: 1px solid darkblue;
	font-size: 1.4em;
	font-family: verdana;
	text-align: center;
}

</style>
}

/// This XML block defines the contents of this page.
/// There are 4 main panes defined for the standard page:
/// menu	table
/// message	details
/// The contents of these panes are provided by subclasses.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page title="HelpDesk">
<html OnDrawContent="DrawTitle"/>

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Sample App" title="Sample App" />
</locatorBar>

<hgroup>
<vgroup valign="top">
<pane paneName="menuPane"/>
<spacer height="20"/>
<pane paneName="messagePane"/>
</vgroup>
<spacer width="20"/>
<vgroup width="100%" valign="top">
<pane paneName="tablePane"/>
<spacer height="20"/>
<pane paneName="detailPane"/>
</vgroup>
</hgroup>
</page>
}

/// Draw HTML for the page title
Method DrawTitle(pSeed As %String) As %Status
{
	#; Whatever HTML we render here will be used as the title bar
	&html<<table class="helpDeskTitle" border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left" width="40"><img width="185" height="60" src="images/zentitle.jpg"/></td>
		<td align="center" width="90%">
		<div style="font-size: 0.6em;">Zen Sample Application</div>
		<div>#($ZCVT(..#PAGENAME,"O","HTML"))#</div></td>
		<td>&nbsp;</td></tr></table>>

	Quit $$$OK
}

}

