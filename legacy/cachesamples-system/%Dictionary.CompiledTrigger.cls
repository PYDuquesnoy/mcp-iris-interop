/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledTrigger Extends (%Persistent, %Dictionary.CompiledTriggerQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Triggers ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// The code that is executed when the trigger is fired.
Property Code As %RawString;

/// Specifies how a given method is implemented: lines of code to be compiled, or a method that will generate the resulting method or object.
Property CodeMode As %RawString;

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// True if this trigger is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the SQL trigger.
Property Description As %RawString;

/// Specifies the SQL event that will fire the trigger.
Property Event As %RawString;

/// Specifies that subclasses cannot override the definition of the SQL trigger.
Property Final As %Boolean;

/// Indicates if the trigger will be invoked for each row, for rows and objects, or for each statement
Property Foreach As %RawString;

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

/// The language used to implement this trigger.
Property Language As %RawString [ SqlFieldName = _Language ];

/// The name of the SQL trigger.
Property Name As %Dictionary.Identifier [ Required ];

/// The name of the SQL table that holds old values for the trigger.
Property NewTable As %RawString;

/// NotInheritable
Property NotInheritable As %Boolean;

/// The name of the SQL table that holds old values for the trigger.
Property OldTable As %RawString;

/// In the case of multiple triggers for the same EVENT and TIME, specifies the order in which the triggers should be fired.
Property Order As %Integer;

/// Origin
Property Origin As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Specifies an alternate name when this trigger is used by SQL.
Property SqlName As %RawString;

/// TagGenerator
Property TagGenerator As %RawString;

/// Specifies whether the trigger is fired before or after the EVENT.
Property Time As %RawString [ SqlFieldName = _Time ];

/// Specifies one or more columns whose modification causes the trigger to be pulled by SQL.
Property UpdateColumnList As %RawString;

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
 i $$$comMemberDefined(name1,$$$cCLASStrigger,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASStrigger,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Code=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode),i%%isDefined("Code")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode)
 . s i%CodeMode=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode),i%%isDefined("CodeMode")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode)
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcompilergenerated)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription)
 . s i%Event=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent),i%%isDefined("Event")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal)
 . s i%Foreach=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach),i%%isDefined("Foreach")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinheritedid)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERkeywordmodified)
 . s i%Language=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage),i%%isDefined("Language")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage)
 . s i%NewTable=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable),i%%isDefined("NewTable")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnotinheritable)
 . s i%OldTable=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable),i%%isDefined("OldTable")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable)
 . s i%Order=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder),i%%isDefined("Order")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorigin)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber)
 . s i%SqlName=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname),i%%isDefined("SqlName")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname)
 . s i%TagGenerator=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERtaggenerator),i%%isDefined("TagGenerator")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtaggenerator)
 . s i%Time=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime),i%%isDefined("Time")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime)
 . s i%UpdateColumnList=$$$comMemberKeyGetO(origin,name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist),i%%isDefined("UpdateColumnList")=$$$comMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist)
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

Method CodeSet(value As %String = "") As %Status
{
 set i%Code=value,i%%isDefined("Code")=1 quit $$$OK
}

Method CodeReset()
{
 set i%Code="" set i%%isDefined("Code")=0 quit
}

Method CodeIsDefined() As %Boolean
{
 quit ''i%%isDefined("Code")
}

Method CodeModeSet(value As %String = "") As %Status
{
 set i%CodeMode=value,i%%isDefined("CodeMode")=1 quit $$$OK
}

Method CodeModeReset()
{
 set i%CodeMode="code" set i%%isDefined("CodeMode")=0 quit
}

Method CodeModeIsDefined() As %Boolean
{
 quit ''i%%isDefined("CodeMode")
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

Method EventSet(value As %String = "") As %Status
{
 set i%Event=value,i%%isDefined("Event")=1 quit $$$OK
}

Method EventReset()
{
 set i%Event="" set i%%isDefined("Event")=0 quit
}

Method EventIsDefined() As %Boolean
{
 quit ''i%%isDefined("Event")
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

Method ForeachSet(value As %String = "") As %Status
{
 set i%Foreach=value,i%%isDefined("Foreach")=1 quit $$$OK
}

Method ForeachReset()
{
 set i%Foreach="" set i%%isDefined("Foreach")=0 quit
}

Method ForeachIsDefined() As %Boolean
{
 quit ''i%%isDefined("Foreach")
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

Method LanguageSet(value As %String = "") As %Status
{
 set i%Language=value,i%%isDefined("Language")=1 quit $$$OK
}

Method LanguageReset()
{
 set i%Language="" set i%%isDefined("Language")=0 quit
}

Method LanguageIsDefined() As %Boolean
{
 quit ''i%%isDefined("Language")
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

Method NewTableSet(value As %String = "") As %Status
{
 set i%NewTable=value,i%%isDefined("NewTable")=1 quit $$$OK
}

Method NewTableReset()
{
 set i%NewTable="" set i%%isDefined("NewTable")=0 quit
}

Method NewTableIsDefined() As %Boolean
{
 quit ''i%%isDefined("NewTable")
}

Method OldTableSet(value As %String = "") As %Status
{
 set i%OldTable=value,i%%isDefined("OldTable")=1 quit $$$OK
}

Method OldTableReset()
{
 set i%OldTable="" set i%%isDefined("OldTable")=0 quit
}

Method OldTableIsDefined() As %Boolean
{
 quit ''i%%isDefined("OldTable")
}

Method OrderSet(value As %String = "") As %Status
{
 set i%Order=value,i%%isDefined("Order")=1 quit $$$OK
}

Method OrderReset()
{
 set i%Order=0 set i%%isDefined("Order")=0 quit
}

Method OrderIsDefined() As %Boolean
{
 quit ''i%%isDefined("Order")
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

Method TimeSet(value As %String = "") As %Status
{
 set i%Time=value,i%%isDefined("Time")=1 quit $$$OK
}

Method TimeReset()
{
 set i%Time="BEFORE" set i%%isDefined("Time")=0 quit
}

Method TimeIsDefined() As %Boolean
{
 quit ''i%%isDefined("Time")
}

Method UpdateColumnListSet(value As %String = "") As %Status
{
 set i%UpdateColumnList=value,i%%isDefined("UpdateColumnList")=1 quit $$$OK
}

Method UpdateColumnListReset()
{
 set i%UpdateColumnList="" set i%%isDefined("UpdateColumnList")=0 quit
}

Method UpdateColumnListIsDefined() As %Boolean
{
 quit ''i%%isDefined("UpdateColumnList")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Code">
<RetrievalCode> s {Code}=$s($d(^oddCOM({L1},"t",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"t",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},21))#2:^(21),1:""))
</RetrievalCode>
</Data>
<Data name="CodeMode">
<RetrievalCode> s {CodeMode}=$s($d(^oddCOM({L1},"t",{L3},31))#2:^(31),$d(^oddCOM($g(^(2),{L1}),"t",{L3},31))#2:^(31),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},31))#2:^(31),1:"code"))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"t",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"t",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"t",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"t",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"t",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"t",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="Event">
<RetrievalCode> s {Event}=$s($d(^oddCOM({L1},"t",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"t",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},22))#2:^(22),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"t",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"t",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="Foreach">
<RetrievalCode> s {Foreach}=$s($d(^oddCOM({L1},"t",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"t",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"t",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"t",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"t",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"t",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"t",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"t",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"t",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"t",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"t",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"t",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NewTable">
<RetrievalCode> s {NewTable}=$s($d(^oddCOM({L1},"t",{L3},29))#2:^(29),$d(^oddCOM($g(^(2),{L1}),"t",{L3},29))#2:^(29),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},29))#2:^(29),1:""))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"t",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"t",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="OldTable">
<RetrievalCode> s {OldTable}=$s($d(^oddCOM({L1},"t",{L3},30))#2:^(30),$d(^oddCOM($g(^(2),{L1}),"t",{L3},30))#2:^(30),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},30))#2:^(30),1:""))
</RetrievalCode>
</Data>
<Data name="Order">
<RetrievalCode> s {Order}=$s($d(^oddCOM({L1},"t",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"t",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},23))#2:^(23),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"t",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"t",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"t",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"t",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddCOM({L1},"t",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"t",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="TagGenerator">
<RetrievalCode> s {TagGenerator}=$s($d(^oddCOM({L1},"t",{L3},32))#2:^(32),$d(^oddCOM($g(^(2),{L1}),"t",{L3},32))#2:^(32),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},32))#2:^(32),1:""))
</RetrievalCode>
</Data>
<Data name="UpdateColumnList">
<RetrievalCode> s {UpdateColumnList}=$s($d(^oddCOM({L1},"t",{L3},28))#2:^(28),$d(^oddCOM($g(^(2),{L1}),"t",{L3},28))#2:^(28),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},28))#2:^(28),1:""))
</RetrievalCode>
</Data>
<Data name="_Language">
<RetrievalCode> s {_Language}=$s($d(^oddCOM({L1},"t",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"t",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="_Time">
<RetrievalCode> s {_Time}=$s($d(^oddCOM({L1},"t",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"t",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"t",{L3},2),{L1}),"t",{L3},25))#2:^(25),1:"BEFORE"))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"t"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledTrigger.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledTriggerS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
