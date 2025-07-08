/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <b>
/// Note: The class definition classes in the %Library package have been superceded
/// by those in the %Dictionary package. Instead use <class>%Dictionary.CompiledParameter</class>.</b>
/// <p>
/// This class represents a specific class parameter description for a compiled class.
Class %Library.CompiledParameter Extends %Persistent [ Deprecated, Not ProcedureBlock, StorageStrategy = custom, System = 2 ]
{

/// A string containing the name of the class the class parameter belongs to.
Property ClassName As %RawString;

/// A string containing the name of the class parameter.
Property Name As %RawString;

/// A string containing the default value for the class parameter.
Property Default As %RawString;

/// This is for internal use only.
Property Type As %RawString;

Method %LoadData(paramId As %String) As %Status [ Private ]
{
 n classname,paramname,%sc
 i paramId[":"
 i  s classname=$p(paramId,":",1),paramname=$p(paramId,":",2)
 e  n len s len=$l(paramId,"."),classname=$p(paramId,".",1,len-1),paramname=$p(paramId,".",len)
 ;
 i $$$comMemberDefined(classname,$$$cCLASSparameter,paramname)=0 q $$$ERROR($$$ParameterDoesNotExist,classname_":"_paramname)
 ;
 s i%ClassName=classname
 s i%Name=paramname
 s i%Default=$$$comMemberKeyGet(classname,$$$cCLASSparameter,paramname,$$$cPARAMdefault)
 s i%Type=$$$comMemberKeyGet(classname,$$$cCLASSparameter,paramname,$$$cPARAMtype)
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

Storage custom
{
<ExtentSize>100000</ExtentSize>
<StreamLocation>^%Library.CompiledParameterS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
