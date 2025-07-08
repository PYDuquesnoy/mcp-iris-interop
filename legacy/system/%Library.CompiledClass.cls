/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <b>
/// Note: The class definition classes in the %Library package have been superceded
/// by those in the %Dictionary package. Instead use <class>%Dictionary.CompiledClass</class>.</b>
/// <p>
/// This class represents a specific, compiled class definition.
/// It contains all class members, including those 
/// that are inherited from super classes.
/// 
/// <p>Instances of this class are "read only"; to modify class definitions use the 
/// non-compiled class definition classes.
Class %Library.CompiledClass Extends %Persistent [ Deprecated, Not ProcedureBlock, StorageStrategy = custom, System = 2 ]
{

/// A string indicating the class type.
Property ClassType As %RawString;

/// A string containing the description of the class.
Property Description As %RawString;

/// A flag indicating whether the class is a datatype class (1) or not (0).
Property Datatype As %RawString;

/// A string containing the name of the class.
Property Name As %RawString;

/// A flag indicating whether the class is persistent (1) or not (0).
Property Persistent As %RawString;

/// A flag indicating whether the class is serial (embeddable) (1) or not (0).
Property Serial As %RawString;

/// A flag indicating whether the class is a system class (1) or not (0).
Property System As %RawString;

/// A collection of methods belonging to the class. See <CLASS>%CompiledMethod</CLASS>
/// for details.
Property Methods As %ListOfPersistentChildObjects(CLASSNAME = 1);

/// A collection of class parameters belonging to the class.
/// See <CLASS>%CompiledParameter</CLASS> for details.
Property Parameters As %ListOfPersistentChildObjects(CLASSNAME = 1);

/// A collection of properties belonging to the class.
/// See <CLASS>%CompiledProperty</CLASS> for details.
Property Properties As %ListOfPersistentChildObjects(CLASSNAME = 1);

/// A collection of queries belonging to the class.
/// See <CLASS>%CompiledQuery</CLASS> for details.
Property Queries As %ListOfPersistentChildObjects(CLASSNAME = 1);

Property list As %ListOfDataTypes [ Transient ];

/// Returns a <class>%ClassDefinition</class> for this class so that you
/// can edit the class definition.
Property ClassDefinition As %ClassDefinition(CLASSNAME = 1);

Method ClassDefinitionGet() As %ClassDefinition
{
 Quit ##class(%ClassDefinition).%OpenId(..Name)
}

Method ClassDefinitionSet(val As %ClassDefinition) As %Status [ Private ]
{
 Quit $$$OK
}

/// The GetParameter method returns the value of the parameter
/// named <i>name</i> from the class <i>classname</i>.
ClassMethod GetClassParameter(classname As %String, name As %String) As %String
{
 Quit $$$comMemberKeyGet(classname,$$$cCLASSparameter,name,$$$cPARAMdefault)
}

Method %LoadData(classname As %String) As %Status [ Private ]
{
 s classname=$$$NormalizeClassname(classname)
 i $$$comClassDefined(classname)=0 q $$$ERROR($$$CompiledClassDoesNotExist,classname)
 i $$$defClassVersionGet(classname)'=$$$CLASSDEFINITIONVERSION New sc Set sc=$$Upgrade^%occConvert("/nodisplay",,classname) If $$$ISERR(sc) RETURN sc
 ;
 n %sc
 ;
 s i%Name=classname
 s i%Description=$$$comClassKeyGet(classname,$$$cCLASSdescription)
 s i%ClassType=$$$getClassType(classname)
 s i%System=$$$comClassKeyGet(classname,$$$cCLASSsystem)
 ;
 s i%Datatype=i%ClassType=$$$cCLASSCLASSTYPEDATATYPE
 s i%Persistent=i%ClassType=$$$cCLASSCLASSTYPEPERSISTENT
 s i%Serial=i%ClassType=$$$cCLASSCLASSTYPESERIAL
 ;
 s i%Methods=$$$oidForm($lb("^oddCOM("""_classname_""","""_$$$cCLASSmethod_""")",classname,"%CompiledMethod","-private"))
 s i%Parameters=$$$oidForm($lb("^oddCOM("""_classname_""","""_$$$cCLASSparameter_""")",classname,"%CompiledParameter","-private"))
 s i%Properties=$$$oidForm($lb("^oddCOM("""_classname_""","""_$$$cCLASSproperty_""")",classname,"%CompiledProperty","-private"))
 s i%Queries=$$$oidForm($lb("^oddCOM("""_classname_""","""_$$$cCLASSquery_""")",classname,"%CompiledQuery",""))
 ;
 q $$$OK
}

Method %SaveData(id As %String) As %Status [ Private ]
{
 q $$$OK
}

ClassMethod %DeleteData(id As %String, concurrency As %Integer) As %Status [ Private ]
{
 q $$$OK
}

ClassMethod %Exists(oid As %ObjectIdentity) As %Boolean
{
 n id s id=$$$oidPrimary(oid) QUIT:id="" 0
 Set id=$$$NormalizeClassname(id)
 Quit $$$comClassDefined(id)\10
}

Method GetClassList() As %ListOfDataTypes
{
 n class
 i ..list=$$$NULLOREF s ..list=##class(%ListOfDataTypes).%New()
 d ..list.Clear()
 s class="" f  s class=$$$comClassNext(class) q:class=""  d
 . i $$$comClassKeyGet(class,$$$cCLASSabstract) q
 . i $$$comClassKeyGet(class,$$$cCLASSsystem) q
 . d ..list.Insert(class)
 q ..list
}

ClassMethod ExportODL(Class As %String, File As %String) As %Status
{
 n classes s classes(Class)=""
 q $$ExportODLList^%occTypeLib(.classes,File)
}

/// The <b>ClassInfo</b> query provides a summary of information about compiled classes contained in the 
/// <i>Class Dictionary</i>.
Query ClassInfo(initvalue As %String) As %Query(ROWSPEC = "Name::ClassName,Abstract:%Integer,System,Persistent,HasProperty:%Integer,Caption") [ SqlProc ]
{
}

ClassMethod ClassInfoExecute(ByRef QHandle As %Binary, initvalue As %String) As %Status
{
 s QHandle=$lb(0,$g(initvalue))
 Quit $$$OK
}

ClassMethod ClassInfoFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 n class,caption
 s AtEnd=$li(QHandle,1),class=$li(QHandle,2),Row=""
 i AtEnd q $$$OK
 s class=$$$comClassNext(class)
 i class="" s AtEnd=1
 e  d  i $$$comClassNext(class)="" s AtEnd=1
 . s Row=$lb(class)
 . s Row=Row_$lb($$$comClassKeyGet(class,$$$cCLASSabstract))
 . s Row=Row_$lb($$$comClassKeyGet(class,$$$cCLASSsystem))
 . s Row=Row_$lb($$$getClassType(class)=$$$cCLASSCLASSTYPEPERSISTENT)
 . s Row=Row_$lb(''$$$comClassKeyDefined(class,$$$cCLASSproperty))
 . s caption=$$$comMemberKeyGet(class,$$$cCLASSparameter,"CAPTION",$$$cPARAMdefault)
 . i caption="" s caption=class
 . s Row=Row_$lb(caption)
 s QHandle=$lb(AtEnd,class)
 q $$$OK
}

ClassMethod ClassInfoClose(QHandle As %Binary) As %Status
{
 s QHandle=""
 Quit $$$OK
}

/// The <b>IndexInfo</b> query provides a list of indices defined for the class
/// <var>classname</var>.
Query IndexInfo(classname As %String) As %Query(ROWSPEC = "Name:%String,Attributes:%String,Type:%String,PrimaryKey:%Integer,Unique:%Integer")
{
}

ClassMethod IndexInfoExecute(ByRef QHandle As %Binary, classname As %String) As %Status
{
 s QHandle=$lb(0,$g(classname),"")
 Quit $$$OK
}

ClassMethod IndexInfoFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 n class,caption,index
 s AtEnd=$li(QHandle,1),class=$li(QHandle,2),index=$li(QHandle,3),Row=""
 i class="" s AtEnd=1
 i AtEnd q $$$OK
 s index=$$$comMemberNext(class,$$$cCLASSindex,index)
 i index="" s AtEnd=1
 e  d  i $$$comMemberNext(class,$$$cCLASSindex,index)="" s AtEnd=1
 . s Row=$lb(index,$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXproperties))
 . s Row=Row_$lb($s($$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXidkey):"idkey",$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXextent):"extent",1:$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXtype)))
 . s Row=Row_$lb(+$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXprimarykey),+$$$comMemberKeyGet(class,$$$cCLASSindex,index,$$$cINDEXunique))
 s QHandle=$lb(AtEnd,class,index)
 q $$$OK
}

ClassMethod IndexInfoClose(QHandle As %Binary) As %Status
{
 s QHandle=""
 Quit $$$OK
}

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%Library.CompiledClassS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
