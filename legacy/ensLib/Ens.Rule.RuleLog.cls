/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Deprecated; use Ens.Rule.Log.
/// Defines an audit trail for the Rules Engine.<br>
/// Maintains a history of when rules were invoked and the reason for the returned value.
Class Ens.Rule.RuleLog Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

/// IdKey
Index ID On (SessionId, ExecutionId) [ IdKey ];

Index TimeExecuted On TimeExecuted;

/// The id for the session in which the Rule was fired.
Property SessionId As %Integer(XMLNAME = "sessionId", XMLPROJECTION = "attribute");

/// Unique id for this rule execution.
Property ExecutionId As %Integer(XMLNAME = "executionId", XMLPROJECTION = "attribute") [ InitialExpression = {$I(^Ens.Rule.RuleLogC("ExecutionId"))} ];

/// Time that this Rule was executed.
Property TimeExecuted As Ens.DataType.UTC(XMLNAME = "timeExecuted", XMLPROJECTION = "attribute") [ InitialExpression = {$$$timeUTC}, Required ];

/// The class name of the Business Process that invoked the rule.
Property HostClass As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "host", XMLPROJECTION = "attribute");

/// The name of the Rule Definition that was executed.
Property RuleName As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "ruleName", XMLPROJECTION = "attribute") [ Required ];

/// The EffectiveBeginDateTime of the rule executed.
Property EffectiveBeginDateTime As %String(COLLATION = "EXACT", MAXLEN = 2000, XMLNAME = "effectiveBeginDateTime", XMLPROJECTION = "attribute");

/// The EffectiveEndDateTime of the rule executed.
Property EffectiveEndDateTime As %String(COLLATION = "EXACT", MAXLEN = 2000, XMLNAME = "effectiveEndDateTime", XMLPROJECTION = "attribute");

/// Object Id of Rule Definition.
Property RuleId As %String(XMLPROJECTION = "none") [ Calculated, SqlComputeCode = { Set {RuleId}={HostClass}_"||"_{RuleName}
}, SqlComputed, SqlComputeOnChange = (HostClass, RuleName) ];

/// (Optional) The name of the BPL rule activity that invoked the rule.
Property ActivityName As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "activityName", XMLPROJECTION = "attribute");

/// The version number for the Rule Definition.
Property RuleVersion As %Integer(XMLNAME = "ruleVersion", XMLPROJECTION = "attribute");

/// The reason (e.g, rule name) that the Rules Engine performed its action.
Property Reason As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "reason", XMLPROJECTION = "attribute");

/// The value returned by the Rule Engine for this rule.
Property ReturnValue As %String(MAXLEN = "", XMLNAME = "returnValue", XMLPROJECTION = "attribute");

/// If the Rules Engine returns an error it is placed here.
Property ErrorMsg As %String(MAXLEN = 1024, TRUNCATE = 1, XMLNAME = "errorMsg", XMLPROJECTION = "attribute");

/// True if this is an error.
Property IsError As %Boolean [ InitialExpression = 0 ];

/// The name of the routine in the Rule Cache used to execute this rule.
Property RoutineName As %String(MAXLEN = 255, TRUNCATE = 1, XMLNAME = "routineName", XMLPROJECTION = "attribute");

Method RuleIdGet() As %String [ CodeMode = expression ]
{
i%HostClass _ "||" _ i%RuleName
}

/// Returns the current contents of the Rule Audit Log.
Query Enumerate() As %SQLQuery
{
	SELECT %ID,
		SessionId,
		ExecutionId,
		TimeExecuted,
		HostClass,
		ActivityName,
		RuleName,
		EffectiveBeginDateTime,
		EffectiveEndDateTime,
		RuleVersion,
		Reason,
		ReturnValue,
		IsError,
		ErrorMsg,
		RuleId,
		RoutineName
	FROM RuleLog
 	ORDER BY ExecutionId
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pDummy As %Boolean) As %Status
{
	New %tDoNotDeleteDate,%tID Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set SQLCODE=0, pDeletedCount=0
	&sql(DECLARE C1 CURSOR FOR
		Select ID Into :%tID From Ens_Rule.RuleLog Where TimeExecuted < :%tDoNotDeleteDate)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		&sql(Delete From Ens_Rule.RuleLog Where ID=:%tID)
		Set pDeletedCount=pDeletedCount+%ROWCOUNT
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE)
	Quit $$$OK
}

Storage Default
{
<Data name="RuleLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ActivityName</Value>
</Value>
<Value name="3">
<Value>HostClass</Value>
</Value>
<Value name="4">
<Value>Reason</Value>
</Value>
<Value name="5">
<Value>ReturnValue</Value>
</Value>
<Value name="6">
<Value>RuleName</Value>
</Value>
<Value name="7">
<Value>RuleVersion</Value>
</Value>
<Value name="8">
<Value>TimeExecuted</Value>
</Value>
<Value name="9">
<Value>Status</Value>
</Value>
<Value name="10">
<Value>Status</Value>
</Value>
<Value name="11">
<Value>ErrorMsg</Value>
</Value>
<Value name="12">
<Value>IsError</Value>
</Value>
<Value name="13">
<Value>RoutineName</Value>
</Value>
<Value name="14">
<Value>EffectiveBeginDateTime</Value>
</Value>
<Value name="15">
<Value>EffectiveEndDateTime</Value>
</Value>
</Data>
<DataLocation>^Ens.Rule.RuleLogD</DataLocation>
<DefaultData>RuleLogDefaultData</DefaultData>
<IdLocation>^Ens.Rule.RuleLogD</IdLocation>
<IndexLocation>^Ens.Rule.RuleLogI</IndexLocation>
<StreamLocation>^Ens.Rule.RuleLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
