/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This object is used to hold values and details of a Submit operation.
Class %ZEN.Submit Extends %RegisteredObject [ Deprecated, System = 3 ]
{

/// Internal property.<br>
/// Array of submitted values, indexed by control name.
Property %Data As %String [ MultiDimensional ];

/// Internal property.<br>
/// Array of errors in submitted values, indexed by control name.
Property %Errors As %String [ MultiDimensional ];

/// Name of submit action. This comes from the <property>action</property>
/// property of the <class>%ZEN.Component.submit</class> that
/// submitted this form.
Property %Action As %String;

/// Component id of the submitted form (if defined).
Property %FormId As %String;

/// Key value (object id) associated with the submitted form (if any).<br>
/// If the form defines an OnLoadForm callback, this contains the
/// user-supplied key value used to load data for the form.<br>
/// If the form is bound to a DataModel, this contains the id of the
/// DataModel object.
Property %FormKey As %String;

/// If the form is bound to a DataModel class, this is the name of the DataModel class.
Property %ModelClass As %String;

/// Page to redirect to after a submit.<br>
/// This is initially set to the submitting form's <property>nextPage</property> property
/// but can be modified by an <method>%OnSubmit</method> method.
Property %NextPage As %String;

/// Internal Property.<br>
/// If true, bypass the rest of the submit processing for this page.
Property %SkipProcessing As %Boolean [ InitialExpression = 0 ];

/// Return true if errors have been added to this submit object.
Method %HasErrors() As %Boolean [ CodeMode = expression ]
{
''$D(..%Errors)
}

/// Associate an error message with a component by name.
Method %SetError(pCompName As %String, pError As %String)
{
	Set ..%Errors(pCompName) = pError
}

/// Get value associated with a control by name.
Method %GetValue(pCompName As %String) [ CodeMode = expression ]
{
$G(..%Data(pCompName))
}

/// Get a pointer to a MIME stream associated with a control by name
Method %GetStream(pCompName As %String) [ CodeMode = expression ]
{
$G(%request.MimeData("$V_"_pCompName,1))
}

/// Set the value associated with a control by name.<br>
/// This value will be applied to the control <em>if</em>
/// the form is redisplayed because of errors.
Method %SetValue(pCompName As %String, pValue As %String = "")
{
	Set ..%Data(pCompName) = pValue
}

}
