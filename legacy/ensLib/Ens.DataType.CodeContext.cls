/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Encapsulate a CodeContext value
Class Ens.DataType.CodeContext Extends %Integer [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

Parameter DISPLAYLIST = ",None,Process,Request,Response";

Parameter VALUELIST = ",1,2,3,4";

}
