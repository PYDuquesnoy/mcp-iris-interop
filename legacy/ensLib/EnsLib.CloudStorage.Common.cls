/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.CloudStorage.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Storage provider
Property StorageProvider As %Integer(DISPLAYLIST = ",Amazon S3,Azure Blob,Google Cloud Storage", VALUELIST = ",0,1,2") [ InitialExpression = 0 ];

/// 	PrivateLink endpoint.
/// 	
Property EndPoint As %String(MAXLEN = 1000);

/// Credentials file.
/// To use the default credentials provider chain, leave this field blank.
Property ProviderCredentialsFile As %String(MAXLEN = 1000);

/// Storage region. </br>
/// Amazon S3: us-east-1, us-east-2, us-west-1, us-west-2 etc. </br>
/// For details, please refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html </br>
/// Google Cloud Storage: ASIA, EU, US etc. </br>
/// For details, please refer to http://g.co/cloud/storage/docs/bucket-locations#location-mr </br>
/// Azure Blob: Not applicable </br>
Property StorageRegion As %String(MAXLEN = 100);

Parameter SETTINGS = "StorageProvider:Cloud Storage,EndPoint:Cloud Storage,ProviderCredentialsFile:Cloud Storage:fileSelector,StorageRegion:Cloud Storage,-%remoteClassname,-%remoteSettings,-%gatewayName,-%gatewayHost,-%gatewayPort,-%gatewayTimeout,-%gatewayExtraClasspaths,-%useHostConnection";

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

}
