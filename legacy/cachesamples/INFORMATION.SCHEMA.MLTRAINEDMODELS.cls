/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Returns one row for each Integrated ML Trained Model that can be accessed by the current user in the current namespace.
Class INFORMATION.SCHEMA.MLTRAINEDMODELS Extends %Library.Persistent [ ClassType = persistent, Final, Owner = {_PUBLIC}, SqlRowIdPrivate, SqlTableName = ML_TRAINED_MODELS, StorageStrategy = SQLStorage, System = 4 ]
{

Parameter READONLY = 1;

Index IDKeyIndex On ID [ IdKey, Internal, Unique ];

/// ID of the Training Run
Property ID As %BigInt [ Internal, Private, Required, SqlColumnNumber = 2, SqlFieldName = ID ];

/// Name of the model that was trained
Property MODELNAME As %String(MAXLEN = 256) [ Required, SqlColumnNumber = 3, SqlFieldName = MODEL_NAME ];

/// Name of the Trained Model, same as the name for the corresponding Training Run
Property TRAINEDMODELNAME As %String(MAXLEN = 256) [ SqlColumnNumber = 4, SqlFieldName = TRAINED_MODEL_NAME ];

/// Provider used with Training Run
Property PROVIDER As %String(MAXLEN = 128) [ SqlColumnNumber = 5, SqlFieldName = PROVIDER ];

/// Timestamp for when the Trained Model was created (UTC)
Property TRAINEDTIMESTAMP As %TimeStamp [ Required, SqlColumnNumber = 6, SqlFieldName = TRAINED_TIMESTAMP ];

/// Type of the Trained Model
Property MODELTYPE As %String(DISPLAYLIST = ",Classification,Regression") [ SqlColumnNumber = 7, SqlFieldName = MODEL_TYPE ];

/// Model information
Property MODELINFO As %String(MAXLEN = "") [ SqlColumnNumber = 8, SqlFieldName = MODEL_INFO ];

ClassMethod GetModelInfo(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

/// Given the Trained Model ID, return the Model Name
ClassMethod GetModelName(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

/// Given the Trained Model ID, is the user privileged to see this Trained Model info?
/// We make sure the user is privileged on the Training Run query
ClassMethod IsPrivileged(id As %BigInt) As %String [ Final, Internal, Language = objectscript ]
{
}

Storage SQLStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="Master">
<Data name="MODEL_INFO">
<RetrievalCode> set {*}=##class(INFORMATION.SCHEMA.MLTRAINEDMODELS).GetModelInfo({L1})</RetrievalCode>
</Data>
<Data name="MODEL_NAME">
<RetrievalCode> set {*}=##class(INFORMATION.SCHEMA.MLTRAINEDMODELS).GetModelName({L1})</RetrievalCode>
</Data>
<Data name="MODEL_TYPE">
<Piece>7</Piece>
</Data>
<Data name="PROVIDER">
<RetrievalCode> set {*}=$p($lg(^IRIS.ML.TrainedModelD({L1}),3),".",2)</RetrievalCode>
</Data>
<Data name="TRAINED_MODEL_NAME">
<Piece>6</Piece>
</Data>
<Data name="TRAINED_TIMESTAMP">
<Piece>5</Piece>
</Data>
<Global>^IRIS.ML.TrainedModelD</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>{ID}</Expression>
<Invalidcondition name="1">
<Expression>'##class(INFORMATION.SCHEMA.MLTRAINEDMODELS).IsPrivileged({L1})</Expression>
</Invalidcondition>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="NameIndex">
<Global>^IRIS.ML.TrainedModelI</Global>
<PopulationType>full</PopulationType>
<Subscript name="1">
<Expression>"NameIndex"</Expression>
</Subscript>
<Subscript name="2">
<Expression>$$SQLUPPER({TRAINED_MODEL_NAME})</Expression>
</Subscript>
<Subscript name="3">
<Expression>{ID}</Expression>
<Invalidcondition name="1">
<Expression>'##class(INFORMATION.SCHEMA.MLTRAINEDMODELS).IsPrivileged({L3})</Expression>
</Invalidcondition>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.ML.TrainedModelS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}

