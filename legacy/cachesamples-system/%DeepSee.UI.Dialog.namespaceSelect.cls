/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility dialog window displays and lets the user select from a set of available namespaces.
/// The list will not show namespaces that are not DeepSee enabled.<br/>
Class %DeepSee.UI.Dialog.namespaceSelect Extends %ZEN.Dialog.namespaceSelect
{

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("If a namespace exists but is not listed, then you may not hold permission to view it, its database may not be mounted, or it is not Analytics enabled.")
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
		Set tEnabled = $lg(NspList(tNamespace),1) && 
						##class(%DeepSee.Utils).%IsDeepSeeEnabled(tNamespace) &&
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

}
