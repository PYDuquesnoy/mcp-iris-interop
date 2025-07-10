/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.Model.ruleDefinition Extends (Ens.Rule.Model.base, Ens.Util.PortalModelBase) [ System = 3 ]
{

Property alias As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property description As %String(MAXLEN = "", XMLPROJECTION = "NONE");

Property context As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property production As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property variables As list Of Ens.Rule.Model.variable(XMLNAME = "variable", XMLPROJECTION = "ELEMENT");

Property ruleSets As list Of Ens.Rule.Model.ruleSet(XMLNAME = "ruleSet", XMLPROJECTION = "ELEMENT");

Property assistClass As %String(MAXLEN = "", XMLPROJECTION = "NONE");

Property ruleType As %String(MAXLEN = "", XMLPROJECTION = "NONE");

Property contextEditable As %Boolean(XMLPROJECTION = "NONE");

Property hasConstraints As %Boolean(XMLPROJECTION = "NONE");

Property isRoutingRule As %Boolean(XMLPROJECTION = "NONE");

Property hasSegments As %Boolean(XMLPROJECTION = "NONE");

Property constraintCache As %ZEN.proxyObject(XMLPROJECTION = "NONE");

Method SaveAs(pClassName As %String) As %Status
{
	set tSC=$$$OK
	try {
		#; make sure we don't have an alias/classname collision
		set tSC = ##class(Ens.Projection.Rule).ValidateAlias(pClassName,..alias)
		if $$$ISERR(tSC) quit

		#; open the class definition, if doesn't exist, create it anew
		if ##class(%Dictionary.ClassDefinition).%ExistsId(pClassName) {
			set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName,,.tSC)
			if $$$ISERR(tSC) quit
		}
		else {
			set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New(pClassName)
			if '$IsObject(tClassDefinition) set tSC=%objlasterror quit
			set tClassDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
		}
		
		set tClassDefinition.Super = "Ens.Rule.Definition"
		set tClassDefinition.Description = $replace(..description,$c(10),$c(13,10))
		
		#; delete the old parameter named RuleAssistClass
		set tIndex = tClassDefinition.Parameters.FindObjectId(pClassName_"||RuleAssistClass")
		if tIndex'="" do tClassDefinition.Parameters.RemoveAt(tIndex)
		if ( ..assistClass '= "" ) {
			#; define a new parameter named RuleAssistClass
			set tParameterDefinition = ##class(%Dictionary.ParameterDefinition).%New()
			set tParameterDefinition.Name="RuleAssistClass"
			set tParameterDefinition.parent=tClassDefinition
			set tParameterDefinition.Default=..assistClass

			#; reload metadata for new assist class
			try {
				set ..ruleType = $classmethod(..assistClass,"GetDescription")
				set ..contextEditable = ($classmethod(..assistClass,"GetContextClass")="")
				set ..hasConstraints = ($classmethod(..assistClass,"GetMetaData")'="")
				set ..isRoutingRule = $classmethod(..assistClass,"GetIsRoutingRule")
				set ..hasSegments = $classmethod(..assistClass,"GetIsSegmentedDoc")
			}
			catch {
				set ..ruleType = "(unknown)"
				set ..contextEditable = 1
				set ..hasConstraints = 0
				set ..isRoutingRule = 0
				set ..hasSegments = 0
			}
		} else {
			set ..ruleType = "(unknown)"
			set ..contextEditable = 1
			set ..hasConstraints = 0
			set ..isRoutingRule = 0
			set ..hasSegments = 0
		}
		if '..isRoutingRule Set ..production = ""

		#; delete the old XDATA block named RuleDefinition
		set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||RuleDefinition")
		if tIndex'="" do tClassDefinition.XDatas.RemoveAt(tIndex)
		#; define a new XDATA block named RuleDefinition
		set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()
		set tXDataDefinition.Name="RuleDefinition"
		set tXDataDefinition.parent=tClassDefinition
		set tXDataDefinition.XMLNamespace = "http://www.intersystems.com/rule"
		#; export to stream
		set tSC=..XMLExportToStream(tXDataDefinition.Data,,",indent()") quit:$$$ISERR(tSC)
	
		#; save the class definition
		set tSC=tClassDefinition.%Save() quit:$$$ISERR(tSC)

		set ..Timestamp = $zdatetime(tClassDefinition.TimeChanged,3,,6)
	} catch {
		set tSC = $$$SystemError
	}
	quit tSC
}

ClassMethod LoadFromClass(pClassname As %String = "", Output pRuleDefinition As Ens.Rule.Model.ruleDefinition, pLoadConstraintCache As %Boolean = 1, pConcurrency As %Integer = -1) As %Status
{
	set pRuleDefinition = ""
	set tSC = $$$OK
	try {
		if '##class(%Dictionary.ClassDefinition).%ExistsId(pClassname) {
			set tSC = $$$ERROR($$$ClassDoesNotExist,pClassname)
			quit
		}
		if '##class(%Dictionary.XDataDefinition).IDKEYExists(pClassname,"RuleDefinition") {
			set tSC = $$$ERROR($$$EnsErrXDataBlockNotDefined,pClassname,"RuleDefinition")
			quit
		}
		
		set tClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(pClassname,pConcurrency,.tSC)
		if $$$ISERR(tSC) quit
		
		set tSC = ##class(Ens.Rule.Generator).correlateByName(pClassname,.tRuleDef,pConcurrency)
		if $$$ISERR(tSC) quit
		
		set tRuleDef.description = $replace(tClassDef.Description,$c(13,10),$c(10))
		set tRuleDef.assistClass = $$$defMemberKeyGet(pClassname,$$$cCLASSparameter,"RuleAssistClass",$$$cPARAMdefault)

		set tAssistValsDone = 0
		if tRuleDef.assistClass '= "" {
			try {
				set tRuleDef.ruleType = $classmethod(tRuleDef.assistClass,"GetDescription")
				set tRuleDef.contextEditable = ($classmethod(tRuleDef.assistClass,"GetContextClass")="")
				set tRuleDef.hasConstraints = ($classmethod(tRuleDef.assistClass,"GetMetaData")'="")
				set tRuleDef.isRoutingRule = $classmethod(tRuleDef.assistClass,"GetIsRoutingRule")
				set tRuleDef.hasSegments = $classmethod(tRuleDef.assistClass,"GetIsSegmentedDoc")
				set tAssistValsDone = 1
				if (pLoadConstraintCache && tRuleDef.hasConstraints) {
					do ..buildConstraintDisplayCache(tRuleDef)
				}
			}
			catch {}
		}
		if 'tAssistValsDone {
			set tRuleDef.ruleType = "(unknown)"
			set tRuleDef.contextEditable = 1
			set tRuleDef.hasConstraints = 0
			set tRuleDef.isRoutingRule = 0
			set tRuleDef.hasSegments = 0
		}
	}
	catch {
		set tSC = $$$SystemError
	}
	if $$$ISOK(tSC) set pRuleDefinition = tRuleDef
	quit tSC
}

ClassMethod buildConstraintDisplayCache(pRuleDefinition As Ens.Rule.Model.ruleDefinition) As %Status [ Private ]
{
	New %EnsConstraintCache
	If $IsObject(pRuleDefinition) && (pRuleDefinition.assistClass '= "") && ##class(%Dictionary.CompiledClass).%ExistsId(pRuleDefinition.assistClass) {
		For i=1:1:pRuleDefinition.ruleSets.Count() {
			Set ruleSet = pRuleDefinition.ruleSets.GetAt(i)
			For j=1:1:ruleSet.actions.Count() {
				Set action = ruleSet.actions.GetAt(j)
				If (action.type = "rule") {
					Do ..addConstraintsForRule(action,pRuleDefinition.assistClass)
				}
			}
		}
		Set pRuleDefinition.constraintCache = ##class(%ZEN.proxyObject).%New()
		Set pRuleDefinition.constraintCache.empty = $classmethod(pRuleDefinition.assistClass,"GetShortDisplay")
		Set tServerData = ##class(%Library.ListOfObjects).%New()
		Set pRuleDefinition.constraintCache.serverData = tServerData
		Set tKey = ""
		For {
			Set tKey = $order(%EnsConstraintCache(tKey),1,tPairData)
			Quit:(tKey = "")
			Set tPair = ##class(%ZEN.proxyObject).%New()
			Set tPair.key = $listget(tPairData,1)
			Set tPair.value = $listget(tPairData,2)
			Do tServerData.Insert(tPair)
		}
	}
	Kill %EnsConstraintCache
	Quit $$$OK
}

ClassMethod addConstraintsForRule(pRule As Ens.Rule.Model.rule, pAssistClass As %String) As %Status [ Private ]
{
	Kill tConstraints
	Set tConstraintPath = ""
	For i=1:1:pRule.constraints.Count() {
		Set constraint = pRule.constraints.GetAt(i)
		If (constraint.name '= "") Set tConstraints(constraint.name) = constraint.value
		Set tConstraintPath = tConstraintPath _ $char(0) _ constraint.name _ $char(1) _ constraint.value
	}
	Set tConstraintPath = $extract(tConstraintPath,2,*)
	
	If (tConstraintPath '= "") {
		If ($length(tConstraintPath) <= 225) {
			Set tConstraintKey = tConstraintPath
		}
		Else {
			Set tConstraintKey = $extract(tConstraintPath,1,225)_$system.Encryption.SHA1Hash($extract(tConstraintPath,226,*))
		}
		If '$data(%EnsConstraintCache(tConstraintKey)) {
			Set %EnsConstraintCache(tConstraintKey) = $listbuild(tConstraintPath,$classmethod(pAssistClass,"GetShortDisplay",.tConstraints))
		}
	}

	For i=1:1:pRule.whens.Count() {
		Set when = pRule.whens.GetAt(i)
		For j=1:1:when.actions.Count() {
			Set action = when.actions.GetAt(i)
			If (action.type = "rule") {
				Do ..addConstraintsForRule(action,pAssistClass)
			}
		}
	}
	Quit $$$OK
}

}
