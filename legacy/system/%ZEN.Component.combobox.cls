/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A <class>combobox</class> is a specialized type of <class>abstractComboBox</class> that
/// presents the user with a pre-defined set of options.<br>
/// The contents displayed by the <class>combobox</class> dropdown list are
/// defined using a set of <class>%ZEN.Auxiliary.option</class> objects.<br>
/// For example:
/// <example language="xml!fragment">
/// <combobox id="comboboxEdit" label="Editable" editable="true">
/// <option value="1" text="Apple" />
/// <option value="2" text="Banana" style="font-size: 2.5em; "/>
/// </combobox>
/// </example>
Class %ZEN.Component.combobox Extends abstractComboBox [ Deprecated, System = 3 ]
{

/// Set of options displayed within the combobox. Each option is a <class>%ZEN.Auxiliary.option</class>
/// object. For each option you specify a logical value, a display value, and an optional CSS style.
Property options As list Of %ZEN.Auxiliary.option(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// (Optional) A csv-list of values used for logical values within this combobox.<br/>
/// If this is defined, then the <property>options</property> property is ignored.<br/>
/// If your data include commas, escape them with "\,".<br/>
Property valueList As %ZEN.Datatype.csv;

/// (Optional) A csv-list of values used for display values within this combobox.<br/>
/// This is only used if the <property>valueList</property> property is defined.<br/>
/// The entire list is a localized value.
/// If your data include commas, escape them with "\,".<br/>
Property displayList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// Lookup up the display value for the combobox given
/// a logical value.<br>
/// This is called when the control is initially drawn.<br/>
Method %GetDisplayValue(pValue As %String) As %String
{
	If (..valueList '= "") {
		Quit:(..displayList="") pValue

		#; look for value in list
		Set tValueList = $Replace(..valueList,"\,",$C(1))
		Set tDisplayList = $Replace(..displayList,"\,",$C(1))
		For n = 1:1:$L(tValueList,",") {
			Set tTest = $P(tValueList,",",n)
			Set tTest = $Replace(tTest,$C(1),",")
			If (pValue = tTest) {
				Set pValue = $Replace($P(tDisplayList,",",n),$C(1),",")
				Quit
			}
		}
	}
	Else {	
		#; look through options
		Set tCount = ..options.Count()
		For n = 1:1:tCount {
			Set tOption = ..options.GetAt(n)
			If (pValue = tOption.value) {
				Set pValue = tOption.text
				Quit
			}
		}
	}
	Quit pValue
}

/// Internal method.<br>
/// Create contents of drop down box using DHTML.
ClientMethod renderDropdown() [ Internal, Language = javascript ]
{
	var div = this.getDropDownDiv();
	zenASSERT(div,'Unable to find DropDown element',arguments);

	var html = new Array();
	html[html.length] = '<table class="comboboxTable" width="100%" border="0" cellpadding="0" cellspacing="0">';

	// if valuelist is defined, use it
	if ('' != this.valueList) {
		var valueList = this.valueList;
		valueList = valueList.replace(/\\,/g,'\x01');
		var displayList = this.displayList;
		displayList = displayList.replace(/\\,/g,'\x01');
		var values = valueList.split(',');
		var texts = (''==displayList) ? values : displayList.split(',');
		for (var n = 0; n < values.length; n++) {
			var val = values[n];
			val = val.replace(/\x01/g,',');
			var text = texts[n];
			text = text.replace(/\x01/g,',');
			text = (''==text) ? '&nbsp;' : zenEscapeHTMLSafe(text);
			html[html.length] = '<tr id="item_'+n+'_'+this.index+'" class="comboboxItem" onmousedown="zenPage.getComponent('+this.index+').itemMouseDown(event,'+n+');" onmouseup="zenPage.getComponent('+this.index+').itemMouseUp(event,'+n+');"><td width="100%"><a href="#">'+text+'<\/a><\/td><\/tr>';
		}
	}
	else {
		for (var n = 0; n < this.options.length; n++) {
			var option = this.options[n];
			var val = option.value;
			var text = option.text.toString();
			text = ('' == text) ? '&nbsp;' : zenEscapeHTMLSafe(text);
			html[html.length] = '<tr id="item_'+n+'_'+this.index+'" class="comboboxItem" onmousedown="zenPage.getComponent('+this.index+').itemMouseDown(event,'+n+');" onmouseup="zenPage.getComponent('+this.index+').itemMouseUp(event,'+n+');"><td style="'+zenEscapeHTML(option.style)+'" width="100%"><a href="#">'+text+'<\/a><\/td><\/tr>';
		}
	}
	html[html.length] = '<\/table>';
	div.innerHTML = html.join("");

	// register that we used the modal div!
	zenPage.lastModalIndex = this.index;

	var input = this.findElement('input');
	zenASSERT(input,'Unable to find input element',arguments);
	input.focus();
	this.isDropdownVisible = (div.style.display != 'none');
	this.findSelectedItem();
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	For n=1:1:3 {
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do ..options.Insert(tOption)
		Do:$IsObject(%page) %page.%AddComponent(tOption)
		Set tOption.text="Item " _ n
		Set tOption.value=n
	}
}

/// Return number of items in dropdown list.<br>
ClientMethod getOptionCount() [ Language = javascript ]
{
	var valueList = this.valueList;
	valueList = valueList.replace(/\\,/g,'\x01');
	return ('' == valueList) ? this.options.length : valueList.split(',').length;
}

/// Return the <class>%ZEN.Auxiliary.option</class> option object
/// associated with the given item (0-based) in the dropdown list.<br>
/// If <property>valueList</property> is defined, then this returns null.
ClientMethod getOption(idx) [ Language = javascript ]
{
	return ('' == this.valueList) ? this.options[idx] : null;
}

/// Return the logical value of the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionValue(idx) [ Language = javascript ]
{
	var value;
	
	if ('' != this.valueList) {
		var valueList = this.valueList;
		valueList = valueList.replace(/\\,/g,'\x01');
		value = valueList.split(',')[idx];
		value = value.replace(/\x01/g,',');
	}
	else {
		value = this.options[idx].value;
	}
	
	return (null == value) ? '' : value;
}

/// Return the display text for the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionText(idx) [ Language = javascript ]
{
	var text;
	
	if ('' != this.valueList) {
		// use valueList (or displayList)
		if ('' != this.displayList) {
			var displayList = this.displayList;
			displayList = displayList.replace(/\\,/g,'\x01');
			text = displayList.split(',')[idx];
			text = text.replace(/\x01/g,',');
		}
		else {
			var valueList = this.valueList;
			valueList = valueList.replace(/\\,/g,'\x01');
			text = valueList.split(',')[idx];
			text = text.replace(/\x01/g,',');
		}
	}
	else {
		text = this.options[idx].text;
	}
	
	return (null == text) ? '' : text;
}

/// Remove all options from this combobox.<br>
/// Clears the current value of the combobox.<br>
/// If there is a value for <property>valueList</property> it is cleared as well.
ClientMethod resetOptions() [ Language = javascript ]
{
	this.valueList = '';
	this.displayList = '';
	this.options.length = 0;
	this.selectedIndex = -1;
	this.text = '';
	this.setValue('');
}

/// Create a new option and append it to this combobox.
/// If <var>text</var> is omitted, then <var>value</var> is used as the display value.
ClientMethod appendOption(value, text, style) [ Language = javascript ]
{
	var option = zenPage.createComponent('option');
	if (value != null) option.value = value;
	option.text = (text != null) ? text : option.value;
	if (style != null) option.style = style;

	this.options[this.options.length] = option;
}

/// Set the properties of an option within this combobox.<br>
/// <var>index</var> is the index number (0-based) of the option.<br>
/// If <var>text</var> is omitted, then <var>value</var> is used as the display value.
ClientMethod setOption(index, value, text, style) [ Language = javascript ]
{
	var option = this.options[index];
	if (null != option) {
		if (value != null) option.value = value;
		option.text = (text != null) ? text : option.value;
		if (style != null) option.style = style;
	}
}

/// Remove an option from this combobox.<br>
/// <var>index</var> is the index number (0-based) of the option.<br>
ClientMethod removeOption(index) [ Language = javascript ]
{
	this.options.splice(index,1);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'valueList':
		if (this.valueList != value) {
			this.valueList = value;
			this.setValue(this.getValue());
		}
		break;
	case 'displayList':
		if (this.displayList != value) {
			this.displayList = value;
			this.setValue(this.getValue());
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
