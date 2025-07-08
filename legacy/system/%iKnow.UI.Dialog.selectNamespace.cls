/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

/// This class only show the namespaced to which iKnow is enabled.
Class %iKnow.UI.Dialog.selectNamespace Extends %ZEN.Dialog.namespaceSelect [ Deprecated ]
{

Parameter DOMAIN = "%iKnow";

/// Security requirement
Parameter RESOURCE = "%Development";

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$FormatText($$$Text("If a namespace exists but is not listed, then you may not hold permission to view it, its database may not be mounted, or it is not %1 enabled."),$$$PRODUCT5)
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tCombo = ..%GetComponentById("lstBox")
	Set tSC = ##class(%CSP.Portal.Utils).%GetNamespaceList(.NspList)
	If $$$ISERR(tSC) Quit tSC
	Set tNamespace = $O(NspList(""))
	Set tDisabled = ""
	While tNamespace '= "" {
		Set tEnabled = $lg(NspList(tNamespace),1) && ..%IsiKnowEnabled(tNamespace)&&
						(tNamespace'="%SYS") &&
						(tNamespace'="DOCBOOK")
		If tEnabled = 1 {
			#;YSD2618 If $system.CSP.GetDefaultApp(tNamespace) '= "" {
			If $system.CSP.GetPortalApp(tNamespace,"%ZEN.Dialog.namespaceSelect.cls") '= "" {	
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do tCombo.options.Insert(tOption)
				Do ..%AddComponent(tOption)
				Set tOption.text = tNamespace
				Set tOption.value = tNamespace
			}
		} Else {
			Set tDisabled = tDisabled _ $S(tDisabled'="":", ",1:"")_tNamespace
		}
		Set tNamespace = $O(NspList(tNamespace))
	}

	Set:..CurrNamespace="" ..CurrNamespace = $namespace
	Set tCombo.value = ..CurrNamespace
	
	Quit $$$OK
}

ClassMethod getEnabledIKnowNS(ByRef namespaces) As %Integer
{
	Set tSC = ##class(%CSP.Portal.Utils).%GetNamespaceList(.NspList)
	If $$$ISERR(tSC) Quit tSC
	Set tNamespace = $O(NspList(""))
	Set count = 0

	While tNamespace '= "" 
	{
		Set tEnabled = $lg(NspList(tNamespace),1) && ..%IsiKnowEnabled(tNamespace)
		if tEnabled
		{
			set namespaces(tNamespace) = ""
			set count = count + 1
		} 
		Set tNamespace = $O(NspList(tNamespace))
	}
	quit count
}

ClassMethod %IsiKnowEnabled(pNamespace = "") As %Boolean
{
	// DTB073 - Provide an API to determine whether a namespace is DeepSee enabled
	Set tEnabled = 0
	if pNamespace = "%SYS" quit 0
	if pNamespace = "DOCBOOK" quit 0


	Try {
		Set tNamespace = $S(pNamespace="":$NAMESPACE,1:$$$UPPER(pNamespace))
		Set tApplication = $system.CSP.GetDefaultApp(tNamespace)
		If $E(tApplication,1)'="/" {
			Set tApplication = "/" _ tApplication
		}
		If $E(tApplication,*)'="/" {
			Set tApplication = tApplication _ "/"
		}
		Set tEnabled = $$IsIKnowEnabled^%SYS.cspServer(tApplication)
	}
	Catch {
	}
	
	Quit tEnabled
}

}
