/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This superclass is used as a known entry point for OpenAPI REST API Models.
/// Subclasses of this class should override the XData OpenAPI block for storing custom API descriptions. 
Class %REST.Spec [ Abstract, System = 3 ]
{

/// The name of the XData block which contains the OpenAPI 2.0 specification
Parameter XDataName = "OpenAPI";

/// If Strict=0 (false), then only the swagger properties which are needed for code generation are checked during compile.
/// If Strict=1 (true), then all swagger properties are checked during compile.
Parameter Strict As STRING = 1;

/// Create a REST application.
/// If the REST application already exists, then it will be replaced.
/// The swagger argument contains the OpenAPI 2.0 swagger document for the application.
/// If xdataStream="", then the RESTSpec will be empty.<br/>
/// If the request body is empty, the addPing feature determines if a ping method should be added to the empty swagger spec.
/// The REST application package containing 3 classes:<br/>
/// The specification class (.spec) which is created with the specified OpenAPI XData block.<br/>
/// The dispatch class (.disp) which is deleted for a new application and will be created by compile<br/>
/// The implementation class (.impl) which is updated as needed with other contents unchanged.
ClassMethod %CreateRESTApplication(applicationName As %String, swagger = "", ByRef features, Output newApplication As %Boolean) As %Status [ Internal ]
{
	//Check to see if class already exists
	Set specClassName=applicationName_".spec"
	Set cDef=##class(%Dictionary.ClassDefinition).%OpenId(specClassName,4,.sc)
	If $isobject(cDef) {
		Do ..%RemoveXDataBlock(cDef,..#XDataName)
		Set newApplication=0
	} Else {
		Set cDef=##class(%Dictionary.ClassDefinition).%New(specClassName)
		Set newApplication=1
	}
	
	Set sc=$$$OK
	
	Try {
		// Use transaction in order to be able to save no classes if there is an error
		Tstart
		
		$$$SysLog(3,"apimgmnt","[%REST.Spec:%CreateRESTApplication]","applicationName="_applicationName_", newApplication="_newApplication)

		// RESTSpec class is always subclass of %REST.Spec
		Set cDef.Super = "%REST.Spec"
		
		// Always procedure block.
		Set cDef.ProcedureBlock=1
		
		// Create a RESTSpec xdata block
		Set xData=##class(%Dictionary.XDataDefinition).%New()
		Set xData.Name=..#XDataName
		Set xData.MimeType="application/json"

		If swagger'="" {
			// If Swagger specified, then format and copy to xdata block.
			If $isobject(swagger),swagger.%IsA("%Library.DynamicAbstractObject") {
				// Already a dynamic object
				Set swaggerObject=swagger
			} Else {
				// A JSON stream or string
				Set swaggerObject=##class(%Library.DynamicAbstractObject).%FromJSON(swagger)
			}
			// Remove host property, sice this system is always the host.
			Do swaggerObject.%Remove("host")
			// Format and write the swagger.
			Set formatter=##class(%JSON.Formatter).%New()
			If $$$ISOK(sc) Set sc=formatter.FormatToString(swaggerObject,.swaggerString)
			If $$$ISOK(sc) Set sc=xData.Data.Write(swaggerString)

		} Else {
			// If no stream, then just empty RERSTSpec
			Do xData.Data.WriteLine("{")
			Do xData.Data.WriteLine("  ""swagger"":""2.0"",")
			Do xData.Data.WriteLine("  ""info"":{")
			Do xData.Data.WriteLine("    ""title"":""New Application"",")
			Do xData.Data.WriteLine("    ""version"":""0""")
			Do xData.Data.WriteLine("  },")
			Do xData.Data.WriteLine("  ""paths"":{")
			// Add a ping method if required
			If $get(features("addPing")) {
				Do xData.Data.WriteLine("    ""/ping"":{")
				Do xData.Data.WriteLine("      ""get"":{")
				Do xData.Data.WriteLine("        ""summary"":""Respond to ping"",")
				Do xData.Data.WriteLine("        ""description"":""This request returns a reply message in response to a /ping request."",")
				Do xData.Data.WriteLine("        ""operationId"":""ping"",")
				Do xData.Data.WriteLine("        ""responses"":{")
				Do xData.Data.WriteLine("          ""200"":{")
				Do xData.Data.WriteLine("            ""description"":""Returns 'Reply from "_applicationName_"'."",")
				Do xData.Data.WriteLine("            ""schema"": {")
				Do xData.Data.WriteLine("              ""type"":""string""")
				Do xData.Data.WriteLine("            }")
				Do xData.Data.WriteLine("          }")
				Do xData.Data.WriteLine("        }")
				Do xData.Data.WriteLine("      }")
				Do xData.Data.WriteLine("    }")
			}
			Do xData.Data.WriteLine("  }")
			Do xData.Data.WriteLine("}")
		}
		
		// Add the xdata block to the class.
		If $$$ISOK(sc) {
			Set sc=cDef.XDatas.Insert(xData)
		}

		// If strict feature is specified, then override Strict parameter of .spec class.
		If $data(features("strict")) {
			Set desc="If Strict=0 (false), then only the swagger properties which are needed for code generation are checked during compile."_$c(13,10)
			Set desc=desc_"If Strict=1 (true), then all swagger properties are checked during compile."
			Set sc=..CreateParameter(cDef,"Strict",features("strict"),desc)
		}
		
		// Save RESTSpec class
		If $$$ISOK(sc) {
			Set sc=cDef.%Save()
		}

		// Delete the dispatch class for this application.
		If $$$ISOK(sc) {
			Do $system.OBJ.Delete(applicationName_".disp","-d")
		}
		
		// Compile the specification class for this application.
		// The compilation of the specification will cause the dispatch and implementation classes to be updated.
		If $$$ISOK(sc) {
			Set sc=$system.OBJ.Compile(specClassName,"ck-d")
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISOK(sc) {
		// Save the classes that we have created.
		Tcommit
		
	} Else {
		// Save no classes if there is an error,unless features("keep")
		If $get(features("keep")) {
			Tcommit
		} Else {
			Trollback
		}
		Do ##class(%REST.API).LogStatusError("[%REST.Spec:%CreateRESTApplication]",sc)
	}
	
	Quit sc
}

/// Create a parameter
ClassMethod CreateParameter(classDef As %Dictionary.ClassDefinition, name As %String, value As %String, desc As %String) As %Status [ Internal ]
{
 	Set sc=$$$OK
	Set className=classDef.Name
	
	Set paramPos=""
	// Look for existing parameter
	For i=1:1:classDef.Parameters.Count() {
		If classDef.Parameters.GetAt(i).Name=name {
			Set paramPos=i
			Quit
		}
	}

 	// Create a new parameter
	Set paramName=className_":"_name
	Kill %objlasterror
	Set paramDef=##class(%Dictionary.ParameterDefinition).%New(paramName)
	If paramDef="" {
		Quit $get(%objlasterror,$$$ERROR($$$FailedToCreateClass,paramName) )
 	}

	// Fill in the type, value and description
	Set paramDef.Default=value
	Set paramDef.Description=$get(desc)
	
	// Insert into the class definition
	If paramPos="" {
		Set sc=classDef.Parameters.Insert(paramDef)
	} Else {
		Set sc=classDef.Parameters.SetAt(paramDef,paramPos)
	}

	Quit sc
}

/// Delete a new REST application including the implementation class.
ClassMethod %DeleteRESTApplication(applicationName As %String, Output newApplication As %Boolean) As %Status [ Internal ]
{
	$$$SysLog(3,"apimgmnt","[%REST.Spec:%DeleteRESTApplication]","applicationName="_applicationName)
	
	Set classes(applicationName_".spec","-d")=""
	Set classes(applicationName_".disp","-d")=""
	Set classes(applicationName_".impl","-d")=""
	Do $system.OBJ.Delete(.classes,"-d")

	Quit $$$OK
}

ClassMethod %RemoveXDataBlock(cDef, blockName) [ Internal ]
{
 	Set key = cDef.XDatas.FindObjectId(cDef.Name_"||"_blockName)
 	If (key'="") {
 		Set oid = cDef.XDatas.RemoveAt(key)
	}
}

ClassMethod %OnCompile() [ CodeMode = objectgenerator, Internal ]
{
	// Don't run this method on the base class
	Set classname=%compiledclass.Name
	If classname="%REST.Spec" Quit $$$OK

	Set sc=$$$OK
	
	// Generate the classes needed by a REST application.
	If $$$ISOK(sc),$$$ClassShortName(classname)="spec" {
		Set sc=##class(%REST.RESTSpec).GetSpecificationXData(classname,,.xdata)
		If $$$ISOK(sc),$isobject(xdata) {
			Set generator=##class(%REST.Generator).%New()
			Set applicationName=$$$ClassPackageName(classname)
			Set sc=generator.Process(applicationName)
			If $$$ISERR(sc) {
				Set %RESTInternalError=generator.InternalError
			}
		}
	}

	Quit sc
}

/// Storage space for the swagger document.
XData OpenAPI [ MimeType = application/json ]
{
{ "swagger":"2.0" }
}

}
