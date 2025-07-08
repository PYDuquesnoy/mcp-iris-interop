/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// Run-time and compile-time utility methods for Quality Measures.
/// This class should be consider to be INTERNAL to DeepSee;
/// There are no methods intended for public use.
Class %DeepSee.QualityMeasure.Utils Extends %RegisteredObject [ System = 4 ]
{

/// Build the meta data for the given quality measure.
ClassMethod %ProcessQualityMeasure(pQMSRDef As %DeepSee.Model.QualityMeasure.qualityMeasure, Output pInfo) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given the logical name, <var>pQMSRName</var> of a DeepSee Quality Measure,
/// test if it exists.
ClassMethod %QualityMeasureExists(pQMSRName As %String, Output pStatus As %Status) As %Boolean
{
	If (pQMSRName="") Quit 0
	Set tClassName = ..%GetQualityMeasureClass(pQMSRName,.pStatus)
	Quit (tClassName'="")
}

/// Given the logical name, <var>pQMSRName</var> of a DeepSee Quality Measure,
/// return its name in its original case.
ClassMethod %GetQualityMeasureName(pQMSRName As %String, Output pStatus As %Status) As %String
{
	Set tName = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetQualityMeasureClass(pQMSRName,.pStatus)
		If $$$ISOK(pStatus) {
			Set tName = $classmethod(tClassName,"%GetQualityMeasureName")
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tName
}

/// Given the logical name, <var>pQMSRName</var> of a DeepSee Quality Measure,
/// return a list of the groups and elements it contains.
ClassMethod %GetQualityElements(pQMSRName As %String, Output pList As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set tClassName = ..%GetQualityMeasureClass(pQMSRName,.tSC,1)
		If $$$ISOK(tSC) {
			Do $classmethod(tClassName,"%GetGroupsAndElements",.pList)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given the logical name, <var>pQMSRName</var> of a DeepSee Quality Measure,
/// return its MDX expression.
ClassMethod %GetQualityMeasureExpression(pQMSRName As %String, Output pStatus As %Status) As %String
{
	Set tMDX = ""
	Set pStatus = $$$OK
	Try {
		Set tName = ..%ParseQualityMeasureName(pQMSRName,.tGroup,.tElement)
		Set tClassName = ..%GetQualityMeasureClass(tName,.pStatus,1)
		If $$$ISOK(pStatus) {
			Set tMDX = $classmethod(tClassName,"%GetExpression",tGroup,tElement)
		}
	}
	Catch(ex) {
		Set pStatus = ex.AsStatus()
	}

	Quit tMDX
}

/// Given the logical name, <var>pQMSRName</var> of a DeepSee Quality Measure,
/// return the class name of the quality measure definition.</br>
/// If <var>pUseLink</var> is true, then return the resolved master class name for a linked measure.
ClassMethod %GetQualityMeasureClass(pQMSRName As %String, Output pStatus As %Status, pUseLink As %Boolean = 0, ByRef pVisited) As %String
{
	Set tClassName = ""
	Set pStatus = $$$OK
	Try {
		If ((pQMSRName'="")&&$D(pVisited(pQMSRName))) {
			Set pStatus = $$$ERROR($$$GeneralError,"Quality measure with circular linkTo: " _ pQMSRName)
			Quit
		}
		
		Set tName = ..%ParseQualityMeasureName(pQMSRName,.tGroup,.tElement)

		// No privilege is same as does not exist
		If ((tName'="")&&($G($$$DeepSeeQMsrGLVN("qmsrNames",$$$UPPER(tName)))'="")&&..%CheckPrivilege(tName)) {
			Set tClassName = $$$DeepSeeQMsrGLVN("qmsrNames",$$$UPPER(tName))
		}
		Else {
			Set pStatus = $$$ERROR($$$GeneralError,"Cannot find quality measure: '" _ tName _ "'")
		}

		If (pUseLink && (tClassName'="")) {
			// follow link, if present
			Set tLinkTo = $classmethod(tClassName,"%GetQualityMeasureLinkedTo")
			If (tLinkTo'="") {
				Set pVisited(pQMSRName) = ""
				Set tClassName = ..%GetQualityMeasureClass(tLinkTo,.pStatus,1,.pVisited)
			}
		}
	}
	Catch(ex) {
		Set tClassName = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tClassName
}

/// Given the logical full name, <var>pQMSRName</var> of a DeepSee Quality Measure,
/// return the quality measure name as well as the optional group and element names.
/// A full name takes the form: "catalog/set/id/group/element".
ClassMethod %ParseQualityMeasureName(pQMSRName As %String, Output pGroup As %String, Output pElement As %String) As %String
{
	Set pGroup = $P(pQMSRName,"/",4)
	Set pElement = $P(pQMSRName,"/",5)
	Quit $P(pQMSRName,"/",1,3)
}

/// Test that the current user holds privileges on the given quality measure.
ClassMethod %CheckPrivilege(pQMSRName As %String) As %Boolean [ Final ]
{
	Quit 1
}

/// Given the logical name, <var>pQMSRName</var> of a DeepSee quality measure,
/// return an instance of the <class>%DeepSee.Model.QualityMeasure.qualityMeasure</class>
/// meta-data object that describes the quality measure.<br/>
/// Return "" if the given quality measure does not exist.<br/>
ClassMethod %GetModel(pQMSRName As %String, Output pStatus As %Status, pUseLink As %Boolean = 0) As %DeepSee.Model.QualityMeasure.qualityMeasure
{
	Set tQMSR = ""
	Set pStatus = $$$OK
	Try {
		Set tClassName = ..%GetQualityMeasureClass(pQMSRName,.pStatus)
		Set tMasterClass = ""
		If ($$$ISOK(pStatus)&&pUseLink) {
			// get info on master measure
			Set tMasterClass = ..%GetQualityMeasureClass(pQMSRName,.pStatus,pUseLink,.tVisited)
			If (tMasterClass=tClassName) {
				Set tMasterClass = ""
			}
		}

		If $$$ISOK(pStatus) {
			// GetModel only works for *compiled* quality measures!
			If ($System.OBJ.IsUpToDate(tClassName)) {
				If $classmethod(tClassName,"%IsA","%DeepSee.QualityMeasure.QualityMeasure") {
					Set tQMSR = $classmethod(tClassName,"%GetModel")
				}
				Else {
					Set pStatus = $$$ERROR($$$GeneralError,"Class is not a quality measure definition")
					Quit
				}
				
				// merge in master class model, if present and asked for
				Set tMasterQMSR = ""
				If (tMasterClass'="") {
					If ($System.OBJ.IsUpToDate(tMasterClass)) {
						If $classmethod(tMasterClass,"%IsA","%DeepSee.QualityMeasure.QualityMeasure") {
							Set tMasterQMSR = $classmethod(tMasterClass,"%GetModel")
						}
						Else {
							Set pStatus = $$$ERROR($$$GeneralError,"Master class is not a quality measure definition")
							Quit
						}
					}
				}

				If $IsObject(tMasterQMSR) {
					Set tMasterQMSR.catalog = tQMSR.catalog
					Set tMasterQMSR.set = tQMSR.set
					Set tMasterQMSR.id = tQMSR.id
					Set tMasterQMSR.caption = tQMSR.caption
					Set tMasterQMSR.description = tQMSR.description
					Set tMasterQMSR.linkedTo = tQMSR.linkedTo
					Set tMasterQMSR.published = tQMSR.published
					Set tMasterQMSR.subjectArea = tQMSR.subjectArea
					Set tQMSR = tMasterQMSR
				}
			}
			Else {
				// get model from XData directly
				Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName)
				#; find the XDATA block named QualityMeasure
				Set tIndex = tClassDefinition.XDatas.FindObjectId(tClassName_"||QualityMeasure")
				If tIndex'="" {
					#; get XDATA as stream
					Set tStream = tClassDefinition.XDatas.GetAt(tIndex).Data
					Do tStream.Rewind()

					If (tStream.Size > 0) {
						#; render the stream into a meta-data object (with children)
						Set tReader = ##class(%XML.Reader).%New()

						Set pStatus = tReader.OpenStream(tStream)
						If $$$ISERR(pStatus) Quit

						Do tReader.Correlate("qualityMeasure","%DeepSee.Model.QualityMeasure.qualityMeasure")

						#; there should only be one item defined
						Do tReader.Next(.tQMSR,.tSC)
						If $$$ISERR(tSC) Quit
						If '$IsObject(tQMSR) {
							Set pStatus = $$$ERROR($$$GeneralError,"No <qualityMeasure> element defined in QualityMeasure block.")
							Quit
						}
					}
				}
				If (tQMSR = "") {
					Set pStatus = $$$ERROR($$$GeneralError,"Class does not contain a quality measure definition")
					Quit
				}
			}
		}
		If $IsObject(tQMSR) Set tQMSR.Timestamp = $ZDT($$$defClassKeyGet(tClassName,$$$cCLASStimechanged),3,,6)
	}
	Catch(ex) {
		Set tQMSR = ""
		Set pStatus = ex.AsStatus()
	}
	Quit tQMSR
}

/// Get a list of currently defined (and published) quality measures for a specific cube. This is returned as:<br/>
/// pList(NAME) = $LB(name,caption,description)<br/>
ClassMethod %GetQualityMeasuresForCube(Output pList As %List, pCube As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		If (pCube="") Quit
		Set tCubeList($$$UPPER(pCube)) = ""
		Set tBaseCube = ##class(%DeepSee.Utils).%GetBaseCube(pCube)
		If ((tBaseCube'="")&&($$$UPPER(tBaseCube)'=$$$UPPER(pCube))) {
			Set tCubeList($$$UPPER(tBaseCube)) = ""
		}

		Set tCube = $O(tCubeList(""))
		While (tCube'="") {
			Set tQMsr = $O($$$DeepSeeQMsrGLVN("cubes",tCube,""))
			While (tQMsr'="") {
				Set tClass = $G($$$DeepSeeQMsrGLVN("qmsrNames",tQMsr))
				If $classmethod(tClass,"%IsPublished") {
					Set tName = $G($$$DeepSeeQMsrGLVN("qmsrClasses",tClass))
					Set tCaption = $classmethod(tClass,"%GetQualityMeasureCaption")
					Set tDesc = $classmethod(tClass,"%GetQualityMeasureDescription")
					Set pList(tQMsr) = $LB(tName,tCaption,tDesc)
				}
				Set tQMsr = $O($$$DeepSeeQMsrGLVN("cubes",tCube,tQMsr))
			}
			Set tCube = $O(tCubeList(tCube))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get a list of currently defined quality measures. This is returned as:<br/>
/// pList(NAME) = $LB(name,caption,moddate,type,msrCaption)<br/>
ClassMethod %GetQualityMeasureList(Output pList As %List, pCatalog As %String = "", pSet As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// find all subclasses of QualityMeasure
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%DeepSee.QualityMeasure.QualityMeasure")
		If $$$ISERR(tSC) Quit
		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tName = $G(tRS.Data("Name"))

			// make sure class is compiled and non-abstract
			If $$$comClassDefined(tName) {
				Set tAbstract = +$$$comClassKeyGet(tName,$$$cCLASSabstract)
				If (('tAbstract)) {
					Set tClasses(tName) = $$$comClassKeyGet(tName,$$$cCLASStimechanged)
				}
			}
		}

		Set k = $O(tClasses(""))
		While (k'="") {
			Set tSkip = 0
			If ('tSkip && (pCatalog'="")) {
				If ($$$UPPER(pCatalog)'=$$$UPPER($classmethod(k,"%GetQualityMeasureCatalog"))) {
					Set tSkip = 1
				}
			}
			If ('tSkip && (pSet'="")) {
				If ($$$UPPER(pSet)'=$$$UPPER($classmethod(k,"%GetQualityMeasureSet"))) {
					Set tSkip = 1
				}
			}
			If ('tSkip) {
				Set tName = $classmethod(k,"%GetQualityMeasureName")
				Set tCaption = $P(tName,"/",3)	// caption in finder
				Set tModDate = tClasses(k)
				Set tMsrCaption = $classmethod(k,"%GetQualityMeasureCaption")
				Set pList($I(n)) = $LB(tName,tCaption,tModDate,"qmsr",tMsrCaption)
			}
			Set k = $O(tClasses(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all currently defined DeepSee Quality Measures
/// in a format that can be used by a finderDialog.
ClassMethod %GetQualityMeasureArray(ByRef pParameters, Output pMetaData, Output %pData) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// These are the names of the returned properties
		Set pMetaData = $LB("name","value","type","date","caption")

		Set tSC = ..%GetQualityMeasureList(.tList)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%DeepSee.Utils).%BuildItemListArray(.tList, .pMetaData, .%pData,.pParameters)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Utility method to create and save a qmsr definition class.
ClassMethod %SaveQMsrDefinition(pClassName As %String, pSuper As %String = "", pDesc As %String, pModel As %DeepSee.Model.cube, pDomain As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// open the class definition
		If (##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)) {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
			#; delete the old XDATA block named QualityMeasure
			Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||QualityMeasure")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)

			#; delete the old DOMAIN parameter
			Set tIndex = tClassDefinition.Parameters.FindObjectId(pClassName_"||DOMAIN")
			If tIndex'="" Do tClassDefinition.Parameters.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.ProcedureBlock = 1
		}

		Set:pDesc="" pDesc = pModel.caption_$C(10)_"Saved on "_$ZDT($H,3)
		Set tClassDefinition.Super = $S(pSuper="":"%DeepSee.QualityMeasure.QualityMeasure",1:pSuper)
		Set tClassDefinition.Description = $Replace(pDesc,$C(10),$C(13,10))

		// Add dependency on source class to cube class !!!
		// Set tClassDefinition.DependsOn = pModel.sourceClass

		// sequence number controls the order in which class members are displayed
		Set tSeqNo = 0

		#; DOMAIN param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(pClassName_":"_"DOMAIN")
		Set tParmDef.Default = pDomain
		Do tClassDefinition.Parameters.Insert(tParmDef)

		// create XData block to hold the model
		Set tCubeXData = ##class(%Dictionary.XDataDefinition).%New()
	
		Set tCubeXData.SequenceNumber = $I(tSeqNo)
		Set tCubeXData.Description = "Quality Measure Definition."
		Set tCubeXData.XMLNamespace = "http://www.intersystems.com/qualityMeasure"

		Set tCubeXData.Name = "QualityMeasure"
		Set tCubeXData.parent = tClassDefinition
		
		// use XML writer to format output
		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.Indent = 1
		Set tSC = tWriter.OutputToString()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.StartDocument()
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.RootObject(pModel)
		If $$$ISERR(tSC) Quit
		Set tSC = tWriter.EndDocument()
		If $$$ISERR(tSC) Quit

		Set tString = tWriter.GetXMLString()

		// contents of xdata block is the xml for the model
		Set tSC = tCubeXData.Data.Write(tString)
		If $$$ISERR(tSC) Quit

		// save the cube class
		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit

		// compile
		Set tSC = $System.OBJ.Compile(pClassName,"-d")
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get a list of currently defined quality measure catalogs. This is returned as:<br/>
/// pList(NAME) = $LB(name)<br/>
ClassMethod %GetCatalogList(Output pList As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set tSC = ..%GetQualityMeasureList(.tList)
		If $$$ISERR(tSC) Quit

		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $LG(tList(k),1)
			Set tCat = $P(tName,"/",1)
			If (tCat'="") {
				Set pList($$$UPPER(tCat)) = $LB(tCat)
			}
			Set k = $O(tList(k))
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get a list of currently defined quality measure sets. This is returned as:<br/>
/// pList(NAME) = $LB(name)<br/>
ClassMethod %GetSetList(Output pList As %List, pCatalog As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set tSC = ..%GetQualityMeasureList(.tList,pCatalog)
		If $$$ISERR(tSC) Quit

		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $LG(tList(k),1)
			Set tSet = $P(tName,"/",2)
			If (tSet'="") {
				Set pList($$$UPPER(tSet)) = $LB(tSet)
			}
			Set k = $O(tList(k))
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
