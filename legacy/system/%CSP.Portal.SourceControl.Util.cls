/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.Portal.SourceControl.Util [ Abstract, System = 4 ]
{

/// Return a project's full name, including a ".PRJ" extension.
ClassMethod GetFullProjectName(pProjectName As %String = "") [ CodeMode = expression ]
{
$select(pProjectName = "": "", $zcvt($extract(pProjectName,*-3,*),"U") = ".PRJ": pProjectName, 1: pProjectName _ ".PRJ")
}

/// Create an instance of a Source Control object
ClassMethod CreateSourceControl(Output pSourceControl As %Studio.SourceControl.Base, Output pCreated As %Boolean, Output pUsername As %String, pUserData As %ZEN.proxyObject = "") As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pSourceControl = ""
		Set pCreated = 0
		Set pUsername = $username
		
		Set tClass = ..GetSourceControlClass()
		If tClass = "" Quit
		
		New %objlasterror
		Set pSourceControl = $classmethod(tClass,"%New",$listbuild(pUsername, ""))
		If pSourceControl = "" {
			Set tStatus = $select($get(%objlasterror) '= "": %objlasterror, 1: $$$ERROR($$$SourceControlClass,tClass))
			Quit
		}
		
		Try {
			Set tStatus = pSourceControl.OnPortalCreate(pUserData)
			If $$$ISERR(tStatus) Quit
		}
		Catch innerEx {
			If innerEx.Name '[ "<METHOD DOES NOT EXIST>" {
				Throw innerEx
			}
		}
		Set pCreated = 1
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Determine whether source control is enabled for the Management
/// Portal in the specified namespace. The default is to return the
/// flag for the current namespace.
ClassMethod IsEnabled(pNamespace As %String = {$namespace}) As %Boolean
{
	If ($system.Version.GetMajor() < 2014) {
		Quit 0
	}
	New $namespace
	Try {
		Set tReturn = 0
		If $namespace '= pNamespace {
			Set $namespace = pNamespace
		}
		Set tReturn = (..GetSourceControlClass() '= "")
	}
	Catch {
		Set tReturn = 0
	}
	Quit tReturn
}

/// Enable or disable the flag indicating whether the source control class
/// used in the current namespace requires a specific project to be selected
/// for the source control hooks to operate correctly.
ClassMethod SetProjectRequired(pNewValue As %Boolean = 0, Output pOldValue As %Boolean) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pOldValue = ''$get(^%SYS("SourceControl","Portal",$namespace,"ProjectContext"))
		Set ^%SYS("SourceControl","Portal",$namespace,"ProjectContext") = ''pNewValue
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Helper method to indicate whether the source control hooks in the current
/// production-enabled namespace need a project defined.
ClassMethod IsProjectRequired() As %Boolean
{
	Try {
		Set tRequired = 0
		If '..IsEnabled() Quit
		Set tRequired = ''$get(^%SYS("SourceControl","Portal",$namespace,"ProjectContext"))
	}
	Catch {
		Set tRequired = 0
	}
	Quit tRequired
}

/// Helper method to save the name of the current project and whether its
/// OnBeforeLoad() and OnAfterLoad() callbacks have been executed. The data is saved
/// in the current CSP session data, so will be cleaned up when the user logs out.
ClassMethod SetCurrentProject(pProjectName As %String, pLoaded As %Boolean = 0) [ ZenMethod ]
{
	If $IsObject($get(%session)) {
		Set tProjectName = ..GetFullProjectName(pProjectName)
		Set %session.Data("%ISC","Portal","SourceControl",$namespace,"Project") = tProjectName
		If pLoaded && (tProjectName '= "") {
			Set %session.Data("%ISC","Portal","SourceControl",$namespace,"Project","Loaded") = tProjectName
		}
		Else {
			Kill %session.Data("%ISC","Portal","SourceControl",$namespace,"Project","Loaded")
		}
	}
}

/// Helper method to retrieve the current project for the CSP session,
/// along with a flag to indicate whether the OnBeforeLoad() and OnAfterLoad()
/// source control hooks have been executed for the project.
ClassMethod GetCurrentProject(Output pLoaded As %Boolean) As %String [ ZenMethod ]
{
	Set pLoaded = 0
	If $IsObject($get(%session)) {
		Set tProject = ..GetFullProjectName($get(%session.Data("%ISC","Portal","SourceControl",$namespace,"Project")))
		If tProject '= "" {
			Set pLoaded = (tProject = ..GetFullProjectName($get(%session.Data("%ISC","Portal","SourceControl",$namespace,"Project","Loaded"))))
		}
		Quit tProject
	}
	
	Quit ""
}

/// Return the source control class which is to be used in the current namespace.
/// If source control hooks are not enabled, an empty string is returned.
ClassMethod GetSourceControlClass() As %String
{
	Quit ##class(%Studio.SourceControl.Interface).SourceControlClassGet()
}

/// Helper method to load a class definition from disk.
ClassMethod LoadClassDefinition(pClassname As %String, Output pDefinition As %Dictionary.ClassDefinition, Output pReadOnly As %Boolean, pExclusiveOnly As %Boolean = 0) As %Status [ Private ]
{
	Set pDefinition = ""
	Set pReadOnly = 0
	Set tStatus = $$$OK
	Set tLockTimeout = $zu(115,4)
	Try {
		// reduce the lock timeout for the first attempt to open the class definition
		Do $zu(115,4,1)
		Set pDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassname,4,.tStatus)
		If $system.Status.Equals(tStatus,$$$ERRORCODE($$$ClassExclusiveLockFailed),$$$ERRORCODE($$$CanNotLockRoutineInfo)) {
			Set pReadOnly = 1
			// Quit now if we only want exclusive -- this is used during save.
			If pExclusiveOnly Quit

			Set tStatus = $$$OK
			Set pDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassname,0,.tStatus)
		}
		If $$$ISERR(tStatus) Quit
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Do $zu(115,4,tLockTimeout)
	Quit tStatus
}

}
