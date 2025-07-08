/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <class>%Exception.PythonException</class> class provides access to information
/// about the most recent python error.  It is the type of object assigned to
/// the CATCH variable when a python error occurs inside a TRY block.
/// Only the System should create an instance of this class.
/// 
Class %Exception.PythonException Extends %Exception.AbstractException [ Final ]
{

Property ExceptionObject;

Method %OnNew(pName As %String = "", pCode As %String = "", pLocation As %String = "", pData As %String = "", pInnerException As %Exception.AbstractException = {$$$NULLOREF}, pStack As %String, pObject As %SYS.Python = {$$$NULLOREF}) As %Status [ Private ]
{
	Set i%Name=pName,i%Code=pCode,i%Location=pLocation,i%Data=pData,i%InnerException=pInnerException,i%ExceptionObject=pObject
	Try {
		If $data(pStack) { Set i%iStack=pStack }
		Else { Set i%iStack=$LI($ZU(41,-2),2,*) }
	} Catch {
		#; $zu(41,-2) can get MAXSTRING error
		Set i%iStack=""
	}
	Quit $$$OK
}

/// Force Name to be Read-Only
Method NameSet(pName As %String) As %Status [ Internal, Private ]
{
	Set i%Name=pName
	Quit $$$OK
}

/// Force Code to be Read-Only
Method CodeSet(pCode As %Integer) As %Status [ Internal, Private ]
{
	Set i%Code=pCode
	Quit $$$OK
}

/// Force Location to be Read-Only
Method LocationSet(pLocation As %String) As %Status [ Internal, Private ]
{
	Set i%Location=pLocation
	Quit $$$OK
}

/// Force Data to be Read-Only
Method DataSet(pData As %String) As %Status [ Internal, Private ]
{
	Set i%Data=pData
	Quit $$$OK
}

/// Force InnerException to be Read-Only
Method InnerExceptionSet(pInnerException As %Exception.AbstractException) As %Status [ Internal, Private ]
{
	Set i%InnerException=pInnerException
	Quit $$$OK
}

/// Force Object to be Read-Only
Method ObjectSet(pObject As %SYS.Python) As %Status [ Internal, Private ]
{
	Set i%Object=pObject
	Quit $$$OK
}

/// Convert this exception to a traditional $ZE string
Method AsSystemError() As %String [ CodeMode = expression ]
{
i%Name_i%Location_$select(i%Data'="":$select($extract(i%Data)="^":" ",1:" *")_i%Data,1:"")
}

/// Custom conversion of an exception to a status
Method OnAsStatus() As %Status [ CodeMode = expression, Private ]
{
$$$ERROR($$$ObjectScriptError,i%Name_i%Location_$select(i%Data'="":$select($extract(i%Data)="^":" ",1:" *")_i%Data,1:""),,,,,,,,,,$select(i%iStack="":$lb(""),1:i%iStack))
}

/// Custom conversion of an exception to the SQL %msg string
Method OnAsSQLMessage() As %String(MAXLEN="")
{
	RETURN $$GetErrorText^%apiOBJ(..AsStatus())
}

/// Return a string that represents the exception
Method DisplayString(pLevel As %Integer = 0) As %String
{
	Quit $Justify("",pLevel)_i%Name_$S(i%Code:" "_i%Code_" ",1:"")_$S(i%Location]"":i%Location_" ",1:"")_i%Data
}

}
