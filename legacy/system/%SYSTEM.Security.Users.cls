/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.Security.Users [ Abstract, System = 4 ]
{

/// Returns the name of the SSL/TLS ciphersuite currently in use over the current device,
/// if an SSL/TLS connection is currently established.
ClassMethod SSLGetCipher() As %String
{
}

/// Returns a colon-delimited list of the names of all supported ciphersuites for TLSv1.2 and below
/// that are consistent with the input parameters.<br>
/// Parameters:<br><br>
/// Direction:<br>
/// 0 = client<br>
/// 1 = server<br><br>
/// TLSMinVersion:<br>
/// 4 = TLSv1.0<br>
/// 8 = TLSv1.1<br>
/// 16 = TLSv1.2<br><br>
/// TLSMaxVersion:<br>
/// 4 = TLSv1.0<br>
/// 8 = TLSv1.1<br>
/// 16 = TLSv1.2<br><br>
/// Note:  TLSMaxVersion cannot be less than TLSMinVersion<br><br>
/// CipherList, a colon-delimited string constraining the return values, as specified in the OpenSSL Cipher
/// man page
ClassMethod SSLGetCipherList(Direction As %Integer, TLSMinVersion As %Integer, TLSMaxVersion As %Integer, CipherList As %String) As %String
{
}

/// Returns a description of the SSL/TLS error encountered, if any, during the most recent SSL/TLS
/// operation over the current device.<BR>
ClassMethod SSLGetLastError() As %String
{
}

/// Returns the X.509 certificate used
/// to verify the peer for the SSL/TLS session running over the current
/// principal TCP device, in binary DER format.  The certificate can be used as
/// input to $System.Encryption.X509GetField() and the RSA* functions.
/// To save the certificate to a file in PEM format: <br>
/// <br>
/// Do file.Write("-----BEGIN CERTIFICATE-----"_$c(13,10)) <br>
/// Do file.Write($System.Encryption.Base64Encode(certificate)) <br>
/// Do file.Write($c(13,10)_"-----END CERTIFICATE-----"_$c(13,10)) <br>
ClassMethod SSLGetPeerCertificate() As %String
{
}

/// Returns the SSL session parameters used
/// for the SSL/TLS session running over the current
/// principal TCP device, in binary DER format.
/// To save the session to a file in PEM format: <br>
/// <br>
/// Do file.Write("-----BEGIN SSL SESSION PARAMETERS-----"_$c(13,10)) <br>
/// Do file.Write($System.Encryption.Base64Encode(session)) <br>
/// Do file.Write($c(13,10)_"-----END SSL SESSION PARAMETERS-----"_$c(13,10)) <br>
ClassMethod SSLGetSession() As %String
{
}

/// Returns a string representation of the X.500 distinguished name contained in the X.509 certificate used
/// to verify the peer for the SSL/TLS session running over the
/// current device.  Called with no arguments it returns the entire
/// name on one line.  Called with an optional argument specifying a component
/// name entry it retuns just that entry, if present.  Legal values for the
/// entry argument, and their legal short abreviations, are:<br><br>
/// "commonName","CN"<br>
/// "countryName","C"<br>
/// "localityName","L"<br>
/// "stateOrProvinceName","ST"<br>
/// "organizationName","O"<br>
/// "organizationalUnitName","OU"<br>
/// "givenName","G"<br>
/// "surname","S"<br>
/// "initials","I"<br>
/// "uniqueIdentifier","UID"<br>
/// "serialNumber","SN"<br>
/// "title","T"<br>
/// "description","D"<br><br>
/// Also supports the IA5 string components of the X.509 v3 subjectAltName extension.
/// Additional legal values for the entry argument are:<br><br>
/// "email"<br>
/// "DNS"<br>
/// "URI"<br>
ClassMethod SSLGetPeerName(Entry As %String) As %String
{
}

/// Returns the name of the protocol currently in use over the current device,
/// if an SSL/TLS connection is currently established.
ClassMethod SSLGetProtocol() As %String
{
}

/// If the current device is a TCP device, peek into the TCP receive buffer.<br>
/// Returns 1 if it contains an SSLv3 or TLSv1 Client Hello message, or
/// an SSLv2 Client Hello message requesting SSLv3 or later.
/// Otherwise returns 0.
/// Parameter:<br><br>
/// Timeout, time to wait for data, in seconds
ClassMethod SSLPeekClientHello(Timeout As %Integer) As %Integer
{
}

/// Fetch Windows Telnet service SSL security setting. Only applicable to instances on Windows platform.  See also the SetTelnetSSLSetting method.<br>
/// <ul><li>Return value = 0: Disabled</li>
/// <li>Return value = 1: Enabled</li>
/// <li>Return value = 2: Required</li></ul>
ClassMethod GetTelnetSSLSetting() As %Integer
{
	Quit $System.Security.System.GetSSLServer()
}

/// Set the SSL requirement (Disabled/Enabled/Required) for inbound connections on the %Service_Telnet service.
/// The default value is 1 (Enabled) if a %TELNET/SSL configuration exists is enabled.
/// The default value is 0 (Disabled) of no %TELNET/SSL configuration exists or is enabled.
/// This method can be called from SYSTEM^%ZSTART to establish the setting for an instance at startup.
/// This setting is only applicable on the Windows platform.  Valid inputs are:<br>
/// <ul><li>Setting = 0: Disabled</li>
/// <li>Setting = 1: Enabled</li>
/// <li>Setting = 2: Required</li></ul>
/// <br>Returns previous setting.
ClassMethod SetTelnetSSLSetting(Setting As %Integer) As %Integer
{
	Quit $System.Security.System.SetSSLServer(Setting)
}

/// Calls the Windows LogonUser() API and saves the security token for the current process.
/// The user context is unaffected until the ImpersonateUser() method is called.  
/// Return value is 0 on success or the error value retrieved from GetLastError() on failure.
/// <br>This method is only available on Windows platforms.  
/// It cannot be called from a local InterSystems IRIS Terminal process which displays TRM:pid (InstanceName) in the title bar because this process is already impersonating the logged in Windows user.
/// An attempt to call LogonUser() from a local terminal process will result in a <FUNCTION> error.
ClassMethod LogonUser(UserName As %String, Domain As %String, Password As %String) As %Integer
{
}

/// Closes the handle to the security token previously created by LogonUser() after reverting the process user context to the original user context.
/// Return value is 0.
ClassMethod LogoffUser() As %Integer
{
}

/// Impersonates the user logged on by the LogonUser() method by calling the Windows ImpersonateLoggedOnUser() API with the security token saved by LogonUser().
/// ImpersonateUser() and RevertToSelf do not affect the user context contained in $USERNAME.
/// Returns 0 on success, -1 if no security token has been saved, or the value returned by GetLastError() on failure.
ClassMethod ImpersonateUser() As %Integer
{
}

/// Reverts the process user context to the original logon context.
/// Returns 0.
ClassMethod RevertToSelf() As %Integer
{
}

}
