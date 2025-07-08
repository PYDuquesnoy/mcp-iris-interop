/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledMethod Extends (%Persistent, %Dictionary.CompiledMethodQuery) [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledClass [ Cardinality = parent, Inverse = Methods ];

/// Stores the DEFINED state of each attribute.
Property %isDefined As %RawString [ MultiDimensional, Private, Transient ];

/// Specifies that this is an abstract method. An abstract method has no implementation and has no executable code generated for it. Abstract methods exist solely for the purpose of defining a method signature or interface that can be overridden and implemented within one or more subclasses. 
Property Abstract As %Boolean;

/// Specifies that the method is a class method.  Instance methods can only be invoked via an instantiated object while class methods can be directly invoked without an object instance. 
Property ClassMethod As %Boolean;

/// If true this method is only available on the server, and is to be projected as a client method.
Property ClientMethod As %Boolean;

/// An alias used by client projections of this method.
Property ClientName As %RawString;

/// Specifies how a given method is implemented: as a routine call, lines of code to be compiled, an expression, or a method that will generate the resulting method or object.
Property CodeMode As %RawString;

/// CompilerGenerated
Property CompilerGenerated As %Boolean;

/// DefaultArgs
Property DefaultArgs As %RawString;

/// True if this method is deprecated.
Property Deprecated As %Boolean;

/// Specifies a description of the method.
Property Description As %RawString;

/// Specifies the SQL procedure name in the foreign database.
Property ExternalProcName As %RawString;

/// Specifies that subclasses cannot override the implementation of the method.
Property Final As %Boolean;

/// When true we always regenerate this method into each subclass even if normal rules would allow us to call the superclass implementation.
Property ForceGenerate As %Boolean;

/// Specifies the list of arguments. Each argument is of the format [&amp;|*]&lt;name&gt;[:&lt;type&gt;][=&lt;default&gt;] where &amp; means pass-by-reference and * means output-only.
Property FormalSpec As %RawString;

/// FormalSpecParsed
Property FormalSpecParsed As %RawString;

/// FormalType
Property FormalType As %RawString;

/// In the case of a method generator method, specifies that the generator should be invoked after the listed methods are generated.
Property GenerateAfter As %RawString;

/// Hash
Property Hash As %RawString;

/// Id
Property Id As %Integer;

/// The code that is executed when the method is invoked. In the case of an expression method, this is an expression. In the case of a call method, this is the name of an ObjectScript routine to call.
Property Implementation As %Stream.TmpCharacter;

/// InheritedId
Property InheritedId As %Boolean;

/// If true, then do not display this item in automatic documentation.
Property Internal As %Boolean;

/// KeywordError
Property KeywordError As %Boolean;

/// KeywordModified
Property KeywordModified As %Boolean;

/// Label
Property Label As %RawString;

/// The language used to implement this method.
Property Language As %RawString [ SqlFieldName = _Language ];

/// The name of the method.
Property Name As %Dictionary.Identifier [ Required ];

/// If true and in a datatype method, this prevents the * Set %val=..prop Set $this=&quot;&quot; * that is added to the property method so you can override things like the Get/Set methods.
Property NoContext As %Boolean;

/// Deprecated.
Property NotForProperty As %Boolean;

/// Specifies that this method is not inherited in subclasses.
Property NotInheritable As %Boolean;

/// OptimizedMAC
Property OptimizedMAC As %RawString;

/// OptimizedRun
Property OptimizedRun As %RawString;

/// Origin
Property Origin As %RawString;

/// OriginalName
Property OriginalName As %RawString;

/// Specifies that the class compiler should place this method after the listed methods in the routine it creates for the class.
Property PlaceAfter As %RawString;

/// Specifies that the method is private. Private methods can only be invoked by instance methods of this class or its subclasses.
Property Private As %Boolean;

/// Specifies that this method uses procedure block for method code.
Property ProcedureBlock As %RawString;

/// Specifies the public list.  This keyword is used only if the ProcedureBlock keyword is set to true.
Property PublicList As %RawString;

/// Comma separated string of resource constraints to run this method
Property Requires As %RawString;

/// If true this method may return zero, one, or more Resultsets in the %sqlcontext.
Property ReturnResultsets As %Boolean;

/// Specifies the data type of the value returned by a call to the method. Setting ReturnType to an empty string specifies that there is no return value.
Property ReturnType As %Dictionary.Classname;

/// A comma separated list of any parameters on the ReturnType keyword.
Property ReturnTypeParams As %RawString;

/// RtnLabel
Property RtnLabel As %RawString;

/// Runnable
Property Runnable As %Integer;

/// RuntimeClient
Property RuntimeClient As %Boolean;

/// CodeMode to use for generated methods
Property RuntimeCodeMode As %RawString;

/// RuntimeHash
Property RuntimeHash As %RawString;

/// RuntimeLanguage
Property RuntimeLanguage As %RawString;

/// SequenceNumber
Property SequenceNumber As %Integer;

/// Specifies that a method will not be projected to a Java or C++ client.
Property ServerOnly As %RawString;

/// Lets you specify the HTTP SOAP action that must be used when invoking this web service method as a web method. For SOAP 1.1, the SOAP action is obtained from the SOAPAction HTTP header. For SOAP 1.2, it is obtained from the Content-Type HTTP header.
Property SoapAction As %RawString;

/// Specifies what type of SOAP invocation is used for a web method. This keyword is ignored for non-web methods.
Property SoapBindingStyle As %RawString;

/// Specifies what kind of SOAP encoding is used for the inputs and outputs of a web method. This keyword is ignored for non-web methods.
Property SoapBodyUse As %RawString;

/// Specifies the name of the child element of the body of the response message for a web service method.
Property SoapMessageName As %RawString;

/// Overrides the SOAPNAMESPACE class parameter for this web service or web service client.
Property SoapNameSpace As %RawString;

///  This keyword will reflects the expected element name for top element of the SOAP body in the SOAP request.  This element is needed to distinguish between multiple requests which have the same SoapAction but different top level body elements.
Property SoapRequestMessage As %RawString;

/// Overrides the SOAPTYPENAMESPACE class parameter for this web service or web service client.
Property SoapTypeNameSpace As %RawString;

/// If this method is projected as an SQL stored procedure, then this name is used as the name of the stored procedure.
Property SqlName As %RawString;

/// Specifies that the method can be invoked as an SQL stored procedure. Only class methods can be called as SQL stored procedures.
Property SqlProc As %Boolean;

/// If &#39;procedure&#39; then this is equivalent to SqlProc keyword and means class method can be called as an SQL procedure. If &#39;function&#39; then this class method can be called as an SQL function.
Property SqlRoutine As %RawString;

/// Stub
Property Stub As %RawString;

/// StubMember
Property StubMember As %RawString;

/// TagGenerator
Property TagGenerator As %RawString;

/// UserActualType
Property UserActualType As %RawString;

/// Specifies that a method can be invoked as a web method using the SOAP protocol.
Property WebMethod As %Boolean;

/// Specifies that the method should be projected to the web client for use in the Zen framework.
Property ZenMethod As %Boolean;

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
 i $$$comMemberDefined(name1,$$$cCLASSmethod,name2) QUIT 1
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
 i (name1="")||(name2="")||('$$$comMemberDefined(name1,$$$cCLASSmethod,name2)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,1)
 . s i%Name=name2
 . s i%Abstract=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHabstract),i%%isDefined("Abstract")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHabstract)
 . s i%ClassMethod=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHclassmethod),i%%isDefined("ClassMethod")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHclassmethod)
 . s i%ClientMethod=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHclientmethod),i%%isDefined("ClientMethod")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHclientmethod)
 . s i%ClientName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHclientname),i%%isDefined("ClientName")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHclientname)
 . s i%CodeMode=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHcodemode),i%%isDefined("CodeMode")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHcodemode)
 . s i%CompilerGenerated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHcompilergenerated)
 . s i%DefaultArgs=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHdefaultargs),i%%isDefined("DefaultArgs")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHdefaultargs)
 . s i%Deprecated=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHdeprecated),i%%isDefined("Deprecated")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHdeprecated)
 . s i%Description=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHdescription),i%%isDefined("Description")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHdescription)
 . s i%ExternalProcName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHexternalprocname),i%%isDefined("ExternalProcName")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHexternalprocname)
 . s i%Final=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHfinal),i%%isDefined("Final")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHfinal)
 . s i%ForceGenerate=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHforcegenerate),i%%isDefined("ForceGenerate")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHforcegenerate)
 . s i%FormalSpec=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHformalspec),i%%isDefined("FormalSpec")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHformalspec)
 . s i%FormalSpecParsed=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHformalspecparsed),i%%isDefined("FormalSpecParsed")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHformalspecparsed)
 . s i%FormalType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHformaltype),i%%isDefined("FormalType")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHformaltype)
 . s i%GenerateAfter=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHgenerateafter),i%%isDefined("GenerateAfter")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHgenerateafter)
 . s i%Hash=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHhash),i%%isDefined("Hash")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHhash)
 . s i%Id=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHid),i%%isDefined("Id")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHid)
 . s i%InheritedId=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHinheritedid),i%%isDefined("InheritedId")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHinheritedid)
 . s i%Internal=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHinternal),i%%isDefined("Internal")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHinternal)
 . s i%KeywordError=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHkeyworderror),i%%isDefined("KeywordError")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHkeyworderror)
 . s i%KeywordModified=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHkeywordmodified),i%%isDefined("KeywordModified")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHkeywordmodified)
 . s i%Label=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHlabel),i%%isDefined("Label")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHlabel)
 . s i%Language=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHlanguage),i%%isDefined("Language")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHlanguage)
 . s i%NoContext=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHnocontext),i%%isDefined("NoContext")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHnocontext)
 . s i%NotForProperty=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHnotforproperty),i%%isDefined("NotForProperty")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHnotforproperty)
 . s i%NotInheritable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHnotinheritable),i%%isDefined("NotInheritable")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHnotinheritable)
 . s i%OptimizedMAC=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHoptimizedmac),i%%isDefined("OptimizedMAC")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHoptimizedmac)
 . s i%OptimizedRun=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHoptimizedrun),i%%isDefined("OptimizedRun")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHoptimizedrun)
 . s i%Origin=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHorigin),i%%isDefined("Origin")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHorigin)
 . s i%OriginalName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHoriginalname),i%%isDefined("OriginalName")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHoriginalname)
 . s i%PlaceAfter=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHplaceafter),i%%isDefined("PlaceAfter")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHplaceafter)
 . s i%Private=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHprivate),i%%isDefined("Private")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHprivate)
 . s i%ProcedureBlock=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHprocedureblock),i%%isDefined("ProcedureBlock")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHprocedureblock)
 . s i%PublicList=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHpubliclist),i%%isDefined("PublicList")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHpubliclist)
 . s i%Requires=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHrequires),i%%isDefined("Requires")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHrequires)
 . s i%ReturnResultsets=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHreturnresultsets),i%%isDefined("ReturnResultsets")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHreturnresultsets)
 . s i%ReturnType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHreturntype),i%%isDefined("ReturnType")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHreturntype)
 . s i%ReturnTypeParams=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHreturntypeparams),i%%isDefined("ReturnTypeParams")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHreturntypeparams)
 . s i%RtnLabel=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHrtnlabel),i%%isDefined("RtnLabel")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHrtnlabel)
 . s i%Runnable=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHrunnable),i%%isDefined("Runnable")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHrunnable)
 . s i%RuntimeClient=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHruntimeclient),i%%isDefined("RuntimeClient")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHruntimeclient)
 . s i%RuntimeCodeMode=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHruntimecodemode),i%%isDefined("RuntimeCodeMode")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHruntimecodemode)
 . s i%RuntimeHash=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHruntimehash),i%%isDefined("RuntimeHash")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHruntimehash)
 . s i%RuntimeLanguage=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHruntimelanguage),i%%isDefined("RuntimeLanguage")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHruntimelanguage)
 . s i%SequenceNumber=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsequencenumber),i%%isDefined("SequenceNumber")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsequencenumber)
 . s i%ServerOnly=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHserveronly),i%%isDefined("ServerOnly")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHserveronly)
 . s i%SoapAction=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoapaction),i%%isDefined("SoapAction")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoapaction)
 . s i%SoapBindingStyle=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoapbindingstyle),i%%isDefined("SoapBindingStyle")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoapbindingstyle)
 . s i%SoapBodyUse=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoapbodyuse),i%%isDefined("SoapBodyUse")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoapbodyuse)
 . s i%SoapMessageName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoapmessagename),i%%isDefined("SoapMessageName")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoapmessagename)
 . s i%SoapNameSpace=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoapnamespace),i%%isDefined("SoapNameSpace")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoapnamespace)
 . s i%SoapRequestMessage=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoaprequestmessage),i%%isDefined("SoapRequestMessage")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoaprequestmessage)
 . s i%SoapTypeNameSpace=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsoaptypenamespace),i%%isDefined("SoapTypeNameSpace")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsoaptypenamespace)
 . s i%SqlName=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsqlname),i%%isDefined("SqlName")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsqlname)
 . s i%SqlProc=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsqlproc),i%%isDefined("SqlProc")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsqlproc)
 . s i%SqlRoutine=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHsqlroutine),i%%isDefined("SqlRoutine")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHsqlroutine)
 . s i%Stub=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHstub),i%%isDefined("Stub")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHstub)
 . s i%StubMember=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHstubmember),i%%isDefined("StubMember")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHstubmember)
 . s i%TagGenerator=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHtaggenerator),i%%isDefined("TagGenerator")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHtaggenerator)
 . s i%UserActualType=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHuseractualtype),i%%isDefined("UserActualType")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHuseractualtype)
 . s i%WebMethod=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHwebmethod),i%%isDefined("WebMethod")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHwebmethod)
 . s i%ZenMethod=$$$comMemberKeyGetO(origin,name1,$$$cCLASSmethod,name2,$$$cMETHzenmethod),i%%isDefined("ZenMethod")=$$$comMemberKeyDefined(name1,$$$cCLASSmethod,name2,$$$cMETHzenmethod)
 . s i%Implementation=""
 . f ptr=1:1:$$$comMemberKeyGet(name1,$$$cCLASSmethod,name2,$$$cMETHimplementation) d
 . . d ..Implementation.WriteLine($$$comMemberArrayGet(name1,$$$cCLASSmethod,name2,$$$cMETHimplementation,ptr))
 . d ..Implementation.Rewind()
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

Method ClassMethodSet(value As %String = "") As %Status
{
 set i%ClassMethod=value,i%%isDefined("ClassMethod")=1 quit $$$OK
}

Method ClassMethodReset()
{
 set i%ClassMethod=0 set i%%isDefined("ClassMethod")=0 quit
}

Method ClassMethodIsDefined() As %Boolean
{
 quit ''i%%isDefined("ClassMethod")
}

Method ClientMethodSet(value As %String = "") As %Status
{
 set i%ClientMethod=value,i%%isDefined("ClientMethod")=1 quit $$$OK
}

Method ClientMethodReset()
{
 set i%ClientMethod=0 set i%%isDefined("ClientMethod")=0 quit
}

Method ClientMethodIsDefined() As %Boolean
{
 quit ''i%%isDefined("ClientMethod")
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

Method ExternalProcNameSet(value As %String = "") As %Status
{
 set i%ExternalProcName=value,i%%isDefined("ExternalProcName")=1 quit $$$OK
}

Method ExternalProcNameReset()
{
 set i%ExternalProcName="" set i%%isDefined("ExternalProcName")=0 quit
}

Method ExternalProcNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("ExternalProcName")
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

Method ForceGenerateSet(value As %String = "") As %Status
{
 set i%ForceGenerate=value,i%%isDefined("ForceGenerate")=1 quit $$$OK
}

Method ForceGenerateReset()
{
 set i%ForceGenerate=0 set i%%isDefined("ForceGenerate")=0 quit
}

Method ForceGenerateIsDefined() As %Boolean
{
 quit ''i%%isDefined("ForceGenerate")
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

Method GenerateAfterSet(value As %String = "") As %Status
{
 set i%GenerateAfter=value,i%%isDefined("GenerateAfter")=1 quit $$$OK
}

Method GenerateAfterReset()
{
 set i%GenerateAfter="" set i%%isDefined("GenerateAfter")=0 quit
}

Method GenerateAfterIsDefined() As %Boolean
{
 quit ''i%%isDefined("GenerateAfter")
}

Method HashSet(value As %String = "") As %Status
{
 set i%Hash=value,i%%isDefined("Hash")=1 quit $$$OK
}

Method HashReset()
{
 set i%Hash="" set i%%isDefined("Hash")=0 quit
}

Method HashIsDefined() As %Boolean
{
 quit ''i%%isDefined("Hash")
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

Method NoContextSet(value As %String = "") As %Status
{
 set i%NoContext=value,i%%isDefined("NoContext")=1 quit $$$OK
}

Method NoContextReset()
{
 set i%NoContext=0 set i%%isDefined("NoContext")=0 quit
}

Method NoContextIsDefined() As %Boolean
{
 quit ''i%%isDefined("NoContext")
}

Method NotForPropertySet(value As %String = "") As %Status
{
 set i%NotForProperty=value,i%%isDefined("NotForProperty")=1 quit $$$OK
}

Method NotForPropertyReset()
{
 set i%NotForProperty=0 set i%%isDefined("NotForProperty")=0 quit
}

Method NotForPropertyIsDefined() As %Boolean
{
 quit ''i%%isDefined("NotForProperty")
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

Method PlaceAfterSet(value As %String = "") As %Status
{
 set i%PlaceAfter=value,i%%isDefined("PlaceAfter")=1 quit $$$OK
}

Method PlaceAfterReset()
{
 set i%PlaceAfter="" set i%%isDefined("PlaceAfter")=0 quit
}

Method PlaceAfterIsDefined() As %Boolean
{
 quit ''i%%isDefined("PlaceAfter")
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

Method ProcedureBlockSet(value As %String = "") As %Status
{
 set i%ProcedureBlock=value,i%%isDefined("ProcedureBlock")=1 quit $$$OK
}

Method ProcedureBlockReset()
{
 set i%ProcedureBlock="" set i%%isDefined("ProcedureBlock")=0 quit
}

Method ProcedureBlockIsDefined() As %Boolean
{
 quit ''i%%isDefined("ProcedureBlock")
}

Method PublicListSet(value As %String = "") As %Status
{
 set i%PublicList=value,i%%isDefined("PublicList")=1 quit $$$OK
}

Method PublicListReset()
{
 set i%PublicList="" set i%%isDefined("PublicList")=0 quit
}

Method PublicListIsDefined() As %Boolean
{
 quit ''i%%isDefined("PublicList")
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

Method ReturnResultsetsSet(value As %String = "") As %Status
{
 set i%ReturnResultsets=value,i%%isDefined("ReturnResultsets")=1 quit $$$OK
}

Method ReturnResultsetsReset()
{
 set i%ReturnResultsets=0 set i%%isDefined("ReturnResultsets")=0 quit
}

Method ReturnResultsetsIsDefined() As %Boolean
{
 quit ''i%%isDefined("ReturnResultsets")
}

Method ReturnTypeSet(value As %String = "") As %Status
{
 set i%ReturnType=value,i%%isDefined("ReturnType")=1 quit $$$OK
}

Method ReturnTypeReset()
{
 set i%ReturnType="" set i%%isDefined("ReturnType")=0 quit
}

Method ReturnTypeIsDefined() As %Boolean
{
 quit ''i%%isDefined("ReturnType")
}

Method ReturnTypeParamsSet(value As %String = "") As %Status
{
 set i%ReturnTypeParams=value,i%%isDefined("ReturnTypeParams")=1 quit $$$OK
}

Method ReturnTypeParamsReset()
{
 set i%ReturnTypeParams="" set i%%isDefined("ReturnTypeParams")=0 quit
}

Method ReturnTypeParamsIsDefined() As %Boolean
{
 quit ''i%%isDefined("ReturnTypeParams")
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

Method ServerOnlySet(value As %String = "") As %Status
{
 set i%ServerOnly=value,i%%isDefined("ServerOnly")=1 quit $$$OK
}

Method ServerOnlyReset()
{
 set i%ServerOnly="" set i%%isDefined("ServerOnly")=0 quit
}

Method ServerOnlyIsDefined() As %Boolean
{
 quit ''i%%isDefined("ServerOnly")
}

Method SoapActionSet(value As %String = "") As %Status
{
 set i%SoapAction=value,i%%isDefined("SoapAction")=1 quit $$$OK
}

Method SoapActionReset()
{
 set i%SoapAction="[default]" set i%%isDefined("SoapAction")=0 quit
}

Method SoapActionIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapAction")
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

Method SoapMessageNameSet(value As %String = "") As %Status
{
 set i%SoapMessageName=value,i%%isDefined("SoapMessageName")=1 quit $$$OK
}

Method SoapMessageNameReset()
{
 set i%SoapMessageName="" set i%%isDefined("SoapMessageName")=0 quit
}

Method SoapMessageNameIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapMessageName")
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

Method SoapRequestMessageSet(value As %String = "") As %Status
{
 set i%SoapRequestMessage=value,i%%isDefined("SoapRequestMessage")=1 quit $$$OK
}

Method SoapRequestMessageReset()
{
 set i%SoapRequestMessage="" set i%%isDefined("SoapRequestMessage")=0 quit
}

Method SoapRequestMessageIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapRequestMessage")
}

Method SoapTypeNameSpaceSet(value As %String = "") As %Status
{
 set i%SoapTypeNameSpace=value,i%%isDefined("SoapTypeNameSpace")=1 quit $$$OK
}

Method SoapTypeNameSpaceReset()
{
 set i%SoapTypeNameSpace="" set i%%isDefined("SoapTypeNameSpace")=0 quit
}

Method SoapTypeNameSpaceIsDefined() As %Boolean
{
 quit ''i%%isDefined("SoapTypeNameSpace")
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

Method SqlRoutineSet(value As %String = "") As %Status
{
 set i%SqlRoutine=value,i%%isDefined("SqlRoutine")=1 quit $$$OK
}

Method SqlRoutineReset()
{
 set i%SqlRoutine="" set i%%isDefined("SqlRoutine")=0 quit
}

Method SqlRoutineIsDefined() As %Boolean
{
 quit ''i%%isDefined("SqlRoutine")
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

Method ZenMethodSet(value As %String = "") As %Status
{
 set i%ZenMethod=value,i%%isDefined("ZenMethod")=1 quit $$$OK
}

Method ZenMethodReset()
{
 set i%ZenMethod=0 set i%%isDefined("ZenMethod")=0 quit
}

Method ZenMethodIsDefined() As %Boolean
{
 quit ''i%%isDefined("ZenMethod")
}

ClassMethod parentOnDelete(id As %String, concurrency As %Integer) As %Status
{
 Quit $$$OK
}

Storage custom
{
<SQLMap name="Master">
<Data name="Abstract">
<RetrievalCode> s {Abstract}=$s($d(^oddCOM({L1},"m",{L3},21))#2:^(21),$d(^oddCOM($g(^(2),{L1}),"m",{L3},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},21))#2:^(21),1:0))
</RetrievalCode>
</Data>
<Data name="ClassMethod">
<RetrievalCode> s {ClassMethod}=$s($d(^oddCOM({L1},"m",{L3},23))#2:^(23),$d(^oddCOM($g(^(2),{L1}),"m",{L3},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},23))#2:^(23),1:0))
</RetrievalCode>
</Data>
<Data name="ClientMethod">
<RetrievalCode> s {ClientMethod}=$s($d(^oddCOM({L1},"m",{L3},70))#2:^(70),$d(^oddCOM($g(^(2),{L1}),"m",{L3},70))#2:^(70),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},70))#2:^(70),1:0))
</RetrievalCode>
</Data>
<Data name="ClientName">
<RetrievalCode> s {ClientName}=$s($d(^oddCOM({L1},"m",{L3},24))#2:^(24),$d(^oddCOM($g(^(2),{L1}),"m",{L3},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="CodeMode">
<RetrievalCode> s {CodeMode}=$s($d(^oddCOM({L1},"m",{L3},25))#2:^(25),$d(^oddCOM($g(^(2),{L1}),"m",{L3},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},25))#2:^(25),1:"code"))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"m",{L3},10))#2:^(10),$d(^oddCOM($g(^(2),{L1}),"m",{L3},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="DefaultArgs">
<RetrievalCode> s {DefaultArgs}=$s($d(^oddCOM({L1},"m",{L3},26))#2:^(26),$d(^oddCOM($g(^(2),{L1}),"m",{L3},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"m",{L3},17))#2:^(17),$d(^oddCOM($g(^(2),{L1}),"m",{L3},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"m",{L3},4))#2:^(4),$d(^oddCOM($g(^(2),{L1}),"m",{L3},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="ExternalProcName">
<RetrievalCode> s {ExternalProcName}=$s($d(^oddCOM({L1},"m",{L3},63))#2:^(63),$d(^oddCOM($g(^(2),{L1}),"m",{L3},63))#2:^(63),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},63))#2:^(63),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"m",{L3},7))#2:^(7),$d(^oddCOM($g(^(2),{L1}),"m",{L3},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="ForceGenerate">
<RetrievalCode> s {ForceGenerate}=$s($d(^oddCOM({L1},"m",{L3},71))#2:^(71),$d(^oddCOM($g(^(2),{L1}),"m",{L3},71))#2:^(71),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},71))#2:^(71),1:0))
</RetrievalCode>
</Data>
<Data name="FormalSpec">
<RetrievalCode> s {FormalSpec}=$s($d(^oddCOM({L1},"m",{L3},27))#2:^(27),$d(^oddCOM($g(^(2),{L1}),"m",{L3},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="FormalSpecParsed">
<RetrievalCode> s {FormalSpecParsed}=$s($d(^oddCOM({L1},"m",{L3},60))#2:^(60),$d(^oddCOM($g(^(2),{L1}),"m",{L3},60))#2:^(60),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},60))#2:^(60),1:""))
</RetrievalCode>
</Data>
<Data name="FormalType">
<RetrievalCode> s {FormalType}=$s($d(^oddCOM({L1},"m",{L3},28))#2:^(28),$d(^oddCOM($g(^(2),{L1}),"m",{L3},28))#2:^(28),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},28))#2:^(28),1:""))
</RetrievalCode>
</Data>
<Data name="GenerateAfter">
<RetrievalCode> s {GenerateAfter}=$s($d(^oddCOM({L1},"m",{L3},29))#2:^(29),$d(^oddCOM($g(^(2),{L1}),"m",{L3},29))#2:^(29),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},29))#2:^(29),1:""))
</RetrievalCode>
</Data>
<Data name="Hash">
<RetrievalCode> s {Hash}=$s($d(^oddCOM({L1},"m",{L3},66))#2:^(66),$d(^oddCOM($g(^(2),{L1}),"m",{L3},66))#2:^(66),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},66))#2:^(66),1:""))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"m",{L3},6))#2:^(6),$d(^oddCOM($g(^(2),{L1}),"m",{L3},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="Implementation">
<RetrievalCode> s {Implementation}=""
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"m",{L3},8))#2:^(8),$d(^oddCOM($g(^(2),{L1}),"m",{L3},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"m",{L3},14))#2:^(14),$d(^oddCOM($g(^(2),{L1}),"m",{L3},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"m",{L3},12))#2:^(12),$d(^oddCOM($g(^(2),{L1}),"m",{L3},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"m",{L3},13))#2:^(13),$d(^oddCOM($g(^(2),{L1}),"m",{L3},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="Label">
<RetrievalCode> s {Label}=$s($d(^oddCOM({L1},"m",{L3},31))#2:^(31),$d(^oddCOM($g(^(2),{L1}),"m",{L3},31))#2:^(31),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},31))#2:^(31),1:""))
</RetrievalCode>
</Data>
<Data name="NoContext">
<RetrievalCode> s {NoContext}=$s($d(^oddCOM({L1},"m",{L3},33))#2:^(33),$d(^oddCOM($g(^(2),{L1}),"m",{L3},33))#2:^(33),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},33))#2:^(33),1:0))
</RetrievalCode>
</Data>
<Data name="NotForProperty">
<RetrievalCode> s {NotForProperty}=$s($d(^oddCOM({L1},"m",{L3},34))#2:^(34),$d(^oddCOM($g(^(2),{L1}),"m",{L3},34))#2:^(34),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},34))#2:^(34),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"m",{L3},9))#2:^(9),$d(^oddCOM($g(^(2),{L1}),"m",{L3},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="OptimizedMAC">
<RetrievalCode> s {OptimizedMAC}=$s($d(^oddCOM({L1},"m",{L3},35))#2:^(35),$d(^oddCOM($g(^(2),{L1}),"m",{L3},35))#2:^(35),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},35))#2:^(35),1:""))
</RetrievalCode>
</Data>
<Data name="OptimizedRun">
<RetrievalCode> s {OptimizedRun}=$s($d(^oddCOM({L1},"m",{L3},36))#2:^(36),$d(^oddCOM($g(^(2),{L1}),"m",{L3},36))#2:^(36),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},36))#2:^(36),1:""))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"m",{L3},2))#2:^(2),$d(^oddCOM($g(^(2),{L1}),"m",{L3},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="OriginalName">
<RetrievalCode> s {OriginalName}=$s($d(^oddCOM({L1},"m",{L3},37))#2:^(37),$d(^oddCOM($g(^(2),{L1}),"m",{L3},37))#2:^(37),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},37))#2:^(37),1:""))
</RetrievalCode>
</Data>
<Data name="PlaceAfter">
<RetrievalCode> s {PlaceAfter}=$s($d(^oddCOM({L1},"m",{L3},38))#2:^(38),$d(^oddCOM($g(^(2),{L1}),"m",{L3},38))#2:^(38),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},38))#2:^(38),1:""))
</RetrievalCode>
</Data>
<Data name="Private">
<RetrievalCode> s {Private}=$s($d(^oddCOM({L1},"m",{L3},39))#2:^(39),$d(^oddCOM($g(^(2),{L1}),"m",{L3},39))#2:^(39),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},39))#2:^(39),1:0))
</RetrievalCode>
</Data>
<Data name="ProcedureBlock">
<RetrievalCode> s {ProcedureBlock}=$s($d(^oddCOM({L1},"m",{L3},40))#2:^(40),$d(^oddCOM($g(^(2),{L1}),"m",{L3},40))#2:^(40),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},40))#2:^(40),1:""))
</RetrievalCode>
</Data>
<Data name="PublicList">
<RetrievalCode> s {PublicList}=$s($d(^oddCOM({L1},"m",{L3},41))#2:^(41),$d(^oddCOM($g(^(2),{L1}),"m",{L3},41))#2:^(41),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},41))#2:^(41),1:""))
</RetrievalCode>
</Data>
<Data name="Requires">
<RetrievalCode> s {Requires}=$s($d(^oddCOM({L1},"m",{L3},75))#2:^(75),$d(^oddCOM($g(^(2),{L1}),"m",{L3},75))#2:^(75),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},75))#2:^(75),1:""))
</RetrievalCode>
</Data>
<Data name="ReturnResultsets">
<RetrievalCode> s {ReturnResultsets}=$s($d(^oddCOM({L1},"m",{L3},64))#2:^(64),$d(^oddCOM($g(^(2),{L1}),"m",{L3},64))#2:^(64),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},64))#2:^(64),1:0))
</RetrievalCode>
</Data>
<Data name="ReturnType">
<RetrievalCode> s {ReturnType}=$s($d(^oddCOM({L1},"m",{L3},42))#2:^(42),$d(^oddCOM($g(^(2),{L1}),"m",{L3},42))#2:^(42),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},42))#2:^(42),1:""))
</RetrievalCode>
</Data>
<Data name="ReturnTypeParams">
<RetrievalCode> s {ReturnTypeParams}=$s($d(^oddCOM({L1},"m",{L3},62))#2:^(62),$d(^oddCOM($g(^(2),{L1}),"m",{L3},62))#2:^(62),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},62))#2:^(62),1:""))
</RetrievalCode>
</Data>
<Data name="RtnLabel">
<RetrievalCode> s {RtnLabel}=$s($d(^oddCOM({L1},"m",{L3},43))#2:^(43),$d(^oddCOM($g(^(2),{L1}),"m",{L3},43))#2:^(43),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},43))#2:^(43),1:""))
</RetrievalCode>
</Data>
<Data name="Runnable">
<RetrievalCode> s {Runnable}=$s($d(^oddCOM({L1},"m",{L3},44))#2:^(44),$d(^oddCOM($g(^(2),{L1}),"m",{L3},44))#2:^(44),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},44))#2:^(44),1:0))
</RetrievalCode>
</Data>
<Data name="RuntimeClient">
<RetrievalCode> s {RuntimeClient}=$s($d(^oddCOM({L1},"m",{L3},55))#2:^(55),$d(^oddCOM($g(^(2),{L1}),"m",{L3},55))#2:^(55),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},55))#2:^(55),1:0))
</RetrievalCode>
</Data>
<Data name="RuntimeCodeMode">
<RetrievalCode> s {RuntimeCodeMode}=$s($d(^oddCOM({L1},"m",{L3},56))#2:^(56),$d(^oddCOM($g(^(2),{L1}),"m",{L3},56))#2:^(56),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},56))#2:^(56),1:"code"))
</RetrievalCode>
</Data>
<Data name="RuntimeHash">
<RetrievalCode> s {RuntimeHash}=$s($d(^oddCOM({L1},"m",{L3},69))#2:^(69),$d(^oddCOM($g(^(2),{L1}),"m",{L3},69))#2:^(69),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},69))#2:^(69),1:""))
</RetrievalCode>
</Data>
<Data name="RuntimeLanguage">
<RetrievalCode> s {RuntimeLanguage}=$s($d(^oddCOM({L1},"m",{L3},58))#2:^(58),$d(^oddCOM($g(^(2),{L1}),"m",{L3},58))#2:^(58),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},58))#2:^(58),1:"objectscript"))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"m",{L3},11))#2:^(11),$d(^oddCOM($g(^(2),{L1}),"m",{L3},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="ServerOnly">
<RetrievalCode> s {ServerOnly}=$s($d(^oddCOM({L1},"m",{L3},59))#2:^(59),$d(^oddCOM($g(^(2),{L1}),"m",{L3},59))#2:^(59),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},59))#2:^(59),1:""))
</RetrievalCode>
</Data>
<Data name="SoapAction">
<RetrievalCode> s {SoapAction}=$s($d(^oddCOM({L1},"m",{L3},67))#2:^(67),$d(^oddCOM($g(^(2),{L1}),"m",{L3},67))#2:^(67),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},67))#2:^(67),1:"[default]"))
</RetrievalCode>
</Data>
<Data name="SoapBindingStyle">
<RetrievalCode> s {SoapBindingStyle}=$s($d(^oddCOM({L1},"m",{L3},53))#2:^(53),$d(^oddCOM($g(^(2),{L1}),"m",{L3},53))#2:^(53),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},53))#2:^(53),1:""))
</RetrievalCode>
</Data>
<Data name="SoapBodyUse">
<RetrievalCode> s {SoapBodyUse}=$s($d(^oddCOM({L1},"m",{L3},54))#2:^(54),$d(^oddCOM($g(^(2),{L1}),"m",{L3},54))#2:^(54),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},54))#2:^(54),1:""))
</RetrievalCode>
</Data>
<Data name="SoapMessageName">
<RetrievalCode> s {SoapMessageName}=$s($d(^oddCOM({L1},"m",{L3},68))#2:^(68),$d(^oddCOM($g(^(2),{L1}),"m",{L3},68))#2:^(68),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},68))#2:^(68),1:""))
</RetrievalCode>
</Data>
<Data name="SoapNameSpace">
<RetrievalCode> s {SoapNameSpace}=$s($d(^oddCOM({L1},"m",{L3},61))#2:^(61),$d(^oddCOM($g(^(2),{L1}),"m",{L3},61))#2:^(61),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},61))#2:^(61),1:""))
</RetrievalCode>
</Data>
<Data name="SoapRequestMessage">
<RetrievalCode> s {SoapRequestMessage}=$s($d(^oddCOM({L1},"m",{L3},73))#2:^(73),$d(^oddCOM($g(^(2),{L1}),"m",{L3},73))#2:^(73),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},73))#2:^(73),1:""))
</RetrievalCode>
</Data>
<Data name="SoapTypeNameSpace">
<RetrievalCode> s {SoapTypeNameSpace}=$s($d(^oddCOM({L1},"m",{L3},65))#2:^(65),$d(^oddCOM($g(^(2),{L1}),"m",{L3},65))#2:^(65),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},65))#2:^(65),1:""))
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddCOM({L1},"m",{L3},45))#2:^(45),$d(^oddCOM($g(^(2),{L1}),"m",{L3},45))#2:^(45),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},45))#2:^(45),1:""))
</RetrievalCode>
</Data>
<Data name="SqlProc">
<RetrievalCode> s {SqlProc}=$s($d(^oddCOM({L1},"m",{L3},46))#2:^(46),$d(^oddCOM($g(^(2),{L1}),"m",{L3},46))#2:^(46),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},46))#2:^(46),1:0))
</RetrievalCode>
</Data>
<Data name="SqlRoutine">
<RetrievalCode> s {SqlRoutine}=$s($d(^oddCOM({L1},"m",{L3},74))#2:^(74),$d(^oddCOM($g(^(2),{L1}),"m",{L3},74))#2:^(74),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},74))#2:^(74),1:""))
</RetrievalCode>
</Data>
<Data name="Stub">
<RetrievalCode> s {Stub}=$s($d(^oddCOM({L1},"m",{L3},47))#2:^(47),$d(^oddCOM($g(^(2),{L1}),"m",{L3},47))#2:^(47),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},47))#2:^(47),1:""))
</RetrievalCode>
</Data>
<Data name="StubMember">
<RetrievalCode> s {StubMember}=$s($d(^oddCOM({L1},"m",{L3},72))#2:^(72),$d(^oddCOM($g(^(2),{L1}),"m",{L3},72))#2:^(72),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},72))#2:^(72),1:""))
</RetrievalCode>
</Data>
<Data name="TagGenerator">
<RetrievalCode> s {TagGenerator}=$s($d(^oddCOM({L1},"m",{L3},48))#2:^(48),$d(^oddCOM($g(^(2),{L1}),"m",{L3},48))#2:^(48),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},48))#2:^(48),1:""))
</RetrievalCode>
</Data>
<Data name="UserActualType">
<RetrievalCode> s {UserActualType}=$s($d(^oddCOM({L1},"m",{L3},50))#2:^(50),$d(^oddCOM($g(^(2),{L1}),"m",{L3},50))#2:^(50),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},50))#2:^(50),1:""))
</RetrievalCode>
</Data>
<Data name="WebMethod">
<RetrievalCode> s {WebMethod}=$s($d(^oddCOM({L1},"m",{L3},51))#2:^(51),$d(^oddCOM($g(^(2),{L1}),"m",{L3},51))#2:^(51),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},51))#2:^(51),1:0))
</RetrievalCode>
</Data>
<Data name="ZenMethod">
<RetrievalCode> s {ZenMethod}=$s($d(^oddCOM({L1},"m",{L3},52))#2:^(52),$d(^oddCOM($g(^(2),{L1}),"m",{L3},52))#2:^(52),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},52))#2:^(52),1:0))
</RetrievalCode>
</Data>
<Data name="_Language">
<RetrievalCode> s {_Language}=$s($d(^oddCOM({L1},"m",{L3},32))#2:^(32),$d(^oddCOM($g(^(2),{L1}),"m",{L3},32))#2:^(32),1:$s($d(^oddDEF($g(^oddCOM({L1},"m",{L3},2),{L1}),"m",{L3},32))#2:^(32),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"m"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledMethod.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledMethodS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
