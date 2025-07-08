/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A submit button.<br>
/// A submit button must be placed within a form.<br>
/// When the user presses the submit button, the form is submitted.
/// The value of the <property>action</property> is passed along
/// to the server-side <method>%OnSubmit</method> method.
Class %ZEN.Component.submit Extends button [ Deprecated, System = 3 ]
{

/// This is the *action* code (a string) associated with this submit button.
/// By default, action is "submit". This value is passed along
/// to the server-side <method>%OnSubmit</method> method.
Property action As %ZEN.Datatype.string(MAXLEN = 250) [ InitialExpression = "submit" ];

/// If defined, the URL to go to <i>after</i> this form is submitted successfully.
/// This value, if defined, will override the <property>nextPage</property>
/// of the form.
Property nextPage As %ZEN.Datatype.uri;

Method %DrawHTML()
{
	#; N.B. We actually use a normal button and invoke the submit using JavaScript
	Set disabled = $S(..disabled:"disabled",1:"")

	Set tIgnore("onclick") = ""
	Set tIgnore("onchange") = ""
	&html<<input type="button" class="#(..controlClass)#" id="#(..%MakeId("control"))#" #(..%Attr("title",..title))# #(..%Attr("value",..caption))# #(disabled)# #(..%Attr("style",..controlStyle))# #(..%GetEventHandlers(.tIgnore))# #(..%Attr("tabindex",..tabIndex))# onclick="zenPage.getComponent(#(..index)#).onclickHandler();"/>>
}

/// Internal onclick handler method for submit button.
/// Users should not call this method.
ClientMethod onclickHandler() [ Language = javascript ]
{
	// find form this submit belongs to
	var form = this.getForm();
	zenASSERT(form,"Submit button is not part of a form",arguments);

	if (form) {
		// check for nextPage override
		if ('' != this.nextPage) {
			form.setProperty('nextPage',this.nextPage);
		}
		
		// invoke user callback, if present
		zenInvokeCallbackMethod(this.onclick,this,'onclick');

		// submit the form
		form.submit(this.action);
	}
}

}
