/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each trigger for tables that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.TRIGGERS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = TRIGGERS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On (SchemaExact, TableExact, TriggerObjName) [ IdKey, Internal, Unique ];

Property SchemaExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 20 ];

Property TableExact As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 21 ];

Property TriggerObjName As %String(MAXLEN = 128) [ Internal, Private, Required, SqlColumnNumber = 22 ];

/// Is the table a system table (1 or 0)
Property SystemTable As %Integer [ Calculated, Internal, Private, Required, SqlColumnNumber = 23, SqlComputeCode = { set {*}=$s($e({TABLE_SCHEMA})="%"||({TABLE_SCHEMA}="INFORMATION_SCHEMA"):1,1:0) }, SqlComputed ];

/// Table qualifier - always NULL in InterSystems IRIS
Property TABLECATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 2, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = TABLE_CATALOG ];

/// Name of schema that contains the table.
Property TABLESCHEMA As %String(COLLATION = "Upper", MAXLEN = 128) [ Calculated, Required, SqlColumnNumber = 3, SqlComputeCode = { set {*}={SchemaExact} }, SqlComputed, SqlFieldName = TABLE_SCHEMA ];

/// Name of the table.
Property TABLENAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Calculated, Required, SqlColumnNumber = 4, SqlComputeCode = { set {*}={TableExact} }, SqlComputed, SqlFieldName = TABLE_NAME ];

/// Name of the trigger.
Property TRIGGERNAME As %String(COLLATION = "Upper", MAXLEN = 128) [ Required, SqlColumnNumber = 5, SqlFieldName = TRIGGER_NAME ];

/// Event for this trigger, typically INSERT, UPDATE, or DELETE
Property EVENTMANIPULATION As %String(MAXLEN = 48) [ SqlColumnNumber = 6, SqlFieldName = EVENT_MANIPULATION ];

/// EVENT_OBJECT_CATALOG is not currently used by InterSystems IRIS, reserved for future use.
Property EVENTOBJECTCATALOG As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 7, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = EVENT_OBJECT_CATALOG ];

/// EVENT_OBJECT_SCHEMA is not currently used by InterSystems IRIS, reserved for future use.
Property EVENTOBJECTSCHEMA As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 8, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = EVENT_OBJECT_SCHEMA ];

/// EVENT_OBJECT_TABLE is not currently used by InterSystems IRIS, reserved for future use.
Property EVENTOBJECTTABLE As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 9, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = EVENT_OBJECT_TABLE ];

/// Column's ordinal position within the table.
Property ACTIONORDER As %Integer [ SqlColumnNumber = 10, SqlFieldName = ACTION_ORDER ];

/// ACTION_CONDITION is not currently used by InterSystems IRIS, reserved for future use.
Property ACTIONCONDITION As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 11, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = ACTION_CONDITION ];

/// ACTION_STATEMENT is not currently used by InterSystems IRIS, reserved for future use.
Property ACTIONSTATEMENT As %String(MAXLEN = "") [ SqlColumnNumber = 12, SqlFieldName = ACTION_STATEMENT ];

/// Foreach specification, ROW, ROW/OBJECT, or STATEMENT
Property ACTIONORIENTATION As %String(MAXLEN = 10, VALUELIST = ",ROW,ROW/OBJECT,STATEMENT") [ SqlColumnNumber = 13, SqlFieldName = ACTION_ORIENTATION ];

/// Time, BEFORE or AFTER
/// <br>BEFORE - the trigger's Time is BEFORE
/// <br>AFTER - the trigger's Time is AFTER
Property ACTIONTIMING As %String(MAXLEN = 6, VALUELIST = ",BEFORE,AFTER") [ SqlColumnNumber = 14, SqlFieldName = ACTION_TIMING ];

/// Trigger's old table name
Property ACTIONREFERENCEOLDTABLE As %String(MAXLEN = 128) [ SqlColumnNumber = 15, SqlFieldName = ACTION_REFERENCE_OLD_TABLE ];

/// Trigger's new table name
Property ACTIONREFERENCENEWTABLE As %String(MAXLEN = 128) [ SqlColumnNumber = 16, SqlFieldName = ACTION_REFERENCE_NEW_TABLE ];

/// ACTION_REFERENCE_OLD_ROW is not currently used by InterSystems IRIS, reserved for future use.
Property ACTIONREFERENCEOLDROW As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 17, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = ACTION_REFERENCE_OLD_ROW ];

/// ACTION_REFERENCE_NEW_ROW is not currently used by InterSystems IRIS, reserved for future use.
Property ACTIONREFERENCENEWROW As %String(MAXLEN = 128) [ Calculated, SqlColumnNumber = 18, SqlComputeCode = { set {*}=""}, SqlComputed, SqlFieldName = ACTION_REFERENCE_NEW_ROW ];

/// Time trigger was created
/// This is actually the time the class that defines the table was last changed as the IRIS class metadata cannot account for when the trigger was actually created
Property CREATED As %TimeStamp [ SqlColumnNumber = 19, SqlFieldName = CREATED ];

/// Access Variable {2D1} is the table's extent
Storage SQLStorage
{
<Description>
<![CDATA[Access Variable {2D1} is the table's extent]]></Description>
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="ACTION_ORDER">
<Node>23</Node>
</Data>
<Data name="ACTION_ORIENTATION">
<RetrievalCode>set {*}=$zcvt($s($d(^oddDEF({2D1},"t",{L3},26))#2:^(26),1:""),"U") set:{*}="" {*}="ROW"</RetrievalCode>
</Data>
<Data name="ACTION_REFERENCE_NEW_TABLE">
<Node>29</Node>
</Data>
<Data name="ACTION_REFERENCE_OLD_TABLE">
<Node>30</Node>
</Data>
<Data name="ACTION_STATEMENT">
<Node>21</Node>
</Data>
<Data name="ACTION_TIMING">
<RetrievalCode>set {*}=$s($d(^oddDEF({2D1},"t",{L3},25))#2:^(25),1:"") set:{*}="" {*}="BEFORE"</RetrievalCode>
</Data>
<Data name="CREATED">
<RetrievalCode>set {*}=$zdt($s($d(^oddCOM({2D1},63))#2:^(63),1:$s($d(^oddDEF({2D1},63))#2:^(63),1:"")),3)</RetrievalCode>
</Data>
<Data name="EVENT_MANIPULATION">
<Node>22</Node>
</Data>
<Data name="TRIGGER_NAME">
<RetrievalCode>set {*}=$s($d(^oddDEF({2D1},"t",{L3},24))#2:^(24),1:"") set:{*}="" {*}={L3}</RetrievalCode>
</Data>
<Global>^oddSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{SchemaExact}</Expression>
<Invalidcondition name="1">
<Expression>$e({L1},1,10)="IRIS_Shard"||($e({L1},1,20)="IRIS_MasterFederated")||($e({L1},1,14)="IRIS_Federated")</Expression>
</Invalidcondition>
<NextCode>set {L1} = $$GetNextSubscript^%SYS.SQLSEC("^oddSQL", {L1}) quit:{L1}=""
	goto:($e({L1},1,10)="IRIS_Shard"||($e({L1},1,20)="IRIS_MasterFederated")||($e({L1},1,14)="IRIS_Federated")) NEXT</NextCode>
</Subscript>
<Subscript name="2">
<Accessvar name="1">
<Code> set {2D1}=$li(^rINDEXSQL("rv",$zconvert({L1},"u"),$zconvert({L2},"u")),2)</Code>
<Variable>{2D1}</Variable>
</Accessvar>
<Expression>{TableExact}</Expression>
<Invalidcondition name="1">
<Expression>'($d(^oddSQL({L1},{L2}))#2)</Expression>
</Invalidcondition>
<Invalidcondition name="2">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC($li(^oddSQL({L1},{L2}),6),0)</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="3">
<DataAccess>^oddDEF({2D1},"t")</DataAccess>
<Expression>{TriggerObjName}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="rxIndex">
<Data name="ACTION_ORIENTATION">
<RetrievalCode>set {*}=$zcvt($s($d(^oddDEF({3D1},"t",{L4},26))#2:^(26),1:""),"U") set:{*}="" {*}="ROW"</RetrievalCode>
</Data>
<Data name="ACTION_TIMING">
<RetrievalCode>set {*}=$s($d(^oddDEF({3D1},"t",{L4},25))#2:^(25),1:"") set:{*}="" {*}="BEFORE"</RetrievalCode>
</Data>
<Data name="CREATED">
<RetrievalCode>set {*}=$zdt($s($d(^oddCOM({3D1},63))#2:^(63),1:$s($d(^oddDEF({3D1},63))#2:^(63),1:"")),3)</RetrievalCode>
</Data>
<Data name="SchemaExact">
<RetrievalCode>set {*}=$p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",1,*-1)</RetrievalCode>
</Data>
<Data name="TRIGGER_NAME">
<RetrievalCode>set {*}=$s($d(^oddDEF({3D1},"t",{L4},24))#2:^(24),1:"") set:{*}="" {*}={L4}</RetrievalCode>
</Data>
<Data name="TableExact">
<RetrievalCode>set {*}=$tr($p($lg(^rINDEXSQL("rv",{L2},{L3}),4),".",*),$c(2),".")</RetrievalCode>
</Data>
<Global>^rINDEXSQL</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"rv"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$UPPER({TABLE_SCHEMA})</Expression>
<Invalidcondition name="1">
<Expression>$e({L2},1,10)="IRIS_SHARD"||($e({L2},1,20)="IRIS_MASTERFEDERATED")||($e({L2},1,14)="IRIS_FEDERATED")</Expression>
</Invalidcondition>
<NextCode>set {L2} = $$GetNextSubscript^%SYS.SQLSEC("^rINDEXSQL(""rv"")", {L2}) quit:{L2}=""
	goto:($e({L2},1,10)="IRIS_SHARD"||($e({L2},1,20)="IRIS_MASTERFEDERATED")||($e({L2},1,14)="IRIS_FEDERATED")) NEXT</NextCode>
</Subscript>
<Subscript name="3">
<Accessvar name="1">
<Code> set {3D1}=$li(^rINDEXSQL("rv",{L2},{L3}),2)</Code>
<Variable>{3D1}</Variable>
</Accessvar>
<Expression>$$UPPER({TABLE_NAME})</Expression>
<Invalidcondition name="1">
<Expression>'$$AnyPrivObj^%SYS.SQLSEC($li(^rINDEXSQL("rv",{L2},{L3}),3)_","_$li(^rINDEXSQL("rv",{L2},{L3}),4))</Expression>
</Invalidcondition>
</Subscript>
<Subscript name="4">
<DataAccess>^oddDEF({3D1},"t")</DataAccess>
<Expression>{TriggerObjName}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^INFORMATION.SCHEMA.TABLESS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

