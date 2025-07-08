/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Compiler.Binding.JavaDocCreator Extends %RegisteredObject [ System = 4 ]
{

Property javaDoc As %Boolean;

Property tConverter As JavaTypeConverter;

Property irisClassName As %String;

Property javaClassName As %String;

Property documaticHost As %String;

Property documaticPort As %String;

Property documaticNamespace As %String;

Property documaticUrl As %String;

Property deleteMethodNames As %List;

Property existsMethodNames As %List;

Method %OnNew(irisClassName As %String, javaClassName As %String, projParams As %ArrayOfDataTypes, tConverter As JavaTypeConverter) As %Status
{
	s ..javaDoc = projParams.GetAt("JAVADOC")
	s ..tConverter = tConverter
	s ..irisClassName = irisClassName
	s ..javaClassName = javaClassName
	
	s ..documaticHost = projParams.GetAt("DOCUMATICHOST")
	if ..documaticHost = "" {s ..documaticHost = "localhost"}
	s ..documaticPort = projParams.GetAt("DOCUMATICPORT")
	if ..documaticPort = "" {s ..documaticPort = ^%SYS("WebServer","Port")}
	s ..documaticNamespace = projParams.GetAt("DOCUMATICNAMESPACE")
	if ..documaticNamespace = "" {s ..documaticNamespace = $namespace}
	s ..documaticUrl = """"_..documaticHost_":"_..documaticPort_"/csp/documatic/%25CSP.Documatic.cls?APP=1&PAGE=CLASS&LIBRARY="_..documaticNamespace_"&CLASSNAME="
	
	s ..deleteMethodNames = $lb("%DeleteId", "%Delete")
	s ..existsMethodNames = $lb("%ExistsId", "%Exists")
	Quit $$$OK
}

Method createClassIntro(file As JavaFile, description As %String)
{
	d file.IndentAndWriteLine("/**")
	d file.IndentAndWriteLine(" * Java class generated for IRIS class "_..irisClassName_" on version "_$zv_".<br>")
	if description '= "" {d file.IndentAndWriteLine(" * Description: "_description)}
	d file.IndentAndWriteLine(" * @see <a href = "_..documaticUrl_..irisClassName_"</A>")
	d file.IndentAndWriteLine("**/")
}

Method createConstructorDoc(file As JavaFile, params As %List, hasConnectionObject = 1)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Creates a new instance of class """_..irisClassName_""" in IRIS database", 2)
	d file.IndentAndWriteLine("and a corresponding instance of class <code>"_..javaClassName_"</code>.", 2)
	
	d ..createParamsDoc(file, params, hasConnectionObject)
	d file.IndentAndWriteLine("*/", 1)
}

Method createSystemConstructorDoc(file As JavaFile)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("This constructor is NOT for use in application. It is called by binding code.", 2)
	d file.IndentAndWriteLine("*/", 1)
}

Method createIRISClassNameDoc(file As JavaFile)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Returns name of class "_..javaClassName_" as it is in IRIS database.", 2)
	d file.IndentAndWriteLine("@return IRIS class name as <code>String</code>", 2)
	d file.IndentAndWriteLine("*/", 1)
}

Method createOpenDoc(file As JavaFile, methodName As %String, params As %List, hasConnectionObject = 1, hasConcurrency = 0)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Runs IRIS method <code>"_methodName_"</code> to open an object in IRIS database", 2)
	d file.IndentAndWriteLine("and creates corresponding object of class <code>"_..javaClassName_"</code>.", 2)
	
	d file.IndentAndWriteLine("@return <code>RegisteredObject</code> corresponding to opened object", 2)
	d file.IndentAndWriteLine("This object may be of type <code>"_..javaClassName_"</code> or any of its subclasses.", 2)
	
	d ..createParamsDoc(file, params, hasConnectionObject)
	if hasConcurrency {
		d file.IndentAndWriteLine("See Object Concurrency Options in your online IRIS documentation for more information.", 2)
		d file.IndentAndWriteLine("@see <a href = ""https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_persobj#GOBJ_concurrency"">Object Concurrency Options.</A>", 2)
	}
	d file.IndentAndWriteLine("*/", 1)
}

Method createOpenByQueryDoc(file As JavaFile, hasArgs = 0)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Opens all instances of class "_..irisClassName_" that satisfy given simple condition, specified in SQL syntax.", 2)
	
	d file.IndentAndWriteLine("@return Iterator as <code>java.util.Iterator</code> that iterates over all opened objects in specified order.", 2)
	
	d file.IndentAndWriteLine("@param db <code>Database</code> to connect with server", 2)
	d file.IndentAndWriteLine("@param condition Simple condition on objects, in SQL syntax.", 2)
	d file.IndentAndWriteLine("It can refer only to properties of a single object.", 2)
	
	if hasArgs {
		d file.IndentAndWriteLine("@param args Parameters to replace ""?"" in<code>condition</code>.", 2)
		d file.IndentAndWriteLine("If there are no parameters in condition, this may be null or empty array.", 2)
	}
	d file.IndentAndWriteLine("*/", 1)
}

Method createPersistentMethodDoc(file As JavaFile, methodName As %String, params As %List)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	
	if $lf(..deleteMethodNames, methodName) {	
		d file.IndentAndWriteLine("Runs method <code>"_methodName_"</code> in IRIS to delete an object from the database.", 2)
		d file.IndentAndWriteLine("Deletes the stored version of the object with OID <var>oid</var> from the database.", 2)
		d file.IndentAndWriteLine("It does not remove any in-memory versions of the object that may be present.", 2)
	} elseif $lf(..existsMethodNames, methodName) {
		d file.IndentAndWriteLine("Runs method <code>"_methodName_"</code> in IRIS to check if an object exists.", 2)
	}
	
	d ..createParamsDoc(file, params, 2, .hasConcurrency)
	if hasConcurrency {
		d file.IndentAndWriteLine("See Object Concurrency Options in your online IRIS documentation for more information.", 2)
		d file.IndentAndWriteLine("@see <a href = ""https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_persobj#GOBJ_concurrency"">Object Concurrency Options.</A>", 2)
	}
	
	d file.IndentAndWriteLine("*/", 1)
}

Method createGetterDoc(file As JavaFile, propName As %String, propType As %String, description As %String)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Returns value of property <code>"_propName_"<code>.", 2)
	if description '= "" {d file.IndentAndWriteLine("<p>Description: "_description_"</p>", 2)}
	
	d file.IndentAndWriteLine("@return current value of <code>"_propName_"</code> as <code>"_propType_"</code>", 2)
	d file.IndentAndWriteLine("@see <a href = "_..documaticUrl_..irisClassName_"#"_propName_""">"_propName_"</A>", 2)
	d file.IndentAndWriteLine("*/", 1)
}

Method createSetterDoc(file As JavaFile, propName As %String, propType As %String, description As %String)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Sets new value for property <code>"_propName_"<code>.", 2)
	if description '= "" {d file.IndentAndWriteLine("<p>Description: "_description_"</p>", 2)}
	
	d file.IndentAndWriteLine("@param _val new value to be set as <code>"_propType_"</code>", 2)
	d file.IndentAndWriteLine("@see <a href = "_..documaticUrl_..irisClassName_"#"_propName_""">"_propName_"</A>", 2)
	d file.IndentAndWriteLine("*/", 1)
}

Method createMethodDoc(file As JavaFile, methodName As %String, params As %List, description As %String, isStatic = 0, createsMethodDoc = 0)
{
	if ('..javaDoc) || ('createsMethodDoc) {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Runs method "_methodName_" in IRIS.", 2)
	if description '= "" {d file.IndentAndWriteLine("<p>Description: "_description_"</p>", 2)}
	
	d ..createParamsDoc(file, params, isStatic)
	d file.IndentAndWriteLine("@see <a href = "_..documaticUrl_..irisClassName_"#"_methodName_""">Method "_methodName_"</A>", 2)
	d file.IndentAndWriteLine("*/", 1)
}

Method createStoredProcedureDoc(file As JavaFile, procName As %String, methodName As %String, description As %String)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Returns a CallableStatement for stored procedure "_procName_".", 2)
	if description '= "" {d file.IndentAndWriteLine("<p>Description: "_description_"</p>", 2)}
	
	d ..createParamsDoc(file, "", 2)
	d file.IndentAndWriteLine("@see <a href = "_..documaticUrl_..irisClassName_"#"_methodName_""">Method "_methodName_"</A>", 2)
	d file.IndentAndWriteLine("*/", 1)
}

Method createQueryDoc(file As JavaFile, queryName As %String, description As %String, hasConnectionObject = 1)
{
	if '..javaDoc {return}
	
	d file.IndentAndWriteLine("/**", 1)
	d file.IndentAndWriteLine("Returns a CallableStatement for query "_queryName_".", 2)
	if description '= "" {d file.IndentAndWriteLine("<p>Description: "_description_"</p>", 2)}
	
	d ..createParamsDoc(file, "", hasConnectionObject)
	d file.IndentAndWriteLine("*/", 1)
}

Method createParamsDoc(file As JavaFile, params As %List, hasConnectionObject = 0, ByRef hasConcurrency = 0)
{
	if hasConnectionObject {
		if hasConnectionObject = 1 {
			d file.IndentAndWriteLine("@param connection <code>IRISConnection</code> instance to connect with IRIS database", 2)
		} else {
			d file.IndentAndWriteLine("@param db <code>Database</code> instance to connect with IRIS database", 2)
		}
	}
	
	s params = ..tConverter.paramsToString(params)
	if params '= "" {
		for i=1:1:$length(params, ", ") {
			s param = $p(params, ", ", i)
			s type = $p(param, " ", 1)
			s name = $p(param, " ", 2)
			
			if name = "concurrency" {s hasConcurrency = 1}
			d file.IndentAndWriteLine("@param "_name_" as <code>"_type_"<code>", 2)
		}
	}
	
	if hasConnectionObject {d file.IndentAndWriteLine("@throws java.sql.SQLException in case of error", 2)}
}

}
