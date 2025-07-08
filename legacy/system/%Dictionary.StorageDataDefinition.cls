/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.StorageDataDefinition Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.StorageDefinition [ Cardinality = parent, Inverse = Data ];

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

/// Specifies the name of the StorageData definition. This name must be a valid storage member name and must not conflict with any other StorageData names.
Property Name As %RawString [ Required ];

/// Specifies the size of the small chunk for this colmnar string field.
Property SmallChunkSize As %Integer [ InitialExpression = 0 ];

/// Specifies how the data is stored into a global node.
Property Structure As %RawString [ InitialExpression = "listnode" ];

/// Subscript
Property Subscript As %RawString;

/// Value
Relationship Values As %Dictionary.StorageDataValueDefinition [ Cardinality = children, Inverse = parent ];

ClassMethod StructureIsValid(val As %String) As %Status
{
 i val="node" q $$$OK
 i val="listnode" q $$$OK
 i val="subnode" q $$$OK
 i val="vector" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.StorageDataDefinition:Structure",val)
}

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
 s i%%isDefined("Attribute")=0
 s i%%isDefined("ColumnarGlobal")=0
 s i%%isDefined("ConversionTarget")=0
 s i%%isDefined("DataDefinitionLocation")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("SmallChunkSize")=0
 s i%%isDefined("Structure")=0
 s i%%isDefined("Subscript")=0
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
 i $$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||('$$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%Attribute=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute),i%%isDefined("Attribute")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute)
 . s i%ColumnarGlobal=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal),i%%isDefined("ColumnarGlobal")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal)
 . s i%ConversionTarget=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget),i%%isDefined("ConversionTarget")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget)
 . s i%DataDefinitionLocation=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation),i%%isDefined("DataDefinitionLocation")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation)
 . s i%SmallChunkSize=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize),i%%isDefined("SmallChunkSize")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize)
 . s i%Structure=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure),i%%isDefined("Structure")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure)
 . s i%Subscript=$$$defStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript),i%%isDefined("Subscript")=$$$defStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript)
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
 . i '($$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defStorageSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,"")
 . i 'i%%isDefined("Attribute") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute,i%Attribute) }
 . i 'i%%isDefined("ColumnarGlobal") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal,i%ColumnarGlobal) }
 . i 'i%%isDefined("ConversionTarget") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget,i%ConversionTarget) }
 . i 'i%%isDefined("DataDefinitionLocation") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation,i%DataDefinitionLocation) }
 . i 'i%%isDefined("SmallChunkSize") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize,i%SmallChunkSize) }
 . i 'i%%isDefined("Structure") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure,i%Structure) }
 . i 'i%%isDefined("Subscript") { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript,i%Subscript) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,2):1,i%Name'=$p(id,"||",3):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.StorageDataDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defStorageSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,"")
 . i i%Attribute="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAattribute,i%Attribute) }
 . i i%ColumnarGlobal="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAcolumnarglobal,i%ColumnarGlobal) }
 . i i%ConversionTarget="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAconversiontarget,i%ConversionTarget) }
 . i i%DataDefinitionLocation="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAdatadefinitionlocation,i%DataDefinitionLocation) }
 . i i%SmallChunkSize=0 { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsmallchunksize,i%SmallChunkSize) }
 . i i%Structure="listnode" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAstructure,i%Structure) }
 . i i%Subscript="" { $$$defStorageSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript) } else { $$$defStorageSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3,$$$cSDEFDATAsubscript,i%Subscript) }
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
 If '($$$defStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defStorageSubMemberKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdata,name3) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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
<RetrievalCode> s {Attribute}=$g(^oddDEF({L1},"s",{L3},"D",{L5},21),$g(^%qObjectKey(1,"D",21)))
</RetrievalCode>
</Data>
<Data name="ColumnarGlobal">
<RetrievalCode> s {ColumnarGlobal}=$g(^oddDEF({L1},"s",{L3},"D",{L5},39),$g(^%qObjectKey(1,"D",39)))
</RetrievalCode>
</Data>
<Data name="ConversionTarget">
<RetrievalCode> s {ConversionTarget}=$g(^oddDEF({L1},"s",{L3},"D",{L5},41),$g(^%qObjectKey(1,"D",41)))
</RetrievalCode>
</Data>
<Data name="DataDefinitionLocation">
<RetrievalCode> s {DataDefinitionLocation}=$g(^oddDEF({L1},"s",{L3},"D",{L5},46),$g(^%qObjectKey(1,"D",46)))
</RetrievalCode>
</Data>
<Data name="SmallChunkSize">
<RetrievalCode> s {SmallChunkSize}=$g(^oddDEF({L1},"s",{L3},"D",{L5},40),$g(^%qObjectKey(1,"D",40)))
</RetrievalCode>
</Data>
<Data name="Structure">
<RetrievalCode> s {Structure}=$g(^oddDEF({L1},"s",{L3},"D",{L5},22),$g(^%qObjectKey(1,"D",22)))
</RetrievalCode>
</Data>
<Data name="Subscript">
<RetrievalCode> s {Subscript}=$g(^oddDEF({L1},"s",{L3},"D",{L5},23),$g(^%qObjectKey(1,"D",23)))
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
<Expression>"D"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.StorageDataDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.StorageData1004S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
