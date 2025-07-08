/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %XML.XPATH.ValueResult Extends %XML.XPATH.Result [ System = 4 ]
{

Method %LoadData(id As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..target=id Quit $$$OK
}

Property Value;

Method ValueGet()
{
	#; Test for simple value
	If $$$JobPrivateGlobalRef(i%target,"v")=1 Quit ^("v",1)
	
	#; Value is compound, create a stream for it
	Set tResult=##class(%GlobalCharacterStream).%New()
	For tI=1:1:$$$JobPrivateGlobalRef(i%target,"v") Do tResult.Write($$$JobPrivateGlobalRef(i%target,"v",tI))
	Do tResult.Rewind()
	Quit tResult
}

Storage custom
{
<Type>%Library.CustomStorage</Type>
}

}
