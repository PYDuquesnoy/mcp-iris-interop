/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Database" activity within a Manifest document
Class %Installer.Database Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Database "logical" name, for example USER or ENSDEMO
Property Target As %String(XMLNAME = "Name") [ Required ];

/// Database location on the filesystem.
Property Dir As %String(MAXLEN = 195) [ Required ];

/// Database creation flags:<br/>
/// yes - Must always create the database, will fail if already exists<br/>
/// no  - Database must already exist<br/>
/// overwrite - Overwrite if present, or create a new one.
Property Create As %String(VALUELIST = ",yes,no,overwrite") [ InitialExpression = "yes" ];

/// Database Resource required to access this database, for example %DB_%DEFAULT
Property Resource As %String(MAXLEN = 64);

/// Public Permissions, zero or more of "R", "W", "U"
Property PublicPermissions As %String(MAXLEN = 8);

/// Enable encryption for this database
Property Encrypted As %Installer.Boolean;

/// The encryption key id for an encrypted database
Property EncryptionKeyID As %String(MAXLEN = 256);

/// Database block size
Property BlockSize As %Installer.Integer(VALUELIST = ",4096,8192,16384,32768,65536");

/// Initial database size (in MB)
Property InitialSize As %Installer.Integer(MINVAL = 1);

/// Maximum database size (in MB)
Property MaximumSize As %Installer.Integer(MINVAL = 1);

/// Expansion size (i.e. by how many MB should the DB get expanded when it fills)
Property ExpansionSize As %Installer.Integer(MINVAL = 1);

/// Database collation
Property Collation As %String;

/// Directory where the streams associated with this database go.<br>
/// By default (value=""), the location is in the subdirectory "stream", underneath the
/// database directory, e.g. for a database located in c:\abc, the default would be
/// c:\abc\stream. InterSystems recommends leaving this parameter as "".<br>
Property StreamLocation As %String;

/// Specifies whether the database should be mounted privately or clustered.<br>
/// 0 - Mount private<br>
/// 1 - Mount clustered<br>
Property ClusterMountMode As %Installer.Boolean;

/// Specifies whether the database should be mounted at startup.<br>
/// 0 - Don't mount at startup<br>
/// 1 - Mount at startup<br>
Property MountAtStartup As %Installer.Boolean;

/// Specifies that the database MUST be successfully mounted at startup.<br>
/// 0 - Successful mount not required for startup to succeed.<br>
/// 1 - Successful mount required for startup to succeed.<br>
Property MountRequired As %Installer.Boolean;

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.CreateDatabase($$$EVAL("_..Target_"),$$$EVAL("_..Dir_"),$$$EVAL("_..Create_"),$$$EVAL("_..Resource_"),$$$EVAL("_..PublicPermissions_"),$$$EVAL("_..Encrypted_"),$$$EVAL("_..EncryptionKeyID_"),$$$EVAL("_..BlockSize_"),$$$EVAL("_..InitialSize_"),$$$EVAL("_..MaximumSize_"),$$$EVAL("_..ExpansionSize_"),$$$EVAL("_..Collation_"),$$$EVAL("_..StreamLocation_"),$$$EVAL("_..ClusterMountMode_"),$$$EVAL("_..MountAtStartup_"),$$$EVAL("_..MountRequired_"))")
	Quit $$$OK
}

}
