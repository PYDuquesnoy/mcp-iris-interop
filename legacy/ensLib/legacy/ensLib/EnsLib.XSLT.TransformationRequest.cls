/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Request the transformation of some XML
Class EnsLib.XSLT.TransformationRequest Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// XML Stream to transform
Property Content As %Stream.GlobalCharacter;

/// Stylesheet key for the XSL to use
Property StylesheetKey As %String [ InitialExpression = "DEFAULT" ];

/// Name/Value pairs to be passed into the XSLT transformation
Property Parameters As array Of %String(MAXLEN = 512);

Storage Default
{
<Data name="Parameters">
<Attribute>Parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"Parameters"</Subscript>
</Data>
<Data name="TransformationRequestDefaultData">
<Subscript>"TransformationRequest"</Subscript>
<Value name="1">
<Value>Content</Value>
</Value>
<Value name="2">
<Value>StylesheetKey</Value>
</Value>
</Data>
<DefaultData>TransformationRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
