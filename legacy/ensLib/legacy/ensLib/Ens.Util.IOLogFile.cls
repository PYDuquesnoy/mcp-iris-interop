/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A header class that records raw Adapter Inputs and Outputs
Class Ens.Util.IOLogFile Extends Ens.Util.IOLog [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Property InObject As %FileCharacterStream;

Property OutObject As %FileCharacterStream;

Method IsEmpty() As %Boolean
{
	Quit ""=..%Id()&&(0=..InObject.Size)&&(0=..OutObject.Size)
}

/// Ensure that we remove references to file streams that no longer exist before trying to
/// delete the object, as attempts to delete these stale file pointers will result in errors.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	Set tIOLog = ..%Open(oid)
	If $IsObject(tIOLog) {
		Set tMod = 0
		If (tIOLog.InObject.Filename '= "") && '##class(%Library.File).Exists(tIOLog.InObject.Filename) {
			Set tMod = 1
			Set tIOLog.InObject.Filename = ""
		}
		If (tIOLog.OutObject.Filename '= "") && '##class(%Library.File).Exists(tIOLog.OutObject.Filename) {
			Set tMod = 1
			Set tIOLog.OutObject.Filename = ""
		}
		If tMod Do tIOLog.%Save()
	}
	Quit $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
