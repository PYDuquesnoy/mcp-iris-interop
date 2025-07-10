/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.Dialog.MessageBodyDisplay Extends EnsPortal.Dialog.MessageBodyDisplay [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MsgBank_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageHeader:USE";

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
Method DrawBodyInfo(pHeaderID As %String) As %Status
{
	If ""=pHeaderID { 
		Quit $$$OK
	}
	Else {
		Quit ##class(EnsPortal.Utils).DrawBodyInfo(pHeaderID,"Ens.Enterprise.MsgBank.MessageHeader")
	}
}

/// Write out contents of details panel.
/// <var>pID</var> is the message id.
Method DrawDetailsContent(pID As %String) As %Status
{
	If ""=pID { 
		Quit $$$OK
	}
	Else {
		Quit ##class(EnsPortal.Utils).DrawItemDetails(pID,"Ens.Enterprise.MsgBank.MessageHeader")
	}
}

}
