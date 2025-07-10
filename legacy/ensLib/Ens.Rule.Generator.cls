/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occUtility)

Class Ens.Rule.Generator [ Abstract, System = 3 ]
{

ClassMethod generateRuleDefinition(%compiledclass As %Dictionary.CompiledClass, %code As %Stream.MethodGenerator = "") As %Status
{
	set tSC=$$$OK
	try {
		set tSC=..correlateByObj(%compiledclass,.tRuleDefinition) if $$$ISERR(tSC) quit
		set tAssistClass=""
		for i=1:1:%compiledclass.Parameters.Count() if %compiledclass.Parameters.GetAt(i).Name="RuleAssistClass" set tAssistClass=%compiledclass.Parameters.GetAt(i).Default quit
		;
		new %usesRuleActionUserData
		set %usesRuleActionUserData = ..usesProperty("RuleActionUserData",%compiledclass.Name, tAssistClass)
		;
		set ^IRIS.TempEnsRule("class",%compiledclass.Name)=tRuleDefinition.alias
		Try {
			kill ^Ens.Rule.Targets(%compiledclass.Name)
		} Catch { /* Might be on a RO Mirror member */}
		;
		do ..line("set tSC=$$$OK,$ZE=""""",1)
		do ..line("try {",1)
		do ..line("set pReturnValue="""",pReason=""""",2)
		;
		do ..line("; Initialize temporary variables",2)
		for i=1:1:tRuleDefinition.variables.Count() {
			set variable = tRuleDefinition.variables.GetAt(i)
			if variable.name="" continue
			if '$zname(variable.name,0) {
				set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid Temporary Variable Name: "_variable.name)
				quit
			}
			do ..line("set tTempVars("""_variable.name_""")=""""",2)
			set variables(variable.name)=""
		}
		quit:$$$ISERR(tSC)
		;
		set tRuleSetDispatcher=(tRuleDefinition.ruleSets.Count()'=1)||(tRuleDefinition.ruleSets.GetAt(1).effectiveBegin'="")||(tRuleDefinition.ruleSets.GetAt(1).effectiveEnd'="")
		;
		if tRuleSetDispatcher {
			do ..line("; Set up tEffectiveTable, in the order of appearance.",2)
			set tDispatch=""
			for tRuleSetIndex=1:1:tRuleDefinition.ruleSets.Count() {
				set tRuleSet = tRuleDefinition.ruleSets.GetAt(tRuleSetIndex)
				set tName = tRuleDefinition.ruleSets.GetAt(tRuleSetIndex).name
				if tName="" set tName="(#"_tRuleSetIndex_")"
				If ((tRuleSet.effectiveBegin'="") && '(tRuleSet.effectiveBegin?4N1"-"2N1"-"2N.1(1"T"2N1":"2N.1(1":"2N)))) {
					set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid Date/Time Format for Effective Begin: "_tRuleSet.effectiveBegin_". Date/Time format should be YYYY-MM-DDTHH:MM:SS")
					quit
				}
				If ((tRuleSet.effectiveEnd'="") && '(tRuleSet.effectiveEnd?4N1"-"2N1"-"2N.1(1"T"2N1":"2N.1(1":"2N)))) {
					set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid Date/Time Format for Effective End: "_tRuleSet.effectiveEnd_". Date/Time format should be YYYY-MM-DDTHH:MM:SS")
					quit
				}
				If (($f(tName,"""_")'=0) && ($f(tName,"_""",$f(tName,"""_"))'=0)) {
					set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid RuleSet Name: "_tName_". RuleSet name should not contain ""_ and _""")
					quit
				}
				do ..line("set tEffectiveTable("_tRuleSetIndex_")="""_tRuleSet.effectiveBegin_"$"_tRuleSet.effectiveEnd_"$"_"ruleSet: "_tName_"""",2)
				set tDispatch=tDispatch_tRuleSetIndex_":ruleSet"_tRuleSetIndex_","
			}
			quit:$$$ISERR(tSC)
			do ..line("; Find the effective ruleSet to which to dispatch",2)
			do ..line("set tRuleSetIndex=..findEffectiveDispatch(.tEffectiveTable)",2)
			do ..line("set pEffectiveBegin=$p($g(tEffectiveTable(tRuleSetIndex)),""$"",1)",2)
			do ..line("set pEffectiveEnd=$p($g(tEffectiveTable(tRuleSetIndex)),""$"",2)",2)
			do ..line("set pRuleSet=$p($g(tEffectiveTable(tRuleSetIndex)),""$"",3,999)",2)
			do ..line("goto $Case(tRuleSetIndex,"_tDispatch_":ruleSetNotFound)",2)
			do ..line(";",2)
		} else {
			do ..line("; No ruleSet dispatching code generated.",2)
			do ..line("set pEffectiveBegin=""""",2)
			do ..line("set pEffectiveEnd=""""",2)
			do ..line("set pRuleSet=""""",2)
			do ..line(";",2)
		}
		;
		for tRuleSetIndex=1:1:tRuleDefinition.ruleSets.Count() {
			set tRuleSet = tRuleDefinition.ruleSets.GetAt(tRuleSetIndex)
			set tSC=..generateOneRuleSet(%compiledclass.Name,.variables,tRuleSet,tRuleSetIndex,tAssistClass,%code) quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		;
		if tRuleSetDispatcher {
			do ..line("ruleSetNotFound ; No effective ruleSet can be found.",0)
			do ..line("set tSC=$$$ERROR($$$EnsErrNoEffectiveRuleSetFound)",2)
			do ..line("quit",2)
			do ..line(";",2)
		}
		do ..line("} catch err {",1)
		do ..line("if $ZE="""" {set tSC=err.AsStatus()} Else {set tSC=$$$SystemError}",2)
		do ..line("}",1)
		do ..line("set pReason=$e(pReason,2,*)",1)
		do ..clearRuleActionReason()
		do ..line("quit tSC",1)
		do ..line(";",1)
		;
	} catch {		
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod generateOneRuleSet(pClassname As %String, variables As %String, pRuleSet As Ens.Rule.Model.ruleSet, pRuleSetIndex As %String, pAssistClass As %String, %code As %Stream.MethodGenerator) As %Status
{
	set tSC=$$$OK
	try {
		set tDescription = "effectiveBegin = "_$s(pRuleSet.effectiveBegin'="":pRuleSet.effectiveBegin,1:"(not-specified)")
		set tDescription = tDescription_"; effectiveEnd = "_$s(pRuleSet.effectiveEnd'="":pRuleSet.effectiveEnd,1:"(not-specified)")
		do ..line("ruleSet"_pRuleSetIndex_" ; "_tDescription,0)
		do ..line("if (pLogLevel [ $$$eRuleLogTypeConditionDebug) set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"""","_$$$quote("Executing ruleSet"_pRuleSetIndex_": "_tDescription)_",0) quit:$$$ISERR(tSC)",2)
		do ..line(";",2)
		;
		set tSC = ..generateActions(pClassname,.variables,pRuleSet.actions,"",pAssistClass,%code,2) quit:$$$ISERR(tSC)
		;
		do ..line("quit",2)
		do ..line(";",2)
		;
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod generateActions(pClassname As %String, variables As %String, pActions As %Collection.ListOfObj, pReason As %String, pAssistClass As %String, %code As %Stream.MethodGenerator, pLevel As %Integer) As %Status
{
	set tSC=$$$OK
	try {
		set tRuleCount=0
		for tIndex=1:1:pActions.Count() {
			set tAction=pActions.GetAt(tIndex)
			if tAction.type="rule" {
				set tRuleCount=tRuleCount+1
				If (($f(tAction.name,"""_")'=0) && ($f(tAction.name,"_""",$f(tAction.name,"""_"))'=0)) {
					set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid rule name: "_tAction.name_". Rule name should not contain ""_ and _""")
					quit
				}
				set tReason = pReason _ $s(pReason'="":"-",1:"") _ "rule#" _ tRuleCount _ $s(tAction.name'="":"("_tAction.name_")",1:"")
			} else {
				set tReason = pReason
			}
			set tSC = ..generateOneAction(pClassname,.variables,tAction,tReason,pAssistClass,%code,pLevel) quit:$$$ISERR(tSC)
		}
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod generateWhens(pClassname As %String, variables As %String, pAction As Ens.Rule.Model.action, pReason As %String, pAssistClass As %String, %code As %Stream.MethodGenerator, pLevel As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		If $case(pAction.type,"rule":1,"foreach":1,:0) {
			for tIndex=1:1:pAction.whens.Count() {
				set tWhen = pAction.whens.GetAt(tIndex)
				set tSC=##class(Ens.Rule.Model.expression).convertToCOS(tWhen.condition,.tExpression,.variables) quit:$$$ISERR(tSC)
				do ..line($s(tIndex=1:"if",1:"} elseif")_" ("_tExpression_") {",pLevel)
				set tReason = pReason_":when#"_tIndex
				do ..line("set pReason=pReason_"","_tReason_"""",pLevel+1)
				do ..setActionReasonLines(tReason, pLevel)
				do ..line("if (pLogLevel [ $$$eRuleLogTypeConditionDebug) set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"_$$$quote(tReason)_","_$$$quote("When ("_tWhen.condition_") succeeded")_",0) quit:$$$ISERR(tSC)",pLevel+1)
				set tSC = ..generateActions(pClassname,.variables,tWhen.actions,tReason,pAssistClass,%code,pLevel+1) quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			if $isObject(pAction.otherwise) {
				do ..line("} else {",pLevel)
				set tReason = pReason_":otherwise"
				do ..line("set pReason=pReason_"","_tReason_"""",pLevel+1)
				do ..setActionReasonLines(tReason, pLevel)
				do ..line("if (pLogLevel [ $$$eRuleLogTypeConditionDebug) set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"_$$$quote(tReason)_",""Otherwise called"",1) quit:$$$ISERR(tSC)",pLevel+1)
				set tSC = ..generateActions(pClassname,.variables,pAction.otherwise.actions,tReason,pAssistClass,%code,pLevel+1) quit:$$$ISERR(tSC)
			}
			elseif (pAction.whens.Count() > 0) {
				do ..line("} elseif (pLogLevel [ $$$eRuleLogTypeConditionDebug) {",pLevel)
				if (pAction.type="rule") {
					do ..line("set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"_$$$quote(pReason)_","_$$$quote("For rule '"_$select(pAction.name = "": pReason, 1: pAction.name)_"', no whens matched and no otherwise defined")_",0) quit:$$$ISERR(tSC)",pLevel+1)
				} else {
					#; foreach
					do ..line("set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"_$$$quote(pReason)_","_$$$quote("For foreach loop over'"_pAction.propertypath_"', no whens matched and no otherwise defined")_",0) quit:$$$ISERR(tSC)",pLevel+1)
				}
			}
			quit:$$$ISERR(tSC)
			if pAction.whens.Count()>0 do ..line("}",pLevel)
		} Else {
			#; Other actions don't have whens and otherwise
		}
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod generateLoop(pClassname As %String, variables As %String, pAction As Ens.Rule.Model.foreach, pReason As %String, pAssistClass As %String, %code As %Stream.MethodGenerator, pLevel As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tExpression, tDocName, tSegmentPath, tPiece, tSegIndex As %String = ""
	#dim tExpressionObj As Ens.Rule.Model.expression
	#dim tLevelCount As %Integer = 0
	
	Try {
		If (""=pAction.propertypath) {
			Set tSC = $$$ERROR($$$EnsErrGeneral,"propertypath required for foreach action")
			Quit
		}
		
		#; Just to make sure there's no code being injected
		Set tSC = ##class(Ens.Rule.Model.expression).parseExpression(pAction.propertypath,.tExpressionObj)	Quit:$$$ISERR(tSC)
		
		If tExpressionObj.type="value" {
			Set tExpression=tExpressionObj.value
			If $e(tExpression)?1(1AZFWCHARZ,1"%") {
				Set tDocName="pContext."_$P(tExpression,".")
				Set tExpression = $P(tExpression,".",2,*)
				If (($E(tExpression)="{") && ($E(tExpression,*)="}")) {
					Set tExpression = $E(tExpression,2,*-1)
					do ..line("set tReturn = 0",pLevel)
					For i=1:1:$l(tExpression,".") {
						Set tPiece = $P(tExpression,".",i)
						If (tPiece'["(") {
							#; Not repeating
							Set tSegmentPath = $Select(tSegmentPath'="":tSegmentPath_".",1:"")_tPiece
						} ElseIf ($Piece(tPiece,"(",2,*)=")") {
							#; Empty parens -> repeating loop or segment
							#; Set index variable to be used at this level in the loop
							Set tSegIndex = "tSegIndex"_$S($I(tLevelCount)>1:tLevelCount,1:"")
							#; Start the for loop					
							do ..line("set "_tSegIndex_" = """"",pLevel)
							do ..line("for {",pLevel)
							do ..line("set "_tSegIndex_" = "_tDocName_".GetNextIndex("""_$Select(tSegmentPath'="":tSegmentPath_".",1:"")_tPiece_""","_tSegIndex_",.tSC)",$I(pLevel))
							do ..line("quit:($$$ISERR(tSC)||(""""="_tSegIndex_"))",pLevel)
							#; Add on to the property path so it includes this level in the loop
							Set tSegmentPath = $Select(tSegmentPath'="":tSegmentPath_".",1:"")_$P(tPiece,"(")_"(""_"_tSegIndex_"_"")"
						} Else {
							#; Deal with any values enclosed in parentheses and make sure we have matching open and close parentheses
							Set parenLevel=0, k=$F(tPiece,"(")-1
							For {
								Quit:$e(tPiece,k)=""
								If $e(tPiece,k)="(" {
									Set parenLevel = parenLevel+1
									Set:parenLevel=1 parenStart = k
								}
								If $e(tPiece,k)=")" {
									Set parenLevel = parenLevel -1
									If parenLevel = 0 {
										Set tIndex = $e(tPiece,parenStart+1, k-1)
										If (($f(tIndex,"""_")'=0) && ($f(tIndex,"_""",$f(tIndex,"""_"))'=0)) {
											Set tSC=$$$ERROR($$$EnsErrGeneral,"Invalid index value "_tIndex_" in "_tExpressionObj.value_". Index value should not contain ""_ and _""")
											Quit
										} ElseIf ((tIndex'="") && (tIndex '="*") && (tIndex '= "-")) {
											Set tSC = ##class(Ens.Rule.Model.expression).convertToCOS(tIndex, .result, .variables)	Quit:$$$ISERR(tSC)
											Set $e(tPiece,parenStart, k) = "(""_"_result_"_"")"
											set k = k+4+$l(result)
										}
									}
								}
								Set k = k+1
							}
							Quit:$$$ISERR(tSC)
							If parenLevel'=0 {
								Set tSC=$$$ERROR($$$EnsErrMissingCloseParen,$l(tExpressionObj.value)-1)
								Quit
							}
							#; Add on to the property path
							Set tSegmentPath = $Select(tSegmentPath'="":tSegmentPath_".",1:"")_tPiece
						}
					}
				} Else {
					#; No { to indicate start of VDoc path
					Set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid value for propertypath")
					Quit
				}
			} Else {
				#; No VDoc variable
				Set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid value for propertypath")
				Quit
			}
		} Else {
			#; Should only be the path - no operators or functions
			Set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid value for propertypath")
			Quit
		}
		
		If (tLevelCount = 0) {
			#; No "()" to iterate over
			Set tSC = $$$ERROR($$$EnsErrGeneral,"Cannot iterate on given propertypath")
			Quit
		}
		
		#; Inner-most loop - access the segment and perform actions on it
		do ..line("set pContext.Segment = "_tDocName_".GetSegmentAt("""_tSegmentPath_""",.tSC1)",pLevel)
		do ..line("if $$$ISERR(tSC1) {",pLevel)
		do ..line("if (($$$StatusText(tSC1)'[""No segment found"")&&($$$StatusText(tSC1)'[""is not an element, instead this node"")) { set tSC=$$$ADDSC(tSC,tSC1)	quit }",pLevel+1)
		do ..line("else { continue }",pLevel+1)
		do ..line("}",pLevel)
		#; reason
		set tReason = pReason_":foreach"
		do ..line("set pReason=pReason_"","_tReason_"""",pLevel)
		do ..setActionReasonLines(tReason, pLevel)
		do ..line("if (pLogLevel [ $$$eRuleLogTypeConditionDebug) set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"_$$$quote(tReason)_",""Segment ("_tSegmentPath_") loop"",0) quit:$$$ISERR(tSC)",pLevel)
		#; Code inside the loop
		Set tSC = ..generateWhens(pClassname,.variables,pAction,tReason,pAssistClass,%code,pLevel)
		#; Close the loop
		For i=1:1:(tLevelCount-1) {
			Set pLevel = pLevel - 1
			do ..line("}",pLevel)
			#; Make sure to quit out of the entire rule if there was a Return action
			do ..line("quit:tReturn",pLevel)
		}
		Set pLevel = pLevel - 1
		do ..line("}",pLevel)
		#; Clear out the Segment object
		do ..line("set pContext.Segment = $$$NULLOREF",pLevel)
		#; Make sure to quit out of the entire rule if there was a Return action
		do ..line("quit:tReturn",pLevel)
	
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod generateOneAction(pClassname As %String, variables As %String, pAction As Ens.Rule.Model.action, pReason As %String, pAssistClass As %String, %code As %Stream.MethodGenerator, pLevel As %Integer) As %Status
{
	set tSC=$$$OK
	try {
		if ( pAction.type = "rule" ) {
			if ( pAction.disabled ) quit
			do ..line("; Evaluating rule: "_pReason,pLevel)
			if ( pAssistClass'="" ) {
				do ..line("kill tConstraints",pLevel)
				for i=1:1:pAction.constraints.Count() {
					If (($f(pAction.constraints.GetAt(i).value,"""_")'=0) && ($f(pAction.constraints.GetAt(i).value,"_""",$f(pAction.constraints.GetAt(i).value,"""_"))'=0)) {
						set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid Constraint: "_pAction.constraints.GetAt(i).name_"="_pAction.constraints.GetAt(i).value_". Constraint values should not contain ""_ and _""")
						quit
					}
					do ..line("set tConstraints("""_pAction.constraints.GetAt(i).name_""")="""_pAction.constraints.GetAt(i).value_"""",pLevel)
				}
				Quit:$$$ISERR(tSC)
				do ..line("set tSC=##class("_pAssistClass_").RuntimeConstraintCheck(.tConstraints,pContext,.pPassed) quit:$$$ISERR(tSC)",pLevel)
				do ..line("if (pLogLevel [ $$$eRuleLogTypeConditionDebug) set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeConditionDebug,"_$$$quote(pReason)_","_$$$quote("Constraints for rule '"_$select(pAction.name = "": pReason, 1: pAction.name)_"' ")_"_$select(pPassed: ""passed"",1: ""failed""),0) quit:$$$ISERR(tSC)",pLevel)
				do ..line("if pPassed {",pLevel)
				set pLevel=pLevel+1
			}
			Set tSC = ..generateWhens(pClassname,.variables,pAction,pReason,pAssistClass,%code,pLevel)
			if ( pAssistClass'="" ) { set pLevel=pLevel-1 do ..line("}",pLevel) }
			Quit:$$$ISERR(tSC)
		} elseif ( pAction.type = "foreach" ) {
			Set tSC = ..generateLoop(pClassname,.variables,pAction,pReason,pAssistClass,%code,pLevel)
		} elseif ( pAction.type = "assign" ) {
			set tSC=##class(Ens.Rule.Model.expression).convertToCOS(pAction.value,.tValueExpression,.variables) quit:$$$ISERR(tSC)
			set tSC = ##class(Ens.Rule.Model.expression).convertToCOS(pAction.property, .tVProp,.variables,1) quit:$$$ISERR(tSC)
			if tVProp["SetValueAt" {
				do ..line("do "_$p(tVProp,",",1)_tValueExpression_","_$p(tVProp,",",2),pLevel)
			}
			else {
				do ..line("set "_tVProp_"="_tValueExpression,pLevel)
			}
		} elseif ( pAction.type = "return" ) {
			set tSC=##class(Ens.Rule.Model.expression).convertToCOS(pAction.value,.tExpression,.variables) quit:$$$ISERR(tSC)
			do ..line("set tReturn = 1",pLevel)
			if tExpression'="" {
				do ..line("set pReturnValue="_tExpression_" quit",pLevel)
			} else {
				do ..line("quit",pLevel)
			}
		} elseif ( pAction.type = "trace" ) {
			set tSC=##class(Ens.Rule.Model.expression).convertToCOS(pAction.value,.tExpression,.variables) quit:$$$ISERR(tSC)
			do ..line("do ##class(Ens.Util.Trace).WriteTrace(""user"",$$$CurrentClass,$$$CurrentMethod,"_tExpression_")",pLevel)
		} elseif ( pAction.type = "send" ) {
			for r=1:1:$l(pAction.target,",") {
				Set oneTarget=$ZStrip($P(pAction.target,",",r),"<>W")
				If ""=oneTarget Continue
				If (($f(oneTarget,"""_")'=0) && ($f(oneTarget,"_""",$f(oneTarget,"""_"))'=0)) {
					set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid target name: "_oneTarget_". Target name should not contain ""_ and _""")
					quit
				}
				Try {
					Set ^Ens.Rule.Targets(pClassname,oneTarget)=""
				} Catch { /* Might be RO Mirror Member */ }
			}
			if $$$ISERR(tSC) quit
			for t=1:1:$l(pAction.transform,",") {
				set tTransform = $zstrip($p(pAction.transform,",",t),"<>W")
				if ((tTransform '= "") && ('$zname(tTransform,4))) {
					set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid data transformation name: '"_tTransform_"'")
					quit
				}
			}
			if $$$ISERR(tSC) quit
			do ..writeReturnForSend(pAction, pLevel)
		} elseif ( pAction.type = "delete" ) {
			do ..line("set pReturnValue=pReturnValue_$s(pReturnValue'="""":"";"",1:"""")_""delete""",pLevel)
		} elseif ( pAction.type = "delegate" ) {
			if $translate(pAction.ruleName,";,:|!*-$'""<>&") '= pAction.ruleName {
				set tSC = $$$ERROR($$$EnsErrGeneral,"Invalid rule name: "_pAction.ruleName_". Rule names cannot contain any of the following characters: ',;:|!*-'$""<>&'" )
				quit
			}
			Try {
				Set ^Ens.Rule.Delegates(pClassname,pAction.ruleName)=""
			} Catch { /* Might be RO Mirror Member */ }
			do ..line("set pReturnValue=pReturnValue_$s(pReturnValue'="""":"";"",1:"""")_""delegate:"_pAction.ruleName_"""",pLevel)
		} elseif ( pAction.type = "debug" ) {
			set tSC=##class(Ens.Rule.Model.expression).convertToCOS(pAction.value,.tExpression,.variables) quit:$$$ISERR(tSC)
			set tDebug = $select(pAction.value = tExpression: tExpression, 1: $$$quote(pAction.value) _ "_"" = '""_" _ tExpression _ "_""'""")
			do ..line("if (pLogLevel [ $$$eRuleLogTypeUserDebug) set tSC = ##class(Ens.Rule.DebugLog).Log(pDebugId,$$$eRuleLogTypeUserDebug,"_$$$quote(pReason)_","_tDebug_",0) quit:$$$ISERR(tSC)",pLevel)
		} else {
		}
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod line(pCode, pLevel = 1)
{
	set tLine=$j("",pLevel*4)
	set tLine=tLine_pCode
	if $isObject($g(%code)) { do %code.WriteLine(tLine) } else { write tLine,! }
}

ClassMethod correlateByName(pClassname As %String, Output pRuleDefinition As Ens.Rule.Model.ruleDefinition, pConcurrency As %Integer = -1) As %Status
{
	set tSC=$$$OK
	try {
		; open class definition
		set tObjClass=##class(%Dictionary.ClassDefinition).%OpenId(pClassname)
		if '$isObject(tObjClass) set tSC=$$$ERROR($$$ClassDoesNotExist,pClassname) quit
		Set tObjXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(pClassname,"RuleDefinition",pConcurrency,.tSC)
		; RuleDefinition not found
		if tObjXData="" set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,pClassname,"RuleDefinition") quit
		; open the reader and correlate the XData to Ens.Rule.Model.ruleDefinition
		set tReader = ##class(%XML.Reader).%New()
		set tSC=tReader.OpenStream(tObjXData.Data) quit:$$$ISERR(tSC)
		do tReader.Correlate("ruleDefinition","Ens.Rule.Model.ruleDefinition")
		; find the first object
		do tReader.Next(.pRuleDefinition,.tSC) quit:$$$ISERR(tSC)
		if $isObject($get(pRuleDefinition)) set pRuleDefinition.Timestamp = $zdatetime(tObjClass.TimeChanged,3,,6)
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod correlateByObj(pObjClass As %Dictionary.ClassDefinition, Output pRuleDefinition As Ens.Rule.Model.ruleDefinition) As %Status
{
	set tSC=$$$OK
	try {
		; find XData with name RuleDefinition
		set tObjXData="" for i=1:1:pObjClass.XDatas.Count() if pObjClass.XDatas.GetAt(i).Name="RuleDefinition" set tObjXData=pObjClass.XDatas.GetAt(i) quit
		; RuleDefinition not found
		if tObjXData="" set tSC=$$$ERROR($$$EnsErrXDataBlockNotDefined,pObjClass.Name,"RuleDefinition") quit
		; open the reader and correlate the XData to Ens.Rule.Model.ruleDefinition
		set tReader = ##class(%XML.Reader).%New()
		set tSC=tReader.OpenStream(tObjXData.Data) quit:$$$ISERR(tSC)
		do tReader.Correlate("ruleDefinition","Ens.Rule.Model.ruleDefinition")
		; find the first object
		do tReader.Next(.pRuleDefinition,.tSC) quit:$$$ISERR(tSC)
		if $isObject($get(pRuleDefinition)) set pRuleDefinition.Timestamp = $zdatetime(pObjClass.TimeChanged,3,,6)
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

/* ----- Internal methods for handling RuleActionUserData during compilation -----*/
ClassMethod usesProperty(pProperty As %String, pRuleClassName As %String, pAssistClass As %String, pMustBeRoutingRule As %Boolean = 1) As %Boolean [ Internal ]
{
	#; Look in class code for use of the string pProperty
	#dim usesProperty = 0
	try {
		if pMustBeRoutingRule {
			if pAssistClass = "" quit
			if '$classmethod(pAssistClass,"GetIsRoutingRule") quit
			#dim contextClass = $classmethod(pAssistClass,"GetContextClass")
			if contextClass = "" quit
			if '$classmethod(contextClass,"%Extends","EnsLib.MsgRouter.RoutingEngine") quit
		}
		#dim tCookie, tSC, tMsgArray
		set tSC = $$BeginCapture^%SYS.Capture(.tCookie) quit:$$$ISERR(tSC)
		set tSC = ##class(%Studio.Project).FindInFiles(pProperty,pRuleClassName_".cls",0/*not system*/,0/*not wholeword*/,1/*case sensitive*/,1/*only need to find once*/) quit:$$$ISERR(tSC)
		set tSC = $$EndCapture^%SYS.Capture(.tCookie,.tMsgArray) quit:$$$ISERR(tSC)
		set usesProperty = (( tMsgArray.%Size() > 2) && (tMsgArray.%Get(2) [ pProperty))
	} catch {}
	return usesProperty
}

ClassMethod setActionReasonLines(pReason As %String, pLevel As %Integer) [ Internal ]
{
	/*	Routing engine relies on : , and ; for $Piece. 
		pReason contains : Including other 2. 
		Also strip out rule name - indicated by being in () - rule name might contain ) - hence check length
	*/
	try {
		if %usesRuleActionUserData {
			#dim tShortReason = $Translate(pReason,":,;")
			if tShortReason["(" Set tShortReason = $Piece(tShortReason,"(")_$Piece(tShortReason,")",$Length(tShortReason,")"))
			#dim tLevel = pLevel+1
			do ..line("try {",tLevel)
			do ..line("set tRuleActionReason="""_tShortReason_"""",tLevel+1)
			do ..line("set pContext.RuleActionReason=tRuleActionReason",tLevel+1)
			do ..line("} catch {}",tLevel)
		}
	} catch {}
}

ClassMethod writeReturnForSend(pAction As Ens.Rule.Model.action, pLevel As %Integer) [ Internal ]
{
	#dim closingQuotesandOptionalFourthSendPiece = """"
	#; ought to be defined but safeguard to ensure compiles.
	if $Get(%usesRuleActionUserData,0) {
		Set closingQuotesandOptionalFourthSendPiece = """_$s($Data(tRuleActionReason):"":""_tRuleActionReason"_",1:"""")"
	}
	do ..line("set pReturnValue=pReturnValue_$s(pReturnValue'="""":"";"",1:"""")_""send:"_pAction.target_":"_pAction.transform_closingQuotesandOptionalFourthSendPiece,pLevel)
}

ClassMethod clearRuleActionReason() [ Internal ]
{
	try {
		if %usesRuleActionUserData {
			do ..line("try {",1)
			do ..line("set pContext.RuleActionReason=""""",2)
			do ..line("} catch {}",1)
		}
	} catch {}
}

/* ----- End Internal methods for handling RuleActionUserData during compilation -----*/
}
