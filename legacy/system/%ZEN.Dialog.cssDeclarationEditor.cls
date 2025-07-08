/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized page that displays a CSS declaration editor.<br>
/// This is used by ZEN utilities.
Class %ZEN.Dialog.cssDeclarationEditor Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// Show Apply button.
Parameter APPLYBUTTON = 1;

/// What type of CSS declaration: "HTML" or "SVG". Passed in via URL.
Property context As %ZEN.Datatype.string(ZENURL = "context");

/// Selector for the CSS declaration. Passed in via URL.
Property selector As %ZEN.Datatype.string(ZENURL = "selector");

/// Initial value of the CSS declaration. Passed in via URL.
Property declaration As %ZEN.Datatype.string(ZENURL = "declaration");

/// True if result should formatted as multi-line text. Passed in via URL.
Property multiLine As %ZEN.Datatype.boolean(ZENURL = "multiLine") [ InitialExpression = 0 ];

/// Localized message for missing property.
Property msgMissingProp As %ZEN.Datatype.caption [ InitialExpression = "Please enter a property value." ];

/// example of customized style sheet
XData Style
{
<style type="text/css">
</style>
}

/// Contents of this dialog pane:
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup id="mainGroup">
<spacer width="10" />
<vgroup id="fieldSet" labelPosition="top">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<spacer height="5" />
<listBox id="declarations" label="CSS Declarations:" 
	listHeight="150px"
	onchange="zenPage.changeDeclaration(zenThis);"/>
<spacer height="10" />
<hgroup cellVAlign="bottom">
<combobox id="property" label="Property:" editable="true" onchange="zenPage.changeProperty(zenThis);"/>
<spacer width="5" />
<button id="btnRemove" caption="Remove" title="Remove this property" onclick="zenPage.removeProperty();" />
</hgroup>
<spacer height="10" />
<hgroup cellVAlign="bottom">
<text id="value" label="Value:" onchange="zenPage.changeProperty(zenThis);"/>
<spacer width="5" />
<button id="btnEdit" caption="Edit" 
	title="Edit this value using the value editor." 
	onclick="zenPage.editCSSValue();" />
</hgroup>
<spacer height="10" />
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("CSS Declaration Editor")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit "<b>"_$$$TextHTML("Selector")_"</b>:&nbsp;"_$ZCVT(..selector,"O","HTML")
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("A set of CSS style declarations are displayed in the list below."),"<br/>"
	Write $$$TextHTML("You can select a declaration by clicking on it."),"<br/>"
	Write $$$TextHTML("To add a new declaration, click on New and select a property for it."),"<br/>"
	Write $$$TextHTML("You can select a CSS property name for the declaration using the Property combobox."),"<br/>"
	Write $$$TextHTML("You can edit the value for the declaration using the Value control.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set ctrl = ..%GetComponentById("declarations")
	If '$IsObject(ctrl) Quit $$$OK

	#; see if there is incoming CSS and parse it apart
	Do ##class(%ZEN.Utils).ParseCSS(..declaration,.tCSS)

	#; list of declarations
	Set n = $O(tCSS(""))
	While (n '= "") {
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do ctrl.options.Insert(tOption)
		Do:$IsObject(%page) %page.%AddComponent(tOption)

		Set tProp = $LG(tCSS(n),1)
		Set tVal = $LG(tCSS(n),2)
		Set tDecl = tProp_": "_tVal_";"
		Set tOption.value = tDecl
		Set tOption.text = tDecl
		Set n = $O(tCSS(n))
	}

	#; extra option for new item
	Set tOption = ##class(%ZEN.Auxiliary.option).%New()
	Do ctrl.options.Insert(tOption)
	Do:$IsObject(%page) %page.%AddComponent(tOption)

	Set tOption.value = ""
	Set tOption.text = $$$Text("--New--")
	Set tOption.style = "font-style: italic; color: blue;"

	#; property
	Set ctrl = ..%GetComponentById("property")

	Do ..GetCSSPropertyList(..context,.list)

	Set prop = $O(list(""))
	While (prop '= "") {
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do ctrl.options.Insert(tOption)
		Do:$IsObject(%page) %page.%AddComponent(tOption)
		Set tOption.value=prop
		Set tOption.text=prop
		Set prop = $O(list(prop))
	}

	Quit $$$OK
}

/// Return the value that should be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var ret = '';
	
	// convert current options back into CSS declaration
	var lb = this.getComponentById('declarations');

	for (var n = 0; n < lb.getOptionCount(); n++) {
		var val = lb.getOptionValue(n);
		if ('' != val) {
			ret += val + (this.multiLine ? '\r\n' : '');
		}
	}
	
	return ret;
}

/// User has selected a declaration in the list box.
ClientMethod changeDeclaration(lb) [ Language = javascript ]
{
	var val = lb.getOptionValue(lb.selectedIndex);

	// update property and value controls
	var ctrlProp = this.getComponentById('property');
	var ctrlVal = this.getComponentById('value');

	if ('' == val) {
		// new
		ctrlProp.setValue('');
		ctrlVal.setValue('***');
	}
	else {
		var p = val.split(':')[0];
		var v = val.split(':')[1].split(';')[0];
		ctrlProp.setValue(p);
		ctrlVal.setValue(v);
	}
}

/// User has changed the property or value control
ClientMethod changeProperty(ctrl) [ Language = javascript ]
{
	var lb = this.getComponentById('declarations');
	var index = lb.selectedIndex;
	var currVal = lb.getOptionValue(index);
	var currText = lb.getOptionText(index);

	// change option
	var decl = this.getCurrDeclaration();
	lb.setOption(index,decl,decl,'');
	
	// if this was the --new-- option, add a new *new*
	if ('' == currVal) {
		lb.appendOption(currVal,currText,'font-style: italic; color: blue;');
		lb.selectItem(index);
	}
}

/// Remove the current property
ClientMethod removeProperty() [ Language = javascript ]
{
	var lb = this.getComponentById('declarations');
	var index = lb.selectedIndex;
	var currVal = lb.getOptionValue(index);

	// remove option
	if ('' != currVal) {
		lb.removeOption(index);
		var ctrlProp = this.getComponentById('property');
		var ctrlVal = this.getComponentById('value');
		ctrlProp.setValue('');
		ctrlVal.setValue('***');
	}
}

/// Get current declaration from property and value controls.
ClientMethod getCurrDeclaration() [ Language = javascript ]
{
	var ctrlProp = this.getComponentById('property');
	var ctrlVal = this.getComponentById('value');

	return ctrlProp.getValue() + ": " + ctrlVal.getValue() + ";";
}

/// Return an array of possible CSS property values.
ClassMethod GetCSSPropertyList(pContext As %String, Output pList)
{
	If (pContext = "SVG"){
		Set pList("font") = ""
		Set pList("font-family") = "<family-name>|inherit"
		Set pList("font-size") = "xx-small|x-small|small|medium|large|x-large|xx-large|smaller|larger|<length>|<percentage>|inherit"
		Set pList("font-size-adjust") = ""
		Set pList("font-stretch") = ""
		Set pList("font-style") = "italic|oblique|normal|inherit"
		Set pList("font-variant") = "small-caps|normal|inherit"
		Set pList("font-weight") = "normal|bold|bolder|lighter|100|200|300|400|500|600|700|800|900|inherit"

		Set pList("letter-spacing") = "<length>|normal|inherit"
		Set pList("text-decoration") = "none|underline|overline|line-through|inherit"
		Set pList("word-spacing") = "<length>|normal|inherit"

		Set pList("clip") = ""
		Set pList("cursor") = "auto|default|pointer|crosshair|move|e-resize|ne-resize|nw-resize|n-resize|se-resize|sw-resize|s-resize|w-resize|text|wait|help|progress|inherit"
		Set pList("display") = "none|inherit"
		Set pList("overflow") = ""
		Set pList("visibility") = "hidden|visible"
		Set pList("opacity") = "<number>"

		Set pList("pointer-events") = ""

		Set pList("fill") = "<color>|none"
		Set pList("fill-opacity") = "<number>"
		Set pList("fill-rule") = ""

		Set pList("stroke") = "<color>|none"
		Set pList("stroke-dasharray") = "<list-of-numbers>"
		Set pList("stroke-dashoffset") = ""
		Set pList("stroke-linecap") = ""
		Set pList("stroke-linejoin") = ""
		Set pList("stroke-miterlimit") = ""
		Set pList("stroke-opacity") = "<number>"
		Set pList("stroke-width") = "<length>"

		Set pList("text-anchor") = "start|middle|end"
	}
	Else {
		Set pList("background") = "<color>"
		Set pList("background-attachment") = "scroll|fixed|inherit"
		Set pList("background-color") = "<color>|transparent|inherit"
		Set pList("background-image") = "<uri>|none|inherit"
		Set pList("background-repeat") = "repeat|repeat-x|repeat-y|no-repeat|inherit"
		Set pList("border") = "<border>|inherit"
		Set pList("border-bottom") = "<border>|inherit"
		Set pList("border-bottom-color") = "<color>|transparent|inherit"
		Set pList("border-bottom-style") = "none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|inherit"
		Set pList("border-bottom-width") = "thin|medium|thick|<length>|inherit"
		Set pList("border-color") = "<color>"
		Set pList("border-left") = "<border>|inherit"
		Set pList("border-left-color") = "<color>|transparent|inherit"
		Set pList("border-left-style") = "none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|inherit"
		Set pList("border-left-width") = "thin|medium|thick|<length>|inherit"
		Set pList("border-right") = "<border>|inherit"
		Set pList("border-right-color") = "<color>|transparent|inherit"
		Set pList("border-right-style") = "none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|inherit"
		Set pList("border-right-width") = "thin|medium|thick|<length>|inherit"
		Set pList("border-style") = "none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|inherit"
		Set pList("border-top") = "<border>|inherit"
		Set pList("border-top-color") = "<color>|transparent|inherit"
		Set pList("border-top-style") = "none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|inherit"
		Set pList("border-top-width") = "thin|medium|thick|<length>|inherit"
		Set pList("border-width") = ""
		Set pList("bottom") = "<length>"
		Set pList("clear") = "left|right|both|none"
		Set pList("clip") = "rect()|auto|inherit"
		Set pList("color") = "<color>|inherit"
		Set pList("content") = ""
		Set pList("cursor") = "auto|default|pointer|crosshair|move|e-resize|ne-resize|nw-resize|n-resize|se-resize|sw-resize|s-resize|w-resize|text|wait|help|progress|inherit"
		Set pList("display") = "none|inline|block|inline-block|list-item|run-in|table|inline-table|table-row-group|table-header-group|table-footer-group|table-row|table-column-group|table-column|table-cell|table-caption|inherit"
		Set pList("float") = "left|right|none|inherit"
		Set pList("font") = "caption|icon|menu|message-box|small-caption|status-bar|inherit"
		Set pList("font-family") = "<family-name>|inherit"
		Set pList("font-size") = "xx-small|x-small|small|medium|large|x-large|xx-large|smaller|larger|<length>|<percentage>|inherit"
		Set pList("font-style") = "italic|oblique|normal|inherit"
		Set pList("font-variant") = "small-caps|normal|inherit"
		Set pList("font-weight") = "normal|bold|bolder|lighter|100|200|300|400|500|600|700|800|900|inherit"
		Set pList("height") = "<length>|<percentage>|auto|inherit"
		Set pList("left") = "<length>|<percentage>|auto|inherit"
		Set pList("letter-spacing") = "<length>|normal|inherit"
		Set pList("line-height") = "<length>|<percentage>|<number>|normal|inherit"
		Set pList("list-style") = ""
		Set pList("margin") = "<length>"
		Set pList("margin-bottom") = "<length>|<percentage>|auto|inherit"
		Set pList("margin-left") = "<length>|<percentage>|auto|inherit"
		Set pList("margin-right") = "<length>|<percentage>|auto|inherit"
		Set pList("margin-top") = "<length>|<percentage>|auto|inherit"
		Set pList("overflow") = "visible|hidden|scroll|auto|inherit"
		Set pList("overflow-x") = "visible|hidden|scroll|auto|inherit"
		Set pList("overflow-y") = "visible|hidden|scroll|auto|inherit"
		Set pList("padding") = "<length>"
		Set pList("padding-bottom") = "<length>|<percentage>|inherit"
		Set pList("padding-left") = "<length>|<percentage>|inherit"
		Set pList("padding-right") = "<length>|<percentage>|inherit"
		Set pList("padding-top") = "<length>|<percentage>|inherit"
		Set pList("position") = "static|relative|absolute|fixed|inherit"
		Set pList("right") = "<length>|<percentage>|auto|inherit"
		Set pList("table-layout") = "auto|fixed|inherit"
		Set pList("text-align") = "left|center|right|justify|inherit"
		Set pList("text-decoration") = "none|underline|overline|line-through|inherit"
		Set pList("text-indent") = "<length>|<percentage>|inherit"
		Set pList("text-transform") = "uppercase|lowercase|capitalize|none|inherit"
		Set pList("top") = "<length>|<percentage>|auto|inherit"
		Set pList("vertical-align") = "baseline|sub|super|top|text-top|middle|bottom|text-bottom|<percentage>|<length>|inherit"
		Set pList("visibility") = "visible|hidden|collapse|inherit"
		Set pList("width") = "<length>|<percentage>|auto|inherit"
		Set pList("white-space") = "normal|nowrap|pre|pre-wrap|pre-line|inherit"
		Set pList("word-spacing") = "<length>|normal|inherit"
		Set pList("z-index") = "<integer>|auto|inherit"
	}
}

/// Launch the CSS Value Editor popup.
ClientMethod editCSSValue() [ Language = javascript ]
{
	var ctrlProp = this.getComponentById('property');
	var ctrlVal = this.getComponentById('value');

	var prop = ctrlProp.getValue();
	var value = ctrlVal.getValue();
	
	if ('' == prop) {
		alert(this.msgMissingProp);
		return;
	}

	var url = zenLink('%ZEN.Dialog.cssValueEditor.cls?context=' + escape(this.context) + '&property=' + escape(prop)+ '&value=' + escape(value));
	zenLaunchPopupWindow(url,'CSSValueEditor','resizable,top=100,width=500,height=700');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch (action) {
	case 'ok':
	case 'apply':
		var ctrl = this.getComponentById('value');
		if (ctrl) {
			ctrl.setValue(value);
			this.changeProperty(ctrl);
		}
		if ('apply' == action) {
			// cascade
			this.btnApply();
		}
		break;
	}
}

}
