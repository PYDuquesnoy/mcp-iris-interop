/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// MFT Outbound Adapter
Class EnsLib.MFT.Adapter.Outbound Extends (Ens.OutboundAdapter, EnsLib.MFT.Adapter.Common) [ System = 4 ]
{

Parameter SETTINGS = "MFTConnectionName:Basic:mftconnectionSelector";

Method OnInit() As %Status
{
	#;Make MFT Connection
	#dim tSC As %Status = ##class(EnsLib.MFT.Adapter.Common)$this.OnInit()

	Quit tSC
}

}
