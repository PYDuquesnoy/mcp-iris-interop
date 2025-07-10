/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate a Priority value
Class Ens.DataType.MessageStatus Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Created,Queued,Delivered,Discarded,Suspended,Deferred,Aborted,Error,Completed";

Parameter VALUELIST = ",1,2,3,4,5,6,7,8,9";

}
