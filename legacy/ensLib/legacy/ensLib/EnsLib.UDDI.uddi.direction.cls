/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.uddi.org/schema/uddi_v3.xsd
Class EnsLib.UDDI.uddi.direction Extends %String [ ClassType = datatype, CompileAfter = , ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter MAXLEN;

Parameter NAMESPACE = "urn:uddi-org:api_v3";

Parameter VALUELIST = ",fromKey,toKey";

}
