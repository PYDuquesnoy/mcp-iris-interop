/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Datatype for a TCP Port to connect to (integer value below 65536, may be prepended with @AgentName:)
Class Ens.DataType.TCPAgentPort Extends %String [ System = 4 ]
{

Parameter MAXLEN = 135;

Parameter MINLEN = 1;

ClassMethod IsValid(pVal As %String) As %Status [ ServerOnly = 1 ]
{
	Quit:""=pVal $$$OK
	If "@"=$E(pVal) {
		Set tAgent=$E($P(pVal,":"),2,*), pVal=$E(pVal,$L(tAgent)+3,*)
		Quit:$L(tAgent)>128||'$L(tAgent) $$$ERROR($$$EnsErrGeneral,"Agent name '@"_tAgent_"' is too long")
	}
	Quit:pVal'?1.5N||(pVal<=0)||(pVal>65535) $$$ERROR($$$EnsErrGeneral,"Port number '"_pVal_"' is not valid")
	Quit $$$OK
}

}
