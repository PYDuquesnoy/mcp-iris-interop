/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// </br >This object is part of the <class>%CSP.Mgr.GatewaySystemStatus</class> object.
Class %CSP.Mgr.Helper.CachedForms Extends (%SerialObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

Parameter XMLIGNORENULL As STRING = 1;

/// Number of CSP forms cached by the Gateway
Property FormsInCache As %Integer;

/// Amount (in bytes) of cached form dat held in the Gateway.
Property CachedData As %Integer;

/// Number of hits for forms held in the Gateway cache.
Property CacheActivity As %Integer;

/// Information about individual forms in the Gateway cache.
Property Form As array Of %CSP.Mgr.Helper.Form(XMLKEYNAME = "id", XMLPROJECTION = "ELEMENT");

Storage Default
{
<Data name="CachedFormsState">
<Value name="1">
<Value>FormsInCache</Value>
</Value>
<Value name="2">
<Value>CachedData</Value>
</Value>
<Value name="3">
<Value>CacheActivity</Value>
</Value>
<Value name="4">
<Value>Forms</Value>
</Value>
<Value name="5">
<Value>Form</Value>
</Value>
</Data>
<State>CachedFormsState</State>
<StreamLocation>^%CSP.Mgr.Helper.CachedFormsS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
