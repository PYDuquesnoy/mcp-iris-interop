/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.OutboundAdapter Extends Ens.Adapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

Property BusinessHost As Ens.BusinessOperation;

Method OnInit() As %Status
{
	Quit $$$OK
}

}
