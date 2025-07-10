/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsCompiler)

/// This is the BPL Compiler. It it called during the compilation
/// process of subclasses of Ens.BusinessProcessBPL to generate the business
/// process runtime classes.
/// 
/// These debug flags affect the diagnostic output of the compiler:-
/// ^Ens.Debug("ShowGeneratedXML") - Displays XML reconstructed from the parse
/// tree to the current device.
Class Ens.BPL.Compiler Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// This holds the thread counter
Property ThreadCounter As Ens.BPL.Counter;

/// This holds the method counter
Property MethodCounter As Ens.BPL.Counter;

/// Counter for Python Method name suffix
/// to ensure unique method name regardless of thread or context location  
Property PyMethodCounter As Ens.BPL.Counter;

/// This holds the business class being generated
Property Context As %Dictionary.ClassDefinition;

/// This holds the root of the parse tree being compiled
Property Process As Ens.BPL.Process;

/// This holds the language for the generated classes
Property Language As %String;

/// This holds the current context of the compilation. It supports
/// a 'Path' property which defines the current position in the nesting 
/// hierarchy of the parse tree being traversed.
Property ContextStack As Ens.BPL.ContextStack;

/// This holds the stack of thread classes being generated. There is at minimum
/// a single thread class which implements the top-level activities of the process.
Property ThreadStack As Ens.BPL.Stack;

/// This holds the stack of methods being generated
Property MethodStack As Ens.BPL.Stack;

/// This holds the stack of states
Property StateStack As Ens.BPL.Stack;

/// This holds the stack of states which may be broken to
Property BreakStack As Ens.BPL.Stack;

/// This holds the stack of states which may be continued to
Property ContinueStack As Ens.BPL.Stack;

/// This holds the state counter
Property StateCounterStack As Ens.BPL.Counter;

/// This holds the current method being generated
Property CurrentMethod As %Dictionary.MethodDefinition [ Calculated ];

/// This holds the current thread being generated
Property CurrentThread As Ens.BPL.CompilerThread [ Calculated ];

/// This holds the counter for the current state
Property CurrentStateCounter As Ens.BPL.Counter [ Calculated ];

/// This holds the list of properties which must be instantiated
/// in the %OnNew() method of the context class
Property PropertiesToNew As list Of %String;

/// This holds the collection of compensatation handlers
/// which are active for the current scope
Property CompensationHandlers As %String [ MultiDimensional ];

/// Reserved variable name for result of Python method invocation.
/// Required to support handling of status error and stack unwind
Parameter ObjectScriptVariableNameForPythonReturn = "ensPyExecReturnVariable";

/// Accesor for Language
Method LanguageGet() As %String
{
    #; Language is specfied by the Transform
    Set tLanguage=..Process.Language
    
    #; Only legal languages are objectscript (cache) and basic
    $$$ASSERT(tLanguage=$$$objectscript||(tLanguage=$$$basic)||(tLanguage=$$$python))
    
    Quit tLanguage
}

/// Accessor for the CurrentStateCounter property.
Method CurrentStateCounterGet() As Ens.BPL.Counter
{
    Quit ..StateCounterStack.Top()
}

/// Accessor for the CurrentMethod property.
Method CurrentMethodGet() As %Dictionary.MethodDefinition
{
    $$$ASSERT($IsObject(..MethodStack.Top()))
    Quit ..MethodStack.Top()
}

/// Accessor for the CurrentThread property.
Method CurrentThreadGet() As Ens.BPL.CompilerThread
{
    $$$ASSERT($IsObject(..ThreadStack.Top()))
    Quit ..ThreadStack.Top()
}

/// Parse the BPL contained in the supplied stream and generate/compile
/// the resulting Business Process and its supporting Classes. The Package parameter
/// must contain the name of the cache package prefix which will be prepended to the
/// names of the generated classes
ClassMethod CompileStream(pStream As %BinaryStream, pPackage As %String) As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {

        #; Get a new parser object
        Set tParser=##class(Ens.BPL.Parser).%New()
        $$$ASSERT($IsObject(tParser))
        
        #; Parse the specified stream and obtain the root of the parse tree,
        #; Ens.BPL.Process
        Set tSC=tParser.ParseStream(pStream,.tProcess)
        If $$$ISERR(tSC) Quit
        
        $$$ASSERT($IsObject(tProcess)&&tProcess.%IsA("Ens.BPL.Process"))
        
        #; If the debug flag is set, output the corresponding XML to the 
        #; current device
        If $G(^Ens.Debug("ShowGeneratedXML")) {
            
            #; Generate the XML
            Set tSC=..GenerateXML(tProcess)
            If $$$ISERR(tSC) Quit
        }
    
        #; Create a validation context
        Set tValidationContext=##class(Ens.BPL.ValidationContext).%New()
        $$$ASSERT($IsObject(tValidationContext))
        
        #; Now do sanity Check
        Set tValidateStatus=$$$OK,tSC=tProcess.Validate(.tValidateStatus,tValidationContext)
        If $$$ISERR(tSC) Quit
        
        #; Display it for now
        If $$$ISERR(tValidateStatus) Do $System.Status.DisplayError(tValidateStatus)
        
        #; Update the package name for the process
        Set tProcess.Package=pPackage
        
        #; Generate the Code
        Set tSC=..GenerateCode(tProcess)
        If $$$ISERR(tSC) Quit
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// Given the root of the parse tree, ( an instance of Ens.BPL.Process ), generate
/// the classes corresponding to the process definition
ClassMethod GenerateCode(pProcess As Ens.BPL.Process) As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        #; Create an instance of the compiler, this can fail if the user has
        #; specified a bad indirect expression on the version attribute of the <process> tag
        Kill %objlasterror
        Set tCompiler=##class(Ens.BPL.Compiler).%New(pProcess)
        If '$IsObject(tCompiler) Set tSC=$Get(%objlasterror,$$$ERROR($$$FailedToNewClass,"Ens.BPL.Compiler")) Quit
        
        #; Generate the code
        Set tSC=pProcess.GenerateCode(tCompiler)
        If $$$ISERR(tSC) Quit
        
        #; And compile it
        Set tSC=tCompiler.GenerateClass()
        If $$$ISERR(tSC) Quit
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

ClassMethod GenerateXML(pProcess As Ens.BPL.Process) As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
            
        Set tStream=##class(%GlobalBinaryStream).%New()
        $$$ASSERT($IsObject(tStream))
            
        Do tStream.WriteLine(""),tStream.WriteLine("<?xml version='1.0' ?>")
        Set tSC=pProcess.GenerateXML(tStream)
        If $$$ISERR(tSC) Quit
        
        Do tStream.OutputToDevice()
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

/// Initialize the compiler
Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        $$$ASSERT($Get(initvalue)'="")
        
        #; The constructor takes the process
        Set ..Process=initvalue
        
        #; Create the thread counter
        Set ..ThreadCounter=##class(Ens.BPL.Counter).%New("Thread")
        $$$ASSERT($IsObject(..ThreadCounter))
                
        Set ..MethodCounter=##class(Ens.BPL.Counter).%New("OnResponse")
        $$$ASSERT($IsObject(..MethodCounter))

        Set ..PyMethodCounter=##class(Ens.BPL.Counter).%New("pyExec")
        $$$ASSERT($IsObject(..PyMethodCounter))
                
        #; Create the context stack
        Set ..ContextStack=##class(Ens.BPL.ContextStack).%New()
        $$$ASSERT($IsObject(..ContextStack))
        
        #; Create the thread stack
        Set ..ThreadStack=##class(Ens.BPL.Stack).%New()
        $$$ASSERT($IsObject(..ThreadStack))
        
        #; Create the state stack
        Set ..StateStack=##class(Ens.BPL.Stack).%New()
        $$$ASSERT($IsObject(..StateStack))
        
        #; Create the break stack
        Set ..BreakStack=##class(Ens.BPL.Stack).%New()
        $$$ASSERT($IsObject(..BreakStack))
        
        #; Create the continue stack
        Set ..ContinueStack=##class(Ens.BPL.Stack).%New()
        $$$ASSERT($IsObject(..ContinueStack))
        
        #; Create the method stack
        Set ..MethodStack=##class(Ens.BPL.Stack).%New()
        $$$ASSERT($IsObject(..MethodStack))
        
        #; Create the state counter stack
        Set ..StateCounterStack=##class(Ens.BPL.Stack).%New()
        $$$ASSERT($IsObject(..StateCounterStack))
        
        #; We wish to preserve any pre-existing context storage
        If ..Process.Version'="" {
            
            Set tSC=..Process.GetVersion(.tVersion)
            If $$$ISERR(tSC) Quit
            
            Set tContextClassName=..Process.Package_".V"_tVersion_".Context"
        
        } else {
            Set tContextClassName=..Process.Package_".Context"
        }
        
        If ##class(%Dictionary.ClassDefinition).%ExistsId(tContextClassName) {
            
            &sql(delete from %Dictionary.PropertyDefinition  where parent = :tContextClassName)
            $$$ASSERT((SQLCODE=0)||(SQLCODE=100))
            
            &sql(delete from %Dictionary.ParameterDefinition where parent = :tContextClassName)
            $$$ASSERT((SQLCODE=0)||(SQLCODE=100))
            
            &sql(delete from %Dictionary.MethodDefinition    where parent = :tContextClassName)
            $$$ASSERT((SQLCODE=0)||(SQLCODE=100))
            
            Set ..Context=##class(%Dictionary.ClassDefinition).%OpenId(tContextClassName)
            $$$ASSERT($IsObject(..Context))
            
        } else {
            
            #; Create the class definition for the process
            Set ..Context=##class(%Dictionary.ClassDefinition).%New()
            $$$ASSERT($IsObject(..Context))
            
            #; Fill in the superclass,classtype,name etc
            Set ..Context.Super="Ens.BP.Context",..Context.ClassType="persistent"
            Set ..Context.Name=tContextClassName,..Context.ProcedureBlock=1
            Set ..Context.CompileAfter=..Process.Package
        }
        // Mark context class as generated (done here so pre-existing context class gets marked too)
        Set ..Context.GeneratedBy="Ens.BPL.Compiler.CLS"
        Set ..Context.Description="This class is generated by the "_..Process.Package_" BPL class."_$c(13,10)_"This class should not be edited or modified in any way."_$C(13,10)_"Do not make direct use of this class in your application."
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method GenerateClass() As %Status
{
	Set tSC = $$$OK
	Try {
		#; New this variable as it gets set but ignored by the compiler
		New %objlasterror

		#; Create the %OnNew() method if required
		If ..PropertiesToNew.Count() {

			#; Create a method definition
			Set tMethod=##class(%Dictionary.MethodDefinition).%New()
			$$$ASSERT($IsObject(tMethod))

			Set tMethod.ReturnType="%Status"
			Set tMethod.Name="%OnNew"
			Set tMethod.FormalSpec="initvalue"

			#; Always use Language = cache as we need to call ##super()
			Set tMethod.Language=$$$cCLASSLANGUAGEOBJECTSCRIPT

			Set tCode=tMethod.Implementation
			If tMethod.Language=$$$basic {
				Do tCode.WriteLine($C(9)_"// %OnNew() is generated in Objectscript as Basic has limitations when calling ##super(initvalue)")
			}

			Set tProperty=..PropertiesToNew.Next("")
			While tProperty'="" {
				Do tCode.WriteLine($C(9)_"If '$IsObject(.."_..PropertiesToNew.GetAt(tProperty)_"NewObject()) Quit %objlasterror")
				Set tProperty=..PropertiesToNew.Next(tProperty)
			}

			Do tCode.WriteLine($C(9)_"Quit ##super(initvalue)")

			Do ..Context.Methods.Insert(tMethod)
		}

		Set tSC=..Context.%Save()
		If $$$ISERR(tSC) Quit

		Do QueueClass^%occCompile(..Context.Name)
		Do SetQueueFlag^%occCompile("-r")
    }
    Catch ex {
	    Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
    }
    Quit tSC
}

/// Generate definition
Method StartMethod(pName As %String, pThread As Ens.BPL.CompilerThread, pThreadMethod = 1, pContext = 0) As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
    
        if (pThreadMethod ) {
            Set tClass=pThread.ClassDefinition
        } else {
            Set tClass=pContext
        }
        
        #; Create a method definition
        Set tMethod=##class(%Dictionary.MethodDefinition).%New()
        $$$ASSERT($IsObject(tMethod))
        
        Set tMethod.ReturnType="%Status",tMethod.Name=pName

        Set tMethod.FormalSpec="process:Ens.BusinessProcess,context:Ens.BP.Context,synctimedout:%Boolean,syncresponses:%ArrayOfObjects(ELEMENTTYPE=""%Library.Persistent""),request:%Library.Persistent,response:%Library.Persistent"
        
        Set tMethod.PublicList="process,context"
        
        Set tMethod.Language=$$$sysLangFromBPL(..Process.Language)
        
        Set tCode=tMethod.Implementation
        if $$$objectscriptOrPython(..Process.Language) {
            Do tCode.WriteLine(" Set $ZT=""Trap"",status=$$$OK do {")
        } else {
            Do tCode.WriteLine("On Error Goto Trap")
            Do tCode.WriteLine("status=System.Status.OK()")
            Do tCode.WriteLine("Do")
        }
        
        Do ..MethodStack.Push(tMethod),tClass.Methods.Insert(tMethod)
         
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method EndResponseMethod() As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        Set tMethod=..MethodStack.Top(),tCode=tMethod.Implementation
        
        Set tClassName=..CurrentThread.ClassDefinition.Name,tMethodName=tMethod.Name
        
        If $$$objectscriptOrPython(..Process.Language) {
            
            Do tCode.WriteLine(" } while (0)")
            Do tCode.WriteLine("Exit Quit status")
            Do tCode.WriteLine("Trap Set $ZT="""",status=##class(Ens.Util.Error).EnsSystemError("""_tClassName_""","""_tMethodName_""")")
            Do tCode.WriteLine(" Goto Exit")
            
        } else {
            
            Do tCode.WriteLine("Loop While 0")
            Do tCode.WriteLine("Exit: Return status")
            Do tCode.WriteLine("Trap: On Error Goto 0 : status=""Ens.Util.Error"".EnsSystemError("""_tClassName_""","""_tMethodName_""")")
            Do tCode.WriteLine("Goto Exit")
        } 
        
        Do ..MethodStack.Pop()
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method EndMethod() As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        Set tMethod=..MethodStack.Top(),tCode=tMethod.Implementation
        
        Set tClassName=..CurrentThread.ClassDefinition.Name,tMethodName=tMethod.Name
        
        If $$$objectscriptOrPython(..Process.Language) {
            
            Do tCode.WriteLine(" } while (0)")
            Do tCode.WriteLine("Exit Quit ..ManageState(status)")
            Do tCode.WriteLine("Trap Set $ZT="""",status=..ManageStatus(status,"""_tMethodName_""") Goto Exit")
        } else {
            
            Do tCode.WriteLine("Loop While 0")
            Do tCode.WriteLine("Exit: Return Me.ManageState(status)")
            Do tCode.WriteLine("Trap: On Error Goto 0 : status=Me.ManageStatus(status,"""_tMethodName_""") : Goto Exit")
        } 
        
        Do ..MethodStack.Pop()
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method StartThread(pThreadName As %String) As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        
        Set tThreadCounter=..ThreadCounter.Next()
        
        #; Create a new state counter for this thread
        Set tStateCounter=##class(Ens.BPL.Counter).%New("S")
        $$$ASSERT($IsObject(tStateCounter))
        
        #; Push the counter on the counter stack
        Do ..StateCounterStack.Push(tStateCounter)
        
        #; Create the class definition for the thread
        Set tThread=##class(Ens.BPL.CompilerThread).%New()
        $$$ASSERT($IsObject(tThread))
    
        #; Calculate a name for this thread
        If ..Process.Version'="" {
            
            Set tSC=..Process.GetVersion(.tVersion)
            If $$$ISERR(tSC) Quit
            
            Set pThreadName=..Process.Package_".V"_tVersion_"."_tThreadCounter
            
        } else {
            Set pThreadName=..Process.Package_"."_tThreadCounter
        }
            
        Set tThread.ClassDefinition.Super="Ens.BP.Thread"
        Set tThread.ClassDefinition.ClassType="persistent"
        Set tThread.ClassDefinition.ProcedureBlock=1
        Set tThread.ClassDefinition.Name=pThreadName
        Set tThread.ClassDefinition.CompileAfter=..Process.Package
        Set tThread.ClassDefinition.IncludeCode=..Process.Includes

        // Mark thread class as generated
        Set tThread.ClassDefinition.GeneratedBy="Ens.BPL.Compiler.CLS"
        Set tThread.ClassDefinition.Description="This class is generated by the "_..Process.Package_" BPL class."_$c(13,10)_"This class should not be edited or modified in any way."_$C(13,10)_"Do not make direct use of this class in your application."

        #; Establish a label scope for this thread
        Do tThread.PushLabelScope()
        
        #; Push the thread on the thread stack
        Do ..ThreadStack.Push(tThread)
        
        #; Create the first state method for this thread
        Set tSC=..StartMethod(tStateCounter.Next(),tThread)
        If $$$ISERR(tSC) Quit
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method EndThread() As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
            
        If $$$objectscriptOrPython(..Process.Language) {
            Do ..CurrentMethod.Implementation.WriteLine(" Set ..%NextState=""Stop""")
        } else {
            Do ..CurrentMethod.Implementation.WriteLine("   Me.%NextState=""Stop""")
        }
        
        Set tSC=..EndMethod()
        If $$$ISERR(tSC) Quit
        
        Set tThread=..ThreadStack.Top()
        
        $$$ASSERT($IsObject(tThread))
        
        #; Generate the code for the current label scope
        Set tSC=tThread.GenerateCode($this) If $$$ISERR(tSC) Quit
        
        #; Now pop it
        Do tThread.PopLabelScope()
        
        #; Delete any pre-existing class definition 
        #; ignore error status, as 'ClassDoesNotExist' will be common
        Set tSC=$$Delete^%apiOBJ(tThread.ClassDefinition.Name,"-d",,1)
        
        Set tSC=tThread.ClassDefinition.%Save()
        If $$$ISERR(tSC) Quit
        
        Do QueueClass^%occCompile(tThread.ClassDefinition.Name)
        
        #; Pop the state counter
        Do ..StateCounterStack.Pop()
        
        #; Pop the thread
        Do ..ThreadStack.Pop()
        
    } while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method CreateAlarmCall(Output pCall As Ens.BPL.Call, pCallName As %String, pDuration As %String, pUntil As %String = "") As %Status
{
    Set $ZT="Trap",tSC=$$$OK
    do {
        #; Generate a call for the timeout
        Set tRequest=##class(Ens.BPL.Request).%New()
        $$$ASSERT($IsObject(tRequest))
        
        Set tRequest.Type="Ens.AlarmRequest"
        
        #; Fill in the assignments
        Set tAssign=##class(Ens.BPL.Assign).%New()
        $$$ASSERT($IsObject(tAssign))
        
        #; Our assignment is a 'Set'
        Set tAssign.Action="set"
        
        #; Set the appropriate property in the call request
        If pDuration'="" {
            #; It's a duration
            Set tAssign.Property="callrequest.Duration"
            if (pDuration=+pDuration) {
                #; It's numeric
                Set tAssign.Value=+pDuration
            }else {
                #; It's a string
                Set tAssign.Value=pDuration
            }
        } elseif pUntil'="" {
            #; It's an instant
            Set tAssign.Property="callrequest.Until",tAssign.Value=pUntil
        } else {
            $$$ASSERT("0:Timeout with no duration")
        }
        Do tRequest.Activities.Insert(tAssign)
        
        #; Create a response
        Set tResponse=##class(Ens.BPL.Response).%New()
        $$$ASSERT($IsObject(tResponse))
        
        Set tCall=##class(Ens.BPL.Call).%New()
        $$$ASSERT($IsObject(tCall))
    
        #; Fix up the parents   
        Set tCall.Request=tRequest,tRequest.Parent=tCall
        Set tCall.Response=tResponse,tResponse.Parent=tCall
    
        #; Set the name ( completion key ) and target class
        Set tCall.Name=pCallName,tCall.Target="Ens.Alarm",tCall.Async=1
        
        #; Assign the output
        Set pCall=tCall
        
    }while (0)
Exit
    Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
    Goto Exit
}

Method GetStateForLabel(pLabel As %String) As %String
{
    Quit ..CurrentThread().GetStateForLabel(pLabel)
}

ClassMethod EvaluateIndirection(pString As %String, ByRef pVersion As %Integer) As %Status [ PublicList = %expr ]
{
    Set $ZT="Trap",tSC=$$$OK
    Set pVersion="" New %expr Xecute "Set %expr=+"_pString Set pVersion=%expr
Exit Quit tSC
Trap
    Set $ZT="",tSC=$$$ERROR($$$EnsErrBPLBadExpressionValue)
    Goto Exit
}

/// Generates a wrapped Python Method for Expressions Or Code blocks
/// Returns the method signature required to invoke by current thread
/// Argument may be a String expression OR a %Stream (lines of code)
/// Getting "ObjectScript error: <THROW>CompileRtns+98^%occRoutine *%Exception.PythonException  230 CompileRtns+98^%occRoutine^3"
/// indicates an issue in injected Python Source code. Check blocks of python import syntax
/// Parameters<ul>
/// <li>pContent - This can be a stream when invoked for code blocks
///            Otherwise this is a String (expression)</li>
/// <li>pErrorPrefix - Tags some context in generated menthod signature to record what shape time is originated from.
///            Also included as prefix in status for runtime errors when running python code</li>
/// <li>invokeLang - System Language ObjectScript or Basic</li>
/// <li>returnsValue - Controls how method generater shapes invocation signature used by calling context</li>
/// </ul>
Method GeneratePyExec(pContent As %GlobalBinaryStream, pErrorPrefix = "", invokeLang = {$$$objectscript}, returnsValue As %Boolean = 1) As %String [ Internal, ProcedureBlock = 1 ]
{
    // Decided to not use %import XDATA for Python import statements
    // Rationale: Code that compiles and runs in a development environment, when deployed to TEST / PROD could
    // throws the "<OBJECT DISPATCH> *python object not found" error, when a required import library is not available
    // or has an issue loading.
    // The current generator implementation will catch the import error detail, and save this in the usual Integration EventLog via status parameter.
    // To support XData import in future, each generated Thread and the generated context class will need the import XData block to be defined.
    // If the context extends an existing class, generated code would need check for existing XData block
    // and then either define additional python imports along existing implementation pattern OR copy and extend the existing superclass XData block 

    // Import Statements from 
    set pyMethod=##class(%Dictionary.MethodDefinition).%New()
	set pyMethod.Name=..PyMethodCounter.Next() //"pyExec"_methodSuffix
    // Grabbing the numeric suffix
    // The current method will invoke local class method on thread or context
    // So the pyMethod is generated on the appropriate invoking class (thread or context)
    do pyMethod.parentSetObjectId(..CurrentMethod.parent.Name)
	set pyMethod.Language=$$$python
	set pyMethod.ClassMethod=1 // Insulate Thread Class from Python activity
	set pyMethod.Description="Generated. DO NOT EDIT. "_pErrorPrefix_" for "_..CurrentMethod.parent.Name
    // To avoid runtime error in invoking generated python method code, manually assign a sequence number
    // "<THROW> *%Exception.PythonException <THROW> 230 ^^0^ <class 'TypeError'>: descriptor 'pyExec1' for '[package].Thread1' objects doesn't apply to a 'NoneType' object"
    // To confirm if can dispose of this or is needed for runtime invocation
    set pyMethod.SequenceNumber=..PyMethodCounter.Index
	// no handling of return values
    set pyMethod.ReturnType="%Library.String"
	set pyMethod.FormalSpec="process:Ens.BusinessProcess,context:Ens.BP.Context,request:%Library.Persistent,response:%Library.Persistent,status:Ens.Util.PyByRef"
	// open error handler
    set pCount=0
	do pyMethod.Implementation.WriteLine("import iris")
	do pyMethod.Implementation.WriteLine("import traceback")
    do pyMethod.Implementation.WriteLine("status.value=iris.cls('%SYSTEM.Status').OK()")
    do pyMethod.Implementation.WriteLine("pErrorMessage=""""")

    // Start Region - General Py imports
    kill importsArray
    set importsArray=0
    set genPyImports=$TR(..Process.PyFromImport,$C(13))
    set len=$L(genPyImports,$C(10))
    for i=1:1:len {
        set genPyImport=$ZSTRIP($P(genPyImports,$C(10),i),"<>W")
        continue:""=genPyImport
        continue:"import iris"=genPyImport  // Already included
        continue:"import traceback"=genPyImport  // Already included
        set importsArray($I(importsArray))=genPyImport
    }
    // ONLY include an imports section if additional imports have been specified
    if importsArray {
        do pyMethod.Implementation.WriteLine("try:")
        for i=1:1:importsArray {
            do pyMethod.Implementation.WriteLine(" "_importsArray(i))
        }
        do pyMethod.Implementation.WriteLine("except:")
	    do pyMethod.Implementation.WriteLine(" pErrorMessage='"_pErrorPrefix_"'+(traceback.format_exc()[:28000])")
        // The BPL can fail when deployed to environment that is missing required Py module dependencies
        do pyMethod.Implementation.WriteLine(" status.value=iris.cls('%SYSTEM.Status').Error("_$$$PythonImportFailed_",pErrorMessage)")
        // Return empty string from Python to ObjectScript
        do pyMethod.Implementation.WriteLine(" return ''")
    }
    kill importsArray
    // End Region - General Py imports

    // Start Region - Py Expression or Code
    do pyMethod.Implementation.WriteLine("try:")
    // Handle Py Code block
    if $IsObject(pContent) {
        do pContent.Rewind()
        // find least indent
        set indent=999,resetTerminator=1
        
        // Need LineTerminator to match current normalized / non-normalized XML 
        if (pContent.LineTerminator=$C(10)) {
            set line=pContent.ReadLine()
            if $E(line,*)=$C(13) {
                do pContent.Rewind()
                set pContent.LineTerminator=$C(13,10)
            } else {do pContent.Rewind()}
        } else {
            set line=pContent.ReadLine()
            if line[$C(10) {
                do pContent.Rewind()
                set pContent.LineTerminator=$C(10)
            } else {do pContent.Rewind()}
        }

        // Code blocks do not return a value. Only used for example to set a property on context
        set rCount=0
        for {
            quit:pContent.AtEnd
            set line=pContent.ReadLine()
            // Variable rline is used to help consistency of indentation characters
            // for nesting blocks regardless values supplied in designer
            set rline=$ZSTRIP(line,"<W")
            // Decision: Keep Python comments (line prefixed with "#")
            set indent=($L(line)*2)-$L(rline)+1
            // Trade leading whitespace characters for spaces
            do pyMethod.Implementation.WriteLine($J(rline,indent))
            set:"#"'=$E(rline) rCount=rCount+1
        }
        // Python block MUST have at least one functional placeholder statement to compile
        // Cannot just have a code block with all "empty lines" or all "commented out commands"
        // This behavior can be mitigated by design time validation.
        // However, will retain fall back to inject "pass", to ensure classes can compile during development
        do:0=rCount pyMethod.Implementation.WriteLine(" pass")
    } 
    // Handle Py expression. Allow compilation to proceed if placeholder is applied
    else {
        // No useful content put in value of expression
        if ""=$L($ZSTRIP(pContent,"<>W")) {
            do pyMethod.Implementation.WriteLine(" return")
        // "pass" keyword used for value of expression
        } elseif "pass"=$ZSTRIP(pContent,"<>W") {
            do pyMethod.Implementation.WriteLine(" return")
        // comment line used for value of expression
        } elseif "#"=$E($ZSTRIP(pContent,"<W")) {
            do pyMethod.Implementation.WriteLine(" return")
        // running useful code
        } else {
            do pyMethod.Implementation.WriteLine(" return "_$ZSTRIP(pContent,"<W"))
        }
    }
    do pyMethod.Implementation.WriteLine("except:")
	do pyMethod.Implementation.WriteLine(" pErrorMessage='"_pErrorPrefix_"'+(traceback.format_exc())")
    do pyMethod.Implementation.WriteLine(" status.value=iris.cls('%SYSTEM.Status').Error("_$$$PythonGeneralError_",pErrorMessage)")
    // Return empty string from Python to ObjectScript
    do pyMethod.Implementation.WriteLine(" return ''")
    // End Region - Py Expression or Code
    do pyMethod.%Save()
    // CurrentMethod Parent may be a thread or context class
    do ..CurrentMethod.parent.Methods.Insert(pyMethod)
    // The Py invocation signature for BPL shape is maintined here in same method as the generated formal spec
    Set tMethod=..MethodStack.Top(),tCode=tMethod.Implementation

    If invokeLang=$$$objectscript {
        Do tCode.WriteLine("   Set status"_..#ObjectScriptVariableNameForPythonReturn_"=##class(Ens.Util.PyByRef).%New()")
	    Do tCode.WriteLine("   "_$S(returnsValue:"Set "_..#ObjectScriptVariableNameForPythonReturn_"=",1:"Do ")_".."_pyMethod.Name_"(.process, .context, .request, .response, .status"_..#ObjectScriptVariableNameForPythonReturn_")")
        Do tCode.WriteLine("   Set status=status"_..#ObjectScriptVariableNameForPythonReturn_".value")
		Do tCode.WriteLine("   If $$$ISERR(status) Quit")  // Allow to unwind on status error
    } else {
        // No basic support
        //Do tCode.WriteLine("   Set status"_..#ObjectScriptVariableNameForPythonReturn_"=##class(Ens.Util.PyByRef).%New()")
		//Do tCode.WriteLine(" "_$S(returnsValue:" "_..#ObjectScriptVariableNameForPythonReturn_"=",1:"Me.")_pyMethod.Name_"(process, context, request, response, status)")
		//Do tCode.WriteLine(" If ""System.Status"".ISERR(status.value) Then Goto Exit")  // Allow to unwind on status error
	}
	quit ..#ObjectScriptVariableNameForPythonReturn
}

}
