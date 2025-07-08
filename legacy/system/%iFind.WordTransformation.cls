/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This table projects all registered word transformations filed by iFind indices with namespace-shared
/// storage. (cf IFINDSHAREDSTORAGELOCATION parameter in <class>%iFind.Index.Basic</class>)
Class %iFind.WordTransformation Extends %Persistent [ Final, StorageStrategy = iFindStorage, System = 4 ]
{

Parameter READONLY = 1;

/// The original word, as it appeared in the text
Property OriginalWord As %iFind.Word;

/// The transformed word string, after applying <property>Transformation</property>
Property TransformedWord As %iFind.Word;

/// The transformation object translating <property>OriginalWord</property> into <property>TransformedWord</property>
Property Transformation As %iFind.Transformation;

Index IDKey On (Transformation, TransformedWord, OriginalWord) [ IdKey, PrimaryKey, Unique ];

Storage iFindStorage
{
<SQLMap name="Data">
<Global>^IRIS.IF.TransfoW</Global>
<Subscript name="1">
<Expression>{Transformation}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{TransformedWord}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{OriginalWord}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%iFind.WordTransformationS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
