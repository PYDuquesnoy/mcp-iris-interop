/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// A composite control containing a Selector for a Rule, a Details image button, and a link to the Rule Editor page
Class EnsPortal.Component.ruleSelector Extends (%ZEN.Component.composite, EnsPortal.Util.PageLinks) [ System = 4 ]
{

// Parameter NAMESPACE = "http://www.intersystems.com/ensportal";

Parameter USECOMMONDIRECTORY = 1;

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<selector name="Rule" id="selRule" context="Ens.ContextSearch/RuleNames" size="30"/>
<image src="deepsee/zoom_24.png" id="btnRule" title="Show details for the selected Rule." onclick="this.showRuleDetails();"/>
</hgroup>
</composite>
}

/// Launch the profile info dialog.
ClientMethod showRuleDetails() [ Language = javascript ]
{
	// get the class name or alias from the list
	var name = this.getChildById('selRule').getValue();
	if (''==name) {
		alert($$$Text('Click here after selecting a rule to see the rule\'s details'));
	}
	else { // make sure we are using a class name, not an alias, when popping up the rule editor;
		   // also make sure the class exists, and if not, offer to create it
		var link = zenLink(zenPage.ruleEditorBaseURL);
		link += (link.indexOf('?') > -1) ? '&' : '?';
		var className = this.GetClassName(name);
		if (className.length > 0) {
			link += 'rule=' + encodeURIComponent(className);
			window.open(link);
		}
		else {
			if (confirm($$$FormatText($$$Text('The rule %1 does not exist; would you like to create it?'),name))) {
				link += 'rule=' + encodeURIComponent(name) + '&NEW=1';
				window.open(link);
			}
		}
	}
}

/// Get the class name (in case what's been selected is an alias which is invalid as a class name).
/// If the id is already a class name, that class name will be returned as the return value.
ClassMethod GetClassName(id As %String) As %String [ ZenMethod ]
{
	Set tClassName = ##class(Ens.Projection.Rule).ResolveRuleAlias(id)
	try {
		Set tFound = $classmethod(tClassName,"%Extends","Ens.Rule.Definition")
	}
	catch {
		Set tFound = 0
	}
	Quit $S(tFound:tClassName, 1:"")
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		var sel = this.getChildById('selRule');
		if (sel) sel.setReadOnly(value);
		break;
	case 'value':
		var sel = this.getChildById('selRule');
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
		var sel = this.getChildById('selRule');
		if (sel) return sel.getReadOnly();
		break;
	case 'value':
		var sel = this.getChildById('selRule');
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
	sel.name="Rule";
	sel.setProperty('id',this.id+".sel"+sel.name);
	sel.size=30;
	sel.setProperty('context',"Ens.ContextSearch/RuleNames");
	sel.onchange = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	sel.onkeyup = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	hgroup.addChild(sel);

	var btn = zenPage.createComponent('image');
	btn.src="deepsee/zoom_24.png";
	btn.setProperty('id',this.id+"."+"btn"+sel.name);
	btn.title="Show details for the selected Rule.";
	btn.onclick="if (zenPage.stopTimers) {zenPage.stopTimers()}; zenPage.getComponentById('"+this.id+"').showRuleDetails(); if (zenPage.startTimers) {zenPage.startTimers(2000)};"
	hgroup.addChild(btn);
	this.addChild(hgroup);

	this.childrenCreated = true;

	return '';
}

}
