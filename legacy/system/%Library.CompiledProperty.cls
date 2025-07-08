/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <b>
/// Note: The class definition classes in the %Library package have been superceded
/// by those in the %Dictionary package. Instead use <class>%Dictionary.CompiledProperty</class>.</b>
/// <p>
/// This class represents a specific property description for a compiled class.
Class %Library.CompiledProperty Extends %Persistent [ Deprecated, Not ProcedureBlock, StorageStrategy = custom, System = 2 ]
{

/// A string containing the name of the class the property belongs to.
Property ClassName As %RawString;

/// A string containing the name of the property.
Property Name As %RawString;

/// A flag indicating whether the property is calculated (1) or not (0).
Property Calculated As %RawString;

/// If the property is a collection, this is a string containing the name of 
/// the collection type. If the property is not a collection (single-valued) it 
/// contains a null string ("").
Property Collection As %RawString;

Property Datatype As %RawString;

/// A string containing the initial value expression for the property.
Property InitialExpression As %RawString;

/// A flag indicating whether the property is multi-dimensional (1) or not (0).
Property MultiDimensional As %RawString;

Property Persistent As %RawString;

/// A flag indicating whether the property is private (1) or public (0).
Property Private As %RawString;

/// A flag indicating whether the property is required (1) or not (0).
Property Required As %RawString;

Property RuntimeDatatype As %RawString;

Property RuntimeType As %RawString;

/// A flag indicating whether the property is transient (1) or not (0).
Property Transient As %RawString;

/// A string containing the defined type (class name) of the field.
Property Type As %RawString;

/// An array containing any parameter definitions for the property. The array 
/// keys are the parameter names and the array values are the parameter values.
Property Parameters As array Of %RawString;

Method %LoadData(propertyId As %String) As %Status [ Private ]
{
 n classname,propertyname,%sc
 i propertyId[":"
 i  s classname=$p(propertyId,":",1),propertyname=$p(propertyId,":",2)
 e  n len s len=$l(propertyId,"."),classname=$p(propertyId,".",1,len-1),propertyname=$p(propertyId,".",len)
 ;
 i $$$comMemberDefined(classname,$$$cCLASSproperty,propertyname)=0 q $$$ERROR($$$PropertyDoesNotExist,classname_":"_propertyname)
 ;
 s i%ClassName=classname
 s i%Name=propertyname
 s i%Calculated=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPcalculated)
 s i%Collection=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPcollection)
 s i%InitialExpression=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPinitialexpression)
 s i%MultiDimensional=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPmultidimensional)
 s i%Private=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPprivate)
 s i%Required=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPrequired)
 s i%RuntimeType=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPruntimetype)
 s i%RuntimeDatatype=$$$classIsDataType(i%RuntimeType)
 s i%Persistent=$$$classIsPersistent(i%RuntimeType)
 s i%Transient=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPtransient)
 s i%Type=$$$comMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPtype)
 s i%Datatype=$$$classIsDataType(i%Type)
 n param
 s param="" f  s param=$$$comSubMemberNext(classname,$$$cCLASSproperty,propertyname,$$$cPROPparameter,param) q:param=""  d
 . d ..Parameters.SetAt($$$comMemberArrayGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPparameter,param),param)
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

/// The <b>PropertyInfo</b> query provides a summary of information about properties 
/// contained within the specific class <PARAMETER>ClassName</PARAMETER>.
Query PropertyInfo(ClassName As %String) As %Query(ROWSPEC = "Name:%String:PropertyName,Datatype,Type,Collection,Caption,Serial,Editable,MaxLen,Required,Stream") [ SqlProc ]
{
}

ClassMethod PropertyInfoExecute(ByRef QHandle As %Binary, ClassName As %String) As %Status
{
 s QHandle=$lb(0,ClassName,"")
 Quit $$$OK
}

ClassMethod PropertyInfoFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 n class,prop,caption,maxlen,runnable,type,classtype,clientdatatype
 s AtEnd=$li(QHandle,1),class=$li(QHandle,2),prop=$li(QHandle,3),Row=""
 i AtEnd q $$$OK
 f  s prop=$$$comMemberNext(class,$$$cCLASSproperty,prop) q:prop=""  q:'$$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPprivate)
 i prop="" s AtEnd=1
 e  d  i $$$comMemberNext(class,$$$cCLASSproperty,prop)="" s AtEnd=1
 . s Row=$lb(prop)
 . $$$comMemberKeyGetLvar(type,class,$$$cCLASSproperty,prop,$$$cPROPtype)
 . s classtype=$$$getClassType(type)
 . s Row=Row_$lb(classtype=$$$cCLASSCLASSTYPEDATATYPE)
 . s Row=Row_$lb($$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPtype))
 . s Row=Row_$lb($$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPcollection))
 . s caption=$$$comMemberArrayGet(class,$$$cCLASSproperty,prop,$$$cPROPparameter,"CAPTION")
 . i caption="" s caption=prop
 . s Row=Row_$lb(caption)
 . $$$comMemberKeyGetLvar(type,class,$$$cCLASSproperty,prop,$$$cPROPruntimetype)
 . s Row=Row_$lb(classtype=$$$cCLASSCLASSTYPESERIAL)
 . s editable=1
 . i $$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPcalculated)
 . i  s editable=$$$comSubMemberDefined(class,$$$cCLASSproperty,prop,$$$cPROPmethod,$$$NameForSet)||$$$comMemberKeyGet(class,$$$cCLASSmethod,prop_$$$NameForSet,$$$cMETHrunnable)
 . s Row=Row_$lb(editable)
 . s maxlen=$$$comMemberArrayGet(class,$$$cCLASSproperty,prop,$$$cPROPparameter,"MAXLEN")
 . s Row=Row_$lb(maxlen)
 . s Row=Row_$lb($$$comMemberKeyGet(class,$$$cCLASSproperty,prop,$$$cPROPrequired))
 . i classtype=$$$cCLASSCLASSTYPESTREAM d
 . . $$$comClassKeyGetLvar(clientdatatype,type,$$$cCLASSclientdatatype)
 . . s Row=Row_$lb(clientdatatype)
 . e  d
 . . s Row=Row_$lb("")
 s QHandle=$lb(AtEnd,class,prop)
 Quit $$$OK
}

ClassMethod PropertyInfoClose(QHandle As %Binary) As %Status
{
 s QHandle=""
 Quit $$$OK
}

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%Library.CompiledPropertyS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
