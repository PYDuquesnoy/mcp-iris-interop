/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Management portal index utility
Class %CSP.UI.System.Index Extends %RegisteredObject [ Abstract, CompileAfter = %CSP.Util.FieldDefinition, LegacyInstanceContext, ServerOnly = 1, System = 3 ]
{

/// Location of MgtPortal page index
Parameter INDEXGLVN = "^%qMgtPortal.Index";

/// Build the MgtPortal page index within the global
/// #INDEXGLVN
/// 
ClassMethod BuildIndex() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tAutoSC=..BuildPageIndex()
		If $$$ISERR(tAutoSC) {
			Write "Autopage status: ", $SYSTEM.Status.GetErrorCodes(tAutoSC), ": ", $SYSTEM.Status.GetErrorText(tAutoSC), !
		}
		
		// Check if Ensemble is installed OR ENSLIB database exists, as %Library.EnsembleMgr::IsEnsembleInstalled() returns 0 during ^build
		If (##class(%Library.EnsembleMgr).IsEnsembleInstalled() || ($zu(49,##class(%Library.EnsembleMgr).GetENSLIB()) >= -1)) {
			// we need to see the ensemble pages
			Set tIndexNS = $namespace
			new $namespace
			set $namespace = ##class(%Library.EnsembleMgr).GetENSLIB(1)
			set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
			set tEnsSC = tRS.Execute("%ZEN.Portal.standardPage")
			If $$$ISERR(tEnsSC) {
				Write "Ensemble execute status: ", $SYSTEM.Status.GetErrorCodes(tEnsSC), ": ", $SYSTEM.Status.GetErrorText(tEnsSC), !
			}
			Else { 
				Set tEnsSC = ..ProcessIndexZen("Ensemble", tRS, tIndexNS) 
				If $$$ISERR(tEnsSC) {
						Write "Ensemble process status: ", $SYSTEM.Status.GetErrorCodes(tEnsSC), ": ", $SYSTEM.Status.GetErrorText(tEnsSC), !
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method will only locate portal pages for the current namespace.
ClassMethod BuildPageIndex() As %Status
{
	Set tSC = $$$OK
	Try {
		// clear out index
		Kill @(..#INDEXGLVN)

		#; autopage-based portal pages
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%CSP.Util.AutoPage")
		If $$$ISERR(tSC) {
			Write "Autopage build status: ", $SYSTEM.Status.GetErrorCodes(tSC), ": ", $SYSTEM.Status.GetErrorText(tSC), !
        	Quit
        }

		Do ..ProcessIndex(tRS)
		Set tRS = ""

		// JMD690
		// some pages are zen-based
		// these are derived from %CSP.UI.Portal.Template
		set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		//Write "ResultSet: ", tRS, !
		set tZenSC = tRS.Execute("%CSP.UI.Portal.Template")
		If $$$ISERR(tZenSC) {
			Write "Zen execute status: ", $SYSTEM.Status.GetErrorCodes(tZenSC), ": ", $SYSTEM.Status.GetErrorText(tZenSC), !
		}
		Set tZenSC = ..ProcessIndexZen("Zen", tRS)
		If $$$ISERR(tZenSC) {
			Write "Zen process status: ", $SYSTEM.Status.GetErrorCodes(tZenSC), ": ", $SYSTEM.Status.GetErrorText(tZenSC), !
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Internal method to build page index for autopage-based pages.
ClassMethod ProcessIndex(tRS As %ResultSet) [ Private ]
{
	Write "Autopage collection started", !
	Set tCnt = 0
	While (tRS.Next()) {
		Set tClass = tRS.Data("Name")
		Set tPageName = $$$defMemberKeyGet(tClass,$$$cCLASSparameter,"PAGENAME",$$$cPARAMdefault)
		Set tURL = $$$defMemberKeyGet(tClass,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)
		Set:$E(tPageName)="@" tPageName = $P(tPageName,"@",3,*)
		Set:tPageName'="" tPageName = """"_tPageName_""""

		// find parent info
		Set tParent = $$$defMemberKeyGet(tClass,$$$cCLASSparameter,"PARENTPAGE",$$$cPARAMdefault)

		While ((tPageName '= "") && (tParent '= "")) {
			// determine class name for parent page
			// we cannot rely on csp applications being defined...
			Set tParent = $P(tParent,".csp",1) // strip off .csp
			
			// pull off leading ../ from parent name
			Set tLevels = $L(tParent,"../")
			Set tParent = $P(tParent,"../",$L(tParent,"../"))

			// get package prefix
			Set tPrefix = $P(tClass,".",1,$L(tClass,".")-tLevels)
			Set tParentClass = tPrefix _ "." _ $ZCVT($TR(tParent,"/","."),"L")

			Set tParent = ""
			If (tParentClass '= "") {
				Set tName = $$$defMemberKeyGet(tParentClass,$$$cCLASSparameter,"PAGENAME",$$$cPARAMdefault)
				Set:$E(tName)="@" tName = $P(tName,"@",3,*)
				If (tName '= "") {
					Set tPageName = $$$quote(tName) _","_tPageName
					Set tParent = $$$defMemberKeyGet(tParentClass,$$$cCLASSparameter,"PARENTPAGE",$$$cPARAMdefault)
				}
			}
		}
		If (tPageName '= "") {
			Set x = "Set "_..#INDEXGLVN_"("_tPageName_") = "_$$$quote(tURL)
			Set tCnt = tCnt + 1
			X x
		}
	}
	Write "Autopages installed: ", tCnt, !
	Quit
}

/// Internal method to build page index for zen-based pages.
ClassMethod ProcessIndexZen(tSection As %String, tRS As %ResultSet, tIndexNS As %String = {$namespace}) As %Status [ Private ]
{
	Write tSection, " Collection started", !
	Set tCnt = 0
	Set tSC = $$$OK
	Try {
		// JMD690	
		// set up bogus session context
		New %session,%response,%page,%request

		// so that we can invoke CSP method in a non-web context
		Set %session = ##class(%CSP.Session).%New(1)
		Set %request = ##class(%CSP.Request).%New()
		// if this fails, talk to the CSP team!
		Set %response = ##class(%CSP.Response).%New()
		
		Set tIndexGLVN = ..#INDEXGLVN
		If tIndexNS '= $namespace {
			Set tIndexGLVN = "^|"""_tIndexNS_"""|"_$piece(..#INDEXGLVN,"^",2)
		}

		While (tRS.Next()) {
			Set tClass = tRS.Data("Name")
			//Write "ProcessIndex", tSection, " Name: ", tClass, !
			Set tAbstract = +$$$comClassKeyGet(tClass,$$$cCLASSabstract)
			If ('tAbstract) {
				Set tPkg = $P(tClass,".",1,$L(tClass,".")-1)
				Set tURL = $ZCVT(tClass,"O","URL")_".zen"

				// organize by package
				Kill tCat
				If (tPkg["EnsPortal") {
					Set tCat(1) = "Ensemble"
					Set tURL = "/csp/ensdemo/"_tURL
				}
				ElseIf (tPkg["EnsLib.Hub.UI") {
					Set tCat(1) = "Identity"
					Set tURL = "/csp/ensdemo/"_tURL
				}
				ElseIf (tPkg["EnsLib.EDI") {
					Set tCat(1) = "Ensemble EDI"
					Set tURL = "/csp/ensdemo/"_tURL
				}
				ElseIf (tPkg["%CSP.UI.Portal") {
					// JMD690
					// this is zen-based mgt portal page
					// get URL from class parm
					Set tURL = $$$defMemberKeyGet(tClass,$$$cCLASSparameter,"CSPURL",$$$cPARAMdefault)

					// now get category by analyzing the links for this page
					Try {
						Kill tLinks
						Set %page = $classmethod(tClass,"%New")
						Set tSC = $method(%page,"%GetLocatorLinks",.tLinks)
						Set cx = 0
						Set k = $O(tLinks(""))
						While (k'="") {
							Set tName = $LG(tLinks(k),1)
							If (tName'="") {
								Set tCat($I(cx)) = tName
							}
							Set k = $O(tLinks(k))
						}
					}
					Catch (ex) {
						Write "Locator link status: ", $SYSTEM.Status.GetErrorCodes(ex.AsStatus()), ": ", $SYSTEM.Status.GetErrorText(tSC), !
					}
				}
				ElseIf (tPkg["%CSP") {
					Set tCat(1) = "Ensemble"
					Set tURL = "/csp/sys/"_tURL
				}
				ElseIf (tPkg["%DeepSee") {
					Set tCat(1) = "DeepSee"
					Set tURL = "/csp/samples/"_tURL
				}
				ElseIf (tPkg["%WebStress") {
					Set tCat(1) = "WebStress"
					Set tURL = "/csp/samples/"_tURL
				}

				// set index
				Set tPageName = $$$defMemberKeyGet(tClass,$$$cCLASSparameter,"PAGENAME",$$$cPARAMdefault)
				If (tPageName '= "") {
					Set tPageName = $$$quote(tPageName)
					Set k = $O(tCat(""),-1)
					While (k'="") {
						Set tPageName = $$$quote(tCat(k))_","_tPageName
						Set k = $O(tCat(k),-1)
					}

					Set x = "Set "_tIndexGLVN_"("_tPageName_") = "_$$$quote(tURL)
					Set tCnt = tCnt + 1
					X x
				}

			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "Process index [", tSection, "] status: ", $SYSTEM.Status.GetErrorCodes(tSC), ": ", $SYSTEM.Status.GetErrorText(tSC), !
	}
	Write tSection, " pages installed: ", tCnt, !
	Quit tSC
}

/// Get locator info from the given zen portal page.
ClassMethod %GetLocatorInfo(pClass As %String, Output pInfo)
{
	Try {
		Kill pInfo
		Do $classmethod(pClass,"%GetLocatorInfo",.pInfo)
	}
	Catch(ex) {
		Do $System.Status.DisplayError(ex.AsStatus())
	}
}

}
