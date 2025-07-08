/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Component manager class
Class %Installer.Component Extends (%RegisteredObject, %XML.Adaptor) [ ServerOnly = 1, System = 3 ]
{

Property Name As %String;

Property Version As %String;

Property Prerequisites As list Of Component;

/// Minimum version for other components when installing this component
Property Compatibility As list Of Component;

/// List is used to keep track of a list of components
Property List As list Of Component;

/// Call ##class(Installer.Install).OnInstallComponent in the corresponding database
ClassMethod InstallComponent(pDB = "", pVerbose = 0, pDev = 0) As %Status
{
	quit:pDB="" $$$ERROR($$$GeneralError,"No database defined")
	try {
		set tSC=$$$OK
		new $namespace
		set $namespace = "^^"_$zu(12)_$zcvt(pDB,"l")
		Set tSC=##class(Installer.Install).OnInstallComponent(pDB,pVerbose,pDev)
		#; potentially the OnInstallComponent has left us in a different database
		set $namespace = "^^"_$zu(12)_$zcvt(pDB,"l")
		if $$$ISOK(tSC) do ..InstallUpdateINI()
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

/// Call ##class(Installer.Install).OnUnInstallComponent in the corresponding database
ClassMethod UnInstallComponent(pDB = "", pVerbose = 0) As %Status
{
	quit:pDB="" $$$ERROR($$$GeneralError,"No database defined")
	try {
		set tSC=$$$OK
		new $namespace
		set $namespace = "^^"_$zu(12)_$zcvt(pDB,"l")
		set tSC=##class(Installer.Install).OnUnInstallComponent(pDB)
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

/// Add mappings for a Namespace and additional configuration items
ClassMethod ConfigureComponent(pDB = "", pNamespace = "", pVerbose = 0, ByRef pVars) As %Status
{
	quit:pDB="" $$$ERROR($$$GeneralError,"No database defined")
	try {
		set tSC=$$$OK
		new $namespace
		set $namespace = "^^"_$zu(12)_$zcvt(pDB,"l")
		try {
			#; introduced a new parameter, catch if it throws an error and try without
			Set tSC=##class(Installer.Install).OnConfigureComponent(pNamespace,pVerbose,.pVars)
		} catch {
			set tSC=##class(Installer.Install).OnConfigureComponent(pNamespace,pVerbose)
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

/// Remove mappings for a Namespace (to a component)
ClassMethod UnconfigureComponent(pDB = "", pNamespace = "", pVerbose = 0, pPurgeFiles = 0, ByRef pVars) As %Status
{
	quit:pDB="" $$$ERROR($$$GeneralError,"No database defined")
	try {
		set tSC=$$$OK
		new $namespace
		set $namespace = "^^"_$zu(12)_$zcvt(pDB,"l")
		try {
			#; introduced a new parameter, catch if it throws an error and try without
			Set tSC=##class(Installer.Install).OnUnconfigureComponent(pNamespace,pVerbose,pPurgeFiles,.pVars)
		} catch {
			Set tSC=##class(Installer.Install).OnUnconfigureComponent(pNamespace,pVerbose,pPurgeFiles)
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

/// Version of the installed Component version
ClassMethod ComponentVersion(pDB = "", pVersion = "") As %Status
{
	Set pVersion="",tSC=$$$OK
	Quit:pDB="" $$$ERROR($$$GeneralError,"No database defined")
	try {
		Set tSC=$$$OK
		New $namespace
		Set tTo=$S($E(pDB)="^":pDB,1:"^^"_$zu(12)_$zcvt(pDB,"l"))
		Set $namespace=tTo
		try {
			Set tSC = ##class(Installer.Install).OnComponentVersion(.pVersion)
			Set tSC = ##class(Installer.Install).OnComponentMaintenanceVersion(.tMaintVersion)
			
		} catch {
			set tSC=$$$ERROR($$$ObjectScriptError,$ze)
		}
		Set:$$$ISERR(tSC) pVersion = $parameter("Installer.Install","Version"),tMaintVersion=$parameter("Installer.Install","MaintenanceVersion"),tSC=$$$OK
		Set pVersion=pVersion_"."_$g(tMaintVersion,0)
		;
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit tSC
}

ClassMethod InstallUpdateINI(pFileName = "Components.ini", pDirectory = {$system.Util.DataDirectory()})
{
	try {
		Set tSC = ..GetXDataAsStreamWithSubstitutions("XData://Installer.Install:InstallationInfo",.tStream)
		Quit:$$$ISERR(tSC)
		Set tReader = ##class(%XML.Reader).%New()
		Do tReader.Correlate("Component", "%Installer.Component")
		Do tReader.OpenStream(tStream)
		If tReader.Next(.tComponent, .tSC) {
			Do ..UpdateComponentINI(tComponent,pFileName,pDirectory)	
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit tSC
}

ClassMethod BuildUpdateINI(pFileName = {"Component_"_$namespace_".ini"})
{
	try {
		Set tSC = ..GetXDataAsStreamWithSubstitutions("XData://Installer.Install:InstallationInfo",.tStream)
		Quit:$$$ISERR(tSC)
		Set tReader = ##class(%XML.Reader).%New()
		Do tReader.Correlate("Component", "%Installer.Component")
		Do tReader.OpenStream(tStream)
		If tReader.Next(.tComponent, .tSC) {
			Do ..UpdateComponentINI(tComponent,pFileName,,1)
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit tSC
}

ClassMethod GetXDataAsStreamWithSubstitutions(pXData, ByRef pStream) As %Status
{
	try {
		If pXData'[":" {
			Set tClassname=$classname()
			Set tNode=pXData
		} Else {
			Set tClassname=$p($p(pXData,"//",2),":")
			Set tNode=$p($p(pXData,"//",2),":",2)
		}

		Set tClass=##class(%Dictionary.ClassDefinition).%OpenId(tClassname,0,.tSC)
		If $$$ISERR(tSC) Quit
		Set tStream=$$$NULLOREF		
		Do {
			Set tIndex = tClass.XDatas.FindObjectId(tClassname_"||"_tNode)
			If tIndex'="" {
				#; Get XDATA as stream
				Set tStream = tClass.XDatas.GetAt(tIndex).Data
				Quit:$IsObject(tStream)
			}
			#; If not found in ClassDefinition, try in CompiledClass		
			Set tClass=##class(%Dictionary.CompiledClass).%OpenId(tClassname,0,.tSC)
			If $$$ISERR(tSC) Quit
	
			Set tIndex = tClass.XDatas.FindObjectId(tClassname_"||"_tNode)
			If tIndex'="" {
				#; Get XDATA as stream
				Set tStream = tClass.XDatas.GetAt(tIndex).Data
				Quit
			}
		} While 0

		If '$IsObject(tStream) Set tSC=$$$ERROR($$$GeneralError,"XData not found") Quit
	
		New %expression,%value
		Set tString=tStream.Read(30000000000)
		For  {
			Set tPos=$f(tString,"{$expression{")
			Quit:'tPos
			Set tPosEnd=$f(tString,"}}",tPos)
			Quit:'tPosEnd
			Set %expression=$e(tString,tPos,tPosEnd-3)
			X "Set %value="_%expression
			Set tString=$e(tString,1,tPos-14)_%value_$e(tString,tPosEnd,*)
		}
		For  {
			Set tPos=$f(tString,"{$method{")
			Quit:'tPos
			Set tPosEnd=$f(tString,"}}",tPos)
			Quit:'tPosEnd
			Set %expression=$e(tString,tPos,tPosEnd-3)
			X "Set %value="_%expression
			Set tString=$e(tString,1,tPos-10)_%value_$e(tString,tPosEnd,*)
		}
		Set pStream=##class(%Stream.GlobalCharacter).%New()
		Do pStream.Write(tString),pStream.Rewind()
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit tSC
}

ClassMethod UpdateComponentINI(pComponent As Component, pFile = "Components.ini", pDirectory = {$zu(12)_"utils/"}, pFromBuild = 0) As %Status
{
	Set tSC=$$$OK
	try {
		#dim tList as List of Component
		Set tSC = ##class(%File).CreateDirectoryChain(pDirectory) Quit:$$$ISERR(tSC)
		Set tSC = ..LoadComponentINI(.tList,pFile,pDirectory)
		Quit:$$$ISERR(tSC)
		Set tFound=0
		For tIdx = 1:1:tList.Count() {
			If $zcvt(tList.GetAt(tIdx).Name,"U")=$zcvt(pComponent.Name,"U") Do tList.RemoveAt(tIdx),tList.InsertAt(pComponent,tIdx) Set tFound=1 Quit
		}
		If 'tFound do tList.Insert(pComponent)
		Set pDirectory=##class(%File).NormalizeDirectory(pDirectory)
		Set tFileObject=##class(%File).%New(pDirectory_pFile)
		Do tFileObject.Open("NWS")
		For tIdx = 1:1:tList.Count() {
			#dim tItem as Component
			Set tItem=tList.GetAt(tIdx)
			Do tFileObject.WriteLine("["_$zcvt(tItem.Name,"U")_"]")
			Do:pFromBuild tFileObject.WriteLine("CompiledOnVersion="_$system.Version.GetMajor()_"."_$system.Version.GetMinor()_"."_$S($system.Version.GetPoint()="":"0",1:$system.Version.GetPoint()))
			Do ..ComponentVersion(tItem.Name,.tVersion)
			Do tFileObject.WriteLine("Version="_tVersion)
			For tIdxC=1:1:tItem.Compatibility.Count() {
				Set tCompatibilityItem = tItem.Compatibility.GetAt(tIdxC)
				Do tFileObject.WriteLine("Compatibility_"_$zcvt(tCompatibilityItem.Name,"U")_"="_tCompatibilityItem.Version)
			}
			For tIdxC=1:1:tItem.Prerequisites.Count() {
				Set tPrerequisiteItem = tItem.Prerequisites.GetAt(tIdxC)
				Do tFileObject.WriteLine("Prerequisites_"_$zcvt(tPrerequisiteItem.Name,"U")_"="_tPrerequisiteItem.Version)
			}
		}		
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit tSC
}

ClassMethod LoadComponentINI(ByRef pList, pFile = "Components.ini", pDirectory = {$zu(12)_"utils/"}) As %Status
{
	Set tSC=$$$OK
	try {
		Set tThis=..%New()
		Set pList=tThis.List,tComponent=""
		Set pDirectory=##class(%File).NormalizeDirectory(pDirectory)
		Set tFileObject=##class(%File).%New(pDirectory_pFile)
		If tFileObject.Size=0 Quit
		Do tFileObject.Open("R")
		For  {
			Quit:tFileObject.AtEnd
			Set tLine=tFileObject.ReadLine()
			If $E(tLine)="[" {
				Set tComponent=##class(Component).%New()
				Set tComponent.Name=$E(tLine,2,*-1)
				Do pList.Insert(tComponent)
				continue
			} 
			If '$IsObject(tComponent) Continue
			Set tItem=$zstrip($zcvt($p(tLine,"="),"l"),"<>W")
			Set tValue=$p(tLine,"=",2)
			If $L(tItem,"_")>1 {
				Set tItemValue=$p(tItem,"_",2)
				Set tCompatibleComponent=..%New()
				Set tCompatibleComponent.Version=tValue
				Set tCompatibleComponent.Name=$zstrip($p($p(tLine,"_",2),"="),"<>W")
			}
			If tItem="version" {
				Set tComponent.Version=tValue
			} ElseIf $p(tItem,"_")="compatibility" {
				Do tComponent.Compatibility.Insert(tCompatibleComponent)
			} ElseIf $p(tItem,"_")="prerequisites" {
				Do tComponent.Prerequisites.Insert(tCompatibleComponent)
			}
		}
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ze)
	}
	Quit tSC
}

}
