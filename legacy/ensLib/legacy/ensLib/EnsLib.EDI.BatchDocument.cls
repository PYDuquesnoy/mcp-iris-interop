/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDI

IncludeGenerator (Ensemble, %occInclude)

/// Common base class for VDoc documents that can contain other VDoc documents of the same type
Class EnsLib.EDI.BatchDocument Extends EnsLib.EDI.Document [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// An object representing the original immediate parent document of this nested document, if nested
Property Parent As EnsLib.EDI.Document [ Calculated, ReadOnly, Transient ];

/// The ID:SegIndex of the immediate parent document of this nested document, if nested
Property ParentId As %String(COLLATION = "EXACT", MAXLEN = "");

/// The ID:SegIndex of the outermost parent document of this nested document, if nested
Property TopParentId As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {TopParentId}=$LG({ParentIds},$LL({ParentIds}))}, SqlComputed, Transient ];

/// A $List of the ID:SegIndex's of all the enclosing parent documents of this nested
///  document, if nested,in order from from immediate to outermost.
/// E.g. for Id of enclosing batch document if we are a document within a batch document
Property ParentIds As %String [ Calculated, ReadOnly, SqlComputeCode = { Set {ParentIds}=##class({%%CLASSNAME}).getParentIds({ParentId},1) }, SqlComputed, Transient ];

/// Number of Children
Property ChildCount As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {ChildCount}="subclass responsibility" }, SqlComputed, Transient ];

/// The raw text content of the document. Note that this is a truncated version suitable for use in SQL results and visual inspection,
/// but not a complete or definitive representation of the document.
Property RawContent As %String(MAXLEN = "") [ Calculated, ReadOnly ];

Method ParentIdsGet() As %String [ CodeMode = expression ]
{
$S(""=..ParentId:"",1:$LB(..ParentId)_..Parent.ParentIds)
}

ClassMethod getParentIds(pParentRef, pSkipOne = 0) As %String [ CodeMode = objectgenerator ]
{
	Set tSuperTable=##class(Ens.VDoc.SearchTableGenerator).GetExtentSupertable(%compiledclass.Name)
 	If tSuperTable="" {
		Do %code.WriteLine(" Quit $$$OK // not %Persistent")
		Quit $$$OK
	}
	Do %code.WriteLine(" Quit:""""=pParentRef """"")
	Do %code.WriteLine(" Set tParentId=$P(pParentRef,"":"")")
	Do %code.WriteLine(" &sql(Select ParentId Into :tGrandparentRef From "_tSuperTable_" Where ID=:tParentId)")
	Do %code.WriteLine(" Quit:SQLCODE $S(pSkipOne:"""",1:$LB(pParentRef))")
	Do %code.WriteLine(" Quit $S(pSkipOne:"""",1:$LB(pParentRef))_..getParentIds(tGrandparentRef,0)")
	Quit $$$OK
}

Method TopParentIdGet() As %String [ CodeMode = expression ]
{
$LG(..ParentIds,$LL(..ParentIds))
}

/// Required for AutoForm
Method ParentGetObjectId(force As %Integer) As %String [ CodeMode = expression ]
{
$P(..ParentId,":")
}

Method ParentGet() As EnsLib.EDI.Document [ CodeMode = objectgenerator ]
{
	Set tSuperclass=##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(%compiledclass.Name)
 	If tSuperclass="" {
		Do %code.WriteLine(" Quit $$$OK // not %Persistent")
		Quit $$$OK
	}
	Do %code.WriteLine(" Quit:""""'=..ParentId ##class("_tSuperclass_").%OpenId($P(..ParentId,"":""))")
	Do %code.WriteLine(" Quit $$$NULLOREF")
	Quit $$$OK
}

/// Implemented in subclasses
Method resolveChildDocType() As %String
{
	Set tDocType = ..DocType
	Set tParent = ..Parent
	If (""=tDocType)&&($IsObject(tParent))&&(""'=tParent.DocTypeCategory) {
		Set tNameFound = ..Name
		Set:(""'=tNameFound) tDocType=tParent.DocTypeCategory_":"_tNameFound
	}
	Quit tDocType
}

Method ChildCountGet(pParentRef As %String = "") As %Status [ CodeMode = expression ]
{
..getChildCount(..%Id(),pParentRef)
}

ClassMethod getChildCount(pId As %String, pRefSegIndex As %String = "") As %Status [ CodeMode = objectgenerator ]
{
	Set tSuperTable=##class(Ens.VDoc.SearchTableGenerator).GetExtentSupertable(%compiledclass.Name)
 	If tSuperTable="" {
		Do %code.WriteLine(" Quit $$$OK // not %Persistent")
		Quit $$$OK
	}
	Do %code.WriteLine(" Quit:""""=pId 0")
	Do %code.WriteLine(" If """"=pRefSegIndex {")
	Do %code.WriteLine("  &sql(Select Count(*) Into :tCount From "_tSuperTable_" Where ParentId=:pId Or ParentId %StartsWith :pId||':')")
	Do %code.WriteLine(" } Else {")
	Do %code.WriteLine("  Set tIdVal=pId_"":""_pRefSegIndex")
	Do %code.WriteLine("  &sql(Select Count(*) Into :tCount From "_tSuperTable_" Where ParentId=:tIdVal)")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit:SQLCODE 0")
	Do %code.WriteLine(" Quit tCount")
	Quit $$$OK
}

Method NextChild(pChild As EnsLib.EDI.Document = {$$$NULLOREF}, pRefSegIndex As %String) As EnsLib.EDI.Document [ CodeMode = objectgenerator ]
{
	Set tSuper=##class(Ens.VDoc.SearchTableGenerator).GetExtentSuperclass(%compiledclass.Name)
 	If tSuper="" {
		Do %code.WriteLine(" Quit $$$OK ; not %Persistent")
		Quit $$$OK
	}
	Do %code.WriteLine(" Set tId=..NextChildId($S($IsObject(pChild):pChild.%Id(),1:""""),.pRefSegIndex)")
	Do %code.WriteLine(" Quit $S(""""=tId:$$$NULLOREF,1:##class("_tSuper_").%OpenId(tId))")
}

Method NextChildId(pId As %String, pRefSegIndex As %String) As %String [ CodeMode = expression ]
{
..getNextChildId(..%Id(),.pId,.pRefSegIndex)
}

ClassMethod getNextChildId(pParentId As %String, pId As %String = "", pRefSegIndex As %String = "") As %String [ CodeMode = objectgenerator ]
{
	Set tSuperTable=##class(Ens.VDoc.SearchTableGenerator).GetExtentSupertable(%compiledclass.Name)
 	If tSuperTable="" {
		Do %code.WriteLine(" Quit $$$OK ; not %Persistent")
		Quit $$$OK
	}
	Do %code.WriteLine(" Set tDocId=$$$NULLOREF")
	Do %code.WriteLine(" If """"=pId {")
	Do %code.WriteLine("  If """"=pRefSegIndex {")
	Do %code.WriteLine("   &sql(Select ID Into :tDocId From "_tSuperTable_" Where ParentId=:pParentId Or ParentId %StartsWith :pParentId||':' Order By ID)")
	Do %code.WriteLine("  } Else {")
	Do %code.WriteLine("   Set tIdVal=pParentId_"":""_pRefSegIndex")
	Do %code.WriteLine("   &sql(Select ID Into :tDocId From "_tSuperTable_" Where ParentId=:tIdVal Order By ID)")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" } Else {")
	Do %code.WriteLine("  If """"=pRefSegIndex {")
	Do %code.WriteLine("   &sql(Select ID Into :tDocId From "_tSuperTable_" Where (ParentId=:pParentId Or ParentId %StartsWith :pParentId||':') And ID>:pId Order By ID)")
	Do %code.WriteLine("  } Else {")
	Do %code.WriteLine("   Set tIdVal=pParentId_"":""_pRefSegIndex")
	Do %code.WriteLine("   &sql(Select ID Into :tDocId From "_tSuperTable_" Where ParentId=:tIdVal And ID>:pId Order By ID)")
	Do %code.WriteLine("  }")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tDocId")
	Quit $$$OK
}

ClassMethod GetChildIdsArray(ByRef pArray, pParentId As %String, pLeavesOnly As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, tNextId="" For { Set tNextId=..getNextChildId(pParentId,tNextId)  Quit:""=tNextId
		If ..getChildCount(tNextId) {
			Set:'pLeavesOnly pArray=$G(pArray)+1, pArray(pArray)=tNextId
			Set tSC=..GetChildIdsArray(.pArray,tNextId,pLeavesOnly)  Quit:$$$ISERR(tSC)
		} Else {
			Set pArray=$G(pArray)+1, pArray(pArray)=tNextId
		}
	}
	Quit tSC
}

/// To the current batch parent object, add one or more child objects as children of the DocsRef placeholder segment referenced by its index position in <var>pRefSegIndex</var>.
/// (This is 2 for a simple batch parent with 3 segments: Header, DocsRef, and Trailer segments.)
Method AddChild(pRefSegIndex As %Integer, pChild...) As %Status [ CodeMode = expression ]
{
..AddChildArray(.pRefSegIndex,.pChild)
}

/// To the current batch parent object, add one or more child objects as children of the DocsRef placeholder segment referenced by its index position in <var>pRefSegIndex</var>.
/// (This is 2 for a simple batch parent with 3 segments: Header, DocsRef, and Trailer segments.)
/// The children are objects passed as numbered subscript values in array <var>pChildren</var> whose top value is the count of child object values.
Method AddChildArray(pRefSegIndex As %Integer, ByRef pChildren) As %Status
{
	Quit:'..IsMutable $$$ERROR($$$EnsErrGeneral,"Object is immutable")
	Set tParentRef=..getId()_":"_pRefSegIndex
	For i=1:1:pChildren { Set tChild=pChildren(i)
		Set tChild.ParentId=tParentRef
		Set tSC=tChild.%Save()  Quit:$$$ISERR(tSC)
	}
	Quit ..SetValueAt(pChildren+..GetValueAt(pRefSegIndex_":"_$$$REFSEGFLDCOUNT),pRefSegIndex_":"_$$$REFSEGFLDCOUNT)
}

/// Override in subclass
/// Used by DTL Editor for nested schemas in Batch document
ClassMethod GetBatchChildDTLInfoArray(pDocType As %String, pSegment As %String, pNodeAddr As %String, ByRef pBatchChildInfoArray As %String) As %Boolean [ Internal ]
{
	Return 0
}

}
