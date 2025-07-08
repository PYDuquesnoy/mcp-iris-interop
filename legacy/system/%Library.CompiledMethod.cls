/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <b>
/// Note: The class definition classes in the %Library package have been superceded
/// by those in the %Dictionary package. Instead use <class>%Dictionary.CompiledMethod</class>.</b>
/// <p>
/// This class represents a specific method description for a compiled class.
Class %Library.CompiledMethod Extends %Persistent [ Deprecated, Not ProcedureBlock, StorageStrategy = custom, System = 2 ]
{

/// A string containing the name of the class the method belongs to.
Property ClassName As %RawString;

/// A string containing the name of the method.
Property Name As %RawString;

/// A flag indicating whether the method is a class method (1) or an instance method (0).
Property ClassMethod As %RawString;

/// A flag indicating whether the method is private (1) or public (0).
Property Private As %RawString;

/// A flag indicating whether the method returns a value (1) or not (0).
Property QuitWithValue As %RawString;

/// A string containing the return type (a class name) for the method. If there is 
/// no return type it contains a null string ("").
Property ReturnType As %RawString;

Method %LoadData(methodId As %String) As %Status [ Private ]
{
 n classname,propertyname,methodname,%sc
 i methodId[":"
 i  s classname=$p(methodId,":",1),methodname=$p(methodId,":",2)
 e  n len s len=$l(methodId,"."),classname=$p(methodId,".",1,len-1),methodname=$p(methodId,".",len)
 ;
 i $$$comMemberDefined(classname,$$$cCLASSmethod,methodname)=0 q $$$ERROR($$$MethodDoesNotExist,classname_":"_methodname)
 ;
 s i%ClassName=classname
 s i%Name=methodname
 i $$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHstub)="" d
 . s i%ClassMethod=$$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHclassmethod)
 . s i%Private=$$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHprivate)
 . s i%ReturnType=$$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHreturntype)
 . s i%QuitWithValue=(i%ReturnType'="")
 i $$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHstub)'="" d
 . s propertyname=$p($$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHstub),".",1)
 . s methodname=$p($$$comMemberKeyGet(classname,$$$cCLASSmethod,methodname,$$$cMETHstub),".",2)
 . s i%ClassMethod=$$$comSubMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPmethod,methodname,$$$cMETHclassmethod)
 . s i%Private=$$$comSubMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPmethod,methodname,$$$cMETHprivate)
 . s i%ReturnType=$$$comSubMemberKeyGet(classname,$$$cCLASSproperty,propertyname,$$$cPROPmethod,methodname,$$$cMETHreturntype)
 . s i%QuitWithValue=(i%ReturnType'="")
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
<StreamLocation>^%Library.CompiledMethodS</StreamLocation>
<Type>%CustomStorage</Type>
}

}
