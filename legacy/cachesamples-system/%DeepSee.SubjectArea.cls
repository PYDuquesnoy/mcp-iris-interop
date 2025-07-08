/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// This class is used to define DeepSee Subject Areas.<br/>
/// Each subclass of this class defines an
/// active Subject Area. A Subject Area is analogous to an
/// SQL view; it is based on an actual DeepSee Cube data model 
/// and can serve as the target of queries as if it were an
/// actual cube model.<br/>
/// A Subject Area cannot define additional dimensions or measures
/// but it can define:<br/>
/// <ul>
/// <li>What dimensions and measures can be used in queries.</li>
/// <li>What permissions are needed to query a cube</li>
/// <li>How the data within a cube should be filtered.</li>
/// <li>The default listing for this subject area.</li>
/// </ul>
Class %DeepSee.SubjectArea Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = (%DeepSee.Model.SubjectArea.subjectArea, %DeepSee.Generator), System = 4 ]
{

/// This projection is used to keep track of when Subject areas are
/// compiled or deleted.
Projection SubjectAreaProjection As %DeepSee.SubjectAreaProjection [ Internal ];

/// This XData definition defines the SubjectArea.
XData SubjectArea [ XMLNamespace = "http://www.intersystems.com/deepsee/subjectarea" ]
{
}

/// Process the model for this Subject Area and generate meta data.
ClassMethod %Generate() As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	Do %code.WriteLine(" Quit $$$OK")
	Set tSC = $$$OK
	Try {
		// DTB949 - The previous Subject Area and Base Cube name (if they exist) are kept 
		// in case the compile fails and information needs to be recorded
		Set tOldCubeName = $G(^||%Cls(%compiledclass.Name,"cube"))
		Set tOldBaseCube = $G(^||%Cls(%compiledclass.Name,"baseCube"))

		Kill ^||%Cls(%compiledclass.Name)
		Set:(tOldCubeName'="") ^||%Cls(%compiledclass.Name,"oldCubeName") = tOldCubeName		// DTB949
		Set:(tOldBaseCube'="") ^||%Cls(%compiledclass.Name,"oldBaseCube") = tOldBaseCube		// DTB949
		If (%class.Abstract || (%class.Name = "%DeepSee.SubjectArea")) {
			Quit
		}

		// JMD1348 prevent incremental compile
#ifdef cCLASSdisableincremental
	$$$comClassKeySet(%class.Name,$$$cCLASSdisableincremental,1)
#endif
		Set tDisplay=$$$qualifierGetValue(%qstruct,"displaylog")		// DTB466 - Track whether or not to display messages

		#; find XDATA block named SubjectArea
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||SubjectArea")

		If (tIndex '= "") {
			#; get XDATA as stream
			Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()

			If (tStream.Size > 0) {

				#; render the stream into cube meta-data object (with children)
				Set tReader = ##class(%XML.Reader).%New()

				Set tSC = tReader.OpenStream(tStream)
				If $$$ISERR(tSC) Quit

				Do tReader.Correlate("subjectArea","%DeepSee.Model.SubjectArea.subjectArea")

				#; there should only be one subject area defined
				Do tReader.Next(.tSubject,.tSC)
				If $$$ISERR(tSC) Quit
				If '$IsObject(tSubject) {
					Set tSC = $$$ERROR($$$GeneralError,"No <subjectArea> element defined in SubjectArea block.")
					Quit
				}

				#; is subject area disabled?
				If (tSubject.disabled) {
					Write !,$$$FormatText($$$Text("Subject Area '%1' is disabled","%DeepSee"),tSubject.name)
					Quit
				}

				#; is this cube name already used?
				Set tCubeName = tSubject.name
				Set tRegClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName)))
				If ((tRegClass'="") && (tRegClass '= %class.Name)) {
					Set tSC = $$$ERROR($$$GeneralError,"Cube or SubjectArea with given name already exists: " _ tCubeName)
					Quit
				}

				#; validate subject area
				Set tSC = tSubject.%Validate()
				If $$$ISERR(tSC) Quit

				Set tJoinList = ""
				Set tBaseCubeList = tSubject.baseCube
				
				// +DTB372 - Translate all base cubes to their currently active version
				For c=1:1:$L(tBaseCubeList,",") {
					Set tVersionBaseCube = $P(tBaseCubeList,",",c)
					Set tVersionedCubeName = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tVersionBaseCube)
					// Report versions of cubes being used
					If ($L(tBaseCubeList,",")>1)&&##class(%DeepSee.CubeVersion.Utils).%IsVersion(tVersionedCubeName) {
						Set tSC=$$$ERROR($$$GeneralError,"Compound cubes do not support versioned base cubes:"_tVersionedCubeName)
						$$$ThrowStatus(tSC)
					}
					Else {
						// Inform the caller that a versioned cube is the base cube
						Write:tDisplay !,$$$FormatText($$$Text("Subject area is based on versioned cube %1","%DeepSee"),tVersionedCubeName)		// DTB466 - Write is conditional on compiler flag
						Set $P(tBaseCubeList,",",c) = tVersionedCubeName
					}
				}
				// -DTB372
				
				
				#; base cube can contain a list of cube names!
				#; the first is the primary base; the rest are joined into the primary
				For p=1:1:$L(tBaseCubeList,",") {
					Set tBaseCube = $P(tBaseCubeList,",",p)
					Set tBaseClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tBaseCube)))
					If (tBaseClass = "") {
						Set tSC = $$$ERROR($$$GeneralError,"Base cube does not exist: " _ tBaseCube)
						Quit
					}
					If (p=1) {
						Set tPrimaryBaseCube = tBaseCube
						Set tPrimaryBaseClass = tBaseClass
					}
					Else {
						Set tJoinList = tBaseCubeList
					}
				}
				If $$$ISERR(tSC) Quit

				#; get cube name of subject area
				Set ^||%Cls(%compiledclass.Name,"cubeName") = tCubeName
				Set ^||%Cls(%compiledclass.Name,"baseCube") = $G(tPrimaryBaseCube)
				Set ^||%Cls(%compiledclass.Name,"baseClass") = $G(tPrimaryBaseClass)
				Set ^||%Cls(%compiledclass.Name,"cubeCaption") = tSubject.caption
				Set ^||%Cls(%compiledclass.Name,"countCaption") = tSubject.countMeasureCaption
				Set ^||%Cls(%compiledclass.Name,"countName") = tSubject.countMeasureName
				Set:tJoinList'="" ^||%Cls(%compiledclass.Name,"joinList") = tJoinList

				// reset so rest of logic will work
				Set tSubject.baseCube = $G(tPrimaryBaseCube)

				Set tSC = ##class(%DeepSee.Generator).%ProcessSubjectArea(%class.Name,tSubject,.tCaptions,tJoinList)
				If $$$ISERR(tSC) Quit

				Merge ^||%Cls(%compiledclass.Name,"captions") = tCaptions

				#; does this subjectArea support drill through
				Set tHasListing = ''$D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing"))
				Set ^||%Cls(%compiledclass.Name,"drillThrough") = tHasListing
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"No SubjectArea definition in subject area class: " _ %class.Name)
				Quit
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	// DTB949 - If there was an error, communicate it to the projection for recording in the metadata
	Set:$$$ISERR(tSC) ^||%Cls(%compiledclass.Name,"error") = tSC

	Quit tSC
}

/// Return the logical name of the MDX cube defined by this subject area.
ClassMethod %GetCubeName() As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"cubeName"))))
	Quit $$$OK
}

/// Return number of facts in the base cube's fact table.
ClassMethod %GetFactCount() As %Integer [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	// dispatch to base class
	Set tBaseClass = $G(^||%Cls(%compiledclass.Name,"baseClass"))
	If (tBaseClass '= "") {
		Do %code.WriteLine(" Quit ##class("_tBaseClass_").%GetFactCount()")
	}
	Else {
		Do %code.WriteLine(" Quit """"")
	}
	Quit $$$OK
}

/// Notification that a listing (drillthrough) query is about to be executed.<br/>
/// This is called immediately before a listing query is executed.
/// This is useful for cases where additional setup work is required before
/// a listing query can run.<br/>
/// <var>pSQL</var> is the listing query that will be executed.
ClassMethod %OnExecuteListing(pSQL As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	// default: dispatch to base class
	Set tBaseClass = $G(^||%Cls(%compiledclass.Name,"baseClass"))
	If (tBaseClass '= "") {
		Do %code.WriteLine(" Quit ##class("_tBaseClass_").%OnExecuteListing(pSQL)")
	}
	Else {
		Do %code.WriteLine(" Quit $$$OK")
	}
	Quit $$$OK
}

/// Return name of the fact class used by the base cube.
ClassMethod %GetFactClass() As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	// dispatch to base class
	Set tBaseClass = $G(^||%Cls(%compiledclass.Name,"baseClass"))
	If (tBaseClass '= "") {
		Do %code.WriteLine(" Quit ##class("_tBaseClass_").%GetFactClass()")
	}
	Else {
		Do %code.WriteLine(" Quit """"")
	}
	Quit $$$OK
}

/// Return the caption of the subject area defined by this class.
/// If not defined, the subject area name is returned.
ClassMethod %GetCubeCaption() As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Set tCaption = $G(^||%Cls(%compiledclass.Name,"cubeCaption"))
	If (tCaption = "") {
		Set tCaption = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	}

	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
	}
	If (tLocalize) {
		Do %code.WriteLine(" Quit $$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_")")
	}
	Else {
		Do %code.WriteLine(" Quit "_$$$quote(tCaption))
	}
	Quit $$$OK
}

/// For a given dimenions, hierarchy, and level return its localized caption.
ClassMethod %GetMemberCaption(pDimName As %String, pHierName As %String = "", pLevelName As %String = "", pPropName As %String = "") As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		Do %code.WriteLine(" Set tCaption = """"")
		If (%class.Abstract || (%class.Name = "%DeepSee.SubjectArea")) {
			Quit
		}

		Do %code.WriteLine(" Set pDimName = $$$UPPER(pDimName)")
		Do %code.WriteLine(" Set pHierName = $$$UPPER(pHierName)")
		Do %code.WriteLine(" Set pLevelName = $$$UPPER(pLevelName)")
		Do %code.WriteLine(" Set pPropName = $$$UPPER(pPropName)")

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Merge tCaptions = ^||%Cls(%compiledclass.Name,"captions")

		Set tDimTest = "If"
		Set tDimName = $O(tCaptions(""))
		While (tDimName '= "") {
			Do %code.WriteLine(" "_tDimTest_" (pDimName="_$$$quote($$$UPPER(tDimName))_") {")
			Set tDimTest = "ElseIf"

			Do %code.Write("  If ((pHierName="""")&&(pLevelName="""")) {")

			If ($LG($G(tCaptions(tDimName)),2)'="") {
				If (tLocalize) {
					Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG($G(tCaptions(tDimName)),2))_","_$$$quote(DOMAIN)_") }")
				}
				Else {
					Do %code.WriteLine(" Quit "_$$$quote($LG($G(tCaptions(tDimName)),2))_" }")
				}
			}
			Else {
				If ($LG($G(tCaptions(tDimName)),1)'="") {
					Do %code.WriteLine(" Quit "_$$$quote($LG($G(tCaptions(tDimName)),1)))
				}
				Do %code.WriteLine(" }")
			}
			
			Set tHierName = $O(tCaptions(tDimName,""))
			While (tHierName '= "") {
				Do %code.WriteLine("  ElseIf (pHierName="_$$$quote($$$UPPER(tHierName))_") {")

				Do %code.Write("   If (pLevelName="""") {")

				If ($LG($G(tCaptions(tDimName,tHierName)),2)'="") {
					If (tLocalize) {
						Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG($G(tCaptions(tDimName,tHierName)),2))_","_$$$quote(DOMAIN)_")"_" }")
					}
					Else {
						Do %code.WriteLine(" Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName)),2))_" }")
					}
				}
				Else {
					If ($LG($G(tCaptions(tDimName,tHierName)),1)'="") {
						Do %code.WriteLine(" Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName)),1)))
					}
					Do %code.WriteLine(" }")
				}

				Set tLevelName = $O(tCaptions(tDimName,tHierName,""))
				While (tLevelName '= "") {
					Set tPropName = $O(tCaptions(tDimName,tHierName,tLevelName,""))
					Set tHasProps = (tPropName '= "")

					Do %code.WriteLine("   ElseIf (pLevelName="_$$$quote($$$UPPER(tLevelName))_") {")
					Do:tHasProps %code.WriteLine("    If (pPropName="""") {")
					If ($LG($G(tCaptions(tDimName,tHierName,tLevelName)),2)'="") {
						If (tLocalize) {
							Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName)),2))_","_$$$quote(DOMAIN)_")")
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName)),2)))
						}
					}
					Else {
						If ($LG($G(tCaptions(tDimName,tHierName,tLevelName)),1)'="") {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName)),1)))
						}
						Do %code.WriteLine(" }")
					}
					Do %code.WriteLine("    }")

					While (tPropName '= "") {
						Do %code.WriteLine("    ElseIf (pPropName="_$$$quote($$$UPPER(tPropName))_") {")
						If ($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),2)'="") {
							If (tLocalize) {
								Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),2))_","_$$$quote(DOMAIN)_")")
							}
							Else {
								Do %code.WriteLine("     Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),2)))
							}
						}
						Else {
							If ($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),2)'="") {
								Do %code.WriteLine("     Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),1)))
							}
							Do %code.WriteLine(" }")
						}
						Do %code.WriteLine("    }")
						Set tPropName = $O(tCaptions(tDimName,tHierName,tLevelName,tPropName))
					}
					Do:tHasProps %code.WriteLine("   }")

					Set tLevelName = $O(tCaptions(tDimName,tHierName,tLevelName))
				}
				Do %code.WriteLine("  }")
				Set tHierName = $O(tCaptions(tDimName,tHierName))
			}
			Do %code.WriteLine(" }")
			Set tDimName = $O(tCaptions(tDimName))
		}

		// dispatch to base class
		Set tBaseClass = ^||%Cls(%compiledclass.Name,"baseClass")
		If (tBaseClass '= "") {
			Do %code.WriteLine(" Set tCaption = ##class("_tBaseClass_").%GetMemberCaption(pDimName,pHierName,pLevelName,pPropName)")
		}

		// for compound cube, try the other base classes as well
		Set tJoinList = $G(^||%Cls(%compiledclass.Name,"joinList"))
		For p=2:1:$L(tJoinList,",") {
			Set tBaseCube = $P(tJoinList,",",p)
			Set tBaseClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tBaseCube)))
			If (tBaseClass '= "") {
				Do %code.WriteLine(" Set:tCaption="""" tCaption = ##class("_tBaseClass_").%GetMemberCaption(pDimName,pHierName,pLevelName,pPropName)")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do %code.WriteLine(" Quit tCaption")
	Quit tSC
}

/// For a given dimenions, hierarchy, and level return its localized caption.
ClassMethod %GetMemberDescription(pDimName As %String, pHierName As %String = "", pLevelName As %String = "", pPropName As %String = "") As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// JSL4475 add this method
	Set tSC = $$$OK
	Try {
		Do %code.WriteLine(" Set tDescription = """"")
		If (%class.Abstract || (%class.Name = "%DeepSee.SubjectArea")) {
			Quit
		}

		Do %code.WriteLine(" Set pDimName = $$$UPPER(pDimName)")
		Do %code.WriteLine(" Set pHierName = $$$UPPER(pHierName)")
		Do %code.WriteLine(" Set pLevelName = $$$UPPER(pLevelName)")
		Do %code.WriteLine(" Set pPropName = $$$UPPER(pPropName)")

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Merge tDescriptions = ^||%Cls(%compiledclass.Name,"descriptions")

		Set tDimTest = "If"
		Set tDimName = $O(tDescriptions(""))
		While (tDimName '= "") {
			Do %code.WriteLine(" "_tDimTest_" (pDimName="_$$$quote($$$UPPER(tDimName))_") {")
			Set tDimTest = "ElseIf"

			Do %code.Write("  If ((pHierName="""")&&(pLevelName="""")) {")

			If ($LG($G(tDescriptions(tDimName)),1)'="") {
				If (tLocalize) {
					Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG($G(tDescriptions(tDimName)),1))_","_$$$quote(DOMAIN)_") }")
				}
				Else {
					Do %code.WriteLine(" Quit "_$$$quote($LG($G(tDescriptions(tDimName)),1))_" }")
				}
			}
			Else {
				If ($LG($G(tDescriptions(tDimName)),1)'="") {
					Do %code.WriteLine(" Quit "_$$$quote($LG($G(tDescriptions(tDimName)),1)))
				}
				Do %code.WriteLine(" }")
			}
			
			Set tHierName = $O(tDescriptions(tDimName,""))
			While (tHierName '= "") {
				Do %code.WriteLine("  ElseIf (pHierName="_$$$quote($$$UPPER(tHierName))_") {")

				Do %code.Write("   If (pLevelName="""") {")

				If ($LG($G(tDescriptions(tDimName,tHierName)),1)'="") {
					If (tLocalize) {
						Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG($G(tDescriptions(tDimName,tHierName)),1))_","_$$$quote(DOMAIN)_")"_" }")
					}
					Else {
						Do %code.WriteLine(" Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName)),1))_" }")
					}
				}
				Else {
					If ($LG($G(tDescriptions(tDimName,tHierName)),1)'="") {
						Do %code.WriteLine(" Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName)),1)))
					}
					Do %code.WriteLine(" }")
				}

				Set tLevelName = $O(tDescriptions(tDimName,tHierName,""))
				While (tLevelName '= "") {
					Set tPropName = $O(tDescriptions(tDimName,tHierName,tLevelName,""))
					Set tHasProps = (tPropName '= "")

					Do %code.WriteLine("   ElseIf (pLevelName="_$$$quote($$$UPPER(tLevelName))_") {")
					Do:tHasProps %code.WriteLine("    If (pPropName="""") {")
					If ($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1)'="") {
						If (tLocalize) {
							Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1))_","_$$$quote(DOMAIN)_")")
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1)))
						}
					}
					Else {
						If ($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1)'="") {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1)))
						}
						Do %code.WriteLine(" }")
					}
					Do %code.WriteLine("    }")

					While (tPropName '= "") {
						Do %code.WriteLine("    ElseIf (pPropName="_$$$quote($$$UPPER(tPropName))_") {")
						If ($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1)'="") {
							If (tLocalize) {
								Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1))_","_$$$quote(DOMAIN)_")")
							}
							Else {
								Do %code.WriteLine("     Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1)))
							}
						}
						Else {
							If ($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1)'="") {
								Do %code.WriteLine("     Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1)))
							}
							Do %code.WriteLine(" }")
						}
						Do %code.WriteLine("    }")
						Set tPropName = $O(tDescriptions(tDimName,tHierName,tLevelName,tPropName))
					}
					Do:tHasProps %code.WriteLine("   }")

					Set tLevelName = $O(tDescriptions(tDimName,tHierName,tLevelName))
				}
				Do %code.WriteLine("  }")
				Set tHierName = $O(tDescriptions(tDimName,tHierName))
			}
			Do %code.WriteLine(" }")
			Set tDimName = $O(tDescriptions(tDimName))
		}

		// dispatch to base class
		Set tBaseClass = ^||%Cls(%compiledclass.Name,"baseClass")
		If (tBaseClass '= "") {
			Do %code.WriteLine(" Set tDescription = ##class("_tBaseClass_").%GetMemberDescription(pDimName,pHierName,pLevelName,pPropName)")
		}

		// for compound cube, try the other base classes as well
		Set tJoinList = $G(^||%Cls(%compiledclass.Name,"joinList"))
		For p=2:1:$L(tJoinList,",") {
			Set tBaseCube = $P(tJoinList,",",p)
			Set tBaseClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tBaseCube)))
			If (tBaseClass '= "") {
				Do %code.WriteLine(" Set:tDescription="""" tDescription = ##class("_tBaseClass_").%GetMemberDescription(pDimName,pHierName,pLevelName,pPropName)")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do %code.WriteLine(" Quit tDescription")
	Quit tSC
}

/// Return the filter spec for this subject area.
ClassMethod %GetFilterSpec() As %String [ Final ]
{
	Set tCube = $$$UPPER(..%GetCubeName())
	Set tFilter = $G($$$DeepSeeMetaGLVN("cubes",tCube,"filterSpec"))
	Set tFilter = ..%OnGetFilterSpec(tFilter)
	Quit tFilter
}

/// This callback gives a SubjectArea a chance to programmatically define its filter spec.
ClassMethod %OnGetFilterSpec(pFilterSpec As %String) As %String
{
	Quit pFilterSpec
}

/// Return the name of the default listing for this SubjectArea, if any.
ClassMethod %GetDefaultListing() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate ]
{
	// JMD1061
	// first try callback
	Do %code.WriteLine(" Set tListing = ..%OnGetDefaultListing()")

	// now dispatch to base cube
	Set tBaseClass = $G(^||%Cls(%compiledclass.Name,"baseClass"))
	If (tBaseClass '= "") {
		Do %code.WriteLine(" Set:tListing="""" tListing = ##class("_tBaseClass_").%GetDefaultListing()")
	}
	Do %code.WriteLine(" Quit tListing")
	Quit $$$OK
}

/// This callback gives a SubjectArea a chance to programmatically return the name 
/// of the listing to use as its default listing.
/// This must be the name of a defined listing within the SubjectArea.
/// Return "" to use the pre-defined default listing.
ClassMethod %OnGetDefaultListing() As %String
{
	Quit ""
}

/// Test if this cube supports drill through (listing) queries.
ClassMethod %CanDrillThrough() As %Boolean
{
	// see if any listings are available to the current user
	Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(..%GetCubeName(),.tListings)
	Quit $S($D(tListings):1,1:0)
}

/// Test whether this subject area is abstract or not.
ClassMethod %IsAbstract() As %Boolean [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit 1")
	}
	Else {
		Do %code.WriteLine(" Quit 0")
	}
	Quit $$$OK
}

/// Test whether this subject area is compound or not.
ClassMethod %IsCompound(Output pJoinList As %String) As %Boolean [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Set tCompound =	($G(^||%Cls(%compiledclass.Name,"joinList"))'="")
	If (tCompound) {
		Do %code.WriteLine(" Set pJoinList = "_$$$quote(^||%Cls(%compiledclass.Name,"joinList")))
		Do %code.WriteLine(" Quit 1")
	}
	Else {
		Do %code.WriteLine(" Set pJoinList = """"")
		Do %code.WriteLine(" Quit 0")
	}
	Quit $$$OK
}

/// Return the (localized) caption for the %COUNT measure used by this cube.
/// Returns "" if this has not been overridden by the cube.
ClassMethod %GetCountCaption() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (%class.Abstract || (%class.Name = "%DeepSee.SubjectArea")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tName = ^||%Cls(%compiledclass.Name,"countCaption")
		If (tName="") {
			Set tBaseClass = ^||%Cls(%compiledclass.Name,"baseClass")
			Do %code.WriteLine(" Quit ##class("_tBaseClass_").%GetCountCaption()")
			Quit
		}
		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		If (tLocalize) {
			Do %code.WriteLine(" Quit $$$Text("_$$$quote(tName)_","_$$$quote(DOMAIN)_")")
		}
		Else {
			Do %code.WriteLine(" Quit "_$$$quote(tName))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the logical name for the %COUNT measure used by this cube.
ClassMethod %GetCountName() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (%class.Abstract || (%class.Name = "%DeepSee.SubjectArea")) {
			Do %code.WriteLine(" Quit ""%COUNT""")
			Quit
		}

		Set tName = ^||%Cls(%compiledclass.Name,"countName")
		If (tName="") {
			Set tBaseClass = ^||%Cls(%compiledclass.Name,"baseClass")
			Do %code.WriteLine(" Quit ##class("_tBaseClass_").%GetCountName()")
			Quit
		}
		Do %code.WriteLine(" Quit "_$$$quote(tName))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible actions for this Subject Area.
/// This simply dispatches to the base cube's method.
ClassMethod %GetActionList(ByRef pActions As %List) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// dispatch to base class
	Set tBaseClass = $G(^||%Cls(%compiledclass.Name,"baseClass"))
	If (tBaseClass '= "") {
		Do %code.WriteLine(" Quit ##class("_tBaseClass_").%GetActionList(.pActions)")
	}
	Else {
		Do %code.WriteLine(" Quit $$$OK")
	}
	Quit $$$OK
}

/// Return the (localized) caption for a given listing within this cube.
ClassMethod %GetListingCaption(pListing As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))

		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition") || (tCubeName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pListing = $$$UPPER(pListing)")

		Set n = 0
		Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",""))
		While (k'="") {
			Set n = n + 1
			Set tName = $$$UPPER(k)
			Set tCaption = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",k,"displayName"))
			Set:tCaption="" tCaption = k
			Set tIf = $S(n>1:"ElseIf",1:"If")
			Do %code.WriteLine(" "_tIf_" ("_$$$quote(tName)_"=pListing) {")
			If (tLocalize) {
				Do %code.WriteLine("  Quit $$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine("  Quit "_$$$quote(tCaption))
			}
			Do %code.WriteLine(" }")
			Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",k))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the (localized) description for a given listing within this cube.
ClassMethod %GetListingDescription(pListing As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// Method added by JSL4477
	Set tSC = $$$OK
	Try {
		Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))

		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition") || (tCubeName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pListing = $$$UPPER(pListing)")

		Set n = 0
		Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",""))
		While (k'="") {
			Set n = n + 1
			Set tName = $$$UPPER(k)
			Set tDescription = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",k,"displayName"))
			;Set:tDescription="" tDescription = k
			Set tIf = $S(n>1:"ElseIf",1:"If")
			Do %code.WriteLine(" "_tIf_" ("_$$$quote(tName)_"=pListing) {")
			If (tLocalize) {
				Do %code.WriteLine("  Quit $$$Text("_$$$quote(tDescription)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine("  Quit "_$$$quote(tDescription))
			}
			Do %code.WriteLine(" }")
			Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",k))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the (localized) caption for a given listing field within this cube.
ClassMethod %GetListingFieldCaption(pField As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))

		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition") || (tCubeName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pField = $$$UPPER(pField)")

		Set n = 0
		Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",""))
		While (k'="") {
			Set n = n + 1
			Set tName = $$$UPPER(k)
			Set tCaption = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",k,"displayName"))
			Set:tCaption="" tCaption = k
			Set tIf = $S(n>1:"ElseIf",1:"If")
			Do %code.WriteLine(" "_tIf_" ("_$$$quote(tName)_"=pField) {")
			If (tLocalize) {
				Do %code.WriteLine("  Quit $$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine("  Quit "_$$$quote(tCaption))
			}
			Do %code.WriteLine(" }")
			Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",k))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the (localized) description for a given listing field within this cube.
ClassMethod %GetListingFieldDescription(pField As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// JSL4477 - added method
	Set tSC = $$$OK
	Try {
		Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))

		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition") || (tCubeName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pField = $$$UPPER(pField)")

		Set n = 0
		Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",""))
		While (k'="") {
			Set n = n + 1
			Set tName = $$$UPPER(k)
			Set tDescription = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",k,"description"))
			Set:tDescription="" tDescription = k
			Set tIf = $S(n>1:"ElseIf",1:"If")
			Do %code.WriteLine(" "_tIf_" ("_$$$quote(tName)_"=pField) {")
			If (tLocalize) {
				Do %code.WriteLine("  Quit $$$Text("_$$$quote(tDescription)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine("  Quit "_$$$quote(tDescription))
			}
			Do %code.WriteLine(" }")
			Set k = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",k))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// For a pre-defined member within a given level in this cube, return its (localized) caption (display name).
ClassMethod %GetLevelMemberCaption(pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pName As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Set tSC = $$$OK
	Try {
		// JMD1010
		Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))

		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition") || (tCubeName="")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Do %code.WriteLine(" Set pName = $$$UPPER(pName)")

		Set tCaseCount = 0
		Set dno = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",""))
		While (dno'="") {
			Set hno = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,""))
			While (hno'="") {
				Set lno = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,""))
				While (lno'="") {
					If $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,lno,"mbr")) {
						Set tCaseCount = tCaseCount + 1
						Do %code.WriteLine(" "_$S(tCaseCount>1:"Else",1:"")_"If ((pDimNo="_dno_")&&(pHierNo="_hno_")&&(pLevelNo="_lno_")) {")

						Set mc = 0
						Set m = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,lno,"mbr",""))
						While (m'="") {
							Set mc = mc + 1
							Set tName = $LG($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,lno,"mbr",m)),1)
							Set tCaption = $LG($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,lno,"mbr",m)),3)
							Do %code.Write("  "_$S(mc>1:"Else",1:"")_"If (pName="_$$$quote($$$UPPER(tName))_") {")
							If (tLocalize && (tCaption'="")) {
								Do %code.Write(" Quit $$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_")")
							}
							Else {
								Set:tCaption="" tCaption = tName
								Do %code.Write(" Quit "_$$$quote(tCaption))
							}
							Do %code.WriteLine("  }")
							Set m = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,lno,"mbr",m))
						}

						Do %code.WriteLine(" }")
					}
					Set lno = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno,lno))
				}
				Set hno = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno,hno))
			}
			Set dno = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",dno))
		}
		Do %code.WriteLine(" Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback gives a Cube a chance to programmatically provide a set of
/// members for a computed dimension.<br/>
/// This simply dispatches to the base cube's method.
ClassMethod %OnGetComputedMembers(pDimName As %String, pHierName As %String, pLevelName As %String, ByRef pMemberList, pRollupKey As %String = "", ByRef pRange As %String = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// dispatch to base class
	Set tBaseClass = $G(^||%Cls(%compiledclass.Name,"baseClass"))
	If (tBaseClass '= "") {
		Do %code.WriteLine(" Quit ##class("_tBaseClass_").%OnGetComputedMembers(pDimName,pHierName,pLevelName,.pMemberList,pRollupKey,.pRange)")
	}
	Else {
		Do %code.WriteLine(" Quit $$$OK")
	}
	Quit $$$OK
}

Storage Default
{
<Data name="SubjectAreaDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>name</Value>
</Value>
<Value name="3">
<Value>baseCube</Value>
</Value>
<Value name="4">
<Value>caption</Value>
</Value>
</Data>
<DataLocation>^DeepSee.SubjectArea("data")</DataLocation>
<DefaultData>SubjectAreaDefaultData</DefaultData>
<IdLocation>^DeepSee.SubjectArea("data")</IdLocation>
<IndexLocation>^DeepSee.SubjectArea("index")</IndexLocation>
<StreamLocation>^DeepSee.SubjectArea("stream")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
