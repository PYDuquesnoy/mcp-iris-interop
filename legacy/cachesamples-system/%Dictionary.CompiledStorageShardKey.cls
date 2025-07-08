/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageShardKey Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorage [ Cardinality = parent, Inverse = ShardKeies ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies the class with which to coshard this class
Property CoshardWith As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

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
 i $$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||('$$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%CoshardWith=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith),i%%isDefined("CoshardWith")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYcoshardwith)
 . s i%KeywordError=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYkeyworderror)
 . s i%KeywordModified=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYkeywordmodified)
 . s i%Properties=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties),i%%isDefined("Properties")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardkey,name3,$$$cSTORAGESHARDKEYproperties)
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
<RetrievalCode> s {CoshardWith}=$g(^oddCOM({L1},"s",{L3},"K",{L5},43),$g(^%qObjectKey(1,"K",43)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"K",{L5},12),$g(^%qObjectKey(1,"K",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"K",{L5},13),$g(^%qObjectKey(1,"K",13)))
</RetrievalCode>
</Data>
<Data name="Properties">
<RetrievalCode> s {Properties}=$g(^oddCOM({L1},"s",{L3},"K",{L5},42),$g(^%qObjectKey(1,"K",42)))
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
<Expression>"K"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledStorageShardKey.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStoD046S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
