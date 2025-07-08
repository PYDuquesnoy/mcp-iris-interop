/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.QueryDefinition Extends (%Persistent, %Dictionary.QueryDefinitionQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.ClassDefinition [ Cardinality = parent, Inverse = Queries ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// An alias used by client projections of this query.
Property ClientName As %RawString;

/// True if this query is deprecated.
Property Deprecated As %Boolean [ InitialExpression = 0 ];

/// Specifies a description of the query.
Property Description As %RawString;

/// Specifies that subclasses cannot override the definition of the query.
Property Final As %Boolean [ InitialExpression = 0 ];

/// Specifies the list of arguments passed to the Execute method. Each argument is of the format [&amp;|*]&lt;name&gt;[:&lt;type&gt;][=&lt;default&gt;] where &amp; means pass-by-reference and * means output-only.
Property FormalSpec As %RawString;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean [ InitialExpression = 0 ];

/// The name of the query.
Property Name As %Dictionary.Identifier [ Required ];

/// Deprecated
Property NotInheritable As %Boolean [ InitialExpression = 0 ];

/// Parameter
Property Parameters As array Of %RawString;

/// Deprecated.
Property Private As %Boolean [ InitialExpression = 0 ];

/// Comma separated string of resource constraints to run this method
Property Requires As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer [ InitialExpression = 0 ];

/// Specifies what type of SOAP invocation is used for a web method. This keyword is ignored for non-web methods.
Property SoapBindingStyle As %RawString;

/// Specifies what kind of SOAP encoding is used for the inputs and outputs of a web method. This keyword is ignored for non-web methods.
Property SoapBodyUse As %RawString;

/// Specifies the namespace at the binding operation level in the WSDL. Applies only in a class that is defined as a web service or web client.
Property SoapNameSpace As %RawString;

/// If this query is projected as an SQL stored procedure, then this name is used as the name of the stored procedure.
Property SqlName As %RawString;

/// Specifies that the query can be invoked as an SQL stored procedure.
Property SqlProc As %Boolean [ InitialExpression = 0 ];

/// Specifies an SQL statement to be used for an SQL-based query.
Property SqlQuery As %RawString;

/// Specifies whether to project this query as an SQL View.
Property SqlView As %Boolean [ InitialExpression = 0 ];

/// Specifies an SQL alias for the view projected from this query.
Property SqlViewName As %RawString;

/// Specifies the Query class used to provide the implementation of the query interface.
Property Type As %Dictionary.Classname;

/// description=Specifies that this query can be invoked using the SOAP protocol. 
Property WebMethod As %Boolean [ InitialExpression = 0 ];

ClassMethod SoapBindingStyleIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="document" q $$$OK
 i val="rpc" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.QueryDefinition:SoapBindingStyle",val)
}

ClassMethod SoapBodyUseIsValid(val As %String) As %Status
{
 i val="" q $$$OK
 i val="literal" q $$$OK
 i val="encoded" q $$$OK
 q $$$ERROR($$$DatatypeValidationFailed,"%Dictionary.QueryDefinition:SoapBodyUse",val)
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
 s i%%isDefined("ClientName")=0
 s i%%isDefined("Deprecated")=0
 s i%%isDefined("Description")=0
 s i%%isDefined("Final")=0
 s i%%isDefined("FormalSpec")=0
 s i%%isDefined("Internal")=0
 s i%%isDefined("Name")=0
 s i%%isDefined("NotInheritable")=0
 s i%%isDefined("Private")=0
 s i%%isDefined("Requires")=0
 s i%%isDefined("SequenceNumber")=0
 s i%%isDefined("SoapBindingStyle")=0
 s i%%isDefined("SoapBodyUse")=0
 s i%%isDefined("SoapNameSpace")=0
 s i%%isDefined("SqlName")=0
 s i%%isDefined("SqlProc")=0
 s i%%isDefined("SqlQuery")=0
 s i%%isDefined("SqlView")=0
 s i%%isDefined("SqlViewName")=0
 s i%%isDefined("Type")=0
 s i%%isDefined("WebMethod")=0
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
 i $$$defMemberDefined(name1,$$$cCLASSquery,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$defMemberDefined(name1,$$$cCLASSquery,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%ClientName=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYclientname),i%%isDefined("ClientName")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYclientname)
 . s i%Deprecated=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated),i%%isDefined("Deprecated")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated)
 . s i%Description=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYdescription),i%%isDefined("Description")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYdescription)
 . s i%Final=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYfinal),i%%isDefined("Final")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYfinal)
 . s i%FormalSpec=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec),i%%isDefined("FormalSpec")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec)
 . s i%Internal=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYinternal),i%%isDefined("Internal")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYinternal)
 . s i%NotInheritable=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable),i%%isDefined("NotInheritable")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable)
 . s i%Private=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYprivate),i%%isDefined("Private")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYprivate)
 . s i%Requires=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYrequires),i%%isDefined("Requires")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYrequires)
 . s i%SequenceNumber=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber),i%%isDefined("SequenceNumber")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber)
 . s i%SoapBindingStyle=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle),i%%isDefined("SoapBindingStyle")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle)
 . s i%SoapBodyUse=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse),i%%isDefined("SoapBodyUse")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse)
 . s i%SoapNameSpace=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace),i%%isDefined("SoapNameSpace")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace)
 . s i%SqlName=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname),i%%isDefined("SqlName")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname)
 . s i%SqlProc=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc),i%%isDefined("SqlProc")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc)
 . s i%SqlQuery=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery),i%%isDefined("SqlQuery")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery)
 . s i%SqlView=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview),i%%isDefined("SqlView")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview)
 . s i%SqlViewName=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname),i%%isDefined("SqlViewName")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname)
 . s i%Type=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYtype),i%%isDefined("Type")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYtype)
 . s i%WebMethod=$$$defMemberKeyGet(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod),i%%isDefined("WebMethod")=$$$defMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod)
 . s sub="" f  s sub=$$$defSubMemberNext(name1,$$$cCLASSquery,name2,$$$cQUERYparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$defMemberArrayGet(name1,$$$cCLASSquery,name2,$$$cQUERYparameter,sub),sub)
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
 . i '($$$defMemberDefined(name1,$$$cCLASSquery,name2)) s insert=1 q
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . $$$defMemberSet(name1,$$$cCLASSquery,name2,"")
 . i 'i%%isDefined("ClientName") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYclientname) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYclientname,i%ClientName) }
 . i 'i%%isDefined("Deprecated") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated,i%Deprecated) }
 . i 'i%%isDefined("Description") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYdescription,i%Description) }
 . i 'i%%isDefined("Final") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYfinal) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYfinal,i%Final) }
 . i 'i%%isDefined("FormalSpec") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec,i%FormalSpec) }
 . i 'i%%isDefined("Internal") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYinternal,i%Internal) }
 . i 'i%%isDefined("NotInheritable") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable,i%NotInheritable) }
 . i 'i%%isDefined("Private") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYprivate) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYprivate,i%Private) }
 . i 'i%%isDefined("Requires") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYrequires) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYrequires,i%Requires) }
 . i 'i%%isDefined("SequenceNumber") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber,i%SequenceNumber) }
 . i 'i%%isDefined("SoapBindingStyle") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle,i%SoapBindingStyle) }
 . i 'i%%isDefined("SoapBodyUse") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse,i%SoapBodyUse) }
 . i 'i%%isDefined("SoapNameSpace") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace,i%SoapNameSpace) }
 . i 'i%%isDefined("SqlName") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname,i%SqlName) }
 . i 'i%%isDefined("SqlProc") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc,i%SqlProc) }
 . i 'i%%isDefined("SqlQuery") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery,i%SqlQuery) }
 . i 'i%%isDefined("SqlView") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview,i%SqlView) }
 . i 'i%%isDefined("SqlViewName") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname,i%SqlViewName) }
 . i 'i%%isDefined("Type") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYtype) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYtype,i%Type) }
 . i 'i%%isDefined("WebMethod") { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod,i%WebMethod) }
 . $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSquery,name2,$$$cQUERYparameter,sub,..Parameters.GetAt(sub))
 i insert DO
 . i 'idassigned s id=i%parent_"||"_i%Name i 1
 . e  i $s(i%parent'=$p(id,"||",1,1):1,i%Name'=$p(id,"||",2):1,1:0) s sc=$$$ERROR($$$OidPreviouslyAssigned,$classname(),id) q
 . s name1=$p(id,"||",1),name2=$p(id,"||",2)
 . i i%%Concurrency s sc=..%LockId(id) s lock=$$$ISOK(sc) i 'lock q
 . i $$$defMemberDefined(name1,$$$cCLASSquery,name2) s sc=$$$ERROR($$$IDKeyNotUnique,"%Dictionary.QueryDefinition",$zreference,"") q
 . i 'idassigned s sc=..%IdSet(id) q:$$$ISERR(sc)  s:$$$txON $$$txOIDASSIGNED($this)=""
 . $$$defMemberSet(name1,$$$cCLASSquery,name2,"")
 . i i%ClientName="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYclientname) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYclientname,i%ClientName) }
 . i i%Deprecated=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated,i%Deprecated) }
 . i i%Description="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYdescription) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYdescription,i%Description) }
 . i i%Final=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYfinal) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYfinal,i%Final) }
 . i i%FormalSpec="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec,i%FormalSpec) }
 . i i%Internal=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYinternal) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYinternal,i%Internal) }
 . i i%NotInheritable=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable,i%NotInheritable) }
 . i i%Private=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYprivate) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYprivate,i%Private) }
 . i i%Requires="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYrequires) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYrequires,i%Requires) }
 . i i%SequenceNumber=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber,i%SequenceNumber) }
 . i i%SoapBindingStyle="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle,i%SoapBindingStyle) }
 . i i%SoapBodyUse="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse,i%SoapBodyUse) }
 . i i%SoapNameSpace="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace,i%SoapNameSpace) }
 . i i%SqlName="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname,i%SqlName) }
 . i i%SqlProc=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc,i%SqlProc) }
 . i i%SqlQuery="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery,i%SqlQuery) }
 . i i%SqlView=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview,i%SqlView) }
 . i i%SqlViewName="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname,i%SqlViewName) }
 . i i%Type="" { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYtype) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYtype,i%Type) }
 . i i%WebMethod=0 { $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod) } else { $$$defMemberKeySet(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod,i%WebMethod) }
 . $$$defMemberKeyKill(name1,$$$cCLASSquery,name2,$$$cQUERYparameter)
 . s sub="" f  s sub=..Parameters.Next(sub) q:sub=""  d
 . . $$$defSubMemberSet(name1,$$$cCLASSquery,name2,$$$cQUERYparameter,sub,..Parameters.GetAt(sub))
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
 If '($$$defMemberDefined(name1,$$$cCLASSquery,name2)) {
  If '$$$GetddlNo30 Set sc=$$$ERROR($$$DeleteObjectNotFound,$classname(),id)
 } Else {
  $$$defMemberKill(name1,$$$cCLASSquery,name2) Do UpdClsDef^%occLibrary(name1)
 }
 If concurrency Do ..%UnlockId(id)
 Quit sc
}

Method ClientNameSet(value As %String = "") As %Status
{
 set i%ClientName=value,i%%isDefined("ClientName")=1 quit $$$OK
}

Method ClientNameReset()
{
 set i%ClientName="" set i%%isDefined("ClientName")=0 quit
}

Method ClientNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("ClientName")
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

Method FormalSpecSet(value As %String = "") As %Status
{
 set i%FormalSpec=value,i%%isDefined("FormalSpec")=1 quit $$$OK
}

Method FormalSpecReset()
{
 set i%FormalSpec="" set i%%isDefined("FormalSpec")=0 quit
}

Method FormalSpecIsDefined() As %Boolean
{
 quit ''i%%isDefined("FormalSpec")
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

Method PrivateSet(value As %String = "") As %Status
{
 set i%Private=value,i%%isDefined("Private")=1 quit $$$OK
}

Method PrivateReset()
{
 set i%Private=0 set i%%isDefined("Private")=0 quit
}

Method PrivateIsDefined() As %Boolean
{
 quit ''i%%isDefined("Private")
}

Method RequiresSet(value As %String = "") As %Status
{
 set i%Requires=value,i%%isDefined("Requires")=1 quit $$$OK
}

Method RequiresReset()
{
 set i%Requires="" set i%%isDefined("Requires")=0 quit
}

Method RequiresIsDefined() As %Boolean
{
 quit ''i%%isDefined("Requires")
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

Method SoapBindingStyleSet(value As %String = "") As %Status
{
 set i%SoapBindingStyle=value,i%%isDefined("SoapBindingStyle")=1 quit $$$OK
}

Method SoapBindingStyleReset()
{
 set i%SoapBindingStyle="" set i%%isDefined("SoapBindingStyle")=0 quit
}

Method SoapBindingStyleIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapBindingStyle")
}

Method SoapBodyUseSet(value As %String = "") As %Status
{
 set i%SoapBodyUse=value,i%%isDefined("SoapBodyUse")=1 quit $$$OK
}

Method SoapBodyUseReset()
{
 set i%SoapBodyUse="" set i%%isDefined("SoapBodyUse")=0 quit
}

Method SoapBodyUseIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapBodyUse")
}

Method SoapNameSpaceSet(value As %String = "") As %Status
{
 set i%SoapNameSpace=value,i%%isDefined("SoapNameSpace")=1 quit $$$OK
}

Method SoapNameSpaceReset()
{
 set i%SoapNameSpace="" set i%%isDefined("SoapNameSpace")=0 quit
}

Method SoapNameSpaceIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapNameSpace")
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

Method SqlProcSet(value As %String = "") As %Status
{
 set i%SqlProc=value,i%%isDefined("SqlProc")=1 quit $$$OK
}

Method SqlProcReset()
{
 set i%SqlProc=0 set i%%isDefined("SqlProc")=0 quit
}

Method SqlProcIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlProc")
}

Method SqlQuerySet(value As %String = "") As %Status
{
 set i%SqlQuery=value,i%%isDefined("SqlQuery")=1 quit $$$OK
}

Method SqlQueryReset()
{
 set i%SqlQuery="" set i%%isDefined("SqlQuery")=0 quit
}

Method SqlQueryIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlQuery")
}

Method SqlViewSet(value As %String = "") As %Status
{
 set i%SqlView=value,i%%isDefined("SqlView")=1 quit $$$OK
}

Method SqlViewReset()
{
 set i%SqlView=0 set i%%isDefined("SqlView")=0 quit
}

Method SqlViewIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlView")
}

Method SqlViewNameSet(value As %String = "") As %Status
{
 set i%SqlViewName=value,i%%isDefined("SqlViewName")=1 quit $$$OK
}

Method SqlViewNameReset()
{
 set i%SqlViewName="" set i%%isDefined("SqlViewName")=0 quit
}

Method SqlViewNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlViewName")
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

Method WebMethodSet(value As %String = "") As %Status
{
 set i%WebMethod=value,i%%isDefined("WebMethod")=1 quit $$$OK
}

Method WebMethodReset()
{
 set i%WebMethod=0 set i%%isDefined("WebMethod")=0 quit
}

Method WebMethodIsDefined() As %Boolean
{
 quit ''i%%isDefined("WebMethod")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="ClientName">
<RetrievalCode> s {ClientName}=$s($d(^oddDEF({L1},"q",{L3},41))#2:^(41),1:"")
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddDEF({L1},"q",{L3},17))#2:^(17),1:0)
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddDEF({L1},"q",{L3},4))#2:^(4),1:"")
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddDEF({L1},"q",{L3},7))#2:^(7),1:0)
</RetrievalCode>
</Data>
<Data name="FormalSpec">
<RetrievalCode> s {FormalSpec}=$s($d(^oddDEF({L1},"q",{L3},24))#2:^(24),1:"")
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddDEF({L1},"q",{L3},14))#2:^(14),1:0)
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddDEF({L1},"q",{L3},9))#2:^(9),1:0)
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddDEF({L1},"q",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$g(^oddDEF({L1},"q",{L3},"P",sub))))
</RetrievalCode>
</Data>
<Data name="Private">
<RetrievalCode> s {Private}=$s($d(^oddDEF({L1},"q",{L3},26))#2:^(26),1:0)
</RetrievalCode>
</Data>
<Data name="Requires">
<RetrievalCode> s {Requires}=$s($d(^oddDEF({L1},"q",{L3},42))#2:^(42),1:"")
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddDEF({L1},"q",{L3},11))#2:^(11),1:0)
</RetrievalCode>
</Data>
<Data name="SoapBindingStyle">
<RetrievalCode> s {SoapBindingStyle}=$s($d(^oddDEF({L1},"q",{L3},35))#2:^(35),1:"")
</RetrievalCode>
</Data>
<Data name="SoapBodyUse">
<RetrievalCode> s {SoapBodyUse}=$s($d(^oddDEF({L1},"q",{L3},36))#2:^(36),1:"")
</RetrievalCode>
</Data>
<Data name="SoapNameSpace">
<RetrievalCode> s {SoapNameSpace}=$s($d(^oddDEF({L1},"q",{L3},37))#2:^(37),1:"")
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddDEF({L1},"q",{L3},27))#2:^(27),1:"")
</RetrievalCode>
</Data>
<Data name="SqlProc">
<RetrievalCode> s {SqlProc}=$s($d(^oddDEF({L1},"q",{L3},28))#2:^(28),1:0)
</RetrievalCode>
</Data>
<Data name="SqlQuery">
<RetrievalCode> s {SqlQuery}=$s($d(^oddDEF({L1},"q",{L3},29))#2:^(29),1:"")
</RetrievalCode>
</Data>
<Data name="SqlView">
<RetrievalCode> s {SqlView}=$s($d(^oddDEF({L1},"q",{L3},30))#2:^(30),1:0)
</RetrievalCode>
</Data>
<Data name="SqlViewName">
<RetrievalCode> s {SqlViewName}=$s($d(^oddDEF({L1},"q",{L3},31))#2:^(31),1:"")
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddDEF({L1},"q",{L3},5))#2:^(5),1:"")
</RetrievalCode>
</Data>
<Data name="WebMethod">
<RetrievalCode> s {WebMethod}=$s($d(^oddDEF({L1},"q",{L3},33))#2:^(33),1:0)
</RetrievalCode>
</Data>
<Global>^oddDEF</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.ClassDefinition.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"q"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.QueryDefinition.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.QueryDefinitionS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
