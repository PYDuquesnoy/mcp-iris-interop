/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a "Configuration" activity within a Manifest document
Class %Installer.Configuration Extends %Installer.Sequence [ ServerOnly = 1, System = 3 ]
{

/// Generate code for this document.
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	#dim tSC As %Status
	#dim tChild As %XGEN.AbstractElement
	#dim tClass As %String
	#dim tItem As %String
	#dim tItems,i
	
	Set tSC = $$$OK
	Do {
		// Disable processing of the children, we'll do it!
		Set ..skipChildren = 1
		Do pCode.WriteLine(..%Indent()_"Try {")
		
		// Sort items by type
		For i=1:1:..children.Count() {
			Set tChild = ..children.GetAt(i)
			Set tClass = tChild.%ClassName(0)
	
			// Now, do these in the right sequence, Databases first
			If tClass="Database" {
				Set tSC = ..generateCode(tChild,pTargetClass,pCode,pDocument)
				Quit:$$$ISERR(tSC)
			} Else {
				// Hold on to the other types ...
				Set tItems(i) = tChild
			}
		}
		
		// Next, we can create the namespace!
		Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.CreateNamespace(tNSName,tNSCodeDB,tNSDataDB,tNSFlags)")
		Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.ActivateConfiguration(tNSName)")
		
		// Now, any remaining elements
		Set tItem = ""
		For {
			Set tItem = $ORDER(tItems(tItem))
			Quit:tItem=""
			
			Set tSC = ..generateCode(tItems(tItem),pTargetClass,pCode,pDocument)
			Quit:$$$ISERR(tSC)
		}
	} While(0)
	
	Quit tSC
}

/// Generate code for a specific item
Method generateCode(pNode As %XGEN.AbstractElement, pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Set pNode.%level = ..%level + 1
	Quit pNode.%GenerateCode(pTargetClass,pCode,pDocument)
}

/// Generate code for this document.
Method %OnAfterGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(1)_"Do:tNSEnsemble tInstaller.EnableEnsemble(tNSName,tNSEnsPortalSuffix,tNSEnsPortalPrefix,tNSEnsPortalGrant,tNSEnsPortalCookiePath,tNSEnsPortalAuthMethods)")
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.ActivateConfiguration(tNSName)")
	Do pCode.WriteLine(..%Indent()_"} Catch (ex) {")
	Do pCode.WriteLine(..%Indent(1)_"// Configuration failed!")
	Do pCode.WriteLine(..%Indent(1)_"Set tSC = ex.AsStatus()")
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.Log(0,"""_pTargetClass.Name_""",$system.Status.GetErrorText(tSC))")
	Do pCode.WriteLine(..%Indent(1)_"Throw ##class(%Installer.Exception).%New(""%Installer.Exception"",""<Ins>ConfigFailed"",,,ex)")
	Do pCode.WriteLine(..%Indent()_"}")
	Quit $$$OK
}

}
