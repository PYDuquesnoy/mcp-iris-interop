/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for controls.<br>
/// A control is a specialized type of component that can be placed within a form. Typically
/// controls are used to allow the user to display and edit values (such as <class>text</class> controls) or
/// to let the user take actions (such as <class>button</class> controls).<br>
/// Most controls define a value (via the <property>value</property>) that is the data value
/// associated with the control. This value can be submitted to the server as part of a <class>form</class> submit
/// operation.<br> 
/// Controls define a set of common event handler properties, such as <property>onclick</property> that
/// let you define a JavaScript expression that is executed when a given event occurs within the control.<br>
/// Using the ZEN Model-View-Controller mechanism, you can bind data values to controls within
/// a <class>form</class>. This provides a way to automatically set the value of a control to a property 
/// within a DataModel object.<br>
/// Controls work together with a <class>form</class> to provide support for data validation and change tracking.
/// Each control can define whether its current value is valid or not.<br/>
/// By default controls support drag-and-drop in the following way:<br/>
/// A drag from a control will drag the current value of the control.<br/>
/// A drop onto a control will set the current value of the control to the value
/// of the drag data object. The text value is used if different than the logical value.
Class %ZEN.Component.control Extends component [ Abstract, Deprecated, System = 3 ]
{

Parameter SYSMODULE = "form";

/// The default css class used for the main element within this control. This
/// is overridden by subclasses.
Parameter DEFAULTCONTROLCLASS As STRING;

/// The default value for the <property>clientType</property> property.
Parameter DEFAULTCLIENTTYPE As STRING;

/// Default value displayed within this control.
/// This is a special value in that it is automatically intialized
/// when a form is displayed.<br>
/// Do not use this property directly on the client; instead
/// used the <method>getValue</method> method to get the current value of a control.
Property value As %ZEN.Datatype.value(ZENEXPRESSION = 1);

/// Original value for this control before any user modification.
/// It is used to detect which controls have been modified.<br>
/// This is a special value in that it is automatically intialized
/// when a form is displayed.<br>
/// Do not use this property directly on the client; instead
/// used the <method>getProperty</method> method.<br>
/// Note that setting this on the client (via <method>setProperty</method>)
/// will reset it to the current value of this control.
Property originalValue As %ZEN.Datatype.value;

/// Indicates the client-side (JavaScript) type that should be used for this control's value.<br>
/// By default controls treat their values as strings with no client-side normalization.<br>
/// A control, or a page containing the control, can override this to
/// indicate that this control displays a non-string value. The client-side
/// logic will then try to convert the value to the appropriate client-side type
/// whenever the value of the control is set.<br>
/// Possible values are:
/// <ul>
/// <li>'string' - the control will trim leading and trailing spaces from its value.</li> 
/// <li>'boolean' - the control will convert its value to true or false.</li> 
/// <li>'integer' - the control will convert its value to an integer or '' for an invalid integer.</li> 
/// <li>'float' - the control will convert its value to an float or '' for an invalid float.</li> 
/// </ul>
Property clientType As %ZEN.Datatype.string(VALUELIST = ",string,boolean,integer,float") [ InitialExpression = {..#DEFAULTCLIENTTYPE} ];

/// Optional CSS class used for the primary HTML element displayed for this control.
Property controlClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTCONTROLCLASS} ];

/// If defined, this is used to provide a value for the HTML tabIndex
/// attribute. This is used by the browser to control the tab order of
/// controls within a form.
Property tabIndex As %ZEN.Datatype.integer;

/// Optional CSS style applied to the primary HTML element displayed for this control.<br>
/// How, and whether, this CSS style is used is up to the actual control implementation.<br>
/// This property is provided as a convenience.
/// It is more typical to provide style information via a style sheet.
Property controlStyle As %ZEN.Datatype.style;

/// onchange event handler:
/// This event is fired when the value of the control changes.
/// Note that controls fire this event indirectly; the actual
/// onchange event is sent to a built-in handler that notifies
/// the form that owns this control of the modification.
Property onchange As %ZEN.Datatype.eventHandler(HANDLER = """_..%Self()_"".onchangeHandler();");

/// onclick event handler:
/// This event is fired when the mouse is clicked on the control.
Property onclick As %ZEN.Datatype.eventHandler;

/// ondblclick event handler:
/// This event is fired when the mouse is double-clicked on the control.
Property ondblclick As %ZEN.Datatype.eventHandler;

/// onfocus event handler:
/// This event is fired when the control is given focus.
Property onfocus As %ZEN.Datatype.eventHandler;

/// onblur event handler:
/// This event is fired when the control loses focus.
Property onblur As %ZEN.Datatype.eventHandler;

/// onkeypress event handler:
/// This event is fired when a key is pressed when this control has focus.
Property onkeypress As %ZEN.Datatype.eventHandler;

/// onkeydown event handler:
/// This event is fired when a key is pressed when this control has focus.
Property onkeydown As %ZEN.Datatype.eventHandler;

/// onkeyup event handler:
/// This event is fired when a key is released when this control has focus.
Property onkeyup As %ZEN.Datatype.eventHandler;

/// onmouseout event handler:
/// This event is fired when the mouse pointer leaves the area of the control.
Property onmouseout As %ZEN.Datatype.eventHandler;

/// onmouseover event handler:
/// This event is fired when the mouse pointer enters the area of the control.
Property onmouseover As %ZEN.Datatype.eventHandler;

/// onmouseup event handler:
/// This event is fired when a mouse button is pressed while within the area of the control.
Property onmouseup As %ZEN.Datatype.eventHandler;

/// onmousedown event handler:
/// This event is fired when a mouse button is released while within the area of the control.
Property onmousedown As %ZEN.Datatype.eventHandler;

/// ontouchstart event handler:
/// This event is fired on a touch screen device when a figure or stylus initially contacts 
/// the screen within the area of the control.
Property ontouchstart As %ZEN.Datatype.eventHandler;

/// ontouchend event handler:
/// This event is fired on a touch screen device when the last figure or stylus breaks contact 
/// the screen at the end of a gesture.
Property ontouchend As %ZEN.Datatype.eventHandler;

/// ontouchmove event handler:
/// This event is fired on a touch screen device when the one or more of the active contact points
/// changes position as part of a gesture input. 
Property ontouchmove As %ZEN.Datatype.eventHandler;

/// onvalidate event handler:
/// This event is fired when this control's value is validated
/// by its parent form. Return false if the value of this control
/// is invalid.
Property onvalidate As %ZEN.Datatype.eventHandler(HANDLER = "");

/// onsubmit event handler:
/// This event is fired when the form this control belongs to is submitted.
/// This gives controls a chance to supply or modify the value they submit.
Property onsubmit As %ZEN.Datatype.eventHandler(HANDLER = "");

/// If true, this control is disabled.
Property disabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this control is readOnly.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this control is required. That is, a user must supply a 
/// value for this control or the default form validation logic will fail.
Property required As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Set this true when the value of this control is known to be
/// invalid. Typically this is done by the form validation logic to
/// to display this in a way that indicates it contains an invalid value.
Property invalid As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Value displayed in alert box by the form <method>validate</method>
/// method when the contents of this control are invalid.<br>
/// This is a localized value.
Property invalidMessage As %ZEN.Datatype.caption [ InitialExpression = "out-of-range or invalid value." ];

/// Value displayed in alert box by the form <method>validate</method>
/// method when this control is required and does not have a value.<br>
/// This is a localized value.
Property requiredMessage As %ZEN.Datatype.caption [ InitialExpression = "required." ];

/// Optional. If this control belongs to a form that is associated with
/// a dataController, this specifies the name of the property within the dataController
/// that will provide the value for this control.
Property dataBinding As %ZEN.Datatype.string;

/// Utility method used by subclasses to write out the
/// <b>name</b>attribute for the primary HTML element of this control.<br>
/// Names are of the form: $V_id<br/>
/// If name starts with "IRIS" or "Cache" then it is assumed to be a built-in
/// variable and is not escaped.
Method %Name() As %String [ CodeMode = expression ]
{
$S((($L(..name)>5)&&($e(..name,1,5)="Cache"))||(($L(..name)>4)&&($e(..name,1,4)="IRIS")):"name="""_..name_"""",$$$ZENVAL(..name)="":"",1:"name=""$V_"_$S($IsObject(..composite):$S(..composite.id="":"id"_..composite.index,1:..composite.id)_".",1:"")_$$$ZENVALHTML(..name)_"""")
}

/// Client-side version of the <method>%Name</method> method.
/// Use this to contruct control names when creating controls
/// via DHTML that may be submitted by a Zen form.
ClientMethod sysName() [ Language = javascript ]
{
	var name = '';
	if (''==this.name) {
		name = '$V_' + ((this.composite) ? (this.composite.id=='' ? this.composite.index : this.composite.id)+'.':'') + this.id;
	}
	else if (('Cache'==this.name.substr(0,5))||('IRIS'==this.name.substr(0,4))) {
		name = this.name;
	}
	else {
		name = '$V_' + this.name;
	}
	return name;
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as the Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
}

/// Intercept this internal method so that we do not have
/// to copy code into every control.
Method ReallyRefreshContents() [ Final, Internal, ZenMethod ]
{
	Do ##super()
}

/// Server-side method.
/// Find the form object that this control belongs to.
/// Return "" if there is no form.
Method %GetForm() As %ZEN.Component.form
{
	Set tForm = ""
	Set tParent = ..parent
	While ($IsObject(tParent)) {
		If (tParent.%IsA("%ZEN.Component.form")) {
			Set tForm = tParent
			Quit
		}
		Set tParent = tParent.parent
	}
	Quit tForm
}

/// Client-side method to set disabled state of this control.
ClientMethod setDisabled(flag) [ Final, Language = javascript ]
{
	this.setProperty('disabled',flag);
}

/// Client-side method to get the disabled state of this control.
ClientMethod getDisabled() As %Boolean [ Final, Language = javascript ]
{
	return this.getProperty('disabled');
}

/// Client-side method to set disabled state of this control.
ClientMethod setReadOnly(flag) [ Final, Language = javascript ]
{
	this.setProperty('readOnly',flag);
}

/// Client-side method to get the disabled state of this control.
ClientMethod getReadOnly() As %Boolean [ Final, Language = javascript ]
{
	return this.getProperty('readOnly');
}

/// Client-side method to set the value associated with this control.
/// <var>value2</var> is an optional, second parameter used by some controls
/// (such as <class>dataCombo</class>).
ClientMethod setValue(value, value2) [ Final, Language = javascript ]
{
	var oldValue = this.value;	
	this.setProperty('value',value,value2);
	var form = this.getForm();
	if (form && form.propagateChanges) {
		if (this._initialized && oldValue===this.value) return;
		this.onchangeHandler();
		this._initialized = true;
	}
}

/// Client-side method to return the value associated with this control.
ClientMethod getValue() As %String [ Final, Language = javascript ]
{
	return this.getProperty('value');
}

/// Normalize the type of <var>val</var> based on the <property>clientType</property>
/// of this control.
ClientMethod normalizeValue(val) As %String [ Language = javascript ]
{
	switch(this.clientType) {
	case 'boolean':
		if ((''==val)&&('string'==typeof val)) { val = false; }
		else if (('true'==val)||('on'==val)) { val = true; }
		else if (('false'==val)||('off'==val)||('0'==val)) { val = false; }
		else { val = val ? true : false; }
		break;
	case 'integer':
		if (!((''==val)&&('string'==typeof val))) {
			val = parseInt(val,10);
			val = isNaN(val) ? '' : val;
		}
		break;
	case 'float':
		if (!((''==val)&&('string'==typeof val))) {
			val = parseFloat(val);
			val = isNaN(val) ? '' : val;
		}
		break;
	case 'string':
		val = zenTrim(val);
		break;
	}
	return val;
}

/// This is called when the client serializes this object.<br>
/// This gives us a chance to make sure that the value property
/// is updated to have the current value displayed within the control.
/// This version will take care of this for native controls.
/// Custom controls must either ensure that the value property matches
/// the current value of the control or override this method.
ClientMethod onSerialize() [ Language = javascript ]
{
	var el = this.findElement('control');
	if (el) {
		this.value = this.normalizeValue(this.unformatValue ? this.unformatValue(el.value) : el.value);
	}
}

/// If defined, convert display value of this control to its internal value.
ClientMethod unformatValue(val) [ Abstract, Language = javascript ]
{
}

/// If defined, convert the internal value of this control into a display value.
ClientMethod formatValue(val) [ Abstract, Language = javascript ]
{
}

/// Override to get current value of control.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'value':
		if (el) { 
			this.value = this.unformatValue ? this.unformatValue(el.value) : el.value;
		}
		return this.normalizeValue(this.value);
	}

	// dispatch
	return this.invokeSuper('getProperty',arguments);
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var retVal = true; 
	var el = this.findElement('control');
	switch(property) {
	case 'value':
		value = this.normalizeValue(value);
		if (el) { 
			el.value = this.formatValue ? this.formatValue(value) : value;
		}
		this.value = value;
		break;
	case 'clientType':
		this.clientType = value;
		break;
	case 'originalValue':
		// special case: setting this *always* copies the value
		// from this.value
		this.originalValue = this.value;
		break;
	case 'required':
		value = (value) ? true : false;
		this.required = value;
		break;
	case 'invalid':
		value = (value) ? true : false;
		this.invalid = value;
		var errClass = 'zenInvalid'
		if (this.controlClass) errClass = this.controlClass+' zenInvalid';
		if (el) { el.className = (value ? errClass : this.controlClass);}
		break;
	case 'controlClass':
		this.controlClass = value;
		var errClass = 'zenInvalid'
		if (this.controlClass) errClass = this.controlClass+' zenInvalid';
		if (el) { el.className = (this.invalid ? errClass : this.controlClass);}
		break;
	case 'controlStyle':
		this.controlStyle = value;
		if (el) { el.style.cssText = value;	}
		break;
	case 'disabled':
		value = (value) ? true : false;
		if (el) { el.disabled = value;	}
		this.disabled = value;
		// change label style
		var lbl = this.getLabelElement();
		if (lbl) {
			if (this.disabled) {
				lbl.className = (''==this.labelDisabledClass) ? 'zenLabelDisabled' : this.labelDisabledClass ;
			}
			else {
				lbl.className = (''==this.labelClass) ? 'zenLabel' : this.labelClass;
			}
		}
		break;
	case 'readOnly':
		value = (value) ? true : false;
		if (el) { el.readOnly = value;	}
		this.readOnly = value;
		break;
	case 'title':
		if (el) { el.title = value;	}
		this.title = value;
		var label = this.getLabelElement();
		if (label) {
			label.title = value;
		}		
		break;

	case 'onchange':
		this.onchange = value;
		break;

	case 'onclick':
	case 'ondblclick':
	case 'onfocus':
	case 'onblur':
	case 'onkeypress':
	case 'onkeydown':
	case 'onkeyup':
	case 'onmouseout':
	case 'onmouseover':
	case 'onmouseup':
	case 'onmousedown':
	case 'ontouchstart':
	case 'ontouchmove':
	case 'ontouchend':
		this[property] = value;
		if (el) {
			// escape
			var expr = value.toString();
			expr = expr.replace(/\\/g,'\\\\'); // escape any backslash
			expr = expr.replace(/\"/g,'\\\"'); // escape any quotes
			expr = expr.replace(/\'/g,"\\\'"); // escape any single quotes
			el[property] = new Function('event','return zenFireEvent('+this.index+',"'+expr+'","'+property+'",event)');
		}
		break;

	default:
		// dispatch
		var oldSyncMode = zenSynchronousMode;
		zenSynchronousMode = true;
		retVal = this.invokeSuper('setProperty',arguments);
		zenSynchronousMode = oldSyncMode;
	}
	return retVal;
}

/// Client-side method to give input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	// default implementation
	var el = this.findElement('control');
	if (el) {
		try {
			el.focus();
		}
		catch(ex) {
			// swallow errors if control cannot take focus.
		}
	}
}

/// Client-side method to select the contents of this control.
ClientMethod select() [ Language = javascript ]
{
	// default implementation
	var el = this.findElement('control');
	if (el) {
		el.select();
	}
}

/// This built-in event handler is called by the HTML control
/// associated with the control to raise notification that 
/// the control's value has changed.
ClientMethod onchangeHandler() [ Language = javascript ]
{
	// force HTML value into value property
	var value = this.getValue();

	// notify our form of the change
	var form = this.getForm();
	if (form) {
		form.controlChangeHandler(this);
	}

	// if we are invalid, see if new value makes us valid
	if (this.invalid && this.validationHandler()) {
		this.setProperty('invalid',false);
	}

	// call user event handler 
	zenInvokeCallbackMethod(this.onchange,this,'onchange');
}

/// Return true if the current value of this control is different
/// than its orginal value.
ClientMethod isModified() [ Language = javascript ]
{
	return this.value != this.originalValue;
}

/// Find the form object that this control belongs to.
/// Return null if there is no form.
ClientMethod getForm() [ Language = javascript ]
{
	var form = null;
	var parent = this.parent;
	while (parent) {
		if (parent.isOfType('form') || parent.isOfType('loginForm')) {
			form = parent;
			break;
		}
		parent = parent.parent;
	}
	return form;
}

/// This client-side method is called by the form object's
/// <method>validate</method> to test if the contents of this
/// control are valid.<br>
/// This method does the following:<br>
/// <ul>
/// <li>If this control is required, it tests that a value has been supplied.</li>
/// <li>If this control has an onvalidate callback defined, it calls it.</li>
/// <li>Otherwise, it invokes the <method>isValid</method> method for this control to perform control-specific validation logic.</li>
/// </ul>
/// Readonly and disabled controls are always considered to be valid.
/// A subclass can override this method to provide additional
/// behavior, but the overridden method should perform the above actions.<br>
/// Returns true if the control value is valid; false otherwise.
ClientMethod validationHandler() [ Language = javascript ]
{
	if (this.readOnly || this.disabled) {
		return true;
	}

	// test for empty value
	if (zenIsMissing(this.getValue())) {
		// if not required, empty string is always valid
		return !this.required;
	}

	// test for event handler
	if (this.onvalidate) {
		return zenInvokeCallbackMethod(this.onvalidate,this,'onvalidate');
	}

	// invoke isValid method
	return this.isValid();
}

/// This method is called by the form validation mechanism to test
/// if the current contents of this control are valid.<br>
/// Returns true if the control value is valid; false otherwise.
/// Subclasses can override this to provide specific behavior.<br>
/// The default behavior is to return true.
ClientMethod isValid() [ Language = javascript ]
{
	return true;
}

/// This method is called by the form validation mechanism
/// in order to get an invalid message to display for this
/// control.<br>
/// This is called by the form's <method>validate</method> method
/// after it has determined that this control has an invalid value.
ClientMethod getInvalidReason() [ Language = javascript ]
{
	// test for required
	if (this.required && zenIsMissing(this.getValue())) {
		return this.label + ' ' + this.requiredMessage;
	}
	return this.label + ' ' + this.invalidMessage;
}

/// Fill in the zenDragData object for this control.
/// This is called when a drag operation starts on this control.
/// Subclasses can override this to provide customized behavior.
ClientMethod getDragData(dragData) [ Language = javascript ]
{
	dragData.value = this.getValue();
	if (null != this.text) {
		// if there is a text property, use it as the text value
		dragData.text = this.text;
	}
	else {
		dragData.text = dragData.value;
	}	
	return true;
}

/// Default drag handler for controls.
ClientMethod dragStartHandler(dragData) [ Language = javascript ]
{
	// get drag data
	if (!this.getDragData(dragData)) {
		return false;
	}
	
	// avatar
	var icon = this.getEnclosingDiv().cloneNode(true);
	icon.style.position="absolute";
	icon.style.border ="1px solid darkgray";
	icon.style.background ="#D0D0F0";
	ZLM.setDragAvatar(icon);

	return true;
}

/// Default drop handler for controls.
ClientMethod dropStartHandler(dragData) [ Language = javascript ]
{
	this.setValue(dragData.toString());
	return true;
}

}
