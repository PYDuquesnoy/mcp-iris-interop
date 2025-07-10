/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Context for determining where Managed Alert notifications should be sent.
Class Ens.Alerting.Context.Notify Extends (%Persistent, %XML.Adaptor) [ NoExtent, System = 4 ]
{

Property NotificationRequest As Ens.Alerting.NotificationRequest;

Property Targets As list Of Ens.Alerting.NotificationTarget;

Property Notify As %Boolean [ InitialExpression = 1 ];

Method NotifySet(pNotify As %Boolean) As %Status
{
	Set i%Notify = ''pNotify
	Quit $$$OK
}

/// Don't permit this object to be saved at this time.
/// The persistence is primarily to ensure that the class is listed in various Ensemble lists.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	Quit ..%RemoveFromSaveSet()
}

}
