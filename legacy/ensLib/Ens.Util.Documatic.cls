/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This class contains methods used by the Documatic class reference
/// viewer to display details about Interoperability components.
Class Ens.Util.Documatic Extends %CSP.Util.Pane [ System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Show summary information about the given production class.
ClassMethod RenderProductionInfo(pClass As %String) As %Status
{
	Try {
		#Dim production As Ens.Config.Production
		Set production = ##class(Ens.Config.Production).%OpenId(pClass)
		If '$IsObject(production) Quit

		Set msgHost($$$eHostTypeService) = $$$Text("Business Services")
		Set msgHost($$$eHostTypeProcess) = $$$Text("Business Processes")
		Set msgHost($$$eHostTypeOperation) = $$$Text("Business Operations")
		Set msgMain = $$$Text("This is a Production class.")
		Set hlpKey = ""

		&html<<div class="SummaryText">#(msgMain)#</div>>

		If (production.Description '= "") {
			&html<<div class="SummaryText">#($ZCVT(production.Description,"O","HTML"))#</div>>
		}

		&html<<br/>>

		For i = 1:1:production.Items.Count() {
			Set item = production.Items.GetAt(i)
			Set name = $S(item.Name="":item.ClassName,1:item.Name)
			Set type = item.BusinessType()
			If (item.Enabled)&&(name'="")&&(type'="") {
				Set tList(type,name) = item
			}
		}

		Set tLibrary = ..GetLibrary()
		#; show members of this production
		For type=$$$eHostTypeService,$$$eHostTypeProcess,$$$eHostTypeOperation {
			If ($D(tList(type))) {
				Set tCols = 3
				&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
				<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($G(msgHost(type)))#</th></tr>>
				&html<<tr>>
				Set col = 1
				Set tPageName = $O(tList(type,""))
				While (tPageName '= "") {
					#Dim item As Ens.Config.Item
					Set item = tList(type,tPageName)
					Set url = ""
					Set priv = ""
					Set url = ..GetLink(item.ClassName, tLibrary)
					Set inh = "class=""inherited"""
					
					If (col > tCols) {
						&html<</tr><tr>>
						Set col = 1
					}
					&html<<td #(priv)#><a #(inh)# href="#(url)#" title="#($ZCVT(item.Comment,"O","HTML"))#">#($ZCVT(tPageName,"O","HTML"))#</a></td>>
					Set col = col + 1
			
					Set tPageName = $O(tList(type,tPageName))
				}
				&html<</tr>>
				&html<</table>>
				&html<<br>>
			}
		}
	}
	Catch(ex) {
	}
	Quit $$$OK
}

/// Show summary information about the given service class.
ClassMethod RenderBusinessServiceInfo(pClass As %String) As %Status
{
	Try {
		Set msgMain = $$$Text("This is a Business Service class.")
		Set hlpKey = ""

		&html<<div class="SummaryText">#(msgMain)#</div><br/>>
		Do ..RenderAdapterInfo(pClass)
	}
	Catch(ex) {
	}
	Quit $$$OK
}

/// Show summary information about the given process class.
ClassMethod RenderBusinessProcessInfo(pClass As %String) As %Status
{
	Try {
		Set msgMain = $$$Text("This is a Business Process class.")
		Set hlpKey = ""

		&html<<div class="SummaryText">#(msgMain)#</div><br/>>

		Do ..RenderRequestInfo(pClass)
	}
	Catch(ex) {
	}
	Quit $$$OK
}

/// Show summary information about the given operation class.
ClassMethod RenderBusinessOperationInfo(pClass As %String) As %Status
{
	Try {
		Set msgMain = $$$Text("This is a Business Operation class.")

		&html<<div class="SummaryText">#(msgMain)#</div><br/>>
		Do ..RenderAdapterInfo(pClass)

		Do ..RenderRequestInfo(pClass)
	}
	Catch(ex) {
	}
	Quit $$$OK
}

ClassMethod RenderAdapterInfo(pClass As %String) As %Status
{
	Try {
		Set tAdapter = $parameter(pClass,"ADAPTER")
		If (tAdapter '= "") {
			Set tLink = "<a href="""_..GetLink(tAdapter)_""">"_tAdapter_"</a>"
			Set msgMain = $$$FormatText($$$Text("The associated Adapter class is %1."),tLink)
			&html<<div class="SummaryText">#(msgMain)#</div><br/>>
		}
	}
	Catch(ex) {
	}
	Quit $$$OK
}

/// Show summary information for the request/responses for a host.
ClassMethod RenderRequestInfo(pClass As %String) As %Status
{
	Try {
		Set msgReq = $$$Text("Request")
		Set msgResp = $$$Text("Response")
		Set tReqList = $classmethod(pClass,"GetRequestClassList")
		Set tRespList = $classmethod(pClass,"GetResponseClassList")

		If ($LL(tReqList)>0) {
			&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
			<tr><th>#(msgReq)#</th><th>#(msgResp)#</th></tr>>

			Set tLibrary = ..GetLibrary()
			For i = 1:1:$LL(tReqList) {
				Set tReq = $LG(tReqList,i)
				Set tResp = $LG(tRespList,i)

				Set urlReq = ..GetLink(tReq,tLibrary)
				Set urlResp = ..GetLink(tResp,tLibrary)

				&html<<tr>
				<td><a class="inherited" href="#(urlReq)#" title="">#($ZCVT(tReq,"O","HTML"))#</a></td>
				<td><a class="inherited" href="#(urlResp)#" title="">#($ZCVT(tResp,"O","HTML"))#</a></td>
				</tr>>
			}
			&html<</table>>
			&html<<br>>
		}
	}
	Catch(ex) {
	}
	Quit $$$OK
}

ClassMethod GetLink(pClass As %String = "", pLibrary As %String = {..GetLibrary()}) As %String [ Private ]
{
	Set tLink = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$$$URLENCODE(pLibrary)_"&CLASSNAME="_$$$URLENCODE(pClass)
	Quit ##class(%CSP.Page).Link(tLink)
}

ClassMethod GetLibrary(pLibrary As %String = {$namespace}) As %String [ CodeMode = expression, Private ]
{
$select($e(pLibrary,1,2)="^^" && ($zcvt(pLibrary,"L") = $zcvt(##class(%Library.EnsembleMgr).GetENSLIB(1),"L")): "ENSLIB", 1: pLibrary)
}

}
