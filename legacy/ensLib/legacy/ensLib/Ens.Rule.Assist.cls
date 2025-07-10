/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.Assist [ Abstract, System = 4 ]
{

/// This method returns the meta data for the cconstraint fields
/// The structure of the meta data is the following:
/// meta-data = comma separted list of fields
/// field = colon separated values:
///       = constraint-field-name : caption : [collection] # [type] [ # parameter ]
///       the valid value for collection-type is commalist or null
///       the valid values for type is configname, class or query
///       the parameter for class is passed to the class finder dialog box.
/// 
ClassMethod GetMetaData() As %String
{
	quit ""
}

/// Returns the description of the rule type 
ClassMethod GetDescription() As %String
{
	quit ""
}

/// If return true, then the class is excluded from the new rule wizard
ClassMethod IsHidden() As %String
{
	quit 0
}

/// Returns the context class. If the return value is not null, then users can not change it
ClassMethod GetContextClass() As %String
{
	quit ""
}

/// Returns if the rule is a routing rule
ClassMethod GetIsRoutingRule() As %String
{
	quit 0
}

/// Returns if the rule input is a segmented document
ClassMethod GetIsSegmentedDoc() As %String
{
	quit 0
}

/// Returns the short display string for the constraint
/// The input data is in pArray, subscripted by the constraint-field-name
ClassMethod GetShortDisplay(pArray) As %String
{
	set tMetaData=..GetMetaData() if tMetaData="" quit ""
	set tData="",tMaxLen=100\$l(tMetaData,",")
	for i=1:1:$l(tMetaData,",") {
		set name=$p($p(tMetaData,",",i),":",1)
		if $d(pArray(name)) set tData=tData_$s(tData="":"",1:", ")_name_"="_$s($l(pArray(name))>tMaxLen:$e(pArray(name),1,tMaxLen-3)_"...",1:pArray(name))
	}
	quit tData
}

/// This method is called when the constraint type is query.
/// This method returns a comma separated list of all the possible values for a particular field
/// The list will be used to populated the combo box.
ClassMethod GetQueryData(pArray, pParam) As %String
{
	quit ""
}

/// This method is called to return a list of properties
ClassMethod GetPropertyList(pArray, pText) As %String
{
	set context = $g(pArray("%contextClass"))
	set path = pText
	if (path [ "..") quit ""
	if $e(path,*)="." set path=$e(path,1,*-1)
	set piece = $s(path="":0,1:$l(path,"."))
	for i=1:1:piece {
		if context="" quit
		set property = $p(path,".",i)
		if property = "" {
			set context = ""
		} else {
			set context = $g(pArray("%classPropertyTypeOverride",context,property),..getClassPropertyType(context,property))
		}
	}
	if context="" quit ""
	quit ..getClassPropertyList(context)
}

ClassMethod getClassPropertyType(className, propertyName) As %String
{
	&sql(SELECT Type INTO :propType
		FROM %Dictionary.CompiledProperty
		WHERE parent = :className
		AND Name = :propertyName)
	If (SQLCODE = 0) {
		Quit propType
	}
	Quit ""
}

ClassMethod getClassPropertyList(className) As %String
{
	Set propertyList = ""
	&sql(DECLARE classProperties CURSOR FOR
		SELECT p.Name, c.ClassType INTO :propName, :propClassType
		FROM %Dictionary.CompiledProperty p,
		%Dictionary.CompiledClass c
		WHERE p.parent = :className
		AND $EXTRACT(p.Name,1) <> '%'
		AND p.Private = 0
		AND p.Type = c.Name)
	&sql(OPEN classProperties)
	&sql(FETCH classProperties)
	While SQLCODE = 0 {
		Set referenceSuffix = $select(propClassType '= "datatype": ".", 1: "")
		Set propertyList = propertyList _ $LB(propName _ referenceSuffix)
		&sql(FETCH classProperties)
	}
	&sql(CLOSE classProperties)
	quit $LTS(propertyList,",")
}

/// This method is called at runtime for constraint check
/// The method is to return 1 or 0 on the output parameter pPassed
ClassMethod RuntimeConstraintCheck(ByRef pArray, pContext, Output pPassed) As %Status
{
	set pPassed=1
	quit $$$OK
}

/// Maintain backwards compatibility with user-written assist classes with the rule editor UI.
/// The rule editor no longer does any special case handling based on GetIsSegmentedDoc
/// or GetIsRoutingRule. It instead uses the schema returned by GenerateSchema().
/// This method ensures that routing rules/segmented doc rules will maintain the same
/// behavior as in the previous editor without needing to overwrite GenerateSchema()
ClassMethod GenerateSchemaCompatible() As %DynamicObject [ Final, Internal ]
{
	set tClass = $classname($this)
	while tClass '= "Ens.Rule.Assist" {
		set tClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(tClass)
		set key = ""
		do {
			set method = tClassDef.Methods.GetNext(.key)
			if method '= "" {
				return:(method.Name = "GenerateSchema") ..GenerateSchema()
			}
		} while (key '= "")
		set tClass = tClassDef.Super
	}

	if (..GetIsSegmentedDoc()) {
		return ##class(EnsLib.MsgRouter.VDocRuleAssist).GenerateSchema()
	} elseif (..GetIsRoutingRule()) {
		return ##class(EnsLib.MsgRouter.RuleAssist).GenerateSchema()
	} else {
		return ..GenerateSchema()
	}
}

/// Generates the schema rule definitions of this type are expected to follow
/// This schema is used by the Rule Editor to hide/show certain UI elements as appropriate
/// The schema determines:
/// 	- what context sensitive buttons to show when elements of the rule definition are selected
/// 	- what properties are exposed for editing
/// The schema can also constrain:
/// 	- the number of elements of a given type which are permitted in an array
ClassMethod GenerateSchema() As %DynamicObject
{
	set schema = {
		"type": "object",
		"properties":{
			"type": {
				"const": "ruleDefinition"
			},
			"description": {
				"type": "string"
			},
			"context": {
				"type": "string",
				"readOnly": false
			},
			"assistClass": {
				"type": "string"
			},
			"ruleType": {
				"type": "string",
				"readOnly": true
			},
			"ruleSets": {}
		},
		"definitions": {}
	}
	set schema.properties.context.readOnly = (..GetContextClass() '= "")
	set schema.properties.ruleSets = ..GenerateArraySchema($listbuild("ruleSet"))
	set schema.definitions = ..GenerateSchemaDefinitions()
	return schema
}

/// Used by GenerateSchema() to generate schema definitions for re-use throughout the schema
ClassMethod GenerateSchemaDefinitions() As %DynamicObject
{
	set schema = ..GenerateActionDefinitionSchemas()

	// generate non-action definitions
	set schema.valueObject = ..GenerateExpressionObjectSchema()
	set schema.conditionObject = ..GenerateExpressionObjectSchema(1)

	// generate definitions which use action definitions
	set schema.condition = ..GenerateConditionSchema(..GetValidConditionActions())
	set schema.else = ..GenerateElseSchema(..GetValidElseActions())
	set schema.ruleSet = ..GenerateRuleSetSchema(..GetValidRuleSetActions())

	return schema
}

/// Used by GenerateSchemaDefinitions to generate to definitions for subclasses of Ens.Rule.Model.action
/// By default, calls the Generate<Action>Schema() method for each action returned by GetValidActions()
ClassMethod GenerateActionDefinitionSchemas()
{
	set schema = {}
	set tValidActions = ..GetValidActions()
	set tPointer = 0
	while $listnext(tValidActions, tPointer, tValidAction) {
		do schema.%Set(tValidAction, $classmethod(,"Generate"_$ZCONVERT(tValidAction,"w")_"Schema"))
	}
	return schema
}

/// Defines the valid actions for this rule type
ClassMethod GetValidActions()
{
	return $listbuild("assign","comment","debug","return","rule","trace")
}

/// Defines the valid actions for condition objects in this rule type
/// By default, includes all valid actions defined by GetValidActions()
ClassMethod GetValidConditionActions()
{
	return ..GetValidActions()
}

/// Defines the valid actions for else objects in this rule type
/// By default, includes all valid actions defined by GetValidActions()
ClassMethod GetValidElseActions()
{
	return ..GetValidActions()
}

/// Defines the valid actions for ruleSet objects in this rule type
/// By default, includes all valid actions defined by GetValidActions()
ClassMethod GetValidRuleSetActions()
{
	return ..GetValidActions()
}

/// Generates the schema for a ruleSet objects
ClassMethod GenerateRuleSetSchema(pAllowedActions) As %DynamicObject
{
	set schema = {
		"type": "object",
		"properties": {
			"type": {
				"const": "ruleSet"
			},
			"name": {
				"type": "string"
			},
			"effectiveBegin": {
				"type": "string"
			},
			"effectiveEnd": {
				"type": "string"
			},
			"actions": {}
		}
	}
	set schema.properties.actions = ..GenerateArraySchema(pAllowedActions)
	return schema
}

/// Generates the schema for a rule objects
ClassMethod GenerateRuleSchema() As %DynamicObject
{
	set schema = {
		"type": "object",
		"properties": {
			"type": {
				"const": "rule"
			},
			"name": {
				"type": "string"
			},
			"disabled": {
				"type": "boolean"
			},
			"conditions": {},
			"else": {
				"$ref": "#/definitions/else"
			},
			"comments": {}
		},
		"if": {
			"properties": {
				"conditions": {
					"maxItems": 0
				}
			}
		},
		"then": {
			"not": { 
				"required": [ "else" ] 
			}
		}
	}
	set schema.properties.conditions = ..GenerateArraySchema($listbuild("condition"))
	set schema.properties.comments = ..GenerateArraySchema($listbuild("comment"))
	return schema
}

/// Generates the schema for a condition objects
ClassMethod GenerateConditionSchema(pAllowedActions) As %DynamicObject
{
	set schema = {
		"type": "object",
		"properties": {
			"type": {
				"const": "condition"
			},
			"if": {},
			"comments": {}
		}
	}
	set schema.properties.comments = ..GenerateArraySchema($listbuild("comment"))
	set schema.properties.if = {
		"type": "object",
		"properties": {
			"value": {
				"type": "string"
			},
			"valueObject": {
				"$ref": "#/definitions/valueObject"
			},
			"conditionObject": {
				"$ref": "#/definitions/conditionObject"
			}
		}
	}
	set schema.properties.then = {
		"type": "object",
		"properties": {
			"type": {
				"const": "then"
			},
			"actions": {}
		}
	}
	set schema.properties.then.properties.actions = ..GenerateArraySchema(pAllowedActions)

	return schema
}

/// Generates the schema for a else objects
ClassMethod GenerateElseSchema(pAllowedActions) As %DynamicObject
{
	set schema = {
		"type": "object",
		"properties": {
			"type": {
				"const": "else"
			},
			"actions": {}
		}
	}
	set schema.properties.actions = ..GenerateArraySchema(pAllowedActions)

	return schema
}

/// Generates the schema for a expression objects, defined as
/// deserialized instances of Ens.Rule.Model.expression
ClassMethod GenerateExpressionObjectSchema(pIsCondition As %Boolean = 0) As %DynamicObject
{
	set schema = {
		"type": "object",
		"oneOf": [
			{
				"properties": {
					"operator": {
						"type": "string"
					},
					"operands": {
						"type": "array",
						"items": {
							"$ref": "#/definitions/valueObject"
						}
					}
				}
			},
			{
				"type": "object",
				"properties": {
					"value": {
						"type": "string"
					}
				}
			}
		]
	}
	set schema.oneOf.%Get(0).properties.operator.enum = []
	if pIsCondition {
		do schema.oneOf.%Get(0).properties.operands.items.%Set("$ref", "#/definitions/conditionObject")
		set schema.oneOf.%Get(0).properties.operator.enum = []
		set operators = ["&&", "||"]
		set operatorIter = operators.%GetIterator()
		while operatorIter.%GetNext(.key, .val) {
			set operatorObj = {}
			set operatorObj.type = "operator"
			set operatorObj.value = val
			do schema.oneOf.%Get(0).properties.operator.enum.%Push(operatorObj)
		}
	} else {
		set operators = ["&&", "||", "+", "-", "!", "*", "/", "!=", "=", ">=", "<=", ">", "<", "&", "[", "_"]
		set operatorIter = operators.%GetIterator()
		while operatorIter.%GetNext(.key, .val) {
			set operatorObj = {}
			set operatorObj.type = "operator"
			set operatorObj.value = val
			do schema.oneOf.%Get(0).properties.operator.enum.%Push(operatorObj)
		}

		do ##class(Ens.Rule.Utilities).GetFunctionSet(.tFunctionList)
		set tKey = ""
		for {
			set tKey = $order(tFunctionList(tKey))
			quit:(tKey = "")

			set functionObj = {}

			// get function metadata
			set functionObj.type = "function"
			set functionObj.value = $listget(tFunctionList(tKey), 2)
			set functionObj.description = $$$comMemberKeyGet($listGet(tFunctionList(tKey), 1),$$$cCLASSmethod,$listGet(tFunctionList(tKey), 2),$$$cMETHdescription)

			// get parameters and organize parameter metadata
			set functionObj.parameters = []
			set parameters = $listget(tFunctionList(tKey), 3)
			set pointer = 0
			while $listNext(parameters, pointer, parameter) {
				set parameterObj = {}
				set parameterObj.name = $listGet(parameter, 1)
				set parameterObj.type = $listGet(parameter, 2)
				set:($listGet(parameter, 4) '= "") parameterObj.default = $listGet(parameter, 4)
				set parameterObj.optional = parameterObj.default '= ""
				do functionObj.parameters.%Push(parameterObj)
			}

			do schema.oneOf.%Get(0).properties.operator.enum.%Push(functionObj)
		}
	}
	return schema
}

/// Generates the schema for a assign objects
ClassMethod GenerateAssignSchema() As %DynamicObject
{
	return ..GenerateActionSchema("Ens.Rule.Model.assign")
}

/// Generates the schema for a comment objects
ClassMethod GenerateCommentSchema() As %DynamicObject
{
	return ..GenerateActionSchema("Ens.Rule.Model.comment")
}

/// Generates the schema for a debug objects
ClassMethod GenerateDebugSchema() As %DynamicObject
{
	return ..GenerateActionSchema("Ens.Rule.Model.debug")
}

/// Generates the schema for a return objects
ClassMethod GenerateReturnSchema()
{
	return ..GenerateActionSchema("Ens.Rule.Model.return")
}

/// Generates the schema for a trace objects
ClassMethod GenerateTraceSchema() As %DynamicObject
{
	return ..GenerateActionSchema("Ens.Rule.Model.trace")
}

/// Generates the definition for generic objects which extend Ens.Rule.Model.action
/// By default, writes all properties of the class to its schema
/// and adds a "valueObject" property as generated by GenerateExpressionObjSchema()
ClassMethod GenerateActionSchema(pClass As %String) As %DynamicObject
{
	set schema = {
		"type": "object"
	}
	set schema.properties = ..GenerateDefaultPropertiesSchema(pClass)
	if schema.properties.%IsDefined("value") {
		set schema.properties.valueObject = {
			"$ref": "#/definitions/valueObject"
		}
	}

	// add type information
	set schema.properties.type = {}
	set schema.properties.type.const = $piece(pClass, ".", *-0)
	return schema
}

/// Generates the schema for a generic array with element type(s) in pAllowedElements
/// Assumes that all elements of pAllowedElements are defined in the definitions
/// object of the schema
ClassMethod GenerateArraySchema(pAllowedElements) As %Status
{
	set schema = {
		"type": "array",
		"items": {}
	}

	if $listlength(pAllowedElements) = 1 {
		do schema.items.%Set("$ref", "#/definitions/"_$listget(pAllowedElements, 1))
	} elseif $listlength(pAllowedElements) > 1 {
		do schema.items.%Set("oneOf", [])
		set tPointer = 0
		while $listnext(pAllowedElements, tPointer, tAllowedElement) {
			set tElementObject = {}
			do tElementObject.%Set("$ref", "#/definitions/"_tAllowedElement)
			do schema.items.oneOf.%Push(tElementObject)
		}
	}
	return schema
}

/// Generate schema from properties of class
/// Recursively generates schema for subclasses of Ens.Rule.Model.base
ClassMethod GenerateDefaultPropertiesSchema(pClass As %String) As %DynamicObject
{
	if '$system.CLS.IsMthd(pClass, "%New") $$$ThrowStatus($$$ERROR($$$ClassDoesNotExist, pClass))

	set schema = {}
	if '$classmethod(pClass, "%Extends", "Ens.Rule.Model.base") {
		if (pClass = "%String") {
			set schema = {
				"type": "string"
			}
		} else {
			$$$ThrowStatus($$$ERROR($$$GeneralError, "Unsupported type " _ pClass))
		}
	} else {
		set tClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(pClass)
		set key = ""
		do {
			set property = tClassDef.Properties.GetNext(.key)
			if property '= "" {
				if property.Collection = "list" {
					if $classmethod(property.Type, "%Extends", "Ens.Rule.Model.base") {
						do schema.%Set(property.Name, ..GenerateArraySchema($listbuild($piece(property.Type, ".", *-0))))
					} else {
						$$$ThrowStatus($$$ERROR($$$GeneralError, "Unsupported type " _ property.Type))
					}
				} else {
					do schema.%Set(property.Name, ..GenerateDefaultPropertiesSchema(property.Type))
				}
			}
		} while (key '= "")
	}
	return schema
}

}
