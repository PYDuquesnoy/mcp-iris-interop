/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Login Form component.<br>
/// This is a specialized type of form designed to be used in a login page.
/// Unlike the regular form component, this is a very simple object with none of the
/// more advanced form features that are inappropriate for a login page.<br/>
/// 
Class %ZEN.Component.loginForm Extends group [ Deprecated, System = 3 ]
{

Parameter SYSMODULE = "form";

Parameter DEFAULTGROUPCLASS = "form";

/// Default style for cells within forms
Parameter DEFAULTGROUPSTYLE = "padding: 5px;";

/// Specifies the enctype for the form. 
/// (Refer to the HTML form element for details).
Property enctype As %ZEN.Datatype.string;

/// onsubmit event handler:
/// This event is fired when this form is about to be submitted.
/// It provides a chance to perform client-side validation of values
/// within the form. If this event handler returns false, then
/// the submit operation will not occur.<br>
/// Note that unlike the HTML onsubmit event, this callback is
/// <i>always</i> called when the form is submitted.
Property onsubmit As %ZEN.Datatype.eventHandler(HANDLER = "");

/// ondefault event handler:
/// This is a special event that is fired when the user performs
/// an action that triggers the default action for a form. Typically
/// this is when the user presses the Enter key within a control within
/// the form.
Property ondefault As %ZEN.Datatype.eventHandler(HANDLER = "");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for login error message." */
.zenLoginError {
	color: red;
	padding: 5px;
}
</style>
}

Method %DrawHTML()
{
	#; write out <form> element

	#; If there is a password error *and* an error URL, then we
	#; will set it as the target; this is for zen-based login/change password pages.
	Set tEC = $Get(%request.Data("Error:ErrorCode",1))
	If ((tEC'="")&&(($SYSTEM.Status.GetErrorCodes(tEC)[$$$ERRORCODE($$$RequireAuthentication))||($SYSTEM.Status.GetErrorCodes(tEC)[$$$ERRORCODE($$$PasswordChangeRequired)))) {
		//Set tURL = $get(%request.Data("Error:URL",1),tURL)
	}

	&html<<form method="post" action="#($ZConvert($G(%request.Data("Error:FullURL",1)),"O","HTML"))#" 
		id="#(..%MakeId("form"))#" 
		#(..%Attr("name",..name))# 
		#(..%Attr("enctype",..enctype))##(..%GetEventHandlers(.tIgnore))# 		
		onkeypress="zenPage.getComponent(#(..index)#).handleKey();"
		onsubmit="return zenPage.getComponent(#(..index)#).submitHandler();">>

	#; add hidden field so that we can determine this is a login form and bypass normal
	#; Zen submit logic
	&html<<input type="hidden" name="IRISLogin" value="1"/>>

	#; add hidden submit button to catch default action
	&html<<input type="submit" style="display:none;"/>>

	#; inject hidden fields
	Write $$cspHiddenForm^%SYS.cspServer($ZConvert($G(%request.Data("Error:URL",1)),"O","HTML"))

	#; invoke callback
	Set tSC = ..%OnDrawForm()

	#; let group handle the details
	Do ##super()

	&html<</form>>
}

ClientMethod handleKey(e) [ Language = javascript ]
{
  var charCode;
  charCode = window.event ? event.keyCode : e.which;
  if(charCode == 13) {
    this.submit();
    var evt  = window.event ? event : e;
    if (evt.stopPropagation) evt.stopPropagation();
	if (evt.cancelBubble!=null) evt.cancelBubble=true;
	if (evt.preventDefault) evt.preventDefault();
	else evt.returnValue=false;
	return(false);
  }
}

/// This callback gives form subclasses a chance to add additional
/// hidden fields.
Method %OnDrawForm() As %Status [ CodeMode = expression ]
{
$$$OK
}

/// This callback ensures that CSRF tokens are set (if desired) in 
/// any page employing this widget
Method %OnAddToPageAfter() As %Status
{
	Quit ##class(%CSP.Login).OnPreHTTP()
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

/// Submit the HTML form associated with this component.
/// <var>action</var> if defined, is the action value that
/// is passed on to the server %OnSubmit callback method.
ClientMethod submit(action) [ Language = javascript ]
{
	var canSubmit = true;
	if ('' != this.onsubmit) {
		// invoke onsubmit callback
		canSubmit = zenInvokeCallbackMethod(this.onsubmit,this,'onsubmit');
	}
	if (canSubmit) {
		this.getFormElement().submit();
	}
}

/// Reset the HTML form associated with this component.
ClientMethod reset() [ Language = javascript ]
{
	this.getFormElement().reset();
}

/// Internal method.<br>
/// Onsubmit event handler. This is an internal method
/// used to trap the default action of the form.
ClientMethod submitHandler() [ Language = javascript ]
{
	if (''==this.ondefault) {
		// if no default, try to submit
		this.submit('');
	}
	else {
		zenInvokeCallbackMethod(this.ondefault,this,'ondefault');
	}
	return false;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'nextPage':
	case 'action':
		// ignore
		break;

	case 'enctype':
		var form = this.getFormElement();
		form[property] = value;
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// In case a control thinks this is a normal form, indicate that there is no
/// data controller in play.
ClientMethod getController() [ Language = javascript ]
{
	return null;
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
}

}
