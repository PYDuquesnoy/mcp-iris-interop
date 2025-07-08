/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each Integrated ML Validation Metric that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.MLVALIDATIONMETRICS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = ML_VALIDATION_METRICS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On ID [ IdKey, Internal, Unique ];

/// ID of the Validation Run
Property ID As %BigInt [ Internal, Private, Required, SqlColumnNumber = 2, SqlFieldName = ID ];

/// Model Name
Property MODELNAME As %String(MAXLEN = 256) [ SqlColumnNumber = 3, SqlComputeCode = { set {*}=##class(INFORMATION.SCHEMA.MLVALIDATIONMETRICS).GetModelName({VALIDATION_RUN_ID}) }, SqlComputed, SqlComputeOnChange = VALIDATIONRUNID, SqlFieldName = MODEL_NAME, Transient ];

/// Name of the Trained Model for this Validation Run
Property TRAINEDMODELNAME As %String(MAXLEN = 256) [ SqlColumnNumber = 4, SqlComputeCode = { set {*}=##class(INFORMATION.SCHEMA.MLVALIDATIONMETRICS).GetTrainedModelName({VALIDATION_RUN_ID}) }, SqlComputed, SqlComputeOnChange = VALIDATIONRUNID, SqlFieldName = TRAINED_MODEL_NAME, Transient ];

/// ID of the Validation Run
Property VALIDATIONRUNID As %BigInt [ Internal, Private, SqlColumnNumber = 5, SqlFieldName = VALIDATION_RUN_ID ];

/// Name of the Validation Run
Property VALIDATIONRUNNAME As %String(MAXLEN = 256) [ SqlColumnNumber = 6, SqlComputeCode = { set {*}=$lg($g(^IRIS.ML.ValidationRunD({VALIDATION_RUN_ID}),$lb(,,"UNKNOWN>")),3) }, SqlComputed, SqlComputeOnChange = VALIDATIONRUNID, SqlFieldName = VALIDATION_RUN_NAME, Transient ];

/// Validation Metric Name
Property METRICNAME As %String(MAXLEN = 200) [ SqlColumnNumber = 7, SqlFieldName = METRIC_NAME ];

/// Validation Metric Value
Property METRICVALUE As %Numeric [ SqlColumnNumber = 8, SqlFieldName = METRIC_VALUE ];

/// Validation Target Value
Property TARGETVALUE As %String(MAXLEN = 2000) [ SqlColumnNumber = 9, SqlFieldName = TARGET_VALUE ];

/// Given the %ML.ValidationRun ID, return the Trained Model Name
ClassMethod GetTrainedModelName(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

/// Given the %ML.ValidationRun ID, return the model name
ClassMethod GetModelName(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

/// Given the Validation Metric ID, is the user privileged to see this Validation Metrics info?
/// We make sure the user is privileged on the Validation Run query
ClassMethod IsPrivileged(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="METRIC_NAME">
<Piece>3</Piece>
</Data>
<Data name="METRIC_VALUE">
<Piece>4</Piece>
</Data>
<Data name="TARGET_VALUE">
<Piece>5</Piece>
</Data>
<Data name="VALIDATION_RUN_ID">
<Piece>2</Piece>
</Data>
<Global>^IRIS.ML.ValidationMetricD</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{ID}</Expression>
<Invalidcondition name="1">
<Expression>'##class(INFORMATION.SCHEMA.MLVALIDATIONMETRICS).IsPrivileged({L1})</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.ML.ValidationMetricS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

