/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageQuery [ Abstract, Not ProcedureBlock, System = 2 ]
{

Query Summary(classname As %String) As %Query(ROWSPEC = "Name")
{
}

ClassMethod SummaryExecute(ByRef QHandle As %Binary, classname As %String) As %Status [ CodeMode = expression ]
{
##class(%Dictionary.CompiledClassQuery).MemberSummaryExecute(.QHandle,classname,$$$cCLASSstorage)
}

ClassMethod SummaryFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ CodeMode = expression ]
{
##class(%Dictionary.CompiledClassQuery).MemberSummaryFetch(.QHandle,.Row,.AtEnd)
}

ClassMethod SummaryClose(QHandle As %Binary) As %Status [ CodeMode = expression ]
{
##class(%Dictionary.CompiledClassQuery).MemberSummaryFetch(.QHandle)
}

}
