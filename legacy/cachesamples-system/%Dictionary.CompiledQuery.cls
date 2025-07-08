/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledQuery Extends (%Persistent, %Dictionary.CompiledQueryQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Queries ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Cardinality
Property Cardinality As %Integer;

/// ClientInfo
Property ClientInfo As %RawString;

/// An alias used by client projections of this query.
Property ClientName As %RawString;

/// ColCaptions
Property ColCaptions As %RawString;

/// ColNames
Property ColNames As %RawString;

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// True if this query is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the query.
Property Description As %RawString;

/// ExtendedInfo
Property ExtendedInfo As %RawString;

/// Specifies that subclasses cannot override the definition of the query.
Property Final As %Boolean;

/// Specifies the list of arguments passed to the Execute method. Each argument is of the format [&amp;|*]&lt;name&gt;[:&lt;type&gt;][=&lt;default&gt;] where &amp; means pass-by-reference and * means output-only.
Property FormalSpec As %RawString;

/// FormalSpecParsed
Property FormalSpecParsed As %RawString;

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

/// Method
Relationship Methods As %Dictionary.CompiledQueryMethod [ Cardinality = children, Inverse = parent ];

/// The name of the query.
Property Name As %Dictionary.Identifier [ Required ];

/// Deprecated
Property NotInheritable As %Boolean;

/// Origin
Property Origin As %RawString;

/// Parameter
Property Parameters As array Of %RawString;

/// ParmNames
Property ParmNames As %RawString;

/// Deprecated.
Property Private As %Boolean;

/// Comma separated string of resource constraints to run this method
Property Requires As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Specifies what type of SOAP invocation is used for a web method. This keyword is ignored for non-web methods.
Property SoapBindingStyle As %RawString;

/// Specifies what kind of SOAP encoding is used for the inputs and outputs of a web method. This keyword is ignored for non-web methods.
Property SoapBodyUse As %RawString;

/// Specifies the namespace at the binding operation level in the WSDL. Applies only in a class that is defined as a web service or web client.
Property SoapNameSpace As %RawString;

/// If this query is projected as an SQL stored procedure, then this name is used as the name of the stored procedure.
Property SqlName As %RawString;

/// Specifies that the query can be invoked as an SQL stored procedure.
Property SqlProc As %Boolean;

/// Specifies an SQL statement to be used for an SQL-based query.
Property SqlQuery As %RawString;

/// SqlQueryGen
Property SqlQueryGen As %RawString;

/// Specifies whether to project this query as an SQL View.
Property SqlView As %Boolean;

/// Specifies an SQL alias for the view projected from this query.
Property SqlViewName As %RawString;

/// Specifies the Query class used to provide the implementation of the query interface.
Property Type As %Dictionary.Classname;

/// UserActualType
Property UserActualType As %RawString;

/// description=Specifies that this query can be invoked using the SOAP protocol. 
Property WebMethod As %Boolean;

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
 i $$$comMemberDefined(name1,$$$cCLASSquery,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSquery,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Cardinality=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYcardinality),i%%isDefined("Cardinality")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYcardinality)
 . s i%ClientInfo=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYclientinfo),i%%isDefined("ClientInfo")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYclientinfo)
 . s i%ClientName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYclientname),i%%isDefined("ClientName")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYclientname)
 . s i%ColCaptions=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYcolcaptions),i%%isDefined("ColCaptions")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYcolcaptions)
 . s i%ColNames=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYcolnames),i%%isDefined("ColNames")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYcolnames)
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYcompilergenerated)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYdescription)
 . s i%ExtendedInfo=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYextendedinfo),i%%isDefined("ExtendedInfo")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYextendedinfo)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYfinal)
 . s i%FormalSpec=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYformalspec),i%%isDefined("FormalSpec")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYformalspec)
 . s i%FormalSpecParsed=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYformalspecparsed),i%%isDefined("FormalSpecParsed")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYformalspecparsed)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYinheritedid)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYkeywordmodified)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYnotinheritable)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYorigin)
 . s i%ParmNames=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYparmnames),i%%isDefined("ParmNames")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYparmnames)
 . s i%Private=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYprivate),i%%isDefined("Private")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYprivate)
 . s i%Requires=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYrequires),i%%isDefined("Requires")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYrequires)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsequencenumber)
 . s i%SoapBindingStyle=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle),i%%isDefined("SoapBindingStyle")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbindingstyle)
 . s i%SoapBodyUse=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse),i%%isDefined("SoapBodyUse")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsoapbodyuse)
 . s i%SoapNameSpace=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace),i%%isDefined("SoapNameSpace")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsoapnamespace)
 . s i%SqlName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsqlname),i%%isDefined("SqlName")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlname)
 . s i%SqlProc=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc),i%%isDefined("SqlProc")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlproc)
 . s i%SqlQuery=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery),i%%isDefined("SqlQuery")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquery)
 . s i%SqlQueryGen=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsqlquerygen),i%%isDefined("SqlQueryGen")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlquerygen)
 . s i%SqlView=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsqlview),i%%isDefined("SqlView")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlview)
 . s i%SqlViewName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname),i%%isDefined("SqlViewName")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYsqlviewname)
 . s i%Type=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYtype),i%%isDefined("Type")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYtype)
 . s i%UserActualType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYuseractualtype),i%%isDefined("UserActualType")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYuseractualtype)
 . s i%WebMethod=$$$comMemberKeyGetO(origin,name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod),i%%isDefined("WebMethod")=$$$comMemberKeyDefined(name1,$$$cCLASSquery,name2,$$$cQUERYwebmethod)
 . s sub="" f  s sub=$$$comSubMemberNext(name1,$$$cCLASSquery,name2,$$$cQUERYparameter,sub) q:sub=""  d
 . . d ..Parameters.SetAt($$$comMemberArrayGet(name1,$$$cCLASSquery,name2,$$$cQUERYparameter,sub),sub)
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
<Data name="Cardinality">
<RetrievalCode> s {Cardinality}=$s($d(^oddCOM({L1},"q",{L3},40))#2:^(40),$d(^oddCOM($g(^(2),{L1}),"q",{L3},40))#2:^(40),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},40))#2:^(40),1:0))
</RetrievalCode>
</Data>
<Data name="ClientInfo">
<RetrievalCode> s {ClientInfo}=$s($d(^oddCOM({L1},"q",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"q",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},21))#2:^(21),1:""))
</RetrievalCode>
</Data>
<Data name="ClientName">
<RetrievalCode> s {ClientName}=$s($d(^oddCOM({L1},"q",{L3},41))#2:^(41),$d(^oddCOM($g(^(2),{L1}),"q",{L3},41))#2:^(41),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},41))#2:^(41),1:""))
</RetrievalCode>
</Data>
<Data name="ColCaptions">
<RetrievalCode> s {ColCaptions}=$s($d(^oddCOM({L1},"q",{L3},22))#2:^(22),$d(^oddCOM($g(^(2),{L1}),"q",{L3},22))#2:^(22),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},22))#2:^(22),1:""))
</RetrievalCode>
</Data>
<Data name="ColNames">
<RetrievalCode> s {ColNames}=$s($d(^oddCOM({L1},"q",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"q",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},23))#2:^(23),1:""))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"q",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"q",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"q",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"q",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"q",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"q",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="ExtendedInfo">
<RetrievalCode> s {ExtendedInfo}=$s($d(^oddCOM({L1},"q",{L3},38))#2:^(38),$d(^oddCOM($g(^(2),{L1}),"q",{L3},38))#2:^(38),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},38))#2:^(38),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"q",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"q",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="FormalSpec">
<RetrievalCode> s {FormalSpec}=$s($d(^oddCOM({L1},"q",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"q",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="FormalSpecParsed">
<RetrievalCode> s {FormalSpecParsed}=$s($d(^oddCOM({L1},"q",{L3},34))#2:^(34),$d(^oddCOM($g(^(2),{L1}),"q",{L3},34))#2:^(34),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},34))#2:^(34),1:""))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"q",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"q",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"q",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"q",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"q",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"q",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"q",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"q",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"q",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"q",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"q",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"q",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"q",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"q",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="Parameters">
<RetrievalCode> n sub s {Parameters}="",sub="" f  s sub=$o(^oddCOM({L1},"q",{L3},"P",sub)) q:sub=""  s {Parameters}={Parameters}_$lb($lb(sub,$s($d(^oddCOM({L1},"q",{L3},"P",sub))#2:^(sub),$d(^oddCOM($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},"P",sub))#2:^(sub),1:$g(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},"P",sub)))))
</RetrievalCode>
</Data>
<Data name="ParmNames">
<RetrievalCode> s {ParmNames}=$s($d(^oddCOM({L1},"q",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"q",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},25))#2:^(25),1:""))
</RetrievalCode>
</Data>
<Data name="Private">
<RetrievalCode> s {Private}=$s($d(^oddCOM({L1},"q",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"q",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},26))#2:^(26),1:0))
</RetrievalCode>
</Data>
<Data name="Requires">
<RetrievalCode> s {Requires}=$s($d(^oddCOM({L1},"q",{L3},42))#2:^(42),$d(^oddCOM($g(^(2),{L1}),"q",{L3},42))#2:^(42),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},42))#2:^(42),1:""))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"q",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"q",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="SoapBindingStyle">
<RetrievalCode> s {SoapBindingStyle}=$s($d(^oddCOM({L1},"q",{L3},35))#2:^(35),$d(^oddCOM($g(^(2),{L1}),"q",{L3},35))#2:^(35),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},35))#2:^(35),1:""))
</RetrievalCode>
</Data>
<Data name="SoapBodyUse">
<RetrievalCode> s {SoapBodyUse}=$s($d(^oddCOM({L1},"q",{L3},36))#2:^(36),$d(^oddCOM($g(^(2),{L1}),"q",{L3},36))#2:^(36),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},36))#2:^(36),1:""))
</RetrievalCode>
</Data>
<Data name="SoapNameSpace">
<RetrievalCode> s {SoapNameSpace}=$s($d(^oddCOM({L1},"q",{L3},37))#2:^(37),$d(^oddCOM($g(^(2),{L1}),"q",{L3},37))#2:^(37),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},37))#2:^(37),1:""))
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddCOM({L1},"q",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"q",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="SqlProc">
<RetrievalCode> s {SqlProc}=$s($d(^oddCOM({L1},"q",{L3},28))#2:^(28),$d(^oddCOM($g(^(2),{L1}),"q",{L3},28))#2:^(28),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},28))#2:^(28),1:0))
</RetrievalCode>
</Data>
<Data name="SqlQuery">
<RetrievalCode> s {SqlQuery}=$s($d(^oddCOM({L1},"q",{L3},29))#2:^(29),$d(^oddCOM($g(^(2),{L1}),"q",{L3},29))#2:^(29),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},29))#2:^(29),1:""))
</RetrievalCode>
</Data>
<Data name="SqlQueryGen">
<RetrievalCode> s {SqlQueryGen}=$s($d(^oddCOM({L1},"q",{L3},39))#2:^(39),$d(^oddCOM($g(^(2),{L1}),"q",{L3},39))#2:^(39),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},39))#2:^(39),1:""))
</RetrievalCode>
</Data>
<Data name="SqlView">
<RetrievalCode> s {SqlView}=$s($d(^oddCOM({L1},"q",{L3},30))#2:^(30),$d(^oddCOM($g(^(2),{L1}),"q",{L3},30))#2:^(30),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},30))#2:^(30),1:0))
</RetrievalCode>
</Data>
<Data name="SqlViewName">
<RetrievalCode> s {SqlViewName}=$s($d(^oddCOM({L1},"q",{L3},31))#2:^(31),$d(^oddCOM($g(^(2),{L1}),"q",{L3},31))#2:^(31),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},31))#2:^(31),1:""))
</RetrievalCode>
</Data>
<Data name="Type">
<RetrievalCode> s {Type}=$s($d(^oddCOM({L1},"q",{L3},5))#2:^(5),$d(^oddCOM($g(^(2),{L1}),"q",{L3},5))#2:^(5),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},5))#2:^(5),1:""))
</RetrievalCode>
</Data>
<Data name="UserActualType">
<RetrievalCode> s {UserActualType}=$s($d(^oddCOM({L1},"q",{L3},32))#2:^(32),$d(^oddCOM($g(^(2),{L1}),"q",{L3},32))#2:^(32),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},32))#2:^(32),1:""))
</RetrievalCode>
</Data>
<Data name="WebMethod">
<RetrievalCode> s {WebMethod}=$s($d(^oddCOM({L1},"q",{L3},33))#2:^(33),$d(^oddCOM($g(^(2),{L1}),"q",{L3},33))#2:^(33),1:$s($d(^oddDEF($g(^oddCOM({L1},"q",{L3},2),{L1}),"q",{L3},33))#2:^(33),1:0))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"q"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledQuery.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledQueryS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
