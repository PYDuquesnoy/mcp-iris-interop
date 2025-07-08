/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IFInclude

/// This table contains all words identified by iFind indices in this namespace using namespace-wide
/// shared storage (cf the IFINDSHAREDSTORAGELOCATION parameter in <class>%iFind.Index.Basic</class>).
/// Note that this may also include transformed words. To only find original words wrt a specific 
/// transformation, use <class>%iFind.OriginalWord</class>.
Class %iFind.Word Extends %Persistent [ Final, StorageStrategy = iFind, System = 4 ]
{

Parameter READONLY = 1;

///  String value of this word 
Property Value As %String(COLLATION = "SQLSTRING", MAXLEN = "");

///  Internal identifier of this word 
Property Key As %Integer;

Index KeyIdx On Key [ IdKey, Unique ];

Index ValueIdx On Value [ Type = collatedkey, Unique ];

///  Calculated property returning the word object equivalent to this object, with all punctuation stripped off. 
Property StrippedWordId As %iFind.Word [ Calculated, SqlComputeCode = { set {StrippedWordId}=##class(%iFind.Word).GetStrippedWordId({Value})}, SqlComputed ];

///  Returns the word ID for the supplied string, stripped of all punctuation. 
ClassMethod GetStrippedWordId(pString As %String, pKeepChars As %String = {$$$STRIPKEEP}) As %Integer
{
   set tWord = $zstrip(pString,"<>P",,pKeepChars)
   quit $s(tWord="":"", 1:$g(^IRIS.IF.WordI(" "_tWord)))
}

Storage iFind
{
<Data name="WordDefaultData">
<Attribute>Value</Attribute>
<Structure>node</Structure>
<Value name="1">
<Value>Value</Value>
</Value>
</Data>
<DataLocation>^IRIS.IF.WordD</DataLocation>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.IF.WordD</IdLocation>
<Index name="ValueIdx">
<Location>^IRIS.IF.WordI</Location>
</Index>
<IndexLocation>^IRIS.IF.WordIDX</IndexLocation>
<SQLMap name="Map1">
<Data name="Value">
<Delimiter>$c(0)</Delimiter>
<Piece>1</Piece>
</Data>
<Global>^IRIS.IF.WordD</Global>
<RowIdSpec name="1">
<Expression>{L1}</Expression>
<Field>Key</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{Key}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="Map2">
<Data name="Key">
<Delimiter>$c(0)</Delimiter>
<Piece>1</Piece>
</Data>
<Global>^IRIS.IF.WordI</Global>
<RowIdSpec name="1">
<Expression>$g(^IRIS.IF.WordI({L1}))</Expression>
<Field>Key</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>" "_{Value}</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IF.WordS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
