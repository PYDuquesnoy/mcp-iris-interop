/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

Class EnsLib.RecordMap.ComplexMap [ Abstract, System = 4 ]
{

Parameter BATCHCLASS;

ClassMethod GetBatch(pIOStream As %IO.DeviceStream, pTimeout As %Numeric = -1, Output pBatch As EnsLib.RecordMap.ComplexBatch, ByRef pLookAhead As %String = "") As %Status
{
	Set pBatch = ""
	Quit $$$ERROR($$$NotImplemented)
}

/// Write out the batch header, all the records in the batch, and then the batch trailer
Method OutputWholeBatch(pIOStream As %IO.DeviceStream, pRecordMap As %String, pUnSwizzleRecords As %Boolean = 1) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Delete an existing Complex RecordMap, and optionally delete the target class definition and the target class's extent.<br>
/// The option to remove the extent is only evaluated if the target class is also being deleted, otherwise the option is ignored.<br>
/// The input parameter pLeaveClassDeleteToCaller & output parameter pTargetClass allow the caller to delete the ComplexMap class
/// and optional delete of TargetClass within a separate Source Control aware API.
ClassMethod DeleteComplexMap(pComplexMap As %String = "", pRemoveTargetClass As %Boolean = 0, pRemoveTargetExtent As %Boolean = 0, pLeaveClassDeleteToCaller As %Boolean = 0, Output pTargetClass As %String = "") As %Status
{
	If '##class(EnsLib.RecordMap.Model.ComplexBatch).Exists(pComplexMap) Quit $$$ERROR($$$ClassDoesNotExist,pComplexMap)

	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		#dim tComplexMap = $$$NormalizeClassname(pComplexMap)
		#; We'll pass back target class as pTargetClass if use it.
		#dim tTargetClass = $$$comMemberKeyGet(tComplexMap,$$$cCLASSparameter,"BATCHCLASS",$$$cPARAMdefault)
		If 'pLeaveClassDeleteToCaller {
			Set tStatus = ##class(%Dictionary.ClassDefinition).%DeleteId(tComplexMap)
			If $$$ISERR(tStatus) Quit
		}
		If pRemoveTargetClass && (tTargetClass '= "") {
			Set pTargetClass = $$$NormalizeClassname(tTargetClass)
			If pRemoveTargetExtent && ##class(%Dictionary.CompiledClass).%ExistsId(pTargetClass) && $classmethod(pTargetClass, "%Extends", "%Persistent") {
				Set tStatus = $classmethod(pTargetClass, "%DeleteExtent")
				If $system.Status.Equals(tStatus, $$$ERRORCODE($$$ClassDoesNotExist), $$$ERRORCODE($$$DeleteObjectNotFound)) Set tStatus = $$$OK
				If $$$ISERR(tStatus) Quit
			}
			If 'pLeaveClassDeleteToCaller {
				// Returns an error if target class doesn't exist
				Set tStatus = ##class(%Dictionary.ClassDefinition).%DeleteId(pTargetClass)
				If $$$ISERR(tStatus) Quit
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

}
