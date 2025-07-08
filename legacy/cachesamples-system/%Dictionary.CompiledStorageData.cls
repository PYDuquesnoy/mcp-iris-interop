/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageData Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorage [ Cardinality = parent, Inverse = Data ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Attribute
Property Attribute As %RawString;

/// Specifies the name of the global this Columnar column is stored in.
Property ColumnarGlobal As %RawString;

/// For columnar maps, specifies that this map is the target of a storage type conversion
Property ConversionTarget As %RawString;

/// Specifies the name of the global to store this field in.
Property DataDefinitionLocation As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Specifies the name of the StorageData definition. This name must be a valid storage member name and must not conflict with any other StorageData names.
Property Name As %RawString [ Required ];

/// Specifies the size of the small chunk for this colmnar string field.
Property SmallChunkSize As %Integer;

/// Specifies how the data is stored into a global node.
Property Structure As %RawString;

/// Subscript
Property Subscript As %RawString;

/// Value
Relationship Values As %Dictionary.CompiledStorageDataValue [ Cardinality = children, Inverse = parent ];

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
 i $$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||('$$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%Attribute=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute),i%%isDefined("Attribute")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute)
 . s i%ColumnarGlobal=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal),i%%isDefined("ColumnarGlobal")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal)
 . s i%ConversionTarget=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget),i%%isDefined("ConversionTarget")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget)
 . s i%DataDefinitionLocation=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation),i%%isDefined("DataDefinitionLocation")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation)
 . s i%KeywordError=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAkeyworderror)
 . s i%KeywordModified=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAkeywordmodified)
 . s i%SmallChunkSize=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize),i%%isDefined("SmallChunkSize")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize)
 . s i%Structure=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure),i%%isDefined("Structure")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure)
 . s i%Subscript=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript),i%%isDefined("Subscript")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript)
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

Method AttributeSet(value As %String = "") As %Status
{
 set i%Attribute=value,i%%isDefined("Attribute")=1 quit $$$OK
}

Method AttributeReset()
{
 set i%Attribute="" set i%%isDefined("Attribute")=0 quit
}

Method AttributeIsDefined() As %Boolean
{
 quit ''i%%isDefined("Attribute")
}

Method ColumnarGlobalSet(value As %String = "") As %Status
{
 set i%ColumnarGlobal=value,i%%isDefined("ColumnarGlobal")=1 quit $$$OK
}

Method ColumnarGlobalReset()
{
 set i%ColumnarGlobal="" set i%%isDefined("ColumnarGlobal")=0 quit
}

Method ColumnarGlobalIsDefined() As %Boolean
{
 quit ''i%%isDefined("ColumnarGlobal")
}

Method ConversionTargetSet(value As %String = "") As %Status
{
 set i%ConversionTarget=value,i%%isDefined("ConversionTarget")=1 quit $$$OK
}

Method ConversionTargetReset()
{
 set i%ConversionTarget="" set i%%isDefined("ConversionTarget")=0 quit
}

Method ConversionTargetIsDefined() As %Boolean
{
 quit ''i%%isDefined("ConversionTarget")
}

Method DataDefinitionLocationSet(value As %String = "") As %Status
{
 set i%DataDefinitionLocation=value,i%%isDefined("DataDefinitionLocation")=1 quit $$$OK
}

Method DataDefinitionLocationReset()
{
 set i%DataDefinitionLocation="" set i%%isDefined("DataDefinitionLocation")=0 quit
}

Method DataDefinitionLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("DataDefinitionLocation")
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

Method StructureSet(value As %String = "") As %Status
{
 set i%Structure=value,i%%isDefined("Structure")=1 quit $$$OK
}

Method StructureReset()
{
 set i%Structure="listnode" set i%%isDefined("Structure")=0 quit
}

Method StructureIsDefined() As %Boolean
{
 quit ''i%%isDefined("Structure")
}

Method SubscriptSet(value As %String = "") As %Status
{
 set i%Subscript=value,i%%isDefined("Subscript")=1 quit $$$OK
}

Method SubscriptReset()
{
 set i%Subscript="" set i%%isDefined("Subscript")=0 quit
}

Method SubscriptIsDefined() As %Boolean
{
 quit ''i%%isDefined("Subscript")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Attribute">
<RetrievalCode> s {Attribute}=$g(^oddCOM({L1},"s",{L3},"D",{L5},21),$g(^%qObjectKey(1,"D",21)))
</RetrievalCode>
</Data>
<Data name="ColumnarGlobal">
<RetrievalCode> s {ColumnarGlobal}=$g(^oddCOM({L1},"s",{L3},"D",{L5},39),$g(^%qObjectKey(1,"D",39)))
</RetrievalCode>
</Data>
<Data name="ConversionTarget">
<RetrievalCode> s {ConversionTarget}=$g(^oddCOM({L1},"s",{L3},"D",{L5},41),$g(^%qObjectKey(1,"D",41)))
</RetrievalCode>
</Data>
<Data name="DataDefinitionLocation">
<RetrievalCode> s {DataDefinitionLocation}=$g(^oddCOM({L1},"s",{L3},"D",{L5},46),$g(^%qObjectKey(1,"D",46)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"D",{L5},12),$g(^%qObjectKey(1,"D",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"D",{L5},13),$g(^%qObjectKey(1,"D",13)))
</RetrievalCode>
</Data>
<Data name="SmallChunkSize">
<RetrievalCode> s {SmallChunkSize}=$g(^oddCOM({L1},"s",{L3},"D",{L5},40),$g(^%qObjectKey(1,"D",40)))
</RetrievalCode>
</Data>
<Data name="Structure">
<RetrievalCode> s {Structure}=$g(^oddCOM({L1},"s",{L3},"D",{L5},22),$g(^%qObjectKey(1,"D",22)))
</RetrievalCode>
</Data>
<Data name="Subscript">
<RetrievalCode> s {Subscript}=$g(^oddCOM({L1},"s",{L3},"D",{L5},23),$g(^%qObjectKey(1,"D",23)))
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
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStoE869S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
