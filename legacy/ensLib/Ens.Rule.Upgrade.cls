/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.Upgrade Extends %RegisteredObject [ System = 4 ]
{

ClassMethod ConvertAll(qspec As %String) As %Status
{
	set tSC=$$$OK
	try {
		set qspec="/compile/delete"_$g(qspec)
		Set tSC=$$$qualifierParse(,qspec,.qstruct) quit:$$$ISERR(tSC)
		set host="" for  {
			set host=$o(^Ens.Rule.RuleDefinitionD(host)) quit:host=""
			set rule="" for  {
				set rule=$o(^Ens.Rule.RuleDefinitionD(host,rule)) quit:rule=""
				write:$$$qualifierGetValue(qstruct,"displaylog") "Converting rule ",host,".",rule," ...",!
				set tSC=..ConvertOne(host,rule,,qspec)
				if $$$ISERR(tSC) do:$$$qualifierGetValue(qstruct,"displayerror") DisplayError^%apiOBJ(tSC)
			}
		}
		quit
	} catch {
		set tSC=$$$SystemError
	}
	if $$$ISERR(tSC) do DisplayError^%apiOBJ(tSC)
	quit tSC
}

ClassMethod ConvertOne(pHostName As %String, pRuleLongName As %String, pClassName As %String, qspec As %String) As %Status
{
	set tSC=$$$OK
	try {
		set qspec="/compile/delete"_$g(qspec)
		Set tSC=$$$qualifierParse(,.qspec,.qstruct) quit:$$$ISERR(tSC)
		;
		if $d(^Ens.Rule.RuleDefinitionD(pHostName,pRuleLongName))=0 set tSC=$$$ERROR($$$EnsErrGeneral,"Rule "_pHostName_"."_pRuleLongName_" does not exist.") quit
		;
		set tVersion=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleLongName,""),-1)
		set tRuleName=$p(pRuleLongName,"$",1)
		set tEffectiveBegin=$p(pRuleLongName,"$",2)
		set tEffectiveEnd=$p(pRuleLongName,"$",3)
		;
		if $g(pClassName)="" set pClassName=..ConvertRulenameToClassname(pHostName,tRuleName)
		;
		write:$$$qualifierGetValue(qstruct,"displaylog") "Generating class ",pClassName," ...",!
		set tSC=..generateOneClass(pClassName,pHostName,pRuleLongName,tVersion,tEffectiveBegin,tEffectiveEnd) quit:$$$ISERR(tSC)
		;
		if $$$qualifierGetValue(qstruct,"delete") kill ^Ens.Rule.RuleDefinitionD(pHostName,pRuleLongName)
		if $$$qualifierGetValue(qstruct,"compile") do $system.OBJ.Compile(pClassName,.qstruct)
		;
		quit
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod ConvertRulenameToClassname(pHostName, pRuleName) As %String
{
	set tAlias = pHostName_"."_$p(pRuleName,"$",1)
	; normalize the package name
	set tPackage=$zstrip(pHostName,"*P",,"."),tPACKAGE=$zcvt(tPackage,"u")
	if $d(^rINDEXCLASS(tPACKAGE)) {
		set tNextValue=^rINDEXCLASS(tPACKAGE)
	} else {
		set tNextIndex=$o(^rINDEXCLASS(tPACKAGE),1,tNextValue)
	}
	if $g(tNextValue)'="" {
		set tNextClass=$li(tNextValue,2)
		if ($zcvt(tNextClass,"u")=tPACKAGE)||($zcvt($e(tNextClass,1,$l(tPACKAGE)+1),"u")=(tPACKAGE_".")) {
			set tPackage=$e(tNextClass,1,$l(tPACKAGE))
		}
	}
	set tClassnameBase = tPackage_"."_$zstrip(pRuleName,"*P",,".")
	for tSuffix="",1:1 {
		set tClassname=tClassnameBase_tSuffix
		if $d(^rINDEXCLASS($zcvt(tClassname,"u")),tIndexValue) set tClassname=$li(tIndexValue,2)
		set tClassDef=##class(%Dictionary.ClassDefinition).%OpenId(tClassname)
		if $isObject(tClassDef) {
			set tIndex=tClassDef.XDatas.FindObjectId(tClassname_"||RuleDefinition")
			if tIndex="" continue
			set tSC=##class(Ens.Rule.Generator).correlateByObj(tClassDef,.tRuleDefinitionModel) if $$$ISERR(tSC) continue
			set tExistingAlias=tRuleDefinitionModel.alias if tExistingAlias="" set tExistingAlias=tClassname
			if tExistingAlias'=tAlias continue
		}
		quit
	}
	quit tClassname
}

ClassMethod generateOneClass(pClassname, pHostName, pRuleName, pVersion, pEffectiveBegin, pEffectiveEnd) As %Status
{
	set tSC=$$$OK
	try {
		set tClassDef=##class(%Dictionary.ClassDefinition).%OpenId(pClassname)
		if '$isObject(tClassDef) {
			set tClassDef=##class(%Dictionary.ClassDefinition).%New(pClassname)
			set tClassDef.ClassVersion = 25
			set tClassDef.ProcedureBlock = 1
		}
		;
		set tValue=$g(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion))
		set tDescription = $li(tValue,2)
		set tDescription=$$replace^EnsUtil(tDescription,$C(10),$C(13,10), $C(13,13,10),$C(13,10))
		set tContext = $li(tValue,9)
		set tReportGroup = $lg(tValue,10)
		set tReportName = $lg(tValue,11)
		set tShortDescription = $lg(tValue,12)
		set tIsRoutingRule=$d(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"RoutingRule"))
		if tIsRoutingRule {
			set tAssistClass=$case(tContext,
				"EnsLib.MsgRouter.RoutingEngine"     :"EnsLib.MsgRouter.RuleAssist",
				"EnsLib.MsgRouter.RoutingEngineST"   :"EnsLib.MsgRouter.RuleAssist",
				"EnsLib.MsgRouter.VDocRoutingEngine" :"EnsLib.MsgRouter.VDocRuleAssistCompatible",
				"EnsLib.HL7.MsgRouter.RoutingEngine" :"EnsLib.HL7.MsgRouter.RuleAssistCompatible",
				"Demo.HL7v3.MsgRouter.RoutingEngine" :"Demo.HL7v3.MsgRouter.RuleAssist",
				                                     :"")
			if (tAssistClass="") {
				try {
					if ..isSubclass(tContext,"EnsLib.HL7.MsgRouter.RoutingEngine") {
						set tAssistClass = "EnsLib.HL7.MsgRouter.RuleAssistCompatible"
					} else {
						set:(..isSubclass(tContext,"EnsLib.MsgRouter.VDocRoutingEngine")) tAssistClass = "EnsLib.MsgRouter.VDocRuleAssistCompatible"
					}
				} catch {}
			}
			set:(tAssistClass="") tAssistClass = "EnsLib.MsgRouter.RuleAssist"
		} else {
			set tAssistClass="Ens.Rule.GeneralBusinessRuleAssist"
		}
		;
		set tParameters($i(tParameters))=$lb("ReportGroup",tReportGroup)
		set tParameters($i(tParameters))=$lb("ReportName",tReportName)
		set tParameters($i(tParameters))=$lb("ShortDescription",tShortDescription)
		set tParameters($i(tParameters))=$lb("RuleAssistClass",tAssistClass)
		;
		set tClassDef.Super = "Ens.Rule.Definition"
		set tClassDef.Description = tDescription
		for i=1:1:$g(tParameters) {
			set tParamName = $li(tParameters(i),1)
			set tParamValue = $li(tParameters(i),2)
			if tParamValue="" continue
			if tClassDef.Parameters.FindObjectId(pClassname_"||"_tParamName)'="" continue
			set tParamDef = ##class(%Dictionary.ParameterDefinition).%New()
			set tParamDef.parent = tClassDef
			set tParamDef.Name = tParamName
			set tParamDef.Default = tParamValue
			set tParamDef.SequenceNumber = $i(tSequenceNumber)
		}
		;
		set tIndex=tClassDef.XDatas.FindObjectId(pClassname_"||RuleDefinition")
		if tIndex'="" {
			set tXDataDef = tClassDef.XDatas.GetAt(tIndex)
			set tSC=##class(Ens.Rule.Generator).correlateByObj(tClassDef,.tRuleDefinitionModel) if $$$ISERR(tSC) quit

		} else {
			set tXDataDef = ##class(%Dictionary.XDataDefinition).%New()
			set tXDataDef.parent = tClassDef
			set tXDataDef.Name = "RuleDefinition"
			set tXDataDef.XMLNamespace = "http://www.intersystems.com/rule"
			set tXDataDef.SequenceNumber = $i(tSequenceNumber)
			set tRuleDefinitionModel = ##class(Ens.Rule.Model.ruleDefinition).%New()
		}
		;
		set tAlias = pHostName_"."_$p(pRuleName,"$",1)
		if tAlias'=pClassname set tRuleDefinitionModel.alias = tAlias
		set tRuleDefinitionModel.context = tContext
		;
		set tRuleSetModel=""
		for i=1:1:tRuleDefinitionModel.ruleSets.Count() {
			set tRuleSetOne=tRuleDefinitionModel.ruleSets.GetAt(i)
			if (tRuleSetOne.effectiveBegin=pEffectiveBegin)&&(tRuleSetOne.effectiveEnd=pEffectiveEnd) {
				set tRuleSetModel=tRuleSetOne
				do tRuleSetModel.actions.Clear()
				quit
			}
		}
		if tRuleSetModel="" {
			set tRuleSetModel=##class(Ens.Rule.Model.ruleSet).%New()
			set tRuleSetModel.effectiveBegin = pEffectiveBegin
			set tRuleSetModel.effectiveEnd = pEffectiveEnd
			do tRuleDefinitionModel.ruleSets.Insert(tRuleSetModel)
		}
		;
		if tIsRoutingRule {
			set tSC=..generateOneRoutingRule(tRuleSetModel,pHostName,pRuleName,pVersion) quit:$$$ISERR(tSC)
		} else {
			set tSC=..generateOneGeneralRule(tRuleSetModel,pHostName,pRuleName,pVersion) quit:$$$ISERR(tSC)
		}
		;
		set tSC=tRuleDefinitionModel.XMLExportToStream(tXDataDef.Data,,",indent()") quit:$$$ISERR(tSC)
		set tSC=tClassDef.%Save() quit:$$$ISERR(tSC)
		;
		quit
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod generateOneGeneralRule(pRuleSetModel As Ens.Rule.Model.ruleSet, pHostName As %String, pRuleName As %String, pVersion As %String) As %Status
{
	set tSC=$$$OK
	try {
		set tDefault=$li(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"RuleSet"),1)
		;
		set tRule="" for  {
			set tRule=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.RuleSet.Rules",tRule),1,tValue) quit:tRule=""
			;
			set tRuleModel = ##class(Ens.Rule.Model.rule).%New()
			set tRuleModel.disabled = $li(tValue,2)
			do pRuleSetModel.actions.Insert(tRuleModel)
			;
			set tCondition=""
			set tCount="" for  {
				set tCount=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.RuleSet.Rules",tRule,"Conditions",tCount),1,tSubValue) quit:tCount=""
				set tJoin=$li(tSubValue,2)
				set tOp1=$li(tSubValue,3)
				set tOp2=$li(tSubValue,4)
				set tOperator=$li(tSubValue,5)
				set tOneCondition=..fixOneCondition(tOperator,tOp1,tOp2)
				set tJoin=$s(tJoin="AND":"&&",1:"||")
				set tCondition=$s(tCondition="":"("_tOneCondition_")",1:tCondition_tJoin_"("_tOneCondition_")")
			}
			if tCondition="" set tCondition=1
			set tWhenModel = ##class(Ens.Rule.Model.when).%New()
			set tWhenModel.condition = tCondition
			do tRuleModel.whens.Insert(tWhenModel)
			;
			set tAction="" for  {
				set tAction=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.RuleSet.Rules",tRule,"Actions",tAction)) quit:tAction=""
				set tSubValue=$g(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.RuleSet.Rules",tRule,"Actions",tAction,"Assign"))
				if tSubValue'="" {
					set tAssignModel = ##class(Ens.Rule.Model.assign).%New()
					set tAssignModel.property = $li(tSubValue,1)
					set tAssignModel.value = $li(tSubValue,2)
					do tWhenModel.actions.Insert(tAssignModel)
				}
			}
			;
			set tReturnModel = ##class(Ens.Rule.Model.return).%New()
			set tReturnModel.value = $li(tValue,3)
			do tWhenModel.actions.Insert(tReturnModel)
		}
		;
		if tDefault'="" {
			set tReturnModel = ##class(Ens.Rule.Model.return).%New()
			set tReturnModel.value = tDefault
			do pRuleSetModel.actions.Insert(tReturnModel)
		}
		;
		quit
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod generateOneRoutingRule(pRuleSetModel As Ens.Rule.Model.ruleSet, pHostName As %String, pRuleName As %String, pVersion As %String) As %Status
{
	set tSC=$$$OK
	try {
		;
		set tSubValue=^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"RoutingRule")
		#; DoAll was introduced by TAP310 in 2007.1 - the value may not exist for 4.0 rules
		set tDoAll=''$lg(tSubValue,6)
		set tBaseSource=$li(tSubValue,5)
		set tBaseMsgClass=$li(tSubValue,4)
		set tBaseDocName=$li(tSubValue,2)
		set tBaseDocCategory=$li(tSubValue,1)
		set tBaseDocType=$li(tSubValue,3)
		;
		set tRule="" for  {
			set tRule=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.Router.RoutingRule.Rules",tRule),1,tValue) quit:tRule=""
			;
			set tRuleModel = ##class(Ens.Rule.Model.rule).%New()
			set tRuleModel.disabled = $li(tValue,2)
			do pRuleSetModel.actions.Insert(tRuleModel)
			;
			set tProperty(1)="source",     tValue(1)=$li(tValue,6) if tValue(1)="" set tValue(1)=tBaseSource
			set tProperty(2)="msgClass",   tValue(2)=$li(tValue,3) if tValue(2)="" set tValue(2)=tBaseMsgClass
			set tProperty(3)="docName",    tValue(3)=$li(tValue,8) if tValue(3)="" set tValue(3)=tBaseDocName
			set tProperty(4)="docCategory",tValue(4)=$li(tValue,7) if tValue(4)="" set tValue(4)=tBaseDocCategory
			set tProperty(5)="docType",    tValue(5)=$li(tValue,9) if tValue(5)="" set tValue(5)=tBaseDocType
			for i=1:1:5 {
				if tValue(i)'="" {
					set tConstraintModel = ##class(Ens.Rule.Model.constraint).%New()
					set tConstraintModel.name = tProperty(i)
					set tConstraintModel.value = tValue(i)
					do tRuleModel.constraints.Insert(tConstraintModel)
				}
			}
			set tCondition=""
			set tCount="" for  {
				set tCount=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.Router.RoutingRule.Rules",tRule,"Conditions",tCount),1,tSubValue) quit:tCount=""
				set tJoin=$li(tSubValue,2)
				set tOp1=$li(tSubValue,3)
				set tOp2=$li(tSubValue,4)
				set tOperator=$li(tSubValue,5)
				set tJoin=$s(tJoin="AND":"&&",1:"||")
				set tOneCondition=..fixOneCondition(tOperator,tOp1,tOp2)
				set tCondition=$s(tCondition="":"("_tOneCondition_")",1:tCondition_tJoin_"("_tOneCondition_")")
			}
			if tCondition="" set tCondition=1
			set tWhenModel = ##class(Ens.Rule.Model.when).%New()
			set tWhenModel.condition = tCondition
			do tRuleModel.whens.Insert(tWhenModel)
			;
			set tContinue=tDoAll
			set tAction="" for  {
				set tAction=$o(^Ens.Rule.RuleDefinitionD(pHostName,pRuleName,pVersion,"Ens.Rule.Router.RoutingRule.Rules",tRule,"Actions",tAction),1,tSubValue) quit:tAction=""
				set tTarget=$li(tSubValue,2)
				set tTransform=$li(tSubValue,3)
				set tType=$li(tSubValue,4)
				if tType="contin" set:tDoAll=0 tContinue=1 continue
				if tType="stop"   set:tDoAll=1 tContinue=0 continue
				if tType="rule" set tType="delegate"
				;
				if tType="send" {
					set tSendModel = ##class(Ens.Rule.Model.send).%New()
					set tSendModel.transform = tTransform
					set tSendModel.target = tTarget
					do tWhenModel.actions.Insert(tSendModel)
				} elseif tType="delete" {
					set tDeleteModel = ##class(Ens.Rule.Model.delete).%New()
					do tWhenModel.actions.Insert(tDeleteModel)
				} elseif tType="delegate" {
					set tDelegateModel = ##class(Ens.Rule.Model.delegate).%New()
					set tDelegateModel.ruleName = tTarget
					do tWhenModel.actions.Insert(tDelegateModel)
				}
			}
			if tContinue=0 do tWhenModel.actions.Insert(##class(Ens.Rule.Model.return).%New())
		}
		quit
	} catch {
		set tSC=$$$SystemError
	}
	quit tSC
}

ClassMethod fixOneCondition(pOperator As %String, pOp1, pOp2) As %String
{
	set:pOp1="" pOp1=""""""
	set:pOp2="" pOp2=""""""
	if pOperator="" quit pOp1
	if $zname(pOperator) quit pOperator_"("_pOp1_","_pOp2_")"
	quit "("_pOp1_")"_pOperator_"("_pOp2_")"
}

ClassMethod OperatorPrecedenceChangeReport(pReport) As %Status
{
	set tSC=$$$OK
	try {
		set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		set tSC = tRS.%Execute("Ens.Rule.Definition") quit:$$$ISERR(tSC)
		while tRS.%Next() {
			set tClass = tRS.%Get("Name")
			set pReport(tClass)=0
			set tSC = ##class(Ens.Rule.Generator).correlateByName(tClass,.tModel) quit:$$$ISERR(tSC)
			for tRuleSetIndex=1:1:tModel.ruleSets.Count() {
				set tSC = ..scanActions(.pReport,tClass,tModel.ruleSets.GetAt(tRuleSetIndex).actions) quit:$$$ISERR(tSC)
			}
		}
		set tClass="" for  {
			set tClass=$o(pReport(tClass)) quit:tClass=""
			write tClass," - ",$case(pReport(tClass), 0:"no expressions affected", 1:"1 expression affected", :pReport(tClass)_" expressions affected"),!
			for tIndex=1:1:pReport(tClass) {
				write "    original expression: ",pReport(tClass,tIndex,0),!
				write "     old interpretation: ",pReport(tClass,tIndex,1),!
				write "     new interpretation: ",pReport(tClass,tIndex,2),!
			}
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	if $$$ISERR(tSC) do $system.OBJ.DisplayError(tSC)
	quit tSC
}

ClassMethod scanActions(pReport, class, actions) As %Status
{
	set tSC = $$$OK
	for tActionIndex = 1:1:actions.Count() {
		set tSC = ..scanOneAction(.pReport,class,actions.GetAt(tActionIndex)) quit:$$$ISERR(tSC)
	}
	quit tSC
}

ClassMethod scanOneAction(pReport, class, action) As %Status
{
	set tSC = $$$OK
	if ( action.type = "rule" ) {
		for tIndex=1:1:action.whens.Count() {
			do ..checkOneExpression(.pReport,class,action.whens.GetAt(tIndex).condition)
			set tSC = ..scanActions(.pReport,class,action.whens.GetAt(tIndex).actions) quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		if $isObject(action.otherwise) {
			set tSC = ..scanActions(.pReport,class,action.otherwise.actions) quit:$$$ISERR(tSC)
		}
	} elseif ( action.type = "assign" ) {
		if $e(action.property,*)="}" {
			set tObject=$p(action.property,".{",1,$l(action.property,".{")-1)
			do ..checkOneExpression(.pReport,class,tObject)
		}
		do ..checkOneExpression(.pReport,class,action.value)
	} elseif ( action.type = "return" ) {
		do ..checkOneExpression(.pReport,class,action.value)
	} elseif ( action.type = "trace" ) {
		do ..checkOneExpression(.pReport,class,action.value)
	} elseif ( action.type = "send" ) {
	} elseif ( action.type = "delete" ) {
	} elseif ( action.type = "delegate" ) {
	} else {
	}
	quit tSC
}

ClassMethod checkOneExpression(pReport, class, expression) As %Status
{
	if ##class(Ens.Rule.Model.expression).IsInterpretationChanged(expression,.old,.new) {
		set index = $i(pReport(class))
		set pReport(class,index,0) = expression
		set pReport(class,index,1) = old
		set pReport(class,index,2) = new
	}
	quit
}

/// Internal helper method to determine whether <var>pClassname</var> is actually a subclass of <var>pSuper</var>.
/// Taken from EnsPortal.Utils but accounts for <INVALID CLASS> which is likely when converting Rules.
ClassMethod isSubclass(pClassname As %String, pSuper As %String) As %Boolean [ Internal ]
{
	Set tIsSub = 0
	#dim ex As %Exception.AbstractException
	#dim tInvalidClass As %Boolean = 0
	Try {
		If ##class(%Dictionary.CompiledMethod).IDKEYExists(pClassname,"%Extends") {
			Try {
				Set tIsSub = $classmethod(pClassname,"%Extends",pSuper)
			}
			Catch ex {
				#; we want to continue to look at the class definition
				If ex.Name="<INVALID CLASS>" Set tInvalidClass = 1
				Set tIsSub = 0
			}
			If 'tInvalidClass Quit
		}
	
		If ##class(%Dictionary.ClassDefinition).%ExistsId(pClassname) {
			Set tClasses = 1
			Set tClasses(1) = $lb(pClassname)
			Set tIsSub = 0
			Set tLevel = 1
			For {
				For i=1:1:$listlength(tClasses(tLevel)) {
					Set tClass = $listget(tClasses(tLevel), i)
					If $data(tSeen(tClass)) { Continue }
					Set tSeen(tClass) = ""
					If 'tInvalidClass && ##class(%Dictionary.CompiledMethod).IDKEYExists(tClass,"%Extends") {
						Set tIsSub = $classmethod(tClass,"%Extends",pSuper)
						If tIsSub Quit  ; May be wrong branch
					}
					Else {
						Set tSuper = $$$defClassKeyGet(tClass,$$$cCLASSsuper)
						If (tSuper = "") { Continue }
						Set tSuper = $listfromstring(tSuper)
						If $listfind(tSuper, pSuper) {
							Set tIsSub = 1
							Quit
						}
					}
					Set tClasses(tLevel + 1) = $get(tClasses(tLevel + 1)) _ tSuper
					Set tClasses = (tLevel + 1)
				}
				If tIsSub Quit
				Set tLevel = tLevel + 1
				If '$data(tClasses(tLevel)) Quit
			}
		}
	}
	Catch ex {
		Set tIsSub = 0
	}
	Quit tIsSub
}

}
