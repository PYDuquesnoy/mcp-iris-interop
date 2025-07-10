/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.MsgRouter.VDocRuleAssistCompatible Extends Ens.Rule.Assist [ Abstract, System = 4 ]
{

ClassMethod GetMetaData() As %String
{
	quit "source:"_$$$Text("Source","Ensemble")_":#configname,msgClass:"_$$$Text("Message Class","Ensemble")_":#class#vdocclass,docCategory:"_$$$Text("Schema Category","Ensemble")_":#query,docName:"_$$$Text("Document Name","Ensemble")_":commalist#query,docType:"_$$$Text("Schema DocType","Ensemble")_":commalist#query"
}

ClassMethod GetDescription() As %String
{
	quit $$$Text("Virtual Document Message Routing Rule (compatible mode)","Ensemble")
}

ClassMethod IsHidden() As %String
{
	quit 1
}

ClassMethod GetContextClass() As %String
{
	quit "EnsLib.MsgRouter.VDocRoutingEngine"
}

ClassMethod GetIsRoutingRule() As %String
{
	quit 1
}

ClassMethod GetQueryData(ByRef pArray, pParam) As %String
{
	Set tVal=""
	Try {
		If pParam="msgClass" {
			Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
			Do tRS.Execute("Ens.VDoc.Interface")
			While (tRS.Next()) { 
				Set class=$G(tRS.Data("Name"))
				set classobj=##class(%Dictionary.CompiledClass).%OpenId(class)
				if '$isObject(classobj) continue
				if classobj.ClassType="persistent" Set tVal=tVal_","_class
			}
			Do tRS.Close()			
		} ElseIf pParam="docCategory" {
			Set tClass=$G(pArray("msgClass")) If tClass="" Quit
			Set tSchemaClass=$P($$$GetClassParameter(tClass,"SCHEMACLASS"),":",1)  Quit:""=tSchemaClass
			Set tRS = ##class(%ResultSet).%New(tSchemaClass_":TypeCategories")
			Do tRS.Execute("")
			While (tRS.Next()) { 
				Set cat=$G(tRS.Data("Category"))
				Set tVal=tVal_","_cat
			}
			Do tRS.Close()
		} ElseIf pParam="docName" {
			Quit:$G(pArray("docCategory"))=""
			If pArray("msgClass")="EnsLib.HL7.Message" {
				Set tRS = ##class(%ResultSet).%New("EnsLib.HL7.Schema:MessageTypes")
			} Else {
				Set tClass=$G(pArray("msgClass"))  If tClass="" Quit
				Set tRS = ##class(%ResultSet).%New(tClass_":EnumerateDocTypes")
			}
			Set tSC = tRS.Execute(pArray("docCategory"),1) Quit:$$$ISERR(tSC)
			While (tRS.Next()) { 
				Set struct=tRS.GetData(1)
				Set tVal=tVal_","_$p(struct,":",2)
			}
			Do tRS.Close()
		} ElseIf pParam="docType" {
			Set tClass=$G(pArray("msgClass")) If tClass="" Quit
			Quit:$G(pArray("docCategory"))=""
			Set tRS = ##class(%ResultSet).%New(tClass_":EnumerateDocTypes")
			Set tSC = tRS.Execute($G(pArray("docCategory")),1) Quit:$$$ISERR(tSC)
			While (tRS.Next()) { 
				Set struct=tRS.GetData(1)
				Set tVal=tVal_","_$P(struct,":",2)
			}
			Do tRS.Close()
		}
	} Catch {
	}
	Quit $E(tVal,2,*)
}

ClassMethod GetPropertyList(ByRef pArray, pText) As %String
{
	set tVPTable("Document")=""
	for i=1:1:$l($g(pArray("%additionalVDocProperties")),",") set tVPOne=$P($g(pArray("%additionalVDocProperties")),",",i) if tVPOne'="" set tVPTable(tVPOne)=""
	;
	set tVProp=$P(pText,".{",1)
	;
	if (tVProp'="")&&($d(tVPTable(tVProp)))&&($g(pArray("msgClass"))'="") {
		set rootPath=$e(pText,$f(pText,".{"),*),rootLength=$l(rootPath)
		set tList=0
		set tDocCategory=$ZStrip($p($g(pArray("docCategory")),","),"<>WC")
		set tDocType=$ZStrip($P($G(pArray("docType")),","),"<>WC")
		set tDocName=$ZStrip($p($g(pArray("docName")),","),"<>WC")
		if ""=tDocType {
			set tClass=$g(pArray("msgClass")) If tClass="" Quit ""
			set tSchemaClass=$p($$$GetClassParameter(tClass,"SCHEMACLASS"),":",1) If tSchemaClass="" Quit ""
			set tDocType=$classmethod(tSchemaClass,"ResolveSchemaTypeToDocType",tDocCategory,tDocName)
		}
		set tRS = ##class(%ResultSet).%New("Ens.VDoc.Utils:EnumerateDocContents")
		Do tRS.Execute(pArray("msgClass"),"source",$S(tDocType[":":"",1:tDocCategory_":")_tDocType,,0,,1)
		While (tRS.Next()) {
			Set path=$G(tRS.Data("Property"))
			if $e(path,1,rootLength)'=rootPath continue
			set rest=$e(path,rootLength+1,*)
			if rest="" continue
			if $f(rest,":") {
				set rest=$e(rest,1,$f(rest,":")-2)
				set type=":"
			} elseif $f(rest,".") {
				set rest=$e(rest,1,$f(rest,".")-2)
				set type="."
			} else {
				set type=""
			}
			if $g(tList(tList))'=rest set tList($i(tList))=rest
			set:type'="" tList(tList,type)=""
		}
		Do tRS.Close()
		set tVal=""
		for i=1:1:tList {
			if $d(tList(i,":")) set tVal=tVal_","_tList(i)_":"
			if $d(tList(i,".")) set tVal=tVal_","_tList(i)_"."
			if $d(tList(i))=1   set tVal=tVal_","_tList(i)_"}"
		}
		quit $e(tVal,2,*)
	} else {
		quit ##super(.pArray,pText)
	}
}

ClassMethod RuntimeConstraintCheck(ByRef pArray, pContext, Output pPassed) As %Status
{
	Set pPassed=0
	Set tSource=$G(pArray("source"))  Quit:""'=tSource&&(tSource'=pContext.Source) $$$OK
	Set tMsgClass=$G(pArray("msgClass"))  Quit:""'=tMsgClass&&(tMsgClass'=pContext.MsgClass) $$$OK
	Set tDocNames=$G(pArray("docName")), tDocTypes=$G(pArray("docType")), tDocCategory=$G(pArray("docCategory"))
	Set cDocName=pContext.DocName
	Set cDocType=pContext.DocType, cDocCategory=""
	Set:cDocType[":" cDocCategory=$P(cDocType,":",1), cDocType=$P(cDocType,":",2)
	#; loop over constraint DocNames
	For n=1:1:$L(tDocNames,",") { Set tName=$P(tDocNames,",",n)  Continue:""=tName&&(n>1)  Continue:""'=tName&&(tName'=cDocName)
		#; loop over constraint DocTypes
		For t=1:1:$L(tDocTypes,",") { Set tType=$P(tDocTypes,",",t)  Continue:""=tType&&(t>1)
			#; test for local override of category, i.e. "2.3.1:ADT_A04"
			If tType [ ":" {
				Set tCategory=$P(tType,":",1), tType=$P(tType,":",2)
			} Else {
				Set tCategory = tDocCategory
			}
			If ""=tCategory||(tCategory=cDocCategory) {
				If ""=tType||(tType=cDocType) {
					Set pPassed=1
					Quit
				}
			}
		} Quit:pPassed
	}
	Quit $$$OK
}

ClassMethod GenerateSchema() As %DynamicObject
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GenerateSchema()
}

ClassMethod GenerateRuleSchema() As %DynamicObject
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GenerateRuleSchema()
}

ClassMethod GetValidActions()
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GetValidActions()
}

ClassMethod GenerateDelegateSchema()
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GenerateDelegateSchema()
}

ClassMethod GenerateDeleteSchema()
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GenerateDeleteSchema()
}

ClassMethod GenerateSendSchema()
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GenerateSendSchema()
}

ClassMethod GenerateReturnSchema()
{
	return ##class(EnsLib.MsgRouter.RuleAssist).GenerateReturnSchema()
}

}
