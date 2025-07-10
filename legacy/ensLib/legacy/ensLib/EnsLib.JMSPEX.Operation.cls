/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMSPEX.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.JMSPEX.OutboundAdapter";

Property Adapter As EnsLib.JMSPEX.OutboundAdapter;

Parameter INVOCATION = "Queue";

Method OnMessage(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..Adapter.SendMessage(pRequest)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
