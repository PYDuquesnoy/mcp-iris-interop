/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledProjection Extends (%Persistent, %Dictionary.CompiledProjectionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Projections ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// True if this projection is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the projection.
Property Description As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// The name of the projection.
Property Name As %Dictionary.Identifier [ Required ];

/// Specifies that this projection is not inherited in subclasses.
Property NotInheritable As %Boolean;

/// Origin
Property Origin As %RawString;

/// Parameter
Property Parameters As array Of %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Specifies the name of the class associated with the projection.
Property Type As %Dictionary.Classname;

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
 i $$$comMemberDefined(name1,$$$cCLASSprojection,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSprojection,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJdescription)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJkeywordmodified)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJorigin)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber)
 . s i%Type=$$$comMemberKeyGetO(origin,name1,$$$cCLASSprojection,name2,$$$cPROJtype),i%%isDefined("Type")=$$$comMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJtype)
 . s sub="" f  s sub=$$$comSubMemberNext(name1,$$$cCLASSprojection,name2,$$$cPROJparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$comMemberArrayGet(name1,$$$cCLASSprojection,name2,$$$cPROJparameter,sub),sub)
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
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"j",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"j",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"j",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"j",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"j",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"j",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"j",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"j",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"j",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"j",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"j",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"j",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"j",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"j",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddCOM({L1},"j",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$s($d(^oddCOM({L1},"j",{L3},"P",sub))#2:^(sub),$d(^oddCOM($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},"P",sub))#2:^(sub),1:$g(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},"P",sub)))))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"j",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"j",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddCOM({L1},"j",{L3},5))#2:^(5),$d(^oddCOM($g(^(2),{L1}),"j",{L3},5))#2:^(5),1:$s($d(^oddDEF($g(^oddCOM({L1},"j",{L3},2),{L1}),"j",{L3},5))#2:^(5),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"j"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledProjection.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledProDCA3S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
