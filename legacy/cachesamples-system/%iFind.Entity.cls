/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IFInclude

/// <p>The InterSystems IRIS NLP iKnow technology on which this output type is based is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail. The <class>%iKnow.Index.Basic</class> and <class>%iKnow.Index.Minimal</class>
/// index types, which only generate word-level content, remain fully supported.</p>
/// This table contains all entities identified by iFind Semantic or Analytic indices in this namespace
/// using namespace-wide shared storage (cf the IFINDSHAREDSTORAGELOCATION parameter in
/// <class>%iFind.Index.Basic</class>).
Class %iFind.Entity Extends %Persistent [ Deprecated, Final, StorageStrategy = iFind, System = 4 ]
{

Parameter READONLY = 1;

///  String value for this entity 
Property Value As %String(COLLATION = "EXACT", MAXLEN = "");

Property EntityId As %Integer;

/// Calculated property returning the entity ID of the entity corresponding to this row, with all words
/// stripped of leading and trailing punctuation. If no such entity exists, this
/// record's entity ID is returned.
Property StrippedEntityId As %iFind.Entity [ Calculated, SqlComputeCode = { set {StrippedEntityId}=##class(%iFind.Entity).GetStrippedEntityId({Value},{ID})}, SqlComputed ];

Index EntityIdx On EntityId [ IdKey, PrimaryKey, Unique ];

Index ValueIdx On Value [ Type = key, Unique ];

///  Returns the Entity ID corresponding to the supplied string, after stripping off punctuation.
///  If no such entity exists, <var>pOriginalId</var> is returned.
ClassMethod GetStrippedEntityId(pEntity As %String, pOriginalId As %Integer = "", pKeepChars As %String = {$$$STRIPKEEP}) As %Integer [ SqlName = GetStrippedEntityId, SqlProc ]
{
  // first split into words
  s number=$length(pEntity," ")
  kill arrayWordsStripped
  set stripped=0
  for counter=1:1:number {
	  set word=$piece(pEntity," ",counter)
	  set wordstripped=$zstrip(word,"<>P",,pKeepChars)
	  if (wordstripped'=word) {
		  set stripped=1
	  }
	  set arrayWordsStripped(counter)=wordstripped
  }
  
   if (stripped=0) && pOriginalId {
	   quit pOriginalId
   }
   set eId=""
   
   // get all the wordid's
	set entkey=""
	for counter=1:1:number {
		set tWord=arrayWordsStripped(counter)
		continue:tWord=""
		if '$d(^IRIS.IF.WordI(" "_tWord),tWordId) {
			return pOriginalId
		}
		set:entkey'="" entkey=entkey_","
		set entkey=entkey_tWordId
	}
	quit $s(entkey="":pOriginalId, 1:$g(^IRIS.IF.EntityI(entkey),pOriginalId))
}

///  Returns the Entity ID corresponding to the supplied string 
ClassMethod GetEntityId(pValue As %String) As %Integer [ SqlName = GetEntityId, SqlProc ]
{
	quit $g(^IRIS.IF.EntityI(..GetWordKey(pValue)))
}

/// Returns the internal key of the supplied entity value, which is calculated by concatenating the
/// word IDs of all words in the entity value.
ClassMethod GetWordKey(pValue As %String) As %String [ Internal ]
{
	set tWordIds="", tPos=0
	while 1 {
		set tNewPos = $find(pValue," ",tPos)
		if (tNewPos) {
			set tWord = $e(pValue,tPos,tNewPos-2)
		} else {
			set tWord = $e(pValue,tPos,*)
		}
		if '$d(^IRIS.IF.WordI(" "_tWord), tWordId) {
			set tWordIds = $c(0) // BDB863
			quit
		}
		set tWordIds = tWordIds _ $s(tWordIds="":"", 1:",") _ tWordId
		
		quit:'tNewPos
		set tPos = tNewPos
	}
	quit tWordIds
}

Storage iFind
{
<IndexLocation>^IRIS.IF.EntityI</IndexLocation>
<SQLMap name="Data">
<Data name="Value">
<Delimiter>$c(0)</Delimiter>
<Piece>1</Piece>
</Data>
<Global>^IRIS.IF.EntityD</Global>
<RowIdSpec name="1">
<Expression>{S1}</Expression>
<Field>EntityId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>{EntityId}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<SQLMap name="ValueIdx">
<Data name="EntityId">
<Delimiter>$c(0)</Delimiter>
<Piece>1</Piece>
</Data>
<Global>^IRIS.IF.EntityI</Global>
<PopulationType>full</PopulationType>
<RowIdSpec name="1">
<Expression>{EntityId}</Expression>
<Field>EntityId</Field>
</RowIdSpec>
<Subscript name="1">
<Expression>##class(%iFind.Entity).GetWordKey({Value})</Expression>
</Subscript>
<Type>index</Type>
</SQLMap>
<StreamLocation>^IRIS.IF.EntityS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
