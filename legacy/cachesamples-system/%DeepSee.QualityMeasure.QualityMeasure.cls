/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// This class is used to define DeepSee Quality Measures.<br/>
Class %DeepSee.QualityMeasure.QualityMeasure Extends (%RegisteredObject, %XML.Adaptor) [ CompileAfter = (%DeepSee.Model.QualityMeasure.qualityMeasure, %DeepSee.Utils), System = 4 ]
{

/// This projection is used to keep track of when Quality Measure classes are compiled or deleted.
Projection QualityMeasure As %DeepSee.QualityMeasure.QualityMeasureProjection [ Internal ];

/// This XData definition defines the Quality Measure.
XData QualityMeasure [ XMLNamespace = "http://www.intersystems.com/deepsee/qualityMeasure" ]
{
}

/// Process the model for this quality measure.
ClassMethod %GetModel() As %DeepSee.Model.QualityMeasure.qualityMeasure [ CodeMode = objectgenerator, Final, Internal ]
{
	Kill ^||%Cls(%compiledclass.Name)
	If (%class.Abstract || (%class.Name = "%DeepSee.QualityMeasure.QualityMeasure")) {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	#; find XDATA block named QualityMeasure
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||QualityMeasure")

	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
	}

	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into cube meta-data object (with children)
			Set tReader = ##class(%XML.Reader).%New()

			Set tSC = tReader.OpenStream(tStream)
			If $$$ISERR(tSC) Quit tSC

			Do tReader.Correlate("qualityMeasure","%DeepSee.Model.QualityMeasure.qualityMeasure")

			#; there should only be one quality measure defined
			Do tReader.Next(.tQMSR,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tQMSR) Quit $$$ERROR($$$GeneralError,"No <qualityMeasure> element defined in QualityMeasure block.")

			#; is QualityMeasure disabled?
			If (tQMSR.disabled) {
				Write !,$$$FormatText($$$Text("QualityMeasure '%1' is disabled","%DeepSee"),tQMSR.name)
				Do %code.WriteLine(" Quit tQMSR1")
				Quit tSC
			}

			#; is this name already used?
			Set tQMSRName = tQMSR.name
			Set tRegClass = $G($$$DeepSeeMetaGLVN("qmsrNames",$$$UPPER(tQMSRName)))
			If ((tRegClass'="") && (tRegClass '= %class.Name)) {
				Quit $$$ERROR($$$GeneralError,"Quality Measure with given name already exists: " _ tQMSRName)
			}

			#; validate
			Set tSC = tQMSR.%Validate()
			If $$$ISERR(tSC) Quit tSC

			#; get meta data
			Set tSC = ##class(%DeepSee.QualityMeasure.Utils).%ProcessQualityMeasure(tQMSR,.tInfo)
			If $$$ISERR(tSC) Quit tSC

			Set ^||%Cls(%compiledclass.Name,"qmsrName") = tQMSRName
			Set ^||%Cls(%compiledclass.Name,"catalog") = tQMSR.catalog
			Set ^||%Cls(%compiledclass.Name,"set") = tQMSR.set
			Set ^||%Cls(%compiledclass.Name,"id") = tQMSR.id
			Set ^||%Cls(%compiledclass.Name,"caption") = tQMSR.caption
			Set ^||%Cls(%compiledclass.Name,"subjectArea") = tQMSR.subjectArea
			Set ^||%Cls(%compiledclass.Name,"format") = tQMSR.format
			Set ^||%Cls(%compiledclass.Name,"published") = tQMSR.published
			Set ^||%Cls(%compiledclass.Name,"linkedTo") = tQMSR.linkedTo
			Set ^||%Cls(%compiledclass.Name,"description") = tQMSR.description

			#; additional info
			Merge ^||%Cls(%compiledclass.Name,"info") = tInfo

			#; have qmsr generate code to recreate itself at run-time
			Do tQMSR.%GenerateCode(%code,tLocalize)

			#; assemble information needed to resolve expression for this measure
			Set tGroupCount = tQMSR.groups.Count()
			For p = 1:1:tGroupCount {
				Set tGroup = tQMSR.groups.GetAt(p)
				If (tGroup.disabled) {
					Continue
				}
				Set tElementCount = tGroup.elements.Count()
				For e = 1:1:tElementCount {
					Set tElement = tGroup.elements.GetAt(e)
					If (tElement.disabled) {
						Continue
					}
					
					// 
					Set tGroupInfo(tGroup.name,tElement.name) = $LB("Include",tElement.mdx)
				}
			}
			If $$$ISERR(tSC) Quit

			Set ^||%Cls(%compiledclass.Name,"expression") = tQMSR.expression
			Merge ^||%Cls(%compiledclass.Name,"groupInfo") = tGroupInfo

			Do %code.WriteLine(" Quit qltyMsr1")
		}
		Else {
			Do %code.WriteLine(" Quit """"")
			Quit $$$ERROR($$$GeneralError,"No Quality Measure definition in class: " _ %class.Name)
		}
	}
	Quit $$$OK
}

/// Return the caption of the quality measure.
ClassMethod %GetQualityMeasureCaption() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"caption"))))
	Quit $$$OK
}

/// Return the description of the quality measure.
ClassMethod %GetQualityMeasureDescription() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"description"))))
	Quit $$$OK
}

/// Return the linkedTo setting for the quality measure.
ClassMethod %GetQualityMeasureLinkedTo() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"linkedTo"))))
	Quit $$$OK
}

/// Return the logical name of the quality measure.
ClassMethod %GetQualityMeasureName() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"qmsrName"))))
	Quit $$$OK
}

/// Return the logical catalog of the quality measure.
ClassMethod %GetQualityMeasureCatalog() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"catalog"))))
	Quit $$$OK
}

/// Return the logical set of the quality measure.
ClassMethod %GetQualityMeasureSet() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"set"))))
	Quit $$$OK
}

/// Test if the quality measure is published.
ClassMethod %IsPublished() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_+$G(^||%Cls(%compiledclass.Name,"published")))
	Quit $$$OK
}

/// Return the format string for the quality measure.
ClassMethod %GetFormat() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"format"))))
	Quit $$$OK
}

/// Return the logical id of the quality measure.
ClassMethod %GetQualityMeasureId() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"id"))))
	Quit $$$OK
}

/// Return the name of the subject area this quality measure applies to.
ClassMethod %GetSubjectArea() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"subjectArea"))))
	Quit $$$OK
}

/// Test whether this class is abstract or not.
ClassMethod %IsAbstract() As %Boolean [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit 1")
	}
	Else {
		Do %code.WriteLine(" Quit 0")
	}
	Quit $$$OK
}

/// Return the set of groups and elements for this quality measure.
ClassMethod %GetGroupsAndElements(Output pList) [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Kill pList")
	Merge tGroupInfo = ^||%Cls(%compiledclass.Name,"groupInfo")

	Set g = $O(tGroupInfo(""))
	While (g'="") {
		Set ex = $O(tGroupInfo(g,""))
		While (ex'="") {
			Do %code.WriteLine(" Set pList("_$$$quote(g)_","_$$$quote(ex)_") = """"")
			Set ex = $O(tGroupInfo(g,ex))
		}
		Set g = $O(tGroupInfo(g))
	}
	Quit $$$OK
}

/// Return the MDX expression for this quality measure.<br/>
/// If <var>pGroup</var> is defined, return the specific expression for the group.
/// If <var>pGroup</var> and <var>pElement</var> are defined, return the specific expression for the element within the group.
ClassMethod %GetExpression(pGroup As %String = "", pElement As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Set tSC = $$$OK
	Try {
		Set tExpr = ""

		Merge tGroupInfo = ^||%Cls(%compiledclass.Name,"groupInfo")

		// resolve group expressions
		Set g = $O(tGroupInfo(""))
		While (g'="") {
			Set tClause = ""
			Set tCount = 0
			Set ex = $O(tGroupInfo(g,""))
			While (ex'="") {
				Set tMDX = $LG(tGroupInfo(g,ex),2)
				If (tMDX'="") {
					Set tClause = tClause _ $S(tCount=0:"",1:",") _ tMDX
					Set tCount = tCount + 1
					Set tTable($$$UPPER(g),$$$UPPER(ex)) = tMDX
				}
				Set ex = $O(tGroupInfo(g,ex))
				Set:tCount>1 tClause = "AGGREGATE({"_tClause_"})"
				Set tTable($$$UPPER(g)) = tClause
			}
			Set g = $O(tGroupInfo(g))
		}

		// find all group names within the main expression and replace
		Set tOrigExpr = $G(^||%Cls(%compiledclass.Name,"expression"))
		Set tState = 0
		Set tToken = ""
		For p=1:1:$L(tOrigExpr) {
			Set ch = $E(tOrigExpr,p)
			If (tState = 0) {
				If (ch = "[") {
					Set tState = 1
					Set tToken = ""
				}
				Else {
					Set tExpr = tExpr _ ch
				}
			}
			Else { // in []
				If (ch = "]") {
					Set tState = 0
					If ((tToken'="")&&$D(tTable($$$UPPER(tToken)))) {
						Set tExpr = tExpr _ tTable($$$UPPER(tToken))
					}
					Else {
						Set tSC = $$$ERROR($$$GeneralError,"Unable to find group in measure expression: " _ tToken)
						Set tExpr = ""
						Quit
					}
				}
				Else {
					Set tToken = tToken _ ch
				}
			}
		}
	
		If (tState=1) {
			Set tSC = $$$ERROR($$$GeneralError,"Unmatched [] in measure expression: " _ tOrigExpr)
			Set tExpr = ""
		}

		Do %code.WriteLine(" If ((pGroup="""")&&(pElement="""")) {")
		Do %code.WriteLine("  Quit "_$$$quote(tExpr))
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" Else {")

		Do %code.WriteLine(" Set pGroup=$$$UPPER(pGroup)")
		Do %code.WriteLine(" Set pElement=$$$UPPER(pElement)")

		// JMD1098
		// add cases for specific group and element names
		Set tGroupCount = 0
		Set g = $O(tTable(""))
		While (g'="") {
			Do %code.WriteLine("  "_$S(tGroupCount=0:"If",1:"ElseIf")_" (pGroup="_$$$quote(g)_") {")
			Set tElCount = 0
			Set ex = $O(tTable(g,""))
			While (ex'="") {
				Do %code.WriteLine("   "_$S(tElCount=0:"If",1:"ElseIf")_" (pElement="_$$$quote(ex)_") {")
				Do %code.WriteLine("    Quit "_$$$quote($G(tTable(g,ex))))
				Do %code.WriteLine("   }")
				Set tElCount = tElCount + 1
				Set ex = $O(tTable(g,ex))
			}
			Do %code.WriteLine("   Else {")
			Do %code.WriteLine("    Quit "_$$$quote($G(tTable(g))))
			Do %code.WriteLine("   }")
			Do %code.WriteLine("  }")
			Set tGroupCount = tGroupCount + 1
			Set g = $O(tTable(g))
		}
		Do %code.WriteLine(" }")
		Do %code.WriteLine("  Quit """"")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
