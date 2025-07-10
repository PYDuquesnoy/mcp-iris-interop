/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.AmazonSQS.Service Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.AmazonSQS.InboundAdapter";

Property Adapter As EnsLib.AmazonSQS.InboundAdapter;

Property TargetConfigNames As Ens.DataType.ConfigName;

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnProcessInput(pInput As %Net.Remote.Object, Output pOutput As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tMsg = ##class(EnsLib.AmazonSQS.Message).%New()
		Do tMsg.FromRemoteObject(pInput)
		W tMsg.ToJSON(), !
		
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
