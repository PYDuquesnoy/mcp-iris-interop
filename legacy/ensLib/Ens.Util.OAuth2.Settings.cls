/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This class is used to add the necessary OAuth2 property
/// settings to adapters/host items.
/// It is an abstract class and needs to be sub-classed by adapters/host items.
/// Initial implementation is to allow EMail adapters to
/// use SASL XOAUTH2
Class Ens.Util.OAuth2.Settings Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Optional - OAuth2 Client Configuration Application name to use. <br>
/// If specified, this is an indication that OAUTH2 is to be used
///  and the name is used in the Authorization and Access Token retrieval process. <br>
Property OAuth2ApplicationName As %String(MAXLEN = 128);

/// If using OAUTH2 this is the grant type flow that the OAuth2CallBackHandler will follow. <br>
/// Ability to follow the grant flow type will depend on the OAuth2CallBackHandler as well as IRIS and
/// the external OAuth2 server's support for the grant type flow. <br> 
Property OAuth2GrantType As %String(DISPLAYLIST = ",Authorization Code,Client Credentials,JWT Authorization", VALUELIST = ",AuthCode,ClientCredentials,JWTAuth") [ InitialExpression = "AuthCode" ];

/// Optional - Specify the scope to be included in the authorization request. <br>
/// If not specified the default scope specified in the OAuth2 Client Configuration Application name. <br>
Property OAuth2Scope As %String(MAXLEN = 256);

/// Optional - extra properties to included in the grant flow authorization process. <br>
/// Comma separated key value pairs such as access_type=offline,prompt=consent <br>
Property OAuth2AuthProperties As %String(MAXLEN = "") [ InitialExpression = "access_type=offline" ];

/// Optional - This is the Workflow Role to which authorization requests will be sent depending on Grant Type flow
Property OAuth2AuthorizationWorkFlowRole As %String [ InitialExpression = {$$$EnsWFRoleOAuth2Authorizers} ];

/// Optional - This is the JWT Subject when using the JWT Authorization Grant Type flow
Property OAuth2JWTSubject As %String(MAXLEN = 256);

/// If OAuth2AppName is specified this class is used to handle obtaining the access token. <br>
/// The default is Ens.Util.OAuth2.Handler which can be subclassed for access token retrieval customization. <br> 
Property OAuth2CallBackHandler As %String(MAXLEN = 64) [ InitialExpression = {..#DEFAULTOAUTH2CALLBACKHANDLER} ];

/// This is the OAuth2 session Id (different from Interoperability Message Session Id)
/// which is combined with the OAuth2 Application name to identify the Access Token source. <br>
/// The maximum length is 50 characters and if shared with other host items it is necessary to 
/// ensure the authorization is appropriate. <br>
/// Any custom value cannot include || <br>
/// If none is specified the combination of namespace,production,config name is used to create an
/// instance wide unique string. <br>
Property OAuth2SessionId As %String(MAXLEN = 50);

/// If authorization fails this is an internal record of any outstanding Work Flow request
/// to prevent repeat WF requests.
/// Restarting the Host item will lead to a new work flow request if not unauthorized.
Property %outstandingWorkFlowRequestId As %String [ Internal ];

/// Internal property used to reduce event log warning entries.
Property %lastOAuth2WarningText As %String(MAXLEN = "") [ Internal ];

/// Default OAuth2 Call Back Handler class.
Parameter DEFAULTOAUTH2CALLBACKHANDLER = "Ens.Util.OAuth2.Handler";

/// Expose the properties by default.
Parameter SETTINGS = "OAuth2ApplicationName:OAuth2,OAuth2GrantType:OAuth2,OAuth2CallBackHandler:OAuth2,OAuth2Scope:OAuth2,OAuth2AuthProperties:OAuth2,OAuth2JWTSubject:OAuth2 Grant Specific,OAuth2AuthorizationWorkFlowRole:OAuth2";

/// Use the default if not set using the method GetDefaultSessionIdForRunningHostItem()
/// in the OAuth2 Call Back Handler class.
Method OAuth2SessionIdGet() As %String
{
    If i%OAuth2SessionId = "" {
        Set i%OAuth2SessionId = $classmethod(i%OAuth2CallBackHandler,"GetDefaultSessionIdForRunningHostItem")
    }
    Return i%OAuth2SessionId
}

/// Check that the OAuth2 Call Back Handler class extends the system default OAuth2 Call Back Handler class
Method OAuth2CallBackHandlerSet(tOAuth2CallBackHandler As %String) As %Status
{
    If '$classmethod(tOAuth2CallBackHandler,"%Extends",..#DEFAULTOAUTH2CALLBACKHANDLER) {
        Return $$$ERROR($$$EnsErrOAUTH2InvalidCallbackHandler,tOAuth2CallBackHandler)
    }
    Set i%OAuth2CallBackHandler = tOAuth2CallBackHandler
    Return $$$OK
}

/// Dynamic Object containing optional Grant Type specific values for example pGrantTypeSpecific.JWTAuth.Subject. <br>
/// It is constructed from other properties. Currently OAuth2JWTSubject
Property OAuth2GrantTypeSpecific As %DynamicObject;

/// Construct Grant Type specific dynamic object.
Method OAuth2GrantTypeSpecificGet() As %String
{
    Set tOAuth2GrantTypeSpecific = {}
    If i%OAuth2GrantType = "JWTAuth" {
        Set tOAuth2GrantTypeSpecific.JWTAuth = {}
        Set tOAuth2GrantTypeSpecific.JWTAuth.Subject = i%OAuth2JWTSubject
    }
    Return tOAuth2GrantTypeSpecific
}

}
