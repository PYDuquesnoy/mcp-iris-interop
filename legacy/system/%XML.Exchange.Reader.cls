/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %XML.Exchange

/// Configuration Management XML Reader
/// 
/// This class is used while importing Configuration Items.  
/// Do not use this class directly.
Class %XML.Exchange.Reader Extends %XML.Reader [ System = 4 ]
{

/// The filename used as an XML source. 
Property Filename As %String;

/// ResolveElement() returns the class name corresponding to an element name
/// within the current XMLReader context.
Method ResolveElement(element As %String, defaultNamespace As %String) As %String [ Internal ]
{
	If element="" Quit ""
	If '$Data(i%CorrelationTable) {
		#; %XML.Exchange.Metadata is used to include details relating to the element.
		If element="Information" Quit "%XML.Exchange.Metadata"
		If ##class(%Dictionary.CompiledClass).%ExistsId(element) {
			#; Check the class is both XMLENABLED and GUIDENABLED.
			#; These are turned on by %XML.Exchange.Adaptor.
			If $$$comMemberKeyGet(element,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault),$$$comMemberKeyGet(element,$$$cCLASSparameter,"GUIDENABLED",$$$cPARAMdefault) Quit element
		}
	} Else {
		Quit ##super(element, defaultNamespace)
	}
	Quit ""
}

/// Get and return the next object.<p>
/// <method>Next</method> returns 1 (true), if the next object matching one of the Correlate criteria 
/// is found and successfully imported.<br>
/// <method>Next</method> returns 0 (false) and a %Status of $$$OK in sc
/// after all objects have been imported.<br>
/// <method>Next</method> returns 0 (false) and an error %Status in sc, 
/// if an error has occurred importing this object.<p>
/// The <var>namespace</var> argument indicates the default namespace 
/// for this XML file.
Method Next(ByRef oref As %ObjectHandle, ByRef sc As %Status, namespace As %String = "", ByRef qstruct As %String) As %Integer
{
	#Define IsGUID(%val) %val?8(1N,1"A",1"B",1"C",1"D",1"E",1"F")1"-"4(1N,1"A",1"B",1"C",1"D",1"E",1"F")1"-"4(1N,1"A",1"B",1"C",1"D",1"E",1"F")1"-"4(1N,1"A",1"B",1"C",1"D",1"E",1"F")1"-"12(1N,1"A",1"B",1"C",1"D",1"E",1"F")

	#; Errors will be returned via the status.  Do not count errors that are not returned.
	#; During the oref.XMLImport call the error count would be incremented without returning any errors.
	New %ISCCountErrors
	
	Set sc=$$$OK
	If i%Document="" Quit 0
	If i%Node="" Quit 0
	Set tree = i%Document.DocumentId
	Set oref = ""
	Set found = 0
	
	#; Get qualifiers
	Set loadguids=$$$qualifierGetValue(qstruct,"loadguids")
	Set update=$$$qualifierGetValue(qstruct,"update")
	
	While i%ParentNodeId '= "" {
		If '..NodeIsCurrent {
			If $$$xmlaIsTop(tree,i%ParentNodeId) Quit
			Set pcl=i%ParentChildlist
			$$$xmlaNextChild(tree,i%ParentNodeId,pcl,i%Node,descriptor)
			Set i%ParentChildlist=pcl
			Set i%Descriptor=descriptor
		}
		While i%Node '= "" {
			Set ..NodeIsCurrent=0
			If $$$xmlaGetNodeType(tree,i%Descriptor)=$$$xmlELEMENTNODE {
				$$$xmlaGetChildListFromDescriptor(tree,i%Descriptor,i%Childlist)
				Set element = $$$xmlaGetLocalName(tree,i%Childlist)
				Set type = $get(i%CorrelationTable($c(0)))
				If type = "" Set type = ..ResolveElement(element,namespace)
				If type '= "" {
					Set oref=$get(i%Idlist(i%Node))
					If oref="" {
						If loadguids {
							If $zobjclassmethod(type,"%GetParameter","GUIDENABLED") {
								Set oref=$zobjclassmethod(type,"XMLLoadGUID",..Document,i%Node)
								If oref'="" {
									Set i%Idlist(i%Node)=oref
								}
							}
						} Else {
							$$$XMLTimerNewMark
							Set oref=$zobjclassmethod(type,"XMLNew",i%Document,i%Node)
							$$$XMLTimerRecord("XMLNew")
							If oref'="" {
								#; Do not clear the existing properties if the update qualifier is used.
								If 'update, oref.%Extends("%Library.Persistent"), oref.%Id()'="" {
									#; Prepare object for population.
									Do oref.XMLClear()
								}
								#; GUID reference checks.
								#; Ideally this check would be done during XMLImport for properties that are exported as GUIDs.
								#; To avoid overriding the entire method we parse for GUIDs prior to the call to XMLImport.
								Set ref = ""
								For  {
									Set ref = $order(@tree@(ref))
									If ref = "" Quit
									
									#; References to another object using a GUID are in character data.
									Set data=$order(@tree@(ref,"c",""))
									If data'="",$order(@tree@(ref,"c",data))="",$listget($get(@tree@(data,0)),1)'="e" {
										Set data=@tree@(data)
										#; Check whether or not this field uses a GUID.
										#; If it's a GUID that has not already been processed, check if it exists for this system.
										If $$$IsGUID(data), '$d(handled(data)) {
											#; Does the GUID match an existing object.
											Set oid = ##class(%Library.GUID).%GUIDFind(data)
											#; GUIDs are not removed when an object is deleted.
											#; When there is an oid confirm the object still exists.
											If oid '= "" {
												Set exists = $ClassMethod($$$oidClassName(oid),"%Exists",oid)
											} Else {
												Set exists = 0
											}
											Set handled(data) = exists
											If 'exists {
												$$$xmlSubMemberSet("file",..Filename,"unknown",data)
											}
										}
									}
								}
								Merge idlist=i%Idlist
								$$$XMLTimerNewMark
								Set sc=$$$ADDSC(sc, oref.XMLImport(element,i%OpenFormat,namespace,..Document,i%Node,.idlist))
								$$$XMLTimerRecord("XMLImport")
								Merge i%Idlist=idlist
							}
						}
						Set found = 1
						Quit
					}
				}
				If $$$xmlaHasChildNodes(tree,i%Childlist) {
					Set i%ParentNodeId = i%Node
					Set i%ParentChildlist = i%Childlist
					Set i%Node = ""
				}
			}
			If $$$xmlaIsTop(tree,i%ParentNodeId) Quit
			Set pcl=i%ParentChildlist
			If i%Node="" {
				$$$xmlaFirstChild(tree,i%ParentNodeId,pcl,i%Node,descriptor)
			} Else {
				$$$xmlaNextChild(tree,i%ParentNodeId,pcl,i%Node,descriptor)
			}
			Set i%ParentChildlist=pcl
			Set i%Descriptor=descriptor
		}
		If found Quit
		Set i%Node = i%ParentNodeId
		Set i%Childlist=i%ParentChildlist
		Set i%Descriptor=i%ParentDescriptor
		Set i%ParentNodeId = $$$xmlaParentNode(tree,i%Node)
		If $$$xmlaIsTop(tree,i%ParentNodeId) {
			Set i%ParentNodeId=""
		} Else {
			$$$xmlaGetChildList(tree,i%ParentNodeId,i%ParentChildlist,i%ParentDescriptor)
		}
	}
	If $$$ISOK(sc) && found Quit 1
	Set i%Node = ""
	Quit 0
}

/// Import XML source from a file using %XML.Document.
Method OpenFile(xmlsource As %String, format As %String) As %Status
{
	Set ..Filename = xmlsource
	Quit ..Open(xmlsource,"ParseFile",.format)
}

}
