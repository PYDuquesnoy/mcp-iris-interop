/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Remote.ImportHelper Extends %RegisteredObject [ System = 3 ]
{

ClassMethod ExpressImport(classOrJar As %String, port As %Integer, path As %String = "", host As %String = "127.0.0.1") [ Final ]
{
	Set classPath=##class(%ListOfDataTypes).%New()
	If (path'="") {
		Do classPath.Insert(path)
	}
	Do ..Import(classOrJar,classPath,port,host)
}

/// Imports the given interface
ClassMethod Import(name As %String, classPath As %ListOfDataTypes, port As %Integer, host As %String = "127.0.0.1", exclusions As %ListOfDataTypes = "") [ Final, Private ]
{
	Try {
		Set gateway=..Connect(port,host) 
		Quit:gateway=""
		Set status=gateway.%Import(name,.classes,classPath,exclusions) If status'=$$$OK { Do ..ProcessError(status) Quit }
		Write "Generated the following proxy classes:",!
		For i=1:1:classes.Count() {
			Write "  ["_i_"] "_classes.GetAt(i),!
		}
		Write !
		Set status=gateway.%Disconnect()
		Do ..ProcessError(status)
	} Catch exception {
		Set status=##class(%Net.Remote.Gateway).%SetStatus(exception)
		Do ..ProcessError(status)
	}
}

/// Given a jar file or a directory name, displays all available classes in tha jar file/directory
ClassMethod Browse(jarFileOrDirectoryName As %String, port As %Integer, host As %String = "127.0.0.1") [ Final ]
{
	Try {
		Set gateway=..Connect(port,host) 
		Quit:gateway=""
		Set status=gateway.%GetAllClasses(jarFileOrDirectoryName,.classes)  If status'=$$$OK { Do ..ProcessError(status) Quit }
		For i=1:1:classes.Count() {
			Write "  ["_i_"] "_classes.GetAt(i),!
		}
		Set status=gateway.%Disconnect()
		Do ..ProcessError(status)
	} Catch exception {
		Set status=##class(%Net.Remote.Gateway).%SetStatus(exception)
		Do ..ProcessError(status)
	}
}

ClassMethod ProcessError(status As %Status) [ Final ]
{
	Use 0
	If status=$$$OK {
		Write !,"Test Successfully Completed"
	} Else {
		Write $system.OBJ.DisplayError(status)
	}
}

ClassMethod Connect(port As %Integer, host As %String) As %Net.Remote.Gateway
{
	Set namespace=$namespace,timeout=2
	Set gateway=##class(%Net.Remote.Gateway).%New()
	Set status=gateway.%Connect(host,port,namespace,timeout)  
	If status'=$$$OK { Do ..ProcessError(status) Quit ""}
	Quit gateway
}

}
