/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page allows testing for SFTP server side append.
Class EnsPortal.Dialog.SFTPTest Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter PAGENAME = "SFTP Server Side Append Test";

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

XData Style
{
<style type="text/css">
	#testinformation {
			border: 1px solid darkblue;
			background: DFEFFF;
			padding: 5px;
			width: 400px;
			height: 200px;
		}
	#testnotes {
			padding: 5px;
			width: 400px;
			height: 60px;
		}
	</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="SFTP Server Side Append Test">
<hgroup align="left">
<spacer width="50"/>
<vgroup>
<spacer height="30"/>
<label id="title" align="center" value="SFTP Server Side Append Test"/>
<spacer height="30"/>
<hgroup>
<text label="Host:" id="Host" name="Host" title="IP address or name of SFTP server" size="50"/>
</hgroup>
<hgroup>
<text label="Username:" id="Username" name="Username" title="SFTP Username" size="50"/>
</hgroup>
<hgroup>
<password label="Password or Passphrase:" id="Password" name="Password" title="User password or passphrase" size="50"/>
</hgroup>
<hgroup>
<password label="SFTPPublicKeyFile:" id="SFTPPublicKeyFile" name="SFTPPublicKeyFile" title="File path to a file containing the SSH public key certificate" size="50"/>
</hgroup>
<hgroup>
<password label="SFTPPrivateKeyFile:" id="SFTPPrivateKeyFile" name="SFTPPrivateKeyFile" title="File path to a file containing the SSH private key certificate" size="50"/>
</hgroup>
<spacer height="25"/>
<button caption="Test Append" title="Press to test server side append" onclick="zenPage.ProcessTest();"/>
<spacer height="25"/>
<hgroup>
<label value="Test Results:"/> 
</hgroup>
<hgroup>
<html id="testinformation">
</html>
</hgroup>
<spacer height="25"/>
<html id="testnotes">
 This test creates and tries to issue a server side append to the remote file 'testtodelete.ignore' before deleting it.
</html>
</vgroup>
</hgroup>
</page>
}

Method ProcessTest() [ ZenMethod ]
{
	Try {
		Set htmlOutput = %page.%GetComponentById("testinformation")
		Set htmlOutput.content=""
		Set tHost = %page.%GetComponentById("Host").value
		Set tUsername = %page.%GetComponentById("Username").value
		Set tPassword = %page.%GetComponentById("Password").value
		Set tSFTPPublicKeyFile = %page.%GetComponentById("SFTPPublicKeyFile").value
		Set tSFTPPrivateKeyFile = %page.%GetComponentById("SFTPPrivateKeyFile").value
		Set tResult = ..TestSFTPServerAppend(tHost,tUsername,tPassword,tSFTPPublicKeyFile,tSFTPPrivateKeyFile,,0,.tInformation)
		Set:(tInformation = "") tInformation = " No further information from diagnostic call"
		Set htmlOutput.content = $S(tResult=1:"Server side append test was a success to ",1:"Server side append test failed to ")_tHost_"<br><br>"_$REPLACE(tInformation,$C(13,10)," ")
	}	Catch(ex) { 
		// Display the server side error to the client
		&js<alert('Error in Server method:\n#($ZCVT(ex.DisplayString(),"O","JS"))#');>
	}
	Quit
}

/// This method tests if the SFTP server supports 
/// server side APPEND command.
ClassMethod TestSFTPServerAppend(pHost As %String = "", pUser As %String = "", pPassword As %String = "", pPublicKey As %String = "", pPrivateKey As %String = "", pRemoteTempNameToDelete As %String = "testtodelete.ignore", pVerbose As %Boolean = 1, Output pInformation As %String) As %Boolean
{
	/*
	This is a test to see if the remote SFTP server support server side APPEND command
	It creates a file with one X and puts it twice to the remote server.
	It then retrieves and examines if there are 2 Xs.
	pRemoteTempNameToDelete is the name of file that will be made temporarily on the remote SFTP server 
	*/
	Set tSC=$$$OK
	Set tSuccess=0,pInformation=""
	If pHost="" {
		Set pInformation = $$$Text("Please provide a host to connect to.")
		Set pInformation = pInformation_" "_$$$Text("Parameters are: Host (required),User,Password or Passphrase,PublicKey or blank,PrivateKey or blank,Remote temporary file name to create(optional),Verbose true or false (optional), output information")
		Write:pVerbose pInformation
		Quit tSuccess
	}
	Set tSession=##class(%Net.SSH.Session).%New()
	Set tSC=tSession.Connect(pHost)
	If 'tSC {
		Set pInformation=$$$Text("Failed to Create initial connection to SFTP server")_" "_pHost
		Write:pVerbose pInformation ,!
		Quit tSuccess
	}
	If (""'=pPublicKey)&&(""'=pPrivateKey)  {
		Set tSC=tSession.AuthenticateWithKeyPair(pUser,pPublicKey,pPrivateKey,pPassword)
	} Else {
		Set tSC=tSession.AuthenticateWithUsername(pUser,pPassword)
	}
	Set tSC=tSession.VersionInfo(.tClientVersion,.tServerVersion)
	Set tSC=tSession.OpenSFTP(.sftp)
	If 'tSC {
		Set pInformation=$$$Text("Failed to Authenticate to SFTP server")_" "_pHost_" "_$$$Text("with user")_": "_pUser
		Write:pVerbose pInformation ,!
		Quit tSuccess
	}
	/*
	Create 1 file locally.
	Put it remotely twice
	Get the file back
	Check Contents
	*/
	Set tLocalFilenamePut=##class(%File).TempFilename("sftp")
	Open tLocalFilenamePut:"WNU":1
	If $Test {
		Use tLocalFilenamePut Write "X" Close tLocalFilenamePut
	} Else {
		Set pInformation=$$$Text("Failed to create temporary local file")_" "_tLocalFilenamePut
		Write:pVerbose pInformation,!
		Quit tSuccess
	}
	Set tLocalFilenameGet=##class(%File).TempFilename("sftp")
	Try {
		Set tSC=sftp.Put(tLocalFilenamePut,pRemoteTempNameToDelete,)
		Set tSC=sftp.Put(tLocalFilenamePut,pRemoteTempNameToDelete,,1)
		Set tSC=sftp.Get(pRemoteTempNameToDelete,tLocalFilenameGet)
		Open tLocalFilenameGet:"RU":1
		If $Test {
			Use tLocalFilenameGet Read tX Close tLocalFilenameGet
			If tX="XX" {
				Set pInformation = pInformation_$C(13,10)_$$$Text("The remote SFTP server appears to support server Side Append.")
				Set pInformation = pInformation_$C(13,10)_$$$Text("In order to use server side append select Server")
				Set tSuccess=1 
			} Else {
				Set pInformation = pInformation_$C(13,10)_$$$Text("The remote SFTP server does not support server side Append.")
				Set pInformation = pInformation_$C(13,10)_$$$Text("This means that the adapter will need to do the appending locally.")
				Set pInformation = pInformation_$C(13,10)_$$$Text("This is the default behaviour or you can select Client.")
			}
			Set pInformation= pInformation_$C(13,10)_$$$Text("The SSH client version is")_" "_tClientVersion
		} Else {
			Set pInformation = pInformation_" "_$$$Text("Failed to read temporary retrieved file")_" "_tLocalFilenameGet 
		}
		/* Delete to cleanup */
		Set tSC=sftp.Delete(pRemoteTempNameToDelete)
		/* Test if file still there. If it is it is an indication that need kit with at least Upgrade to libssh2-1.4.2 */
		Set tSC=sftp.FileInfo(pRemoteTempNameToDelete,.tList)
		If $D(tList) Set pInformation = pInformation_" *** "_$$$Text("It appears the delete of the temporary file failed. Check your instance installs at least libssh2-1.4.2 (internal ref DMC839)")_" ***"
	} Catch e {
		Set pInformation = pInformation_" "_$$$Text("Error")_": "_e.DisplayString()
	}
	Write:pVerbose pInformation,!
	Do ##class(%File).Delete(tLocalFilenamePut)
	Do ##class(%File).Delete(tLocalFilenameGet)
	Quit tSuccess
}

}
