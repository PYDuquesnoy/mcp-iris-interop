/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides the basic search capabilities for context-based
/// searching within the Portal.
Class %ZEN.Portal.ContextSearch Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%ZEN";

/// Perform a search. Return a list of results.<br/>
/// <var>pContext</var> is the search context string. This is parsed
/// and the actual search class and method are invoked.<br/>
/// <var>pSearchKey</var> is the value in the search control when the user invoked
/// the search.<br/>
/// <var>pTopResults</var> contains the list of most likely results (if any).<br/>
/// <var>pResults</var> contains the list of all results.<br/>
/// Both arrays take the form:<br/>
/// pResults(n) = result (string)<br/>
ClassMethod %Search(Output pCaption As %String, Output pTopResults, Output pResults, pContext As %String, pSearchKey As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		// parse the context string
		// this is off the form: class/method?p1=val&p2=val
		Set tSC = ..%ParseContext(pContext,.tClassName,.tMethodName,.tParms)
		If $$$ISERR(tSC) Quit

		// now perform the search
		If (tClassName = "") {
			// search method is built into this class
			Set tClassName = ..%ClassName(1)
		}
		ElseIf (tClassName = "Ens") {
			// shortcut for ensemble
			Set tClassName = "Ens.ContextSearch"
		}

		// validate class name
		If ('$zobjclassmethod(tClassName,"%Extends","%ZEN.Portal.ContextSearch")) {
			Set tSC = $$$ERROR($$$GeneralError,"Search class must inherit from base search class.")
			Quit
		}

		If (tMethodName = "") {
			Set tSC = $$$ERROR($$$GeneralError,"No search method name supplied for search: Try ""class/method"".")
			Quit
		}

		Set tSC = $zobjclassmethod(tClassName,tMethodName,.pCaption,.pTopResults,.pResults,.tParms,pSearchKey)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		If ($ZE["CLASS DOES NOT EXIST") {
			Set tSC = $$$ERROR($$$GeneralError,"Search class does not exist: " _ $G(tClassName))
			Quit
		}
		ElseIf ($ZE["METHOD DOES NOT EXIST") {
			Set tSC = $$$ERROR($$$GeneralError,"Search method does not exist: " _ $G(tMethodName))
			Quit
		}
	}
	Quit tSC
}

/// Parse a context string.
ClassMethod %ParseContext(pContext As %String, Output pClassName As %String, Output pMethodName As %String, Output pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pClassName = ""
		Set pMethodName = ""
		Kill pParms

		// pull apart context like a url
		Set tHost = $P(pContext,"?",1)
		Set tQuery = $P(pContext,"?",2)

		Set pClassName = $P(tHost,"/",1)
		Set pMethodName = $P(tHost,"/",2)

		If (pMethodName ["%") {
			Set tSC = $$$ERROR($$$GeneralError,"Search method name cannot contain %")
			Quit
		}

		For n = 1:1:$L(tQuery,"&") {
			Set t = $P(tQuery,"&",n)
			Set tKey = $ZCVT($P(t,"=",1),"I","URL")
			Set tValue = $ZCVT($P(t,"=",2),"I","URL")
			If (tKey'="") {
				Set pParms(tKey) = tValue
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Search method: Classes.<br/>
/// Execute a class name search.<br/>
/// Parameters can include:<br/>
/// <var>super</var> or <var>subclasses</var> = show only classes derived from the specified class.<br/>
/// <var>system</var> = 1|0 show system classes.<br/>
/// <var>internal</var> = 1|0 show internal classes.<br/>
/// <var>hideAbstract</var> = 1|0 hide classes marked as abstract.<br/>
/// <var>classtype</var> = datatype|persistent|serial|stream|view show only classes of the specified type. Default is empty string for all types.
ClassMethod Classes(Output pCaption As %String, Output pTopResults, Output pResults, ByRef pParms As %String, pSearchKey As %String) As %Status
{
	Set tSC = $$$OK

	Set pCaption = $$$Text("Classes")

	Set tInternal = +$G(pParms("internal"))
	Set tSystem = +$G(pParms("system"))
	Merge pParms("super") = pParms("subclasses")
	Set tSuper = $G(pParms("super"))
	Set tClassType = $G(pParms("classtype"))
	Set tHideAbstract = +$G(pParms("hideAbstract"))
	Set tMask = $$$UPPER($E(pSearchKey,1,10))
	Set n = 0
	Try {
		If tSuper="" {
			Set tKey = $O(^rINDEXCLASS(""),1,data)
			While (tKey '= "") {
				If ('$LG(data,4)||(tInternal)) {
					If (($LG(data,3)="")||(tSystem)) {
						If ((tMask="")||($E(tKey,1,$L(tMask))=tMask)) {
							Set tClass = $LG(data,2)
							If (tClassType = "")||($$$comClassKeyGet(tClass,$$$cCLASSclasstype) = tClassType) {
								If ('tHideAbstract) || '$$$comClassKeyGet(tClass,$$$cCLASSabstract) {
									Set n = n + 1
									Set pResults(n) = tClass
								}
							}
						}
					}
				}
				Set tKey = $O(^rINDEXCLASS(tKey),1,data)
			}
		}
		Else {
			Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinitionQuery:SubclassOf")
			Set tSC = tRS.Execute(tSuper, tMask)
			If $$$ISOK(tSC) {
				While (tRS.Next(.tSC) && $$$ISOK(tSC)) {
					Set tClass = tRS.GetData(1)
					Set tKey = $ZCVT(tClass,"U")
					Set data = $G(^rINDEXCLASS(tKey))
					If ('$LG(data,4)||(tInternal)) {
						If (($LG(data,3)="")||(tSystem)) {
							If ((tMask="")||($E(tKey,1,$L(tMask))=tMask)) {
								If (tClassType = "")||($$$comClassKeyGet(tClass,$$$cCLASSclasstype) = tClassType) {
									If ('tHideAbstract) || '$$$comClassKeyGet(tClass,$$$cCLASSabstract) {
										Set n = n + 1
										Set pResults(n) = tClass
									}
								}
							}
						}
					}
				}
			}
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	Quit tSC
}

/// Search method: Packages.<br/>
/// Execute a package name search.<br/>
/// <i>system</i> = 1|0 show system classes.<br/>
ClassMethod Packages(Output pCaption As %String, Output pTopResults, Output pResults, ByRef pParms As %String, pSearchKey As %String) As %Status
{
	Set tSC = $$$OK

	Set pCaption = $$$Text("Packages")

	Set tShowInternal = +$G(pParms("internal"))
	Set tSystem = +$G(pParms("system"))
	Set tMask = $$$UPPER($E(pSearchKey,1,4))
	Set n = 0
	Set tKey = $O(^rINDEXCLASS(""),1,data)
	While (tKey '= "") {
		If ('$LG(data,4)||(tShowInternal)) {
			If (($LG(data,3)="")||(tSystem)) {
				If ((tMask="")||($E(tKey,1,$L(tMask))=tMask)){
					Set tClass = $LG(data,2)
					Set tPkg = $P(tClass,".",1,$L(tClass,".")-1)
					If (tPkg'="") && (tSystem || ($P(tPkg,".",1) '= "%sqlcq")) { // Ignore %sqlcq if not System
						If '$D(tVisited(tPkg)) {
							Set tVisited(tPkg) = ""
						}
					}
				}
			}
		}
		Set tKey = $O(^rINDEXCLASS(tKey),1,data)
	}
	Set n = 0
	Set k = $O(tVisited(""))
	While (k'="") {
		Set pResults($I(n)) = k
		Set k = $O(tVisited(k))
	}


	Quit tSC
}

/// Search method: Properties.<br/>
/// Execute a class property search.<br/>
/// Parameters can include:<br/>
/// <var>class</var> = class name<br/>
ClassMethod Properties(Output pCaption As %String, Output pTopResults, Output pResults, ByRef pParms As %String, pSearchKey As %String) As %Status
{
	Set tSC = $$$OK
	Set tClassName = $G(pParms("class"))
	
	Set tRS = ##class(%ResultSet).%New("%Dictionary.CompiledProperty:Summary")
	Set tSC = tRS.%Execute(tClassName)
	If $$$ISERR(tSC) Quit tSC

	Set tMask = $$$UPPER($E(pSearchKey,1,10))
	Set n = 0
	Set tn = 0
	While (tRS.Next()) {
		Set tName = $G(tRS.Data("Name"))
		If ((tMask="")||($E($$$UPPER(tName),1,$L(tMask))=tMask)){
			Set tn = tn + 1
			Set pTopResults(tn) = tName
		}
		Set n = n + 1
		Set pResults(n) = tName
	}
	Quit tSC
}

/// Search method: CustomResource.<br/>
/// Execute a search for resources and custom resources.<br/>
ClassMethod CustomResource(Output pCaption As %String, Output pTopResults, Output pResults, ByRef pParms As %String, pSearchKey As %String) As %Status
{
	Set tSC = $$$OK
	Set tSC = ##class(%CSP.Portal.Utils).%GetCustomResourceList(.tList)
	If $$$ISERR(tSC) Quit tSC

	Set tMask = $$$UPPER($E(pSearchKey,1,10))
	Set k = $O(tList(""))
	Set tn = 0
	While (k'="") {
		Set tName = k
		If ((tMask="")||($E($$$UPPER(tName),1,$L(tMask))=tMask)){
			Set tn = tn + 1
			Set pTopResults(tn) = tName
		}
		#; YSD2479 Set n = n + 1
		#; YSD2479 Set pResults(n) = tName
		Set k = $O(tList(k))
	}
	#; If user is not in %SYS then we need to switch to %SYS in order to use Security.Resources:List
	Set tOldNS = $namespace
	Set tSC = ##class(%ZEN.Controller).%ChangeNS("%SYS")
	If $$$ISERR(tSC) Quit tSC
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	If '$IsObject(tRS) {
		Set tSC = ##class(%ZEN.Controller).%ChangeNS(tOldNS)
		Quit tSC
	}
	Do tRS.Execute("*",-1,$zb((2**32)-1,$$$DBResourceType,2))
	Set n = 0
	If tn = 0 Set pTopResults(1) = ""
	While tRS.Next() {
		Set n = n + 1
		Set tName = tRS.GetData(1)
		Set pResults(n) = tName
	}
	Kill tRS
	Set tSC = ##class(%ZEN.Controller).%ChangeNS(tOldNS)
	Quit tSC
}

}
