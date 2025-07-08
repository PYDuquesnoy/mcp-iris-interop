/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SOAP.WebServiceInvoke Extends %CSP.Page [ System = 3 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

Parameter CHARSET = "UTF-8";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

ClassMethod OnPage() As %Status
{
 Set title = $$$Text("Web Service")
 &html< 
 <html>
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
 <title>#(title)# #(..EscapeHTML($Get(%request.Data("CLS",1))))#</title>
 </head>
 >
	Do {
		Set class=..UnescapeURL($Get(%request.Data("CLS",1))),tMethod=$Get(%request.Data("OP",1))
		Write !,"<body><div id=""content""><p class=""heading1"">"_title_" "_..EscapeHTML(class)_"</p><br>"
		Write "<span><h2>"_..EscapeHTML(tMethod)_"</h2>"
		If %request.Get("QUERY") {
			Set desc=$$$comMemberKeyGet(class,$$$cCLASSquery,tMethod,$$$cQUERYdescription)
		} Else {
			Set desc=$$$comMemberKeyGet(class,$$$cCLASSmethod,tMethod,$$$cMETHdescription)
		}
		Write "<p class=""description"">"_..EscapeHTML(desc)_"</p>"

		If class=""!(tMethod="") {
			Write "<h3>"_$$$Text("Query Parameters Missing - Did you mean to call this page directly?")_"</h3>" 
			Quit
		}
	
		Set tAction=$$$comMemberKeyGet(class,$$$cCLASSparameter,"LOCATION",$$$cPARAMdefault)
		If tAction'="",$extract(tAction,*)'="/" Set tAction=tAction_"/"
		Set tAction=tAction_..EscapeURL(class_".cls")
		If '$case($zconvert($piece(tAction,"://"),"L"),"http":1,"https":1,:0) {
	 		Set tAction=$$CSPNormalizeURL^%SYS.cspServer(tAction,%request.URL)
	 		Set tPort=%request.CgiEnvs("SERVER_PORT")
	 		Set tServer=%request.CgiEnvs("SERVER_NAME")
	 		If tPort'=80 Set tServer=tServer_":"_tPort
	 		Set tAction=$select(%request.Secure:"https",1:"http")_"://"_tServer_tAction
		}
	
		Set tClass=class_$select(%request.Get("QUERY"):"."_tMethod,1:"")
		Set tFormalSpec=$$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethod,$$$cMETHformalspec),tComplex=0
		If tFormalSpec]"" {
    		Set sc=$$parseFormal^%occName("Method","",tFormalSpec,.tFormalArgs)
    		If $$$ISERR(sc) Set tFormalArgs=0,tComplex=1
			For tP=1:1:tFormalArgs {
				Set tRef=$get(tFormalArgs(tP,1))
				Set tType=$get(tFormalArgs(tP,2))
				If (tType'="") && (tRef'="*") {
					Set tType=$$$NormalizeClassname(tType)
					If $$$comClassKeyGet(tType,$$$cCLASSsuper)["%XML.Adaptor" Set tComplex=1
					If $$$getClassType(tType)'=$$$cCLASSCLASSTYPEDATATYPE Set tComplex=1
				}
			}
		}
	
		If tComplex=1 {
			Write "<h3>"_$$$Text("Test")_"</h3>"_$$$Text("No Test Form is available for this method.")
			Quit
		}
		
		Write " <form action="""_..EscapeHTML(tAction)_""" method=""get"">",!
		Write " <input type=""hidden"" name=""soap_method"" value="""_..EscapeHTML(tMethod)_""">"
		Write "<h3>"_$$$Text("Test")_"</h3>"_$$$Text("To test the operation using the HTTP GET protocol, click the 'Invoke' button.")_"<br><br><p>"
		If tFormalSpec]"" {
			Write "<table cellpadding=""5"" border=""1"">"
			Write "<tr><td>"_$$$Text("Parameter")_"</td>"
			Write "<td>"_$$$Text("Value")_"</td></tr>"
			For tP=1:1:tFormalArgs {
				Set tRef=$get(tFormalArgs(tP,1))
				If tRef'="*" {
					Set tName=tFormalArgs(tP)
					Set tValue=$get(tFormalArgs(tP,3))
					If tValue="""""" {
						Set tValue=""
					} ElseIf tValue'="",$extract(tValue)="""",$extract(tValue,*)="""" {
						Set tValue=$extract(tValue,2,*-1)
					}
					Write "<tr><td align=""left"">"_..EscapeHTML(tName)_"</td>",!
					Write "<td><input type=""text"" name="""_..EscapeHTML(tName)_""""
					If tValue'="" Write " value="""_..EscapeHTML(tValue)_""""
					Write "></td></tr>",!
				}
			}
			Write "<tr><td>&nbsp;</td><td align=""right""><input type=""submit"" value="""_$$$Text("Invoke")_""" class=""button""></td></tr>"
			Write "</table>"
		} Else {
			Write "<br><input type=""submit"" value="""_$$$Text("Invoke")_""" class=""button"">"
		}
		Write "</form><span></body></html>"
	} While (0)
 Quit $$$OK
}

}
