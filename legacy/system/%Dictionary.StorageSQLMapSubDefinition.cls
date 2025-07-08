/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.StorageSQLMapSubDefinition Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.StorageSQLMapDefinition [ Cardinality = parent, Inverse = Subscripts ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// AccessType
Property AccessType As %RawString;

/// Accessvar
Relationship Accessvars As %Dictionary.StorageSQLMapSubAccessvarDefinition [ Cardinality = children, Inverse = parent ];

/// DataAccess
Property DataAccess As %RawString;

/// Delimiter
Property Delimiter As %RawString;

/// Expression
Property Expression As %RawString;

/// Invalidcondition
Relationship Invalidconditions As %Dictionary.StorageSQLMapSubInvalidconditionDefinition [ Cardinality = children, Inverse = parent ];

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

Trigger OnDelete [ Event = DELETE, Time = AFTER ]
{
 $$$defClassKeySet($p({parent},"||",1),$$$cCLASStimechanged,$zutil(188))
 do RebuildItemIndex^%R($p({parent},"||",1),"CLS")
}

Method %OnNew(name As %String) As %Status [ Private ]
{
 s i%%isDefined("AccessType")=0
 s i%%isDefined("DataAccess")=0
 s i%%isDefined("Delimiter")=0
 s i%%isDefined("Expression")=0
 s i%%isDefined("LoopInitValue")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("NextCode")=0
 s i%%isDefined("NullMarker")=0
 s i%%isDefined("StartValue")=0
 s i%%isDefined("StopExpression")=0
 s i%%isDefined("StopValue")=0
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
 i $$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||(name4="")||('$$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,3)
 . s i%Name=name4
 . s i%AccessType=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype),i%%isDefined("AccessType")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype)
 . s i%DataAccess=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess),i%%isDefined("DataAccess")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess)
 . s i%Delimiter=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter),i%%isDefined("Delimiter")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter)
 . s i%Expression=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression),i%%isDefined("Expression")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression)
 . s i%LoopInitValue=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue),i%%isDefined("LoopInitValue")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue)
 . s i%NextCode=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode),i%%isDefined("NextCode")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode)
 . s i%NullMarker=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker),i%%isDefined("NullMarker")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker)
 . s i%StartValue=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue),i%%isDefined("StartValue")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue)
 . s i%StopExpression=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression),i%%isDefined("StopExpression")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression)
 . s i%StopValue=$$$defStorageSubSubMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue),i%%isDefined("StopValue")=$$$defStorageSubSubMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue)
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
 . i '($$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defStorageSubSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,"")
 . i 'i%%isDefined("AccessType") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype,i%AccessType) }
 . i 'i%%isDefined("DataAccess") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess,i%DataAccess) }
 . i 'i%%isDefined("Delimiter") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter,i%Delimiter) }
 . i 'i%%isDefined("Expression") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression,i%Expression) }
 . i 'i%%isDefined("LoopInitValue") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue,i%LoopInitValue) }
 . i 'i%%isDefined("NextCode") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode,i%NextCode) }
 . i 'i%%isDefined("NullMarker") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker,i%NullMarker) }
 . i 'i%%isDefined("StartValue") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue,i%StartValue) }
 . i 'i%%isDefined("StopExpression") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression,i%StopExpression) }
 . i 'i%%isDefined("StopValue") { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue,i%StopValue) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,3):1,i%Name'=$p(id,"||",4):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3),name4=$p(id,"||",4)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.StorageSQLMapSubDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defStorageSubSubMemberSet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,"")
 . i i%AccessType="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBaccesstype,i%AccessType) }
 . i i%DataAccess="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdataaccess,i%DataAccess) }
 . i i%Delimiter="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBdelimiter,i%Delimiter) }
 . i i%Expression="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBexpression,i%Expression) }
 . i i%LoopInitValue="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBloopinitvalue,i%LoopInitValue) }
 . i i%NextCode="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnextcode,i%NextCode) }
 . i i%NullMarker="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBnullmarker,i%NullMarker) }
 . i i%StartValue="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstartvalue,i%StartValue) }
 . i i%StopExpression="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopexpression,i%StopExpression) }
 . i i%StopValue="" { $$$defStorageSubSubMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue) } else { $$$defStorageSubSubMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4,$$$cSDEFSQLMAPSUBstopvalue,i%StopValue) }
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
 If '($$$defStorageSubSubMemberDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defStorageSubSubMemberKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlmap,name3,$$$cSDEFSQLMAPsubscript,name4) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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
<RetrievalCode> s {AccessType}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},21),$g(^%qObjectKey(1,"B",21)))
</RetrievalCode>
</Data>
<Data name="DataAccess">
<RetrievalCode> s {DataAccess}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},22),$g(^%qObjectKey(1,"B",22)))
</RetrievalCode>
</Data>
<Data name="Delimiter">
<RetrievalCode> s {Delimiter}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},23),$g(^%qObjectKey(1,"B",23)))
</RetrievalCode>
</Data>
<Data name="Expression">
<RetrievalCode> s {Expression}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},24),$g(^%qObjectKey(1,"B",24)))
</RetrievalCode>
</Data>
<Data name="LoopInitValue">
<RetrievalCode> s {LoopInitValue}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},25),$g(^%qObjectKey(1,"B",25)))
</RetrievalCode>
</Data>
<Data name="NextCode">
<RetrievalCode> s {NextCode}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},26),$g(^%qObjectKey(1,"B",26)))
</RetrievalCode>
</Data>
<Data name="NullMarker">
<RetrievalCode> s {NullMarker}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},27),$g(^%qObjectKey(1,"B",27)))
</RetrievalCode>
</Data>
<Data name="StartValue">
<RetrievalCode> s {StartValue}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},28),$g(^%qObjectKey(1,"B",28)))
</RetrievalCode>
</Data>
<Data name="StopExpression">
<RetrievalCode> s {StopExpression}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},29),$g(^%qObjectKey(1,"B",29)))
</RetrievalCode>
</Data>
<Data name="StopValue">
<RetrievalCode> s {StopValue}=$g(^oddDEF({L1},"s",{L3},"S",{L5},"B",{L7},30),$g(^%qObjectKey(1,"B",30)))
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
<Expression>"B"</Expression>
</Subscript>
<Subscript name="7">
<Expression>{%Dictionary.StorageSQLMapSubDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.StorageSQLM551BS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
