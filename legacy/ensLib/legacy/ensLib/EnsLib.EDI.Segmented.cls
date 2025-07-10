/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDI

/// Common (secondary) base class for VDoc classes that have segments, BuildMap(), and Separators
Class EnsLib.EDI.Segmented Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Number of Segments composing this Document
Property SegCount As %Integer [ Calculated, ReadOnly, SqlComputeCode = { Set {SegCount}="subclass responsibility" }, SqlComputed, Transient ];

/// The status of the last BuildMap() action, or empty if the map gets updated or discarded later.
/// Note that the BuildMap() is not called automatically when a saved document gets opened.
Property BuildMapStatus As %Status [ ReadOnly, Transient ];

/// Determines if maps should be built automatically on segment insertion/deletion
Property AutoBuildMap As %Boolean [ InitialExpression = 0, Transient ];

/// Flag to control whether segments retrieved from a document should be cached in the map of the document object.
/// Segments not cached will be marked immutable because the document will have no record of them and therefore couldn't save any changes to them when it is saved
Property CacheSegsGotten As %Boolean [ InitialExpression = 1, Transient ];

/// pReportMissingLoopAsFirstSeg not implemented except for in EnsLib.EDI.X12.Document
Method BuildMap(pKeepParsingAfterError As %Boolean = 1, pReportMissingLoopAsFirstSeg As %Boolean = 0) As %Status [ Abstract ]
{
	$$$ASSERT("0:Subclass Responsibility")
	Quit $$$OK
}

/// Gets a immutable segment object by path or index
Method GetSegmentAt(pIndexOrPath As %String, Output pStatus As %Status) As EnsLib.EDI.Segment
{
	If $G(pIndexOrPath)=""  Set pStatus=$$$ERROR($$$EnsErrGeneral,"Segment '' does not exist")  Quit $$$NULLOREF
	If $$$vaIsIndex(pIndexOrPath) Quit ..getSegmentByIndex($$$vaIndex(pIndexOrPath),.pStatus)
	Quit ..getSegmentByPath(pIndexOrPath,.pStatus)
}

/// Gets a immutable segment ID by path or index
Method GetSegmentIdAt(pIndexOrPath As %String, Output pStatus As %Status) As %String
{
	If $G(pIndexOrPath)="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Segment '' does not exist")  Quit ""
	If $$$vaIsIndex(pIndexOrPath) Quit ..getSegmentIdByIndex($$$vaIndex(pIndexOrPath),.pStatus)
	Quit ..getSegmentIdByPath(pIndexOrPath,.pStatus)
}

/// Gets a mutable segment object by path or index
Method GetMutableSegmentAt(pIndexOrPath As %String, Output pStatus As %Status) As EnsLib.EDI.Segment
{
	If '..IsMutable Set pStatus=$$$ERROR($$$EnsErrGeneral,"Object is immutable")  Quit $$$NULLOREF
	If $G(pIndexOrPath)="" Set pStatus=$$$ERROR($$$EnsErrGeneral,"Segment '' does not exist")  Quit $$$NULLOREF
	If $$$vaIsIndex(pIndexOrPath) Quit ..getMutableSegmentByIndex($$$vaIndex(pIndexOrPath),.pStatus)
	Quit ..getMutableSegmentByPath(pIndexOrPath,.pStatus)
}

/// Set a segment object by path or index
Method SetSegmentAt(pSegment As EnsLib.EDI.Segment, pIndexOrPath As %String = "") As %Status
{
	Quit:""=pIndexOrPath $$$ERROR($$$EnsErrGeneral,"Segment '' does not exist")
	If $$$vaIsIndex(pIndexOrPath) Quit ..setSegmentByIndex(pSegment,$$$vaIndex(pIndexOrPath),0)
	Quit ..setSegmentByPath(pSegment,pIndexOrPath)
}

/// Set a segment ID by path or index
Method SetSegmentIdAt(pSegmentId As %String, pIndexOrPath As %String = "") As %Status
{
	Quit:""=pIndexOrPath $$$ERROR($$$EnsErrGeneral,"Segment '' does not exist")
	If $$$vaIsIndex(pIndexOrPath) Quit ..setSegmentIdByIndex(pSegmentId,$$$vaIndex(pIndexOrPath),0)
	Quit ..setSegmentIdByPath(pSegmentId,pIndexOrPath)
}

/// Insert a segment object by index
Method InsertSegmentAt(pSegment As EnsLib.EDI.Segment, pIndex As %Integer = "") As %Status
{
	Quit:'$$$vaIsIndex(pIndex) $$$ERROR($$$EnsErrGeneral,"Segment index '"_pIndex_"' is not a valid number")
	Quit ..setSegmentByIndex(pSegment,$$$vaIndex(pIndex),1)
}

/// Insert a segment ID by index
Method InsertSegmentIdAt(pSegmentId As %String, pIndex As %Integer = "") As %Status
{
	Quit:'$$$vaIsIndex(pIndex) $$$ERROR($$$EnsErrGeneral,"Segment index '"_pIndex_"' is not a valid number")
	Quit ..setSegmentIdByIndex(pSegmentId,$$$vaIndex(pIndex),1)
}

/// Insert a segment at the end by index
Method AppendSegment(pSegment As EnsLib.EDI.Segment) As %Status [ CodeMode = expression ]
{
..InsertSegmentAt(pSegment,..SegCount+1)
}

/// Insert a segment ID at the end by index
Method AppendSegmentId(pSegmentId As %String) As %Status [ CodeMode = expression ]
{
..InsertSegmentIdAt(pSegmentId,..SegCount+1)
}

/// Removes a segment by path or index
Method RemoveSegmentAt(pIndexOrPath As %String = "") As %Status
{
	Quit:""=pIndexOrPath $$$ERROR($$$EnsErrGeneral,"Segment '' does not exist")
	If $$$vaIsIndex(pIndexOrPath) Quit ..removeSegmentByIndex($$$vaIndex(pIndexOrPath))
	Quit ..removeSegmentByPath(pIndexOrPath)
}

/// Returns a new segment of type suitable for inserting in the current transaction type at the position given by pSegPath
Method NewSegment(pSegPath As %String, pSeparators As %String, Output pStatus As %Status) As EnsLib.EDI.Segment [ Abstract ]
{
	$$$ASSERT("0:Subclass Responsibility")
}

Method GetSegmentTypeAt(pSegPath As %String, Output pStatus As %Status) As %String [ Abstract ]
{
	$$$ASSERT("0:Subclass Responsibility")
}

/// Finds all values matching a SegPath:PropertyPath string that contains zero or more () implicit iterators
Method GetValuesArray(pSegmentPropertyPath As %String, pSeparators As %String, ByRef pArray As %String, Output pStatus As %Status, ByRef pLongArray As %String)
{
	Set pStatus=$$$OK  Kill pArray,pLongArray
	Do ..getValsArray(pSegmentPropertyPath,.pSeparators,.pArray,.pStatus,.pLongArray)
}

/// Finds all values matching a SegPath:PropertyPath string that contains zero or more () implicit iterators
Method getValsArray(pSegmentPropertyPath As %String, pSeparators As %String, ByRef pArray As %String, Output pStatus As %Status, ByRef pLongArray As %String)
{
	Set $ZT="Trap"
	Set f=$F(pSegmentPropertyPath,"()")
	If 'f {
		Set tVal=..GetValueAt(pSegmentPropertyPath,.pSeparators,.pStatus)
		If tVal '= "" {
			If $l(tVal) >= $$$MAXEDIARRAYSUBSCRIPT {
				Set pLongArray($i(pLongArray)) = tVal
			}
			Set pArray($E(tVal,1,$$$MAXEDIARRAYSUBSCRIPT))=""
		}
		Quit
	}
	Set tHead=$E(pSegmentPropertyPath,1,f-3)
	Set tTail=$E(pSegmentPropertyPath,f,*)

	Set i="" For { Set i=..GetNextIndex(tHead_"()",i,.pStatus)  Quit:i=""
		Set tNewPath=tHead_"("_(i)_")"_tTail
		Do ..getValsArray(tNewPath,.pSeparators,.pArray,.tSC,.pLongArray)
		Set:$$$ISERR(tSC) pStatus=$$$ADDSC(pStatus,tSC)
	}
	Quit
Trap
	Set $ZT="", pStatus=$$$SystemError
	Quit
}

/// Finds all values matching a SegPath:PropertyPath string that contains zero or more () implicit iterators
/// Supports SegPath values with (), (n) to choose a specific one of the given type, or just plain (same as seg() or seg(*)).
Method GetValues(pSegmentPropertyPath As %String, pSeparators As %String, pValSepString As %String = "<>", Output pStatus As %Status) As %String
{
	Set pStatus=$$$OK
	Set f=$F(pSegmentPropertyPath,"()")  Quit:'f ..GetValueAt(pSegmentPropertyPath,.pSeparators,.pStatus)
	Set tHead=$E(pSegmentPropertyPath,1,f-3)
	Set tTail=$E(pSegmentPropertyPath,f,*)
	Set tVals=""
	Set i="" For { Set i=..GetNextIndex(tHead_"()",i,.pStatus)  Quit:i=""
		Set tNewPath=tHead_"("_(i)_")"_tTail
		Set tVal=..GetValues(tNewPath,.pSeparators,pValSepString,.tSC)
		Set:""'=tVal tVals=$S(""=tVals:"",1:tVals_pValSepString)_tVal
		Set:$$$ISERR(tSC) pStatus=$$$ADDSC(pStatus,tSC)
	}
	Quit tVals
}

/// Finds all values matching a SegName:PropertyPath string, where the SegName is a simple segment type name
///  (not a full schema-based seg path); PropertyPath describes a field or subfield within the segment.
/// Supports SegName = '*' to match any segment, and SegName(n) to match only the n'th segment of the given type.
Method FindSegmentValuesArray(pSegmentPropertyPath As %String, pSeparators As %String, ByRef pArray As %String, Output pStatus As %Status, pSchemaCategory As %String = "", ByRef pLongArray As %String)
{
	#; implementation for non-HL7 EDI documents
	Set pStatus=$$$OK  Kill pArray
	Set tSegName=$P(pSegmentPropertyPath,":"), tPropPath=$P(pSegmentPropertyPath,":",2)
	Set tSegIndex=$P(tSegName,"(",2), tSegName=$P($P($P(tSegName,"("),"-"),"!"), tSegIndex=$ZStrip($P(tSegIndex,")"),"<>W","*")
	Do:$ZStrip(tPropPath,"*A")'=tPropPath&&(""'=..DocType)&&(""=..BuildMapStatus) ..BuildMap(0) ; get seg types if available
	Set tIndex="" For i=1:1 { Set tSegObj=..FindSegment(tSegName,.tIndex,.pStatus)  Quit:""=tIndex
		Continue:(""'=tSegIndex)&&(i'=tSegIndex) ; if they asked for a specific number, forsake all others
		Do tSegObj.FindValuesArray(tPropPath,.pSeparators,.pArray,.pSchemaCategory,.pStatus,.pLongArray)  Quit:$$$ISERR(pStatus)
		Quit:i=tSegIndex ;all done
	}
}

/// Finds all values matching a SegName:PropertyPath string, where the SegName is a simple segment type name
///  (not a full schema-based seg path); PropertyPath describes a field or subfield within the segment. <br>
/// Supports SegName = '*' to match any segment, and SegName(n) to match only the n'th segment of the given type. <br>
/// Final parameter is an output of the list of segment indexes (separated by pValSepString) for the values found.
Method FindSegmentValues(pSegmentPropertyPath As %String, pSeparators As %String, pValSepString As %String = "<>", Output pStatus As %Status, pSchemaCategory As %String = "", Output pIndices As %String) As %String
{
	#; implementation for non-HL7 EDI documents
	Set pStatus=$$$OK, pIndices = ""
	Set tSegName=$P(pSegmentPropertyPath,":"), tPropPath=$P(pSegmentPropertyPath,":",2)
	Set tSegIndex=$P(tSegName,"(",2), tSegName=$P($P($P(tSegName,"("),"-"),"!"), tSegIndex=$ZStrip($P(tSegIndex,")"),"<>W","*")
	Do:$ZStrip(tPropPath,"*A")'=tPropPath&&(""'=..DocType)&&(""=..BuildMapStatus) ..BuildMap(0) ; get seg types if available
	Set (tVals,tIndex)="" For i=1:1 { Set tSegObj=..FindSegment(tSegName,.tIndex,.pStatus)  Quit:""=tIndex
		Continue:(""'=tSegIndex)&&(i'=tSegIndex) ; if they asked for a specific number, forsake all others
		Set tVal=tSegObj.FindValues(tPropPath,.pSeparators,pValSepString,.pSchemaCategory,.pStatus)  Quit:$$$ISERR(pStatus)
		If (""'=tVal) {
			Set tVals=$S(""=tVals:"",1:tVals_pValSepString)_tVal
			For tR=1:1:$L(tVal,pValSepString) Set pIndices = $S(""=pIndices:"",1:pIndices_pValSepString)_tIndex
		}
		Quit:i=tSegIndex ;all done
	}
	Quit tVals
}

/// Gets the next segment after index <var>pIndex</var> with name <var>pSegName</var>.
/// Supports <var>pSegName</var> = '*' to match any segment.
Method FindSegment(pSegName As %String, ByRef pIndex As %String = "", Output pStatus As %Status) As EnsLib.EDI.Segment [ Abstract ]
{
}

/// Returns a list of schema categories and segment types and segment fields for the document class. <br/>
/// The <var>Category</var> and <var>Level</var> parameters can be used to restrict the list. <br/>
/// If <var>Category</var> is: <br/>
///  0 - return only standard categories <br/>
///  + - return only user-defined categories <br/>
///  empty - return all categories <br/>
///  a category name - return only SegTypes in the named category <br/>
///  a category name:segment type name - return only information about the named SegType <br/>
///  a partial name suffixed with '%' - return only SegTypes in categories matching the partial category name <br/>
///  other - return nothing <br/>
/// If <var>Level</var> is: <br/>
///  0 - return all segment names <br/>
///  n - return the given number of levels of nested field names within each segment <br/>
///  empty - return all levels of nested field names within each segment <br/>
/// If <var>IncludeBase</var> is: <br/>
///  0 - return only segment names defined in the current schema category itself <br/>
///  1 - return all segment names in the current schema category's base category in addition to those defined in the current category itself <br/>
Query EnumerateSegTypes(Category As %String = "", Level As %String = "", IncludeBase As %Boolean = 0) As %Query(CONTAINID = 0, ROWSPEC = "SegType:%String,Field:%String,Description:%String,IsStandard:%Boolean")
{
}

ClassMethod EnumerateSegTypesExecute(ByRef qHandle As %Binary, Category As %String, Level As %String, IncludeBase As %Boolean) As %Status
{
	Set qHandle=0
	Quit $$$OK
}

ClassMethod EnumerateSegTypesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateSegTypesExecute ]
{
	Set Row="",AtEnd=1 Quit $$$OK
}

ClassMethod EnumerateSegTypesClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateSegTypesExecute ]
{
	Kill qHandle
	Quit $$$OK
}

}
