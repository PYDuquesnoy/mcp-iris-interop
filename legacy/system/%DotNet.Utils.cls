/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DotNet.Utils Extends %RegisteredObject [ System = 4 ]
{

ClassMethod Classes(Output pStream As %GlobalCharacterStream) As %Status
{
	Set tSC=$$$OK,$ZE="Trap"
	do {
		
		#; Create the Stream to Write To (this will appear as a string in DotNet)
		Set pStream=##class(%GlobalCharacterStream).%New()
		If '$IsObject(pStream) Set tSC=%objlasterror Quit
		
		#; Going to write to IRIS.Temp to obtain the correct package order
		Set tKey=$Increment(^IRIS.Temp),tClass=$Order(^oddDEF(""))
		while tClass'=""
		{
			#; Pick out the package and classname and cache in ^IRIS.Temp
			Set tPieceCount=$Length(tClass,".")
			Set tPackage=$Piece(tClass,".",1,tPieceCount-1),tClassName=$Piece(tClass,".",tPieceCount)
			Set ^IRIS.Temp(tKey,tPackage,tClassName)="",tClass=$Order(^oddDEF(tClass))
		}
	
		#; Now walk through the Packages/Classes and construct the return value
		Set tPackage=$Order(^IRIS.Temp(tKey,"")),tFirst=1
		while tPackage'="" {
		
			if 'tFirst {
				Do pStream.Write("|")
			} else {
				Set tFirst=0
			}
			Do pStream.Write(tPackage_"~")
			
			Set tClass=$Order(^IRIS.Temp(tKey,tPackage,""))
			while tClass'="" {
				
				Do pStream.Write(tClass)
				Set tClass=$Order(^IRIS.Temp(tKey,tPackage,tClass))
				If tClass'="" Do pStream.Write("^")
			}
			Set tPackage=$Order(^IRIS.Temp(tKey,tPackage))
		}
		
		Kill ^IRIS.Temp(tKey)
	
	} while (0)
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod Namespaces(Output pStream As %GlobalCharacterStream) As %Status
{
	Set tSC=$$$OK,$ZE="Trap"
	do {
		#; Create the Stream to Write To (this will appear as a string in DotNet)
		Set pStream=##class(%GlobalCharacterStream).%New()
		If '$IsObject(pStream) Set tSC=%objlasterror Quit
	
		#; Enumerate the Namespaces on this system, add to array to remove duplicates
		d List^%SYS.NAMESPACE(.tNS)
		
		#; Walk the array and build the result string
		Set tNS=$Order(tNS(""))
		while tNS'="" {
			Do pStream.Write(tNS)
			Set tNS=$Order(tNS(tNS))
			If tNS'="" Do pStream.Write("|")
		}	
	} while (0)
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod DerivedClasses(pClassName As %String, Output pStream As %GlobalCharacterStream) As %Status
{
	Set tSC=$$$OK,$ZE="Trap"
	do {
		#; Create the Stream to Write To (this will appear as a string in DotNet)
		Set pStream=##class(%GlobalCharacterStream).%New()
		If '$IsObject(pStream) Set tSC=%objlasterror Quit
	
		Set tSC=$$GetAllDerivedClasses^%occLibrary(pClassName,.tCN)
		If $$$ISERR(tSC) Quit
		
		#; Walk the array and build the result string
		Set tCN=$Order(tCN(""))
		while tCN'="" {
			Do pStream.Write(tCN)
			Set tCN=$Order(tCN(tCN))
			If tCN'="" Do pStream.Write("|")
		}	
	} while (0)
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod Configuration(Output pString As %String) As %Status
{
	Set tSC=$$$OK,$ZE="Trap"
	do {
		Set pString=$Piece($ZU(86),"*",2)
	} while (0)
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

ClassMethod Test()
{
	do
	{
		Set tSC=..Classes(.tStream)
		If $$$ISERR(tSC) Quit
		Do tStream.OutputToDevice()
		
		Set tSC=..Namespaces(.tStream)
		If $$$ISERR(tSC) Quit
		Do tStream.OutputToDevice()
		
		Set tSC=..DerivedClasses("%RegisteredObject",.tStream)
		Do tStream.OutputToDevice()
		
	} while (0)
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC) Quit
}

}
