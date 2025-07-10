/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occLG, %occMGInfo)

Class EnsLib.SOAP.CST.Fault Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

Property Code As %String;

Property Title As %String;

Property Actor As %String;

Property Text As %String;

Property Namespace As %String;

/// Return this SOAP fault as a string.
Method FaultAsString() As %String
{
 Quit "code="_..Code_$c(13,10)_
 "title="_..Text_$c(13,10)_
 "actor="_..Actor_$c(13,10)_
 "text="_..Text_$c(13,10)_
 "namespace="_..Namespace
}

}
