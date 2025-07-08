/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Utility class to parse and manage parameters XData block in web service and web client.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.WebParameters Extends %RegisteredObject [ System = 2 ]
{

/// Parse parameters XData block for this web service or client.<br><br>
/// 
/// <pre>
/// The format of the parameters variable is
///    parameters(0,"request") is request parameters for entire web client or service.
///    parameters(0,"response") is response parameters for entire web client or service.
///    parameters(0,"soapAction",soapAction)=$lb(methodName,...)
///        specifies which methods are associated with a soap action
///    parameters(0,"requestName",requestName)=$lb(methodName,...)
///        specifies which methods are associated with a top level request element
///    parameters(methodName,"request") is request parameters for a method of web client or service.
///    parameters(methodName,"response") is response parameters for a method of web client or service.
/// 
/// The parameter subnodes defined are
///    parameter(...,"Action")=wsaw:Action value
///    parameter(...,"header",name,class)=$lb(alias,encoded)
///       name is the required element name of the header.
///       class is the required name of the class that corresponds to the header.
///       alias is the optional alias to be used for this header in the HeadersIn and HeadersOut arrays.
///          The default alias is the element name specified in the name attribute.
///       encoded is true if the header is expected to be output in encoded format.
/// </pre>
ClassMethod ParseParameters(classDef As %Dictionary.CompiledClass, methodInheritance As %Boolean, ByRef methods, ByRef actions, ByRef elements, Output parameters) As %Status [ Internal, ServerOnly = 1 ]
{
	New %classname
	Set %classname=classDef.Name
	Kill parameters
	Set sc=$$$OK
	
	// Add in parameters obtained from method keywords
	Merge parameters(0,"soapAction")=actions
	Merge parameters(0,"requestName")=elements
	
	For i=1:1:classDef.XDatas.Count() {
		Set xdata=classDef.XDatas.GetAt(i)
		Set sc=..ParseOpen(xdata.Data,.reader,.root)
		If $$$ISERR(sc) Quit

		If root="parameters" {
			Set sc=..ParseParametersElement(reader, (methodInheritance || (%classname=xdata.Origin)),.methods,.parameters)
			If $$$ISERR(sc) Quit
		}
	}
	
	Quit sc
}

/// Parse the XML content of the XDATA block to get web service/client parameters
ClassMethod ParseOpen(stream As %GlobalCharacterStream, Output reader As %XML.Reader, Output root As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	Set root=""
	
	Try {
		If stream.Size<=0 Quit
	
		Set reader = ##class(%XML.Reader).%New()
		Set reader.KeepWhitespace=0
		Set sc=reader.OpenStream(stream)
		If $$$ISERR(sc) Quit
	
		#dim document As %XML.Document = reader.Document
		#dim node As %XML.Node = document.GetDocumentElement()
	
		If node="" Quit
	
		If node.LocalName="parameters" {
			If node.Namespace'=$$$SOAPWSISCConfig {
				Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname,"SOAP")
				Quit
			}
			Set root=node.LocalName
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Parse a single parameters element which is defined as an XData block.
ClassMethod ParseParametersElement(reader As %XML.Reader, processMethod As %Boolean, ByRef methods, Output parameters) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	#dim document As %XML.Document = reader.Document
	#dim node As %XML.Node = document.GetDocumentElement()
	
	If node.Namespace'=$$$SOAPWSISCConfig {
		Quit $$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname,"SOAP")
	}
		
	Try {
		Set continue=node.MoveToFirstChild()

		If continue, node.LocalName="request" {
			Do ..ParseIO(node,"request","",.parameters)
			Set continue=node.MoveToNextSibling()
		}

		If continue, node.LocalName="response" {
			Do ..ParseIO(node,"response","",.parameters)
			Set continue=node.MoveToNextSibling()
		}
		
		If processMethod {
			While continue {
				If node.LocalName'="method" Quit
				Do ..ParseMethod(node,.methods,.parameters)
				Set continue=node.MoveToNextSibling()
			}
	
			If continue {
				Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname,"SOAP")
			}
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Parse the method element
ClassMethod ParseMethod(node As %XML.Node, ByRef methods, Output parameters) [ Internal ]
{
	If node.Namespace'=$$$SOAPWSISCConfig {
		Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname,"SOAP")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
		
	Set methodName=node.GetAttributeValue("name")
	If methodName="" {
		Set sc=$$$ERROR($$$SOAPParamNoMethodName,%classname)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	If '$data(methods(methodName)) {
		Set sc=$$$ERROR($$$SOAPParamNoMethod,methodName,%classname)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}

	Set saveNode=node.NodeId

	Set continue=node.MoveToFirstChild()
	
	If continue, node.LocalName="request" {
		Do ..ParseIO(node,"request",methodName,.parameters)
		Set continue=node.MoveToNextSibling()
	}

	If continue, node.LocalName="response" {
		Do ..ParseIO(node,"response",methodName,.parameters)
		Set continue=node.MoveToNextSibling()
	}
	
	If continue {
		Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname,"SOAP")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	
	Set node.NodeId=saveNode
}

/// Parse the request or response element
ClassMethod ParseIO(node As %XML.Node, kind As %String, methodName As %String, Output parameters) [ Internal ]
{
	If node.Namespace'=$$$SOAPWSISCConfig {
		Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname,"SOAP")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
		
	Set saveNode=node.NodeId

	Set continue=node.MoveToFirstChild()
	While continue {
		If node.LocalName="header",node.Namespace=$$$SOAPWSISCConfig {
			Do ..ParseHeader(node,kind,methodName,.parameters)
			Set continue=node.MoveToNextSibling()
		} ElseIf node.LocalName="Action",node.Namespace=$$$SOAPWSISCConfig {
			If methodName="" Quit
			Do ..ParseAction(node,kind,methodName,.parameters)
			Set continue=node.MoveToNextSibling()
		} Else {
			Quit
		}
	}
	
	If continue {
		Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname,"SOAP")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}

	Set node.NodeId=saveNode
}

/// Parse the header element and save in paramneters
ClassMethod ParseHeader(node As %XML.Node, kind As %String, methodName As %String, Output parameters) [ Internal ]
{
	If node.Namespace'=$$$SOAPWSISCConfig {
		Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname,"SOAP")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
		
	Set name=node.GetAttributeValue("name")
	If name="" {
		Set sc=$$$ERROR($$$SOAPParamHeaderAttrReq,"name",%classname)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	Set class=node.GetAttributeValue("class")
	If class="" {
		Set sc=$$$ERROR($$$SOAPParamHeaderAttrReq,"class",%classname)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	Set alias=node.GetAttributeValue("alias")
	If alias="" Set alias=name
	If methodName="" {
		Set methodName=0
		Set use=$$$comClassKeyGet(%classname,$$$cCLASSsoapbodyuse)
	} Else {
		Set use=$$$comMemberKeyGet(%classname,$$$cCLASSmethod,methodName,$$$cMETHsoapbodyuse)
	}
	Set encoded=(use="encoded")

	Set parameters(methodName,kind,"header",name,class)=$lb(alias,encoded)
}

/// Parse the Action element and save in paramneters
ClassMethod ParseAction(node As %XML.Node, kind As %String, methodName As %String, Output parameters) [ Internal ]
{
	If node.Namespace'=$$$SOAPWSISCConfig {
		Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname,"SOAP")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	If 'node.GetText(.text) {
		Set sc=$$$ERROR($$$SOAPParamNoActionText,%classname)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	Set parameters(methodName,kind,"Action")=text
}

/// Fill in array of headers based on parameters and SOAPHEADERS
/// headers(namespace,name)=$lb(class,alias,encoded)
ClassMethod GetHeaders(class As %String, method As %String, kind As %String, soapHeaders As %String, Output headers) [ Internal ]
{
	Kill headers
	For i=1:1:$length(soapHeaders,",") {
		set headerName=$piece($piece(soapHeaders,",",i),":",1)
		set headerClass=$piece($piece(soapHeaders,",",i),":",2)
		If (headerName'="") && (headerClass'="") Set headers($c(0),headerName)=$lb(headerClass)
	}
	
	Merge parameters=$$$SOAPParametersNode(class)
	Merge xdataHeaders=parameters(0,kind,"header")
	If method'="" {
		Merge xdataHeaders=parameters(method,kind,"header")
	}
	Set headerName=""
	For {
		Set headerName=$order(xdataHeaders(headerName))
		If headerName="" Quit
		Set headerClass=""
		For {
			Set headerClass=$order(xdataHeaders(headerName,headerClass))
			If headerClass="" Quit
			Set namespace=$parameter(headerClass,"NAMESPACE")
			If namespace="" Set namespace=$c(0)
			Set headers(namespace,headerName)=$lb(headerClass)_xdataHeaders(headerName,headerClass)
		}
	}
	Quit
}

/// Create index of header classes -- byClass(class)=alias 
ClassMethod GetHeadersByClass(class As %String, method As %String, kind As %String, soapHeaders As %String, Output headersByClass) [ Internal ]
{
	Kill headers
	Do ..GetHeaders(class,method,kind,soapHeaders,.headers)

	Kill headersByClass
	Set namespace=""
	For {
		Set namespace=$order(headers(namespace))
		If namespace="" Quit
		Set name=""
		For {
			Set name=$order(headers(namespace,name))
			If name="" Quit
			Set class=$list(headers(namespace,name))
			Set alias=$listget(headers(namespace,name),2,name)
			Set headersByClass(class)=alias
		}
	}
}

/// Fill in array of header classes based on parameters.
/// Each entry is classes(classname,encoded,alias)=$lb(name,namespace)
ClassMethod GetClasses(class As %String, Output classes) [ Internal ]
{
	Kill classes
	Merge parameters=$$$SOAPParametersNode(class)
	Set method=""
	For {
		Set method=$order(parameters(method))
		If method="" Quit
		Set kind=""
		For {
			Set kind=$order(parameters(method,kind))
			If kind="" Quit
			Set name=""
			For {
				Set name=$order(parameters(method,kind,"header",name))
				If name="" Quit
				Set classname=""
				For {
					Set classname=$order(parameters(method,kind,"header",name,classname),1,val)
					If classname="" Quit
					Set namespace=$parameter(classname,"NAMESPACE")
					If namespace="" Set namespace=$c(0)
					Set alias=$list(val,1)
					Set encoded=$list(val,2)
					Set classes(classname,encoded,alias)=$lb(name,namespace)
					Set classes=$get(classes,0)+1
				}
			}
		}
	}
}

/// Get value of Action for method request or response.
ClassMethod GetAction(class As %String, method As %String, kind As %String) As %String [ CodeMode = expression, Internal ]
{
$select(method="":"",1:$get($$$SOAPParametersAction(class,method,kind)))
}

}
