/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageDataValue Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorageData [ Cardinality = parent, Inverse = Values ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// ConversionCleanup
Property ConversionCleanup As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Specifies the name of the StorageDataValue. This name must be a valid storage member name and must not conflict with any other StorageDataValue names.
Property Name As %Integer [ Required ];

/// Value
Property Value As %RawString;

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
 i $$$comStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||(name4="")||('$$$comStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,3)
 . s i%Name=name4
 . s i%ConversionCleanup=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALconversioncleanup),i%%isDefined("ConversionCleanup")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALconversioncleanup)
 . s i%KeywordError=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALkeyworderror)
 . s i%KeywordModified=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALkeywordmodified)
 . s i%Value=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALvalue),i%%isDefined("Value")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAvalue,name4,$$$cSDEFDATAVALvalue)
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

Method ConversionCleanupSet(value As %String = "") As %Status
{
 set i%ConversionCleanup=value,i%%isDefined("ConversionCleanup")=1 quit $$$OK
}

Method ConversionCleanupReset()
{
 set i%ConversionCleanup="" set i%%isDefined("ConversionCleanup")=0 quit
}

Method ConversionCleanupIsDefined() As %Boolean
{
 quit ''i%%isDefined("ConversionCleanup")
}

Method NameSet(value As %String = "") As %Status
{
 set i%Name=value,i%%isDefined("Name")=1 quit $$$OK
}

Method NameReset()
{
 set i%Name=0 set i%%isDefined("Name")=0 quit
}

Method NameIsDefined() As %Boolean
{
 quit ''i%%isDefined("Name")
}

Method ValueSet(value As %String = "") As %Status
{
 set i%Value=value,i%%isDefined("Value")=1 quit $$$OK
}

Method ValueReset()
{
 set i%Value="" set i%%isDefined("Value")=0 quit
}

Method ValueIsDefined() As %Boolean
{
 quit ''i%%isDefined("Value")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="ConversionCleanup">
<RetrievalCode> s {ConversionCleanup}=$g(^oddCOM({L1},"s",{L3},"D",{L5},"V",{L7},22),$g(^%qObjectKey(1,"V",22)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"D",{L5},"V",{L7},12),$g(^%qObjectKey(1,"V",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"D",{L5},"V",{L7},13),$g(^%qObjectKey(1,"V",13)))
</RetrievalCode>
</Data>
<Data name="Value">
<RetrievalCode> s {Value}=$g(^oddCOM({L1},"s",{L3},"D",{L5},"V",{L7},21),$g(^%qObjectKey(1,"V",21)))
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
<Expression>"D"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledStorageData.Name}</Expression>
</Subscript>
<Subscript name="6">
<Expression>"V"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{%Dictionary.CompiledStorageDataValue.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStoFF18S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
