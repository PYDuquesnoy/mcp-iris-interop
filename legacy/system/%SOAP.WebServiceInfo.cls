/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SOAP.WebServiceInfo Extends %CSP.Page [ System = 3 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

Parameter CHARSET = "UTF-8";

ClassMethod OnPage() As %Status
{
 If '$system.Security.Check("%Development","USE") Quit $$$ERROR($$$NoDevloperPriv)
 
 Set title = $$$Text("Web Service")
 &html< <html>
 <head>
 <style type="text/css">

		body { color: #000000; background-color: #ddddff; font-size: .8em; font-family: Verdana; margin-left: 0px; margin-top: 0px; }
		#content { margin-left: 30px; padding-bottom: 2em; }
		a:link { color: #000099; font-weight: bold; text-decoration: underline; }
		a:active { color: #000099; font-weight: bold; text-decoration: underline; }
		a:hover { color: cc3300; font-weight: bold; text-decoration: underline; }
		p { color: #000000; margin-top: 0px; margin-bottom: 12px; font-family: Verdana; }
		table  { color: #000000; font-family: Verdana; }
		td { color: #000000; font-family: Verdana; font-size: .8em; }
		h2 { font-size: 1.5em; font-weight: bold; margin-top: 25px; margin-bottom: 10px; border-top: 1px solid #000088; margin-left: -15px; color: #000088; }
		h3 { font-size: 1.1em; color: #000000; margin-left: -15px; margin-top: 10px; margin-bottom: 10px; }
		ul, ol { margin-top: 10px; margin-left: 20px; }
		li { margin-top: 10px; color: #000000; }
		font.value { color: darkblue; font: bold; }
		font.key { color: darkgreen; font: bold; }
		.heading1 { color: #ffffff; font-family: Tahoma; font-size: 2.2em; font-weight: normal; background-color: #000088; margin-top: 0px; margin-bottom: 0px; margin-left: -30px; padding-top: 10px; padding-bottom: 3px; padding-left: 15px; width: 105%; }
		.button { background-color: #dcdcdc; font-family: Verdana; border-top: #cccccc 1px solid; border-bottom: #666666 1px solid; border-left: #cccccc 1px solid; border-right: #666666 1px solid; }
		.intro { margin-left: -15px; }
		.description { margin-left: -15px; font-size: 1.1 em; }
 </style>
 <title>#(title)# #($Get(%request.Data("CLS",1)))#</title>
 </head>
 >

 Set tMethod=""
 Set class = $zconvert($Get(%request.Data("CLS",1)),"I",$replace($$$GETIO,"JSML","UTF8"))

 Write !,"<body><div id=""content""><p class=""heading1"">"_title_" "_class_" </p><br>",!
 If class="" {
 	Write "<h3>"_$$$Text("Query Parameters Missing - Did you mean to call this page directly?")_"</h3>"
 	Quit $$$OK
 }
 
 Set desc=$$$comClassKeyGet(class,$$$cCLASSdescription)
 If desc'="" Write "<p class=""intro"">"_desc_"</p>",!
 Write "<hr>",!

 Set namespace=$$$comMemberKeyGet(class,$$$cCLASSparameter,"NAMESPACE",$$$cPARAMdefault)
 Set servicename=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SERVICENAME",$$$cPARAMdefault)
 Write "<p class=""intro"">"_$$$Text("This web service is using")_" <b>"_namespace_"</b> "_$$$Text("as its default namespace.")_"</p>",!
 Write "<p class=""intro"">"_$$$Text("The name of this web service is")_" <b>"_servicename_"</b></p>",!
 Write "<p class=""intro"">"_$$$Text("The following operations are supported.  For a formal definition, please review the")_" <a href="""_..EscapeURL(class)_".CLS?WSDL=1"">"_$$$Text("Service Description")_"</a></p>",!
 Write "<ul>",!

 Set isCSPAllowed=$$AllowPercentClass^%SYS.cspServer("%SOAP.WebServiceInvoke",%request.AppMatch)
 Set includeInternalMethods=$parameter(class,"SOAPINTERNALWSDL")
 Set methodInheritance=$$$comMemberKeyGet(class,$$$cCLASSparameter,"SOAPMETHODINHERITANCE",$$$cPARAMdefault)
 Set tMethod=$$$comMemberNext(class,$$$cCLASSmethod,"")
 While tMethod'="" {
	Set isincluded=1
	If methodInheritance {
		Set iswebmethod=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod,$$$cMETHwebmethod)
		If 'includeInternalMethods,iswebmethod {
			Set isincluded='$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod,$$$cMETHinternal)
		}
	} Else {
		Set iswebmethod=$$$defMemberKeyGet(class,$$$cCLASSmethod,tMethod,$$$cMETHwebmethod)
		If 'includeInternalMethods,iswebmethod {
			Set isincluded='$$$defMemberKeyGet(class,$$$cCLASSmethod,tMethod,$$$cMETHinternal)
		}
	}
	If iswebmethod,isincluded {
		If isCSPAllowed {
			Write "<li><a href=""%25SOAP.WebServiceInvoke.cls?CLS="_class_"&amp;OP="_tMethod_""">"_tMethod_"</a><p>",!
		} Else {
			Write "<li><b>"_tMethod_"</b><p>",!
		}
		Set desc=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod,$$$cMETHdescription)
		If desc'="" Write desc,!
		Write "</p></li>",!
	}
	Set tMethod=$$$comMemberNext(class,$$$cCLASSmethod,tMethod)
 }

 Set tMethod=$$$comMemberNext(class,$$$cCLASSquery,"")
 While tMethod'="" {
	Set isincluded=1
	If methodInheritance {
		Set iswebmethod=$$$comMemberKeyGet(class,$$$cCLASSquery,tMethod,$$$cQUERYwebmethod)
		If 'includeInternalMethods,iswebmethod {
			Set isincluded='$$$comMemberKeyGet(class,$$$cCLASSquery,tMethod,$$$cQUERYinternal)
		}
	} Else {
		Set iswebmethod=$$$defMemberKeyGet(class,$$$cCLASSquery,tMethod,$$$cQUERYwebmethod)
		If 'includeInternalMethods,iswebmethod {
			Set isincluded='$$$defMemberKeyGet(class,$$$cCLASSquery,tMethod,$$$cQUERYinternal)
		}
	}
    If iswebmethod,isincluded {
	    If isCSPAllowed {
			Write "<li><a href=""%25SOAP.WebServiceInvoke.cls?CLS="_class_"&amp;OP="_tMethod_"&amp;QUERY=1"">"_tMethod_"</a><p>",!
	    } Else {
			Write "<li><b>"_tMethod_"</b><p>",!
	    }
		Set desc=$$$comMemberKeyGet(class,$$$cCLASSquery,tMethod,$$$cQUERYdescription)
		If desc'="" Write desc,!
		Write "</p></li>",!
	}
    Set tMethod=$$$comMemberNext(class,$$$cCLASSquery,tMethod)
 }

 Write "</ul>",!
 Write "</div></body></html>",!

 Quit $$$OK
}

}
