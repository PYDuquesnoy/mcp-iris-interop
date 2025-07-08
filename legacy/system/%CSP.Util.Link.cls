/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Defines a link to a CSP Utility page
Class %CSP.Util.Link Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

/// The displayed value for this link.<BR>
/// This is a localizable value.
Property Caption As %String(MAXLEN = 50);

/// When appropriate, popup help for this link.<BR>
/// This is a localizable value.
Property Popup As %String(MAXLEN = 100);

/// Name of page to go to.
Property HREF As %String(MAXLEN = 128);

/// ID Value for the link
Property IDValues As %String [ MultiDimensional ];

Storage Default
{
<Data name="ActionState">
<Subscript>"%CSP.Util.Action"</Subscript>
<Value name="1">
<Value>Page</Value>
</Value>
<Value name="2">
<Value>Class</Value>
</Value>
<Value name="3">
<Value>IDColumn</Value>
</Value>
<Value name="4">
<Value>Caption</Value>
</Value>
<Value name="5">
<Value>Popup</Value>
</Value>
<Value name="6">
<Value>IDValue</Value>
</Value>
<Value name="7">
<Value>HREF</Value>
</Value>
</Data>
<State>ActionState</State>
<StreamLocation>^%CSP.Util.ActionS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
