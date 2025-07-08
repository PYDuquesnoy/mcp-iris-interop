/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageSQLMapData Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorageSQLMap [ Cardinality = parent, Inverse = Data ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Delimiter
Property Delimiter As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Name
Property Name As %RawString [ Required ];

/// Node
Property Node As %RawString;

/// Piece
Property Piece As %RawString;

/// RetrievalCode
Property RetrievalCode As %RawString;

Index IDKEY On Name [ IdKey ];

Parameter SQLENABLED = 1;

Trigger OnInsertUpdate [ Event = INSERT/UPDATE ]
{
 set %ok=0
 set %msg="Insert/Update operations not supported on this table."
}

Trigger OnDelete [ Event = DELETE ]
{
 set %ok=0
 set %msg="Delete operation not supported on this table."
}

Method %OnNew(name As %String) As %Status [ Private ]
{
 q $$$ERROR($$$CanNotNewCompiledDictionaryClasses)
}

ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 i (name1="")||(name2="")||(name3="")||(name4="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$comStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||(name3="")||(name4="")||('$$$comStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,3)
 . s i%Name=name4
 . s i%Delimiter=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter),i%%isDefined("Delimiter")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter)
 . s i%KeywordError=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAkeyworderror)
 . s i%KeywordModified=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAkeywordmodified)
 . s i%Node=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode),i%%isDefined("Node")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode)
 . s i%Piece=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece),i%%isDefined("Piece")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece)
 . s i%RetrievalCode=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode),i%%isDefined("RetrievalCode")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode)
exit i i%%Concurrency=2||(i%%Concurrency=1) d ..%UnlockId(id,1,1)
 q sc
trap s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g exit
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 q $$$ERROR($$$CanNotSaveCompiledDictionaryClasses)
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
	Quit $$$ERROR($$$CanNotDeleteCompiledDictionaryClasses)
}

Method DelimiterSet(value As %String = "") As %Status
{
 set i%Delimiter=value,i%%isDefined("Delimiter")=1 quit $$$OK
}

Method DelimiterReset()
{
 set i%Delimiter="" set i%%isDefined("Delimiter")=0 quit
}

Method DelimiterIsDefined() As %Boolean
{
 quit ''i%%isDefined("Delimiter")
}

Method NameSet(value As %String = "") As %Status
{
 set i%Name=value,i%%isDefined("Name")=1 quit $$$OK
}

Method NameReset()
{
 set i%Name="" set i%%isDefined("Name")=0 quit
}

Method NameIsDefined() As %Boolean
{
 quit ''i%%isDefined("Name")
}

Method NodeSet(value As %String = "") As %Status
{
 set i%Node=value,i%%isDefined("Node")=1 quit $$$OK
}

Method NodeReset()
{
 set i%Node="" set i%%isDefined("Node")=0 quit
}

Method NodeIsDefined() As %Boolean
{
 quit ''i%%isDefined("Node")
}

Method PieceSet(value As %String = "") As %Status
{
 set i%Piece=value,i%%isDefined("Piece")=1 quit $$$OK
}

Method PieceReset()
{
 set i%Piece="" set i%%isDefined("Piece")=0 quit
}

Method PieceIsDefined() As %Boolean
{
 quit ''i%%isDefined("Piece")
}

Method RetrievalCodeSet(value As %String = "") As %Status
{
 set i%RetrievalCode=value,i%%isDefined("RetrievalCode")=1 quit $$$OK
}

Method RetrievalCodeReset()
{
 set i%RetrievalCode="" set i%%isDefined("RetrievalCode")=0 quit
}

Method RetrievalCodeIsDefined() As %Boolean
{
 quit ''i%%isDefined("RetrievalCode")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Delimiter">
<RetrievalCode> s {Delimiter}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"T",{L7},21),$g(^%qObjectKey(1,"T",21)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"T",{L7},12),$g(^%qObjectKey(1,"T",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"T",{L7},13),$g(^%qObjectKey(1,"T",13)))
</RetrievalCode>
</Data>
<Data name="Node">
<RetrievalCode> s {Node}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"T",{L7},22),$g(^%qObjectKey(1,"T",22)))
</RetrievalCode>
</Data>
<Data name="Piece">
<RetrievalCode> s {Piece}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"T",{L7},23),$g(^%qObjectKey(1,"T",23)))
</RetrievalCode>
</Data>
<Data name="RetrievalCode">
<RetrievalCode> s {RetrievalCode}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"T",{L7},24),$g(^%qObjectKey(1,"T",24)))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"s"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledStorage.Name}</Expression>
</Subscript>
<Subscript name="4">
<Expression>"S"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledStorageSQLMap.Name}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"T"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{%Dictionary.CompiledStorageSQLMapData.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledSto6C88S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
