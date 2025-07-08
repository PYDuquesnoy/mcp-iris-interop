/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Dictionary.CompiledPropertyMethod Extends %Persistent [ StorageStrategy = custom, System = 2 ]
{

/// Pointer to the containing parent object
Relationship parent As %Dictionary.CompiledProperty [ Cardinality = parent, Inverse = Methods ];

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
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$LockClassRef^%occLock(name1,shared,.timeout)
}

ClassMethod %UnlockId(id As %String, shared As %Boolean = 0, immediate As %Boolean = 0) As %Status
{
 QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 QUIT $$UnlockClassRef^%occLock(name1,shared,immediate)
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 s $zt="TrapExists"
 s id=$$$oidPrimary(oid) QUIT:id="" $$$ERROR($$$NullId)
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 i (name1="")||(name2="")||(name3="") QUIT 0
 i '$$$defClassDefined(name1)||($$$defClassKeyGet(name1,$$$cCLASSdeployed)=2) QUIT 0
 i $$$comSubMemberDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3) QUIT 1
 QUIT 0
TrapExists s $zt=""
 QUIT 0
}

Method %LoadData(id As %String) As %Status [ Private ]
{
 s name1=$p(id,"||",1),name2=$p(id,"||",2),name3=$p(id,"||",3)
 s sc=$$$OK
 s $zt="trap"
 i i%%Concurrency>0 s sc=..%LockId(id,i%%Concurrency'=4) If $$$ISERR(sc) Quit sc
 i (name1="")||(name2="")||(name3="")||('$$$comSubMemberDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3)) s sc=$$$ERROR($$$LoadObjectNotFound,$classname(),id)
 i $$$ISOK(sc),$$$defClassKeyGet(name1,$$$cCLASSdeployed)=2 s sc=$$$ERROR($$$ClassIsStub,name1)
 i $$$ISOK(sc),$$$defClassVersionGet(name1)'=$$$CLASSDEFINITIONVERSION Set sc=$$Upgrade^%occConvert("/nodisplay",,name1)
 i $$$ISOK(sc) d
 . s i%parent=$p(id,"||",1,2)
 . s i%Name=name3
 . s i%Abstract=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHabstract),i%%isDefined("Abstract")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHabstract)
 . s i%ClassMethod=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHclassmethod),i%%isDefined("ClassMethod")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHclassmethod)
 . s i%ClientMethod=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHclientmethod),i%%isDefined("ClientMethod")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHclientmethod)
 . s i%ClientName=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHclientname),i%%isDefined("ClientName")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHclientname)
 . s i%CodeMode=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHcodemode),i%%isDefined("CodeMode")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHcodemode)
 . s i%CompilerGenerated=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHcompilergenerated),i%%isDefined("CompilerGenerated")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHcompilergenerated)
 . s i%DefaultArgs=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHdefaultargs),i%%isDefined("DefaultArgs")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHdefaultargs)
 . s i%Deprecated=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHdeprecated),i%%isDefined("Deprecated")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHdeprecated)
 . s i%Description=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHdescription),i%%isDefined("Description")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHdescription)
 . s i%ExternalProcName=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHexternalprocname),i%%isDefined("ExternalProcName")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHexternalprocname)
 . s i%Final=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHfinal),i%%isDefined("Final")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHfinal)
 . s i%ForceGenerate=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHforcegenerate),i%%isDefined("ForceGenerate")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHforcegenerate)
 . s i%FormalSpec=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHformalspec),i%%isDefined("FormalSpec")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHformalspec)
 . s i%FormalSpecParsed=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHformalspecparsed),i%%isDefined("FormalSpecParsed")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHformalspecparsed)
 . s i%FormalType=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHformaltype),i%%isDefined("FormalType")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHformaltype)
 . s i%GenerateAfter=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHgenerateafter),i%%isDefined("GenerateAfter")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHgenerateafter)
 . s i%Hash=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHhash),i%%isDefined("Hash")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHhash)
 . s i%Id=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHid),i%%isDefined("Id")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHid)
 . s i%InheritedId=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHinheritedid),i%%isDefined("InheritedId")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHinheritedid)
 . s i%Internal=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHinternal),i%%isDefined("Internal")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHinternal)
 . s i%KeywordError=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHkeyworderror),i%%isDefined("KeywordError")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHkeyworderror)
 . s i%KeywordModified=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHkeywordmodified),i%%isDefined("KeywordModified")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHkeywordmodified)
 . s i%Label=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHlabel),i%%isDefined("Label")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHlabel)
 . s i%Language=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHlanguage),i%%isDefined("Language")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHlanguage)
 . s i%NoContext=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHnocontext),i%%isDefined("NoContext")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHnocontext)
 . s i%NotForProperty=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHnotforproperty),i%%isDefined("NotForProperty")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHnotforproperty)
 . s i%NotInheritable=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHnotinheritable),i%%isDefined("NotInheritable")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHnotinheritable)
 . s i%OptimizedMAC=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHoptimizedmac),i%%isDefined("OptimizedMAC")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHoptimizedmac)
 . s i%OptimizedRun=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHoptimizedrun),i%%isDefined("OptimizedRun")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHoptimizedrun)
 . s i%Origin=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHorigin),i%%isDefined("Origin")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHorigin)
 . s i%OriginalName=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHoriginalname),i%%isDefined("OriginalName")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHoriginalname)
 . s i%PlaceAfter=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHplaceafter),i%%isDefined("PlaceAfter")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHplaceafter)
 . s i%Private=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHprivate),i%%isDefined("Private")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHprivate)
 . s i%ProcedureBlock=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHprocedureblock),i%%isDefined("ProcedureBlock")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHprocedureblock)
 . s i%PublicList=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHpubliclist),i%%isDefined("PublicList")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHpubliclist)
 . s i%Requires=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHrequires),i%%isDefined("Requires")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHrequires)
 . s i%ReturnResultsets=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHreturnresultsets),i%%isDefined("ReturnResultsets")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHreturnresultsets)
 . s i%ReturnType=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHreturntype),i%%isDefined("ReturnType")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHreturntype)
 . s i%ReturnTypeParams=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHreturntypeparams),i%%isDefined("ReturnTypeParams")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHreturntypeparams)
 . s i%RtnLabel=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHrtnlabel),i%%isDefined("RtnLabel")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHrtnlabel)
 . s i%Runnable=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHrunnable),i%%isDefined("Runnable")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHrunnable)
 . s i%RuntimeClient=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimeclient),i%%isDefined("RuntimeClient")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimeclient)
 . s i%RuntimeCodeMode=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimecodemode),i%%isDefined("RuntimeCodeMode")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimecodemode)
 . s i%RuntimeHash=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimehash),i%%isDefined("RuntimeHash")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimehash)
 . s i%RuntimeLanguage=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimelanguage),i%%isDefined("RuntimeLanguage")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHruntimelanguage)
 . s i%SequenceNumber=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsequencenumber),i%%isDefined("SequenceNumber")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsequencenumber)
 . s i%ServerOnly=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHserveronly),i%%isDefined("ServerOnly")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHserveronly)
 . s i%SoapAction=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapaction),i%%isDefined("SoapAction")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapaction)
 . s i%SoapBindingStyle=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapbindingstyle),i%%isDefined("SoapBindingStyle")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapbindingstyle)
 . s i%SoapBodyUse=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapbodyuse),i%%isDefined("SoapBodyUse")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapbodyuse)
 . s i%SoapMessageName=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapmessagename),i%%isDefined("SoapMessageName")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapmessagename)
 . s i%SoapNameSpace=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapnamespace),i%%isDefined("SoapNameSpace")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoapnamespace)
 . s i%SoapRequestMessage=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoaprequestmessage),i%%isDefined("SoapRequestMessage")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoaprequestmessage)
 . s i%SoapTypeNameSpace=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoaptypenamespace),i%%isDefined("SoapTypeNameSpace")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsoaptypenamespace)
 . s i%SqlName=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsqlname),i%%isDefined("SqlName")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsqlname)
 . s i%SqlProc=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsqlproc),i%%isDefined("SqlProc")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsqlproc)
 . s i%SqlRoutine=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsqlroutine),i%%isDefined("SqlRoutine")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHsqlroutine)
 . s i%Stub=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHstub),i%%isDefined("Stub")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHstub)
 . s i%StubMember=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHstubmember),i%%isDefined("StubMember")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHstubmember)
 . s i%TagGenerator=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHtaggenerator),i%%isDefined("TagGenerator")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHtaggenerator)
 . s i%UserActualType=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHuseractualtype),i%%isDefined("UserActualType")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHuseractualtype)
 . s i%WebMethod=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHwebmethod),i%%isDefined("WebMethod")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHwebmethod)
 . s i%ZenMethod=$$$comSubMemberKeyGetO(origin,name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHzenmethod),i%%isDefined("ZenMethod")=$$$comSubMemberKeyDefined(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHzenmethod)
 . s i%Implementation=""
 . f ptr=1:1:$$$comSubMemberKeyGet(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHimplementation) d
 . . d ..Implementation.WriteLine($$$comSubMemberArrayGet(name1,$$$cCLASSproperty,name2,$$$cPROPmethod,name3,$$$cMETHimplementation,ptr))
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
<RetrievalCode> s {Abstract}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},21))#2:^(21),$d(^oddCOM($g(^(2),"*"),"m",{L5},21))#2:^(21),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},21))#2:^(21),1:0))
</RetrievalCode>
</Data>
<Data name="ClassMethod">
<RetrievalCode> s {ClassMethod}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},23))#2:^(23),$d(^oddCOM($g(^(2),"*"),"m",{L5},23))#2:^(23),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},23))#2:^(23),1:0))
</RetrievalCode>
</Data>
<Data name="ClientMethod">
<RetrievalCode> s {ClientMethod}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},70))#2:^(70),$d(^oddCOM($g(^(2),"*"),"m",{L5},70))#2:^(70),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},70))#2:^(70),1:0))
</RetrievalCode>
</Data>
<Data name="ClientName">
<RetrievalCode> s {ClientName}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},24))#2:^(24),$d(^oddCOM($g(^(2),"*"),"m",{L5},24))#2:^(24),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},24))#2:^(24),1:""))
</RetrievalCode>
</Data>
<Data name="CodeMode">
<RetrievalCode> s {CodeMode}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},25))#2:^(25),$d(^oddCOM($g(^(2),"*"),"m",{L5},25))#2:^(25),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},25))#2:^(25),1:"code"))
</RetrievalCode>
</Data>
<Data name="CompilerGenerated">
<RetrievalCode> s {CompilerGenerated}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},10))#2:^(10),$d(^oddCOM($g(^(2),"*"),"m",{L5},10))#2:^(10),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},10))#2:^(10),1:0))
</RetrievalCode>
</Data>
<Data name="DefaultArgs">
<RetrievalCode> s {DefaultArgs}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},26))#2:^(26),$d(^oddCOM($g(^(2),"*"),"m",{L5},26))#2:^(26),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},26))#2:^(26),1:""))
</RetrievalCode>
</Data>
<Data name="Deprecated">
<RetrievalCode> s {Deprecated}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},17))#2:^(17),$d(^oddCOM($g(^(2),"*"),"m",{L5},17))#2:^(17),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},17))#2:^(17),1:0))
</RetrievalCode>
</Data>
<Data name="Description">
<RetrievalCode> s {Description}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},4))#2:^(4),$d(^oddCOM($g(^(2),"*"),"m",{L5},4))#2:^(4),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},4))#2:^(4),1:""))
</RetrievalCode>
</Data>
<Data name="ExternalProcName">
<RetrievalCode> s {ExternalProcName}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},63))#2:^(63),$d(^oddCOM($g(^(2),"*"),"m",{L5},63))#2:^(63),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},63))#2:^(63),1:""))
</RetrievalCode>
</Data>
<Data name="Final">
<RetrievalCode> s {Final}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},7))#2:^(7),$d(^oddCOM($g(^(2),"*"),"m",{L5},7))#2:^(7),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},7))#2:^(7),1:0))
</RetrievalCode>
</Data>
<Data name="ForceGenerate">
<RetrievalCode> s {ForceGenerate}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},71))#2:^(71),$d(^oddCOM($g(^(2),"*"),"m",{L5},71))#2:^(71),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},71))#2:^(71),1:0))
</RetrievalCode>
</Data>
<Data name="FormalSpec">
<RetrievalCode> s {FormalSpec}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},27))#2:^(27),$d(^oddCOM($g(^(2),"*"),"m",{L5},27))#2:^(27),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},27))#2:^(27),1:""))
</RetrievalCode>
</Data>
<Data name="FormalSpecParsed">
<RetrievalCode> s {FormalSpecParsed}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},60))#2:^(60),$d(^oddCOM($g(^(2),"*"),"m",{L5},60))#2:^(60),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},60))#2:^(60),1:""))
</RetrievalCode>
</Data>
<Data name="FormalType">
<RetrievalCode> s {FormalType}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},28))#2:^(28),$d(^oddCOM($g(^(2),"*"),"m",{L5},28))#2:^(28),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},28))#2:^(28),1:""))
</RetrievalCode>
</Data>
<Data name="GenerateAfter">
<RetrievalCode> s {GenerateAfter}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},29))#2:^(29),$d(^oddCOM($g(^(2),"*"),"m",{L5},29))#2:^(29),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},29))#2:^(29),1:""))
</RetrievalCode>
</Data>
<Data name="Hash">
<RetrievalCode> s {Hash}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},66))#2:^(66),$d(^oddCOM($g(^(2),"*"),"m",{L5},66))#2:^(66),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},66))#2:^(66),1:""))
</RetrievalCode>
</Data>
<Data name="Id">
<RetrievalCode> s {Id}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},6))#2:^(6),$d(^oddCOM($g(^(2),"*"),"m",{L5},6))#2:^(6),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},6))#2:^(6),1:0))
</RetrievalCode>
</Data>
<Data name="Implementation">
<RetrievalCode> s {Implementation}=""
</RetrievalCode>
</Data>
<Data name="InheritedId">
<RetrievalCode> s {InheritedId}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},8))#2:^(8),$d(^oddCOM($g(^(2),"*"),"m",{L5},8))#2:^(8),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},8))#2:^(8),1:0))
</RetrievalCode>
</Data>
<Data name="Internal">
<RetrievalCode> s {Internal}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},14))#2:^(14),$d(^oddCOM($g(^(2),"*"),"m",{L5},14))#2:^(14),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},14))#2:^(14),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordError">
<RetrievalCode> s {KeywordError}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},12))#2:^(12),$d(^oddCOM($g(^(2),"*"),"m",{L5},12))#2:^(12),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},12))#2:^(12),1:0))
</RetrievalCode>
</Data>
<Data name="KeywordModified">
<RetrievalCode> s {KeywordModified}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},13))#2:^(13),$d(^oddCOM($g(^(2),"*"),"m",{L5},13))#2:^(13),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},13))#2:^(13),1:0))
</RetrievalCode>
</Data>
<Data name="Label">
<RetrievalCode> s {Label}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},31))#2:^(31),$d(^oddCOM($g(^(2),"*"),"m",{L5},31))#2:^(31),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},31))#2:^(31),1:""))
</RetrievalCode>
</Data>
<Data name="NoContext">
<RetrievalCode> s {NoContext}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},33))#2:^(33),$d(^oddCOM($g(^(2),"*"),"m",{L5},33))#2:^(33),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},33))#2:^(33),1:0))
</RetrievalCode>
</Data>
<Data name="NotForProperty">
<RetrievalCode> s {NotForProperty}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},34))#2:^(34),$d(^oddCOM($g(^(2),"*"),"m",{L5},34))#2:^(34),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},34))#2:^(34),1:0))
</RetrievalCode>
</Data>
<Data name="NotInheritable">
<RetrievalCode> s {NotInheritable}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},9))#2:^(9),$d(^oddCOM($g(^(2),"*"),"m",{L5},9))#2:^(9),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},9))#2:^(9),1:0))
</RetrievalCode>
</Data>
<Data name="OptimizedMAC">
<RetrievalCode> s {OptimizedMAC}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},35))#2:^(35),$d(^oddCOM($g(^(2),"*"),"m",{L5},35))#2:^(35),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},35))#2:^(35),1:""))
</RetrievalCode>
</Data>
<Data name="OptimizedRun">
<RetrievalCode> s {OptimizedRun}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},36))#2:^(36),$d(^oddCOM($g(^(2),"*"),"m",{L5},36))#2:^(36),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},36))#2:^(36),1:""))
</RetrievalCode>
</Data>
<Data name="Origin">
<RetrievalCode> s {Origin}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},2))#2:^(2),$d(^oddCOM($g(^(2),"*"),"m",{L5},2))#2:^(2),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},2))#2:^(2),1:""))
</RetrievalCode>
</Data>
<Data name="OriginalName">
<RetrievalCode> s {OriginalName}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},37))#2:^(37),$d(^oddCOM($g(^(2),"*"),"m",{L5},37))#2:^(37),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},37))#2:^(37),1:""))
</RetrievalCode>
</Data>
<Data name="PlaceAfter">
<RetrievalCode> s {PlaceAfter}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},38))#2:^(38),$d(^oddCOM($g(^(2),"*"),"m",{L5},38))#2:^(38),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},38))#2:^(38),1:""))
</RetrievalCode>
</Data>
<Data name="Private">
<RetrievalCode> s {Private}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},39))#2:^(39),$d(^oddCOM($g(^(2),"*"),"m",{L5},39))#2:^(39),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},39))#2:^(39),1:0))
</RetrievalCode>
</Data>
<Data name="ProcedureBlock">
<RetrievalCode> s {ProcedureBlock}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},40))#2:^(40),$d(^oddCOM($g(^(2),"*"),"m",{L5},40))#2:^(40),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},40))#2:^(40),1:""))
</RetrievalCode>
</Data>
<Data name="PublicList">
<RetrievalCode> s {PublicList}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},41))#2:^(41),$d(^oddCOM($g(^(2),"*"),"m",{L5},41))#2:^(41),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},41))#2:^(41),1:""))
</RetrievalCode>
</Data>
<Data name="Requires">
<RetrievalCode> s {Requires}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},75))#2:^(75),$d(^oddCOM($g(^(2),"*"),"m",{L5},75))#2:^(75),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},75))#2:^(75),1:""))
</RetrievalCode>
</Data>
<Data name="ReturnResultsets">
<RetrievalCode> s {ReturnResultsets}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},64))#2:^(64),$d(^oddCOM($g(^(2),"*"),"m",{L5},64))#2:^(64),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},64))#2:^(64),1:0))
</RetrievalCode>
</Data>
<Data name="ReturnType">
<RetrievalCode> s {ReturnType}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},42))#2:^(42),$d(^oddCOM($g(^(2),"*"),"m",{L5},42))#2:^(42),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},42))#2:^(42),1:""))
</RetrievalCode>
</Data>
<Data name="ReturnTypeParams">
<RetrievalCode> s {ReturnTypeParams}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},62))#2:^(62),$d(^oddCOM($g(^(2),"*"),"m",{L5},62))#2:^(62),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},62))#2:^(62),1:""))
</RetrievalCode>
</Data>
<Data name="RtnLabel">
<RetrievalCode> s {RtnLabel}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},43))#2:^(43),$d(^oddCOM($g(^(2),"*"),"m",{L5},43))#2:^(43),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},43))#2:^(43),1:""))
</RetrievalCode>
</Data>
<Data name="Runnable">
<RetrievalCode> s {Runnable}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},44))#2:^(44),$d(^oddCOM($g(^(2),"*"),"m",{L5},44))#2:^(44),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},44))#2:^(44),1:0))
</RetrievalCode>
</Data>
<Data name="RuntimeClient">
<RetrievalCode> s {RuntimeClient}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},55))#2:^(55),$d(^oddCOM($g(^(2),"*"),"m",{L5},55))#2:^(55),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},55))#2:^(55),1:0))
</RetrievalCode>
</Data>
<Data name="RuntimeCodeMode">
<RetrievalCode> s {RuntimeCodeMode}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},56))#2:^(56),$d(^oddCOM($g(^(2),"*"),"m",{L5},56))#2:^(56),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},56))#2:^(56),1:"code"))
</RetrievalCode>
</Data>
<Data name="RuntimeHash">
<RetrievalCode> s {RuntimeHash}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},69))#2:^(69),$d(^oddCOM($g(^(2),"*"),"m",{L5},69))#2:^(69),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},69))#2:^(69),1:""))
</RetrievalCode>
</Data>
<Data name="RuntimeLanguage">
<RetrievalCode> s {RuntimeLanguage}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},58))#2:^(58),$d(^oddCOM($g(^(2),"*"),"m",{L5},58))#2:^(58),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},58))#2:^(58),1:"objectscript"))
</RetrievalCode>
</Data>
<Data name="SequenceNumber">
<RetrievalCode> s {SequenceNumber}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},11))#2:^(11),$d(^oddCOM($g(^(2),"*"),"m",{L5},11))#2:^(11),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},11))#2:^(11),1:0))
</RetrievalCode>
</Data>
<Data name="ServerOnly">
<RetrievalCode> s {ServerOnly}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},59))#2:^(59),$d(^oddCOM($g(^(2),"*"),"m",{L5},59))#2:^(59),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},59))#2:^(59),1:""))
</RetrievalCode>
</Data>
<Data name="SoapAction">
<RetrievalCode> s {SoapAction}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},67))#2:^(67),$d(^oddCOM($g(^(2),"*"),"m",{L5},67))#2:^(67),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},67))#2:^(67),1:"[default]"))
</RetrievalCode>
</Data>
<Data name="SoapBindingStyle">
<RetrievalCode> s {SoapBindingStyle}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},53))#2:^(53),$d(^oddCOM($g(^(2),"*"),"m",{L5},53))#2:^(53),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},53))#2:^(53),1:""))
</RetrievalCode>
</Data>
<Data name="SoapBodyUse">
<RetrievalCode> s {SoapBodyUse}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},54))#2:^(54),$d(^oddCOM($g(^(2),"*"),"m",{L5},54))#2:^(54),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},54))#2:^(54),1:""))
</RetrievalCode>
</Data>
<Data name="SoapMessageName">
<RetrievalCode> s {SoapMessageName}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},68))#2:^(68),$d(^oddCOM($g(^(2),"*"),"m",{L5},68))#2:^(68),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},68))#2:^(68),1:""))
</RetrievalCode>
</Data>
<Data name="SoapNameSpace">
<RetrievalCode> s {SoapNameSpace}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},61))#2:^(61),$d(^oddCOM($g(^(2),"*"),"m",{L5},61))#2:^(61),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},61))#2:^(61),1:""))
</RetrievalCode>
</Data>
<Data name="SoapRequestMessage">
<RetrievalCode> s {SoapRequestMessage}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},73))#2:^(73),$d(^oddCOM($g(^(2),"*"),"m",{L5},73))#2:^(73),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},73))#2:^(73),1:""))
</RetrievalCode>
</Data>
<Data name="SoapTypeNameSpace">
<RetrievalCode> s {SoapTypeNameSpace}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},65))#2:^(65),$d(^oddCOM($g(^(2),"*"),"m",{L5},65))#2:^(65),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},65))#2:^(65),1:""))
</RetrievalCode>
</Data>
<Data name="SqlName">
<RetrievalCode> s {SqlName}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},45))#2:^(45),$d(^oddCOM($g(^(2),"*"),"m",{L5},45))#2:^(45),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},45))#2:^(45),1:""))
</RetrievalCode>
</Data>
<Data name="SqlProc">
<RetrievalCode> s {SqlProc}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},46))#2:^(46),$d(^oddCOM($g(^(2),"*"),"m",{L5},46))#2:^(46),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},46))#2:^(46),1:0))
</RetrievalCode>
</Data>
<Data name="SqlRoutine">
<RetrievalCode> s {SqlRoutine}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},74))#2:^(74),$d(^oddCOM($g(^(2),"*"),"m",{L5},74))#2:^(74),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},74))#2:^(74),1:""))
</RetrievalCode>
</Data>
<Data name="Stub">
<RetrievalCode> s {Stub}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},47))#2:^(47),$d(^oddCOM($g(^(2),"*"),"m",{L5},47))#2:^(47),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},47))#2:^(47),1:""))
</RetrievalCode>
</Data>
<Data name="StubMember">
<RetrievalCode> s {StubMember}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},72))#2:^(72),$d(^oddCOM($g(^(2),"*"),"m",{L5},72))#2:^(72),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},72))#2:^(72),1:""))
</RetrievalCode>
</Data>
<Data name="TagGenerator">
<RetrievalCode> s {TagGenerator}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},48))#2:^(48),$d(^oddCOM($g(^(2),"*"),"m",{L5},48))#2:^(48),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},48))#2:^(48),1:""))
</RetrievalCode>
</Data>
<Data name="UserActualType">
<RetrievalCode> s {UserActualType}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},50))#2:^(50),$d(^oddCOM($g(^(2),"*"),"m",{L5},50))#2:^(50),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},50))#2:^(50),1:""))
</RetrievalCode>
</Data>
<Data name="WebMethod">
<RetrievalCode> s {WebMethod}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},51))#2:^(51),$d(^oddCOM($g(^(2),"*"),"m",{L5},51))#2:^(51),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},51))#2:^(51),1:0))
</RetrievalCode>
</Data>
<Data name="ZenMethod">
<RetrievalCode> s {ZenMethod}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},52))#2:^(52),$d(^oddCOM($g(^(2),"*"),"m",{L5},52))#2:^(52),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},52))#2:^(52),1:0))
</RetrievalCode>
</Data>
<Data name="_Language">
<RetrievalCode> s {_Language}=$s($d(^oddCOM({L1},"a",{L3},"m",{L5},32))#2:^(32),$d(^oddCOM($g(^(2),"*"),"m",{L5},32))#2:^(32),1:$s($d(^oddDEF($g(^oddCOM({L1},"a",{L3},"m",{L5},2),"*"),"m",{L5},32))#2:^(32),1:""))
</RetrievalCode>
</Data>
<Global>^oddCOM</Global>
<Structure>delimited</Structure>
<Subscript name="1">
<Expression>{%Dictionary.CompiledClass.Name}</Expression>
</Subscript>
<Subscript name="2">
<Expression>"a"</Expression>
</Subscript>
<Subscript name="3">
<Expression>{%Dictionary.CompiledProperty.Name}</Expression>
</Subscript>
<Subscript name="4">
<Expression>"m"</Expression>
</Subscript>
<Subscript name="5">
<Expression>{%Dictionary.CompiledPropertyMethod.Name}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%Dictionary.CompiledPro4352S</StreamLocation>
<Type>%CustomStorage</Type>
}

}
