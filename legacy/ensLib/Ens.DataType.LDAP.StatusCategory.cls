/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate LDAP StatusCategory type
Class Ens.DataType.LDAP.StatusCategory Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Success,Referral,Authorization,Unavailable,Operation,System,Unknown";

Parameter VALUELIST = ",0,1,2,4,8,16,32";

}
