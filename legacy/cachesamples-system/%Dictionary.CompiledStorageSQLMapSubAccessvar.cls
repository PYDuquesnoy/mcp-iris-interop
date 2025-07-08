/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageSQLMapSubAccessvar Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorageSQLMapSub [ Cardinality = parent, Inverse = Accessvars ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Code
Property Code As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Name
Property Name As %Integer [ Required ];

/// Variable
Property Variable As %RawString;

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
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4),name5=$p(id,"||",5)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4),name5=$p(id,"||",5)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4),name5=$p(id,"||",5)
 i (name1="")||(name2="")||(name3="")||(name4="")||(name5="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$comStorageSubSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4),name5=$p(id,"||",5)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||(name3="")||(name4="")||(name5="")||('$$$comStorageSubSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,4)
 . s i%Name=name5
 . s i%Code=$$$comStorageSubSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARcode),i%%isDefined("Code")=$$$comStorageSubSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARcode)
 . s i%KeywordError=$$$comStorageSubSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARkeyworderror)
 . s i%KeywordModified=$$$comStorageSubSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARkeywordmodified)
 . s i%Variable=$$$comStorageSubSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARvariable),i%%isDefined("Variable")=$$$comStorageSubSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccessvar,name5,$$$cSDEFSQLMAPSUBACCESSVARvariable)
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

Method CodeSet(value As %String = "") As %Status
{
 set i%Code=value,i%%isDefined("Code")=1 quit $$$OK
}

Method CodeReset()
{
 set i%Code="" set i%%isDefined("Code")=0 quit
}

Method CodeIsDefined() As %Boolean
{
 quit ''i%%isDefined("Code")
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

Method VariableSet(value As %String = "") As %Status
{
 set i%Variable=value,i%%isDefined("Variable")=1 quit $$$OK
}

Method VariableReset()
{
 set i%Variable="" set i%%isDefined("Variable")=0 quit
}

Method VariableIsDefined() As %Boolean
{
 quit ''i%%isDefined("Variable")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Code">
<RetrievalCode> s {Code}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},"A",{L9},21),$g(^%qObjectKey(1,"A",21)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},"A",{L9},12),$g(^%qObjectKey(1,"A",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},"A",{L9},13),$g(^%qObjectKey(1,"A",13)))
</RetrievalCode>
</Data>
<Data name="Variable">
<RetrievalCode> s {Variable}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},"A",{L9},22),$g(^%qObjectKey(1,"A",22)))
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
<Expression>"B"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{%Dictionary.CompiledStorageSQLMapSub.Name}</Expression>
</Subscript>
<Subscript name="8">
<Expression>"A"</Expression>
</Subscript>
<Subscript name="9">
<Expression>{%Dictionary.CompiledStorageSQLMapSubAccessvar.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStoA1E3S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
