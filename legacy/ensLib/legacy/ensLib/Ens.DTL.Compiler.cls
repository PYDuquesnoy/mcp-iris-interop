/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is the DTL Compiler. It it called primarily during the compilation
/// process of subclasses of Ens.DataTransformDTL that define a DTL XDATA block. 
/// However, it can be called to directly compile a file or a stream containing DTL
/// 
/// These debug flags affect the diagnostic output of the compiler:-
/// ^Ens.Debug("ShowGeneratedXML") - Displays xml reconstructed from the parse
/// tree to the current device
Class Ens.DTL.Compiler Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the language of the current compilation
Property Language As %String;

/// This holds the root of the Parse Tree
Property Transform As Ens.DTL.Transform;

/// This holds the name of the data transform class
Property ClassName As %String;

/// This holds the method implementation stream
Property Implementation As %RawString [ Transient ];

Property Indent As %String [ InitialExpression = {$char(9)} ];

/// Counter for Python Method name suffix
/// to ensure unique method name regardless of thread or context location  
Property PyMethodCounter As Ens.BPL.Counter;

/// This property tracks newly created variables to be stored in the context of the Compiler. These variables 
/// are created when an Assign Action uses a "set" statement to create a new variable that is not a VDoc
Property ContextCustomVariables As %String [ MultiDimensional ];

/// This property stores the key for each ForEach action the compiler encounters at the time of code generation
Property ForEachKeys As %String [ MultiDimensional ];

/// Accesor for Language
Method LanguageGet() As %String
{
	#; Language is specfied by the Transform
	Set tLanguage=..Transform.Language
	
	#; Only legal languages are objectscript (cache) and basic
	$$$ASSERT(tLanguage=$$$objectscript||(tLanguage=$$$basic)||(tLanguage=$$$python))
	
	Quit tLanguage
}

ClassMethod ParseStream(Output pTransform As Ens.DTL.Transform, pStream As %BinaryStream) As %Status
{
	Set tSC=$$$OK
	Try {

		Set tParser=##class(Ens.DTL.Parser).%New()
		$$$ASSERT($IsObject(tParser))
		
		#; Import the Transform definition from the specified stream
		Set tSC=tParser.ParseStream(.pTransform,pStream)	
	
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Parse the DTL contained in the supplied stream and generate a stream
/// containing the implementation of the Transform method
ClassMethod CompileStream(pStream As %BinaryStream, pClass As %Dictionary.ClassDefinition, pMethod As %Stream.MethodGenerator) As %Status
{
	Set tSC=$$$OK
	Try {

		Set tSC=..ParseStream(.tTransform,pStream)
		If $$$ISERR(tSC) Quit
		
		$$$ASSERT($IsObject(tTransform)&&tTransform.%Extends("Ens.DTL.Transform"))
	
		#; Create a validation context
		Set tValidationContext=##class(Ens.DTL.ValidationContext).%New()
		$$$ASSERT($IsObject(tValidationContext))
		
		#; Now do sanity Check
		Set tValidateStatus=$$$OK,tSC=tTransform.Validate(.tValidateStatus,tValidationContext)
		If $$$ISERR(tSC) Quit
		
		#; Display it for now
		If $$$ISERR(tValidateStatus) Do $System.Status.DisplayError(tValidateStatus)
		
		If tValidationContext.IsFatal=1 {
			Set tSC=$$$ERROR($$$EnsErrDTLCannotBeCompiled) Quit
		}
		
		If $G(^Ens.Debug("ShowGeneratedXML")) {
			
			#; Generate the XML
			Set tSC=..GenerateXML(tTransform)
			If $$$ISERR(tSC) Quit
		}
		
		#; Generate the Code
		Set tSC=..GenerateCode(tTransform,pClass,pMethod)
	
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod GenerateCode(pTransform As Ens.DTL.Transform, pClass As %Dictionary.ClassDefinition, pMethod As %Stream.MethodGenerator) As %Status
{
	Set tSC=$$$OK
	Try {
		#; Create an instance of the compiler
		Set tCompiler=##class(Ens.DTL.Compiler).%New()
		$$$ASSERT($IsObject(tCompiler))

		#; Initialize it
		Set tCompiler.Transform=pTransform
		Set tCompiler.ClassName=pClass.Name
		Set tCompiler.Implementation=pMethod

		#; Initialize pymethodcounter
		Set tCompiler.PyMethodCounter=##class(Ens.BPL.Counter).%New("pyExec")

		#; Generate the code
		Set tSC=pTransform.GenerateCode(tCompiler)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod GenerateXML(pTransform As Ens.DTL.Transform) As %Status
{
	Set tSC=$$$OK
	Try {
			
		Set tStream=##class(%GlobalBinaryStream).%New()
		$$$ASSERT($IsObject(tStream))
			
		Do tStream.WriteLine(""),tStream.WriteLine("<?xml version='1.0' ?>")
		Set tSC=pTransform.GenerateXML(tStream)
		If $$$ISERR(tSC) Quit
		
		Do tStream.OutputToDevice()
		
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method AddIndent()
{
	Set ..Indent = ..Indent _ $char(9)
}

Method RemoveIndent()
{
	If $length(..Indent) > 1 {
		Set ..Indent = $extract(..Indent,1,*-1)
	}
}

/// this method allows to parse vDoc syntax from the input, get its values using objectscript and pass these values as arguments to the generated python method.
/// example: text = "source.{PIDgrp.PID:PatientID.IDNumber} + "" abc "" + source.{PIDgrp.PID:PatientID.IDNumber}"
/// returns->
/// args     =     2
/// args(1)  =     "source.{PIDgrp.PID:PatientID.IDNumber}"
/// args(2)  =     "source.{PIDgrp.PID:PatientID.IDNumber}"
/// fullcode =     "set arg2 = source.{PIDgrp.PID:PatientID.IDNumber}"_$c(13,10)_" set arg1 = source.{PIDgrp.PID:PatientID.IDNumber}"_$c(13,10)_" "
/// replaced =     "arg1 + "" abc "" + arg2"
ClassMethod vDocsToPythonArgs(text, args, fullcode, replaced) As %Status
{
    Set tSC = $$$OK
    Try {
        Kill args, fullcode
        Set fullcode = "", args = 0, replaced = text, newStart = 0
        Set matcher=##class(%Regex.Matcher).%New("(source\.\{[^}]+\})|(target\.\{[^}]+\})")
        Set matcher.Text = text
        While matcher.Locate() {
			If matcher.Start(1)>0 {Set id = 1} Else {Set id = 2}
			Set args($INCREMENT(args)) = matcher.Group(id)
			Set fullcode = "set arg"_args_" = "_matcher.Group(id)_$CHAR(13,10)_" "_fullcode
			Set replaced = $EXTRACT(replaced,1,matcher.Start-1-newStart)_"arg"_args_$EXTRACT(replaced,matcher.End-newStart,*)
			Set newStart = newStart + $LENGTH(args(args)) - $LENGTH("arg"_args)
        }
    } Catch ex {
       Set tSC = ex.AsStatus()
    }
    Return tSC
}

/// Takes in a python expression and returns the arguments as ArrayOfDataTypes. 
/// expression = "variable1 + math.sqrt(variable2)" will return {"variable1":1,"math":1, "variable2":1}
/// Note: in the above expression, "math" is also treated as a variable
ClassMethod parsePyExpression(expression As %String) As %ListOfDataTypes [ Language = python ]
{
	import iris
	import ast 
	osArray = iris.cls('%ArrayOfDataTypes')._New()	
	tree = ast.parse(expression)
	for i in ast.walk(tree):
		if isinstance(i,ast.Name):
			osArray.SetAt("1",i.id)
	return osArray
}

/// Takes in an objectscript code block and returns all the new variables that have been "set" in it
ClassMethod findLocalVariables(text) As %ArrayOfDataTypes
{
	Set matcher=##class(%Regex.Matcher).%New("(?im)(?:\b(?:s(?:et)?) |,\s*)([^\s=,]+)")
	Set matcher.Text = text
	Set osArray = ##class(%ArrayOfDataTypes).%New()
	While matcher.Locate() {
		Do osArray.SetAt("1",matcher.Group(1))
	}
	Return osArray
}

/// Takes in a python expression and returns list of arguments that are being compared to an empty string. 
/// for expression: ("" == arg1) and (arg2 == "") and (arg3=arg4) and (not arg5), 
/// this method returns an array with arg1, arg2 and arg5 as keys
ClassMethod findEmptyStringComparisons(expression As %String) As %ArrayOfDataTypes [ Language = python ]
{
import ast
import iris
irisCls = iris.cls('%ArrayOfDataTypes')
osArray = irisCls._New()

tree = ast.parse(expression)
for i in ast.walk(tree):
	if isinstance(i,ast.Compare):
		if isinstance(i.ops[0], ast.Eq) or isinstance(i.ops[0],ast.NotEq):  
			if isinstance(i.left, ast.Name) and isinstance(i.comparators[0],ast.Constant) and i.comparators[0].value == '' :
				osArray.SetAt("1",i.left.id)
			if isinstance(i.left, ast.Constant) and i.left.value == '' :
				osArray.SetAt("1",i.comparators[0].id)
	if isinstance(i, ast.UnaryOp) and isinstance(i.op, ast.Not):
		osArray.SetAt("1",i.operand.id)    
return osArray
}

/// This method returns all the variables that have been defined in a block of python code 
ClassMethod pyDefinedVariables(text) [ Language = python ]
{
import ast
import iris
osArray = iris.cls('%ArrayOfDataTypes')._New()
tree = ast.parse(text)
for node in ast.walk(tree):
	if isinstance(node, ast.Assign):  
		for target in node.targets:
			if isinstance(target, ast.Name):  
				osArray.SetAt("1",target.id)			
return osArray
}

/// Slightly modified from ##class(Ens.BPL.Compiler).GeneratePyExec()
/// Generates a wrapped Python Method for Expressions Or Code blocks
/// Returns the method signature.
/// Parameters<ul>
/// <li>content - This can be a stream when invoked for code blocks. Otherwise this is a String (expression)</li>
/// <li>errorPrefix - Tags some context in generated menthod signature to record what shape time is originated from.
///            Also included as prefix in status for runtime errors when running python code</li>
/// <li>invokeLang - System Language ObjectScript or Basic</li>
/// <li>returnsValue - Controls how method generater shapes invocation signature used by calling context</li>
/// <li>args - arguments obtained by replacing vDocSyntax from a python expression using the method vDocsToPythonArgs <li>
/// <li>newArgs - contains arguments obtained by parsing a python expression. eg: python expression : str(arg1) + str(math.sqrt(arg2)). newArgs would be [arg1, arg2]<li>
/// </ul>
Method GeneratePyExec(content As %GlobalBinaryStream, errorPrefix = "", invokeLang = {$$$objectscript}, returnsValue As %Boolean = 1, compiler As Ens.DTL.Compiler, args As %Integer = 0, newArgs As %ListOfDataTypes = {##class(%ListOfDataTypes).%New()}) As %String [ Internal, ProcedureBlock = 1 ]
{
	// generating a new class called pythonMethods which holds all the python wrapper methods that will be generated for this DTL
	// under a new package named after the calling class.  
	Set helperClass = compiler.ClassName_".pythonMethods"
	If '##class(%Dictionary.ClassDefinition).%ExistsId(helperClass) {
		Set clsDef=##class(%Dictionary.ClassDefinition).%New(helperClass)
	} Else {
		Set clsDef = ##class(%Dictionary.ClassDefinition).%OpenId(helperClass)
	}
    Set pyMethod=##class(%Dictionary.MethodDefinition).%New()
	Set pyMethod.Name=..PyMethodCounter.Next() // each method named as: "pyExec"_methodSuffix
    Do pyMethod.parentSetObjectId(..ClassName)
	Set pyMethod.Language=$$$python
	Set pyMethod.ClassMethod=1 
	Set pyMethod.Description="Generated. DO NOT EDIT. "_errorPrefix_" for "_..ClassName
    Set pyMethod.SequenceNumber=..PyMethodCounter.Index
    Set pyMethod.ReturnType="%Library.String"
	Set pyMethod.FormalSpec="process:Ens.BusinessProcess,context:Ens.BP.Context,source:%Library.Persistent,target:%Library.Persistent, aux:%Library.RegisteredObject,status:Ens.Util.PyByRef"
	
	//adding arguments obtained from vDocsToPythonArgs() to the list of method parameters for the python method being generated

	For countArgs = args : -1 : 1 {
		Set pyMethod.FormalSpec =  pyMethod.FormalSpec_",arg"_countArgs
	}

	For countNewArgs = newArgs.Count() : -1 : 1 {
		Set pyMethod.FormalSpec =  pyMethod.FormalSpec_","_newArgs.GetAt(countNewArgs)
	}

	//adding arguments to account for the possibility that a "key" for a foreach action may be passed into a python method
	Set key = ""
	For { 
		Set key = $ORDER(compiler.ForEachKeys(key)) Quit:(key = "")
		Set pyMethod.FormalSpec =  pyMethod.FormalSpec_","_key
		}

	If 'returnsValue{
		Set pyMethod.FormalSpec =  pyMethod.FormalSpec_", pyDefinedVars:%ArrayOfDataTypes"
	}
	Do pyMethod.Implementation.WriteLine("import iris")
	Do pyMethod.Implementation.WriteLine("import traceback")
	Do pyMethod.Implementation.WriteLine("status.value=iris.cls('%SYSTEM.Status').OK()")
    Do pyMethod.Implementation.WriteLine("pErrorMessage=""""")

    // Start Region - General Py imports
	// Checks if there are any libraries imported under the Transform tab and adds them to the method
	// Note: here pyMethod essentially is getting passed as an object reference, so we don't need to pass it by reference or expect a return value
    Do ..writeGeneralPyImports(pyMethod, errorPrefix)
	// End Region - General Py imports

	Set pyDefinedVariables = ##class(%ArrayOfDataTypes).%New()
	If $ISOBJECT(content) Do content.Rewind()
	Set:'returnsValue pyDefinedVariables = ##class(Ens.DTL.Compiler).pyDefinedVariables(content.Read())

    // Start Region - Py Expression or Code
	Do ..writePythonCode(pyMethod, content, errorPrefix, returnsValue,pyDefinedVariables)
	// End Region - Py Expression or Code

    Do clsDef.Methods.Insert(pyMethod)
    Do clsDef.%Save()
	Do $SYSTEM.OBJ.Compile(clsDef.Name)

	// now write code to invoke this newly created class/package in the main .int file
	Set returnName = "return"_pyMethod.Name
	Set statusName = "status"_pyMethod.Name
	Set invokeMethod = "##class("_clsDef.Name_")."_pyMethod.Name
	Do ..invokePyMethodinIntFile(compiler,returnName,statusName,invokeMethod,args,returnsValue, newArgs,pyDefinedVariables)
	Quit returnName
}

Method invokePyMethodinIntFile(compiler, returnName, statusName, invokeMethod, args, returnsValue, newArgs, pyDefinedVariables)
{
	Do compiler.Implementation.WriteLine(" ; ====== Start Code Block To Call Python Method ======")
	Do compiler.Implementation.WriteLine("   Set "_statusName_" = ##class(Ens.Util.PyByRef).%New()")
	Do:'returnsValue compiler.Implementation.WriteLine("   Set pyDefinedVars = ##class(%ArrayOfDataTypes).%New()")
	Set parentheses = "(.process, .context, .source, .target, .aux ,."_statusName
	For countArgs = args : -1 : 1 {
		Set parentheses = parentheses_",arg"_countArgs
	}
	For countNewArgs = newArgs.Count() : -1 : 1 {
		Set parentheses = parentheses_","_newArgs.GetAt(countNewArgs)
	}
	Set key = ""
	For { 
		Set key = $ORDER(compiler.ForEachKeys(key)) Quit:(key = "")
		Set parentheses = parentheses_",$g("_key_")"
		}
	Set:'returnsValue parentheses = parentheses_",.pyDefinedVars"
	Set parentheses = parentheses_")"
	Do compiler.Implementation.WriteLine("   "_$SELECT(returnsValue:"Set "_returnName_" =",1:"Do ")_invokeMethod_parentheses)
	Do compiler.Implementation.WriteLine("   If $$$ISERR("_statusName_".value) Set tSC = "_statusName_".value Quit")  // Allow to unwind on status error
    If 'returnsValue{
		Set key=""
		For  {
			Set value=pyDefinedVariables.GetNext(.key)  
			Quit:key="" 
			Do compiler.Implementation.WriteLine("   	Set "_key_"=pyDefinedVars.GetAt("""_key_""")")
			Set compiler.ContextCustomVariables(key) = ""
		}
		Do compiler.Implementation.WriteLine("   	Kill pyDefinedVars")
	}
	Do compiler.Implementation.WriteLine(" ; ====== End Code Block ======")
}

/// Checks if there are any libraries imported under the Transform tab and adds them to the method
Method writeGeneralPyImports(pyMethod As %Dictionary.MethodDefinition, errorPrefix)
{
	Kill importsArray
    Set importsArray=0

    Set genPyImports=$TRANSLATE(..Transform.pyFromImport,$CHAR(13))
    Set len=$LENGTH(genPyImports,$CHAR(10))
    For i=1:1:len {
        Set genPyImport=$ZSTRIP($PIECE(genPyImports,$CHAR(10),i),"<>W")
        Continue:""=genPyImport
        Continue:"import iris"=genPyImport  // Already included
        Continue:"import traceback"=genPyImport  // Already included
        Set importsArray($INCREMENT(importsArray))=genPyImport
    }
    // ONLY include an imports section if additional imports have been specified
    If importsArray {
        Do pyMethod.Implementation.WriteLine("try:")
        For i=1:1:importsArray {
            Do pyMethod.Implementation.WriteLine(" "_importsArray(i))
        }
        Do pyMethod.Implementation.WriteLine("except:")
	    Do pyMethod.Implementation.WriteLine(" pErrorMessage='"_errorPrefix_"'+(traceback.format_exc()[:28000])")
        // The DTL can fail when deployed to environment that is missing required Py module dependencies
        Do pyMethod.Implementation.WriteLine(" status.value=iris.cls('%SYSTEM.Status').Error("_$$$PythonImportFailed_",pErrorMessage)")
        // Return empty string from Python to ObjectScript
		Do pyMethod.Implementation.WriteLine(" print(""error importing one or more libraries in general python import section"")")
												
        Do pyMethod.Implementation.WriteLine(" return ''")
    }
    Kill importsArray
}

Method writePythonCode(pyMethod As %Dictionary.MethodDefinition, content, errorPrefix, returnsValue, pyDefinedVariables)
{
	Do pyMethod.Implementation.WriteLine("try:")
	// Handle Py Code block
    If $ISOBJECT(content) {
        Do content.Rewind()
		// find least indent
        Set indent=999,resetTerminator=1 

		// Need LineTerminator to match current normalized / non-normalized XML
        If (content.LineTerminator=$CHAR(10)) {
            Set line=content.ReadLine()
            If $EXTRACT(line,*)=$CHAR(13) {
                Do content.Rewind()
                Set content.LineTerminator=$CHAR(13,10)
            } Else {Do content.Rewind()}
        } Else {
            Set line=content.ReadLine()
            If line[$CHAR(10) {
                Do content.Rewind()
                Set content.LineTerminator=$CHAR(10)
            } Else {Do content.Rewind()}
        }
		// Code blocks do not return a value. Only used for example to set a property on context
        Set rCount=0
        For {
            Quit:content.AtEnd
            Set line=content.ReadLine()
			// Variable rline is used to help consistency of indentation characters
            // for nesting blocks regardless values supplied in designer
            Set rline=$ZSTRIP(line,"<W")
			// Decision: Keep Python comments (line prefixed with "#")
            Set indent=($LENGTH(line)*2)-$LENGTH(rline)+1
			// Trade leading whitespace characters for spaces
            Do pyMethod.Implementation.WriteLine($JUSTIFY(rline,indent))
            Set:"#"'=$EXTRACT(rline) rCount=rCount+1
        }
		// Python block MUST have at least one functional placeholder statement to compile
        // Cannot just have a code block with all "empty lines" or all "commented out commands"
        // This behavior can be mitigated by design time validation.
        // However, will retain fall back to inject "pass", to ensure classes can compile during development
        Do:0=rCount pyMethod.Implementation.WriteLine(" pass")
    } 

	// Handle Py expression. Allow compilation to proceed if placeholder is applied
    Else {
		// No useful content put in value of expression
        If ""=$LENGTH($ZSTRIP(content,"<>W")) {
            Do pyMethod.Implementation.WriteLine(" return")
		// "pass" keyword used for value of expression
        } ElseIf "pass"=$ZSTRIP(content,"<>W") {
            Do pyMethod.Implementation.WriteLine(" return")
		// comment line used for value of expression
        } ElseIf "#"=$EXTRACT($ZSTRIP(content,"<W")) {
            Do pyMethod.Implementation.WriteLine(" return")
		// running useful code
        } Else {
            Do pyMethod.Implementation.WriteLine(" return "_$ZSTRIP(content,"<W"))
        }
    }
	If 'returnsValue{
			Set key=""
			For  {
				Set value=pyDefinedVariables.GetNext(.key)  
				Quit:key="" 
				Do pyMethod.Implementation.WriteLine(" if """_key_""" in locals(): pyDefinedVars.SetAt("_key_","""_key_""")")
			}
		}
    Do pyMethod.Implementation.WriteLine("except:")
	Do pyMethod.Implementation.WriteLine(" pErrorMessage='"_errorPrefix_"'+(traceback.format_exc())")
    Do pyMethod.Implementation.WriteLine(" status.value=iris.cls('%SYSTEM.Status').Error("_$$$PythonGeneralError_",pErrorMessage)")
    Do pyMethod.Implementation.WriteLine(" return ''")
}

}
