/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each Integrated ML Validation Run that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.MLVALIDATIONRUNS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = ML_VALIDATION_RUNS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On ID [ IdKey, Internal, Unique ];

/// ID of the Validation Run
Property ID As %BigInt [ Internal, Private, Required, SqlColumnNumber = 2, SqlFieldName = ID ];

/// Name of the model that was Validated
Property MODELNAME As %String(MAXLEN = 256) [ Required, SqlColumnNumber = 3, SqlFieldName = MODEL_NAME ];

/// Name of the Trained Model that was Validated
Property TRAINEDMODELNAME As %String(MAXLEN = 256) [ Required, SqlColumnNumber = 4, SqlFieldName = TRAINED_MODEL_NAME ];

/// Name of the Validation Run
Property VALIDATIONRUNNAME As %String(MAXLEN = 256) [ SqlColumnNumber = 5, SqlFieldName = VALIDATION_RUN_NAME ];

/// Timestamp for when the Validation Run began (UTC)
Property STARTTIMESTAMP As %TimeStamp [ Required, SqlColumnNumber = 6, SqlFieldName = START_TIMESTAMP ];

/// Timestamp for when the Validation Run completed (UTC)
Property COMPLETEDTIMESTAMP As %TimeStamp [ Required, SqlColumnNumber = 7, SqlFieldName = COMPLETED_TIMESTAMP ];

/// Validation duration (in seconds)
Property VALIDATIONDURATION As %Numeric [ SqlColumnNumber = 8, SqlComputeCode = { Set {*}=##class(%ML.TrainingRun).GetInterval({START_TIMESTAMP},{COMPLETED_TIMESTAMP}) }, SqlComputed, SqlFieldName = VALIDATION_DURATION, Transient ];

/// Validation status
Property RUNSTATUS As %String(DISPLAYLIST = ",Training,Completed,Failed", VALUELIST = ",training,completed,failed") [ SqlColumnNumber = 9, SqlFieldName = RUN_STATUS ];

/// Validation error (if encountered)
Property STATUSCODE As %Status [ SqlColumnNumber = 10, SqlFieldName = STATUS_CODE ];

/// Validation log output
Property LOG As %Stream.GlobalCharacter [ SqlColumnNumber = 11, SqlFieldName = LOG ];

/// Validation Run Settings
Property SETTINGS As %String(MAXLEN = "") [ SqlColumnNumber = 13, SqlComputeCode = { Set {*}=##class(INFORMATION.SCHEMA.MLVALIDATIONRUNS).GetSettings({ID}) }, SqlComputed, SqlFieldName = SETTINGS, Transient ];

/// Validation Run query (SQL)
Property VALIDATIONRUNQUERY As %String(MAXLEN = 32000) [ SqlColumnNumber = 14, SqlFieldName = VALIDATION_RUN_QUERY ];

/// Given a ML_VALIDATION_RUN ID, get the display string for the %ML.ValidationRun.Settings
ClassMethod GetSettings(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

/// Given a Validation Run ID, return the Model Name
ClassMethod GetModelName(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

/// Given a Validation Run ID, returned the trained model name
ClassMethod GetTrainedModelName(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="COMPLETED_TIMESTAMP">
<Piece>5</Piece>
</Data>
<Data name="LOG">
<Piece>9</Piece>
</Data>
<Data name="MODEL_NAME">
<RetrievalCode> set {*}=##class({%%CLASSNAME}).GetModelName({L1})</RetrievalCode>
</Data>
<Data name="RUN_STATUS">
<Piece>7</Piece>
</Data>
<Data name="START_TIMESTAMP">
<Piece>4</Piece>
</Data>
<Data name="STATUS_CODE">
<Piece>8</Piece>
</Data>
<Data name="TRAINED_MODEL_NAME">
<RetrievalCode> set {*}=##class({%%CLASSNAME}).GetTrainedModelName({L1})</RetrievalCode>
</Data>
<Data name="VALIDATION_RUN_NAME">
<Piece>3</Piece>
</Data>
<Data name="VALIDATION_RUN_QUERY">
<Piece>6</Piece>
</Data>
<Global>^IRIS.ML.ValidationRunD</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{ID}</Expression>
<Invalidcondition name="1">
<Expression>'$$SQLStatementPrivCheck^%SYS.SQLSEC($lg($g(^IRIS.ML.ValidationRunD({L1})),6))</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="NameIndex">
<Global>^IRIS.ML.ValidationRunI</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"NameIndex"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$SQLUPPER({VALIDATION_RUN_NAME})</Expression>
</Subscript>
<Subscript name="3">
<Expression>{ID}</Expression>
<Invalidcondition name="1">
<Expression>'$$SQLStatementPrivCheck^%SYS.SQLSEC($lg($g(^IRIS.ML.ValidationRunD({L3})),6))</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.ML.ValidationRunS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

