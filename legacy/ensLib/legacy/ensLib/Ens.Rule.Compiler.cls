/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Legacy: Provided the ability to compile persistent rule definitions into routines.
Class Ens.Rule.Compiler Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This holds the generated code
Property Code As %GlobalCharacterStream [ Transient ];

/// Delete all routines from Rule Cache
ClassMethod PurgeRuleCache() As %Status
{
	// loop over all possible routines, delete them
	Set tCount = +$G(^Ens.RuleCacheCounter)
	For id = 1:1:tCount {
		Set tSC = ##class(%Routine).Delete(..MakeRoutineName(id)_".MAC",0)
	}

	$$$KillRootNode(^Ens.RuleCacheCounter)

	// make sure rules do not refer to old values
	&SQL(UPDATE RuleDefinition
     	SET RoutineName = NULL
     	WHERE RoutineName IS NOT NULL)

	Quit $$$OK
}

/// Returns a routine name in which compiled rule can be placed.
ClassMethod AllocateRoutineName() As %String
{
	// find next available routine #
	Set id = ""
	
	// first check free list
	If ($D(^Ens.RuleCacheCounter) >= 10) {
		// lock free list
		Lock +(^Ens.RuleCacheCounter):5 If '$Test Quit
		
		Set id = $O(^Ens.RuleCacheCounter(""))
		If (id '= "") {
			// remove from free list
			Kill ^Ens.RuleCacheCounter(id)
		}

		// unlock free list
		Lock -(^Ens.RuleCacheCounter)
	}
	
	// otherwise allocate a new number
	If (id = "") {
		Set id = $I(^Ens.RuleCacheCounter)
	}
	
	Quit ..MakeRoutineName(id)
}

/// Return a rule cache routine name
/// Try to use values that collate
ClassMethod MakeRoutineName(id As %Integer) As %String [ CodeMode = expression ]
{
"RuleCache.R" _ $S(id>=10000:id,1:$TR($J(id,4)," ","0"))
}

/// Delete the given routine from the rule cache
ClassMethod DeleteRoutine(pName As %String) As %Status
{
	Set tSC = $$$OK
	
	If (("$"_pName) [ "$RuleCache.R") {
		// find id # for this routine
		Set id = $P(pName,".",2)
		Set id = +$E(id,2,999)
		
		// add number to free list
		If ((id > 0) && (id <= +$G(^Ens.RuleCacheCounter))) {
			Set ^Ens.RuleCacheCounter(id) = ""
		}

		Set tName = pName _ ".MAC"
		Set tSC = ##class(%Routine).Delete(tName,0)
	}

	Quit tSC
}

/// Generate executable code for the given rule definition
/// and store it into routine <var>pRoutineName</var>.
ClassMethod CompileRule(pRuleDef As RuleDefinition, pRoutineName As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		// Create an instance of the compiler
		Set tCompiler = ##class(Ens.Rule.Compiler).%New()
		$$$ASSERT($IsObject(tCompiler))

		// Initialize it
		Set tCompiler.Code = ##class(%GlobalCharacterStream).%New()

		// Generate code for routine 
		Set tSC = pRuleDef.GenerateCode(tCompiler)
		If $$$ISERR(tSC) Quit
		
		// Create routine
		Set tRoutine = ##class(%Routine).%New(pRoutineName _ ".MAC")
		$$$ASSERT($IsObject(tRoutine))
		
		// Generate scaffolding for code
		Do tRoutine.WriteLine(" #; " _ pRoutineName _ ".MAC")
		Do tRoutine.WriteLine(" #; Auto-compiled version of Business Rule")
		Do tRoutine.WriteLine(" #; Rule class:      " _ $classname(pRuleDef))
		Do tRoutine.WriteLine(" #; Host class:      " _ pRuleDef.HostClass)
		Do tRoutine.WriteLine(" #; Rule name:       " _ pRuleDef.Name)
		Do tRoutine.WriteLine(" #; Rule version:    " _ pRuleDef.Version)
		Do tRoutine.WriteLine(" #; Rule Modified:   " _ pRuleDef.TimeModified)
		Do tRoutine.WriteLine(" #; Routine created: " _ $$$timeUTC)
		Do tRoutine.WriteLine(" #; ---------------- DO NOT EDIT ----------------")
		Do tRoutine.WriteLine("")
		Do tRoutine.WriteLine("#include Ensemble")
		Do tRoutine.WriteLine("")
		Do tRoutine.WriteLine("Evaluate(pRuleDef, pContext) PUBLIC {")
		Do tRoutine.WriteLine(" Set pRuleDef.%ReturnValue="""", $ZT=""Trap""")
		Do tRoutine.WriteLine(" $$$catTRACE(""rule"",""Executing RuleSet '"_pRuleDef.Name_"' routine "_pRoutineName_""")")

		// Inject generated code
		Do tRoutine.CopyFrom(tCompiler.Code)

		// Final scaffolding
		Do tRoutine.WriteLine("Trap")
		Do tRoutine.WriteLine(" Set $ZT="""", pRuleDef.%ErrorMsg=$ZE")
		Do tRoutine.WriteLine(" Quit $$$ERROR($$$ObjectScriptError,$ZE)")
		Do tRoutine.WriteLine("}")

		// Save and compile
		Set tSC = tRoutine.Save()
		If $$$ISERR(tSC) Quit

		Set tSC = tRoutine.Compile("-d")
		If $$$ISERR(tSC) Quit
	
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
