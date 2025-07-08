/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.ProjectionDefinition Extends (%Persistent, %Dictionary.ProjectionDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = Projections ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// True if this projection is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the projection.
Property Description As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// The name of the projection.
Property Name As %Dictionary.Identifier [ Required ];

/// Specifies that this projection is not inherited in subclasses.
Property NotInheritable As %Boolean [ InitialExpression = 0 ];

/// Parameter
Property Parameters As array Of %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// Specifies the name of the class associated with the projection.
Property Type As %Dictionary.Classname;

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
 s i%%isDefined("NotInheritable")=0
 s i%%isDefined("SequenceNumber")=0
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
 i $$$defMemberDefined(name1,$$$cCLASSprojection,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSprojection,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSprojection,name2,$$$cPROJdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJdescription)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSprojection,name2,$$$cPROJinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJinternal)
 . s i%NotInheritable=$$$defMemberKeyGet(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable),i%%isDefined("NotInheritable")=$$$defMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber)
 . s i%Type=$$$defMemberKeyGet(name1,$$$cCLASSprojection,name2,$$$cPROJtype),i%%isDefined("Type")=$$$defMemberKeyDefined(name1,$$$cCLASSprojection,name2,$$$cPROJtype)
 . s sub="" f  s sub=$$$defSubMemberNext(name1,$$$cCLASSprojection,name2,$$$cPROJparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$defMemberArrayGet(name1,$$$cCLASSprojection,name2,$$$cPROJparameter,sub),sub)
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
 . i '($$$defMemberDefined(name1,$$$cCLASSprojection,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSprojection,name2,"")
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJdescription,i%Description) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJinternal,i%Internal) }
 . i 'i%%isDefined("NotInheritable") { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable,i%NotInheritable) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("Type") { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJtype) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJtype,i%Type) }
 . $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSprojection,name2,$$$cPROJparameter,sub,..Parameters.GetAt(sub))
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSprojection,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.ProjectionDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSprojection,name2,"")
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJdescription,i%Description) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJinternal,i%Internal) }
 . i i%NotInheritable=0 { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJnotinheritable,i%NotInheritable) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJsequencenumber,i%SequenceNumber) }
 . i i%Type="" { $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJtype) } else { $$$defMemberKeySet(name1,$$$cCLASSprojection,name2,$$$cPROJtype,i%Type) }
 . $$$defMemberKeyKill(name1,$$$cCLASSprojection,name2,$$$cPROJparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSprojection,name2,$$$cPROJparameter,sub,..Parameters.GetAt(sub))
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
 If '($$$defMemberDefined(name1,$$$cCLASSprojection,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSprojection,name2) Do UpdClsDef^%occLibrary(name1)
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
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"j",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"j",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"j",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddDEF({L1},"j",{L3},9))#2:^(9),1:0)
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddDEF({L1},"j",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$g(^oddDEF({L1},"j",{L3},"P",sub))))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"j",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddDEF({L1},"j",{L3},5))#2:^(5),1:"")
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"j"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.ProjectionDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.ProjectionD882AS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
