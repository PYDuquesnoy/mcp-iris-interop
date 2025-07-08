/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user edit or add Format String for measure definition.
Class %DeepSee.UI.Dialog.FormatString Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

Property measureName As %ZEN.Datatype.string(ZENURL = "ELEMENT");

Property formatString As %ZEN.Datatype.string(ZENURL = "VALUE");

Property msgCube As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please enter a Cube Name.")} ];

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
<label id="measureName" label="Measure name:" enclosingClass="zenLabel"/>
</vgroup>
<label label="Enter a Format string and optional color for each piece below." enclosingStyle="padding:2px;" hint="Base units: [#], [#,#], [#.##], [#,#.##]"/>

<fieldSet legend="Positive piece" >
<hgroup>
<text id="Format1" label="Format string" onchange="zenPage.showExample(zenThis.getValue(),'1');"/>
<text id="Style1" label="Color" size="40" onchange="zenPage.showStyle(zenThis.getValue(),'1');"/>
</hgroup>
<hgroup labelPosition="left">
<label id="Example1" enclosingClass="zenLabelDisabled" />
</hgroup>
</fieldSet>
<fieldSet legend="Negative piece" >
<hgroup>
<text id="Format2" label="Format string" onchange="zenPage.showExample(zenThis.getValue(),'2');"/>
<text id="Style2" label="Color" size="40" onchange="zenPage.showStyle(zenThis.getValue(),'2');" />
</hgroup>
<label id="Example2" enclosingClass="zenLabelDisabled" />
</fieldSet>
<fieldSet legend="Zero piece" >
<hgroup>
<text id="Format3" label="Format string" onchange="zenPage.showExample(zenThis.getValue(),'3');"/>
<text id="Style3" label="Color" size="40" onchange="zenPage.showStyle(zenThis.getValue(),'3');" />
</hgroup>
<label id="Example3" enclosingClass="zenLabelDisabled" />
</fieldSet>
<fieldSet legend="Missing piece" >
<hgroup>
<text id="Format4" label="Format string" onchange="zenPage.showExample(zenThis.getValue(),'4');"/>
<text id="Style4" label="Color" size="40" onchange="zenPage.showStyle(zenThis.getValue(),'4');" />
</hgroup>
<label id="Example4" enclosingClass="zenLabelDisabled" />
</fieldSet>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Format String")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Edit format string for Architect.")
}

/// Value returned is delimited first by "^" then by ";". The first piece of "^" is the String value, the second piece is the Color value.<br>
/// The String values and Color values are each delimited by ";".
ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		var values = ""
		for (var m=1;m<5;m++) values = values + zen("Format"+m).getValue()+";";
		if (values == ";;;;") values = "";
		var stylevalues = "";
		var hasStyle = 0;
		var svalue;
		for (var m=1;m<5;m++) {
			svalue = zen("Style"+m).getValue();
			if (svalue != "") hasStyle = 1;
			stylevalues = stylevalues + svalue+";";
		}
		if (hasStyle == 1) {
			values = values + "^" + stylevalues;
		}
		return encodeURIComponent(values);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return '';
}

/// Apply a format string value to the associated example
ClientMethod showExample(value, id) As %Boolean [ Language = javascript ]
{
	try {
		id = "Example" + id;
		var example = "";
		if (value != "") {
			example = this.GetDisplayValue(value);
		}
		zen(id).setValue(example);		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Apply a style value to the associated example
ClientMethod showStyle(value, id) As %Boolean [ Language = javascript ]
{
	try {
		id = "Example" + id;
		zen(id).setProperty("enclosingStyle",(value=='') ? '' : 'color:'+value+';');	
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%GetComponentById("cubeName").value = ..cubeName
		Set ..%GetComponentById("measureName").value = ..measureName
		If (..measureName="") {
			Set ..%GetComponentById("measureName").hidden = 1
		}

		Set format = $P(..formatString,"^",1)
		Set style = $P(..formatString,"^",2)
		For m = 1:1:4 Set format(m) = $P(format,";",m),style(m) = $P(style,";",m)
		// Set format and color values
		For m = 1:1:4 Set ..%GetComponentById("Format"_m).value = format(m),..%GetComponentById("Style"_m).value = style(m)
		// Set examples
		For m = 1:1:4 If format(m) '= "" Set ..%GetComponentById("Example"_m).value = ..GetDisplayValue(format(m)),..%GetComponentById("Example"_m).enclosingStyle="color:"_style(m)  // WAL060 -- add "color"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return example display value given user entered format string.
ClassMethod GetDisplayValue(format As %String) As %String [ ZenMethod ]
{
	Set Example = "1234567"
	Quit ##class(%DeepSee.ResultSet).%FormatNumber(Example,format)
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
}

}
