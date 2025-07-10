/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// A composite control containing a Selector for a Lookup Table, a Details image button,
/// and a link to the Lookup Tables page if the user holds %Ens_LookupTables:READ privilege.
Class EnsPortal.Component.lookuptableSelector Extends %ZEN.Component.composite [ System = 4 ]
{

Parameter USECOMMONDIRECTORY = 1;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<selector name="LookupTables" id="selLookupTables" context="Ens.ContextSearch/LookupTables" size="30"/>
<image src="deepsee/zoom_24.png" id="btnLookupTables" title="Show details for the selected Lookup Table" onclick="this.showLookupTableDetails();"/>
</hgroup>
<link enclosingStyle="font-size:10pt;" labelClass="ribbonSortOption" caption="Lookup Tables Page" title="Click here to go to the Looup Tables configuration page." href="/csp/sys/sec/EnsPortal.LookupSettings.zen" />
</composite>
}

/// Launch the profile info dialog.
ClientMethod showLookupTableDetails() [ Language = javascript ]
{
	var name = this.getChildById('selLookupTables').getValue();
	if ((name.charAt(0) !== '@')) {
		alert($$$Text('Click here after selecting a Lookup Table, to see the Lookup Table management page'));
		return;
	}
	try {
		if (!zenPage.hasPermissionForLink('%Ens_LookupTables','READ')) {
			alert($$$Text('Insufficient Privilege to see the Lookup Table management page'));
			return;
		}
		/* ContextSearch prepends @ */
		if (name.charAt(0) === '@') name = name.slice(1);
	} catch (ex) {/* link to management page will still enforce privilege required */}
	
	var link = zenLink('EnsPortal.LookupSettings.zen');
	link += (link.indexOf('?') > -1) ? '&' : '?';
	link += 'LookupTable=' + encodeURIComponent(name);
	window.open(link);
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		var sel = this.getChildById('selLookupTables');
		if (sel) sel.setReadOnly(value);
		break;
	case 'value':
		var sel = this.getChildById('selLookupTables');
		if (sel) {
			sel.setValue(value);
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
	case 'readOnly':
		var sel = this.getChildById('selLookupTables');
		if (sel) return sel.getReadOnly();
		break;
	case 'value':
		var sel = this.getChildById('selLookupTables');
		if (sel) return sel.getValue();
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
	sel.name="LookupTables";
	sel.setProperty('id',this.id+".sel"+sel.name);
	sel.size=30;
	sel.setProperty('context',"Ens.ContextSearch/LookupTables");
	sel.onchange = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	sel.onkeyup = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	hgroup.addChild(sel);
	var btn = zenPage.createComponent('image');
	btn.src="deepsee/zoom_24.png";
	btn.setProperty('id',this.id+"."+"btn"+sel.name);
	btn.title="Show the Lookup Tables management page.";
	btn.onclick="if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showLookupTableDetails(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"

	hgroup.addChild(btn);

	this.addChild(hgroup);

	this.childrenCreated = true;

	return '';
}

}
