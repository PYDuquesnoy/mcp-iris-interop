/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.StorageShardKeyDefinition Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.StorageDefinition [ Cardinality = parent, Inverse = ShardKeies ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies the class with which to coshard this class
Property CoshardWith As %RawString;

/// Specifies the name of the shard key
Property Name As %RawString [ Required ];

/// Specifies the properties of the shard key
Property Properties As %RawString;

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
 s i%%isDefined("CoshardWith")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("Properties")=0
 i $g(name)="" q $$$OK
 s i%parent=$$$NormalizeClassname($p(name,":",1))_"||"_$p(name,":",2)
 s i%Name=$p(name,":",3)
 q $$$OK
}

ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 i (name1="")||(name2="")||(name3="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||(name3="")||('$$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%CoshardWith=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith),i%%isDefined("CoshardWith")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith)
 . s i%Properties=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties),i%%isDefined("Properties")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties)
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
 i i%parent'="",'##class(%Dictionary.StorageDefinition).%ExistsId(i%parent) q $$$ERROR($$$ReferencedObjectDoesNotExist,"ClassName")
 i 'insert DO
 . i $s(i%parent'=$p(id,"||",1,2):1,i%Name'=$p(id,"||",3):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 . i '($$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defStorageSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,"")
 . i 'i%%isDefined("CoshardWith") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith,i%CoshardWith) }
 . i 'i%%isDefined("Properties") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties,i%Properties) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,2):1,i%Name'=$p(id,"||",3):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.StorageShardKeyDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defStorageSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,"")
 . i i%CoshardWith="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith,i%CoshardWith) }
 . i i%Properties="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties,i%Properties) }
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
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 If concurrency Set sc=..%LockId(id) If $$$ISERR(sc) Quit sc
 If '($$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defStorageSubMemberKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
}

Method CoshardWithSet(value As %String = "") As %Status
{
 set i%CoshardWith=value,i%%isDefined("CoshardWith")=1 quit $$$OK
}

Method CoshardWithReset()
{
 set i%CoshardWith="" set i%%isDefined("CoshardWith")=0 quit
}

Method CoshardWithIsDefined() As %Boolean
{
 quit ''i%%isDefined("CoshardWith")
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

Method PropertiesSet(value As %String = "") As %Status
{
 set i%Properties=value,i%%isDefined("Properties")=1 quit $$$OK
}

Method PropertiesReset()
{
 set i%Properties="" set i%%isDefined("Properties")=0 quit
}

Method PropertiesIsDefined() As %Boolean
{
 quit ''i%%isDefined("Properties")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="CoshardWith">
<RetrievalCode> s {CoshardWith}=$g(^oddDEF({L1},"s",{L3},"K",{L5},43),$g(^%qObjectKey(1,"K",43)))
</RetrievalCode>
</Data>
<Data name="Properties">
<RetrievalCode> s {Properties}=$g(^oddDEF({L1},"s",{L3},"K",{L5},42),$g(^%qObjectKey(1,"K",42)))
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
<Expression>"K"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.StorageShardKeyDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.StorageShar31C1S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
