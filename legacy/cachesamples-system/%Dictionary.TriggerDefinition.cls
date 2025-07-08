/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.TriggerDefinition Extends (%Persistent, %Dictionary.TriggerDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = Triggers ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// The code that is executed when the trigger is fired.
Property Code As %RawString;

/// Specifies how a given method is implemented: lines of code to be compiled, or a method that will generate the resulting method or object.
Property CodeMode As %RawString [ InitialExpression = "code" ];

/// True if this trigger is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the SQL trigger.
Property Description As %RawString;

/// Specifies the SQL event that will fire the trigger.
Property Event As %RawString;

/// Specifies that subclasses cannot override the definition of the SQL trigger.
Property Final As %Boolean [ InitialExpression = 0 ];

/// Indicates if the trigger will be invoked for each row, for rows and objects, or for each statement
Property Foreach As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// The language used to implement this trigger.
Property Language As %RawString [ SqlFieldName = _Language ];

/// The name of the SQL trigger.
Property Name As %Dictionary.Identifier [ Required ];

/// The name of the SQL table that holds old values for the trigger.
Property NewTable As %RawString;

/// The name of the SQL table that holds old values for the trigger.
Property OldTable As %RawString;

/// In the case of multiple triggers for the same EVENT and TIME, specifies the order in which the triggers should be fired.
Property Order As %Integer [ InitialExpression = 0 ];

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// Specifies an alternate name when this trigger is used by SQL.
Property SqlName As %RawString;

/// Specifies whether the trigger is fired before or after the EVENT.
Property Time As %RawString [ InitialExpression = "BEFORE", SqlFieldName = _Time ];

/// Specifies one or more columns whose modification causes the trigger to be pulled by SQL.
Property UpdateColumnList As %RawString;

ClassMethod CodeModeIsValid(val As %String) As %Status
{
 i val="code" q $$$OK
 i val="generator" q $$$OK
 i val="objectgenerator" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.TriggerDefinition:CodeMode",val)
}

ClassMethod EventIsValid(val As %String) As %Status
{
 i val="INSERT" q $$$OK
 i val="UPDATE" q $$$OK
 i val="DELETE" q $$$OK
 i val="INSERT/UPDATE" q $$$OK
 i val="INSERT/DELETE" q $$$OK
 i val="UPDATE/DELETE" q $$$OK
 i val="INSERT/UPDATE/DELETE" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.TriggerDefinition:Event",val)
}

ClassMethod ForeachIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="row" q $$$OK
 i val="row/object" q $$$OK
 i val="statement" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.TriggerDefinition:Foreach",val)
}

ClassMethod LanguageIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="objectscript" q $$$OK
 i val="tsql" q $$$OK
 i val="ispl" q $$$OK
 i val="python" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.TriggerDefinition:Language",val)
}

ClassMethod TimeIsValid(val As %String) As %Status
{
 i val="BEFORE" q $$$OK
 i val="AFTER" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.TriggerDefinition:Time",val)
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
 s i%%isDefined("Code")=0
 s i%%isDefined("CodeMode")=0
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("Event")=0
 s i%%isDefined("Final")=0
 s i%%isDefined("Foreach")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("Language")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("NewTable")=0
 s i%%isDefined("OldTable")=0
 s i%%isDefined("Order")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("SqlName")=0
 s i%%isDefined("Time")=0
 s i%%isDefined("UpdateColumnList")=0
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
 i $$$defMemberDefined(name1,$$$cCLASStrigger,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASStrigger,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Code=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode),i%%isDefined("Code")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode)
 . s i%CodeMode=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode),i%%isDefined("CodeMode")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode)
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription)
 . s i%Event=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent),i%%isDefined("Event")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent)
 . s i%Final=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal),i%%isDefined("Final")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal)
 . s i%Foreach=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach),i%%isDefined("Foreach")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal)
 . s i%Language=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage),i%%isDefined("Language")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage)
 . s i%NewTable=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable),i%%isDefined("NewTable")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable)
 . s i%OldTable=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable),i%%isDefined("OldTable")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable)
 . s i%Order=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder),i%%isDefined("Order")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber)
 . s i%SqlName=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname),i%%isDefined("SqlName")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname)
 . s i%Time=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime),i%%isDefined("Time")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime)
 . s i%UpdateColumnList=$$$defMemberKeyGet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist),i%%isDefined("UpdateColumnList")=$$$defMemberKeyDefined(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist)
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
 . i '($$$defMemberDefined(name1,$$$cCLASStrigger,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASStrigger,name2,"")
 . i 'i%%isDefined("Code") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode,i%Code) }
 . i 'i%%isDefined("CodeMode") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode,i%CodeMode) }
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription,i%Description) }
 . i 'i%%isDefined("Event") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent,i%Event) }
 . i 'i%%isDefined("Final") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal,i%Final) }
 . i 'i%%isDefined("Foreach") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach,i%Foreach) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal,i%Internal) }
 . i 'i%%isDefined("Language") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage,i%Language) }
 . i 'i%%isDefined("NewTable") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable,i%NewTable) }
 . i 'i%%isDefined("OldTable") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable,i%OldTable) }
 . i 'i%%isDefined("Order") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder,i%Order) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("SqlName") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname,i%SqlName) }
 . i 'i%%isDefined("Time") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime,i%Time) }
 . i 'i%%isDefined("UpdateColumnList") { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist,i%UpdateColumnList) }
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASStrigger,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.TriggerDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASStrigger,name2,"")
 . i i%Code="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcode,i%Code) }
 . i i%CodeMode="code" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERcodemode,i%CodeMode) }
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERdescription,i%Description) }
 . i i%Event="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERevent,i%Event) }
 . i i%Final=0 { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERfinal,i%Final) }
 . i i%Foreach="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERforeach,i%Foreach) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERinternal,i%Internal) }
 . i i%Language="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERlanguage,i%Language) }
 . i i%NewTable="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERnewtable,i%NewTable) }
 . i i%OldTable="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERoldtable,i%OldTable) }
 . i i%Order=0 { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERorder,i%Order) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsequencenumber,i%SequenceNumber) }
 . i i%SqlName="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERsqlname,i%SqlName) }
 . i i%Time="BEFORE" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERtime,i%Time) }
 . i i%UpdateColumnList="" { $$$defMemberKeyKill(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist) } else { $$$defMemberKeySet(name1,$$$cCLASStrigger,name2,$$$cTRIGGERupdatecolumnlist,i%UpdateColumnList) }
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
 If '($$$defMemberDefined(name1,$$$cCLASStrigger,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASStrigger,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
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
<RetrievalCode> s {Code}=$s($d(^oddDEF({L1},"t",{L3},21))#2:^(21),1:"")
</RetrievalCode>
</Data>
<Data name="CodeMode">
<RetrievalCode> s {CodeMode}=$s($d(^oddDEF({L1},"t",{L3},31))#2:^(31),1:"code")
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"t",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"t",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Event">
<RetrievalCode> s {Event}=$s($d(^oddDEF({L1},"t",{L3},22))#2:^(22),1:"")
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddDEF({L1},"t",{L3},7))#2:^(7),1:0)
</RetrievalCode>
</Data>
<Data name="Foreach">
<RetrievalCode> s {Foreach}=$s($d(^oddDEF({L1},"t",{L3},26))#2:^(26),1:"")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"t",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="NewTable">
<RetrievalCode> s {NewTable}=$s($d(^oddDEF({L1},"t",{L3},29))#2:^(29),1:"")
</RetrievalCode>
</Data>
<Data name="OldTable">
<RetrievalCode> s {OldTable}=$s($d(^oddDEF({L1},"t",{L3},30))#2:^(30),1:"")
</RetrievalCode>
</Data>
<Data name="Order">
<RetrievalCode> s {Order}=$s($d(^oddDEF({L1},"t",{L3},23))#2:^(23),1:0)
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"t",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddDEF({L1},"t",{L3},24))#2:^(24),1:"")
</RetrievalCode>
</Data>
<Data name="UpdateColumnList">
<RetrievalCode> s {UpdateColumnList}=$s($d(^oddDEF({L1},"t",{L3},28))#2:^(28),1:"")
</RetrievalCode>
</Data>
<Data name="_Language">
<RetrievalCode> s {_Language}=$s($d(^oddDEF({L1},"t",{L3},27))#2:^(27),1:"")
</RetrievalCode>
</Data>
<Data name="_Time">
<RetrievalCode> s {_Time}=$s($d(^oddDEF({L1},"t",{L3},25))#2:^(25),1:"BEFORE")
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"t"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.TriggerDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.TriggerDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
