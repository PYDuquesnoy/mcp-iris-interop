/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledProperty Extends (%Persistent, %Dictionary.CompiledPropertyQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Properties ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// List of aliases for this property.
Property Aliases As %RawString;

/// Specifies that the property has no in-memory storage allocated for it when the object containing it is instantiated.
Property Calculated As %Boolean;

/// Specifies the cardinality of a relationship property. The Cardinality keyword is required for relationship properties. It is ignored by non-relationship properties. 
Property Cardinality As %RawString;

/// An alias used by client projections of this property.
Property ClientName As %RawString;

/// Specifies that a property is a collection property as well as what type of collection it is.
Property Collection As %RawString;

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// List of properties referenced by the SQLCOMPUTECODE.
Property ComputeDependency As %RawString;

/// List of properties to be computed when this property changes.
Property ComputeTriggers As %RawString;

/// True if this property is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the property.
Property Description As %RawString;

/// Deprecated
Property DirectRefOnGet As %Boolean;

/// Deprecated
Property DirectRefOnSet As %Boolean;

/// Specifies that subclasses cannot override the definition of this property.
Property Final As %Boolean;

/// Id
Property Id As %Integer;

/// Specifies that this property is the identity for this class. Identity properties can be set in new objects only and the default is set by incrementing a counter.
Property Identity As %Boolean [ SqlFieldName = _Identity ];

/// InheritedId
Property InheritedId As %Boolean;

/// Specifies an initial value for the property.
Property InitialExpression As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// Specifies the name of the inverse side of a relationship. That is, the name of the corresponding relationship property in the related class. The inverse property must exist in the related class and have the correct Cardinality value. The Inverse keyword is required for relationship properties. It is ignored by non-relationship properties.
Property Inverse As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Method
Relationship Methods As %Dictionary.CompiledPropertyMethod [ Cardinality = children, Inverse = parent ];

/// Specifies that an attribute has the characteristics of a multidimensional array.
Property MultiDimensional As %Boolean;

/// The name of the property.
Property Name As %Dictionary.Identifier [ Required ];

/// Deprecated.
Property NoModBit As %Boolean;

/// Deprecated.
Property NotInheritable As %Boolean;

/// Specifies what referential action to take when the key value is deleted from the foreign table.
Property OnDelete As %RawString;

/// Origin
Property Origin As %RawString;

/// Parameter
Property Parameters As array Of %RawString;

/// Specifies that the property is private. Private properties can only be used by instance methods of this class or its subclasses.
Property Private As %Boolean;

/// Specifies that the property is readonly.
Property ReadOnly As %Boolean;

/// Specifies that a property is a relationship property. 
Property Relationship As %Boolean;

/// In the case of a persistent class, specifies that the value of the property must be given a value before it can be stored to disk.
Property Required As %Boolean;

/// RuntimeType
Property RuntimeType As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Specifies that a property will not be projected to a Java or C++ client.
Property ServerOnly As %RawString;

/// Deprecated.
Property SqlCollation As %RawString;

/// Explicitly sets the SQL Column number for this property. This is provided for legacy application support.
Property SqlColumnNumber As %RawString;

/// Specifies ObjectScript code that evaluates to a computed field value. 
Property SqlComputeCode As %RawString;

/// Specifies that this property is an SQL computed field.
Property SqlComputed As %Boolean;

/// Specifies one or more properties whose modification triggers the recalculation of this computed field within SQL.
Property SqlComputeOnChange As %RawString;

/// In the case of a persistent class, specifies the column name used to identify the property in its SQL projection. By default, the SQL column name is the same as the property name.
Property SqlFieldName As %RawString;

/// Specifies the delimiter character used within SQL for lists. This is provided for legacy application support.
Property SqlListDelimiter As %RawString;

/// specifies the representation to be used for a list.
Property SqlListType As %RawString;

/// Storable
Property Storable As %Boolean;

/// In the case of a persistent class, specifies that the property is not stored in the database.
Property Transient As %Boolean;

/// Specifies the name of the class associated with the property, which can be a data type class, a persistent class, or an embeddable serial class.
Property Type As %Dictionary.Classname;

/// UDLText
Relationship UDLTexts As %Dictionary.CompiledPropertyUDLText [ Cardinality = children, Inverse = parent ];

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
 i $$$comMemberDefined(name1,$$$cCLASSproperty,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSproperty,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Aliases=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPaliases),i%%isDefined("Aliases")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPaliases)
 . s i%Calculated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPcalculated),i%%isDefined("Calculated")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated)
 . s i%Cardinality=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPcardinality),i%%isDefined("Cardinality")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality)
 . s i%ClientName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPclientname),i%%isDefined("ClientName")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPclientname)
 . s i%Collection=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPcollection),i%%isDefined("Collection")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcollection)
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcompilergenerated)
 . s i%ComputeDependency=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPcomputedependency),i%%isDefined("ComputeDependency")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcomputedependency)
 . s i%ComputeTriggers=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPcomputetriggers),i%%isDefined("ComputeTriggers")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcomputetriggers)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPdescription)
 . s i%DirectRefOnGet=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPdirectrefonget),i%%isDefined("DirectRefOnGet")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPdirectrefonget)
 . s i%DirectRefOnSet=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPdirectrefonset),i%%isDefined("DirectRefOnSet")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPdirectrefonset)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPfinal)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPid)
 . s i%Identity=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPidentity),i%%isDefined("Identity")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPidentity)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinheritedid)
 . s i%InitialExpression=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression),i%%isDefined("InitialExpression")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinternal)
 . s i%Inverse=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPinverse),i%%isDefined("Inverse")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinverse)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPkeywordmodified)
 . s i%MultiDimensional=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional),i%%isDefined("MultiDimensional")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional)
 . s i%NoModBit=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit),i%%isDefined("NoModBit")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable)
 . s i%OnDelete=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPondelete),i%%isDefined("OnDelete")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPondelete)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPorigin)
 . s i%Private=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPprivate),i%%isDefined("Private")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPprivate)
 . s i%ReadOnly=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPreadonly),i%%isDefined("ReadOnly")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly)
 . s i%Relationship=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPrelationship),i%%isDefined("Relationship")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship)
 . s i%Required=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPrequired),i%%isDefined("Required")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPrequired)
 . s i%RuntimeType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPruntimetype),i%%isDefined("RuntimeType")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPruntimetype)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber)
 . s i%ServerOnly=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPserveronly),i%%isDefined("ServerOnly")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly)
 . s i%SqlCollation=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation),i%%isDefined("SqlCollation")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation)
 . s i%SqlColumnNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber),i%%isDefined("SqlColumnNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber)
 . s i%SqlComputeCode=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode),i%%isDefined("SqlComputeCode")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode)
 . s i%SqlComputed=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed),i%%isDefined("SqlComputed")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed)
 . s i%SqlComputeOnChange=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange),i%%isDefined("SqlComputeOnChange")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange)
 . s i%SqlFieldName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname),i%%isDefined("SqlFieldName")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname)
 . s i%SqlListDelimiter=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter),i%%isDefined("SqlListDelimiter")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter)
 . s i%SqlListType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype),i%%isDefined("SqlListType")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype)
 . s i%Storable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPstorable),i%%isDefined("Storable")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPstorable)
 . s i%Transient=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPtransient),i%%isDefined("Transient")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPtransient)
 . s i%Type=$$$comMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPtype),i%%isDefined("Type")=$$$comMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPtype)
 . s sub="" f  s sub=$$$comSubMemberNext(name1,$$$cCLASSproperty,name2,$$$cPROPparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$comMemberArrayGet(name1,$$$cCLASSproperty,name2,$$$cPROPparameter,sub),sub)
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

Method AliasesSet(value As %String = "") As %Status
{
 set i%Aliases=value,i%%isDefined("Aliases")=1 quit $$$OK
}

Method AliasesReset()
{
 set i%Aliases="" set i%%isDefined("Aliases")=0 quit
}

Method AliasesIsDefined() As %Boolean
{
 quit ''i%%isDefined("Aliases")
}

Method CalculatedSet(value As %String = "") As %Status
{
 set i%Calculated=value,i%%isDefined("Calculated")=1 quit $$$OK
}

Method CalculatedReset()
{
 set i%Calculated=0 set i%%isDefined("Calculated")=0 quit
}

Method CalculatedIsDefined() As %Boolean
{
 quit ''i%%isDefined("Calculated")
}

Method CardinalitySet(value As %String = "") As %Status
{
 set i%Cardinality=value,i%%isDefined("Cardinality")=1 quit $$$OK
}

Method CardinalityReset()
{
 set i%Cardinality="" set i%%isDefined("Cardinality")=0 quit
}

Method CardinalityIsDefined() As %Boolean
{
 quit ''i%%isDefined("Cardinality")
}

Method ClientNameSet(value As %String = "") As %Status
{
 set i%ClientName=value,i%%isDefined("ClientName")=1 quit $$$OK
}

Method ClientNameReset()
{
 set i%ClientName="" set i%%isDefined("ClientName")=0 quit
}

Method ClientNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("ClientName")
}

Method CollectionSet(value As %String = "") As %Status
{
 set i%Collection=value,i%%isDefined("Collection")=1 quit $$$OK
}

Method CollectionReset()
{
 set i%Collection="" set i%%isDefined("Collection")=0 quit
}

Method CollectionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Collection")
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

Method IdentitySet(value As %String = "") As %Status
{
 set i%Identity=value,i%%isDefined("Identity")=1 quit $$$OK
}

Method IdentityReset()
{
 set i%Identity=0 set i%%isDefined("Identity")=0 quit
}

Method IdentityIsDefined() As %Boolean
{
 quit ''i%%isDefined("Identity")
}

Method InitialExpressionSet(value As %String = "") As %Status
{
 set i%InitialExpression=value,i%%isDefined("InitialExpression")=1 quit $$$OK
}

Method InitialExpressionReset()
{
 set i%InitialExpression="""""" set i%%isDefined("InitialExpression")=0 quit
}

Method InitialExpressionIsDefined() As %Boolean
{
 quit ''i%%isDefined("InitialExpression")
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

Method InverseSet(value As %String = "") As %Status
{
 set i%Inverse=value,i%%isDefined("Inverse")=1 quit $$$OK
}

Method InverseReset()
{
 set i%Inverse="" set i%%isDefined("Inverse")=0 quit
}

Method InverseIsDefined() As %Boolean
{
 quit ''i%%isDefined("Inverse")
}

Method MultiDimensionalSet(value As %String = "") As %Status
{
 set i%MultiDimensional=value,i%%isDefined("MultiDimensional")=1 quit $$$OK
}

Method MultiDimensionalReset()
{
 set i%MultiDimensional=0 set i%%isDefined("MultiDimensional")=0 quit
}

Method MultiDimensionalIsDefined() As %Boolean
{
 quit ''i%%isDefined("MultiDimensional")
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

Method NoModBitSet(value As %String = "") As %Status
{
 set i%NoModBit=value,i%%isDefined("NoModBit")=1 quit $$$OK
}

Method NoModBitReset()
{
 set i%NoModBit=0 set i%%isDefined("NoModBit")=0 quit
}

Method NoModBitIsDefined() As %Boolean
{
 quit ''i%%isDefined("NoModBit")
}

Method NotInheritableSet(value As %String = "") As %Status
{
 set i%NotInheritable=value,i%%isDefined("NotInheritable")=1 quit $$$OK
}

Method NotInheritableReset()
{
 set i%NotInheritable=0 set i%%isDefined("NotInheritable")=0 quit
}

Method NotInheritableIsDefined() As %Boolean
{
 quit ''i%%isDefined("NotInheritable")
}

Method OnDeleteSet(value As %String = "") As %Status
{
 set i%OnDelete=value,i%%isDefined("OnDelete")=1 quit $$$OK
}

Method OnDeleteReset()
{
 set i%OnDelete="" set i%%isDefined("OnDelete")=0 quit
}

Method OnDeleteIsDefined() As %Boolean
{
 quit ''i%%isDefined("OnDelete")
}

Method PrivateSet(value As %String = "") As %Status
{
 set i%Private=value,i%%isDefined("Private")=1 quit $$$OK
}

Method PrivateReset()
{
 set i%Private=0 set i%%isDefined("Private")=0 quit
}

Method PrivateIsDefined() As %Boolean
{
 quit ''i%%isDefined("Private")
}

Method ReadOnlySet(value As %String = "") As %Status
{
 set i%ReadOnly=value,i%%isDefined("ReadOnly")=1 quit $$$OK
}

Method ReadOnlyReset()
{
 set i%ReadOnly=0 set i%%isDefined("ReadOnly")=0 quit
}

Method ReadOnlyIsDefined() As %Boolean
{
 quit ''i%%isDefined("ReadOnly")
}

Method RelationshipSet(value As %String = "") As %Status
{
 set i%Relationship=value,i%%isDefined("Relationship")=1 quit $$$OK
}

Method RelationshipReset()
{
 set i%Relationship=0 set i%%isDefined("Relationship")=0 quit
}

Method RelationshipIsDefined() As %Boolean
{
 quit ''i%%isDefined("Relationship")
}

Method RequiredSet(value As %String = "") As %Status
{
 set i%Required=value,i%%isDefined("Required")=1 quit $$$OK
}

Method RequiredReset()
{
 set i%Required=0 set i%%isDefined("Required")=0 quit
}

Method RequiredIsDefined() As %Boolean
{
 quit ''i%%isDefined("Required")
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

Method ServerOnlySet(value As %String = "") As %Status
{
 set i%ServerOnly=value,i%%isDefined("ServerOnly")=1 quit $$$OK
}

Method ServerOnlyReset()
{
 set i%ServerOnly="" set i%%isDefined("ServerOnly")=0 quit
}

Method ServerOnlyIsDefined() As %Boolean
{
 quit ''i%%isDefined("ServerOnly")
}

Method SqlCollationSet(value As %String = "") As %Status
{
 set i%SqlCollation=value,i%%isDefined("SqlCollation")=1 quit $$$OK
}

Method SqlCollationReset()
{
 set i%SqlCollation="" set i%%isDefined("SqlCollation")=0 quit
}

Method SqlCollationIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlCollation")
}

Method SqlColumnNumberSet(value As %String = "") As %Status
{
 set i%SqlColumnNumber=value,i%%isDefined("SqlColumnNumber")=1 quit $$$OK
}

Method SqlColumnNumberReset()
{
 set i%SqlColumnNumber="" set i%%isDefined("SqlColumnNumber")=0 quit
}

Method SqlColumnNumberIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlColumnNumber")
}

Method SqlComputeCodeSet(value As %String = "") As %Status
{
 set i%SqlComputeCode=value,i%%isDefined("SqlComputeCode")=1 quit $$$OK
}

Method SqlComputeCodeReset()
{
 set i%SqlComputeCode="" set i%%isDefined("SqlComputeCode")=0 quit
}

Method SqlComputeCodeIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlComputeCode")
}

Method SqlComputedSet(value As %String = "") As %Status
{
 set i%SqlComputed=value,i%%isDefined("SqlComputed")=1 quit $$$OK
}

Method SqlComputedReset()
{
 set i%SqlComputed=0 set i%%isDefined("SqlComputed")=0 quit
}

Method SqlComputedIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlComputed")
}

Method SqlComputeOnChangeSet(value As %String = "") As %Status
{
 set i%SqlComputeOnChange=value,i%%isDefined("SqlComputeOnChange")=1 quit $$$OK
}

Method SqlComputeOnChangeReset()
{
 set i%SqlComputeOnChange="" set i%%isDefined("SqlComputeOnChange")=0 quit
}

Method SqlComputeOnChangeIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlComputeOnChange")
}

Method SqlFieldNameSet(value As %String = "") As %Status
{
 set i%SqlFieldName=value,i%%isDefined("SqlFieldName")=1 quit $$$OK
}

Method SqlFieldNameReset()
{
 set i%SqlFieldName="" set i%%isDefined("SqlFieldName")=0 quit
}

Method SqlFieldNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlFieldName")
}

Method SqlListDelimiterSet(value As %String = "") As %Status
{
 set i%SqlListDelimiter=value,i%%isDefined("SqlListDelimiter")=1 quit $$$OK
}

Method SqlListDelimiterReset()
{
 set i%SqlListDelimiter="" set i%%isDefined("SqlListDelimiter")=0 quit
}

Method SqlListDelimiterIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlListDelimiter")
}

Method SqlListTypeSet(value As %String = "") As %Status
{
 set i%SqlListType=value,i%%isDefined("SqlListType")=1 quit $$$OK
}

Method SqlListTypeReset()
{
 set i%SqlListType="" set i%%isDefined("SqlListType")=0 quit
}

Method SqlListTypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlListType")
}

Method TransientSet(value As %String = "") As %Status
{
 set i%Transient=value,i%%isDefined("Transient")=1 quit $$$OK
}

Method TransientReset()
{
 set i%Transient=0 set i%%isDefined("Transient")=0 quit
}

Method TransientIsDefined() As %Boolean
{
 quit ''i%%isDefined("Transient")
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
<Data name="Aliases">
<RetrievalCode> s {Aliases}=$s($d(^oddCOM({L1},"a",{L3},58))#2:^(58),$d(^oddCOM($g(^(2),{L1}),"a",{L3},58))#2:^(58),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},58))#2:^(58),1:""))
</RetrievalCode>
</Data>
<Data name="Calculated">
<RetrievalCode> s {Calculated}=$s($d(^oddCOM({L1},"a",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"a",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},23))#2:^(23),1:0))
</RetrievalCode>
</Data>
<Data name="Cardinality">
<RetrievalCode> s {Cardinality}=$s($d(^oddCOM({L1},"a",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"a",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="ClientName">
<RetrievalCode> s {ClientName}=$s($d(^oddCOM({L1},"a",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"a",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Data name="Collection">
<RetrievalCode> s {Collection}=$s($d(^oddCOM({L1},"a",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"a",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"a",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"a",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="ComputeDependency">
<RetrievalCode> s {ComputeDependency}=$s($d(^oddCOM({L1},"a",{L3},54))#2:^(54),$d(^oddCOM($g(^(2),{L1}),"a",{L3},54))#2:^(54),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},54))#2:^(54),1:""))
</RetrievalCode>
</Data>
<Data name="ComputeTriggers">
<RetrievalCode> s {ComputeTriggers}=$s($d(^oddCOM({L1},"a",{L3},55))#2:^(55),$d(^oddCOM($g(^(2),{L1}),"a",{L3},55))#2:^(55),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},55))#2:^(55),1:""))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"a",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"a",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"a",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"a",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="DirectRefOnGet">
<RetrievalCode> s {DirectRefOnGet}=$s($d(^oddCOM({L1},"a",{L3},29))#2:^(29),$d(^oddCOM($g(^(2),{L1}),"a",{L3},29))#2:^(29),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},29))#2:^(29),1:0))
</RetrievalCode>
</Data>
<Data name="DirectRefOnSet">
<RetrievalCode> s {DirectRefOnSet}=$s($d(^oddCOM({L1},"a",{L3},30))#2:^(30),$d(^oddCOM($g(^(2),{L1}),"a",{L3},30))#2:^(30),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},30))#2:^(30),1:0))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"a",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"a",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"a",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"a",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"a",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"a",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="InitialExpression">
<RetrievalCode> s {InitialExpression}=$s($d(^oddCOM({L1},"a",{L3},31))#2:^(31),$d(^oddCOM($g(^(2),{L1}),"a",{L3},31))#2:^(31),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},31))#2:^(31),1:""""""))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"a",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"a",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="Inverse">
<RetrievalCode> s {Inverse}=$s($d(^oddCOM({L1},"a",{L3},32))#2:^(32),$d(^oddCOM($g(^(2),{L1}),"a",{L3},32))#2:^(32),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},32))#2:^(32),1:""))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"a",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"a",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"a",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"a",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="MultiDimensional">
<RetrievalCode> s {MultiDimensional}=$s($d(^oddCOM({L1},"a",{L3},33))#2:^(33),$d(^oddCOM($g(^(2),{L1}),"a",{L3},33))#2:^(33),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},33))#2:^(33),1:0))
</RetrievalCode>
</Data>
<Data name="NoModBit">
<RetrievalCode> s {NoModBit}=$s($d(^oddCOM({L1},"a",{L3},53))#2:^(53),$d(^oddCOM($g(^(2),{L1}),"a",{L3},53))#2:^(53),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},53))#2:^(53),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"a",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"a",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="OnDelete">
<RetrievalCode> s {OnDelete}=$s($d(^oddCOM({L1},"a",{L3},59))#2:^(59),$d(^oddCOM($g(^(2),{L1}),"a",{L3},59))#2:^(59),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},59))#2:^(59),1:""))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"a",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"a",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddCOM({L1},"a",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$s($d(^oddCOM({L1},"a",{L3},"P",sub))#2:^(sub),$d(^oddCOM($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},"P",sub))#2:^(sub),1:$g(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},"P",sub)))))
</RetrievalCode>
</Data>
<Data name="Private">
<RetrievalCode> s {Private}=$s($d(^oddCOM({L1},"a",{L3},35))#2:^(35),$d(^oddCOM($g(^(2),{L1}),"a",{L3},35))#2:^(35),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},35))#2:^(35),1:0))
</RetrievalCode>
</Data>
<Data name="ReadOnly">
<RetrievalCode> s {ReadOnly}=$s($d(^oddCOM({L1},"a",{L3},52))#2:^(52),$d(^oddCOM($g(^(2),{L1}),"a",{L3},52))#2:^(52),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},52))#2:^(52),1:0))
</RetrievalCode>
</Data>
<Data name="Relationship">
<RetrievalCode> s {Relationship}=$s($d(^oddCOM({L1},"a",{L3},36))#2:^(36),$d(^oddCOM($g(^(2),{L1}),"a",{L3},36))#2:^(36),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},36))#2:^(36),1:0))
</RetrievalCode>
</Data>
<Data name="Required">
<RetrievalCode> s {Required}=$s($d(^oddCOM({L1},"a",{L3},37))#2:^(37),$d(^oddCOM($g(^(2),{L1}),"a",{L3},37))#2:^(37),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},37))#2:^(37),1:0))
</RetrievalCode>
</Data>
<Data name="RuntimeType">
<RetrievalCode> s {RuntimeType}=$s($d(^oddCOM({L1},"a",{L3},40))#2:^(40),$d(^oddCOM($g(^(2),{L1}),"a",{L3},40))#2:^(40),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},40))#2:^(40),1:""))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"a",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"a",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="ServerOnly">
<RetrievalCode> s {ServerOnly}=$s($d(^oddCOM({L1},"a",{L3},57))#2:^(57),$d(^oddCOM($g(^(2),{L1}),"a",{L3},57))#2:^(57),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},57))#2:^(57),1:""))
</RetrievalCode>
</Data>
<Data name="SqlCollation">
<RetrievalCode> s {SqlCollation}=$s($d(^oddCOM({L1},"a",{L3},42))#2:^(42),$d(^oddCOM($g(^(2),{L1}),"a",{L3},42))#2:^(42),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},42))#2:^(42),1:""))
</RetrievalCode>
</Data>
<Data name="SqlColumnNumber">
<RetrievalCode> s {SqlColumnNumber}=$s($d(^oddCOM({L1},"a",{L3},43))#2:^(43),$d(^oddCOM($g(^(2),{L1}),"a",{L3},43))#2:^(43),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},43))#2:^(43),1:""))
</RetrievalCode>
</Data>
<Data name="SqlComputeCode">
<RetrievalCode> s {SqlComputeCode}=$s($d(^oddCOM({L1},"a",{L3},44))#2:^(44),$d(^oddCOM($g(^(2),{L1}),"a",{L3},44))#2:^(44),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},44))#2:^(44),1:""))
</RetrievalCode>
</Data>
<Data name="SqlComputeOnChange">
<RetrievalCode> s {SqlComputeOnChange}=$s($d(^oddCOM({L1},"a",{L3},46))#2:^(46),$d(^oddCOM($g(^(2),{L1}),"a",{L3},46))#2:^(46),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},46))#2:^(46),1:""))
</RetrievalCode>
</Data>
<Data name="SqlComputed">
<RetrievalCode> s {SqlComputed}=$s($d(^oddCOM({L1},"a",{L3},45))#2:^(45),$d(^oddCOM($g(^(2),{L1}),"a",{L3},45))#2:^(45),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},45))#2:^(45),1:0))
</RetrievalCode>
</Data>
<Data name="SqlFieldName">
<RetrievalCode> s {SqlFieldName}=$s($d(^oddCOM({L1},"a",{L3},47))#2:^(47),$d(^oddCOM($g(^(2),{L1}),"a",{L3},47))#2:^(47),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},47))#2:^(47),1:""))
</RetrievalCode>
</Data>
<Data name="SqlListDelimiter">
<RetrievalCode> s {SqlListDelimiter}=$s($d(^oddCOM({L1},"a",{L3},48))#2:^(48),$d(^oddCOM($g(^(2),{L1}),"a",{L3},48))#2:^(48),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},48))#2:^(48),1:""))
</RetrievalCode>
</Data>
<Data name="SqlListType">
<RetrievalCode> s {SqlListType}=$s($d(^oddCOM({L1},"a",{L3},49))#2:^(49),$d(^oddCOM($g(^(2),{L1}),"a",{L3},49))#2:^(49),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},49))#2:^(49),1:""))
</RetrievalCode>
</Data>
<Data name="Storable">
<RetrievalCode> s {Storable}=$s($d(^oddCOM({L1},"a",{L3},50))#2:^(50),$d(^oddCOM($g(^(2),{L1}),"a",{L3},50))#2:^(50),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},50))#2:^(50),1:0))
</RetrievalCode>
</Data>
<Data name="Transient">
<RetrievalCode> s {Transient}=$s($d(^oddCOM({L1},"a",{L3},51))#2:^(51),$d(^oddCOM($g(^(2),{L1}),"a",{L3},51))#2:^(51),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},51))#2:^(51),1:0))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddCOM({L1},"a",{L3},5))#2:^(5),$d(^oddCOM($g(^(2),{L1}),"a",{L3},5))#2:^(5),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},5))#2:^(5),1:""))
</RetrievalCode>
</Data>
<Data name="_Identity">
<RetrievalCode> s {_Identity}=$s($d(^oddCOM({L1},"a",{L3},56))#2:^(56),$d(^oddCOM($g(^(2),{L1}),"a",{L3},56))#2:^(56),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},2),{L1}),"a",{L3},56))#2:^(56),1:0))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"a"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledProperty.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledPropertyS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
