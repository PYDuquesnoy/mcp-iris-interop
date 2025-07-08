/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Manifest document for a installer manifest.
Class %Installer.Manifest Extends %XGEN.AbstractDocument [ ServerOnly = 1, System = 3 ]
{

/// This is the XML namespace for INSTALLER documents.
Parameter NAMESPACE = "INSTALLER";

/// This is the XML name of this document.
Parameter XMLNAME = "Manifest";

/// This is the value to be used for the XMLNamespace keyword for XData
/// blocks containing this type of document.
Parameter XMLNAMESPACE As STRING = "INSTALLER";

Parameter ROOTCLASSES As STRING = "%Installer.Manifest:Manifest";

/// Title of this installer manifest
Property Title As %String(MAXLEN = 512);

/// Enable to capture I/O for logging purposes
Property CaptureIO As %Boolean [ InitialExpression = 0 ];

/// Generate starting code for this document.
Method %OnBeforeGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	// Process any method arguments ...
	
	/* NOTE: We used to do this, but this causes Evaluate() to be called even on unspecified values.
	         By using the ##expression syntax, we can optimize out the evaluation of any unspecified
	         values.
	         
	   Do pCode.WriteLine(..%Indent()_"#define EVAL(%x) tInstaller.Evaluate(%x)")
	*/
	Do pCode.WriteLine(..%Indent()_"#def1arg EVAL(%x) ##expression(##class(%Installer.Installer).macroArgs(%literalargs))")
	Do pCode.WriteLine(..%Indent()_"#def1arg EVAL1(%x) ##expression(##class(%Installer.Installer).macroArg($LISTTOSTRING(%literalargs,"","")))")
	Set ..%level = ..%level + 1
	Do pCode.WriteLine(..%Indent()_"Set tSC=$$$OK,tInitialNS=$NAMESPACE,tTime=$ZH,tNSName=tInitialNS")
	If ..CaptureIO {
		Do pCode.WriteLine(..%Indent()_"Use 0::(""^""_$ZNAME)")
		Do pCode.WriteLine(..%Indent()_"Do $ZU(82,12,1)")
	}
	Do pCode.WriteLine(..%Indent()_"New $NAMESPACE")
	Do pCode.WriteLine(..%Indent()_"Set $NAMESPACE=""%SYS""")
	Do pCode.WriteLine(..%Indent()_"Try {")
	Do pCode.WriteLine(..%Indent(1)_"Set tInstaller = $S($IsObject($GET(pInstaller)):pInstaller,1:##class(%Installer.Installer).%New(,.pVars,+$G(pLogLevel),.pLogger))")
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.Logger.BeginLogging()")
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.Log(0,"""_pTargetClass.Name_""",""Installation starting at ""_$zdt($h,3)_"", LogLevel=""_tInstaller.LogLevel)")
	Quit $$$OK
}

/// Generate ending code for this document.
Method %OnAfterGenerateCode(pTargetClass As %Dictionary.CompiledClass, pCode As %Stream.TmpCharacter, pDocument As %Installer.Manifest) As %Status [ Internal ]
{
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.Log(0,"""_pTargetClass.Name_""",""Installation succeeded at ""_$zdt($h,3))")
	Do pCode.WriteLine(..%Indent()_"} Catch(ex) {")
	Do pCode.WriteLine(..%Indent(1)_"Set tSC = ex.AsStatus()")
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.Log(0,"""_pTargetClass.Name_""",$system.Status.GetErrorText(tSC))")
	Do pCode.WriteLine(..%Indent(1)_"Do tInstaller.Log(0,"""_pTargetClass.Name_""",""Installation failed at ""_$zdt($h,3))")
	Do pCode.WriteLine(..%Indent(1)_"If $IsObject($GET(pInstaller)) Throw ex")
	Do pCode.WriteLine(..%Indent()_"}")
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.Logger.EndLogging()")
	If ..CaptureIO {
		Do pCode.WriteLine(..%Indent()_"Do $ZU(82,12,0)")
	}
	Do pCode.WriteLine(..%Indent()_"Do tInstaller.Log(0,""%Installer"",""Elapsed time ""_($ZH-tTime)_""s"")")
	// Namespace is restored when we leave this Do block
	Do pCode.WriteLine(..%Indent()_"Kill tInstaller")
	Do pCode.WriteLine(..%Indent()_"Quit tSC")
	If ..CaptureIO {
		Do pCode.WriteLine(..%Indent()_"wchr(s)	;")
		Do pCode.WriteLine(..%Indent()_"	Set %InstallerLogText = %InstallerLogText _ $CHAR(s)")
		Do pCode.WriteLine(..%Indent()_"	Quit")
		Do pCode.WriteLine(..%Indent()_"wff()	;")
		Do pCode.WriteLine(..%Indent()_"	Set %InstallerLogText = %InstallerLogText _ $CHAR(12)")
		Do pCode.WriteLine(..%Indent()_"	Quit")
		Do pCode.WriteLine(..%Indent()_"wnl()	;")
		Do pCode.WriteLine(..%Indent()_"	Do ..flushIO()")
		Do pCode.WriteLine(..%Indent()_"	Quit")
		Do pCode.WriteLine(..%Indent()_"wstr(s)	;")
		Do pCode.WriteLine(..%Indent()_"	Set %InstallerLogText = %InstallerLogText _ s")
		Do pCode.WriteLine(..%Indent()_"	Quit")
		Do pCode.WriteLine(..%Indent()_"wtab(s)	;")
		Do pCode.WriteLine(..%Indent()_"	Set:s<$L(%InstallerLogText) %InstallerLogText = %InstallerLogText _ $J("",s-$L(%InstallerLogText))")
		Do pCode.WriteLine(..%Indent()_"	Quit")
	}
	Quit $$$OK
}

}
