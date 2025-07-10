/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Used as the context object for the background business processes
Class Ens.Background.BP.Context Extends Ens.BP.Context [ System = 4 ]
{

/// Name of Role
Property WorkFlowRole As %String(MAXLEN = 128);

/// Flag used in BPL to wait for WF action
Property WaitOnWorkFlow As %Boolean [ InitialExpression = 1 ];

/// Workflow user who is asked to confirm WF request - if process' RequiresConfirmation is true
Property ConfirmUser As %String(MAXLEN = 128);

/// Result of confirmation action
Property ConfirmAction As %String(MAXLEN = 128);

/// Final WF action
Property CompletedWorkAction As %String(MAXLEN = 128);

Storage Default
{
<Data name="ContextDefaultData1">
<Subscript>"Context"</Subscript>
<Value name="1">
<Value>WorkFlowRole</Value>
</Value>
<Value name="2">
<Value>WaitOnWorkFlow</Value>
</Value>
<Value name="3">
<Value>ConfirmUser</Value>
</Value>
<Value name="4">
<Value>ConfirmAction</Value>
</Value>
<Value name="5">
<Value>CompletedWorkAction</Value>
</Value>
</Data>
<DefaultData>ContextDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
