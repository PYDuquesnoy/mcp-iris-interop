/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledStorage Extends (%Persistent, %Dictionary.CompiledStorageQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Storages ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// Specifies the base location of counters for properties with type is %Library.Counter. Normally this would be a global reference such as ^User.PersonC. The global reference can also include one or more leading subscripts.
Property CounterLocation As %RawString;

/// Data
Relationship Data As %Dictionary.CompiledStorageData [ Cardinality = children, Inverse = parent ];

/// Specifies expression that is the location where data is stored for this class. Normally this would be a global reference such as ^User.PersonD. The global reference can also include one or more leading subscripts.
Property DataLocation As %RawString;

/// Specifies the name of the DATA definition that the Class Compiler Data Structure Generator uses to place any previously unstored properties. A property is unstored if it is storable, but is not listed in any DATA definition. 
Property DefaultData As %RawString;

/// True if this storage is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the storage definition. This description is displayed by the online class reference.
Property Description As %RawString;

/// Specifies the base location of globals used by the extent of this class. 
Property ExtentLocation As %RawString;

/// ExtentSize
Property ExtentSize As %RawString;

/// Specifies that the storage definition cannot be modified by subclasses.
Property Final As %Boolean;

/// Id
Property Id As %Integer;

/// IdExpression
Property IdExpression As %RawString;

/// Specifies the system function used to allocate new id values.
Property IdFunction As %RawString;

/// Specifies location of the ID Counter.
Property IdLocation As %RawString;

/// Index
Relationship Indices As %Dictionary.CompiledStorageIndex [ Cardinality = children, Inverse = parent ];

/// Specifies the global used for indices for this class. If not specified, the index location is ^MyApp.MyClassI, where MyApp.MyClass is the classname. 
Property IndexLocation As %RawString;

/// InheritedId
Property InheritedId As %Boolean;

/// If true then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Specifies the name of the Storage definition. This name must be a valid class member name and must not conflict with any other class member names.
Property Name As %RawString [ Required ];

/// NotInheritable
Property NotInheritable As %Boolean;

/// Origin
Property Origin As %RawString;

/// Property
Relationship Properties As %Dictionary.CompiledStorageProperty [ Cardinality = children, Inverse = parent ];

/// RootClass
Property RootClass As %Boolean;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Value of the Sharded keyword
Property Sharded As %RawString;

/// ShardKey
Relationship ShardKeies As %Dictionary.CompiledStorageShardKey [ Cardinality = children, Inverse = parent ];

/// Specifies the name of the shard-local class
Property ShardLocalClassName As %RawString;

/// Specifies the name of the shard-local table
Property ShardLocalTableName As %RawString;

/// SqlChildSub
Property SqlChildSub As %RawString;

/// SqlIdExpression
Property SqlIdExpression As %RawString;

/// SQLMap
Relationship SQLMaps As %Dictionary.CompiledStorageSQLMap [ Cardinality = children, Inverse = parent ];

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
 i $$$comMemberDefined(name1,$$$cCLASSstorage,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSstorage,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFcompilergenerated)
 . s i%CounterLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation),i%%isDefined("CounterLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFcounterlocation)
 . s i%DataLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation),i%%isDefined("DataLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdatalocation)
 . s i%DefaultData=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata),i%%isDefined("DefaultData")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdefaultdata)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFdescription)
 . s i%ExtentLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation),i%%isDefined("ExtentLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFextentlocation)
 . s i%ExtentSize=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize),i%%isDefined("ExtentSize")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFextentsize)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFfinal)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFid)
 . s i%IdExpression=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression),i%%isDefined("IdExpression")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFidexpression)
 . s i%IdFunction=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction),i%%isDefined("IdFunction")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFidfunction)
 . s i%IdLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation),i%%isDefined("IdLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFidlocation)
 . s i%IndexLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation),i%%isDefined("IndexLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFindexlocation)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFinheritedid)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFkeywordmodified)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFnotinheritable)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEForigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEForigin)
 . s i%RootClass=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFrootclass),i%%isDefined("RootClass")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFrootclass)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsequencenumber)
 . s i%Sharded=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsharded),i%%isDefined("Sharded")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsharded)
 . s i%ShardLocalClassName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname),i%%isDefined("ShardLocalClassName")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocalclassname)
 . s i%ShardLocalTableName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename),i%%isDefined("ShardLocalTableName")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFshardlocaltablename)
 . s i%SqlChildSub=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub),i%%isDefined("SqlChildSub")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlchildsub)
 . s i%SqlIdExpression=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression),i%%isDefined("SqlIdExpression")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlidexpression)
 . s i%SqlRowIdName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname),i%%isDefined("SqlRowIdName")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidname)
 . s i%SqlRowIdProperty=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty),i%%isDefined("SqlRowIdProperty")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqlrowidproperty)
 . s i%SqlTableNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber),i%%isDefined("SqlTableNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFsqltablenumber)
 . s i%State=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFstate),i%%isDefined("State")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFstate)
 . s i%StreamLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation),i%%isDefined("StreamLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFstreamlocation)
 . s i%Type=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFtype),i%%isDefined("Type")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFtype)
 . s i%VersionLocation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation),i%%isDefined("VersionLocation")=$$$comMemberKeyDefined(name1,$$$cCLASSstorage,name2,$$$cSDEFversionlocation)
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
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"s",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"s",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="CounterLocation">
<RetrievalCode> s {CounterLocation}=$s($d(^oddCOM({L1},"s",{L3},36))#2:^(36),$d(^oddCOM($g(^(2),{L1}),"s",{L3},36))#2:^(36),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},36))#2:^(36),1:""))
</RetrievalCode>
</Data>
<Data name="DataLocation">
<RetrievalCode> s {DataLocation}=$s($d(^oddCOM({L1},"s",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"s",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},21))#2:^(21),1:""))
</RetrievalCode>
</Data>
<Data name="DefaultData">
<RetrievalCode> s {DefaultData}=$s($d(^oddCOM({L1},"s",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"s",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},22))#2:^(22),1:""))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"s",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"s",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"s",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"s",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="ExtentLocation">
<RetrievalCode> s {ExtentLocation}=$s($d(^oddCOM({L1},"s",{L3},38))#2:^(38),$d(^oddCOM($g(^(2),{L1}),"s",{L3},38))#2:^(38),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},38))#2:^(38),1:""))
</RetrievalCode>
</Data>
<Data name="ExtentSize">
<RetrievalCode> s {ExtentSize}=$s($d(^oddCOM({L1},"s",{L3},34))#2:^(34),$d(^oddCOM($g(^(2),{L1}),"s",{L3},34))#2:^(34),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},34))#2:^(34),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"s",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"s",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"s",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"s",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="IdExpression">
<RetrievalCode> s {IdExpression}=$s($d(^oddCOM({L1},"s",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"s",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Data name="IdFunction">
<RetrievalCode> s {IdFunction}=$s($d(^oddCOM({L1},"s",{L3},37))#2:^(37),$d(^oddCOM($g(^(2),{L1}),"s",{L3},37))#2:^(37),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},37))#2:^(37),1:""))
</RetrievalCode>
</Data>
<Data name="IdLocation">
<RetrievalCode> s {IdLocation}=$s($d(^oddCOM({L1},"s",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"s",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="IndexLocation">
<RetrievalCode> s {IndexLocation}=$s($d(^oddCOM({L1},"s",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"s",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},25))#2:^(25),1:""))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"s",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"s",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"s",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"s",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"s",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"s",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"s",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"s",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"s",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"s",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"s",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"s",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="RootClass">
<RetrievalCode> s {RootClass}=$s($d(^oddCOM({L1},"s",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"s",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},26))#2:^(26),1:0))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"s",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"s",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="ShardLocalClassName">
<RetrievalCode> s {ShardLocalClassName}=$s($d(^oddCOM({L1},"s",{L3},44))#2:^(44),$d(^oddCOM($g(^(2),{L1}),"s",{L3},44))#2:^(44),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},44))#2:^(44),1:""))
</RetrievalCode>
</Data>
<Data name="ShardLocalTableName">
<RetrievalCode> s {ShardLocalTableName}=$s($d(^oddCOM({L1},"s",{L3},45))#2:^(45),$d(^oddCOM($g(^(2),{L1}),"s",{L3},45))#2:^(45),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},45))#2:^(45),1:""))
</RetrievalCode>
</Data>
<Data name="Sharded">
<RetrievalCode> s {Sharded}=$s($d(^oddCOM({L1},"s",{L3},40))#2:^(40),$d(^oddCOM($g(^(2),{L1}),"s",{L3},40))#2:^(40),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},40))#2:^(40),1:""))
</RetrievalCode>
</Data>
<Data name="SqlChildSub">
<RetrievalCode> s {SqlChildSub}=$s($d(^oddCOM({L1},"s",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"s",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="SqlIdExpression">
<RetrievalCode> s {SqlIdExpression}=$s($d(^oddCOM({L1},"s",{L3},28))#2:^(28),$d(^oddCOM($g(^(2),{L1}),"s",{L3},28))#2:^(28),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},28))#2:^(28),1:""))
</RetrievalCode>
</Data>
<Data name="SqlRowIdName">
<RetrievalCode> s {SqlRowIdName}=$s($d(^oddCOM({L1},"s",{L3},29))#2:^(29),$d(^oddCOM($g(^(2),{L1}),"s",{L3},29))#2:^(29),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},29))#2:^(29),1:""))
</RetrievalCode>
</Data>
<Data name="SqlRowIdProperty">
<RetrievalCode> s {SqlRowIdProperty}=$s($d(^oddCOM({L1},"s",{L3},30))#2:^(30),$d(^oddCOM($g(^(2),{L1}),"s",{L3},30))#2:^(30),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},30))#2:^(30),1:""))
</RetrievalCode>
</Data>
<Data name="SqlTableNumber">
<RetrievalCode> s {SqlTableNumber}=$s($d(^oddCOM({L1},"s",{L3},31))#2:^(31),$d(^oddCOM($g(^(2),{L1}),"s",{L3},31))#2:^(31),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},31))#2:^(31),1:""))
</RetrievalCode>
</Data>
<Data name="State">
<RetrievalCode> s {State}=$s($d(^oddCOM({L1},"s",{L3},32))#2:^(32),$d(^oddCOM($g(^(2),{L1}),"s",{L3},32))#2:^(32),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},32))#2:^(32),1:""))
</RetrievalCode>
</Data>
<Data name="StreamLocation">
<RetrievalCode> s {StreamLocation}=$s($d(^oddCOM({L1},"s",{L3},33))#2:^(33),$d(^oddCOM($g(^(2),{L1}),"s",{L3},33))#2:^(33),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},33))#2:^(33),1:""))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddCOM({L1},"s",{L3},5))#2:^(5),$d(^oddCOM($g(^(2),{L1}),"s",{L3},5))#2:^(5),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},5))#2:^(5),1:""))
</RetrievalCode>
</Data>
<Data name="VersionLocation">
<RetrievalCode> s {VersionLocation}=$s($d(^oddCOM({L1},"s",{L3},35))#2:^(35),$d(^oddCOM($g(^(2),{L1}),"s",{L3},35))#2:^(35),1:$s($d(^oddDEF($g(^oddCOM({L1},"s",{L3},2),{L1}),"s",{L3},35))#2:^(35),1:""))
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
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledStorageS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
