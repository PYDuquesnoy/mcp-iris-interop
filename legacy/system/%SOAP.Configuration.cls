/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

IncludeGenerator %soap

/// Abstract super class of class to contain configuration of a SOAP web service or web client.
/// %SOAP.Configuration should be subclassed to specify the configuration.  No methods or
/// properties of %SOAP.Configuration should be directly accessed.<br><br>
/// 
/// The configuration is specified as XML content in an XData member of a subclass.
/// Each XData member may contain one configuration.  However, only one configuration
/// may be specified for each web service or web client class across all %SOAP.Configuration
/// subclasses in a namespace.
/// The format of the configuration as follows:<br>
/// <pre>
/// &lt;configuration name="xs:NCNAME"? xmlns="http://www.intersystems.com/configuration"&gt;
///    &lt;service classname="xs:NCNAME"&gt;
///       ( (&lt;wsp:Policy cfg:wsdlElement="s:string"? ...&gt; ... &lt;/wsp:Policy&gt;) 
///        |(&lt;wsp:PolicyReference URI="#policyId cfg:wsdlElement="s:string"?&gt;)) *
///       &lt;method name="xs:NCNAME"&gt;
///          ( (&lt;wsp:Policy cfg:wsdlElement="s:string"? ...&gt; ... &lt;/wsp:Policy&gt;) 
///           |(&lt;wsp:PolicyReference URI="#policyId cfg:wsdlElement="s:string"?&gt;)) *
///          &lt;request&gt;
///             ( (&lt;wsp:Policy cfg:wsdlElement="s:string"? ...&gt; ... &lt;/wsp:Policy&gt;) 
///              |(&lt;wsp:PolicyReference URI="#policyId cfg:wsdlElement="s:string"?&gt;)) *
///          &lt;/request&gt; ?
///          &lt;response&gt;
///             ( (&lt;wsp:Policy cfg:wsdlElement="s:string"? ...&gt; ... &lt;/wsp:Policy&gt;) 
///              |(&lt;wsp:PolicyReference URI="#policyId cfg:wsdlElement="s:string"?&gt;)) *
///          &lt;/response&gt; ?
///       &lt;/method&gt; *
///    &lt;/service&gt; +
/// &lt;configuration&gt;
/// Cardinality is indicated by ? (0 or 1), * (0 or more) and + (1 or more).
/// 
/// The following describes the elements and attributes:
/// /configuration
///     Identifies a configuration
/// /configuration/@name
///     Optional name of the configuration.  
///     If specified this name must match the name of the XData block.
/// /configuration/service
///     Identifies the service that is being configured
/// /configuration/service/@classname
///     The name of the web service or web client class that is being configured.
/// /configuration/service/wsp:Policy
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the endpoint or service subject for
///     this web service or client.
/// /configuration/service/wsp:Policy/@cfg:wsdlElement
///     Specifies WSDL attachment elements: service, port, binding, portType
/// /configuration/service/wsp:PolicyReference
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the endpoint or service subject for
///     to this method in the SOAP binding for this web service or client.
///     The policyId is a reference to a local policy defined in a different XData section.
/// /configuration/service/wsp:PolicyReference/@cfg:wsdlElement
///     Specifies WSDL attachment elements: service, port, binding, portType
/// 
/// /configuration/service/method
///     The configuration for the operation corresponding to this method in the SOAP binding 
///     for this web service or client.
/// /configuration/service/method/@name
///     The name of the method
/// /configuration/service/method/wsp:Policy
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the operation corresponding
///     to this method in the SOAP binding for this web service or client.
/// /configuration/service/method/wsp:Policy/@cfg:wsdlElement
///     Specifies WSDL attachment elements: binding, portType
/// /configuration/service/method/wsp:PolicyReference
///     The optional reference WS-Policy 1.2 or WS-Policy 1.5 to be applied to the operation corresponding
///     to this method in the SOAP binding for this web service or client.
///     The policyId is a reference to a local policy defined in a different XData section.
/// /configuration/service/method/wsp:PolicyReference/@cfg:wsdlElement
///     Specifies WSDL attachment elements: binding, portType
/// 
/// /configuration/service/method/request
///     The configuration for the request message corresponding to this method for 
///     this web service or client.
/// /configuration/service/method/request/wsp:Policy
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the request message corresponding
///     to this method for this web service or client.
/// /configuration/service/method/request/wsp:Policy/@cfg:wsdlElement
///     Specifies WSDL attachment elements: binding, portType, message
/// /configuration/service/method/request/wsp:PolicyReference
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the request message corresponding
///     to this method for this web service or client.
///     The policyId is a reference to a local policy defined in a different XData section.
/// /configuration/service/method/request/wsp:PolicyReference/@cfg:wsdlElement
///     Specifies WSDL attachment elements: binding, portType, message
/// 
/// /configuration/service/method/response
///     The configuration for the response message corresponding to this method for 
///     this web service or client.
/// /configuration/service/method/response/wsp:Policy
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the response message corresponding
///     to this method for this web service or client.
/// /configuration/service/method/response/wsp:Policy/@cfg:wsdlElement
///     Specifies WSDL attachment elements: binding, portType, message
/// /configuration/service/method/response/wsp:PolicyReference
///     The optional WS-Policy 1.2 or WS-Policy 1.5 to be applied to the response message corresponding
///     to this method for this web service or client.
///     The policyId is a reference to a local policy defined in a different XData section.
/// /configuration/service/method/response/wsp:PolicyReference/@cfg:wsdlElement
///     Specifies WSDL attachment elements: binding, portType, message
/// </pre>
Class %SOAP.Configuration Extends %RegisteredObject [ Abstract, System = 3 ]
{

Projection SOAPConfiguration As %Projection.SOAPConfiguration;

/// If REPORTANYERROR is true (1), Report error when compiling policy if any alternative is invalid.
/// Otherwise only report an error if all aternatives are invalid.  In this latter case,
/// we are looking for any alternative to use in a policy supplied by a thrid party.
Parameter REPORTANYERROR As BOOLEAN = 1;

/// Get configuration id for specified class
ClassMethod GetConfigId(classname As %String) As %String [ CodeMode = expression, Internal ]
{
$get($$$SOAPConfigIndex(classname))
}

/// Associate configuration with SOAP class
Method AssociateConfiguration(soapClassname As %String, configName As %String) [ Internal ]
{
	Set $$$SOAPConfigIndex(soapClassname)=$classname()_":"_configName
}

/// Remove Association of configuration with SOAP class
Method RemoveConfiguration(soapClassname As %String) [ Internal ]
{
	Kill $$$SOAPConfigIndex(soapClassname)
}

/// Get names of all SOAP classes which are configured in the specified configuration class.
ClassMethod GetSOAPClasses(configId As %String, Output SOAPClasses As %String) [ Internal ]
{
	Kill SOAPClasses
	Set configClass=$piece(configId,":",1)
	Set configName=""
	For {
	    Set configName=$order($$$SOAPConfig(configClass,configName))
	    If configName="" Quit
	    Set class=$get($$$SOAPConfig(configClass,configName,$$$SOAPConfigClass))
	    If class'="" Set SOAPClasses(class)=""
	}
}

/// Find all policies referenced using Policyreference or included as an inline Policy.
/// by one of the specified methods in the specified configuration.
/// List value is 1 if referenced policy, else 0.
ClassMethod FindWSDLPolicies(configId As %String, ByRef methods, Output policyList, Output version) [ Internal ]
{
	Kill policyList
	Set classname=$piece(configId,":",1)
	Set configName=$piece(configId,":",2)
	Set version=$get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyVersion))

	For refIndex=1:1:$get($$$SOAPConfig(classname,configName)) {
		Set policyIndex=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyRef,refIndex))
		If policyIndex="" Continue
		Set uri=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyId,refIndex))
		If (uri'="") && $get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyId,uri,$$$SOAPConfigPolicyTop)) {
			Set policyList(policyIndex)=1
		} Else {
			If '$data(policyList(policyIndex)) Set policyList(policyIndex)=0
		}
	}

	Set methodName=$order(methods(""))
	While methodName'="" {
		For refIndex=1:1:+$get($$$SOAPConfig(classname,configName,methodName)) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex="" Continue
			Set uri=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyId,refIndex))
			If (uri'="") && $get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyId,uri,$$$SOAPConfigPolicyTop)) {
				Set policyList(policyIndex)=1
			} Else {
				If '$data(policyList(policyIndex)) Set policyList(policyIndex)=0
			}
		}

		For refIndex=1:1:+$get($$$SOAPConfig(classname,configName,methodName,"request")) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,"request",$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex="" Continue
			Set uri=$get($$$SOAPConfig(classname,configName,methodName,"request",$$$SOAPConfigPolicyId,refIndex))
			If (uri'="") && $get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyId,uri,$$$SOAPConfigPolicyTop)) {
				Set policyList(policyIndex)=1
			} Else {
				If '$data(policyList(policyIndex)) Set policyList(policyIndex)=0
			}
		}

		For refIndex=1:1:+$get($$$SOAPConfig(classname,configName,methodName,"response")) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,"response",$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex="" Continue
			Set uri=$get($$$SOAPConfig(classname,configName,methodName,"response",$$$SOAPConfigPolicyId,refIndex))
			If (uri'="") && $get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyId,uri,$$$SOAPConfigPolicyTop)) {
				Set policyList(policyIndex)=1
			} Else {
				If '$data(policyList(policyIndex)) Set policyList(policyIndex)=0
			}
		}

		Set methodName=$order(methods(methodName))
	}
}

/// Write all policies referenced using Policyreference by one of
/// the specified methods in the specified configuration
ClassMethod WriteReferencedPolicies(writer As %XML.Writer, ByRef policyList) [ Internal ]
{
	Set policyIndex=$order(policyList(""))
	While policyIndex'="" {
		If policyList(policyIndex) {
			Do ..WritePolicy(writer,policyIndex,"","",0)
		}
		Set policyIndex=$order(policyList(policyIndex))
	}
}

/// Write inline Policy or PolicyReference for specified wsdlElement
ClassMethod WriteWSDLPolicy(writer As %XML.Writer, configId As %String, wsdlElement As %String, methodName As %String, reqres As %String) [ Internal ]
{
	Set classname=$piece(configId,":",1)
	Set configName=$piece(configId,":",2)

	If methodName="" {
		For refIndex=1:1:$get($$$SOAPConfig(classname,configName)) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex'="" {
				Set element=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyWsdlElement,refIndex),"binding")
				If element=wsdlElement {
					Set uri=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyId,refIndex))
					Do ..WritePolicy(writer,policyIndex,uri,"",0)
				}
			}
		}
	} ElseIf reqres="" {
		For refIndex=1:1:$get($$$SOAPConfig(classname,configName,methodName)) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex'="" {
				Set element=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyWsdlElement,refIndex),"binding")
				If element=wsdlElement {
					Set uri=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyId,refIndex))
					Do ..WritePolicy(writer,policyIndex,uri,"",0)
				}
			}
		}
	} Else {
		For refIndex=1:1:$get($$$SOAPConfig(classname,configName,methodName,reqres)) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,reqres,$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex'="" {
				Set element=$get($$$SOAPConfig(classname,configName,methodName,reqres,$$$SOAPConfigPolicyWsdlElement,refIndex),"binding")
				If element=wsdlElement {
					Set uri=$get($$$SOAPConfig(classname,configName,methodName,reqres,$$$SOAPConfigPolicyId,refIndex))
					Do ..WritePolicy(writer,policyIndex,uri,"",0)
				}
			}
		}
	}
}

/// Write a policy for the configuration class
/// <var>configName</var> is the name of configuration or "" for all configurations in the class.
ClassMethod WriteConfiguration(configName As %String = "", normalized As %Boolean = 0) As %Status [ Internal ]
{
	#dim writer As %XML.Writer = ##class(%XML.Writer).%New()
	Set writer.Indent=1
	;;Set writer.IndentChars="    "
	;;Set writer.AttributeQualified=1
	Set writer.SuppressXmlns=1
	Do writer.AddNamespace($$$SOAPWSUns,"wsu")
	
	Set sc=$$$OK
	Set classname=$zobjclass()
	Set sc=writer.RootElement("ConfigurationClass")
	If $$$ISERR(sc) Quit sc
	Do writer.WriteAttribute("name",classname)

	If configName'="" {
		If '$data($$$SOAPConfig(classname,configName)) {
			Quit $$$ERROR($$$SOAPConfigNotFound,configName,,classname)
		}
		Set sc=..WriteOneConfig(writer,configName,normalized)
	} Else {
		Set configName=$order($$$SOAPConfig(classname,""))
		While configName'="" {
			Set sc=..WriteOneConfig(writer,configName,normalized)
			If $$$ISERR(sc) Quit
			Set configName=$order($$$SOAPConfig(classname,configName))
		}
	}

	Do writer.EndRootElement()
	
	Quit sc
}

/// Write a single configuration
ClassMethod WriteOneConfig(writer As %XML.Writer, configName As %String, normalized As %Boolean) [ Internal ]
{
	Set sc=$$$OK
	
	Try {
		Set classname=$zobjclass()

		Do writer.AddNamespace($$$SOAPWSISCConfig,"cfg")
		If $$$SOAPPolicy(classname,$$$SOAPConfigPolicyVersion)="1.2" {
			Do writer.AddNamespace($$$SOAPWSPolicy12,"wsp")
			Do writer.AddNamespace($$$SOAPWSSecurityPolicy11,"sp")
		} ElseIf $$$SOAPPolicy(classname,$$$SOAPConfigPolicyVersion)="1.5" {
			Do writer.AddNamespace($$$SOAPWSPolicy15,"wsp")
			Do writer.AddNamespace($$$SOAPWSSecurityPolicy12,"sp")
		}
		
		If $get($$$SOAPConfig(classname,configName,$$$SOAPConfigClass))="" {
			Set policyType=$select(normalized:$$$SOAPConfigPolicyNormalized,1:$$$SOAPConfigPolicyRef)
			Set policyIndex=$get($$$SOAPConfig(classname,configName,policyType))
			If policyIndex'="" {
				Do ..WritePolicy(writer,policyIndex,"","",1)
			}

		} Else {
			Do writer.Element("configuration",$$$SOAPWSISCConfig)
			Do writer.WriteAttribute("name",configName)
			Do writer.Element("service",$$$SOAPWSISCConfig)
			Do writer.WriteAttribute("classname",$$$SOAPConfig(classname,configName,$$$SOAPConfigClass))

			If normalized {
				Set policyIndex=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyNormalized))
				If policyIndex'="" {
					Do ..WritePolicy(writer,policyIndex,"","",1)
				}
			} Else {
				For refIndex=1:1:$get($$$SOAPConfig(classname,configName)) {
					Set policyIndex=$get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyRef,refIndex))
					If policyIndex'="" {
						Do ..WritePolicy(writer,policyIndex,
						  $get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyId,refIndex)),
    					  $get($$$SOAPConfig(classname,configName,$$$SOAPConfigPolicyWsdlElement,refIndex))
    					  ,1)
					}
				}
			}
	
			Set methodName=$order($$$SOAPConfig(classname,configName,""))
			While methodName'="" {
				If ..IsName(methodName) {
					Do ..WriteMethod(writer,configName,methodName,normalized)
				}
				Set methodName=$order($$$SOAPConfig(classname,configName,methodName))
			}
	
			Do writer.EndElement()		; service
			Do writer.EndElement()		; configuration
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

ClassMethod WritePolicy(writer As %XML.Writer, policyIndex As %Integer, uri As %String, wsdlElement As %String, internal As %Boolean) [ Internal ]
{
	Set classname=$zobjclass()
	If uri'="" {
		Do ##class(%SOAP.Policy).WritePolicyReference(writer,uri,wsdlElement,$get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyVersion)),internal)
		
	} Else {
		Set policy=##class(%SOAP.Policy).%New()
		Merge policy.PolicyTree=$$$SOAPPolicy(classname,policyIndex)
		Set policy.PolicyTree($$$SOAPConfigPolicyVersion)=$get($$$SOAPPolicy(classname,$$$SOAPConfigPolicyVersion))
		Merge policy.PolicyAlternatives=$$$SOAPPolicyAlternatives(classname,policyIndex)
		Do policy.Write(writer,wsdlElement,internal)
	}
}

/// Write a method element
ClassMethod WriteMethod(writer As %XML.Writer, configName As %String, methodName As %String, normalized As %Boolean) [ Internal ]
{
	Set classname=$zobjclass()
	
	Do writer.Element("method",$$$SOAPWSISCConfig)
	Do writer.WriteAttribute("name",methodName)

	If normalized {
		Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyNormalized))
		If policyIndex'="" {
			Do ..WritePolicy(writer,policyIndex,"","",1)
		}

		Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,"request",$$$SOAPConfigPolicyNormalized))
		If policyIndex'="" {
			Do writer.Element("request",$$$SOAPWSISCConfig)
			Do ..WritePolicy(writer,policyIndex,"","",1)
			Do writer.EndElement()		; request
		}

		Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,"response",$$$SOAPConfigPolicyNormalized))
		If policyIndex'="" {
			Do writer.Element("response",$$$SOAPWSISCConfig)
			Do ..WritePolicy(writer,policyIndex,"","",1)
			Do writer.EndElement()		; response
		}
	} Else {
		For refIndex=1:1:$get($$$SOAPConfig(classname,configName,methodName)) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex'="" {
				Do ..WritePolicy(writer,policyIndex,
				  $get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyId,refIndex)),
    			  $get($$$SOAPConfig(classname,configName,methodName,$$$SOAPConfigPolicyWsdlElement,refIndex))
    			  ,1)
			}
		}

		For refIndex=1:1:$get($$$SOAPConfig(classname,configName,methodName,"request")) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,"request",$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex'="" {
				Do writer.Element("request",$$$SOAPWSISCConfig)
				Do ..WritePolicy(writer,policyIndex,
				  $get($$$SOAPConfig(classname,configName,methodName,"request",$$$SOAPConfigPolicyId,refIndex)),
    			  $get($$$SOAPConfig(classname,configName,methodName,"request",$$$SOAPConfigPolicyWsdlElement,refIndex))
    			  ,1)
				Do writer.EndElement()		; request
			}
		}
	
		For refIndex=1:1:$get($$$SOAPConfig(classname,configName,methodName,"response")) {
			Set policyIndex=$get($$$SOAPConfig(classname,configName,methodName,"response",$$$SOAPConfigPolicyRef,refIndex))
			If policyIndex'="" {
				Do writer.Element("response",$$$SOAPWSISCConfig)
				Do ..WritePolicy(writer,policyIndex,
				  $get($$$SOAPConfig(classname,configName,methodName,"response",$$$SOAPConfigPolicyId,refIndex)),
    			  $get($$$SOAPConfig(classname,configName,methodName,"response",$$$SOAPConfigPolicyWsdlElement,refIndex))
    			  ,1)
				Do writer.EndElement()		; response
			}
		}
	}
	
	Do writer.EndElement()		; method
}

/// Return true if this is a name rather than a defined type
ClassMethod IsName(name As %String) As %Boolean [ CodeMode = expression, Internal ]
{
$extract(name)'=$$$SOAPConfigIndicator
}

/// Parse all configurations defined in specified class.
ClassMethod OnConfigurationCompile() [ CodeMode = objectgenerator, Internal ]
{
	If %compiledclass.Abstract Quit $$$OK

	Quit ..ParseAll(%class.Name,%compiledclass)
}

/// Parse all configurations defined in specified class.
ClassMethod ParseAll(classname As %String, compiledclass As %Dictionary.CompiledClass) As %Status [ Internal ]
{
	Set sc=$$$OK
	New %classname
	Set %classname=classname
	Kill $$$SOAPConfig(%classname),$$$SOAPPolicy(%classname),$$$SOAPPolicyAlternatives(%classname)
	$$$SOAPLogConfigCompile("Compiling Configuration class: "_%classname)
	
	Set count=compiledclass.XDatas.Count()

	For i=1:1:count {
		Set xdata=compiledclass.XDatas.GetAt(i)
		Set configName=xdata.Name
		If configName="" Continue
		$$$SOAPLogConfigCompile("Opening Configuration: "_configName)
		Set sc=##class(%SOAP.Configuration).ParseOpen(xdata.Data,configName,.reader,.root)
		If $$$ISERR(sc) {
			$$$SOAPLogConfigCompile("Error result: ")
			Do $system.Status.DecomposeStatus(sc,.err)
			For i=1:1:err {
				$$$SOAPLogConfigCompile($zstrip($piece(err(i),"[",1),">W"))
			}
			Quit
		}
		If $data(reader) {
			Set configs(i,"reader")=reader
			Set configs(i,"name")=configName
			Set configs(i,"root")=root
		} Else {
			Set configs(i,"reader")=""
			Set configs(i,"name")=""
			Set configs(i,"root")=""
		}
	}

	If $$$ISOK(sc) {
		For i=1:1:count {
			If configs(i,"root")'="Policy" Continue

			Set configName=configs(i,"name")
			$$$SOAPLogConfigCompile("Compiling Policy: "_configName)
			Set sc=##class(%SOAP.Configuration).ParseConfigurationPolicy(configs(i,"reader"),configName)
			Kill configs(i,"reader")
			If $$$ISERR(sc) {
				$$$SOAPLogConfigCompile("Error result: ")
				Do $system.Status.DecomposeStatus(sc,.err)
				For i=1:1:err {
					$$$SOAPLogConfigCompile($zstrip($piece(err(i),"[",1),">W"))
				}
				Quit
			}
		}
	}

	If $$$ISOK(sc) {
		For i=1:1:count {
			If configs(i,"root")'="configuration" Continue

			Set configName=configs(i,"name")
			$$$SOAPLogConfigCompile("Compiling Configuration: "_configName)
			Set sc=##class(%SOAP.Configuration).ParseConfiguration(configs(i,"reader"),configName)
			Kill configs(i,"reader")
			If $$$ISERR(sc) {
				$$$SOAPLogConfigCompile("Error result: ")
				Do $system.Status.DecomposeStatus(sc,.err)
				For i=1:1:err {
					$$$SOAPLogConfigCompile($zstrip($piece(err(i),"[",1),">W"))
				}
				Quit
			}
		}
	}

	If $$$ISOK(sc) {
		Set configName=$order($$$SOAPConfig(%classname,""))
		While configName'="" {
			Set soapClassname=$get($$$SOAPConfig(%classname,configName,$$$SOAPConfigClass))
			If soapClassname'="" {
				Set $$$SOAPConfigIndex(soapClassname)=%classname_":"_configName
			}
			Set configName=$order($$$SOAPConfig(%classname,configName))
		}
	} Else {
		Kill $$$SOAPConfig(%classname),$$$SOAPPolicy(%classname),$$$SOAPPolicyAlternatives(%classname)
	}

	Quit sc
}

/// Parse the XML content of the XDATA block to determine if valid Policy or configuration
ClassMethod ParseOpen(stream As %GlobalCharacterStream, configName As %String, Output reader As %XML.Reader, Output root As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	New %fullStatus
	
	Try {
		Kill reader
		If stream.Size<=0 Quit
	
		Set reader = ##class(%XML.Reader).%New()
		Set reader.KeepWhitespace=0
		Set sc=reader.OpenStream(stream)
		If $$$ISERR(sc) Quit
	
		#dim document As %XML.Document = reader.Document
		#dim node As %XML.Node = document.GetDocumentElement()
	
		If node="" Quit
	
		If node.LocalName="configuration" {
			If node.Namespace'=$$$SOAPWSISCConfig {
				Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname_":"_configName,"%SOAP.Configuration")
				Quit
			}
		} ElseIf node.LocalName="Policy" {
			If (node.Namespace'=$$$SOAPWSPolicy12) && (node.Namespace'=$$$SOAPWSPolicy15) {
				Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname_":"_configName,"%SOAP.Configuration")
				Quit
			}
		} ElseIf node.LocalName'="parameters" {
			Set sc=$$$ERROR($$$SOAPConfigBadRoot,node.LocalName,%classname_":"_configName)
			Quit
		}
		
		Set root=node.LocalName

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Parse a wsp:Policy within a configuration file which is defined as an XData block.
ClassMethod ParseConfigurationPolicy(reader As %XML.Reader, configName As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	New %fullStatus
	
	Try {
		#dim document As %XML.Document = reader.Document
		#dim node As %XML.Node = document.GetDocumentElement()
	
		Set policy=..ParsePolicy(node,configName,"","",0,.policyIndex,"",.normalizedPolicyIndex)
		If policy'="" {
			Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyRef)=policyIndex
			Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyNormalized)=normalizedPolicyIndex
		}

	} Catch ex {
		If $data(%fullStatus) {
			Set sc=%fullStatus
		} Else {
			Set sc=ex.AsStatus()
		}
	}
	
	Quit sc
}

/// Parse a SOAP configuration which is defined as an XData block.
ClassMethod ParseConfiguration(reader As %XML.Reader, configName As %String) As %Status [ Internal ]
{
	Set sc=$$$OK
	New %fullStatus
	
	Try {
		#dim document As %XML.Document = reader.Document
		#dim node As %XML.Node = document.GetDocumentElement()
	
		Set name=node.GetAttributeValue("name")
		If (name'="") && (name'=configName) {
			Set sc=$$$ERROR($$$SOAPConfigNameNoMatch,name,%classname_":"_configName)
			Quit
		}
	
		If node.MoveToFirstChild() {
			If node.LocalName="service" {
				If node.Namespace'=$$$SOAPWSISCConfig {
					Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname_":"_configName,"%SOAP.Configuration")
					Quit
				}
				If $data($$$SOAPConfig(configName)) {
					Set sc=$$$ERROR($$$SOAPConfigDuplicate,%classname_":"_configName)
					Quit
				}
				Do ..ParseService(node,configName)
				If node.MoveToNextSibling() {
					Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname_":"_configName,"%SOAP.Configuration")
					Quit
				}
			} Else {
				Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname_":"_configName,"%SOAP.Configuration")
				Quit
			}
		}
	} Catch ex {
		If $data(%fullStatus) {
			Set sc=%fullStatus
		} Else {
			Set sc=ex.AsStatus()
		}
	}
	
	Quit sc
}

/// Parse the service configuration
ClassMethod ParseService(node As %XML.Node, configName As %String) [ Internal ]
{
	Set sc=$$$OK
	// classname attribute must be specified.
	// However, allow classname="" which means index set later to associate policy with class.
	If 'node.AttributeDefined("classname") {
		Set sc=$$$ERROR($$$SOAPConfigNoClass,%classname_":"_configName)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	Set soapClassname=node.GetAttributeValue("classname")
	If soapClassname'="",$data($$$SOAPConfigIndex(soapClassname)) {
		Set sc=$$$ERROR($$$SOAPConfigDuplicateClass,%classname_":"_configName,soapClassname)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}

    Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigClass)=soapClassname

	Set continue=node.MoveToFirstChild()
	Set refIndex=0
	Set servicePolicy=""
	While continue {
		Set policy=..ParsePolicy(node,configName,"",$lb("service","port","binding","portType"),1,.policyIndex,servicePolicy,.normalizedPolicyIndex)
		If policy'="" {
			Set refIndex=refIndex+1
			Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyRef,refIndex)=policyIndex
			If policy.PolicyReferenceId'="" {
				Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyId,refIndex)=policy.PolicyReferenceId
			}
			If policy.WsdlElement'="" {
				Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyWsdlElement,refIndex)=policy.WsdlElement
			}

			Set servicePolicy=policy
			Set continue=node.MoveToNextSibling()
		} Else {
			Quit
		}
	}
	
	If refIndex>0 {
		Set $$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyNormalized)=normalizedPolicyIndex
		Set $$$SOAPConfig(%classname,configName)=refIndex
		Do ..ParseAnalyze(servicePolicy,normalizedPolicyIndex)
	}
	
	While continue {
		If node.LocalName'="method" Quit

		If node.Namespace'=$$$SOAPWSISCConfig {
			Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname_":"_configName,"%SOAP.Configuration")
			Quit
		}
		
		Do ..ParseMethod(node,configName,servicePolicy)
		
		Set continue=node.MoveToNextSibling()
	}
	
	If continue {
		Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname_":"_configName,"%SOAP.Configuration")
	}

	If $$$ISERR(sc) {
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
}

/// Parse the method element of the configuration
ClassMethod ParseMethod(node As %XML.Node, configName As %String, servicePolicy As %SOAP.Policy) [ Internal ]
{
	#dim methodPolicy As %SOAP.Policy
	Set methodName=node.GetAttributeValue("name")
	If methodName="" {
		Set sc=$$$ERROR($$$SOAPConfigNoMethodName,%classname_":"_configName)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	If $data($$$SOAPConfig(%classname,configName,methodName)) {
		Set sc=$$$ERROR($$$SOAPConfigDuplicateMethod,%classname_":"_configName,methodName)
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}

    Set $$$SOAPConfig(%classname,configName,methodName)=0

	Set saveNode=node.NodeId

	Set refIndex=0
	Set methodPolicy=servicePolicy
	Set continue=node.MoveToFirstChild()
	While continue {
		Set policy=..ParsePolicy(node,configName,methodName,$lb("binding","portType"),1,.policyIndex,methodPolicy,.normalizedPolicyIndex)
		If policy'="" {
			Set refIndex=refIndex+1
			Set $$$SOAPConfig(%classname,configName,methodName,$$$SOAPConfigPolicyRef,refIndex)=policyIndex
			If policy.PolicyReferenceId'="" {
				Set $$$SOAPConfig(%classname,configName,methodName,$$$SOAPConfigPolicyId,refIndex)=policy.PolicyReferenceId
			}
			If policy.WsdlElement'="" {
				Set $$$SOAPConfig(%classname,configName,methodName,$$$SOAPConfigPolicyWsdlElement,refIndex)=policy.WsdlElement
			}
			Set methodPolicy=policy
			Set continue=node.MoveToNextSibling()
		} Else {
			Quit
		}
	}
	
	If refIndex>0 {
		Set $$$SOAPConfig(%classname,configName,methodName,$$$SOAPConfigPolicyNormalized)=normalizedPolicyIndex
		Set $$$SOAPConfig(%classname,configName,methodName)=refIndex
	} Else {
		Set normalizedPolicyIndex=$get($$$SOAPConfig(%classname,configName,$$$SOAPConfigPolicyNormalized))
	}
	
	If continue && (node.LocalName="request") {
		Do ..ParseIO(node,configName,"request",methodName,methodPolicy,normalizedPolicyIndex)
		Set continue=node.MoveToNextSibling()
	} Else {
		Do ..ParseAnalyze(methodPolicy,normalizedPolicyIndex)
	}
	
	If continue && (node.LocalName="response") {
		Do ..ParseIO(node,configName,"response",methodName,methodPolicy,normalizedPolicyIndex)
		Set continue=node.MoveToNextSibling()
	} Else {
		Do ..ParseAnalyze(methodPolicy,normalizedPolicyIndex)
	}
	
	If continue {
		Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname_":"_configName,"%SOAP.Configuration")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
	
	Set node.NodeId=saveNode
}

/// Parse the request or response element of the configuration
ClassMethod ParseIO(node As %XML.Node, configName As %String, kind As %String, methodName As %String, methodPolicy As %SOAP.Policy, methodPolicyIndex As %Integer) [ Internal ]
{
	If node.Namespace'=$$$SOAPWSISCConfig {
		Set sc=$$$ERROR($$$SOAPConfigUnexpectedNamespace,node.QName,%classname_":"_configName,"%SOAP.Configuration")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
		
	Set saveNode=node.NodeId
	Set io=node.LocalName

	Set refIndex=0
	Set ioPolicy=methodPolicy
	Set continue=node.MoveToFirstChild()
	While continue {
		Set policy=..ParsePolicy(node,configName,methodName_":"_kind,$lb("binding","portType","message"),1,.policyIndex,ioPolicy,.normalizedPolicyIndex)
		If policy'="" {
			Set refIndex=refIndex+1
			Set $$$SOAPConfig(%classname,configName,methodName,io,$$$SOAPConfigPolicyRef,refIndex)=policyIndex
			If policy.PolicyReferenceId'="" {
				Set $$$SOAPConfig(%classname,configName,methodName,io,$$$SOAPConfigPolicyId,refIndex)=policy.PolicyReferenceId
			}
			If policy.WsdlElement'="" {
				Set $$$SOAPConfig(%classname,configName,methodName,io,$$$SOAPConfigPolicyWsdlElement,refIndex)=policy.WsdlElement
			}
			Set ioPolicy=policy
			Set continue=node.MoveToNextSibling()
		} Else {
			Quit
		}
	}
	
	If continue {
		Set sc=$$$ERROR($$$SOAPConfigUnexpected,node.QName,%classname_":"_configName,"%SOAP.Configuration")
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}

	If refIndex>0 {
		Set $$$SOAPConfig(%classname,configName,methodName,io,$$$SOAPConfigPolicyNormalized)=normalizedPolicyIndex
		Set $$$SOAPConfig(%classname,configName,methodName,io)=refIndex
		Do ..ParseAnalyze(ioPolicy,normalizedPolicyIndex)
	} Else {
		Do ..ParseAnalyze(methodPolicy,methodPolicyIndex)
	}
	
	Set node.NodeId=saveNode
}

/// Analyze a policy
ClassMethod ParseAnalyze(policy As %SOAP.Policy, policyIndex As %Integer) [ Internal ]
{
	If $get(policy)="" Quit
	If $data(policy.PolicyAlternatives) Quit

	Set reportAnyError=''$$$comMemberKeyGet(%classname,$$$cCLASSparameter,"REPORTANYERROR",$$$cPARAMdefault)
	Set sc=policy.Analyze(reportAnyError)
	If $$$ISOK(sc) {
		If policyIndex'="" {
			Merge $$$SOAPPolicyAlternatives(%classname,policyIndex)=policy.PolicyAlternatives
		}
	} Else {
		Set %fullStatus=sc
		Throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
}

/// Parse a wsp:Policy element in the configuration
ClassMethod ParsePolicy(node As %XML.Node, configName As %String, kind As %String, validWSDL As %List, inline As %Boolean, Output policyIndex As %Integer, basePolicy As %SOAP.Policy, Output normalizedPolicyIndex As %Integer) As %SOAP.Policy [ Internal ]
{
///    $$$SOAPPolicy(configClass,$$$SOAPConfigPolicyId,policyId)=policyIndex
///    $$$SOAPPolicy(configClass,$$$SOAPConfigPolicyName,policyName)=policyIndex
///    $$$SOAPPolicy(configClass,$$$SOAPConfigPolicyVersion)=policyVersion
	Set policyIndex=0

	Set policy=##class(%SOAP.Policy).ParsePolicy(node,%classname_":"_configName_$select(kind="":"",1:":"_kind),validWSDL)
	If policy'="" {
		If policy.PolicyReferenceId="" {
			Set policyIndex=$increment($$$SOAPPolicy(%classname))
			Merge $$$SOAPPolicy(%classname,policyIndex)=policy.PolicyTree

			Set policyId=$get(policy.PolicyTree($$$SOAPConfigPolicyId))
			If policyId'="" {
				Set $$$SOAPPolicy(%classname,$$$SOAPConfigPolicyId,policyId)=policyIndex
				If 'inline Set $$$SOAPPolicy(%classname,$$$SOAPConfigPolicyId,policyId,$$$SOAPConfigPolicyTop)=1
			}
			Set policyName=$get(policy.PolicyTree($$$SOAPConfigPolicyName))
			If policyName'="" {
				Set $$$SOAPPolicy(%classname,$$$SOAPConfigPolicyName,policyName)=policyIndex
				If 'inline Set $$$SOAPPolicy(%classname,$$$SOAPConfigPolicyId,policyName,$$$SOAPConfigPolicyTop)=1
			}
			Set policyVersion=$get(policy.PolicyTree($$$SOAPConfigPolicyVersion))
			If policyVersion>$get($$$SOAPPolicy(%classname,$$$SOAPConfigPolicyVersion)) {
				Set $$$SOAPPolicy(%classname,$$$SOAPConfigPolicyVersion)=policyVersion
			}
		} Else {
			Set policyIndex=policy.PolicyIndex
		}
		
		If basePolicy'="" Do policy.Merge(basePolicy)
		Do policy.Normalize(inline)
		Set normalizedPolicyIndex=$increment($$$SOAPPolicy(%classname))
		Merge $$$SOAPPolicy(%classname,normalizedPolicyIndex)=policy.PolicyTree
	}
	
	Quit policy
}

/// Write out configuration policy -- should never be called.
ClassMethod WriteAlternative(ByRef alternative, indent As %String = "   ") As %String [ Internal ]
{
	Quit ""
}

/// Analyze ISC configuraation assertion -- should never be called.
ClassMethod AnalyzeAssertion(policy As %SOAP.Policy, nodeId As %Integer, ByRef alternative) As %Status [ Internal ]
{
	Quit $$$ERROR($$$SOAPPolicyUnknown,policy.PolicyTree(nodeId),policy.ConfigLabel)
}

}
