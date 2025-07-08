/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This pages shows the output of SOAP Wizard.
Class %ZEN.Template.AddInWizard.SOAPWizardOutput Extends %ZEN.Template.cspTemplate [ Deprecated, System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%TemplateMessages";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		// Namespace is the current Studio Namespace. If for some reason it went back to %SYS, change it here.
		Set Namespace = $G(%request.Data("Namespace",1))
		If Namespace '= "",Namespace '= $namespace Set $Namespace = Namespace

		Set ^ISC.SOAPClientWizard($Username,"Status") = ""
		Set ^ISC.SOAPClientWizard($Username,"Error") = ""
		Set ^ISC.SOAPClientWizard($Username,"Namespace")=$namespace
		&html<<html><head>
		<style type="text/css">
		body {
			font-family: courier new, sans-serif;
		}

		div.ClassList {	
			margin-left: 20px; margin-right: 10px;
			margin-bottom: 5px;
			padding: 0px;
		}

		div.Title	{	
			margin-left: 20px; margin-right: 10px;
			margin-bottom: 4px;
			margin-top: 4px;
			padding: 0px;
			color: #3b84bc;
		}

		table.ClassList	{
			font-family: courier new, sans-serif;
			font-size: 0.8em; 
			background: white; 
			text-align: left; 
			border: 1px solid black;
		}

		table.ClassList	TH {
			font-size: 1.0em;
			background: #3b84bc;
			color: white; 
			padding: 4px;
		}

		table.ClassList	TD 	{ 
			border-bottom: 1px solid gray; 
			padding: 4px;
		}
		</style>
		</head>>
		&html<<body>>
		Do %response.Flush()
		
		Set error = ""
		Set url = $G(%request.Data("url",1))
		Set ssl = $G(%request.Data("ssl",1))
		Set sslCheckServer = $G(%request.Data("sslCheckServer",1))
		If sslCheckServer="" Set sslCheckServer=1
		Set username = $G(%request.Data("username",1))
		Set password = $G(%request.Data("password",1))
		#; SOAPClientWizardPreview.csp had this logic:
		If $zcvt($extract(url,1,8),"L")'="https://" Set ssl = $g(url)
		Set package = $G(%request.Data("package",1))
		Set classtype = $G(%request.Data("classtype",1))
		Set CascadeDeletes = $G(%request.Data("CascadeDeletes",1))
		Set compile = $G(%request.Data("compile",1))
		Set compileflags = $G(%request.Data("compileflags",1))
		Set MakeClient = $G(%request.Data("MakeClient",1))
		Set MakeService = $G(%request.Data("MakeService",1))
		Set ClientPackage = $S(MakeClient:$G(%request.Data("ClientPackage",1)),1:"")
		Set ServicePackage = $S(MakeService:$G(%request.Data("ServicePackage",1)),1:"")
		Set ConfigPackage = $G(%request.Data("ConfigPackage",1))
		Set TotalPackages = $G(%request.Data("TotalPackages",1))
		Set Packages = $G(%request.Data("Packages",1))

		If package = "" {
			Set ClientPackage = $select(ClientPackage'="":"."_ClientPackage,1:"")
			Set ServicePackage= $select(ServicePackage'="":"."_ServicePackage,1:"")
		}
		Set businessOperation = $G(%request.Data("businessOperation",1))
		Set bopackage = $G(%request.Data("bopackage",1))
		Set reqpackage = $G(%request.Data("reqpackage",1))
		Set respackage = $G(%request.Data("respackage",1))
		Set makeNamespace = $G(%request.Data("makeNamespace",1))
		Set makeMessage = $G(%request.Data("makeMessage",1))
		Set noarray = $G(%request.Data("noarray",1))
		Set xmlnil = $G(%request.Data("xmlnil",1))
		Set xmlnilnoobject = $G(%request.Data("xmlnilnoobject",1))
		Set nosequence = $G(%request.Data("nosequence",1))
		Set ignorenull = $G(%request.Data("ignorenull",1))
		Set binaryasstream = $G(%request.Data("binaryasstream",1))
		Set suppressNamespace = $G(%request.Data("suppressNamespace",1))
		Set clientUrlEscapeSoapAction = $G(%request.Data("clientUrlEscapeSoapAction",1))
		Set outputTypeAttribute = $G(%request.Data("outputTypeAttribute",1))
		Set securityin = $G(%request.Data("securityin",1))
		Set schemaid = $G(%session.Data("schemaid"))
		
		// Workaround bug in $zcvt(s,"I","URL")
		do {
			set pos=$find(url,"%3F")
			if pos'=0 set $extract(url,pos-3,pos-1)="?"
		} while pos'=0
	
		&html<<div class="Title">#($$$FormatText($$$Text("Generator Output in Namespace %1"),Namespace))#:</div>
		<pre>>
		Write $$$Text("Creating classes..."),!
		Write "WSDL: <b>",$zconvert(url,"O","HTML"),"</b>",!
	 	Do %response.Flush()
		#; Get a WSDL reader
		Set tSC=$$$OK
		Do {
			If (schemaid '= "") {
				// open existing schema
				Set reader = ##class(%XML.Utils.SchemaReader).Open(schemaid)
		 		Set reader.SSLConfiguration = ssl
		 		Set reader.SSLCheckServerIdentity = sslCheckServer
				If username'="" {
					Set http=##class(%Net.HttpRequest).%New() 
					Set http.Username=username 
					Set http.Password=password 
					Set reader.HttpRequest=http 
				}

				// test if we have to update package/ns info
				For n = 1:1:TotalPackages {
					Set item = $P(Packages,",",n)
					If item '= "" {
						If ($get(reader.NSInfo(n,"Package")) '=	item) {
							Set reader.NSInfo(n,"Package") = item
						}
					}
				}		
			
				// reparse schema using new NSInfo
				Do reader.Reset()

		 		Set WSDLReader=##Class(%SOAP.WSDL.Reader).%New()
				If '$isobject(WSDLReader) Set tSC=$$$ERROR($$$FailedToNewClass,"%SOAP.WSDL.Reader") Quit
		 		Set WSDLReader.SSLConfiguration = ssl
		 		Set WSDLReader.SSLCheckServerIdentity = sslCheckServer
				If username'="" {
					Set http=##class(%Net.HttpRequest).%New() 
					Set http.Username=username 
					Set http.Password=password 
					Set WSDLReader.HttpRequest=http 
				}
		 		Set WSDLReader.MakeNamespace = makeNamespace
		 		Set WSDLReader.MakeMessageStyle = makeMessage
		 		Set WSDLReader.NoArrayProperties = noarray
		 		Set WSDLReader.GenerateXMLNIL = xmlnil
		 		Set WSDLReader.GenerateXMLNILNOOBJECT = xmlnilnoobject
		 		Set WSDLReader.NoSequence=$select(nosequence:1,1:"")
		 		Set WSDLReader.IgnoreNull=$select(ignorenull:1,1:"")
		 		Set WSDLReader.BinaryAsStream=$select(binaryasstream:1,1:"")
		 		Set WSDLReader.SecurityInParameter = securityin
				Set WSDLReader.SuppressNamespace = suppressNamespace
				If classtype = "persistent" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
				} ElseIf classtype = "relationships" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
					Set WSDLReader.MakeRelationships=1
					Set WSDLReader.ParentChildRelationship=0
					Set WSDLReader.IndexRelationship=0
				} ElseIf classtype = "relationships-parentchild" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
					Set WSDLReader.MakeRelationships=1
					Set WSDLReader.ParentChildRelationship=1
					Set WSDLReader.IndexRelationship=0
				} ElseIf classtype = "relationships-index" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
					Set WSDLReader.MakeRelationships=1
					Set WSDLReader.ParentChildRelationship=0
					Set WSDLReader.IndexRelationship=1
				} ElseIf classtype = "serial" {
					Set WSDLReader.MakePersistent = 0
					Set WSDLReader.MakeSerial = 1
				} Else {
					Set WSDLReader.MakePersistent = 0
					Set WSDLReader.MakeSerial = 0
				}
				If businessOperation {
					Set WSDLReader.MakeEnsembleClasses = 1
					Set WSDLReader.OperationPackage = bopackage
					Set WSDLReader.RequestPackage = reqpackage
					Set WSDLReader.ResponsePackage = respackage
				}
				Set WSDLReader.OutputTypeAttribute = outputTypeAttribute
				Set WSDLReader.ClientURLEscapeSoapAction = clientUrlEscapeSoapAction
				Set WSDLReader.CascadeDeletes=CascadeDeletes
				Set WSDLReader.CompileClasses=''compile
				Set WSDLReader.CompileFlags = compileflags
				Set WSDLReader.MakeClient=MakeClient
				Set WSDLReader.MakeService=MakeService
				Set WSDLReader.ClientPackage=ClientPackage
				Set WSDLReader.ServicePackage=ServicePackage
				Set WSDLReader.ConfigPackage=ConfigPackage				 
				Set tSC = WSDLReader.Process(url,package,,reader)
				If $$$ISERR(tSC) Quit

				Set schemaid = reader.Save()
			}
			Else {
				If url="" {
					Set tSC = $$$ERROR($$$GeneralError,"Unable to find Schema File.")
					Quit
				}

		 		Set WSDLReader=##Class(%SOAP.WSDL.Reader).%New()
				If '$isobject(WSDLReader) Set tSC=$$$ERROR($$$FailedToNewClass,"%SOAP.WSDL.Reader") Quit
		 		Set WSDLReader.SSLConfiguration = ssl
		 		Set WSDLReader.SSLCheckServerIdentity = sslCheckServer
				If username'="" {
					Set http=##class(%Net.HttpRequest).%New() 
					Set http.Username=username 
					Set http.Password=password 
					Set WSDLReader.HttpRequest=http 
				}
		 		Set WSDLReader.MakeNamespace = makeNamespace
				Set WSDLReader.SuppressNamespace = suppressNamespace
				If classtype = "persistent" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
				} ElseIf classtype = "relationships" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
					Set WSDLReader.MakeRelationships=1
					Set WSDLReader.ParentChildRelationship=0
					Set WSDLReader.IndexRelationship=0
				} ElseIf classtype = "relationships-parentchild" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
					Set WSDLReader.MakeRelationships=1
					Set WSDLReader.ParentChildRelationship=1
					Set WSDLReader.IndexRelationship=0
				} ElseIf classtype = "relationships-index" {
					Set WSDLReader.MakePersistent = 1
					Set WSDLReader.MakeSerial = 0
					Set WSDLReader.MakeRelationships=1
					Set WSDLReader.ParentChildRelationship=0
					Set WSDLReader.IndexRelationship=1
				} ElseIf classtype = "serial" {
					Set WSDLReader.MakePersistent = 0
					Set WSDLReader.MakeSerial = 1
				} Else {
					Set WSDLReader.MakePersistent = 0
					Set WSDLReader.MakeSerial = 0
				}
				If businessOperation {
					Set WSDLReader.MakeEnsembleClasses = 1
					Set WSDLReader.OperationPackage = bopackage
					Set WSDLReader.RequestPackage = reqpackage
					Set WSDLReader.ResponsePackage = respackage
				}
				Set WSDLReader.OutputTypeAttribute = outputTypeAttribute
				Set WSDLReader.ClientURLEscapeSoapAction = clientUrlEscapeSoapAction
				Set WSDLReader.CascadeDeletes=CascadeDeletes
				Set WSDLReader.CompileClasses=''compile
				Set tSC = WSDLReader.Process(url,package)
				If $$$ISERR(tSC) Quit
	
				// Save the schema info for later use
				Set schemaid = reader.Save()
			}
		} While(0)
		&html<</div>>
	 	If $$$ISERR(tSC) {
		 	Set error = $System.Status.GetErrorText(tSC)
		 	Write $zconvert(error,"O","HTML")
	 	} Else {
			// put classes into session data
	 		Kill %session.Data("ClassList")
			Merge %session.Data("ClassList") = WSDLReader.BOClassList
			Merge %session.Data("ClassList") = WSDLReader.ClientClassList
			Merge %session.Data("ClassList") = WSDLReader.TypeClassList
		
			// show list of generated classes
			&html<<br><hr><div class="Title">#($$$Text("Class Summary"))#:</div>
			<div class="ClassList">
			<table class="ClassList" border="0" cellpadding="4" cellspacing="0">>

			If $data(WSDLReader.BOClassList) {
				&html<<tr><th>#($$$Text("Ensemble Business Operation Classes"))#</th></tr>>
				Set cls = $order(WSDLReader.BOClassList(""))
				set idx = 1
				While (cls '= "") {
					set id = "soapensclass_"_idx
					&html<<tr><td id=#(id)#>#(cls)#</td></tr>>
					Set cls = $order(WSDLReader.BOClassList(cls))
					set idx = idx + 1
				}
			}
		
			&html<<tr><th>#($$$Text("SOAP Classes"))#</th></tr>>
			Set cls = $order(WSDLReader.ClientClassList(""))
			set idx = 1
			While (cls '= "") {
				set id = "soapclass_"_idx
				&html<<tr><td id=#(id)#>#(cls)#</td></tr>>
				Set cls = $order(WSDLReader.ClientClassList(cls))
				set idx = idx + 1
			}
			&html<<tr><th>#($$$Text("SOAP Type Classes"))#</th></tr>>
			
			Set cls = $order(WSDLReader.TypeClassList(""))
			set idx = 1
			While (cls '= "") {
				set id = "soaptypeclass_"_idx
				&html<<tr><td id=#(id)#>#(cls)#</td></tr>>
				Set cls = $order(WSDLReader.TypeClassList(cls))
				set idx = idx + 1
			}
			&html<</table></div>>
		} 	
		Set ^ISC.SOAPClientWizard($Username,"Error") = error
		Set ^ISC.SOAPClientWizard($Username,"Status") = "Done"
		&html<</pre>>
		Set msgComplete = $$$FormatText($$$Text("Completed at %1"),$ZDT($H,3))
		Write msgComplete,"<br/>"
		Do %response.Flush()
		
		Set callBack = "self.parent.zenPage.outputDone();"
		&html<</body><script>#(callBack)#</script></html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set ^ISC.SOAPClientWizard($Username,"Error") = "Unexpected Error: "_tSC
		Write "Unexpected Error: "_tSC
	}
	Do %response.Flush()
	Quit $$$OK
}

/// Event handler for <b>PreHTTP</b> event: this is invoked before
/// the HTTP headers for a CSP page have been sent.  All changes to the
/// <class>%CSP.Response</class> class, such as adding cookies, HTTP headers,
/// setting the content type etc. must be made from within the OnPreHTTP() method.
/// Also changes to the state of the CSP application such as changing
/// %session.EndSession or %session.AppTimeout must be made within the OnPreHTTP() method.
/// It is prefered that changes to %session.Preserve are also made in the OnPreHTTP() method
/// as this is more efficient, although it is supported in any section of the page.
/// Return <b>0</b> to prevent <method>OnPage</method> from being called.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '##super() Quit 0
	// Allow one hour for compiles.
	Set %response.Timeout = 3600
	Quit 1
}

}
