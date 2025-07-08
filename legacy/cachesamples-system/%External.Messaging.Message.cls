/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base Message class 
Class %External.Messaging.Message Extends (%RegisteredObject, %JSON.Adaptor) [ Abstract ]
{

/// Convert message object to JSON String
Method ToJSON() As %String
{
   Do ..%JSONExportToString(.json)
   Quit json
}

/// Set up message object from JSON string
Method FromJSON(json As %String) As %Status
{
   Quit ..%JSONImport(json)
}

/// Set up message object from remote gateway object
Method FromRemoteObject(o As %Net.Remote.Object) As %Status
{
   Set tSC = $$$OK
   Try {
      Set json = o.toJson()
      Set tSC = ..FromJSON(json)
      Quit:$$$ISERR(tSC)
      // Set ignored json properties
      Do o.toIRISTransient($THIS)
   }
   Catch (ex) {
      Set tSC = ex.AsStatus()
   }
   Quit tSC
}

}
