/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class handles creating the proxy Java class.
Class %Compiler.Binding.Java Extends %RegisteredObject [ System = 4 ]
{

/// Creates the proxy Java class.
/// <var>IRISClassName</var> is the full name of the IRIS class being projected (including package name).
/// <var>projParams</var> is the array of projection parameters defined in the IRIS class.
/// <var>flushGlobals</var> is set to 0 if createProjection() is called during the projection of another class,
/// and 1 otherwise. It prevents looping projection calls, and also flushes out globals used during projection.
/// <var>properties</var> is used by a subclass that is calling CreateProjection() on its leftmost superclass.
/// It helps the subclass keep track of properties already existing in its superclass, so that it doesn't
/// reproject those properties.
ClassMethod CreateProjection(IRISClassName, projParams As %ArrayOfDataTypes, flushGlobals = 1, ByRef properties = {##class(%ArrayOfDataTypes).%New()}, ByRef qstruct As %String) As %Status
{
 	s Status = $$$OK
 	s tConverter = ##class(%Compiler.Binding.JavaTypeConverter).%New(projParams)
 	s class = ##class(%Dictionary.CompiledClass).%OpenId(IRISClassName)
	s display=$$$qualifierGetValue(qstruct,"displaylog")

 	//TODO: refactor all checks for error to a method
 	// If class is not found in %Dictionary.CompiledClass, user should compile the class
 	if class = "" {
	 	return $System.Status.Error(5001, "%Dictionary.CompiledClass object not found for class "_IRISClassName_". Please make sure "_IRISClassName_" is compiled.")
 	}
 	
 	// Send warning for Deployed classes
 	if class.Deployed {
	 	if display { w !, "WARNING: Class ", class.Name, " is Deployed and will not be recompiled before projection." }
	 	//return Status	
	}
 	
 	// Don't project ServerOnly classes
 	if class.ServerOnly {
	 	return $System.Status.Error(6650, IRISClassName, IRISClassName)
 	}
 	
 	// If class is not up-to-date (have been compiled after last change), don't project
	if flushGlobals && projParams.GetAt("CHECKUPTODATE") && '$$isuptodate^%occClass(class.Name) {
	 	d ..FlushGlobals(flushGlobals)
	 	return $System.Status.Error(6632, class.Name)
 	}
 	
 	// Don't project datatype classes
	if flushGlobals && (class.ClassType = "datatype") {
	 	d ..FlushGlobals(flushGlobals)
	 	return $System.Status.Error(6636, class.Name)
 	}
 	
 	// If ClientName is specified, use it as Java class name
 	s className = $p(class.Name, ".", *)
 	if class.ClientName '= "" {s className = class.ClientName}
 	
 	// If this is a %Library data type class, find matching Java type
 	s irisPackage = $p(class.Name, ".", 1, *-1)
	if $e(irisPackage, 1) = "%" {
		s javaType = tConverter.convertCDType(class.ClientDataType, className)
		s ^irisToJavaClassName(class.Name) = javaType
		s ^irisToODBCType(class.Name) = class.OdbcType
	 	return Status
 	}
 	
 	// Process superclass
 	s irisSupers = $listfromstring(class.Super, ",")
 	s leftSuperProps = ##class(%ArrayOfDataTypes).%New()
 	
 	s leftSuper = ""
 	s super = ""
 	if irisSupers '= "" {
	 	for i=1:1:$listlength(irisSupers) {
		 	s curSuper = $list(irisSupers, i)
		 	if i = 1 {
				s leftSuper = curSuper
		 		s super = curSuper
		 	}
		 	
		 	s s1 = $p(curSuper, ".", 1)
		 	s s2 = $p(curSuper, ".", *)
		 	
		 	if (s1 = "%Library") {
			 	// If superclass is a %Library data class, map this class to its matching Java type
			 	s objectClasses = $lb("Persistent", "SerialObject", "RegisteredObject")
			 	if '$listfind(objectClasses, s2) {
					s superClass = ##class(%Dictionary.CompiledClass).%OpenId(curSuper)
					s superJava = tConverter.convertCDType(superClass.ClientDataType, curSuper)
				 	s ^irisToJavaClassName(class.Name) = superJava
				 	if i = 1 {return Status}
		 			continue
			 	}
			 	
			 	if i = 1 {
					s super = s2
			 	}
		 		
		 	// Otherwise, superclass is an object class, so project it
		 	} else {
			 	if '$data(^irisToJavaClassName(curSuper)) {
				 	if i = 1 {
					 	s Status = ##class(%Compiler.Binding.Java).CreateProjection(curSuper, projParams, 0, .leftSuperProps,.qstruct)
				 	} else {
					 	s Status = ##class(%Compiler.Binding.Java).CreateProjection(curSuper, projParams, 0,,.qstruct)
				 	}
					if $$$ISERR(Status) {
						d ..FlushGlobals(flushGlobals)
						return Status
					}
				}
				s curSuper = $get(^irisToJavaClassName(curSuper))
				if i = 1 {
					s super = curSuper
				}
		 	}
	 	}
	 	
	// If there's no supertype, check ClientDataType to see if this is a datatype class
 	} elseif class.ClassType = "datatype" {
	 	s javaType = tConverter.convertCDType(class.ClientDataType)
		s ^irisToJavaClassName(class.Name) = javaType
		s ^irisToODBCType(class.Name) = class.OdbcType
	 	return Status
	
	// If ClassType is persistent, leftmost super must be %Persistent
	} elseif class.ClassType = "persistent" {
		d ..FlushGlobals(flushGlobals)
		return $System.Status.Error(6631, class.Name)
		
	// If ClassType is serial, leftmost super must be at least %RegisteredObject
 	} elseif class.ClassType = "serial" {
		d ..FlushGlobals(flushGlobals)
		return $System.Status.Error(6630, class.Name)
 	}
 	
 	// Process java package info and directory for projected file
 	s rootdir = projParams.GetAt("ROOTDIR")
 	s javaPackage = irisPackage
 	for i = 1:1:class.Parameters.Count() {
	 	s param = class.Parameters.GetAt(i)
	 	//set up java package and output directory
 		if param.Name = "JAVAPACKAGE" {
	 		if param.Default '= "" {s javaPackage = param.Default}
	 		quit
 		}
 	}
 	s pathName = ..SetPackageDir(rootdir, javaPackage)
 	
 	// Add this class to list of classes being projected
 	s ^irisToJavaClassName(class.Name) = javaPackage_"."_className
	s ^projectedJavaClasses(javaPackage_"."_className) = 1

 	
 	// If RECURSIVE = 0, don't project the class
 	if 'projParams.GetAt("RECURSIVE") && 'flushGlobals {q Status}
 	
 	// Find the root superclass of this class
 	s primarySuper = $listfromstring(class.PrimarySuper, "~")
 	s rootSuper = $select($lf(primarySuper, "%Library.Persistent"): "Persistent",
 							$lf(primarySuper, "%Library.SerialObject"): "SerialObject",
 							$lf(primarySuper, "%Library.RegisteredObject"): "RegisteredObject",
 																	1: "")
 	
 	// Process class metadata
 	s jdCreator = ##class(%Compiler.Binding.JavaDocCreator).%New(class.Name, javaPackage_"."_className, projParams, tConverter)
 	s mCreator = ##class(%Compiler.Binding.JavaMethodCreator).%New(class, className, rootSuper, leftSuper, irisSupers, projParams, jdCreator)
 	
 	// Set up generated file and directory
 	s fileName = ##class(%File).SubDirectoryName(pathName, className_".java")
 	s file = ..GetFile(pathName, className, 0, projParams, .generateTime)
 	
 	s interfaceFileName = ##class(%File).SubDirectoryName(pathName, "I"_className_".java")
 	s interfaceFile = ..GetFile(pathName, "I"_className, 1, projParams)
 	
 	// If compilation time is before the last time this file is projected, stop projecting
 	if generateTime '= "" && projParams.GetAt("MAKE") {
	 	s compileTime = class.TimeChanged
	 	if ($p(compileTime, ",", 1) < $p(generateTime, ",", 1))
	 	|| (($p(compileTime, ",", 1) = $p(generateTime, ",", 1)) && ($p(compileTime, ",", 2) < $p(generateTime, ",", 2))) {
		 	d ..FlushGlobals(flushGlobals)
			return Status
	 	}
 	}
 	
 	// Prepare directory and file for write
 	s st = file.CreateDirectoryChain(pathName, .ret)
	if 'st {
		d ..FlushGlobals(flushGlobals)
		return $$$ERROR(5001, "Operating system error "_(-1 * ret))
	}
	s Status = file.Open("WSN")
	if $$$ISERR(Status) {
		d ..FlushGlobals(flushGlobals)
		return Status
	}
	if interfaceFile.createsInterface {d interfaceFile.Open("WSN")}
 	
 	// Create package, dependencies/imports
 	d ..CreatePackage(file, javaPackage)
 	d ..CreatePackage(interfaceFile, javaPackage)
 	d ..CreateImports(file, tConverter, super)
 	d ..CreateImports(interfaceFile, tConverter, super)
 	d file.IndentAndWriteLine()
 	d interfaceFile.IndentAndWriteLine()
 	
 	// Create class declaration
 	d ..CreateDeclaration(file, class.Abstract, className, class.ClassType, super, jdCreator, class.Description)
 	d ..CreateDeclaration(interfaceFile, class.Abstract, className, class.ClassType, super, jdCreator, class.Description)
 	
 	// Create Java local variables
 	d ..CreateLocalVars(file, class.Name, projParams.GetAt("GENSERIALUID"))
 	d ..CreateLocalVars(interfaceFile, class.Name, projParams.GetAt("GENSERIALUID"))
 	
 	// Generate constructor
 	for i=1:1:class.Methods.Count() {
		s method = class.Methods.GetAt(i)
		if method.Name = "%OnNew" {
			s Status = mCreator.createConstructors(file, method,.qstruct)
			if $$$ISERR(Status) {
				d ..FlushGlobals(flushGlobals)
				d ..CloseFile(pathName, className, file)
				d ..CloseFile(pathName, className, interfaceFile)
				return Status	
			}
			quit
		}
 	}

	// Generate %OpenId/%Open methods
	s tableName = class.SqlTableName
	if tableName = "" {s table = class.Name}
	d mCreator.createOpens(file, irisPackage_"."_tableName)
	
	// Generate Delete methods
	d mCreator.createDeletes(file)
	
	// Generate Exists methods
	d mCreator.createExists(file)
	
	// Generate ClassName methods
 	d mCreator.createClassName(file, (class.Properties.Count() > 0))
 	
	// Track all properties of this class
	for i = 1:1:class.Properties.Count() {
		s prop = class.Properties.GetAt(i)
		if 'prop.ServerOnly {
			s Status = mCreator.trackProperties(prop, .properties, leftSuperProps,.qstruct)
			if $$$ISERR(Status) {
				d ..FlushGlobals(flushGlobals)
				d ..CloseFile(pathName, className, file)
				d ..CloseFile(pathName, className, interfaceFile)
				return Status	
			}
		}
 	}
 	
 	// Create user-defined methods
 	for i=1:1:class.Methods.Count() {
		s method = class.Methods.GetAt(i)
		
		// if a non-ClassMethod in a non-Registered class, skip
		if 'method.ClassMethod && (class.Super = "") {
			if 'class.Abstract {
				d ..FlushGlobals(flushGlobals)
				d ..CloseFile(pathName, className, file)
				d ..CloseFile(pathName, className, interfaceFile)
				return $System.Status.Error(6630, class.Name)
			}
			continue
	 	}
		
		s Status = mCreator.createUserDefinedMethod(file, method, properties, interfaceFile, .qstruct)
		if $$$ISERR(Status) {
			d ..FlushGlobals(flushGlobals)
			d ..CloseFile(pathName, className, file)
			d ..CloseFile(pathName, className, interfaceFile)
			return Status	
		}
 	}
	
	// Generate property methods
	for i = 1:1:class.Properties.Count() {
		s prop = class.Properties.GetAt(i)
		if 'prop.ServerOnly {
			s Status = mCreator.createProperty(file, prop, interfaceFile)
			if $$$ISERR(Status) {
				d ..FlushGlobals(flushGlobals)
				d ..CloseFile(pathName, className, file)
				d ..CloseFile(pathName, className, interfaceFile)
				return Status	
			}
		}
 	}
 	
 	// Generate index methods
	for i = 1:1:class.Indices.Count() {
		s Status = mCreator.createIndexMethods(file, class.Indices.GetAt(i),.qstruct)
		if $$$ISERR(Status) {
			d ..FlushGlobals(flushGlobals)
			d ..CloseFile(pathName, className, file)
			d ..CloseFile(pathName, className, interfaceFile)
			return Status	
		}
 	}
 	
 	// Generate query methods
 	for i = 1:1:class.Queries.Count() {
	 	s query = class.Queries.GetAt(i)
	 	do mCreator.createQueryMethod(file, query)	
 	}
 	
 	d file.IndentAndWriteLine("}")
	d ..CloseFile(pathName, className, file, 1)
	if display { w !,"Generating Java Binding: "_##class(%File).SubDirectoryName(pathName, className_".java") }
	d interfaceFile.IndentAndWriteLine("}")
	d ..CloseFile(pathName, "I"_className, interfaceFile, 1)
	if interfaceFile.createsInterface,display { w !,"Generating Java Binding: "_##class(%File).SubDirectoryName(pathName, "I"_className_".java") }
	
	d ..FlushGlobals(flushGlobals)
	q Status
}

/// Returns a newly created stub file if the file specified by <var>pathName</var> and <var>className</var> doesn't exist.
/// Otherwise, returns a temporary file that will be recopied and removed once projection succeeds.
ClassMethod GetFile(pathName As %String, className As %String, isInterface As %Boolean, projParams As %ArrayOfDataTypes, ByRef generateTime = "") As JavaFile
{
	s fileName = ##class(%File).SubDirectoryName(pathName, className_".java")
 	s file = ##class(%Compiler.Binding.JavaFile).%New(fileName)
 	if ##class(%File).Exists(fileName) {
		s generateTime = file.DateModified
		s fileName = ##class(%File).SubDirectoryName(pathName, className_".tmp")
		s file = ##class(%Compiler.Binding.JavaFile).%New(fileName)
 	}
 	
 	s file.isInterface = isInterface
 	if isInterface {s file.createsInterface = (projParams.GetAt("GENERATIONTYPE") = 2)}
 	return file
}

/// Close the file specified by <var>pathName</var> and <var>className</var>.
/// If a temporary file exists for the class, copy its content to the right .java file, then delete the temporary file.
ClassMethod CloseFile(pathName As %String, className As %String, file As JavaFile, projIsSuccessful = 0)
{
	d file.Close()
	s tmpName = ##class(%File).SubDirectoryName(pathName, className_".tmp")
 	if ##class(%File).Exists(tmpName) {
	 	if projIsSuccessful {
			s fileName = ##class(%File).SubDirectoryName(pathName, className_".java")
			d ##class(%File).CopyFile(tmpName, fileName)
	 	}
		d ##class(%File).Delete(tmpName)
 	}
}

/// Returns the pathname for the directory the projected Java file would be in.
ClassMethod SetPackageDir(rootdir As %RawString, ByRef javaPackage As %RawString) As %RawString
{
	s pathName = rootdir
	s length = $length(javaPackage, ".")
	for i=1:1:length {
		s subDir = $p(javaPackage, ".", i)
		s pathName = ##class(%File).SubDirectoryName(pathName, subDir)
	}
	return pathName
}

/// Writes package info to Java file.
ClassMethod CreatePackage(file As JavaFile, javaPackage As %String)
{
	if javaPackage '= "" {
 		d file.IndentAndWriteLine("package "_javaPackage_";")
 		d file.IndentAndWriteLine()
 	}
}

/// Writes Java class declaration to the Java file.
ClassMethod CreateDeclaration(file As JavaFile, isAbstract As %Boolean, className As %String, classType As %String, super As %String, jdCreator As JavaDocCreator, description As %String)
{
	d jdCreator.createClassIntro(file, description)
	
	s sigType = $select(file.isInterface: " interface I",
								isAbstract: " abstract class ",
										1 : " class ")
 	s classDeclaration = "public"_sigType_className
 	
 	if 'file.isInterface {
	 	if super '= "" {
		 	s classDeclaration = classDeclaration_" extends "_super
	 	}
		s serialTypes = $lb("", "RegisteredObject", "SerialObject")
	 	if $lf(serialTypes, super) || (classType = "serial") {
		 	s classDeclaration = classDeclaration_" implements java.io.Serializable"
	 	}
 	} else {
	 	s classDeclaration = classDeclaration_" extends java.io.Serializable"
 	}
 	
	d file.IndentAndWriteLine(classDeclaration_" {")
}

ClassMethod CreateLocalVars(file As JavaFile, className As %String, genSerialUid = 0)
{
	if 'file.isInterface && genSerialUid {
		d file.IndentAndWriteLine("private static final long serialVersionUID = "_$$hashClass^%occLGUtil(className)_";", 1)
	}
	d file.IndentAndWriteLine("public static String IRIS_CLASS_NAME = """_className_""";", 1)
 	//d ..CreateFieldList(file, class.Properties)
 	d file.IndentAndWriteLine()
}

ClassMethod CreateImports(file As JavaFile, tConverter As JavaTypeConverter, super As %String)
{
	d file.IndentAndWriteLine("import java.sql.SQLException;")
	d file.IndentAndWriteLine("import com.intersystems.jdbc.IRIS;")
	d file.IndentAndWriteLine("import com.intersystems.jdbc.IRISObject;")
	d file.IndentAndWriteLine("import com.intersystems.jdbc.IRISConnection;")
	d file.IndentAndWriteLine("import com.intersystems.binding.Database;")
	d file.IndentAndWriteLine("import com.intersystems.binding.Oid;")
	d file.IndentAndWriteLine("import com.intersystems.binding.Util;")
	
	if (super = "") {
		return	
	}
	
	d file.IndentAndWriteLine("import com.intersystems.binding.IRISReference;")
	d file.IndentAndWriteLine("import com.intersystems.binding.RegisteredObject;")
	d file.IndentAndWriteLine("import com.intersystems.binding.ClassnameMap;")
	
	if (super '= "") && (super '= "RegisteredObject") {
	 	d file.IndentAndWriteLine("import com.intersystems.binding.Id;")
	 	d file.IndentAndWriteLine("import "_tConverter.convertObjectTypes(super)_";")
 	}
}

ClassMethod FlushGlobals(toFlush As %Boolean)
{
	if toFlush {
		kill ^irisToJavaClassName
		kill ^projectedJavaClasses
		kill ^irisToODBCType
	}
}

}
