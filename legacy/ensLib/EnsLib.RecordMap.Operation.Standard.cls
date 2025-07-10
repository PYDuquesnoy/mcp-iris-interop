/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is intended for simple output of records into files. It is NOT designed to be
/// run in multiple processes as it implements no locking.
Class EnsLib.RecordMap.Operation.Standard Extends Ens.BusinessOperation [ Abstract, System = 4 ]
{

Parameter SETTINGS = "RecordMap:Basic:selector?context={Ens.ContextSearch/RecordMaps}";

/// Name of the RecordMap which is to be written out.
Property RecordMap As %String(MAXLEN = 220) [ Required ];

/// Full classname of the RecordMap.
Property recordMapFull As %String(MAXLEN = 220) [ Private, Transient ];

/// Wrapper method for the PutObject method on the RecordMap class.
Method PutObject(pStream As %IO.DeviceStream, pObject As %RegisteredObject) As %Status
{
	Try {
		$$$sysTRACE("Writing object "_$select(pObject."%%OID" '= "": "with classname '"_$classname(pObject)_"' and Id '"_$listget(pObject."%%OID",1),1: "'"_pObject)_"' to stream '"_pStream.Name_"'")
		Set tStatus = $classmethod(..recordMapFull, "PutObject", pStream, pObject)
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Confirm that the RecordMap exists and confirm that the classes have been generated.
Method OnInit() As %Status
{
	Try {
		set tStatus = $$$OK
		Set tStatus = ..%ValidateObject()
		If $$$ISERR(tStatus) Quit
	
		If '##class(EnsLib.RecordMap.RecordMap).Exists(..RecordMap) {
			Set tStatus = $$$ERROR($$$ClassDoesNotExist, ..RecordMap)
			Quit
		}
		
		Set ..recordMapFull = $$$NormalizeClassname(..RecordMap)
		
		Set tObjectClass = $classmethod(..recordMapFull, "%GetParameter", "OBJECTNAME")
		If '##class(%Dictionary.CompiledClass).%ExistsId(tObjectClass) {
			Set tStatus = $$$ERROR($$$ClassDoesNotExist, tObjectClass)
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

}
