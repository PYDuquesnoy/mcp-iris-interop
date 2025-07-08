/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The Gateway Manager class defines an API used to control a Gateway from ObjectScript code.
/// These provide the infrastructure for accessing (and modifying) the Gateway's 
/// internal tables, configuration, and log files from participating servers. This functionality is only 
/// provided by Version 2012 Gateways and later.
/// <p>Participating InterSystems IRIS servers are those to which the Gateway holds at least one connection. The Gateway 
/// will not allow access to these facilities from any other client. This does mean, however, 
/// that ObjectScript routines cannot access Gateway resources until the Gateway has created its 
/// first connection to that server - even if the Gateway contains a configuration (under 'Server Access') for 
/// accessing that InterSystems IRIS server.</p>
/// <script type="text/javascript" language="JavaScript">  
/// function draw_a(){ 
/// var a_canvas = document.getElementById("gcanvas");
/// var ctx = a_canvas.getContext("2d");
/// ctx.beginPath();
/// ctx.fillStyle = 'rgb(64,64,128)';
/// var x = 10; var y0 = 10; var w = 150; var h = 26;
/// var xoff=10; var yoff=15; var dy=70; var gap=15;
/// ctx.strokeRect(x,y0,w+80,h); 
/// ctx.fillText("$System.CSP.GetGatewayRegistry()",x+xoff,y0+yoff);
/// y1 = y0+dy;
/// ctx.strokeRect(x,y1,w+80,h); 
/// ctx.fillText("%CSP.Mgr.GatewayRegisty.GetGatewayMgrs()",x+xoff,y1+yoff);
/// y2 = y1+dy; x = 10;
/// ctx.strokeRect(x,y2,w,h); 
/// ctx.fillText("%CSP.Mgr.GatewayMgr",x+xoff,y2+yoff);
/// x = x+w+gap;
/// ctx.strokeRect(x,y2,w,h); 
/// ctx.fillText("%CSP.Mgr.GatewayMgr",x+xoff,y2+yoff);
/// x = x+w+gap;
/// ctx.strokeRect(x,y2,w,h); 
/// ctx.fillText("%CSP.Mgr.GatewayMgr",x+xoff,y2+yoff);
/// x = 30; y = y0+h; ctx.moveTo(x,y); ctx.lineTo(x,y1);
/// y = y1+h;
/// ctx.moveTo(x,y);
/// ctx.lineTo(x,y2);
/// y = y2 - (h/3);
/// ctx.moveTo(x,y);
/// ctx.lineTo(x+(2*(w+gap)),y);
/// ctx.lineTo(x+(2*(w+gap)),y2);
/// ctx.moveTo(x+w+gap,y);
/// ctx.lineTo(x+w+gap,y2);
/// ctx.stroke(); ctx.restore();
/// }
/// </script>
/// <div id="gatewayinfo" style="display:none">
/// <canvas id="gcanvas" width="660" height="200">Please use a browser which supports html5.</canvas>
/// </div>
/// <script language="javascript"> 
/// function toggle() {
/// 	var ele = document.getElementById("gatewayinfo");
/// 	var text = document.getElementById("displayText");
/// if(ele.style.display == "block") {
///    	ele.style.display = "none";
/// 		text.innerHTML = "How do I get a gateway?";
///  	}
/// 	else {
/// 		ele.style.display = "block";
/// 		text.innerHTML = "hide";
/// 	}
/// } 
/// </script>
/// <script language="javascript"> 
/// function togglessxml() {
/// 	var ele = document.getElementById("ssxmlExample");
/// 	var text = document.getElementById("displaySSXml");
/// if(ele.style.display == "block") {
///    	ele.style.display = "none";
/// 		text.innerHTML = "System Status XML Example";
///  	}
/// 	else {
/// 		ele.style.display = "block";
/// 		text.innerHTML = "hide";
/// 	}
/// } 
/// </script>
/// <div id="toggleText" style="display: none"></div>
/// <p><b>Security</b></p>
/// For read-oriented methods (e.g. GetDefaultParams()), users must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.
/// <br>
/// For update-oriented methods (e.g. SetDefaultParams()), users must hold the %Admin_Manage:Use privilege.
/// <p><b>Logging</b></p>
/// <p>All Gateway Manager commands are recorded in the Event Log (Gateway Log Level 'v2'). For example a request for the configuration file would be logged as:</p>
/// <example language="none">Gateway Management: CallBack Request for Information
/// Command=sys_get_CSP_ini; Bytes Returned=4206;
/// CSPSYS=sys_set_config:default&Server_Response_Timeout=300
/// </example>
/// A request to update the default configuration would be logged as something like:
/// <example language="none">Gateway Management: Response to CallBack: /csp/samples/%CSP.Callback.cls
/// HTTP/1.1 200 OK
/// Content-Type= application/x-www-form-urlencoded
/// Connection: close
/// Content-Length: 83
/// CSPID: MyToken</example>
/// Errors are recorded: <example language="none">Gateway Management: Bad Request
/// CSPrequest: xxx_yyy_CSP_log</example>
/// <p><b>Types of Methods</b></p>
/// <p> The methods are divided into two groups. Those that GET information from the Gateway 
/// and those that SEND information or action requests to the Gateway. These methods send asynchronous 
/// requests to the Gateway. To get a list of gateways see <class>%CSP.Mgr.GatewayRegistry</class>.</p>
/// <p> <table border=1>
/// <tr><td>GET</td><td>
/// GET methods wait for ten seconds for the CSP infrastructure to process the 
/// request.
/// <ol>
/// <li>A status of $$$OK indicates that the requested data was successfully returned</li>
/// <li>The status of $$$GatewayRequestTimeoutSec indicates that the request timed out.</li>
/// <li>The status will indicate that an error occurred in processing the request.</li>
/// <li>These functions wait for the return data (up to 10 seconds). Generally, when the load on the server is 
/// not too heavy, they will return very quickly as the return a small amount of data. The exception is GetCSPLog() which 
/// can return a very large amount of data and potentially time out.</li>
/// </ol>
/// </td></tr>
/// <tr><td>SEND</td><td>The status return indicates that the request was successfully 
/// sent to the Gateway. However, it does not indicate that updates were successfully applied.
/// <p>When a configuration is interactively modified, each parameter will be fully checked for validity.
/// If a parameter or a value give for a particular parameter is unacceptable, then an error will be 
/// generated and the existing value is left unmodified. In some cases, the Gateway will modify a value
/// such that it makes more sense in the context of the current configuration. For these cases a warning 
/// is generated with notification of the 'corrected' value.</p>
/// <p>For commands updating configuration parameters, the new values should appear 
/// as a list of [name,value] pairs. For example: 
/// <p><example language="none">$lb("Server_Response_Timeout=90","Queued_Request_Timeout=70")</example></p>
/// <ol><li>Note that all configuration parameters are case-sensitive.</li>
/// <li>All passwords will be encrypted (as appropriate) before they are saved in CSP.ini.</li>
/// <li>Setting a parameter to empty string ("") effectively deletes it from CSP.ini.<p></li>
/// <li>In all cases the parameter names should be specified exactly as they appear 
/// in CSP.ini. The parameter values, in most cases, take the values as shown in the management form.</li>
/// </ol></p>
/// </td></tr></table></p>
/// <br><br>Example:<br>
/// <example language="none">
/// %SYS>s Reg=$SYSTEM.CSP.GetGatewayRegistry()
/// 
/// %SYS>s Mgrs=Reg.GetGatewayMgrs()
/// 
/// %SYS>w Mgrs.Count()
/// 1
/// %SYS>s Mgr=Mgrs.GetAt(1)
/// %SYS>w Mgr.Port
/// 57775
/// %SYS>s Status=Mgr.GetCSPIni(.ini)
/// 
/// %SYS>zw ini
/// ini("[APP_PATH_INDEX]","/csp")="Enabled"
/// ini("[LOCAL]")=""
/// ini("[LOCAL]","Maximum_Session_Connections")=3
/// ini("[LOCAL]","Minimum_Server_Connections")=3
/// ini("[LOCAL]","TCP_Port")=56781
/// ini("[SYSTEM]","Configuration_Initialized")="Thu Oct 27 08:57:23 2011"
/// ini("[SYSTEM]","Configuration_Initialized_Build")=1201.1264
/// ini("[SYSTEM]","Queued_Request_Timeout")=60
/// ini("[SYSTEM]","SM_Timeout")=300
/// ini("[SYSTEM]","Server_Response_Timeout")=60
/// ini("[SYSTEM]","sys_shm_inst")=1
/// ini("[SYSTEM]","sys_timestamp")=1336083061
/// </example>
/// 
Class %CSP.Mgr.GatewayMgr [ Abstract, System = 4 ]
{

/// <p>The <b>Server</b> and <b>Port</b> information of the Gateway being managed. If connecting with the server name fails, the IP Address will be used instead.
Property Server As %String;

/// The URL part matching the Web Application that initialized this connection
Property AppMatch;

/// <p>The <b>Server</b> and <b>Port</b> information of the Gateway being managed. This is used if connecting using the server name fails.
Property IPAddress As %String;

Property Port As %String;

/// <p>The <b>Version</b> of the Gateway being managed.</p>.
Property Version As %String;

/// <p><b>State</b> has one of the following values:</p>
/// <ul><li>"a" - This gateway has a live connection to the currently-running instance of InterSystems IRIS.</li>
/// <li>"i" - This gateway was connected to this InterSystems IRIS instance some time in the recent past (currently one month), but 
/// is does not have a live connection to the currently-running InterSystems IRIS instance</li>
/// </ul></p> 
Property State As %String;

/// <p><b>LastConnectTime</b> contains the data/time of the last time this Gateway connected to this InterSystems IRIS instance</p>
Property LastConnectTime As %Date;

/// The process identifier associated with this connection. (Has a value only for Active connections.)</p>
Property CachePid As %String;

/// <p><b>ResponseBufferTimeout</b> the maximum time the Mgr will before for the next portion of the response. 'GET's wait for a response from 
/// the Gateway. The response is sent in buffers. This is the maximum time the Manager will wait for the next buffer to be send, including the 
/// first buffer, i.e., the response must begin within ResponseBufferTimeout seconds of the request. This is measured in seconds. The default
/// value is 10 seconds.</p>
Property ResponseBufferTimeout As %Integer;

/// <method>ClearCache</method> clears the Gateway's Page Cache.
/// <p>The values  of <i>clearFilenames</i> determines the exact action of the method. 
/// <ol>
/// <li>An empty or undefined value indicates that the entire cache should be cleared.</li>
/// <li>A list of the file names to be purged from the cache. </li>
/// <li>A file name may contain a 
/// wildcard, '*'.
/// <pre>
/// 1.  Clear all forms named 'zenutils.js', regardless of path: */zenutils.js
/// 2.  Clear all forms from the '/csp/samples/images/' location: /csp/samples/images/*
/// 3.  Clear all forms whose path/name contains the '/Zen_' token: */Zen* </pre>
/// </ol></p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method ClearCache(clearFilenames As %List) As %Status
{
}

/// <method>GetApplicationParams</method> gets the Application Access Parameters.
/// <p><i>path</i> indicates the application path whose parameters are being
/// requested. See the <method>GetApplicationPaths</method> method to obtain a list of the application paths 
/// defined for this Gateway.</p>
/// <p><i>configAry</i> [name,value] pairs are returned in local array</p>
/// <p>See <method>SetApplicationParams</method> for a list of parameters.</p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetApplicationParams(path As %String, ByRef configAry) As %Status
{
}

/// <method>SetApplicationParams</method> updates settings in the 'Application Access' section.
/// <p><i>path</i> indicates that application path being updated. See the 
/// <method>GetApplicationPaths</method> method to obtain a list of the application paths 
/// defined for this Gateway.</p>
/// <p><i>configUpdates</i> a local array whose [name,value] pairs are used to update the configuration.</p>
/// <p><table border=1><tr><th>Param Name</th><th>Description</th></tr>
/// <tr><td>Application_Status</td><td>Service Status: Enabled, Disabled</td></tr>
/// <tr><td>Extra_CGI_Env_Variables</td><td>Extra CGI Environment Variables</td></tr>
/// <tr><td>Proc_Class</td><td>Process with this class</td></tr>
/// <tr><td>GZIP_Compression</td><td>GZIP Compression: Enabled, Disabled</td></tr>
/// <tr><td>GZIP_Mininum_File_Size</td><td>GZIP minimum file size</td></tr>
/// <tr><td>GZIP_Exclude_File_Types</td><td>GZIP exclude file types</td></tr>
/// <tr><td>KeepAlive</td><td>Keep alive: Enabled, Disabled, No Action</td></tr>
/// <tr><td>Non_Parsed_Headers</td><td>Non-parsed headers: Enabled, Disabled</td></tr>
/// <tr><td>Default_Server</td><td>Default server</td></tr>
/// <tr><td>Alternative_Servers</td><td>Alternative Servers.<p>This takes one of the following values:</p>
/// <p>LoadBalancing - Load balancing and failover</p><p>FailOver - Failover only</p>
/// <p>Disabled - Disabled</p>
/// </p> </td></tr>
/// <tr><td>Alternative_Server_[n]</td><td>Alternative server</td></tr>
/// <tr><td>Alternative_Server_[n]_Status</td><td>Alternative Server Status: Enabled, Disabled, OFFLINE</td></tr>
/// </table></p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method SetApplicationParams(path As %String, ByRef configUpdates) As %Status
{
}

/// <method>GetApplicationPaths</method> gets the list of configured application paths for this Gateway.
/// <p><i>appPaths</i> is a list of strings, each an application path.<p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetApplicationPaths(ByRef appPaths As %List) As %Status
{
}

/// <method>GetServers</method> gets the list of configured servers for this server.
/// <p><i>serverList</i> is a list of strings, each the name of a configured server.<p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetServers(ByRef serverList As %List) As %Status
{
}

/// <method>GetCSPIni</method> get the contents of the configuration file (CSP.ini).
/// <p><i>format</i> is the return format: <br />    "array" - return as 
/// an array. 
/// <br />   "stream" - returns as a <class>%Stream.GlobalCharacter</class>.</p>
/// <p><i>cspIni</i><p> If format="array", tke values are returned in a two-level array. A partial example:
/// <example language="none">
/// cspini("[APP_PATH:/]", "Default_Server" ) = "LOCAL"
/// cspini("[APP_PATH:/csp]", "Default_Server") = "LOCAL"
/// cspini("[APP_PATH:/csp]", "GZIP_Minimum_File_Size") = "0"
/// cspini("[LOCAL]", "Ip_Address") = "127.0.0.1"
/// cspini("[LOCAL]", "Maximum_Server_Connections") = "4"
/// cspini("[LOCAL]", "Maximum_Session_Connections") = "3"
/// cspini("[LOCAL]", "Minimum_Server_Connections") = "30"
/// cspini("[LOCAL]", "Username") = "CSPSystem"
/// </example>
/// <p>If format="stream", the data is returend as a <class>%Stream.GlobalCharacter</class> object which allows 
/// the CSP Ini text to be parsed directly.</p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetCSPIni(ByRef cspIni, format As %String = "array") As %Status
{
}

/// <method>ClearCSPLog</method> clears the Event Log (CSP.log)
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method ClearCSPLog() As %Status
{
}

/// <method>ActivateCSPIni</method> activates changes made manually to the Gateway Configuration (CSP.ini)
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method ActivateCSPIni() As %Status
{
}

/// <method>GetCSPLog</method> gets the Event Log (CSP.log)
/// <p><i>cspLogStream</i> is a <class>%Stream.GlobalCharacter</class> stream from which you can read the lines of the returned from the event log  
/// When you close the stream, the temporary data from the server will be removed.</p>
/// <p><i>startDateTime</i> the time from which to start returning events. The format the date one of the following: <p>
/// <pre>   C format: e.g.:         Fri Apr 01 22:28:23 2011 
///   RFC1123 format: e.g.:   Mon, 26 Jul 2010 15:09:28 GMT</pre>
/// <p>The value "now" [default] will be replaced by the current date and time.</p>
/// <p><i>direction</i> the direction to scan for events: 1 -> forward; -1 -> backward</p>
/// <p><i>nEvents</i> the number of Events to return from the event file. 
/// Each event consists of one line in a structured name-value pair format.
/// Caution: The CSP Log file contains tens of thousands of lines of text. If you request too many events in one call, GetCSPLog() will timeout 
/// waiting for the Gateway to finish transfering all the data. </p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetCSPLog(ByRef cspLogStream As %Stream.GlobalCharacter, startDateTime As %String = "now", direction As %Integer = -1, nEvents = 1000) As %Status
{
}

/// <method>GetDefaultParams</method> gets Default Parameters.
/// <p><i>config</i> values are returned as named parameters of the object.
/// See <method>SetDefaultParams</method> for a list of parameters. </p>
/// <p><i>configAry</i> [name,value] pairs are returned in local array</p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetDefaultParams(ByRef configAry) As %Status
{
}

/// <method>SetDefaultParams</method> updates parameters in the 'Default Parameters' section.
/// <p><i>configUpdates</i> a local array whose [name,value] pairs are used to update the configuration.</p>
/// <p><table BORDER=1><tr><th>Param Name</th><th>Description</th></tr>
/// <tr><td>Instance_Host_Name</td><td>Instance host name</td></tr>
/// <tr><td>SM_Forms</td><td>Access to these forms</td></tr>
/// <tr><td>Username</td><td>User name</td></tr>
/// <tr><td>Password</td><td>Password<br>All passwords will be encrypted (as appropriate) before they are saved in CSP.ini.
/// </td></tr>
/// <tr><td>SM_Timeout</td><td>Session Timeout</td></tr>
/// <tr><td>System_Manager</td><td>System Manager Machine(s)</td></tr>
/// <tr><td>System_Manager_UNPW_Override</td><td>Override Username and Password Checkbox<br>"1"=checked; ""=unchecked</td></tr>
/// <tr><td>Server_Response_Timeout</td><td>Server response timeout</td></tr>
/// <tr><td>Queued_Request_Timeout</td><td>Queued request timeout</td></tr>
/// <tr><td>No_Activity_Timout</td><td>No activity timeout</td></tr>
/// <tr><td>Env_Parameters</td><td>Event Log Level</td></tr>
/// <tr><td>Event_Log_File</td><td>Event log file</td></tr>
/// <tr><td>Event_Log_Rotation_Size</td><td>Event log rotation size</td></tr>
/// <tr><td>Maximum_Logged_Request_Size</td><td>Maximum data logged per HTTP request</td></tr>
/// <tr><td>Document_Root</td><td>Web document root</td></tr>
/// <tr><td>ASP_Directory</td><td>Temp ASP Directory</td></tr>
/// <tr><td>WS_Service_Status</td><td>Service State: Enabled,Disabled</td></tr>
/// <tr><td>NSD_Document_Root</td><td>NSD Document Root</td></tr>
/// <tr><td>Server_Error</td><td>Server Error</td></tr>
/// <tr><td>Server_Busy</td><td>Server_Busy</td></tr>
/// <tr><td>Server_Unavailable</td><td>Server Unavailable</td></tr>
/// <tr><td>Server_Timeout</td><td>Server timeout</td></tr>
/// <tr><td>Connection_Closed</td><td>Connection closed</td></tr>
/// </table></p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method SetDefaultParams(ByRef configUpdates) As %Status
{
}

/// <method>GetInfo</method> gets the information about the gateway.
/// <p><i>format</i> is the return format: <br />    "object" - return as 
/// <class>%CSP.Mgr.GatewayInformation</class> object; 
/// <br />   "stream" - returns as the information as XML in a <class>%Stream.GlobalCharacter</class>.</p>
/// <p><i>info</i> </br >if format="object" this is an instance of the 
/// <class>%CSP.Mgr.GatewayInformation</class> class.<br />
/// if format="stream", this is a <class>%Stream.GlobalCharacter</class> containing the information as XML</p>
/// <example language="none">
/// &lt;?xml version="1.0" encoding="UTF-8" ?&gt;
/// &lt;GatewayInformation&gt;
/// &lt;Version&gt;2011.2.0.202.0&lt;/Version&gt;
/// &lt;Build&gt;1102.1226&lt;/Build&gt;
/// &lt;WebServerName&gt;localhost&lt;/WebServerName&gt;
/// &lt;WebServerPort&gt;57773&lt;/WebServerPort&gt;
/// &lt;WebServerSoftware&gt;Apache Cache_Server_Pages-Apache_Module/2011.2.0.202.0-1102.1226&lt;/WebServerSoftware&gt;
/// &lt;ActiveInterface&gt;apapi&lt;/ActiveInterface&gt;
/// &lt;/GatewayInformation&gt;
/// </example>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetInfo(ByRef info, format As %String = "object") As %Status
{
}

/// <method>GetServerParams</method> gets the Server Access Parameters for this server.
/// <p><i>server</i> indicates that server path whose values are being 
/// requested. See the <method>GetServers</method> method to obtain a list of the servers 
/// defined for this Gateway.</p>
/// <p><i>configAry</i> [name,value] pairs are returned in local array</p>
/// <p>See <method>SetServerParams</method> for a list of parameters.</p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetServerParams(server As %String, ByRef configAry) As %Status
{
}

/// <method>SetServerParams</method> updates settings in the 'Server Access' section.
/// <p> <i>server</i> indicates that server path being updated. See the 
/// <method>GetServers</method> method to obtain a list of the servers 
/// configured on this Gateway.</p>
/// <p><i>configUpdates</i> a local array whose [name,value] pairs are used to update the configuration.</p>
/// <p><table border=1><tr><th>Param Name</th><th>Description</th></tr>
/// <tr><td>Server_Status</td><td>Server status: Enabled, Disabled</td></tr>
/// <tr><td>Ip_Address</td><td>IP Address</td></tr>
/// <tr><td>TCP_Port</td><td>TCP Port</td></tr>
/// <tr><td>Minimum_Server_Connections</td><td>Minimum server connections</td></tr>
/// <tr><td>Maximum_Server_Connections</td><td>Maximum server connections</td></tr>
/// <tr><td>Connection_Security_Level</td><td>Connection Security Level<p>This takes a numeric value:</p>
/// <p>0 Password</p><p>1 Kerberos</p><p>2 Kerberos with Packet Integrity</p>
/// <p>3 Kerboros with Encryption</p><p>10 SSL</p>
/// </td></tr>
/// <tr><td>Product</td><td>Product<p>This takes a numeric value:</p>
/// <p>0 (deprecated)</p><p>1 InterSystems IRIS</p>
/// </td></tr>
/// <tr><td>Service_Principal_Name</td><td>Service principal name</td></tr>
/// <tr><td>Keytable</td><td>Key table</td></tr>
/// <tr><td>SSLCC_Protocol</td><td>SSL Protocol<p>Deprecated; use SSLCC_Protocol_Min and SSLCC_Protocol_Max instead</p>
/// </td></tr>
/// <tr><td>SSLCC_Protocol_Min</td><td>Minimum SSL/TLS Protocol Version<p>This takes a numeric value:</p>
/// <p>4 TLSv1.0</p><p>8 TLSv1.1</p><p>16 TLSv1.2</p><p>32 TLSv1.3</p>
/// </td></tr>
/// <tr><td>SSLCC_Protocol_Max</td><td>Maximum SSL/TLS Protocol Version<p>This takes a numeric value:</p>
/// <p>4 TLSv1.0</p><p>8 TLSv1.1</p><p>16 TLSv1.2</p><p>32 TLSv1.3</p>
/// </td></tr>
/// <tr><td>SSLCC_Key_Type</td><td>SSL Key Type<p>This takes a numeric value:</p>
/// <p>1 DSA</p><p>2 RSA</p>
/// </td></tr>
/// <tr><td>SSLCC_Verify_Peer</td><td>SSL Verify Peer checkbox:<p>"1"=Checked;""=Unchecked"</td></tr>
/// <tr><td>SSLCC_Cipher_Suites</td><td>The Cipher Suite list (TLSv1.2 and below)</td></tr>
/// <tr><td>SSLCC_Cipher_Suites_1_3</td><td>The Cipher Suite list (TLSv1.3)</td></tr>
/// <tr><td>SSLCC_Certificate_File</td><td>SSL Certificate File</td></tr>
/// <tr><td>SSLCC_Certificate_Key_File</td><td>SSL Certifictate Key File</td></tr>
/// <tr><td>SSLCC_CA_Certificate_File</td><td>SSL CA Certificate File</td></tr>
/// </table></p>
/// <p>Alternative Servers should be saved as a contiguous set of alternative servers as follows:</p>
/// <example language="none">Alternative_Server_1=APPSERVER1
/// Alternative_Server_1_Status=Enabled
/// Alternative_Server_2=APPSERVER2
/// Alternative_Server_2=Disabled</example>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method SetServerParams(server As %String, ByRef configUpdates) As %Status
{
}

/// <p><method>SetServerStatus</method> sets the 'online' status for either a single or a specified range of InterSystems IRIS servers</p>
/// <p><i>path</i> is the application path as defined in the Gateway Configuration (or "*" for all) <br />
/// <i>server</i> is the InterSystems IRIS server name as defined in the Gateway configuration (or "*" for all) <br />
/// <i>status</i> is '1' for online and '0' for offline  <br />
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method SetServerStatus(path As %String = "*", server As %String = "*", status As %Integer) As %Status
{
}

/// <p><method>GetServerStatus</method> retrieves the 'online' status for either a single or a specified range of InterSystems IRIS servers</p>
/// <p><i>path</i> is the application path as defined in the Gateway Configuration (or "*" for all) <br />
/// <i>server</i> is the InterSystems IRIS server name as defined in the Gateway configuration (or "*" for all) <br />
/// <p>An array of servers and their status is returned as follows: <br />
/// <p><i>statusAry(path,server_number)=$List(server, status)</i> <br />
/// <P>Where <i>status</i> is '1' for online and '0' for offline <br />
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetServerStatus(path As %String = "*", server As %String = "*", ByRef statusAry) As %Status
{
}

/// <method>GetSystemMetrics</method> gets information related to Gateway performance.
/// The information returned is used by the Gateway Monitor.
/// <p><i>metricsAry</i> [name,value] pairs are returned in local array</p>
/// <p><b>Security:</b> No privileges are necessary to call this method.</p>
Method GetSystemMetrics(ByRef metricsAry) As %Status
{
}

/// <method>GetThisServerName</method> gets the name that the Gateway uses to access <i><b>this</b></i> InterSystems IRIS server.
/// The Gateway can be configured to access the same InterSystems IRIS server via multiple names.
/// Therefore a numbered array will be returned.
/// Index zero will hold the name used to currently access <i><b>this</b></i> InterSystems IRIS server.  Any other names will follow in the numbered list. 
/// <p><i>serversAry</i> [number,name] pairs are returned in local array</p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetThisServerName(ByRef serversAry) As %Status
{
}

/// <p><method>GetSystemStatus</method> gets the System Status.</p>
/// <p><i>format</i> is the return format: <br />    "object" - return as an object; 
/// <br />   "stream" - returns as the information as XML.</p>
/// <p><i>systemStatus</i> </br >if format="object" returned as an instance of a <class>%CSP.Mgr.GatewaySystemStatus</class>
/// object. There are the following main 
/// sections to the status: Connections, Servers, Application Paths, Alternative Servers, and Cached Form.<br />
/// if format="stream", this is a %Stream.GlobalCharacter containing the information as XML</p>
/// <p><table border=1>
/// <tr><td>Connection, number </td><td> </td></tr>
/// <tr><td> </td><td>WebServerPID </td></tr>
/// <tr><td> </td><td>CacheServerName </td></tr>
/// <tr><td> </td><td>IpAddress </td></tr>
/// <tr><td> </td><td>TCPPort </td></tr>
/// <tr><td> </td><td>CacheServerPID </td></tr>
/// <tr><td> </td><td>Status</td></tr>
/// <tr><td> </td><td>IdleTime </td></tr>
/// <tr><td> </td><td>Activity </td></tr>
/// <tr><td>CacheServer, number </td><td> </td></tr>
/// <tr><td> </td><td>CacheServerName </td></tr>
/// <tr><td> </td><td>IpAddress </td></tr>
/// <tr><td> </td><td>TCPPort </td></tr>
/// <tr><td> </td><td>TotalConnections </td></tr>
/// <tr><td> </td><td>ConnectionsInUse </td></tr>
/// <tr><td> </td><td>PrivateConnections </td></tr>
/// <tr><td> </td><td>Activity </td></tr>
/// <tr><td> </td><td>QueuedRequests </td></tr>
/// <tr><td>Application Path, path </td><td> </td></tr>
/// <tr><td> </td><td>AlternativeServer </td></tr>
/// <tr><td> </td><td>CacheServerName </td></tr>
/// <tr><td> </td><td>Activity </td></tr>
/// <tr><td> </td><td>Status </td></tr>
/// <tr><td>Alternative Server, number </td><td> </td></tr>
/// <tr><td> </td><td>CacheServerName </td></tr>
/// <tr><td> </td><td>Activity </td></tr>
/// <tr><td> </td><td>Status </td></tr>
/// <tr><td>CachedForms </td><td> </td></tr>
/// <tr><td> </td><td>FormsInCache </td></tr>
/// <tr><td> </td><td>CachedData </td></tr>
/// <tr><td> </td><td>CacheActivity </td></tr>
/// <tr><td>CachedForms,Form, form name </td><td> </td></tr>
/// <tr><td> </td><td>Size </td></tr>
/// <tr><td> </td><td>Activity </td></tr>
/// </table></p>
/// <a id="displaySSXmlText" href="javascript:togglessxml()">System Status XML Example</a> 
/// <div id="toggleSSXml" style="display: none"></div>
/// <div id="ssxmlExample" style="display:none">
/// <p>Example:</p>
/// <example language="none">
/// &lt;?xml version="1.0" encoding="UTF-8" ?&gt; 
///   &lt;GatewaySystemStatus&gt;
///      &lt;Connections&gt;
///         &lt;Connection Number="0"&gt;
///            &lt;WebServerPID&gt;5936&lt;/WebServerPID&gt; 
///            &lt;CacheServerName&gt;APPSERVER1&lt;/CacheServerName&gt; 
///            &lt;IpAddress&gt;127.0.0.1&lt;/IpAddress&gt; 
///            &lt;TcpPort&gt;56773&lt;/TcpPort&gt; 
///            &lt;CacheServerPID&gt;3304&lt;/CacheServerPID&gt; 
///            &lt;Status&gt;Free&lt;/Status&gt; 
///            &lt;IdleTime&gt;0/0&lt;/IdleTime&gt; 
///            &lt;Activity&gt;19&lt;/Activity&gt; 
///         &lt;/Connection&gt;
///         &lt;Connection Number="1"&gt;
///            &lt;WebServerPID&gt;5936&lt;/WebServerPID&gt; 
///            &lt;CacheServerName&gt;APPSERVER1&lt;/CacheServerName&gt; 
///            &lt;IpAddress&gt;127.0.0.1&lt;/IpAddress&gt; 
///            &lt;TcpPort&gt;56773&lt;/TcpPort&gt; 
///            &lt;CacheServerPID&gt;3428&lt;/CacheServerPID&gt; 
///            &lt;Status&gt;Free&lt;/Status&gt; 
///            &lt;IdleTime&gt;0/0&lt;/IdleTime&gt; 
///            &lt;Activity&gt;12&lt;/Activity&gt; 
///         &lt;/Connection&gt;
///      &lt;/Connections&gt;
///      &lt;CacheServers&gt;
///         &lt;CacheServer Number="2"&gt;
///            &lt;CacheServerName&gt;APPSERVER1&lt;/CacheServerName&gt; 
///            &lt;IpAddress&gt;127.0.0.1&lt;/IpAddress&gt; 
///            &lt;TCPPort&gt;56773&lt;/TCPPort&gt; 
///            &lt;TotalConnections&gt;6&lt;/TotalConnections&gt; 
///             &lt;ConnectionsInUse&gt;0&lt;/ConnectionsInUse&gt; 
///           &lt;PrivateConnections&gt;0&lt;/PrivateConnections&gt; 
///            &lt;Activity&gt;75&lt;/Activity&gt; 
///            &lt;QueuedRequests&gt;0&lt;/QueuedRequests&gt; 
///          &lt;/CacheServer&gt;
///      &lt;/CacheServers&gt;
///      &lt;ApplicationPaths&gt;
///         &lt;ApplicationPath Number="1"&gt;
///            &lt;Path&gt;/csp&lt;/Path&gt; 
///            &lt;AlternativeServer Number="0"&gt;
///            &lt;CacheServerName&gt;APPSERVER1&lt;/CacheServerName&gt; 
///            &lt;Activity&gt;75&lt;/Activity&gt; 
///            &lt;Status&gt;Enabled (Master)&lt;/Status&gt; 
///         &lt;/AlternativeServer&gt;
///         &lt;AlternativeServer Number="1"&gt;
///            &lt;CacheServerName&gt;APPSERVER2&lt;/CacheServerName&gt; 
///            &lt;Activity&gt;0&lt;/Activity&gt; 
///            &lt;Status&gt;Disabled&lt;/Status&gt; 
///         &lt;/AlternativeServer&gt;
///      &lt;/ApplicationPath&gt;
///   &lt;/ApplicationPaths&gt;
///   &lt;CachedForms&gt;
///      &lt;FormsInCache&gt;1&lt;/FormsInCache&gt; 
///      &lt;CachedData&gt;6584&lt;/CachedData&gt; 
///      &lt;CacheActivity&gt;3&lt;/CacheActivity&gt; 
///      &lt;Form id="/csp/samples/images/zenLogo.svg"&gt;
///        &lt;Size&gt;6584&lt;/Size&gt; 
///        &lt;Activity&gt;3&lt;/Activity&gt; 
///      &lt;/Form&gt;
///   &lt;/CachedForms&gt;
///   &lt;/GatewaySystemStatus&gt;
/// </example>
/// </div>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Operate:Use or %Admin_Manage:Use privilege.</p>
Method GetSystemStatus(ByRef systemStatus, format As %String = "object") As %Status
{
}

/// <method>CloseConnection</method> closes connections to this gateway.
/// <p><i>connections</i> specifies which connections are to be closed:</p>
/// <p><table><tr><th>Value</th></th>Connections Closed</th></tr>
/// <tr><td>* </td><td>All connections </td></tr>
/// <tr><td>Server Name </td><td>Close connections to a specific server, e.g. LOCAL</td></tr>
/// <tr><td>number </td><td>Close a specific connections, e.g. 3 </td></tr>
/// <tr><td>list of numbers </td><td>Close a list of specific connections, e.g, $lb(2,5,7)</td></tr>
/// </table></p>
/// <p><b>Security:</b> To call this method, you must hold the %Admin_Manage:Use privilege.</p>
Method CloseConnections(connections As %String = "*") As %Status
{
}

}
