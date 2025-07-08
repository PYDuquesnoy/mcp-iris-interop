/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A list of alternative InterSystems IRIS servers may be defined for an application (path).
/// </br >This object is part of the <class>%CSP.Mgr.GatewaySystemStatus</class> object.
Class %CSP.Mgr.Helper.ApplicationPath Extends (%SerialObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

Parameter XMLIGNORENULL As STRING = 1;

/// Path for which alternative servers are begin specified.
Property Path As %String;

/// Number denotes the server number.
Property AlternativeServer As array Of %CSP.Mgr.Helper.AlternativeServer(XMLKEYNAME = "Number", XMLPROJECTION = "ELEMENT");

Storage Default
{
<Data name="ApplicationPathState">
<Value name="1">
<Value>Path</Value>
</Value>
<Value name="2">
<Value>AlternativeServer</Value>
</Value>
</Data>
<State>ApplicationPathState</State>
<StreamLocation>^%CSP.Mgr.H7E9C.ApplicationE920S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
