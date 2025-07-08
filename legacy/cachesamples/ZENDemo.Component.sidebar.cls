/// Example of a custom component.<br>
/// This displays a standard side bar for pages within the Demo application.
Class ZENDemo.Component.sidebar Extends %ZEN.Component.component [ System = 4 ]
{

/// XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zendemo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDemo";

/// Main text displayed within this pane.
Property text As %ZEN.Datatype.caption;

/// List of bullet point objects.
/// Each object defines a bullet point to be displayed within the sidebar. 
Property bullets As list Of bullet(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
.demoSidebar {
	color: black;
	width: 200px;
	height: 500px;
	padding: 10px;
	font-size: 0.8em;
	font-family: verdana;
	overflow: auto;
}

.demoSidebar ul {
	margin-left: 8px;
	padding-left: 8px;
}

.demoSidebar ul li {
	padding-bottom: 3px;
}

</style>
}

/// Draw the HTML contents of this component.
Method %DrawHTML()
{
	&html<<div class="demoSidebar">>
	Write $ZCVT(..text,"O","HTML")

	#; bullets
	Set tCount = ..bullets.Count()
	If (tCount > 0) {
		&html<<ul>>
		For n = 1:1:tCount {
			Set tBullet = ..bullets.GetAt(n)
			If (tBullet.image '= "") {
				&html<<div><img src="#(tBullet.image)#" title="#($ZCVT(tBullet.text,"O","HTML"))#"/></div>>
			}
			Else {
				&html<<li>#($ZCVT(tBullet.text,"O","HTML"))#</li>>
			}
		}
		&html<</ul>>
	}
	&html<</div>>
}

}

