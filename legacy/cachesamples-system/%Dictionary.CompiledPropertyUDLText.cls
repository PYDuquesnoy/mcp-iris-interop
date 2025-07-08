/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledPropertyUDLText Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledProperty [ Cardinality = parent, Inverse = UDLTexts ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Category
Property Category As %RawString;

/// Holds the content of the UDL text.
Property Content As %Stream.TmpCharacter;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Speficies the COS name of the UDL text.
Property Name As %Dictionary.Identifier [ Required ];

/// Position
Property Position As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// TextType
Property TextType As %Integer;

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
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 i (name1="")||(name2="")||(name3="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$comSubMemberDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||(name3="")||('$$$comSubMemberDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%Category=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTcategory),i%%isDefined("Category")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTcategory)
 . s i%KeywordError=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTkeyworderror),i%%isDefined("KeywordError")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTkeyworderror)
 . s i%KeywordModified=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTkeywordmodified),i%%isDefined("KeywordModified")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTkeywordmodified)
 . s i%Position=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTposition),i%%isDefined("Position")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTposition)
 . s i%SequenceNumber=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTsequencenumber),i%%isDefined("SequenceNumber")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTsequencenumber)
 . s i%TextType=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTtexttype),i%%isDefined("TextType")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTtexttype)
 . s i%Content=""
 . f ptr=1:1:$$$comSubMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTcontent) d
 . . d ..Content.WriteLine($$$comSubMemberArrayGet(name1,$$$cCLASSproperty,name2,$$$cPROPudltext,name3,$$$cUDLTEXTcontent,ptr))
 . d ..Content.Rewind()
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

Method CategorySet(value As %String = "") As %Status
{
 set i%Category=value,i%%isDefined("Category")=1 quit $$$OK
}

Method CategoryReset()
{
 set i%Category="comment" set i%%isDefined("Category")=0 quit
}

Method CategoryIsDefined() As %Boolean
{
 quit ''i%%isDefined("Category")
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

Method PositionSet(value As %String = "") As %Status
{
 set i%Position=value,i%%isDefined("Position")=1 quit $$$OK
}

Method PositionReset()
{
 set i%Position="body" set i%%isDefined("Position")=0 quit
}

Method PositionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Position")
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

Method TextTypeSet(value As %String = "") As %Status
{
 set i%TextType=value,i%%isDefined("TextType")=1 quit $$$OK
}

Method TextTypeReset()
{
 set i%TextType=0 set i%%isDefined("TextType")=0 quit
}

Method TextTypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("TextType")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Category">
<RetrievalCode> s {Category}=$s($d(^oddCOM({L1},"a",{L3},"u",{L5},23))#2:^(23),$d(^oddCOM($g(^(2),"*"),"u",{L5},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"u",{L5},2),"*"),"u",{L5},23))#2:^(23),1:"comment"))
</RetrievalCode>
</Data>
<Data name="Content">
<RetrievalCode> s {Content}=""
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"a",{L3},"u",{L5},12))#2:^(12),$d(^oddCOM($g(^(2),"*"),"u",{L5},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"u",{L5},2),"*"),"u",{L5},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"a",{L3},"u",{L5},13))#2:^(13),$d(^oddCOM($g(^(2),"*"),"u",{L5},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"u",{L5},2),"*"),"u",{L5},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="Position">
<RetrievalCode> s {Position}=$s($d(^oddCOM({L1},"a",{L3},"u",{L5},24))#2:^(24),$d(^oddCOM($g(^(2),"*"),"u",{L5},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"u",{L5},2),"*"),"u",{L5},24))#2:^(24),1:"body"))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"a",{L3},"u",{L5},11))#2:^(11),$d(^oddCOM($g(^(2),"*"),"u",{L5},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"u",{L5},2),"*"),"u",{L5},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="TextType">
<RetrievalCode> s {TextType}=$s($d(^oddCOM({L1},"a",{L3},"u",{L5},22))#2:^(22),$d(^oddCOM($g(^(2),"*"),"u",{L5},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"u",{L5},2),"*"),"u",{L5},22))#2:^(22),1:0))
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
<Subscript name="4">
<Expression>"u"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledPropertyUDLText.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledPro3DD9S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
