/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSLT

/// Defines a set of properties derived from XML Stream objects embedded in class 'Ens.StreamContainer'
/// that can be used in SQL to locate and join to XML documents of interest.
Class EnsLib.XML.SearchTable Extends (%Persistent, Ens.VDoc.XMLSearchTable) [ ClassType = persistent, CompileAfter = Ens.StreamContainer, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter EXTENTSIZE = 4000000;

/* Re-declare indices because the superclass is abstract */
Index indexValue On (PropId, PropValue, DocId) [ IdKey, Unique ];

Index indexDocId On (DocId, PropId, PropValue) [ Unique ];

XData SearchSpec
{
<Items>
<Item DocType=""  PropName="RootElement" >{/|name(/*)}</Item>
</Items>
}

Storage Default
{
<Data name="SearchTableDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^EnsLib.XML.SearchTableD</DataLocation>
<DefaultData>SearchTableDefaultData</DefaultData>
<ExtentSize>4000000</ExtentSize>
<IdLocation>^EnsLib.XML.SearchTableD</IdLocation>
<IndexLocation>^EnsLib.XML.SearchTableI</IndexLocation>
<StreamLocation>^EnsLib.XML.SearchTableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
