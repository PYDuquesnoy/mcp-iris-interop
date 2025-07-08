/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Remote.Exception Extends %Exception.AbstractException [ System = 3 ]
{

Property RemoteError As %String(MAXLEN = "");

Property RawData As %String(MAXLEN = "");

Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR(..Code,..Name_" "_..RemoteError_" "_..Location_" "_..Data)
}

Method DisplayString(pLevel As %Integer = 0) As %String
{
	Quit $Justify("",pLevel)_..Name_" "_..RemoteError_" "_$tr(..Location," ",$c(160))_" "_..Data
}

Method StackAsArray(ByRef array) As %Status
{
	kill array
	for i=1:1:$ll(..iStack) set array($i(array)) = $li(..iStack,i)
	quit $$$OK
}

}
