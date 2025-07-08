/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageSQLMap Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorage [ Cardinality = parent, Inverse = SQLMaps ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// BlockCount
Property BlockCount As %Integer;

/// Condition
Property Condition As %RawString;

/// ConditionalWithHostVars
Property ConditionalWithHostVars As %Boolean;

/// ConditionFields
Property ConditionFields As %RawString;

/// Data
Relationship Data As %Dictionary.CompiledStorageSQLMapData [ Cardinality = children, Inverse = parent ];

/// Global
Property Global As %RawString [ SqlFieldName = _Global ];

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Name
Property Name As %RawString [ Required ];

/// PopulationPct
Property PopulationPct As %RawString;

/// PopulationType
Property PopulationType As %RawString;

/// RowIdSpec
Relationship RowIdSpecs As %Dictionary.CompiledStorageSQLMapRowIdSpec [ Cardinality = children, Inverse = parent ];

/// RowReference
Property RowReference As %RawString;

/// Structure
Property Structure As %RawString;

/// Subscript
Relationship Subscripts As %Dictionary.CompiledStorageSQLMapSub [ Cardinality = children, Inverse = parent ];

/// Specifies what kind of a map this is.
Property Type As %RawString;

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
 i $$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||('$$$comStorageSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%BlockCount=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPblockcount),i%%isDefined("BlockCount")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPblockcount)
 . s i%Condition=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPcondition),i%%isDefined("Condition")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPcondition)
 . s i%ConditionalWithHostVars=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPconditionalwithhostvars),i%%isDefined("ConditionalWithHostVars")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPconditionalwithhostvars)
 . s i%ConditionFields=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPconditionfields),i%%isDefined("ConditionFields")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPconditionfields)
 . s i%Global=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPglobal),i%%isDefined("Global")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPglobal)
 . s i%KeywordError=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPkeyworderror)
 . s i%KeywordModified=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPkeywordmodified)
 . s i%PopulationPct=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPpopulationpct),i%%isDefined("PopulationPct")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPpopulationpct)
 . s i%PopulationType=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPpopulationtype),i%%isDefined("PopulationType")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPpopulationtype)
 . s i%RowReference=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAProwreference),i%%isDefined("RowReference")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAProwreference)
 . s i%Structure=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPstructure),i%%isDefined("Structure")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPstructure)
 . s i%Type=$$$comStorageSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPtype),i%%isDefined("Type")=$$$comStorageSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPtype)
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

Method BlockCountSet(value As %String = "") As %Status
{
 set i%BlockCount=value,i%%isDefined("BlockCount")=1 quit $$$OK
}

Method BlockCountReset()
{
 set i%BlockCount=0 set i%%isDefined("BlockCount")=0 quit
}

Method BlockCountIsDefined() As %Boolean
{
 quit ''i%%isDefined("BlockCount")
}

Method ConditionSet(value As %String = "") As %Status
{
 set i%Condition=value,i%%isDefined("Condition")=1 quit $$$OK
}

Method ConditionReset()
{
 set i%Condition="" set i%%isDefined("Condition")=0 quit
}

Method ConditionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Condition")
}

Method ConditionalWithHostVarsSet(value As %String = "") As %Status
{
 set i%ConditionalWithHostVars=value,i%%isDefined("ConditionalWithHostVars")=1 quit $$$OK
}

Method ConditionalWithHostVarsReset()
{
 set i%ConditionalWithHostVars=0 set i%%isDefined("ConditionalWithHostVars")=0 quit
}

Method ConditionalWithHostVarsIsDefined() As %Boolean
{
 quit ''i%%isDefined("ConditionalWithHostVars")
}

Method ConditionFieldsSet(value As %String = "") As %Status
{
 set i%ConditionFields=value,i%%isDefined("ConditionFields")=1 quit $$$OK
}

Method ConditionFieldsReset()
{
 set i%ConditionFields="" set i%%isDefined("ConditionFields")=0 quit
}

Method ConditionFieldsIsDefined() As %Boolean
{
 quit ''i%%isDefined("ConditionFields")
}

Method GlobalSet(value As %String = "") As %Status
{
 set i%Global=value,i%%isDefined("Global")=1 quit $$$OK
}

Method GlobalReset()
{
 set i%Global="" set i%%isDefined("Global")=0 quit
}

Method GlobalIsDefined() As %Boolean
{
 quit ''i%%isDefined("Global")
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

Method PopulationPctSet(value As %String = "") As %Status
{
 set i%PopulationPct=value,i%%isDefined("PopulationPct")=1 quit $$$OK
}

Method PopulationPctReset()
{
 set i%PopulationPct="" set i%%isDefined("PopulationPct")=0 quit
}

Method PopulationPctIsDefined() As %Boolean
{
 quit ''i%%isDefined("PopulationPct")
}

Method PopulationTypeSet(value As %String = "") As %Status
{
 set i%PopulationType=value,i%%isDefined("PopulationType")=1 quit $$$OK
}

Method PopulationTypeReset()
{
 set i%PopulationType="" set i%%isDefined("PopulationType")=0 quit
}

Method PopulationTypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("PopulationType")
}

Method RowReferenceSet(value As %String = "") As %Status
{
 set i%RowReference=value,i%%isDefined("RowReference")=1 quit $$$OK
}

Method RowReferenceReset()
{
 set i%RowReference="" set i%%isDefined("RowReference")=0 quit
}

Method RowReferenceIsDefined() As %Boolean
{
 quit ''i%%isDefined("RowReference")
}

Method StructureSet(value As %String = "") As %Status
{
 set i%Structure=value,i%%isDefined("Structure")=1 quit $$$OK
}

Method StructureReset()
{
 set i%Structure="" set i%%isDefined("Structure")=0 quit
}

Method StructureIsDefined() As %Boolean
{
 quit ''i%%isDefined("Structure")
}

Method TypeSet(value As %String = "") As %Status
{
 set i%Type=value,i%%isDefined("Type")=1 quit $$$OK
}

Method TypeReset()
{
 set i%Type="" set i%%isDefined("Type")=0 quit
}

Method TypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("Type")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="BlockCount">
<RetrievalCode> s {BlockCount}=$g(^oddCOM({L1},"s",{L3},"S",{L5},29),$g(^%qObjectKey(1,"S",29)))
</RetrievalCode>
</Data>
<Data name="Condition">
<RetrievalCode> s {Condition}=$g(^oddCOM({L1},"s",{L3},"S",{L5},21),$g(^%qObjectKey(1,"S",21)))
</RetrievalCode>
</Data>
<Data name="ConditionFields">
<RetrievalCode> s {ConditionFields}=$g(^oddCOM({L1},"s",{L3},"S",{L5},23),$g(^%qObjectKey(1,"S",23)))
</RetrievalCode>
</Data>
<Data name="ConditionalWithHostVars">
<RetrievalCode> s {ConditionalWithHostVars}=$g(^oddCOM({L1},"s",{L3},"S",{L5},22),$g(^%qObjectKey(1,"S",22)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"S",{L5},12),$g(^%qObjectKey(1,"S",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"S",{L5},13),$g(^%qObjectKey(1,"S",13)))
</RetrievalCode>
</Data>
<Data name="PopulationPct">
<RetrievalCode> s {PopulationPct}=$g(^oddCOM({L1},"s",{L3},"S",{L5},25),$g(^%qObjectKey(1,"S",25)))
</RetrievalCode>
</Data>
<Data name="PopulationType">
<RetrievalCode> s {PopulationType}=$g(^oddCOM({L1},"s",{L3},"S",{L5},26),$g(^%qObjectKey(1,"S",26)))
</RetrievalCode>
</Data>
<Data name="RowReference">
<RetrievalCode> s {RowReference}=$g(^oddCOM({L1},"s",{L3},"S",{L5},27),$g(^%qObjectKey(1,"S",27)))
</RetrievalCode>
</Data>
<Data name="Structure">
<RetrievalCode> s {Structure}=$g(^oddCOM({L1},"s",{L3},"S",{L5},28),$g(^%qObjectKey(1,"S",28)))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$g(^oddCOM({L1},"s",{L3},"S",{L5},5),$g(^%qObjectKey(1,"S",5)))
</RetrievalCode>
</Data>
<Data name="_Global">
<RetrievalCode> s {_Global}=$g(^oddCOM({L1},"s",{L3},"S",{L5},24),$g(^%qObjectKey(1,"S",24)))
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
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStoE089S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
