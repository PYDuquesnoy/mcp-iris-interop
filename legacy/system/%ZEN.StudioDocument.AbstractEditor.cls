/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for Studio Document editors that use the XEDIT
/// window within Studio.<br>
/// An XEDIT document is a window within Studio with 2 panes: the upper
/// pane contains HTML content, served by a subclass of this class;
/// the lower pane displays an editable XML representation of the data
/// displayed in the upper pane. This XML representation is provided by this
/// class as well.<br>
/// Subclasses of this are used to provide Studio content editors
/// for Abstract documents served by a corresponding subclass of the
/// <class>%ZEN.StudioDocument.AbstractDocument</class> class.
Class %ZEN.StudioDocument.AbstractEditor Extends %ZEN.Component.page [ Abstract, Deprecated, System = 4 ]
{

/// Require %Development:USE for access to subclasses of this page.
Parameter RESOURCE = "%Development:USE";

/// ID of current document.
/// This is provided, as a URL parameter, by the Studio.
Property DocumentID As %ZEN.Datatype.string(ZENURL = "ID");

/// Name of document being edited.
/// This is provided, as a URL parameter, by the Studio.
Property documentName As %ZEN.Datatype.string(ZENURL = "DOC");

/// Indicates that this document is in read only mode.
/// Editors should not set this property; it is set by the Studio.
/// Use the <method>isReadOnly</method> method to observe this.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicates that this document is modified.
/// Use the <method>isModified</method>,<method>setModified</method>,
/// and <method>clearModified</method> methods 
/// to observe and change this.
Property modified As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Current zoom level (as a percentage) of this editor (if applicable).
/// Use the <method>getZoom</method> and <method>setZoom</method> 
/// methods to modify and observe this.
Property zoom As %ZEN.Datatype.float [ InitialExpression = 100 ];

/// Internal property.
/// Client-side flag indicating that this editor is ready to process
/// events from the Studio.
Property editorReady As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

XData Style
{
<style type="text/css">
body {
	background: #C5D6D6;
	font-family: verdana, sans-serif;
}
</style>
}

/// Contents of editor page.
/// Provided by subclass.
XData Contents
{
}

/// Given a document name, strip off the extension and return the class name.
ClassMethod GetClassName(pName As %String) As %String [ CodeMode = expression ]
{
$P(pName,".",1,$L(pName,".")-1)
}

/// This callback is called at the start of the HTML HEAD section of the page.<br>
/// This writes out the JavaScript methods expected by the Studio API.
Method %OnDrawHTMLHead() As %Status
{
	Quit ..%DrawStudioAPI()
}

/// Writes out the JavaScript methods expected by the Studio API.
Method %DrawStudioAPI() As %Status [ Internal ]
{
	&html<
	<script language="JavaScript">

// inspector delimiters
var insDelim1 = '\x01';
var insDelim1a = '\x02';  // used for some message types!
var insDelim2 = '\x03';

// Test if editor is ready to process events
function isEditorReady()
{
	return (zenPage != null && zenPage.editorReady);
}

// Set current state of editor
function document_setDocument(state)
{
	if (isEditorReady() && zenPage.onSetDocument) {
		zenPage.onSetDocument(state);
	}
}

// Get document with current state of editor
// (raise event with current document in it)
function document_getDocument()
{
	if (!isEditorReady()) {
		if (null==zenPage.onGetDocument) {
			zenPage.setResultsDiv('');
		}
		else {
			zenPage.setResultsDiv(zenPage.onGetDocument());
		}
	}
}

// Set a specific property value
function document_setProperty(prop,value)
{
	if (isEditorReady() && zenPage.onSetProperty) {
		zenPage.onSetProperty(prop,value);
	}
}

// Get a specific property value
function document_getProperty(prop)
{
	if (!isEditorReady()) {
		if (null==zenPage.onGetProperty) {
			zenPage.setResultsDiv('');
		}
		else {
			zenPage.setResultsDiv(zenPage.onGetProperty(prop));
		}
	}
}

function document_delete() {
	if (isEditorReady() && zenPage.onCmdDelete) {
		zenPage.onCmdDelete();
	}
}
function document_cut() {
	if (isEditorReady() && zenPage.onCmdCut) {
		zenPage.onCmdCut();
	}
}
function document_copy() {
	if (isEditorReady() && zenPage.onCmdCopy) {
		zenPage.onCmdCopy();
	}
}
function document_undo() {
	if (isEditorReady() && zenPage.onCmdUndo) {
		zenPage.onCmdUndo();
	}
}
function document_canUndo() {
	if (!isEditorReady()) {
		if (null==zenPage.onCanUndo) {
			zenPage.setResultsDiv(0);
		}
		else {
			zenPage.setResultsDiv(zenPage.onCanUndo() ? 1 : 0);
		}
	}
}
function document_isModified() {
	if (!isEditorReady()) {
		zenPage.setResultsDiv(zenPage.modified ? 1 : 0);
	}
}
function document_redo() {
	if (isEditorReady() && zenPage.onCmdRedo) {
		zenPage.onCmdRedo();
	}
}
function document_paste() {
	if (isEditorReady() && zenPage.onCmdPaste) {
		zenPage.onCmdPaste();
	}
}
function document_getZoom() {
	if (!isEditorReady()) {
		zenPage.setResultsDiv(zenPage.getZoom());
	}
}

function document_setZoom(zoom) {
	if (isEditorReady()) {
		zenPage.setZoom(zoom);
	}
}
function document_setReadOnly(ro) {
	if (isEditorReady() && zenPage.onSetReadyOnly) {
		zenPage.readOnly = (ro ? true : false);
		zenPage.onSetReadyOnly();
	}
}
	</script>
	>
	Quit $$$OK
}

/// This callback is called at the start of the HTML BODY section of the page.<br>
/// This writes out the "result" div expected by the Studio API.
Method %OnDrawHTMLBody() As %Status [ Internal ]
{
	&html<<xml id="results" style="display:none;"></xml>>
	Quit $$$OK
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.editorReady = true;

	if (this.onStartEditor) {
		this.onStartEditor();
	}
}

/// This client event, if present, is fired when editor is loaded.
ClientMethod onStartEditor() [ Language = javascript ]
{
	// set initial contents of document window
	this.raiseDocument('');
}

/// Set contents of results div used to pass data to Studio.
ClientMethod setResultsDiv(data) [ Language = javascript ]
{
	var div = self.document.getElementById('results');
	if (div) {
		div.innerHTML = data;
	}
}

/// Raise a named event for Studio to catch.
ClientMethod raiseEvent(type) [ Language = javascript ]
{
	if (isNaN(this.extCounter)) {
		this.extCounter = 1;
	}

	if (this.editorReady) {
		self.document.title = type + ':' + this.extCounter++;
	}
}

/// Raise a 'document' event to Studio.<br>
/// This will set the contents of the XML pane within the Studio edit window,
/// if applicable. <var>state</var> is the text that will be placed within
/// the edit window.
ClientMethod raiseDocument(state) [ Language = javascript ]
{
	state = (null==state) ? '' : state;
	this.setResultsDiv(state);
	this.raiseEvent('document');
}

/// Raise an OPENDOC event to Studio.<br>
/// <var>doc</var> is the full name (with extension) of the
/// document for Studio to open.
ClientMethod raiseOpenDocument(doc) [ Language = javascript ]
{
	if (!zenIsMissing(doc)) {
		this.setResultsDiv(doc);
		this.raiseEvent('OPENDOC');
	}
}

/// Raise a SELECT event to Studio.<br>
/// This will update the Studio Inspector.<br>
/// <var>proplist</var> is a list of property values for inspector to show.
/// The first property in the list is the Name of selected item.
/// <var>proplist</var> is an array of objects of the form:<br>
/// proplist[n] = obj;<br>
/// obj.name = 'name of property'<br>
/// obj.type = 'type' (STRING,INTEGER, etc.)<br>
/// obj.value = value<br>
ClientMethod raiseSelect(proplist) [ Language = javascript ]
{
	var state = '';

	// loop over proplist
	if (proplist) {
		for (var p = 0; p < proplist.length; p++) {
			var item = proplist[p];
			if (item) {
				state += (item.name?item.name:'?') + insDelim2 + (item.type?item.type:'STRING') + insDelim2 + (item.value?item.value:'') + insDelim1;
			}
		}
	}
	
	// place state into results div
	this.setResultsDiv(state);

	// raise event
	this.raiseEvent('SELECT');
}

/// Notification that the user has changed the XML version of this
/// document.<br>
/// <var>state</var> is the contents of the XML editor pane.
ClientMethod onSetDocument(state) [ Language = javascript ]
{
}

/// Get document with current state of editor
/// (raise event with current document in it)
ClientMethod onGetDocument() [ Abstract, Language = javascript ]
{
}

/// Notification that the user has changed a property using
/// the Inspector.<br>
/// <var>prop</var> is the property name, <var>value</var> is the
/// new value.
ClientMethod onSetProperty(prop, value) [ Abstract, Language = javascript ]
{
}

/// Return the value of a specific property value from the editor.
ClientMethod onGetProperty(prop) [ Abstract, Language = javascript ]
{
}

/// Notification that user has invoked the delete command.
ClientMethod onCmdDelete() [ Abstract, Language = javascript ]
{
}

/// Notification that user has invoked the cut command.
ClientMethod onCmdCut() [ Abstract, Language = javascript ]
{
}

/// Notification that user has invoked the copy command.
ClientMethod onCmdCopy() [ Abstract, Language = javascript ]
{
}

/// Notification that user has invoked the undo command.
ClientMethod onCmdUndo() [ Abstract, Language = javascript ]
{
}

/// Test if undo is possible.
ClientMethod onCanUndo() [ Abstract, Language = javascript ]
{
}

/// Notification that user has invoked the redo command.
ClientMethod onCmdRedo() [ Abstract, Language = javascript ]
{
}

/// Notification that user has invoked the paste command.
ClientMethod onCmdPaste() [ Abstract, Language = javascript ]
{
}

/// Notification that the zoom level of the editor has changed.
ClientMethod onSetZoom() [ Abstract, Language = javascript ]
{
}

/// Notification that Studio has modified the ReadOnly state of the editor.
ClientMethod onSetReadOnly() [ Abstract, Language = javascript ]
{
}

/// Return the ReadOnly state of the editor.
ClientMethod isReadOnly() [ Language = javascript ]
{
	return this.readOnly;
}

/// Return the zoom level of the editor.
ClientMethod getZoom() [ Language = javascript ]
{
	return this.zoom;
}

/// Set the zoom level of the editor.
ClientMethod setZoom(zoom) [ Language = javascript ]
{
	this.zoom = zoom;
	if (this.onSetZoom) {
		this.onSetZoom();
	}
}

/// Test if the document is modified.
ClientMethod isModified() [ Language = javascript ]
{
	return this.modified;
}

/// Set the modified flag for this editor.
ClientMethod setModified() [ Language = javascript ]
{
	this.modified = true;
}

/// Clear the modified flag for this editor.
ClientMethod clearModified() [ Language = javascript ]
{
	this.modified = false;
}

}
