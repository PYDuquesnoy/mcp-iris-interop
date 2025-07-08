/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorageSQLMapSub Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledStorageSQLMap [ Cardinality = parent, Inverse = Subscripts ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// AccessType
Property AccessType As %RawString;

/// Accessvar
Relationship Accessvars As %Dictionary.CompiledStorageSQLMapSubAccessvar [ Cardinality = children, Inverse = parent ];

/// DataAccess
Property DataAccess As %RawString;

/// Delimiter
Property Delimiter As %RawString;

/// Expression
Property Expression As %RawString;

/// Invalidcondition
Relationship Invalidconditions As %Dictionary.CompiledStorageSQLMapSubInvalidcondition [ Cardinality = children, Inverse = parent ];

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// LoopInitValue
Property LoopInitValue As %RawString;

/// Name
Property Name As %Integer [ Required ];

/// NextCode
Property NextCode As %RawString;

/// NullMarker
Property NullMarker As %RawString;

/// StartValue
Property StartValue As %RawString;

/// StopExpression
Property StopExpression As %RawString;

/// StopValue
Property StopValue As %RawString;

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
 i $$$comStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||(name4="")||('$$$comStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,3)
 . s i%Name=name4
 . s i%AccessType=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype),i%%isDefined("AccessType")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype)
 . s i%DataAccess=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess),i%%isDefined("DataAccess")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess)
 . s i%Delimiter=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter),i%%isDefined("Delimiter")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter)
 . s i%Expression=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression),i%%isDefined("Expression")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression)
 . s i%KeywordError=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBkeyworderror),i%%isDefined("KeywordError")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBkeyworderror)
 . s i%KeywordModified=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBkeywordmodified),i%%isDefined("KeywordModified")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBkeywordmodified)
 . s i%LoopInitValue=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue),i%%isDefined("LoopInitValue")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue)
 . s i%NextCode=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode),i%%isDefined("NextCode")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode)
 . s i%NullMarker=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker),i%%isDefined("NullMarker")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker)
 . s i%StartValue=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue),i%%isDefined("StartValue")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue)
 . s i%StopExpression=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression),i%%isDefined("StopExpression")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression)
 . s i%StopValue=$$$comStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue),i%%isDefined("StopValue")=$$$comStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue)
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

Method AccessTypeSet(value As %String = "") As %Status
{
 set i%AccessType=value,i%%isDefined("AccessType")=1 quit $$$OK
}

Method AccessTypeReset()
{
 set i%AccessType="" set i%%isDefined("AccessType")=0 quit
}

Method AccessTypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("AccessType")
}

Method DataAccessSet(value As %String = "") As %Status
{
 set i%DataAccess=value,i%%isDefined("DataAccess")=1 quit $$$OK
}

Method DataAccessReset()
{
 set i%DataAccess="" set i%%isDefined("DataAccess")=0 quit
}

Method DataAccessIsDefined() As %Boolean
{
 quit ''i%%isDefined("DataAccess")
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

Method ExpressionSet(value As %String = "") As %Status
{
 set i%Expression=value,i%%isDefined("Expression")=1 quit $$$OK
}

Method ExpressionReset()
{
 set i%Expression="" set i%%isDefined("Expression")=0 quit
}

Method ExpressionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Expression")
}

Method LoopInitValueSet(value As %String = "") As %Status
{
 set i%LoopInitValue=value,i%%isDefined("LoopInitValue")=1 quit $$$OK
}

Method LoopInitValueReset()
{
 set i%LoopInitValue="" set i%%isDefined("LoopInitValue")=0 quit
}

Method LoopInitValueIsDefined() As %Boolean
{
 quit ''i%%isDefined("LoopInitValue")
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

Method NextCodeSet(value As %String = "") As %Status
{
 set i%NextCode=value,i%%isDefined("NextCode")=1 quit $$$OK
}

Method NextCodeReset()
{
 set i%NextCode="" set i%%isDefined("NextCode")=0 quit
}

Method NextCodeIsDefined() As %Boolean
{
 quit ''i%%isDefined("NextCode")
}

Method NullMarkerSet(value As %String = "") As %Status
{
 set i%NullMarker=value,i%%isDefined("NullMarker")=1 quit $$$OK
}

Method NullMarkerReset()
{
 set i%NullMarker="" set i%%isDefined("NullMarker")=0 quit
}

Method NullMarkerIsDefined() As %Boolean
{
 quit ''i%%isDefined("NullMarker")
}

Method StartValueSet(value As %String = "") As %Status
{
 set i%StartValue=value,i%%isDefined("StartValue")=1 quit $$$OK
}

Method StartValueReset()
{
 set i%StartValue="" set i%%isDefined("StartValue")=0 quit
}

Method StartValueIsDefined() As %Boolean
{
 quit ''i%%isDefined("StartValue")
}

Method StopExpressionSet(value As %String = "") As %Status
{
 set i%StopExpression=value,i%%isDefined("StopExpression")=1 quit $$$OK
}

Method StopExpressionReset()
{
 set i%StopExpression="" set i%%isDefined("StopExpression")=0 quit
}

Method StopExpressionIsDefined() As %Boolean
{
 quit ''i%%isDefined("StopExpression")
}

Method StopValueSet(value As %String = "") As %Status
{
 set i%StopValue=value,i%%isDefined("StopValue")=1 quit $$$OK
}

Method StopValueReset()
{
 set i%StopValue="" set i%%isDefined("StopValue")=0 quit
}

Method StopValueIsDefined() As %Boolean
{
 quit ''i%%isDefined("StopValue")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="AccessType">
<RetrievalCode> s {AccessType}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},21),$g(^%qObjectKey(1,"B",21)))
</RetrievalCode>
</Data>
<Data name="DataAccess">
<RetrievalCode> s {DataAccess}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},22),$g(^%qObjectKey(1,"B",22)))
</RetrievalCode>
</Data>
<Data name="Delimiter">
<RetrievalCode> s {Delimiter}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},23),$g(^%qObjectKey(1,"B",23)))
</RetrievalCode>
</Data>
<Data name="Expression">
<RetrievalCode> s {Expression}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},24),$g(^%qObjectKey(1,"B",24)))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},12),$g(^%qObjectKey(1,"B",12)))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},13),$g(^%qObjectKey(1,"B",13)))
</RetrievalCode>
</Data>
<Data name="LoopInitValue">
<RetrievalCode> s {LoopInitValue}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},25),$g(^%qObjectKey(1,"B",25)))
</RetrievalCode>
</Data>
<Data name="NextCode">
<RetrievalCode> s {NextCode}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},26),$g(^%qObjectKey(1,"B",26)))
</RetrievalCode>
</Data>
<Data name="NullMarker">
<RetrievalCode> s {NullMarker}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},27),$g(^%qObjectKey(1,"B",27)))
</RetrievalCode>
</Data>
<Data name="StartValue">
<RetrievalCode> s {StartValue}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},28),$g(^%qObjectKey(1,"B",28)))
</RetrievalCode>
</Data>
<Data name="StopExpression">
<RetrievalCode> s {StopExpression}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},29),$g(^%qObjectKey(1,"B",29)))
</RetrievalCode>
</Data>
<Data name="StopValue">
<RetrievalCode> s {StopValue}=$g(^oddCOM({L1},"s",{L3},"S",{L5},"B",{L7},30),$g(^%qObjectKey(1,"B",30)))
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
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledSto42CFS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
