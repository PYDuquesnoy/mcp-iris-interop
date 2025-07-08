/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledConstraint Extends (%Persistent, %Dictionary.CompiledConstraintQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Constraints ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies the type of constraint.
Property Category As %RawString;

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// Deferrable
Property Deferrable As %Boolean [ SqlFieldName = _Deferrable ];

/// True if this constraint is deprecated.
Property Deprecated As %Boolean;

/// Final
Property Final As %Boolean;

/// Specifies the list of arguments that are passed to the constraint.
Property FormalSpec As %RawString;

/// FormalSpecParsed
Property FormalSpecParsed As %RawString;

/// Specifies the name of the class member from which this constraint is generated, member type depends on the value of the Category keyword.
Property GeneratedFrom As %RawString;

/// Id
Property Id As %Integer;

/// InheritedId
Property InheritedId As %Boolean;

/// Initialmode
Property Initialmode As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Method
Relationship Methods As %Dictionary.CompiledConstraintMethod [ Cardinality = children, Inverse = parent ];

/// Name
Property Name As %Dictionary.Identifier [ Required ];

/// NotInheritable
Property NotInheritable As %Boolean;

/// Origin
Property Origin As %RawString;

/// Parameter
Property Parameters As array Of %RawString;

/// SqlName
Property SqlName As %RawString;

/// Type
Property Type As %RawString;

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
 i $$$comMemberDefined(name1,$$$cCLASSconstraint,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSconstraint,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Category=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONScategory),i%%isDefined("Category")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONScategory)
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONScompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONScompilergenerated)
 . s i%Deferrable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSdeferrable),i%%isDefined("Deferrable")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSdeferrable)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSdeprecated)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSfinal)
 . s i%FormalSpec=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSformalspec),i%%isDefined("FormalSpec")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSformalspec)
 . s i%FormalSpecParsed=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSformalspecparsed),i%%isDefined("FormalSpecParsed")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSformalspecparsed)
 . s i%GeneratedFrom=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSgeneratedfrom),i%%isDefined("GeneratedFrom")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSgeneratedfrom)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSinheritedid)
 . s i%Initialmode=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSinitialmode),i%%isDefined("Initialmode")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSinitialmode)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSkeywordmodified)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSnotinheritable)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSorigin)
 . s i%SqlName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONSsqlname),i%%isDefined("SqlName")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONSsqlname)
 . s i%Type=$$$comMemberKeyGetO(origin,name1,$$$cCLASSconstraint,name2,$$$cCONStype),i%%isDefined("Type")=$$$comMemberKeyDefined(name1,$$$cCLASSconstraint,name2,$$$cCONStype)
 . s sub="" f  s sub=$$$comSubMemberNext(name1,$$$cCLASSconstraint,name2,$$$cCONSparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$comMemberArrayGet(name1,$$$cCLASSconstraint,name2,$$$cCONSparameter,sub),sub)
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

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Category">
<RetrievalCode> s {Category}=$s($d(^oddCOM({L1},"n",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"n",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},21))#2:^(21),1:"fkey"))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"n",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"n",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"n",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"n",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"n",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"n",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},7))#2:^(7),1:1))
</RetrievalCode>
</Data>
<Data name="FormalSpec">
<RetrievalCode> s {FormalSpec}=$s($d(^oddCOM({L1},"n",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"n",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},25))#2:^(25),1:""))
</RetrievalCode>
</Data>
<Data name="FormalSpecParsed">
<RetrievalCode> s {FormalSpecParsed}=$s($d(^oddCOM({L1},"n",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"n",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Data name="GeneratedFrom">
<RetrievalCode> s {GeneratedFrom}=$s($d(^oddCOM({L1},"n",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"n",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"n",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"n",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"n",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"n",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Initialmode">
<RetrievalCode> s {Initialmode}=$s($d(^oddCOM({L1},"n",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"n",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"n",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"n",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"n",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"n",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"n",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"n",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"n",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"n",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddCOM({L1},"n",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$s($d(^oddCOM({L1},"n",{L3},"P",sub))#2:^(sub),$d(^oddCOM($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},"P",sub))#2:^(sub),1:$g(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},"P",sub)))))
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddCOM({L1},"n",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"n",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddCOM({L1},"n",{L3},5))#2:^(5),$d(^oddCOM($g(^(2),{L1}),"n",{L3},5))#2:^(5),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},5))#2:^(5),1:""))
</RetrievalCode>
</Data>
<Data name="_Deferrable">
<RetrievalCode> s {_Deferrable}=$s($d(^oddCOM({L1},"n",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"n",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"n",{L3},2),{L1}),"n",{L3},22))#2:^(22),1:0))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"n"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledConstraint.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledConsEF5S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
