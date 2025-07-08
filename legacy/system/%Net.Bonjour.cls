/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides access to the Bonjour service registration protocol
Class %Net.Bonjour Extends %RegisteredObject [ System = 4 ]
{

/// Registers a service with Bonjour
Method Register(name As %String, type As %String, port As %Integer, txtRecord As BonjourTXTRecord = "") As BonjourServiceReference
{
	//txt records are optional
	if ($G(txtRecord)) {
		Set txtHandle = ..ConstructTXTRecord(txtRecord)
	}
	else {
		Set txtHandle = ""
	}
	Set serviceHandle = ##class(BonjourLibrary).Advertise(name, type, port, txtHandle)
	Do ##class(BonjourLibrary).TXTMapDestroy(txtHandle)
	Set ref = ##class(BonjourServiceReference).%New()
	Set ref.Handle = serviceHandle
	Quit ref
}

/// Returns an integer handle to a Bonjour TXT Record
ClassMethod ConstructTXTRecord(txtRecord As BonjourTXTRecord) As %Integer
{
	Set handle = ##class(BonjourLibrary).TXTMapCreate()
	Set key = txtRecord.KeyValueMap.Next("")
	While key '= "" {
		Do ##class(BonjourLibrary).TXTMapSetAt(handle, key, txtRecord.KeyValueMap.GetAt(key))
		Set key = txtRecord.KeyValueMap.Next(key)
	}
	Quit handle
}

/// Returns true if Bonjour services are supported in this instance
ClassMethod IsSupported() As %Boolean
{
	//just delegate to the library wrapper
	Quit ##class(BonjourLibrary).IsSupported()
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	//Check to see if Bonjour is supported
	If ##class(BonjourLibrary).IsSupported() {
		Quit $$$OK
	}
	Else {
		Quit $$$ERROR($$$UnsupportedError)
	}
}

}
