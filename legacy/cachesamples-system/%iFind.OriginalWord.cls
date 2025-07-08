/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This table maps all original words appearing in text indexed by an iFind index using namespace-wide
/// shared storage (cf the IFINDSHAREDSTORAGELOCATION parameter in <class>%iFind.Index.Basic</class>).
Class %iFind.OriginalWord Extends %Persistent [ StorageStrategy = iFindStorage, System = 4 ]
{

Parameter READONLY = 1;

/// The original word form.
Property OriginalWord As %iFind.Word;

Index IDKey On OriginalWord [ IdKey, PrimaryKey, Unique ];

Storage iFindStorage
{
<SQLMap name="Data">
<Global>^IRIS.IF.TransfoB</Global>
<Subscript name="1">
<Expression>0</Expression>
</Subscript>
<Subscript name="2">
<Accessvar name="2">
<Code>s {2D2}=({L2}-1)*64000-1</Code>
<Variable>2D2</Variable>
</Accessvar>
<Expression>{OriginalWord}\64000+1</Expression>
</Subscript>
<Subscript name="3">
<AccessType>Other</AccessType>
<Expression>{OriginalWord}</Expression>
<Invalidcondition name="1">
<Expression>'$bit({3D},{L3}-{2D2})</Expression>
</Invalidcondition>
<NextCode>
<![CDATA[ i '({2D2}+64000]]]]><![CDATA[{L3}) s {L3}="" QUIT  
 n pos s pos={L3}-{2D2} 
 s:pos<0 pos=0  
 s pos=$bitfind({3D},1,pos+1) 
 i 'pos s {L3}="" QUIT 
 s {L3}={2D2}+pos  
 goto NEXT:{L3}=0  
 q]]></NextCode>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^IRIS.IF.Transfos</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
