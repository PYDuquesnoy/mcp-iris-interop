/// Example of a custom component.<br>
/// This displays a standard title bar for pages within the Demo application.
Class ZENDemo.Component.demoTitle Extends %ZEN.Component.component [ System = 4 ]
{

/// XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zendemo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDemo";

/// Title displayed within this pane.
Property title As %ZEN.Datatype.caption;

/// Category displayed within this pane (above the title).
Property category As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Zen Demonstration")} ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
.demoTitle {
	color: black;
	background: #c5d6d6;
	background-image: url(images/titlegradient.png);
	background-repeat: repeat-y;
	background-position: right;
	width: 100%;
	padding: 0px;
	border-bottom: 1px solid darkblue;
	font-size: 1.4em;
	font-family: verdana;
	text-align: center;
}
</style>
}

/// Draw the HTML contents of this component.
Method %DrawHTML()
{
	Set tCategory = ..category

	#; show which server we are connected to
	Set tInstance = $P($ZU(86),"*",2)

	&html<<table class="demoTitle" border="0" cellpadding="0" cellspacing="0" width="100%">
		<tr>
		<td align="left" width="40px"><img width="185px" height="60px" src="images/zentitle.jpg"/></td>
		<td align="left" width="90%" style="padding-left:20px;">
		<div style="font-size: 0.6em;">#($ZCVT(tCategory,"O","HTML"))#</div>
		<div>#($ZCVT(..title,"O","HTML"))#</div></td>
		<td style="text-align: right; vertical-align: middle;">
		<table border="0" style="font-size: 0.6em;">
		<tr><td align="right">#($$$Text("User"))#:</td><td align="left"><b>#($UserName)#</b>&nbsp;</td></tr>
		<tr><td align="right">#($$$Text("Server"))#:</td><td align="left"><b>#(tInstance)#</b>&nbsp;</td></tr>
		</table>
		</td></tr></table>>
}

}

