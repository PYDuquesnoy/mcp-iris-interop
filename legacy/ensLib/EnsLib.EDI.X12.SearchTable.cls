/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.SearchTable Extends (%Persistent, Ens.VDoc.SearchTable) [ ClassType = persistent, CompileAfter = EnsLib.EDI.X12.Document, Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter DOCCLASS = "EnsLib.EDI.X12.Document";

Parameter EXTENTSIZE = 4000000;

/// Adds Batch Document Search Support for SearchTables
/// Where Search Properties defined for Child Documents can be evaluated and located
/// in context to the Top Parent Document.
/// Display List Detail of Child Document Search Table properties in Message Search
Property TopParentId As %Integer;

/* Re-declare indices because the superclass is abstract */
Index indexValue On (PropId, PropValue, DocId) [ IdKey, Unique ];

Index indexDocId On (DocId, PropId, PropValue) [ Unique ];

/// Supports use of Batch Document Search Tables
Index indexTopParentId On TopParentId;

XData SearchSpec [ XMLNamespace = "http://www.intersystems.com/EnsSearchTable" ]
{
<Items>
<Item DocType=""  PropName="Identifier" >Identifier</Item>
</Items>
}

Storage Default
{
<Data name="SearchTableDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TopParentId</Value>
</Value>
</Data>
<DataLocation>^EnsLib.EDI.X12.SearchTableD</DataLocation>
<DefaultData>SearchTableDefaultData</DefaultData>
<ExtentSize>4000000</ExtentSize>
<IdLocation>^EnsLib.EDI.X12.SearchTableD</IdLocation>
<IndexLocation>^EnsLib.EDI.X12.SearchTableI</IndexLocation>
<StreamLocation>^EnsLib.EDI.X12.SearchTableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
