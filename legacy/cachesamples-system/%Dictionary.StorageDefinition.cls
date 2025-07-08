/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.StorageDefinition Extends (%Persistent, %Dictionary.StorageDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = Storages ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies the base location of counters for properties with type is %Library.Counter. Normally this would be a global reference such as ^User.PersonC. The global reference can also include one or more leading subscripts.
Property CounterLocation As %RawString;

/// Data
Relationship Data As %Dictionary.StorageDataDefinition [ Cardinality = children, Inverse = parent ];

/// Specifies expression that is the location where data is stored for this class. Normally this would be a global reference such as ^User.PersonD. The global reference can also include one or more leading subscripts.
Property DataLocation As %RawString;

/// Specifies the name of the DATA definition that the Class Compiler Data Structure Generator uses to place any previously unstored properties. A property is unstored if it is storable, but is not listed in any DATA definition. 
Property DefaultData As %RawString;

/// True if this storage is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the storage definition. This description is displayed by the online class reference.
Property Description As %RawString;

/// Specifies the base location of globals used by the extent of this class. 
Property ExtentLocation As %RawString;

/// ExtentSize
Property ExtentSize As %RawString;

/// Specifies that the storage definition cannot be modified by subclasses.
Property Final As %Boolean [ InitialExpression = 0 ];

/// IdExpression
Property IdExpression As %RawString;

/// Specifies the system function used to allocate new id values.
Property IdFunction As %RawString;

/// Specifies location of the ID Counter.
Property IdLocation As %RawString;

/// Index
Relationship Indices As %Dictionary.StorageIndexDefinition [ Cardinality = children, Inverse = parent ];

/// Specifies the global used for indices for this class. If not specified, the index location is ^MyApp.MyClassI, where MyApp.MyClass is the classname. 
Property IndexLocation As %RawString;

/// If true then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// Specifies the name of the Storage definition. This name must be a valid class member name and must not conflict with any other class member names.
Property Name As %RawString [ Required ];

/// Property
Relationship Properties As %Dictionary.StoragePropertyDefinition [ Cardinality = children, Inverse = parent ];

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// Value of the Sharded keyword
Property Sharded As %RawString;

/// ShardKey
Relationship ShardKeies As %Dictionary.StorageShardKeyDefinition [ Cardinality = children, Inverse = parent ];

/// Specifies the name of the shard-local class
Property ShardLocalClassName As %RawString;

/// Specifies the name of the shard-local table
Property ShardLocalTableName As %RawString;

/// SqlChildSub
Property SqlChildSub As %RawString;

/// SqlIdExpression
Property SqlIdExpression As %RawString;

/// SQLMap
Relationship SQLMaps As %Dictionary.StorageSQLMapDefinition [ Cardinality = children, Inverse = parent ];

/// Specifies the name of the Row ID column projected to SQL.
Property SqlRowIdName As %RawString;

/// Specifies the SQL RowId property. This keyword is only used by classes that have been migrated from earlier InterSystems products.
Property SqlRowIdProperty As %RawString;

/// Specifies the internal SQL Table Number. This keyword is only used by classes that have been migrated from earlier InterSystems products.
Property SqlTableNumber As %RawString;

/// For a serial embedded class, this keyword specifies which Data definition is used to define the serialized state of the object. This is also the default DATA definition that unstored properties will be added to by the default structure generator.
Property State As %RawString;

/// Specifies the default global used to store any stream properties within this class. If not specified, the index location is ^MyApp.MyClassS, where MyApp.MyClass is the classname. 
Property StreamLocation As %RawString;

/// Specifies the Storage Class used to provide persistence for this class.
Property Type As %Dictionary.Classname;

/// Specifies location of the %Version Counter.
Property VersionLocation As %RawString;

ClassMethod IdFunctionIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="increment" q $$$OK
 i val="sequence" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.StorageDefinition:IdFunction",val)
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
 s i%%isDefined("CounterLocation")=0
 s i%%isDefined("DataLocation")=0
 s i%%isDefined("DefaultData")=0
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("ExtentLocation")=0
 s i%%isDefined("ExtentSize")=0
 s i%%isDefined("Final")=0
 s i%%isDefined("IdExpression")=0
 s i%%isDefined("IdFunction")=0
 s i%%isDefined("IdLocation")=0
 s i%%isDefined("IndexLocation")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("Sharded")=0
 s i%%isDefined("ShardLocalClassName")=0
 s i%%isDefined("ShardLocalTableName")=0
 s i%%isDefined("SqlChildSub")=0
 s i%%isDefined("SqlIdExpression")=0
 s i%%isDefined("SqlRowIdName")=0
 s i%%isDefined("SqlRowIdProperty")=0
 s i%%isDefined("SqlTableNumber")=0
 s i%%isDefined("State")=0
 s i%%isDefined("StreamLocation")=0
 s i%%isDefined("Type")=0
 s i%%isDefined("VersionLocation")=0
 i $g(name)="" q $$$OK
 s i%parent=$$$NormalizeClassname($p(name,":",1))
 s i%Name=$p(name,":",2)
 q $$$OK
}

ClassMethod %LockId(id As %String, shared As %Boolean = 0, timeout As %Integer) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 i (name1="")||(name2="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$defMemberDefined(name1,$$$cCLASSstorage,name2) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSstorage,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%CounterLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation),i%%isDefined("CounterLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation)
 . s i%DataLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation),i%%isDefined("DataLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation)
 . s i%DefaultData=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata),i%%isDefined("DefaultData")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata)
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription)
 . s i%ExtentLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation),i%%isDefined("ExtentLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation)
 . s i%ExtentSize=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize),i%%isDefined("ExtentSize")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize)
 . s i%Final=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal),i%%isDefined("Final")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal)
 . s i%IdExpression=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression),i%%isDefined("IdExpression")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression)
 . s i%IdFunction=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction),i%%isDefined("IdFunction")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction)
 . s i%IdLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation),i%%isDefined("IdLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation)
 . s i%IndexLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation),i%%isDefined("IndexLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber)
 . s i%Sharded=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded),i%%isDefined("Sharded")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded)
 . s i%ShardLocalClassName=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname),i%%isDefined("ShardLocalClassName")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname)
 . s i%ShardLocalTableName=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename),i%%isDefined("ShardLocalTableName")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename)
 . s i%SqlChildSub=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub),i%%isDefined("SqlChildSub")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub)
 . s i%SqlIdExpression=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression),i%%isDefined("SqlIdExpression")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression)
 . s i%SqlRowIdName=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname),i%%isDefined("SqlRowIdName")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname)
 . s i%SqlRowIdProperty=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty),i%%isDefined("SqlRowIdProperty")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty)
 . s i%SqlTableNumber=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber),i%%isDefined("SqlTableNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber)
 . s i%State=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFstate),i%%isDefined("State")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFstate)
 . s i%StreamLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation),i%%isDefined("StreamLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation)
 . s i%Type=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFtype),i%%isDefined("Type")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFtype)
 . s i%VersionLocation=$$$defMemberKeyGet(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation),i%%isDefined("VersionLocation")=$$$defMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation)
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
 i i%parent'="",'##class(%Dictionary.ClassDefinition).%ExistsId(i%parent) q $$$ERROR($$$ReferencedObjectDoesNotExist,"ClassName")
 i 'insert DO
 . i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i '($$$defMemberDefined(name1,$$$cCLASSstorage,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSstorage,name2,"")
 . i 'i%%isDefined("CounterLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation,i%CounterLocation) }
 . i 'i%%isDefined("DataLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation,i%DataLocation) }
 . i 'i%%isDefined("DefaultData") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata,i%DefaultData) }
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription,i%Description) }
 . i 'i%%isDefined("ExtentLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation,i%ExtentLocation) }
 . i 'i%%isDefined("ExtentSize") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize,i%ExtentSize) }
 . i 'i%%isDefined("Final") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal,i%Final) }
 . i 'i%%isDefined("IdExpression") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression,i%IdExpression) }
 . i 'i%%isDefined("IdFunction") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction,i%IdFunction) }
 . i 'i%%isDefined("IdLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation,i%IdLocation) }
 . i 'i%%isDefined("IndexLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation,i%IndexLocation) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal,i%Internal) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("Sharded") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded,i%Sharded) }
 . i 'i%%isDefined("ShardLocalClassName") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname,i%ShardLocalClassName) }
 . i 'i%%isDefined("ShardLocalTableName") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename,i%ShardLocalTableName) }
 . i 'i%%isDefined("SqlChildSub") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub,i%SqlChildSub) }
 . i 'i%%isDefined("SqlIdExpression") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression,i%SqlIdExpression) }
 . i 'i%%isDefined("SqlRowIdName") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname,i%SqlRowIdName) }
 . i 'i%%isDefined("SqlRowIdProperty") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty,i%SqlRowIdProperty) }
 . i 'i%%isDefined("SqlTableNumber") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber,i%SqlTableNumber) }
 . i 'i%%isDefined("State") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFstate) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFstate,i%State) }
 . i 'i%%isDefined("StreamLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation,i%StreamLocation) }
 . i 'i%%isDefined("Type") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFtype) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFtype,i%Type) }
 . i 'i%%isDefined("VersionLocation") { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation,i%VersionLocation) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSstorage,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.StorageDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSstorage,name2,"")
 . i i%CounterLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation,i%CounterLocation) }
 . i i%DataLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation,i%DataLocation) }
 . i i%DefaultData="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata,i%DefaultData) }
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription,i%Description) }
 . i i%ExtentLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation,i%ExtentLocation) }
 . i i%ExtentSize="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize,i%ExtentSize) }
 . i i%Final=0 { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal,i%Final) }
 . i i%IdExpression="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression,i%IdExpression) }
 . i i%IdFunction="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction,i%IdFunction) }
 . i i%IdLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation,i%IdLocation) }
 . i i%IndexLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation,i%IndexLocation) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal,i%Internal) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber,i%SequenceNumber) }
 . i i%Sharded="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded,i%Sharded) }
 . i i%ShardLocalClassName="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname,i%ShardLocalClassName) }
 . i i%ShardLocalTableName="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename,i%ShardLocalTableName) }
 . i i%SqlChildSub="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub,i%SqlChildSub) }
 . i i%SqlIdExpression="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression,i%SqlIdExpression) }
 . i i%SqlRowIdName="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname,i%SqlRowIdName) }
 . i i%SqlRowIdProperty="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty,i%SqlRowIdProperty) }
 . i i%SqlTableNumber="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber,i%SqlTableNumber) }
 . i i%State="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFstate) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFstate,i%State) }
 . i i%StreamLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation,i%StreamLocation) }
 . i i%Type="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFtype) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFtype,i%Type) }
 . i i%VersionLocation="" { $$$defMemberKeyKill(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation) } else { $$$defMemberKeySet(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation,i%VersionLocation) }
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
 s name1=$p(id,"||",1),name2=$p(id,"||",2)
 If concurrency Set sc=..%LockId(id) If $$$ISERR(sc) Quit sc
 If '($$$defMemberDefined(name1,$$$cCLASSstorage,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSstorage,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
}

Method CounterLocationSet(value As %String = "") As %Status
{
 set i%CounterLocation=value,i%%isDefined("CounterLocation")=1 quit $$$OK
}

Method CounterLocationReset()
{
 set i%CounterLocation="" set i%%isDefined("CounterLocation")=0 quit
}

Method CounterLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("CounterLocation")
}

Method DataLocationSet(value As %String = "") As %Status
{
 set i%DataLocation=value,i%%isDefined("DataLocation")=1 quit $$$OK
}

Method DataLocationReset()
{
 set i%DataLocation="" set i%%isDefined("DataLocation")=0 quit
}

Method DataLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("DataLocation")
}

Method DefaultDataSet(value As %String = "") As %Status
{
 set i%DefaultData=value,i%%isDefined("DefaultData")=1 quit $$$OK
}

Method DefaultDataReset()
{
 set i%DefaultData="" set i%%isDefined("DefaultData")=0 quit
}

Method DefaultDataIsDefined() As %Boolean
{
 quit ''i%%isDefined("DefaultData")
}

Method DeprecatedSet(value As %String = "") As %Status
{
 set i%Deprecated=value,i%%isDefined("Deprecated")=1 quit $$$OK
}

Method DeprecatedReset()
{
 set i%Deprecated=0 set i%%isDefined("Deprecated")=0 quit
}

Method DeprecatedIsDefined() As %Boolean
{
 quit ''i%%isDefined("Deprecated")
}

Method DescriptionSet(value As %String = "") As %Status
{
 set i%Description=value,i%%isDefined("Description")=1 quit $$$OK
}

Method DescriptionReset()
{
 set i%Description="" set i%%isDefined("Description")=0 quit
}

Method DescriptionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Description")
}

Method ExtentLocationSet(value As %String = "") As %Status
{
 set i%ExtentLocation=value,i%%isDefined("ExtentLocation")=1 quit $$$OK
}

Method ExtentLocationReset()
{
 set i%ExtentLocation="" set i%%isDefined("ExtentLocation")=0 quit
}

Method ExtentLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("ExtentLocation")
}

Method ExtentSizeSet(value As %String = "") As %Status
{
 set i%ExtentSize=value,i%%isDefined("ExtentSize")=1 quit $$$OK
}

Method ExtentSizeReset()
{
 set i%ExtentSize="" set i%%isDefined("ExtentSize")=0 quit
}

Method ExtentSizeIsDefined() As %Boolean
{
 quit ''i%%isDefined("ExtentSize")
}

Method FinalSet(value As %String = "") As %Status
{
 set i%Final=value,i%%isDefined("Final")=1 quit $$$OK
}

Method FinalReset()
{
 set i%Final=0 set i%%isDefined("Final")=0 quit
}

Method FinalIsDefined() As %Boolean
{
 quit ''i%%isDefined("Final")
}

Method IdExpressionSet(value As %String = "") As %Status
{
 set i%IdExpression=value,i%%isDefined("IdExpression")=1 quit $$$OK
}

Method IdExpressionReset()
{
 set i%IdExpression="" set i%%isDefined("IdExpression")=0 quit
}

Method IdExpressionIsDefined() As %Boolean
{
 quit ''i%%isDefined("IdExpression")
}

Method IdFunctionSet(value As %String = "") As %Status
{
 set i%IdFunction=value,i%%isDefined("IdFunction")=1 quit $$$OK
}

Method IdFunctionReset()
{
 set i%IdFunction="" set i%%isDefined("IdFunction")=0 quit
}

Method IdFunctionIsDefined() As %Boolean
{
 quit ''i%%isDefined("IdFunction")
}

Method IdLocationSet(value As %String = "") As %Status
{
 set i%IdLocation=value,i%%isDefined("IdLocation")=1 quit $$$OK
}

Method IdLocationReset()
{
 set i%IdLocation="" set i%%isDefined("IdLocation")=0 quit
}

Method IdLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("IdLocation")
}

Method IndexLocationSet(value As %String = "") As %Status
{
 set i%IndexLocation=value,i%%isDefined("IndexLocation")=1 quit $$$OK
}

Method IndexLocationReset()
{
 set i%IndexLocation="" set i%%isDefined("IndexLocation")=0 quit
}

Method IndexLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("IndexLocation")
}

Method InternalSet(value As %String = "") As %Status
{
 set i%Internal=value,i%%isDefined("Internal")=1 quit $$$OK
}

Method InternalReset()
{
 set i%Internal=0 set i%%isDefined("Internal")=0 quit
}

Method InternalIsDefined() As %Boolean
{
 quit ''i%%isDefined("Internal")
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

Method SequenceNumberSet(value As %String = "") As %Status
{
 set i%SequenceNumber=value,i%%isDefined("SequenceNumber")=1 quit $$$OK
}

Method SequenceNumberReset()
{
 set i%SequenceNumber=0 set i%%isDefined("SequenceNumber")=0 quit
}

Method SequenceNumberIsDefined() As %Boolean
{
 quit ''i%%isDefined("SequenceNumber")
}

Method ShardedSet(value As %String = "") As %Status
{
 set i%Sharded=value,i%%isDefined("Sharded")=1 quit $$$OK
}

Method ShardedReset()
{
 set i%Sharded="" set i%%isDefined("Sharded")=0 quit
}

Method ShardedIsDefined() As %Boolean
{
 quit ''i%%isDefined("Sharded")
}

Method ShardLocalClassNameSet(value As %String = "") As %Status
{
 set i%ShardLocalClassName=value,i%%isDefined("ShardLocalClassName")=1 quit $$$OK
}

Method ShardLocalClassNameReset()
{
 set i%ShardLocalClassName="" set i%%isDefined("ShardLocalClassName")=0 quit
}

Method ShardLocalClassNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("ShardLocalClassName")
}

Method ShardLocalTableNameSet(value As %String = "") As %Status
{
 set i%ShardLocalTableName=value,i%%isDefined("ShardLocalTableName")=1 quit $$$OK
}

Method ShardLocalTableNameReset()
{
 set i%ShardLocalTableName="" set i%%isDefined("ShardLocalTableName")=0 quit
}

Method ShardLocalTableNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("ShardLocalTableName")
}

Method SqlChildSubSet(value As %String = "") As %Status
{
 set i%SqlChildSub=value,i%%isDefined("SqlChildSub")=1 quit $$$OK
}

Method SqlChildSubReset()
{
 set i%SqlChildSub="" set i%%isDefined("SqlChildSub")=0 quit
}

Method SqlChildSubIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlChildSub")
}

Method SqlIdExpressionSet(value As %String = "") As %Status
{
 set i%SqlIdExpression=value,i%%isDefined("SqlIdExpression")=1 quit $$$OK
}

Method SqlIdExpressionReset()
{
 set i%SqlIdExpression="" set i%%isDefined("SqlIdExpression")=0 quit
}

Method SqlIdExpressionIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlIdExpression")
}

Method SqlRowIdNameSet(value As %String = "") As %Status
{
 set i%SqlRowIdName=value,i%%isDefined("SqlRowIdName")=1 quit $$$OK
}

Method SqlRowIdNameReset()
{
 set i%SqlRowIdName="" set i%%isDefined("SqlRowIdName")=0 quit
}

Method SqlRowIdNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlRowIdName")
}

Method SqlRowIdPropertySet(value As %String = "") As %Status
{
 set i%SqlRowIdProperty=value,i%%isDefined("SqlRowIdProperty")=1 quit $$$OK
}

Method SqlRowIdPropertyReset()
{
 set i%SqlRowIdProperty="" set i%%isDefined("SqlRowIdProperty")=0 quit
}

Method SqlRowIdPropertyIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlRowIdProperty")
}

Method SqlTableNumberSet(value As %String = "") As %Status
{
 set i%SqlTableNumber=value,i%%isDefined("SqlTableNumber")=1 quit $$$OK
}

Method SqlTableNumberReset()
{
 set i%SqlTableNumber="" set i%%isDefined("SqlTableNumber")=0 quit
}

Method SqlTableNumberIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlTableNumber")
}

Method StateSet(value As %String = "") As %Status
{
 set i%State=value,i%%isDefined("State")=1 quit $$$OK
}

Method StateReset()
{
 set i%State="" set i%%isDefined("State")=0 quit
}

Method StateIsDefined() As %Boolean
{
 quit ''i%%isDefined("State")
}

Method StreamLocationSet(value As %String = "") As %Status
{
 set i%StreamLocation=value,i%%isDefined("StreamLocation")=1 quit $$$OK
}

Method StreamLocationReset()
{
 set i%StreamLocation="" set i%%isDefined("StreamLocation")=0 quit
}

Method StreamLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("StreamLocation")
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

Method VersionLocationSet(value As %String = "") As %Status
{
 set i%VersionLocation=value,i%%isDefined("VersionLocation")=1 quit $$$OK
}

Method VersionLocationReset()
{
 set i%VersionLocation="" set i%%isDefined("VersionLocation")=0 quit
}

Method VersionLocationIsDefined() As %Boolean
{
 quit ''i%%isDefined("VersionLocation")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="CounterLocation">
<RetrievalCode> s {CounterLocation}=$s($d(^oddDEF({L1},"s",{L3},36))#2:^(36),1:"")
</RetrievalCode>
</Data>
<Data name="DataLocation">
<RetrievalCode> s {DataLocation}=$s($d(^oddDEF({L1},"s",{L3},21))#2:^(21),1:"")
</RetrievalCode>
</Data>
<Data name="DefaultData">
<RetrievalCode> s {DefaultData}=$s($d(^oddDEF({L1},"s",{L3},22))#2:^(22),1:"")
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"s",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"s",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="ExtentLocation">
<RetrievalCode> s {ExtentLocation}=$s($d(^oddDEF({L1},"s",{L3},38))#2:^(38),1:"")
</RetrievalCode>
</Data>
<Data name="ExtentSize">
<RetrievalCode> s {ExtentSize}=$s($d(^oddDEF({L1},"s",{L3},34))#2:^(34),1:"")
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddDEF({L1},"s",{L3},7))#2:^(7),1:0)
</RetrievalCode>
</Data>
<Data name="IdExpression">
<RetrievalCode> s {IdExpression}=$s($d(^oddDEF({L1},"s",{L3},23))#2:^(23),1:"")
</RetrievalCode>
</Data>
<Data name="IdFunction">
<RetrievalCode> s {IdFunction}=$s($d(^oddDEF({L1},"s",{L3},37))#2:^(37),1:"")
</RetrievalCode>
</Data>
<Data name="IdLocation">
<RetrievalCode> s {IdLocation}=$s($d(^oddDEF({L1},"s",{L3},24))#2:^(24),1:"")
</RetrievalCode>
</Data>
<Data name="IndexLocation">
<RetrievalCode> s {IndexLocation}=$s($d(^oddDEF({L1},"s",{L3},25))#2:^(25),1:"")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"s",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"s",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="ShardLocalClassName">
<RetrievalCode> s {ShardLocalClassName}=$s($d(^oddDEF({L1},"s",{L3},44))#2:^(44),1:"")
</RetrievalCode>
</Data>
<Data name="ShardLocalTableName">
<RetrievalCode> s {ShardLocalTableName}=$s($d(^oddDEF({L1},"s",{L3},45))#2:^(45),1:"")
</RetrievalCode>
</Data>
<Data name="Sharded">
<RetrievalCode> s {Sharded}=$s($d(^oddDEF({L1},"s",{L3},40))#2:^(40),1:"")
</RetrievalCode>
</Data>
<Data name="SqlChildSub">
<RetrievalCode> s {SqlChildSub}=$s($d(^oddDEF({L1},"s",{L3},27))#2:^(27),1:"")
</RetrievalCode>
</Data>
<Data name="SqlIdExpression">
<RetrievalCode> s {SqlIdExpression}=$s($d(^oddDEF({L1},"s",{L3},28))#2:^(28),1:"")
</RetrievalCode>
</Data>
<Data name="SqlRowIdName">
<RetrievalCode> s {SqlRowIdName}=$s($d(^oddDEF({L1},"s",{L3},29))#2:^(29),1:"")
</RetrievalCode>
</Data>
<Data name="SqlRowIdProperty">
<RetrievalCode> s {SqlRowIdProperty}=$s($d(^oddDEF({L1},"s",{L3},30))#2:^(30),1:"")
</RetrievalCode>
</Data>
<Data name="SqlTableNumber">
<RetrievalCode> s {SqlTableNumber}=$s($d(^oddDEF({L1},"s",{L3},31))#2:^(31),1:"")
</RetrievalCode>
</Data>
<Data name="State">
<RetrievalCode> s {State}=$s($d(^oddDEF({L1},"s",{L3},32))#2:^(32),1:"")
</RetrievalCode>
</Data>
<Data name="StreamLocation">
<RetrievalCode> s {StreamLocation}=$s($d(^oddDEF({L1},"s",{L3},33))#2:^(33),1:"")
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddDEF({L1},"s",{L3},5))#2:^(5),1:"")
</RetrievalCode>
</Data>
<Data name="VersionLocation">
<RetrievalCode> s {VersionLocation}=$s($d(^oddDEF({L1},"s",{L3},35))#2:^(35),1:"")
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
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.StorageDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
