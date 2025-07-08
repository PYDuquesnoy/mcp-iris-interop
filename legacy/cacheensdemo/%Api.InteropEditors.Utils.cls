/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

Class %Api.InteropEditors.Utils
{

/// Comments on 'when's are stored in an attribute rather than an array of elements.
/// This string acts a the delimeter for the comment attribute on each when.
Parameter WhenCommentDelimeter = "&sep;";

Parameter AllRulesRead = 1;

Parameter AllRulesWrite = 2;

Parameter BusinessRulesRead = 3;

Parameter BusinessRulesWrite = 4;

Parameter RoutingRulesRead = 5;

Parameter RoutingRulesWrite = 6;

/// Get properties and plugin metadata of an extended context class.
/// The method arguments hold values for:
///     namespace, Namespace to search for extensions in.
///     contextClassName, Context class to get properties and plugin metadata of.
ClassMethod GetInputPlugins(contextClassName As %String, ByRef plugins As %DynamicArray) As %Status
{
    // Get map of plugin data types -> extended context classes
    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%PrepareClassQuery("%Dictionary.ClassDefinition","SubclassOf")
    if $$$ISERR(tSC) {
        return tSC
    }
    try {
        set tResult = tStatement.%Execute("Ens.Rule.Extension", "%YZ")
    } catch ex {
        return ex.AsStatus()
    }
    while tResult.%Next() {
        set tName = tResult.%Get("Name")
        set dataTypes = $parameter(tName, "DataTypes")
        for i = 1:1:$L(dataTypes,",") {
            set trimmedDataType = $ZStrip($P(dataTypes,",",i),"<>W")
            set:""'=trimmedDataType dataTypeMap(trimmedDataType) = tName
        }
    }

    // Parse input properties from InputTypesJSON XData block into map of property names -> plugin types
    set tXDataObj = ##class(%Dictionary.XDataDefinition).%OpenId(contextClassName_"||InputTypesSpec",,.tSC)
     if $IsObject(tXDataObj) {
        set propTypes = ##class(%Library.DynamicObject).%FromJSON($S(tXDataObj.Data.Size:tXDataObj.Data, 1:"{}"))
    } else {
        if '$system.Status.Equals(tSC,$$$LoadObjectNotFound) {
            set tSC = $$$ERROR($$$InteropAPIInvalidClassParameterJSON, contextClassName, "InputTypesSpec", tSC)
            return tSC
        }
        set propTypes = $$$NULLOREF
    }

    &sql(DECLARE Cgcp CURSOR FOR
        SELECT Name, Type, RuntimeType, Collection INTO :propName, :propType, :propRuntimeType, :propCollection
        FROM %Dictionary.CompiledProperty
        WHERE parent = :contextClassName AND $EXTRACT(Name,1) <> '%' AND Private<>1 AND Internal<>1 AND Calculated<>1)
    &sql(OPEN Cgcp) 

    For { 
        &sql(FETCH Cgcp) 
        quit:SQLCODE
        set pluginType = $$$NULLOREF
        set:$IsObject(propTypes) pluginType = propTypes.%Get(propName)        
        set tExtensionProperty = ##class(%DynamicObject).%New()
        set tExtensionProperty.name = propName
        set tExtensionProperty.irisType = propType

        if $isObject(pluginType) {
            if $data(dataTypeMap(pluginType.type), pluginClass) {
                    set pluginName = $parameter(pluginClass, "PluginName")
            } else { 
                set (pluginClass,pluginName) = "" 
            }
            set tExtensionProperty.pluginType = pluginType.type
            set tExtensionProperty.pluginSchema = pluginType.pluginSchema
            set tExtensionProperty.displayName = pluginType.displayName
            set tExtensionProperty.pluginClass = pluginClass
            set tExtensionProperty.pluginName = pluginName
        } else {
            &sql(SELECT ClassType INTO :classType FROM %Dictionary.CompiledClass WHERE name = :propType)
            if SQLCODE < 0 {
                set tSC = $$$ERROR($$$SQLError, SQLCODE, $g(%msg))
                &sql(CLOSE Cgcp) 
                return tSC
            }
            if $case(classType, "datatype":0, "donotuse":0, "":0, :1) {
                set tExtensionProperty.pluginType = "IRISClass"
                set tExtensionProperty.pluginSchema = propType
                set tExtensionProperty.displayName = ""
                set tExtensionProperty.pluginClass = "Ens.Rule.ClassdefExtension"
                set tExtensionProperty.pluginName = "IRISClass"
            }
        }
        do plugins.%Push(tExtensionProperty) 
    } set tCode=SQLCODE,tMsg=$G(%msg) &sql(CLOSE Cgcp) set:'SQLCODE SQLCODE=tCode,%msg=tMsg

    if SQLCODE < 0 {
        set tSC = $$$ERROR($$$SQLError, SQLCODE, $g(%msg))
        return tSC
    }
    return $$$OK
}

/// Save 'ruleDefinition' into class 'ruleClass'.
/// If a class 'ruleClass' exists it will be overwritten.
ClassMethod SaveRule(ruleClass As %String, ruleDefinition As %DynamicObject) As %Status
{
    // remove/contract expression objects
    for i=0:1:(ruleDefinition.ruleSets.%Size()-1) {
        set ruleSet = ruleDefinition.ruleSets.%Get(i)
        if ..HasKey(ruleSet, "actions") {
            set tSC = ..ContractRuleSet(ruleSet.%Get("actions"))
            return:$$$ISERR(tSC) tSC
        }
    }

    // convert rule definition JSON to rule definition object
    set ruleDefObj = ##class(Ens.Rule.Model.ruleDefinition).%New()
    set tSC = ruleDefObj.%JSONImport(ruleDefinition)

    return:$$$ISERR(tSC) tSC
    set tSC = ruleDefObj.SaveAs(ruleClass)
    return tSC
}

/// Transform generated rule definition JSON to be more complete and internally consistent.
/// Recursively iterate through the actions array of a ruleSet
/// Rename each when.condition to match action.expression naming style
/// and deserialize when.comment string into when.comments array.
/// Performs inverse of ContractRuleSet.
ClassMethod ExpandRuleSet(actions As %DynamicArray) As %Status
{
    for i=0:1:(actions.%Size()-1) {
        set action = actions.%Get(i)

        if ..HasKey(action, "whens") {
            set whens = action.%Get("whens")
            for j=0:1:(whens.%Size()-1) {
                set when = whens.%Get(j)
                set when.type = "condition"
                set when.then = ##class(%DynamicObject).%New()
                set when.then.type = "then"
                if ..HasKey(when, "actions") {
                    set when.then.actions = when.%Get("actions")
                    do when.%Remove("actions")
                    set tSC = ..ExpandRuleSet(when.then.actions)
                    return:$$$ISERR(tSC) tSC
                } else {
                    set when.then.actions = ##class(%DynamicArray).%New()
                }

                if ..HasKey(when, "condition") {
                    set when.if = {}
                    set when.if.value = when.condition
                    do when.%Remove("condition")
                    do when.%Remove("conditionObject")
                }

                // comments on a when are stored as an attribute rather than an element, so all comments must be stored in a delimeted list
                if ..HasKey(when, "comment") {
                    set delimetedComments = when.%Get("comment")
                    if delimetedComments '= "" {
                        set comments = ##class(%DynamicArray).%New()
                        set commentsList = $listFromString(delimetedComments, ..#WhenCommentDelimeter)
                        set pointer = 0
                        while $listNext(commentsList, pointer, comment) {
                            set commentObj = ##class(%DynamicObject).%New()
                            set commentObj.type = "comment"
                            set commentObj.text = comment
                            do comments.%Push(commentObj)
                        }
                        set when.comments = comments
                    }
                    do when.%Remove("comment")
                }

                if ..HasKey(action, "otherwise") {
                    if ..HasKey(action.%Get("otherwise"), "actions") {
                        set tSC = ..ExpandRuleSet(action.otherwise.actions)
                        return:$$$ISERR(tSC) tSC
                    } else {
                        set action.otherwise.actions = []
                    }

                    // rename otherwise the else
                    set action.else = action.%Get("otherwise")
                    do action.%Remove("otherwise")
                    set action.%Get("else").type = "else"
                }
            }
            // rename whens to conditions
            set action.conditions = action.%Get("whens")
            do action.%Remove("whens")
        }

        if ..HasKey(action, "otherwise") {
            set otherwise = action.%Get("otherwise")
            if ..HasKey(otherwise, "actions") {
                set tSC = ..ExpandRuleSet(otherwise.%Get("actions"))
                return:$$$ISERR(tSC) tSC
            }
        }
    }
    return $$$OK
}

/// Transform provided rule definition JSON to match generated rule definition structure.
/// Recursively iterate through the actions array of a ruleSet.
/// Remove each action.expression.valueObject and move each action.expression.value to action.value.
/// Rename each when.expression.value to when.condition and when.expression.valueObject to when.conditionObject and 
/// deserialize when.comments array into delimeted when.comment string.
/// Performs inverse of ExpandRuleSet.
ClassMethod ContractRuleSet(actions As %DynamicArray) As %Status
{
    for i=0:1:(actions.%Size()-1) {
        set action = actions.%Get(i)
        do action.%Remove("valueObject")

        if ..HasKey(action, "conditions") {
            set whens = action.%Get("conditions")
            for j=0:1:(whens.%Size()-1) {
                set when = whens.%Get(j)
                set when.type = "when"
                if ..HasKey(when, "then") {
                    set then = when.%Get("then")
                    if ..HasKey(when, "then") {
                        set tSC = ..ContractRuleSet(then.%Get("actions"))
                    }
                    return:$$$ISERR(tSC) tSC
                    set when.actions = when.then.actions
                    do when.%Remove("then")
                }

                if ..HasKey(when, "if") {
                    if ..HasKey(when.%Get("if"), "value") {
                        set when.condition =  when.%Get("if").%Get("value")
                    }
                    do when.%Remove("if")
                }

                // comments on a when are stored as an attribute rather than an element
                //  so all comments must be stored in a delimeted list
                //  and when.comment should be an empty string if no comments are present
                set when.comment = ""
                if ..HasKey(when, "comments") {
                    set comments = when.%Get("comments")
                    for k=0:1:(comments.%Size()-1) {
                        set when.comment = when.comment_comments.%Get(k).text
                        if k '= (comments.%Size()-1) {
                            set when.comment = when.comment_..#WhenCommentDelimeter
                        }
                    }
                    do when.%Remove("comments")
                }
            }
            set action.whens = whens
            do action.%Remove("conditions")
        }

        if ..HasKey(action, "else") {
            set otherwise = action.%Get("else")
            if ..HasKey(otherwise, "actions") {
                set tSC = ..ContractRuleSet(otherwise.%Get("actions"))
                return:$$$ISERR(tSC) tSC
            }
            set action.otherwise = action.%Get("else")
            set action.otherwise.type = "otherwise"
            do action.%Remove("else")
        }
    }
    return $$$OK
}

/// Check if this 'ruleClass' is read only for this user
/// Class will be considered read only if the database underlying the namespace this rule is in is read only
ClassMethod IsReadOnly(ruleClass As %String) As %Boolean
{
    set normalizedName = $$NormalizeClassname^%occName(ruleClass)
    return $$ClassFromRODatabase^%SYS.SECURITY(normalizedName, $namespace)
}

/// Get permissions the current user has on rules. 
/// Permissions are returned in a bitstring with the following mapping:<br/>
///     1: %Ens_Rules Read<br/>
///     2: %Ens_Rules Write<br/>
///     3: %Ens_BusinessRules Read<br/>
///     4: %Ens_BusinessRules Write<br/>
///     5: %Ens_RoutingRules Read<br/>
///     6: %Ens_RoutingRules Write
ClassMethod GetRulePerms() As %Binary
{
    set $bit(perms, ..#AllRulesRead)        = $system.Security.Check("%Ens_Rules", "READ")  || $system.Security.Check("%Ens_Code", "READ")
    set $bit(perms, ..#AllRulesWrite)       = $system.Security.Check("%Ens_Rules", "WRITE") || $system.Security.Check("%Ens_Code", "WRITE")
    set $bit(perms, ..#BusinessRulesRead)   = $bit(perms, ..#AllRulesRead)  || $system.Security.Check("%Ens_BusinessRules", "READ")
    set $bit(perms, ..#BusinessRulesWrite)  = $bit(perms, ..#AllRulesWrite) || $system.Security.Check("%Ens_BusinessRules", "WRITE")
    set $bit(perms, ..#RoutingRulesRead)    = $bit(perms, ..#AllRulesRead)  || $system.Security.Check("%Ens_RoutingRules", "READ")
    set $bit(perms, ..#RoutingRulesWrite)   = $bit(perms, ..#AllRulesWrite) || $system.Security.Check("%Ens_RoutingRules", "WRITE")
    return perms
}

/// Check if the current user has specified permissions on this rule class.
/// Input 'permString' defines what permissions to check: valid values are "R", "W", and "RW". 
/// Input 'perms' defines the permissions the current user has on rules:
/// expected format is a bitstring as returned by <METHOD>GetRulePerms</METHOD>.
ClassMethod HasPermsByRuleClass(ruleClass As %String, permStr As %String, perms As %Binary)
{
    try {
        set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(ruleClass)
        if classDef {
            set paramList = classDef.Parameters
            for i=1:1:classDef.Parameters.Count() {
                set param  = classDef.Parameters.GetAt(i)
                if param.Name = "RuleAssistClass" {
                    return ..HasPermsByAssistClass(param.Default, permStr, perms)
                }
            }
        }
    } catch {
    }
    // require user has access to all rules if rule type is indeterminate
    return ..HasPermsByRuleType("A", permStr, perms)
}

/// Check if the current user has specified permissions on rules that use this assist class.
/// Input 'permString' defines what permissions to check: valid values are "R", "W", and "RW". 
/// Input 'perms' defines the permissions the current user has on rules:
/// expected format is a bitstring as returned by <METHOD>GetRulePerms</METHOD>.
ClassMethod HasPermsByAssistClass(assistClass As %String, permStr As %String, perms As %Binary) As %Boolean
{
    try {
        if $classmethod(assistClass, "GetIsRoutingRule") {
            return ..HasPermsByRuleType("R", permStr, perms)
        } else {
            return ..HasPermsByRuleType("B", permStr, perms)
        }
    } catch {
        // if rule type is undetermined, require user to have access to all rule types
        return ..HasPermsByRuleType("A", permStr, perms)
    }
}

/// Check if the current user has specified permissions on all rules in 'ruleTypes' input:
/// valid values are "B" (Business Rules), "R" (Routing Rules), "A" (All Rules), and "*" (Any Rules).
/// Input 'permString' defines what permissions to check: valid values are "R", "W", and "RW". 
/// Input 'perms' defines the permissions the current user has on rules:
/// expected format is a bitstring as returned by <METHOD>GetRulePerms</METHOD>.
ClassMethod HasPermsByRuleType(ruleTypes As %String, permStr As %String, perms As %Binary) As %Boolean [ CodeMode = expression ]
{
('$find(permStr, "R")
    || ($find(ruleTypes, "*")
        && ($bit(perms, ..#AllRulesRead)
            || $bit(perms, ..#BusinessRulesRead)
            || $bit(perms, ..#RoutingRulesRead)))
    || ($find(ruleTypes, "A")
        && ($bit(perms, ..#AllRulesRead)
            || ($bit(perms, ..#BusinessRulesRead)
            &&  $bit(perms, ..#RoutingRulesRead))))
    || ($find(ruleTypes, "B") && $bit(perms, ..#BusinessRulesRead))
    || ($find(ruleTypes, "R") && $bit(perms, ..#RoutingRulesRead)))
&&
('$find(permStr, "W")
    || ($find(ruleTypes, "*")
        && ($bit(perms, ..#AllRulesWrite)
            || $bit(perms, ..#BusinessRulesWrite)
            || $bit(perms, ..#RoutingRulesWrite)))
    || ($find(ruleTypes, "A")
        && ($bit(perms, ..#AllRulesWrite)
            || ($bit(perms, ..#BusinessRulesWrite)
            &&  $bit(perms, ..#RoutingRulesWrite))))
    || ($find(ruleTypes, "B") && $bit(perms, ..#BusinessRulesWrite))
    || ($find(ruleTypes, "R") && $bit(perms, ..#RoutingRulesWrite)))
}

/// Check if the given 'class' is a subclass of 'superClass':
/// if class is guaranteed to be compiled use %Extends instead.
ClassMethod IsSubClass(class As %String, superClass As %String) As %Integer
{
    set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(class)
    if classDef {
        set superList = $ListFromString(classDef.Super, ",")
        if $listFind(superList, superClass) {
            return 1
        }

        set pointer = 0
        while $ListNext(superList, pointer, super) {
            if ..IsSubClass(super, superClass) {
                return 1
            }
        }
    }
    return 0
}

/// Check if 'parent' has key 'key'
ClassMethod HasKey(parent As %DynamicObject, key As %String) As %Integer
{
    try {
        if (parent.%GetTypeOf(key) '= "unassigned") {
            return 1
        } else {
            return 0
        }
    } catch {
        return 0
    }
}

/// Invoke request Source Control callback as appropriate
ClassMethod CallSourceControlCallback(className As %String, callback As %String = "", Output serverOutput As %DynamicArray, Output usesSourceControl As %Boolean, Output sourceControlInstance As %Studio.SourceControl.Base, enforceCanEdit As %Boolean = 0, wasNewCode As %Boolean = 0) As %Status [ Internal ]
{

    set tSC = $$$OK
    try {

        #; Capture output
        set tSC=##class(%Atelier.v1.Utils.General).BeginCaptureOutput(.tCookie)

        #; Use this api since does not enforce %Development and support OnPortalCreate callback
        set tSC = ##class(%CSP.Portal.SourceControl.Base).CreateSourceControl(.sourceControlInstance,.usesSourceControl,.username)
        if 'usesSourceControl || $$$ISERR(tSC) || (callback="") || '$match(callback,"OnBeforeLoad|OnAfterLoad|OnBeforeSave|OnAfterSave") Quit

        set internalClassName = ..GetInternalName(className)
        #; Quit if the Source Control system has it marked as read only
        if $$$ISOK(tSC) && enforceCanEdit {
            new %SourceControl
            set %SourceControl = sourceControlInstance
            set tSC = ##class(%Api.Atelier.v1).CheckSourceControlEdit(internalClassName)
            if $$$ISERR(tSC) Quit
        }

        if $$$ISOK(tSC) {
            set tSC = $method(sourceControlInstance,callback,internalClassName)
        }

        if $$$ISOK(tSC) && wasNewCode {
            #; Adapted from %Atelier.v1 code
            set extensionContent = []
            #; User has created a new class and saved it (successfully) for the first time.
            #; Fire both "User has created a new document" and
            #; "User has saved a new document for the first time"
            for actionName = 1,7 {
                set tSC = ##class(%Atelier.v1.Utils.Extension).UserActionExecute(.extensionItem,1,actionName,internalClassName,"")
                if $$$ISERR(tSC) quit
                if $IsObject(extensionItem) && extensionItem.%IsDefined("message") {
                    do extensionContent.%Push(extensionItem.message)
                }
            }
        }

    } catch e {
        set tSC = e.AsStatus()
    }

    #; MUST close the redirect whatever happens
    if $data(tCookie) Do ##class(%Atelier.v1.Utils.General).EndCaptureOutput(tCookie,.serverOutput)

    if $data(extensionContent) {
        set iterator = extensionContent.%GetIterator()
        while iterator.%GetNext(.line,.text) {do serverOutput.%Push(text)}
    }

    return tSC
}

/// Return the internal name of the rule.
ClassMethod GetInternalName(className) As %String [ Internal ]
{
    Quit $select(className = "": "", 1: $$$NormalizeClassname(className)_".CLS")
}

ClassMethod AddSCInfoToContainer(ByRef container As %DynamicObject, scProperty, msgArrays...) [ Internal ]
{
    set combinedArray =  msgArrays(msgArrays)
    for msgArrayNum = (msgArrays-1):-1:1 {
      set iterator = msgArrays(msgArrayNum).%GetIterator()
      while iterator.%GetNext(.line,.text) {do combinedArray.%Push(text)}
    }
    if '$data(container) set container = {}
    do container.%Set(scProperty,combinedArray)
}

/// Given a context object evaluate the rule and create result output as JSON
ClassMethod evaluateRule(pContext As %RegisteredObject, pRuleName As %String, Output pRuleLogData As %String = "", pDebugFlags As %String = "crd", pSelectMode As %Integer = 2) As %Status
{
    #; remove data from previous execution
    kill pRuleLogData
    #; use a negative session id
	Set tSessionId = -$JOB
	Set tReturnValue = ""
	Set tReason = ""
	Set tSCRuleStatus = $$$OK
	#dim ex As %Exception.AbstractException
    Set pRuleLogData = ""
	Try {
		/*	Any error return status will only be reported if no rule log
			since the rule log will contain the error.
		*/
		#dim tSCRuleEvaluate= ##class(Ens.Rule.Definition).EvaluateRules(pRuleName,tSessionId,pContext,"",.tReturnValue,.tReason,pDebugFlags)
		#; Get rule log output.
		Set tSQL = "SELECT TOP 1 ID,TimeExecuted,RuleName,RuleSet,EffectiveBegin,EffectiveEnd,Reason,ReturnValue,IsError,ErrorMsg,DebugId FROM ENS_RULE.LOG WHERE SESSIONID = ? ORDER BY ID DESC"
		#; Specify display mode
		#dim tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode=pSelectMode
		#dim tRS =  ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL,tSessionId)

		If 'tRS.%Next() {
			Set tSCRuleStatus =$$$ADDSC($$$ERROR("Failed to open rule log"),tSCRuleEvaluate)
			Quit
		}

		Set tRuleLogJSONObj ={}
		Set tID = tRS.ID
		Do tRuleLogJSONObj.%Set("ID",tID)
		Do tRuleLogJSONObj.%Set("TimeExecuted",tRS.TimeExecuted)
		Do tRuleLogJSONObj.%Set("RuleName",tRS.RuleName)
		Do tRuleLogJSONObj.%Set("RuleSet",tRS.RuleSet)
		Do tRuleLogJSONObj.%Set("EffectiveBegin",tRS.EffectiveBegin)
		Do tRuleLogJSONObj.%Set("EffectiveEnd",tRS.EffectiveEnd)
		Do tRuleLogJSONObj.%Set("Reason",tRS.Reason)
		Do tRuleLogJSONObj.%Set("ReturnValue",tRS.ReturnValue)
		Do tRuleLogJSONObj.%Set("IsError",tRS.IsError)
		Do tRuleLogJSONObj.%Set("ErrorMsg",tRS.ErrorMsg)

		Set tDebugId = tRS.DebugId
		If (tDebugId '= "") && ##class(Ens.Rule.DebugLog).DebugIdExists(tDebugId) {

			Set tRuleLogJSONObj.DebugLog = []
			#dim tLogTypes
			Set tLogTypes("d") = "Debug"
			Set tLogTypes("c") = "Condition"


			Set tStatement = ##class(%SQL.Statement).%New()
			Set tStatement.%SelectMode=pSelectMode
			Set tDebugRS = ##class(%SQL.Statement).%ExecDirect(.tStatement,"SELECT LogType,Source,Message,IsOtherwise FROM Ens_Rule.DebugLog WHERE DebugId = ? ORDER BY ID ASC",tDebugId)
			#dim tDebugLogEntry
			While tDebugRS.%Next(.tSCRuleStatus) {

				Set tDebugLogEntry = {}
				Set tDebugLogEntry.Type = $Get(tLogTypes(tDebugRS.LogType))
				Set tDebugLogEntry.Source = tDebugRS.Source
				Set tDebugLogEntry.IsOtherwise = tDebugRS.IsOtherwise
				Set tDebugLogEntry.Message = tDebugRS.Message
				Do tRuleLogJSONObj.DebugLog.%Push(tDebugLogEntry)
			}
        }

		Set pRuleLogData = tRuleLogJSONObj.%ToJSON()

		#; Delete rule log
		Do ##class(Ens.Rule.Log).%DeleteId(tID)

	} Catch ex {

		Set tSCRuleStatus = ex.AsStatus()

	}

	Quit tSCRuleStatus
}

/// Internal server side method to retrieve list of Schema categories or structures.
/// This is only called if the context is EnsLib.HL7.Message and hence EnsLib.HL7.MsgRouter.RuleAssist
/// will exist in this namespace.
ClassMethod ServerGetQueryData(pParam As %String = "", assistClassName As %String = "", pValue As %String = "") As %String [ Internal, ZenMethod ]
{
     #; #dim tArray
    If (pParam'="docCategory") && (pParam'="docTypeName") Return ""
    If ( assistClassName="") { 
        Set assistClassName =  "EnsLib.HL7.MsgRouter.RuleAssist"
    } Elseif ( assistClassName="EnsLib.MsgRouter.VDocRuleAssist" ) {
        Set tArray("msgClass") = "EnsLib.EDI.X12.Document"
     } Elseif (  assistClassName="EnsLib.MsgRouter.VDocRuleAssistCompatible" ) {
        Set tArray("msgClass") = "EnsLib.EDI.X12.Document"
    } Elseif (  assistClassName="EnsLib.EDI.MsgRouter.SegmentedRuleAssist" ) {
        Set tArray("msgClass") = "EnsLib.EDI.X12.Document"
    } Elseif ( assistClassName="EnsLib.HL7.MsgRouter.RuleAssistCompatible" ) {
        Set assistClassName =  "EnsLib.HL7.MsgRouter.RuleAssist"
   }
    
    If (pParam="docTypeName") Set tArray("docCategory") = pValue
       if (##class(%Dictionary.CompiledClass).%ExistsId(assistClassName) && $classmethod(assistClassName, "%Extends", "Ens.Rule.Assist")) {
            Try {
                #dim queryData = $classmethod(assistClassName,"GetQueryData",.tArray,pParam)
            } Catch {Set queryData = ""}
       }
    Return queryData
}

/// Given an object create an HTML serialization of the object.
ClassMethod serializeMessageAsHTML(pMessageObject As %RegisteredObject, Output pNeedsHTMLEscaping As %Boolean = 1, Output tXMLStream As %Stream.TmpCharacter) As %Status
{
    Set tSCRuleStatus = $$$OK
    Set tXMLStream = ##class(%Stream.TmpCharacter).%New()
    If pMessageObject.%Extends("EnsLib.EDI.Document") {

        Try {

            If pMessageObject.%Extends("EnsLib.HL7.Message") {
                Set pNeedsHTMLEscaping = 0
                Set tSCRuleStatus=pMessageObject.OutputToLibraryStream(tXMLStream,,,"EnsLib.HL7.Util.FormatHTMLv2Zen")
            } ElseIf pMessageObject.%Extends("EnsLib.EDI.X12.Document") {
                Set pNeedsHTMLEscaping = 0
                Set tSCRuleStatus=pMessageObject.OutputToLibraryStream(tXMLStream,,$S(pMessageObject.useValSchema:"EnsLib.EDI.X12.Util.FormatValHTML",1:"EnsLib.EDI.X12.Util.FormatHTML"))
            } ElseIf pMessageObject.%Extends("EnsLib.EDI.ASTM.Document") {
                Set pNeedsHTMLEscaping = 0
                Set tSCRuleStatus=pMessageObject.OutputToLibraryStream(tXMLStream,,,"EnsLib.EDI.ASTM.Util.FormatHTML")
            } ElseIf pMessageObject.%Extends("EnsLib.EDI.EDIFACT.Document") {
                Set pNeedsHTMLEscaping = 0
                Set tSCRuleStatus=pMessageObject.OutputToLibraryStream(tXMLStream,,"EnsLib.EDI.EDIFACT.Util.FormatHTML")
            } ElseIf pMessageObject.%Extends("EnsLib.EDI.XML.Document") {
                Set tSCRuleStatus=pMessageObject.OutputToLibraryStream(tXMLStream,"wt")
            } Else {
                Do tXMLStream.Write("Message format not supported")
            }

        } Catch {

            Set tSCRuleStatus=$$$ERROR("Failed to retrieve message")

        }

    } ElseIf pMessageObject.%Extends("%XML.Adaptor") {

        Try {

            Set tWriter=##class(%XML.Writer).%New()
            Set tWriter.Indent=1
            Set tSCRuleStatus=tWriter.OutputToStream(tXMLStream)
            Set:$$$ISOK(tSCRuleStatus) tSCRuleStatus=tWriter.RootObject(pMessageObject)

        } Catch {
            Set tSCRuleStatus=$$$ERROR("Failed to retrieve message")
        }

    } Else {

        Do tXMLStream.Clear()
        Do tXMLStream.Write("Message format not supported")

    }

    If $$$ISERR(tSCRuleStatus) {
        Do tXMLStream.Clear()
    }
    If $IsObject(tXMLStream) {
        Do tXMLStream.Rewind()
    }
    
    Quit tSCRuleStatus
}

}
