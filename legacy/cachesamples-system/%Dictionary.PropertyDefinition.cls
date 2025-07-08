/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.PropertyDefinition Extends (%Persistent, %Dictionary.PropertyDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = Properties ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// List of aliases for this property.
Property Aliases As %RawString;

/// Specifies that the property has no in-memory storage allocated for it when the object containing it is instantiated.
Property Calculated As %Boolean [ InitialExpression = 0 ];

/// Specifies the cardinality of a relationship property. The Cardinality keyword is required for relationship properties. It is ignored by non-relationship properties. 
Property Cardinality As %RawString;

/// An alias used by client projections of this property.
Property ClientName As %RawString;

/// Specifies that a property is a collection property as well as what type of collection it is.
Property Collection As %RawString;

/// True if this property is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the property.
Property Description As %RawString;

/// Specifies that subclasses cannot override the definition of this property.
Property Final As %Boolean [ InitialExpression = 0 ];

/// Specifies that this property is the identity for this class. Identity properties can be set in new objects only and the default is set by incrementing a counter.
Property Identity As %Boolean [ InitialExpression = 0, SqlFieldName = _Identity ];

/// Specifies an initial value for the property.
Property InitialExpression As %RawString [ InitialExpression = """""" ];

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// Specifies the name of the inverse side of a relationship. That is, the name of the corresponding relationship property in the related class. The inverse property must exist in the related class and have the correct Cardinality value. The Inverse keyword is required for relationship properties. It is ignored by non-relationship properties.
Property Inverse As %RawString;

/// Specifies that an attribute has the characteristics of a multidimensional array.
Property MultiDimensional As %Boolean [ InitialExpression = 0 ];

/// The name of the property.
Property Name As %Dictionary.Identifier [ Required ];

/// Deprecated.
Property NoModBit As %Boolean [ InitialExpression = 0 ];

/// Deprecated.
Property NotInheritable As %Boolean [ InitialExpression = 0 ];

/// Specifies what referential action to take when the key value is deleted from the foreign table.
Property OnDelete As %RawString;

/// Parameter
Property Parameters As array Of %RawString;

/// Specifies that the property is private. Private properties can only be used by instance methods of this class or its subclasses.
Property Private As %Boolean [ InitialExpression = 0 ];

/// Specifies that the property is readonly.
Property ReadOnly As %Boolean [ InitialExpression = 0 ];

/// Specifies that a property is a relationship property. 
Property Relationship As %Boolean [ InitialExpression = 0 ];

/// In the case of a persistent class, specifies that the value of the property must be given a value before it can be stored to disk.
Property Required As %Boolean [ InitialExpression = 0 ];

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// Specifies that a property will not be projected to a Java or C++ client.
Property ServerOnly As %RawString;

/// Deprecated.
Property SqlCollation As %RawString;

/// Explicitly sets the SQL Column number for this property. This is provided for legacy application support.
Property SqlColumnNumber As %RawString;

/// Specifies ObjectScript code that evaluates to a computed field value. 
Property SqlComputeCode As %RawString;

/// Specifies that this property is an SQL computed field.
Property SqlComputed As %Boolean [ InitialExpression = 0 ];

/// Specifies one or more properties whose modification triggers the recalculation of this computed field within SQL.
Property SqlComputeOnChange As %RawString;

/// In the case of a persistent class, specifies the column name used to identify the property in its SQL projection. By default, the SQL column name is the same as the property name.
Property SqlFieldName As %RawString;

/// Specifies the delimiter character used within SQL for lists. This is provided for legacy application support.
Property SqlListDelimiter As %RawString;

/// specifies the representation to be used for a list.
Property SqlListType As %RawString;

/// In the case of a persistent class, specifies that the property is not stored in the database.
Property Transient As %Boolean [ InitialExpression = 0 ];

/// Specifies the name of the class associated with the property, which can be a data type class, a persistent class, or an embeddable serial class.
Property Type As %Dictionary.Classname;

/// UDLText
Relationship UDLTexts As %Dictionary.PropertyUDLTextDefinition [ Cardinality = children, Inverse = parent ];

ClassMethod CardinalityIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="one" q $$$OK
 i val="many" q $$$OK
 i val="parent" q $$$OK
 i val="children" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.PropertyDefinition:Cardinality",val)
}

ClassMethod CollectionIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="array" q $$$OK
 i val="list" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.PropertyDefinition:Collection",val)
}

ClassMethod OnDeleteIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="cascade" q $$$OK
 i val="noaction" q $$$OK
 i val="setdefault" q $$$OK
 i val="setnull" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.PropertyDefinition:OnDelete",val)
}

ClassMethod ServerOnlyIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="0" q $$$OK
 i val="1" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.PropertyDefinition:ServerOnly",val)
}

ClassMethod SqlCollationIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="ALPHAUP" q $$$OK
 i val="PLUS" q $$$OK
 i val="MINUS" q $$$OK
 i val="SPACE" q $$$OK
 i val="EXACT" q $$$OK
 i val="UPPER" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.PropertyDefinition:SqlCollation",val)
}

ClassMethod SqlListTypeIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="DELIMITED" q $$$OK
 i val="LIST" q $$$OK
 i val="SUBNODE" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.PropertyDefinition:SqlListType",val)
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
 s i%%isDefined("Aliases")=0
 s i%%isDefined("Calculated")=0
 s i%%isDefined("Cardinality")=0
 s i%%isDefined("ClientName")=0
 s i%%isDefined("Collection")=0
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("Final")=0
 s i%%isDefined("Identity")=0
 s i%%isDefined("InitialExpression")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("Inverse")=0
 s i%%isDefined("MultiDimensional")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("NoModBit")=0
 s i%%isDefined("NotInheritable")=0
 s i%%isDefined("OnDelete")=0
 s i%%isDefined("Private")=0
 s i%%isDefined("ReadOnly")=0
 s i%%isDefined("Relationship")=0
 s i%%isDefined("Required")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("ServerOnly")=0
 s i%%isDefined("SqlCollation")=0
 s i%%isDefined("SqlColumnNumber")=0
 s i%%isDefined("SqlComputeCode")=0
 s i%%isDefined("SqlComputed")=0
 s i%%isDefined("SqlComputeOnChange")=0
 s i%%isDefined("SqlFieldName")=0
 s i%%isDefined("SqlListDelimiter")=0
 s i%%isDefined("SqlListType")=0
 s i%%isDefined("Transient")=0
 s i%%isDefined("Type")=0
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
 i $$$defMemberDefined(name1,$$$cCLASSproperty,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSproperty,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Aliases=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPaliases),i%%isDefined("Aliases")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPaliases)
 . s i%Calculated=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated),i%%isDefined("Calculated")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated)
 . s i%Cardinality=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality),i%%isDefined("Cardinality")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality)
 . s i%ClientName=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPclientname),i%%isDefined("ClientName")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPclientname)
 . s i%Collection=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPcollection),i%%isDefined("Collection")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPcollection)
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPdescription)
 . s i%Final=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPfinal),i%%isDefined("Final")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPfinal)
 . s i%Identity=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPidentity),i%%isDefined("Identity")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPidentity)
 . s i%InitialExpression=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression),i%%isDefined("InitialExpression")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinternal)
 . s i%Inverse=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPinverse),i%%isDefined("Inverse")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPinverse)
 . s i%MultiDimensional=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional),i%%isDefined("MultiDimensional")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional)
 . s i%NoModBit=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit),i%%isDefined("NoModBit")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit)
 . s i%NotInheritable=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable),i%%isDefined("NotInheritable")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable)
 . s i%OnDelete=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPondelete),i%%isDefined("OnDelete")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPondelete)
 . s i%Private=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPprivate),i%%isDefined("Private")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPprivate)
 . s i%ReadOnly=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly),i%%isDefined("ReadOnly")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly)
 . s i%Relationship=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship),i%%isDefined("Relationship")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship)
 . s i%Required=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPrequired),i%%isDefined("Required")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPrequired)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber)
 . s i%ServerOnly=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly),i%%isDefined("ServerOnly")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly)
 . s i%SqlCollation=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation),i%%isDefined("SqlCollation")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation)
 . s i%SqlColumnNumber=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber),i%%isDefined("SqlColumnNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber)
 . s i%SqlComputeCode=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode),i%%isDefined("SqlComputeCode")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode)
 . s i%SqlComputed=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed),i%%isDefined("SqlComputed")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed)
 . s i%SqlComputeOnChange=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange),i%%isDefined("SqlComputeOnChange")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange)
 . s i%SqlFieldName=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname),i%%isDefined("SqlFieldName")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname)
 . s i%SqlListDelimiter=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter),i%%isDefined("SqlListDelimiter")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter)
 . s i%SqlListType=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype),i%%isDefined("SqlListType")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype)
 . s i%Transient=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPtransient),i%%isDefined("Transient")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPtransient)
 . s i%Type=$$$defMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPtype),i%%isDefined("Type")=$$$defMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPtype)
 . s sub="" f  s sub=$$$defSubMemberNext(name1,$$$cCLASSproperty,name2,$$$cPROPparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$defMemberArrayGet(name1,$$$cCLASSproperty,name2,$$$cPROPparameter,sub),sub)
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
 . i '($$$defMemberDefined(name1,$$$cCLASSproperty,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSproperty,name2,"")
 . i 'i%%isDefined("Aliases") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPaliases) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPaliases,i%Aliases) }
 . i 'i%%isDefined("Calculated") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated,i%Calculated) }
 . i 'i%%isDefined("Cardinality") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality,i%Cardinality) }
 . i 'i%%isDefined("ClientName") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPclientname) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPclientname,i%ClientName) }
 . i 'i%%isDefined("Collection") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPcollection) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPcollection,i%Collection) }
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPdescription,i%Description) }
 . i 'i%%isDefined("Final") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPfinal) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPfinal,i%Final) }
 . i 'i%%isDefined("Identity") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPidentity) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPidentity,i%Identity) }
 . i 'i%%isDefined("InitialExpression") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression,i%InitialExpression) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPinternal,i%Internal) }
 . i 'i%%isDefined("Inverse") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPinverse) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPinverse,i%Inverse) }
 . i 'i%%isDefined("MultiDimensional") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional,i%MultiDimensional) }
 . i 'i%%isDefined("NoModBit") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit,i%NoModBit) }
 . i 'i%%isDefined("NotInheritable") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable,i%NotInheritable) }
 . i 'i%%isDefined("OnDelete") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPondelete) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPondelete,i%OnDelete) }
 . i 'i%%isDefined("Private") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPprivate) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPprivate,i%Private) }
 . i 'i%%isDefined("ReadOnly") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly,i%ReadOnly) }
 . i 'i%%isDefined("Relationship") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship,i%Relationship) }
 . i 'i%%isDefined("Required") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPrequired) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPrequired,i%Required) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("ServerOnly") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly,i%ServerOnly) }
 . i 'i%%isDefined("SqlCollation") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation,i%SqlCollation) }
 . i 'i%%isDefined("SqlColumnNumber") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber,i%SqlColumnNumber) }
 . i 'i%%isDefined("SqlComputeCode") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode,i%SqlComputeCode) }
 . i 'i%%isDefined("SqlComputed") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed,i%SqlComputed) }
 . i 'i%%isDefined("SqlComputeOnChange") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange,i%SqlComputeOnChange) }
 . i 'i%%isDefined("SqlFieldName") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname,i%SqlFieldName) }
 . i 'i%%isDefined("SqlListDelimiter") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter,i%SqlListDelimiter) }
 . i 'i%%isDefined("SqlListType") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype,i%SqlListType) }
 . i 'i%%isDefined("Transient") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPtransient) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPtransient,i%Transient) }
 . i 'i%%isDefined("Type") { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPtype) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPtype,i%Type) }
 . $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSproperty,name2,$$$cPROPparameter,sub,..Parameters.GetAt(sub))
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSproperty,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.PropertyDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSproperty,name2,"")
 . i i%Aliases="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPaliases) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPaliases,i%Aliases) }
 . i i%Calculated=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPcalculated,i%Calculated) }
 . i i%Cardinality="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPcardinality,i%Cardinality) }
 . i i%ClientName="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPclientname) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPclientname,i%ClientName) }
 . i i%Collection="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPcollection) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPcollection,i%Collection) }
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPdescription,i%Description) }
 . i i%Final=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPfinal) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPfinal,i%Final) }
 . i i%Identity=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPidentity) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPidentity,i%Identity) }
 . i i%InitialExpression="""""" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPinitialexpression,i%InitialExpression) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPinternal,i%Internal) }
 . i i%Inverse="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPinverse) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPinverse,i%Inverse) }
 . i i%MultiDimensional=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPmultidimensional,i%MultiDimensional) }
 . i i%NoModBit=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPnomodbit,i%NoModBit) }
 . i i%NotInheritable=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPnotinheritable,i%NotInheritable) }
 . i i%OnDelete="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPondelete) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPondelete,i%OnDelete) }
 . i i%Private=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPprivate) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPprivate,i%Private) }
 . i i%ReadOnly=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPreadonly,i%ReadOnly) }
 . i i%Relationship=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPrelationship,i%Relationship) }
 . i i%Required=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPrequired) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPrequired,i%Required) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsequencenumber,i%SequenceNumber) }
 . i i%ServerOnly="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPserveronly,i%ServerOnly) }
 . i i%SqlCollation="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcollation,i%SqlCollation) }
 . i i%SqlColumnNumber="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcolumnnumber,i%SqlColumnNumber) }
 . i i%SqlComputeCode="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputecode,i%SqlComputeCode) }
 . i i%SqlComputed=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputed,i%SqlComputed) }
 . i i%SqlComputeOnChange="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlcomputeonchange,i%SqlComputeOnChange) }
 . i i%SqlFieldName="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqlfieldname,i%SqlFieldName) }
 . i i%SqlListDelimiter="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqllistdelimiter,i%SqlListDelimiter) }
 . i i%SqlListType="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPsqllisttype,i%SqlListType) }
 . i i%Transient=0 { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPtransient) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPtransient,i%Transient) }
 . i i%Type="" { $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPtype) } else { $$$defMemberKeySet(name1,$$$cCLASSproperty,name2,$$$cPROPtype,i%Type) }
 . $$$defMemberKeyKill(name1,$$$cCLASSproperty,name2,$$$cPROPparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSproperty,name2,$$$cPROPparameter,sub,..Parameters.GetAt(sub))
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
 If '($$$defMemberDefined(name1,$$$cCLASSproperty,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSproperty,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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
<RetrievalCode> s {Aliases}=$s($d(^oddDEF({L1},"a",{L3},58))#2:^(58),1:"")
</RetrievalCode>
</Data>
<Data name="Calculated">
<RetrievalCode> s {Calculated}=$s($d(^oddDEF({L1},"a",{L3},23))#2:^(23),1:0)
</RetrievalCode>
</Data>
<Data name="Cardinality">
<RetrievalCode> s {Cardinality}=$s($d(^oddDEF({L1},"a",{L3},24))#2:^(24),1:"")
</RetrievalCode>
</Data>
<Data name="ClientName">
<RetrievalCode> s {ClientName}=$s($d(^oddDEF({L1},"a",{L3},26))#2:^(26),1:"")
</RetrievalCode>
</Data>
<Data name="Collection">
<RetrievalCode> s {Collection}=$s($d(^oddDEF({L1},"a",{L3},27))#2:^(27),1:"")
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"a",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"a",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddDEF({L1},"a",{L3},7))#2:^(7),1:0)
</RetrievalCode>
</Data>
<Data name="InitialExpression">
<RetrievalCode> s {InitialExpression}=$s($d(^oddDEF({L1},"a",{L3},31))#2:^(31),1:"""""")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"a",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="Inverse">
<RetrievalCode> s {Inverse}=$s($d(^oddDEF({L1},"a",{L3},32))#2:^(32),1:"")
</RetrievalCode>
</Data>
<Data name="MultiDimensional">
<RetrievalCode> s {MultiDimensional}=$s($d(^oddDEF({L1},"a",{L3},33))#2:^(33),1:0)
</RetrievalCode>
</Data>
<Data name="NoModBit">
<RetrievalCode> s {NoModBit}=$s($d(^oddDEF({L1},"a",{L3},53))#2:^(53),1:0)
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddDEF({L1},"a",{L3},9))#2:^(9),1:0)
</RetrievalCode>
</Data>
<Data name="OnDelete">
<RetrievalCode> s {OnDelete}=$s($d(^oddDEF({L1},"a",{L3},59))#2:^(59),1:"")
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddDEF({L1},"a",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$g(^oddDEF({L1},"a",{L3},"P",sub))))
</RetrievalCode>
</Data>
<Data name="Private">
<RetrievalCode> s {Private}=$s($d(^oddDEF({L1},"a",{L3},35))#2:^(35),1:0)
</RetrievalCode>
</Data>
<Data name="ReadOnly">
<RetrievalCode> s {ReadOnly}=$s($d(^oddDEF({L1},"a",{L3},52))#2:^(52),1:0)
</RetrievalCode>
</Data>
<Data name="Relationship">
<RetrievalCode> s {Relationship}=$s($d(^oddDEF({L1},"a",{L3},36))#2:^(36),1:0)
</RetrievalCode>
</Data>
<Data name="Required">
<RetrievalCode> s {Required}=$s($d(^oddDEF({L1},"a",{L3},37))#2:^(37),1:0)
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"a",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="ServerOnly">
<RetrievalCode> s {ServerOnly}=$s($d(^oddDEF({L1},"a",{L3},57))#2:^(57),1:"")
</RetrievalCode>
</Data>
<Data name="SqlCollation">
<RetrievalCode> s {SqlCollation}=$s($d(^oddDEF({L1},"a",{L3},42))#2:^(42),1:"")
</RetrievalCode>
</Data>
<Data name="SqlColumnNumber">
<RetrievalCode> s {SqlColumnNumber}=$s($d(^oddDEF({L1},"a",{L3},43))#2:^(43),1:"")
</RetrievalCode>
</Data>
<Data name="SqlComputeCode">
<RetrievalCode> s {SqlComputeCode}=$s($d(^oddDEF({L1},"a",{L3},44))#2:^(44),1:"")
</RetrievalCode>
</Data>
<Data name="SqlComputeOnChange">
<RetrievalCode> s {SqlComputeOnChange}=$s($d(^oddDEF({L1},"a",{L3},46))#2:^(46),1:"")
</RetrievalCode>
</Data>
<Data name="SqlComputed">
<RetrievalCode> s {SqlComputed}=$s($d(^oddDEF({L1},"a",{L3},45))#2:^(45),1:0)
</RetrievalCode>
</Data>
<Data name="SqlFieldName">
<RetrievalCode> s {SqlFieldName}=$s($d(^oddDEF({L1},"a",{L3},47))#2:^(47),1:"")
</RetrievalCode>
</Data>
<Data name="SqlListDelimiter">
<RetrievalCode> s {SqlListDelimiter}=$s($d(^oddDEF({L1},"a",{L3},48))#2:^(48),1:"")
</RetrievalCode>
</Data>
<Data name="SqlListType">
<RetrievalCode> s {SqlListType}=$s($d(^oddDEF({L1},"a",{L3},49))#2:^(49),1:"")
</RetrievalCode>
</Data>
<Data name="Transient">
<RetrievalCode> s {Transient}=$s($d(^oddDEF({L1},"a",{L3},51))#2:^(51),1:0)
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddDEF({L1},"a",{L3},5))#2:^(5),1:"")
</RetrievalCode>
</Data>
<Data name="_Identity">
<RetrievalCode> s {_Identity}=$s($d(^oddDEF({L1},"a",{L3},56))#2:^(56),1:0)
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"a"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.PropertyDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.PropertyDef88F9S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
