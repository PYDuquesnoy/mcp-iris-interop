/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created from: http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd
Class EnsLib.ebXML.schema.msg.severity.type Extends %String [ ClassType = datatype, CompileAfter = , ProcedureBlock, System = 4 ]
{

Parameter ELEMENTQUALIFIED = 1;

Parameter ATTRIBUTEQUALIFIED = 1;

Parameter MAXLEN;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter VALUELIST = ",Warning,Error";

}
