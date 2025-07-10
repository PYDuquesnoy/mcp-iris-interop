/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.SearchCriteria Extends EnsPortal.Dialog.SearchCriteria [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MsgBank_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_MessageHeader:USE";

Property headerClass As %ZEN.Datatype.className [ InitialExpression = "Ens.Enterprise.MsgBank.MessageHeader" ];

}
