/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

/// This class implements the IRIS Native API for Object Script DataSource interface. At this time that interface consists 
/// solely of the <method>CreateConnection</method> method.
/// <h2>IRIS Native API for ObjectScript</h2>
/// <p>
/// The Native API for ObjectScript follows the API used on other language platforms. It starts with a static API that 
/// allows the user to connect to an IRIS Namespace, either local or remote, using an Iris Connection. The connection interface allows 
/// the user to then instantiate the IRIS Native API class (<class>%Net.DB.Iris</class>). That instance can then be used to access IRIS Global Arrays, manage transactions, 
/// invoke functions and methods implemented in routines or classes, and instantiate remote iterators. 
/// </p>
Class %Net.DB.DataSource [ Abstract ]
{

/// CreateConnection accepts <var>url</var>, <var>port</var>,<var>namespace</var>, <var>user</var>, and <var>pwd</var> parameters. 
/// Refer to <class>%Net.DB.Connection</class> for more information on these parameters. 
/// CreateConnection() returns an instance of <class>%Net.DB.Connection</class>. 
/// <p>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td>host</td>
/// 			<td>input</td>
/// 			<td>The host name or address, defaults to 127.0.0.1 </td>
/// 		</tr>
/// 		<tr>
/// 			<td>port</td>
/// 			<td>input</td>
/// 			<td>The port on which to connect </td>
/// 		</tr>
/// 		<tr>
/// 			<td>namespace</td>
/// 			<td>input</td>
/// 			<td>The namespace to connect to </td>
/// 		</tr>
/// 		<tr>
/// 			<td>user</td>
/// 			<td>input</td>
/// 			<td>The user's name </td>
/// 		</tr>
/// 		<tr>
/// 			<td>pwd</td>
/// 			<td>input</td>
/// 			<td>User's password </td>
/// 		</tr>
/// 		<tr>
/// 			<td>timeout</td>
/// 			<td>input</td>
/// 			<td>The number of seconds to wait for the connection to be established. Optional. </td>
/// 		</tr>
/// 		<tr>
/// 			<td>logfile</td>
/// 			<td>input</td>
/// 			<td>The name of the file to be used for logging. If specified, connection activity will be logged to that file. Optional. </td>
/// 		</tr>
/// 		<tr>
/// 			<td></td>
/// 			<td>return</td>
/// 			<td>An oref referencing an instance of <class>%Net.DB.Connection</class> </td>
/// 		</tr>
/// 	</table><br/>
/// </p>
ClassMethod CreateConnection(host As %String(MAXLEN="") = "127.0.0.1", port As %Integer = 51773, namespace As %String(MAXLEN="") = "USER", user, pwd, timeout As %Integer, logfile As %String(MAXLEN=255) = "") As %Net.DB.Connection
{
	do ..validateConnection(.host,.port,.namespace,.user,.pwd,.timeout,.logfile)
	set conn = ##class(%Net.DB.Connection).%New(host,port,namespace,,.timeout)
	$$$THROWONERROR(status, conn.Connect(user,pwd))
	return conn
}

ClassMethod validateConnection(host As %String(MAXLEN="") = "", port As %Integer = "", namespace As %String(MAXLEN="") = "", user As %String(MAXLEN="") = "", pwd As %String(MAXLEN="") = "", timeout As %Integer = 5, logfile As %String = "") As %Boolean [ Internal, ServerOnly = 1 ]
{
	if (host = "") {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "host is required")
	}

	if ($length(host) > 255) {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "invalid host")
	}

	// check port, timeout, logfile for valid values
	if (port '> 0) || (port > 65535) {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "invalid port: " _ port)
	}

	if namespace = "" {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "namespace is required")
	}

	if $length(namespace) > 255 {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "invalid ns: " _ namespace)
	}

	if timeout < 0 {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "invalid timeout: " _ timeout)
	}

	if $length(logfile) > 255 {
		throw ##class(%Exception.General).%New("ValueError","ValueError","validateConnection()", "invalid logfile: " _ logfile)
	}
	return 1
}

}
