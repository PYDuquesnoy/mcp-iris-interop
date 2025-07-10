/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDI

/// Common base class for VDoc classes that have Separators and are non-persistent, being objects representing Segments that compose an instance of a "Segmented" VDoc class
Class EnsLib.EDI.Segment Extends EnsLib.EDI.Document [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Index into Segment Storage
Property ID As %String [ ReadOnly ];

/// All Separators as a single String
Property Separators As %String;

/// Number of Fields
Property Count As %Integer [ Calculated, ReadOnly ];

/// We clear this property to prevent saving or modifying of already-saved document objects
Property IsMutable As %Boolean [ ReadOnly ];

/// creates an object based on id=initvalue but editable if specified
Method %OnNew(initvalue As %RawString = "") As %Status [ CodeMode = expression, Private ]
{
..init($LG(initvalue,1),+$LG(initvalue,2),$LG(initvalue,3),$LG(initvalue,4))
}

/// Initialize a segment. The segid is typically an index into the Segment storage global. Mutable indicates
/// whether the initialized segment may be modified or not and SegType is used to determine the
/// segment schema to be used for interpretation of segment contents
Method init(pSegID As %String = "", pMutable As %Boolean = 0, pSegType As %String = "", pSegData As %String = "") As %Status [ Abstract, Internal ]
{
	if pSegID="" set i%IsMutable=1 quit $$$OK
	set i%ID=pSegID,i%IsMutable=+pMutable
	quit $$$OK
}

Method NameGet() As %String [ CodeMode = expression, Internal ]
{
..GetValueAt(0)
}

Method CountGet() As %String [ CodeMode = expression, Internal ]
{
..GetValueAt("*")
}

Method IsMutableSet(value As %Library.Boolean) As %Status [ Abstract, CodeMode = expression, Internal ]
{
$$$OK
}

/// Returns the value at the specified property path. The separators argument is used to specify the
/// separators to be used when a non-atomic value is returned. Status is returned via the Status output variable.
/// A boolean value <var>pTreatEmptyFieldAsNull</var> indicates whether repeating fields which have a separator but are empty should be considered to have a count of 1 (if false) or 0 (if true)
Method GetValueAt(pPropertyPath As %String = "", pSeparators As %String = "", Output pStatus As %Status, pTreatEmptyFieldAsNull As %Boolean = 0) As %String [ Abstract, CodeMode = expression ]
{
""
}

/// Sets a value at the specified property path. Typically the key is used to specify arguments which may
/// be matched at run-time with place-holders in the property path. The action corresponds to the actions in the
/// DTL <assign> statement
Method SetValueAt(pValue As %String, pPropertyPath As %String = "", pKey As %String = "", pAction As %String = "set") As %Status [ CodeMode = expression ]
{
$S(..IsMutable:$$$OK, 1:$$$ERROR($$$EnsErrGeneral,"Object is immutable"))
}

Method SaveData() As %Status [ Abstract, CodeMode = expression ]
{
$$$OK
}

/// Validate a segment item
Method Validate(pPath As %String) As %Status [ Abstract ]
{
	$$$ASSERT("0:subclass responsibility")
	Quit $$$OK
}

/// Gets the next index in an array by path
Method GetNextIndex(pPath As %String, pIndex As %String, ByRef pStatus As %Status) As %String [ Abstract ]
{
	$$$ASSERT("0:subclass responsibility")
}

Method IsChildHolder(Output pRefSegIndex As %String) As %Boolean
{
	Set tName=..Name
	If "DocsRef"=$E(tName,*-$L("DocsRef")+1,*) {
		Set pRefSegIndex=..GetValueAt($$$REFSEGFLDINDEX)
		Quit 1
	} Else {
		Set pRefSegIndex=""
		Quit 0
	}
}

Method FindValuesArray(pPropertyPath As %String = "", pSeparators As %String, ByRef pArray As %String, pSchemaCategory As %String, Output pStatus As %Status = {$$$OK}, ByRef pLongArray As %String)
{
	Set $ZT="Trap"
	Set f=$F(pPropertyPath,"()")  If 'f {
		Set:""=..DocType&&(""'=pSchemaCategory) tCat=1, ..DocType=pSchemaCategory_":"_..Name
		Set tVal=..GetValueAt(pPropertyPath,.pSeparators,.pStatus) 
		If tVal '= "" {
			Set tInSub=1
			If $l(tVal) >= $$$MAXEDIARRAYSUBSCRIPT {
				Set pLongArray($i(pLongArray)) = tVal
				Set tInSub =0
			}
			Set pArray($E(tVal,1,$$$MAXEDIARRAYSUBSCRIPT))=""
			
		}
		Set:$G(tCat) ..DocType=""
		Quit
	}
	Set tHead=$E(pPropertyPath,1,f-3)
	Set tTail=$E(pPropertyPath,f,*)
	Set i="" For { Set i=..GetNextIndex(tHead_"()",i,.pStatus)  Quit:i=""
		Set tNewPath=tHead_"("_(i)_")"_tTail
		Do ..FindValuesArray(tNewPath,.pSeparators,.pArray,.pSchemaCategory,.tSC,.pLongArray)
		Set:$$$ISERR(tSC) pStatus=$$$ADDSC(pStatus,tSC)
	}
	Quit
Trap
	Set $ZT="", pStatus=$$$SystemError
	Quit
}

Method FindValues(pPropertyPath As %String = "", pSeparators As %String, pValSepString As %String = "<>", pSchemaCategory As %String, Output pStatus As %Status = {$$$OK}) As %String
{
	Set f=$F(pPropertyPath,"()")  If 'f {
		Set:""=..DocType&&(""'=pSchemaCategory) tCat=1, ..DocType=pSchemaCategory_":"_..Name
		Set tVals=..GetValueAt(pPropertyPath,.pSeparators,.pStatus)
		Set:$G(tCat) ..DocType=""
		Quit tVals
	}
	Set tHead=$E(pPropertyPath,1,f-3)
	Set tTail=$E(pPropertyPath,f,*)
	Set tVals=""
	Set i="" For { Set i=..GetNextIndex(tHead_"()",i,.pStatus)  Quit:i=""
		Set tNewPath=tHead_"("_(i)_")"_tTail
		Set tVal=..FindValues(tNewPath,.pSeparators,pValSepString,.pSchemaCategory,.tSC)
		Set:""'=tVal tVals=$S(""=tVals:"",1:tVals_pValSepString)_tVal
		Set:$$$ISERR(tSC) pStatus=$$$ADDSC(pStatus,tSC)
	}
	Quit tVals
}

}
