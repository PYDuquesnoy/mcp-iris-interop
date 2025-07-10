/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request the transformation of some XML
Class EnsLib.XSLT.TransformationResponse Extends Ens.Response [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Transformed XML content	
Property Content As %Stream.GlobalCharacter;

Storage Default
{
<Data name="TransformationResponseDefaultData">
<Subscript>"TransformationResponse"</Subscript>
<Value name="1">
<Value>Content</Value>
</Value>
<Value name="2">
<Value>Status</Value>
</Value>
</Data>
<DefaultData>TransformationResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
