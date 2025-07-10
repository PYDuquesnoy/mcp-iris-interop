/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class is used to obtain the Access Token for use in 
/// Interoperability adapters.<br>
/// Subclass to implement custom call backs. <br>
Class Ens.Util.OAuth2.Handler Extends %RegisteredObject [ System = 4 ]
{

/// Method to invoke <class>%SYS.OAuth2.AccessToken</class> IsAuthorized(). <br>
/// If authorization fails call a method with name generated from pOAuth2GrantType:<br>
/// <method>OnNotAuthorizedGrantAuthCode</method> <br>
/// <method>OnNotAuthorizedGrantClientCredentials</method> <br>
/// <method>OnNotAuthorizedGrantJWTAuth</method> <br>
/// <method>OnNotAuthorizedGrantPassword</method> <br>
/// Parameters: <br>
/// <parameter>pCallerInstance - optional instance of the caller. Code needs to guard against it being not an object of the expected type <br>
/// <parameter>pOAuth2GrantType - Grant type flow requested (AuthCode,ClientCredentials or JWTAuth)  <br>
/// <parameter>pOAuth2ApplicationName - OAuth2 Client Configuration Application name <br>
/// <parameter>pOAuth2SessionId - OAuth2 session Id (different from Interoperability Message Sesssion Id) which is combined with the OAuth2 Application name to identify the Access Token source.  <br>
/// <parameter>pOAuth2Resource</parameter> - Free form string indicating resource the caller wants to access. <br>
/// <parameter>pOAuth2Scope</parameter> - Scope required. If not specified uses default given in the Auth2 Client Configuration. <br>
/// <parameter>pOAuth2AuthProperties</parameter> - Properties to be set when requesting authorization. <br>
/// pOAuth2AuthProperties may not be defined, it maybe empty string, it maybe comma delimited key=value pairs,
/// it may already be an array with (key)=value <br>
/// <parameter>pGrantTypeSpecific</parameter> - Dynamic Object containing optional Grant Type specific values for example pGrantTypeSpecific.JWTAuth.Subject. <br>
/// <parameter>pOAuth2IsAuthorized</parameter> - Output indicating if already authorised. <br>
/// <parameter>pOAuth2AccessToken</parameter> - Output of Access Token if authorized. <br>
/// <parameter>pOAuth2HostShouldRetry</parameter> - Output boolean that can be used by caller to indicate message ought to be retried if waiting 
/// on authorization. Expected to be used by Business Operations. <br>
ClassMethod OnGetAccessToken(pCallerInstance As %RegisteredObject = "", pOAuth2GrantType As %String, pOAuth2ApplicationName As %String = "", pOAuth2SessionId As %String, pOAuth2Resource As %String, ByRef pOAuth2Scope As %String, ByRef pOAuth2AuthProperties As %String, ByRef pGrantTypeSpecific As %DynamicObject, Output pOAuth2IsAuthorized As %Boolean = 0, Output pOAuth2AccessToken As %String = "", Output pOAuth2HostShouldRetry As %Boolean = 0) As %Status
{
    #dim t0=$zh
    #dim tSC = $$$OK
    #dim tSCOnNotAuthorized = $$$OK
    #dim tOAuth2IDToken, tOAUTH2ResponseProperties, tOAuth2Error, tReturnNow
    #dim tOAuth2ResponseProperties

    Set pOAuth2IsAuthorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(pOAuth2ApplicationName,.pOAuth2SessionId,.pOAuth2Scope,.pOAuth2AccessToken,.tOAuth2IDToken,.tOAuth2ResponseProperties,.tOAuth2Error)
    If pOAuth2IsAuthorized {
        If $Get(pOAuth2AccessToken)="" {
            Set tSC = $$$ERROR($$$EnsErrOAUTH2NotRetrieved,pOAuth2ApplicationName)
            Set pOAuth2HostShouldRetry = 1
            Set pOAuth2IsAuthorized = 0
        }
    } else {
        /* These may be reset to $$$OK and 0 later if authorize */
        Set tSC = $$$ERROR($$$EnsErrOAUTH2NotAuthorized,pOAuth2ApplicationName)
        Set pOAuth2HostShouldRetry = 1
    }

    If 'pOAuth2IsAuthorized {

        #dim tOAuth2AuthPropertiesArray

        /* Convert pOAuth2AuthProperties to tOAuth2AuthPropertiesArray
            pOAuth2AuthProperties may not be defined
            pOAuth2AuthProperties maybe empty string
            pOAuth2AuthProperties maybe comma delimited key=value pairs
            pOAuth2AuthProperties may already be an array with (key)=value
        */

        If $data(pOAuth2AuthProperties)>9 {
            Merge tOAuth2AuthPropertiesArray = pOAuth2AuthProperties
        } ElseIf $data(pOAuth2AuthProperties) && (pOAuth2AuthProperties["=") {
            #dim pieceNum,propertyKey,propertyValue
            For pieceNum=1:1:$Length(pOAuth2AuthProperties,",") {
                Set propertyKey=$zstrip($piece(pOAuth2AuthProperties,",",pieceNum),"<>W")
                Set propertyValue=$zstrip($piece(propertyKey,"=",2),"<>W")
                Set propertyKey=$zstrip($piece(propertyKey,"=",1),"<>W")
                If propertyKey'="" Set tOAuth2AuthPropertiesArray(propertyKey)=propertyValue
            }
        }
        /*
            Call method based on pOAuth2GrantType
                AuthCode
                ClientCredentials
                JWTAuth
                Password
                not currently supported: DeviceCode
        */
        #dim tOnNotAuthorizedGrantMethod = "OnNotAuthorizedGrant"_pOAuth2GrantType
        Set tSCOnNotAuthorized = $classmethod($this,tOnNotAuthorizedGrantMethod,pCallerInstance,pOAuth2ApplicationName,pOAuth2SessionId,pOAuth2Resource,.pOAuth2Scope,.tOAuth2AuthPropertiesArray,.pGrantTypeSpecific)
        If $$$ISERR(tSCOnNotAuthorized) {
            Set tSC = $$$ADDSC(tSCOnNotAuthorized,tSC)
        } ElseIf (pOAuth2GrantType '= "AuthCode") {
            /* try again now to see if authorized if not using workflow */
            Set pOAuth2IsAuthorized=##class(%SYS.OAuth2.AccessToken).IsAuthorized(pOAuth2ApplicationName,.pOAuth2SessionId,.pOAuth2Scope,.pOAuth2AccessToken,.tOAuth2IDToken,.tOAuth2ResponseProperties,.tOAuth2Error)
            If pOAuth2IsAuthorized {
                /* check received an access token rather than just an ID Token */
                If $Get(pOAuth2AccessToken)="" {
                    /* replace tSC of $$$ERROR($$$EnsErrOAUTH2NotAuthorized,pOAuth2ApplicationName)
                        and reset not be authorized as no access token but set retry.
                    */
                    Set tSC = $$$ERROR($$$EnsErrOAUTH2NotRetrieved,pOAuth2ApplicationName)
                    Set pOAuth2HostShouldRetry = 1
                    Set pOAuth2IsAuthorized = 0
                } Else {
                    Set tSC = $$$OK, pOAuth2HostShouldRetry = 0
                }
            }
        }
    }

    $$$catTRACE("OAuth2","OnGetAccessToken duration: "_($zh-t0))

    Return tSC
}

/// This method will generate a Workflow Request, if one is not already outstanding, to
/// request the manual authorization using the URL generated from <class>%SYS.OAuth2.Authorization</class>
/// GetAuthorizationCodeEndpoint() <br>
/// Parameters as per subset of <method>OnGetAccessToken</method> with 
/// the exception of pGrantTypeSpecific which is dynamic object with data applicable to specific grant types.
/// Default Handler is currently only passing in JWT Subject in pGrantTypeSpecific.
ClassMethod OnNotAuthorizedGrantAuthCode(pCallerInstance As %RegisteredObject, pOAuth2ApplicationName As %String, pOAuth2SessionId As %String, pOAuth2Resource As %String, ByRef pOAuth2Scope As %String, ByRef pOAuth2AuthPropertiesArray, ByRef pGrantTypeSpecific As %DynamicObject) As %Status
{
    #dim tSC = $$$OK

    #dim tSupportsCachingtOutstandingWorkFlowRequestId = 0
    #dim tRequestWorkFlowAuthorizationRequest = 1
    #dim tWarnMessage = ""

    /* Check if already sent a workflow request */
    If $ISOBJECT(pCallerInstance) {
        Try {
            #dim tOutstandingWorkFlowRequestId = pCallerInstance.%outstandingWorkFlowRequestId
            Set tSupportsCachingtOutstandingWorkFlowRequestId = 1
            If tOutstandingWorkFlowRequestId '= "" {
                #dim tSQLFindIfComplete = "SELECT TaskStatus_IsComplete AS RequestCompleted FROM ENSLIB_WORKFLOW.TASKRESPONSE WHERE TaskStatus_Request = ?"
                Try {
                    #dim tSQLFindIfCompleteRS = ##class(%SQL.Statement).%ExecDirect(,tSQLFindIfComplete,tOutstandingWorkFlowRequestId)
                    If tSQLFindIfCompleteRS.%Next() {
                        If 'tSQLFindIfCompleteRS.RequestCompleted {
                            Set tWarnMessage = $$$FormatText("Outstanding Work Flow Authorization Request %1 is not marked as completed. Not requesting again.",tOutstandingWorkFlowRequestId)
                            Set tRequestWorkFlowAuthorizationRequest = 0
                        } Else {
                            Set tWarnMessage = $$$FormatText("Outstanding Work Flow Authorization Request %1 is marked as complete. Requesting again.",tOutstandingWorkFlowRequestId)
                        }
                    } Else {
                        Set tWarnMessage = $$$FormatText("Failed to find Work Flow Authorization Request %1. Requesting again.",tOutstandingWorkFlowRequestId)
                    }
                    Set tSQLFindIfCompleteRS = $$$NULLOREF
                } Catch {
                    Set tWarnMessage = $$$FormatText("Failed to identify if outstanding Work Flow Authorization Request %1 Complete due to query error. Requesting again.",tOutstandingWorkFlowRequestId)
                }
                #; Clear cached work flow request id
                If tRequestWorkFlowAuthorizationRequest Set pCallerInstance.%outstandingWorkFlowRequestId = ""
                #; Check if same warning and clear if it is otherwise save
                If pCallerInstance.%lastOAuth2WarningText'=tWarnMessage {
                    Set pCallerInstance.%lastOAuth2WarningText = tWarnMessage
                } Else {
                    Set tWarnMessage = ""
                }
            }
            If tWarnMessage'="" {
                $$$LOGWARNING(tWarnMessage)
                Set tWarnMessage = ""
            }
       
        } Catch {
            /* Does not support  %outstandingWorkFlowRequestId */
        }
    }
    If tRequestWorkFlowAuthorizationRequest {
        /*  After Oauth response handling redirect user's browser page to WorkFlow: _DeepSee.UserPortal.Workflow.zen rather
            than redirecting to production configuration page - EnsPortal.ProductionConfig.zen
        */
        #dim appUrl = ##class(%Library.EnsembleMgr).DetermineMgmtURLForNamespace($Namespace,0)_"_DeepSee.UserPortal.Workflow.zen"
        /*
            pOAuth2AuthPropertiesArray could include
                "access_type=offline"
                "aud=mine"
                "prompt=consent"
        */
        #dim url = ##class(%SYS.OAuth2.Authorization).GetAuthorizationCodeEndpoint(pOAuth2ApplicationName,,appUrl,.pOAuth2AuthPropertiesArray,,.tSC,"form_post",pOAuth2SessionId)
        If $$$ISOK(tSC) {
            #; Create WF request
            Set tWFRequest = ##class(EnsLib.Background.Workflow.OAuth2Request).%New()
            Set tWFRequest.BackgroundProcessor = "EnsLib.Background.Workflow.Operation"

            #; WF Target Role is set in overloaded property %Command
            If $ISOBJECT(pCallerInstance) {
                Try {
                    Set tWFRequest.%Command = pCallerInstance.OAuth2AuthorizationWorkFlowRole
                } Catch { /* Will set to default */}
            }
            If tWFRequest.%Command = "" Set tWFRequest.%Command = $$$EnsWFRoleOAuth2Authorizers
            #; Not setting tWFRequest.%UserName

            Set tWFRequest.%Actions = "Completed Authorization,-Relinquish,-Save"

            Set tWFRequest.%Subject = $$$JobConfigName_" Request for access to "_pOAuth2Resource

            Set tWFRequest.%FormTemplate = "EnsLib.Background.Workflow.Template.OAuth2AuthLink.cls"
            Set tWFRequest.%FormFields = "AuthURL,Resource"
            Do tWFRequest.%FormValues.SetAt(url,"AuthURL")
            Do tWFRequest.%FormValues.SetAt(pOAuth2Resource,"Resource")
            #dim tWFRequestMessageSessionId
            Set tSC = ##class(EnsLib.Background.Service).SendBackgroundRequest(tWFRequest,,.tWFRequestMessageSessionId)

            If $$$ISOK(tSC) {
                Set tWFRequestMessageHeader = ##class(Ens.MessageHeader).%OpenId(tWFRequestMessageSessionId,0,.tSC)
                If $$$ISOK(tSC) {
                    Set tWarnMessage = $$$FormatText("Submitted Work Flow Authorization Request %1",tWFRequestMessageHeader.MessageBodyId)
                    If tSupportsCachingtOutstandingWorkFlowRequestId {
                        Set pCallerInstance.%outstandingWorkFlowRequestId = tWFRequestMessageHeader.MessageBodyId
                        Set tWFRequestMessageHeader = $$$NULLOREF
                    }
                } Else {
                    #; Error will be returned but log a warning
                    Set tWarnMessage = $$$FormatText("Failed Finding Work Flow Authorization Request for Session %1",tWFRequestMessageSessionId)
                }
            } Else {
                Set tWarnMessage = $$$FormatText("Failed to Submit Work Flow Authorization Request for resource %1.",pOAuth2Resource)
            }
            If tWarnMessage'="" {
                #dim tWarn = 1
                Try {
                    If pCallerInstance.%lastOAuth2WarningText=tWarnMessage {
                        Set tWarn = 0
                    } Else {
                        Set pCallerInstance.%lastOAuth2WarningText = tWarnMessage
                    }
                } Catch {
                    /* leave tWarn on */
                }
                If tWarn $$$LOGWARNING(tWarnMessage)
                Set tWarnMessage = ""
            }
        }
    }

    Return tSC
}

/// This calls <class>%SYS.OAuth2.Authorization</class> GetAccessTokenClient() <br>
/// Parameters as per subset of <method>OnGetAccessToken</method with 
/// the exception of pGrantTypeSpecific which is dynamic object with data applicable to specific grant types.
/// Default Handler is currently only passing in JWT Subject in pGrantTypeSpecific.
ClassMethod OnNotAuthorizedGrantClientCredentials(pCallerInstance As %RegisteredObject, pOAuth2ApplicationName As %String, pOAuth2SessionId As %String, pOAuth2Resource As %String, ByRef pOAuth2Scope As %String, ByRef pOAuth2AuthPropertiesArray, ByRef pGrantTypeSpecific As %DynamicObject) As %Status
{
    Return ##class(%SYS.OAuth2.Authorization).GetAccessTokenClient(pOAuth2ApplicationName,.pOAuth2Scope,.pOAuth2AuthPropertiesArray,.error,pOAuth2SessionId)
}

/// This calls <class>%SYS.OAuth2.Authorization</class> GetAccessTokenJWT()
/// Parameters as per subset of <method>OnGetAccessToken</method> with 
/// the exception of pGrantTypeSpecific which is dynamic object with data applicable to specific grant types.
/// Default Handler is currently only passing in JWT Subject in pGrantTypeSpecific.
ClassMethod OnNotAuthorizedGrantJWTAuth(pCallerInstance As %RegisteredObject, pOAuth2ApplicationName As %String, pOAuth2SessionId As %String, pOAuth2Resource As %String, ByRef pOAuth2Scope As %String, ByRef pOAuth2AuthPropertiesArray, ByRef pGrantTypeSpecific As %DynamicObject) As %Status
{
    #dim tSubject
    If $Data(pGrantTypeSpecific) && $IsObject(pGrantTypeSpecific) {
        Set tSubject = pGrantTypeSpecific.JWTAuth.Subject
    } Else {
        Set tSubject = $Get(pGrantTypeSpecific)
    }
    Return ##class(%SYS.OAuth2.Authorization).GetAccessTokenJWT(pOAuth2ApplicationName,tSubject,.pOAuth2Scope,.pOAuth2AuthPropertiesArray,.error,pOAuth2SessionId)
}

/// Method to generate a SessionId property for use in OAuth2.AccessToken instance. <br>
/// Limited to 50 characters and cannot use || due to use in combined index - hence replace any | with : <br>
ClassMethod GetDefaultSessionIdForRunningHostItem() As %String
{
    #dim tOauthSessionId = $$$JobConfigName_"^"_$namespace
    If $Length(tOauthSessionId)>50  Set tOauthSessionId = $E(tOauthSessionId,1,50)
    /* Combined index use so ensure no || */
    Return $tr(tOauthSessionId,"|",":")
}

/// This calls <class>%SYS.OAuth2.Authorization</class> GetAccessTokenPassword()
/// Parameters as per subset of <method>OnGetAccessToken</method> with 
/// the exception of pGrantTypeSpecific which is dynamic object with data applicable to specific grant types.
/// Default Handler is currently only passing in JWT Subject in pGrantTypeSpecific.
ClassMethod OnNotAuthorizedGrantPassword(pCallerInstance As %RegisteredObject, pOAuth2ApplicationName As %String, pOAuth2SessionId As %String, pOAuth2Resource As %String, ByRef pOAuth2Scope As %String, ByRef pOAuth2AuthPropertiesArray, ByRef pGrantTypeSpecific As %DynamicObject) As %Status
{
    // Parameter pOAuth2Resource is the user credentials (i.e. username and password) used for OAuth 2.0 authorisation
    Set credentials = ##class(Ens.Config.Credentials).%OpenId(pOAuth2Resource,,.tSC)
    Return:$$$ISERR(tSC) tSC

    Return ##class(%SYS.OAuth2.Authorization).GetAccessTokenPassword(pOAuth2ApplicationName, credentials.Username, credentials.Password, .pOAuth2Scope, .pOAuth2AuthPropertiesArray,,pOAuth2SessionId)
}

}
