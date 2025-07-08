/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledInstanceVar Extends (%Persistent, %Dictionary.CompiledInstanceVarQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = InstanceVars ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// Id
Property Id As %Integer;

/// InheritedId
Property InheritedId As %Boolean;

/// InitialExpression
Property InitialExpression As %RawString;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Name
Property Name As %Dictionary.Identifier [ Required ];

/// NotInheritable
Property NotInheritable As %Boolean;

/// Origin
Property Origin As %RawString;

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
 i $$$comMemberDefined(name1,$$$cCLASSinstancevar,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSinstancevar,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARcompilergenerated)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARinheritedid)
 . s i%InitialExpression=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARinitialexpression),i%%isDefined("InitialExpression")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARinitialexpression)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARkeywordmodified)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARnotinheritable)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSinstancevar,name2,$$$cIVARorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSinstancevar,name2,$$$cIVARorigin)
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
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"v",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"v",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"v",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"v",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"v",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"v",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="InitialExpression">
<RetrievalCode> s {InitialExpression}=$s($d(^oddCOM({L1},"v",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"v",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},21))#2:^(21),1:""""""))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"v",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"v",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"v",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"v",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"v",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"v",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"v",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"v",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"v",{L3},2),{L1}),"v",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"v"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledInstanceVar.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledIns9959S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
