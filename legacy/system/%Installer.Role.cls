/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Role" activity within a Manifest document
Class %Installer.Role Extends %Installer.Activity [ ServerOnly = 1, System = 3 ]
{

/// Namespace name
Property Target As %String(XMLNAME = "Name") [ Required ];

/// Role Description: Note that currently, the role description cannot be modified once created.
Property Description As %String(MAXLEN = 32000) [ Required ];

/// Resources<br>
/// 	ResourceName:Permission,ResourceName:Permission<br>
/// For example:<br>
/// 	MyResource:RW,MyResource1:RWU"<br>
Property Resources As %String(MAXLEN = 32000);

/// RolesGranted
/// Additional roles granted when this role is granted to a user<br>
Property RolesGranted As %String(MAXLEN = 32000);

/// Generate code for this document.
Method %OnGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.CreateRole($$$EVAL("_..Target_"),$$$EVAL("_..Description_"),$$$EVAL1("_..Resources_"),"""_..RolesGranted_""")")
	Quit $$$OK
}

}
