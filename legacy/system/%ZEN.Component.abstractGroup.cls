/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract container component.
/// This is the base class from which various types of grouping elements are derived.
Class %ZEN.Component.abstractGroup Extends component [ Abstract, Deprecated, System = 3 ]
{

Parameter SYSMODULE = "core";

/// Subclasses can set this to change default css class for a group.
Parameter DEFAULTGROUPCLASS As STRING = "group";

/// Set of components within this group.
Property children As list Of component(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// If true, this group and its children are disabled.
Property disabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Internal property.<br/>
/// If true, this group was only partially serialized on the client
/// (it is the ancestor of the object being serialized) 
/// and we should ignore changes made to the children array when
/// shipping changes back to the client.
Property %partial As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// This is an internal method that does the actual work of adding a
/// child component to a group.<br>
/// Applications should not call this, instead use <method>%AddChild</method>,
/// <method>%AddChildAfter</method>, and <method>%AddChildBefore</method>.
Method %ReallyAddChild(pComponent As %ZEN.Component.object, pSibling As %ZEN.Component.object = "", pBefore As %Boolean = 0) As %Status [ GenerateAfter = %AddChild, Internal ]
{
	Set tSC = $$$OK

	#; if pSibling is provided, make sure it is in the list
	Set tIndex = 0
	If (pSibling '= "") {
		Set tIndex = ..%GetChildIndex(pSibling)
		Quit:(tIndex<1) $$$ERROR($$$GeneralError,"pSibling is not a member of this group.")
	}

	#; add component to page
	If $IsObject($G(%page)) {
		Set tSC = %page.%AddComponent(pComponent)
		#; if we failed to get added to page, set page error and quit
		If $$$ISERR(tSC) {
			Set %zenPageError = tSC
			Quit tSC
		}
	}

	#; add component to our list of children
	If (tIndex < 1) {
		Do ..children.Insert(pComponent)
	}
	Else {
		Do ..children.InsertAt(pComponent,$S(pBefore:tIndex,1:tIndex+1))
	}
	Set pComponent.parent = ##this
	Set x = ..%OnMutateChildren(1)
	Quit tSC
}

/// Add a child component <var>pComponent</var> to this group.<br>
/// This is called when the server component tree is being created.
/// This also adds <var>pComponent</var> to the page that this group 
/// belongs to; this group must be added to a page before adding any child
/// components to it. In addition, the <property>id</property> property
/// of the component <em>must</em> be set before calling this method.
Method %AddChild(pComponent As %ZEN.Component.object) As %Status [ CodeMode = expression, Final ]
{
..%ReallyAddChild(pComponent)
}

/// Add a child component <var>pComponent</var> to this group immediately
/// <em>before</em> component <var>pSibling</var>.<br>
/// If <var>pSibling</var> is not a member of this group, this method will fail.<br>
/// This is called when the server component tree is being created.
/// This also adds <var>pComponent</var> to the page that this group 
/// belongs to; this group must be added to a page before adding any child
/// components to it. In addition, the <property>id</property> property
/// of the component <em>must</em> be set before calling this method.
Method %AddChildBefore(pComponent As %ZEN.Component.object, pSibling As %ZEN.Component.object = "") As %Status [ CodeMode = expression, Final ]
{
..%ReallyAddChild(pComponent,pSibling,1)
}

/// Add a child component <var>pComponent</var> to this group immediately
/// <em>after</em> component <var>pSibling</var>.<br>
/// If <var>pSibling</var> is not a member of this group, this method will fail.<br>
/// This is called when the server component tree is being created.
/// This also adds <var>pComponent</var> to the page that this group 
/// belongs to; this group must be added to a page before adding any child
/// components to it. In addition, the <property>id</property> property
/// of the component <em>must</em> be set before calling this method.
Method %AddChildAfter(pComponent As %ZEN.Component.object, pSibling As %ZEN.Component.object = "") As %Status [ CodeMode = expression, Final ]
{
..%ReallyAddChild(pComponent,pSibling,0)
}

/// Remove child component <var>pComponent</var> from this group.
/// Returns true if the component was found and removed.
Method %RemoveChild(pComponent As %ZEN.Component.object) As %Boolean
{
	#; find child in our list of children
	Set tFound = 0
	For n=1:1:..children.Count() {
		If (pComponent = ..children.GetAt(n)) {
			#; remove component from our list of children
			Do ..children.RemoveAt(n)
			Set tFound = 1
			Quit
		}
	}

	#; this is not our child
	Quit:'tFound 0

	#; if component is a group, remove its children also
	If (pComponent.%IsA("%ZEN.Component.group")) {
		Do pComponent.%RemoveChildren()
	}

	#; remove component from the page
	If $IsObject($G(%page)) {
		Do %page.%RemoveComponent(pComponent)
	}

	#; clear component's parent
	Set pComponent.parent = ""
	Set x = ..%OnMutateChildren(0)
	Quit 1
}

/// Remove all children from this group.
/// If <var>pDynamicOnly</var> is true, then only delete components
/// whose <property>dynamic</property> is set to true.
Method %RemoveChildren(pDynamicOnly As %Boolean = 0)
{
	Set tSkip = 0
	For n=1:1:..children.Count() {
		Set tComponent = ..children.GetAt(n)
		If (pDynamicOnly && tComponent.%IsA("%ZEN.Component.component") && 'tComponent.dynamic) {
			Set tSkip = 1
			#; if component is a group, pass this along
			If (tComponent.%IsA("%ZEN.Component.group")) {
				Do tComponent.%RemoveChildren(pDynamicOnly)
			}
		}
		Else {
			Set tComponent.parent = ""

			#; if component is a group, remove its children also
			If (tComponent.%IsA("%ZEN.Component.group")) {
				Do tComponent.%RemoveChildren(pDynamicOnly)
			}

			#; remove component from the page
			If $IsObject($G(%page)) {
				Do %page.%RemoveComponent(tComponent)
			}
		}
	}
	If ('tSkip) {
		Do ..children.Clear()
	}
	Else {
		#; remove only dynamic components
		For n=..children.Count():-1:1 {
			Set tComponent = ..children.GetAt(n)
			If (tComponent.%IsA("%ZEN.Component.component") && tComponent.dynamic) {
				Do ..children.RemoveAt(n)
			}
		}
	}
	Set x = ..%OnMutateChildren(0)
}

/// Notification that children have been added or removed from this group. 
Method %OnMutateChildren(pAdd As %Boolean) As %Boolean [ CodeMode = expression ]
{
1
}

/// Server-only method: Look for the given child object within this group's set of
/// children and return its 1-based index number.<br>
/// Returns -1 if unable to find the child.
Method %GetChildIndex(pChild As %ZEN.Component.component) As %Integer
{
	Set tIndex = -1

	Set tCount = ..children.Count()
	For n=1:1:tCount {
		If (pChild = ..children.GetAt(n)) {
			Set tIndex = n
			Quit
		}
	}
	Quit tIndex
}

/// Client-side method.<br>
/// Dynamically add a component to this group on the client.<br>
/// If <var>refresh</var> is true, then refresh the contents of this group
/// to show the new component.
ClientMethod addChild(component, refresh) [ Language = javascript ]
{
	zenASSERT(component && zenIsComponent(component),'Invalid component',arguments);
	if (!component.isOfType('component')) {
		alert('Only HTML components can be added to groups');
		return;
	}
	this.children[this.children.length] = component;
	component.parent = this;
	if (this.childrenMutated) {
		this.childrenMutated();
	}
	if (refresh) {
		this.refreshContents();
	}
	if (component.id!="") {
		_zenIds[component.id]=component;
	}
}

/// Client-side method.<br>
/// Dynamically add a component to this group on the client after component
/// <var>sibling</var>.<br>
/// If <var>refresh</var> is true, then refresh the contents of this group
/// to show the new component.
ClientMethod addChildAfter(component, sibling, refresh) [ Language = javascript ]
{
	zenASSERT(component && zenIsComponent(component),'Invalid component',arguments);
	if (!component.isOfType('component')) {
		alert('Only HTML components can be added to groups');
		return;
	}
	var index = this.getChildIndex(sibling);
	if (index < 0) {
		alert('addChildAfter: sibling is not in this group');
		return;
	}
	// place child into list
	this.children.splice(index+1,0,component);
	component.parent = this;
	if (this.childrenMutated) {
		this.childrenMutated();
	}
	if (refresh) {
		this.refreshContents();
	}
	if (component.id!="") {
		_zenIds[component.id]=component;
	}
}

/// Client-side method.<br>
/// Dynamically add a component to this group on the client before component
/// <var>sibling</var>.<br>
/// If <var>refresh</var> is true, then refresh the contents of this group
/// to show the new component.
ClientMethod addChildBefore(component, sibling, refresh) [ Language = javascript ]
{
	zenASSERT(component && zenIsComponent(component),'Invalid component',arguments);
	if (!component.isOfType('component')) {
		alert('Only HTML components can be added to groups');
		return;
	}
	var index = this.getChildIndex(sibling);
	if (index < 0) {
		alert('addChildBefore: sibling is not in this group');
		return;
	}
	// place child into list
	this.children.splice(index,0,component);
	component.parent = this;
	if (this.childrenMutated) {
		this.childrenMutated();
	}
	if (refresh) {
		this.refreshContents();
	}
	if (component.id!="") {
		_zenIds[component.id]=component;
	}
}

/// Notification to subclasses that a child has been added or removed
/// from this group.
ClientMethod childrenMutated() [ Abstract, Language = javascript ]
{
}

/// Client-side method.<br>
/// Dynamically remove a component from this group on the client.
ClientMethod removeChild(component) [ Language = javascript ]
{
	// get the page to do the work
	zenPage.deleteComponent(component);
	if (this.childrenMutated) {
		this.childrenMutated();
	}
}

/// Look for the given child object within this group's set of
/// children and return its 0-based index number.<br>
/// Returns -1 if unable to find the child.
ClientMethod getChildIndex(child) [ Language = javascript ]
{
	for (var n = 0; n < this.children.length; n++) {
		if (this.children[n] == child) {
			return n;
		}
	}
	return -1;
}

/// This manages the ondisplay event callback handling.  The display event
/// fires when the page is first displayed, when the component or its containing
/// group is refreshed from the server, or when the component or its containing
/// group is displayed via a programmatic 'show()' call.  Note that setting the
/// style.display value from JavaScript DOES NOT trigger this event. In general,
/// application code should not modify or overload this method; instead, use the
/// onDisplayHandler() to customize this processing.
ClientMethod exposeComponent() [ Language = javascript ]
{
	try {
		var div = this.getEnclosingDiv();
		if (!div) return;
		if (div.offsetWidth == 0 || div.offsetHeight == 0) return;
		if (this.onDisplayHandler) {
			this.onDisplayHandler();
		}
		for (var n = 0; n < this.children.length; n++) {
			this.children[n].exposeComponent();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in exposeComponent.');
	}
}

/// Set overlay mode for each child of this group.
ClientMethod setOverlayMode(mode) [ Language = javascript ]
{
	this.overlayMode = mode;

	for (var n = 0; n < this.children.length; n++) {
		this.children[n].setOverlayMode(mode);
	}
}

/// Apply the given value to the specified property for
/// this group and all of its children.<br>
/// Note that this will not work for 'disabled'; for that
/// use <method>setProperty</method>.
ClientMethod setPropertyAll(property, value, value2) [ Language = javascript ]
{
	if ('disabled' == property) return;
	
	this.setProperty(property, value, value2);

	// pass to all of our children
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (child.setPropertyAll) {
			child.setPropertyAll(property,value,value2);
		}
		else {
			child.setProperty(property,value,value2);
		}
	}
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'disabled':
		value = (value) ? true : false;
		this.disabled = value;
		// now enable/disable all of our children
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			child.setProperty(property,value);
		}
		// notify
		if (this.ondisabledHandler) {
			this.ondisabledHandler();
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Client-side method that is called when a group's disabled
/// state changes. This gives subclasses a chance to update their
/// style when they are enabled/disabled.
ClientMethod ondisabledHandler() [ Abstract, Language = javascript ]
{
	return;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.disabled && this.parent && !this.parent.disabled) {
		// if we are disabled, make sure our children
		// are disabled when this component is first loaded
		this.setProperty('disabled',true);
	}
}

/// Apply the current control values to all controls within a modalGroup.
ClientMethod updateControlsInGroup() [ Internal, Language = javascript ]
{
	// pass to all of our children
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (child.updateControlsInGroup) {
			child.updateControlsInGroup();
		}
		else if (child.setValue) {
			if (typeof(child.src)!="undefined") {
			}
			else {
				child.setValue(child.value);
			}
		}
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onRefreshContents() [ Language = javascript ]
{
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (child.onRefreshContents) child.onRefreshContents();
		zenInvokeCallbackMethod(child.onrefresh,child,'onrefresh');
	}
}

}
