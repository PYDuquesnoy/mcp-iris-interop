/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>Note: the use of this class is no longer recommended for accessing elements of a specific domain.
/// For those scenarios, <class>%iKnow.Tables.Utils</class> offers a more flexible and customizable
/// way of projecting iKnow domain data to SQL</p>
///  <p>This is a read-only object representation wrapping the internal iKnow data structures for 
///  unique Entities.</p>
///  <p>This class can be used from ObjectScript or SQL to access a single or small number of
///  entries, but the storage mappings are not meant to support elaborate or complex queries
///  targeting this SQL table.</p>
///  <p>Please use the predefined queries in <class>%iKnow.Queries.EntityAPI</class> and other query classes
///  to consult Entity data as the internal global structures are designed to optimize performance for
///  these queries rather than general-purpose access.</p>
///  <p>Note: the <index>EntUni</index> index only works for entities up to 150 characters.</p>
///  <p>NOTE: This object assumes all underlying data structures are present. Use domain-specific
///  copies of these objects for domains where not all indices are built. See also the 
///  GenerateAllObjectsForDomain() method in <class>%iKnow.Objects.Utils</class>.</p>
Class %iKnow.Objects.EntityUnique Extends %Persistent [ Deprecated, StorageStrategy = iKnowStorage, System = 4 ]
{

Parameter READONLY = 1;

Property DomainId As %Integer;

Property EntUniId As %Integer;

Property EntityValue As %String(MAXLEN = 2000);

Property CorpusFrequency As %Integer [ Calculated, SqlComputeCode = {set {CorpusFrequency} = {CorpusFrequencyAsConcept} + {CorpusFrequencyAsRelation}}, SqlComputed ];

Property CorpusFrequencyAsConcept As %Integer [ Calculated, SqlComputeCode = {set {CorpusFrequencyAsConcept} = +$lg($g(^IRIS.IK.EntUniDetails({DomainId},{EntUniId})),1) }, SqlComputed ];

Property CorpusFrequencyAsRelation As %Integer [ Calculated, SqlComputeCode = {set {CorpusFrequencyAsRelation} = +$lg($g(^IRIS.IK.EntUniDetails({DomainId},{EntUniId})),2) }, SqlComputed ];

Property CorpusSpread As %Integer [ Calculated, SqlComputeCode = {set {CorpusSpread} = +$lg($g(^IRIS.IK.EntUniDetails({DomainId},{EntUniId})),3) }, SqlComputed ];

Property CorpusSpreadAsConcept As %Integer [ Calculated, SqlComputeCode = {set {CorpusSpreadAsConcept} = +$lg($g(^IRIS.IK.EntUniDetails({DomainId},{EntUniId})),4) }, SqlComputed ];

Property CorpusSpreadAsRelation As %Integer [ Calculated, SqlComputeCode = {set {CorpusSpreadAsRelation} = +$lg($g(^IRIS.IK.EntUniDetails({DomainId},{EntUniId})),5) }, SqlComputed ];

Property CorpusDominanceAsConcept As %Numeric [ Calculated, SqlComputeCode = {set {CorpusDominanceAsConcept} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue({DomainId},{EntUniId},$$$SDCONCEPT) }, SqlComputed ];

Property CorpusDominanceAsRelation As %Numeric [ Calculated, SqlComputeCode = {set {CorpusDominanceAsRelation} = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue({DomainId},{EntUniId},$$$SDRELATION) }, SqlComputed ];

Index PKINDEX On (DomainId, EntUniId) [ IdKey, PrimaryKey, Unique ];

Index EntUniFreqCon On (DomainId, CorpusFrequencyAsConcept);

Index EntUniFreqRel On (DomainId, CorpusFrequencyAsRelation);

Index EntUniSpreadCon On (DomainId, CorpusSpreadAsConcept);

Index EntUniSpreadRel On (DomainId, CorpusSpreadAsRelation);

/// This Index only works for strings of up to 150 ($$$IKHASHIZE) characters
Index EntUni On (DomainId, EntityValue) [ Unique ];

Storage iKnowStorage
{
<ExtentSize>100000</ExtentSize>
<SQLMap name="EntUni">
<Data name="EntUniId"/>
<Global>^IRIS.IK.EntUni</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{EntUniId}</Expression>
<Field>EntUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>" "_{EntityValue}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="EntUniFreqCon">
<Condition>
<![CDATA[{CorpusFrequencyAsConcept}>0]]></Condition>
<Global>^IRIS.IK.EntUniIdFreq</Global>
<PopulationType>conditional</PopulationType>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S4}</Expression>
<Field>EntUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>0</Expression>
</Subscript>
<Subscript name="3">
<Expression>-{CorpusFrequencyAsConcept}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{EntUniId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="EntUniFreqRel">
<Condition>
<![CDATA[{CorpusFrequencyAsRelation}>0]]></Condition>
<Global>^IRIS.IK.EntUniIdFreq</Global>
<PopulationType>conditional</PopulationType>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S4}</Expression>
<Field>EntUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>1</Expression>
</Subscript>
<Subscript name="3">
<Expression>-{CorpusFrequencyAsRelation}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{EntUniId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="EntUniSpreadCon">
<Condition>
<![CDATA[{CorpusSpreadAsConcept}>0]]></Condition>
<Global>^IRIS.IK.EntUniIdSpread</Global>
<PopulationType>conditional</PopulationType>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S4}</Expression>
<Field>EntUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>0</Expression>
</Subscript>
<Subscript name="3">
<Expression>-{CorpusSpreadAsConcept}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{EntUniId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="EntUniSpreadRel">
<Condition>
<![CDATA[{CorpusSpreadAsRelation}>0]]></Condition>
<Global>^IRIS.IK.EntUniIdSpread</Global>
<PopulationType>conditional</PopulationType>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>DomainId</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{S4}</Expression>
<Field>EntUniId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>1</Expression>
</Subscript>
<Subscript name="3">
<Expression>-{CorpusSpreadAsRelation}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{EntUniId}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<SQLMap name="MainMap">
<Data name="EntityValue"/>
<Global>^IRIS.IK.EntUniId</Global>
<Subscript name="1">
<Expression>{DomainId}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{EntUniId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IK.Objects.EntUniqueS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
