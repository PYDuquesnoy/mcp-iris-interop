/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Defines contact information for a Business Partner.<br/>
Class Ens.Config.BusinessPartnerContact Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

/// Name of this Contact.
Property Name As %String(MAXLEN = 255, XMLPROJECTION = "ATTRIBUTE");

/// Title of this Contact (e.g., "Analyst").
Property Title As %String(MAXLEN = 255, XMLPROJECTION = "ATTRIBUTE");

/// Email address for this Contact.
Property Email As %String(MAXLEN = 255, XMLPROJECTION = "ATTRIBUTE");

/// Primary phone number for this contact.
Property PhoneNumber As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Mobile phone number for this contact.
Property MobileNumber As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Notes on this contact.
Property Notes As %String(MAXLEN = 1000, XMLPROJECTION = "ELEMENT");

Storage Default
{
<Data name="BusinessPartnerContactState">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Title</Value>
</Value>
<Value name="3">
<Value>Email</Value>
</Value>
<Value name="4">
<Value>PhoneNumber</Value>
</Value>
<Value name="5">
<Value>MobileNumber</Value>
</Value>
<Value name="6">
<Value>Notes</Value>
</Value>
</Data>
<State>BusinessPartnerContactState</State>
<StreamLocation>^Ens.Config.BusinessParEFC1S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
