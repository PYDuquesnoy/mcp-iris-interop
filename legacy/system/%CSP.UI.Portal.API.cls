/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %CSP.Portal.System

/// This class defines system APIs used by the Systems Management Portal
Class %CSP.UI.Portal.API [ Abstract ]
{

/// This method returns system information used by the System Manager Portal's About page.
/// It also includes additional data about the system useful for WRC.
/// 
ClassMethod GetSystemInfo(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.error = ""

		///////////////////////////
		///      About Info    ////
		///////////////////////////
		Set InstalledProduct = $System.Version.GetISCProduct()		
		Set ComponentVersionList = ""
		Set CacheVerStr = $ZVersion

		Try {
			; Check if the installed product is HealthShare
			If (InstalledProduct = $$$HealthShareProductKey) && ##class(%ZHSLIB.HealthShareMgr).IsHealthShareInstance() {
				Set CacheVerStr = ##class(%ZHSLIB.HealthShareMgr).VersionInfo()
			}
		}
		Catch {}
		Set ComponentVersionList = $System.Version.GetISCComponentVersionList(InstalledProduct)
		Set ComponentVersionList = $ListToString(ComponentVersionList,"|",1)

		If ComponentVersionList '= "" {
			Set pObject.modules = ##class(%ListOfObjects).%New()
			Set Len = $Length(ComponentVersionList,"|")
			For i = 1:1:Len {
				Set Comp = $Piece(ComponentVersionList,"|",i) 
				Set tComponent = ##class(%ZEN.proxyObject).%New()
				Set tComponent.module = $Piece(Comp,":",1)
				Set tComponent.version = $Piece(Comp,":",2)
				Do pObject.modules.Insert(tComponent)
			}
		}
		Set WebPortStatus = ##class(%RoutineMgr).GetWebServerPort(.WebPort)
		Set pObject.CacheVerStr = CacheVerStr
		Set pObject.Cluster = ##Class(%SYS.ClusterInfo).NodeStatus()
		Set pObject.Configuration = $p($zu(86),"*")
		Set pObject.DatabaseCache = ##Class(%SYS.System).GetGlobalCache()
		Set pObject.RoutineCache = ##Class(%SYS.System).GetRoutineCache()
		Set pObject.Mirror = ##class(%CSP.UI.System.Mirror).MemberStatus()
		Set pObject.CurrentJournalFile = ##class(%SYS.Journal.System).GetCurrentFileName()
		Set pObject.SuperserverPort = ##class(%SQL.Manager.API).GetPort()
		Set pObject.WebPort = WebPort
		Set pObject.WebPortStatus = WebPortStatus
		Set pObject.LicenseServer = $$GetLicenseServer^%SYS.LICENSE
		Set pObject.LicenseTo = $$DisplayName^%SYS.LICENSE
		Set pObject.TimeSince = $ZDT(..TimeSince(),3)
		Set pObject.DBEncKeyID = $System.Security.System.GetDBEncKeyID()
		Set pObject.NLSLOCALE = $ZCVT(^|"^^"_$zu(12)|%SYS("LOCALE","CURRENT"),"U")

		////////////////////////////
		///     Support Info     ///
		////////////////////////////

		Set HostName = $System.INetInfo.LocalHostName()	
		Set IPAddress = $$$HostNameToIPText(HostName,0)
				
		Set pObject.IPAddress = IPAddress
		Set pObject.CacheVerNumber = $System.Version.GetNumber()
		Set pObject.ComponentVersionList = ComponentVersionList
		Set pObject.DisplayProductName = $Case(InstalledProduct,$$$IRISProductKey:"InterSystems IRIS",$$$CacheProductKey:"Caché",$$$EnsembleProductKey:"Ensemble",$$$HealthShareProductKey:"HealthShare",:InstalledProduct)
		Set pObject.HostName = HostName
		Set pObject.IPAddress = IPAddress
		Set pObject.InstalledProduct = InstalledProduct
		Set pObject.OS = $System.Version.GetCompBuildOS()
		Set pObject.Username = $Username		
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// This entry returns information needed by the Contact WRC page for sending new WRC issue email.<br/>
/// "minib" will be displayed as the default system info for the mail body.<br/>
/// Support can add or remove entries from here.
ClassMethod GetInfoForContactWRC(Output pObject As %ZEN.proxyObject) As %Status
{
	Try {
		Set tSC = $$$OK
		Set pObject = $$$NULLOREF
		Set tSC = ..GetSystemInfo(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
		Set tMinib = "[user_info] %0D"
		If $IsObject(pObject.modules) {
			Set tMinib = tMinib _"[healthShare_installed_modules]"
			Set tItem = 0
			Set tRow = pObject.modules.GetNext(.tItem)
			While $IsObject(tRow) {
				Set tMinib = tMinib _" "_tRow.module_" version "_tRow.version_"%0D"	
				Set tRow = pObject.modules.GetNext(.tItem)
			}
		}
		Set tMinib = tMinib _"[version_string] "_pObject.CacheVerStr_"%0D"
		Set tMinib = tMinib _"[configuration] "_pObject.Configuration_"%0D"
		Set tMinib = tMinib _"[database Cache (MB)] "_pObject.DatabaseCache_"%0D"
		Set tMinib = tMinib _"[routine Cache (MB)] "_pObject.RoutineCache_"%0D"
		Set tMinib = tMinib _"[configuration] "_pObject.Configuration_"%0D"
		Set tMinib = tMinib _"[licensed to] "_pObject.LicenseTo_"%0D"
		Set tMinib = tMinib _"[operating_system] "_pObject.OS_"%0D"
		Set tMinib = tMinib _"[cluster support] "_pObject.Cluster_"%0D"
		Set tMinib = tMinib _"[mirroring] "_pObject.Mirror_"%0D"
		Set tMinib = tMinib _"[time system started] "_pObject.TimeSince_"%0D"
				
		Set tMinib = tMinib_"%0D [suppport_info] %0D"
		Set tMinib = tMinib _"[installed_product] "_pObject.DisplayProductName_"%0D"
		Set tMinib = tMinib _"[product_version] "_pObject.CacheVerNumber_"%0D"
		Set tMinib = tMinib _"[hostname] "_pObject.HostName_"%0D"

		Set pObject.minib = tMinib
		// Hide the email address here to avoid spam bot
		Set pObject.mailto = "support@intersystems.com"
	} Catch ex {
		Set tSC = ex.AsStatus()
		Set pObject.error = tSC
	}
	Quit tSC
}

/// Returns last InterSystems IRIS start time.
ClassMethod TimeSince() As %String
{
 Set Secs = $p($zh,".")
 Set today = $h
 Set days = Secs\86400
 Set seconds = Secs#86400
 Set daystart = +today-days
 Set timestart = +$p(today,",",2) - seconds
 If timestart<0 s daystart = daystart - 1,timestart = 86400-(seconds-+$P(today,",",2))
 Quit daystart_","_timestart
}

}
