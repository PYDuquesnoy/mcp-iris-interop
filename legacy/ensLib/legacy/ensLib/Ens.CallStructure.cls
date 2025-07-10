/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.CallStructure Extends %RegisteredObject [ System = 4 ]
{

Property TargetDispatchName As %String;

Property Request As %Library.Persistent;

Property Response As %Library.Persistent;

Property Description As %String;

Property ResponseCode As %Status [ InitialExpression = {$$$OK} ];

}
