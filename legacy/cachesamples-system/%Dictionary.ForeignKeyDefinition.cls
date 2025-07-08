/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.ForeignKeyDefinition Extends (%Persistent, %Dictionary.ForeignKeyDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = ForeignKeys ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// True if this foreign key is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Supplies a description of the foreign key.
Property Description As %RawString;

/// If true then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// Defines a name for the key. It must be a valid class member name and must not conflict with any existing member name.
Property Name As %Dictionary.Identifier [ Required ];

/// Specifies whether InterSystems IRIS should check this foreign key constraint.
Property NoCheck As %Boolean [ InitialExpression = 0 ];

/// Specifies what referential action to take when the key value is deleted from the foreign table.
Property OnDelete As %RawString [ InitialExpression = "noaction" ];

/// Specifies what referential action to take when the key value is updated in the foreign table.
Property OnUpdate As %RawString [ InitialExpression = "noaction" ];

/// Specifies one or more properties whose values are used to constrain the value of the foreign key.
Property Properties As %RawString;

/// Specifies the name of the class containing the key referred to by this foreign key definition.
Property ReferencedClass As %Dictionary.Classname;

/// Specifies the key name of a unique index within a class that provides the set of allowed values for this foreign key.
Property ReferencedKey As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// Specifies an alternate name for this foreign key when referred to via SQL.
Property SqlName As %RawString;

ClassMethod OnDeleteIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="cascade" q $$$OK
 i val="noaction" q $$$OK
 i val="setdefault" q $$$OK
 i val="setnull" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.ForeignKeyDefinition:OnDelete",val)
}

ClassMethod OnUpdateIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="cascade" q $$$OK
 i val="noaction" q $$$OK
 i val="setdefault" q $$$OK
 i val="setnull" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.ForeignKeyDefinition:OnUpdate",val)
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
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("NoCheck")=0
 s i%%isDefined("OnDelete")=0
 s i%%isDefined("OnUpdate")=0
 s i%%isDefined("Properties")=0
 s i%%isDefined("ReferencedClass")=0
 s i%%isDefined("ReferencedKey")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("SqlName")=0
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
 i $$$defMemberDefined(name1,$$$cCLASSfkey,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSfkey,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal)
 . s i%NoCheck=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck),i%%isDefined("NoCheck")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck)
 . s i%OnDelete=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete),i%%isDefined("OnDelete")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete)
 . s i%OnUpdate=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate),i%%isDefined("OnUpdate")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate)
 . s i%Properties=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties),i%%isDefined("Properties")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties)
 . s i%ReferencedClass=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass),i%%isDefined("ReferencedClass")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass)
 . s i%ReferencedKey=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey),i%%isDefined("ReferencedKey")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber)
 . s i%SqlName=$$$defMemberKeyGet(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname),i%%isDefined("SqlName")=$$$defMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname)
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
 . i '($$$defMemberDefined(name1,$$$cCLASSfkey,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSfkey,name2,"")
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription,i%Description) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal,i%Internal) }
 . i 'i%%isDefined("NoCheck") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck,i%NoCheck) }
 . i 'i%%isDefined("OnDelete") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete,i%OnDelete) }
 . i 'i%%isDefined("OnUpdate") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate,i%OnUpdate) }
 . i 'i%%isDefined("Properties") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties,i%Properties) }
 . i 'i%%isDefined("ReferencedClass") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass,i%ReferencedClass) }
 . i 'i%%isDefined("ReferencedKey") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey,i%ReferencedKey) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("SqlName") { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname,i%SqlName) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSfkey,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.ForeignKeyDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSfkey,name2,"")
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription,i%Description) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal,i%Internal) }
 . i i%NoCheck=0 { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck,i%NoCheck) }
 . i i%OnDelete="noaction" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete,i%OnDelete) }
 . i i%OnUpdate="noaction" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate,i%OnUpdate) }
 . i i%Properties="" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties,i%Properties) }
 . i i%ReferencedClass="" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass,i%ReferencedClass) }
 . i i%ReferencedKey="" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey,i%ReferencedKey) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber,i%SequenceNumber) }
 . i i%SqlName="" { $$$defMemberKeyKill(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname,i%SqlName) }
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
 If '($$$defMemberDefined(name1,$$$cCLASSfkey,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSfkey,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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

Method NoCheckSet(value As %String = "") As %Status
{
 set i%NoCheck=value,i%%isDefined("NoCheck")=1 quit $$$OK
}

Method NoCheckReset()
{
 set i%NoCheck=0 set i%%isDefined("NoCheck")=0 quit
}

Method NoCheckIsDefined() As %Boolean
{
 quit ''i%%isDefined("NoCheck")
}

Method OnDeleteSet(value As %String = "") As %Status
{
 set i%OnDelete=value,i%%isDefined("OnDelete")=1 quit $$$OK
}

Method OnDeleteReset()
{
 set i%OnDelete="noaction" set i%%isDefined("OnDelete")=0 quit
}

Method OnDeleteIsDefined() As %Boolean
{
 quit ''i%%isDefined("OnDelete")
}

Method OnUpdateSet(value As %String = "") As %Status
{
 set i%OnUpdate=value,i%%isDefined("OnUpdate")=1 quit $$$OK
}

Method OnUpdateReset()
{
 set i%OnUpdate="noaction" set i%%isDefined("OnUpdate")=0 quit
}

Method OnUpdateIsDefined() As %Boolean
{
 quit ''i%%isDefined("OnUpdate")
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

Method ReferencedClassSet(value As %String = "") As %Status
{
 set i%ReferencedClass=value,i%%isDefined("ReferencedClass")=1 quit $$$OK
}

Method ReferencedClassReset()
{
 set i%ReferencedClass="" set i%%isDefined("ReferencedClass")=0 quit
}

Method ReferencedClassIsDefined() As %Boolean
{
 quit ''i%%isDefined("ReferencedClass")
}

Method ReferencedKeySet(value As %String = "") As %Status
{
 set i%ReferencedKey=value,i%%isDefined("ReferencedKey")=1 quit $$$OK
}

Method ReferencedKeyReset()
{
 set i%ReferencedKey="" set i%%isDefined("ReferencedKey")=0 quit
}

Method ReferencedKeyIsDefined() As %Boolean
{
 quit ''i%%isDefined("ReferencedKey")
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

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"f",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"f",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"f",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="NoCheck">
<RetrievalCode> s {NoCheck}=$s($d(^oddDEF({L1},"f",{L3},27))#2:^(27),1:0)
</RetrievalCode>
</Data>
<Data name="OnDelete">
<RetrievalCode> s {OnDelete}=$s($d(^oddDEF({L1},"f",{L3},21))#2:^(21),1:"noaction")
</RetrievalCode>
</Data>
<Data name="OnUpdate">
<RetrievalCode> s {OnUpdate}=$s($d(^oddDEF({L1},"f",{L3},22))#2:^(22),1:"noaction")
</RetrievalCode>
</Data>
<Data name="Properties">
<RetrievalCode> s {Properties}=$s($d(^oddDEF({L1},"f",{L3},23))#2:^(23),1:"")
</RetrievalCode>
</Data>
<Data name="ReferencedClass">
<RetrievalCode> s {ReferencedClass}=$s($d(^oddDEF({L1},"f",{L3},24))#2:^(24),1:"")
</RetrievalCode>
</Data>
<Data name="ReferencedKey">
<RetrievalCode> s {ReferencedKey}=$s($d(^oddDEF({L1},"f",{L3},25))#2:^(25),1:"")
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"f",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddDEF({L1},"f",{L3},26))#2:^(26),1:"")
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"f"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.ForeignKeyDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.ForeignKeyDD81DS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
