/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.Amazon.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// AWS credentials file.
/// To use the default AWS credentials provider chain, leave this field blank.
Property CredentialsFile As %String(MAXLEN = 1000);

/// AWS region. For example, us-east-1, us-east-2, us-west-1, us-west-2 etc.
/// For details, please refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
Property Region As %String(MAXLEN = 100);

Parameter SETTINGS = "CredentialsFile:AWS:fileSelector,Region:AWS,-%remoteClassname,-%remoteSettings,-%gatewayName,-%gatewayHost,-%gatewayPort,-%gatewayTimeout,-%gatewayExtraClasspaths,-%useHostConnection";

ClassMethod GetCloudClientJARPaths() As %String
{
	Set paths = ""
	Try {
		Set jarDir = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/1.8")

		// Get utils JAR paths
		Set utilsJARpath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-utils"), jarDir)
		Set utilsJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(utilsJARpath)
		
		// Get cloudclient JAR paths
		Set cloudJARpath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-cloudclient"), jarDir)
		Set cloudJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(cloudJARpath)
		
		Set paths = utilsJARpath_"|"_cloudJARpath
	}
	Catch (ex) {
		Set paths = ""
	}
	Quit paths
}

ClassMethod GetMessagingClientJARPaths() As %String
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
		
		Set paths = utilsJARpath_"|"_messagingJARpath
	}
	Catch (ex) {
		Set paths = ""
	}
	Quit paths
}

}
