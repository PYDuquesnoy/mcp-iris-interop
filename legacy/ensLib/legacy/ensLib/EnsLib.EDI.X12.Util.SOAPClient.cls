/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.EDI.X12.Util.SOAPClient Extends %SOAP.WebClient [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is the URL used to access the web service.
Parameter LOCATION = "http://127.0.0.1/EnsLib.EDI.X12.Service.SOAPService.cls";

Parameter NAMESPACE = "http://tempuri.org";

Parameter SERVICENAME = "X12Service";

Method Send(Input As %Stream.GlobalCharacter) As %Stream.GlobalCharacter [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
	Quit ..WebMethod("Send").Invoke($this,"http://tempuri.org/EnsLib.EDI.X12.Service.SOAPService.Send",.Input)
}

}
