/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate a Priority value
Class Ens.DataType.LogType Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",Assert,Error,Warning,Info,Trace,Alert";

Parameter VALUELIST = ",1,2,3,4,5,6";

}
