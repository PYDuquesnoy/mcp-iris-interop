/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Adapter that receives email messages via the POP3 protocol.
Class EnsLib.EMail.InboundAdapter Extends (Ens.Util.OAuth2.Settings, Ens.InboundAdapter) [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Net.MailMessage";

/// Address of the POP3 Email Server to get mail from
Property POP3Server As %String;

/// TCP Port on the POP3 Email Server to get mail from. If left blank, the adapter will use port 110 for plain text and port 995 for SSL/TLS.
Property POP3Port As %Integer;

/// A list of strings to look for in the From: field of incoming email messages, separated by semicolons (';').<p>
/// If empty, matches every message. If not, only messages containing any of these (partial) strings AND matching other match settings (To:,Subject:) will be processed.
Property MatchFrom As %String;

/// A list of strings to look for in the To: field of email messages, separated by semicolons (';').<p>
/// If empty, matches every message. If not, only messages containing any of these (partial) strings AND matching other match settings (From:,Subject:) will be processed.
Property MatchTo As %String;

/// A list of strings to look for in the Subject: field of email messages, separated by semicolons (';').<p>
/// If empty, matches every message. If not, only messages containing any of these (partial) strings AND matching other match settings (From:,To:) will be processed.
Property MatchSubject As %String;

/// To use email with Secure Socket Layer / Transport Layer Security,
/// the SSLConfig field must contain the name of 
/// an existing SSL/TLS Configuration of the Client type. You can create one using the 
/// System Management Portal [Security Management] > [SSL/TLS Configurations] page.
/// <p>If your SSL Configuration requires you to supply a password for the local private key file, specify it in 
/// the Private key password property of the SSL/TLS Configuration.
/// <p>When you specify a value in the SSLConfig field, the normal case is that
/// inbound email will open a socket on default port 995 and use POP3 over SSL/TLS.
/// <p>The SSLConfig field also supports the special case when you want the server interaction 
/// to begin on a normal TCP socket and then switch to SSL/TLS on the same port as the 
/// normal socket. (RFC2595 provides the details.) In this case the default port is 110 for POP3. 
/// To use this convention, append '*' to your entry in the SSLConfig field; 
/// for example:<br/>MySSLItem*<br/>
Property SSLConfig As %String;

/// When using email with Secure Socket Layer / Transport Layer Security, check the server identity in the certificate matches the name of the system we are connecting to.
/// This defaults to being OFF but it is recommended to enable. <br>
/// If enabled it matches based on the rules layed out in section 3.1 of RFC 2818.<br>
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 0 ];

/// Flag to prevent deletion of main message. Default is to delete.<br>
/// Service code responsibility to handle repeated downloads.<br>
Property DeleteMessage As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "POP3Server:Basic,POP3Port:Basic,Credentials:Basic:credentialsSelector,SSLConfig:Connection:sslConfigSelector,SSLCheckServerIdentity:Connection,MatchFrom,MatchTo,MatchSubject,DeleteMessage";

Property MailServer As %Net.POP3;

/// Made this multidimensional to allow it to be NULLOREF sometimes.
Property %UIDArray [ MultiDimensional, Private ];

Property %UIDKey As %String;

Property %ILastMsg As %Integer [ InitialExpression = 0 ];

/// Array of UIDs of messages found in a single query.
Property %MsgsFound [ MultiDimensional, Private ];

Method OnInit() As %Status
{
    #; Set up POP MailServer object
    Do ..MailServerNewObject()  $$$ASSERT($IsObject(..MailServer))

    #; If there is an SSL Configuration identified, see if it also wants to use STARTTLS (look for the '*')
    Set ..SSLConfig = $ZSTRIP(..SSLConfig,"<>WC")
    If (""'=..SSLConfig) { 
        Set ..MailServer.SSLConfiguration = $S("*"=$E(..SSLConfig,*):$E(..SSLConfig,1,*-1),1:..SSLConfig)
        Set ..MailServer.UseSTARTTLS = ("*"=$E(..SSLConfig,*))
        Set ..MailServer.SSLCheckServerIdentity = ..SSLCheckServerIdentity
        $$$EnsCheckSSLConfig(..SSLConfig)
    }
    Set ..%UIDArray=$$$NULLOREF

    Quit ##super()
}

Method OnTask() As %Status
{
#define MsgTable(%msgid) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,%msgid)

    Set $ZT="Trap"
    #dim tSC=$$$OK
    #dim tCurrMsgID=""
    #dim tSCQuit,tOneUID,tOneMsgID,tUIDArray,taMsgHeaders,tFromMatch,tToMatch,i,m,tMailMessage,tSubjectMatch

    Do {
        $$$sysTRACE("..%UIDArray='"_..%UIDArray_"', ..%ILastMsg="_..%ILastMsg_", ..%UIDKey="_..%UIDKey_", ..%UIDArray.Count()="_$S($IsObject(..%UIDArray):..%UIDArray.Count(),1:0)_", ..MailServer.Connected="_..MailServer.Connected)

        #; (Re-)connect to the server if in clean state
        If '$IsObject(..%UIDArray) {
            $$$ASSERT(""=..%UIDKey&&(0=..%ILastMsg)&&'..MailServer.Connected)
            $$$sysTRACE("Connecting...")
            If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials) If '$IsObject(..%CredentialsObj) { Set tSC=$$$EnsError($$$EnsErrNoCredentials,..Credentials) Quit }
            #dim tOAuth2AccessToken = ""
            If ..OAuth2ApplicationName'="" {
                /* SASL XOAuth2 support */
                #dim tOAuth2IsAuthorized = 0
                /* Get AccessToken. Each call needed since AccessToken might expire or be revoked */
                #dim tGrantTypeSpecific As %DynamicObject = {}
                Set tSC = $classmethod(..OAuth2CallBackHandler,"OnGetAccessToken",$this, ..OAuth2GrantType, ..OAuth2ApplicationName, ..OAuth2SessionId, ..%CredentialsObj.Username, ..OAuth2Scope, ..OAuth2AuthProperties, ..OAuth2GrantTypeSpecific, .tOAuth2IsAuthorized, .tOAuth2AccessToken)
                If $$$ISERR(tSC) {
                    $$$LOGSTATUS(tSC)
                    Quit
                }
            }

            Set tSC = ..MailServer.ConnectPort(..POP3Server,..POP3Port,..%CredentialsObj.Username,..%CredentialsObj.Password,tOAuth2AccessToken)
            $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,..MailServer.Connected_"|"_$$$timeUTC_"|"_..POP3Server_":"_..POP3Port)
            Set:$$$ISOK(tSC) tSC = ..MailServer.GetMessageUIDArray("",.tUIDArray) ; get results from UIDL command
            If $$$ISERR(tSC) || '$IsObject(tUIDArray) || (0=tUIDArray.Count()) {
                $$$sysTRACE("No Messages - Disconnecting...")
                If ..MailServer.Connected { Set tSCQuit = ..MailServer.QuitAndCommit()  Set:$$$ISOK(tSC) tSC = tSCQuit }
                If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
                Quit
            } Else {
                If (0'=tUIDArray.Count()) { $$$sysTRACE("POP3 server reports "_tUIDArray.Count()_" messages in mailbox on server") }
            }
            Set ..%UIDArray=tUIDArray
            Kill ..%MsgsFound
        }
        #; Find the next one that can be processed
        For {
            Set ..%UIDKey = ..%UIDArray.Next(..%UIDKey), ..%ILastMsg=..%ILastMsg+1  Quit:""=..%UIDKey  ; done finding them
            Set tOneUID = ..%UIDArray.GetAt(..%UIDKey)  $$$ASSERT(""'=tOneUID)
            #; Get header, test for matching From,To, and/or Subject header
            Set tSC = ..MailServer.FetchMessageHeaders(..%UIDKey,.taMsgHeaders)  Quit:$$$ISERR(tSC)
            Set tOneMsgID=$G(taMsgHeaders("message-id")) If ""=tOneMsgID $$$LOGWARNING("Received message "_..%UIDKey_" with no message-id (Unable to lock or mark it errored), From: "_$G(taMsgHeaders("from"))_", Subject: "_$G(taMsgHeaders("subject")))

            #; Check for a matching message we can deal with
            $$$sysTRACE("Got msg header '"_tOneMsgID_"', test for hdrs match") ; - From: "_$G(taMsgHeaders("from"))_", To: "_$G(taMsgHeaders("to"))_", Subject: "_$G(taMsgHeaders("subject")))
            Set tFromMatch=(""=..MatchFrom) For i=1:1:$L(..MatchFrom,";") If $G(taMsgHeaders("from"))[$P(..MatchFrom,";",i) Set tFromMatch=1 Quit
            Set tToMatch=(""=..MatchTo) For i=1:1:$L(..MatchTo,";") If $G(taMsgHeaders("to"))[$P(..MatchTo,";",i) Set tToMatch=1 Quit
            Set tSubjectMatch=(""=..MatchSubject) For i=1:1:$L(..MatchSubject,";") If $G(taMsgHeaders("subject"))[$P(..MatchSubject,";",i) Set tSubjectMatch=1 Quit
            If tFromMatch && tToMatch && tSubjectMatch {
                If ""'=tOneMsgID {
                    Set ..%MsgsFound(tOneMsgID)=1
                    #; Check for previously locked or errored messages  
                    Lock +$$$MsgTable(tOneMsgID):0 Else  $$$LOGINFO("Skipping locked Message '"_tOneMsgID_"'") Continue
                    If $G($$$MsgTable(tOneMsgID),0) If $G(^(tOneMsgID,"wrn")) { Kill ^("wrn") $$$LOGWARNING("Skipping previously errored message '"_tOneMsgID_"'") } Lock -$$$MsgTable(tOneMsgID) Continue
                }
                $$$sysTRACE("Got matching msg - header '"_tOneMsgID_"', From: "_$G(taMsgHeaders("from"))_", To: "_$G(taMsgHeaders("to"))_", Subject: "_$G(taMsgHeaders("subject")))
                Set:""'=tOneMsgID $$$MsgTable(tOneMsgID)=1, ^(tOneMsgID,"wrn")=1
                Set tCurrMsgID=$S(""'=tOneMsgID:tOneMsgID,1:"x")
                Quit ; found a good one
            }
        }
        If ""=..%UIDKey || $$$ISERR(tSC) {
            #; Done with this UIDArray now; Disconnect
            $$$ASSERT($$$ISERR(tSC)||(""=tCurrMsgID && (..%ILastMsg-1=..%UIDArray.Count())))

            $$$sysTRACE("Disconnecting...")
            If ..MailServer.Connected { Set tSCQuit = ..MailServer.QuitAndCommit()  Set:$$$ISOK(tSC) tSC = tSCQuit }

            #; Remove errored UIDs from global if they no longer exist
            Set m="" For  Set m=$Order($$$MsgTable(m))  Quit:m=""  If '$G(..%MsgsFound(m),0) Kill $$$MsgTable(m) $$$sysTRACE("Removed absent message '"_m_"' from errored list")
            Kill ..%MsgsFound
            Set ..%UIDArray= $$$NULLOREF, ..%UIDKey="", ..%ILastMsg=0
            Quit
        }
        $$$ASSERT(tCurrMsgID'="")

        #; call BusinessService for processing
        Set tSC = ..MailServer.Fetch(..%ILastMsg,.tMailMessage)  Quit:$$$ISERR(tSC) ; Get full message
        $$$LOGINFO("Processing Mail Message "_..%ILastMsg_"/"_..%UIDArray.Count()_":'"_tCurrMsgID_"' From: "_tMailMessage.From_", To: "_tMailMessage.To.GetAt(1)_", Subject: "_tMailMessage.Subject)
        Set tSC = ..BusinessHost.ProcessInput(tMailMessage)  Quit:$$$ISERR(tSC)
        #; Optional Delete Message from Server
        If ..DeleteMessage {
            Set tSC = ..MailServer.DeleteMessage(..%UIDKey)  Quit:$$$ISERR(tSC)
        }
            #; Mark the Message Not Errored
            Kill:"x"'=tCurrMsgID $$$MsgTable(tCurrMsgID)

    } While 0
Exit
    Lock:""'=tCurrMsgID&&("x"'=tCurrMsgID) -$$$MsgTable(tCurrMsgID)
    $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,..MailServer.Connected_"|"_$$$timeUTC_"|"_..POP3Server_":"_..POP3Port)
    Quit tSC
Trap
    Set $ZT="",tSC=$$$EnsSystemError
    #; Disconnect if needed
    Do:..MailServer.Connected ..MailServer.QuitAndCommit()
    Goto Exit
}

Method OnTearDown() As %Status
{
    Do:..MailServer.Connected ..MailServer.QuitAndCommit()
    $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,..MailServer.Connected_"|"_$$$timeUTC_"|"_..POP3Server_":"_..POP3Port)
    Quit $$$OK
}

}
