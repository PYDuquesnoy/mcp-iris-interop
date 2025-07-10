/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate a RunStatus value
Class Ens.DataType.RunStatus Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Ready,Completed,Waiting,Errored";

Parameter VALUELIST = ",1,2,3,4";

}
