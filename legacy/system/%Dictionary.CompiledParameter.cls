/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledParameter Extends (%Persistent, %Dictionary.CompiledParameterQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Parameters ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies whether this is an abstract parameter.
Property Abstract As %Boolean;

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// Specifies a constraint value used by Studio to provide input validation for the parameter. Its value is not used nor enforced by the Class Compiler.
Property Constraint As %RawString [ SqlFieldName = _Constraint ];

/// Specifies a default value for the parameter assuming the Expression keyword is blank.
Property Default As %RawString [ SqlFieldName = _Default ];

/// True if this parameter is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the parameter.
Property Description As %RawString;

/// If true then the parameter value is base64 encoded.
Property Encoded As %Boolean;

/// An expression to seed parameter with evaluated at compile time, if specified this takes precedence over the Default keyword.
Property Expression As %RawString;

/// Specifies that subclasses cannot override the definition of the parameter.
Property Final As %Boolean;

/// Specifies any additional modifier flags for the parameter type.
Property Flags As %RawString;

/// Id
Property Id As %Integer;

/// InheritedId
Property InheritedId As %Boolean;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// The name of the parameter.
Property Name As %Dictionary.Identifier [ Required ];

/// NotInheritable
Property NotInheritable As %Boolean;

/// Origin
Property Origin As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// TagGenerator
Property TagGenerator As %RawString;

/// Specifies a type for the parameter. The type is used by Studio to provide input validation for the parameter.
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
 i $$$comMemberDefined(name1,$$$cCLASSparameter,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSparameter,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Abstract=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMabstract),i%%isDefined("Abstract")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMabstract)
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMcompilergenerated)
 . s i%Constraint=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMconstraint),i%%isDefined("Constraint")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMconstraint)
 . s i%Default=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMdefault),i%%isDefined("Default")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMdefault)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMdescription)
 . s i%Encoded=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMencoded),i%%isDefined("Encoded")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMencoded)
 . s i%Expression=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMexpression),i%%isDefined("Expression")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMexpression)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMfinal)
 . s i%Flags=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMflags),i%%isDefined("Flags")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMflags)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMinheritedid)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMkeywordmodified)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMnotinheritable)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMorigin)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMsequencenumber)
 . s i%TagGenerator=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMtaggenerator),i%%isDefined("TagGenerator")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMtaggenerator)
 . s i%Type=$$$comMemberKeyGetO(origin,name1,$$$cCLASSparameter,name2,$$$cPARAMtype),i%%isDefined("Type")=$$$comMemberKeyDefined(name1,$$$cCLASSparameter,name2,$$$cPARAMtype)
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

Method AbstractSet(value As %String = "") As %Status
{
 set i%Abstract=value,i%%isDefined("Abstract")=1 quit $$$OK
}

Method AbstractReset()
{
 set i%Abstract=0 set i%%isDefined("Abstract")=0 quit
}

Method AbstractIsDefined() As %Boolean
{
 quit ''i%%isDefined("Abstract")
}

Method ConstraintSet(value As %String = "") As %Status
{
 set i%Constraint=value,i%%isDefined("Constraint")=1 quit $$$OK
}

Method ConstraintReset()
{
 set i%Constraint="" set i%%isDefined("Constraint")=0 quit
}

Method ConstraintIsDefined() As %Boolean
{
 quit ''i%%isDefined("Constraint")
}

Method DefaultSet(value As %String = "") As %Status
{
 set i%Default=value,i%%isDefined("Default")=1 quit $$$OK
}

Method DefaultReset()
{
 set i%Default="" set i%%isDefined("Default")=0 quit
}

Method DefaultIsDefined() As %Boolean
{
 quit ''i%%isDefined("Default")
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

Method EncodedSet(value As %String = "") As %Status
{
 set i%Encoded=value,i%%isDefined("Encoded")=1 quit $$$OK
}

Method EncodedReset()
{
 set i%Encoded=0 set i%%isDefined("Encoded")=0 quit
}

Method EncodedIsDefined() As %Boolean
{
 quit ''i%%isDefined("Encoded")
}

Method ExpressionSet(value As %String = "") As %Status
{
 set i%Expression=value,i%%isDefined("Expression")=1 quit $$$OK
}

Method ExpressionReset()
{
 set i%Expression="" set i%%isDefined("Expression")=0 quit
}

Method ExpressionIsDefined() As %Boolean
{
 quit ''i%%isDefined("Expression")
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

Method FlagsSet(value As %String = "") As %Status
{
 set i%Flags=value,i%%isDefined("Flags")=1 quit $$$OK
}

Method FlagsReset()
{
 set i%Flags="" set i%%isDefined("Flags")=0 quit
}

Method FlagsIsDefined() As %Boolean
{
 quit ''i%%isDefined("Flags")
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
<Data name="Abstract">
<RetrievalCode> s {Abstract}=$s($d(^oddCOM({L1},"p",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"p",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},24))#2:^(24),1:0))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"p",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"p",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"p",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"p",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"p",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"p",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="Encoded">
<RetrievalCode> s {Encoded}=$s($d(^oddCOM({L1},"p",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"p",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},27))#2:^(27),1:0))
</RetrievalCode>
</Data>
<Data name="Expression">
<RetrievalCode> s {Expression}=$s($d(^oddCOM({L1},"p",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"p",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},25))#2:^(25),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"p",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"p",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="Flags">
<RetrievalCode> s {Flags}=$s($d(^oddCOM({L1},"p",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"p",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"p",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"p",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"p",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"p",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"p",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"p",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"p",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"p",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"p",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"p",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"p",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"p",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"p",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"p",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"p",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"p",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="TagGenerator">
<RetrievalCode> s {TagGenerator}=$s($d(^oddCOM({L1},"p",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"p",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddCOM({L1},"p",{L3},5))#2:^(5),$d(^oddCOM($g(^(2),{L1}),"p",{L3},5))#2:^(5),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},5))#2:^(5),1:""))
</RetrievalCode>
</Data>
<Data name="_Constraint">
<RetrievalCode> s {_Constraint}=$s($d(^oddCOM({L1},"p",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"p",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},21))#2:^(21),1:""))
</RetrievalCode>
</Data>
<Data name="_Default">
<RetrievalCode> s {_Default}=$s($d(^oddCOM({L1},"p",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"p",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"p",{L3},2),{L1}),"p",{L3},22))#2:^(22),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"p"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledParameter.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledParameterS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
