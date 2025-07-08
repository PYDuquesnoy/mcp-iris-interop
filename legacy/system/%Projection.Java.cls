/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This projection class generates the appropriate Java client code (using 
/// the Java Binding) for the associated class.<BR>
/// For more information refer to the <CLASS>%Projection.AbstractProjection</CLASS> class.
Class %Projection.Java Extends %Projection.AbstractProjection [ Abstract, System = 2 ]
{

/// If true then do not create this projection using the class compiler multicompile
/// jobs but create it in the main process. Used to allow projections that do not function
/// in the multicompile environment to disable this feature.
Parameter DisableMulticompile As BOOLEAN = 1;

/// The root directory in which generated files are written.
Parameter ROOTDIR;

/// When NEWCOLLECTIONS is set collection properties project as java.util.Map (for arrays) and Java.util.List (for lists).  
/// When NEWCOLLECTIONS is zero (the default) collection properties project as follows:
/// ArrayOfDataTypes for array of a datatypoe
/// ArrayOfObjects for array of an object
/// ListOfDataTypes for list of a datatype
/// ListOfObjects for list of an object
/// This parameter will be overriden by JAVATYPE if that is specified for property.
Parameter NEWCOLLECTIONS = 1;

/// When PRIMITIVEDATATYPES is set %Integer maps to int, %Float maps to double, %Boolean maps to boolean, and %BigInt maps to long
Parameter PRIMITIVEDATATYPES = 0;

/// Only generate dependency or class if timestamp of last compilation is greater than timestamp of last generation
Parameter MAKE = 1;

/// Choose DOCUMATIC Host
Parameter DOCUMATICHOST;

/// Choose DOCUMATIC Port
Parameter DOCUMATICPORT;

/// Choose DOCUMATIC Namespace
Parameter DOCUMATICNAMESPACE;

/// Generation Type
/// 1 - legacy
/// 2 - generate class as implementing interface
Parameter GENERATIONTYPE = 1;

/// Deprecated - POJO mode
/// 0 - legacy
/// 1 - POJO on
Parameter POJO [ Deprecated ] = 0;

/// CHECKUPTODATE
/// 0 - don't check if classes are up to date to project
/// 1 - do check if classes are up to date, useful for deploying final application
Parameter CHECKUPTODATE = 1;

/// JAVADOC
/// 0 - do NOT generate javadoc
/// 1 - generate javadoc (the default)
Parameter JAVADOC = 1;

/// RECURSIVE
/// 0 - do NOT generate dependencies
/// 1 - generate dependencies, default
Parameter RECURSIVE = 1;

/// Deprecated - PROJECTBYREFMETHODSTOPOJO
/// 0 - generate error when you try to project classes that contain methods with ByRef arguments to pojo implementation
/// 1 - project classes that contain methods with ByRef arguments to pojo implementation
Parameter PROJECTBYREFMETHODSTOPOJO [ Deprecated ] = 0;

/// Deprecated - PROJECTABSTRACTSTREAM
/// 0 - generate error when you try to project classes that contain methods with abstract stream arguments or return type
/// 1 - project classes that contain methods with with abstract stream arguments or return type
Parameter PROJECTABSTRACTSTREAM [ Deprecated ] = 0;

/// Generate serialVersionUID
Parameter GENSERIALUID = 1;

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, ByRef qstruct As %String) As %Status
{
	s projParams = ##class(%ArrayOfDataTypes).%New()
	d projParams.SetAt(..getROOTDIR(.parameters, "java"), "ROOTDIR")
	d projParams.SetAt($get(parameters("NEWCOLLECTIONS")), "NEWCOLLECTIONS")
	d projParams.SetAt($get(parameters("PRIMITIVEDATATYPES")), "PRIMITIVEDATATYPES")
	d projParams.SetAt($get(parameters("MAKE")), "MAKE")
	d projParams.SetAt($get(parameters("GENERATIONTYPE")), "GENERATIONTYPE")
	d projParams.SetAt($get(parameters("RECURSIVE")), "RECURSIVE")
	d projParams.SetAt($get(parameters("CHECKUPTODATE")), "CHECKUPTODATE")
	d projParams.SetAt($get(parameters("GENSERIALUID")), "GENSERIALUID")
	
	d projParams.SetAt($get(parameters("DOCUMATICHOST")), "DOCUMATICHOST")
	d projParams.SetAt($get(parameters("DOCUMATICPORT")), "DOCUMATICPORT")
	d projParams.SetAt($get(parameters("DOCUMATICNAMESPACE")), "DOCUMATICNAMESPACE")
	d projParams.SetAt($get(parameters("JAVADOC")), "JAVADOC")
	
	return ##class(%Compiler.Binding.Java).CreateProjection(classname, projParams,,,.qstruct)
}

}
