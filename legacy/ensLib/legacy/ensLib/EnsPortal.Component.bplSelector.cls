/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// A composite control containing a Selector for a Business Process, a Details image button, and a link to the BPL Editor page
Class EnsPortal.Component.bplSelector Extends %ZEN.Component.composite [ System = 4 ]
{

// Parameter NAMESPACE = "http://www.intersystems.com/ensportal";

Parameter USECOMMONDIRECTORY = 1;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<label controlClass="zenLabel" value=""/>
<label name="BPLClass" id="lblBPLClass"/>
<image src="deepsee/zoom_24.png" id="btnBPLClass" title="Go to Business Process definition" onclick="this.showBPLDetails();"/>
</hgroup>
</composite>
}

/// Launch the BPL editor / viewer.
ClientMethod showBPLDetails() [ Language = javascript ]
{
	var name = this.getChildById('lblBPLClass').getValue();
	var link = zenLink('EnsPortal.BPLEditor.zen');
	link += (link.indexOf('?') > -1) ? '&' : '?';
	link += 'BP=' + encodeURIComponent(name + '.bpl');
	window.open(link);
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		var lbl = this.getChildById('lblBPLClass')
		if (lbl) {
			lbl.setValue(value);
		}
		// no break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Return the value of a named property (i.e. a setting).<br>
/// Returns null if this is not a property of this object.<br>
/// <var>key</var> is an optional argument used for properties
/// (such as collections) that may need a key to find a specific value.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'value':
		var lbl = this.getChildById('lblBPLClass')
		if (lbl) return lbl.getValue();
		// no break;
	default:
		// dispatch
		return this.invokeSuper('getProperty',arguments);
	}
}

/// Client-side method to set the value associated with this control.
/// <var>value2</var> is an optional, second parameter used by some controls
/// (such as <class>dataCombo</class>).
ClientMethod setValue(value, value2) [ Final, Language = javascript ]
{
	this.setProperty('value',value,value2);
}

ClientMethod getValue() [ Final, Language = javascript ]
{
	return this.getProperty('value');
}

/// The server has just installed us as a fresh code-generated component. Recover the old value and replace ourselves in the page list.
ClientMethod onRefreshContents() [ Final, Language = javascript ]
{
	var old = zenPage.composites[this.id];
	this.setValue(old.getValue());
	zenPage.composites[this.id] = this;
}

/// Create children on client side so we can use them immediately. Note that the server may substitute fresh code-generated objects later.
ClientMethod createChildren(form) [ Language = javascript ]
{
	var hgroup = zenPage.createComponent('hgroup');
	var ctrllb = zenPage.createComponent('label');
	ctrllb.name="BPLClass";
	ctrllb.setProperty('id',this.id+".lbl"+ctrllb.name);
	hgroup.addChild(ctrllb);
	var btn = zenPage.createComponent('image');
	btn.src="deepsee/zoom_24.png";
	btn.setProperty('id',this.id+"."+"btn"+ctrllb.name);
	btn.title="Go to Business Process definition";
	btn.onclick="if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showBPLDetails(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"
	hgroup.addChild(btn);

	this.addChild(hgroup);

	this.childrenCreated = true;
	return '';
}

}
