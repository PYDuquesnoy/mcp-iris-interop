/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Messaging.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Additional Gateway class paths delimited by "|"
Property ExtraClasspaths As %String(MAXLEN = 1000);

Parameter SETTINGS = "ExtraClasspaths:Gateway Settings,-%remoteClassname,-%remoteSettings,-%gatewayName,-%gatewayHost,-%gatewayPort,-%gatewayTimeout,-%gatewayExtraClasspaths,-%useHostConnection";

Method GetMessagingClientJARPaths() As %String
{
	Set paths = ""
	Try {
		Set jarDir = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/1.8")

		// Get utils JAR paths
		Set utilsJARpath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-utils"), jarDir)
		Set utilsJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(utilsJARpath)
		
		// Get messaging JAR paths
		Set messagingJARpath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-messaging"), jarDir)
		Set messagingJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(messagingJARpath)
		
		Set paths = utilsJARpath_"|"_messagingJARpath_$SELECT(..ExtraClasspaths="":"", 1:"|"_..ExtraClasspaths)
	}
	Catch (ex) {
		Set paths = ""
	}
	Quit paths
}

Method getCredentials(credentials As %String) As %List
{
	Set tSC = ##Class(Ens.Config.Credentials).GetCredentialsObj(.credentialsObj,$classname($this),"Ens.Config.Credentials", credentials)
	Quit $S($$$ISERR(tSC):$LB(), 1:$LB(credentialsObj.Username,credentialsObj.Password))
}

}
