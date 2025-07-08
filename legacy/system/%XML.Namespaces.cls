/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// %XML.Namespace manages the XML namespaces for an XML document.
Class %XML.Namespaces Extends %RegisteredObject [ System = 3 ]
{

/// The default namespace to use when no namespace is specified for the 
/// current namespace.  The namespace "" is treated as equivalent to an
/// XML document with no namespace.
Property DefaultNamespace As %String;

/// If true, the XML document is the the form specified by elementFormDefault="qualified".
/// This is the default value to use if elementQualfied not specified in PushNodeForExport.
Property ElementQualified As %Boolean [ InitialExpression = 0 ];

/// If true, the XML document is the the form specified by attributeFormDefault="qualified".
Property AttributeQualified As %Boolean [ InitialExpression = 0 ];

/// <property>SuppressXmlns</property> allows optionally suppression of the use of xmlns= to set
/// default XML namespace when ElementQualified is false.  
/// If SuppressXmlns is true then a prefix is used for each tag rather than default namespace with xmlns=. 
Property SuppressXmlns As %Boolean [ InitialExpression = 0 ];

/// <property>SuppressAutoPrefix</property> allows optionally suppression of the prefix
/// that is created for the default XML namespace even if it is not needed for the current element.  
Property SuppressAutoPrefix As %Boolean [ InitialExpression = 0, Internal ];

/// <property>DefaultXmlns</property> allows optional specification of the XML namespace
/// to use as the default XML namespace when SuppressXmlns is false.  
Property DefaultXmlns As %String;

/// <property>OutputTypeAttribute</property> allows the user to force the inclusion of the xsi:type
/// attribute for each element of object output.
Property OutputTypeAttribute As %Boolean [ InitialExpression = 0 ];

Method OutputTypeAttributeSet(value As %Boolean) As %Status [ Internal ]
{
	Set i%OutputTypeAttribute=value
	If value {
		Do ..AddInstanceNamespace()
		Do ..AddSchemaNamespace()
	}
}

/// Restore the value of <property>OutputTypeAttribute</property> without adding the schema namespaces again.
Method RestoreOutputTypeAttribute(value As %Boolean) As %Status [ Internal ]
{
	Set i%OutputTypeAttribute=value
}

/// The namespace for the current node.
Property CurrentNamespace As %String;

/// The depth of the current namespace list.
/// The <property>depth</property> property represents the number of times this identical
/// namespace list has been pushed for a child node.  This use of depth
/// is an optimization to prevent the use of an instance of %XML.Namespaces
/// for each level of child node.
Property depth As %Integer [ InitialExpression = 0, Internal, Private ];

/// The <property>stack</property> property points to the next %XML.Namespaces
/// instance on the linked list that defines the stack of nodes.
Property stack As %XML.Namespaces [ Internal, Private ];

/// The <property>maxPrefix</property> property is the number for the next last
/// prefix of the form "s"_..maxPrefix that was created.
Property maxPrefix As %Integer [ InitialExpression = 0, Internal, Private ];

/// The namespaces that have already been defined.
/// For each namespace, namespaces(prefix)=namespace.
Property namespaces As %String [ Internal, MultiDimensional, Private ];

/// The prefixes associated with namespaces that have already been defined.
/// Each entry in prefixes has a corresponding entry in namespaces.
/// For each namespace, prefixes(namespace)=prefix.
Property prefixes As %String [ Internal, MultiDimensional, Private ];

/// The schemaLocation associated with namespaces that have already been defined.
/// Each entry in locations has a corresponding entry in namespaces.
/// For each namespace, locations(namespace)=schemaLocation.
/// If locations(namespace) node exists, then no schemaLocation attribute is to be output.
/// If locations(namespace)="", then the schemaLocation attribute has already been output.
Property locations As %String [ Internal, MultiDimensional, Private ];

/// The namespaces that will be defined for child nodes.
/// These namespaces do not yet have there prefix defined even though
/// the prefix may be specified as a hint.
/// For each added namespace and prefix, addedNamespaces(namespace,prefix)=schemaLocation.
Property addedNamespaces As %String [ Internal, MultiDimensional, Private ];

/// These namespaces where added temporarily
Property removeNamespaces As %String [ Internal, MultiDimensional, Private ];

/// The default namespace that the XML document has defined or "" if none.
Property DefaultDefined As %String;

/// Save default namespace when making temporary change before calling XMLExportInternal
/// in order to support form="unqualified"
Property SaveDefaultDefined As %String;

/// The current value of ElementQualified.
Property CurrentElementQualified As %Boolean [ Internal, Private ];

/// Stable is true, if the same prefixes may be used if the current namespace does not change
Property Stable As %Boolean [ Internal ];

/// DefaultPrefix(namespace)=prefix is an array of default prefixes to be used for 
/// adding namespaces when no prefix is defined.
Property DefaultPrefix As %String [ MultiDimensional ];

/// Push a new current namespace onto the stack of active namespaces.<br><br>
/// 
/// <var>namespace</var> is the XML namespace for the elements of the
/// node that is being created.  This method does not actually create the node.
/// It just does the required namespace handling.  If this namespace
/// has not yet been added, it will also be added with a default prefix.
/// The default namespace will be the namespace for the node if "" is specified.<br>
Method PushNode(namespace As %String = "") As %Status
{
	If namespace="" Set namespace=..DefaultNamespace

	Set addNewCurrent=(namespace'="") && '$data(..prefixes(namespace)) && '$data(..addedNamespaces(namespace))

	If '$data(..removeNamespaces) && (namespace=..CurrentNamespace) && ($order(..addedNamespaces(""))="") && 'addNewCurrent {
		Set ..depth=..depth+1
	} Else {
		Set ns=..%ConstructClone()
		Set ..Stable=0
		Kill ns.addedNamespaces
		Set ..stack=ns
		Set ..depth=1
		Set ..CurrentNamespace=namespace
	}

	// Add new current namespace
	If addNewCurrent && '..SuppressAutoPrefix Set ..addedNamespaces(namespace,$c(0))=""

	Quit $$$OK
}

/// Set new value of DefaultDefined property. 
/// If the value of DefaultDefined changes, then make sure that this node
/// is at depth=1.
Method SetDefaultDefined(defaultdefined As %String) [ Internal, Private ]
{
	If defaultdefined=i%DefaultDefined Quit
	
	If ..depth>1 {
		Set ..depth=..depth-1
		Set ns=..%ConstructClone()
		Set ..Stable=0
		Set ..stack=ns
		Set ..depth=1
	}
	Set i%DefaultDefined=defaultdefined

	Quit
}

/// Pop previous value of DefaultDefined property. 
Method PopDefaultDefined() [ Internal ]
{
	Set prev=$select(..depth=1:..stack,1:$this)
	If prev'="" Set i%DefaultDefined=prev.DefaultDefined
}

/// Set new value of CurrentElementQualified property. 
/// If the value of CurrentElementQualified changes, then make sure that this node
/// is at depth=1.
Method SetCurrentElementQualified(elementQualified As %Boolean) [ Internal, Private ]
{
	If elementQualified=i%CurrentElementQualified Quit
	
	If ..depth>1 {
		Set ..depth=..depth-1
		Set ns=..%ConstructClone()
		Set ..Stable=0
		Set ..stack=ns
		Set ..depth=1
	}
	Set i%CurrentElementQualified=elementQualified

	Quit
}

/// Set new value of SuppressXmlns property. 
/// If the value of SuppressXmlns changes, then make sure that this node
/// is at depth=1.
Method SetSuppressXmlns(suppressxmlns As %Boolean) [ Internal, Private ]
{
	If suppressxmlns=i%SuppressXmlns Quit
	
	If ..depth>1 {
		Set ..depth=..depth-1
		Set ns=..%ConstructClone()
		Set ..Stable=0
		Set ..stack=ns
		Set ..depth=1
	}
	Set i%SuppressXmlns=suppressxmlns

	Quit
}

/// Set new value of Stable property. 
/// If the value of Stable changes, then make sure that this node
/// is at depth=1.
Method SetStable(stable As %Boolean) [ Internal ]
{
	If stable=i%Stable Quit
	
	If ..depth>1 {
		Set ..depth=..depth-1
		Set ns=..%ConstructClone()
		Set ..stack=ns
		Set ..depth=1
	}
	Set i%Stable=stable

	Quit
}

/// Push a new current namespace onto the stack of active namespaces
/// and return information needed by XMLExport.<br><br>
/// 
/// This method is for internal use only. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this method.<br>
/// 
/// <var>namespace</var> is the XML namespace for the elements of the
/// node that is being created.  This mehod does not actually create the node.
/// It just does the required namespace hadnling.  If this namespace
/// has not yet been added, it will also be added with a default prefix.
/// The default namespace will be the namespace for the node if "" is specified.<br>
/// <var>local</var> specifies if the element is treated as a local element.
/// A global element is specified by a false value of <var>local</var> which can
/// be either 0 to represent a global element in the namespace specified by
/// the <var>namespace</var> argument or a string which is the namespace to which
/// the global element belongs.
/// The default for <var>local</var> is 0.<br>
/// <var>defaultPrefixRequired</var> specifies if the prefix for the default namespace must be defined.
/// <var>elementQualified</var> specifies override for ElementQualified property.<br>
/// The following are returned for use the XMLExport based on the new current namespace:<br>
/// <var>topPrefix</var> is the prefix (or "") to be used for the next top containing tag.<br>
/// <var>topAttrs</var> is any xmlns attributes needed to define topPrefix.<br>
/// <var>typesPrefix</var> is the prefix to be used for type references in the object being exported.<br>
/// <var>attrsPrefix</var> is the prefix (or "") to be used for any attributes of this object.<br>
/// <var>soapPrefix</var> is prefix to be used for the SOAP encoding namespace.<br>
/// <var>schemaPrefix</var> is prefix to be used for the XML schema namespace.<br>
/// <var>xsiPrefix</var> is prefix to be used for the XML schema instance namespace.<br>
/// <var>xsiAttrs</var> is any xmlns attributes needed to define the XML schema instance namespace.<br>
Method PushNodeForExport(namespace As %String = "", local As %Boolean, defaultPrefixRequired As %Boolean, elementQualified As %Boolean, attributeQualified As %Boolean, Output topPrefix As %String, Output topAttrs As %String, Output typesPrefix As %String, Output attrsPrefix As %String, Output usePrefix As %Boolean, forceStable As %Boolean) As %Status [ Internal ]
{
	// Special value of local to indicate that DefaultDefined should not be changed
	Set saveDefaultDefined=..SaveDefaultDefined
	If local=-2 {
		Set local=1
		Set ..SaveDefaultDefined=..DefaultDefined
		Set formQualified=elementQualified
	} Else {
		Set ..SaveDefaultDefined=""
		Set formQualified=""
	}
	
	Set sc=..PushNode(namespace)
	If $$$ISERR(sc) Quit sc
	
	If $get(elementQualified)="" Set elementQualified=..ElementQualified
	Do ..SetCurrentElementQualified(elementQualified)
	If $get(attributeQualified)="" Set attributeQualified=..AttributeQualified
	
	Set stable=0
	Set prefixRequired=1
	Set ns=..CurrentNamespace
	Set prev=$select(..depth=1:..stack,1:$this)
	Set prevns=$select(prev="":"",1:prev.CurrentNamespace)
	Set preveq=$select(prev="":"",1:prev.CurrentElementQualified)
	
	Set elementns=$case(local,-1:ns,1:prevns,0:ns,:local)
	
	Kill locs	
	Set topAttrs=""
	Set topPrefix=""
	Set prefixNS=""
	Set usePrefix=..SuppressXmlns
	
	Set defaultXmlns=$select(..DefaultXmlns=$c(0):"",1:..DefaultXmlns)

	If ns'="" {
		If ns'=prevns,attributeQualified,..GetPrefix(ns)="" {
			Do ..AddNamespace(ns)
		}

		If elementQualified {
			If ns'=prevns {
				If local || (ns'=elementns) Set prefixNS=elementns
				If '..SuppressXmlns {
					If ..DefaultXmlns="" {
						if ns'=..DefaultDefined {
							Set topAttrs="xmlns="""_ns_"""" Do ..SetDefaultDefined(ns)
							Set locs(ns)=""
						}
						Set prefixRequired=defaultPrefixRequired
						Set stable=(prefixNS="")
					} Else {
						If defaultXmlns'=ns {
							If 'local Set prefixNS=elementns
							Set defaultPrefixRequired=1
							Set usePrefix=1
						} Else {
							Set usePrefix=0
							Set stable=(prefixNS="")
						}
					}
				} Else {
					If (..DefaultDefined'="") && '..SuppressAutoPrefix {
						Set topAttrs="xmlns=""""" Do ..SetDefaultDefined("")
					}
					Set defaultPrefixRequired=1
					If 'local Set prefixNS=elementns
					Set stable=0
				}
			} Else {
				Set stable=1
				If '..SuppressXmlns {
					Set newns=$select(..DefaultXmlns'="":defaultXmlns,1:..DefaultDefined)
					If newns'=ns {
						If ..DefaultXmlns="" {
							if ns'=..DefaultDefined {
								Set topAttrs="xmlns="""_ns_"""" Do ..SetDefaultDefined(ns)
								Set locs(ns)=""
							}
							Set prefixRequired=defaultPrefixRequired
						} Else {
							If defaultXmlns'=ns {
								Set prefixNS=elementns
								Set usePrefix=1
								Set stable=0
							} Else {
								Set usePrefix=0
							}
						}
					}
				} Else {
					Set prefixNS=elementns
				}
			}
		} Else {
			If 'local Set prefixNS=elementns
			If (..DefaultDefined'="") || (saveDefaultDefined'="") {
				Set topAttrs="xmlns=""""" Do ..SetDefaultDefined("")
			} Else {
				Set topAttrs=$c(0)
			}
		}
	} Else {
		If elementQualified && (ns'=prevns) && (local'=0) && (..SuppressXmlns || ..DefaultDefined'="") {
			Set prefixNS=elementns
		}
		If ..DefaultDefined'="" {
			Set topAttrs="xmlns=""""" Do ..SetDefaultDefined("")
		} Else {
			Set topAttrs=$c(0)
		}
		Set stable=0
	}
	
	If '..SuppressXmlns && (topAttrs="") && (..DefaultXmlns'="") && (defaultXmlns'=..DefaultDefined) {
		Set topAttrs="xmlns="""_defaultXmlns_""""
		Do ..SetDefaultDefined(defaultXmlns)
		If defaultXmlns'="" Set locs(defaultXmlns)=""
	}

	If topAttrs=$c(0) Set topAttrs=""

	If elementQualified && (preveq=0) && (local=1) Set prefixNS=""
	If 'elementQualified && (preveq=1) && (local=1) && (formQualified="") Set prefixNS=elementns

	If prefixNS'="" {
		Set topPrefix=..GetPrefix(prefixNS)
		If topPrefix="" {
			Do ..DefineNamespacePrefix(prefixNS,(prefixRequired||(ns'=prefixNS)))
			Set topPrefix=..GetPrefix(prefixNS)
			If topPrefix'="" {
				Set definePrefixes(topPrefix)=prefixNS
				Set locs(prefixNS)=""
			}
		}
		If topPrefix'="" Set topPrefix=topPrefix_":"
	} ElseIf local && (..DefaultDefined'="") && ($extract(topAttrs,1,6)="xmlns=") {
		Do ..SetSuppressXmlns(1)
		Set usePrefix=1
		If saveDefaultDefined'="" {
			Set topAttrs="xmlns="""""
		} Else {
			Set topAttrs=""
		}
		Kill locs
		Do ..SetDefaultDefined("")
		Set defaultPrefixRequired=1
		Set stable=0
	}

	Set nsName=$order(..addedNamespaces(""))
	While nsName'="" {
		Set prefix=$order(..addedNamespaces(nsName,""))
		While prefix'="" {
			Do ..DefineNamespacePrefix(nsName,(prefixRequired||(ns'=nsName)),prefix)
			If prefix=$c(0) Set prefix=..GetPrefix(nsName)
			If prefix'="" {
				Set definePrefixes(prefix)=nsName
				Set locs(nsName)=""
			}
			Set prefix=$order(..addedNamespaces(nsName,prefix))
		}
		Set nsName=$order(..addedNamespaces(nsName))
	}
	
	If ns'="" {
		Set prefix=..GetPrefix(ns)
		If defaultPrefixRequired || attributeQualified, prefix="" {
			Do ..DefineNamespacePrefix(ns,1)
			Set prefix=..GetPrefix(ns)
			;;If defaultPrefixRequired Set ..prefixes(ns)=""
			If prefix'="" {
				Set definePrefixes(prefix)=ns
				Set locs(ns)=""
			}
		}
		Set typesPrefix=$select(prefix="":"",1:prefix_":")
		If formQualified=0 Set typesPrefix=""
		Set attrsPrefix=$select(attributeQualified:typesPrefix,1:"")
	} Else {
		Set typesPrefix=""
		Set attrsPrefix=""
	}

	Set prefix=$order(definePrefixes(""))
	While prefix'="" {
		If topAttrs'="" Set topAttrs=topAttrs_" "
		Set topAttrs=topAttrs_"xmlns:"_prefix_"="""_definePrefixes(prefix)_""""
		Set ..removeNamespaces(definePrefixes(prefix))=""
		Set prefix=$order(definePrefixes(prefix))
	}

	If topAttrs'="" {
		Set locString=""
		Set ns=$order(locs(""))
		While ns'="" {
			If $get(..locations(ns))'="" {
				If locString'="" Set locString=locString_" "
				Set locString=locString_ns_" "_..locations(ns)
				Set ..locations(ns)=""
			}
			Set ns=$order(locs(ns))
		}
		If locString'="" {
			Set xsiPrefix=..GetPrefix($$$XSIns)
			If xsiPrefix'="" Set xsiPrefix=xsiPrefix_":"
			Set topAttrs=topAttrs_" "_xsiPrefix_"schemaLocation="""_locString_""""
		}
	}
	
	If $get(forceStable)'="" {
		Set stable=forceStable
	} ElseIf attributeQualified {
		Set stable=0
	}
	Do ..SetStable(stable)
	
	Quit sc
}

/// Pop the namespace information for the last node pushed.
Method PopNode()
{
	Set ..depth=..depth-1
	If ..depth<1 {
		If ..stack'="" {
			Do ..Copy(..stack)
		} Else {
			Do ..Reset()
		}
	} Else {
		Set namespace=$order(..removeNamespaces(""))
		While namespace '="" {
			Set prefix=$get(..prefixes(namespace))
			Kill ..prefixes(namespace)
			If prefix'="" kill ..namespaces(prefix)
			Set namespace=$order(..removeNamespaces(namespace))
		}
		Kill ..removeNamespaces
	}
}

/// Remove any prefix definitions that were introduced just for one class
Method PopNamespaces() [ Internal ]
{
	Set namespace=$order(..removeNamespaces(""))
	While namespace '="" {
		Set prefix=$get(..prefixes(namespace))
		Kill ..prefixes(namespace)
		If prefix'="" kill ..namespaces(prefix)
		Set namespace=$order(..removeNamespaces(namespace))
	}
	Kill ..removeNamespaces
}

/// Get SOAP, Schema and Schema instance prefixes
Method GetXMLPrefixes(Output soapPrefix As %String, Output schemaPrefix As %String, Output xsiPrefix As %String, Output xsiAttrs As %String) [ Internal ]
{
	Set soapPrefix=..GetPrefix($$$SOAP12ENCns)
	If soapPrefix="" Set soapPrefix=$order(..addedNamespaces($$$SOAP12ENCns,""))
	If soapPrefix="" Set soapPrefix=..GetPrefix($$$SOAPENCns)
	If soapPrefix="" Set soapPrefix=$order(..addedNamespaces($$$SOAPENCns,""))
	If soapPrefix'="" Set soapPrefix=soapPrefix_":"

	Set schemaPrefix=..GetPrefix($$$XSDns)
	If schemaPrefix="" Set schemaPrefix=$order(..addedNamespaces($$$XSDns,""))
	If schemaPrefix'="" Set schemaPrefix=schemaPrefix_":"
  
	Set xsiPrefix=..GetPrefix($$$XSIns)
	If xsiPrefix'="" {
		Set xsiAttrs=""
	} Else {
		Set xsiPrefix=..GetNewPrefix("xsi")
		If $data(..addedNamespaces($$$XSIns)) {
			Set xsiAttrs=""
		} Else {
			Set xsiAttrs=" xmlns:"_xsiPrefix_"="""_$$$XSIns_""""
		}
	}
	Set xsiPrefix=xsiPrefix_":"
}

/// Add a namespace definition to the current level.
/// <method>PopNode</method> will remove this definition.
/// The next <method>PushNode...</method> will cause the attributes
/// to be created for adding this namespace to the XML document.<br><br>
/// 
/// <var>prefix</var> is the optional preferred prefix for this namespace.
/// If no prefix is specified, a unique prefix will be computed.<br><br>
/// 
/// A <var>schemaLocation</var> attribute value for the first definition
/// of this namespace may also specified.<br><br>
/// 
/// If <var>allowMultiplePrefixes</var> is true then multiple prefixes may be defined for the same namespace.
/// The default is false which will override the previously defined prefix for the same namespace.
Method AddNamespace(namespace As %String, prefix As %String, schemaLocation As %String = "", allowMultiplePrefixes As %Boolean = 0) As %Status
{
	If '$data(prefix) {
		If $data(..DefaultPrefix(namespace)) {
			Set prefix=..DefaultPrefix(namespace)
		} Else {
			If $get(..prefixes(namespace))'="" Quit $$$OK
			If 'allowMultiplePrefixes,$order(..addedNamespaces(namespace,""))'="" Quit $$$OK
			Set prefix=$get(prefix)
		}
	}

	If (prefix'="") && ($extract(prefix,*)=":") {
		Set $extract(prefix,$length(prefix))=""
	}
	Set prefix=$select(prefix="":$c(0),1:prefix)
	If $data(..addedNamespaces(namespace,prefix)) {
		If schemaLocation'="" {
			Set ..addedNamespaces(namespace,prefix)=schemaLocation
		}
	} Else {
		If 'allowMultiplePrefixes Kill ..addedNamespaces(namespace)
		Set ..addedNamespaces(namespace,prefix)=schemaLocation
	}
	If schemaLocation'="",$get(..prefixes($$$XSIns))="",'$data(..addedNamespaces($$$XSIns)) {
		Do ..AddInstanceNamespace()
	}
	Quit $$$OK
}

Method GetNamespacePrefix(namespace As %String, ByRef attrs) As %String
{
	Set attrs=""
	If namespace="" Set namespace=..DefaultNamespace
	if namespace="" Quit ""

	Set prefix=..GetPrefix(namespace)
	If prefix="" {
		Set prefix=..GetNewPrefix("",1)
		Set attrs=" xmlns:"_prefix_"="""_namespace_""""
	}

	Quit prefix_":"
}

/// Make prefix definition for all newly added namespaces.  
Method DefineAllNamespacePrefixes(prefixRequired As %Boolean = 1)
{
	Set nsName=$order(..addedNamespaces(""))
	While nsName'="" {
		Set prefix=$order(..addedNamespaces(nsName,""))
		While prefix'="" {
			Do ..DefineNamespacePrefix(nsName,prefixRequired,prefix)
			Set prefix=$order(..addedNamespaces(nsName,prefix))
		}
		Set nsName=$order(..addedNamespaces(nsName))
	}

	Quit
}

/// Make prefix definition for a new namespace at the current level. 
/// Optionally force the prefix to be used by specifying 3rd argument. 
Method DefineNamespacePrefix(namespace As %String, prefixRequired As %Boolean = 1, prefix As %String)
{
	If $get(prefix)="" {
		Set addedPrefix=$order(..addedNamespaces(namespace,""))
		If addedPrefix="" {
			Set prefix=""
			Set addedPrefix=$c(0)
		} Else {
			Set prefix=$select(addedPrefix=$c(0):"",1:addedPrefix)
		}
	} Else {
		Set addedPrefix=prefix
		If prefix=$c(0) Set prefix=""
	}
	Set schemaLocation=$get(..addedNamespaces(namespace,addedPrefix))
	If prefix="" {
		if prefixRequired Set prefix=..GetNewPrefix("")
	} Else {
		If $data(..namespaces(prefix)) Kill ..prefixes(..namespaces(prefix))
	}
	Set ..prefixes(namespace)=prefix
	If prefix'="" Set ..namespaces(prefix)=namespace
	If (schemaLocation'="") && '$data(..locations(namespace)) {
		Set ..locations(namespace)=schemaLocation
	}
	If addedPrefix'="" Kill ..addedNamespaces(namespace,addedPrefix)

	Quit
}

/// Remove the prefix definition for an existing namespace at the current level.  
Method RemoveNamespacePrefix(namespace As %String) [ Internal ]
{
	Set ..removeNamespaces(namespace)=""
}

/// Add a the XML Schema instance namespace definition to the current level.
/// <method>PopNode</method> will remove this definition.
/// The next <method>PushNode...</method> will cause the attributes
/// to be created for adding this namespace to the XML document.<br>
/// 
/// <var>prefix</var> is the optional preferred prefix for this namespace.
/// If no prefix is specified, a unique prefix will be computed.
Method AddInstanceNamespace(prefix As %String) As %Status
{
	If $get(prefix)'="" {
		If $extract(prefix,*)=":" {
			Set $extract(prefix,$length(prefix))=""
		}
	} Else {
		If $data(..addedNamespaces($$$XSIns)) Quit $$$OK
		Set prefix="xsi"
	}
	Quit ..AddNamespace($$$XSIns,prefix)
}

/// Add a the XML Schema namespace definition to the current level.
/// <method>PopNode</method> will remove this definition.
/// The next <method>PushNode...</method> will cause the attributes
/// to be created for adding this namespace to the XML document.<br>
/// 
/// <var>prefix</var> is the optional preferred prefix for this namespace.
/// If no prefix is specified, a unique prefix will be computed.
Method AddSchemaNamespace(prefix As %String) As %Status
{
	If $get(prefix)'="" {
		If $extract(prefix,*)=":" {
			Set $extract(prefix,$length(prefix))=""
		}
	} Else {
		If $data(..addedNamespaces($$$XSDns)) Quit $$$OK
		Set prefix="s"
	}
	Quit ..AddNamespace($$$XSDns,prefix)
}

/// Add the SOAP 1.1 encoding namespace, the XML schema namespace and the 
/// XML Schema instance namespace definitions to the current level.
/// <method>PopNode</method> will remove these definitions.
/// The next <method>PushNode...</method> will cause the attributes
/// to be created for adding these namespaces to the XML document.<br>
/// 
/// <var>soapPrefix</var>, <var>schemaPrefixPrefix</var> and <var>xsiPrefix</var>
/// are the optional preferred prefix for these namespaces.
/// If no prefix is specified, a unique prefix will be computed.
Method AddSOAPNamespace(soapPrefix As %String, schemaPrefix As %String, xsiPrefix As %String) As %Status
{
	If $get(soapPrefix)'="" {
		If $extract(soapPrefix,*)=":" {
			Set $extract(soapPrefix,$length(soapPrefix))=""
		}
	} Else {
		If $data(..addedNamespaces($$$SOAPENCns)) Quit $$$OK
		Set soapPrefix="SOAP-ENC"
	}
	Do ..AddNamespace($$$SOAPENCns,soapPrefix)
	Do ..AddSchemaNamespace(.schemaPrefix)
	Quit ..AddInstanceNamespace(.xsiPrefix)
}

/// Add the SOAP 1.2 encoding namespace, the XML schema namespace and the 
/// XML Schema instance namespace definitions to the current level.
/// <method>PopNode</method> will remove these definitions.
/// The next <method>PushNode...</method> will cause the attributes
/// to be created for adding these namespaces to the XML document.<br>
/// 
/// <var>soapPrefix</var>, <var>schemaPrefixPrefix</var> and <var>xsiPrefix</var>
/// are the optional preferred prefix for these namespaces.
/// If no prefix is specified, a unique prefix will be computed.
Method AddSOAP12Namespace(soapPrefix As %String, schemaPrefix As %String, xsiPrefix As %String) As %Status
{
	If $get(soapPrefix)'="" {
		If $extract(soapPrefix,*)=":" {
			Set $extract(soapPrefix,$length(soapPrefix))=""
		}
	} Else {
		If $data(..addedNamespaces($$$SOAP12ENCns)) Quit $$$OK
		Set soapPrefix="SOAP-ENC"
	}
	Do ..AddNamespace($$$SOAP12ENCns,soapPrefix)
	Do ..AddSchemaNamespace(.schemaPrefix)
	Quit ..AddInstanceNamespace(.xsiPrefix)
}

/// Get a new unique prefix.
Method GetNewPrefix(prefix As %String, bTemp As %Boolean = 0) As %String
{
	While (prefix="") || ($get(..namespaces(prefix))'="") {
		Set max=..maxPrefix+1
		If 'bTemp Set ..maxPrefix=max
		Set prefix="s"_$select(max<10:"0",1:"")_max
	}
	Quit prefix
}

/// Get the prefix for the specified namespace at the current stack level.
/// "" is returned if the namespace is not defined.
Method GetPrefix(namespace As %String) As %String [ CodeMode = expression ]
{
$get(..prefixes(namespace))
}

/// Get the next namespace
Method GetNextDefinedNamespace(namespace As %String) As %String [ CodeMode = expression ]
{
$order(..prefixes(namespace))
}

/// Get the namespace for the specified prefix at the current stack level.
/// "" is returned if the prefix is not defined.
Method GetNamespace(prefix As %String) As %String [ CodeMode = expression ]
{
$get(..namespaces(prefix))
}

/// Fill myself from the specified instance
Method Copy(source As %XML.Namespaces) [ Internal ]
{
	Set ..DefaultNamespace=source.DefaultNamespace
	Set ..ElementQualified=source.ElementQualified
	Set ..AttributeQualified=source.AttributeQualified
	Set ..OutputTypeAttribute=source.OutputTypeAttribute
	Set ..CurrentNamespace=source.CurrentNamespace
	Set ..DefaultDefined=source.DefaultDefined
	Set ..SuppressXmlns=source.SuppressXmlns
	Set ..DefaultXmlns=source.DefaultXmlns
	Set ..CurrentElementQualified=source.CurrentElementQualified
	Set ..depth=source.depth
	Kill ..namespaces,..prefixes,..addedNamespaces,..DefaultPrefix
	Merge ..namespaces=source.namespaces
	Merge ..prefixes=source.prefixes
	Merge ..addedNamespaces=source.addedNamespaces
	Merge ..DefaultPrefix=source.DefaultPrefix
	Set ..stack=source.stack
	Set ..maxPrefix=source.maxPrefix
	Set ..Stable=source.Stable
}

/// Reset myself
Method Reset()
{
	Set ..DefaultNamespace=""
	Set ..ElementQualified=0
	Set ..AttributeQualified=0
	Set ..CurrentNamespace=""
	Set ..SuppressXmlns=0
	Set ..DefaultXmlns=""
	Set ..DefaultDefined=""
	Set ..CurrentElementQualified=""
	Set ..depth=0
	Kill ..namespaces,..prefixes,..addedNamespaces,..DefaultPrefix
	Set ..stack=""
	Set ..maxPrefix=0
	Set ..Stable=0
}

/// GetNextNamespace returns the next XML namespace in name order.  
/// A return of "", indicates no more XML namespaces to list.
ClassMethod GetNextNamespace(namespace As %String) As %String [ CodeMode = expression ]
{
$order(^oddXML("-ns",$select(namespace="":"-",1:namespace)))
}

/// GetNextClass returns the next class in the XML namespace in class name order.  
/// A return of "", indicates no more classes to list.  
/// Note that namespace="" indicates classes without an XML namespace defined.
ClassMethod GetNextClass(namespace As %String, class As %String) As %String [ CodeMode = expression ]
{
$order(^oddXML("-ns",$select(namespace="":"-",1:namespace),class))
}

}
