/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate LDAP Scope type
Class Ens.DataType.LDAP.Scope Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Base,One level,Subtree,Object";

Parameter VALUELIST = ",0,1,2,0";

}
