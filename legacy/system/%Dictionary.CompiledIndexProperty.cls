/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledIndexProperty Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledIndex [ Cardinality = parent, Inverse = PropertyCollection ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Collation
Property Collation As %RawString;

/// CollationParms
Property CollationParms As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Name
Property Name As %Dictionary.Identifier [ Required ];

/// Property
Property Property As %RawString;

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
 i $$$comSubMemberDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3) QUIT 1
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
 i (name1="")||(name2="")||(name3="")||('$$$comSubMemberDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%Collation=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPcollation),i%%isDefined("Collation")=$$$comSubMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPcollation)
 . s i%CollationParms=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPcollationparms),i%%isDefined("CollationParms")=$$$comSubMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPcollationparms)
 . s i%KeywordError=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPkeyworderror),i%%isDefined("KeywordError")=$$$comSubMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPkeyworderror)
 . s i%KeywordModified=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPkeywordmodified),i%%isDefined("KeywordModified")=$$$comSubMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPkeywordmodified)
 . s i%Property=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPproperty),i%%isDefined("Property")=$$$comSubMemberKeyDefined(name1,$$$cCLASSindex,name2,$$$cINDEXproperty,name3,$$$cINDEXPROPproperty)
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

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Collation">
<RetrievalCode> s {Collation}=$s($d(^oddCOM({L1},"i",{L3},"I",{L5},21))#2:^(21),$d(^oddCOM($g(^(2),"*"),"I",{L5},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"i",{L3},"I",{L5},2),"*"),"I",{L5},21))#2:^(21),1:""))
</RetrievalCode>
</Data>
<Data name="CollationParms">
<RetrievalCode> s {CollationParms}=$s($d(^oddCOM({L1},"i",{L3},"I",{L5},22))#2:^(22),$d(^oddCOM($g(^(2),"*"),"I",{L5},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"i",{L3},"I",{L5},2),"*"),"I",{L5},22))#2:^(22),1:""))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"i",{L3},"I",{L5},12))#2:^(12),$d(^oddCOM($g(^(2),"*"),"I",{L5},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"i",{L3},"I",{L5},2),"*"),"I",{L5},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"i",{L3},"I",{L5},13))#2:^(13),$d(^oddCOM($g(^(2),"*"),"I",{L5},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"i",{L3},"I",{L5},2),"*"),"I",{L5},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="Property">
<RetrievalCode> s {Property}=$s($d(^oddCOM({L1},"i",{L3},"I",{L5},23))#2:^(23),$d(^oddCOM($g(^(2),"*"),"I",{L5},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"i",{L3},"I",{L5},2),"*"),"I",{L5},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"i"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledIndex.Name}</Expression>
</Subscript>
<Subscript name="4">
<Expression>"I"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledIndexProperty.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledInd682ES</StreamLocation>
<Type>%CustomStorage</Type>
}

}
