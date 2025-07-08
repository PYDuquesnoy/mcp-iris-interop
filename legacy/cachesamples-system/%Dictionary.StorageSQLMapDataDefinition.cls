/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.StorageSQLMapDataDefinition Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.StorageSQLMapDefinition [ Cardinality = parent, Inverse = Data ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Delimiter
Property Delimiter As %RawString;

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

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
 $$$defClassKeySet($p({parent},"||",1),$$$cCLASStimechanged,$zutil(188))
 do RebuildItemIndex^%R($p({parent},"||",1),"CLS")
}

Method %OnNew(name As %String) As %Status [ Private ]
{
 s i%%isDefined("Delimiter")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("Node")=0
 s i%%isDefined("Piece")=0
 s i%%isDefined("RetrievalCode")=0
 i $g(name)="" q $$$OK
 s i%parent=$$$NormalizeClassname($p(name,":",1))_"||"_$p(name,":",2)_"||"_$p(name,":",3)
 s i%Name=$p(name,":",4)
 q $$$OK
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
 i $$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||(name4="")||('$$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,3)
 . s i%Name=name4
 . s i%Delimiter=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter),i%%isDefined("Delimiter")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter)
 . s i%Node=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode),i%%isDefined("Node")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode)
 . s i%Piece=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece),i%%isDefined("Piece")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece)
 . s i%RetrievalCode=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode),i%%isDefined("RetrievalCode")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode)
exit i i%%Concurrency=2||(i%%Concurrency=1) d ..%UnlockId(id,1,1)
 q sc
trap s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g exit
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 $$$IsClassDefVersionMatched(ismatched) i ismatched=0 q $$$ERROR($$$ClassDictionaryVersionMismatch)
 s sc=$$$OK,id=$$$idCurrent i id'="" s insert=0,idassigned=1
 e  s insert=1,idassigned=0
 s lock=0
 i i%parent'="",'##class(%Dictionary.StorageSQLMapDefinition).%ExistsId(i%parent) q $$$ERROR($$$ReferencedObjectDoesNotExist,"ClassName")
 i 'insert DO
 . i $s(i%parent'=$p(id,"||",1,3):1,i%Name'=$p(id,"||",4):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 . i '($$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defStorageSubSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,"")
 . i 'i%%isDefined("Delimiter") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter,i%Delimiter) }
 . i 'i%%isDefined("Node") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode,i%Node) }
 . i 'i%%isDefined("Piece") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece,i%Piece) }
 . i 'i%%isDefined("RetrievalCode") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode,i%RetrievalCode) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,3):1,i%Name'=$p(id,"||",4):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.StorageSQLMapDataDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defStorageSubSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,"")
 . i i%Delimiter="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAdelimiter,i%Delimiter) }
 . i i%Node="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAnode,i%Node) }
 . i i%Piece="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATApiece,i%Piece) }
 . i i%RetrievalCode="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4,$$$cSDEFSQLMAPDATAretrievalcode,i%RetrievalCode) }
 . i i%%Concurrency=3 s sc=..%LockId(id,1)
 . s:i%%Concurrency=4 lock=0
 i $$$ISERR(sc) d:lock ..%UnlockId(id) QUIT sc
 d:lock ..%UnlockId(id)
 If $$$ISOK(sc) Set %objTX(9,"Do UpdClsDef^%occLibrary("""_name1_""")")=""
 QUIT sc
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
 Quit:id="" $$$ERROR($$$NullId)
 Set sc=$$$OK
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 If concurrency Set sc=..%LockId(id) If $$$ISERR(sc) Quit sc
 If '($$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defStorageSubSubMemberKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPdata,name4) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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
<RetrievalCode> s {Delimiter}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"T",{L7},21),$g(^%qObjectKey(1,"T",21)))
</RetrievalCode>
</Data>
<Data name="Node">
<RetrievalCode> s {Node}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"T",{L7},22),$g(^%qObjectKey(1,"T",22)))
</RetrievalCode>
</Data>
<Data name="Piece">
<RetrievalCode> s {Piece}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"T",{L7},23),$g(^%qObjectKey(1,"T",23)))
</RetrievalCode>
</Data>
<Data name="RetrievalCode">
<RetrievalCode> s {RetrievalCode}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"T",{L7},24),$g(^%qObjectKey(1,"T",24)))
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"s"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.StorageDefinition.Name}</Expression>
</Subscript>
<Subscript name="4">
<Expression>"S"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.StorageSQLMapDefinition.Name}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"T"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{%Dictionary.StorageSQLMapDataDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.StorageSQLM88B8S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
