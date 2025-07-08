/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageIndex Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorage [ Cardinality = parent, Inverse = Indices ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Location
Property Location As %RawString;

/// Name
Property Name As %RawString [ Required ];

/// SmallChunkSize
Property SmallChunkSize As %Integer;

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
 i $$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||('$$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%KeywordError=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXkeyworderror)
 . s i%KeywordModified=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXkeywordmodified)
 . s i%Location=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXlocation),i%%isDefined("Location")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXlocation)
 . s i%SmallChunkSize=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXsmallchunksize),i%%isDefined("SmallChunkSize")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindex,name3,$$$cSDEFIDXsmallchunksize)
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

Method LocationSet(value As %String = "") As %Status
{
 set i%Location=value,i%%isDefined("Location")=1 quit $$$OK
}

Method LocationReset()
{
 set i%Location="" set i%%isDefined("Location")=0 quit
}

Method LocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("Location")
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

Method SmallChunkSizeSet(value As %String = "") As %Status
{
 set i%SmallChunkSize=value,i%%isDefined("SmallChunkSize")=1 quit $$$OK
}

Method SmallChunkSizeReset()
{
 set i%SmallChunkSize=0 set i%%isDefined("SmallChunkSize")=0 quit
}

Method SmallChunkSizeIsDefined() As %Boolean
{
 quit ''i%%isDefined("SmallChunkSize")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"X",{L5},12),$g(^%qObjectKey(1,"X",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"X",{L5},13),$g(^%qObjectKey(1,"X",13)))
</RetrievalCode>
</Data>
<Data name="Location">
<RetrievalCode> s {Location}=$g(^oddCOM({L1},"s",{L3},"X",{L5},21),$g(^%qObjectKey(1,"X",21)))
</RetrievalCode>
</Data>
<Data name="SmallChunkSize">
<RetrievalCode> s {SmallChunkSize}=$g(^oddCOM({L1},"s",{L3},"X",{L5},22),$g(^%qObjectKey(1,"X",22)))
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
<Expression>"X"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledStorageIndex.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStoDC05S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
