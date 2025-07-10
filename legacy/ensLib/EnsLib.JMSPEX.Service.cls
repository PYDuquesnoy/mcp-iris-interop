/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMSPEX.Service Extends Ens.BusinessService
{

Property TargetConfigNames As Ens.DataType.ConfigName;

Property Adapter As EnsLib.JMSPEX.InboundAdapter;

Parameter ADAPTER = "EnsLib.JMSPEX.InboundAdapter";

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnProcessInput(pInput As %Net.Remote.Object, Output pOutput As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tMsg = ##class(EnsLib.JMSPEX.Message).%New()
		Do tMsg.FromRemoteObject(pInput)
		
		Set targets = $LFS(..TargetConfigNames)
		For i=1:1:$LL(targets) {
			Set target = $LG(targets, i)
			Set tSC = ..SendRequestAsync(target, tMsg)
			Quit:$$$ISERR(tSC)
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
