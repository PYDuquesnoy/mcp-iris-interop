/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.MsgRouter.RuleAssist Extends Ens.Rule.Assist [ Abstract, System = 4 ]
{

ClassMethod GetMetaData() As %String
{
	quit "source:"_$$$Text("Source","Ensemble")_":#configname,msgClass:"_$$$Text("Message Class","Ensemble")_":#class#allmessages"
}

ClassMethod GetDescription() As %String
{
	quit $$$Text("General Message Routing Rule","Ensemble")
}

ClassMethod GetContextClass() As %String
{
	quit "EnsLib.MsgRouter.RoutingEngine"
}

ClassMethod GetIsRoutingRule() As %String
{
	quit 1
}

ClassMethod GetPropertyList(pArray, pText, pPropertyTypeOverride) As %String
{
	set pArray("%classPropertyTypeOverride","EnsLib.MsgRouter.RoutingEngine","Document")=$g(pArray("msgClass"))
	quit ##super(.pArray,pText)
}

ClassMethod RuntimeConstraintCheck(ByRef pArray, pContext, Output pPassed) As %Status
{
	Set pPassed=0
	Set tSource=$G(pArray("source"))  Quit:""'=tSource&&(tSource'=pContext.Source) $$$OK
	Set tMsgClass=$G(pArray("msgClass"))  Quit:""'=tMsgClass&&(tMsgClass'=pContext.MsgClass) $$$OK
	Set pPassed=1
	Quit $$$OK
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

/// Add delegate, delete, and send actions for use with routing rules
ClassMethod GetValidActions()
{
	return ##super()_$listbuild("delegate","delete","send")
}

/// Generates the schema for a delegate objects
ClassMethod GenerateDelegateSchema()
{
	return ..GenerateActionSchema("Ens.Rule.Model.delegate")
}

/// Generates the schema for a delete objects
ClassMethod GenerateDeleteSchema() As %DynamicObject
{
	return ..GenerateActionSchema("Ens.Rule.Model.delete")
}

/// Generates the schema for a send objects
ClassMethod GenerateSendSchema()
{
	return ..GenerateActionSchema("Ens.Rule.Model.send")
}

/// Configure returns on routing rules to not return a value
ClassMethod GenerateReturnSchema()
{
	return {
		"type": "object",
		"properties": {
			"type": {
				"const": "return"
			}
		}
	}
}

}
