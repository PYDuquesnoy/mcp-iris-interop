/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// </br >This object is part of the <class>%CSP.Mgr.GatewaySystemStatus</class> object.
Class %CSP.Mgr.Helper.Form Extends (%SerialObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

Parameter XMLIGNORENULL As STRING = 1;

Property Size As %Integer;

Property BlocksUsed As %Integer;

Property CacheFile As %String;

Property Activity As %Integer;

Storage Default
{
<Data name="FormState">
<Value name="1">
<Value>Size</Value>
</Value>
<Value name="2">
<Value>Activity</Value>
</Value>
<Value name="3">
<Value>BlocksUsed</Value>
</Value>
<Value name="4">
<Value>CacheFile</Value>
</Value>
</Data>
<State>FormState</State>
<StreamLocation>^%CSP.Mgr.Helper.FormS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
