/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Editor logic for a Zen Page Studio Document.
Class %ZEN.StudioDocument.ZENPageEditor Extends %ZEN.StudioDocument.AbstractEditor [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

XData Style
{
<style type="text/css">
body {
	background: #C5D6D6;
	font-family: verdana, sans-serif;
}

</style>
}

/// Contents of application editor page;
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" >
<iframe id="targetFrame" height="1200" width="1200" />
</page>
}

/// DrawHTMLContent
Method DrawHTMLContent(seed As %ZEN.Datatype.string) As %Status
{
	Write ..GetClassName(..documentName)
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	#; point iframe to our page class
	Set tClass = ..GetClassName(..documentName)
	
	Set iFrame = ..%GetComponentById("targetFrame")
	Set iFrame.src = tClass _ ".cls?$DESIGNMODE=1"
	Quit $$$OK
}

/// Return the target page loaded within this editor.
ClientMethod getTargetPage() [ Language = javascript ]
{
	return parent.frames[0].zenPage;
}

/// User has selected a component in the editor pane.
ClientMethod selectComponent(page, obj, evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.stopPropagation) { evt.stopPropagation(); }
	if (evt.preventDefault) { evt.preventDefault(); }

	// establish this before we get here!
	this.targetPage = page;

	// select item
	var oldItem = this.selectedItems[0];
	if (oldItem) {
		oldItem.getEnclosingDiv().style.border = 'gray dotted 1px';
	}

	this.selectedItems.length = 0;

	if (obj) {
		this.selectedItems[this.selectedItems.length] = obj;
		obj.getEnclosingDiv().style.border = 'blue solid 2px';
	}
	
	this.updateInspector();
	//alert(this.getComponentXML(obj));
	//this.raiseDocument(this.getComponentXML(obj));

	return false;
}

/// Update the inspector with details on the selected component.
ClientMethod updateInspector() [ Language = javascript ]
{
	var proplist = null;

	if (1 == this.selectedItems.length && null != this.selectedItems[0]) {
		var obj = this.selectedItems[0];
		
		var proplist = new Array();
		proplist[proplist.length] = { name:'Component',type:'STRING',value:obj._type }
		proplist[proplist.length] = { name:'index',type:'READONLY',value:obj.index }

		// build sorted list of settings
		var settings = new Object();
		obj.getSettings(settings);
		var props = new Array();
		for (var mbr in obj) {
			// always show type & index
			if ((null!=settings[mbr]) && (mbr != 'index') && (mbr != '_type')) {
				props[props.length] = mbr;
			}
		}
		props.sort();
	
		for (var i = 0; i < props.length; i++) {
			var mbr = props[i];
			if (settings[mbr] && obj.getProperty) {
				var val = obj.getProperty(mbr);
				var mbrType = settings[mbr];
				// translate type
				switch(mbrType) {
				case 'boolean':
					type = 'BOOLEAN';
					break;
				case 'integer':
				case 'float':
					type = 'NUMBER';
					break;
	
				case 'eventHandler':
					type = 'EXPRESSION_javascript'; // !!!
					type = 'DESCRIPTION';
					break;
				case 'caption':
				case 'length':
				case 'cssClass':
				case 'style':
				case 'string':
					type = 'STRING';
					break;
				default:
					if ('enum'==mbrType.substr(0,4)) {
						var opts = mbrType.split(':')[1].split(',');
						type = 'ENUM^^'+opts.join('^');
					}
					else {
						type = 'STRING';
					}
					break;
				}
				proplist[proplist.length] = { name:mbr,type:type,value:val }
			}
		}
	}

	// update inspector
	this.raiseSelect(proplist);
}

ClientMethod getComponentXML(obj) [ Language = javascript ]
{
	var xml = '<'+obj._type;
	
	for (var mbr in obj) {
		if (('index'!=mbr) && ('_'!=mbr.substr(0,1))) {
			if (obj[mbr] && '' != obj[mbr] && ('function'!=typeof obj[mbr])) {
				if ('object' != typeof obj[mbr]) {
					xml += ' ' + mbr + '="' + obj[mbr] + '"';
				}
			}
		}
	}
	xml += '/>';
	return xml;
}

/// User has changed a property value within the Inspector.
ClientMethod onSetProperty(prop, value) [ Language = javascript ]
{
	if (1 == this.selectedItems.length && null != this.selectedItems[0]) {
		var obj = this.selectedItems[0];

		// cast values from Inspector
		if ('1' == value) { value = 1; }
		if ('0' == value) { value = 0; }

		obj.setProperty(prop,value);
	}
}

ClientMethod onSetDocument(state) [ Language = javascript ]
{
	//zenPage.getComponentById('html').setContent(state);
}

/// This client event, if present, is fired when editor is loaded.
ClientMethod onStartEditor() [ Language = javascript ]
{
	// set initial contents of document window
	// this.raiseDocument(zenPage.getComponentById('html').getContent());
	this.raiseDocument('');
}

/// This client event, if present, is called when this component is
/// instantiated. This allows for any additional client-side 
/// initialization for this object.<br>
/// Note that this <em>must</em> be a client-side method.
ClientMethod onCreate() [ Language = javascript ]
{
	// client-side variables
	this.targetPage = null;
	this.selectedItems = new Array(); // list of selected components
}

}
