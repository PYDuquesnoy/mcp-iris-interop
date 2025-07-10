/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RecordMap.Model.RecordReference Extends EnsLib.RecordMap.Model.BatchElement [ System = 4 ]
{

/// Name of the underlying RecordMap.
Property recordMap As %String(MAXLEN = 220, XMLPROJECTION = "ATTRIBUTE") [ Required ];

/// Ensure that the corresponding RecordMap exists and can be correctly pulled out of the Batch.
Method %OnValidateObject() As %Status [ Private, ServerOnly = 1 ]
{
	If '##class(EnsLib.RecordMap.Model.Record).Exists(..recordMap) {
		Quit $$$ERROR($$$ClassDoesNotExist,..recordMap)
	}
	If ('..isExplicitSpec()) && ('..mapHasIdentifier()) {
		Quit $$$ERROR($$$EnsRecordMapErrIdentifierRequired,..recordMap,..name)
	}
	Quit ##super()
}

/// Helper method to indicate whether the underlying RecordMap specified in <property>recordMap</property>
/// has leading data that serves as an identifier.
Method mapHasIdentifier() As %Boolean
{
	Set tIdentifier = ##class(EnsLib.RecordMap.RecordMap).GetRecordIdentifier(..recordMap)
	Quit (tIdentifier '= "")
}

}
