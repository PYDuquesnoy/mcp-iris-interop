/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized page that displays an editor for a given
/// component property.<br>
/// This is used by ZEN utilities.
Class %ZEN.Dialog.componentValueEditor Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// Show Apply button.
Parameter APPLYBUTTON = 1;

/// Name of the property to be edited. Passed in via URL.
Property propertyName As %ZEN.Datatype.string(ZENURL = "property");

/// Name of the class that contains the property to be edited. Passed in via URL.
Property className As %ZEN.Datatype.string(ZENURL = "className");

/// Type of the property to be edited. Passed in via URL.
Property type As %ZEN.Datatype.string(ZENURL = "type");

/// Current value of the property to be edited. Passed in via URL.
Property value As %ZEN.Datatype.string(ZENURL = "value");

/// example of customized style sheet
XData Style
{
<style type="text/css">
#desc {
	border-top: 1px solid gray;
}

#help {
	font-style: italic;
	color: darkblue;
}

#sample {
	padding-top: 10px;
	padding-bottom: 10px;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup>
<spacer width="10" />
<form ondefault="zenPage.dialogFinish();" >
<vgroup id="mainGroup" labelPosition="left">
<spacer height="5" />
<vgroup id="controlGroup" labelPosition="left"/>
<spacer height="5" />
<html id="desc" OnDrawContent="%GetDescHTML"/>
</vgroup>
</form>
<spacer width="40" />
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Zen Value Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Set tName = $P(..className,".",$L(..className,"."))
	Set tProp = tName _ "." _ ..propertyName
	Quit "<b>"_$$$TextHTML("Property")_"</b>:&nbsp;"_$ZCVT(tProp,"O","HTML")
}

Method %OnAfterCreatePage() As %Status
{
	Set tClass = ..className

	#; work-around for IE issue
	Set:tClass="" tClass = $G(%request.Data("class",1))

	Set tProp = ..propertyName
	Set tRawType = ..type
	Set tValue = ..value

	Set group = ..%GetComponentById("controlGroup")

	Set tType = $P(tRawType,":",1)
	Set tTypeMod = $P(tRawType,":",2)
	Set tTypeMod2 = $P(tRawType,":",3)
	Set:tTypeMod2="" tTypeMod2=tTypeMod

	// add edit control and text to field set based on type
	// (type comes from the settings entry for this property)
	If (tType = "boolean") {
		Set ctrl = ##class(%ZEN.Component.checkbox).%New()
		Do group.%AddChild(ctrl)

		Set ctrl.id = "value"
		Set ctrl.caption = tProp
		Set ctrl.value = $S(tValue="true":1,tValue="false":0,1:+tValue)
	}
	ElseIf (tType = "enum") {
		#; insert "" choice
		Set tTypeMod = ","_tTypeMod
		Set tTypeMod2 = "("_$$$Text("empty")_"),"_tTypeMod2
		
		If ($L(tTypeMod,",") > 5) {
			Set ctrl = ##class(%ZEN.Component.combobox).%New()
			Do group.%AddChild(ctrl)
	
			Set ctrl.id = "value"
			Set ctrl.label = tProp_":"
			Set ctrl.value = tValue
			For n=1:1:$L(tTypeMod,",") {
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do ctrl.options.Insert(tOption)
				Do:$IsObject(%page) %page.%AddComponent(tOption)
				Set tOption.value=$P(tTypeMod,",",n)
				Set tOption.text=$P(tTypeMod2,",",n)
			}
		}
		Else {
			Set ctrl = ##class(%ZEN.Component.radioSet).%New()
			Do group.%AddChild(ctrl)
	
			Set ctrl.id = "value"
			Set ctrl.label = tProp_":"
			Set ctrl.value = tValue
			Set ctrl.valueList = tTypeMod
			Set ctrl.displayList = tTypeMod2
			Set ctrl.emptyCaption = "N/A"
		}
	}
	ElseIf (tType = "classMember") {
		#; convert member name to type
		Set tMbrType = $CASE(tTypeMod,"PROPERTY":$$$cCLASSproperty,"METHOD":$$$cCLASSmethod,"QUERY":$$$cCLASSquery,:$$$cCLASSproperty)

		Set ctrl = ##class(%ZEN.Component.dataCombo).%New()
		Do group.%AddChild(ctrl)

		Set ctrl.id = "value"
		Set ctrl.label = tProp_":"
		Set ctrl.value = tValue
		Set ctrl.editable = 1
		Set ctrl.queryClass = "%Dictionary.CompiledClass"
		Set ctrl.queryName = "MemberSummary"

		#; set up query parameters
		Set tParam = ##class(%ZEN.Auxiliary.parameter).%New()
		Set tParam.value = tClass
		Do ctrl.parameters.Insert(tParam)
		Do:$IsObject(%page) %page.%AddComponent(tParam)

		Set tParam = ##class(%ZEN.Auxiliary.parameter).%New()
		Set tParam.value = tMbrType
		Do ctrl.parameters.Insert(tParam)
		Do:$IsObject(%page) %page.%AddComponent(tParam)
	}
	ElseIf ((tType = "html")||(tType = "eventHandler")||(tType="csv")) {
		Set ctrl = ##class(%ZEN.Component.textarea).%New()
		Do group.%AddChild(ctrl)

		Set ctrl.id = "value"
		Set ctrl.label = tProp_":"
		Set ctrl.value = tValue
		Set ctrl.rows = 8
		Set ctrl.cols = 30
		If (tType = "html") {
			Set tHelp = $$$Text("Please enter HTML to display for this component.")
		}
		ElseIf (tType = "csv") {
			#; break up value into lines
			Set s = ""
			For n=1:1:$L(tValue,",") {
				Set s = s _ $P(tValue,",",n) _ $C(10)
			}
			Set ctrl.value = $E(s,1,$L(s)-1) // trim off last \n
			Set tHelp = $$$Text("Please enter one or more values, one item per line.")
		}
		Else {
			Set tHelp = $$$Text("Please enter a JavaScript expression.")
		}
	}
	ElseIf ((tType="style")||(tType="svgStyle")) {
		If (tType="svgStyle") {
			Set tHelp = $$$Text("Please enter one or more SVG CSS style declarations.")
			Set tContext = "SVG"
		}
		Else {
			Set tHelp = $$$Text("Please enter one or more HTML CSS style declarations.")
			Set tContext = "HTML"
		}

		#; style
		Set hg = ##class(%ZEN.Component.hgroup).%New()
		Set hg.cellVAlign = "bottom"
		Set hg.labelPosition = "left"
		Do group.%AddChild(hg)

		Set tc = ##class(%ZEN.Component.text).%New()
		Set tc.id = "value"
		Set tc.label = $$$Text("Value:")
		Set tc.value = tValue
		Set tc.size = 50
		Set tc.onchange = "zenPage.updateSample();"
		Set:(tContext="HTML") tc.onkeyup = "zenPage.updateSample();"

		Set btn = ##class(%ZEN.Component.button).%New()
		Set btn.caption = $$$Text("Edit")
		Set btn.onclick = "zenPage.editCSSValue('"_tContext_"','');"

		Do hg.%AddChild(tc)
		Do hg.%AddChild(btn)

		#; sample text
		If (tContext = "HTML") {
			Set sample = ##class(%ZEN.Component.html).%New()
			Set sample.id = "sample"
			Set tTitle = $$$Text("Sample showing effect of CSS style")
			Set sample.content = "<div title="""_tTitle_""" id=""sampleDiv"" style="""_$ZCVT(tValue,"O","HTML")_""">"_$$$Text("Sample")_"</div>"
			Do group.%AddChild(sample)
		}
	}
	Else {
		#; string etc.
		Set ctrl = ##class(%ZEN.Component.text).%New()
		Do group.%AddChild(ctrl)
		Set ctrl.id = "value"
		Set ctrl.label = $$$Text("Value:")
		Set ctrl.value = tValue
		If ((tType = "integer")||(tType = "length")||(tType = "float")) {
			Set ctrl.size = 5
		}
		Else {
			Set ctrl.size = 60
		}
		Set tHelp = $$$FormatText($$$Text("Please enter a value of type %1."),tType)
	}


	#; help message
	If ($G(tHelp) '= "") {
		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.height = 10
		Do group.%AddChild(spacer)

		Set help = ##class(%ZEN.Component.label).%New()
		Set help.id = "help"
		Set help.value = tHelp
		Do group.%AddChild(help)
	}

	Quit $$$OK
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Set tClass = ..className
	Set tProp = ..propertyName

	If ((tClass'= "")&&(tProp'="")) {
		Do ##class(%ZEN.Utils).%DrawPropertyDescription(tClass,tProp)
	}
	Quit $$$OK
}

/// Get the value to be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var ctrl = this.getComponentById('value');
	var value = ctrl.getValue();
	
	// see if we need to clean up user value
	switch (this.type) {
	case 'csv':
		var s = value.split('\n');
		// IE may insert \r into strings--take it out!
		for (var n =0; n < s.length; n++) {
			s[n] = s[n].replace(/\r/,'');
		}
		value = s.join(',');
		break;
	default:
		break;
	}

	return value;
}

/// Called when dialog is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	var ctrl = this.getComponentById('value');
	if (ctrl) {
		ctrl.focus();
		ctrl.select();
	}

	// clean up links to documatic
	var links = self.document.links;
	for (var n = 0; n < links.length; n++) {
		var href = links[n].href;
		if (-1 != href.indexOf('%CSP.Documatic')) {
			// change url & target of link
			var h = href.split('?');
			h[0] = '/csp/documatic/%25CSP.Documatic.cls';
			links[n].href = h.join('?');
			links[n].target = 'Documatic';
		}
	}
}

/// Update the style for the sample text.
ClientMethod updateSample() [ Language = javascript ]
{
	try {
		var sample = self.document.getElementById('sampleDiv');
		if (sample) {
			var text = zenPage.getComponentById('value');
			sample.style.cssText = text.getValue();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Launch the CSS Value Editor popup.
/// <var>context</var> is "HTML" or "SVG".
ClientMethod editCSSValue(context) [ Language = javascript ]
{
	var ctrl = this.getComponentById('value');
	var value = ctrl.getValue();

	var url = zenLink('%ZEN.Dialog.cssDeclarationEditor.cls?context=' + escape(context) + '&declaration=' + escape(value));
	zenLaunchPopupWindow(url,'CSSDeclarationEditor','resizable,width=500,height=700');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch (action) {
	case 'apply':
	case 'ok':
		var ctrl = this.getComponentById('value');
		if (ctrl) {
			ctrl.setValue(value);
		}
		zenPage.updateSample();
		break;
	}
}

}
