/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a set of properties derived from Document objects of class 'EnsLib.EDI.XML.Document'
/// that can be used in SQL to locate and join to messages of interest.
Class EnsLib.EDI.XML.SearchTable Extends (%Persistent, Ens.VDoc.SearchTable) [ ClassType = persistent, CompileAfter = EnsLib.EDI.XML.Document, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOCCLASS = "EnsLib.EDI.XML.Document";

Parameter EXTENTSIZE = 4000000;

/* Re-declare indices because the superclass is abstract */
Index indexValue On (PropId, PropValue, DocId) [ IdKey, Unique ];

Index indexDocId On (DocId, PropId, PropValue) [ Unique ];

XData SearchSpec [ XMLNamespace = "http://www.intersystems.com/EnsSearchTable" ]
{
<Items>
<Item DocType=""  PropName="Name" >Name</Item>
</Items>
}

Storage Default
{
<Data name="SearchTableDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^EnsLib.EDI.XML.SearchTableD</DataLocation>
<DefaultData>SearchTableDefaultData</DefaultData>
<ExtentSize>4000000</ExtentSize>
<IdLocation>^EnsLib.EDI.XML.SearchTableD</IdLocation>
<IndexLocation>^EnsLib.EDI.XML.SearchTableI</IndexLocation>
<StreamLocation>^EnsLib.EDI.XML.SearchTableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
