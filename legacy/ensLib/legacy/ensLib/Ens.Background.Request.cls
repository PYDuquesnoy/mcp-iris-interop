/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Super class for Background requests
Class Ens.Background.Request Extends Ens.Request [ System = 4 ]
{

Parameter XMLTYPE = "BackgroundRequest";

/// Workflow role to be used if needed.
Property WorkFlowRole As %String(MAXLEN = 128);

/// Requested By Username
Property RequestedByUsername As %String(MAXLEN = 128);

/// Business Process that will handle request
Property BackgroundProcessor As %String(MAXLEN = 128);

Storage Default
{
<Data name="RequestDefaultData">
<Subscript>"Request"</Subscript>
<Value name="1">
<Value>WorkFlowRole</Value>
</Value>
<Value name="2">
<Value>RequestedByUsername</Value>
</Value>
<Value name="3">
<Value>BackgroundProcessor</Value>
</Value>
</Data>
<DefaultData>RequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
