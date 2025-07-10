/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate a MessageHeader type value
/// value = 3 is no longer in use. It was used for Normal pripority in the past, and is only defined here for displaying older messages.
Class Ens.DataType.MessagePriority Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",HighSync,Sync,Normal,SimSync,Async";

Parameter VALUELIST = ",1,2,3,4,6";

}
