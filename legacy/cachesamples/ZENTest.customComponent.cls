/// Simple component used for testing custom components.
Class ZENTest.customComponent Extends %ZEN.Component.control [ System = 4 ]
{

/// This is the XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zentest";

/// This message is displayed within the custom component.
Property message As %ZEN.Datatype.caption [ InitialExpression = "Custom Component" ];

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// The %DrawHTML method draws the initial HTML for this component.
Method %DrawHTML()
{
	#; write out HTML-escaped message.
	&html<#($ZCVT(..message,"O","HTML"))#>

 	#; test of error detection:
 	#; we are not allowed to create component once HTML rendering has started
	/*
	Set btn = ##class(%ZEN.Component.button).%New()
	Set btn.caption = "Not allowed"
	Do %page.%AddChild(btn)
	*/
}

}

