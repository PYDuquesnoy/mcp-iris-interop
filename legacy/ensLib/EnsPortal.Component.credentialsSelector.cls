/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// A composite control containing a Selector for a Credentials pair, a Details image button, and a link to the Credentials page
Class EnsPortal.Component.credentialsSelector Extends %ZEN.Component.composite [ System = 4 ]
{

// Parameter NAMESPACE = "http://www.intersystems.com/ensportal";

Parameter USECOMMONDIRECTORY = 1;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<selector name="Credentials" id="selCredentials" context="Ens.ContextSearch/Credentials" size="30"/>
<image src="deepsee/zoom_24.png" id="btnCredentials" title="Show details for the selected Credentials." onclick="this.showCredentialsDetails();"/>
</hgroup>
<link enclosingStyle="font-size:10pt;" labelClass="ribbonSortOption" caption="Credentials Configuration Page" title="Click here to go to the Credentials configuration page." href="EnsPortal.Credentials.zen" />
</composite>
}

/// Launch the profile info dialog.
ClientMethod showCredentialsDetails() [ Language = javascript ]
{
	var name = this.getChildById('selCredentials').getValue();
	if (''==name) {
		alert($$$Text('Click here after selecting a pair of credentials, to see the credentials\' details'));
		return;
	}
	var link = zenLink('EnsPortal.Credentials.zen');
	link += (link.indexOf('?') > -1) ? '&' : '?';
	link += 'ID=' + encodeURIComponent(name);
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
		var sel = this.getChildById('selCredentials');
		if (sel) sel.setReadOnly(value);
		break;
	case 'value':
		var sel = this.getChildById('selCredentials');
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
		var sel = this.getChildById('selCredentials');
		if (sel) return sel.getReadOnly();
		break;
	case 'value':
		var sel = this.getChildById('selCredentials');
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
	sel.name="Credentials";
	sel.setProperty('id',this.id+".sel"+sel.name);
	sel.size=30;
	sel.setProperty('context',"Ens.ContextSearch/Credentials");
	sel.onchange = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	sel.onkeyup = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	hgroup.addChild(sel);
	var btn = zenPage.createComponent('image');
	btn.src="deepsee/zoom_24.png";
	btn.setProperty('id',this.id+"."+"btn"+sel.name);
	btn.title="Show details for the selected Credentials.";
	btn.onclick="if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showCredentialsDetails(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"

	hgroup.addChild(btn);

	this.addChild(hgroup);

	/*  Removed by HCR306
	var link = zenPage.createComponent('link');
	link.enclosingStyle="font-size:10pt;";
	link.labelClass="ribbonSortOption";
	link.caption="Credentials Configuration Page";
	link.title="Click here to go to the Credentials configuration page.";
	link.href="EnsPortal.Credentials.zen";
	this.addChild(link);
	*/

	this.childrenCreated = true;

	return '';
}

}
