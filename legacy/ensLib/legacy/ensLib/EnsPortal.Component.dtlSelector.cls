/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// A composite control containing a Selector for a Data Transform and a Details image button that links to the DTL Editor page
Class EnsPortal.Component.dtlSelector Extends %ZEN.Component.composite [ System = 4 ]
{

Parameter USECOMMONDIRECTORY = 1;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<selector id="transformSelector" name="DTL" context="Ens.ContextSearch/SubclassOf?class=Ens.DataTransform" size="30"/>
<image src="deepsee/zoom_24.png" id="transformDetails" title="Show details for the selected Transform." onclick="this.showDTL();"/>
</hgroup>
</composite>
}

/// Launch the DTL editor.
ClientMethod showDTL() [ Language = javascript ]
{
	var name = this.getChildById('transformSelector').getValue();
	if (name == '') {
		alert($$$Text('Please select a valid transform'));
		return;
	}
	var link = zenLink('EnsPortal.DTLEditor.zen');
	link += (link.indexOf('?') > -1) ? '&' : '?';
	link += 'DT=' + encodeURIComponent(name + '.dtl');
	window.open(link);
}

/// Set the value of a named property.<br>
/// Ensure that the selector has the new value
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		var sel = this.getChildById('transformSelector');
		if (sel) sel.setReadOnly(value);
		break;
	case 'value':
		var selector = this.getChildById('transformSelector');
		if (selector) {
			selector.setValue(value);
		}
		// no break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Override getProperty('value') to get the value from the selector.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		var sel = this.getChildById('transformSelector');
		if (sel) return sel.getReadOnly();
		break;
	case 'value':
		var selector = this.getChildById('transformSelector');
		if (selector) {
			return selector.getValue();
		}
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
	var sel = zenPage.createComponent('selector');
	sel.name = 'DTL';
	sel.setProperty('id',this.id+'.transformSelector');
	sel.size = 30;
	sel.setProperty('context','Ens.ContextSearch/SubclassOf?class=Ens.DataTransform&abstract=0');
	sel.onchange = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	sel.onkeyup = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	hgroup.addChild(sel);

	var btn = zenPage.createComponent('image');
	btn.src = 'deepsee/zoom_24.png';
	btn.setProperty('id',this.id+'.transformDetails');
	btn.title = $$$Text('Show details for the selected Transform.','Ensemble');
	btn.onclick = "if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showDTL(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"
	hgroup.addChild(btn);
	this.addChild(hgroup);

	this.childrenCreated = true;

	return '';
}

}
