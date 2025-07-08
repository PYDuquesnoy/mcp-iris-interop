/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized page that displays an editor CSS declaration.<br>
/// This is used by ZEN utilities.
Class %ZEN.Dialog.cssValueEditor Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// Show Apply button.
Parameter APPLYBUTTON = 1;

/// What type of CSS declaration: "HTML" or "SVG". Passed in via URL.
Property context As %ZEN.Datatype.string(ZENURL = "context");

/// CSS property being edited. Passed in via URL.
Property property As %ZEN.Datatype.string(ZENURL = "property");

/// CSS value being edited. Passed in via URL.
Property value As %ZEN.Datatype.string(ZENURL = "value");

/// Client-side variable indicating what type of value we are editing.
Property cssType As %ZEN.Datatype.string;

/// example of customized style sheet
XData Style
{
<style type="text/css">
</style>
}

/// Main body of dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<vgroup id="fieldSet" labelPosition="left">
<spacer height="5" />
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("Edit the value of this CSS style property using the form below."),"<br/>"
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("CSS Value Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit "<b>"_$$$TextHTML("Property")_"</b>:&nbsp;"_$ZCVT(..property,"O","HTML")
}

Method %OnAfterCreatePage() As %Status
{
	#; stock list of colors
	Set tColorList = "black,blue,darkblue,darkgreen,darkred,gray,green,orange,plum,purple,red,silver,teal,yellow,white,transparent,inherit"

	#; for SVG throw in some good gradients
	If (..context = "SVG") {
		Set tColorList = tColorList _ ",url(#glow-blue),url(#glow-blueHz),url(#glow-blueDiag),url(#glow-green),url(#glow-greenHz),url(#glow-greenDiag),url(#glow-orange),url(#glow-orangeHz),url(#glow-orangeDiag),url(#glow-purple),url(#glow-purpleHz),url(#glow-purpleDiag),url(#glow-red),url(#glow-redHz),url(#glow-redDiag),url(#glow-silver),url(#glow-silverHz),url(#glow-silverDiag),url(#glow-teal),url(#glow-tealHz),url(#glow-tealDiag),url(#glow-yellow),url(#glow-yellowHz),url(#glow-yellowDiag)"
	}

	Set tGroup = ..%GetComponentById("fieldSet")
	Set ctrl = ..%GetComponentById("value")
	Set tHelp = ""

	#; get info on CSS property
	Set tInfo = ""
	If (..property '= "") {
		Do ##class(%ZEN.Dialog.cssDeclarationEditor).GetCSSPropertyList(..context,.list)
		Set tInfo = $G(list(..property))
	}

	#; info is a list in the form: a|b|c, break it apart
	#; there may be a directive in the list: <border>|b|c (if more than one, concatenate)
	Set tCount = 0
	Set tDirective = ""
	For n = 1:1:$L(tInfo,"|") {
		Set tItem = $P(tInfo,"|",n)
		
		If ($E(tItem) = "<") {
			#; directive, not a value
			Set tDirective = tDirective _ $S(tDirective="":"",1:",") _ $E(tItem,2,$L(tItem)-1)
		}
		ElseIf(tItem '= "") {
			Set tCount = tCount + 1 
			Set tOptions(tCount) = tItem
		}
	}

	#; Create controls based on what kind of options/directives there are
	#; special controls based on directive
	If (tDirective = "border") {
		#; border box
		Set ..cssType = tDirective
		
		Set tBorderWidthList = "thin,medium,thick,1px,2px,3px,4px,inherit"
		Set tBorderStyleList = "none,hidden,dotted,dashed,solid,double,groove,ridge,inset,outset,inherit"
		
		Set tValue = $S((..value="")||(..value="***"):"1px solid black",1:$ZSTRIP(..value,"<>W"))
		
		#; split value and make a guess about which part is which
		For n=1:1:3 {
			Set tPart(n) = $P(tValue," ",n)
		}

		If ((tBorderWidthList [ tPart(1))||(+tPart(1)>0)) {
			#; width first
			If (tBorderStyleList [ tPart(2)) {
				#; style second
				Set tBorderWidth = tPart(1),tBorderStyle = tPart(2),tBorderColor = tPart(3)
			}
			Else {
				Set tBorderWidth = tPart(1),tBorderStyle = tPart(3),tBorderColor = tPart(2)
			}
		}
		ElseIf ((tBorderWidthList [ tPart(2))||(+tPart(2)>0)) {
			#; width second
			If (tBorderStyleList [ tPart(1)) {
				#; style first
				Set tBorderWidth = tPart(2),tBorderStyle = tPart(1),tBorderColor = tPart(3)
			}
			Else {
				Set tBorderWidth = tPart(2),tBorderStyle = tPart(3),tBorderColor = tPart(1)
			}
		}
		ElseIf ((tBorderWidthList [ tPart(3))||(+tPart(3)>0)) {
			#; width third
			If (tBorderStyleList [ tPart(1)) {
				#; style first
				Set tBorderWidth = tPart(3),tBorderStyle = tPart(1),tBorderColor = tPart(2)
			}
			Else {
				Set tBorderWidth = tPart(3),tBorderStyle = tPart(2),tBorderColor = tPart(1)
			}
		}
		Else {
			Set tBorderWidth = tPart(1),tBorderStyle = tPart(2),tBorderColor = tPart(3)
		}

		Set ctrl = ##class(%ZEN.Component.combobox).%New()
		Set ctrl.id = "borderWidth"
		Set ctrl.valueList = tBorderWidthList
		Set ctrl.label = $$$Text("Border width:")
		Set ctrl.value = tBorderWidth
		Do tGroup.%AddChild(ctrl)

		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.height = 10
		Do tGroup.%AddChild(spacer)

		Set ctrl = ##class(%ZEN.Component.combobox).%New()
		Set ctrl.id = "borderStyle"
		Set ctrl.valueList = tBorderStyleList
		Set ctrl.label = $$$Text("Border style:")
		Set ctrl.value = tBorderStyle
		Do tGroup.%AddChild(ctrl)

		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.height = 10
		Do tGroup.%AddChild(spacer)

		Set hgroup = ##class(%ZEN.Component.hgroup).%New()
		Set hgroup.cellVAlign = "bottom"
		Set hgroup.label = $$$Text("Border color:")
		Do tGroup.%AddChild(hgroup)

		Set ctrl = ##class(%ZEN.Component.combobox).%New()
		Set ctrl.id = "borderColor"
		Set ctrl.size = 20
		Set ctrl.editable = 1
		Set ctrl.unrestricted = 1
		Set ctrl.valueList = tColorList
		Set ctrl.value = tBorderColor
		Do hgroup.%AddChild(ctrl)

		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.width = 5
		Do hgroup.%AddChild(spacer)

		Set ctrl = ##class(%ZEN.Component.button).%New()
		Set ctrl.id = "btnColor"
		Set ctrl.caption = $$$Text("Browse...")
		Set ctrl.onclick = "zenPage.editColorValue('borderColor');"
		Do hgroup.%AddChild(ctrl)
	}
	ElseIf (tDirective = "color") {
		Set ..cssType = tDirective
		
		Set tValue = ..value

		Set hgroup = ##class(%ZEN.Component.hgroup).%New()
		Set hgroup.cellVAlign = "bottom"
		Set hgroup.label = $$$Text("Color:")
		Do tGroup.%AddChild(hgroup)

		Set ctrl = ##class(%ZEN.Component.combobox).%New()
		Set ctrl.id = "value"
		Set ctrl.size = 20
		Set ctrl.editable = 1
		Set ctrl.unrestricted = 1
		Set ctrl.valueList = tColorList
		Set ctrl.value = $P(tValue," ",3)
		Do hgroup.%AddChild(ctrl)

		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.width = 5
		Do hgroup.%AddChild(spacer)

		Set ctrl = ##class(%ZEN.Component.button).%New()
		Set ctrl.id = "btnColor"
		Set ctrl.caption = $$$Text("Browse...")
		Set ctrl.onclick = "zenPage.editColorValue('value');"
		Do hgroup.%AddChild(ctrl)
	}
	ElseIf (tDirective = "length") {
		Set ..cssType = tDirective
		
		Set tValue = ..value
		Set tSize = +tValue
		Set tUnits = $S(tValue["px":"px",tValue["%":"%",tValue["em":"em",tValue["pt":"pt",1:"")

		Set ctrl = ##class(%ZEN.Component.text).%New()
		Set ctrl.id = "value"
		Set ctrl.size = 10
		Set ctrl.label = $$$Text("Value:")
		Set ctrl.value = tSize
		Do tGroup.%AddChild(ctrl)

		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.height = 5
		Do tGroup.%AddChild(spacer)

		Set ctrl = ##class(%ZEN.Component.radioSet).%New()
		Set ctrl.id = "units"
		Set ctrl.valueList = ",%,em,pt,px"
		Set ctrl.label = $$$Text("Units:")
		Set ctrl.value = tUnits
		Do tGroup.%AddChild(ctrl)
	}
	ElseIf (tDirective = "family-name") {
		Set ..cssType = tDirective
		Set tFontList = "arial,courier,verdana,inherit"

		Set tValue = ..value

		Set ctrl = ##class(%ZEN.Component.combobox).%New()
		Set ctrl.id = "value"
		Set ctrl.size = 20
		Set ctrl.label = $$$Text("Font family:")
		Set ctrl.editable = 1
		Set ctrl.unrestricted = 1
		Set ctrl.valueList = tFontList
		Set ctrl.value = $P(tValue," ",3)
		Do tGroup.%AddChild(ctrl)
	}
	Else {
		If (tDirective '= "") {
			For n = 1:1:$L(tDirective,",") {
				Set tHelp = "<li>"_$P(tDirective,",",n)_"</li>"
			}
		}

		If (tCount > 0) {
			#; option list
			Set ctrl = ##class(%ZEN.Component.combobox).%New()
			Set ctrl.id = "value"
			Set ctrl.size = 40
			Set ctrl.label = $$$Text("Value:")
			Set ctrl.editable = 1
			Set ctrl.unrestricted = 1
			Set ctrl.value = ..value
			Do tGroup.%AddChild(ctrl)

			#; create options

			#; Add empty value to list of options
			Set tOption = ##class(%ZEN.Auxiliary.option).%New()
			Do ctrl.options.Insert(tOption)
			Do:$IsObject(%page) %page.%AddComponent(tOption)
			Set tOption.value = ""
			Set tOption.text = ""
			For n=1:1:tCount {
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do ctrl.options.Insert(tOption)
				Do:$IsObject(%page) %page.%AddComponent(tOption)
				Set tOption.value = tOptions(n)
				Set tOption.text = tOptions(n)
			}
		}
		Else {
			#; simple text box
			Set ctrl = ##class(%ZEN.Component.text).%New()
			Set ctrl.id = "value"
			Set ctrl.size = 40
			Set ctrl.label = $$$Text("Value:")
			Set ctrl.value = ..value
			Do tGroup.%AddChild(ctrl)
		}
	}
	
	#; help message!!!
	If ($G(tHelp) '= "") {
		Set spacer = ##class(%ZEN.Component.spacer).%New()
		Set spacer.height = 10
		Do tGroup.%AddChild(spacer)

		Set help = ##class(%ZEN.Component.html).%New()
		Set help.id = "help"
		Set help.content = $$$Text("You can also provide a CSS value of the following type:") _ "<ul>"_tHelp_"</ul>"
		Do tGroup.%AddChild(help)
	}

	Quit $$$OK
}

/// Return the value that should be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var ret = '';

	// convert current options back into CSS declaration
	switch(this.cssType) {
	case 'length':
		ret = zenPage.getComponentById('value').getValue() + 
			zenPage.getComponentById('units').getValue();
		break;
	case 'border':
		ret = zenPage.getComponentById('borderWidth').getValue() + ' ' +
			zenPage.getComponentById('borderStyle').getValue() + ' ' +
			zenPage.getComponentById('borderColor').getValue();
		break;
	default:
		ret = zenPage.getComponentById('value').getValue();
		break;
	}
	return ret;
}

/// Launch the Color Value Editor popup.
/// <var>ctrlId</var> is control to place value in.
ClientMethod editColorValue(ctrlId) [ Language = javascript ]
{
	var url = zenLink('%ZEN.Dialog.colorSelect.cls');
	zenPage._controlId = ctrlId;
	zenLaunchPopupWindow(url,'ColorEditor','resizable,top=100,width=500,height=700');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch (action) {
	case 'ok':
	case 'apply':
		var ctrl = this.getComponentById(zenPage._controlId);
		if (ctrl) {
			ctrl.setValue(value);
		}
		if ('apply' == action) {
			// cascade
			this.btnApply();
		}
		break;
	}
}

/// This client event, if present, is fired when the dialog is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	var ctrl = this.getComponentById('value');
	if (ctrl) {
		ctrl.focus();
		ctrl.select();
	}
}

}
