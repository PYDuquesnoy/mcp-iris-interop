/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Representation of a single action taken by a user to update a <class>ManagedAlert</class>.
Class Ens.Alerting.Action Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

/// The time at which the action was performed.
Property ActionTime As Ens.DataType.UTC [ InitialExpression = {$$$timeUTC}, Required ];

/// The username of the user performing the action.
Property Username As %String(MAXLEN = 128) [ InitialExpression = {$username}, Required ];

/// A set of boolean flags indicating what actions were performed as part of the update.
Property Action As Ens.DataType.ManagedAlertAction [ InitialExpression = 0, Required ];

/// A short text string to indicate what the user actually did.
Property Reason As %String(MAXLEN = 500) [ Required ];

/// A list of key/value pairs for old values that were changed by this action.
Property OldValues As array Of %String(MAXLEN = 128, XMLITEMNAME = "Value", XMLKEYNAME = "Property");

/// A list of key/value pairs for new values that were changed by this action.
Property NewValues As array Of %String(MAXLEN = 128, XMLITEMNAME = "Value", XMLKEYNAME = "Property");

Storage Default
{
<Data name="ActionState">
<Value name="1">
<Value>ActionTime</Value>
</Value>
<Value name="2">
<Value>Username</Value>
</Value>
<Value name="3">
<Value>Action</Value>
</Value>
<Value name="4">
<Value>Reason</Value>
</Value>
<Value name="5">
<Value>OldValues</Value>
</Value>
<Value name="6">
<Value>NewValues</Value>
</Value>
</Data>
<State>ActionState</State>
<StreamLocation>^Ens.Alerting.ActionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
