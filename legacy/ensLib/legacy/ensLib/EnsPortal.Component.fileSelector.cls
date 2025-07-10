/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Component.fileSelector Extends %ZEN.Component.composite [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter USECOMMONDIRECTORY = 1;

Property wildcard As %ZEN.Datatype.string [ InitialExpression = "*" ];

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup>
<text id="txtFileValue" size="35"/>
<image src="deepsee/zoom_24.png" id="btnFileValue" disabled="true" title="Select a file" onclick="var fileSel = zenIndex(#(%composite.index)#); if (fileSel) fileSel.showFileSelect();"/>
</hgroup>
</composite>
}

/// Helper method to wrap the main selectFile() function in the containing page.
ClientMethod showFileSelect() [ Language = javascript ]
{
	if (zenPage && (typeof zenPage.selectFile == 'function')) {
		zenPage.selectFile(this.index);
	}
}

/// This client callback is called from exposeComponent after
/// the element has been displayed on the screen.  This ia a synthetic event 
/// that fires when the page is first displayed, when the component or its containing
/// group is refreshed from the server, or when the component or its containing
/// group is displayed via a programmatic 'show()' call.  Note that setting the
/// style.display value from JavaScript DOES NOT trigger this event
ClientMethod onDisplayHandler() [ Language = javascript ]
{
	var buttonEnabled = (zenPage && zenPage.canViewFileSystem && this.disabled==false && !this.getProperty('readOnly'));
	var button = this.getChildById('btnFileValue');
	if (button) button.setDisabled(!buttonEnabled);
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
		var txt = this.getChildById('txtFileValue');
		if (txt) txt.setReadOnly(value);
		var btn = this.getChildById('btnFileValue');
		if (btn) btn.setDisabled(value);
		break;
	case 'value':
		var txt = this.getChildById('txtFileValue');
		if (txt) {
			txt.setValue(value);
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
		var txt = this.getChildById('txtFileValue');
		var btn = this.getChildById('btnFileValue');
		if (txt && btn) return (txt.getReadOnly() && btn.getProperty('disabled'));
		break;
	case 'value':
		var txt = this.getChildById('txtFileValue');
		if (txt) return txt.getValue();
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

ClientMethod getForm() [ Language = javascript ]
{
	var text = this.getChildById('txtFileValue');
	if (text) return text.getForm();
	return null;
}

/// Create children on client side so we can use them immediately. Note that the server may substitute fresh code-generated objects later.
ClientMethod createChildren(form) [ Language = javascript ]
{
	var hgroup = zenPage.createComponent('hgroup');
	var text = zenPage.createComponent('text');
	text.setProperty('id',this.id + '.txtFileValue');
	text.setProperty('size',35);
	text.onchange = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	text.onkeyup = "zenPage.settingChanged('"+escape(this.index)+"','"+escape(form.index)+"');"
	hgroup.addChild(text);
	var btn = zenPage.createComponent('image');
	btn.src = 'deepsee/zoom_24.png';
	btn.setProperty('id',this.id + '.btnFileValue');
	btn.title = $$$Text('Select a file');
	btn.onclick = 'zenIndex('+this.index+').showFileSelect();'
	hgroup.addChild(btn);

	this.addChild(hgroup);

	this.childrenCreated = true;
	return '';
}

}
