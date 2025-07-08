/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.IndexDefinition Extends (%Persistent, %Dictionary.IndexDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = Indices ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies that this index should be abstract.  Not projected to SQL, holds no data.
Property Abstract As %Boolean [ InitialExpression = 0 ];

/// In the case of a conditional index, specifies the condition that must be met for an entry to be included in the index.
Property Condition As %RawString;

/// Specifies the name of the class this class is cosharded with.
Property CoshardWith As %Dictionary.Classname;

/// Specifies a list of properties whose values are to be stored within this index.
Property Data As %RawString;

/// True if this index is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the index.
Property Description As %RawString;

/// An extent index is used to keep track of which object instances belong to a subclass. When using bitmap indices, then an extent index is automatically maintained and there is no need to define one.
Property Extent As %Boolean [ ClientName = _Extent, InitialExpression = 0 ];

/// Specifies that the property or properties defined for this index will be used to form the Object Identity value for this object. This value is used to uniquely locate persistent object instances. 
Property IdKey As %Boolean [ InitialExpression = 0 ];

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// The name of the index.
Property Name As %Dictionary.Identifier [ Required ];

/// Parameter
Property Parameters As array Of %RawString;

/// Specifies that this index should be reported, via SQL, as being the Primary Key for this class. 
Property PrimaryKey As %Boolean [ InitialExpression = 0 ];

/// Specifies a list of properties used to build this index. May also include a collation specification for each property.
Property Properties As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// If true then this index defines the components of the shard key.
Property ShardKey As %Boolean [ InitialExpression = 0 ];

/// Defines an alternate name for this index when referred to via SQL.
Property SqlName As %RawString;

/// Specifies the type of the index. Type &#39;key&#39; is deprecated.
Property Type As %RawString;

/// Specifies the FunctionalIndex class used to provide the implementation of the functional index interface.
Property TypeClass As %Dictionary.Classname;

/// Specifies whether this is a unique index.  The property or properties indexed by a unique index are constrained to have unique values.  This means that no two instances can have the same collated value within the extent among the set of all objects of the class that defines the index.
Property Unique As %Boolean [ InitialExpression = 0, SqlFieldName = _Unique ];

ClassMethod TypeIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="bitmap" q $$$OK
 i val="bitslice" q $$$OK
 i val="columnar" q $$$OK
 i val="index" q $$$OK
 i val="collatedkey" q $$$OK
 i val="key" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.IndexDefinition:Type",val)
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
 s i%%isDefined("Abstract")=0
 s i%%isDefined("Condition")=0
 s i%%isDefined("CoshardWith")=0
 s i%%isDefined("Data")=0
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("Extent")=0
 s i%%isDefined("IdKey")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("PrimaryKey")=0
 s i%%isDefined("Properties")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("ShardKey")=0
 s i%%isDefined("SqlName")=0
 s i%%isDefined("Type")=0
 s i%%isDefined("TypeClass")=0
 s i%%isDefined("Unique")=0
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
 i $$$defMemberDefined(name1,$$$cCLASSindex,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSindex,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Abstract=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXabstract),i%%isDefined("Abstract")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXabstract)
 . s i%Condition=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXcondition),i%%isDefined("Condition")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXcondition)
 . s i%CoshardWith=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXcoshardwith),i%%isDefined("CoshardWith")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXcoshardwith)
 . s i%Data=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXdata),i%%isDefined("Data")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXdata)
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXdescription)
 . s i%Extent=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXextent),i%%isDefined("Extent")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXextent)
 . s i%IdKey=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXidkey),i%%isDefined("IdKey")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXidkey)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXinternal)
 . s i%PrimaryKey=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXprimarykey),i%%isDefined("PrimaryKey")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXprimarykey)
 . s i%Properties=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXproperties),i%%isDefined("Properties")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperties)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXsequencenumber)
 . s i%ShardKey=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXshardkey),i%%isDefined("ShardKey")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXshardkey)
 . s i%SqlName=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXsqlname),i%%isDefined("SqlName")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXsqlname)
 . s i%Type=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXtype),i%%isDefined("Type")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXtype)
 . s i%TypeClass=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXtypeclass),i%%isDefined("TypeClass")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXtypeclass)
 . s i%Unique=$$$defMemberKeyGet(name1,$$$cCLASSindex,name2,$$$cINDEXunique),i%%isDefined("Unique")=$$$defMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXunique)
 . s sub="" f  s sub=$$$defSubMemberNext(name1,$$$cCLASSindex,name2,$$$cINDEXparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$defMemberArrayGet(name1,$$$cCLASSindex,name2,$$$cINDEXparameter,sub),sub)
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
 . i '($$$defMemberDefined(name1,$$$cCLASSindex,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSindex,name2,"")
 . i 'i%%isDefined("Abstract") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXabstract) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXabstract,i%Abstract) }
 . i 'i%%isDefined("Condition") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXcondition) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXcondition,i%Condition) }
 . i 'i%%isDefined("CoshardWith") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXcoshardwith) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXcoshardwith,i%CoshardWith) }
 . i 'i%%isDefined("Data") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXdata) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXdata,i%Data) }
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXdescription,i%Description) }
 . i 'i%%isDefined("Extent") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXextent) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXextent,i%Extent) }
 . i 'i%%isDefined("IdKey") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXidkey) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXidkey,i%IdKey) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXinternal,i%Internal) }
 . i 'i%%isDefined("PrimaryKey") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXprimarykey) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXprimarykey,i%PrimaryKey) }
 . i 'i%%isDefined("Properties") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXproperties) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXproperties,i%Properties) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("ShardKey") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXshardkey) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXshardkey,i%ShardKey) }
 . i 'i%%isDefined("SqlName") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXsqlname,i%SqlName) }
 . i 'i%%isDefined("Type") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXtype) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXtype,i%Type) }
 . i 'i%%isDefined("TypeClass") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXtypeclass) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXtypeclass,i%TypeClass) }
 . i 'i%%isDefined("Unique") { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXunique) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXunique,i%Unique) }
 . $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSindex,name2,$$$cINDEXparameter,sub,..Parameters.GetAt(sub))
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSindex,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.IndexDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSindex,name2,"")
 . i i%Abstract=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXabstract) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXabstract,i%Abstract) }
 . i i%Condition="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXcondition) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXcondition,i%Condition) }
 . i i%CoshardWith="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXcoshardwith) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXcoshardwith,i%CoshardWith) }
 . i i%Data="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXdata) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXdata,i%Data) }
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXdescription,i%Description) }
 . i i%Extent=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXextent) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXextent,i%Extent) }
 . i i%IdKey=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXidkey) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXidkey,i%IdKey) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXinternal,i%Internal) }
 . i i%PrimaryKey=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXprimarykey) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXprimarykey,i%PrimaryKey) }
 . i i%Properties="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXproperties) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXproperties,i%Properties) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXsequencenumber,i%SequenceNumber) }
 . i i%ShardKey=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXshardkey) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXshardkey,i%ShardKey) }
 . i i%SqlName="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXsqlname,i%SqlName) }
 . i i%Type="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXtype) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXtype,i%Type) }
 . i i%TypeClass="" { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXtypeclass) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXtypeclass,i%TypeClass) }
 . i i%Unique=0 { $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXunique) } else { $$$defMemberKeySet(name1,$$$cCLASSindex,name2,$$$cINDEXunique,i%Unique) }
 . $$$defMemberKeyKill(name1,$$$cCLASSindex,name2,$$$cINDEXparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSindex,name2,$$$cINDEXparameter,sub,..Parameters.GetAt(sub))
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
 If '($$$defMemberDefined(name1,$$$cCLASSindex,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSindex,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
}

Method AbstractSet(value As %String = "") As %Status
{
 set i%Abstract=value,i%%isDefined("Abstract")=1 quit $$$OK
}

Method AbstractReset()
{
 set i%Abstract=0 set i%%isDefined("Abstract")=0 quit
}

Method AbstractIsDefined() As %Boolean
{
 quit ''i%%isDefined("Abstract")
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

Method CoshardWithSet(value As %String = "") As %Status
{
 set i%CoshardWith=value,i%%isDefined("CoshardWith")=1 quit $$$OK
}

Method CoshardWithReset()
{
 set i%CoshardWith="" set i%%isDefined("CoshardWith")=0 quit
}

Method CoshardWithIsDefined() As %Boolean
{
 quit ''i%%isDefined("CoshardWith")
}

Method DataSet(value As %String = "") As %Status
{
 set i%Data=value,i%%isDefined("Data")=1 quit $$$OK
}

Method DataReset()
{
 set i%Data="" set i%%isDefined("Data")=0 quit
}

Method DataIsDefined() As %Boolean
{
 quit ''i%%isDefined("Data")
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

Method ExtentSet(value As %String = "") As %Status
{
 set i%Extent=value,i%%isDefined("Extent")=1 quit $$$OK
}

Method ExtentReset()
{
 set i%Extent=0 set i%%isDefined("Extent")=0 quit
}

Method ExtentIsDefined() As %Boolean
{
 quit ''i%%isDefined("Extent")
}

Method IdKeySet(value As %String = "") As %Status
{
 set i%IdKey=value,i%%isDefined("IdKey")=1 quit $$$OK
}

Method IdKeyReset()
{
 set i%IdKey=0 set i%%isDefined("IdKey")=0 quit
}

Method IdKeyIsDefined() As %Boolean
{
 quit ''i%%isDefined("IdKey")
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

Method PrimaryKeySet(value As %String = "") As %Status
{
 set i%PrimaryKey=value,i%%isDefined("PrimaryKey")=1 quit $$$OK
}

Method PrimaryKeyReset()
{
 set i%PrimaryKey=0 set i%%isDefined("PrimaryKey")=0 quit
}

Method PrimaryKeyIsDefined() As %Boolean
{
 quit ''i%%isDefined("PrimaryKey")
}

Method PropertiesSet(value As %String = "") As %Status
{
 set i%Properties=value,i%%isDefined("Properties")=1 quit $$$OK
}

Method PropertiesReset()
{
 set i%Properties="" set i%%isDefined("Properties")=0 quit
}

Method PropertiesIsDefined() As %Boolean
{
 quit ''i%%isDefined("Properties")
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

Method ShardKeySet(value As %String = "") As %Status
{
 set i%ShardKey=value,i%%isDefined("ShardKey")=1 quit $$$OK
}

Method ShardKeyReset()
{
 set i%ShardKey=0 set i%%isDefined("ShardKey")=0 quit
}

Method ShardKeyIsDefined() As %Boolean
{
 quit ''i%%isDefined("ShardKey")
}

Method SqlNameSet(value As %String = "") As %Status
{
 set i%SqlName=value,i%%isDefined("SqlName")=1 quit $$$OK
}

Method SqlNameReset()
{
 set i%SqlName="" set i%%isDefined("SqlName")=0 quit
}

Method SqlNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlName")
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

Method TypeClassSet(value As %String = "") As %Status
{
 set i%TypeClass=value,i%%isDefined("TypeClass")=1 quit $$$OK
}

Method TypeClassReset()
{
 set i%TypeClass="" set i%%isDefined("TypeClass")=0 quit
}

Method TypeClassIsDefined() As %Boolean
{
 quit ''i%%isDefined("TypeClass")
}

Method UniqueSet(value As %String = "") As %Status
{
 set i%Unique=value,i%%isDefined("Unique")=1 quit $$$OK
}

Method UniqueReset()
{
 set i%Unique=0 set i%%isDefined("Unique")=0 quit
}

Method UniqueIsDefined() As %Boolean
{
 quit ''i%%isDefined("Unique")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Abstract">
<RetrievalCode> s {Abstract}=$s($d(^oddDEF({L1},"i",{L3},35))#2:^(35),1:0)
</RetrievalCode>
</Data>
<Data name="Condition">
<RetrievalCode> s {Condition}=$s($d(^oddDEF({L1},"i",{L3},23))#2:^(23),1:"")
</RetrievalCode>
</Data>
<Data name="CoshardWith">
<RetrievalCode> s {CoshardWith}=$s($d(^oddDEF({L1},"i",{L3},36))#2:^(36),1:"")
</RetrievalCode>
</Data>
<Data name="Data">
<RetrievalCode> s {Data}=$s($d(^oddDEF({L1},"i",{L3},24))#2:^(24),1:"")
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"i",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"i",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Extent">
<RetrievalCode> s {Extent}=$s($d(^oddDEF({L1},"i",{L3},25))#2:^(25),1:0)
</RetrievalCode>
</Data>
<Data name="IdKey">
<RetrievalCode> s {IdKey}=$s($d(^oddDEF({L1},"i",{L3},26))#2:^(26),1:0)
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"i",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddDEF({L1},"i",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$g(^oddDEF({L1},"i",{L3},"P",sub))))
</RetrievalCode>
</Data>
<Data name="PrimaryKey">
<RetrievalCode> s {PrimaryKey}=$s($d(^oddDEF({L1},"i",{L3},27))#2:^(27),1:0)
</RetrievalCode>
</Data>
<Data name="Properties">
<RetrievalCode> s {Properties}=$s($d(^oddDEF({L1},"i",{L3},28))#2:^(28),1:"")
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"i",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="ShardKey">
<RetrievalCode> s {ShardKey}=$s($d(^oddDEF({L1},"i",{L3},34))#2:^(34),1:0)
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddDEF({L1},"i",{L3},29))#2:^(29),1:"")
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddDEF({L1},"i",{L3},5))#2:^(5),1:"")
</RetrievalCode>
</Data>
<Data name="TypeClass">
<RetrievalCode> s {TypeClass}=$s($d(^oddDEF({L1},"i",{L3},33))#2:^(33),1:"")
</RetrievalCode>
</Data>
<Data name="_Unique">
<RetrievalCode> s {_Unique}=$s($d(^oddDEF({L1},"i",{L3},31))#2:^(31),1:0)
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"i"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.IndexDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.IndexDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
