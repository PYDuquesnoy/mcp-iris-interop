/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RecordMap.Model.RecordSequence Extends EnsLib.RecordMap.Model.BatchElement [ System = 4 ]
{

/// The sequence of <class>RecordReference</class> and <class>RecordSequence</class> objects that exist in the sequence.
Property Elements As list Of EnsLib.RecordMap.Model.BatchElement(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Required ];

/// Ensure that if the first Record in the Sequence is optional, the Record has an identifier (i.e. leading data).
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	Set tStatus = ##super()
	If $$$ISERR(tStatus) Quit tStatus
	If '..isExplicitSpec() {
		// Ensure that we know what the identifier first record in each possible sub-sequence has an identifier
		//Set tRecordMap = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(..recordMap)
	}
	Quit $$$OK
}

Method isExplicitSpec() As %Boolean
{
	Set tIsExplicit = ##super()
	If 'tIsExplicit Quit tIsExplicit

	Quit ..areChildrenExplicit()
}

Method areChildrenExplicit() As %Boolean
{
	Set tIsExplicit = 1
	For i=1:1:..Elements.Count() {
		Set tIsExplicit = ..Elements.GetAt(i).isExplicitSpec()
		If 'tIsExplicit Quit
	}
	Quit tIsExplicit
}

Method getFirstIdentifier() As %String
{
	Set tElement = ..Elements.GetAt(1)
	If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
		Quit ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(tElement.recordMap)
	}
	ElseIf $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
		Quit tElement.getFirstIdentifier()
	}
	Quit ""
}

/// Examine children to work out which identifiers will trigger this particular sequence
Method getIdentifiers(ByRef pIdents)
{
	For i=1:1:..Elements.Count() {
		Set tElement = ..Elements.GetAt(i)
		If $classname(tElement) = "EnsLib.RecordMap.Model.RecordReference" {
			Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(tElement.recordMap)
			Set:'$D(pIdents(tIdentifier)) pIdents(tIdentifier) = tElement
			Quit:tElement.required ;# this record will be present in the sequence - no need to check anything later
		} ElseIf $classname(tElement) = "EnsLib.RecordMap.Model.RecordSequence" {
			Do tElement.getIdentifiers(.pIdents)
			Quit:tElement.required ;# some element from this sequence will be present - no need to check anything later
		}
	}
}

Method getPossibleRecords()
{
}

}
