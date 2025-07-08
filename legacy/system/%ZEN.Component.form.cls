/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Form component.<br>
/// This is a specialized type of group that wraps its
/// constituent components within an HTML form element.<br>
/// Typically a form contain a set of controls. These are used
/// to collect input from a user. This input is sent to the server
/// for processing via an HTML submit operation.<br>
/// The contents of a form can be submitted in two ways:
/// When the user clicks a <class>submit</class> button 
/// placed within the form, or by calling the <method>submit</method>
/// of this form object.<br>
/// Note that ZEN automatically handles the details of the submit
/// operation including invoking server callbacks and error processing.
/// All forms are submitted using the HTTP POST submission method.
Class %ZEN.Component.form Extends (group, dataView) [ Deprecated, System = 3 ]
{

Parameter SYSMODULE = "form";

Parameter DEFAULTGROUPCLASS = "form";

/// Default style for cells within forms
Parameter DEFAULTGROUPSTYLE = "padding: 5px;";

/// URL to go to <i>after</i> this form is submitted successfully.
/// This value may be overwritten by a specific submit button.
Property nextPage As %ZEN.Datatype.uri;

/// Specifies the target for the form. 
/// (Refer to the HTML form element for details).
Property target As %ZEN.Datatype.string;

/// Specifies the action attribute for the form.<br/>
/// Setting this will override the default behavior of Zen forms (i.e. the
/// normal submit logic will not be executed). This should only be used for special
/// cases where direct control of the action attribute is required.
Property action As %ZEN.Datatype.uri;

/// Specifies the method attribute for the form.<br/>
/// Setting this will override the default behavior of Zen forms.
/// This should only be used for special
/// cases where direct control of the method attribute is required.
Property method As %ZEN.Datatype.string(VALUELIST = ",post,get");

/// Specifies the enctype for the form. 
/// (Refer to the HTML form element for details).
Property enctype As %ZEN.Datatype.string;

/// If true (the default), automatically invoke this form's
/// <method>validate</method> whenever this form is submitted.
Property autoValidate As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Value displayed in alert box by the <method>validate</method>
/// method when the contents of this form are invalid.<br>
/// This is a localized value.
Property invalidMessage As %ZEN.Datatype.caption [ InitialExpression = "This form contains invalid values. Please correct the following field(s) and try again." ];

/// Value displayed in alert box by the <method>save</method>
/// method when an attempt is made to save a form bound to readonly data model<br>
/// This is a localized value.
Property readOnlyMessage As %ZEN.Datatype.caption [ InitialExpression = "This data is read only." ];

/// Value displayed in the component with id <property>messageTargetId</property> when this form
/// is not connected to a data model; the form is connected to a controller but
/// the controller does not have a data model.
/// This is a localized value.
Property noModelMessage As %ZEN.Datatype.caption;

/// If defined, this is the id of a control (which could be anywhere on the page) that will display messages, such as
/// the <property>noModelMessage</property>. The message is displayed by setting the
/// <property>value</property> property of the identified control.
Property messageTargetId As %ZEN.Datatype.id;

/// onsubmit event handler:
/// This event is fired when this form is about to be submitted.
/// It provides a chance to perform client-side validation of values
/// within the form. If this event handler returns false, then
/// the submit operation will not occur.<br>
/// Note that unlike the HTML onsubmit event, this callback is
/// <i>always</i> called when the form is submitted.
Property onsubmit As %ZEN.Datatype.eventHandler(HANDLER = "");

/// onreset event handler:
/// This event is fired when this form is about to be reset.
Property onreset As %ZEN.Datatype.eventHandler;

/// ondefault event handler:
/// This is a special event that is fired when the user performs
/// an action that triggers the default action for a form. Typically
/// this is when the user presses the Enter key within a control within
/// the form.
Property ondefault As %ZEN.Datatype.eventHandler(HANDLER = "");

/// onchange event handler:
/// This event is fired when the value of a control on this form is 
/// changed by the user or when the modified flags are cleared.<br>
/// When fired for a control, the event handler can use an argument called
/// 'control' to get a reference to the modified control. When fired in the
/// case of a call to <method>clearModified</method>, this argument will be null.
Property onchange As %ZEN.Datatype.eventHandler(HANDLER = "");

/// onvalidate event handler:
/// This event is fired when this form's validate method is called.
Property onvalidate As %ZEN.Datatype.eventHandler(HANDLER = "");

/// oninvalid event handler:
/// This event is fired when this form's validate method determines
/// that the contents of this form are invalid. This provides the application
/// with a chance to display a custom message.
Property oninvalid As %ZEN.Datatype.eventHandler(HANDLER = "");

/// (Optional) ID value used by the <method>OnLoadForm</method> method to load 
/// data for this form.<br>
/// If this form is connected to a dataController then this value will be ignored.
Property key As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// If true, then programmatic changes, via the control's setValue method, 
/// to controls in this form will trigger onchange events
/// and notify a dataController if present.<br/>
/// The default is false. In this case, events are only raised in response to user actions.
Property propagateChanges As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// (Optional) Name of Server-side callback method to call to get values for this form.<br>
/// This must be the name of a server-only method in the page
/// class that contains this form component.<br>
Property OnLoadForm As %ZEN.Datatype.delegator(FORMALSPEC = "pID:%String,*pValues:%String", RETURNTYPE = "%Status");

/// (Optional) Name of Server-side callback method to call 
/// when this form is submitted. If this is not specified, then the
/// page's <method>%OnSubmit</method> method is called instead.<br>
/// This must be the name of a server-only method in the page
/// class that contains this form component.
Property OnSubmitForm As %ZEN.Datatype.delegator(FORMALSPEC = "pSubmit:%ZEN.Submit", RETURNTYPE = "%Status");

/// (Optional) Indicates whether controls in this form can by default have their values automatically completed by the browser.<br>
/// This setting can be overridden by an autocomplete attribute on an element belonging to the form.
Property autocomplete As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Method %DrawHTML()
{
	#; write out <form> element
	#; note: we post to *the* current URL and then the server will
	#; redirect us to nextPage, if specified.

	#; note that we never submit via an HTML submit button, so 
	#; the form:onsubmit event is hard-wired to return false.

	If (..action '= "") {
		#; user override; perhaps for a login page
		Set tURL = ..action
	}
	Else {
		#; Set our URL to point back to us; make sure % gets escaped!
		Set tURL = $TR($zobjclass(%page),"%","_") _ ".cls"

		#; If there is a password error *and* an error URL, then we
		#; will set it as the target; this is for zen-based login/change password pages.
		Set tEC = $Get(%request.Data("Error:ErrorCode",1))
		If ((tEC'="")&&(($SYSTEM.Status.GetErrorCodes(tEC)[$$$ERRORCODE($$$RequireAuthentication))||($SYSTEM.Status.GetErrorCodes(tEC)[$$$ERRORCODE($$$PasswordChangeRequired)))) {
			Set tURL = $get(%request.Data("Error:URL",1),tURL)
		}
	}
	
	If (..method'="") {
		Set tMethod = ..method
	}
	Else {
		Set tMethod = "post"
	}
	
	Set tFormUrl=$get(%request.Data("Error:FullURL",1))
	If tFormUrl="" Set tFormUrl=$zconvert($zconvert(tURL,"O",$replace($$$GETIO,"JSML","UTF8")),"O","URL")

	&html<<form method="#(tMethod)#" id="#(..%MakeId("form"))#" action="#(tFormUrl)#" #(..%Attr("name",..name))# #(..%Attr("target",..target))# #(..%Attr("enctype",..enctype))# #(..%Attr("autocomplete",$SELECT(..autocomplete=0:"off",1:"on")))# #(..%GetEventHandlers(.tIgnore))# onsubmit="return zenPage.getComponent(#(..index)#).submitHandler();">>

	#; evaluate key value
	Set tKey = $$$ZENVAL(..key)
	
	#; inject hidden fields needed for session context
	#; plus hidden variables used to keep track of this form
	Set tHidden("$ZEN_FORMINDEX") = ..index
	Set tHidden("$ZEN_FORMID") = ..id
	// Write %page.InsertHiddenFields(tURL,.tHidden)
	// call direct function to force xhtml
	Write $$cspHiddenForm^%SYS.cspServer(tURL,.tHidden,1)

	#; hidden variables that can be modified, need ids
	#; key used by bound forms OR OnLoadForm
	&html<<input id="#(..%MakeId("formKey"))#" type="hidden" name="$ZEN_FORMKEY" value="#($ZCVT(tKey,"O","HTML"))#"/>>

	#; holder for nextPage value
	&html<<input id="#(..%MakeId("nextPage"))#" type="hidden" name="$ZEN_NEXTPAGE" value="#($ZCVT(..nextPage,"O","HTML"))#"/>>

	#; holder for Submit method
		; Encrypt the form source to prevent client manipulation
		Set tFormMethod = $ZCVT(..OnSubmitForm,"O","HTML")
		Set tFormMethod = $$$cspEncode(%session.Key,tFormMethod)
	
	&html<<input id="#(..%MakeId("submitMethod"))#" type="hidden" name="$ZEN_FORMMETHOD" value="#($ZCVT(tFormMethod,"O","HTML"))#"/>>

	If $IsObject(..composite) {
		Set tFormSource = $zobjclass(..composite)
		; Encrypt the form source to prevent client manipulation
		Set tFormSource = $ZCVT(tFormSource,"O","HTML")
		Set tFormSource = $$$cspEncode(%session.Key,tFormSource)
		#; holder for composite class, if this form is embedded in a composite
		&html<<input id="#(..%MakeId("submitSource"))#" type="hidden" name="$ZEN_FORMSOURCE" value="#($ZCVT(tFormSource,"O","HTML"))#"/>>
	}

	#; holder for DataModel class; set by client if we have a dataController
	&html<<input id="#(..%MakeId("modelClass"))#" type="hidden" name="$ZEN_MODELCLASS" value=""/>>

	#; holder of submit action value
	&html<<input id="#(..%MakeId("action"))#" type="hidden" name="$SUBMIT" value="submit" />>

	#; invoke callback
	Set tSC = ..%OnDrawForm()

	#; let group handle the details
	Do ##super()

	&html<</form>>
}

/// This callback gives form subclasses a chance to add additional
/// hidden fields.
Method %OnDrawForm() As %Status [ CodeMode = expression ]
{
$$$OK
}

/// Called just after this form is added to the page.<br>
/// Invokes the OnLoadForm callback for this form.
Method %OnAddToPageAfter() As %Status
{
	Set tSC = $$$OK

	Do {
		#; connect to dataController, if present.
		Set tSC = ..%AcquireDataFromController()
		If $$$ISERR(tSC) Quit
	
		#; see if our form class needs to inject additional components
		Set tSC = ..%InjectControls()
		If $$$ISERR(tSC) Quit
	
		#; if we have a controller, bind its data to our controls
		If $IsObject(..%controller) {
			#; move values to controls
			Set tSC = ..%BindDataControls(..%controller)
			If $$$ISERR(tSC) {
				$$$ZENLOGERROR("MVC: Error in %BindDataControls")
				Quit
			}
		}

		#; invoke user callback, if present
		If (..OnLoadForm '= "") {
			#; evaluate key value
			Set tKey = $$$ZENVAL(..key)
			Set tSC = ..%LoadForm(tKey,..OnLoadForm,.tValues)
			If $$$ISERR(tSC) {
				Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
				Quit
			}
			
			If $D(tValues) {
				#; move values into controls
				Do %page.%SetValuesByName(.tValues)
			}
		}
	} While(0)

	Quit tSC
}

/// Internal method.<br>
/// Inject additional controls into this when it is added to the page.
/// This is implmented by subclasses.
Method %InjectControls() As %Status [ CodeMode = expression ]
{
$$$OK
}

/// Internal method.<br>
/// Invoke server-side event handler (if defined) to get 
/// values for this form.
Method %LoadForm(pKey As %String, pOnLoadForm As %String, ByRef pValues As %String) As %Status [ Internal ]
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (pOnLoadForm '= "")) {
		#; get array of values subscripted by control name
		Set tSC = $zobjmethod(tHost,pOnLoadForm,pKey,.pValues)
		If $$$ISERR(tSC) Quit tSC
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Done
}

/// Internal method.<br>
/// Copies values from a dataController object to the
/// controls that belong to this form.
Method %BindDataControls(pController As %ZEN.Auxiliary.dataController, pGroup As %ZEN.Component.group = "") As %Status [ Private ]
{
	Set tSC = $$$OK
	Set:pGroup="" pGroup = ##this

	#; loop over our children (recurse)
	Set tCount = pGroup.children.Count()
	For n = 1:1:tCount {
		Set tControl = pGroup.children.GetAt(n)
		// JMD957 -- special case for lookup control
		If (tControl.%IsA("%ZEN.Component.lookup")) {
			If (tControl.dataBinding '="") {
				Set tValue = pController.%GetDataByName(tControl.dataBinding)
				If (tValue = $$$ZENMISSING) {
					Set tValue = ""
					Set tControl.disabled = 1
				}
				Set tControl.value = tValue
			}
			If (tControl.displayBinding '="") {
				Set tValue = pController.%GetDataByName(tControl.displayBinding)
				If (tValue = $$$ZENMISSING) {
					Set tValue = ""
				}
				Set tControl.text = tValue
			}
			Else {
				Set tControl.text = tControl.value
			}
		}
		ElseIf (tControl.%IsA("%ZEN.Component.control") && (tControl.dataBinding '="")) {
			Set tValue = pController.%GetDataByName(tControl.dataBinding)
			If (tValue = $$$ZENMISSING) {
				Set tValue = ""
				Set tControl.disabled = 1
			}
			Set tControl.value = tValue
		}
		ElseIf (tControl.%IsA("%ZEN.Component.group")) {
			#; recurse
			Set tSC = ..%BindDataControls(pController,tControl)
			If $$$ISERR(tSC) Quit
		}
	}

	Quit tSC
}

/// Reload the contents of this form given a key value .
ClientMethod reload(key) [ Language = javascript ]
{
	this.key = key;
	var ctrl = this.findElement('formKey');
	zenASSERT(ctrl,"Unable to find formKey element",arguments);
	ctrl.value = key;

	if ('' != this.OnLoadForm) {
		// go to server; get new values
		this.ReloadForm(this.index, this.key);
	}
}

/// Internal method.<br>
/// Get values for form from user callback;
/// Apply them to client form.
Method ReloadForm(pFormIndex As %Integer, pKey As %String) [ ZenMethod ]
{
	Set tSC = ..%LoadForm(pKey,..OnLoadForm,.tValues)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorJS(##this,tSC)
		Quit
	}
	#; reset form
	&js<var form = zenPage.getComponent(#(pFormIndex)#);
		form.reset();
		var values = new Object();
	>

	#; build an array of values
	Set tName = $O(tValues(""))
	While (tName '= "") {
		&js<values['#(tName)#'] = '#($ZCVT($G(tValues(tName)),"O","JS"))#';>
		Set tName = $O(tValues(tName))
	}

	#; JMD637 -- explicitly set formKey control
	&js<var fkey = form.findElement('formKey');
		if (fkey) { fkey.value = '#($ZCVT(..key,"O","JS"))#'; }
	>

	#; apply values to form
	&js<form.setValuesByName(values);>
}

/// Return the HTML form element associated with this component.
/// This is provided in case there are addition HTML form properties
/// or methods that an application needs access to.
ClientMethod getFormElement() [ Language = javascript ]
{
	var form = this.findElement('form');
	zenASSERT(form,"Unable to find form element",arguments);
	return form;
}

/// If this form is connected to a dataController, then
/// validate the contents of the form and then save the data
/// to the server via the dataController.
/// Return the id value used to save the data or "" if not saved.<br>
/// If this form is not connected to a dataController, this
/// method does nothing.
ClientMethod save() [ Language = javascript ]
{
	var id = '';

	var controller = this.getController();
	if (controller && ''!=controller.getProperty('modelClass')) {
		if (controller.isModelReadOnly()) {
			alert(this.readOnlyMessage);
			return id;
		}
	
		if (!this.validate()) {
			return id;
		}
		id = controller.save();
	}
	return id;
}

/// Submit the HTML form associated with this component.
/// <var>action</var> if defined, is the action value that
/// is passed on to the server %OnSubmit callback method.
ClientMethod submit(action) [ Language = javascript ]
{
	var canSubmit = true;

	// fire onsubmit callbacks for controls that have them
	var controls = this.getControlList();
	for (var n = 0; n < controls.length; n++) {
		var child = controls[n];
		if (child.onsubmit) {
			zenInvokeCallbackMethod(child.onsubmit,child,'onsubmit');
		}
	}

	// if bound, test for readonly
	var controller = this.getController();
	if (controller && ''!=controller.getProperty('modelClass')) {
		if (controller.isModelReadOnly()) {
			alert(this.readOnlyMessage);
			return
		}
	}

	// validate the form
	if (this.autoValidate && !this.validate()) {
		return;
	}

	if ('' != this.onsubmit) {
		// invoke onsubmit callback
		canSubmit = zenInvokeCallbackMethod(this.onsubmit,this,'onsubmit');
	}

	if (canSubmit) {
		// if we have a controller, make sure we will submit to the dataModel
		var controller = this.getController();
		if (controller && ''!=controller.getProperty('modelClass')) {
			var formKey = this.findElement('formKey');
			var modelClass = this.findElement('modelClass');
			formKey.value = controller.getProperty('modelId');
			modelClass.value = controller.getProperty('modelClass');
		}

		// set up submit value
		var ctrl = this.findElement('action');
		ctrl.value = (null == action) ? 'submit' : action;
		this.getFormElement().submit();
	}
}

/// Reset the HTML form associated with this component.
ClientMethod reset() [ Language = javascript ]
{
	this.getFormElement().reset();
	
	// clear mod flags and set control values to ''
	this.clearModified(true);
}

/// Internal method.<br>
/// Onsubmit event handler. This is an internal method
/// used to trap the default action of the form.
ClientMethod submitHandler() [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.ondefault,this,'ondefault');
	return false;
}

/// Internal method.<br>
/// This handler is called whenever the value of a control within
/// this form is changed by the user.
ClientMethod controlChangeHandler(control, fire) [ Internal, Language = javascript ]
{
	if ('undefined' == typeof fire || fire) {
		// invoke onchange for the form
		zenInvokeCallbackMethod(this.onchange,this,'onchange','control',control);
	}

	// if we have a dataController, notify it of the change
	var controller = this.getController();
	if (controller && '' != control.dataBinding) {
		this.sendEventToController('propertyChange',control.dataBinding,control.value);
	}
}

/// Test if the contents of the form have been modified.
/// This is done by calling the isModified method for each control
/// on the form.
ClientMethod isModified() [ Language = javascript ]
{
	var flag = false;

	var controls = this.getControlList();
	for (var n = 0; n < controls.length; n++) {
		var child = controls[n];
		if (child.isModified()) {
			flag = true;
			break;
		}
	}
	
	return flag;
}

/// Clear the modified state of this form by visiting every control
/// on the form and resetting its orginalValue property to its
/// current value.<br/>
/// If <var>reset</var> is provided and true, then this also sets 
/// the value of every control to '';
ClientMethod clearModified(reset) [ Language = javascript ]
{
	var controls = this.getControlList();
	for (var n = 0; n < controls.length; n++) {
		var child = controls[n];
		child.setProperty('originalValue','');
		if (reset) {
			child.setProperty('value','');
			this.controlChangeHandler(child,false);
		}
	}

	// invoke onchange for the form: pass null for control.
	zenInvokeCallbackMethod(this.onchange,this,'onchange','control',null);
}

/// Validate the contents of this form.<br>
/// This does the following:<br>
/// <ul>
/// <li>Invokes the form-specific onvalidate callback, if present.</li>
/// <li>Calls the <method>validationHandler</method> method for each control within this form.</li>
/// </ul>
/// It returns true if the form is valid.
ClientMethod validate() [ Language = javascript ]
{
	var valid = true;
	
	// list of controls that are invalid
	var invalidList = new Array();

	// if a control is invalid because of the dataController,
	// the invalid message will be in here (indexed by error #) 
	var invalidMessage = new Object();

	/// onvalidate callback, if present
	if ('' != this.onvalidate) {
		valid = zenInvokeCallbackMethod(this.onvalidate,this,'onvalidate','invalidList',invalidList);
	}
	
	/// See if we are connected to a dataController
	var controller = this.getController();

	if (valid) {
		// visit each control in this form and test it
		var controls = this.getControlList();
		for (var n = 0; n < controls.length; n++) {
			var child = controls[n];
			var dcMsg = '';
			// reset invalid flag
			child.setProperty('invalid',false);

			// first test dataController, if present
			if (controller && ('' != child.dataBinding)) {
				dcMsg = controller.isPropertyValid(child.dataBinding, child.getValue());
			}

			if ('' != dcMsg) {
				// add control to list of invalid controls (plus msg index)
				invalidMessage[invalidList.length] = dcMsg;
				invalidList[invalidList.length] = child;
			}
			else {
				// test control for validity
				if (!child.validationHandler()) {
					invalidList[invalidList.length] = child;
				}
			}
		}
	}

	// show invalid message
	if (invalidList.length > 0) {
		valid = false;
		if ('' != this.oninvalid) {
			// call oninvalid callback
			valid = zenInvokeCallbackMethod(this.oninvalid,this,'oninvalid','invalidList',invalidList);
		}
		else {
			// built-in behavior: built a message and display it
			var msg = this.invalidMessage + '\n-------------------\n';
			for (var n = 0; n < invalidList.length; n++) {
				var ctrl = invalidList[n];
				ctrl.setProperty('invalid',true);
				if (n==0) {
					ctrl.focus();
				}
				// get reason (from dataController or control)
				if (null == invalidMessage[n] || '' == invalidMessage[n]) {
					msg += ctrl.getInvalidReason() + '\n';
				}
				else {
					msg += invalidMessage[n] + '\n';
				}
			}
			alert(msg);
		}
	}

	return valid;
}

/// Given an associative array of the form values[name] = value,
/// set the value of the controls within this form by control name.
ClientMethod setValuesByName(values) [ Language = javascript ]
{
	// get assoc. array of controls by name
	var controls = this.getControlList('name');

	// walk down set of values, apply
	for (var name in values) {
		if (controls[name]) {
			controls[name].setValue(values[name]);
		}
	}
}

/// Return the current values of all controls in this form as a zenProxy object.
/// The names of the properties within the proxy object are based on the
/// each control's <property>name</property> attribute.
ClientMethod getValuesAsObject() [ Language = javascript ]
{
	// get assoc. array of controls by name
	var controls = this.getControlList('name');
	var obj = new zenProxy();

	for (var name in controls) {
		obj[name] = controls[name].getValue();
	}
	return obj;
}

/// Internal client-side method.<br>
/// Copies values from a dataController object to the
/// controls that belong to this form.<br>
/// If <var>dataBinding</var> is not null, then binding only applies to 
/// controls with that dataBinding value.<br>
/// If <var>clear</var> is true, then clear the cache of any controls (i.e.
/// comboboxes).
ClientMethod bindValues(dataBinding, clear) [ Internal, Language = javascript ]
{
	if (this._propagatingChanges==1) return;
	var controller = this.getController();
	if (controller) {
		if (!controller.hasData()) {
			this.showMessage(this.noModelMessage);
		}
		else {
			this.showMessage('');
		}
		var controls = this.getControlList();
		for (var n = 0; n < controls.length; n++) {
			var ctrl = controls[n];
			if (ctrl) {
				// reset invalid flag
				ctrl.setProperty('invalid',false);
			}
			if (ctrl && !zenIsMissing(ctrl.dataBinding) && (null==dataBinding || dataBinding==ctrl.dataBinding)) {
				var data = controller.getDataByName(ctrl.dataBinding);
				if (ctrl.onDataModelChange) {
					ctrl.onDataModelChange(controller.modelClass,controller.modelId);
				}
				if ((clear||ctrl.clearOnLoad) && ctrl.clearCache) {
					ctrl.clearCache();
				}
				if (null==data) {
					if ('%id' != ctrl.dataBinding) {
						ctrl.setProperty('disabled',true);
					}
					this._propagatingChanges = 1;
					ctrl.setValue('');
					this._propagatingChanges = 0;
				}
				else {
					ctrl.setProperty('disabled',false);
					var text = '';

					// JMD957
					if (!zenIsMissing(ctrl.displayBinding)) {
						var text = controller.getDataByName(ctrl.displayBinding);
						text = text==null ? '' : text;
						this._propagatingChanges = 1;
						ctrl.setValue(data,text);
						this._propagatingChanges = 0;
					} else {
						this._propagatingChanges = 1;
						ctrl.setValue(data);
						this._propagatingChanges = 0;
					}
				}
			}
		}
	}
	else {
		this.showMessage('');
	}
}

/// Internal method.
/// Construct an array of references to every control that
/// belongs to this form.
/// If <var>sortBy</var> is defined, it indicates how the
/// controlList should be ordered, "name", "id".
ClientMethod getControlList(sortBy) [ Language = javascript ]
{
	var controlList = (null != sortBy) ? new Object() : new Array();
	
	// recursively loop over contents of this form
	// and find all controls
	var done = false;
	var parent = new Array();
	var cno = new Array();
	var level = 0;
	parent[0] = this;
	cno[0] = 0;

	do {
		// get child & test
		var child = parent[level].children[cno[level]];
		if (child) {
			if (child.isOfType('control')) {
				// add to list
				switch (sortBy) {
				case 'name':
					if (null != child.name && '' != child.name) {
						controlList[child.name] = child;
					}
					break;
				case 'id':
					if (null != child.id && '' != child.id) {
						controlList[child.id] = child;
					}
					break;
				default:
					controlList[controlList.length] = child;
					break;
				}
			}
			else if (child.isOfType('group') && (child.children.length > 0)) {
				// go down a level
				level++;
				parent[level] = child;
				cno[level] = 0;
				continue;
			}
		}
		
		// get next child
		var found = false;
		while (!found) {
			cno[level]++;
			if (cno[level] < parent[level].children.length) {
				found = true;
			}
			else if (level > 0) {
				level--;
			}
			else {
				found = true;
				done = true;
			}
		}

	} while(!done);

	return controlList;
}

/// Show a message by setting the value of the control identified by 
/// <property>messageTargetId</property>.
/// Returns true if the message was displayed.
ClientMethod showMessage(message) [ Language = javascript ]
{
	if (!zenIsMissing(this.messageTargetId)) {
		var ctrl = zenPage.getComponentById(this.messageTargetId);
		if (ctrl) {
			ctrl.setProperty('value',message);
			return true;
		}
	}
	return false;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'target':
	case 'enctype':
	case 'action':
	case 'method':
		var form = this.getFormElement();
		form[property] = value;
		break;

	case 'messageTargetId':
	case 'noModelMessage':
	case 'invalidMessage':
	case 'readOnlyMessage':
	case 'propagateChanges':
		form[property] = value;
		break;

	case 'key':
		this.reload(value);
		break;
	case 'nextPage':
		// update hidden field containing next page
		var next = this.findElement('nextPage');
		zenASSERT(next,"Unable to find nextPage element",arguments);
		next.value = value;
		this.nextPage = value;
		break;
	case 'OnSubmitForm':
		// update hidden field
		var m = this.findElement('submitMethod');
		zenASSERT(m,"Unable to find submitMethod element",arguments);
		m.value = value;
		this.OnSubmitForm = value;
		break;
	case 'autoValidate':
		this.autoValidate = value ? true : false;
		break;
	case 'controllerId':
		// pass this change on to dataView
		this.setControllerId(value);
		// update form
		this.bindValues();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Notification that the dataController associated with this form
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
		// data changed in dataController: data1 is name of property or null
		// data3 is series #-- make sure the series is one we care about
		var controller = this.getController();
		var ds = controller.getProperty('defaultSeries');
		if (null == data3 || ds == data3) {
			this.bindValues(data1,false);
		}
		break;
	case 'seriesChange':
		// default series changed in dataController.
		this.bindValues(null,true);
		break;
	case 'modelChange':
		// model (meta-data) changed in dataController.
		this.bindValues(null,true);
		break;
	}
}

/// Compensate for Chrome's increasingly aggressive autofill behavior
/// by resetting the client-side settings to the server-side originals.
/// This method should be called after page load (and Chrome's auto-fill
/// cycle) but before the user has had a change to start editing things.
/// Optimally this would be done via a setTimeout in the onload method 
/// if autofill has been set to false.
ClientMethod undoAutofill() [ Internal, Language = javascript ]
{
	var controls = this.getControlList();
	for (var n = 0; n < controls.length; n++) {
		var child = controls[n];
		var ov = child.getProperty('originalValue');
		child.setValue(ov);
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// if defined, connect to dataController
	this.connectToController();
	
	// if we are connected to a controller without data, make sure
	// we are disabled.
	var controller = this.getController();
	if (controller && !controller.hasData()) {
		this.bindValues(null,false);
	}

	// make sure that modified flags are cleared when form
	// is first displayed.
	this.clearModified();

	// If autocomplete has been set to false, forcably remove
	// any default values the browser has decided to give us 
	// despite our request to the contrary.
	if (!this.autocomplete) {
		var zenThis = this;
		setTimeout(function() {zenThis.undoAutofill();},250);
	}
}

}
