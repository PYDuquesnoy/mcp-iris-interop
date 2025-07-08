/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a listBox control implemented using HTML primitives.<br>
/// It offers some features not provided by the HTML select control.<br>
/// The contents displayed by the <class>combobox</class> dropdown list are
/// defined using a set of <class>%ZEN.Auxiliary.option</class> objects.<br>
/// For example:
/// <example language="xml!fragment">
/// <listBox>
/// <option value="1" text="Apple" />
/// <option value="2" text="Banana"/>
/// </listBox>
/// </example>
/// The listBox control will support both drag and drop. If 
/// <property>dragEnabled</property> is true, then the user can drag values
/// from the list box and drop them on other drop-enabled components.<br/>
/// If <property>dropEnabled</property> is true, then values can be dropped
/// onto the list. They will be appended to the end of the list.
/// If both drag and drop are enabled, then it is also possible to move
/// items within this listBox using the mouse.
Class %ZEN.Component.listBox Extends abstractListBox [ Deprecated, System = 3 ]
{

/// Set of options displayed within the combobox.
Property options As list Of %ZEN.Auxiliary.option(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Sample usage
XData Example
{
<listBox>
<option value="1" text="Apple" />
<option value="2" text="Banana" style="font-size: 2.5em; "/>
</listBox>
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	For n=1:1:10 {
		Set tOption = ##class(%ZEN.Auxiliary.option).%New()
		Do ..options.Insert(tOption)
		Do:$IsObject(%page) %page.%AddComponent(tOption)
		Set tOption.text="Item " _ n
		Set tOption.value=n
	}
}

/// Internal method.<br>
/// Create contents of list box using DHTML.
ClientMethod renderListBox() [ Internal, Language = javascript ]
{
	var div = this.findElement('list');
	zenASSERT(div,'Unable to find listBox element',arguments);

	var html = new Array();

	var option,val,text,cls,style;
	var hasSel = false;
	for (var n = 0; n < this.options.length; n++) {
		option = this.options[n];
		val = option.value;
		text = (option.text!='') ? option.text : option.value;
		if (!hasSel && this.value == option.value) {
			this.selectedIndex = n;
			cls = 'listBoxItemSelected';
			hasSel = true;
		}
		else {
			cls = 'listBoxItem';
		}

		var mouseEvents = '';
		if (zenPage.dragAndDrop) {
			mouseEvents = ' onmousedown="return zenPage.getComponent('+this.index+').itemMouseDown(event,'+n+');"';
			mouseEvents += ' onmouseup="return zenPage.getComponent('+this.index+').itemMouseUp(event);"';
		}

		style = (option.style=='') ? '' : ('style="'+option.style+'"');
		html[html.length] = '<div'+ mouseEvents + ' class="'+cls+'" id="'+this.makeId('item_'+n)+'" onclick="zenPage.getComponent('+this.index+').clickItem('+n+');return false;" ondblclick="zenPage.getComponent('+this.index+').dblClickItem('+n+');" '+style+'>&nbsp;'+text+'&nbsp;<\/div>';
	}
	div.innerHTML = html.join("");
}

ClientMethod getOptionCount() [ Language = javascript ]
{
	return this.options.length;
}

/// Return the logical value of the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionValue(idx) [ Language = javascript ]
{
	return this.options[idx].value;
}

/// Return the display text for the given item (0-based) in the dropdown list.<br>
ClientMethod getOptionText(idx) [ Language = javascript ]
{
	return this.options[idx].text;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// make sure contents of list are displayed
	this.renderListBox();
}

/// Remove all options from this listBox.<br>
/// Clears the current value of the listBox.<br>
/// If there is a value for <property>valueList</property> it is cleared as well.
ClientMethod resetOptions() [ Language = javascript ]
{
	this.options.length = 0;
	this.selectedIndex = -1;
	this.text = '';
	this.setValue('');
	this.renderListBox();
}

/// Create a new option and append it to this listBox.
/// If <var>text</var> is omitted, then <var>value</var> is used as the display value.
ClientMethod appendOption(value, text, style) [ Language = javascript ]
{
	var option = zenPage.createComponent('option');
	if (value != null) option.value = value;
	option.text = (text != null) ? text : option.value;
	if (style != null) option.style = style;

	this.options[this.options.length] = option;
	this.renderListBox();
}

/// Create a new option and insert it into the set of listBox options.
/// The new option is inserted immediately before the option with index
/// <var>index</var>.
/// If <var>text</var> is omitted, then <var>value</var> is used as the display value.
ClientMethod insertOption(index, value, text, style) [ Language = javascript ]
{
	var option = zenPage.createComponent('option');
	if (value != null) option.value = value;
	option.text = (text != null) ? text : option.value;
	if (style != null) option.style = style;

	this.options.splice(index,0,option);
	this.renderListBox();
}

/// Set the properties of an option within this listBox.<br>
/// <var>index</var> is the index number (0-based) of the option.<br>
/// If <var>text</var> is omitted, then <var>value</var> is used as the display value.
ClientMethod setOption(index, value, text, style) [ Language = javascript ]
{
	var option = this.options[index];
	if (null != option) {
		if (value != null) option.value = value;
		option.text = (text != null) ? text : option.value;
		if (style != null) option.style = style;
		this.renderListBox();
	}
}

/// Move the option at position <var>index</var> to position
/// <var>newIndex</var> (0-based). Slide other options if need be.
ClientMethod moveOption(index, newIndex) [ Language = javascript ]
{
	if (index < 0 || index > this.options.length) return;
	if (newIndex < 0 || newIndex > this.options.length) {
		newIndex = this.options.length;
	}
	if (index == newIndex) return;

	var option = this.options[index];
	this.options.splice(index,1);
	this.options.splice(newIndex,0,option);
	this.renderListBox();
}

/// Remove an option from this listBox.<br>
/// <var>index</var> is the index number (0-based) of the option.<br>
ClientMethod removeOption(index) [ Language = javascript ]
{
	this.options.splice(index,1);
	if (this.selectedIndex >= this.options.length) {
		this.selectedIndex = -1;
	}
	this.renderListBox();
}

/// Called after refreshContents; make sure our contents are updated.
ClientMethod onRefreshContents() [ Internal, Language = javascript ]
{
	this.renderListBox();
}

/// Default drop handler for listBox components.
ClientMethod dropStartHandler(dragData) [ Language = javascript ]
{
	var value = dragData.value;
	var text = dragData.text;

	if (this != dragData.sourceComponent) {
		// drag from another component: append
		this.appendOption(value,text);
	}
	else {
		// move item within this list
		var tgtId = ZLM.getDragInnerDestination().id;
		var tgtIndex = -1;
		if (tgtId && tgtId.indexOf('item')!=-1) {
			tgtIndex = tgtId.split('_')[1];
		}
		dragData.targetItem = tgtIndex;
		var srcIndex = dragData.sourceItem;
		this.moveOption(srcIndex,tgtIndex);
	}
	return true;
}

}
