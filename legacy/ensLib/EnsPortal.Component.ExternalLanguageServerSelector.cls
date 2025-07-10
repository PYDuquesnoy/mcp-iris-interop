/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A composite control containing a Selector for an External Language Server, a Details image button,
/// and a link to the External Language Server pages if the user holds %Admin_Manage:USE and %DB_IRISSYS:READ privilege.
Class EnsPortal.Component.ExternalLanguageServerSelector Extends %ZEN.Component.composite [ System = 4 ]
{

Parameter USECOMMONDIRECTORY = 1;

Parameter DOMAIN = "Ensemble";

Property Types As %ZEN.Datatype.string;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<selector name="ELSNames" id="selELSNames" context="Ens.ContextSearch/ExternalLanguageServers" size="30"/>
<image hidden="true" id="btnExternalLanguageServer" src="deepsee/zoom_24.png" title="Show details for the selected External Language Server" onclick="this.showELSDetails();"/>
</hgroup>
<link hidden="true" id="lnkExternalLanguageServers" enclosingStyle="font-size:10pt;" labelClass="ribbonSortOption" caption="External Language Servers Page" title="Click here to go to the External Language Servers configuration page." href="#" onclick="this.showELSNames();" />
</composite>
}

/// Need %Admin_Manage:USE to get to ELS pages and %DB_IRISSYS:READ for the contents to display properly
ClassMethod hasPermissionsForLinks() As %Boolean [ Internal, ZenMethod ]
{
	Quit ''($System.Security.Check("%Admin_Manage","USE") && $System.Security.Check("%DB_IRISSYS","READ"))
}

/// Need %DB_IRISSYS:WRITE to edit an External Language Server
ClassMethod hasEditPermission() As %Boolean [ Internal, ZenMethod ]
{
	Quit ''$System.Security.Check("%DB_IRISSYS","WRITE")
}

/// Launch the profile info dialog.
ClientMethod showELSDetails() [ Language = javascript ]
{
	var name = this.getChildById('selELSNames').getValue();
	if ((name === '')) {
		alert($$$Text('Click here after selecting a External Language Server Name to see the External Language Server definition'));
		return;
	}
	try {
		if (!this.hasPermissionsForLinks()) {
			alert($$$Text('Insufficient Privilege to see the External Language Server Details page'));
			return;
		}
		
	} catch (ex) {/* link to management page will still enforce privilege required */}
	
	var link = '/csp/sys/mgr/%25CSP.UI.Portal.ExternalLanguageServer.zen?PID='+encodeURIComponent(name)
	// If not WRITE permissions on %DB_IRISSYS, open page in read-only mode
	if (!this.hasEditPermission()) {
		link += '&IsEditForm=0';
	}
	var link = zenLink(link);

	window.open(link);
}

/// Launch the profile info dialog.
ClientMethod showELSNames() [ Language = javascript ]
{
	try {
		if (!this.hasPermissionsForLinks()) {
			alert($$$Text('Insufficient Privilege to see the External Language Servers page'));
			return;
		}
		
	} catch (ex) {/* link to management page will still enforce privilege required */}
	
	var link = zenLink('/csp/sys/mgr/%25CSP.UI.Portal.ExternalLanguageServers.zen');

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
		var sel = this.getChildById('selELSNames');
		if (sel) sel.setReadOnly(value);
		break;
	case 'value':
		var sel = this.getChildById('selELSNames');
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
		var sel = this.getChildById('selELSNames');
		if (sel) return sel.getReadOnly();
		break;
	case 'value':
		var sel = this.getChildById('selELSNames');
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
	// Now that we can access the Types property (not yet available in createChildren()), add a filter to the context search
	if (this.Types != "") {
		var sel = this.getChildById('selELSNames');
		var context = "Ens.ContextSearch/ExternalLanguageServers?Types="+this.Types;
		sel.context = context;
	}
	// Show links if have proper permissions
	if (this.hasPermissionsForLinks()) {
		var btn = this.getChildById("btnExternalLanguageServer");
		if (btn) {
			btn.hidden = false;
		}
		var lnk = this.getChildById("lnkExternalLanguageServers");
		if (lnk) {
			lnk.hidden = false;
		}
	}
	var old = zenPage.composites[this.id];
	this.setValue(old.getValue());
	zenPage.composites[this.id] = this;
}

/// Create children on client side so we can use them immediately. Note that the server may substitute fresh code-generated objects later.
ClientMethod createChildren(form) [ Language = javascript ]
{
	var hgroup = zenPage.createComponent('hgroup');
	var sel = zenPage.createComponent('selector');
	sel.name="ELSNames";
	sel.setProperty('id',this.id+".sel"+sel.name);
	sel.size=30;
	// We'll filter this list down later if the parent gave a list of Types to show
	sel.setProperty('context',"Ens.ContextSearch/ExternalLanguageServers");
	sel.onchange = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	sel.onkeyup = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	hgroup.addChild(sel);
	
	if (this.hasPermissionsForLinks()) {
		var btn = zenPage.createComponent('image');
		btn.src="deepsee/zoom_24.png";
		btn.setProperty('id',this.id+".btnExternalLanguageServer");
		btn.title="Show details for the selected External Language Server.";
		btn.onclick="if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showELSDetails(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"

		hgroup.addChild(btn);
	}

	this.addChild(hgroup);
	
	if (this.hasPermissionsForLinks()) {
		var link = zenPage.createComponent('link');
		link.style='font-size:10pt;';
		link.setProperty('id',this.id+".lnkExternalLanguageServers");
		link.setProperty('labelClass','ribbonSortOption');
		link.caption='External Language Servers Page';
		link.title = 'Click here to go to the External Language Servers configuration page';
		link.href='#';
		link.onclick="if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showELSNames(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"

		this.addChild(link);
	}
	
	this.childrenCreated = true;

	return '';
}

}
