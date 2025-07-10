/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used by the PubSub Routing Operation to return routing information for a given message or topic.
Class EnsLib.PubSub.Response Extends Ens.Response [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// List of targets to which the message should be sent.
Property TargetList As list Of EnsLib.PubSub.Target;

/// Make sure non-subscriber target objects are deleted when then 
/// *this* response is deleted.
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status
{
	Set id = $$$oidPrimary(oid)

	&sql(DELETE FROM EnsLib_PubSub.Target 
			WHERE %CorrespondingResponse = :id)

	Quit $$$OK
}

Storage Default
{
<Data name="ResponseDefaultData">
<Subscript>"Response"</Subscript>
<Value name="1">
<Value>TargetList</Value>
</Value>
</Data>
<DefaultData>ResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
