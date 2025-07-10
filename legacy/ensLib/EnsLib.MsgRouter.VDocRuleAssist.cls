/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.MsgRouter.VDocRuleAssist Extends Ens.Rule.Assist [ Abstract, System = 4 ]
{

ClassMethod GetMetaData() As %String
{
	quit "source:"_$$$Text("Source","Ensemble")_":#configname,msgClass:"_$$$Text("Message Class","Ensemble")_":#query,docCategory:"_$$$Text("Schema Category","Ensemble")_":#query,docName:"_$$$Text("Document Name","Ensemble")_":commalist#query"
}

ClassMethod GetDescription() As %String
{
	quit $$$Text("Virtual Document Message Routing Rule","Ensemble")
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
			Set tRS = ##class(%ResultSet).%New(tClass_":EnumerateTypeCategories")
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
		}
	} Catch {
	}
	Quit $E(tVal,2,*)
}

ClassMethod GetPropertyList(ByRef pArray, pText) As %String
{
	set tVPTable("Document")=""
	if (""'=$g(pArray("%additionalVDocProperties"))) {
		for i=1:1:$l(pArray("%additionalVDocProperties"),",") {
			set tVPOne=$p(pArray("%additionalVDocProperties"),",",i)
			if tVPOne'="" {
				set tVPTable(tVPOne)=""
			}
		}
	}

	set tBraces(1)="{", tBraces(2)="}"
	if $f(pText,".(") && (($f(pText,".{") = 0) || ($f(pText,".(") < $f(pText,".{"))) set tBraces(1)="(", tBraces(2)=")"
	set tVProp=$p(pText,"."_tBraces(1),1)

	if (tVProp'="")&&($d(tVPTable(tVProp)))&&($g(pArray("msgClass"))'="") {
		set rootPath = ..cleanVDocPath($extract(pText,$find(pText,"."_tBraces(1)),*))
		set rootLength=$l(rootPath)
		set tList=0
		set tDocCategory=$ZStrip($p($g(pArray("docCategory")),","),"<>WC")
		set tSchemaClass=$p($$$GetClassParameter(pArray("msgClass"),"SCHEMACLASS"),":",1) If tSchemaClass="" Quit ""
		set tDocName=$ZStrip($p($g(pArray("docName")),","),"<>WC")
		if (tVProp="Segment") {
			set tSegName=$ZStrip($p($g(pArray("segName")),","),"<>WC")
			set tDocType=$classmethod(tSchemaClass,"ResolveSegNameToStructure",tDocCategory,tDocName,tSegName)
			set tClass = $g(pArray("segClass"))
			Quit:(""=tClass) ""
		} else {
			set tDocType=$classmethod(tSchemaClass,"ResolveSchemaTypeToDocType",tDocCategory,tDocName)
			set tClass = pArray("msgClass")
		}
		set tSegsOnly = $Select($g(pArray("%segsOnly")):1,1:0)
		set tRS = ##class(%ResultSet).%New("Ens.VDoc.Utils:EnumerateDocContents")
		Do tRS.Execute(tClass,"source",tDocType,tSegsOnly,0,,1)
		While (tRS.Next()) {
			set path=$G(tRS.Data("Property"))
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
			if (tBraces(1)="{")&&'tSegsOnly {
				set rest=$replace(rest,"()","(1)")
			}
			if $g(tList(tList))'=rest set tList($i(tList))=rest
			set:type'="" tList(tList,type)=""
		}
		Do tRS.Close()
		set tVal=""
		for i=1:1:tList {
			if $d(tList(i,":")) set tVal=tVal_","_tList(i)_":"
			if $d(tList(i,".")) set tVal=tVal_","_tList(i)_"."
			if $d(tList(i))=1   set tVal=tVal_","_tList(i)_tBraces(2)
		}
		quit $e(tVal,2,*)
	} else {
		set pArray("%classPropertyTypeOverride",..GetContextClass(),"Document")=$g(pArray("msgClass"))
		quit ##super(.pArray,pText)
	}
}

ClassMethod RuntimeConstraintCheck(ByRef pArray, pContext, Output pPassed) As %Status
{
	Set pPassed=0
	Set tSource=$G(pArray("source"))  Quit:""'=tSource&&(tSource'=pContext.Source) $$$OK
	Set tMsgClass=$G(pArray("msgClass"))  Quit:""'=tMsgClass&&(tMsgClass'=pContext.MsgClass) $$$OK
	Set tDocNames=$G(pArray("docName")), tDocCategory=$G(pArray("docCategory"))
	Set cDocName=pContext.DocName, cDocType=pContext.DocType
	If ""=tDocCategory||(tDocCategory=$P(cDocType,":")) {
		#; loop over constraint tDocNames, comparing with context cDocName
		For n=1:1:$L(tDocNames,",") {
			Set tName=$P(tDocNames,",",n)
			Continue:""=tName&&(n>1)
			#; Perform the comparison between document name and constraint name, if present.
			#; For non-HL7 messages, the name constraint may refer to the DocTypeName, and so this is checked too. 
			Continue:""'=tName&&(tName'=cDocName)&&((pArray("msgClass")="EnsLib.HL7.Message")||(tName'=$P(cDocType,":",2)))
			Set pPassed=1
			Quit
		}
	}
	Quit $$$OK
}

/// Helper method to extract any user-defined expressions from supplied VDoc paths to ensure
/// that we simplify the expression to match the maps we have on the server.
/// As a simple example, we need to ensure that "NK1(1):Name(1)." is converted to "NK1():Name()"
/// to ensure that we can match the abstract path. The expression may not be numeric, and may contain
/// method calls and/or context variables, so the parsing here is reasonably general.
ClassMethod cleanVDocPath(pPath As %String = "", Output pStatus As %Status) As %String [ Internal ]
{
	Set pStatus = $$$OK
	If pPath = "" Quit ""
	Set tNewPath = pPath
	Try {
		#; Step 1: check quotes are balanced, i.e. $length(pPath,"""") is uneven
		Set tQuoteLen = $length(pPath,"""")
		If (tQuoteLen#2) = 0 {
			Set pStatus = $$$ERROR($$$EnsErrGeneral,"Quote mismatch")
			Quit
		}
		Set tNewPath = ""
		#; Step 2: remove anything inside quotes, i.e. strings inside even pieces
		For i=1:2:tQuoteLen {
			Set tNewPath = tNewPath _ $piece(pPath,"""",i)
		}
		
		#; Step 3: quick check on the number of parentheses
		Set tParenOpenLen = $length(pPath,"(")
		Set tParenCloseLen = $length(pPath,")")
		If (tParenOpenLen '= tParenCloseLen) {
			Set pStatus = $$$ERROR($$$EnsErrGeneral,"Parenthesis mismatch")
			Quit
		}
		#; Step 4: search for parentheses and mark open/close boundaries
		Set tNextOpen = $find(tNewPath,"(")
		If tNextOpen {
			Set tPathLen = $length(tNewPath)
			Set tParenLevel = 1
			Set tParenData(tParenLevel) = 1
			Set tParenData(tParenLevel,tParenData(tParenLevel),"open") = tNextOpen - 1
			Set tRemStart = tNextOpen
			While (tRemStart <= tPathLen) {
				Set tNextOpen = $find(tNewPath,"(",tRemStart)
				Set tNextClose = $find(tNewPath,")",tRemStart)
				If (tNextOpen = 0) && (tNextClose = 0) {
					Set tRemStart = tPathLen + 1
				}
				ElseIf (tNextOpen = 0) || (tNextClose && (tNextClose < tNextOpen)) {
					If (tParenLevel <= 0) || '$data(tParenData(tParenLevel)) {
						Set pStatus = $$$ERROR($$$EnsErrGeneral,"Parenthesis mismatch")
						Quit
					}
					Set tParenData(tParenLevel,tParenData(tParenLevel),"close") = tNextClose - 1
					Set tParenLevel = tParenLevel - 1
					Set tRemStart = tNextClose
				}
				ElseIf (tNextClose = 0) || (tNextOpen && (tNextOpen < tNextClose)) {
					Set tParenLevel = tParenLevel + 1
					Set tParenData(tParenLevel) = $get(tParenData(tParenLevel)) + 1
					Set tParenData(tParenLevel,tParenData(tParenLevel),"open") = tNextOpen - 1
					Set tRemStart = tNextOpen
				}
			}
			If $$$ISERR(pStatus) Quit
			If (tParenLevel '= 0) {
				Set pStatus = $$$ERROR($$$EnsErrGeneral,"Parenthesis mismatch")
				Quit
			}
			#; Step 5: Restrict string to data outside top-level parentheses
			Set tBasePath = tNewPath
			Set tNewPath = ""
			Set tKey = ""
			Set tLastClose = 0
			For {
				Set tKey = $order(tParenData(1,tKey))
				Quit:(tKey = "")
				Set tOpen = $get(tParenData(1,tKey,"open"))
				Set tNewPath = tNewPath _ $extract(tBasePath,tLastClose,tOpen)
				Set tLastClose = $get(tParenData(1,tKey,"close"))
			}
			Set tNewPath = tNewPath _ $extract(tBasePath,tLastClose,*)
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	If $$$ISOK(pStatus) {
		Quit tNewPath
	}
	Quit pPath
}

/// Add production to user-visible properties of routing rule Rule Definitions
ClassMethod GenerateSchema() As %DynamicObject
{
	set schema = ##super()
	set schema.properties.production = {
		"type": "string"
	}
	return schema
}

/// Add constraint to user-visible properties of routing rule Rules
ClassMethod GenerateRuleSchema() As %DynamicObject
{
	set schema = ##super()
	set schema.properties.constraints = {
		"type": "array"
	}
	return schema
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
