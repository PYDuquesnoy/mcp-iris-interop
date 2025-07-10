/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

IncludeGenerator Ensemble

/// All business rule and routing rule classes are defined from this rule. A rule (definition) class may contain multiple rule sets, each of which has its own effective dates/times and may contain multiple rules and actions.
Class Ens.Rule.Definition [ Abstract, System = 4 ]
{

Projection RuleProjection As Ens.Projection.Rule;

/// Evaluate the ruleDefinition.<br/>
/// This method will correctly resolve <var>pRuleName</var> to a class name if it is a rule alias.<br/>
/// <var>pLogLevel</var> is a set of character flags that control the logging performed during rule execution.
/// To ensure that your value is correct, call <method>NormalizeRuleLogTypes</method>()
/// to produce a normalized set of flags for use by this method.<br />
/// The following flags are available:
/// <ul><li>'e' - log errors only. All errors will be logged irrespective of other flags, so 
/// setting the value to 'e' or leaving the value empty will only log errors.</li>
/// <li>'r' - log return values. This is the default value for the setting, and is 
/// also automatic whenever the 'd' or 'c' flags are specified.</li>
/// <li>'d' - log user-defined debug actions in the rule. The 'r' flag must also
/// be specified for this flag to take effect.</li>
/// <li>'c' - log details of the conditions that are evaluated in the rule. The 'r' flag 
/// must also be specified for this flag to take effect.</li></ul>
ClassMethod EvaluateRules(pRuleName As %String, pSessionId As %String = "", pContext As %RegisteredObject, pActivityName As %String = "", Output pReturnValue As %String, Output pReason As %String, pLogLevel As %String = {$$$eRuleLogTypeReturn}) As %Status [ Final ]
{
	set tSC=$$$OK
	try {
		; lookup rule alias name
		set tClassName=##class(Ens.Projection.Rule).ResolveRuleAlias(pRuleName)
		if tClassName="" set tSC=$$$ERROR($$$EnsErrRuleAliasNotFound,pRuleName) quit
		; check to see if class exists
		if '##class(%Dictionary.CompiledClass).%ExistsId(tClassName) {
			set tSC=$$$ERROR($$$EnsErrRuleClassNotFound,tClassName)
			quit
		}
		set tDebugId = ""
		#; We need a RuleLog entry to tie the DebugLog entries to, so $$$eRuleLogTypeReturn (i.e. "r") is needed for debug mode
		if (pLogLevel [ $$$eRuleLogTypeReturn) && ((pLogLevel [ $$$eRuleLogTypeUserDebug) || (pLogLevel [ $$$eRuleLogTypeConditionDebug)){
			set tDebugId = ##class(Ens.Rule.DebugLog).GetNextDebugId()
		}
		; dispatch to evaluateRuleDefinition
		set tSC=$classmethod(tClassName,"evaluateRuleDefinition",pContext,.tRuleSet,.tEffectiveBegin,.tEffectiveEnd,.pReturnValue,.pReason,pLogLevel,tDebugId)
		; check for error
		if $$$ISERR(tSC) {
			set tIsError=1,tErrorMsg=$system.Status.GetErrorText(tSC)
		} else {
			set tIsError=0,tErrorMsg=""
		}
		if (tIsError) || (pLogLevel [ $$$eRuleLogTypeReturn) {
			; add entry to Ens.Rule.Log
			set tLogSC = ##class(Ens.Rule.Log).Log(pSessionId,pRuleName,tRuleSet,tEffectiveBegin,tEffectiveEnd,pActivityName,pReason,pReturnValue,tErrorMsg,tIsError,tDebugId)
			if $$$ISERR(tLogSC) set tSC = $$$ADDSC(tSC,$$$EnsError($$$EnsErrGeneral,"Error "_$system.Status.GetErrorText(tLogSC)_" while saving RuleLog for rule "_pRuleName_$S(""=tErrorMsg:"",1:" with Error "_tErrorMsg)))
		}
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

/// This method is generated for the subclass
/// It contains the runtime code for all the ruleDefinition
ClassMethod evaluateRuleDefinition(pContext As %RegisteredObject, Output pRuleSet As %String, Output pEffectiveBegin As %String, Output pEffectiveEnd As %String, Output pReturnValue As %String, Output pReason As %String, pLogLevel As %String = {$$$eRuleLogTypeReturn}, pDebugId As %Integer = "") As %Status [ CodeMode = objectgenerator ]
{
	set tSC=$$$OK
	try {
		if %classname="Ens.Rule.Definition" {
			do %code.WriteLine(" Quit $$$ERROR($$$NotImplemented)")
		} else {
			set tSC=##class(Ens.Rule.Generator).generateRuleDefinition(%compiledclass,%code) quit:$$$ISERR(tSC)
		}
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

/// pEffectiveTable is of the format: pEffectiveTable(index)= effectiveBegin_"$"_effectiveEnd_"$"_name
ClassMethod findEffectiveDispatch(pEffectiveTable As %String) As %Status
{
	try {
		set tIndex="" for  {
			set tIndex=$o(pEffectiveTable(tIndex),-1) quit:tIndex=""
			set tReverseTable("-$"_$p(pEffectiveTable(tIndex),"$",1,2))=tIndex
		}
		set tFoundIndex=0
		set tNow=$tr($zdatetime($H,3)," ","T"),tFoundRange=0
		set tRange="" for  {
			set tRange=$o(tReverseTable(tRange),-1) quit:tRange=""
			Set tBeg=$p(tRange,"$",2), tEnd=$p(tRange,"$",3)
			If tBeg'="" {
				If tBeg'["T" Set tBeg=tBeg_"T00:00:00"
				If tBeg]tNow Continue
			}
			If tEnd'="" {
				If tEnd'["T" Set tEnd=tEnd_"T24:00:00"
				If tEnd']tNow Continue
			}
			set tFoundIndex=tReverseTable(tRange)
		}
	} catch {
		set tFoundIndex=0
	}
	quit tFoundIndex
}

/// This method normalizes user-defined rule logging flags in <var>pRuleLogTypes</var> into a
/// valid set of flags as expected by the <method>EvaluateRules</method>() method in this class.<br/>
/// The following flags are available:
/// <ul><li>'e' - log errors only. All errors will be logged irrespective of other flags, so 
/// passing in 'e' or leaving the value empty return 'e'.</li>
/// <li>'r' - log return values. This flag is added automatically whenever 
/// one of the 'd' or 'c' flags is specified.</li>
/// <li>'d' - log user-defined debug actions in the rule. This will normalize to 'rd'.</li>
/// <li>'c' - log details of the conditions that are evaluated in the rule. This will normalize to 'rc'.</li>
/// <li>'a' - log all available information. This will normalize to 'rcd'.</li></ul>
ClassMethod NormalizeRuleLogTypes(pRuleLogTypes As %String = "") As %String
{
	Set tRuleLogTypes = ""
	If (pRuleLogTypes [ "a") {
		Set tRuleLogTypes = $$$eRuleLogTypeReturn _ $$$eRuleLogTypeUserDebug _ $$$eRuleLogTypeConditionDebug
	}
	Else {
		If (pRuleLogTypes [ $$$eRuleLogTypeReturn) {
			Set tRuleLogTypes = tRuleLogTypes _ $$$eRuleLogTypeReturn
		}
		If (pRuleLogTypes [ $$$eRuleLogTypeUserDebug) {
			If (tRuleLogTypes '[ $$$eRuleLogTypeReturn) {
				Set tRuleLogTypes = tRuleLogTypes _ $$$eRuleLogTypeReturn
			}
			Set tRuleLogTypes = tRuleLogTypes _ $$$eRuleLogTypeUserDebug
		}
		If (pRuleLogTypes [ $$$eRuleLogTypeConditionDebug) {
			If (tRuleLogTypes '[ $$$eRuleLogTypeReturn) {
				Set tRuleLogTypes = tRuleLogTypes _ $$$eRuleLogTypeReturn
			}
			Set tRuleLogTypes = tRuleLogTypes _ $$$eRuleLogTypeConditionDebug
		}
	}
	If (tRuleLogTypes = "") {
		Set tRuleLogTypes = "e"
	}
	Quit tRuleLogTypes
}

/// Serializes the provided arguments into a JSON string using any relevant metadata provided in the XData named in pValsSpec; override this method to serialize differently
/// The first argument <var>pValsSpec</var> may be a %DynamicArray or a string. The string may be a JSON array; otherwise it's the name of an XData containing a JSON array
/// in the Rule class, or if prefixed with '#' it's the name of an XData in the Rule's Assist class.
ClassMethod SerializeVals(pValsSpec = "", pArgs...) As %String
{
#dim valSpec As %DynamicArray
	Set tSC = $$$OK
	If $IsObject(pValsSpec) { Set valSpec = pValsSpec }
	Else {
		If ""=pValsSpec { Set valSpec = [] }
		Else {
			Set char1 = $E(pValsSpec)
			If "["=char1 { Set specJSON = pValsSpec }
			Else {
				Set tXDataObj = ##class(%Dictionary.CompiledXData).%OpenId($Case(char1,
																	"#":$parameter($classname(),"RuleAssistClass")_"||"_$E(pValsSpec,2,*),
																	"@":$classname()_"||"_$E(pValsSpec,2,*),
																	:$classname()_"||"_pValsSpec)
														,,.tSC)
				Throw:$$$ISERR(tSC) ##class(%Exception.StatusException).CreateFromStatus(tSC)
				Set specJSON = $S('$IsObject(tXDataObj):pValsSpec, tXDataObj.Data.Size:tXDataObj.Data, 1:"[]")
			}
			Set valsSpec = ##class(%Library.DynamicArray).%FromJSON(specJSON)
		}
	}
	// Construct object to serialize. Undefined arguments that are not specified are not constructed. Specified arguments that are undefined are constructed with a null value.
	Set obj = {}
	Set tIter = valsSpec.%GetIterator()
	Set iArg = 0
	While tIter.%GetNext(.tKey, .argSpec) {
		Set iArg = iArg+1
		Do obj.%Set($S($L(argSpec.name):argSpec.name,1:"prop"_iArg),$G(pArgs(iArg)),$S($D(pArgs(iArg)):argSpec.type,1:"null"))
	}
	For iArg=iArg+1:1:$G(pArgs) {
		Do:$D(pArgs(iArg)) obj.%Set("prop"_iArg,pArgs(iArg))
	}
	Quit obj.%ToJSON()
}

}
