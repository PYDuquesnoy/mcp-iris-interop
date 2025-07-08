/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%callout, %occErrors, %syInterop)

/// Interoperability Editor API for InterSystems IRIS<br/>
/// Business logic class defined by OpenAPI in %Api.InteropEditors.v1.spec<br/>
/// Updated Feb 13, 2025 16:24:38
Class %Api.InteropEditors.v1.impl Extends %REST.Impl [ ProcedureBlock ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

/// Overwrite %ReportRESTError for customized external error messages
ClassMethod %ReportRESTError(statusCode As %String, sc As %Status = 1, exposeServerExceptions As %Boolean = 0, externalError As %Status) As %DynamicObject
{
    do ..%SetStatusCode(statusCode)
    do ..%LogError("[%Api.InteropEditors.v1.impl:Error]","status "_statusCode_": "_$system.Status.GetErrorText(sc)_", sc="_$system.Status.GetErrorText(sc))

    set tResponse = ##class(%DynamicObject).%New()
    set tResponse.summary = $ZCONVERT($system.Status.GetOneStatusText(externalError, 1),"O","HTML") ##; client will only see top level error
    set tResponse.errors = []
    if exposeServerExceptions {
        set tServerErrorJSON = ##class(%DynamicObject).%New()
        if '$$$ISERR(##class(%CSP.REST).StatusToJSON(sc, .tServerErrorJSON)) {
            set tResponse.errors = tServerErrorJSON.errors
        }
    }
    return tResponse
}

/// Get a list of permissions for the current user and namespaces they can access.
ClassMethod GetPermissions() As %DynamicObject
{
    set tResponse = ##class(%DynamicObject).%New()
    set tResponse.Username = $Username

    // set the RuleEditor field to true if the current user has read permission on at least one type of rule
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    set tResponse.RuleEditor = ##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleType("*", "R", perms)

    // Set the UserWritePrivs array with Rule types that the user has Write access to
    set tResponse.UserWritePrivs = []
    for tType = "B","R" {
        do:(##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleType(tType, "W", perms)) tResponse.UserWritePrivs.%Push(tType)
    }

    // add list of interoperability-enabled namespaces the current user has access to
    set tResponse.Namespaces = ##class(%DynamicArray).%New()
    do ##class(%SYS.Namespace).ListAll(.namespaces)

    set tCur = $order(namespaces(""))
    while (tCur '= "") {
        // check whether the current user has read access to the namespace's underlying resource
        do ##class(%SYS.Namespace).GetNSInfo(tCur, .nsInfo, 1 /*DontConnect if Remote*/)
        if $$$ISOK($Get(nsInfo("Status"),0)) {
            set tHasResourcePerms = $case(nsInfo("Resource"), "":0, :$system.Security.Check(nsInfo("Resource"), "READ"))
            // add current namespace to list of available non-implied, interoperability-enabled namespaces
            if (($find(tCur,"^") <= 1) &&
                (##class(%Library.EnsembleMgr).IsEnsembleNamespace(tCur)) &&
                (tHasResourcePerms)) {
                do tResponse.Namespaces.%Push(tCur)
            }
        }

        set tCur = $order(namespaces(tCur)) // get next namespace
    }


    return tResponse
}

/// Get a list of rule classes available on the server.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetRules(namespace As %String) As %DynamicObject
{
    // require user has read permission on at least one type of rule
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleType("*", "R", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }

    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%PrepareClassQuery("%Dictionary.ClassDefinition","SubclassOf")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set tResult = tStatement.%Execute("Ens.Rule.Definition")
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set tResponse = ##class(%DynamicArray).%New()
    while tResult.%Next() {
        set ruleClass = tResult.%Get("Name")
        if ##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleClass(ruleClass, "R", perms) {
            do tResponse.%Push(ruleClass)
        }
    }
    return tResponse
}

/// Get a list of rule types available on the server.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetRuleTypes(namespace As %String) As %DynamicObject
{
    // do not require user has any permissions, but include ability to read and write rule types in response
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()

    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%PrepareClassQuery("%Dictionary.ClassDefinition","SubclassOf")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set tResult = tStatement.%Execute("Ens.Rule.Assist")
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set tResponse = ##class(%DynamicArray).%New()
    while (tResult.%Next()) {
        set tName = tResult.%Get("Name")
        if (tName '= "") {
            set tClass = ##class(%DynamicObject).%New()
            set tClass.name = tName
            set tClass.description = $classmethod(tName, "GetDescription")
            set tClass.contextClass = $classmethod(tName, "GetContextClass")
            set tClass.isRoutingRuleType = $classmethod(tName, "GetIsRoutingRule")
            set tClass.isHidden = $classmethod(tName, "IsHidden")
            set tClass.isReadable = ##class(%Api.InteropEditors.v1.Utils).HasPermsByAssistClass(tName, "R", perms)
            set tClass.isWritable = ##class(%Api.InteropEditors.v1.Utils).HasPermsByAssistClass(tName, "W", perms)
            do tResponse.%Push(tClass)
        }
    }
    return tResponse
}

/// Get the schema for this rule type.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     assistClassName, Rule type in the form of an assist class name.<br/>
ClassMethod GetRuleTypeSchema(namespace As %String, assistClassName As %String) As %DynamicObject
{
    // do not require any rule-specific permissions
    if '(##class(%Dictionary.CompiledClass).%ExistsId(assistClassName) && $classmethod(assistClassName, "%Extends", "Ens.Rule.Assist")) {
        set tSC = $$$ERROR($$$InteropAPIInvalidAssistClass, assistClassName)
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, tSC)
    }

    try {
        return $classmethod(assistClassName, "GenerateSchemaCompatible")
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }
}

/// Get list of input plugins.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetInputPluginsList(namespace As %String) As %DynamicObject
{
    // do not require any rule-specific permissions

    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%PrepareClassQuery("%Dictionary.ClassDefinition","SubclassOf")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set tResult = tStatement.%Execute("Ens.Rule.Extension", "%YZ")
    } catch ex {
        return ..%ReportRESTError(500, ##class(%Exception.AbstractException).AsStatus(ex), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set tResponse = ##class(%DynamicArray).%New()
    while tResult.%Next() {
        set tExtension = ##class(%DynamicObject).%New()
        set tExtension.class = tResult.%Get("Name")
        set tExtension.plugin = $parameter(tExtension.class, "PluginName")
        set tExtension.dataTypes = $parameter(tExtension.class, "DataTypes")
        do tResponse.%Push(tExtension)
    }
    return tResponse
}

/// Get information on this context class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     contextClass, Name of the ObjectScript class used as a context class for a rule.<br/>
ClassMethod GetContextInputs(namespace As %String, contextClass As %String) As %DynamicObject
{
    // require user has read permission on at least one type of rule
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleType("A", "R", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }

    // Input plugins are stored on context class (optional)
    set contextInputs = ##class(%DynamicArray).%New()
    if (contextClass '= "") {
        set tSC = ##class(%Api.InteropEditors.v1.Utils).GetInputPlugins(contextClass, .contextInputs)
        if $$$ISERR(tSC) {
            return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
        }
    }

    set tResponse = ##class(%DynamicObject).%New()
    set tResponse.inputSpecs = contextInputs
    return tResponse
}

/// Dispatch to plugin endpoint.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     pluginPath, Path of the plugin endpoint to hit.<br/>
ClassMethod DispatchPlugin(namespace As %String, pluginPath As %String) As %Stream.Object
{
    // do not require any rule-specific permissions

    set pPluginName = $Piece(pluginPath,"/",1,1)
    if pPluginName = "" {
        return ..%ReportRESTError(500,, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%PrepareClassQuery("%Dictionary.ClassDefinition","SubclassOf")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set tResult = tStatement.%Execute("Ens.Rule.Extension")
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set tResponse = ##class(%DynamicArray).%New()
    while tResult.%Next() {
        set tClassName = tResult.%Get("Name")
        set tPluginName = $Parameter(tClassName, "PluginName")
        quit:(tPluginName = pPluginName)
        set tClassName = ""
    }
    if (tClassName = "") {
        return ..%ReportRESTError(404,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIUnsupportedInputPlugin, pPluginName))
    }

    // Store the current TCP connection
    set tIO = $IO
    set tResponse=""
    try {
        // Use XDEV buffer to hold response body from extension endpoint
        set tXDEV = "|XDEV|"_+$JOB
        open tXDEV:($ZF(-6,$$$XSLTLibrary,12):"":"S":/HOSTNAME="XSLT":/IOT="UTF8":/IBU=16384:/OBU=16384)
        use tXDEV

        // Manually dispatch request to extension
        set tSC = $classmethod(tClassName, "DispatchRequest", "/"_$Piece(pluginPath, "/", 2, *), %request.Method, 1)

        // Write extension's response to response body
        // Other values (HTTP status codes, etc) will be automatically forwarded since they are stored on the %response object
        write *-3
        while (1) {
            read tOut:0
            set tResponse = tResponse_tOut
        }
    } catch ex {
        quit:(ex.Name = "<ENDOFFILE>")
        // Must use TCP connection here to correctly write error to response body
        use tIO
        close tXDEV
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }
    // Restore TCP connection and close XDEV
    use tIO
    close tXDEV

    // set the return status code to an error for unhandled exceptions
    if ($$$ISERR(tSC)) && (%response.Status < 400) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    return tResponse
}

/// Create a new rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
///     ruleDefinition, Definition which defines the contents of a rule class.<br/>
ClassMethod PostRule(namespace As %String, ruleClass As %String, ruleDefinition As %DynamicObject) As %DynamicObject
{
    // require user has write permission on a rule of this type
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.v1.Utils).HasPermsByAssistClass(ruleDefinition.%Get("assistClass"), "W", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }

    // check if classname is valid
    if '$zname(ruleClass, 4) {
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, $$$ERROR($$$ClassNameInvalid, ruleClass))
    }
    // do not overwrite with POST, use PUT instead
    if ##class(%Dictionary.ClassDefinition).%ExistsId(ruleClass) {
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIClassNameConflict, ruleClass))
    }

    /* Source Control - explicitly make callback calls */
    set enforceCanEdit = 1
    set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,"OnBeforeSave",.sourceControlBeforeMsgArray,.usesSourceControl,.sourceControlInstance,enforceCanEdit)
    if $$$ISERR(tSC) {
        /* Any info in sourceControlBeforeMsgArray is not currently returned
            but information presented to the user by 400 error may be along lines of:
            ERROR #5865: Item 'Rule.SC1.CLS' is not checked out of source control
        */
        return ..%ReportRESTError(400, tSC, ..#ExposeServerExceptions, tSC)
    } else {
        do ruleDefinition.%Remove("contextEditable")
        do ruleDefinition.%Remove("ruleType")
        do ruleDefinition.%Remove("isRoutingRule")
        set tSC = ##class(%Api.InteropEditors.v1.Utils).SaveRule(ruleClass, ruleDefinition)
        if $$$ISERR(tSC) {
            return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIUnableToSaveRuleClass, ruleClass))
        }
        do ..%SetStatusCode(201)
        if (usesSourceControl) {
            Set newRule = 1
            set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,"OnAfterSave",.sourceControlAfterMsgArray,.usesSourceControl,.sourceControlInstance,,newRule)
            if $$$ISERR(tSC) {
                if '$Data(sourceControlAfterMsgArray) {
                    set sourceControlAfterMsgArray = []
                    do sourceControlAfterMsgArray.%Push("Error returned by Source Control OnAfterSave:")
                    do sourceControlAfterMsgArray.%Push($system.Status.GetOneErrorText(tSC))
                }
            }
            // add sc output to return
            if ($Data(sourceControlBeforeMsgArray)||$Data(sourceControlAfterMsgArray)){
                do ##class(%Api.InteropEditors.v1.Utils).AddSCInfoToContainer(.response,$$$scCallBackOutputProp,.sourceControlBeforeMsgArray,.sourceControlAfterMsgArray)
                do ..%SetHeaderIfEmpty($$$HTTPHeaderSCOutput,$$$scCallBackOutputProp)
                return response
            }
        }
    }

    return ""
}

/// Overwrite this rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
///     ruleDefinition, Definition which defines the contents of a rule class.<br/>
///     ignoreConflict, Overwrite this class if it exists, ignoring conflicts.<br/>
ClassMethod PutRule(namespace As %String, ruleClass As %String, ruleDefinition As %DynamicObject, ignoreConflict As %Boolean) As %DynamicObject
{
    // require user has write permission on a rule of this type
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.v1.Utils).HasPermsByAssistClass(ruleDefinition.%Get("assistClass"), "W", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }

    if ##class(%Dictionary.ClassDefinition).%ExistsId(ruleClass) {
        // require user has write permission on the rule they want to overwrite
        if '##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleClass(ruleClass, "W", perms) {
            return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
        }

        // don't overwrite if read only
        if ##class(%Api.InteropEditors.v1.Utils).IsReadOnly(ruleClass) {
            return ..%ReportRESTError(400,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIReadOnly, ruleClass))
        }

        // only overwrite a more recent class is ignoreConflict flag is set to true
        if '($data(ignoreConflict) && ignoreConflict) {
            set ruleClassDef = ##class(%Dictionary.ClassDefinition).%OpenId(ruleClass,,.tSC)
            if $$$ISERR(tSC) {
                return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
            }
            if ##class(%Library.UTC).Compare(ruleDefinition.Timestamp, $zdatetime(ruleClassDef.TimeChanged,3,,6)) > 0 {
                return ..%ReportRESTError(400, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIRuleClassConflict, ruleClass))
            }
        }
    }

    // check if classname is valid
    if '$zname(ruleClass, 4) {
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, $$$ERROR($$$ClassNameInvalid, ruleClass))
    }

    /* Source Control - explicitly make callback calls */
    set enforceCanEdit = 1
    set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,"OnBeforeSave",.sourceControlBeforeMsgArray,.usesSourceControl,.sourceControlInstance,enforceCanEdit)
    if $$$ISERR(tSC) {
        /* Any info in sourceControlBeforeMsgArray is not currently returned
            but information presented to the user by 400 error may be along lines of:
            ERROR #5865: Item 'Rule.SC1.CLS' is not checked out of source control
        */
        return ..%ReportRESTError(400, tSC, ..#ExposeServerExceptions, tSC)
    } else {
        do ruleDefinition.%Remove("contextEditable")
        do ruleDefinition.%Remove("ruleType")
        do ruleDefinition.%Remove("isRoutingRule")
        set tSC = ##class(%Api.InteropEditors.v1.Utils).SaveRule(ruleClass, ruleDefinition)
        if $$$ISERR(tSC) {
            return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIUnableToSaveRuleClass, ruleClass))
        }
        if (usesSourceControl) {
            set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,"OnAfterSave",.sourceControlAfterMsgArray,.usesSourceControl,.sourceControlInstance)
            if $$$ISERR(tSC) {
                if '$Data(sourceControlAfterMsgArray) {
                    set sourceControlAfterMsgArray = []
                    do sourceControlAfterMsgArray.%Push("Error returned by Source Control OnAfterSave:")
                    do sourceControlAfterMsgArray.%Push($system.Status.GetOneErrorText(tSC))
                }
            }
            // add sc output to return
            if (($Data(sourceControlBeforeMsgArray)||$Data(sourceControlAfterMsgArray))) {
                do ..%SetHeaderIfEmpty($$$HTTPHeaderSCOutput,$$$scCallBackOutputProp)
                do ##class(%Api.InteropEditors.v1.Utils).AddSCInfoToContainer(.response,$$$scCallBackOutputProp,.sourceControlBeforeMsgArray,.sourceControlAfterMsgArray)
                return response
            }
        }
    }

    return ""
}

/// Get this rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
ClassMethod GetRule(namespace As %String, ruleClass As %String) As %DynamicObject
{
    // require user has read permission on a rule of this type
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleClass(ruleClass, "R", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }
    // verify class exists
    if '##class(%Dictionary.ClassDefinition).%ExistsId(ruleClass) {
        return ..%ReportRESTError(404,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIRuleDoesNotExist, ruleClass))
    }

    /* Source Control - explicitly make callback calls */
    set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,"OnBeforeLoad",.sourceControlBeforeMsgArray,.usesSourceControl)
    if $$$ISERR(tSC) {
        /* Any info in sourceControlBeforeMsgArray is not currently returned but user will see Source Control error */
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, tSC)
    }

    set tSC = ##class(Ens.Rule.Model.ruleDefinition).LoadFromClass(ruleClass, .ruleDef, 0, 0)
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIUnableToOpenRuleClass, ruleClass))
    }
    set tSC = ruleDef.%JSONExportToString(.ruleJSON)
    if $$$ISERR(tSC) {
        return $system.Status.GetErrorText(tSC)
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set ruleDef = ##class(%DynamicAbstractObject).%FromJSON(ruleJSON)
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    if $get(usesSourceControl) {
        set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,"OnAfterLoad",.sourceControlAfterMsgArray)
        if $$$ISERR(tSC) {
            /* Any info in sourceControlBeforeMsgArray is not currently returned but user will see Source Control error */
            return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, tSC)
        }
    }

    // remove deprecated/not applicable metadata added by LoadFromClass
    do ruleDef.%Remove("alias")
    do ruleDef.%Remove("hasConstraints")
    do ruleDef.%Remove("hasSegments")
    do ruleDef.%Remove("isRoutingRule")

    // mark rule as ReadOnly if appropriate
    set ruleDef.ReadOnly = '##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleClass(ruleClass, "W", perms)

    // parse expression strings into expression objects
    for i=0:1:(ruleDef.ruleSets.%Size()-1) {
        set ruleSet = ruleDef.ruleSets.%Get(i)
        if ##class(%Api.InteropEditors.v1.Utils).HasKey(ruleSet, "actions") {
            set tSC = ##class(%Api.InteropEditors.v1.Utils).ExpandRuleSet(ruleSet.%Get("actions"))
            return:$$$ISERR(tSC) ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
        }
    }
    // add sc output to ruleDef
    if $get(usesSourceControl) && ($Data(sourceControlBeforeMsgArray)||$Data(sourceControlAfterMsgArray)){
        do ##class(%Api.InteropEditors.v1.Utils).AddSCInfoToContainer(.ruleDef,$$$scCallBackOutputProp,.sourceControlBeforeMsgArray,.sourceControlAfterMsgArray)
        do ..%SetHeaderIfEmpty($$$HTTPHeaderSCOutput,$$$scCallBackOutputProp)
    }
    return ruleDef
}

/// Compile this rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
ClassMethod CompileRule(namespace As %String, ruleClass As %String) As %DynamicObject
{
    // require user has write permission on a rule of this type
    set perms = ##class(%Api.InteropEditors.v1.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.v1.Utils).HasPermsByRuleClass(ruleClass, "W", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }

    set ruleName = ruleClass

    /* Source Control 
        - callbacks handled in Compile() if %SourceControl defined 
        - no source control output captured
    */
    set tSC = ##class(%Api.InteropEditors.v1.Utils).CallSourceControlCallback(ruleClass,,,.usesSourceControl,.sourceControlInstance)
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPISourceControlError, ruleClass))
    }
    if usesSourceControl {
        new %SourceControl
        set %SourceControl = sourceControlInstance
    }
    // compile class and return any compilation errors to client
    set tSC = $system.OBJ.Compile(.ruleClass, "-d")

    if $$$ISERR(tSC) {
        // remove internal information from ensemble errors
        set errTxt = ""
        set errList = $listFromString($piece($system.Status.GetErrorText(tSC), " [", 1), "ERROR <Ens>")
        set pointer = 0
        while $listNext(errList, pointer, err) {
            set idPos = $find(err, ": ")
            if idPos > 0 {
                set errTxt = errTxt_$extract(err, idPos, *-0)
            }
        }
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPICompilationFailure, ruleName, errTxt))
    }
    return ""
}

/// Get a list of defined packages.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetPackages(namespace As %String) As %DynamicObject
{
    set tSC = ##class("%ZEN.Portal.ContextSearch").Packages(.tCaption, .tTopResults, .tResults, .tParms, "")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set tResponse = []
    set tKey = $order(tResults(""))
    while (tKey '= "") {
        do tResponse.%Push(tResults(tKey))
        set tKey = $order(tResults(tKey))
    }
    return tResponse
}

/// Get summaries of non-hidden classes in this namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetClassSummaries(namespace As %String) As %DynamicObject
{
    set tStatement = ##class(%SQL.Statement).%New()
    set tSC = tStatement.%PrepareClassQuery("%Dictionary.ClassDefinition","Summary")
    if $$$ISERR(tSC) { 
        return ..%ReportRESTError(500,, ..#ExposeServerExceptions, tSC)
    }

    set tResponse = []
    set tResult = tStatement.%Execute()
    While (tResult.%Next()) {
        if (tResult.%Get("Name") = "" || tResult.%Get("Hidden")) {
            continue
        }

        set tClassObj = {}
        set tClassObj.name = (tResult.%Get("Name"))
        set tClassObj.datatype = $number(tResult.%Get("Datatype"))
        set tClassObj.system = $number(tResult.%Get("System"))
        set tClassObj.persistent = $number(tResult.%Get("Persistent"))
        set tClassObj.serial = $number(tResult.%Get("Serial"))
        set tClassObj.abstract = $number(tResult.%Get("Abstract"))
        do tResponse.%Push(tClassObj)
    }
    return tResponse
}

/// Terminate CSP Session.
ClassMethod Logout() As %Stream.Object
{
    do %session.Logout(1)
    set %session.EndSession = 1
    return ""
}

/// Get the expiry of the current session
ClassMethod GetExpiry() As %DynamicObject
{
    // using the session resets the timeout time
    return {
        "ExpiresIn": (%session.AppTimeout)
    }
}

/// Returns enabled true or false if Source Control Enabled for the namespace<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod SourceControlEnabled(namespace As %String) As %DynamicObject
{
 /*
  result.content[0]: enabled
 */
    do ..RewriteRequestContent("ExtensionEnabled() enabled", {}, 0)

    quit ..ForwardCallToAtelierQuery(namespace)
}

/// Returns Source Control Menu for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlGetMenus(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
 /*
  parameters[0] = MenuType As %String
  parameters[1] = InternalName As %String
  parameters[2] = SelectedText As %String
  result.content[0]: id,name,type,items[{id,enabled,name,save,separator}]
 */

    do ..RewriteRequestContent("GetMenus(?,?,?)",sourceControlRequestBody)

    quit ..ForwardCallToAtelierQuery(namespace)
}

/// Requests Source Control User Action for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlUserAction(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
 /*
  parameters[0] = System As %Boolean
  parameters[1] = Action As %String
  parameters[2] = InternalName As %String
  parameters[3] = SelectedText As %String
  result.content[0]: action,target,message,reload,doc,errorText
 */

    do ..RewriteRequestContent("UserAction(?,?,?,?)",sourceControlRequestBody)

    quit ..ForwardCallToAtelierQuery(namespace)
}

/// Requests Source Control After User Action for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlAfterUserAction(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
 /*
  parameters[0] = System As %Boolean
  parameters[1] = Action As %String
  parameters[2] = InternalName As %String
  parameters[3] = Answer As %Integer
  parameters[4] = pMessage As %String
  result.content[0]: message,reload,doc,errorText
 */

    do ..RewriteRequestContent("AfterUserAction(?,?,?,?,?)",sourceControlRequestBody)

    quit ..ForwardCallToAtelierQuery(namespace)
}

/// Requests Source Control GetStatus for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlGetStatus(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
 /*
  parameters[0] = InternalNames
  result.content[0]: {name,inSourceControl,editable,isCheckedOut,checkedOutBy}
 */
    do ..RewriteRequestContent("GetStatus(?)",sourceControlRequestBody)

    quit ..ForwardCallToAtelierQuery(namespace)
}

ClassMethod RewriteRequestContent(extensionFunction As %String = "", content As %DynamicObject, includeFrom As %Boolean = 1) [ Internal ]
{
    #; check that request is valid and blank if not
    set iterator = content.%GetIterator()
    while iterator.%GetNext(.key) {
        if (key '= "parameters") {
            set %request.Content=""
            return
        }
    }
        #dim newContentStream = ##class(%CSP.CharacterStream).%New()
        set content.query = "select "_$Select(includeFrom:"* from ",1:"")_"%Atelier_v1_Utils.Extension_"_extensionFunction
        do content.%ToJSON(newContentStream)
        set %request.Content = newContentStream
}

ClassMethod ForwardCallToAtelierQuery(namespace As %String) As %String [ Internal ]
{

    #; We want output from %Api.Atelier.v1 
    set %response.IgnoreRESTOutput = 0

    #; Source Control logs placed in console[]
    do ..%SetHeaderIfEmpty($$$HTTPHeaderSCOutput,"console")

    #;  Issue the same call as if we used Forward in the URLMap
    do $classmethod("%Api.Atelier.v1","DispatchRequest","/"_namespace_"/action/query","POST",1)

    #; Return empty string so %WriteResponse has something.
    quit ""
}

/// Get the system mode of this instance.
ClassMethod GetSystemMode() As %DynamicObject
{
    return {
        "systemMode": ($system.Version.SystemMode())
    }
}

/// Get a list of lookup tables in this namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetLookupTables(namespace As %String) As %DynamicObject
{
    set lookupTables = ##class(%DynamicArray).%New()
	set table = $order(^Ens.LookupTable(""))
	while (table '= "") {
        do lookupTables.%Push(table)
		set table = $order(^Ens.LookupTable(table))
	}
	return {
        "lookupTables": (lookupTables)
    }
}

/// Get a list of productions.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetProductions(namespace As %String) As %DynamicObject
{
    set statement = ##class(%SQL.Statement).%New()
    set tSC = statement.%PrepareClassQuery("Ens.Config.Production","Extent")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set result = statement.%Execute()
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set response = ##class(%DynamicArray).%New()
    while result.%Next() {
        do response.%Push(result.%Get("ID"))
    }
    return {
        "productions": (response)
    }
}

/// Get a list of constraint options for this rule type.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     assistClass, Rule type, in the form of an assist class.<br/>
///     constraints, Constraints to get options for.<br/>
ClassMethod GetConstraintOptions(namespace As %String, assistClass As %String, constraints As %DynamicArray) As %DynamicObject
{
    // check this is a valid assist class
    if '(##class(%Dictionary.CompiledClass).%ExistsId(assistClass) && $classmethod(assistClass, "%Extends", "Ens.Rule.Assist")) {
        set tSC = $$$ERROR($$$InteropAPIInvalidAssistClass, assistClass)
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, tSC)
    }

    // format constraint for use by "GetQueryData"
    if ($data(constraints)) {
        for i=0:1:constraints.%Size()-1 {
            set constraintArray(constraints.%Get(i).name) = constraints.%Get(i).value
        }
    }

    // get constraint options based on class metadata
    set metadataList = $listFromString($classmethod(assistClass, "GetMetaData"))
    set metadataArray = []
    set pointer = 0
    while $listNext(metadataList, pointer, metadataItemString) {
        set metadataItem = $listFromString(metadataItemString, ":")
        set metadataObject = {}

        set metadataObject.name = $listGet(metadataItem, 1)
        set metadataObject.description = $listGet(metadataItem, 2)
        set typeInfo = $listFromString($listGet(metadataItem, 3), "#")
        if ($listGet(typeInfo, 1) = "commalist") {
            set metadataObject.control = "select multiple"
        } elseif ($listGet(typeInfo, 2) = "query") {
            set metadataObject.control = "select"
        } else {
            set metadataObject.control = "input"
        }

        if ($listGet(typeInfo, 2) = "query") {
            set metadataObject.options = []
            set optionsString = $listFromString($classMethod(assistClass, "GetQueryData", .constraintArray, metadataObject.name))
            set optionsPtr = 0
            while $listNext(optionsString, optionsPtr, option) {
                do metadataObject.options.%Push(option)
            }
        } elseif ($listGet(typeInfo, 2) = "configname") {
            set metadataObject.control = "select"
            set metadataObject.configItem = 1
        }
        do metadataArray.%Push(metadataObject)
    }

	return {
        "constraintOptions": (metadataArray)
    }
}

/// Get a list of production configuration items.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     production, Get the configuration items for only this production.<br/>
///     targets, Only get the configuration items of type 'target'.<br/>
ClassMethod GetProductionConfigItems(namespace As %String, production As %String, targets As %Boolean) As %DynamicObject
{
    if ('$data(production)) {
        set production = ""
    }

     set itemType = ""
    if ($data(targets) && targets) {
        set itemType = -1
    }

    set statement = ##class(%SQL.Statement).%New()
    set tSC = statement.%PrepareClassQuery("Ens.Config.Production","EnumerateConfigItems")
    if $$$ISERR(tSC) {
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set result = statement.%Execute(production, itemType)
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set configItems = []
    while result.%Next() {
        do configItems.%Push(result.%Get("ConfigName"))
    }

    return {
        "configItems": (configItems)
    }
}

/// Get a list of data transforms.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetTransforms(namespace As %String) As %DynamicObject
{
    set statement = ##class(%SQL.Statement).%New()
    set tSC = statement.%PrepareClassQuery("%Dictionary.ClassDefinition","SubclassOf")
    if $$$ISERR(tSC) { 
        return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    try {
        set result = statement.%Execute("Ens.DataTransform", "%YZ")
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }

    set transforms = []
    while (result.%Next()) {
        if (result.%Get("Name") = "") {
            continue
        }
        set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(result.%Get("Name"))
        if (classDef.Abstract || classDef.Hidden) {
            continue
        }

        do transforms.%Push(result.%Get("Name"))
    }
    return {
        "transforms": (transforms)
    }
}

/// Get the 'path' portion of the Interoperability management URL for a given namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetMgmtUrl(namespace As %String) As %DynamicObject
{
    return {
        "url": (##class(%EnsembleMgr).DetermineMgmtURLForNamespace(namespace, 0))
    }
}

/// Get the language for this session
ClassMethod GetLanguage() As %DynamicObject
{
    return {
        "language": (%session.Language)
    }
}

/// Set the language for this session<br/>
/// The method arguments hold values for:<br/>
///     language, Language code to set for this session.<br/>
ClassMethod SetLanguage(language As %String) As %DynamicObject
{
    set languages = $$GetLanguages^%occMessages("%Utility","s")
    if ($listFind(languages, language)) {
        set %session.Language = language
        return {}
    } else {
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInvalidLanguage, language))
    }
}

/// Get information on this class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
ClassMethod GetTestingInputs(namespace As %String, ruleClass As %String) As %DynamicObject
{
    Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(ruleClass)
	// get properties for this compiled slass
	Set count = tClassDef.Properties.Count()
    set tResponse = ##class(%DynamicArray).%New()
  
	For i = 1:1:count { 
        Set pdef = tClassDef.Properties.GetAt(i)  
        if $IsObject(pdef) {
            Set tControl = ""
            Set tName =pdef.Name
            Set tCaption = pdef.Parameters.GetAt("CAPTION")  Set:""=tCaption tCaption = pdef.Name
            Set tType = pdef.Type
            Set tType = $$$NormalizeClassname(tType)
            Set tClsType = $$$comClassKeyGet(tType,$$$cCLASSclasstype)
            Set tHasMaxLen = pdef.Parameters.IsDefined("MAXLEN")
            Set MAXLEN = pdef.Parameters.GetAt("MAXLEN")
            //   If pdef.Collection="" && 'pdef.Internal && 'pdef.Private && 'pdef.MultiDimensional && 'pdef.ReadOnly && 'pdef.Calculated {
            
            If pdef.Collection="" && 'pdef.Internal && 'pdef.Private && 'pdef.MultiDimensional && 'pdef.Calculated && 'pdef.ReadOnly {
                set tClassObj = {}
                set tClassObj.type = (pdef.Type)
                set tClassObj.name = (tClsType)
                Set tClassObj.caption = (tCaption)
                set tClassObj.ReadOnly = (pdef.ReadOnly)
                Set tClassObj.SequenceNumber = (pdef.SequenceNumber)
                Set tClassObj.tHasMaxLen = (tHasMaxLen)
                Set tClassObj.MAXLEN = (tHasMaxLen)
                do tResponse.%Push(tClassObj)
            }
        }
	}
    
   
    return tResponse
}

/// Run rule and return logs<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
///     ruleTestMessage, Defines test parameters for rule class<br/>
ClassMethod TestRule(namespace As %String, ruleClass As %String, ruleTestMessage As %DynamicObject) As %DynamicObject
{
    #dim tMessageObject = $$$NULLOREF
	#dim tContextObject = $$$NULLOREF
    Set contextSource = ruleTestMessage.%Get("contextSource")
    Set testContent = ruleTestMessage.%Get("HL7DocumentContent")
    Set docType = ruleTestMessage.%Get("docType")
    Set assistClass = ruleTestMessage.%Get("assistClass")
    Set contextClass = ruleTestMessage.%Get("contextClass")
    If (contextClass = "EnsLib.HL7.MsgRouter.RoutingEngine") { 
        Set className = "EnsLib.HL7.Message"
    } ElseIf (contextClass = "EnsLib.MsgRouter.VDocRoutingEngine") { 
        Set className = "EnsLib.EDI.Document"
    } Else { 
       Set className = "%Library.Persistent"
    }
    Set isRoutingRule = ruleTestMessage.%Get("isRoutingRule")
    Set ruleName  = ruleTestMessage.%Get("ruleName")
    Set headerID = ruleTestMessage.%Get("headerID")
    Set docID = ruleTestMessage.%Get("docID")
    Set separators = ruleTestMessage.%Get("separators")
    Set source  = ruleTestMessage.%Get("source")
    #dim tSCOpen = $$$OK
    If ( contextSource = "Paste" ) { 
	    Set tMessageObject = $classmethod(className,"%New","")
    	Set tMessageObject.Separators = separators
	    Set tMessageObject.DocType = docType
        Set tMessageObject.Envelope = testContent
    
    } ElseIf ( contextSource = "Body") { 
	
        Set tMessageObject=$classmethod(className,"%OpenId",docID,,.tSCOpen)
        If ('($Data(tMessageObject)#2&&$IsObject(tMessageObject)) || $$$ISERR(tSCOpen) ) {
			return {
                "Fail": "RULE_TEST_FAIL_DOC"
            }
        }
        If 'tMessageObject.%Extends(className) {
		    return {
               "Fail": "RULE_TEST_FAIL_NODOC"
            }
        }
    } ElseIf ( contextSource = "Header") {

	    #dim tSCHdrOpen = $$$OK
		#dim tMsgHeader = ##class(Ens.MessageHeader).%OpenId(headerID,,.tSCHdrOpen)
        If ('($Data(tMsgHeader)#2&&$IsObject(tMsgHeader)) || ('##class(%Dictionary.CompiledClass).%ExistsId(tMsgHeader.MessageBodyClassName)) || ('+tMsgHeader.MessageBodyId) || $$$ISERR(tSCHdrOpen) )  {
        	return {
               "Fail": "RULE_TEST_FAIL_NOHEADER"
            }
        } Else {

            Set tMessageObject = $classmethod(tMsgHeader.MessageBodyClassName,"%OpenId",tMsgHeader.MessageBodyId,,.tSCOpen)
            If ('($Data(tMessageObject)#2&&$IsObject(tMessageObject)) || $$$ISERR(tSCOpen) ) {
                return {
                    "Fail": "RULE_TEST_FAIL_DOC"
                }
            }
            If 'tMessageObject.%Extends(className) {
                return {
                    "Fail": "RULE_TEST_FAIL_NOCLASS"
                }
            }
        }
    }
	
    If isRoutingRule = 0 {

		Set tContextObject = tMessageObject

	} Else {
        #dim tSCCreateContext = $$$OK
        #dim tRuleContextClass = (contextClass)
		If $$$ISOK(tSCCreateContext) {

            Set tContextObject=##class(Ens.Host).GetShadowInstance("class ||"_tRuleContextClass,.tSCCreateContext)
            Set tContextObject.Document = tMessageObject
            Set tContextObject.MsgClass = $classname(tMessageObject)
            Set tContextObject.Source = source
            If tContextObject.%Extends("EnsLib.MsgRouter.VDocRoutingEngine") {
                Set tContextObject.DocType = tMessageObject.DocType
                Set tContextObject.DocName = tMessageObject.Name
            }
        } Else { 
             return {
                    "Fail": "RULE_TEST_FAIL_NOCONTEXT"
                }
        }
    }

    #dim tRuleLogJSON = ""
    #dim tSCRuleEvaluation = ##class(%Api.InteropEditors.v1.Utils).evaluateRule(tContextObject,ruleName,.tRuleLogJSON)
    return {
        "Success": (tRuleLogJSON)
    }
}

/// Get a list of production items in rule.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetProductionItems(namespace As %String) As %DynamicObject
{
    Set tResponse = ##class(%DynamicArray).%New()
	Set tStatus = $$$OK
	Kill pResults, pTopResults
	Set pCaption = "", tIndex = 0
	Set tClassname = "" 
    Set tProduction = "",tType =""
	Try {
		Set tIndex = $i(^||%ISC.Ens.ProdItems)
        set statement = ##class(%SQL.Statement).%New()
        set tSC = statement.%PrepareClassQuery("Ens.Config.Production","EnumerateConfigItems")
        if $$$ISERR(tSC) { 
            return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
        }
        try {
            set result = statement.%Execute(tProduction, tType)
        } catch ex {
            return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
        }
		while (result.%Next()) {
    	    Set tConfigName = result.%Get("ConfigName")
			Continue:(tConfigName = "")
			Set ^||%ISC.Ens.ProdItems(tIndex,tConfigName) = ""
		}
		If $$$ISERR(tStatus) Quit
		Set tConfigName = ""
		For {
			Set tConfigName = $order(^||%ISC.Ens.ProdItems(tIndex,tConfigName))
			Quit:(tConfigName = "")
			Set pResults($i(pResults)) = tConfigName
            set tProdItemObj = {}
            set tProdItemObj.value = tConfigName
            do tResponse.%Push(tProdItemObj)
		}
	       
	 
   } Catch ex {
	    do tResponse.%Push(ex)
	 
	}
    //	If tIndex Kill ^||%ISC.Ens.ProdItems(tIndex)
    return tResponse
}

/// Get a list of doctype names and categories for HL7 rule testing<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetDocTypes(namespace As %String) As %DynamicObject
{
    #dim tSCDocCategories = ##class(%Api.InteropEditors.v1.Utils).ServerGetQueryData("docCategory")
    Set docCatList = $LFS(tSCDocCategories,",")
    Set tResponse = ##class(%DynamicArray).%New()
    Set ptr=0
    WHILE $LISTNEXT(docCatList,ptr,value) {
        Set tDocItemObj = {}
        Set tDocItemObj.docCategory = value
        Set tDocItemObj.docTypes = ##class(%Api.InteropEditors.v1.Utils).ServerGetQueryData("docTypeName",value)
        do tResponse.%Push(tDocItemObj)
    }
    return tResponse
}

}
