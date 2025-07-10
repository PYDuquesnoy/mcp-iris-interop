/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated: RFC Ping Request object generated for iWay-based SAP adapter
Class EnsLib.SAP.RFCPING Extends Ens.Request [ ClassType = persistent, Not ProcedureBlock, System = 4 ]
{

Parameter RESPONSECLASSNAME = "EnsLib.SAP.RFCPING.Response";

Parameter XMLNAME = "RFC_PING";

Parameter XMLSEQUENCE = 0;

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
