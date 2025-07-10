/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Defines an audit trail for the Rules Engine.<br>
/// Maintains a history of when rules were invoked and the reason for the returned value.
Class Ens.Rule.Log Extends (%Persistent, Ens.Util.BitmapPurge, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Ensure that we don't get $C(0) for values that are empty strings
Parameter XMLIGNORENULL = 1;

Index TimeExecuted On TimeExecuted;

Index SessionId On SessionId;

Index RuleName On RuleName [ Type = bitmap ];

/// The id for the session in which the Rule was fired.
Property SessionId As %Integer(XMLNAME = "sessionId", XMLPROJECTION = "attribute");

/// Time that this Rule was executed.
Property TimeExecuted As Ens.DataType.UTC(XMLNAME = "timeExecuted", XMLPROJECTION = "attribute") [ InitialExpression = {##class(Ens.DataType.UTC).Normalize($$$timeUTC)}, Required ];

/// The name of the Rule Definition that was executed.
Property RuleName As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "ruleName", XMLPROJECTION = "attribute") [ Required ];

/// The name of the ruleSet that was executed.
Property RuleSet As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "ruleSet", XMLPROJECTION = "attribute");

/// The effectiveBegin of the ruleSet executed.
Property EffectiveBegin As %String(COLLATION = "EXACT", MAXLEN = 2000, XMLNAME = "effectiveBegin", XMLPROJECTION = "attribute");

/// The effectiveEnd of the ruleSet executed.
Property EffectiveEnd As %String(COLLATION = "EXACT", MAXLEN = 2000, XMLNAME = "effectiveEnd", XMLPROJECTION = "attribute");

/// (Optional) The name of the BPL rule activity that invoked the rule.
Property ActivityName As %String(MAXLEN = 128, TRUNCATE = 1, XMLNAME = "activityName", XMLPROJECTION = "attribute");

/// The reason (e.g, rule name) that the Rules Engine performed its action.
Property Reason As %String(MAXLEN = 2000, TRUNCATE = 1, XMLNAME = "reason", XMLPROJECTION = "attribute");

/// The value returned by the Rule Engine for this rule.
Property ReturnValue As %String(MAXLEN = "", XMLNAME = "returnValue", XMLPROJECTION = "attribute");

/// If the Rules Engine returns an error it is placed here.
Property ErrorMsg As %String(MAXLEN = 1024, TRUNCATE = 1, XMLNAME = "errorMsg", XMLPROJECTION = "attribute");

/// True if this is an error.
Property IsError As %Boolean [ InitialExpression = 0 ];

Property DebugId As %Integer;

/// Configured name of the InterSystems IRIS host from which the rule was logged.
Property ConfigName As %String(MAXLEN = 128, TRUNCATE = 1);

Index ConfigName On ConfigName [ Type = bitmap ];

/// Current message header id rule was logged.
Property CurrentHeaderId As %String(MAXLEN = 128, TRUNCATE = 1);

/// Returns the current contents of the Rule Audit Log.
Query Enumerate() As %SQLQuery
{
	SELECT %ID,
		SessionId,
		TimeExecuted,
		ActivityName,
		RuleName,
		RuleSet,
		EffectiveBegin,
		EffectiveEnd,
		Reason,
		ReturnValue,
		IsError,
		ErrorMsg,
		DebugId,
		ConfigName,
		CurrentHeaderId
	FROM Ens_Rule.Log
	ORDER BY %ID ASC
}

ClassMethod Log(pSessionId As %Integer, pRuleName As %String, pRuleSet As %String, pEffectiveBegin As %String, pEffectiveEnd As %String, pActivityName As %String, pReason As %String, pReturnValue As %String, pErrorMsg As %String, pIsError As %Boolean, pDebugId As %Integer = "") As %Status
{
	#dim tConfigName As %String = $$$JobConfigName
	#dim tCurrentHeaderId As %String = $G($$$JobCurrentHeaderId)
	
	&sql(INSERT INTO Ens_Rule.Log
		(SessionId,RuleName,RuleSet,EffectiveBegin,EffectiveEnd,ActivityName,Reason,ReturnValue,ErrorMsg,IsError,DebugID,ConfigName,CurrentHeaderId) VALUES
		(:pSessionId,:pRuleName,:pRuleSet,:pEffectiveBegin,:pEffectiveEnd,:pActivityName,:pReason,:pReturnValue,:pErrorMsg,:pIsError,:pDebugId,:tConfigName,:tCurrentHeaderId)
	)
	If SQLCODE {
		Quit $$$ERROR($$$SQLCode,SQLCODE,$get(%msg))
	}
	Quit $$$OK
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pDummy As %Boolean, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

	Set tSC = ##class(Ens.Rule.RuleLog).Purge(.pDeletedCount,pDaysToKeep)
	Set pDeletedCount = +$get(pDeletedCount)

	New %tDoNotDeleteDate,%tID Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set SQLCODE=0, pDeletedCount=0
	&sql(DECLARE C1 CURSOR FOR
		Select %ID Into :%tID From Ens_Rule.Log Where TimeExecuted < :%tDoNotDeleteDate)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		&sql(Delete From Ens_Rule.Log Where %ID=:%tID)
		Set pDeletedCount=pDeletedCount+%ROWCOUNT
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID_"; SQLCODE = "_SQLCODE)
	Set tSC = ..PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
	Merge pDeletedCount("bitmaps") = tDeletedChunks
	Kill tTransactionSuspendedSwitch
	Quit tSC
}

Trigger OnDelete [ Event = DELETE, Foreach = row/object ]
{
	New tDebugId
	Set tDebugId = {DebugId}
	If (tDebugId '= "") {
		&sql(DELETE FROM Ens_Rule.DebugLog WHERE DebugId = :tDebugId)
		If (SQLCODE '= 0) && (SQLCODE '= 100) {
			Set %ok = $$$ERROR($$$SQLCode,SQLCODE,$get(%msg))
		}
	}
}

Storage Default
{
<Data name="LogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SessionId</Value>
</Value>
<Value name="3">
<Value>TimeExecuted</Value>
</Value>
<Value name="4">
<Value>RuleName</Value>
</Value>
<Value name="5">
<Value>RuleSet</Value>
</Value>
<Value name="6">
<Value>EffectiveBegin</Value>
</Value>
<Value name="7">
<Value>EffectiveEnd</Value>
</Value>
<Value name="8">
<Value>ActivityName</Value>
</Value>
<Value name="9">
<Value>Reason</Value>
</Value>
<Value name="10">
<Value>ReturnValue</Value>
</Value>
<Value name="11">
<Value>ErrorMsg</Value>
</Value>
<Value name="12">
<Value>IsError</Value>
</Value>
<Value name="13">
<Value>DebugId</Value>
</Value>
<Value name="14">
<Value>ConfigName</Value>
</Value>
<Value name="15">
<Value>CurrentHeaderId</Value>
</Value>
</Data>
<DataLocation>^Ens.Rule.LogD</DataLocation>
<DefaultData>LogDefaultData</DefaultData>
<ExtentSize>20000000</ExtentSize>
<IdLocation>^Ens.Rule.LogD</IdLocation>
<IndexLocation>^Ens.Rule.LogI</IndexLocation>
<Property name="SessionId">
<Selectivity>20</Selectivity>
</Property>
<Property name="TimeExecuted">
<Selectivity>1</Selectivity>
</Property>
<StreamLocation>^Ens.Rule.LogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
