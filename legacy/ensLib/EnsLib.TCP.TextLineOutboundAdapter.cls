/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

Class EnsLib.TCP.TextLineOutboundAdapter Extends (EnsLib.TCP.OutboundAdapter, EnsLib.TCP.TextLineCommon) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/* override (empty) superclass initial Terminators value */
Property Terminators As %String [ InitialExpression = {$C(10)} ];

Method SendMessageString(pRequestString As %String, Output pResponseString As %String) As %Status
{
	Set pResponseString=""
	Set tSC = ..Connect(..ConnectTimeout)
	If $$$ISERR(tSC) { Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectException) ..BusinessHost.Retry=1  Quit tSC }

	Set tSC = ..WriteLine(pRequestString)
	If $$$ISERR(tSC) {
		If ..IsWriteError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Text Line Write",..IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If '..StayConnected { Do ..Disconnect() }
			Else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		Quit tSC
	}
	If ..GetReply {
		Set tSC = ..ReadLine(.pResponseString, ..ResponseTimeout)
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Text Line Read",..IOAddr,$$$StatusDisplayString(tSC))
				Set ..BusinessHost.Retry=1  Do ..Disconnect()
			} Else {
				Set:$$$StatusEquals(tSC,$$$EnsErrTCPTerminatedReadTimeoutExpired) ..BusinessHost.Retry=1
				Do ..TestConnection() ; calls Disconnect() if connection is down
			}
		}
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	Quit tSC
}

}
