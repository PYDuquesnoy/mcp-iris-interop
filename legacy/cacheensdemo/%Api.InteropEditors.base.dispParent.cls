/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Api.InteropEditors.base.dispParent Extends %REST.disp [ System = 4 ]
{

/// Override AccessCheck - only Rule APIs supported by this REST dispatch class.
/// Access check will be expanded when different APIs.
ClassMethod AccessCheck(Output pAuthorized As %Boolean = 0) As %Status [ Internal ]
{
	Set sc=$$$OK
	Try {
		Set perms = ##class(%Api.InteropEditors.Utils).GetRulePerms()
		Set pAuthorized = ##class(%Api.InteropEditors.Utils).HasPermsByRuleType("*", "R", perms)||##class(%Api.InteropEditors.Utils).HasPermsByRuleType("*", "W", perms)
	} Catch (ex) {
		set sc=ex.AsStatus()
	}
	quit sc
}

/// This OnPreDispatch assumes any version prefix of the URL has already been removed
/// and therefore takes namespace from the 2nd part
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status [ Internal ]
{
	// Copied from %REST.disp and altered to call the overridden %AdjustNamespace in this class
	If pUrl="/" {
		Set namespace="%SYS"
	} Else {
		Set namespace=$piece(pUrl,"/",2)
	}
	If '..%AdjustNamespace(namespace,0) {
		Set pContinue=0
	}
	Quit $$$OK
}

/// Change to run in specified namespace.
ClassMethod %AdjustNamespace(namespace As %String, updateRequired As %Boolean) As %Boolean [ Internal ]
{
    // Make sure that we are running in an accessible namespace.
    Try {
		/*	Need to change to appropriate namespace here
			except do not change into %SYS since the user may
			not have privileges but all %SYS endpoint operations
			ought to run from any namespace.
			REST landing namespace for this app is %SYS.
		*/
		If ($ZCVT(namespace,"U")'="%SYS") {
			Set $namespace=namespace
		}
		Set sc=$$$OK
	} Catch ex {
		Do ##class(%REST.Utils).LogError("[%Api.InteropEditors.base.dispParent:%AdjustNamespace]","Unable to change namespace. namespace="_namespace_", $namespace="_$namespace_", $roles="_$roles)
		Set sc=$$$ERROR($$$RESTBadNamespace,namespace)
		If ex.Name="<PROTECT>" {
			Set httpError = "HTTP403FORBIDDEN"
		} ElseIf ex.Name="<NAMESPACE>" {
			Set httpError = "HTTP404NOTFOUND"
		} Else {
			Set httpError = "HTTP500INTERNALSERVERERROR"
		}
		Set restError = ##class(%Api.InteropEditors.v2.impl).%ReportRESTError($parameter("%CSP.REST",httpError),, ##class(%Api.InteropEditors.v2.impl).#ExposeServerExceptions, $$$ERROR($$$RESTBadNamespace,namespace))
		Do restError.%ToJSON()
	}
	Quit $$$ISOK(sc)
}

}
