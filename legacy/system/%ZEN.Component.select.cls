/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A select list control.<br>
/// This control is based on the HTML select element.<br/>
/// Setting <property>readOnly</property> to true has the same effect
/// as disabling this component; this is the standard HTML behavior
/// for select controls.
Class %ZEN.Component.select Extends listControl [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "select";

/// Number of rows in the select control.
Property size As %ZEN.Datatype.integer(MINVAL = 0);

///  If true (the default), insert an extra row with the value of <property>emptyText</property>
///  at the top of the dropdown, unless <property>required</property> is true.
Property showEmpty As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  The text to be displayed in the "empty" item displayed if 
///  <property>showEmpty</property> is true. The default is "".
Property emptyText As %ZEN.Datatype.caption;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for select." */
.select {
}
</style>
}

Method %DrawHTML()
{
	Set tSC = ..%BuildValueLists(.tValueList,.tDisplayList)

	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		Quit
	}

	#; <select> does not support readOnly
	#; so we use disabled for both
	Set disabled = $S(..disabled||..readOnly:"disabled",1:"")

	&html<<select class="#(..controlClass)#" id="#(..%MakeId("control"))#" #(..%Name())# #(..%Attr("title",..title))# #(disabled)# #(..%Attr("size",..size))# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers())#>>

	If (..showEmpty) {
		#; empty item for value of ""
		&html<<option #($S(""=..value:"selected=""1""",1:""))#>#($ZCVT(..emptyText,"O","HTML"))#</option>>
	}

	For n=1:1:$LL(tDisplayList) {
		Set tValue = $LG(tValueList,n)
		Set tValue = $$$ZENVAL(tValue)
		&html<<option #($S(tValue=..value:"selected=""1""",1:""))# value="#($ZCVT(tValue,"O","HTML"))#">#($ZCVT($LG(tDisplayList,n),"O","HTML"))#</option>>
	}

	&html<</select>>
}

/// Return the index of the current selected item (0-based) in the select component.
/// Returns -1 is no item is selected.
ClientMethod getSelectedIndex(idx) [ Language = javascript ]
{
	var el = this.findElement('control');
	if (el) {
		return el.selectedIndex;
	}
	return -1;
}

/// Return the logical value of the given item (0-based) in the dropdown list.
ClientMethod getOptionValue(idx) [ Language = javascript ]
{
	var el = this.findElement('control');
	if (el && idx >= 0) {
		var opt = el.options[idx];
		return (null == opt) ? '' : opt.value;
	}
	return '';
}

/// Return the display text for the given item (0-based) in the dropdown list.
ClientMethod getOptionText(idx) [ Language = javascript ]
{
	var el = this.findElement('control');
	if (el && idx >= 0) {
		var opt = el.options[idx];
		return (null == opt) ? '' : opt.text;
	}
	return '';
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'disabled':
		value = (value) ? true : false;
		this.disabled = value;
		var d = (this.readOnly || this.disabled);
		if (el) { el.disabled = d; }

		// change label style
		var lbl = this.getLabelElement();
		if (lbl) {
			if (this.disabled) {
				lbl.className = 'zenLabelDisabled';
			}
			else {
				lbl.className = (''==this.labelClass) ? 'zenLabel' : this.labelClass;
			}
		}
		break;
	case 'readOnly':
		value = (value) ? true : false;
		this.readOnly = value;
		var d = (this.readOnly || this.disabled);
		if (el) { el.disabled = d; }
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
