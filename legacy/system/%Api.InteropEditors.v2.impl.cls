/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Interoperability Editor API for InterSystems IRIS<br/>
/// Business logic class defined by OpenAPI in %Api.InteropEditors.v2.spec<br/>
/// Updated Feb 13, 2025 16:24:38
Class %Api.InteropEditors.v2.impl Extends %Api.InteropEditors.v1.impl [ ProcedureBlock ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

/// Get the property list for this rule type.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     assistClassName, Rule type in the form of an assist class name.<br/>
///     searchProperties, Search context and key for property list<br/>
ClassMethod GetPropertyList(namespace As %String, assistClassName As %String, searchProperties As %DynamicArray) As %DynamicObject
{
   if '(##class(%Dictionary.CompiledClass).%ExistsId(assistClassName)) {
        set tSC = $$$ERROR($$$InteropAPIInvalidAssistClass, assistClassName)
        return ..%ReportRESTError(400,, ..#ExposeServerExceptions, tSC)
    }
 
    try {
        set tResponse = ##class(%DynamicArray).%New()
        set contextClassName = searchProperties.%Get("contextClassName")
        set searchKey = searchProperties.%Get("searchKey")
        set segment =  searchProperties.%Get("segment")
        set constraints = searchProperties.%Get("constraints")
        set tClassObj = []
        set tClassObj("%contextClass") = contextClassName
        set tClassObj("%assistClass") = assistClassName
        set tClassObj("segName") = segment
        set tClassObj("%segsOnly") = 0
        set tIterator = constraints.%GetIterator()
        While tIterator.%GetNext(.prop,.val) {
            Set tClassObj(prop) = val
        }
        set propertiesList = $LFS($classmethod(assistClassName, "GetPropertyList",.tClassObj,searchKey),",")
        set ptr = 0
        while $listNext(propertiesList, ptr, propertyValue) {
            do tResponse.%Push(propertyValue)
        }
        return tResponse
    } catch ex {
        return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
    }
}

/// Get the 'path' portion of the Interoperability management URL for a given namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetMgmtUrl(namespace As %String) As %DynamicObject
{
    return ##super(namespace)
}

/// Get a list of rule classes available on the server.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetRules(namespace As %String) As %DynamicObject
{
    return ##super(namespace)
}

/// Get a list of defined packages.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetPackages(namespace As %String) As %DynamicObject
{
    return ##super(namespace)
}

/// Get summaries of non-hidden classes in this namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetClassSummaries(namespace As %String) As %DynamicObject
{
    return ##super(namespace)
}

/// Get a list of rule types available on the server.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetRuleTypes(namespace As %String) As %DynamicObject
{
    return ##super(namespace)
}

/// Get a list of constraint options for this rule type.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     assistClass, Rule type, in the form of an assist class.<br/>
///     constraints, Constraints to get options for.<br/>
ClassMethod GetConstraintOptions(namespace As %String, assistClass As %String, constraints As %DynamicArray) As %DynamicObject
{
   if ('$data(constraints)) set constraints = ##class(%DynamicArray).%New()
   return ##super(namespace,assistClass,constraints)
}

/// Get the schema for this rule type.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     assistClassName, Rule type in the form of an assist class name.<br/>
ClassMethod GetRuleTypeSchema(namespace As %String, assistClassName As %String) As %DynamicObject
{
   return ##super(namespace,assistClassName)
}

/// Create a new rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
///     ruleDefinition, Definition which defines the contents of a rule class.<br/>
ClassMethod PostRule(namespace As %String, ruleClass As %String, ruleDefinition As %DynamicObject) As %DynamicObject
{
   return ##super(namespace,ruleClass,ruleDefinition)
}

/// Overwrite this rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
///     ruleDefinition, Definition which defines the contents of a rule class.<br/>
///     ignoreConflict, Overwrite this class if it exists, ignoring conflicts.<br/>
ClassMethod PutRule(namespace As %String, ruleClass As %String, ruleDefinition As %DynamicObject, ignoreConflict As %Boolean) As %DynamicObject
{
   set ignoreConflict = $GET(ignoreConflict,0)
   return ##super(namespace,ruleClass,ruleDefinition,ignoreConflict)
}

/// Get this rule class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
ClassMethod GetRule(namespace As %String, ruleClass As %String) As %DynamicObject
{
   
    // require user has read permission on a rule of this type
    set perms = ##class(%Api.InteropEditors.Utils).GetRulePerms()
    if '##class(%Api.InteropEditors.Utils).HasPermsByRuleClass(ruleClass, "R", perms) {
        return ..%ReportRESTError(403,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIInsufficientPerm))
    }
    // verify class exists
    if '##class(%Dictionary.ClassDefinition).%ExistsId(ruleClass) {
        return ..%ReportRESTError(404,, ..#ExposeServerExceptions, $$$ERROR($$$InteropAPIRuleDoesNotExist, ruleClass))
    }

    /* Source Control - explicitly make callback calls */
    set tSC = ##class(%Api.InteropEditors.Utils).CallSourceControlCallback(ruleClass,"OnBeforeLoad",.sourceControlBeforeMsgArray,.usesSourceControl)
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
        set tSC = ##class(%Api.InteropEditors.Utils).CallSourceControlCallback(ruleClass,"OnAfterLoad",.sourceControlAfterMsgArray)
        if $$$ISERR(tSC) {
            /* Any info in sourceControlBeforeMsgArray is not currently returned but user will see Source Control error */
            return ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, tSC)
        }
    }

    // remove deprecated/not applicable metadata added by LoadFromClass
    do ruleDef.%Remove("hasConstraints")
    do ruleDef.%Remove("hasSegments")
    do ruleDef.%Remove("isRoutingRule")

    // mark rule as ReadOnly if appropriate
    set ruleDef.ReadOnly = '##class(%Api.InteropEditors.Utils).HasPermsByRuleClass(ruleClass, "W", perms)

    // parse expression strings into expression objects
    for i=0:1:(ruleDef.ruleSets.%Size()-1) {
        set ruleSet = ruleDef.ruleSets.%Get(i)
        if ##class(%Api.InteropEditors.Utils).HasKey(ruleSet, "actions") {
            set tSC = ##class(%Api.InteropEditors.Utils).ExpandRuleSet(ruleSet.%Get("actions"))
            return:$$$ISERR(tSC) ..%ReportRESTError(500, tSC, ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
        }
    }
    // add sc output to ruleDef
    if $get(usesSourceControl) && ($Data(sourceControlBeforeMsgArray)||$Data(sourceControlAfterMsgArray)){
        do ##class(%Api.InteropEditors.Utils).AddSCInfoToContainer(.ruleDef,$$$scCallBackOutputProp,.sourceControlBeforeMsgArray,.sourceControlAfterMsgArray)
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
   return ##super(namespace,ruleClass)
}

/// Get the expiry of the current session
ClassMethod GetExpiry() As %DynamicObject
{
   return ##super()
}

/// Terminate CSP Session.
ClassMethod Logout() As %Stream.Object
{
   return ##super()
}

/// Get the language for this session
ClassMethod GetLanguage() As %DynamicObject
{
   return ##super()
}

/// Set the language for this session<br/>
/// The method arguments hold values for:<br/>
///     language, Language code to set for this session.<br/>
ClassMethod SetLanguage(language As %String) As %DynamicObject
{
   return ##super(language)
}

/// Get a list of permissions for the current user and namespaces they can access.
ClassMethod GetPermissions() As %DynamicObject
{
   return ##super()
}

/// Get the system mode of this instance.
ClassMethod GetSystemMode() As %DynamicObject
{
   return ##super()
}

/// Get list of input plugins.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetInputPluginsList(namespace As %String) As %DynamicObject
{
   return ##super(namespace)
}

/// Get information on this context class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     contextClass, Name of the ObjectScript class used as a context class for a rule.<br/>
ClassMethod GetContextInputs(namespace As %String, contextClass As %String) As %DynamicObject
{
   return ##super(namespace,contextClass)
}

/// Get information on this class.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     ruleClass, Name of the ObjectScript class in which this rule definition is defined.<br/>
ClassMethod GetTestingInputs(namespace As %String, ruleClass As %String) As %DynamicObject
{
    Set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(ruleClass)
    // get properties for this compiled class
    Set count = tClassDef.Properties.Count()
    set tResponse = ##class(%DynamicArray).%New()
    Try {
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
    } catch(ex) { 
        do tResponse.%Push(ex)
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
   Set propertyValues = ruleTestMessage.%Get("propertyValues")
    Set docClass = ruleTestMessage.%Get("docClass")
    If (contextClass = "EnsLib.HL7.MsgRouter.RoutingEngine") { 
        Set className = "EnsLib.HL7.Message"
    } Else { 
       Set className = docClass
    }
    Set isRoutingRule = ruleTestMessage.%Get("isRoutingRule")
    Set ruleName  = ruleTestMessage.%Get("ruleName")
    Set headerID = ruleTestMessage.%Get("headerID")
    Set docID = ruleTestMessage.%Get("docID")
    Set separators = ruleTestMessage.%Get("separators")
    Set source  = ruleTestMessage.%Get("source")
    #dim tSCOpen = $$$OK
    If ( contextSource = "Paste" ) { 
        If $classmethod(className,"%Extends","EnsLib.EDI.Document") {
            Set tData = ##class(%Stream.GlobalCharacter).%New()
            Do tData.Write(testContent)
            Do tData.Rewind()           
            If (contextClass = "EnsLib.HL7.MsgRouter.RoutingEngine") { 
                
                Set tMessageObject = $classmethod(docClass,"ImportFromLibraryStream",tData,.tSC)
                If $$$ISERR(tSC) {
                    return {
                        "Fail": "RULE_TEST_FAIL_DOC"
                    }
                }
                Set tMessageObject.DocType = docType
            } else { 
                Set pStatus = ##class(Ens.Util.Serialized.Reader).ObjectFromSerialized(.tMessageObject,tData,docClass,,.pDocProperties)
                Set tMessageObject.DocType = docType
                If $$$ISERR(pStatus) {
                    return {
                        "Fail": "RULE_TEST_FAIL_DOC"
                    }
                }
            }

        } else {

            Set tMessageObject = $classmethod(docClass,"%New","")
            #dim tIterator = propertyValues.%GetIterator()
            #dim prop, val
            While tIterator.%GetNext(.prop,.val) {
                Set $property(tMessageObject,prop)=val
            }
        }
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
    #dim tSCRuleEvaluation = ##class(%Api.InteropEditors.Utils).evaluateRule(tContextObject,ruleName,.tRuleLogJSON)
    
    Set testMessageHTML = ""
    if $IsObject(tMessageObject) { 
        Set canViewContents = $system.Security.Check("%Ens_MessageContent","USE")
        #dim tAllowedToSeeMessage As %Boolean = 0
        #dim tAuditSource ="Rule test message display"
        #dim tAuditHDrID = "N/A"

        If ( contextSource = "Header" ) {
            If canViewContents {
                Do ##class(Ens.Util.Auditing).AuditViewMessage(tAuditSource, tMsgHeader.%Id(), tMsgHeader.MessageBodyClassName, tMessageObject.%Id())
                Set tAllowedToSeeMessage = 1
            }
        } ElseIf ( contextSource = "Body" ) {
            If canViewContents {
                Do ##class(Ens.Util.Auditing).AuditViewMessage(tAuditSource, tAuditHDrID, $classname(tMessageObject), tMessageObject.%Id())
                Set tAllowedToSeeMessage = 1
            }
        } ElseIf ( contextSource = "Paste" ) {
            #; No Audit needed for user paste
            Set tAllowedToSeeMessage = 1
        } Else {
            Set encounteredErrorText = "No source of message data was specified"
            Quit
        }
        If tAllowedToSeeMessage {
            #dim tSCMessageHTML = ##class(%Api.InteropEditors.Utils).serializeMessageAsHTML(tMessageObject,.tNeedsHTMLEscaping,.tMessageHTML)
            If $$$ISOK(tSCMessageHTML)  {
                Do tMessageHTML.Rewind()
                #dim tLengthToRead
                While 'tMessageHTML.AtEnd {
                    Set tLengthToRead = ($SYSTEM.SYS.MaxLocalLength()-$Length(testMessageHTML))
                    If tLengthToRead = 0 Quit
                    Set testMessageHTML = testMessageHTML_tMessageHTML.Read(.tLengthToRead)
                }
                Set testMessageNeedsEscaping = tNeedsHTMLEscaping
            } Else {
                Set testMessageHTML = ""
            }
        }
    }
    If ( contextSource = "Paste" ) { 
        Try {
            If tMessageObject.%Oid() '= "" {
                Do ##class(%Library.Persistent).%Delete( tMessageObject.%Oid())
            }
        } Catch {}
    }

    return {
        "Success": (tRuleLogJSON),
        "Message": (testMessageHTML)
    }
}

/// Get a list of production items in rule.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetProductionItems(namespace As %String) As %DynamicObject
{
   return ##super(namespace)
}

/// Get a list of doctype names and categories for specified assist class<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     assistClassName, Rule type in the form of an assist class name.<br/>
ClassMethod GetDocTypes(namespace As %String, assistClassName As %String) As %DynamicObject
{
    #dim tSCDocCategories = ##class(%Api.InteropEditors.Utils).ServerGetQueryData("docCategory",assistClassName)
    Set docCatList = $LFS(tSCDocCategories,",")
    Set tResponse = ##class(%DynamicArray).%New()
    Set ptr=0
    WHILE $LISTNEXT(docCatList,ptr,value) {
        Set tDocItemObj = {}
        Set tDocItemObj.docCategory = value
        Set tDocItemObj.docTypes = ##class(%Api.InteropEditors.Utils).ServerGetQueryData("docTypeName",assistClassName,value)
        do tResponse.%Push(tDocItemObj)
    }
    return tResponse
}

/// Get a list of lookup tables in this namespace.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetLookupTables(namespace As %String) As %DynamicObject
{
   return ##super(namespace)
}

/// Get a list of productions.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetProductions(namespace As %String) As %DynamicObject
{
   return ##super(namespace)
}

/// Get a list of production configuration items.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     production, Get the configuration items for only this production.<br/>
///     targets, Only get the configuration items of type 'target'.<br/>
ClassMethod GetProductionConfigItems(namespace As %String, production As %String, targets As %Boolean) As %DynamicObject
{
   if ('$data(production)) set production = ""
   if ('$data(targets)) set targets = ""
   return ##super(namespace,production,targets)
}

/// Get a list of data transforms.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod GetTransforms(namespace As %String) As %DynamicObject
{
   return ##super(namespace)
}

/// Dispatch to plugin endpoint.<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     pluginPath, Path of the plugin endpoint to hit.<br/>
ClassMethod DispatchPlugin(namespace As %String, pluginPath As %String) As %Stream.Object
{
   return ##super(namespace,pluginPath)
}

/// Returns enabled true or false if Source Control Enabled for the namespace<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
ClassMethod SourceControlEnabled(namespace As %String) As %DynamicObject
{
   return ##super(namespace)
}

/// Returns Source Control Menu for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlGetMenus(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
   return ##super(namespace,sourceControlRequestBody)
}

/// Requests Source Control User Action for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlUserAction(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
   return ##super(namespace,sourceControlRequestBody)
}

/// Requests Source Control After User Action for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlAfterUserAction(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
   return ##super(namespace,sourceControlRequestBody)
}

/// Requests Source Control GetStatus for the given parameters<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     sourceControlRequestBody, The parameters for the requested Source Control function<br/>
ClassMethod SourceControlGetStatus(namespace As %String, sourceControlRequestBody As %DynamicObject) As %DynamicObject
{
   return ##super(namespace,sourceControlRequestBody)
}

/// Get list of context types<br/>
/// The method arguments hold values for:<br/>
///     namespace, InterSystems IRIS namespace this operation will be performed in.<br/>
///     contextClass, Name of the ObjectScript class used as a context class for a rule.<br/>
ClassMethod GetContextTypes(namespace As %String, contextClass As %String) As %DynamicObject
{
   Set tResponse = ##class(%DynamicArray).%New()
    Set tStatus = $$$OK
   Set tRequests = ""
    Set tParams = ""
   Set tIndex = ""
   Set tName = ""
   Try {
       Set tParams("class") = contextClass
       Do ##class(Ens.ContextSearch).SubclassOf(,,.tRequests,.tParams)
       Set tRequests(0) = contextClass

       For {
           Set tIndex = $O(tRequests(tIndex),1,tName)
           Quit:tIndex=""
          do tResponse.%Push(tName)
        }
    } Catch ex {
       return ..%ReportRESTError(500, ex.AsStatus(), ..#ExposeServerExceptions, $$$ERROR($$$InternalError))
  
    }
     return tResponse
}

}
