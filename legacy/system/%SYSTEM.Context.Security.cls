/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syPidtab

Class %SYSTEM.Context.Security Extends %Library.SystemBase
{

Property EscalationRole As %String(MAXLEN = 64);

Property EscalationTimeout As %Integer;

Property IsCSP As %Boolean;

Property LoginContext As %String(MAXLEN = "") [ Private ];

Property InitialDevices As %String(MAXLEN = "") [ Private ];

Property CurrentDevice As %String(MAXLEN = "") [ Private ];

Property IsTrigger As %Boolean [ Private ];

Property BreakMode As %Boolean [ Private ];

Property LoginTimeout As %Integer;

Property InLoop As %Boolean [ InitialExpression = 0, Private ];

Method %OnClose() As %Status [ Internal ]
{
}

Method %OnNew(init) As %Status [ Internal ]
{
}

Method EscalationRoleSet(val) As %Status [ Internal ]
{
}

Method IsCSPSet(val) As %Status [ Internal ]
{
}

Method EscalationTimeoutSet(val) As %Status [ Internal ]
{
}

Method LoginTimeoutSet(val) As %Status [ Internal ]
{
}

Method SetLoginTimeout(to) [ Internal ]
{
}

Method IsEscalated() As %Boolean
{
}

Method Escalate(Role As %String, to As %Integer) [ Internal ]
{
}

Method ClearEscalation(audit As %Boolean = 1) [ Internal ]
{
}

Method EscalationLoop() As %Status [ Internal ]
{
}

ClassMethod CheckNSAccess() As %Status [ Internal, Private ]
{
}

ClassMethod loopInternal() [ Internal, Private ]
{
}

/// This method returns an object which will ensure that escalation is cleared
/// when the object is removed from the stack.
ClassMethod getStackTrigger() As %ObjectHandle [ Internal, Private ]
{
}

ClassMethod getEscalationPrompt(cmdTime) As %String [ Internal, Private ]
{
}

}
