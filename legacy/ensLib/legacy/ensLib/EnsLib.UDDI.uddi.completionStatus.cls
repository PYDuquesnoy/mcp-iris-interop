/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.completionStatus Extends %String [ ClassType = datatype, CompileAfter = , ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter MAXLEN = 32;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter VALUELIST = ",status:complete,status:fromKey_incomplete,status:toKey_incomplete,status:both_incomplete";

}
