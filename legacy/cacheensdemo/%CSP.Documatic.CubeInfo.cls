/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class contains methods used for displaying DeepSee cube information.
Class %CSP.Documatic.CubeInfo Extends %CSP.Documatic [ System = 3 ]
{

/// Draw HTML for DeepSee Cube Information.
ClassMethod RenderCubeInfo(pClass As %String, pIsSub As %Boolean) As %Status [ Private ]
{
	Try {
		Set tSC = $$$OK
		Set tAbstract = +$$$comClassKeyGet(pClass,$$$cCLASSabstract)
		If (tAbstract) Quit
		Set hlpKey = "" //$$$Text("Bold for local member; italics for inherited; shaded for private; blue for client methods.")
		Set msgApp = $$$TextHTML("This is a DeepSee cube class.")
		Set cubeName = $G($$$DeepSeeMetaGLVN("classes",pClass))
		Set %model = ##class(%DeepSee.Utils).%GetModel(cubeName, .tSC)
		If %model = "" {
			// DTB325 - Provide a message that the cube definition does not exist
			Set msgNoCube = "<b>" _ $$$Text("This subject area is disabled or you do not have permission to view it. No model elements will be displayed.") _ "<b>"
			&html<<div>#(msgNoCube)#<br/></div><br/>>
			Quit
		}
		
		//JSL4414 -- added next two lines
		Do %model.%ResolveInheritance() 
		Do %model.%ApplyOverridesForDocumatic()

		Set cubeDomain = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
		Set msgDisplayName = ""
		Set msgPages = $$$FormatText($$$Text("The Cube name is <b>%1</b>. "),cubeName)
		If %model.disabled = 1 Set msgPages = msgPages_" <b>*** "_$$$TextHTML("This cube is DISABLED! ")_" ***</b>"
		&html<<div class="SummaryText">#(msgApp)# #(msgPages)# <br/></div><br/>>
		If (%model.description '= "") {
			Write $$$TextHTML("Description"),":"
			Do ..RenderDescription(pClass,%model.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")			
		}
		#; -------------------- Displaying Cube Details ------------------ ;#
		Set lblNotDef = "<i>"_$$$TextHTML("(Not defined)")_"</i>"
		&html<<p class='cubeInfo'><table class="DetailTable" cellspacing="0" cellpadding="0" border="0">
		<tr><th>#($$$Text("Cube Property"))#</th><th>#($$$Text("Value"))#</th></tr>>
		&html<<tr class='#($S(%model.displayName'="":"LiteRow",1:"DarkRow"))#'><td>displayName</td><td>#($S(%model.displayName'="":..EscapeHTML(%model.displayName),1:lblNotDef))#</td></tr>>
		If %model.caption '= "" &html<<tr class='LiteRow'><td>caption</td><td>#(..EscapeHTML(%model.caption))#</td></tr>>

		If %model.sourceClass '= "" {
     		Set tDocPage = ..Link("/csp/documatic/%25CSP.Documatic.cls",,1)
	    	Set tLink = tDocPage_"CLASSNAME="_..EscapeURL(%model.sourceClass)_"&LIBRARY="_..EscapeURL($namespace)
		    &html<<tr class='LiteRow'><td>sourceClass</td><td><a href="#(tLink)#" target="_top"/>#(..EscapeHTML(%model.sourceClass))#</a></td></tr>>
		}

		If %model.disabled = 1 &html<<tr class='LiteRow'><td>disabled</td><td><b><i>true</i></b></td></tr>>
		If %model.abstract = 1 &html<<tr class='LiteRow'><td>abstract</td><td><b><i>true</i></b></td></tr>>

		Set tDependsOn = $$$comClassKeyGet(pClass,$$$cCLASSdependson)
		If tDependsOn '= "",tDependsOn '= %model.sourceClass {
			Set tDocPage = ..Link("/csp/documatic/%25CSP.Documatic.cls",,1)
			&html<<tr class='DarkRow'><td>depends on</td><td>>
			For n=1:1:$L(tDependsOn,",") {
				Set tDepend = $P(tDependsOn,",",n)
				Set tLink = tDocPage_"CLASSNAME="_..EscapeURL(tDepend)_"&LIBRARY="_..EscapeURL($namespace)
				If n > 1 Write ", "
				&html<<a href="#(tLink)#" target="_top"/>#(..EscapeHTML(tDepend))#</a>>	
			}
			&html<</td></tr>>
		}
		
		&html<<tr class='#($S(cubeDomain'="":"LiteRow",1:"DarkRow"))#'><td>domain</td><td>#($S(cubeDomain'="":..EscapeHTML(cubeDomain),1:lblNotDef))#</td></tr>>
		&html<<tr class='#($S(%model.owner'="":"LiteRow",1:"DarkRow"))#'><td>owner</td><td>#($S(%model.owner'="":..EscapeHTML(%model.owner),1:lblNotDef))#</td></tr>>
		&html<<tr class='#($S(%model.resource'="":"LiteRow",1:"DarkRow"))#'><td>resource</td><td>#($S(%model.resource'="":..EscapeHTML(%model.resource),1:lblNotDef))#</td></tr>>

		If %model.nullReplacement '= "" &html<<tr class='LiteRow'><td>nullReplacement</td><td>#(..EscapeHTML(%model.nullReplacement))#</td></tr>>
		If %model.defaultListing '= "" &html<<tr class='LiteRow'><td>defaultListing</td><td>#(..EscapeHTML(%model.defaultListing))#</td></tr>>
		If %model.countMeasureName '= "" &html<<tr class='LiteRow'><td>countMeasureName</td><td>#(..EscapeHTML(%model.countMeasureName))#</td></tr>>
		If %model.countMeasureCaption '= "" &html<<tr class='LiteRow'><td>countMeasureCaption</td><td>#(..EscapeHTML(%model.countMeasureCaption))#</td></tr>>
		If %model.initialBuildOrder '= "" &html<<tr class='LiteRow'><td>initialBuildOrder</td><td>#(..EscapeHTML(%model.initialBuildOrder))#</td></tr>>
		If %model.buildRestriction '= "" &html<<tr class='LiteRow'><td>buildRestriction</td><td>#(..EscapeHTML(%model.buildRestriction))#</td></tr>>

		&html<</table></p>>		


		#; -------------------- Displaying Summary ------------------ ;#
		Set %CubeName = $ZCVT(cubeName,"U")
		Set tMeaCount = ..DrawSumMea(%model,.tMeaList)
		Set tDimCount = ..DrawSumDim(%model,.tDimList)
		Set tListCount = ..DrawSumList(%model,.tListList)
		Set tListFieldCount = ..DrawSumListField(%model,.tListFieldList)	// DTB092
		Set tCalCount = ..DrawSumCal(%model,.tCalList)
		Set tNamedCount = ..DrawSumNamed(%model,.tNamedList)
		Set tRelCount = ..DrawSumRel(%model,.tRelList)
		Set tPivotCount = ..DrawSumPivot(%model,.tPivotList)

		#; -------------------- Displaying Details ------------------ ;#
		#; Show Measures details
		Set cId = 900
		If tMeaCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Measures",.cId)
			Set tName = $O(tMeaList(0))
			While (tName '= "") {
				Set url = "#"_tName
				Set tItem = %model.measures.GetAt(tMeaList(tName))
				Set IsHidden = $S(tItem.hidden=1:$$$TextHTML(" and hidden"),1:"")
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "measure <b>",$ZCVT(tName,"O","HTML"),"</b> (",$S(tItem.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))_IsHidden_")"
				If $property(tItem,"displayName") '= "" Write " with display name = ",..EscapeHTML(tItem.displayName)		// DTB806	
				If (tItem.description '= "") {
					Do ..RenderDescription(pClass,tItem.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")			
				}
				If 'pIsSub {
					If tItem.sourceExpression '= "" Write "<div class='indent1'>sourceExpression: ",tItem.sourceExpression,"</div>"
					If tItem.sourceProperty '= "" Write "<div class='indent1'>sourceProperty: ",tItem.sourceProperty,"</div>"	
				}  			
		
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tMeaList(tName))
				Write:tName'="" "<br/>"
			}
			// JSL4414 start
			/*
			#; Display Overrides if exists
			Set tName = $O(tMeaList(0,""))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "measure overrides <b>",$ZCVT(tName,"O","HTML"),"</b>"
				Set tOItem = $O(^DeepSee.Overrides(%CubeName,"MEASURES",tName,""))
				While tOItem '= "" {
					Write "<div class='indent1'>",..EscapeHTML(tOItem),": ",..EscapeHTML(^(tOItem)),"</div>"
					Set tOItem = $O(^DeepSee.Overrides(%CubeName,"MEASURES",tName,tOItem))	
				}
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tMeaList(0,tName))
				Write:tName'="" "<br/>"
			}
			*/
			//JSL4414 end

			&html<<br/></div>>
		}
		If tDimCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Dimensions",.cId)
			Set tName = $O(tDimList(0))
			While (tName '= "") {
				Set url = "#"_tName
				Set tItem = %model.dimensions.GetAt(tDimList(tName))
				Set IsHidden = $S(tItem.hidden=1:$$$TextHTML(" and hidden"),1:"")
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "dimension <b>",$ZCVT(tName,"O","HTML"),"</b> (",$S(tItem.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))_IsHidden_")"
				If tItem.displayName '= "" Write " with display name = ",..EscapeHTML(tItem.displayName)		// DTB806	
				If (tItem.description '= "") {
					Do ..RenderDescription(pClass,tItem.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")			
				}		
				If 'pIsSub {
					If tItem.sourceExpression '= "" Write "<div class='indent1'>sourceExpression: ",tItem.sourceExpression,"</div>"
					If tItem.sourceProperty '= "" Write "<div class='indent1'>sourceProperty: ",tItem.sourceProperty,"</div>"	
				}  			
				Write "</nobr>",!

				If tItem.hierarchies.Count() > 0 {
					Do ..DrawHier(pClass, tItem, pIsSub, "")
				}
				Write ..EndFmt()
				Set tName = $O(tDimList(tName))
				Write:tName'="" "<br/>"
			}
			//JSL4414 start
			#; Display Overrides if exists
			/*
			Set tName = $O(tDimList(0,""))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "dimension overrides <b>",$ZCVT(tName,"O","HTML"),"</b>"
				Set tOItem = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName,""))
				While tOItem '= "" {
					If tOItem = "HIERARCHIES" {
						Write "<p class='hier'>"
						Set tOH = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName,tOItem,""))
						While tOH '= "" {
							Write "&#149; hierarchy <b>",..EscapeHTML(tOH), "</b>"
							Set tOL = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName,tOItem,tOH,""))
							While tOL '= "" {
								If tOL = "LEVELS" {
									Do ..DrawOverLvl(tName,tOItem,tOH)
								} Else {
									If tOL '= "" {
										Write "<div class='indent1'>",tOL,": ",$G(^(tOL)),"</div>"
									}
								}
								Set tOL = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName,tOItem,tOH,tOL))	
							}
							Set tOH = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName,tOItem,tOH))						
						}
						Write "</p>"
					} Else {
						If tOItem '= "" {
							Write "<div class='indent1'>",tOItem,": ",$G(^(tOItem)),"</div>"
						}	
					}
					Set tOItem = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName,tOItem))	
				}
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tDimList(0,tName))
				Write:tName'="" "<br/>"
			}
			*/
			//JSL4414 end

			&html<<br/></div>>
		}
		If tListCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Listings",.cId)
			Set tName = $O(tListList(""))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Set tItem = %model.listings.GetAt(tListList(tName))
				Do ..DrawItemLine("listing", tItem, pClass)
				If tItem.resource '= "" Write "<div class='indent1'>resource: ",tItem.resource,"</div>"
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tListList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}	
		If tListFieldCount > 0 {		// DTB092
			&html<<br/>>
			Do ..RenderLabel("Listing Fields",.cId)
			Set tName = $O(tListFieldList(""))
			While (tName '= "") {
				Set url = "#"_tName_"LF"
				Write "<a name="""_tName_"LF""></a>",!
				Set tItem = %model.listingFields.GetAt(tListFieldList(tName))
				Do ..DrawItemLine("listing field", tItem, pClass)
				If tItem.resource '= "" Write "<div class='indent1'>resource: ",tItem.resource,"</div>"
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tListFieldList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}	
		If tCalCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Calculated Members",.cId)
			Set tName = $O(tCalList(0))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Set tItem = %model.calculatedMembers.GetAt(tCalList(tName))
				Do ..DrawItemLine("calculated member", tItem, pClass)
				If tItem.dimension '= "" Write "<div class='indent1'>dimension: ",tItem.dimension,"</div>"
				If tItem.valueExpression '= "" {
					Do ..RenderDescription(pClass,"valueExpression: "_tItem.valueExpression,"<blockquote class='indent1'>","</blockquote>")
				}
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tCalList(tName))
				Write:tName'="" "<br/>"
			}
			//JSL4414 start
			#; Display Overrides if exists
			/*
			Set tName = $O(tCalList(0,""))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "calculated member overrides <b>",$ZCVT(tName,"O","HTML"),"</b>"
				Set tOItem = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName,""))
				While tOItem '= "" {
					If tOItem = "DIMENSIONS" {
						Set tDimName = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName,tOItem,""))
						While tDimName '= "" {
							Write "<div class='indent1'>dimension: ",tDimName,"</div>"
							Set P1 = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName,tOItem,tDimName,""))
							While P1 '= "" {
								Write "<blockquote class='indent1'>",..EscapeHTML(P1),": ",..EscapeHTML(^(P1)),"</<blockquote>"						
								Set P1 = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName,tOItem,tDimName,P1))
							}
							Set tDimName = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName,tOItem,tDimName))
						}
					} Else {
						Write "<blockquote class='indent1'>",..EscapeHTML(tOItem),": ",..EscapeHTML(^(tOItem)),"</<blockquote>"	
					}
					Set tOItem = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName,tOItem))	
				}
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tCalList(0,tName))
				Write:tName'="" "<br/>"
			}
			*/
			//JSL4414 end
			&html<<br/></div>>
		}	
		If tNamedCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Named Sets",.cId)
			Set tName = $O(tNamedList(""))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Set tItem = %model.namedSets.GetAt(tNamedList(tName))
				Do ..DrawItemLine("named set", tItem, pClass)
				If tItem.setExpression '= "" {
					Do ..RenderDescription(pClass,"setExpression: "_tItem.setExpression,"<blockquote class='indent1'>","</blockquote>")
				}
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tNamedList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}			
		If tRelCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Relationships",.cId)
			Set tName = $O(tRelList(""))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Set tItem = %model.relationships.GetAt(tRelList(tName))
				Do ..DrawItemLine("relationship", tItem, pClass)
				If tItem.relatedCube '= "" {
					Set tSourceClass = ##class(%DeepSee.Utils).%GetCubeClass(tItem.relatedCube)
					Set:tSourceClass="" tSourceClass = tItem.relatedCube
					Set relatedLink = ..Link("/csp/documatic/%25CSP.Documatic.cls",,1)_"CLASSNAME="_..EscapeURL(tSourceClass)_"&LIBRARY="_..EscapeURL($namespace)
					Write "<div class='indent1'>related cube <a target='_top' href='",relatedLink,"'>",tItem.relatedCube,"</a>"," (",$ZCVT(tSourceClass,"O","HTML"),")</div>"
				}
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tRelList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}
		If tPivotCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Pivot Tables",.cId)
			Do ..DrawPivot(pClass,.tPivotList,cubeName)
			&html<<br/></div>>
		}			
				
	}
	Catch(ex) {
		Write $ZCVT(ex.AsStatus(),"O","HTML")
	}
	Quit tSC
}

ClassMethod DrawSumMea(%model, Output tMeaList) As %Integer
{
	Set hlpKey = ""
	Set tMeaCount = %model.measures.Count()
	Set n = 0
	Set tMeaMaxLen = 0
	If tMeaCount > 0 {
		While n <= tMeaCount {
			Set n = n + 1
			Set tItem = %model.measures.GetAt(n)
			If $IsObject(tItem) {
				Set tName = tItem.name
				Set:$L(tName)>tMeaMaxLen tMeaMaxLen = $L(tName)
				Set tMeaList(tName) = n
			}
		}
	}
	//JSL4414 start
	/*
	#; check overrides
	If $D(^DeepSee.Overrides(%CubeName,"MEASURES")) {
		Set tName = ""
		Set tName = $O(^DeepSee.Overrides(%CubeName,"MEASURES",tName))
		While tName '= "" {
			Set n = n + 1
			Set:$L(tName)>tMeaMaxLen tMeaMaxLen = $L(tName)
			Set tMeaList(0,tName) = n		
			Set tName = $O(^DeepSee.Overrides(%CubeName,"MEASURES",tName))
		}
		Set tMeaCount = tMeaCount + n
	}
	*/
	//JSL4414 end

	#; show measures summary
	If (tMeaCount > 0) {
		Set tCols = $S(tMeaMaxLen>30:3,tMeaMaxLen<15:5,1:4)
		Set:tMeaCount<tCols tCols = tMeaCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Measures"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tMeaList(0))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1

			Set tName = $O(tMeaList(tName))
		}
		#; show overrides for measures
		Set tName = $O(tMeaList(0,""))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1
			Set tName = $O(tMeaList(0,tName))
		}	
		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tMeaCount
}

ClassMethod DrawSumDim(%model, Output tDimList) As %Integer
{
	Set hlpKey = ""	
	Set tDimCount = %model.dimensions.Count()
	Set n = 0
	Set tDimMaxLen = 0
	If tDimCount > 0 {
		While n <= tDimCount {
			Set n = n + 1
			Set tItem = %model.dimensions.GetAt(n)
			If $IsObject(tItem) {
				Set tName = tItem.name
				Set:$L(tName)>tDimMaxLen tDimMaxLen = $L(tName)
				Set tDimList(tName) = n
			}
		}
	}
	//JSL4414 start
	/*
	#; check overrides
	If $D(^DeepSee.Overrides(%CubeName,"DIMENSIONS")) {
		Set tName = ""
		Set tName = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName))
		While tName '= "" {
			Set n = n + 1
			Set:$L(tName)>tDimMaxLen tDimMaxLen = $L(tName)
			Set tDimList(0,tName) = n		
			Set tName = $O(^DeepSee.Overrides(%CubeName,"DIMENSIONS",tName))
		}
		Set tDimCount = tDimCount + n
	}
	*/
	//JSL4414 end
	
	#; show dimension summary
	If (tDimCount > 0) {
		Set tCols = $S(tDimMaxLen>30:3,tDimMaxLen<15:5,1:4)
		Set:tDimCount<tCols tCols = tDimCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Dimensions"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tDimList(0))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1
			Set tName = $O(tDimList(tName))
		}
		#; show overrides for dimensions
		Set tName = $O(tDimList(0,""))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1
			Set tName = $O(tDimList(0,tName))
		}	

		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tDimCount
}

/// Draw cube element Hierarchies (pDim passed in is the Dimension object)<br/>
/// pBaseModelDim is the base model object for this dimension or null.
ClassMethod DrawHier(pClass, pDim, pIsSub, pBaseModelDim)
{
	Try {
		If pIsSub {
			Kill tBaseList
			#; Get baseCube's hierarchy array for subject area comparison 
			For n = 1:1:pBaseModelDim.hierarchies.Count() Set tBaseList(pBaseModelDim.hierarchies.GetAt(n).name) = n		
			#; Get hierarchy's property list
			Set tCObj = ##class(%Dictionary.CompiledClass).%OpenId("%DeepSee.Model.SubjectArea.hierarchy")
			Kill tProp For n = 1:1:tCObj.Properties.Count() Set tProp(tCObj.Properties.GetAt(n).Name) = n
			Kill tProp("%%OID"),tProp("aggregate"),tProp("description"),tProp("subjectArea"),tProp("hidden"),tProp("name")
		}

		Set H = pDim.hierarchies
		Set len = H.Count()
		Set h = 1
		While h <= len {
			Set tRow = 0
			Set tHier = H.GetAt(h)		
			Set tStatus = $S(tHier.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))
			Set IsHidden = $S('pIsSub:"",tHier.hidden=1:$$$TextHTML(" and hidden"),1:"")
			Write "<p class='hier'>&#149; hierarchy <b>",tHier.name, "</b> (",tStatus,IsHidden,")"
			If tHier.displayName '= "" Write " with display name = ",..EscapeHTML(tHier.displayName)		// DTB806
			Write "</p>"
			If tHier.description '= "" {
				// DTB325 - Add style class
				Do ..RenderDescription(pClass,tHier.description,"<BLOCKQUOTE class='hier'>","</BLOCKQUOTE>")
			}
			#; Show the subject area vs. base cube comparison table for this hierarchy
			If pIsSub {
				&html<<div style="margin-left: 40px;"><table class="DetailTable" cellspacing="1" cellpadding="0" border="0">
				<tr><th>#($$$Text("Property"))#</th><th>#($$$Text("Base Cube"))#</th><th>#($$$Text("Subject Area"))#</th></tr>>
				Set tRow = 0
				Set tBaseObj = pBaseModelDim.hierarchies.GetAt(tBaseList(tHier.name))
				Set tProp = $O(tProp(""))
				While tProp '= "" {
					Set tBaseVal = $property(tBaseObj,tProp)
					If '$IsObject(tBaseVal) {
						Set tSubVal = $property(tHier,tProp)
						Set tRow = tRow + 1
						&html<<tr class='#($S(tSubVal'=""&(tBaseVal'=tSubVal):"DiffRow",tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tBaseVal'="":tBaseVal,1:"&nbsp;"))#</td><td>#($S(tSubVal'="":tSubVal,1:"(no override)"))#</td></tr>>
					}
					Set tProp = $O(tProp(tProp))
				}
				&html<</table></div>>
			}
			If tHier.levels.Count() > 0 {
				Set tHierPath = pDim.name_">"_tHier.name
				Set dimType = $S(pIsSub:"",1:pDim.type)
				Do ..DrawLevel(pClass, tHier.levels,dimType,tHierPath,pIsSub,$G(tBaseObj))
			}
			Set h = h + 1
		}
	}
	Catch(ex) {
		Write $ZCVT($ZE,"O","HTML")
	}
}

/// Draw cube element Levels (pLevel is passed is the objec of tHier.levels
/// pBaseModelHier is the base model object for this subject area's hierarch or null for cube.
ClassMethod DrawLevel(pClass, pLevel, dimType, pHierPath, pIsSub, pBaseModelHier)
{
	Try {
		If pIsSub {
			Kill tBaseList
			#; Get baseCube's hierarchy array for subject area comparison 
			For n = 1:1:pBaseModelHier.levels.Count() Set tBaseList(pBaseModelHier.levels.GetAt(n).name) = n		
			#; Get level's property list
			Set tCObj = ##class(%Dictionary.CompiledClass).%OpenId("%DeepSee.Model.SubjectArea.level")
			Kill tProp For n = 1:1:tCObj.Properties.Count() Set tProp(tCObj.Properties.GetAt(n).Name) = n
			Kill tProp("%%OID"),tProp("aggregate"),tProp("description"),tProp("subjectArea"),tProp("hidden"),tProp("name")
		}
		Set len = pLevel.Count()
		Set lev = 1
		While lev <= len {
			Set tRow = 0
			Set tLevel = pLevel.GetAt(lev)
			Set tLevPath = pHierPath_">"_tLevel.name	
			If 'pIsSub {
				Set sp = tLevel.sourceProperty
				Set se = tLevel.sourceExpression
				Set tDimType = ", "_$$$TextHTML("type=")_dimType
				If sp '= "" Set tDimType = tDimType _ ", sourceProperty="_sp ; JSL4417 change to sourceProperty sourceExpression
				If se '= "" Set tDimType = tDimType _ ", sourceExpression="_se ; JSL4417 change to sourceExpression from sourceProperty
			} Else {
				Set tDimType = ""
			}
			Set tStatus = $S(tLevel.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))
			Write "<p class='lev'>&#149; level <b>",tLevel.name, "</b> (",tStatus,tDimType,")"
			If tLevel.displayName '= "" Write " with display name = ",..EscapeHTML(tLevel.displayName)		// DTB806
			Write "<br><i>[",tLevPath,"]</i></p>"
			If tLevel.description '= "" {
				// DTB325 - Add style class
				Do ..RenderDescription(pClass,tLevel.description,"<BLOCKQUOTE class='lev'>","</BLOCKQUOTE>")
			}	
			#; Show the subject area vs. base cube comparison table for this level
			If pIsSub {
				&html<<div style="margin-left: 70px;"><table class="DetailTable" cellspacing="1" cellpadding="0" border="0">
				<tr><th>#($$$Text("Property"))#</th><th>#($$$Text("Base Cube"))#</th><th>#($$$Text("Subject Area"))#</th></tr>>
				Set tRow = 0
				Set tBaseObj = pBaseModelHier.levels.GetAt(tBaseList(tLevel.name))
				Set tProp = $O(tProp(""))
				While tProp '= "" {
					Set tBaseVal = $property(tBaseObj,tProp)
					If '$IsObject(tBaseVal) {
						Set tSubVal = $property(tLevel,tProp)
						Set tRow = tRow + 1
						&html<<tr class='#($S(tSubVal'=""&(tBaseVal'=tSubVal):"DiffRow",tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tBaseVal'="":tBaseVal,1:"&nbsp;"))#</td><td>#($S(tSubVal'="":tSubVal,1:"(no override)"))#</td></tr>>
					}
					Set tProp = $O(tProp(tProp))
				}
				&html<</table></div>>
			} Else {
				If tLevel.properties.Count() > 0 {
					Do ..DrawProp(pClass, tLevel.properties, tLevPath)
				}
			}
			Set lev = lev + 1
		}
	}
	
	Catch(ex) {
		Write $ZCVT($ZE,"O","HTML")
	}
}

/// Draw cube element Properties (pProp passed in is the object of tLevel.properties)
ClassMethod DrawProp(pClass, pProp, pLevPath)
{
	Set lblEnabled = $$$TextHTML("enabled")
	Set lblDisabled = $$$TextHTML("disabled")
	Set len = pProp.Count()
	Set h = 1
	While h <= len {
		Set tRow = 0
		Set tProp = pProp.GetAt(h)	
		If 'tProp.hidden {
			// DTB325 - Skip hidden properties
			Set tStatus = $S(tProp.disabled=0:lblEnabled,1:lblDisabled)
			Write "<p class='pro'>&#186; property <b>",tProp.name, "</b> (",tStatus,")"
			If tProp.displayName '= "" Write " with display name = ",..EscapeHTML(tProp.displayName)		// DTB806
			Set tPropPath = pLevPath_">"_tProp.name
			Write "<br><i>[",tPropPath,"]</i></p>"
			If tProp.description '= "" {
				Do ..RenderDescription(pClass,tProp.description,"<BLOCKQUOTE class='pro'>","</BLOCKQUOTE>")		// DTB325 - Add style class
			}
		}
		Set h = h + 1
	}
}

ClassMethod DrawPivot(pClass, pPivotList, cubeName)
{
	#; Get pivot's property list
	Set tCObj = ##class(%Dictionary.CompiledClass).%OpenId("%DeepSee.Dashboard.Pivot")
	Kill tProp For n = 1:1:tCObj.Properties.Count() Set tProp(tCObj.Properties.GetAt(n).Name) = n
	Kill tProp("%%OID"),tProp("%Concurrency"),tProp("description")

	Set tName = $O(pPivotList(""))
	While (tName '= "") {
		Set url = "#"_tName
		Write "<a name="""_tName_"""></a>",!
		Set tItem = ##class(%DeepSee.Dashboard.Pivot).%OpenId(pPivotList(tName))
		Write ..FmtInternal(0)
		Write "<nobr>&#149 "	
		Write "pivot <b>",$ZCVT(tName,"O","HTML"),"</b> with folder name <i>",tItem.folderName,"</i>" //, " for cube ",tItem.cubeName
		If tItem.resource '= "" Set msgResource = $$$FormatText($$$Text("Resource is %1."),tItem.resource)
		Else   Set msgResource = $$$Text("Resource is <i>not defined</i>.")
		If (tItem.description '= "") {
			Do ..RenderDescription(pClass,tItem.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")
		}
		If (tItem.mdx '= "") {
			Do ..RenderDescription(pClass,tItem.mdx,"<BLOCKQUOTE>","</BLOCKQUOTE>")
		}		
		If tItem.filters.Count() > 0 {
			&html<<p class='hier'>#($$$TextHTML("Filters"))#:>
			&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>text</th><th>spec</th><th>key</th><th>filterExpression</th></tr>>
			For n = 1:1:tItem.filters.Count() {
				Set tMbr = tItem.filters.GetAt(n)
				&html<<tr class='#($S(n#2:"LiteRow",1:"DarkRow"))#'>>
				If tMbr.spec = "%FILTER" {
					Set filter = $G($$$DeepSeeFiltersGLVN($$$UPPER(cubeName),$$$UPPER(tMbr.text)))
					&html<<td>named filter: #(tMbr.text)#</td><td>#($lg(filter,3))#</td>>
				} Else {
					&html<<td>#(tMbr.text)#<td>#(tMbr.spec)#</td>>
				}
				&html<<td>#(tMbr.key)#</td><td>#(tMbr.filterExpression)#</td></tr>>
			}
			 
			Write "</table></p>"
		}		
		If tItem.rowLevels.Count() > 0 {
			&html<<p class='hier'>#($$$TextHTML("Rows"))#:>
			&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>filterEnabled</th><th>spec</th><th>filterExpression</th></tr>>
			For n = 1:1:tItem.rowLevels.Count() {
				Set tMbr = tItem.rowLevels.GetAt(n)
				&html<<tr class='#($S(n#2:"LiteRow",1:"DarkRow"))#'><td>#(tMbr.filterEnabled)#</td><td>#(tMbr.spec)#</td><td>#(tMbr.filterExpression)#</tr>>
			}
			Write "</table></p>"
		}
		If tItem.columnLevels.Count() > 0 {
			&html<<p class='hier'>#($$$TextHTML("Columns"))#:>
			&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>filterEnabled</th><th>spec</th><th>filterExpression</th></tr>>
			For n = 1:1:tItem.columnLevels.Count() {
				Set tMbr = tItem.columnLevels.GetAt(n)
				&html<<tr class='#($S(n#2:"LiteRow",1:"DarkRow"))#'><td>#(tMbr.filterEnabled)#</td><td>#(tMbr.spec)#</td><td>#(tMbr.filterExpression)#</tr>>
			}
			Write "</table></p>"
		}
		If tItem.measures.Count() > 0 {
			&html<<p class='hier'>#($$$TextHTML("Measures"))#:>
			&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>filterEnabled</th><th>spec</th><th>filterExpression</th></tr>>
			For n = 1:1:tItem.measures.Count() {
				Set tMbr = tItem.measures.GetAt(n)
				&html<<tr class='#($S(n#2:"LiteRow",1:"DarkRow"))#'><td>#(tMbr.filterEnabled)#</td><td>#(tMbr.spec)#</td><td>#(tMbr.filterExpression)#</tr>>
			}
			Write "</table></p>"
		}	
		If tItem.calculatedMembers.Count() > 0 {
			&html<<p class='hier'>#($$$TextHTML("Calculated Members"))#:>
			&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>memberName</th><th>dimension</th><th>valueExpression</th></tr>>
			For n = 1:1:tItem.calculatedMembers.Count() {
				Set tClass = $S(n#2:"LiteRow",1:"DarkRow")
				Set tMbr = tItem.calculatedMembers.GetAt(n)
				Write "<tr class='#(tClass)#'><td>",tMbr.memberName,"</td><td>",tMbr.dimension,"</td><td>",tMbr.valueExpression,"</tr>"
			}
			Write "</table></p>"
		}
		&html<<p class='hier'>#($$$TextHTML("Other Information"))#:<table class="DetailTable" cellspacing="0" cellpadding="0" border="0">
		<tr><th>#($$$Text("Property"))#</th><th>#($$$Text("Value"))#</th></tr>>
		Set tShowProps = "createdBy,keywords,public,resource,shared,showEmptyColumns,showEmptyRows,owner"
		Set tRow = 0
		Set tProp = $P(tShowProps,",",1)
		While tProp '= "" {
			Set tSubVal = $property(tItem,tProp)
				Set tRow = tRow + 1
				&html<<tr class='#($S(tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tSubVal'="":tSubVal,1:"&nbsp;"))#</td></tr>>
			Set tProp = $P(tShowProps,",",tRow+1)
		}
		&html<</table></p>>		
		/*
		&html<<p class='hier'>#($$$TextHTML("All Information"))#:<table class="DetailTable" cellspacing="0" cellpadding="0" border="0">
		<tr><th>#($$$Text("Property"))#</th><th>#($$$Text("Value"))#</th></tr>>
		Set tRow = 0
		Set tProp = $O(tProp(""))
		While tProp '= "" {
			Set tSubVal = $property(tItem,tProp)
			Set tRow = tRow + 1
			&html<<tr class='#($S(tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tSubVal'="":tSubVal,1:"&nbsp;"))#</td></tr>>
			Set tProp = $O(tProp(tProp))
		}
		&html<</table></p>>		
		*/
		Write "</nobr>",!
		Write ..EndFmt()
		Set tName = $O(pPivotList(tName))
		Write:tName'="" "<br/>"
	}
}

ClassMethod DrawSumCal(%model, Output tCalList) As %Integer
{
	Set hlpKey = ""
	Set tCalMaxLen = 0
	Set n = 0
	#; Get calculated members
	Set tCalCount = %model.calculatedMembers.Count()
	If tCalCount > 0 {
		While n <= tCalCount {
			Set n = n + 1
			Set tItem = %model.calculatedMembers.GetAt(n)
			If $IsObject(tItem) {
				Set tName = tItem.name
				Set:$L(tName)>tCalMaxLen tCalMaxLen = $L(tName)
				Set tCalList(tName) = n
			}							
		}
	}
	//JSL4414 start
	/*
	#; check overrides
	If $D(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS")) {
		Set tName = ""
		Set tName = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName))
		While tName '= "" {
			Set n = n + 1
			Set:$L(tName)>tCalMaxLen tCalMaxLen = $L(tName)
			Set tCalList(0,tName) = n
			Set tName = $O(^DeepSee.Overrides(%CubeName,"CALCULATEDMEMBERS",tName))
		} 		
		Set tCalCount = tCalCount + n
	}
	*/
	//JSL4414 end

	#; show calculated members
	If (tCalCount > 0) {
		Set tCols = $S(tCalMaxLen>30:3,tCalMaxLen<15:5,1:4)
		Set:tCalCount<tCols tCols = tCalCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Calculated Members"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tCalList(0))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1

			Set tName = $O(tCalList(tName))
		}
		#; show overrides for dimensions
		Set tName = $O(tCalList(0,""))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1
			Set tName = $O(tCalList(0,tName))
		}	
		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tCalCount
}

ClassMethod DrawSumNamed(%model, Output tNamedList) As %Integer
{
	Set hlpKey = ""
	#; Get named sets
	Set tNamedCount = %model.namedSets.Count()
	If tNamedCount > 0 {
		Set tNamedMaxLen = 0
		Set n = 1
		While n <= tNamedCount {
			Set tRow = 0
			Set tItem = %model.namedSets.GetAt(n)
			Set tName = tItem.name
			Set:$L(tName)>tNamedMaxLen tNamedMaxLen = $L(tName)
			Set tNamedList(tName) = n
			Set n = n + 1							
		}
	}
	#; show named sets summary
	If (tNamedCount > 0) {
		Set tCols = $S(tNamedMaxLen>30:3,tNamedMaxLen<15:5,1:4)
		Set:tNamedCount<tCols tCols = tNamedCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Named Sets"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tNamedList(""))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1

			Set tName = $O(tNamedList(tName))
		}
		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tNamedCount
}

ClassMethod DrawSumList(%model, Output tListList) As %Integer
{
	Set hlpKey = ""
	#; Get listings
	Set tListCount = %model.listings.Count()
	If tListCount > 0 {
		Set tListMaxLen = 0
		Set n = 1
		While n <= tListCount {
			Set tRow = 0
			Set tItem = %model.listings.GetAt(n)
			Set tName = tItem.name
			Set:$L(tName)>tListMaxLen tListMaxLen = $L(tName)
			Set tListList(tName) = n
			Set n = n + 1							
		}
	}
	#; show listing summary
	If (tListCount > 0) {
		Set tCols = $S(tListMaxLen>30:3,tListMaxLen<15:5,1:4)
		Set:tListCount<tCols tCols = tListCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Listings"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tListList(""))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1

			Set tName = $O(tListList(tName))
		}
		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tListCount
}

ClassMethod DrawSumListField(%model, Output tListFieldList) As %Integer
{
	// DTB092 
	Set hlpKey = ""
	#; Get listingFields
	Set tListFieldCount = %model.listingFields.Count()
	If tListFieldCount > 0 {
		Set tListMaxLen = 0
		Set n = 1
		While n <= tListFieldCount {
			Set tRow = 0
			Set tItem = %model.listingFields.GetAt(n)
			Set tName = tItem.name
			Set:$L(tName)>tListMaxLen tListMaxLen = $L(tName)
			Set tListFieldList(tName) = n
			Set n = n + 1							
		}
	}
	#; show listing field summary
	If (tListFieldCount > 0) {
		Set tCols = $S(tListMaxLen>30:3,tListMaxLen<15:5,1:4)
		Set:tListFieldCount<tCols tCols = tListFieldCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Listing Fields"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tListFieldList(""))
		While (tName '= "") {
			Set url = "#"_tName_"LF"
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1

			Set tName = $O(tListFieldList(tName))
		}
		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tListFieldCount
}

ClassMethod DrawSumRel(%model, Output tRelList) As %Integer
{
	Set hlpKey = ""
	#; Get relationships
	Set tRelCount = %model.relationships.Count()
	If tRelCount > 0 {
		Set tRelMaxLen = 0
		Set n = 1
		While n <= tRelCount {
			Set tRow = 0
			Set tItem = %model.relationships.GetAt(n)
			Set tName = tItem.name
			Set:$L(tName)>tRelMaxLen tRelMaxLen = $L(tName)
			Set tRelList(tName) = n
			Set n = n + 1							
		}
	}
	#; show relationships summary
	If (tRelCount > 0) {
		Set tCols = $S(tRelMaxLen>30:3,tRelMaxLen<15:5,1:4)
		Set:tRelCount<tCols tCols = tRelCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Relationships"))#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tName = $O(tRelList(""))
		While (tName '= "") {
			Set url = "#"_tName
			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
			Set col = col + 1

			Set tName = $O(tRelList(tName))
		}
		&html<</tr>>
		&html<</table><br/>>
	}
	Quit tRelCount
}

/// This method draws some common stuff of an item. <br>
/// pItemType is a string, such as "dimension", "named set";<br>
/// pItem is the item's object<br>
/// pClass is the current cube class name.
ClassMethod DrawItemLine(pItemType, pItem, pClass)
{
	Write ..FmtInternal(0)
	Write "<nobr>&#149 "	
	Write pItemType," <b>",$ZCVT(pItem.name,"O","HTML"),"</b> (",$S(pItem.disabled=0:"enabled",1:"disabled")_")"
	If pItem.displayName '= "" Write " with display name = ",..EscapeHTML(pItem.displayName)		// DTB806
	If (pItem.description '= "") {
		Do ..RenderDescription(pClass,pItem.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")
	}
}

/// Draw HTML for DeepSee Subject Area Information.
ClassMethod RenderSubjectAreaInfo(pClass As %String, pIsSub As %Boolean) As %Status [ Private ]
{
	Try {
		Set tSC = $$$OK
		Set msgApp = $$$Text("This is a DeepSee subject area definition class.")
		Set hlpKey = "" //$$$Text("Bold for local member; italics for inherited; shaded for private; blue for client methods.")
		Set %model = ..%GetSubjectAreaModel(pClass, .tSC)
		If $$$ISERR(tSC) Quit
		Set cubeName = %model.name
		Set baseCube = %model.baseCube
		Set cubeDomain = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
		Set msgDisplayName = ""
		Set msgPages = $$$FormatText($$$Text("The Subject Area name is %1 "),cubeName)
		Set msgPages = msgPages _ "("_$S(%model.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))_"). "
		If baseCube'="" {
			Set baseCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(baseCube)
			Set tBaseCubeLink = ..ClassToLink(baseCubeClass,,$G(%library,$namespace))
			Set msgBaseCube = $$$FormatText($$$Text("This subject area's base cube is %1 (%2)."),%model.baseCube,tBaseCubeLink)
		} Else {
			Set msgBaseCube = $$$Text("Base cube is <b><i>not defined</i></b>!")			
		}
		If %model.displayName '= "" Set msgDisplayName = $$$FormatText($$$Text("The display name for this cube is %1."),..EscapeHTML(%model.displayName))
		If %model.resource '= "" Set msgResource = $$$FormatText($$$Text("Resource is %1."),%model.resource)
		Else   Set msgResource = $$$Text("Resource is <i>not defined</i>.")
		If cubeDomain '= "" Set msgDomain = $$$FormatText($$$Text("Domain is %1."),cubeDomain)
		Else   Set msgDomain = $$$Text("Domain is <i>not defined</i>.")
		
		&html<<div class="SummaryText">#(msgApp)#&nbsp;#(msgPages)#&nbsp;#(msgBaseCube)#&nbsp;#(msgDisplayName)#<br/>#(msgResource)#&nbsp;#(msgDomain)#</div><br/>>

		If baseCube = "" {
			&html<<h1>#($$$TextHTML("Base cube is required for a subject area. Please use Studio to define it."))#</h1>> 
			Quit
		}
		#; Get baseCube's object so we can display comparisons
		Set %basemodel = ##class(%DeepSee.Utils).%GetModel(baseCube, .tSC)
		
		#; -------------------- Displaying Summary ------------------ ;#
		Set %CubeName = $ZCVT(cubeName,"U")
		Set tMeaCount = ..DrawSumMea(%model,.tMeaList)
		Set tDimCount = ..DrawSumDim(%model,.tDimList)
		Set tListCount = ..DrawSumList(%model,.tListList)

		#; --------------------- Displaying Details ------------------- ;#
		Set lblProperty = $$$Text("Property")
		Set lblBaseCube = $$$Text("Base Cube")
		Set lblSubArea = $$$Text("Subject Area")

		#; Show Measures details		
		Set cId = 900
		If tMeaCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Measures",.cId)
			#; Get baseCube's measure array for future comparison 
			Kill tBaseList
			For n = 1:1:%basemodel.measures.Count() Set tBaseList(%basemodel.measures.GetAt(n).name) = n
			#; Get measure's property list
			Set tCObj = ##class(%Dictionary.CompiledClass).%OpenId("%DeepSee.Model.SubjectArea.measure")
			Kill tProp For n = 1:1:tCObj.Properties.Count() Set tProp(tCObj.Properties.GetAt(n).Name) = n
			Kill tProp("%%OID"),tProp("aggregate"),tProp("description"),tProp("subjectArea"),tProp("name")
			
			Set tName = $O(tMeaList(0))
			While (tName '= "") {
				Set url = "#"_tName
				Set tItem = %model.measures.GetAt(tMeaList(tName))
				Set IsHidden = $S(tItem.hidden=1:$$$TextHTML(" and hidden"),1:"")
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "measure <b>",$ZCVT(tName,"O","HTML"),"</b> (",$S(tItem.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))_IsHidden_")"
				If $property(tItem,"displayName") '= "" Write " with display name = ",tItem.displayName	
				If (tItem.description '= "") {
					Do ..RenderDescription(pClass,tItem.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")			
				}
				&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>#(lblProperty)#</th><th>#(lblBaseCube)#</th><th>#(lblSubArea)#</th></tr>>
				Set tProp = $O(tProp(""))
				Set tRow = 0
				Set tBaseObj = %basemodel.measures.GetAt(tBaseList(tName))
				While tProp '= "" {
					Set tBaseVal = $property(tBaseObj,tProp)
					Set tSubVal = $property(tItem,tProp)
					Set tRow = tRow + 1
					&html<<tr class='#($S(tSubVal'=""&(tBaseVal'=tSubVal):"DiffRow",tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tBaseVal'="":tBaseVal,1:"&nbsp;"))#</td><td>#($S(tSubVal'="":tSubVal,1:"(no override)"))#</td></tr>>
					Set tProp = $O(tProp(tProp))
				}
				&html<</table>>
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tMeaList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}
		If tDimCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Dimensions",.cId)
			#; Get baseCube's dimensions array for future comparison 
			Kill tBaseList
			For n = 1:1:%basemodel.dimensions.Count() Set tBaseList(%basemodel.dimensions.GetAt(n).name) = n
			#; Get dimensions's property list
			Set tCObj = ##class(%Dictionary.CompiledClass).%OpenId("%DeepSee.Model.SubjectArea.dimension")
			Kill tProp For n = 1:1:tCObj.Properties.Count() Set tProp(tCObj.Properties.GetAt(n).Name) = n
			Kill tProp("%%OID"),tProp("aggregate"),tProp("description"),tProp("subjectArea"),tProp("name")

			Set tName = $O(tDimList(0))
			While (tName '= "") {
				Set url = "#"_tName
				Set tItem = %model.dimensions.GetAt(tDimList(tName))
				Set IsHidden = $S(tItem.hidden=1:$$$TextHTML(" and hidden"),1:"")
				Write "<a name="""_tName_"""></a>",!
				Write ..FmtInternal(0)
				Write "<nobr>&#149 "
				Write "dimension <b>",$ZCVT(tName,"O","HTML"),"</b> (",$S(tItem.disabled=0:$$$Text("enabled"),1:$$$Text("disabled"))_IsHidden_")"
				If tItem.displayName '= "" Write " with display name = ",tItem.displayName	
				If (tItem.description '= "") {
					Do ..RenderDescription(pClass,tItem.description,"<BLOCKQUOTE>","</BLOCKQUOTE>")			
				}
				&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>#(lblProperty)#</th><th>#(lblBaseCube)#</th><th>#(lblSubArea)#</th></tr>>
				Set tProp = $O(tProp(""))
				Set tRow = 0
				Set tBaseObj = %basemodel.dimensions.GetAt(tBaseList(tName))
				While tProp '= "" {
					Set tBaseVal = $property(tBaseObj,tProp)
					If '$IsObject(tBaseVal) {
						Set tSubVal = $property(tItem,tProp)
						Set tRow = tRow + 1
						&html<<tr class='#($S(tSubVal'=""&(tBaseVal'=tSubVal):"DiffRow",tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tBaseVal'="":tBaseVal,1:"&nbsp;"))#</td><td>#($S(tSubVal'="":tSubVal,1:"(no override)"))#</td></tr>>
					}
					Set tProp = $O(tProp(tProp))
				}
				&html<</table>>
				Write "</nobr>",!

				If tItem.hierarchies.Count() > 0 {
					Do ..DrawHier(pClass, tItem, pIsSub, tBaseObj)
				}
				Write ..EndFmt()
				Set tName = $O(tDimList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}		
		If tListCount > 0 {
			&html<<br/>>
			Do ..RenderLabel("Listings",.cId)
			#; Get baseCube's listings array for future comparison 
			Kill tBaseList
			For n = 1:1:%basemodel.listings.Count() Set tBaseList(%basemodel.listings.GetAt(n).name) = n
			#; Get listing's property list
			Set tCObj = ##class(%Dictionary.CompiledClass).%OpenId("%DeepSee.Model.SubjectArea.listing")
			Kill tProp For n = 1:1:tCObj.Properties.Count() Set tProp(tCObj.Properties.GetAt(n).Name) = n
			Kill tProp("%%OID"),tProp("aggregate"),tProp("description"),tProp("subjectArea"),tProp("hidden"),tProp("name")

			Set tName = $O(tListList(0))
			While (tName '= "") {
				Set url = "#"_tName
				Write "<a name="""_tName_"""></a>",!
				Set tItem = %model.listings.GetAt(tListList(tName))
				Do ..DrawItemLine("listing", tItem, pClass)
				&html<<table class="DetailTable" cellspacing="1" cellpadding="0" border="0"><tr><th>#(lblProperty)#</th><th>#(lblBaseCube)#</th><th>#(lblSubArea)#</th></tr>>
				Set tProp = $O(tProp(""))
				Set tRow = 0
				Set tBaseObj = %basemodel.listings.GetAt(tBaseList(tName))
				While tProp '= "" {
					Set tBaseVal = $property(tBaseObj,tProp)
					If '$IsObject(tBaseVal) {
						Set tSubVal = $property(tItem,tProp)
						Set tRow = tRow + 1
						&html<<tr class='#($S(tSubVal'=""&(tBaseVal'=tSubVal):"DiffRow",tRow#2:"LiteRow",1:"DarkRow"))#'><td>#(tProp)#</td><td>#($S(tBaseVal'="":tBaseVal,1:"&nbsp;"))#</td><td nowrap>#($S(tSubVal'="":tSubVal,1:"(no override)"))#</td></tr>>
					}
					Set tProp = $O(tProp(tProp))
				}
				&html<</table>>				
				Write "</nobr>",!
				Write ..EndFmt()
				Set tName = $O(tListList(tName))
				Write:tName'="" "<br/>"
			}
			&html<<br/></div>>
		}		

	}
	Catch(ex) {
	}
	Quit tSC
}

/// Given the DeepSee class name (subject area),
/// return an instance of the <class>%DeepSee.Model.SubjectArea.subjectArea</class>
/// meta-data object that describes the subject area.<br/>
/// Return "" if the given cube does not exist.<br/>
/// This method does not work on base cubes; use %GetModel.
ClassMethod %GetSubjectAreaModel(pClassName As %String, Output pStatus As %Status) As %DeepSee.Model.SubjectArea.subjectArea
{
	Set tSubjectArea = ""
	Set pStatus = $$$OK
	Try {
		// get model from XData directly
		Set tObjClass = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName)
		If '$isObject(tObjClass) Set tSC=$$$ERROR($$$ClassDoesNotExist,pClassname) Quit
		; find XData with name SubjectArea
		Set tObjXData="" For i=1:1:tObjClass.XDatas.Count() If tObjClass.XDatas.GetAt(i).Name="SubjectArea" Set tObjXData=tObjClass.XDatas.GetAt(i) Quit
		If tObjXData = "" Set tSC = $$$ERROR($$$GeneralError,"Class does not contain a subject area definition") Quit
		; open the reader and correlate the XData to %DeepSee.Model.SubjectArea.subjectArea
		Set tReader = ##class(%XML.Reader).%New()
		Set tSC = tReader.OpenStream(tObjXData.Data) Quit:$$$ISERR(tSC)
		Do tReader.Correlate("subjectArea","%DeepSee.Model.SubjectArea.subjectArea")
		#; there should only be one subjectArea defined
		Do tReader.Next(.tSubjectArea,.tSC)
		If $$$ISERR(tSC) Quit
		If '$IsObject(tSubjectArea) {
			Set tSC = $$$ERROR($$$GeneralError,"No <subjectArea> element defined in SubjectArea block.")
			Quit
		}
		If (tSubjectArea = "") {
			Set tSC = $$$ERROR($$$GeneralError,"Class does not contain a subject area definition")
			Quit
		}
	}
	Catch(ex) {
		Set tSubjectArea = ""
		Set pStatus = ex.AsStatus()
	}

	Quit tSubjectArea
}

ClassMethod DrawSumPivot(%model, Output tPivotList) As %Integer
{
	Set (tPivotCount,tPivotMaxLen) = 0
	Set tSC = 1
	Try {
		Set hlpKey = ""
		#; Get pivot tables
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSQL = "SELECT ID,name FROM %DeepSee_Dashboard.Pivot where cubeName='"_%model.name_"'"
		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) Quit
		Set tRS = tStatement.%Execute()
		While tRS.%Next(.tSC) {
			//If tPivotCount = 0 &html<<p>#($$$TextHTML("Pivot Tables"))#<a name="PivotTables"></p>>
			Set tPivotCount = tPivotCount + 1
			Set tName = tRS.name
			Set:$L(tName)>tPivotMaxLen tPivotMaxLen = $L(tName)
			Set tPivotList(tName) = tRS.ID
		}
		#; show pivot table summary
		If (tPivotCount > 0) {
			Set tCols = $S(tPivotMaxLen>30:3,tPivotMaxLen<15:5,1:4)
			Set:tPivotCount<tCols tCols = tPivotCount
			&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
			<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#($$$Text("Pivot Tables"))#</th></tr>>
			&html<<tr>>
			Set col = 1
			Set tName = $O(tPivotList(""))
			While (tName '= "") {
				Set url = "#"_tName
				If (col > tCols) {
					&html<</tr><tr>>
					Set col = 1
				}
				&html<<td nowrap><a href="#(url)#">#($ZCVT(tName,"O","HTML"))#</a></td>>
				Set col = col + 1

				Set tName = $O(tPivotList(tName))
			}
			&html<</tr>>
			&html<</table><br/>>
		}
	}
	Catch(ex) {
	}
	If $$$ISERR(tSC) Write $ZCVT($ZE,"O","HTML")
	Quit tPivotCount
}

/// Pre-process the string provided in <VAR>pDescription</VAR> to HTML escape everything that is
/// not a recognized documatic token.
ClassMethod RenderDescription(pClass As %String, pDescription As %String, starttag As %String, endtag As %String)
{
	// Method override added by DTB808
	// Pre-process the description to escape anything that is not a permitted tag
	Set tPermittedTags = $LB("CLASS","METHOD","PROPERTY","PARAMETER","QUERY","LINK","VAR","EXAMPLE")
	
	// Tokenize according to all HTML tags in the description
	Set xml=##class(%CSP.TokenStream).%New()
 	Do xml.OpenFromString(pDescription)
	
	// Look at each token and decide whether or not to escape it in the final description
	Set tDescription = ""
	While xml.NextToken() {
		Set tCurrText = ""
		If xml.IsTag() && $ListFind(tPermittedTags,xml.GetTag()) {
			// Set permitted tag directly without escaping
			Set tCurrText = xml.Text
		}
		Else {
			// Escape everything else
			Set tCurrText = ..EscapeHTML(xml.Text)
		}
		
		// Add the current token back into the current description
		Set tDescription = tDescription _ tCurrText
	}
	
	// Render the pre-processed description using the superclass
	Do ##super(pClass,tDescription,starttag,endtag)
}

}
