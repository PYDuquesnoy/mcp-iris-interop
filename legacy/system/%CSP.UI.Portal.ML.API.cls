/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %CSP.Portal.System

/// This class defines Machine Learning UI APIs used by the Systems Management Portal
Class %CSP.UI.Portal.ML.API [ Abstract ]
{

/// This method returns all values of ML configurations.
/// 
ClassMethod GetMLConfigs(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""
		
		Set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:MLConfigurationsFull")
		Set tSC = tRS.Execute()
		If $$$ISERR(tSC) {
			Set pObject.error = $System.Status.GetErrorText(tSC)
			Quit	
		}
		Set pObject.children = ##class(%ListOfObjects).%New()
		While tRS.Next() {
			Set tName = tRS.Data("NAME")
			Do pObject.children.Insert(..GetMLConfig(tName))
		}		
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// Given a ML config name, return proxy object with details for this config.<br>
/// This method is also called from %CSP.UI.Portal.ML.Configuration page directly.
ClassMethod GetMLConfig(pName As %String) As %ZEN.proxyObject
{
	Try {
		Set tChildObj = ##class(%ZEN.proxyObject).%New()
		Set tChildObj.error = ""	
		Set tContainer = ##class(%SYS.ML.Configuration).NameIndexOpen(pName,,.tSC)
		If '$IsObject(tContainer) {
			Set tChildObj.error = $System.Status.GetErrorText(tSC)
		} Else {
			Set tChildObj.Name = tContainer.Name
			Set tChildObj.Type = tContainer.Type
			Set tChildObj.Description = tContainer.Description
			Set tChildObj.Using = tContainer.Using
			Set tChildObj.Owner = tContainer.Owner
			If tContainer.Type = 1 {
				Set tChildObj.javaTlsConfigFile = tContainer.javaTlsConfigFile
			} ElseIf tContainer.Type = 2 {
				Set tChildObj.url = tContainer.url
				Set tChildObj.apiToken = tContainer.apiToken
			} ElseIf tContainer.Type = 4 {
				Set tChildObj.url = tContainer.url
				Set tChildObj.jvmOpt = tContainer.jvmOpt
				Set tChildObj.progOpt = tContainer.progOpt
			}
		}
	} Catch ex {
		Set tChildObj.error = ex.AsStatus()
	}
	Quit tChildObj
}

}
