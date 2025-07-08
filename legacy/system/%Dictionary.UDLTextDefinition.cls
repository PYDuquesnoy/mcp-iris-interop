/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.UDLTextDefinition Extends (%Persistent, %Dictionary.UDLTextDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = UDLTexts ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Category
Property Category As %RawString [ InitialExpression = "comment" ];

/// Holds the content of the UDL text.
Property Content As %Stream.TmpCharacter;

/// Speficies the COS name of the UDL text.
Property Name As %Dictionary.Identifier [ Required ];

/// Position
Property Position As %RawString [ InitialExpression = "body" ];

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// TextType
Property TextType As %Integer [ InitialExpression = 0 ];

ClassMethod CategoryIsValid(val As %String) As %Status
{
 i val="comment" q $$$OK
 i val="error" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.UDLTextDefinition:Category",val)
}

ClassMethod PositionIsValid(val As %String) As %Status
{
 i val="body" q $$$OK
 i val="header" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.UDLTextDefinition:Position",val)
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
 s i%%isDefined("Category")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("Position")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("TextType")=0
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
 i $$$defMemberDefined(name1,$$$cCLASSudltext,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSudltext,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Category=$$$defMemberKeyGet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcategory),i%%isDefined("Category")=$$$defMemberKeyDefined(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcategory)
 . s i%Position=$$$defMemberKeyGet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTposition),i%%isDefined("Position")=$$$defMemberKeyDefined(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTposition)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTsequencenumber)
 . s i%TextType=$$$defMemberKeyGet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTtexttype),i%%isDefined("TextType")=$$$defMemberKeyDefined(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTtexttype)
 . s i%Content=""
 . f ptr=1:1:$$$defMemberKeyGet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent) d
 . . d ..Content.WriteLine($$$defMemberArrayGet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent,ptr))
 . d ..Content.Rewind()
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
 . i '($$$defMemberDefined(name1,$$$cCLASSudltext,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSudltext,name2,"")
 . i 'i%%isDefined("Category") { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcategory) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcategory,i%Category) }
 . i 'i%%isDefined("Position") { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTposition) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTposition,i%Position) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("TextType") { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTtexttype) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTtexttype,i%TextType) }
 . $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent)
 . d ..Content.Rewind() s ..Content.LineTerminator=$c(10)
 . f line=1:1 q:..Content.AtEnd  d
 . . s linetext=..Content.ReadLine($$$MaxLocalLength) i $e(linetext,*)=$c(13) s linetext=$e(linetext,1,*-1)
 . . $$$defMemberArraySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent,line,linetext)
 . $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent,line-1)
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSudltext,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.UDLTextDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSudltext,name2,"")
 . i i%Category="comment" { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcategory) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcategory,i%Category) }
 . i i%Position="body" { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTposition) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTposition,i%Position) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTsequencenumber,i%SequenceNumber) }
 . i i%TextType=0 { $$$defMemberKeyKill(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTtexttype) } else { $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTtexttype,i%TextType) }
 . d ..Content.Rewind() s ..Content.LineTerminator=$c(10)
 . f line=1:1 q:..Content.AtEnd  d
 . . s linetext=..Content.ReadLine($$$MaxLocalLength) i $e(linetext,*)=$c(13) s linetext=$e(linetext,1,*-1)
 . . $$$defMemberArraySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent,line,linetext)
 . $$$defMemberKeySet(name1,$$$cCLASSudltext,name2,$$$cUDLTEXTcontent,line-1)
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
 If '($$$defMemberDefined(name1,$$$cCLASSudltext,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSudltext,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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
<RetrievalCode> s {Category}=$s($d(^oddDEF({L1},"u",{L3},23))#2:^(23),1:"comment")
</RetrievalCode>
</Data>
<Data name="Content">
<RetrievalCode> s {Content}=""
</RetrievalCode>
</Data>
<Data name="Position">
<RetrievalCode> s {Position}=$s($d(^oddDEF({L1},"u",{L3},24))#2:^(24),1:"body")
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"u",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="TextType">
<RetrievalCode> s {TextType}=$s($d(^oddDEF({L1},"u",{L3},22))#2:^(22),1:0)
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"u"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.UDLTextDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.UDLTextDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
