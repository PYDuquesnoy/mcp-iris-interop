/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base superclass.
/// For internal use only, this is automatically added to all classes as a superclass.
Class %Library.SystemBase [ ClassType = donotuse ]
{

/// Creates a new instance of object in memory. <METHOD>%New</METHOD> creates an OREF value that refers 
/// to the object instance, registers the OREF with the system along with its class name, and 
/// reserves system storage for the properties.
/// 
/// <p><METHOD>%New</METHOD> initializes all the object's properties to their default values and calls the 
/// user-provided method, <METHOD>%OnNew</METHOD>, if it is present. The optional arguments are 
/// passed on to the <METHOD>%OnNew</METHOD> method. If the object is persistent, its OID is set to null string ("").
/// 
/// <METHOD>%New</METHOD> returns an OREF value that refers to the new object instance or 
/// $$$NULLOREF if unable to create the object instance.
ClassMethod %New(initvalue As %RawString) As %ObjectHandle [ Final ]
{
	Quit ""
}

/// Setting the modified state of the object.
Method %SetModified(value As %Integer) As %Status [ ServerOnly = 1 ]
{
	Do $system.CLS.SetModified(value)
	Quit $$$OK
}

/// This method is deprecated as reference counting is handled automatically by the system.
/// This is now a no-op and just returns a success code.
/// objects is now handled by the system automatically
Method %IncrementCount() As %Integer [ Deprecated, Final, Internal, ServerOnly = 0 ]
{
	Quit 1
}

/// This method is deprecated because we now reference count objects automatically so there is no
/// need to call this method. It is a no-op and just returns success %Status code.
Method %Close() As %Status [ Deprecated, Final, Internal, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// Returns the object's class name. The <var>fullname</var> determines how the
/// class name is represented. If it is 1 then it returns the full class name
/// including any package qualifier. If it is 0 (the default) then it returns the
/// name of the class without the package, this is mainly for backward compatibility
/// with the pre-package behaviour of %ClassName.
ClassMethod %ClassName(fullname As %Boolean) As %String [ ServerOnly = 0 ]
{
	Quit $select($get(fullname,0):$$$objClass,1:$$$ClassCompatibleName($$$objClass))
}

/// Returns the object's package name.
ClassMethod %PackageName() As %String [ Final, ServerOnly = 1 ]
{
	Quit $$$ClassPackageName($$$objClass)
}

/// This method returns the value of a class parameter at runtime
ClassMethod %GetParameter(paramname As %String = "") As %String [ Final, ServerOnly = 1 ]
{
	Try { Set param=$parameter(,paramname) } Catch { Set param="" }
	Quit param
}

/// Returns true (1) if instances of this class are also instances of the isclass parameter.
/// That is 'isclass' is a primary superclass of this object.
ClassMethod %IsA(isclass As %String) As %Integer [ ServerOnly = 0 ]
{
	$$$SystemMethod(Is:0)
}

/// Returns true (1) if this class is inherited either via primary or secondary inheritance from 'isclass'.
ClassMethod %Extends(isclass As %String) As %Integer [ ServerOnly = 1 ]
{
	$$$SystemMethod(Is:1)
}

/// Return the namespace this oref was created in.
/// This also returns the namespace this class was first referenced in if calling class
/// methods.
ClassMethod %OriginalNamespace() As %String [ ServerOnly = 1 ]
{
	$$$SystemMethod(ClsNS)
}

/// Return true if this instance is the latest version of this class, and false
/// if the class has been recompiled so there is a newer version on disk
ClassMethod %ClassIsLatestVersion() As %Boolean [ ServerOnly = 1 ]
{
	Quit $$$objObjectIsLatestVersion()
}

/// Is used to implement an unknown method call.  It is also used
/// to resolve an unknown multidimensional property reference (to get the value
/// of a property) because that syntax is identical to a method call.
Method %DispatchMethod(Method As %String, Args...) [ Abstract, ServerOnly = 1 ]
{
}

/// Is used to implement an unknown class method call
ClassMethod %DispatchClassMethod(Class As %String, Method As %String, Args...) [ Abstract, ServerOnly = 1 ]
{
}

/// Is used to get the value of an unknown property.
Method %DispatchGetProperty(Property As %String) [ Abstract, ServerOnly = 1 ]
{
}

/// is used to set the value of an unknown property.
Method %DispatchSetProperty(Property As %String, Val) [ Abstract, ServerOnly = 1 ]
{
}

/// Is used to set the value of an unknown multidimensional property.
Method %DispatchSetMultidimProperty(Property As %String, Val, Subs...) [ Abstract, ServerOnly = 1 ]
{
}

/// Is used to get the value of the modified flag for an unknown property.
Method %DispatchGetModified(Property As %String) [ Abstract, ServerOnly = 1 ]
{
}

/// Is used to set the value of the modified flag for an unknown property.
Method %DispatchSetModified(Property As %String, Val) [ Abstract, ServerOnly = 1 ]
{
}

}
