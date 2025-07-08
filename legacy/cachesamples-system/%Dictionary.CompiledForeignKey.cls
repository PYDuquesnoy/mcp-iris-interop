/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledForeignKey Extends (%Persistent, %Dictionary.CompiledForeignKeyQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = ForeignKeys ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// True if this foreign key is deprecated.
Property Deprecated As %Boolean;

/// Supplies a description of the foreign key.
Property Description As %RawString;

/// Final
Property Final As %Boolean;

/// Id
Property Id As %Integer;

/// InheritedId
Property InheritedId As %Boolean;

/// If true then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Defines a name for the key. It must be a valid class member name and must not conflict with any existing member name.
Property Name As %Dictionary.Identifier [ Required ];

/// Specifies whether InterSystems IRIS should check this foreign key constraint.
Property NoCheck As %Boolean;

/// NotInheritable
Property NotInheritable As %Boolean;

/// Specifies what referential action to take when the key value is deleted from the foreign table.
Property OnDelete As %RawString;

/// Specifies what referential action to take when the key value is updated in the foreign table.
Property OnUpdate As %RawString;

/// Origin
Property Origin As %RawString;

/// Specifies one or more properties whose values are used to constrain the value of the foreign key.
Property Properties As %RawString;

/// Specifies the name of the class containing the key referred to by this foreign key definition.
Property ReferencedClass As %Dictionary.Classname;

/// Specifies the key name of a unique index within a class that provides the set of allowed values for this foreign key.
Property ReferencedKey As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Specifies an alternate name for this foreign key when referred to via SQL.
Property SqlName As %RawString;

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
 i $$$comMemberDefined(name1,$$$cCLASSfkey,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSfkey,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYcompilergenerated)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYdescription)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYfinal)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYinheritedid)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYkeywordmodified)
 . s i%NoCheck=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck),i%%isDefined("NoCheck")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYnocheck)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYnotinheritable)
 . s i%OnDelete=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYondelete),i%%isDefined("OnDelete")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYondelete)
 . s i%OnUpdate=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate),i%%isDefined("OnUpdate")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYonupdate)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYorigin)
 . s i%Properties=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYproperties),i%%isDefined("Properties")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYproperties)
 . s i%ReferencedClass=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass),i%%isDefined("ReferencedClass")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedclass)
 . s i%ReferencedKey=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey),i%%isDefined("ReferencedKey")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYreferencedkey)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYsequencenumber)
 . s i%SqlName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname),i%%isDefined("SqlName")=$$$comMemberKeyDefined(name1,$$$cCLASSfkey,name2,$$$cFKEYsqlname)
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
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"f",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"f",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"f",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"f",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"f",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"f",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"f",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"f",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},7))#2:^(7),1:1))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"f",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"f",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"f",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"f",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"f",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"f",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"f",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"f",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"f",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"f",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NoCheck">
<RetrievalCode> s {NoCheck}=$s($d(^oddCOM({L1},"f",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"f",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},27))#2:^(27),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"f",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"f",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="OnDelete">
<RetrievalCode> s {OnDelete}=$s($d(^oddCOM({L1},"f",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"f",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},21))#2:^(21),1:"noaction"))
</RetrievalCode>
</Data>
<Data name="OnUpdate">
<RetrievalCode> s {OnUpdate}=$s($d(^oddCOM({L1},"f",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"f",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},22))#2:^(22),1:"noaction"))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"f",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"f",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="Properties">
<RetrievalCode> s {Properties}=$s($d(^oddCOM({L1},"f",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"f",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Data name="ReferencedClass">
<RetrievalCode> s {ReferencedClass}=$s($d(^oddCOM({L1},"f",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"f",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="ReferencedKey">
<RetrievalCode> s {ReferencedKey}=$s($d(^oddCOM({L1},"f",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"f",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},25))#2:^(25),1:""))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"f",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"f",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddCOM({L1},"f",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"f",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"f",{L3},2),{L1}),"f",{L3},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"f"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledForeignKey.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledFor23F8S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
