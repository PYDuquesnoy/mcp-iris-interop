/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate a MessageHeader type value
Class Ens.DataType.MessageBusinessType Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Unknown,BusinessService,BusinessProcess,BusinessOperation";

Parameter VALUELIST = ",0,1,2,3";

}
