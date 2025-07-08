/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

/// This class contains methods used by the various
/// DeepSee code generators.<br/>
/// This class should be consider to be INTERNAL to DeepSee;
/// There are no methods intended for public use.
Class %DeepSee.Generator Extends %RegisteredObject [ System = 4 ]
{

/// Given a cube model, fill in a set of arrays with meta data 
/// about the named sets and calculated members for the cube.<br/>
ClassMethod %ProcessVirtualMembers(pCube As %DeepSee.Model.cube, Output pNamedSets As %List, Output pCalcMembers As %List, ByRef pCaptions As %String, ByRef pDescriptions As %String, ByRef pMemberList As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// calculated members
		For m=1:1:pCube.calculatedMembers.Count() {
			Set tMbr = pCube.calculatedMembers.GetAt(m)
			If (tMbr.disabled) {
				Continue
			}
			// WAL190 -- add tMbr.listingFilter in position 6
			Set pCalcMembers($$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)) = $LB(tMbr.dimension,tMbr.name,tMbr.valueExpression,tMbr.formatString,tMbr.hidden,tMbr.listingFilter)
			// + WAL065 -- don't overwrite dimension caption if this calculated member 
			//             belongs to a standard dimension
			If ('$D(pMemberList($$$UPPER(tMbr.dimension)))) {
				Set pCaptions($$$UPPER(tMbr.dimension)) = $LB(tMbr.dimension,tMbr.dimension)
				Set pDescriptions($$$UPPER(tMbr.dimension)) = $LB(tMbr.description) // + WAL124 -- same for descriptions
			}
			// - WAL065
			Set pCaptions($$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)) = $LB(tMbr.name,tMbr.displayName)
			Set pDescriptions($$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)) = $LB(tMbr.description)
		}

		// named sets
		For m=1:1:pCube.namedSets.Count() {
			Set tMbr = pCube.namedSets.GetAt(m)
			If (tMbr.disabled) {
				Continue
			}
			Set pNamedSets($$$UPPER(tMbr.name)) = $LB(tMbr.name,tMbr.setExpression)

			// use special %%NAMEDSETS dimension name
			Set pCaptions("%%NAMEDSETS",$$$UPPER(tMbr.name)) = $LB(tMbr.name,tMbr.displayName)
			Set pDescriptions("%%NAMEDSETS",$$$UPPER(tMbr.name)) = $LB(tMbr.description)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a cube model, fill in a set of arrays with meta data for the cube.<br/>
/// This meta data takes the form:<br/>
/// pDimIndex(dno,hno,lno) = $LB(mbrType,dimName,hierName,lvlName,factName,mbrClass,mbrField,...)<br/>
/// pDimIndex(dno,hno,lno,"opt",...) = member options (for time classes)<br/>
/// pDimIndex(dno,hno,lno,"prop",prop) = $LB("p",mbrClass,mbrField,propName,propType)<br/>
/// pDimIndex(dno,hno,lno,"mbr",mbr#) = $LB(mbrName,mbrSpec) (for explicit members)<br/>
/// pDimNames(dname,hname,lname) = $LB(dimNo,hierNo,lvlNo)<br/>
/// pFactIndex(factno)=factname<br/>
/// pFactInfo(factname...)<br/>
/// pStarInfo(starname...)<br/>
/// pMsrIndex(msrno)=msrname<br/>
/// pRelationInfo(relname...)<br/>
/// pRelIndex(relno)=relname<br/>
/// pCaptions(dname,hname,lname) = $LB(name,displayName)<br/>
/// pMeta(key) = value -- additional information ("hasAge").<br/>
/// pDependList(dno,hno,lno,tFactNo) -- dependOn info <br/>
/// pComputedDims(dname) -- indicates that this is a computed dimension<br/>
ClassMethod %BuildCubeInfo(pCube As %DeepSee.Model.cube, pSchema As %String, Output pDimIndex As %List, Output pDimNames As %List, ByRef pFactIndex As %String, Output pFactInfo As %List, Output pStarInfo As %List, ByRef pMsrIndex As %String, ByRef pRelationInfo As %String, ByRef pRelIndex As %String, ByRef pCaptions As %String, ByRef pMeta As %String, ByRef pDependList As %String, ByRef pComputedDims As %String, ByRef pDescriptions) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pDimIndex // index of members by ordinal position
		Kill pDimNames // index of members by name
		Kill pFactInfo
		Kill pStarInfo
		Kill pRelationInfo
		Kill pRelIndex
		Kill pMeta
		// pFactIndex // fact #s to names (could be passed in)
		// pMsrIndex // measure #s to names (could be passed in)
		Kill tActualFactNo // counter for allocated fact #s
		Kill pComputedDims

		//
		// <dimNo>: dimension #; 0 = "Measures" dimension.
		// <hierNo>: hierarchy #; 0 for dimension-level data;
		// <lvlNo>: level #; 0 for dim or hierarchy-level data;
		// pDimIndex(<dimNo>,<hierNo>,<lvlNo>) =
		//	$LB(<1:mbrType>,<2:dimName>,<3:hierName>,<4:lvlName>,<5:factNumber>,<6:mbrClass>,<7:mbrNameField>,<8:orderBy>,<9:rollUp>,<10:sortDir>,<11:hasMemberList>,<12:mbrKeyField>,<13:nullMarker>,<14:timeFormat>,<15:timeOffset>,<16:isList>,<17:hidden>,<18:showHierarchies>,<19:useAsFilter>)
		// or for measures:
		// pDimIndex(0,<msrNo>,0) =
		//	$LB("m","Measures",<3:msrName>,,<5:factName>,,<7:msrAggregate>,<8:msrType>,<9:msrScale>,,<11:hidden>,<12:format>,<13:searchable>,<14:sourceCube>,<15:listingFilterOperator>,<16:listingFilter>)
		//
		// mbrType can be: 	"h" - hierarchy
		// 					"d" - dimension, "m" - measure
		// 					"l" - level
		// 					"p" - level property (in subnode)
		//
		// pDimNames(<DIMNAME>,[<HIERNAME>],[<LVLNAME>]) =
		//		$LB(<dimNo>,<heirNo>,<lvlNo>)

		// walk down cube,
		// build list of dimensions
		// determine properties of the FACT table
		// and any STAR tables
		// Names of Fact properties are based on their
		// source fields

		Set tDimNo = 0

		#; add intrinsic "%SEARCH" dimension (hidden)
		#; this is to allow filtering on *searchable* measures
		Set tDimNo = tDimNo + 1
		Set tSMbrName = "%Search"
		Set pDimIndex(tDimNo,0,0) = $LB("d",tSMbrName)
		Set pCaptions($$$UPPER(tSMbrName)) = $LB(tSMbrName,tSMbrName)
		Set pDescriptions($$$UPPER(tSMbrName)) = $LB(tSMbrName)

		Set pDimIndex(tDimNo,1,0) = $LB("h",tSMbrName,tSMbrName,,,"%DeepSee.Query.memberComputed")
		Set pCaptions($$$UPPER(tSMbrName),$$$UPPER(tSMbrName)) = $LB(tSMbrName,tSMbrName)
		Set pDescriptions($$$UPPER(tSMbrName),$$$UPPER(tSMbrName)) = $LB(tSMbrName)

		Set pComputedDims($$$UPPER(tSMbrName)) = "%DeepSee.ComputedDimension.SQL"

		Set x = $I(pFactIndex)
		Set tSearchFactNo = $I(tActualFactNo)
		Set pDimIndex(tDimNo,1,1) = $LB("l",tSMbrName,tSMbrName,tSMbrName,tSearchFactNo,"%DeepSee.ComputedDimension.SQL","","","","","","",pCube.nullReplacement)
		Set pCaptions($$$UPPER(tSMbrName),$$$UPPER(tSMbrName),$$$UPPER(tSMbrName)) = $LB(tSMbrName,tSMbrName)
		Set pDescriptions($$$UPPER(tSMbrName),$$$UPPER(tSMbrName),$$$UPPER(tSMbrName)) = $LB(tSMbrName)

		Set pMeta("namedFactNums") = pCube.namedFactNums		// DTB886 - Log the setting for fixed fact numbers

		// now visit each defined dimension
		For d=1:1:pCube.dimensions.Count() {
			Set tDim = pCube.dimensions.GetAt(d)
			If (tDim.disabled) {
				Continue
			}
			Set tDimNo = tDimNo + 1
			Set tHasAll = tDim.hasAll
			If (tHasAll) {
				Set tAllName = $S(tDim.allCaption'="":tDim.allCaption,1:"All " _ tDim.name)
			}
			Else {
				Set tAllName = ""
			}

			Set pDimIndex(tDimNo,0,0) = $LB("d",tDim.name,,tAllName)
			If (tDim.hidden) {
				Set $List(pDimIndex(tDimNo,0,0),17) = 1
			}
			If ((tDim.showHierarchies'="")&&(tDim.showHierarchies'="default")) {
				Set $List(pDimIndex(tDimNo,0,0),18) = $S(tDim.showHierarchies="true":1,1:0)
			}

			Set pCaptions($$$UPPER(tDim.name)) = $LB(tDim.name,tDim.displayName)
			Set pDescriptions($$$UPPER(tDim.name)) = $LB(tDim.description) // JSL4475
			
			#; walk down hierarchies and levels
			Set tHierNo = 0
			Set tHierCount = tDim.hierarchies.Count()
			For h=1:1:tHierCount {
				Set tHier = tDim.hierarchies.GetAt(h)
				If (tHier.disabled) {
					Continue
				}
				Set tHierNo = tHierNo + 1
				Set tMbrClass = ""
				If ((tDim.type = "time")||(tDim.type = "age")) {
					Set tMbrClass = "%DeepSee.Query.memberTime"
				}
				ElseIf (tDim.type = "computed") {
					Set tMbrClass = "%DeepSee.Query.memberComputed"
				}
				
				// DTB283 - Hierarchies may now be hidden, but there must be more than 1 to do so!
				If (tHierCount=1)&&(tHier.hidden) {
					Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("'%1' is the only hierarchy in the dimension '%2' and may not be marked hidden",tHier.name,tDim.name))
					Quit
				}
				
				Set pDimIndex(tDimNo,tHierNo,0) = $LB("h",tDim.name,tHier.name,,,tMbrClass,,,,,,,,,,,tHier.hidden)
				Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tHier.name)) = $LB(tHier.name,tHier.displayName)
				Set pDescriptions($$$UPPER(tDim.name),$$$UPPER(tHier.name)) = $LB(tHier.description) // JSL4475
				
				// all level
				If (tHasAll) {
					Set pDimIndex(tDimNo,tHierNo,1) = $LB("all",tDim.name,tHier.name,tAllName)
					Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tAllName)) = $LB(tAllName,tDim.allDisplayName)
				}

				// process levels
				Set tRollupFact = "" // used to get rollup information
				Set tRollupField = ""
				Set tLevelCount = tHier.levels.Count()
				Set tLevelNo = $S(tHasAll:1,1:0)
				For lvl=1:1:tLevelCount {
					Kill tAssignedFactNum		// DTB945 - Clear any residual assigned fact number
					
					Set tLevel = tHier.levels.GetAt(lvl)
					If (tLevel.disabled) {
						Continue
					}
					
					// + DTB859 - [Validation] Check factNumber assignments against cube setting
					If (pCube.namedFactNums) {
						Set tLevelSpec = tDim.name _"."_ tHier.name _"."_ tLevel.name
						If 'tLevel.factNumber {
							$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number is required and unassigned to level: " _ tLevelSpec))
						}
						ElseIf '$IsValidNum(tLevel.factNumber) || (tLevel.factNumber '= (tLevel.factNumber\1)) {
							$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number must be an integer: " _ tLevelSpec _ " value: " _ tLevel.factNumber))
						}
						ElseIf '(tLevel.factNumber>=2) {
							$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number must have a value greater than 1: " _ tLevelSpec _ " value: " _ tLevel.factNumber))
						}
						Else {
							Set tAssignedFactNum = tLevel.factNumber
						}
					}
					// - DTB859
					
					Set tLevelNo = tLevelNo + 1
					Set tFactName = ""
					Set tMbrType = "l"
					Set tMbrSource = ""
					Kill tMbrOptions
					Set tTimeFunction = 0
					Set tSName = ""

					// get spec for this level, apply defaults
					Set tSourceProperty = tDim.sourceProperty
					Set tSourceExpression = tDim.sourceExpression
					// (local is an override in a shared dimension)
					Set tLocalSourceProperty = tDim.localSourceProperty
					Set tLocalSourceExpression = tDim.localSourceExpression
					Set tLevelClass = ""
					Set tContext = tDim.name_"."_tHier.name_"."_tLevel.name // used for error messages
					Set tFactName = ""
					Set tElName = ""
					Set tLevelFact = "" // passed onto next level

					// JMD910 test for dependsOn attribute
					If (tLevel.dependsOn'="") {
						// add to list; process later
						Set tDependsList(tDimNo,tHierNo,tLevelNo) = tLevel.dependsOn
					}

					// now get overrides from current level
					// preserve sourceProperty as the *names* have to be the same!
					Set tElName = tLevel.name
					Set:tLevel.sourceProperty'="" tSourceProperty = tLevel.sourceProperty
					Set:tLevel.sourceExpression'="" tSourceExpression = tLevel.sourceExpression
					Set:tLevel.localSourceProperty'="" tLocalSourceProperty = tLevel.localSourceProperty
					Set:tLevel.localSourceExpression'="" tLocalSourceExpression = tLevel.localSourceExpression

					Set tLevelClass = tLevel.timeFunction
					Set tLevelIsList = tLevel.list
					Set tLevelUseDisplay = +tLevel.useDisplayValue
					Set tLevelDelim = tLevel.listDelimiter
					Set tLevelNull = tLevel.nullReplacement
					Set tLevelRangeExpr = tLevel.rangeExpression
					Set tMemberList = tLevel.memberList
					Set tHasMemberList = 0
					Set tTimeOffset = tLevel.timeOffset
					Set tTimeFormat = tLevel.timeFormat

					// default null replacement is cube default or "" (which means we plug in a default at member processing time)
					Set tLevelNull = $S(tLevelNull'="":tLevelNull,pCube.nullReplacement'="":pCube.nullReplacement,1:"")

					Set tLinkClass = tLevel.linkClass
					Set tLinkProperty = tLevel.linkProperty
					
					// PFS097 - Throw error if list is defined and range expression is defined
					If (tLevelIsList) && (tLevelRangeExpr'="") {
						Set tSC=$$$ERROR($$$GeneralError,"List-Based Level cannot define a Range Expression: "_tElName)
						$$$ThrowStatus(tSC)
					}

					// process members defined for this level, if any
					Set tMbrNo = 0
					Set tMemberCount = tLevel.members.Count()
					For m = 1:1:tMemberCount {
						Set tMbr = tLevel.members.GetAt(m)
						If (tMbr.disabled) {
							Continue
						}
						Set tHasMemberList = 1
						Set tMbrNo = tMbrNo + 1
						Set tDisplayName=tMbr.displayName // JSL4431
						Set tDescription=tMbr.description // DTB219
						;Set:tDisplayName="" tDisplayName=tMbr.name // JSL4431 - note JSL4432 comments this line out to avoid cube recompilation
						Set pDimIndex(tDimNo,tHierNo,tLevelNo,"mbr",tMbrNo) = $LB(tMbr.name,tMbr.spec,tDisplayName,tDescription) // JSL4430 (use tDisplayName)
						// DP-247608 - return captions and descriptions of members
						Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name),$$$UPPER(tMbr.name)) = $LB(tMbr.name,tDisplayName)
						Set pDescriptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name),$$$UPPER(tMbr.name)) = $LB(tDescription)
						
						// DP-247608 - log which member names are defined to avoid conflict with properties
						Set tMembers(tDimNo,tHierNo,tLevelNo,$$$UPPER(tMbr.name)) = ""
					}
					
					// If the old memberList property is defined, fold it in
					If (tMemberList'="") {
						For m = 1:1:$L(tMemberList,",") {
							Set tMName = $P(tMemberList,",",m)
							If (tMName'="") {
								Set tHasMemberList = 1
								Set tMbrNo = tMbrNo + 1
								Set pDimIndex(tDimNo,tHierNo,tLevelNo,"mbr",tMbrNo) = $LB(tMName,"")
							}
						}
					}

					// process range expr and add items to memberList if no list defined
					If ((tLevelRangeExpr'="")&&('tHasMemberList)) {
						Set tSC = ##class(%DeepSee.Utils).%ParseRangeExpression(tLevelRangeExpr,.tRList)
					    If $$$ISERR(tSC) Quit
						Set j = $O(tRList(""))
						While (j'="") {
							Set tMName = $LG(tRList(j),6)
							If (tMName'="") {
								Set tHasMemberList = 1
								Set tMbrNo = tMbrNo + 1
								Set pDimIndex(tDimNo,tHierNo,tLevelNo,"mbr",tMbrNo) = $LB(tMName,"")
							}
							Set j = $O(tRList(j))
						}
						// JMD1408: add null entry
						If $D(tRList)&&(tLevelNull'="") {
							Set tMbrNo = tMbrNo + 1
							Set pDimIndex(tDimNo,tHierNo,tLevelNo,"mbr",tMbrNo) = $LB(tLevelNull,"<null>")
						}
					}

					// create facts and star table info according to spec

					// create base fact for this level
					// JMD1329: avoid creating facts for MDX/Computed dimensions
					// do this by using a dummy fact name in this case
					Set tMDXComputed = 0
					If ((tDim.type = "computed")&&(tDim.dimensionClass'="")) {
						Set tMDXComputed = ($classmethod(tDim.dimensionClass,"%GetBehavior")="MDX")
					}
					If (tMDXComputed) {
						Set tFactName = "$MDXCOMPUTED"
					}
					Else { 
						Set tFactName = ..%GetFactName("Dx",tElName,tSourceProperty,tSourceExpression,,tLevelRangeExpr,tLinkClass,tLinkProperty)
					}

					// BDB429 - Avoid fact name conflicts for duplicate iKnow dimension level names,
					// as the fact name would just be based on the level's name, which is not 
					// necessarily unique across dimensions.
					if (tDim.iKnowMeasure'="") {
						while $d(pFactInfo("prop",tFactName)) {
							set tFactName = tFactName_$i(tAliasCounter)
						}
					}
					
					// JMD847
					// if there are 2 identical facts but with different "factNames"
					// give one a different name to avoid conflict!
					If $D(pFactInfo("prop",tFactName,"alias")) {
						Set tFactName = tFactName_$I(tAliasCounter)
					}
					
					Do AddFact(tFactName,,tLevel.factName,tDim.type)
					Set tLevelFact = tFactName
					Set tLevelFieldName = $S(tLevel.factName="":tFactName,1:tLevel.factName)
					Set:($G(tDimNo)'="") pFactInfo("prop",tFactName,"dimNo") = tDimNo			// DTB567 - Store complete level information
					Set:($G(tHierNo)'="") pFactInfo("prop",tFactName,"hierNo") = tHierNo		// DTB567
					Set pFactInfo("prop",tFactName,"levelNo") = tLevelNo

					// JMD878 selectivity
					Set:(tLevel.factSelectivity'="") pFactInfo("prop",tFactName,"parms","SELECTIVITY") = tLevel.factSelectivity

					Set:tLocalSourceExpression'="" pFactInfo("prop",tFactName,"localExpr") = tLocalSourceExpression
					Set:tLocalSourceProperty'="" pFactInfo("prop",tFactName,"localSource") = tLocalSourceProperty

					// determine more details on the fact
					If (tSourceExpression'="") {
						// expression takes precedence over sourceProperty
						Set pFactInfo("prop",tFactName,"expr") = tSourceExpression
						Set:tLevel.castAsNumeric pFactInfo("prop",tFactName,"sourceType") = "NUMERIC"		// DTB243
					}
					Else {
						Set pFactInfo("prop",tFactName,"source") = tSourceProperty

						// test for different date types
						If (tSourceProperty'="") {
							Set tDType = ..%GetPropertyType(.tSC, .mvp, pCube.sourceClass,$S(tLocalSourceProperty'="":tLocalSourceProperty,1:tSourceProperty),tDim.name_"."_tHier.name_"."_tLevel.name)
							Quit:$$$ISERR(tSC)

							Set tDType = $$$NormalizeClassname(tDType)
							If ($$$getClassType(tDType) = "datatype") {
								Set tClientType = $$$comClassKeyGet(tDType,$$$cCLASSclientdatatype)
								If ("MVDATE"=tClientType) {
		   							Set pFactInfo("prop",tFactName,"dateType") = "MVDATE"
								}
								ElseIf ("FTIMESTAMP"=tClientType) {
		   							Set pFactInfo("prop",tFactName,"dateType") = "FTIMESTAMP"
								}
								ElseIf ("FDATE"=tClientType) {
		   							Set pFactInfo("prop",tFactName,"dateType") = "FDATE"
								}
								ElseIf ("TIMESTAMP"=tClientType) {
		   							Set pFactInfo("prop",tFactName,"dateType") = "TIMESTAMP"
								}
								ElseIf ("TIME"=tClientType) {
		   							Set pFactInfo("prop",tFactName,"dateType") = "TIME"
								}
								ElseIf ("DECIMAL"=tClientType) ||		// DTB243 - Add numeric source types to metadata
										("DOUBLE"=tClientType) ||
										("FLOAT"=tClientType) ||
										("INTEGER"=tClientType) ||
										("NUMERIC"=tClientType) {		
									Set pFactInfo("prop",tFactName,"sourceType") = tClientType
								}
							}
						}
					}

					If ((tDim.type = "time")||(tDim.type = "age")) {
						If (tDim.type = "time") {
							If tDim.calendar="partial" {
								Set pFactInfo("prop",tFactName,"type") = "%String"		// DTB - Property type needs to accommodate partial dates
							}
							Else {
   								Set pFactInfo("prop",tFactName,"type") = "%DeepSee.Datatype.dateTime"
							}
						}
						Else {
							Set pMeta("hasAge") = 1
   							Set pFactInfo("prop",tFactName,"type") = "%Integer"
						}
						// For time dimensions source is a time level class
						Set tSC = ..%ParseTimeFunction(tLevel.timeFunction,.tFuncName,.tOptions)
						Quit:$$$ISERR(tSC)

						Set tMbrSource = $G(pCube.%timeFunctions(tDim.calendar,$$$UPPER(tFuncName)))		// DTB177 - Look up time function by calendar
						Merge tMbrOptions = tOptions
						Set tTimeFunction = 1
					}
					ElseIf (tDim.type = "computed") {
						// no star table for computed
						Set tMbrSource = tDim.dimensionClass
   						Set pFactInfo("prop",tFactName,"type") = "$none"
						// JMD890: if we are linked to an iKnow measure, note that
						If (tDim.iKnowMeasure'="") {
	 						Set pFactInfo("prop",tFactName,"iKnowMsr") = tDim.iKnowMeasure
						}
						// JMD1329: note that this is a computed dimension
						Set pComputedDims($$$UPPER(tDim.name)) = tDim.dimensionClass
					}
					Else {
						Set pFactInfo("prop",tFactName,"index") = "bitmap"
						Set pFactInfo("prop",tFactName,"mbrtype") = "d"

						// test for shared dimension
						Set tShared = tDim.sharesFrom

						// create star table for fact to refer to
						Set tCollation = $Case(tLevel.sort,"desc numeric":"exact","asc numeric":"exact",:"")
						Set tSC = ..%AddStarTable(pCube,tShared,pSchema,.pStarInfo,.tSName,pCube.sourceClass,tLevel.name,tSourceProperty,tSourceExpression,tLinkClass,tLinkProperty,tLevelRangeExpr,tLevel.factName,tContext,tCollation)
						Quit:$$$ISERR(tSC)

   						Set pFactInfo("prop",tFactName,"type") = tSName
						Set tMbrSource = tSName
						Kill tMbrOptions

						// indicate that this is a star table
   						Set pFactInfo("prop",tFactName,"star") = 1

						// add rollup to star table
						If (tRollupFact '= "") {
							Set tRollType = $G(pFactInfo("prop",tRollupFact,"type"))
							Set tSC = ..%AddRollupToStar(tSName,tRollupFact,.pFactInfo,.pStarInfo,tContext)
							Quit:$$$ISERR(tSC)
						}
					}

					// is there a function defined?
					If (tTimeFunction) {
						Set tFactNameBase = tFactName
						Set tFuncName = "%Convert"
						// N.b. this *requires* time/age class names to be unique within a given calendar
						Set tFactFuncName = $P(tMbrSource,".",$L(tMbrSource,"."))

						// add additional derived Fact to support this level
						Set tFxFactName = ..%GetFactName("Dx",tElName,tSourceProperty,tSourceExpression,tFactFuncName,tLevelRangeExpr,,,tTimeOffset)
						Set tCalendarCode = $$$dsCodeCalendar(tDim.calendar)
						Set:(tCalendarCode'="G") tFxFactName = tFxFactName _ "Cx" _ tCalendarCode		// DTB181 - Add a calendar code for Hijri calendars.		// DTB - Add calendar code for partial dates
						Do AddFact(tFxFactName,,tLevel.factName)

						Set:($G(tDimNo)'="") pFactInfo("prop",tFxFactName,"dimNo") = tDimNo			// DTB840 - record dimNo
						Set:($G(tHierNo)'="") pFactInfo("prop",tFxFactName,"hierNo") = tHierNo		// DTB840 - record hierNo
						Set pFactInfo("prop",tFxFactName,"levelNo") = tLevelNo						// DTB840 - Use the current level number

						// JMD selectivity
						Set:(tLevel.factSelectivity'="") pFactInfo("prop",tFxFactName,"parms","SELECTIVITY") = tLevel.factSelectivity

						// fact needs function
						Set tDimClass = tMbrSource
						Set tRetType = "%Integer"

						If (tRetType '= "") {
							// inject the function into the Fact class
							Set tFunctions(tFuncName) = tDimClass

							Set pFactInfo("prop",tFxFactName,"type") = tRetType
							Set pFactInfo("prop",tFxFactName,"source") = tSourceProperty
							Set pFactInfo("prop",tFxFactName,"index") = "bitmap"
							Set pFactInfo("prop",tFxFactName,"mbrtype") = "d"

							// info for sql compute
							Set pFactInfo("prop",tFxFactName,"function") = tFuncName
							Set pFactInfo("prop",tFxFactName,"functionClass") = tDimClass
							Merge pFactInfo("prop",tFxFactName,"options") = tMbrOptions
							Set pFactInfo("prop",tFxFactName,"base") = tFactNameBase
							Set pFactInfo("prop",tFxFactName,"isTime") = 1
							
							// PFS039 - Add Shared Dimension local overrides to time levels
							Set:tLocalSourceExpression'="" pFactInfo("prop",tFxFactName,"localExpr") = tLocalSourceExpression
							Set:tLocalSourceProperty'="" pFactInfo("prop",tFxFactName,"localSource") = tLocalSourceProperty

							Set:tTimeOffset'="" pFactInfo("prop",tFxFactName,"timeOffset") = tTimeOffset

							If (tDim.type = "age") {
								// treat age property as a ref so that we always
								// retest axis value that use it.
								Set pMeta("hasAge") = 1
								Set pFactInfo("prop",tFxFactName,"hasref") = 1
							}

							Set tFactName = tFxFactName // associate this member with new fact
						}
						Else {
							Set tSC = $$$ERROR($$$GeneralError,"Unable to find function for level (1):" _ tContext _ "->" _ tTimeFunction)
							Quit
						}
					}

					// link fact to member
					If (tLevelIsList) {
						Set pFactInfo("prop",tFactName,"list") = 1
						Set:tLevelDelim'="" pFactInfo("prop",tFactName,"listDelimiter") = tLevelDelim
						Set pFactInfo("prop",tFactName,"index") = "bitmap"
						Set pFactInfo("prop",tFactName,"mbrtype") = "d"
					}

					If ((tFactName'="")&&(tLevelUseDisplay)) {
						Set pFactInfo("prop",tFactName,"useDisplay") = 1
					}
					If ((tFactName'="")&&(tLevelRangeExpr '= "")) {
						Set pFactInfo("prop",tFactName,"rangeExpr") = tLevelRangeExpr
					}

					If (tLinkClass'="") {
						Set pFactInfo("prop",tFactName,"linkClass") = tLinkClass
						Set pFactInfo("prop",tFactName,"linkProperty") = tLinkProperty
					}

					// process member properties for this level, if any
					Set tDisplayBy = ""
					Set tSortBy = ""
					Set tSortDir = ""
					Set tPropCount = tLevel.properties.Count()
					For p = 1:1:tPropCount {
						Set tProp = tLevel.properties.GetAt(p)
						If (tProp.disabled) {
							Continue
						}

						If $D(tMembers(tDimNo,tHierNo,tLevelNo,$$$UPPER(tProp.name))) {
							// DP-247608 - Report an identifier conflict between members and properties in this level
							Set tPropertySpec = $$$UPPER(tDim.name)_"."_$$$UPPER(tHier.name)_"."_$$$UPPER(tLevel.name)_"."_$$$UPPER(tProp.name)
							Set tSC = $$$ERROR($$$GeneralError,"Members and properties within the same level may not share an identifier:"_tPropertySpec)
							$$$ThrowStatus(tSC)
						}

						// special case for internal/external values
						// prevent name conflict between property and level
						If (tProp.useDisplayValue && (tProp.factName="") && (tSourceProperty = tProp.sourceProperty)) {
							Set tProp.factName = tFactName_"Ext"
						}

						// JMD840: special case for linkProperty
						// prevent name conflict between property and level
						If ((tProp.factName="") && (tSourceProperty = tProp.sourceProperty) && (tLinkClass = tProp.linkClass)  && (tLinkProperty '= tProp.linkProperty)) {
							Set tProp.factName = tFactName_"Link"
						}

						Set tCollation = $Case(tProp.sort,"desc numeric":"exact","asc numeric":"exact",:"")
						If (tShared="") {
							Set tSC = ..%AddPropertyToStar(tSName, tProp.name, .pStarInfo, .tStarProp, pCube.sourceClass, tProp.sourceProperty,tProp.sourceExpression,tProp.isReference,tLinkClass,tLinkProperty,tLevelRangeExpr,tProp.factName,tContext,tCollation)
							If $$$ISERR(tSC) Quit
						}
						Else {
							// JMD935
							Set:tProp.localSourceProperty="" tProp.localSourceProperty = tProp.sourceProperty
							Set:tProp.localSourceExpression="" tProp.localSourceExpression = tProp.sourceExpression

							Set tSC = ..%AddPropertyToStar(tSName, tProp.name, .pStarInfo, .tStarProp, pCube.sourceClass, tProp.localSourceProperty,tProp.localSourceExpression,tProp.isReference,tLinkClass,tLinkProperty,tLevelRangeExpr,tProp.factName,tContext,tCollation)
							If $$$ISERR(tSC) Quit
						}

						// add "virtual" fact for this property
						Do AddFact(tStarProp,1,tProp.factName)
						Set tFieldName = $S(tProp.factName="":tStarProp,1:tProp.factName)

						If (tProp.isName) {
							Set tDisplayBy = tFieldName
							If ($G(pStarInfo(tSName,"prop",tStarProp,"use")) '= "key") {
								// do not let name override key
								// this should not get past earlier validation!
								Set pStarInfo(tSName,"prop",tStarProp,"use") = "name"
							}
						}
						If (tProp.isDescription) {
							If ($G(pStarInfo(tSName,"prop",tStarProp,"use")) '= "key") {
								// do not let description override key
								// this should not get past earlier validation!
								Set pStarInfo(tSName,"prop",tStarProp,"use") = "description"
							}
						}
						If (tProp.sort'="") {
							Set tSD = $Case(tProp.sort,"asc":"asc","desc":"desc","desc numeric":"desc#","asc numeric":"asc#",:"")
							Set tSortBy = tSortBy _ $S(tSortBy="":"",1:",") _ tFieldName
							Set tSortDir = tSortDir _ $S(tSortDir="":"",1:",") _ tSD
						}

						Set pFactInfo("prop",tStarProp,"type") = $G(pStarInfo(tSName,"prop",tStarProp,"type"))
						Merge pFactInfo("prop",tStarProp,"parms") = pStarInfo(tSName,"prop",tStarProp,"parms")

						// JMD909
						If (tProp.formatString'="") {
							Set pStarInfo(tSName,"prop",tStarProp,"format") = tProp.formatString
						}

						If (tProp.useDisplayValue) {
							Set pFactInfo("prop",tStarProp,"useDisplay") = 1
						}

						If (tProp.sourceExpression '= "") {
							Set pFactInfo("prop",tStarProp,"expr") = tProp.sourceExpression
						}
						Else {
							Set pFactInfo("prop",tStarProp,"source") = tProp.sourceProperty
						}

						Set:tProp.localSourceExpression'="" pFactInfo("prop",tStarProp,"localExpr") = tProp.localSourceExpression
						Set:tProp.localSourceProperty'="" pFactInfo("prop",tStarProp,"localSource") = tProp.localSourceProperty

						If (tProp.linkClass'="") {
							Set pFactInfo("prop",tStarProp,"linkClass") = tProp.linkClass
							Set pFactInfo("prop",tStarProp,"linkProperty") = tProp.linkProperty
						}

						If (tProp.isReference) {
							// note this property *is* a reference
							// and that this level *has* a reference
							Set pFactInfo("prop",tFactName,"hasref") = 1
							Set pFactInfo("prop",tStarProp,"isref") = 1
						}

						Set pDimIndex(tDimNo,tHierNo,tLevelNo,"prop",$$$UPPER(tProp.name)) = $LB("p",tSName,tStarProp,tProp.name,$G(pStarInfo(tSName,"prop",tStarProp,"type")),$G(pStarInfo(tSName,"prop",tStarProp,"format")))
						Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name),$$$UPPER(tProp.name)) = $LB(tProp.name,tProp.displayName)
						Set pDescriptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name),$$$UPPER(tProp.name)) = $LB(tProp.description) // JSL4475
						If (tProp.hidden) {
							Set $List(pDimIndex(tDimNo,tHierNo,tLevelNo,"prop",$$$UPPER(tProp.name)),17) = 1
						}
					}

					// if no display field, use key field
					If (tDisplayBy = "") {
						Set tDisplayBy = tLevelFieldName
					}

					// add details on this member to the metadata
					If ($$FactNo(tFactName) < 0) {
						// JMD1329: no real fact for mdx/computed
						If (tFactName'="$MDXCOMPUTED") {
							// assign a real fact number
							Set tActualNo = $S($G(tAssignedFactNum)'="":tAssignedFactNum,1:$I(tActualFactNo))		// DTB859 - Use the assigned number if defined
							Kill pFactIndex($$FactNo(tFactName))
							Set pFactIndex(tActualNo) = tFactName
							Set pFactInfo("prop",tFactName) = tActualNo
						}
					}

					// if no sort direction, apply default from level
					If (tSortDir="") {
						Set tSortDir = $Case(tLevel.sort,"asc":"asc","desc":"desc","desc numeric":"desc#","asc numeric":"asc#",:"")
					}

					// JMD938: pass sortBy along so we can create an index on it
					Set:((tSName'="")&&(tSortBy'="")) pStarInfo(tSName,"sortBy") = tSortBy

					// DTB283 - Levels may now be hidden, but there must be more than 1 to do so!
					If (tLevelCount=1)&&(tLevel.hidden) {
						Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("'%1' is the only level in the hierarchy '%2' and may not be marked hidden",tLevel.name,tDim.name_"."_tHier.name))
						Quit
					}

					Set pDimIndex(tDimNo,tHierNo,tLevelNo) = $LB(tMbrType,tDim.name,tHier.name,tLevel.name,$$FactNo(tFactName),tMbrSource,tDisplayBy,tSortBy,tRollupField,tSortDir,$S(tHasMemberList:1,1:""),tLevelFieldName,tLevelNull,tTimeFormat,tTimeOffset,tLevelIsList,tLevel.hidden,,tLevel.useAsFilter)
					Merge pDimIndex(tDimNo,tHierNo,tLevelNo,"opt") = tMbrOptions

					Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name)) = $LB(tLevel.name,tLevel.displayName)
					Set pDescriptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name)) = $LB(tLevel.description) // JSL4475

					// remember current fact for next level
					If ((tDim.type '= "time")&&(tDim.type '= "age")) {
						If (tLevelFact '= "") {
							Set tRollupFact = tLevelFact
							Set tRollupField = tLevelFieldName
						}
					}
				} // for lvl
				Quit:$$$ISERR(tSC)
			} // for hier
			Quit:$$$ISERR(tSC)
		} // for dim
		Quit:$$$ISERR(tSC)
		
		// DTB945 - Clear the local variable before proceeding to other elements, which will each be 
		// responsible for setting assigned fact numbes for themselves.
		Kill tAssignedFactNum		

		#; now get measures (these are not in pCube.dimensions)
		Set tMsrNo = 0

		#; add intrinsic "%COUNT" measure
		Set tMsrNo = tMsrNo + 1
		Set pDimIndex(0,0,0) = $LB("d","Measures")
		Set tCountName = pCube.countMeasureName
		Set:tCountName="" tCountName = "%COUNT"
		Set pDimIndex(0,tMsrNo,0) = $LB("m","Measures",tCountName,,"",,"COUNT","integer",0,,0)

		#; JMD1497 set def format for %COUNT
		Set $List(pDimIndex(0,tMsrNo,0),12) = "#,###"

		For m=1:1:pCube.measures.Count() {
			Set tMsr = pCube.measures.GetAt(m)
			If (tMsr.disabled) {
				Continue
			}
			
			// + DTB859 - [Validation] Check fctNumber assignments against cube setting
			If (pCube.namedFactNums) {
				If 'tMsr.factNumber {
					$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number is required and unassigned to measure: " _ tMsr.name))
				}
				ElseIf '$IsValidNum(tMsr.factNumber) || (tMsr.factNumber '= (tMsr.factNumber\1)) {
					$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number must be an integer: " _ tMsr.name _ " value: " _ tMsr.factNumber))
				}
				Else {
					Set tAssignedMsrNum = tMsr.factNumber
				}
			}
			// - DTB859
			
			Set tSourceProperty = tMsr.sourceProperty
			Set tSourceExpression = tMsr.sourceExpression
			Set tMsrType = ""
			Set tScale = 0
			Kill tFParms
			Set tMsrDataType = ""
			Set tMsrIndexType = ""
			Set tScaleName = ""
			Set tTypeName = ""
			Set tMsrHidden = +tMsr.hidden
			Set tLinkClass = tMsr.linkClass
			Set tLinkProperty = tMsr.linkProperty
			Set tMsrDateType = ""
			Set tMsrFormat = tMsr.formatString

			// JMD878 selectivity
			Set:(tMsr.factSelectivity'="") tFParms("SELECTIVITY") = tMsr.factSelectivity

			// compute characteristics first, then find fact name
			Set tNeedType = 1
			If (tLinkClass'="") {
			}
			ElseIf (tSourceExpression'="") {
				Set tNeedType = 0
				// expression takes precedence over sourceProperty
				// n.b. we *could* analyze the expression to find the default type
				// but let's leave this up to the cube designer
				Set tDefType = "number"
				If ((tMsr.type = "number")||(tMsr.type = "")) {
					Set tMsrType = "number"
					Set tScale = tMsr.scale
					If (tScale = "") {
						Set tScale = 2 // default
					}
					ElseIf (tScale '= 2) {
						Set tScaleName = "Sx" _ tScale
					}
					Set tMsrDataType = "%Double"
					Set tMsrIndexType = "bitslice"
					Set tFParms("SCALE") = tScale
					// JMD1502
					If (tMsrFormat="") {
						Set tMsrFormat = "#,###"_$S(tScale>0:"."_$TR($J(" ",tScale)," ","#"),1:"")
					}
				}
				ElseIf (tMsr.type = "integer") {
					Set tMsrType = "integer"
					Set tScale = 0
					Set tMsrDataType = "%Integer"
					Set tMsrIndexType = "bitslice"
					// JMD1502
					If ((tMsrFormat="")&&(tMsr.aggregate = "AVG")) {
						Set tMsrFormat = "#,###.##"
					}
				}
				ElseIf (tMsr.type = "boolean") {
					Set tMsrType = "boolean"
					Set tScale = 0
					Set tMsrDataType = "%Boolean"
					Set tMsrIndexType = "bitmap"
				}
				ElseIf (tMsr.type = "date") {
					Set tMsrType = "date"
					Set tScale = 0
					Set tMsrDataType = "%DeepSee.Datatype.dateTime"
					Set tMsrIndexType = "bitslice"
				}
				ElseIf (tMsr.type = "age") {
					Set tMsrType = "age"
					Set tScale = 0
					Set tMsrDataType = "%Integer"
					Set tMsrIndexType = "bitslice"
				}
				ElseIf (tMsr.type = "text") {
					Set tMsrType = "text"
					Set tScale = 0
					Set tMsrDataType = "%Text"
					Set tMsrIndexType = "text"
					Set tFParms("MAXLEN") = 32000
					Set tMsrHidden = 1 // hide text measures
				}
				ElseIf (tMsr.type = "iKnow") {
					Set tMsrType = tMsr.type
					Set tScale = 0
					Set tMsrDataType = "%String"
					Set tFParms("MAXLEN") = 32000
					// tack on source type
					Set tMsrIndexType = tMsr.type_":"_tMsr.iKnowSource
					
					// BDB260: append domain name and user-defined domain parameters
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDomain
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDictionaries
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowParameters
					Set tMsrHidden = 1 // hide text measures
				}
				Else {
					Set tMsrType = "string"
					Set tScale = 0
					Set tMsrDataType = "%String"
					Set tMsrIndexType = "$none"
					Set tFParms("MAXLEN") = 32000
					Set tMsrHidden = 1 // hide string measures
				}

				If (tMsrType '= tDefType) {
					Set tTypeName = $Case(tMsrType,"date":"D","age":"AD","integer":"I","number":"N","boolean":"B","string":"S","text":"T","iKnow":"iK",:"")
				}
			}
			ElseIf (tSourceProperty = "") {
				Set tNeedType = 0
				Set tDefType = "number"
				If ((tMsr.type = "number")||(tMsr.type = "")) {
					Set tMsrType = "number"
					Set tScale = tMsr.scale
					If (tScale = "") {
						Set tScale = 2 // default
					}
					ElseIf (tScale '= 2) {
						Set tScaleName = "Sx" _ tScale
					}
					Set tMsrDataType = "%Double"
					Set tMsrIndexType = "bitslice"
					Set tFParms("SCALE") = tScale
					// JMD1502
					If (tMsrFormat="") {
						Set tMsrFormat = "#,###"_$S(tScale>0:"."_$TR($J(" ",tScale)," ","#"),1:"")
					}
				}
				ElseIf (tMsr.type = "integer") {
					Set tMsrType = "integer"
					Set tScale = 0
					Set tMsrDataType = "%Integer"
					Set tMsrIndexType = "bitslice"
					// JMD1502
					If ((tMsrFormat="")&&(tMsr.aggregate = "AVG")) {
						Set tMsrFormat = "#,###.##"
					}
				}
				ElseIf (tMsr.type = "boolean") {
					Set tMsrType = "boolean"
					Set tScale = 0
					Set tMsrDataType = "%Boolean"
					Set tMsrIndexType = "bitmap"
				}
				ElseIf (tMsr.type = "date") {
					Set tMsrType = "date"
					Set tScale = 0
					Set tMsrDataType = "%DeepSee.Datatype.dateTime"
					Set tMsrIndexType = "bitslice"
				}
				ElseIf (tMsr.type = "age") {
					Set tMsrType = "age"
					Set tScale = 0
					Set tMsrDataType = "%Integer"
					Set tMsrIndexType = "bitslice"
				}
				ElseIf (tMsr.type = "text") {
					Set tMsrType = "text"
					Set tScale = 0
					Set tMsrDataType = "%Text"
					Set tMsrIndexType = "text"
					Set tFParms("MAXLEN") = 32000
					Set tMsrHidden = 1 // hide text measures
				}
				ElseIf (tMsr.type = "iKnow") {
					Set tMsrType = tMsr.type
					Set tScale = 0
					If (tMsr.type = "stream") {
						Set tMsrDataType = "%GlobalCharacterStream"
					}
					Else {
						Set tMsrDataType = "%String"
						Set tFParms("MAXLEN") = 32000
					}
					// tack on source type
					Set tMsrIndexType = tMsr.type_":"_tMsr.iKnowSource
					
					// BDB260: append domain name and user-defined domain parameters
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDomain
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDictionaries
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowParameters
					Set tMsrHidden = 1 // hide text measures
				}
				Else {
					Set tMsrType = "string"
					Set tScale = 0
					Set tMsrDataType = "%String"
					Set tMsrIndexType = "$none"
					Set tFParms("MAXLEN") = 32000
					Set tMsrHidden = 1 // hide string measures
				}
				If (tMsrType '= tDefType) {
					Set tTypeName = $Case(tMsrType,"date":"D","age":"AD","integer":"I","number":"N","boolean":"B","string":"S","text":"T","iKnow":"iK",:"")
				}
			}

			// if we have not yet found the type, do it now
			If (tNeedType) {
				// Find type of source field
				// Make sure it is a literal type
				If (tLinkClass'="") {
					Set tFType = ..%GetPropertyType(.tSC, .p, tLinkClass,tLinkProperty,"Measures."_tMsr.name)
					Quit:$$$ISERR(tSC)
				}
				Else {
					Set tFType = ..%GetPropertyType(.tSC, .p, pCube.sourceClass,tSourceProperty,"Measures."_tMsr.name)
					Quit:$$$ISERR(tSC)
				}
				Merge tFParms = p // fold in defaults from property
				Set tFType = $$$NormalizeClassname(tFType)
				Set tFClsType = $$$getClassType(tFType)
				If (tFClsType = "datatype") {
					// use client type to determine *real* type of datatype
					Set tClientType = $$$comClassKeyGet(tFType,$$$cCLASSclientdatatype)
					If ("MVDATE"=tClientType) {
						Set tMsrDateType = "MVDATE"
					}
					ElseIf ("FDATE"=tClientType) {
						Set tMsrDateType = "FDATE"
					}
					ElseIf ("FTIMESTAMP"=tClientType) {
						Set tMsrDateType = "FTIMESTAMP"
					}
					ElseIf ("TIMESTAMP"=tClientType) {
						Set tMsrDateType = "TIMESTAMP"
					}
					ElseIf ("TIME"=tClientType) {
						Set tMsrDateType = "TIME"
					}

					Set tDefType = $Case(tClientType,"DOUBLE":"number","NUMERIC":"number","CURRENCY":"number","INTEGER":"integer","BOOLEAN":"boolean","DATE":"date","MVDATE":"date","FDATE":"date","FTIMESTAMP":"date","TIMESTAMP":"date","TIME":"date",:"string")
					If ((tMsr.type="number")||((tMsr.type="")&&((tClientType = "DOUBLE")||(tClientType = "NUMERIC")||(tClientType = "CURRENCY")))) {
						// Unless specified, use scale from source property
						// JMD1486
						Set tDefScale=2
						If (tClientType="CURRENCY") {
							Set tDefScale=4
						}
						Set tScale = $S(tMsr.scale="":$G(tFParms("SCALE"),tDefScale),1:tMsr.scale)
						If ((tMsr.scale'="")&&(tScale '= $G(tFParms("SCALE"),tDefScale))) {
							Set tScaleName = "Sx" _ tScale
						}
						Set tFParms("SCALE") = tScale
						Kill tFParms("MAXLEN")
						Set tMsrType = "number"
						Set tMsrDataType = $Case(tClientType,"NUMERIC":"%Numeric","CURRENCY":"%Currency",:"%Double")
						Set tMsrIndexType = "bitslice"
						// JMD1502
						If (tMsrFormat="") {
							Set tMsrFormat = "#,###"_$S(tScale>0:"."_$TR($J(" ",tScale)," ","#"),1:"")
						}
					}
					ElseIf ((tMsr.type="integer")||((tMsr.type="")&&(tClientType = "INTEGER"))) {
						Set tScale = 0
						Set tMsrType = "integer"
						Kill tFParms("SCALE")
						Kill tFParms("MAXLEN")
						Set tMsrDataType = "%Integer"
						Set tMsrIndexType = "bitslice"
						// JMD1502
						If ((tMsrFormat="")&&(tMsr.aggregate = "AVG")) {
							Set tMsrFormat = "#,###.##"
						}
					}
					ElseIf ((tMsr.type = "boolean")||((tMsr.type="")&&(tClientType = "BOOLEAN"))) {
						Set tMsrType = "boolean"
						Set tScale = 0
						Kill tFParms("SCALE")
						Set tMsrDataType = "%Boolean"
						Set tMsrIndexType = "bitmap"
					}
					ElseIf ((tMsr.type="date")||((tMsr.type="")&&((tClientType = "DATE")||(tClientType = "MVDATE")||(tClientType = "FDATE")||(tClientType = "FTIMESTAMP")||(tClientType = "TIMESTAMP")||(tClientType = "TIME")))) {
						Set tScale = 0
						Set tMsrType = "date"
						Kill tFParms("SCALE")
						Kill tFParms("MAXLEN")
						Set tMsrDataType = "%DeepSee.Datatype.dateTime"
						Set tMsrIndexType = "bitslice"
					}
					ElseIf ((tMsr.type="age")) {
						Set tScale = 0
						Set tMsrType = "age"
						Kill tFParms("SCALE")
						Kill tFParms("MAXLEN")
						Set tMsrDataType = "%Integer"
						Set tMsrIndexType = "bitslice"
					}
					ElseIf ((tMsr.type="text")) {
						Set tScale = 0
						Kill tFParms("SCALE")
						Kill tFParms("MAXVAL")
						Kill tFParms("MINVAL")
						Set tMsrType = "text"
						Set tMsrDataType = "%Text"
						Set tMsrIndexType = "text"
						Set tMsrHidden = 1 // hide text measures
					}
					ElseIf ((tMsr.type="iKnow")) {
						Set tScale = 0
						Kill tFParms
						Set tMsrType = tMsr.type
						If (tMsr.iKnowSource = "stream") {
							Set tMsrDataType = "%GlobalCharacterStream"
						}
						Else {
							Set tMsrDataType = "%String"
							Set tFParms("MAXLEN") = 32000
						}
						// tack on source type
						Set tMsrIndexType = tMsr.type_":"_tMsr.iKnowSource
						
						// BDB260: append domain name and  user-defined domain parameters
						Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDomain
						Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDictionaries
						Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowParameters
						Set tMsrHidden = 1 // hide text measures
					}
					Else {
						Set tScale = 0
						Kill tFParms("SCALE")
						Kill tFParms("MAXVAL")
						Kill tFParms("MINVAL")
						Set tMsrType = "string"
						Set tMsrDataType = "%String"
						Set tMsrIndexType = "$none"
						Set tMsrHidden = 1 // hide string measures
					}

					If (tMsrType '= tDefType) {
						Set tTypeName = $Case(tMsrType,"date":"D","age":"AD","integer":"I","number":"N","boolean":"B","string":"S",:"")
					}
				}
				ElseIf (tFClsType="stream") && (tMsr.type="iKnow") && (tMsr.iKnowSource="stream") {
					Set tScale = 0
					Kill tFParms
					Set tMsrType = tMsr.type
					Set tMsrDataType = tFType
					Set tMsrIndexType = tMsr.type_":"_tMsr.iKnowSource
					
					// BDB260: append domain name and user-defined domain parameters
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDomain
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowDictionaries
					Set tMsrIndexType = tMsrIndexType _ ":" _ tMsr.iKnowParameters
					Set tMsrHidden = 1 // hide text measures
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"The source type for a measure must be a literal value: " _ "Measures." _ tMsr.name _ ":" _ tMsr.sourceProperty)
					Quit
				}
			}
			
			// + WAL190
			Set tListingFilter = tMsr.listingFilterValue  // WAL222
			Set tListingFilterOperator = tMsr.listingFilterOperator
			// - WAL190

			// create fact for measure
			Set tAggregate = ""

			// validate and/or determine aggregate for this measure
			If ((tMsrType = "integer")||(tMsrType = "number")) {
				If (tMsr.aggregate = "") {
					Set tAggregate = "SUM"
				}
				Else {
					Set tAggregate = tMsr.aggregate
				}
			}
			ElseIf (tMsrType = "date") {
				If (tMsr.aggregate = "") {
					Set tAggregate = "AVG"
				}
				Else {
					Set tAggregate = tMsr.aggregate
				}
				If ((tAggregate'="MIN")&&(tAggregate'="MAX")&&(tAggregate'="AVG")) {
					Set tSC = $$$ERROR($$$GeneralError,"Aggregate function for date measure must be MIN, MAX, or AVG: " _ tMsr.name)
				}
			}
			ElseIf (tMsrType = "age") {
				If (tMsr.aggregate = "") {
					Set tAggregate = "AVG"
				}
				Else {
					// Invert min/max for age
					Set tAggregate = $CASE(tMsr.aggregate,"MIN":"MAX","MAX":"MIN",:tMsr.aggregate)
				}
				If ((tAggregate'="MIN")&&(tAggregate'="MAX")&&(tAggregate'="AVG")) {
					Set tSC = $$$ERROR($$$GeneralError,"Aggregate function for age measure must be MIN, MAX, or AVG: " _ tMsr.name)
				}
			}
			ElseIf (tMsrType = "boolean") {
				If (tMsr.aggregate = "") {
					Set tAggregate = "COUNT"
				}
				Else {
					Set tAggregate = tMsr.aggregate
				}
				If (tAggregate'="COUNT") {
					Set tSC = $$$ERROR($$$GeneralError,"Aggregate function for boolean measure must be COUNT: " _ tMsr.name)
				}
			}
			Else {
				If (tMsr.aggregate = "") {
					Set tAggregate = "COUNT"
				}
				Else {
					Set tAggregate = tMsr.aggregate
				}
				If (tAggregate'="COUNT") {
					Set tSC = $$$ERROR($$$GeneralError,"Aggregate function for string measure must be COUNT: " _ tMsr.name)
				}
			}
			If $$$ISERR(tSC) Quit
			
			// + WAL233 -- throw compile error if aggregate/operator mismatch
			If ((tAggregate'="")&&(tListingFilterOperator'="")) {
				If ((tAggregate="MAX")&&(tListingFilterOperator'="MAX")) {
					
					Set tSC = $$$ERROR($$$GeneralError,"Measure with MAX measure-specific listing operator must have MAX aggregate: " _ tMsr.name)
				}
				ElseIf ((tAggregate="MIN")&&(tListingFilterOperator'="MIN")) {
					
					Set tSC = $$$ERROR($$$GeneralError,"Measure with MIN measure-specific listing operator must have MIN aggregate: " _ tMsr.name)
				}
			}
			// - WAL233

			If (tMsrType = "age") {
				Set pMeta("hasAge") = 1
				Set tFactName = ..%GetFactName("Mx",tMsr.name,tSourceProperty,tSourceExpression,,,tLinkClass,tLinkProperty)
				Set tFactName = tFactName _ tScaleName _ tTypeName

				Do AddFact(tFactName,,"")
				Set pFactInfo("prop",tFactName,"mbrtype") = "m"
				Set pFactInfo("prop",tFactName,"msrname") = tMsr.name
				Set:tSourceProperty'="" pFactInfo("prop",tFactName,"source") = tSourceProperty
				Set:tSourceExpression'="" pFactInfo("prop",tFactName,"expr") = tSourceExpression
				Set pFactInfo("prop",tFactName,"type") = "%DeepSee.Datatype.dateTime"
				Set pFactInfo("prop",tFactName,"index") = "$none"
				Set:tLinkClass'="" pFactInfo("prop",tFactName,"linkClass") = tLinkClass
				Set:tLinkProperty'="" pFactInfo("prop",tFactName,"linkProperty") = tLinkProperty
				If (tMsrDateType'="") {
					Set pFactInfo("prop",tFactName,"dateType") = tMsrDateType
				}
				Set:tListingFilter'="" pFactInfo("prop",tFactName,"listingFilter") = tListingFilter // WAL190
				Set:tListingFilterOperator'="" pFactInfo("prop",tFactName,"listingFilterOperator") = tListingFilterOperator // WAL190

				// new fact for holding age
				Set tFxFactName = ..%GetFactName("MxFx",tMsr.name,tSourceProperty,tSourceExpression,,,tLinkClass,tLinkProperty)
				Set tFxFactName = tFxFactName _ tTypeName

				Do AddMeasure(tFxFactName,tMsr.factName)
				Set pFactInfo("prop",tFxFactName,"mbrtype") = "m"
				Set pFactInfo("prop",tFxFactName,"msrname") = tMsr.name
				Set pFactInfo("prop",tFxFactName,"type") = tMsrDataType
				Set pFactInfo("prop",tFxFactName,"index") = tMsrIndexType
				Set:+tMsr.searchable pFactInfo("prop",tFxFactName,"searchable") = tMsr.searchable
				Set pFactInfo("prop",tFxFactName,"function") = "%Convert"
				Set pFactInfo("prop",tFxFactName,"functionClass") = "%DeepSee.Age.Days"
				Set pFactInfo("prop",tFxFactName,"base") = tFactName
				Set tFactName = tFxFactName
				
				// Use special aggregate type for age
				// when we consolidate this value, we will convert age to current date
				Set tAggregate = tAggregate_":Days"
			}
			Else {
				Set tFactName = ..%GetFactName("Mx",tMsr.name,tSourceProperty,tSourceExpression,,,tLinkClass,tLinkProperty)
				// fact name must reflect if scale or type is overridden
				Set tFactName = tFactName _ tScaleName _ tTypeName

				Do AddMeasure(tFactName,tMsr.factName)
				Set pFactInfo("prop",tFactName,"mbrtype") = "m"
				Set pFactInfo("prop",tFactName,"msrname") = tMsr.name
				Set:tSourceProperty'="" pFactInfo("prop",tFactName,"source") = tSourceProperty
				Set:tSourceExpression'="" pFactInfo("prop",tFactName,"expr") = tSourceExpression
				Set pFactInfo("prop",tFactName,"type") = tMsrDataType
				Set pFactInfo("prop",tFactName,"index") = tMsrIndexType
				Set:+tMsr.searchable pFactInfo("prop",tFactName,"searchable") = tMsr.searchable
				Merge pFactInfo("prop",tFactName,"parms") = tFParms
				Set:tLinkClass'="" pFactInfo("prop",tFactName,"linkClass") = tLinkClass
				Set:tLinkProperty'="" pFactInfo("prop",tFactName,"linkProperty") = tLinkProperty
				Set:tListingFilter'="" pFactInfo("prop",tFactName,"listingFilter") = tListingFilter // WAL190
				Set:tListingFilterOperator'="" pFactInfo("prop",tFactName,"listingFilterOperator") = tListingFilterOperator // WAL190
				If (tMsrDateType'="") {
					Set pFactInfo("prop",tFactName,"dateType") = tMsrDateType
				}
			}

			// JMD1412
			If ((tMsrFormat="")&&(tMsrType = "date")) {
				Set tMsrFormat = "%date%"
			}
			// Link measure to Fact (d=0 for "measures")
			Set tMsrNo = tMsrNo + 1
			// WAL232 -- add listing filter info here
			Set pDimIndex(0,tMsrNo,0) = $LB("m","Measures",tMsr.name,,$$FactNo(tFactName),,tAggregate,tMsrType,+tScale,,tMsrHidden,tMsrFormat,tMsr.searchable,,$G(tListingFilterOperator),$G(tListingFilter))
			Set pCaptions("MEASURES",$$$UPPER(tMsr.name)) = $LB(tMsr.name,tMsr.displayName)
			Set pDescriptions("MEASURES",$$$UPPER(tMsr.name)) = $LB(tMsr.description) // JSL4475
		} // next measure
		If $$$ISERR(tSC) Quit
 
		#; now process relationships
		For r=1:1:pCube.relationships.Count() {
			Set tRel = pCube.relationships.GetAt(r)
			If (tRel.disabled) {
				Continue
			}
			
			// + DTB859 - [Validation] Check fctNumber assignments against cube setting
			If (pCube.namedFactNums) {
				If 'tRel.factNumber {
					$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number is required and unassigned to relationship " _ tRel.name))
				}
				ElseIf '$IsValidNum(tRel.factNumber) || (tRel.factNumber '= (tRel.factNumber\1)) {
					$$$ThrowStatus($$$ERROR($$$GeneralError,"Fact number must be an integer: " _ tRel.name _ " value: " _ tRel.factNumber))
				}
				Else {
					Set tAssignedFactNum = tRel.factNumber		// DTB918
				}
			}
			// - DTB859
			
			// PFS046 - Cubes can not define a relationship to themselves
			If ($$$UPPER(tRel.relatedCube)=$$$UPPER(pCube.name)) {
				Set tSC=$$$ERROR($$$GeneralError,"Cube relationship can not have itself as the relatedCube: "_tRel.name)
				$$$ThrowStatus(tSC)
			}
			Set tDimNo = tDimNo + 1
			Set tSourceProperty = tRel.sourceProperty
			Set tSourceExpression = tRel.sourceExpression

			Set tFactName = ..%GetFactName("Rx",tRel.name,tSourceProperty,tSourceExpression)
			Do AddFact(tFactName,,tRel.factName)

			Set tRelName = $$$UPPER(tRel.name)
			Set pRelationInfo(tRelName,"name") = tRel.name
			Set pRelationInfo(tRelName,"fact") = $S(tRel.factName="":tFactName,1:tRel.factName)
			Set pRelationInfo(tRelName,"relatedCube") = tRel.relatedCube
			Set pRelationInfo(tRelName,"inverse") = tRel.inverse
			Set pRelationInfo(tRelName,"cardinality") = tRel.cardinality
			Set pRelationInfo(tRelName,"nullReplacement") = tRel.nullReplacement
			
			// DTB639 - Do not allow a cardinality "one" to compile without a source property or expression
			If ((tRel.cardinality="one")&&(tSourceExpression="")&&(tSourceProperty="")) {
				Set tSC = $$$ERROR($$$GeneralError,"Relationship with cardinality 'one' must define a source: "_tRel.name)
				$$$ThrowStatus(tSC)
			}

			// determine which is the "stored" side of the relationship
			If ((tSourceExpression'="")||(tSourceProperty'="")) {
				Set pRelationInfo(tRelName,"storedSide") = 1
			}
			Else {
				Set pRelationInfo(tRelName,"storedSide") = 0
			}

			If ('pRelationInfo(tRelName,"storedSide")) {
				// there is no actual property on the "many" side
				Set pFactInfo("prop",tFactName,"type") = "$none"
			}
			Else {
				// if related cube exists, then use it as the property type
				Set tRelType = ##class(%DeepSee.Utils).%GetCubeFactClass(tRel.relatedCube,.x)
				Set:tRelType="" tRelType = "%Integer"

				// use list for "many" on the stored side
				If (tRel.cardinality = "many") {
					Set tRelType = "%DeepSee.Datatype.list"
					Set pFactInfo("prop",tFactName,"list") = 1
				}

				Set pFactInfo("prop",tFactName,"type") = tRelType
				Set pFactInfo("prop",tFactName,"mbrtype") = "r"
				// index on reference to fact in related cube
				Set pFactInfo("prop",tFactName,"index") = "bitmap"

				If (tSourceExpression'="") {
					// expression takes precedence over sourceProperty
					Set pFactInfo("prop",tFactName,"expr") = tSourceExpression
				}
				ElseIf (tSourceProperty '= "") {
					Set pFactInfo("prop",tFactName,"source") = tSourceProperty
				}

				// JMD1059 process dependsOn
				If (tRel.dependsOn'="") {
					// add to list; process later
					Set tDependsList(tDimNo,0,0) = tRel.dependsOn
				}
			}
			If ($$FactNo(tFactName) < 0) {
				// assign a real fact number
				Set tActualNo = $S($G(tAssignedFactNum)'="":tAssignedFactNum,1:$I(tActualFactNo))		// DTB918 - Use the assigned fact number if defined
				Kill pFactIndex($$FactNo(tFactName))
				Set pFactIndex(tActualNo) = tFactName
				Set pFactInfo("prop",tFactName) = tActualNo
				Set pRelIndex(tActualNo) = tRel.name
			}
			Set pDimIndex(tDimNo,0,0) = $LB("r",tRel.name,,,$$FactNo(tFactName),tRel.relatedCube,tRel.cardinality,tRel.inverse,+$G(pRelationInfo(tRelName,"storedSide")))
			Set pCaptions($$$UPPER(tRel.name)) = $LB(tRel.name,tRel.displayName)
			Set pDescriptions($$$UPPER(tRel.name)) = $LB(tRel.description) // JSL4475
		} // next relationship
		If $$$ISERR(tSC) Quit

		// construct index of member names
		Set tDimCount = 0
		Set d = $O(pDimIndex(""))
		While (d'="") {
			Set:d=+d d = +d // normalize numeric
			Set tAllName = $LG($G(pDimIndex(d,0,0)),4)

			Set tDimCount = tDimCount + 1
			Set tHierCount = 0
			Set h = $O(pDimIndex(d,""))
			While (h'="") {
				Set:h=+h h = +h // normalize numeric
				Set:+h>0 tHierCount = tHierCount + 1
				Set tLevelCount = 0
				Set lvl = $O(pDimIndex(d,h,""))
				While (lvl'="") {
					Set:+lvl>0 tLevelCount = tLevelCount + 1
					Set tDimName = $$$UPPER($LG(pDimIndex(d,h,lvl),2))
					Set tHierName = $$$UPPER($LG(pDimIndex(d,h,lvl),3))
					Set tLvlName = $$$UPPER($LG(pDimIndex(d,h,lvl),4))

					If (lvl = 0) {
						If (h = 0) {
							Set pDimNames(tDimName) = $LB(d,0,0)
							If (tAllName '= "") {
								Set pDimNames(tDimName,$$$UPPER(tAllName)) = $LB(d,1,1)
							}
						}
						Else {
							Set pDimNames(tDimName,tHierName) = $LB(d,h,0)
						}
					}
					Else {
						Set pDimNames(tDimName,tHierName,tLvlName) = $LB(d,h,lvl)
					}
					Set lvl = $O(pDimIndex(d,h,lvl))
				}
				If ((tLevelCount = 1)&&(tHierName '= "")) {
					// only one level, so reference to hier is a reference to this level
					Set pDimNames(tDimName,tHierName) = $LB(d,h,1)
				}
				Set h = $O(pDimIndex(d,h))
			}
			If ((tHierCount = 1) && (tDimName '= "MEASURES") && (tDimName '= "PROPERTIES")) {
				// only one hier, so reference to dim is a reference to this hier (or level)
				If (tLevelCount = 1) {
					Set pDimNames(tDimName) = $LB(d,1,1)
				}
				Else {
					Set pDimNames(tDimName) = $LB(d,1,0)
				}
			}
			Set d = $O(pDimIndex(d))
		}

		// JMD910: process dependsOn list
		If ($D(tDependsList)) {
			Set tDimNo = $O(tDependsList(""))
			While (tDimNo'="") {
				Set tHierNo = $O(tDependsList(tDimNo,""))
				While (tHierNo'="") {
					Set tLevelNo = $O(tDependsList(tDimNo,tHierNo,""))
					While (tLevelNo'="") {
						Set tSpecCSV = $G(tDependsList(tDimNo,tHierNo,tLevelNo))
						// spec can be csv list
						For px = 1:1:$L(tSpecCSV,",") {
							Set tSpec = $P(tSpecCSV,",",px)
							Kill tSpecInfo,tQuoted
							Set tRelAddr = ""
							Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tSpec,.tSpecInfo,.tQuoted)
							If ($$$ISERR(tSC)) {
								Set tSC = $$$ERROR($$$GeneralError,"Invalid dependsOn spec: " _ tSpec)
								Quit
							}

							// JMD1059: test for [Relationship]
							If (($G(tSpecInfo(1))'="")&&($G(tSpecInfo(2))="")&&($G(tSpecInfo(3))="")) {
								// lookup relationship
								Set tRelAddr = $G(pDimNames($$$UPPER(tSpecInfo(1))))
								If (tRelAddr="") {
									Set tSC = $$$ERROR($$$GeneralError,"Level dependsOn refers to non-existing relationship: " _ tSpec)
									Quit
								}
							}
							ElseIf (($G(tSpecInfo(1))="")||($G(tSpecInfo(2))="")||($G(tSpecInfo(3))="")) {
								Set tSC = $$$ERROR($$$GeneralError,"Incomplete dependsOn spec: " _ tSpec)
								Quit
							}

							If (tRelAddr'="") {
								Set tRelInfo = $G(pDimIndex($LG(tRelAddr,1),$LG(tRelAddr,2),$LG(tRelAddr,3)))
								Set tFactNo = $LG(tRelInfo,5)
								If (tFactNo'="") {
									Set pDependList(tDimNo,tHierNo,tLevelNo,tFactNo) = tRelAddr
								}
							}
							Else {
								Set tLevelAddr = $G(pDimNames($$$UPPER(tSpecInfo(1)),$$$UPPER(tSpecInfo(2)),$$$UPPER(tSpecInfo(3))))
								If (tLevelAddr="") {
									Set tSC = $$$ERROR($$$GeneralError,"Level dependsOn refers to non-existing level: " _ tSpec)
									Quit
								}

								Set tLevelInfo = $G(pDimIndex($LG(tLevelAddr,1),$LG(tLevelAddr,2),$LG(tLevelAddr,3)))
								Set tFactNo = $LG(tLevelInfo,5)
						
								If (tFactNo'="") {
									Set pDependList(tDimNo,tHierNo,tLevelNo,tFactNo) = tLevelAddr
								}
							}
						}

						If $$$ISERR(tSC) Quit
						Set tLevelNo = $O(tDependsList(tDimNo,tHierNo,tLevelNo))
					}
					If $$$ISERR(tSC) Quit
					Set tHierNo = $O(tDependsList(tDimNo,tHierNo))
				}
				If $$$ISERR(tSC) Quit
				Set tDimNo = $O(tDependsList(tDimNo))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC

	// add fact to local index of names
	Set (f,fname,alias) = ""
AddFact(f,virtual,alias,dimType)
	Set:'$D(virtual) virtual = 0
	If '$D(pFactInfo("prop",f)) {
		// we use negative fact numbers until we are sure
		// this is an actual level
		Set fno = -$I(pFactIndex)
		Set pFactIndex(fno) = f
		Set pFactInfo("prop",f) = fno
		
		// DTB940 - Prevent multiple factIDs being assigned to the same fact number
		// DTB945 - virtual facts are exempt from this check
		Kill tPreviousFact
		If 'virtual && ($G(tAssignedFactNum)'="") && $D(pFactIndex(tAssignedFactNum),tPreviousFact) && (tPreviousFact'=f) {
			Set tSC = $$$ERROR($$$GeneralError,"Multiple factIDs defined for fact number:"_tAssignedFactNum_":"_f_":"_tPreviousFact)
			$$$ThrowStatus(tSC)
		}
	}
	ElseIf 'virtual {
		// DP-408304 - Fact numbers will not be set for virtual dimensions so there is no need to test
		// for collision if virtual=1
		
		// DTB918 - Check that the factNumber *and* $G(alias) matches what is already filed under this factID
		// If any of these don't match, the fact numbers can't be used.
		Set tPreviousFactNum = $G(pFactInfo("prop",f))
		If ($G(tAssignedFactNum)'="") && (tPreviousFactNum>0) && (tPreviousFactNum '= tAssignedFactNum) {
			Set tSC = $$$ERROR($$$GeneralError,"Multiple fact numbers defined for factID:"_f_":"_tAssignedFactNum_":"_tPreviousFactNum)
			$$$ThrowStatus(tSC)
		}
		
		// DTB918 - Do an alias check if namedFactNums is on.
		// DP-408304 - A null alias can match an explicit alias iff the explicit alias matches the generated factName f.
		If ($G(dimType) '= "time") && pCube.namedFactNums && ($G(pFactInfo("prop",f,"alias"),f) '= $S(alias="":f,1:alias)) {
			Set tSC = $$$ERROR($$$GeneralError,"Alias mismatch when filing '" _ f _ "' : '" _ $G(pFactInfo("prop",f,"alias")) _ "' : '" _ $G(alias) _"'")
			$$$ThrowStatus(tSC)
		}
	}
	
	If ('$D(pFactInfo("prop",f,"virtual"))||'virtual) {
		// if there is a request to use a fact as "real"
		// that was initially virtual, make sure this happens
		Set pFactInfo("prop",f,"virtual") = virtual
	}
	If ($G(alias)'="") {
		If (($G(dimType) '= "time")&&($G(dimType) '= "age")) {
			Set pFactInfo("prop",f,"alias") = alias
		}
	}
	
	Quit

	// return fact/measure index for given name
FactNo(fname)
	Quit pFactInfo("prop",fname)

	// add measure to local index of names
AddMeasure(m,alias)
	If '$D(pFactInfo("prop",m)) {
		// This fact is not defined yet, free to go forward
		Set tActualMsrNo = $S($G(tAssignedMsrNum)'="":tAssignedMsrNum,1:$I(pMsrIndex))		// DTB859 - Use the assigned number if defined
		If $D(pMsrIndex("M"_tActualMsrNo ),prevM) && (prevM '= m) {
			Set tSC = $$$ERROR($$$GeneralError,"Multiple factID's defined for fact number:'M"_tAssignedMsrNum_"'")
		}
		Else {
			Set pMsrIndex("M"_tActualMsrNo ) = m
		}
		Set pFactInfo("prop",m) = "M"_tActualMsrNo
	}
	Else {
		// DTB918 - Check that the factNumber *and* $G(alias) matches what is already filed under this factID
		// If any of these don't match, the fact numbers can't be used.
		If ($G(tAssignedMsrNum)'="") && ($G(pFactInfo("prop",m)) '= ("M"_tAssignedMsrNum)) {
			Set tSC = $$$ERROR($$$GeneralError,"Multiple fact numbers defined for factID:'"_m_"':'M"_tAssignedMsrNum_"'")
			$$$ThrowStatus(tSC)
		}
		
		// DTB918 - Do an alias check if namedFactNums is on.
		// DP-408304 - A null alias can match an explicit alias iff the explicit alias matches the generated factName m.
		If pCube.namedFactNums && ($G(pFactInfo("prop",m,"alias"),m) '= $S(alias="":m,1:alias)) {
			Set tSC = $$$ERROR($$$GeneralError,"Alias mismatch when filing '" _ m _ "' : '" _ $G(pFactInfo("prop",m,"alias")) _ "' : '" _ $G(alias) _"'")
			$$$ThrowStatus(tSC)
		}
	}

	If ($G(alias)'="") {
		Set pFactInfo("prop",m,"alias") = alias
	}
	Quit
}

/// Construct a Fact (property) name based on the given specifications.<br/>
/// <var>pPrefix</var> is a prefix, such as "Dx".<br/>
/// <var>pName</var> is the name of an element (such as a level).<br/>
/// <var>pSourceProperty</var> is a source property name.<br/>
/// <var>pSourceExpression</var> is a source expression used to derive the fact.<br/>
/// <var>pFunction</var> is a function (or name of time level class) applied to the fact.<br/>
/// <var>pRangeExpression</var> is a range expression applied to the fact.<br/>
/// <var>pTimeOffset</var> is a time offset applied to the fact.<br/>
ClassMethod %GetFactName(pPrefix As %String, pName As %String, pSourceProperty As %String, pSourceExpression As %String = "", pFunction As %String = "", pRangeExpression As %String = "", pLinkClass As %String = "", pLinkProperty As %String = "", pTimeOffset As %String = "") As %String
{
	Set tFactName = ""
	If ((pSourceProperty = "")&&(pSourceExpression="")) {
		Set tFactName = $ZSTRIP(pName,"*P")
	}
	Else {
		// Process source name
		Set tSourceName = ""
		If (pSourceExpression'="") {
			// Use hash of expression
			Set tSourceName = $ZCRC(pSourceExpression,7)
		}
		Else {
			For j=$L(pSourceProperty,"."):-1:1 {
				Set tSourceName = tSourceName _ $S(tSourceName="":"",1:"Via")_ $P(pSourceProperty,".",j)
			}
		}
		Set tFactName = tSourceName
		If (pFunction'="") {
			Set tFactName = tFactName _ "Fx"_ pFunction
		}
		If (pRangeExpression'="") {
			Set tFactName = tFactName _ "Rg"_ $ZCRC(pRangeExpression,7)
		}
		If (pLinkClass'="") {
			Set tFactName = tFactName _ "Lx"_ $ZCRC(pLinkClass_pLinkProperty,7)
		}
		If (pTimeOffset'="") {
			Set tFactName = tFactName _ "Tx"_ $TR(pTimeOffset,"-","n")
		}
		Set tFactName = $ZSTRIP(tFactName,"*P")
	}
	// test if name is too long or is invalid
	If (($L(tFactName) > 25)||'$ZNAME(tFactName)) {
		Set tFactName = $ZCRC(tFactName,7)
	}
	Quit pPrefix _ tFactName
}

/// Create a star (dimension) table to hold information for a given
/// level. The table may already exist.???
/// <var>pStarInfo</var> contains information about known star tables (and
/// gets modified by this method).<br/>
/// <var>pSchema</var> is the SQL schema to which the fact table belongs.<br/>
/// <var>pStarName</var> is the name of the star table (returned by reference).
/// This is used as the type of the fact.<br/>
/// <var>pLevelName</var> is the name of the current level.<br/>
/// <var>pSourceClass</var> is the source class for the cube.<br/>
/// <var>pSourceProperty</var> is the source property for the base fact.<br/>
/// <var>pSourceExpression</var> is the source expression for the base fact.<br/>
/// <var>pAlias</var> is the optional field name alias.<br/>
/// <var>pContext</var> contains the name of the model element currently
/// being processed (e.g., "Product.H1.Name"). This is used for error reporting.<br/>
ClassMethod %AddStarTable(pCube As %DeepSee.Model.cube, pSharedCube As %String, pSchema As %String, ByRef pStarInfo As %String, Output pStarName, pSourceClass As %String, pLevelName As %String, pSourceProperty As %String, pSourceExpression As %String, pLinkClass As %String, pLinkProperty As %String, pRangeExpression As %String, pAlias As %String, pContext As %String, pCollation As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// create a fact name; this will be the table name (unless an alias is in play)
		// the fact name is also used to disambiguate star tables
		Set tFactName = ..%GetFactName("Star", pLevelName, pSourceProperty, pSourceExpression,,pRangeExpression,pLinkClass,pLinkProperty)
		If (pAlias = "") {
			Set pStarName = tFactName
		}
		Else {
			Set pStarName = $ZSTRIP(pAlias,"*P")
		}

		If (pSharedCube'="") {
			// get schema from reference cube
			Set tRefClass = ##class(%DeepSee.Utils).%GetCubeFactClass(pSharedCube)
			Set pSchema = $P(tRefClass,".",1,$L(tRefClass,".")-1)
			Set pStarName = pSchema_"."_pStarName
		}
		Else {
			Set pStarName = pSchema_"."_pStarName
		}

		If $D(pStarInfo(pStarName)) {
			If ($G(pStarInfo(pStarName,"source")) '= tFactName) {
				Set tSC = $$$ERROR($$$GeneralError,"Ambiguous Star Table Name: " _ pStarName_" ("_pContext_")")
				Quit
			}
		}
		Else {
			Set pStarInfo(pStarName,"source") = tFactName
		}

		// add key property to star table
		If (pSharedCube="") {
			Set tSC = ..%AddPropertyToStar(pStarName,pLevelName,.pStarInfo,.tStarProp,pSourceClass,pSourceProperty,pSourceExpression,0,pLinkClass,pLinkProperty,pRangeExpression,pAlias,pContext,pCollation)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSourceClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pSharedCube),"sourceClass"))
			Set tSC = ..%AddPropertyToStar(pStarName,pLevelName,.pStarInfo,.tStarProp,tSourceClass,pSourceProperty,pSourceExpression,0,pLinkClass,pLinkProperty,pRangeExpression,pAlias,pContext,pCollation)
			If $$$ISERR(tSC) Quit
		}

		Set pStarInfo(pStarName,"prop",tStarProp,"use") = "key"
		Set:pCollation'="" pStarInfo(pStarName,"prop",tStarProp,"collation") = pCollation

		If (pSharedCube'="") {
			Set pStarInfo(pStarName,"sharedCube") = pSharedCube
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add an additional field to the given star table.<br/>
/// <var>pStarName</var> is the name of the star table.<br/>
/// <var>pPropName</var> is the name of the property (from the model).<br/>
/// <var>pStarInfo</var> contains information about known star tables (and
/// gets modified by this method).<br/>
/// <var>pStarProp</var> returns (by reference) the name of the new property.<br/>
/// <var>pSourceClass</var> is the source class for the cube.<br/>
/// <var>pSourceProperty</var> is the source property for the base fact.<br/>
/// <var>pSourceExpression</var> is the source expression for the base fact.<br/>
/// <var>pAlias</var> is the optional field name alias.<br/>
/// <var>pCollation</var> is the optional collation to apply ("" or "exact").<br/>
/// <var>pContext</var> contains the name of the model element currently
/// being processed (e.g., "Product.H1.Name"). This is used for error reporting.<br/>
ClassMethod %AddPropertyToStar(pStarName As %String, pPropName As %String, ByRef pStarInfo As %String, Output pStarProp As %String, pSourceClass As %String, pSourceProperty As %String, pSourceExpression As %String, pIsReference As %Boolean, pLinkClass As %String, pLinkProperty As %String, pRangeExpression As %String, pAlias As %String, pContext As %String, pCollation As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// create a fact name for the property.
		// use Dxr as prefix for reference properties
		Set tFactName = ..%GetFactName($S(pIsReference:"Dxr",1:"Dx"), pPropName, pSourceProperty, pSourceExpression,,pRangeExpression,pLinkClass,pLinkProperty)
		If (pAlias = "") {
			Set pStarProp = tFactName
		}
		Else {
			Set pStarProp = pAlias
		}

		// find the type of the property
		If ((pSourceProperty'="")&&(pRangeExpression="")&&(pSourceExpression="")) {
			Set tSC = ..%AnalyzeStarProperty(pSourceClass,pSourceProperty,.tType,.tParms,pContext)
			Set:tType="" tType="%Library.String"
			If ("datatype" '= $$$getClassType($$$NormalizeClassname(tType))) {
				// property is a reference (in the orginal source data)
				// treat is as a string in the model
				Set tType = "%Library.String"
				Set tParms("MAXLEN") = 1000
			}
			Quit:$$$ISERR(tSC)
		}
		Else {
			// expression
			Set tType = "%Library.String"
			Set tParms("MAXLEN") = 4000
		}

		If (pCollation="exact") {
			// JMD1080: always remember collation
			Set tParms("COLLATION") = "EXACT"
		}

		If $D(pStarInfo(pStarName,"prop",pStarProp)) {
			If ($G(pStarInfo(pStarName,"prop",pStarProp,"fact")) '= tFactName) {
				Set tSC = $$$ERROR($$$GeneralError,"Ambiguous Star Table Property Name: " _ pPropName_" ("_pContext_")")
				Quit
			}
		}
		If (pIsReference) {
			Set pStarInfo(pStarName,"prop",pStarProp,"isref") = 1
		}

		Set pStarInfo(pStarName,"prop",pStarProp,"type") = tType
		Merge pStarInfo(pStarName,"prop",pStarProp,"parms") = tParms 

		Set pStarInfo(pStarName,"prop",pStarProp,"vname") = pStarProp
		Set pStarInfo(pStarName,"prop",pStarProp,"fact") = tFactName
		If (pSourceExpression '= "") {
			Set pStarInfo(pStarName,"prop",pStarProp,"expr") = pSourceExpression
		}
		Else {
			Set pStarInfo(pStarName,"prop",pStarProp,"source") = pSourceProperty
		}
		Set pStarInfo(pStarName,"prop",pStarProp,"use") = "property"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add a rollup property to the given star table.<br/>
/// <var>pStarName</var> is the name of the star table.<br/>
/// <var>pRollupFact</var> is the name of the rollup fact.<br/>
/// <var>pFactInfo</var> is the array of information about facts.<br/>
/// <var>pStarInfo</var> contains information about known star tables.<br/>
/// <var>pContext</var> contains the name of the model element currently
/// being processed (e.g., "Product.H1.Name"). This is used for error reporting.<br/>
ClassMethod %AddRollupToStar(pStarName As %String, pRollupFact As %String, ByRef pFactInfo As %String, ByRef pStarInfo As %String, pContext As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// find type of rollup fact-- this will be the rollup table
		Set tRollupType = $G(pFactInfo("prop",pRollupFact,"type"))
		Set tAlias = $G(pFactInfo("prop",pRollupFact,"alias"))
		Set tExpr = $G(pFactInfo("prop",pRollupFact,"expr"))
		Set tSource = $G(pFactInfo("prop",pRollupFact,"source"))

		Set tStarProp = pRollupFact
		If (tAlias'="") {
			Set tStarProp = tAlias
		}

		Set pStarInfo(pStarName,"prop",tStarProp,"type") = tRollupType
		Set pStarInfo(pStarName,"prop",tStarProp,"vname") = tStarProp
		Set pStarInfo(pStarName,"prop",tStarProp,"fact") = pRollupFact
		Set pStarInfo(pStarName,"prop",tStarProp,"use") = "rollup"
		If (tExpr '= "") {
			Set pStarInfo(pStarName,"prop",tStarProp,"expr") = tExpr
		}
		Else {
			Set pStarInfo(pStarName,"prop",tStarProp,"source") = tSource
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given meta data for a cube, create the set of Fact 
/// and Star Table classes related to it.<br/>
ClassMethod %CreateFactTable(pCube As %DeepSee.Model.cube, pCubeClass As %String, pSchema As %String, pSourceType As %String, ByRef pFactIndex As %String, ByRef pFactInfo As %List, ByRef pStarInfo As %List, ByRef pMsrIndex As %String, ByRef pRelationInfo As %String, ByRef pStorage As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		#; create fact table class
		Set tClassDefName = pSchema_".Fact"
		Set tCubeName = $$$UPPER(pCube.name)

		#; we have to get SQL name manually as oddCOM does not exist yet!
		Set tFactTableName = $TR(pSchema,".","_")_".Fact"
		Set tListingTableName = $TR(pSchema,".","_")_".Listing"

		#; create star tables
		#; first find dependencies of star tables
		Set tStar = $O(pStarInfo(""))
		While (tStar '= "") {
			Set tDependsOn(tStar) = ""
			Set tProp = $O(pStarInfo(tStar,"prop",""))
			While (tProp '= "") {
				Set tType = $G(pStarInfo(tStar,"prop",tProp,"type"))
				If (tType '= "$none") {
					Set tClsType = $$$getClassType($$$NormalizeClassname(tType))
					If (tClsType '= "datatype") {
						// tType has precedence over tStar
						Set tDependsOn(tStar,tType) = ""
					}
				}
				Set tProp = $O(pStarInfo(tStar,"prop",tProp))
			}
			Set tStar = $O(pStarInfo(tStar))
		}

		Set tSC = ..%BuildOrderedList(.tDependsOn, .tOrderedStar)
	    If $$$ISERR(tSC) Quit

		Set n = $O(tOrderedStar(""))
		While (n '= "") {
			Set tStar = tOrderedStar(n)
			Set tShared = $G(pStarInfo(tStar,"sharedCube"))
			If (tShared="") {
				Set tSC = ..%CreateStarTable(pCube, pCubeClass, tStar, .pStarInfo)
			    If $$$ISERR(tSC) Quit
			}
			Else {
				// get index from ref cube
				Set tPrimaryIndex = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tShared),"star",tStar,"primary"))
				Set pStarInfo(tStar,"primary") = tPrimaryIndex
			}
			Set n = $O(tOrderedStar(n))
		}
	    If $$$ISERR(tSC) Quit

		#; Now create the fact table
		#; Delete any pre-existing definition
		If $$$defClassDefined(tClassDefName) {
		    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
		    If $$$ISERR(tSC) Quit
		}

		#; Create a new class definition
		Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
		If tClassDef = $$$NULLOREF Set tSC=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
		Set tClassDef.Super = "%DeepSee.FactTable,%DeepSee.CubeFunctionSet"
        Set tClassDef.IncludeCode = "%DeepSee"

		#; JMD1248: pick up includes from cube definition class
		If $IsObject($G(%class)) {
			Set:%class.IncludeCode'="" tClassDef.IncludeCode = tClassDef.IncludeCode_","_%class.IncludeCode
		}

        Set tClassDef.ProcedureBlock = 1
        Set tClassDef.Final = 1
		Set tClassDef.Owner = pCube.owner
        Set tClassDef.Description = "Fact table for cube '"_pCube.name_"'.<br/>"_$C(13,10)_
        							"THIS IS A GENERATED CLASS, DO NOT EDIT.<br/>"_$C(13,10)_
        							"Generated by %DeepSee.Generator:%CreateFactTable."

		#; CUBENAME param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"CUBENAME")
		Set tParmDef.Default = pCube.name
		Do tClassDef.Parameters.Insert(tParmDef)

		#; SOURCECLASS param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"SOURCECLASS")
		Set tParmDef.Default = pCube.sourceClass
		Do tClassDef.Parameters.Insert(tParmDef)

		#; BITMAPCHUNKINMEMORY param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"BITMAPCHUNKINMEMORY")
		Set tParmDef.Default = pCube.bitmapChunkInMemory
		Do tClassDef.Parameters.Insert(tParmDef)

		#; INITIALBUILDORDER param (for information only)
		If (pCube.initialBuildOrder'="") {
			Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"INITIALBUILDORDER")
			Set tParmDef.Default = pCube.initialBuildOrder
			Do tClassDef.Parameters.Insert(tParmDef)
		}

		#; BUILDRESTRICTION param (for information only)
		If (pCube.buildRestriction'="") {
			Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"INITIALBUILDRESTRICTION")
			Set tParmDef.Default = pCube.buildRestriction
			Do tClassDef.Parameters.Insert(tParmDef)
		}

		#; storage for fact table
		#dim tStorage As %Dictionary.StorageDefinition
		Set tStorage = ##class(%Dictionary.StorageDefinition).%New(tClassDefName_"||Default")
		Set tStorage.Name = "Default"
		Set tStorage.ExtentSize = 10000000
		Set tStorage.DataLocation = ..%GetFactLocation(tClassDefName)
		Set tStorage.StreamLocation = ..%GetFactLocation(tClassDefName,"S")
		Set tStorage.IdFunction = "sequence"		// DP-423720
		
		// + DTB961 - Manage the actual data in the storage definition. This should be the only
		// <Data> tag present in a fact table's Storage definition. If the generated
		//   FactDefaultData
		// is also present in the compiled fact class, it means one or more properties were not properly 
		// accounted for in the manufacturing of storage data Value entries. Any properties that end
		// up in storage generated by the compiler instead of being assigned by this Generator 
		// should be considered an error.
		Set tFactStorageData = ##class(%Dictionary.StorageDataDefinition).%New()
		Do tFactStorageData.NameSet("FactManagedData")
		Do tStorage.Data.Insert(tFactStorageData)
		// - DTB961
		
		Do tClassDef.Storages.Insert(tStorage)

		#; extent index
		Set tExtent = "$" _ $P(tClassDefName,".",$L(tClassDefName,"."))
		Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":Default"_tExtent)
		Set tIndexStore.Name = tExtent
		Set tIndexStore.Location = ..%GetIndexLocation(pCube.name,tExtent)
		Do tStorage.Indices.Insert(tIndexStore)

		#; count method
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%Count")
		Set tMeth.Name = "%Count"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = ""
		Set tMeth.ReturnType = "%Integer"
		Set tMeth.Description = "Return the total number of items within the Fact table.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable."

		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tCount = 0")
		Do tMeth.Implementation.WriteLine(" &sql(SELECT COUNT(*) INTO :tCount FROM "_tFactTableName_")")
		Do tMeth.Implementation.WriteLine(" Quit tCount")

		Do tClassDef.Methods.Insert(tMeth)

		#; create properties and indices
		#; link to source table
		Set tProp = ##class(%Dictionary.PropertyDefinition).%New(tClassDefName_"||%sourceId")
		Set tProp.Name = "%sourceId"
		If ((pSourceType = "kpi")||(pSourceType = "worksheet")||(pSourceType = "metric")) {
			Set tProp.Type = "%String"
		}
		Else {
			Set tProp.Type = $S(pCube.sourceClass'="":pCube.sourceClass,1:"%String")
		}
		Set tProp.Type = ..%DenormalizeType(tProp.Type)
		If (tProp.Type = "%String") {
			Do tProp.Parameters.SetAt(512,"MAXLEN")
		}
		Set tProp.Description = "Reference to original data in source table."
		Set tProp.SequenceNumber = $I(tSeq) + 1000
		Do tClassDef.Properties.Insert(tProp)
		
		// DTB961 - Insert %sourceId Storage. This is always name=1
		Set tValueDef = ..%MakePropStorageDef("%sourceId",.pStorage,.tNewStorage)
		Do:$IsObject(tValueDef) tFactStorageData.Values.Insert(tValueDef)
		// - DTB961

		// sourceId index
		/* 
		n.b. this is built manually
		Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tProp.Name)
		Set tIndexDef.Name = tProp.Name
		Set tIndexDef.Properties = tProp.Name
		Set tIndexDef.SequenceNumber = $I(tSeq)
		Do tClassDef.Indices.Insert(tIndexDef)

		Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":"_tProp.Name)
		Set tIndexStore.Name = tProp.Name
		Set tIndexStore.Location = ..%GetIndexLocation(pCube.name,tProp.Name)
		Do tStorage.Indices.Insert(tIndexStore)
		*/

		/*
		// reverse sourceId index
		Set tReverseName = "%sourceIdReverse"
		Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tReverseName)
		Set tIndexDef.Name = tReverseName
		Set tIndexDef.Properties = "%%ID"
		Set tIndexDef.Data = tProp.Name
		Set tIndexDef.SequenceNumber = $I(tSeq)
		Do tClassDef.Indices.Insert(tIndexDef)

		Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":"_tReverseName)
		Set tIndexStore.Name = tReverseName
		Set tIndexStore.Location = ..%GetIndexLocation(pCube.name,tReverseName)
		Do tStorage.Indices.Insert(tIndexStore)
		*/

		#; partition #
		Set tProp = ##class(%Dictionary.PropertyDefinition).%New(tClassDefName_"||%dspartition")
		Set tProp.Name = "%dspartition"
		Set tProp.Type = "%Integer"
		Set tProp.Calculated = 1
		Set tProp.SqlComputed = 1
		Set tProp.SqlComputeCode = "Set {"_tProp.Name_"}=({ID}\"_(16*64000)_")+1"
		Set tProp.Description = "This indicates which partition (set of 1M) this fact is in."
		Set tProp.SequenceNumber = $I(tSeq) + 1000
		Do tClassDef.Properties.Insert(tProp)
		// NB - This is computed, so it is not inserted into the storage definition

		#; JMD910 indices for level dependsOn
		Kill tDependsList
		Merge tDependsList = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"levelDepends")
		If $D(tDependsList) {
			Set tDimNo = $O(tDependsList(""))
			While (tDimNo'="") {
				Set tHierNo = $O(tDependsList(tDimNo,""))
				While (tHierNo'="") {
					Set tLevelNo = $O(tDependsList(tDimNo,tHierNo,""))
					While (tLevelNo'="") {
						Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"mbr#",tDimNo,tHierNo,tLevelNo))
						Set tLevelFactNo = $LG(tLevelInfo,5)
						Set tLevelFactName =  $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact#",tLevelFactNo))
						Set tLevelFactIsList = ($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact","prop",tLevelFactName,"list"))) // WAL093
						If ($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact","prop",tLevelFactName,"alias"))'="") {
							Set tLevelFactName = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact","prop",tLevelFactName,"alias")
						}
			
						Set tFactNo = $O(tDependsList(tDimNo,tHierNo,tLevelNo,""))
						While (tFactNo'="") {
							Set tMasterFactName =  $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact#",tFactNo))
							Set tMasterFactIsList = ($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact","prop",tMasterFactName,"list"))) // WAL093
							If ($G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact","prop",tMasterFactName,"alias"))'="") {
								Set tMasterFactName = $$$DeepSeeMetaGLVN("cubes",$$$UPPER(pCube.name),"fact","prop",tMasterFactName,"alias")
							}

							// define an index for this combination
							Set tIndexName = tMasterFactName_"AND"_tLevelFactName

							Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tIndexName)
							Set tIndexDef.Description = "Index for combination of "_tMasterFactName_" and "_tLevelFactName_"."
							Set tIndexDef.Name = tIndexName
							Set tIndexDef.Type = "bitmap"
							//
							// + WAL093 -- if either the master or the dependent level is a list we want to create
							//             the index with the keys of the list
							//
							//             For age a favorite color, we previously would have
							//
							//                Index(0,$lb("purple","yellow"))
							//
							//             Now we will have:
							//
							//               Index(0,"purple")         
							//               Index(0,"yellow")
							//
							//             This is the form that %DeepSee.Query.member*::%GetData and
							//             %DeepSee.Query.Engine::%FindDependentMembers need to return results
							//
							Set tMasterFactIndexSpec = $S(tMasterFactIsList:tMasterFactName_"(KEYS)",1:tMasterFactName)
							Set tLevelFactIndexSpec = $S(tLevelFactIsList:tLevelFactName_"(KEYS)",1:tLevelFactName)
							Set tIndexDef.Properties = tMasterFactIndexSpec_","_tLevelFactIndexSpec
							// - WAL093
							Set tIndexDef.SequenceNumber = $I(tSeq)
							Do tClassDef.Indices.Insert(tIndexDef)

							Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":"_tIndexName)
							Set tIndexStore.Name = tIndexName
							Set tIndexStore.Location = ..%GetIndexLocation(pCube.name,tFactNo_"&"_tLevelFactNo)
							Do tStorage.Indices.Insert(tIndexStore)

							Set tFactNo = $O(tDependsList(tDimNo,tHierNo,tLevelNo,tFactNo))
						}
						Set tLevelNo = $O(tDependsList(tDimNo,tHierNo,tLevelNo))
					}
					Set tHierNo = $O(tDependsList(tDimNo,tHierNo))
				}
				Set tDimNo = $O(tDependsList(tDimNo))
			}
		}
		
		// DP-436975 - BDB982 - build a list of aliases
		set p = ""
		for {
			set p = $order(pFactInfo("prop",p))
			quit:p=""
			set:$d(pFactInfo("prop",p,"alias"), a) tAliases(a)=""
		}

		#; additional indices
		For n=1:1:pCube.indices.Count() {
			Set tIndex = pCube.indices.GetAt(n)
			// If an index is disabled or if a property on which the index is based is disabled, continue
			If (tIndex.disabled) Continue
			
			//DP-405922
			Set tSkipIndex=0
			Set tPropLen=$Length(tIndex.properties,",") //tPropLen: number of properties this index depends on
			For i=1:1:tPropLen{
				// If even a single property does not exist, skip this index
				Set tCurrentProperty = $Piece(tIndex.properties,",",i)
				If ($D(pFactInfo("prop",tCurrentProperty))=0) 
					&& ($D(tAliases(tCurrentProperty))=0) { 
				 	Set tSkipIndex=1
				 	Quit
				}
			}
			If tSkipIndex=1 Continue
			Set tIndexName = "%User"_tIndex.name
			Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tIndexName)
			Set tIndexDef.Name = tIndexName
			Set tIndexDef.Properties = tIndex.properties
			Set tIndexDef.Type = tIndex.type
			Set tIndexDef.Description = tIndex.description
			Set tIndexDef.SequenceNumber = $I(tSeq)
			Do tClassDef.Indices.Insert(tIndexDef)

			// use same storage as built-in indices
			Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":Default"_tIndexName)
			Set tIndexStore.Name = tIndexName
			// use index name as index subscript
			Set tIndexStore.Location = ..%GetIndexLocation(pCube.name,tIndexName)
			Do tStorage.Indices.Insert(tIndexStore)
		}

		#; check for local expressions; add to xform list
		#; first pass; pick up names of expressions
		Kill tExprNames
		For e=1:1:pCube.expressions.Count() {
			Set tExpr = pCube.expressions.GetAt(e)
			If ('tExpr.disabled) {
				Set tExprNames($$$UPPER(tExpr.name)) = ""
			}
		}

		#; second pass-process and validate
		Kill tExprDepends 	// list of dependencies
		Kill tExprList		// list of expression names (used to rank dependencies)
		Set tExprCount = pCube.expressions.Count()
		For e=1:1:tExprCount {
			Set tExpr = pCube.expressions.GetAt(e)
			If (tExpr.disabled) {
				Continue
			}
			Set tExprList(tExpr.name) = ""
			If (tExpr.sourceExpression'="") {
				Set tSC = ..%ParseExpression(tExpr.sourceExpression, .tCode, .tPropList)
				If $$$ISERR(tSC) Quit

				// now replace %expression
				Set tSC = ..%ParseExpression(tCode, .tCode, .tPropListX,"%expression")
				If $$$ISERR(tSC) Quit

				// make sure expression reference is valid
				Set ex = $O(tPropListX(""))
				While (ex'="") {
					If '$D(tExprNames($$$UPPER(ex))) {
						Set tSC = $$$ERROR($$$GeneralError,"Local expression is not defined: "_ ex)
						Quit
					}

					// remember which other expressions *this* expression relies on
					// so that we can process them in order
					Set tExprDepends(tExpr.name,ex) = ""

					// check for simple cycles
					If $D(tExprDepends(ex,tExpr.name)) {
						Set tSC = $$$ERROR($$$GeneralError,"Circular dependency in local expressions: "_ tExpr.name _ " and " _ ex)
						Quit
					}

					Set ex = $O(tPropListX(ex))
				}
				If $$$ISERR(tSC) Quit

				Merge tXFormProps = tPropList
				Set tXFormCodeLocal(tExpr.name) = tCode
			}
			ElseIf (tExpr.sourceProperty'="") {
				Set tXFormProps(tExpr.sourceProperty) = ""
				Set tXFormCodeLocal(tExpr.name) = "%source("_$$$quote(tExpr.sourceProperty)_")"
			}
		}
		If $$$ISERR(tSC) Quit

		#; compute score for expressions
		Kill tExprScore
		Kill tExprRanked
		Set tIter = 0
		While ($D(tExprList)&&(tIter < (tExprCount+1))) {
			Set x1 = $O(tExprList(""))
			While (x1'="") {
				If '$D(tExprDepends(x1)) {
					// we don't depend on anything
					Set tExprRanked(tIter,x1) = ""
					Set tExprScore(x1) = tIter
					Kill tExprList(x1)
				}
				Else {
					// check our dependencies
					Set tResolved = 1
					Set x2 = $O(tExprDepends(x1,""))
					While (x2'="") {
						If '$D(tExprScore(x2)) {
							Set tResolved = 0
							Quit
						}
						Set x2 = $O(tExprDepends(x1,x2))
					}
					If (tResolved) {
						Set tExprRanked(tIter,x1) = ""
						Set tExprScore(x1) = tIter
						Kill tExprList(x1)
					}
				}
				Set x1 = $O(tExprList(x1))
			}
			Set tIter = tIter + 1
		}

		If $D(tExprList) {
			Set x1 = $O(tExprList(""))
			Set tSC = $$$ERROR($$$GeneralError,"Unresolved dependencies in local expression: " _ x1)
			Quit
		}

		#; properties (in fact # order)
		#; (merge fact and measure lists)
		Merge tPropIndex = pFactIndex
		Merge tPropIndex = pMsrIndex

		Set tFactNo = $O(tPropIndex(""))
		While (tFactNo '= "") {
			Set tName = tPropIndex(tFactNo)
			Set tType = $G(pFactInfo("prop",tName,"type"))
			If (tType '= "$none") {
				Set tAlias = $G(pFactInfo("prop",tName,"alias"))
				Set tPropName = $S(tAlias'="":tAlias,1:tName)
				Set tIsList = +$G(pFactInfo("prop",tName,"list"))
				Set tIsTime = +$G(pFactInfo("prop",tName,"isTime"))
				Set tIsRef = +$G(pFactInfo("prop",tName,"isref"))
				Set tDelim = $G(pFactInfo("prop",tName,"listDelimiter"))
				Set tRangeExpr = $G(pFactInfo("prop",tName,"rangeExpr"))
				Set tUseDisplay = +$G(pFactInfo("prop",tName,"useDisplay"))
				Set tVirtual = +$G(pFactInfo("prop",tName,"virtual"))
				Set tDateType = $G(pFactInfo("prop",tName,"dateType"))
				Set tTimeOffset = $G(pFactInfo("prop",tName,"timeOffset"))

				Set tIndexType = $G(pFactInfo("prop",tName,"index"))
				Set tFunction = $G(pFactInfo("prop",tName,"function"))
				Set tFunctionClass = $G(pFactInfo("prop",tName,"functionClass"))
				Kill tOptions
				Merge tOptions = pFactInfo("prop",tName,"options")
				Set tBase = $G(pFactInfo("prop",tName,"base"))
				Set tMbrType = $G(pFactInfo("prop",tName,"mbrtype"))
				Set tMemberType = $Case(tMbrType,"r":$$$Text("Relationship","%DeepSee"),"m":$$$Text("Measure","%DeepSee"),:$$$Text("Dimension","%DeepSee"))
				Set tSource = $G(pFactInfo("prop",tName,"source"))
				Set tSourceExpression = $G(pFactInfo("prop",tName,"expr"))
				Set tLocalSource = $G(pFactInfo("prop",tName,"localSource"))
				Set tLocalSourceExpression = $G(pFactInfo("prop",tName,"localExpr"))
				Set tIsStar = +$G(pFactInfo("prop",tName,"star"))
				Set tMsrSearchable = +$G(pFactInfo("prop",tName,"searchable"))

				Set tLinkClass = $G(pFactInfo("prop",tName,"linkClass"))
				Set tLinkProperty = $G(pFactInfo("prop",tName,"linkProperty"))

				// test for null replacement
				If (('tIsTime) && ('tVirtual) && (tMbrType="d")) {
					Set tNullProps(tPropName) = ""
				}

				If (tIsList && (tDelim="")) {
					// this is a $List; we will need to know this in null replacement
					Set tNullPropsList(tPropName) = ""
				}

				If ((tLinkClass'="")&&(tLinkProperty'="")) {
					Set tLinkProps(tName) = tPropName
				}
				
				// overrides
				If (tLocalSourceExpression'="") {
					Set tSourceExpression = tLocalSourceExpression
				}
				ElseIf ((tSourceExpression'="")&&(tLocalSource'="")) {
					// replace expression with synthetic expression
					Set tSourceExpression = "%source."_tLocalSource
				}

				If (tRangeExpr'="") {
					Set tRangeProps(tPropName) = tRangeExpr
					If (tIsList && (tDelim="")) {
						// this is a $List; we will need to know this later
						Set tRangePropsList(tPropName) = ""
					}
				}

				If (tDateType'="") {
					Set tDateTypeProps(tPropName) = tDateType
				}

				// gather info used to test if dimensions are modified by update
				// JMD1077: make sure member is not a measure or relation
				If ((tFactNo>0)&&(tMbrType'="m")&&(tMbrType'="r")&&('tVirtual)) {
					// JMD1452 add list and delim info
					Set tLevelTest(tFactNo) = $LB(tPropName,tFunctionClass,tFunction,tBase,tTimeOffset,tIsList,tDelim)
				}

				Set tSQLCompute = ""
				If ((tBase'="")&&(tFunction'="")&&(tFunctionClass'="")) {
					Set tFunctions(tFunction) = ""
					// pass (inverse) time offset along
					Set tTimeOffset = $ZSTRIP(tTimeOffset,"<>W")
					// Invert offset
					If ($E(tTimeOffset)="-") {
						Set tTimeOffset = $E(tTimeOffset,2,$L(tTimeOffset))
					}
					ElseIf (tTimeOffset'="") {
						Set tTimeOffset = "-"_tTimeOffset
					}
					Set tOptions("POFFSET") = tTimeOffset
					Set tSC = ..%MakeSQLCompute(.tSQLCompute,tFunctionClass,tFunction,tBase,.tOptions)
					If $$$ISERR(tSC) Quit
				}

				#; gather info for %ProcessFact (all facts)
				If (tSourceExpression'="") {
					Set tSC = ..%ParseExpression(tSourceExpression, .tCode, .tPropList)
					If $$$ISERR(tSC) Quit

					// now replace %expression
					Set tSC = ..%ParseExpression(tCode, .tCode, .tPropListX,"%expression")
					If $$$ISERR(tSC) Quit

					// make sure expression reference is valid
					Set ex = $O(tPropListX(""))
					While (ex'="") {
						If '$D(tXFormCodeLocal(ex)) {
							Set tSC = $$$ERROR($$$GeneralError,"Local expression is not defined: "_ ex)
							Quit
						}
						Set ex = $O(tPropListX(ex))
					}
					If $$$ISERR(tSC) Quit

					Set tXFormCode(tPropName) = tCode
					// JMD929: track properties used by this expression if %value is used
					If (tCode["%value") {
						Merge tXFormCode(tPropName,"src") = tPropList
						Merge tXFormCode(tPropName,"exp") = tPropListX
					}
					Merge tXFormProps = tPropList
					If (tIsStar) {
						Set tStarField(tType,tPropName) = ""
						Set tStarField(tType,tPropName,"fact") = tFactNo
						If (tIsList) {
							Set tStarField(tType,tPropName,"list") = 1
							Set tStarField(tType,tPropName,"listDelimiter") = tDelim
						}
					}
				}
				ElseIf (tSource'="") {
					// JMD1184: modify the source field name by tacking on modifiers with "~~"
					// This makes it possible to refer to the same source fields with
					// different modifiers (specifically: logical and display value of same field)
					// source~~EXTERNAL - indicates that we need to fetch the display value
					// n.b.: this affects users of %InjectFact
					If (tUseDisplay) {
						Set tSource = tSource _ "~~EXTERNAL"
					}
					If '$D(tSelectList(tSource)) {
						If ('tIsRef) {
							// don't fetch reference props
							Set tSelectList(tSource) = tPropName
							Set:tLocalSource'="" tLocalSelectList(tSource) = tLocalSource
						}
					}
					// JMD1256 do not test for virtual fields
					ElseIf (tSQLCompute="") {
						// this property is based on a source field already in the list
						Set tCopyFromList(tPropName) = tSelectList(tSource)
					}

					If (('tVirtual) && (tSQLCompute="")) {
						// do not insert computed or virtual fields
						Set tInsertList(tPropName) = tSelectList(tSource)
					}

					// reference to STAR table
					If (tIsStar) {
						Set tStarField(tType,tPropName) = ""
						Set tStarField(tType,tPropName,"fact") = tFactNo
						If (tIsList) {
							Set tStarField(tType,tPropName,"list") = 1
							Set tStarField(tType,tPropName,"listDelimiter") = tDelim
						}
					}
				}
				// Create properties for all non-virtual facts
				// tFactsPrecompute contains a list of facts that can be precomputed
				// (in combination with measures in tMeasuresPrecompute)
				If ('tVirtual) {
					// keep track of iKnow properties; do not store them
					If (tIndexType["iKnow") {
						Set tiKnowProps(tName) = tIndexType, tiKnowSkip(tPropName) = ""
					}
					Else {
						Set tProp = ##class(%Dictionary.PropertyDefinition).%New(tClassDefName_"||"_tPropName)
						Set tProp.Name = tPropName
						If (tIsList) {
							Set tProp.Type = "%DeepSee.Datatype.list"
						}
						Else {
							If (..%IsString(tType)) {
								// DTB491 - If this is a custom type that extends %String, treat it like a %String
								Set tType = "%String"
							}
							Set tProp.Type = ..%DenormalizeType(tType)
						}
						Set tOrigSource = $P(tSource,"~~",1)
						Set tProp.Description = ..%MakeDescription(tMemberType,tPropName,tOrigSource)
						If (tSourceExpression '= "") {
							Set tProp.Description = tProp.Description _ $C(13,10) _ $$$Text("Expression: ","%DeepSee") _ tSourceExpression
						}
						Set tProp.SequenceNumber = $I(tSeq) + 1000

						If (tSQLCompute'="") {
							Set tProp.Calculated = 1
							Set tProp.SqlComputed = 1
							Set tProp.SqlComputeCode = "Set {"_tPropName_"}=" _ tSQLCompute
							// + WAL212
							If (tIsTime) {
								Set tProp.Type = "%Library.String" // WAL212 -- the compute code we use returns strings
								Do tProp.Parameters.SetAt("EXACT","COLLATION")
							}
							// - WAL212
						}
						Do tClassDef.Properties.Insert(tProp)
						
						// + DTB961 - Insert Data Value into the storage definition for non-calculated properties
						If ('tProp.Calculated) {
							// Manufacture the storage definition for the current property
							Set tValueDef = ..%MakePropStorageDef(tPropName,.pStorage,.tNewStorage)
							Do:$IsObject(tValueDef) tFactStorageData.Values.Insert(tValueDef)
						}
						// - DTB961
						

						// property parameters
						Set tFType = $$$getClassType($$$NormalizeClassname(tProp.Type))
						If (tIsList) {
							Do tProp.Parameters.SetAt("EXACT","COLLATION")
							If (tDelim = "") {
								Do tProp.Parameters.SetAt("LIST","LISTTYPE")
							}
							Else {
								Do tProp.Parameters.SetAt(tDelim,"DELIMITER")
							}
						}
						ElseIf (tFType = "datatype") {
							Set parm = $O(pFactInfo("prop",tName,"parms",""))
							While (parm '= "") {
								Set value = $G(pFactInfo("prop",tName,"parms",parm))
								Do tProp.Parameters.SetAt(value,parm)
								Set parm = $O(pFactInfo("prop",tName,"parms",parm))
							}
						}
						Else {
							// JMD878 selectivity
							Set value = $G(pFactInfo("prop",tName,"parms","SELECTIVITY"))
							Do:value'="" tProp.Parameters.SetAt(value,"SELECTIVITY")
						}
					} // iknow

					// create index for property (if it is a measure or a level)
					If ((tMbrType'="")&&(tIndexType '= "$none")&&(tIndexType'["iKnow")) {
						Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tPropName)
						Set tIndexDef.Name = tPropName
						If (tIndexType = "bitmap") {
							Set tIndexDef.Description = "Index for fact "_tFactNo_"."
							If (tMbrType="d") {
								Set tFactsPrecompute(tPropName) = $LB(tFactNo)
							}
							ElseIf (tMbrType="m") {
								Set tMeasuresPrecompute(tPropName) = $LB(tFactNo)
							}

							If (tIsList) {
								// collection index
								Set tIndexDef.Properties = tPropName_"(KEYS)"
							}
							Else {
								Set tIndexDef.Properties = tPropName
							}
						}
						ElseIf (tIndexType = "bitslice") {
							// n.b., bitslice does not support multiple properties.
							// !!! we need this to support partitioned indices
							Set tIndexDef.Description = "Index for measure "_tFactNo_"."
							Set tIndexDef.Properties = tPropName
							Set tMeasuresPrecompute(tPropName) = $LB(tFactNo)
						}
						ElseIf (tIndexType = "text") {
							Set tIndexDef.Description = "Index for measure "_tFactNo_"."
							Set tIndexDef.Properties = tPropName _ "(KEYS)"
							Set tIndexType = "bitmap"
						}
						Else {
							Set tIndexDef.Description = "Index for measure "_tFactNo_"."
							Set tIndexDef.Properties = tPropName
						}

						Set tIndexDef.Type = tIndexType
						Set tIndexDef.SequenceNumber = $I(tSeq)
						Do tClassDef.Indices.Insert(tIndexDef)

						Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":Default"_tPropName)
						Set tIndexStore.Name = tPropName
						// use fact # as index subscript
						Set tIndexStore.Location = ..%GetIndexLocation(pCube.name,tFactNo)
						Do tStorage.Indices.Insert(tIndexStore)

						If (tMsrSearchable && (tIndexType = "bitslice")) {
							// add additional index for this measure
							Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tPropName_"Search")
							Set tIndexDef.Name = tPropName_"Search"
							Set tIndexDef.Description = "Search index for fact "_tFactNo_"."
							Set tIndexDef.Properties = tPropName
							Set tIndexDef.Type = "bitmap"
							Set tIndexDef.SequenceNumber = $I(tSeq)
							Do tClassDef.Indices.Insert(tIndexDef)

							Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":Default"_tPropName_"Search")
							Set tIndexStore.Name = tPropName_"Search"
							// use propname as index subscript
							Set tIndexStore.Location = ..%GetSearchIndexLocation(pCube.name,tPropName_"Search")
							Do tStorage.Indices.Insert(tIndexStore)
						}
						
						// DTB753 - Add Foreign Key constraint
						If ($E(tType)'="%") { 
							Set tFKDef = ##class(%Dictionary.ForeignKeyDefinition).%New()
							Set tFKDef.Name = tPropName
							Set tFKDef.NoCheck = 1		// Check is not needed and carries a performance penalty. Turn it off.
							Set tFKDef.Properties = tPropName
							Set tFKDef.ReferencedClass = tType
							Set tFKDef.ReferencedKey = ""		// blank means use ID
							Do tClassDef.ForeignKeys.Insert(tFKDef)
						}
					}
				} // 'tVirtual
			} // '$none
			If $$$ISERR(tSC) Quit

			Set tFactNo = $O(tPropIndex(tFactNo))
		}
		If $$$ISERR(tSC) Quit
		
		// DTB961 - Return the list of storage positions that were actually encountered when
		// processing the columns in the cube definition. This is where deleted elements will be
		// removed from the incoming storage, freeing up storage slots for creation of future elements
		Kill pStorage
		Merge pStorage = tNewStorage

		#; %UpdateFacts, %BuildAllFacts, and %BuildTempFile methods
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%UpdateFacts")
		Set tMeth.Name = "%UpdateFacts"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pStartId:%String,pEndId:%String,pBatchMode:%Boolean=0,&pChunks:%Integer,pVerbose:%Boolean=0,pTaskGroup:%String="""",*pUpdates:%Integer,pRefProp:%String="""",pRefID:%String="""",&pDimTables,pFactList:%String="""""		// DTB886 - Add pFactList
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Update a range of Facts with data from the source table row with ids from <var>pStartId</var> to <var>pEndId</var>.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		// tMeth2 is the %BuildAllFacts method
		// which is *almost* the same as the %UpdateFacts method
		Set tMeth2 = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%BuildAllFacts")
		Set tMeth2.Name = "%BuildAllFacts"
		Set tMeth2.ClassMethod = 1
		Set tMeth2.FormalSpec = "pVerbose:%Boolean=0,pFactList:%String="""""		// DTB886 - Add the pFactList
		Set tMeth2.ReturnType = "%Status"
		Set tMeth2.Description = "Update all Facts with data from the source table.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth2.SequenceNumber = $I(tSeq) + 2000

		// tMeth3 is the %BuildTempFile method
		// which uses a similar SQL query to get source id values
		Set tMeth3 = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%BuildTempFile")
		Set tMeth3.Name = "%BuildTempFile"
		Set tMeth3.ClassMethod = 1
		Set tMeth3.FormalSpec = "pTempKey:%String="""",*pImplemented:%Boolean,pVerbose:%Boolean=0"
		Set tMeth3.ReturnType = "%Status"
		Set tMeth3.Description = "Create a temp file of all source ids.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth3.SequenceNumber = $I(tSeq) + 2000
		
		// DTB422 - tMeth4 is the %CheckSourceId method
		Set tMeth4 = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%CheckSourceId")
		Set tMeth4.Name = "%CheckSourceId"
		Set tMeth4.ClassMethod = 1
		Set tMeth4.FormalSpec = "pTestId:%String,pVerbose:%Boolean=0,*pSC:%Status"
		Set tMeth4.ReturnType = "%Boolean"
		Set tMeth4.Description = "Check for the existence of a single ID in the source table.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth4.SequenceNumber = $I(tSeq) + 2000

		// come up with cursor names for this class
		Set tCursorSq = ..%CreateCursorName("sq",tClassDefName) 
		Set tCursorSq2 = ..%CreateCursorName("sq2",tClassDefName)
		Set tCursorSq3 = ..%CreateCursorName("sq3",tClassDefName)
		Set tCursorEq = ..%CreateCursorName("sqeq",tClassDefName)
		Set tCursorList = ..%CreateCursorName("sqlist",tClassDefName)		// DTB976 - UPDATEFACTSTEMP ID list

		Set tPersistent = (pSourceType = "persistent")
		Set tKPI = (pSourceType = "kpi")||(pSourceType = "worksheet")||(pSourceType = "metric")
		// generate different code for different data sources
		If (tKPI) {
			// get data from KPI
			Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth.Implementation.WriteLine(" Set logStatus = $$$OK")
			Do tMeth.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")
			Do tMeth2.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth2.Implementation.WriteLine(" Set logStatus = $$$OK")
			Do tMeth2.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")

			Do tMeth3.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth3.Implementation.WriteLine(" Set pImplemented = 0")
			
			// DTB422
			Do tMeth4.Implementation.WriteLine(" // Method generation added by DTB422")
			Do tMeth4.Implementation.WriteLine(" Set tSourceExists = 0")
			Do tMeth4.Implementation.WriteLine(" Set pSC = $$$OK")
			Do tMeth4.Implementation.WriteLine(" Try {")

			Do tMeth.Implementation.WriteLine(" Try {")
			Do tMeth.Implementation.WriteLine(" Set tUseFactList = ($G(pFactList)'="""")")		// DTB893 - Test for factList
			Do tMeth.Implementation.WriteLine(" Set (tStarId,tRecord) = """"")
			Do tMeth.Implementation.WriteLine(" Set pUpdates = 0")
			Do tMeth.Implementation.WriteLine(" Set tLastCount = 0")

			Do tMeth2.Implementation.WriteLine(" Try {")
			Do tMeth2.Implementation.WriteLine(" Set tUseFactList = ($G(pFactList)'="""")")		// DTB893 - Test for factList
			Do tMeth2.Implementation.WriteLine(" Set (tStarId,tRecord) = """"")
			Do tMeth2.Implementation.WriteLine(" Set tLastCount = 0")

			Do tMeth3.Implementation.WriteLine(" Try {")
		}
		ElseIf ('tPersistent) {
			// get data from data connector API
			Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth.Implementation.WriteLine(" Set logStatus = $$$OK")
			Do tMeth.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")
			Do tMeth2.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth2.Implementation.WriteLine(" Set logStatus = $$$OK")
			Do tMeth2.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")
			Do tMeth3.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth3.Implementation.WriteLine(" Set pImplemented = 0")
			
			// DTB422
			Do tMeth4.Implementation.WriteLine(" // Method generation added by DTB422")
			Do tMeth4.Implementation.WriteLine(" Set tSourceExists = 0")
			Do tMeth4.Implementation.WriteLine(" Set pSC = $$$OK")
			Do tMeth4.Implementation.WriteLine(" Try {")

			Do tMeth.Implementation.WriteLine(" Try {")
			Do tMeth.Implementation.WriteLine(" Set tUseFactList = ($G(pFactList)'="""")")		// DTB893 - Test for factList
			Do tMeth.Implementation.WriteLine(" Set (tStarId,tRecord) = """"")
			Do tMeth.Implementation.WriteLine(" Set pUpdates = 0")
			Do tMeth.Implementation.WriteLine(" Set tLastCount = 0")

			Do tMeth2.Implementation.WriteLine(" Try {")
			Do tMeth2.Implementation.WriteLine(" Set tUseFactList = ($G(pFactList)'="""")")		// DTB893 - Test for factList
			Do tMeth2.Implementation.WriteLine(" Set (tStarId,tRecord) = """"")
			Do tMeth2.Implementation.WriteLine(" Set tLastCount = 0")

			Do tMeth3.Implementation.WriteLine(" Try {")
		}
		Else {
			// generate queries against source class
			Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth.Implementation.WriteLine(" Set logStatus = $$$OK")
			Do tMeth.Implementation.WriteLine(" Set tRS = """"")
			Do tMeth.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")
			Do tMeth2.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth2.Implementation.WriteLine(" Set logStatus = $$$OK")
			Do tMeth2.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")
			Do tMeth3.Implementation.WriteLine(" Set tSC = $$$OK")
			Do tMeth3.Implementation.WriteLine(" New %var,%source,%ROWID,%msg,%dsSourceId,%dsSourceObj")
			Do tMeth3.Implementation.WriteLine(" Set pImplemented = 1")
			
			// DTB422
			Do tMeth4.Implementation.WriteLine(" // Method generation added by DTB422") 
			Do tMeth4.Implementation.WriteLine(" Set tSourceExists = 0")
			Do tMeth4.Implementation.WriteLine(" Set pSC = $$$OK")
			Do tMeth4.Implementation.WriteLine(" Try {")

			Do tMeth.Implementation.WriteLine(" Try {")
			Do tMeth.Implementation.WriteLine(" Set tUseFactList = ($G(pFactList)'="""")")		// DTB893 - Test for factList
			Do tMeth.Implementation.WriteLine(" Set (SQLCODE,tStarId) = """"")
			Do tMeth.Implementation.WriteLine(" Set pUpdates = 0")
			Do tMeth.Implementation.WriteLine(" Set tLastCount = 0")

			Do tMeth2.Implementation.WriteLine(" Try {")
			Do tMeth2.Implementation.WriteLine(" Set tUseFactList = ($G(pFactList)'="""")")		// DTB893 - Test for factList
			Do tMeth2.Implementation.WriteLine(" Set (SQLCODE,tStarId) = """"")
			Do tMeth2.Implementation.WriteLine(" Set tLastCount = 0")

			Do tMeth3.Implementation.WriteLine(" Try {")
			Do tMeth3.Implementation.WriteLine(" Set (SQLCODE,tStarId) = """"")
			Do tMeth3.Implementation.WriteLine(" Set:($G(pTempKey)="""") pTempKey = "_$$$quote(tCubeName))	// DP-413600
			Do tMeth3.Implementation.WriteLine(" Kill $$$DeepSeeTempSourceId("_$$$quote(tCubeName)_")")		// DP-412844 - Clear out all previous temp results

			#; generate query against source table
			Set tSourceTableName = ..%GetSQLTableName(pCube.sourceClass)
			If (tSourceTableName = "") {
				Set tSC = $$$ERROR($$$GeneralError,"No source table specified '" _ pCube.sourceClass _ "'")
				Quit
			}
			
			#; + DP-404002 Moved the following set out of the tSelectList while loop
			#; Dave V's recommended approach for checking if a table is external
			Set tExternalTable=($$$defMemberKeyGet(pCube.sourceClass,$$$cCLASSparameter,"CONNECTION",$$$cPARAMdefault)'="")
			#; - DP-404002 
			
			#; generate 3 queries for %UpdateFacts: 2 embedded and 1 dynamic
			#; 1 embedded uses BETWEEN, the other =
			#; we use the dynamic one for processing changes to source reference tables

			#; tSourceID is hard-coded as "%ID" (which is fine for ISC products), but if the source table is linked,
			#; it may be mapped with a different name. In order to mitigate any problems with name resolution,
			#; DP-403766 imposes a constraint that the first column _must_ be the row ID
			Set tSourceId = "%ID"
			Set SELECT = tSourceId		// between & equals
			Set SELECTDYN = tSourceId	// dynamic
			Set INTO = " :tID"
			Set f = $O(tSelectList(""))
			While (f '= "") {
				Set tFName = $P(f,"~~",1)	// JMD1184
				Set tFModifier = $P(f,"~~",2)
				// translate fx from property to field name
				If ($G(tLocalSelectList(f))'="") {
					// if there is a local override, select that and provide an alias
					// to the real name
					Set fld = ..%GetSQLFieldExpression(.tSC,pCube.sourceClass,tLocalSelectList(f),1)
				    If $$$ISERR(tSC) Quit
				}
				Else {
					Set fld = ..%GetSQLFieldExpression(.tSC,pCube.sourceClass,tFName,1)
				    If $$$ISERR(tSC) Quit
				}

			    // apply %EXTERNAL if useDisplay is in effect
			    // ignore this for linked tables as SQL cannot handle this!
				// JMD1184 remove tDisplay, use modifier
			    If ((tFModifier="EXTERNAL")&&'tExternalTable) {
					Set fld =  "%EXTERNAL(" _ fld _ ")"
				}

				// use fact name as alias for each column (unless it is the same)
				Set SELECT = SELECT _ "," _ fld
				Set:(fld'=tSelectList(f)) SELECT = SELECT _ " " _ $$$quoteIfDelimId(tSelectList(f)) // JSL4470 only quote if delimited identifiers is on
				Set SELECTDYN = SELECTDYN _ "," _ fld
				Set:(fld'=tSelectList(f)) SELECTDYN = SELECTDYN _ " " _ $$$quoteIfDelimId(tSelectList(f)) // JSL4470 only quote if delimited identifiers is on

				Set INTO = INTO _ ",:%var("_$$$quote(tSelectList(f))_")"
				Set f = $O(tSelectList(f))
			}
		    If $$$ISERR(tSC) Quit

			// pick up additional fields that are referred to by expressions
			Set f = $O(tXFormProps(""))
			While (f '= "") {
				// translate f from property to field name
				Set fld = ..%GetSQLFieldExpression(.tSC,pCube.sourceClass,f,1)
			    If $$$ISERR(tSC) Quit

				// make sure propname is valid sql (without delim idents)
				Set fq = $TR(f,".","_")
				if '$$$DelIds {
					Set fq=$e(fq)_$tr($e(fq,2,*),"%","x")
				}

				// n.b., %source is subscripted by source name
				Set SELECT = SELECT _ "," _ fld
				Set:fq'=fld SELECT = SELECT _ " " _ $$$quoteIfDelimId(fq) // alias // JSL4470 only quote if delimited identifiers is on
				Set SELECTDYN = SELECTDYN _ "," _ fld
				Set:fq'=fld SELECTDYN = SELECTDYN _ " " _ $$$quoteIfDelimId(fq) // alias // JSL4470 only quote if delimited identifiers is on
				Set INTO = INTO _ ",:%source("_$$$quote(f)_")"	// don't use esc'd name!
				Set f = $O(tXFormProps(f))
			}
		    If $$$ISERR(tSC) Quit

			Set tSELRESTRICT = ""
			If (pCube.buildRestriction'="") {
				// for queries used for update, add restrict expression to SELECT list
				Set tSELRESTRICT = ", CASE WHEN " _ pCube.buildRestriction _ " THEN 1 ELSE 0 END IrisBITest"		// DP-432576 - Rename test alias
				Set INTO1 = " INTO " _ INTO _ ", :tTest"
			}
			Else {
				Set INTO1 = " INTO" _ INTO
			}
			Set INTO2 = " INTO" _ INTO
			Set INTO3 = " INTO :tID"

			// + DP-403766	Switches the position of SELECT[DYN] and tSELRESTRICT so that the first column is the row ID
			Set SQL = "SELECT " _ SELECT _ tSELRESTRICT _ " FROM " _ tSourceTableName
			Set SQLDYN = "SELECT " _ SELECTDYN _ tSELRESTRICT _ " FROM " _ tSourceTableName
			// - DP-403766

			// no WHERE clause for %BuildAll (unless user supplied one)
			Set SQL2 = "SELECT " _ $S(+pCube.maxFacts>0:"TOP ("_pCube.maxFacts_") ",1:"") _ SELECT _ " FROM " _ tSourceTableName
			// SQL3 for BuildTempFile
			Set SQL3 = "SELECT " _ $S(+pCube.maxFacts>0:"TOP ("_pCube.maxFacts_") ",1:"") _ tSourceId _ " FROM " _ tSourceTableName
			If (pCube.buildRestriction'="") {
				Set SQL2 = SQL2 _ " WHERE " _ pCube.buildRestriction
				Set SQL3 = SQL3 _ " WHERE " _ pCube.buildRestriction
			}
			If (pCube.initialBuildOrder'="") {
				Set SQL2 = SQL2 _ " ORDER BY " _ pCube.initialBuildOrder
				Set SQL3 = SQL3 _ " ORDER BY " _ pCube.initialBuildOrder
			}

			Set SQLEQ = SQL _ $C(13,10) _ "  WHERE "_tSourceId_" = :pStartId"
			Set SQLLIST = SQL _ $C(13,10) _ "  WHERE "_tSourceId_" IN (SELECT sourceId FROM %DeepSee.TempSourceId WHERE (cubeName = '"_tCubeName_"') AND (action <= 2) AND (chunk = :tChunk))"		// DP-412844 - Use subquery
			Set SQL = SQL _ $C(13,10) _ "  WHERE "_tSourceId_" BETWEEN :pStartId  AND :pEndId"
			
			// DTB422 - SQL to check existence of a single ID
			Set tSQLIdCheck = "SELECT COUNT(%ID) INTO :tExists FROM "_tSourceTableName_" WHERE %ID = :pTestId"
			
		} // tPersistent

		Do tMeth.Implementation.WriteLine(" Set tID = """"")
		Do tMeth.Implementation.WriteLine(" Set tRows = 0")
		
		// + DTB976 - Set up the %INLIST argument
		Do tMeth.Implementation.WriteLine("")
		Do tMeth.Implementation.WriteLine(" Set tUseIDList = 0")
 		Do tMeth.Implementation.WriteLine(" If ($G(pStartId)'="""")&&$ListValid(pStartId) {")
		Do tMeth.Implementation.WriteLine("  Set tUseIDList = 1")		// DP-412844 - Set the flag for quick reference to denote batch mode
	 	Do tMeth.Implementation.WriteLine("  Set tTempFileKey = $LG(pStartId,1)")
	 	Do tMeth.Implementation.WriteLine("  Set tChunk = $LG(pStartId,2)")
		Do tMeth.Implementation.WriteLine("  Set tIDUpdateTempList = """"")
		Do tMeth.Implementation.WriteLine("")
		
		If +$G(tExternalTable) {
		// DP-413600 - External tables cannot use %-functions in their SQL statements. Build the update list to
		// deliver a standard IN clause to the remote DB 
	 	Do tMeth.Implementation.WriteLine("  If $D($$$DeepSeeTempSourceId(tTempFileKey,tChunk)) {")
		Do tMeth.Implementation.WriteLine("   Set tSourceId = $O($$$DeepSeeTempSourceId(tTempFileKey,tChunk,""""),1,tOffsetInfo)") 
		Do tMeth.Implementation.WriteLine("   While tSourceId'="""" {")
		Do tMeth.Implementation.WriteLine("    Set tUseIDList = 1")
		Do tMeth.Implementation.WriteLine("    Set tAction = $LG(tOffsetInfo,2)")
		Do tMeth.Implementation.WriteLine("    Set:(tAction<=2) tIDUpdateTempList = tIDUpdateTempList _ $S($L(tIDUpdateTempList):"","",1:"""") _ tSourceId")
		Do tMeth.Implementation.WriteLine("    Set tSourceId = $O($$$DeepSeeTempSourceId(tTempFileKey,tChunk,tSourceId),1,tOffsetInfo)")
		Do tMeth.Implementation.WriteLine("   } // while sourceId")
		Do tMeth.Implementation.WriteLine("  Set:($G(tIDUpdateTempList)="""") tIDUpdateTempList = 0")
		Do tMeth.Implementation.WriteLine("  } // if temp sourceId data")
		Do tMeth.Implementation.WriteLine("")
		}

 		Do tMeth.Implementation.WriteLine(" } // if pStartId is list")
		Do tMeth.Implementation.WriteLine("")
		// - DTB976
		
		
		Do tMeth.Implementation.WriteLine(" If (pEndId="""")&&'tUseIDList {")		// DTB976

		// single fact or reference update, use read committed!
		// JMD1033: test flag
		Do tMeth.Implementation.WriteLine("  Set:+$G(%dsReadCommitted,1) oldzu=$ZU(115,2,1)")
		Do tMeth.Implementation.WriteLine("  Set pEndId=pStartId")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth2.Implementation.WriteLine(" Set tID = """"")
		Do tMeth2.Implementation.WriteLine(" Set tRows = 0")

		Do tMeth3.Implementation.WriteLine(" Set tID = """"")
		Do tMeth3.Implementation.WriteLine(" Set tRows = 0")
		Do tMeth3.Implementation.WriteLine(" Set tUpdate = ..%Count()")		// DTB927 - Check the current size of the fact table

		If (tKPI) {
			// get data from kpi into %var
			Set tExt = $P(pCube.sourceClass,".",$L(pCube.sourceClass,"."))
			If (tExt="kpi") {
				Set tName = $P(pCube.sourceClass,".",1,$L(pCube.sourceClass,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				Set tName = ""
			}
			ElseIf (tExt="worksheet") {
				Set tName = pCube.sourceClass
				Set tKPIClass = "%DeepSee.KPIWorksheet"
			}
			Else {
				Set tName = pCube.sourceClass
				Set tKPIClass = "Ens.BusinessMetricKPI"
			}

			Do tMeth.Implementation.WriteLine(" New %datacontroller")
			Do tMeth.Implementation.WriteLine(" Set tCriteria = ##class(%ZEN.proxyObject).%New()")
			Do tMeth.Implementation.WriteLine(" Set tSC = ##class(%DeepSee.AbstractKPI).%CreateLocalController(.tController,"_$$$quote(tKPIClass)_","_$$$quote(tName)_",tCriteria)")
			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
			Do tMeth.Implementation.WriteLine(" Set %datacontroller = tController")

			Do tMeth.Implementation.WriteLine(" Set tSC = tController.%AcquireData()")
			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			Do tMeth2.Implementation.WriteLine(" New %datacontroller")
			Do tMeth2.Implementation.WriteLine(" Set tCriteria = ##class(%ZEN.proxyObject).%New()")
			Do tMeth2.Implementation.WriteLine(" Set tSC = ##class(%DeepSee.AbstractKPI).%CreateLocalController(.tController,"_$$$quote(tKPIClass)_","_$$$quote(tName)_",tCriteria)")
			Do tMeth2.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
			Do tMeth2.Implementation.WriteLine(" Set %datacontroller = tController")

			Do tMeth2.Implementation.WriteLine(" Set tSC = tController.%AcquireData()")
			Do tMeth2.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			Do tMeth2.Implementation.WriteLine(" Set tSeriesCount = tController.dataBag.seriesCount")
			If (+pCube.maxFacts>0) {
				Do tMeth2.Implementation.WriteLine(" Set:tSeriesCount>"_+pCube.maxFacts_" tSeriesCount = " _ +pCube.maxFacts)
			}

			// loop
			Do tMeth.Implementation.WriteLine(" For tSingleId = pStartId:1:pEndId {")
			Do tMeth.Implementation.WriteLine(" Kill %var")
			Do tMeth.Implementation.WriteLine(" Set tID = tSingleId")

			// loop
			Do tMeth2.Implementation.WriteLine(" For tID = 1:1:tSeriesCount {")
			Do tMeth2.Implementation.WriteLine(" Kill %var")

			// copy
			Set f = $O(tSelectList(""))
			While (f '= "") {
				Set tFName = $P(f,"~~",1)	// JMD1184

				// $$$ZENMISSING is $C(1,1,1)
				Do tMeth.Implementation.WriteLine(" Set tValue = tController.dataBag.%GetValue("_$$$quote(tFName)_",tID)")
				Do tMeth.Implementation.WriteLine(" Set:(tValue=$C(1,1,1)) tValue=""""")
				Do tMeth.Implementation.WriteLine(" Set %var("_$$$quote(tSelectList(f))_") = tValue")

				Do tMeth2.Implementation.WriteLine(" Set tValue = tController.dataBag.%GetValue("_$$$quote(tFName)_",tID)")
				Do tMeth2.Implementation.WriteLine(" Set:(tValue=$C(1,1,1)) tValue=""""")
				Do tMeth2.Implementation.WriteLine(" Set %var("_$$$quote(tSelectList(f))_") = tValue")
				Set f = $O(tSelectList(f))
			}

			// copy data into %source
			Set f = $O(tXFormProps(""))
			While (f '= "") {
				Do tMeth.Implementation.WriteLine(" Set tValue = tController.dataBag.%GetValue("_$$$quote(f)_",tID)")
				Do tMeth.Implementation.WriteLine(" Set:(tValue=$C(1,1,1)) tValue=""""")
				Do tMeth.Implementation.WriteLine(" Set %source("_$$$quote(f)_") = tValue")

				Do tMeth2.Implementation.WriteLine(" Set tValue = tController.dataBag.%GetValue("_$$$quote(f)_",tID)")
				Do tMeth2.Implementation.WriteLine(" Set:(tValue=$C(1,1,1)) tValue=""""")
				Do tMeth2.Implementation.WriteLine(" Set %source("_$$$quote(f)_") = tValue")
				Set f = $O(tXFormProps(f))
			}

		} // kpi
		ElseIf ('tPersistent) {
			Set tVersion = $zobjclassmethod(pCube.sourceClass,"%GetVersion")
			Set tSC = $zobjclassmethod(pCube.sourceClass,"%GetKeyFields",.tKeyFields)
		    If $$$ISERR(tSC) Quit

			If (tVersion'="") {
				Do tMeth.Implementation.WriteLine(" If ("_tVersion_"'=##class("_pCube.sourceClass_").%GetVersion()) {")
				Do tMeth.Implementation.WriteLine("  Set tSC = $$$ERROR($$$GeneralError,""DataConnector has different version than cube; recompile cube: "_pCube.name_""")")
				Do tMeth.Implementation.WriteLine("  Quit")
				Do tMeth.Implementation.WriteLine(" }")
			}

			// get data from dataconnector into %var
			// JMD841: Do tMeth.Implementation.WriteLine(" For tSingleId = pStartId:1:pEndId {")
			Do tMeth.Implementation.WriteLine(" Set tSingleId = pStartId")
			Do tMeth.Implementation.WriteLine(" While (tSingleId'="""") {")
			
			// WAL030 - try block begin for data connector case, %UpdateFacts
			Do tMeth.Implementation.WriteLine(" Try {")
			// WAL030

			Do tMeth.Implementation.WriteLine(" Kill %var")
			Do tMeth.Implementation.WriteLine(" Set tConnector = ##class("_pCube.sourceClass_").%New()")
			Do tMeth.Implementation.WriteLine(" Set tSC = tConnector.%SetMode(""single"")")
			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			Do tMeth.Implementation.WriteLine(" Set tSC = tConnector.%SetSingleId(tSingleId)")
			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			Do tMeth.Implementation.WriteLine(" Set tRecord = tConnector.%Execute(.tParms,.tSC)")
			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			// JMD1016: test if there is a record
			Do tMeth.Implementation.WriteLine(" If (tRecord.%Next(.tSC)) {")
			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			// create instance of data connector
			// check version #
			If (tVersion'="") {
				Do tMeth2.Implementation.WriteLine(" If ("_tVersion_"'=##class("_pCube.sourceClass_").%GetVersion()) {")
				Do tMeth2.Implementation.WriteLine("  Set tSC = $$$ERROR($$$GeneralError,""DataConnector has different version than cube; recompile cube: "_pCube.name_""")")
				Do tMeth2.Implementation.WriteLine("  Quit")
				Do tMeth2.Implementation.WriteLine(" }")
			}

			Do tMeth2.Implementation.WriteLine(" Set tConnector = ##class("_pCube.sourceClass_").%New()")
			Do tMeth2.Implementation.WriteLine(" Set tRecord = tConnector.%Execute(.tParms,.tSC)")
			Do tMeth2.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")

			If (+pCube.maxFacts<=0) {
				Do tMeth2.Implementation.WriteLine(" While(tRecord.%Next(.tSC)) {")
			}
			Else {
				// test count
				Do tMeth2.Implementation.WriteLine(" While((tRows<"_+pCube.maxFacts_")&&tRecord.%Next(.tSC)) {")
			}
			Do tMeth2.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
			Do tMeth2.Implementation.WriteLine(" Kill %var")

			// get sourceId (if any)
			If ($D(tKeyFields)) {
				Set kfx = ""
				Set f = $O(tKeyFields(""))
				While (f '= "") {
					Set kfx = kfx _ $S(kfx="":"",1:"_""||""_") _ "tRecord."_f
					Set f = $O(tKeyFields(f))
				}
				Do tMeth.Implementation.WriteLine(" Set tID = "_kfx)
				Do tMeth2.Implementation.WriteLine(" Set tID = "_kfx)
			}

			// copy
			Set f = $O(tSelectList(""))
			While (f '= "") {
				Set tFName = $P(f,"~~",1)	// JMD1184
				Do tMeth.Implementation.WriteLine(" Set %var("_$$$quote(tSelectList(f))_") = tRecord."_tFName)
				Do tMeth2.Implementation.WriteLine(" Set %var("_$$$quote(tSelectList(f))_") = tRecord."_tFName)
				Set f = $O(tSelectList(f))
			}

			// copy data into %source
			Set f = $O(tXFormProps(""))
			While (f '= "") {
				Do tMeth.Implementation.WriteLine(" Set %source("_$$$quote(f)_") = tRecord."_f)
				Do tMeth2.Implementation.WriteLine(" Set %source("_$$$quote(f)_") = tRecord."_f)
				Set f = $O(tXFormProps(f))
			}
			
			// +DTB422 - Open the connector and check the ID
			Do tMeth4.Implementation.WriteLine("  Set tConnector = ##class(DeepSee.Model.ConnectorExample).%New()")
			Do tMeth4.Implementation.WriteLine("  Set tSC = tConnector.%SetMode(""single"")")
			Do tMeth4.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
			Do tMeth4.Implementation.WriteLine("  Set tSC = tConnector.%SetSingleId(pTestId)")
			Do tMeth4.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
			Do tMeth4.Implementation.WriteLine("  Set tRecord = tConnector.%Execute(.tParms,.tSC)")
			Do tMeth4.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
			Do tMeth4.Implementation.WriteLine("  If (tRecord.%Next(.tSC)) {")
			Do tMeth4.Implementation.WriteLine("   If $$$ISERR(tSC) Quit")
			Do tMeth4.Implementation.WriteLine("   Set tSourceExists = 1")
			Do tMeth4.Implementation.WriteLine("  }")
			// -DTB422
		} // data connect
		Else {
			if tExternalTable {
				// + DP-403766
				//		DTB976/DP-14014 uses EmbeddedSQL to take advantage of a runtime generated $listbuild (tIDUpdateTempList), %INLIST and cursors.
				//		When the source table is a linked table, we cannot use %INLIST and instead must use IN (...). Since tIDUpdateTempList is runtime
				//		generated, we cannot employ EmbeddedSQL either. To minimize the changes between a non-linked source and linked source, when it's
				//		detected that the source is a linked table, we generate Dynamic SQL instead that still leverages tIDUpdateTempList. This also allows
				//		DP-403766 to hook onto the pre-existing data-fetch loop below.
				Do tMeth.Implementation.WriteLine(" If (tUseIDList) {")
				Do tMeth.Implementation.WriteLine("  Set tRS = ##class(%ResultSet).%New()")
				Do tMeth.Implementation.WriteLine("  Set tSC = tRS.Prepare("_$$$quote(SQLDYN_" WHERE " _ tSourceId _ " IN (") _ "_ tIDUpdateTempList _ "")"")")
				Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
				Do tMeth.Implementation.WriteLine("  Set tSC = tRS.Execute()")
				Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
				Do tMeth.Implementation.WriteLine(" }")
				// - DP-403766
			} else {
				// + DTB976 - Use cursor for bulk temp idlist
				Do tMeth.Implementation.WriteLine(" If (tUseIDList) {")
				Do tMeth.Implementation.WriteLine("  &sql(DECLARE "_tCursorList_" CURSOR FOR")
				Do tMeth.Implementation.WriteLine("  " _ SQLLIST)
				Do tMeth.Implementation.WriteLine("  )")
				Do tMeth.Implementation.WriteLine("  &sql(OPEN "_tCursorList_")")
				Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
				Do tMeth.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Error opening SQL cursor: (""_$G(SQLCODE)_"") ""_$G(%msg))")
				Do tMeth.Implementation.WriteLine("   Quit")
				Do tMeth.Implementation.WriteLine("  }")
				Do tMeth.Implementation.WriteLine("  &sql(FETCH "_tCursorList_INTO1_")")
				Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
				Do tMeth.Implementation.WriteLine("    Set tSC = $$$ERROR($$$GeneralError,""Error fetching row: (""_$G(SQLCODE)_"") ""_$G(%msg))")
				Do tMeth.Implementation.WriteLine("    &sql(CLOSE "_tCursorList_")")
				Do tMeth.Implementation.WriteLine("    If ($G(pStartId)'="""") {")
				Do tMeth.Implementation.WriteLine("    	 Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",pStartId,tSC) //APV100.1")
				Do tMeth.Implementation.WriteLine("    }")
				Do tMeth.Implementation.WriteLine("    Quit")
				Do tMeth.Implementation.WriteLine("  }")
				Do tMeth.Implementation.WriteLine(" }")
				// - DTB976
			}

			// If RefProp is provided we use dynamic SQL
			Do tMeth.Implementation.WriteLine(" ElseIf (pRefProp'="""") {")
			Do tMeth.Implementation.WriteLine("  Set tRS = ##class(%ResultSet).%New()")
			Do tMeth.Implementation.WriteLine("  Set tSC = tRS.Prepare("_$$$quote(SQLDYN)_"_"" WHERE ""_pRefProp_""=?"")")
			Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")

			Do tMeth.Implementation.WriteLine("  Set tSC = tRS.Execute(pRefID)")
			Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
			Do tMeth.Implementation.WriteLine(" }")

			// update eq
			Do tMeth.Implementation.WriteLine(" ElseIf (pStartId=pEndId) {")

			Do tMeth.Implementation.WriteLine("  &sql(DECLARE "_tCursorEq_" CURSOR FOR")
			Do tMeth.Implementation.WriteLine("  " _ SQLEQ)
			Do tMeth.Implementation.WriteLine("  )")
			Do tMeth.Implementation.WriteLine("  &sql(OPEN "_tCursorEq_")")
			Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Error opening SQL cursor: (""_$G(SQLCODE)_"") ""_$G(%msg))")
			Do tMeth.Implementation.WriteLine("   Quit")
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  &sql(FETCH "_tCursorEq_INTO1_")")
			// + WAL129 -- FETCH error handling
			Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth.Implementation.WriteLine("    Set tSC = $$$ERROR($$$GeneralError,""Error fetching row: (""_$G(SQLCODE)_"") ""_$G(%msg))")		// DTB371 - Set the status before closing the cursor
			Do tMeth.Implementation.WriteLine("    &sql(CLOSE "_tCursorEq_")")
			// + WAL243 -- report SQL cursor problems to build errors global
			Do tMeth.Implementation.WriteLine("    If ($G(pStartId)'="""") {")
			Do tMeth.Implementation.WriteLine("    	Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",pStartId,tSC) // APV100.2")		// DTB836 - Call API to log the error
			Do tMeth.Implementation.WriteLine("    }")
			// + WAL243 -- report SQL cursor problems to build errors global
			Do tMeth.Implementation.WriteLine("    Quit")
			Do tMeth.Implementation.WriteLine("  }")
			// - WAL129
			Do tMeth.Implementation.WriteLine(" }")

			// update
			Do tMeth.Implementation.WriteLine(" Else {")

			Do tMeth.Implementation.WriteLine("  &sql(DECLARE "_tCursorSq_" CURSOR FOR")
			Do tMeth.Implementation.WriteLine("  " _ SQL)
			Do tMeth.Implementation.WriteLine("  )")
			Do tMeth.Implementation.WriteLine("  &sql(OPEN "_tCursorSq_")")
			Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Error opening SQL cursor: (""_$G(SQLCODE)_"") ""_$G(%msg))")
			Do tMeth.Implementation.WriteLine("   Quit")
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  &sql(FETCH "_tCursorSq_INTO1_")")
			// + WAL129 -- FETCH error handling
			Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth.Implementation.WriteLine("    Set tSC = $$$ERROR($$$GeneralError,""Error fetching row: (""_$G(SQLCODE)_"") ""_$G(%msg))")		// DTB371 - Set the status before closing the cursor
			Do tMeth.Implementation.WriteLine("    &sql(CLOSE "_tCursorSq_")")
			// + WAL243 -- report SQL cursor problems to build errors global
			// WAL245 -- Check that tID exists
			Do tMeth.Implementation.WriteLine("    If ($G(tID)'="""") {")
			Do tMeth.Implementation.WriteLine("       Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",tID,tSC) //APV100.3")		// DTB836 - Call API to log the error
			Do tMeth.Implementation.WriteLine("    }")
			// - WAL243
			Do tMeth.Implementation.WriteLine("    Quit")
			Do tMeth.Implementation.WriteLine("  }")
			// - WAL129
			Do tMeth.Implementation.WriteLine(" }")

			// + DP-403766	%ID is not the column name for a linked table, but it's still the first column
			Do tMeth.Implementation.WriteLine(" set:$IsObject(tRS) idColName = tRS.GetColumnName(1)")
			// - DP-403766
			// loop
			Do tMeth.Implementation.WriteLine(" While ($S($IsObject(tRS):tRS.Next(.tSC),1:SQLCODE=0)) {")
			
			// WAL030 -- begin loop try block, cube case, %UpdateFacts
			Do tMeth.Implementation.WriteLine(" Try {")
			// WAL030

			// get values from RS
			Do tMeth.Implementation.WriteLine(" If ($IsObject(tRS)) {")
			Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")

			// get id value
			// + DP-403766	idColName is defined iff $IsObject(tRS) = 1
			Do tMeth.Implementation.WriteLine("  Set tID = $G(tRS.Data(idColName))")
			// - DP-403766
			If (pCube.buildRestriction'="") {
				// get "test" value
				Do tMeth.Implementation.WriteLine("  Set tTest = $G(tRS.Data("_$$$quote("IrisBITest")_"),1)")
			}

			// copy data into %var
			Set f = $O(tSelectList(""))
			While (f '= "") {
				Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(tSelectList(f))_") = $G(tRS.Data("_$$$quote(tSelectList(f))_"))")
				Set f = $O(tSelectList(f))
			}

			// copy data into %source
			Set f = $O(tXFormProps(""))
			While (f '= "") {
				Do tMeth.Implementation.WriteLine("  Set %source("_$$$quote(f)_") = $G(tRS.Data("_$$$quote(f)_"))")
				Set f = $O(tXFormProps(f))
			}

			Do tMeth.Implementation.WriteLine(" }")

			// build
			Do tMeth2.Implementation.WriteLine("  &sql(DECLARE "_tCursorSq2_" CURSOR FOR")
			Do tMeth2.Implementation.WriteLine("  " _ SQL2)
			Do tMeth2.Implementation.WriteLine("  )")
			Do tMeth2.Implementation.WriteLine("  &sql(OPEN "_tCursorSq2_")")
			Do tMeth2.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth2.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Error opening SQL cursor: (""_$G(SQLCODE)_"") ""_$G(%msg))")
			Do tMeth2.Implementation.WriteLine("   Quit")
			Do tMeth2.Implementation.WriteLine("  }")
			Do tMeth2.Implementation.WriteLine("  &sql(FETCH "_tCursorSq2_INTO2_")")
			Do tMeth2.Implementation.WriteLine("  If ((SQLCODE=100)&&pVerbose) {")
			Do tMeth2.Implementation.WriteLine("   Write ""No source data found."",!")
			Do tMeth2.Implementation.WriteLine("  }")
			Do tMeth2.Implementation.WriteLine("  While (SQLCODE=0) {")
			
			// build temp
			// DTB927 - If the fact table currently contains records, build the temp file from that information
			Do tMeth3.Implementation.WriteLine("  &sql(DECLARE "_tCursorSq3_"u CURSOR FOR")
			Do tMeth3.Implementation.WriteLine("  SELECT %sourceId FROM " _ tFactTableName)
			Do tMeth3.Implementation.WriteLine("  )")
			Do tMeth3.Implementation.WriteLine("  &sql(DECLARE "_tCursorSq3_"i CURSOR FOR")
			Do tMeth3.Implementation.WriteLine("  " _ SQL3)
			Do tMeth3.Implementation.WriteLine("  )")
			Do tMeth3.Implementation.WriteLine("  If tUpdate {")
			Do tMeth3.Implementation.WriteLine("   Set %dsmaxfacts = tUpdate")
			Do tMeth3.Implementation.WriteLine("   &sql(OPEN "_tCursorSq3_"u)")
			Do tMeth3.Implementation.WriteLine("  } Else {")
			Do tMeth3.Implementation.WriteLine("   &sql(OPEN "_tCursorSq3_"i)")
			Do tMeth3.Implementation.WriteLine("  }")
			Do tMeth3.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth3.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Error opening SQL cursor: (""_$G(SQLCODE)_"") ""_$G(%msg))")
			Do tMeth3.Implementation.WriteLine("   Quit")
			Do tMeth3.Implementation.WriteLine("  }")
			Do tMeth3.Implementation.WriteLine("  If tUpdate {")
			Do tMeth3.Implementation.WriteLine("   &sql(FETCH "_tCursorSq3_"u"_INTO3_")")
			Do tMeth3.Implementation.WriteLine("  } Else {")
			Do tMeth3.Implementation.WriteLine("   &sql(FETCH "_tCursorSq3_"i"_INTO3_")")
			Do tMeth3.Implementation.WriteLine("  }")
			Do tMeth3.Implementation.WriteLine("  If ((SQLCODE=100)&&pVerbose) {")
			Do tMeth3.Implementation.WriteLine("   Write ""No source data found."",!")
			Do tMeth3.Implementation.WriteLine("  }")
			Do tMeth3.Implementation.WriteLine("  While (SQLCODE=0) {")

			Do tMeth3.Implementation.WriteLine("  Set tRows = tRows+1")
			Do tMeth3.Implementation.WriteLine("  Set tChunk = tRows\64000+1")
			Do tMeth3.Implementation.WriteLine("  Set tOffset = tRows#64000+1")
			Do tMeth3.Implementation.WriteLine("  Set:tID'="""" $$$DeepSeeTempSourceId(pTempKey,tChunk,tID) = $LB("""",''tUpdate)")		// DP-412844 - Use the new table's storage format
			Do tMeth3.Implementation.WriteLine("  If (pVerbose&&'(tRows#10000)) Write $C(13,27)_""[0J""_""Building temp file: "",?25,$J($FN(tRows,"","",0),10),"" record(s) processed.""")

			Do tMeth3.Implementation.WriteLine("  If ($D(%dsmaxfacts)&&(tRows>=+$G(%dsmaxfacts))) Quit")
			
			// +DTB422
			Do tMeth4.Implementation.WriteLine("  &sql("_tSQLIdCheck_")")
  			Do tMeth4.Implementation.WriteLine("  If (tExists) {")
    		Do tMeth4.Implementation.WriteLine("   Set tSourceExists = 1")
  			Do tMeth4.Implementation.WriteLine("  }")
			// -DTB422
		} // tPersistent

		// check for local override of maxFacts
		Do tMeth2.Implementation.WriteLine("  If ($D(%dsmaxfacts)&&(tRows>=+$G(%dsmaxfacts))) Quit")
		
		// WAL030 -- start try block after maxfacts, data connector and cube, %BuildAllFacts
		If ('tKPI) {
			Do tMeth2.Implementation.WriteLine("  Try {")
		}
		// WAL030

		// apply date type conversions
		If $D(tDateTypeProps) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine(" #; apply date conversions")
			Do tMeth2.Implementation.WriteLine("")
			Do tMeth2.Implementation.WriteLine(" #; apply date conversions")

			Set p = $O(tDateTypeProps(""))
			While (p '= "") {
				// skip this field if it is in the alias list
				If ('$D(tCopyFromList(p))) {
					Do tMeth.Implementation.WriteLine(" Set %var("_$$$quote(p)_") = ##class(%DeepSee.Utils).%ConvertDate(%var("_$$$quote(p)_"),"_$$$quote(tDateTypeProps(p))_")")
					Do tMeth2.Implementation.WriteLine(" Set %var("_$$$quote(p)_") = ##class(%DeepSee.Utils).%ConvertDate(%var("_$$$quote(p)_"),"_$$$quote(tDateTypeProps(p))_")")
				}
				Set p = $O(tDateTypeProps(p))
			}
		}

		// if there are any "copy from" fields, get values for them
		If ($D(tCopyFromList)) {
			Do tMeth.Implementation.WriteLine(" #; Copy aliased fields")
			Do tMeth2.Implementation.WriteLine(" #; Copy aliased fields")
			Set f = $O(tCopyFromList(""))
			While (f '= "") {
				Set src = tCopyFromList(f)
				Do tMeth.Implementation.WriteLine(" Set %var("_$$$quote(f)_") = $G(%var("_$$$quote(src)_"))")		// DTB913
				Do tMeth2.Implementation.WriteLine(" Set %var("_$$$quote(f)_") = $G(%var("_$$$quote(src)_"))")		// DTB913
				Set f = $O(tCopyFromList(f))
			}
		}

		// make source id visible to expressions as %dsSourceId
		// define a holder for the source object (used by %Rule()), %dsSourceObj
		Do tMeth.Implementation.WriteLine(" Set %dsSourceId = $G(tID)")
		Do tMeth2.Implementation.WriteLine(" Set %dsSourceId = $G(tID)")

		// JMD944 Start expression time before local expressions
		Do tMeth.Implementation.WriteLine(" Set tExStartTime = $ZH")
		Do tMeth2.Implementation.WriteLine(" Set tExStartTime = $ZH")

		// Perform transform logic for *local* expressions
		If $D(tXFormCode) {
			Do tMeth.Implementation.WriteLine(" #; apply local expressions")
			Do tMeth2.Implementation.WriteLine(" #; apply local expressions")

			Set rk = $O(tExprRanked(""))
			While (rk'="") {
				Set f = $O(tExprRanked(rk,""))
				While (f'="") {
					Set tCode = tXFormCodeLocal(f)
					If (tCode '= "") {
						// replace method calls
						Set:$IsObject($G(%class)) tCode = $Replace(tCode,"%cube.","##class("_%class.Name_").")
						Set tCode = " Set %expression("_$$$quote(f)_") = " _ tCode
					}
					Else {
						Set tCode = " Set %expression("_$$$quote(f)_") = """""
					}
					Do tMeth.Implementation.WriteLine(tCode)
					Do tMeth2.Implementation.WriteLine(tCode)

					// next expr
					Set f = $O(tExprRanked(rk,f))
				}
				Set rk = $O(tExprRanked(rk))
			}
		}

		// Perform transform logic (from sourceExpressions)
		If $D(tXFormCode) {
			Do tMeth.Implementation.WriteLine(" #; apply source expressions")
			Do tMeth2.Implementation.WriteLine(" #; apply source expressions")
			Set f = $O(tXFormCode(""))
			While (f '= "") {
				Set tCode = tXFormCode(f)
				// JMD929: test for %value reference
				If (tCode [ "%value") {
					// pass properties used by this expression along
					For tx = "src","exp" {
						Set fxp = $O(tXFormCode(f,tx,""))
						While (fxp'="") {
							// store context as subnodes in %var;
							// write out code here
							Set tCode = " Set %var("_$$$quote(f)_","_$$$quote(tx)_","_$$$quote(fxp)_")="_$S(tx="exp":"%expression",1:"%source")_"("_$$$quote(fxp)_")"
							Do tMeth.Implementation.WriteLine(tCode)
							Do tMeth2.Implementation.WriteLine(tCode)
							Set fxp = $O(tXFormCode(f,tx,fxp))
						}
						Set fxp = $O(tXFormCode(f,""))
					}
					Set tCode = " Set %var("_$$$quote(f)_") = """""
				}
				ElseIf (tCode '= "") {
					// replace method calls
					Set:$IsObject($G(%class)) tCode = $Replace(tCode,"%cube.","##class("_%class.Name_").")
					Set tCode = " Set:('tUseFactList||$ListFind(pFactList,"_$$$quote(f)_")) %var("_$$$quote(f)_") = " _ tCode		// DTB893 - Suppress calculation if not in the fact list
				}
				Else {
					Set tCode = " Set %var("_$$$quote(f)_") = """""
				}

				Set tVirtual = +$G(pFactInfo("prop",f,"virtual"))
				If ('tVirtual) {
					Set tInsertList(f) = ""
				}
				Do tMeth.Implementation.WriteLine(tCode)
				Do tMeth2.Implementation.WriteLine(tCode)
				Set f = $O(tXFormCode(f))
			}
		}

		// JMD944: move timer logic outside of source expression block
		Do tMeth.Implementation.WriteLine(" Set x = $I(^IRIS.Temp.DeepSeeBuildStats($namespace,"_$$$quote($$$UPPER(pCube.name))_",""expr""),$ZH-tExStartTime)")
		Do tMeth2.Implementation.WriteLine(" Set x = $I(^IRIS.Temp.DeepSeeBuildStats($namespace,"_$$$quote($$$UPPER(pCube.name))_",""expr""),$ZH-tExStartTime)")

		// invoke the %ProcessFact method
		Do tMeth.Implementation.WriteLine("")
		If (pCube.buildRestriction'="") {
			// test if this row is in or out
			// DP-406811 - Add cache invalidation for facts removed by buildRestriction
			Do tMeth.Implementation.WriteLine(" If ('tTest) {")
			Do tMeth.Implementation.WriteLine("  Set tSC = ..%DeleteFact(tID,.tFactId)")
			Do tMeth.Implementation.WriteLine("  If $$$ISOK(tSC) {")
   			Do tMeth.Implementation.WriteLine("   Set:($G(tFactId)'="""") pChunks(tFactId\64000+1) = """"")
  			Do tMeth.Implementation.WriteLine("  }")
  			Do tMeth.Implementation.WriteLine("  Else {")
  			Do tMeth.Implementation.WriteLine("   Write ""Error deleting row: "",tID,!")
			Do tMeth.Implementation.WriteLine("   Write $System.Status.GetOneStatusText(tSC),!!")		// DTB301 - Improve error display
			Do tMeth.Implementation.WriteLine("   Set tSC = $$$OK")
  			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine(" }")
			Do tMeth.Implementation.WriteLine(" Else {")
		}

		Do tMeth.Implementation.WriteLine(" #; invoke method to process this fact")
		Do tMeth.Implementation.WriteLine(" Set tFactId = """"")
		Do tMeth.Implementation.WriteLine(" Set tSC = ##class("_tClassDefName_").%ProcessFact(tID,pBatchMode,.%var,.tFactId,.tErrorMsg,.pDimTables,,pFactList,.tUpdater)")		// DTB886 - Pass pFactList	// DTB913 - Pass an iterator by reference

		Do tMeth2.Implementation.WriteLine("")
		Do tMeth2.Implementation.WriteLine(" #; invoke method to process this fact")
		Do tMeth2.Implementation.WriteLine(" Set tFactId = """"")
		Do tMeth2.Implementation.WriteLine(" Set tSC = ##class("_tClassDefName_").%ProcessFact(tID,1,.%var,.tFactId,.tErrorMsg,,,pFactList,.tUpdater)")		// DTB886 - Pass pFactList	// DTB913 - Pass an iterator by reference

		// find bitmap chunk(s) affected by this update (but not for BuildAll)
		Do tMeth.Implementation.WriteLine(" If (tFactId'="""") {")

		Do tMeth.Implementation.WriteLine(" If $$$ISOK(tSC) {")
		Do tMeth.Implementation.WriteLine("  Set pUpdates = pUpdates+1")
		Do tMeth.Implementation.WriteLine("  Set pChunks(tFactId\64000+1) = """"")
		Do tMeth.Implementation.WriteLine(" }")
 		Do tMeth.Implementation.WriteLine(" ElseIf (pVerbose) {")
		Do tMeth.Implementation.WriteLine("  Write ""Error filing row: "",tID,!")
		Do tMeth.Implementation.WriteLine("  Write:tErrorMsg'="""" tErrorMsg,!")
		Do tMeth.Implementation.WriteLine("  Write $System.Status.GetOneStatusText(tSC),!!")		// DTB301 - Improve error display
		Do tMeth.Implementation.WriteLine("  Set tSC = $$$OK")
 		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth2.Implementation.WriteLine(" Set:$$$ISERR(tSC) err = $I(%dserrcount)")
		Do tMeth2.Implementation.WriteLine(" If ($$$ISERR(tSC)&&pVerbose) {")
		Do tMeth2.Implementation.WriteLine("  Write ""Error filing row: "",tID,!")
		Do tMeth2.Implementation.WriteLine("  Write:tErrorMsg'="""" tErrorMsg,!")
		Do tMeth2.Implementation.WriteLine("  Write $System.Status.GetOneStatusText(tSC),!!")		// DTB301 - Improve error display
		Do tMeth2.Implementation.WriteLine("  Set tSC = $$$OK")
 		Do tMeth2.Implementation.WriteLine(" }")

		// we only need to pass DimTables in for the first time
		Do tMeth.Implementation.WriteLine(" Kill pDimTables")
		Do tMeth.Implementation.WriteLine(" Set tRows = tRows + 1")
		Do tMeth.Implementation.WriteLine(" If (pVerbose&&'(tRows#1000)) Write $C(13,27)_""[0J""_""Building fact table: "",?25,$J($FN(tRows,"","",0),10),"" fact(s) updated.""")
		Do tMeth.Implementation.WriteLine(" If (pVerbose&&'(tRows#1000)&&(+$G(%dserrcount))) Write "" "",$J($FN(%dserrcount,"","",0),10),"" error(s)""")

		Do tMeth2.Implementation.WriteLine(" If (tFactId'="""") {")
		Do tMeth2.Implementation.WriteLine("  Set tRows = tRows + 1")
		Do tMeth2.Implementation.WriteLine("  Set %dsfactcount = tRows")		// DTB794 - Always set the fact count for later reference
		Do tMeth2.Implementation.WriteLine("  If (pVerbose&&'(tRows#1000)) Write $C(13,27)_""[0J""_""Building fact table: "",?25,$J($FN(tRows,"","",0),10),"" fact(s) updated.""")
		Do tMeth2.Implementation.WriteLine("  If (pVerbose&&'(tRows#1000)&&(+$G(%dserrcount))) Write "" "",$J($FN(%dserrcount,"","",0),10),"" error(s)""")
		Do tMeth2.Implementation.WriteLine(" } ;factId")
		
		// WAL030 -- If a source expression fails in %BuildAllFacts, log it an continue building
		// data connector and cube cases
		If ('tKPI) {
			Do tMeth2.Implementation.WriteLine("  }")
			Do tMeth2.Implementation.WriteLine("  Catch (ex) {")
			Do tMeth2.Implementation.WriteLine("    Set tSC = ex.AsStatus()")
			Do tMeth2.Implementation.WriteLine("    If ($G(tID)'="""") {")
			Do tMeth2.Implementation.WriteLine("      Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",tID,tSC) //APV100.4")		// DTB836 - Call API to log the error
			Do tMeth2.Implementation.WriteLine("      If '$$$ISERR(logStatus) Set tSC=$$$OK //reset error and build next fact") 
			Do tMeth2.Implementation.WriteLine("    }")
			Do tMeth2.Implementation.WriteLine("  }")		
			Do tMeth2.Implementation.WriteLine("  If $$$ISERR(logStatus) Quit //APV100Q1")
		}
		// WAL030

		Do tMeth.Implementation.WriteLine(" If ((pTaskGroup'="""")&&'(tRows#1000)) {")
		Do tMeth.Implementation.WriteLine("  Set tDelta = tRows - tLastCount")
		Do tMeth.Implementation.WriteLine("  Set inc=$I(^IRIS.Temp.DeepSeeUpdate($namespace,pTaskGroup,""facts""),tDelta)")
		Do tMeth.Implementation.WriteLine("  Set tLastCount = tRows")
		Do tMeth.Implementation.WriteLine(" }")
		
		// end of If (tFactId'="")
		Do tMeth.Implementation.WriteLine(" } ;factId")

		If (pCube.buildRestriction'="") {
			// end of if (tTest)
			Do tMeth.Implementation.WriteLine(" }")
		}

		If (tKPI) {
			Do tMeth.Implementation.WriteLine(" } ;while")
			Do tMeth2.Implementation.WriteLine(" } ;while")

			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
			Do tMeth2.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
		}
		ElseIf ('tPersistent) {
			// JMD1016: end of record test
			Do tMeth.Implementation.WriteLine(" } ;if %Next")
								
			// WAL030 -- If a source expression fails in Data Connector %UpdateFacts, log it and continue building
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  Catch (ex) {")
			Do tMeth.Implementation.WriteLine("    Set tSC = ex.AsStatus()")
			Do tMeth.Implementation.WriteLine("    If ($G(tID)'="""") {")
			Do tMeth.Implementation.WriteLine("      Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",tID,tSC)  //APV100.5")		// DTB836 - Call API to log the error
			Do tMeth.Implementation.WriteLine("      If '$$$ISERR(logStatus) Set tSC=$$$OK //reset error and build next fact")
			Do tMeth.Implementation.WriteLine("    }")
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  If $$$ISERR(logStatus) Quit //APV100Q2")
			// WAL030

			// end of loop test
			Do tMeth.Implementation.WriteLine(" Set tSingleId=$S(pStartId=pEndId:"""",1:tSingleId+1)")
			Do tMeth.Implementation.WriteLine(" } ;while")
			Do tMeth2.Implementation.WriteLine(" } ;while")

			Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
			Do tMeth2.Implementation.WriteLine(" If $$$ISERR(tSC) Quit")
		}
		Else {
			
			// WAL030 -- If a source expression fails in cube %UpdateFacts, log it and continue building
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  Catch (ex) {")
			Do tMeth.Implementation.WriteLine("    Set tSC = ex.AsStatus()")
			Do tMeth.Implementation.WriteLine("    If ($G(tID)'="""") {")
			Do tMeth.Implementation.WriteLine("      Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",tID,tSC) //APV100.6")		// DTB836 - Call API to log the error
			Do tMeth.Implementation.WriteLine("      //APV081 - Since the build error has already been logged above, reset tSC to prevent it from erroneously being returned and possibly causing the build to fail")
			Do tMeth.Implementation.WriteLine("      If '$$$ISERR(logStatus) Set tSC=$$$OK //reset error and build next fact")
			Do tMeth.Implementation.WriteLine("    }")
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  If $$$ISERR(logStatus) Quit //APV100Q4")
			// WAL030
			
			Do tMeth.Implementation.WriteLine("  If '$IsObject(tRS) {")
			
			// FETCH section if using an embedded SQL cursor
			// DTB976 - Cursor using 'sourceId %INLIST'
			Do tMeth.Implementation.WriteLine("   If (tUseIDList) {")
			Do tMeth.Implementation.WriteLine("    " _ $select(tExternalTable: "// Source is a link table; dynamicSQL is used instead.", 1:"&sql(FETCH "_tCursorList_INTO1_")"))
			Do tMeth.Implementation.WriteLine("   }")
			// Cursor using 'sourceId = pStartId'
			Do tMeth.Implementation.WriteLine("   ElseIf (pStartId=pEndId) {")
			Do tMeth.Implementation.WriteLine("    &sql(FETCH "_tCursorEq_INTO1_")")
			Do tMeth.Implementation.WriteLine("   }")
			// Cursor using 'sourceId BETWEEN pStartId AND pEndId'
			Do tMeth.Implementation.WriteLine("   Else {")
			Do tMeth.Implementation.WriteLine("    &sql(FETCH "_tCursorSq_INTO1_")")
			Do tMeth.Implementation.WriteLine("   }")
			Do tMeth.Implementation.WriteLine("  }")
			
			Do tMeth2.Implementation.WriteLine("  &sql(FETCH "_tCursorSq2_INTO2_")")
			Do tMeth3.Implementation.WriteLine("  If tUpdate {")
			Do tMeth3.Implementation.WriteLine("   &sql(FETCH "_tCursorSq3_"u"_INTO3_")")
			Do tMeth3.Implementation.WriteLine("  } Else {")
			Do tMeth3.Implementation.WriteLine("   &sql(FETCH "_tCursorSq3_"i"_INTO3_")")
			Do tMeth3.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine(" } ;while")
			Do tMeth2.Implementation.WriteLine(" } ;while")
			Do tMeth3.Implementation.WriteLine(" } ;while")

			Do tMeth.Implementation.WriteLine("  If '$IsObject(tRS) {")
			
			
			// CLOSE section if using an embedded SQL cursor
			// DTB976 - Cursor using 'sourceId %INLIST'
			Do tMeth.Implementation.WriteLine("   If (tUseIDList) {")
			Do tMeth.Implementation.WriteLine("    " _ $select(tExternalTable: "// Source is a link table; dynamicSQL is used instead.", 1:"&sql(CLOSE "_tCursorList_")"))
			Do tMeth.Implementation.WriteLine("   }")
			// Cursor using 'sourceId = pStartId'
			Do tMeth.Implementation.WriteLine("   ElseIf (pStartId=pEndId) {")
			Do tMeth.Implementation.WriteLine("    &sql(CLOSE "_tCursorEq_")")
			Do tMeth.Implementation.WriteLine("   }")
			// Cursor using 'sourceId BETWEEN pStartId AND pEndId'
			Do tMeth.Implementation.WriteLine("   Else {")
			Do tMeth.Implementation.WriteLine("    &sql(CLOSE "_tCursorSq_")")
			Do tMeth.Implementation.WriteLine("   }")
			Do tMeth.Implementation.WriteLine("  }")
			
			Do tMeth2.Implementation.WriteLine("  &sql(CLOSE "_tCursorSq2_")")
			Do tMeth3.Implementation.WriteLine("  If tUpdate {")
			Do tMeth3.Implementation.WriteLine("   &sql(CLOSE "_tCursorSq3_"u)")
			Do tMeth3.Implementation.WriteLine("  } Else {")
			Do tMeth3.Implementation.WriteLine("   &sql(CLOSE "_tCursorSq3_"i)")
			Do tMeth3.Implementation.WriteLine("  }")
		}
		// n.b., in batch mode, indices are built by task manager

		Do tMeth.Implementation.WriteLine(" If (pVerbose) Write $C(13,27)_""[0J""_""Building fact table: ""_$FN(+$G(tRows),"","",0)_"" fact(s) updated""")
		Do tMeth2.Implementation.WriteLine(" If (pVerbose) Write $C(13,27)_""[0J""_""Building fact table: ""_$FN(+$G(tRows),"","",0)_"" fact(s) updated""")
		Do:tPersistent tMeth3.Implementation.WriteLine(" If (pVerbose) Write $C(13,27)_""[0J""_""Building temp file: ""_$FN(+$G(tRows),"","",0)_"" record(s) processed""")

		Do tMeth.Implementation.WriteLine(" If (pTaskGroup'="""") {")
		Do tMeth.Implementation.WriteLine("  Set tDelta = tRows - tLastCount")
		Do tMeth.Implementation.WriteLine("  Set inc=$I(^IRIS.Temp.DeepSeeUpdate($namespace,pTaskGroup,""facts""),tDelta)")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth.Implementation.WriteLine(" }") // try
		Do tMeth.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")

		If ('tKPI && tPersistent) {
			// JMD1326: make sure cursor gets closed
			Do tMeth.Implementation.WriteLine("  &sql(CLOSE "_tCursorEq_")")
			Do tMeth.Implementation.WriteLine("  &sql(CLOSE "_tCursorSq_")")
		}
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth2.Implementation.WriteLine(" }") // try
		Do tMeth2.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth2.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
		// JMD1326: make sure cursor gets closed
		If ('tKPI && tPersistent) {
			Do tMeth2.Implementation.WriteLine("  &sql(CLOSE "_tCursorSq2_")")
		}
		Do tMeth2.Implementation.WriteLine(" }")
		Do tMeth2.Implementation.WriteLine(" If $$$ISERR(logStatus) Quit logStatus //APV100QL1")
		Do tMeth3.Implementation.WriteLine(" }") // try
		Do tMeth3.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth3.Implementation.WriteLine("  Set tSC = ex.AsStatus()")

		// JMD1326: make sure cursor gets closed
		If ('tKPI && tPersistent) {
			Do tMeth3.Implementation.WriteLine("  If tUpdate {")
			Do tMeth3.Implementation.WriteLine("   &sql(CLOSE "_tCursorSq3_"u)")
			Do tMeth3.Implementation.WriteLine("  } Else {")
			Do tMeth3.Implementation.WriteLine("   &sql(CLOSE "_tCursorSq3_"i)")
			Do tMeth3.Implementation.WriteLine("  }")
		}
		Do tMeth3.Implementation.WriteLine(" }")

		// +DTB42
		Do tMeth4.Implementation.WriteLine(" }") // try
		Do tMeth4.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth4.Implementation.WriteLine("  Set pSC = ex.AsStatus()")
		Do tMeth4.Implementation.WriteLine(" }")
		// -DTB422

		// restore read committed mode
		Do tMeth.Implementation.WriteLine("  Set:$D(oldzu) zu=$ZU(115,2,oldzu)")
		Do tMeth.Implementation.WriteLine(" If $$$ISERR(logStatus) Quit logStatus //APV100QL2")
		Do tMeth.Implementation.WriteLine(" If ($$$ISERR(tSC)) {")
		Do tMeth.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth.Implementation.WriteLine("  If (pVerbose) {")
		Do tMeth.Implementation.WriteLine("   Do $System.Status.DisplayError(tSC)")
		Do tMeth.Implementation.WriteLine("  }")
		// JMD1480
		Do tMeth.Implementation.WriteLine("  If ($G(tID)'="""") {")
		Do tMeth.Implementation.WriteLine("   Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",tID,tSC) //APV100.7")		// DTB836 - Call API to log the error
		Do tMeth.Implementation.WriteLine("   If $$$ISERR(logStatus) {")
		Do tMeth.Implementation.WriteLine("    Quit logStatus")
		Do tMeth.Implementation.WriteLine("   }")
		Do tMeth.Implementation.WriteLine("   Else {")
		Do tMeth.Implementation.WriteLine("    // DP-433703 - Since the build error has already been logged above, reset tSC to prevent it from erroneously being returned and possibly causing the build to fail")
		Do tMeth.Implementation.WriteLine("    Set tSC=$$$OK")
		Do tMeth.Implementation.WriteLine("   }")
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth2.Implementation.WriteLine(" If ($$$ISERR(tSC)) {")
		Do tMeth2.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth2.Implementation.WriteLine("  If (pVerbose) {")
		Do tMeth2.Implementation.WriteLine("   Do $System.Status.DisplayError(tSC)")
		Do tMeth2.Implementation.WriteLine("  }")
		// JMD1480
		Do tMeth2.Implementation.WriteLine("  If ($G(tID)'="""") {")
		Do tMeth2.Implementation.WriteLine("   Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",tID,tSC) //APV100.8")		// DTB836 - Call API to log the error
		Do tMeth2.Implementation.WriteLine("   If $$$ISERR(logStatus) {")
		Do tMeth2.Implementation.WriteLine("    Quit logStatus")
		Do tMeth2.Implementation.WriteLine("   }")
		Do tMeth2.Implementation.WriteLine("   Else {")
		Do tMeth2.Implementation.WriteLine("    // DP-433703 - Since the build error has already been logged above, reset tSC to prevent it from erroneously being returned and possibly causing the build to fail")
		Do tMeth2.Implementation.WriteLine("    Set tSC=$$$OK")
		Do tMeth2.Implementation.WriteLine("   }")
		Do tMeth2.Implementation.WriteLine("  }")
		Do tMeth2.Implementation.WriteLine(" }")

		Do tMeth3.Implementation.WriteLine(" If ($$$ISERR(tSC)) {")
		Do tMeth3.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth3.Implementation.WriteLine("  If (pVerbose) {")
		Do tMeth3.Implementation.WriteLine("   Do $System.Status.DisplayError(tSC)")
		Do tMeth3.Implementation.WriteLine("  }")
		Do tMeth3.Implementation.WriteLine(" }")
		
		// +DTB422
		Do tMeth4.Implementation.WriteLine(" If ($$$ISERR(pSC)) {")
		Do tMeth4.Implementation.WriteLine("  Do ..%LogError(pSC)")
		Do tMeth4.Implementation.WriteLine("  If (pVerbose) {")
		Do tMeth4.Implementation.WriteLine("   Do $System.Status.DisplayError(pSC)")
		Do tMeth4.Implementation.WriteLine("  }")
		Do tMeth4.Implementation.WriteLine(" }")
		// -DTB422

		Do tMeth.Implementation.WriteLine(" Quit tSC")
		Do tMeth2.Implementation.WriteLine(" Quit tSC")
		Do tMeth3.Implementation.WriteLine(" Quit tSC")
		Do tMeth4.Implementation.WriteLine(" Quit tSourceExists")

		Do tClassDef.Methods.Insert(tMeth)
		Do tClassDef.Methods.Insert(tMeth2)
		Do tClassDef.Methods.Insert(tMeth3)
		Do tClassDef.Methods.Insert(tMeth4)		// DTB422
		#; End of %UpdateFacts / %BuildAllFacts / %BuildTempFile / %CheckSourceId

		#; %ProcessFact method (called by %UpdateFacts)
		#; JMD1137 add pDimensionsOnly
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%ProcessFact")
		Set tMeth.Name = "%ProcessFact"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pID:%String,pBatchMode:%Boolean=0,&%var:%String,&pFactId:%Integer,*pErrorMsg:%String,&pDimTables,pDimensionsOnly:%Boolean=0,pFactList:%String="""",&pSQLUpdate:%SQL.StatementResult={$$$NULLOREF}"		// DTB886 - Add the pFactList	// DTB913 - Add pSQLUpdate
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Perform the work of updating one fact in the cube.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
		Do tMeth.Implementation.WriteLine(" Set logStatus = $$$OK")
		Do tMeth.Implementation.WriteLine(" New %ROWID,%msg,%value,%source,%expression")
		Do tMeth.Implementation.WriteLine(" Try {")
		Do tMeth.Implementation.WriteLine("  Set (SQLCODE,tStarId) = """"")
		Do tMeth.Implementation.WriteLine("  Set pErrorMsg = """"")
		Do tMeth.Implementation.WriteLine("  Set pFactId = $G(pFactId)")
		Do tMeth.Implementation.WriteLine("  Set %value = """"")
		
		// DTB886 - If the pFactList is defined, remove everything else from the %var variable.
		// Preserve the original %var for restoration when exiting the method.
		Do tMeth.Implementation.WriteLine("")
		Do tMeth.Implementation.WriteLine("  // + DTB886 - Consult the pFactList. If defined, remove anything that is not in the list from %var")
		Do tMeth.Implementation.WriteLine("  // It is assumed that pFactList is a $lb in this method")
		Do tMeth.Implementation.WriteLine("  Set tLimitedList=0")
		Do tMeth.Implementation.WriteLine("  If (pFactList'="""") {")
		Do tMeth.Implementation.WriteLine("    Set tLimitedList = 1")
		Do tMeth.Implementation.WriteLine("    Set tOrigBatchMode = pBatchMode")		// DTB961 - Remember the original setting
		Do tMeth.Implementation.WriteLine("    Set pBatchMode = 0")		// DTB891 - If the fact list is set, we cannot automatically assume an insert is appropriate
		Do tMeth.Implementation.WriteLine("    Merge tOriginalVar = %var")
		
		// DTB938 - Change how the %var is pruned. Kill it and rebuild it from the available fact list.
		Do tMeth.Implementation.WriteLine("    Kill %var")
		Do tMeth.Implementation.WriteLine("    For f=1:1:$LL(pFactList) {")
		Do tMeth.Implementation.WriteLine("      Set tFact = $LG(pFactList,f)")
		Do tMeth.Implementation.WriteLine("      Set:$D(tOriginalVar(tFact)) %var(tFact) = tOriginalVar(tFact)")
		Do tMeth.Implementation.WriteLine("    }")
		
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine("  If tLimitedList {")
		Do tMeth.Implementation.WriteLine("    If '$G($$$DeepSeeMetaGLVN(""cubes"","_$$$quote(tCubeName)_",""namedFactNums"")) {")
		Do tMeth.Implementation.WriteLine("      Set tSC = $$$ERROR($$$GeneralError,""Cube '"_tCubeName_"' does not support updates using a fact list."")")
		Do tMeth.Implementation.WriteLine("      Quit")
		Do tMeth.Implementation.WriteLine("    }")
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine("  // - DTB886")
		
		// + DP-404982 - Move this generated code earlier so it precededs all %var processing and
		// cannot overwrite processing errors
 		Do tMeth.Implementation.WriteLine("")

		// if batch mode: turn off transactions, set insert flag
		Do tMeth.Implementation.WriteLine("  If (pDimensionsOnly) {")
		Do tMeth.Implementation.WriteLine("   Set tFactId=""""")
		Do tMeth.Implementation.WriteLine("   Set tIsInsert = 1")
		Do tMeth.Implementation.WriteLine("  }")

		Do tMeth.Implementation.WriteLine("  ElseIf (pBatchMode) {")
		Do tMeth.Implementation.WriteLine("   Set zuSetting = $zu(115,1,0)")
		Do tMeth.Implementation.WriteLine("   Set tIsInsert = 1")
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine("  ElseIf (pID'="""") {")

		// get fact id from index
		// We have to do this check directly as we do not report this index to SQL
		Do tMeth.Implementation.WriteLine("   Set tFactId = $O($$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceId")_",pID,""""))")
		Do tMeth.Implementation.WriteLine("   Set tIsInsert = ''(tFactId="""")")
		Do tMeth.Implementation.WriteLine("  }")

		Do tMeth.Implementation.WriteLine("  ElseIf (pFactId'="""") {")
		// no source id: see the provided factId exists
		Do tMeth.Implementation.WriteLine("   If ($D($$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceIdReverse")_",pFactId))) {")
		Do tMeth.Implementation.WriteLine("    Set tFactId = pFactId")
		Do tMeth.Implementation.WriteLine("    Set tIsInsert = 0")
		Do tMeth.Implementation.WriteLine("   }")
		Do tMeth.Implementation.WriteLine("   Else {")
		Do tMeth.Implementation.WriteLine("    Set tFactId = """"")
		Do tMeth.Implementation.WriteLine("    Set tIsInsert = 1")
		Do tMeth.Implementation.WriteLine("   }")
		Do tMeth.Implementation.WriteLine("  }")

		Do tMeth.Implementation.WriteLine("  Else {")
		Do tMeth.Implementation.WriteLine("   Set tFactId = """"")
		Do tMeth.Implementation.WriteLine("   Set tIsInsert = 1")
		Do tMeth.Implementation.WriteLine("  }")
		
		// DTB899 - Check conditions and quit out if all are true:
		// - tLimitedList = 1
		// - pBatchMode = 0		(NB: this is the flag that can be used for a "rolling build" insert on the first column)
		// - tInsert = 1
		// This is what establishes the default behavior of UPDATE only for selective update calls
		Do tMeth.Implementation.WriteLine("")
		Do tMeth.Implementation.WriteLine("  If ('pBatchMode && tLimitedList && tIsInsert) {")
		Do tMeth.Implementation.WriteLine("    Quit")
		Do tMeth.Implementation.WriteLine("  }")

		#; check for callback
		If ($$$comMemberKeyGet(pCubeClass,$$$cCLASSmethod,"%OnProcessFact",$$$cMETHrunnable)) {
			Do tMeth.Implementation.WriteLine("  Set tSkip = 0")
			Do tMeth.Implementation.WriteLine("  Set:'pDimensionsOnly tSC = ##class("_pCubeClass_").%OnProcessFact(pID,.%var,.tSkip,tIsInsert)")
			Do tMeth.Implementation.WriteLine("  If (tSkip || $$$ISERR(tSC)) {")
			Do tMeth.Implementation.WriteLine("   Set pFactId=""""")
			Do tMeth.Implementation.WriteLine("   Quit")
			Do tMeth.Implementation.WriteLine("  }")
		}
		// - DP-404982

		// apply transformations to relationship properties (one-side)
		If $D(pRelationInfo) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; Transform relationship properties")

			Set r = $O(pRelationInfo(""))
			While (r '= "") {
				Set tStoredSide = +$G(pRelationInfo(r,"storedSide"))
				
				If (tStoredSide) {
					Set tFact = $G(pRelationInfo(r,"fact"))
					Set tInverse = $G(pRelationInfo(r,"inverse"))
					Set tRelatedCube = $G(pRelationInfo(r,"relatedCube"))
					Set tRelatedClass = ##class(%DeepSee.Utils).%GetCubeFactClass(tRelatedCube, .tSC)
					If ((tRelatedClass="")||$$$ISERR(tSC)) {
						Set tSC = $$$ERROR($$$GeneralError,"Related cube must be compiled before this cube: '" _ tRelatedCube _ "'")
						Quit
					}
					Do tMeth.Implementation.WriteLine("  Set tUseCurrFact = $D(%var("_$$$quote(tFact)_"))")		// DTB886 - Note existence of the %var entry
					
					// generate call to transform "source" id into "fact" id
					Set tCardinality = $G(pRelationInfo(r,"cardinality"))
					If (tCardinality="many") {
						Do tMeth.Implementation.WriteLine("  If tUseCurrFact&&$G((%var("_$$$quote(tFact)_"))'="""") {")		// DTB886 - Add $Get
						Do tMeth.Implementation.WriteLine("  Set tList = $G(%var("_$$$quote(tFact)_"))")		// DTB913
						Do tMeth.Implementation.WriteLine("  For ri=1:1:$LL(tList) {")
						Do tMeth.Implementation.WriteLine("  Set tRItem=$LG(tList,ri)")
					}
					Else {
						Do tMeth.Implementation.WriteLine("  Set tRItem=$G(%var("_$$$quote(tFact)_"))")		// DTB886 - Add $Get
					}

					Do tMeth.Implementation.WriteLine("  If (tRItem'="""") {")
					Do tMeth.Implementation.WriteLine("   Set tRItem = $O($$$DeepSeeIndexGLVN("_$$$quote($$$UPPER(tRelatedCube))_",""%sourceId"",tRItem,""""))")
	
					// JMD1450 - make note that remote index is missing this entry
					Do tMeth.Implementation.WriteLine("   If ($D(%dsMissingRef)&&(tRItem="""")) {")
					Do tMeth.Implementation.WriteLine("    Set x = $I(%dsMissingRef)")
					Do tMeth.Implementation.WriteLine("    Set tSC = $$$ERROR($$$GeneralError,""Missing relationship reference in ""_..#CUBENAME_"": source ID ""_pID_"" missing reference to "_tFact_" ""_%var("_$$$quote(tFact)_"))")
					Do tMeth.Implementation.WriteLine("    If ($G(pID)'="""") {")
					Do tMeth.Implementation.WriteLine("    		Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",pID,tSC) //APV100.9")		// DTB836 - Call API to log the error
					Do tMeth.Implementation.WriteLine("    		If $$$ISERR(logStatus) Quit") //If tCardinality=many, this quits out of the For loop
					Do tMeth.Implementation.WriteLine("    }")
					Do tMeth.Implementation.WriteLine("   }")
	
					// JMD746 - skip validation
					/*
						// test if remote index exists
						Do tMeth.Implementation.WriteLine("   If (tRItem="""") {")
						Do tMeth.Implementation.WriteLine("    Set tSC = $$$ERROR($$$GeneralError,""Related item not found in: '"_tRelatedCube_"' for fact ""_"_$$$quote(tFact)_")")
						Do tMeth.Implementation.WriteLine("    Do ..%LogError(tSC)")
						Do tMeth.Implementation.WriteLine("    Quit")
						Do tMeth.Implementation.WriteLine("   }")
					*/

					Do tMeth.Implementation.WriteLine("  }")

					If (tCardinality="many") {

						Do tMeth.Implementation.WriteLine("  Set:tUseCurrFact $List(%var("_$$$quote(tFact)_"),ri)=tRItem")		// DTB886 - Don't set with a null
						Do tMeth.Implementation.WriteLine("  } ;For")
						Do tMeth.Implementation.WriteLine("  If $$$ISERR(logStatus) Quit //APV100Q7")

						// if fx'=""
						Do tMeth.Implementation.WriteLine("  }")
					}
					Else {
						Do tMeth.Implementation.WriteLine("  Set:tUseCurrFact %var("_$$$quote(tFact)_") = tRItem")		// DTB886 - Don't set with a null
					}
				}
				Set r = $O(pRelationInfo(r))
				Do tMeth.Implementation.WriteLine("")		// DTB - Added for readability of generated code
			}
		    If $$$ISERR(tSC) Quit
		}

		// apply range expressions
		If $D(tRangeProps) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; apply range replacements")
			Set p = $O(tRangeProps(""))
			While (p '= "") {
				Set tSC = ##class(%DeepSee.Utils).%ParseRangeExpression(tRangeProps(p),,"",.tRangeCode)
			    If $$$ISERR(tSC) Quit

				Do tMeth.Implementation.WriteLine("  If $D(%var("_$$$quote(p)_")) {")		// DTB939
				Do tMeth.Implementation.WriteLine("    Set x = $G(%var("_$$$quote(p)_"))")

				If ($D(tRangePropsList(p))) {
					// special handling for list types
					Do tMeth.Implementation.WriteLine("    Set %var("_$$$quote(p)_") = "_tRangeCode)
				}
				Else {
					Do tMeth.Implementation.WriteLine("    Set %var("_$$$quote(p)_") = "_tRangeCode)
				}
				Do tMeth.Implementation.WriteLine("  }")		// DTB939
				
				Set p = $O(tRangeProps(p))
			}
		    If $$$ISERR(tSC) Quit
		}

		// apply linkProperty replacements
		If $D(tLinkProps) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; apply linkProperty replacements")
		
			Set p = $O(tLinkProps(""))
			While (p '= "") {
				Set tLinkClass = $G(pFactInfo("prop",p,"linkClass"))
				Set tLinkProperty = $G(pFactInfo("prop",p,"linkProperty"))
				Set tLinkTable = ..%GetSQLTableName(tLinkClass)

				// translate linkProperty from property to field name
				Set tLinkField = ..%GetSQLFieldExpression(.tSC,tLinkClass,tLinkProperty)
			    If $$$ISERR(tSC) Quit
				
				Set tLinkName = tLinkProps(p)

				Do tMeth.Implementation.WriteLine("  If (%var("_$$$quote(tLinkName)_")'="""") {")
				Do tMeth.Implementation.WriteLine("   &SQL(SELECT "_tLinkField_" INTO :tValue FROM "_tLinkTable_" WHERE %ID = :%var("_$$$quote(tLinkName)_"))")
				Do tMeth.Implementation.WriteLine("   Set %var("_$$$quote(tLinkName)_") = $S(((SQLCODE=0)||(SQLCODE=100)):$G(tValue),1:"""")")
				Do tMeth.Implementation.WriteLine("  }")
				Set p = $O(tLinkProps(p))
			}
		    If $$$ISERR(tSC) Quit
		}

		// apply null replacements
		If $D(tNullProps) {
			Set tNullMarker = $$$DeepSeeNullMarker

			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; apply null replacements")

			Set p = $O(tNullProps(""))
			While (p '= "") {
				If ($D(tNullPropsList(p))) {
					// special handling for list types
					Do tMeth.Implementation.WriteLine("  Set:$D(%var("_$$$quote(p)_"))&&(($G(%var("_$$$quote(p)_"))="""")||($G(%var("_$$$quote(p)_"))=$C(0))) %var("_$$$quote(p)_") = $LB("_$$$quote(tNullMarker)_")")		// DTB886 - Prevent null replacement if the %var entry is removed
				}
				Else {
					// test for null or $C(0)
					Do tMeth.Implementation.WriteLine("  Set:$D(%var("_$$$quote(p)_"))&&(($G(%var("_$$$quote(p)_"))="""")||($G(%var("_$$$quote(p)_"))=$C(0))) %var("_$$$quote(p)_") = "_$$$quote(tNullMarker))		// DTB886 - Prevent null replacement if the %var entry is removed
				}
				Set p = $O(tNullProps(p))
			}
		    If $$$ISERR(tSC) Quit
		}

		// UPDATE STAR TABLES
		// process in dependency order
		Set tUseLocks = 1
		Set n = $O(tOrderedStar(""))
		While (n '= "") {
			Set tStar = tOrderedStar(n)
			Set f = $O(tStarField(tStar,""))
			While (f '= "") {
				Do tMeth.Implementation.WriteLine("")
				Do tMeth.Implementation.WriteLine(" #; STAR Table: " _ tStar)

				Set tFactNo = +$G(tStarField(tStar,f,"fact"))
				Set tIsList = +$G(tStarField(tStar,f,"list"))
				Set tDelim = $G(tStarField(tStar,f,"listDelimiter"))

				#; we have to get SQL name manually as oddCOM does not exist yet!
				Set tStarSchema = $P(tStar,".",1,$L(tStar,".")-1)
				Set tStarClass = $P(tStar,".",$L(tStar,"."))
				Set tStarName = $TR(tStarSchema,".","_")_"."_tStarClass
				Set tShared = $G(pStarInfo(tStar,"sharedCube"))
				If (tShared'="") {
					Set tRefTable = ##class(%DeepSee.Utils).%GetCubeFactTable(tShared)
					Set tRefSchema = $P(tRefTable,".",1)
					Set tStarName = tRefSchema_"."_tStarClass
				}

				// test if we already have the entry in the Star Table
				Do tMeth.Implementation.WriteLine(" If ($G(%var("_$$$quote(f)_"))'="""") {")

				// if list, copy value into temp var
				If (tIsList) {
					Do tMeth.Implementation.WriteLine(" Set tList = $G(%var("_$$$quote(f)_"))")
					If (tDelim="") {
						Do tMeth.Implementation.WriteLine(" For k = 1:1:$LL(tList) {")
						Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(f)_") = $LG(tList,k)")
					}
					Else {
						Do tMeth.Implementation.WriteLine(" For k = 1:1:$L(tList,"_$$$quote(tDelim)_") {")
						Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(f)_") = $P(tList,"_$$$quote(tDelim)_",k)")
					}
					// skip missing items within the list
					Do tMeth.Implementation.WriteLine("  If %var("_$$$quote(f)_") = """" Continue")
				}

				// Find primary index for STAR table
				Set tPrimaryIndex = $G(pStarInfo(tStar,"primary"))
				If (tPrimaryIndex="") {
					// This should NEVER happen unless the table/cube we are referring to is not compiled
					Set tSC = $$$ERROR($$$GeneralError,"No primary index found for dimension table: " _ tStar)
					Quit
				}
				Set UPDATEWHERE = ""	// WHERE clause for dim table UPDATE

				Set tKeyExpr = ..%GetDimensionLocation(tStar,"I")
				Set tKeyExpr = $TR(tKeyExpr,")",",") // replace final )
				Set tKeyExpr = tKeyExpr _ """Primary"","
				For t = 1:1:$L(tPrimaryIndex,",") {
					Set tKeyField = $P(tPrimaryIndex,",",t)
					Set tKeyCollation = $G(pStarInfo(tStar,"prop",tKeyField,"collation"))
					If ((t = $L(tPrimaryIndex,","))&&(tKeyCollation'="exact")) {
						// collate last item
						// JMD1190: change to match SQLUPPER(113)
						Set tKeyExpr = tKeyExpr _ $S(t>1:",",1:"") _ "$zu(28,$G(%var("_$$$quote(tKeyField)_")),7,113)"		// DTB913
					}
					Else {
						Set tKeyExpr = tKeyExpr _ $S(t>1:",",1:"") _ "$G(%var("_$$$quote(tKeyField)_"))"		// DTB913
					}
					Set UPDATEWHERE = UPDATEWHERE _ $S(UPDATEWHERE="":"",1:" AND ") _ tKeyField_"=:%var("_$$$quote(tKeyField)_")"
				}
				Set tKeyExpr = tKeyExpr _ ","""")"

				#; find KEY and ROLLUP fields for star table
				Set tKeyField = ""
				Set tRollupClause = ""
				Set tName = $O(pStarInfo(tStar,"prop",""))
				While (tName '= "") {
					Set tUse = $G(pStarInfo(tStar,"prop",tName,"use"))
					If (tUse = "key") {
						Set tKeyField = tName
					}
					Set tName = $O(pStarInfo(tStar,"prop",tName))
				}

				Set tUpdateStarTable = 0
				If (tUpdateStarTable) {
					// special test for UPDATE of dimension table
					// if %SynchronizeCube is calling this, then the pDimTables array will
					// contain this dimension table; this means we have to UPDATE the values
					// in the dimension table
					Do tMeth.Implementation.WriteLine("  If ($D(pDimTables("_$$$quote(tStar)_"))) {")
					Do tMeth.Implementation.WriteLine("   #; update dimension table")

					// create UPDATE statement for STAR table
					// should match INSERT logic below
					Set INTO = tKeyField
					Set VALUES = ":%var("_$$$quote(tKeyField)_")"
					Set tName = $O(pStarInfo(tStar,"prop",""))
					While (tName '= "") {
						Set tUse = $G(pStarInfo(tStar,"prop",tName,"use"))
						Set tIsRef = +$G(pStarInfo(tStar,"prop",tName,"isref"))
						If ('tIsRef && (tUse '= "key")) {
							Set INTO = INTO _ $S(INTO="":"",1:",") _ tName
							Set VALUES = VALUES _ $S(VALUES="":"",1:",") _ ":%var("_$$$quote(tName)_")"
						}
						Set tName = $O(pStarInfo(tStar,"prop",tName))
					}
					Do tMeth.Implementation.WriteLine("   &sql(UPDATE "_tStarName_" ("_INTO_") VALUES ("_VALUES_") WHERE "_UPDATEWHERE_")")

					// make sure axis cache is invalid
					Do tMeth.Implementation.WriteLine("   Kill $$$DeepSeeAxisGLVN("_$$$quote($$$UPPER(pCube.name))_")")
					Do tMeth.Implementation.WriteLine("  }")
				} // end of update

				// test if we already have this member in the dimension table
				// use direct expression against index in dimension table
				Do tMeth.Implementation.WriteLine("  Set tStarId = $O("_tKeyExpr_")")

				// Get local id value
				Do tMeth.Implementation.WriteLine("  If (tStarId '= """") {")
				Do tMeth.Implementation.WriteLine("   Set %var("_$$$quote(f)_") = tStarId")
				Do tMeth.Implementation.WriteLine("  }")

				// Insert into STAR table
				Do tMeth.Implementation.WriteLine("  Else {")

				If (tUseLocks) {
					// take out a lock to ensure valid unique checking
					// JMD1190 apply collation to lock key
					Do tMeth.Implementation.WriteLine("  Set tLockKey = $zu(28,%var("_$$$quote(f)_"),7,113)")
					// JMD843: use hard-coded 15 second lock as users mess with $ZU(115,4)
					Do tMeth.Implementation.WriteLine("  Lock +$$$DeepSeeIndexGLVN("_$$$quote(tStar)_",tLockKey):15")
					Do tMeth.Implementation.WriteLine("  If '$Test {")
					Do tMeth.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Unable to acquire lock for dimension table: '"_tStarName_"'"")")
					Do tMeth.Implementation.WriteLine("   Quit")
					Do tMeth.Implementation.WriteLine("  }")

					// test again if we already have this member in the dimension table
					Do tMeth.Implementation.WriteLine("  Set tStarId = $O("_tKeyExpr_")")
					Do tMeth.Implementation.WriteLine("   If (tStarId '= """") {")
					Do tMeth.Implementation.WriteLine("    Set %var("_$$$quote(f)_") = tStarId")
					Do tMeth.Implementation.WriteLine("   }")
					Do tMeth.Implementation.WriteLine("   Else {")
				}

				// create insert statement for STAR table
				Set INTO = tKeyField
				Set VALUES = ":%var("_$$$quote(tKeyField)_")"
				Set tName = $O(pStarInfo(tStar,"prop",""))
				While (tName '= "") {
					Set tUse = $G(pStarInfo(tStar,"prop",tName,"use"))
					Set tIsRef = +$G(pStarInfo(tStar,"prop",tName,"isref"))
					If ('tIsRef && (tUse '= "key")) {
						Set INTO = INTO _ $S(INTO="":"",1:",") _ tName
						Set VALUES = VALUES _ $S(VALUES="":"",1:",") _ ":%var("_$$$quote(tName)_")"
					}

					// JMD929: evaluate property expressions containing %value references
					Set tPExpr = $G(pStarInfo(tStar,"prop",tName,"expr"))
					If (tPExpr["%value") {
						// convert expression to code
						Set tSC = ..%ParseExpression(tPExpr, .tPCode, .tPPropList)
						If $$$ISERR(tSC) Quit

						// now replace %expression
						Set tSC = ..%ParseExpression(tPCode, .tPCode, .tPPropListX,"%expression")
						If $$$ISERR(tSC) Quit

						// replace method calls
						Set:$IsObject($G(%class)) tPCode = $Replace(tPCode,"%cube.","##class("_%class.Name_").")

						// build context for expression
						Do tMeth.Implementation.WriteLine("    Kill %source")
						Set p2 = $O(tPPropList(""))
						While (p2'="") {
							Do tMeth.Implementation.WriteLine("    Set %source("_$$$quote(p2)_")=$G(%var("_$$$quote(tName)_",""src"","_$$$quote(p2)_"))")
							Set p2 = $O(tPPropList(p2))
						}
						// build context for expression
						Do tMeth.Implementation.WriteLine("    Kill %expression")
						Set p2 = $O(tPPropListX(""))
						While (p2'="") {
							Do tMeth.Implementation.WriteLine("    Set %expression("_$$$quote(p2)_")=$G(%var("_$$$quote(tName)_",""exp"","_$$$quote(p2)_"))")
							Set p2 = $O(tPPropListX(p2))
						}

						Do tMeth.Implementation.WriteLine("    Set %value = $G(%var("_$$$quote(tKeyField)_"))")		// DTB913
						Do tMeth.Implementation.WriteLine("    Set %var("_$$$quote(tName)_")="_tPCode)
						Do tMeth.Implementation.WriteLine("    Set %value = """"")
					}
					Set tName = $O(pStarInfo(tStar,"prop",tName))
				}


				Do tMeth.Implementation.WriteLine("    &sql(INSERT INTO "_tStarName_" ("_INTO_") VALUES ("_VALUES_"))")
				Do tMeth.Implementation.WriteLine("    If (SQLCODE'=0) {")
				If (tUseLocks) {
					Do tMeth.Implementation.WriteLine("     Lock -$$$DeepSeeIndexGLVN("_$$$quote(tStar)_",tLockKey)")
				}
				Do tMeth.Implementation.WriteLine("     Set tSC = $$$ERROR($$$GeneralError,""Insert into dimension table failed: '"_tStarName_"' SQLCODE=""_SQLCODE)")
				Do tMeth.Implementation.WriteLine("     Quit")
				Do tMeth.Implementation.WriteLine("    }")
				Do tMeth.Implementation.WriteLine("    Set %var("_$$$quote(f)_") = %ROWID")

				Do tMeth.Implementation.WriteLine("   }")

				// release lock
				If (tUseLocks) {
					Do tMeth.Implementation.WriteLine("   Lock -$$$DeepSeeIndexGLVN("_$$$quote(tStar)_",tLockKey)")
					Do tMeth.Implementation.WriteLine("  }")
				}

				If (tIsList) {
					// accumulate results
					If (tDelim="") {
						Do tMeth.Implementation.WriteLine(" Set $List(tList,k) = $G(%var("_$$$quote(f)_"))")
					}
					Else {
						Do tMeth.Implementation.WriteLine(" Set $P(tList,"_$$$quote(tDelim)_",k) = $G(%var("_$$$quote(f)_"))")
					}
					Do tMeth.Implementation.WriteLine(" }") // for k
					Do tMeth.Implementation.WriteLine(" Quit:$$$ISERR(tSC)") // for k
					Do tMeth.Implementation.WriteLine(" Set %var("_$$$quote(f)_") = tList")
				}

				Do tMeth.Implementation.WriteLine(" }")

				Set f = $O(tStarField(tStar,f)) // next field
			}
			If $$$ISERR(tSC) Quit
			Set n = $O(tOrderedStar(n)) // next table
		}
		If $$$ISERR(tSC) Quit

		// test if new dimension level was filed (non-batch mode)
		// if the value for a member is not in the index, then assume
		// we have a new value.

		Do tMeth.Implementation.WriteLine(" If ('pBatchMode) {")
		Set tFactNo = $O(tLevelTest(""),1,data)
		While (tFactNo '= "") {
			Set tPropName = $LG(data,1)
			Set tFunctionClass = $LG(data,2)
			Set tFunction = $LG(data,3)
			Set tBase = $LG(data,4)
			Set tTimeOffset = $LG(data,5)
			Set tIsList = $LG(data,6)
			Set tDelim = $LG(data,7)

			If (tFunction = "") {
				Set tValExpr = "$G(%var("_$$$quote(tPropName)_"))"		// DTB886 - Add $G
			}
			ElseIf ((tFunction="%Convert")&&(tTimeOffset'="")) {
				Set tTimeOffset = $ZSTRIP(tTimeOffset,"<>W")
				// Invert offset
				If ($E(tTimeOffset)="-") {
					Set tTimeOffset = $E(tTimeOffset,2,$L(tTimeOffset))
				}
				ElseIf (tTimeOffset'="") {
					Set tTimeOffset = "-"_tTimeOffset
				}
				Set tValExpr = "##class("_tFunctionClass_")."_tFunction_"($G(%var("_$$$quote(tBase)_")),"_$$$quote(tTimeOffset)_")"		// DTB911 - Add $G
			}
			Else {
				Set tValExpr = "##class("_tFunctionClass_")."_tFunction_"($G(%var("_$$$quote(tBase)_")))"		// DTB911 - Add $G
			}
			Set tTestCode = "'$D($$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_tFactNo_",tVal))"

			// JMD1452: check for list data
			If (tIsList) {
				Do tMeth.Implementation.WriteLine("    Set tList = " _ tValExpr)
				If (tDelim="") {
					Do tMeth.Implementation.WriteLine("    For k = 1:1:$LL(tList) {")
					Do tMeth.Implementation.WriteLine("     Set tVal = $LG(tList,k)")
				}
				Else {
					Do tMeth.Implementation.WriteLine("    For k = 1:1:$L(tList,"_$$$quote(tDelim)_") {")
					Do tMeth.Implementation.WriteLine("     Set tVal = $P(tList,"_$$$quote(tDelim)_",k)")
				}
			}
			Else {
				Do tMeth.Implementation.WriteLine("    Set tVal = " _ tValExpr)
			}

			Do tMeth.Implementation.WriteLine("    If ((tVal'="""")&&("_tTestCode_")) {")
			Do tMeth.Implementation.WriteLine("     Set ts = $I($$$DeepSeeResultsGLVN("_$$$quote(tCubeName)_",""fact"","_tFactNo_"))")
			If (tIsList) {
				// one change is enough
				Do tMeth.Implementation.WriteLine("     Quit")
			}
			Do tMeth.Implementation.WriteLine("    }")
			If (tIsList) {
				Do tMeth.Implementation.WriteLine("    }")
			}

			Set tFactNo = $O(tLevelTest(tFactNo),1,data)
		}
		Do tMeth.Implementation.WriteLine(" }")

		// INSERT into FACT table
		Set INTO = "%sourceId"
		Set VALUES = ":pID"
		Set f = $O(tInsertList(""))
		While (f '= "") {
			// skip iknow props
			If '$D(tiKnowSkip(f)) {
				Set INTO = INTO _ $S(INTO="":"",1:",") _ f
				Set VALUES = VALUES _ $S(VALUES="":"",1:",") _ ":%var("_$$$quote(f)_")"
			}
			Set f = $O(tInsertList(f))
		}

		// 2 versions depending on batch mode
		Set tRestrictFlags = " %NOLOCK %NOINDEX"
		Do tMeth.Implementation.WriteLine("")		// DTB - Added for readability of generated code
		Do tMeth.Implementation.WriteLine(" #; INSERT or UPDATE data into fact table")
		
		// + DTB886 - Build these for all the cases below. It's cheap so build it even if it doesn't get used.
		Do tMeth.Implementation.WriteLine(" // DTB886 - Build these for relevant cases below.")
		Do tMeth.Implementation.WriteLine(" Set tListINTO = ""%sourceId""")
		Do tMeth.Implementation.WriteLine(" Set tListParameters = ""?""")
		Do tMeth.Implementation.WriteLine(" Set tListVALUES($I(tListVALUES)) = pID")
		Do tMeth.Implementation.WriteLine(" Set tFact = $O(%var(""""))")
		Do tMeth.Implementation.WriteLine(" While (tFact'="""") {")
		Do tMeth.Implementation.WriteLine("   Set tListINTO = tListINTO _ $S($L(tListINTO):"","",1:"""") _ tFact")
		Do tMeth.Implementation.WriteLine("   Set tListParameters = tListParameters _ $S($L(tListParameters):"","",1:"""") _ ""?""")
		Do tMeth.Implementation.WriteLine("   Set tListVALUES($I(tListVALUES)) = $G(%var(tFact))")
		Do tMeth.Implementation.WriteLine("   Set tFact = $O(%var(tFact))")
		Do tMeth.Implementation.WriteLine(" }")
		Do tMeth.Implementation.WriteLine(" Set:'tIsInsert tListVALUES($I(tListVALUES)) = tFactId")
		Do tMeth.Implementation.WriteLine("")
		// - DTB886
		
		Do tMeth.Implementation.WriteLine(" If (pDimensionsOnly) {")
		Do tMeth.Implementation.WriteLine(" }")
		Do tMeth.Implementation.WriteLine(" ElseIf (pBatchMode) {")

		// in batch mode no need to test for updates
		// + DTB886 - Add treatment of the limited list of facts to update
		Do tMeth.Implementation.WriteLine("  If tLimitedList {")		// DTB866
		Do tMeth.Implementation.WriteLine("    // DTB886 - Handle a defined incoming pFactList. This forces use of dynamic SQL and has trimmed the available %var")

		// + DTB913 - Prepare a single dynamic INSERT that can be reused. This should not interact with UPDATES since it is triggered by pBatchMode
		Do tMeth.Implementation.WriteLine("    If '$IsObject(pSQLUpdate) {")
		Do tMeth.Implementation.WriteLine("    	Set tSQL = ""INSERT"_tRestrictFlags_" INTO "_tFactTableName_" (""_tListINTO_"") VALUES (""_tListParameters_"")""")
		Do tMeth.Implementation.WriteLine("")    		
		Do tMeth.Implementation.WriteLine("    	Set pSQLUpdate = ##class(%SQL.Statement).%New()")
		Do tMeth.Implementation.WriteLine("    	Set tSC = pSQLUpdate.%Prepare(tSQL)")
		Do tMeth.Implementation.WriteLine("    	If $$$ISERR(tSC) Quit")
 		Do tMeth.Implementation.WriteLine("    }")
 		Do tMeth.Implementation.WriteLine("    Set tListResult = pSQLUpdate.%Execute(tListVALUES...)")
		// - DTB913
		
		Do tMeth.Implementation.WriteLine("")
		Do tMeth.Implementation.WriteLine("    Set pFactId = tListResult.%ROWID")
		Do tMeth.Implementation.WriteLine("    Set SQLCODE = tListResult.%SQLCODE")
		Do tMeth.Implementation.WriteLine("  }")
		// - DTB886
		Do tMeth.Implementation.WriteLine("  Else {")
		Do tMeth.Implementation.WriteLine("    &sql(INSERT"_tRestrictFlags_" INTO "_tFactTableName_" ("_INTO_")")
		Do tMeth.Implementation.WriteLine("         VALUES ("_VALUES_"))")
		Do tMeth.Implementation.WriteLine("    Set pFactId = %ROWID")
		
		// set sourceId and reverse sourceId indices
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine("  If (pFactId'="""") {")
		Do tMeth.Implementation.WriteLine("    Set:pID'="""" $$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceId")_",pID,pFactId) = """"")
		Do tMeth.Implementation.WriteLine("    Set $$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceIdReverse")_",pFactId) = pID")
		Do tMeth.Implementation.WriteLine("    Kill:$D($$$DeepSeeMaskGLVN("_$$$quote(tCubeName)_",""slicer"",$$$DeepSeeFactToChunk(pFactId))) $$$DeepSeeMaskGLVN("_$$$quote(tCubeName)_",""slicer"",$$$DeepSeeFactToChunk(pFactId))")		// DP-421530
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine(" }")

		Set tRestrictFlags = ""
		Do tMeth.Implementation.WriteLine(" Else {")

		Do tMeth.Implementation.WriteLine("  If ($G(tFactId)'="""") {")
		// + DTB886 - Add treatment of the limited list of facts to update
		Do tMeth.Implementation.WriteLine("   If tLimitedList {")
		Do tMeth.Implementation.WriteLine("    // DTB886 - Handle a defined incoming pFactList. This forces use of dynamic SQL and has trimmed the available %var")

		// + DTB913 - Prepare a single dynamic UPDATE that can be reused. This should not interact with INSERTs since it is triggered by pBatchMode
		Do tMeth.Implementation.WriteLine("    If '$IsObject(pSQLUpdate) {")
		Do tMeth.Implementation.WriteLine("    	Set tSQL = ""UPDATE""_$S(+$G(tOrigBatchMode):"" %NOINDEX"",1:"""")_"" "_tFactTableName_" (""_tListINTO_"") VALUES (""_tListParameters_"") WHERE %ID = ?""")		//< --- Build the list of '?' characters in the loop, build the actual args in an array 
		Do tMeth.Implementation.WriteLine("")    		
		Do tMeth.Implementation.WriteLine("    	Set pSQLUpdate = ##class(%SQL.Statement).%New()")
		Do tMeth.Implementation.WriteLine("    	Set tSC = pSQLUpdate.%Prepare(tSQL)")
		Do tMeth.Implementation.WriteLine("    	If $$$ISERR(tSC) Quit")
 		Do tMeth.Implementation.WriteLine("    }")
 		Do tMeth.Implementation.WriteLine("    Set tListResult = pSQLUpdate.%Execute(tListVALUES...)")
		// - DTB913
		
		Do tMeth.Implementation.WriteLine("")    	
		Do tMeth.Implementation.WriteLine("    Set pFactId = tFactId")
		Do tMeth.Implementation.WriteLine("    Set SQLCODE = tListResult.%SQLCODE")
		Do tMeth.Implementation.WriteLine("   }")
		// - DTB886
		Do tMeth.Implementation.WriteLine("   Else {")
		Do tMeth.Implementation.WriteLine("    &sql(UPDATE"_tRestrictFlags_" "_tFactTableName_" ("_INTO_")")
		Do tMeth.Implementation.WriteLine("         VALUES ("_VALUES_") WHERE %ID = :tFactId)")
		Do tMeth.Implementation.WriteLine("    Set pFactId = tFactId")
		Do tMeth.Implementation.WriteLine("   }")
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine("  Else {")
		// + DTB886 - Add treatment of the limited list of facts to update
		Do tMeth.Implementation.WriteLine("   If tLimitedList {")		// DTB866
		Do tMeth.Implementation.WriteLine("     // DTB886 - Handle a defined incoming pFactList. This forces use of dynamic SQL and has trimmed the available %var")

		// + DTB913 - Prepare a single dynamic INSERT that can be reused. This should not interact with UPDATES since it is triggered by pBatchMode
		Do tMeth.Implementation.WriteLine("    If '$IsObject(pSQLUpdate) {")
		Do tMeth.Implementation.WriteLine("    	Set tSQL = ""INSERT"_tRestrictFlags_" INTO "_tFactTableName_" (""_tListINTO_"") VALUES (""_tListParameters_"")""")
		Do tMeth.Implementation.WriteLine("")    		
		Do tMeth.Implementation.WriteLine("    	Set pSQLUpdate = ##class(%SQL.Statement).%New()")
		Do tMeth.Implementation.WriteLine("    	Set tSC = pSQLUpdate.%Prepare(tSQL)")
		Do tMeth.Implementation.WriteLine("    	If $$$ISERR(tSC) Quit")
 		Do tMeth.Implementation.WriteLine("    }")
 		Do tMeth.Implementation.WriteLine("    Set tListResult = pSQLUpdate.%Execute(tListVALUES...)")
		// - DTB913

		Do tMeth.Implementation.WriteLine("")
		Do tMeth.Implementation.WriteLine("    Set pFactId = tListResult.%ROWID")
		Do tMeth.Implementation.WriteLine("    Set SQLCODE = tListResult.%SQLCODE")
		Do tMeth.Implementation.WriteLine("   }")
		// - DTB886
		Do tMeth.Implementation.WriteLine("   Else {")
		Do tMeth.Implementation.WriteLine("     &sql(INSERT"_tRestrictFlags_" INTO "_tFactTableName_" ("_INTO_")")
		Do tMeth.Implementation.WriteLine("          VALUES ("_VALUES_"))")
		Do tMeth.Implementation.WriteLine("     Set pFactId = %ROWID")

		// set sourceId and reverse sourceId indices
		Do tMeth.Implementation.WriteLine("   }")
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine("  If (pFactId'="""") {")
		Do tMeth.Implementation.WriteLine("    Set:pID'="""" $$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceId")_",pID,pFactId) = """"")
		Do tMeth.Implementation.WriteLine("    Set $$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceIdReverse")_",pFactId) = pID")
		Do tMeth.Implementation.WriteLine("    Kill:$D($$$DeepSeeMaskGLVN("_$$$quote(tCubeName)_",""slicer"",$$$DeepSeeFactToChunk(pFactId))) $$$DeepSeeMaskGLVN("_$$$quote(tCubeName)_",""slicer"",$$$DeepSeeFactToChunk(pFactId))")		// DP-421530
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine(" }")

		// test for error
		// !!! on error make sure we remove this fact from the fact table !!!
		// !!! test INSERT/UPDATE errors separately
		// !!! SQLCODE=100 is no good!
		Do tMeth.Implementation.WriteLine(" If (SQLCODE'=0) {")
		Do tMeth.Implementation.WriteLine("  Set pErrorMsg = $G(%msg)")
		Do tMeth.Implementation.WriteLine("  Set tSC = $$$ERROR($$$GeneralError,""Error inserting/updating fact: (Source ID:'""_pID_""') ""_pErrorMsg)")

 		Do tMeth.Implementation.WriteLine(" }")

		// pass iKnow properties on to iKnow class
		If $D(tiKnowProps) {
			// ('pBatchMode)&&
			Do tMeth.Implementation.WriteLine(" If ((pFactId'="""")) {")
			Set tiProp = $O(tiKnowProps(""))
			While (tiProp'="") {
				Do tMeth.Implementation.WriteLine("  Set tFlag = $S(pFactId=$G(tFactId):""U"",1:""I"")")
				Set tiType = $P($G(tiKnowProps(tiProp)),":",2)
				Set:tiType="" tiType = "string"

				// pass measure name to iKnow
				Set tMsrName = $G(pFactInfo("prop",tiProp,"msrname"))
				
				// BDB456 - avoid UNDEFINED if factName was set for iKnow measure
				set tiFactName = $g(pFactInfo("prop",tiProp,"alias"), tiProp)
				
				Do tMeth.Implementation.WriteLine("  Set tIkStartTime = $ZH")
				Do tMeth.Implementation.WriteLine("  Set tSC=##class(%iKnow.DeepSee.CubeUtils).%ProcessIKnowFact("_$$$quote(tCubeName)_",pBatchMode,tFlag,pFactId,"_$$$quote(tMsrName)_","_"%var(" _ $$$quote(tiFactName) _ "),"_$$$quote(tiType)_")")
				Do tMeth.Implementation.WriteLine("  Set tIkTime = $ZH-tIkStartTime")
				Do tMeth.Implementation.WriteLine("  Set x = $I(^IRIS.Temp.DeepSeeBuildStats($namespace,"_$$$quote($$$UPPER(pCube.name))_",""iknow""),tIkTime)")
				Set tiProp = $O(tiKnowProps(tiProp))
			}
			Do tMeth.Implementation.WriteLine(" }")
		}

		Do tMeth.Implementation.WriteLine(" }") // try
		Do tMeth.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
		Do tMeth.Implementation.WriteLine("  Set pErrorMsg = $ZE")
		Do tMeth.Implementation.WriteLine(" }")

		// restore transaction setting
		Do tMeth.Implementation.WriteLine(" Set:$D(zuSetting) zuSetting = $zu(115,1,zuSetting)")
		Do tMeth.Implementation.WriteLine(" If $$$ISERR(logStatus) Quit logStatus //APV100QL3")
		Do tMeth.Implementation.WriteLine("")
		
 		Do tMeth.Implementation.WriteLine(" // DTB886 - Restore original %var if it was trimmed by pFactList")
 		Do tMeth.Implementation.WriteLine(" Merge %var=tOriginalVar")
 		Do tMeth.Implementation.WriteLine("")
 		
		// DTB290 - Run %OnAfterProcessFact before logging any errors.
		If ($$$comMemberKeyGet(pCubeClass,$$$cCLASSmethod,"%OnAfterProcessFact",$$$cMETHrunnable)) {
			Do tMeth.Implementation.WriteLine(" Do ##class("_pCubeClass_").%OnAfterProcessFact(pID,.%var,tSC)		// DTB290 - Call %OnAfterProcessFact before logging errors")
		}
		
		Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) {")
		Do tMeth.Implementation.WriteLine("  Do ..%LogError(tSC)")
		// JMD1480
		// WAL245 -- check to see pID exists
		Do tMeth.Implementation.WriteLine("  If ($G(pID)'="""") {")
		Do tMeth.Implementation.WriteLine("  	Set logStatus = ##class(%DeepSee.Utils).%LogBuildError("_$$$quote(tCubeName)_",pID,tSC) //APV100.10")		// DTB836 - Call API to log the error
		Do tMeth.Implementation.WriteLine("  	If $$$ISERR(logStatus) Quit logStatus")
		Do tMeth.Implementation.WriteLine("  }")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth.Implementation.WriteLine(" Quit tSC")
		Do tClassDef.Methods.Insert(tMeth)
		// End of %ProcessFact

		#; %OnStartBatch method
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%OnStartBatch")
		Set tMeth.Name = "%OnStartBatch"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pCubeName:%String,pVerbose:%Boolean=0"
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Notification that a batch of facts are about to be processed.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000
		If $D(tiKnowProps) {
			Set ip = $O(tiKnowProps(""))
			While (ip'="") {
				Set tMsrName = $G(pFactInfo("prop",ip,"msrname"))
				Do tMeth.Implementation.WriteLine(" Set tMsrList("_$$$quote(tMsrName)_") = """"")
				Set ip = $O(tiKnowProps(ip))
			}
			Do tMeth.Implementation.WriteLine(" Set tIkStartTime = $ZH")
			Do tMeth.Implementation.WriteLine(" Set tSC = ##class(%iKnow.DeepSee.CubeUtils).%StartIKnowBatch(pCubeName,.tMsrList,pVerbose)")
			Do tMeth.Implementation.WriteLine(" Set tIkTime = $ZH-tIkStartTime")
			Do tMeth.Implementation.WriteLine(" Set x = $I(^IRIS.Temp.DeepSeeBuildStats($namespace,"_$$$quote($$$UPPER(pCube.name))_",""iknow""),tIkTime)")
			Do tMeth.Implementation.WriteLine(" Quit tSC")
		}
		Else {
			Do tMeth.Implementation.WriteLine(" Quit $$$OK")
		}
		Do tClassDef.Methods.Insert(tMeth)

		#; %OnEndBatch method
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%OnEndBatch")
		Set tMeth.Name = "%OnEndBatch"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pCubeName:%String,pVerbose:%Boolean=0"
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Notification that a batch of facts have just been processed.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000
		If $D(tiKnowProps) {
			Set ip = $O(tiKnowProps(""))
			While (ip'="") {
				Set tMsrName = $G(pFactInfo("prop",ip,"msrname"))
				Do tMeth.Implementation.WriteLine(" Set tMsrList("_$$$quote(tMsrName)_") = """"")
				Set ip = $O(tiKnowProps(ip))
			}

			Do tMeth.Implementation.WriteLine(" Set tIkStartTime = $ZH")
			Do tMeth.Implementation.WriteLine(" Set tSC = ##class(%iKnow.DeepSee.CubeUtils).%EndIKnowBatch(pCubeName,.tMsrList,pVerbose)")
			Do tMeth.Implementation.WriteLine(" Set tIkTime = $ZH-tIkStartTime")
			Do tMeth.Implementation.WriteLine(" Set x = $I(^IRIS.Temp.DeepSeeBuildStats($namespace,"_$$$quote($$$UPPER(pCube.name))_",""iknow""),tIkTime)")
			Do tMeth.Implementation.WriteLine(" Quit tSC")
		}
		Else {
			Do tMeth.Implementation.WriteLine(" Quit $$$OK")
		}
		Do tClassDef.Methods.Insert(tMeth)

		#; %InjectFact method (called by cube %InjectFact method)
		#; JMD1137 add pDimensionsOnly
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%InjectFact")
		Set tMeth.Name = "%InjectFact"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "&pFactId:%Integer,&pValues:%String,*pChunks:%Integer,pDimensionsOnly:%Boolean=0,pFactList:%String="""""		// DTB886 - Add pFactList
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Perform the work of injecting one fact into the cube without associated source data.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" New %var,%source,%value")
		Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
		Do tMeth.Implementation.WriteLine(" Try {")
		Do tMeth.Implementation.WriteLine("  Set %value=""""")

		// copy data into %var (use source property names as subscripts for pValues)
		Set f = $O(tSelectList(""))
		While (f '= "") {
			// JMD1184
			Set tFName = $P(f,"~~",1)
			Set tFModifier = $P(f,"~~",2)
			If (tFModifier'="") {
				// attempt backward compatibility:
				// default modified name with unmodified name
				Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(tSelectList(f))_") = $G(pValues("_$$$quote(f)_"),$G(pValues("_$$$quote(tFName)_")))")
			}
			Else {
				Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(tSelectList(f))_") = $G(pValues("_$$$quote(f)_"))")
			}
			Set f = $O(tSelectList(f))
		}

		// copy data into %source
		Set f = $O(tXFormProps(""))
		While (f '= "") {
			Do tMeth.Implementation.WriteLine("  Set %source("_$$$quote(f)_") = $G(pValues("_$$$quote(f)_"))")
			Set f = $O(tXFormProps(f))
		}
		
		// DTB893 - Test for factList
		Do tMeth.Implementation.WriteLine("  Set tUseFactList = ($G(pFactList)'="""")")

		// apply date type conversions
		If $D(tDateTypeProps) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; apply date conversions")

			Set p = $O(tDateTypeProps(""))
			While (p '= "") {
				Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(p)_") = ##class(%DeepSee.Utils).%ConvertDate(%var("_$$$quote(p)_"),"_$$$quote(tDateTypeProps(p))_")")
				Set p = $O(tDateTypeProps(p))
			}
		}

		// if there are any "copy from" fields, get values for them
		If ($D(tCopyFromList)) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; Copy aliased fields")
			Set f = $O(tCopyFromList(""))
			While (f '= "") {
				Set src = tCopyFromList(f)
				Do tMeth.Implementation.WriteLine("  Set %var("_$$$quote(f)_") = $G(%var("_$$$quote(src)_"))")		// DTB913
				Set f = $O(tCopyFromList(f))
			}
		}

		// Perform transform logic for *local* expressions
		If $D(tXFormCode) {
			Do tMeth.Implementation.WriteLine("  #; apply local expressions")
			Set f = $O(tXFormCodeLocal(""))
			While (f '= "") {
				Set tCode = tXFormCodeLocal(f)
				If (tCode '= "") {
					// replace method calls
					Set:$IsObject($G(%class)) tCode = $Replace(tCode,"%cube.","##class("_%class.Name_").")
					Set tCode = "  Set %expression("_$$$quote(f)_") = " _ tCode
				}
				Else {
					Set tCode = "  Set %expression("_$$$quote(f)_") = """""
				}

				Do tMeth.Implementation.WriteLine(tCode)
				Set f = $O(tXFormCodeLocal(f))
			}
		}

		// Perform transform logic (from sourceExpressions)
		If $D(tXFormCode) {
			Do tMeth.Implementation.WriteLine("")
			Do tMeth.Implementation.WriteLine("  #; apply source expressions")
			Set f = $O(tXFormCode(""))
			While (f '= "") {
				Set tCode = tXFormCode(f)
				If (tCode '= "") {
					// replace method calls
					Set:$IsObject($G(%class)) tCode = $Replace(tCode,"%cube.","##class("_%class.Name_").")
					Set tCode = "  Set:('tUseFactList||$ListFind(pFactList,"_$$$quote(f)_")) %var("_$$$quote(f)_") = " _ tCode		// DTB893 - Suppress calculation if not in the fact list
				}
				Else {
					Set tCode = "  Set %var("_$$$quote(f)_") = """""
				}

				Do tMeth.Implementation.WriteLine(tCode)
				Set f = $O(tXFormCode(f))
			}
		}

		// invoke the %ProcessFact method
		Do tMeth.Implementation.WriteLine("")
		Do tMeth.Implementation.WriteLine("  #; invoke method to process this fact")
		Do tMeth.Implementation.WriteLine("  Set pFactId = $G(pFactId)")
		Do tMeth.Implementation.WriteLine("  Set tSC = ##class("_tClassDefName_").%ProcessFact("""",0,.%var,.pFactId,.pErrorMsg,,pDimensionsOnly,pFactList,.tUpdater)")		// DTB886 - Add pFactList
		Do tMeth.Implementation.WriteLine("  If $$$ISOK(tSC) {")
		Do tMeth.Implementation.WriteLine("   Set:(pFactId'="""")&&('pDimensionsOnly) pChunks(pFactId\64000+1) = """"")
		Do tMeth.Implementation.WriteLine("  }")

		// !!! detect changes

		Do tMeth.Implementation.WriteLine(" }") // try
		Do tMeth.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
		// JMD1480
		Do tMeth.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth.Implementation.WriteLine(" Quit tSC")
		Do tClassDef.Methods.Insert(tMeth)
		// End of %InjectFact

		#; %DeleteFact method (called by %UpdateFacts)
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%DeleteFact")
		Set tMeth.Name = "%DeleteFact"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pID:%String,*pFactId:%Integer,*pErrorMsg:%String"
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Perform the work of deleting one fact in the cube.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
		Do tMeth.Implementation.WriteLine(" New %ROWID,%msg")
		Do tMeth.Implementation.WriteLine(" Try {")
		Do tMeth.Implementation.WriteLine("  Set (SQLCODE,tStarId) = """"")
		Do tMeth.Implementation.WriteLine("  Set pErrorMsg = """"")
		Do tMeth.Implementation.WriteLine("  Set pFactId = """"")

		// We have to do this check directly as we do not report this index to SQL
		Do tMeth.Implementation.WriteLine("  Set pFactId = $O($$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceId")_",pID,""""))")
		Do tMeth.Implementation.WriteLine("  If (pFactId'="""") {")
		Do tMeth.Implementation.WriteLine("   &sql(DELETE FROM "_tFactTableName_" WHERE %ID = :pFactId)")

		// update source indices
		Do tMeth.Implementation.WriteLine("   Kill $$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceId")_",pID,pFactId)")
		Do tMeth.Implementation.WriteLine("   Kill $$$DeepSeeIndexGLVN("_$$$quote(tCubeName)_","_$$$quote("%sourceIdReverse")_",pFactId)")

		// pass iKnow properties on to iKnow class
		If $D(tiKnowProps) {
			Set tiProp = $O(tiKnowProps(""))
			While (tiProp'="") {
				Set tiType = $P($G(tiKnowProps(tiProp)),":",2)
				Set:tiType="" tiType = "string"

				// pass measure name to iKnow
				Set tMsrName = $G(pFactInfo("prop",tiProp,"msrname"))
				Do tMeth.Implementation.WriteLine("   Set tSC=##class(%iKnow.DeepSee.CubeUtils).%ProcessIKnowFact("_$$$quote(tCubeName)_",0,""D"",pFactId,"_$$$quote(tMsrName)_",,"_$$$quote(tiType)_")")
				Do tMeth.Implementation.WriteLine("   Do:$$$ISERR(tSC) ..%LogError(tSC)")
				Set tiProp = $O(tiKnowProps(tiProp))
			}
		}

		Do tMeth.Implementation.WriteLine("  }")

		Do tMeth.Implementation.WriteLine(" }") // try
		Do tMeth.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
		Do tMeth.Implementation.WriteLine("  Set pErrorMsg = $ZE")
		Do tMeth.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth.Implementation.WriteLine(" Quit tSC")
		Do tClassDef.Methods.Insert(tMeth)
		// End of %DeleteFact

		#; %OnKillFacts method (called by %KillFacts)
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%OnKillFacts")
		Set tMeth.Name = "%OnKillFacts"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = ""
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Notification that this cube is being killed.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
		Do tMeth.Implementation.WriteLine(" Try {")

		// pass iKnow properties on to iKnow class
		If $D(tiKnowProps) {
			Set ip = $O(tiKnowProps(""))
			While (ip'="") {
				Set tMsrName = $G(pFactInfo("prop",ip,"msrname"))
				Do tMeth.Implementation.WriteLine("  Set tMsrList("_$$$quote(tMsrName)_") = """"")
				Set ip = $O(tiKnowProps(ip))
			}
			Do tMeth.Implementation.WriteLine("  Set tSC=##class(%iKnow.DeepSee.CubeUtils).%OnKillFacts("_$$$quote(tCubeName)_",.tMsrList)")
			Do tMeth.Implementation.WriteLine("  Quit:$$$ISERR(tSC)")
		}
		Do tMeth.Implementation.WriteLine(" }") // try
		Do tMeth.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
		Do tMeth.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth.Implementation.WriteLine(" Quit tSC")
		Do tClassDef.Methods.Insert(tMeth)
		// End of %OnKillFacts

		#; %PrecomputeAggregates method (called by %BuildCube)
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%PrecomputeAggregates")
		Set tMeth.Name = "%PrecomputeAggregates"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pStartChunk:%Integer,pEndChunk:%Integer,pAggGLVN:%String,pVerbose:%Boolean=0,pTaskGroup:%String="""",&pCount:%Integer=0"
		Set tMeth.ReturnType = "%Status"
		Set tMeth.Description = "Pre-compute certain aggregates.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateFactTable.<br/>"_$C(13,10)_
       							"DO NOT CALL THIS METHOD DIRECTLY"
		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
		Do tMeth.Implementation.WriteLine(" New %ROWID,%msg,%var")
		Do tMeth.Implementation.WriteLine(" Kill @pAggGLVN")
		Do tMeth.Implementation.WriteLine(" Try {")
		Do tMeth.Implementation.WriteLine("  Set (SQLCODE) = """"")
		Do tMeth.Implementation.WriteLine("  Set tLastCount = 0")

		If ((pCube.precompute>0) && $D(tMeasuresPrecompute) && $D(tFactsPrecompute)) {
			// generate SQL statement against fact table
			Set tSELECT = "%ID"
			Set tINTO = ":tID"
			Set f = $O(tFactsPrecompute(""))
			While (f'="") {
				Set tSELECT = tSELECT_","_f
				Set tINTO = tINTO_",:%var("_$$$quote(f)_")"
				Set f = $O(tFactsPrecompute(f))
			}
			Set m = $O(tMeasuresPrecompute(""))
			While (m'="") {
				Set tSELECT = tSELECT_","_m
				Set tINTO = tINTO_",:%var("_$$$quote(m)_")"
				Set m = $O(tMeasuresPrecompute(m))
			}

			Do tMeth.Implementation.WriteLine("  Set tStartID = ((pStartChunk-1)*64000)+1")
			Do tMeth.Implementation.WriteLine("  Set tEndID = pEndChunk*64000")

			Do tMeth.Implementation.WriteLine("  &sql(DECLARE sqpc CURSOR FOR")
			Do tMeth.Implementation.WriteLine("  SELECT " _ tSELECT)
			Do tMeth.Implementation.WriteLine("  INTO " _ tINTO)
			Do tMeth.Implementation.WriteLine("  FROM "_tFactTableName)
			Do tMeth.Implementation.WriteLine("  WHERE %ID BETWEEN :tStartID AND :tEndID")
			Do tMeth.Implementation.WriteLine("  )")

			Do tMeth.Implementation.WriteLine("  &sql(OPEN sqpc)")
			Do tMeth.Implementation.WriteLine("  If (SQLCODE'=0) {")
			Do tMeth.Implementation.WriteLine("   Set tSC = $$$ERROR($$$GeneralError,""Error opening SQL cursor: (""_$G(SQLCODE)_"") ""_$G(%msg))")
			Do tMeth.Implementation.WriteLine("   Quit")
			Do tMeth.Implementation.WriteLine("  }")

			Do tMeth.Implementation.WriteLine("  &sql(FETCH sqpc)")
			Do tMeth.Implementation.WriteLine("  While (SQLCODE=0) {")

			Do tMeth.Implementation.WriteLine(" Set pCount = pCount + 1")
			Do tMeth.Implementation.WriteLine(" If (pVerbose&&'(pCount#1000)) Write $C(13,27)_""[0J""_""Computing aggregates: ""_$J($FN(pCount,"","",0),10)_"" fact(s) processed.""")
			Do tMeth.Implementation.WriteLine(" If ((pTaskGroup'="""")&&'(pCount#1000)) {")
			Do tMeth.Implementation.WriteLine("  Set tDelta = pCount - tLastCount")
			Do tMeth.Implementation.WriteLine("  Set inc=$I(^IRIS.Temp.DeepSeeUpdate($namespace,pTaskGroup,""facts""),tDelta)")
			Do tMeth.Implementation.WriteLine("  Set tLastCount = pCount")
			Do tMeth.Implementation.WriteLine(" }")

			// first get counts for each fact by itself
			Do tMeth.Implementation.WriteLine("  // Level 1")
			Set f = $O(tFactsPrecompute(""))
			While (f'="") {
				Set fno = $LG(tFactsPrecompute(f),1)
				Set key = $TR($J("",fno)," ",":")
				Do tMeth.Implementation.WriteLine("  Set x = $I(@pAggGLVN@("_$$$quote(key)_"_%var("_$$$quote(f)_"))) // " _fno)
				Set f = $O(tFactsPrecompute(f))
			}

			If (pCube.precompute>1) {
				Do tMeth.Implementation.WriteLine("  // Level 2")
				// now get combinations of 2
				Set f1 = $O(tFactsPrecompute(""))
				While (f1'="") {
					Set f1no = $LG(tFactsPrecompute(f1),1)
					Set f2 = $O(tFactsPrecompute(""))
					While (f2'="") {
						If (f2'=f1) {
							Set f2no = $LG(tFactsPrecompute(f2),1)
							// determine key expression
							If (f1no < f2no) {
								Set key1 = $TR($J("",f1no)," ",":")
								Set key2 = $TR($J("",f2no-f1no)," ",":")
								Set expr = $$$quote(key1)_"_%var("_$$$quote(f1)_")_"_$$$quote(key2)_"_%var("_$$$quote(f2)_")"
							}
							Else {
								Set key1 = $TR($J("",f2no)," ",":")
								Set key2 = $TR($J("",f1no-f2no)," ",":")
								Set expr = $$$quote(key1)_"_%var("_$$$quote(f2)_")_"_$$$quote(key2)_"_%var("_$$$quote(f1)_")"
							}
							Do tMeth.Implementation.WriteLine("  Set x = $I(@pAggGLVN@("_expr_")) // " _f1no_","_f2no)
						}
						Set f2 = $O(tFactsPrecompute(f2))
					}
					Set f1 = $O(tFactsPrecompute(f1))
				}
			}

			// compute measures
			Do tMeth.Implementation.WriteLine("  // Measures")
			Set m = $O(tMeasuresPrecompute(""))
			While (m'="") {
				Set mno = $LG(tMeasuresPrecompute(m),1)
				Do tMeth.Implementation.WriteLine("  If (%var("_$$$quote(m)_")'="""") {")
				Do tMeth.Implementation.WriteLine("   Set msr = $G(%var("_$$$quote(m)_"))")		// DTB913
				Set f = $O(tFactsPrecompute(""))
				While (f'="") {
					Set fno = $LG(tFactsPrecompute(f),1)
					Set key = $TR($J("",fno)," ",":")

					Do tMeth.Implementation.WriteLine("   Set agg = $G(@pAggGLVN@("_$$$quote(key)_"_%var("_$$$quote(f)_"),"_+$E(mno,2,*)_")) // " _fno)
					Do tMeth.Implementation.WriteLine("   Set min = $LG(agg,2),max=$LG(agg,3),count=$LG(agg,4)")
					Do tMeth.Implementation.WriteLine("   Set min = $S((min="""")||(min>msr):msr,1:min)")
					Do tMeth.Implementation.WriteLine("   Set max = $S((max="""")||(max<msr):msr,1:max)")
					Do tMeth.Implementation.WriteLine("   Set @pAggGLVN@("_$$$quote(key)_"_%var("_$$$quote(f)_"),"_+$E(mno,2,*)_") = $LB(msr+$LG(agg,1),min,max,count+1)")

					Set f = $O(tFactsPrecompute(f))
				}
				// measures against 2 facts
				If (pCube.precompute>1) {
					Do tMeth.Implementation.WriteLine("   // Level 2")
					Set f1 = $O(tFactsPrecompute(""))
					While (f1'="") {
						Set f1no = $LG(tFactsPrecompute(f1),1)
						Set f2 = $O(tFactsPrecompute(""))
						While (f2'="") {
							If (f2'=f1) {
								Set f2no = $LG(tFactsPrecompute(f2),1)
								// determine key expression
								If (f1no < f2no) {
									Set key1 = $TR($J("",f1no)," ",":")
									Set key2 = $TR($J("",f2no-f1no)," ",":")
									Set expr = $$$quote(key1)_"_%var("_$$$quote(f1)_")_"_$$$quote(key2)_"_%var("_$$$quote(f2)_")"
								}
								Else {
									Set key1 = $TR($J("",f2no)," ",":")
									Set key2 = $TR($J("",f1no-f2no)," ",":")
									Set expr = $$$quote(key1)_"_%var("_$$$quote(f2)_")_"_$$$quote(key2)_"_%var("_$$$quote(f1)_")"
								}
								Do tMeth.Implementation.WriteLine("   Set x = $I(@pAggGLVN@("_expr_","_+$E(mno,2,*)_"),%var("_$$$quote(m)_")) // " _f1no_","_f2no)
							}
							Set f2 = $O(tFactsPrecompute(f2))
						}
						Set f1 = $O(tFactsPrecompute(f1))
					}
				}

				Do tMeth.Implementation.WriteLine("  }")
				Set m = $O(tMeasuresPrecompute(m))
			}

			// fetch next fact
			Do tMeth.Implementation.WriteLine("   &sql(FETCH sqpc)")
			Do tMeth.Implementation.WriteLine("  }")
			Do tMeth.Implementation.WriteLine("  &sql(CLOSE sqpc)")
		}

		Do tMeth.Implementation.WriteLine(" If (pTaskGroup'="""") {")
		Do tMeth.Implementation.WriteLine("  Set tDelta = pCount - tLastCount")
		Do tMeth.Implementation.WriteLine("  Set inc=$I(^IRIS.Temp.DeepSeeUpdate($namespace,pTaskGroup,""facts""),tDelta)")
		Do tMeth.Implementation.WriteLine(" }")

		Do tMeth.Implementation.WriteLine(" }") // try
		Do tMeth.Implementation.WriteLine(" Catch(ex) {")
		Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
		Do tMeth.Implementation.WriteLine("  Set pErrorMsg = $ZE")
		Do tMeth.Implementation.WriteLine("  Do ..%LogError(tSC)")
		Do tMeth.Implementation.WriteLine(" }")
		Do tMeth.Implementation.WriteLine(" Quit tSC")
		Do tClassDef.Methods.Insert(tMeth)

		// End of %PrecomputeAggregates

		#; additional methods to support relationships
		#; on the many-side generate one %LookupIdFor<Relation> method per relationship
		#; %LookupIdFor<Relation> method(s)
		#; on the one-side generate triggers to maintain the ID to RelationID index
		Kill tTriggerList
		Set r = $O(pRelationInfo(""))
		While (r'="") {
			Set tCardinality = $G(pRelationInfo(r,"cardinality"))
			Set tStoredSide = +$G(pRelationInfo(r,"storedSide"))
			Set tRelName = $G(pRelationInfo(r,"name"))
			If (tStoredSide) {
				// queue this relation so we can include it in the trigger
				// organize by fact name
				Set tFact = $G(pRelationInfo(r,"fact"))
				Set tTriggerList(tFact) = tRelName
				Set tTriggerList(tFact,"cardinality") = tCardinality
			}
			Set r = $O(pRelationInfo(r))
		}

		#; create relationship indices if needed
		// loop over relationship facts
		Set tFact = $O(tTriggerList(""))
		While (tFact'="") {
			Set tHasMany = $G(tTriggerList(tFact,"cardinality"))="many"
			// special index to map facts on the many(child)-side to
			// facts on the one(parent)-side
			Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||%Inverse"_tFact)
			Set tIndexDef.Name = "%Inverse"_tFact
			If (tHasMany){
				Set tIndexDef.Properties = "%%ID"_","_tFact_"(KEYS)"
			}
			Else {
				Set tIndexDef.Properties = "%%ID"_","_tFact
			}
			Set tIndexDef.SequenceNumber = $I(tSeq)
			Set tIndexDef.Description = "Inverse index for relationship "_tFact_"."
			Do tClassDef.Indices.Insert(tIndexDef)

			Set tIndexStore = ##class(%Dictionary.StorageIndexDefinition).%New(tClassDefName_":*Inverse"_tProp.Name)
			Set tIndexStore.Name = "%Inverse"_tFact
			Set tLoc = $Name($$$DeepSeeRelationGLVN)_"("_$$$quote(tCubeName)_","_$$$quote($$$UPPER(tFact))_")"
			Set tIndexStore.Location = tLoc
			Do tStorage.Indices.Insert(tIndexStore)

			// next fact
			Set tFact = $O(tTriggerList(tFact))
		}

		#; save the fact table class definition
	    Set tSC = tClassDef.%Save()
	    If $$$ISERR(tSC) Quit

		// Write !,tClassDef.Name," saved"

	    #; Now queue the generated class for compilation
	    Do QueueClass^%occCompile(tClassDefName)
	    #; Mark this class for deletion when the cube class is deleted.
	    $$$comClassArraySet(pCubeClass,$$$cCLASSclasses,tClassDefName_".CLS","")
	    $$$defClassKeySet(tClassDefName,$$$cCLASSgeneratedby,pCubeClass_".CLS")

		#; create the listing table for this cube
		#; Delete any pre-existing definition
		#; create fact table class
		Set tClassDefName = pSchema_".Listing"

		#; we have to get SQL name manually as oddCOM does not exist yet!
		Set tListingTableName = $TR(pSchema,".","_")_".Listing"

		If $$$defClassDefined(tClassDefName) {
		    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
		    If $$$ISERR(tSC) Quit
		}

		#; Create a new class definition
		Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
		If tClassDef = $$$NULLOREF Set tSC=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
		Set tClassDef.Super = "%DeepSee.ListingTable"
        Set tClassDef.IncludeCode = "%DeepSee"
        Set tClassDef.ProcedureBlock = 1
        Set tClassDef.Description = "Listing table for cube '"_pCube.name_"'.<br/>"_$C(13,10)_
        							"THIS IS A GENERATED CLASS, DO NOT EDIT.<br/>"_$C(13,10)_
        							"Generated by %DeepSee.Generator:%CreateFactTable."

		#; CUBENAME param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"CUBENAME")
		Set tParmDef.Default = pCube.name
		Do tClassDef.Parameters.Insert(tParmDef)

		#; storage for listing table
		Set tStorage = ##class(%Dictionary.StorageDefinition).%New(tClassDefName_"||Default")
		Set tStorage.Name = "Default"
		Set tStorage.ExtentSize = 1000
		Set tStorage.DataLocation = ..%GetListingLocation(pCube.name)
		Do tClassDef.Storages.Insert(tStorage)

		#; save the listing table class definition
	    Set tSC = tClassDef.%Save()
	    If $$$ISERR(tSC) Quit

		// Write !,tClassDef.Name," saved"

	    #; Now queue the generated class for compilation
	    Do QueueClass^%occCompile(tClassDefName)

	    #; Mark this class for deletion when the cube class is deleted.
	    $$$comClassArraySet(pCubeClass,$$$cCLASSclasses,tClassDefName_".CLS","")
	    $$$defClassKeySet(tClassDefName,$$$cCLASSgeneratedby,pCubeClass_".CLS")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Internal method. Given a list of items of the form:<br/>
/// pDepends(item) = ""<br/>
/// pDepend(item,parent)<br/>
/// Return an ordered list with base items listed first.
ClassMethod %BuildOrderedList(ByRef pDepends, Output pList) As %Status
{
	Set tSC = $$$OK

	// Process items with dependencies
	While ($D(pDepends)) {
		Set tItem = $O(pDepends(""))
		While (tItem '= "") {
			Kill tList
			Kill tVisits
			Set tSC = ..%GetAncestors(tItem,.pDepends,.tList,.tVisits)
			If $$$ISERR(tSC) Quit

			// add ancestors to the output
			Set n = $O(tList(""))
			While (n '= "") {
				Set pList($I(pList)) = tList(n)
				Set n = $O(tList(n))
			}
			Set tItem = $O(pDepends(tItem))
		}
		If $$$ISERR(tSC) Quit
	}

	Quit tSC
}

/// Internal method. Given an item within a dependency list,
/// return its set of ancestors (items with no further dependencies).
ClassMethod %GetAncestors(pItem As %String, ByRef pDepends, Output pList, ByRef pVisited) As %Status
{
	Set tSC = $$$OK
	Set tParent = $O(pDepends(pItem,""))
	If (tParent = "") {
		Set pList($I(pList)) = pItem
		// remove every reference to pItem
		Kill pDepends(pItem)
		Set tItem = $O(pDepends(""))
		While (tItem '= "") {
			If $D(pDepends(tItem,pItem)) {
				Kill pDepends(tItem,pItem)
			}
			Set tItem = $O(pDepends(tItem))
		}
	}
	Else {
		While (tParent '= "") {
			If ($D(pVisited(tParent))) {
				Set tSC = $$$ERROR($$$GeneralError,"Circular dependency encountered: "_pItem_"->"_tParent)
				Quit
			}
			Else {
				Set pVisited(tParent) = ""
				Set tSC = ..%GetAncestors(tParent,.pDepends,.pList,.pVisited)
				If $$$ISERR(tSC) Quit
			}
			Set tParent = $O(pDepends(pItem,tParent))
		}
	}
	Quit tSC
}

/// Construct a storage location for a dimension (star) table.
/// Note that these are subscripted by upper-case class name.
ClassMethod %GetDimensionLocation(pClassName As %String, pSuffix As %String = "") As %String [ CodeMode = expression, Internal ]
{
$Name($$$DeepSeeDimGLVN)_pSuffix_"("_$$$quote($$$UPPER(pClassName))_")"
}

/// Construct a storage location for a fact table.
/// Note that these are subscripted by upper-case class name.
ClassMethod %GetFactLocation(pClassName As %String, pSuffix As %String = "") As %String [ CodeMode = expression, Internal ]
{
$Name($$$DeepSeeFactGLVN)_pSuffix_"("_$$$quote($$$UPPER(pClassName))_")"
}

/// Construct a storage location for a listing table.
/// Note that these are subscripted by upper-case cube name.
ClassMethod %GetListingLocation(pCubeName As %String) As %String [ CodeMode = expression, Internal ]
{
$Name($$$DeepSeeListingGLVN)_"("_$$$quote($$$UPPER(pCubeName))_")"
}

/// Construct a storage location for a fact table index.
/// Note that these are subscripted by cube name and index number.
ClassMethod %GetIndexLocation(pCubeName As %String, pIndex As %String) As %String [ CodeMode = expression, Internal ]
{
$Name($$$DeepSeeIndexGLVN)_"("_$$$quote($$$UPPER(pCubeName))_","_$$$quote(pIndex)_")"
}

/// Construct a storage location for a fact table search index.
/// Note that these are subscripted by cube name and prop name.
ClassMethod %GetSearchIndexLocation(pCubeName As %String, pPropName As %String) As %String [ CodeMode = expression, Internal ]
{
$Name($$$DeepSeeIndexGLVN)_"("_$$$quote($$$UPPER(pCubeName))_","_$$$quote(pPropName)_")"
}

/// Create a Star (dimension) table.<br/>
/// This table is used to hold members of a dimension level.
ClassMethod %CreateStarTable(pCube As %DeepSee.Model.cube, pCubeClass As %String, pStar As %String, ByRef pStarInfo As %List) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tClassDefName = pStar
		Set tSchema = $P(pStar,".",1,$L(pStar,".")-1)
		Set tCls = $P(pStar,".",$L(pStar,"."))

		#; we have to get SQL name manually as oddCOM does not exist yet!
		Set tTableName = $TR(tSchema,".","_")_"."_tCls

		#; create STAR table class
		#; Delete any pre-existing definition
		If $$$defClassDefined(tClassDefName) {
		    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
		    If $$$ISERR(tSC) Quit
		}

		#; find KEY field and NAME field(s) for star table
		Set tKeyField = ""
		Set tDescField = ""
		Kill tNameFields,tRollups
		Set tNameFieldCount = 0
		Set tRollupCount = 0
		Set tName = $O(pStarInfo(pStar,"prop",""))
		While (tName '= "") {
			Set tUse = $G(pStarInfo(pStar,"prop",tName,"use"))
			If (tUse = "key") {
				Set tKeyField = tName
				
				// + WAL131 -- save this value for the reference fields
				Set tKeyFieldSourceProp = $G(pStarInfo(pStar,"prop",tName,"source"))
				// - WAL131
			}
			ElseIf (tUse = "name") {
				Set tNameFields(tName) = ""
				Set tNameFieldCount = tNameFieldCount + 1
			}
			ElseIf (tUse = "description") {
				Set tDescField = tName
				// index as name field
				Set tNameFields(tName) = ""
				Set tNameFieldCount = tNameFieldCount + 1
			}
			ElseIf (tUse = "rollup") {
				Set tRollups(tName) = ""
				Set tRollupCount = tRollupCount + 1
			}
			Set tName = $O(pStarInfo(pStar,"prop",tName))
		}

		If ('$D(tNameFields)) {
			Set:tKeyField'="" tNameFields(tKeyField) = ""
		}
		#; n.b, is there any use for namefields?
		
		#; Create a new class definition
		Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
		If tClassDef = $$$NULLOREF Set tSC=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
		Set tClassDef.Super = "%DeepSee.DimensionTable"
        Set tClassDef.ProcedureBlock = 1
		Set tClassDef.Owner = pCube.owner
        Set tClassDef.Description = "Dimension table for cube '"_pCube.name_"'"_$C(13,10)_
        							"THIS IS A GENERATED CLASS, DO NOT EDIT.<br/>"_$C(13,10)_
        							"Generated by %DeepSee.Generator:%CreateStarTable."

		#; storage for star table
		#dim tStorage As %Dictionary.StorageDefinition
		Set tStorage = ##class(%Dictionary.StorageDefinition).%New(tClassDefName_"||Default")
		Set tStorage.Name = "Default"
		Set tStorage.ExtentSize = 100
		Set tStorage.DataLocation = ..%GetDimensionLocation(tClassDefName)
		Set tStorage.IndexLocation = ..%GetDimensionLocation(tClassDefName,"I")
		Set tStorage.StreamLocation = ..%GetDimensionLocation(tClassDefName,"S")
		Do tClassDef.Storages.Insert(tStorage)

		#; CUBENAME param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"CUBENAME")
		Set tParmDef.Default = pCube.name
		Do tClassDef.Parameters.Insert(tParmDef)

		#; KEYPROPERTY param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"KEYPROPERTY")
		Set tParmDef.Default = tKeyField
		Do tClassDef.Parameters.Insert(tParmDef)

		#; DESCRIPTIONPROPERTY param
		Set tParmDef = ##class(%Dictionary.ParameterDefinition).%New(tClassDefName_":"_"DESCRIPTIONPROPERTY")
		Set tParmDef.Default = tDescField
		Do tClassDef.Parameters.Insert(tParmDef)

		#; %Count method
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%Count")
		Set tMeth.Name = "%Count"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = ""
		Set tMeth.ReturnType = "%Integer"
		Set tMeth.Description = "Return the total number of members within this dimension.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateStarTable."

		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tCount = 0")
		Do tMeth.Implementation.WriteLine(" &sql(SELECT COUNT(*) INTO :tCount FROM "_tTableName_")")
		Do tMeth.Implementation.WriteLine(" Quit tCount")

		Do tClassDef.Methods.Insert(tMeth)

		// JMD925: validate KEY
		#; KEYIsValid  method
		If (tKeyField'="") {
			Set tVName = tKeyField_"IsValid"
			Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||"_tVName)
			Set tMeth.Name = tVName
			Set tMeth.ClassMethod = 1
			Set tMeth.FormalSpec = "pArg:%String"
			Set tMeth.ReturnType = "%Status"
			Set tMeth.Description = "Validate the KEY value for this dimension.<br/>"_$C(13,10)_
	       							"Generated by %DeepSee.Generator:%CreateStarTable."

			Set tMeth.SequenceNumber = $I(tSeq) + 2000
			Do tMeth.Implementation.WriteLine(" Quit ##class(%DeepSee.DimensionTable).%ValidateKEY(pArg)")

			Do tClassDef.Methods.Insert(tMeth)
		}

		#; %GetMemberSpec method
		#; This is used by XMLA output to generate a spec for a member
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||%GetMemberSpec")
		Set tMeth.Name = "%GetMemberSpec"
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pMemberId:%String,pCubeName:%String,pDimNo:%Integer,pHierNo:%Integer,pLevelNo:%Integer"
		Set tMeth.ReturnType = "%String"
		Set tMeth.Description = "Return the specification string for the given member.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateStarTable."

		Set tMeth.SequenceNumber = $I(tSeq) + 2000

		Do tMeth.Implementation.WriteLine(" Set tSpec = """"")

		// JMD1453: simplify and return &[key] and not name
		Do tMeth.Implementation.WriteLine(" Set:pMemberId'="""" tSpec = ""&[""_$$$dsEscapeIdent(.."_tKeyField_"GetStored(pMemberId))"_"_""]""")
		Do tMeth.Implementation.WriteLine(" Quit tSpec")
		Do tClassDef.Methods.Insert(tMeth)

		#; properties
		#; generate a %GetDimensionProperty method as we go along
		#; this includes embedded SQL statements to fetch each property

		Set tMethName = "%GetDimensionProperty"
		Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||"_tMethName)
		Set tMeth.Name = tMethName
		Set tMeth.ClassMethod = 1
		Set tMeth.FormalSpec = "pProp:%String,pID:%String,*pFormat:%String,*pType:%String"
		Set tMeth.ReturnType = "%String"
		Set tMeth.Description = "Fetch the value of a given dimension property.<br/>"_$C(13,10)_
       							"Generated by %DeepSee.Generator:%CreateStarTable."

		Set tMeth.SequenceNumber = $I(tSeq) + 2000
		Do tMeth.Implementation.WriteLine(" Set pProp = $$$UPPER(pProp)")
		Do tMeth.Implementation.WriteLine(" Set tValue=""""")
		Do tMeth.Implementation.WriteLine(" Set pFormat=""""")

		#; loop over properties
		Set tPropCount = 0
		Set tName = $O(pStarInfo(pStar,"prop",""))
		While (tName '= "") {
			Set tType = $G(pStarInfo(pStar,"prop",tName,"type"))
			Set tSource = $G(pStarInfo(pStar,"prop",tName,"source")) // used for description
			Set tExpr = $G(pStarInfo(pStar,"prop",tName,"expr"))
			Set tUse = $G(pStarInfo(pStar,"prop",tName,"use"))
			Set tIsRef = +$G(pStarInfo(pStar,"prop",tName,"isref"))
			Set tClsType = $$$getClassType($$$NormalizeClassname(tType))
			Set tPropCount = tPropCount + 1

			// JMD909
			Set tFormat = $G(pStarInfo(pStar,"prop",tName,"format"))

			Set tProp = ##class(%Dictionary.PropertyDefinition).%New(tClassDefName_"||"_tName)
			Set tProp.Name = tName
			
			If (..%IsString(tType)) {
				// DTB491 - If this is a custom type that extends %String, treat it like a %String
				Set tType = "%String"
			}
			Set tProp.Type = ..%DenormalizeType(tType)
			If ((tUse="key")||(tUse="rollup")) {
				Set tProp.Required = 1
				If ((tUse="key")&&(tProp.Type'="%String")) {
					// Keys must be strings (to handle NULL and UNIQUE tests)
					Set tProp.Type = "%String"
					// JMD1080: remember collation
					Set tCollation = $G(pStarInfo(pStar,"prop",tName,"parms","COLLATION"))
					Kill pStarInfo(pStar,"prop",tName,"parms")
					Set:tCollation'="" pStarInfo(pStar,"prop",tName,"parms","COLLATION") = tCollation
				}
				ElseIf(tUse="key") {
					// JMD1190: if not specified, use SQLUPPER(113) for string key fields
					Set tCollation = $G(pStarInfo(pStar,"prop",tName,"parms","COLLATION"))
					If (tCollation="") {
						Set pStarInfo(pStar,"prop",tName,"parms","COLLATION") = "SQLUPPER(113)"
					}
				}
			}
			ElseIf (tUse="name")&&((tProp.Type="%String")||(tProp.Type="%Library.String")) {
				// DTB445 - Add SQLUPPER(113) to strings if not already defined.
				Set tCollation = $G(pStarInfo(pStar,"prop",tName,"parms","COLLATION"))
				If (tCollation="") {
					Set pStarInfo(pStar,"prop",tName,"parms","COLLATION") = "SQLUPPER(113)"
				}
			}

			If (tIsRef) {
				// reference field: generated sql compute logic
				Set tRefFields(tName) = tProp.Type
				Set tProp.Calculated = 1
				Set tProp.SqlComputed = 1
				Set tProp.SqlComputeCode = "Set {"_tProp.Name_"}=##class("_tClassDefName_").%Fetch"_tName_"({"_tKeyField_"})"
			}

			Set tProp.Description = ..%MakeDescription($$$Text("Dimension property","%DeepSee"),tName, $S(tSource="":tExpr,1:tSource))
			Set tProp.SequenceNumber = $I(tSeq) + 1000
			Do tClassDef.Properties.Insert(tProp)

			// always ignore maxlen!
			If ((tProp.Type = "%Library.String")||(tProp.Type = "%String")) {
				Do tProp.Parameters.SetAt(2000,"MAXLEN")
			}

			Set parm = $O(pStarInfo(pStar,"prop",tName,"parms",""))
			While (parm '= "") {
				Set value = $G(pStarInfo(pStar,"prop",tName,"parms",parm))
				If ((parm'="MAXLEN")&&(parm'="MINVAL")&&(parm'="MAXVAL")) {
					// skip maxlen and other validation
					// JMD1080 No collation for non-string properties
					If ((parm'="COLLATION")||(tProp.Type = "%Library.String")||(tProp.Type = "%String")) {
						Do tProp.Parameters.SetAt(value,parm)
					}
				}
				Set parm = $O(pStarInfo(pStar,"prop",tName,"parms",parm))
			}

			// add case to method
			If (tPropCount = 1) {
				Do tMeth.Implementation.WriteLine(" If (pProp=" _ $$$quote($$$UPPER(tName))_") {")
			}
			Else {
				Do tMeth.Implementation.WriteLine(" ElseIf (pProp=" _ $$$quote($$$UPPER(tName))_") {")
			}
			Do tMeth.Implementation.WriteLine("  &sql(SELECT "_tName_" INTO :tValue FROM "_tTableName_" WHERE %ID = :pID)")

			// JMD909
			If (tFormat'="") {
				Do tMeth.Implementation.WriteLine("  Set:tValue'="""" pFormat="_$$$quote(tFormat))
			}
			// JMD988 Return type
			Do tMeth.Implementation.WriteLine("  Set pType="_$$$quote(tType))

			Do tMeth.Implementation.WriteLine(" }")
			
			If ($P(tType,".",1,*-1) = $P(pStar,".",1,*-1)) {
				// DTB754 - If the property type is another class in the current package, make a foreign key to point to it.
				Set tFKDef = ##class(%Dictionary.ForeignKeyDefinition).%New()
				Set tFKDef.Name = tName
				Set tFKDef.NoCheck = 1		// Check is not needed and carries a performance penalty. Turn it off.
				Set tFKDef.Properties = tName
				Set tFKDef.ReferencedClass = tType
				Set tFKDef.ReferencedKey = ""		// blank means use ID
				Do tClassDef.ForeignKeys.Insert(tFKDef)
			}

			// next prop
			Set tName = $O(pStarInfo(pStar,"prop",tName))
		}

		#; end of %GetDimensionProperty method
		Do tMeth.Implementation.WriteLine(" Quit tValue")
		Do tClassDef.Methods.Insert(tMeth)

		#; if there are reference fields, generate %Fetch<Field> methods
		#; to fetch their values
		Set tRefField = $O(tRefFields(""))
		While (tRefField'="") {
			Set tMethName = "%Fetch"_tRefField
			Set tMeth = ##class(%Dictionary.MethodDefinition).%New(tClassDefName_"||"_tMethName)
			Set tMeth.Name = tMethName
			Set tMeth.ClassMethod = 1
			Set tMeth.FormalSpec = "pKey:%String"
			Set tMeth.ReturnType = tRefFields(tRefField)
			Set tMeth.Description = "Fetch the current value of "_tMethName_".<br/>"_$C(13,10)_
	       							"Generated by %DeepSee.Generator:%CreateStarTable."

			Set tMeth.SequenceNumber = $I(tSeq) + 2000

			Do tMeth.Implementation.WriteLine(" // If we don't a value, show key as this is most likely the NULL substitute")
			Do tMeth.Implementation.WriteLine(" Set tValue=pKey")
			
			// figure out sql needed to find the source value
			Set tSourceClass = pCube.sourceClass
			Set tSourceProp = $G(pStarInfo(pStar,"prop",tRefField,"source"))
			
			// + WAL131 (3)
			Set tSourcePropRefs = $L(tSourceProp,".")
			Set tKeyFieldSourcePropRefs = $L(tKeyFieldSourceProp,".")
			Set tSourcePropStart = $P(tSourceProp,".",1,$L(tSourceProp,".")-1)
			Set tKeyFieldSourcePropStart = $P(tKeyFieldSourceProp,".",1,$L(tKeyFieldSourceProp,".")-1)		
			Set tNoRefs = ((tSourcePropRefs=1)&&(tKeyFieldSourcePropRefs=1))
			Set tPath = ((tKeyFieldSourceProp [ tSourcePropStart)&&'tNoRefs)
			Set tID = ((((tSourceProp [ tKeyFieldSourceProp)&&($L(tSourceProp,".") = ($L(tKeyFieldSourceProp,".")+1))))&&'tNoRefs)
			// - WAL131 (3)
			
			// properties come from the same table
			// strip off last property
			If ((tSourcePropRefs = tKeyFieldSourcePropRefs)&&(tSourcePropRefs>1)&&(tSourcePropStart=tKeyFieldSourcePropStart)) {
				Set tLastProp = $P(tSourceProp,".",$L(tSourceProp,"."))
				Set tSourceProp = $P(tSourceProp,".",1,$L(tSourceProp,".")-1)
								
				Set tSC = ..%AnalyzeStarProperty(tSourceClass,tSourceProp,.tType,,tSourceClass_"."_tSourceProp)
				If ("datatype" '= $$$getClassType($$$NormalizeClassname(tType))) {
					// had better be the case!
					Set tFTable = ..%GetSQLTableName(tType)
					Set tFField = ..%GetSQLColumnName(tType,tLastProp)
					
					// + WAL131 -- this code assumes that the keyfield and reference property come from the same source table
					// If we will query some other table, ask for the name of the property in that
					// table (i.e., home.address becomes address)
					Set tWhereField = $P(tKeyFieldSourceProp,".",$L(tKeyFieldSourceProp,"."))
					Do tMeth.Implementation.WriteLine(" &SQL(SELECT "_tFField_" INTO :tValue FROM "_tFTable_" WHERE " _ tWhereField _ " = :pKey)")
					// - WAL131
				}
				Quit:$$$ISERR(tSC)	
			}
			// The value of the level is an ID in the property's source table
			ElseIf (tID) {
				Set tLastProp = $P(tSourceProp,".",$L(tSourceProp,"."))
				Set tSourceProp = $P(tSourceProp,".",1,$L(tSourceProp,".")-1)
								
				Set tSC = ..%AnalyzeStarProperty(tSourceClass,tSourceProp,.tType,,tSourceClass_"."_tSourceProp)
				If ("datatype" '= $$$getClassType($$$NormalizeClassname(tType))) {
					// had better be the case!
					Set tFTable = ..%GetSQLTableName(tType)
					Set tFField = ..%GetSQLColumnName(tType,tLastProp)

					Set tWhereField = "%ID"
					Do tMeth.Implementation.WriteLine(" &SQL(SELECT "_tFField_" INTO :tValue FROM "_tFTable_" WHERE " _ tWhereField _ " = :pKey)")
				}
			}
			// tKeyFieldSourceProp is a reference from the table we will query
			ElseIf (tPath) {
				If (tSourceProp [ ".") {
					Set tLastProp = $P(tSourceProp,".",$L(tSourceProp,"."))
					Set tSourceProp = $P(tSourceProp,".",1,$L(tSourceProp,".")-1)
				}
				Else {
					Set tLastProp = "%ID"	
				}
								
				Set tSC = ..%AnalyzeStarProperty(tSourceClass,tSourceProp,.tType,,tSourceClass_"."_tSourceProp)
				If ("datatype" '= $$$getClassType($$$NormalizeClassname(tType))) {
					// had better be the case!
					Set tFTable = ..%GetSQLTableName(tType)
					Set tFField = ..%GetSQLColumnName(tType,tLastProp)
					If (tSourcePropStart'="") {
						Set tWhereField = $E(tKeyFieldSourceProp,$L(tSourcePropStart)+2,*)
					}
					Else {
						Set tWhereField = $E(tKeyFieldSourceProp,$L(tSourceProp)+2,*)	
					}
					Set tWhereField = $REPLACE(tWhereField,".","->")
					Do tMeth.Implementation.WriteLine(" &SQL(SELECT "_tFField_" INTO :tValue FROM "_tFTable_" WHERE " _ tWhereField _ " = :pKey)")
					// - WAL131
				}
			}
			// Don't share a path, use cube source table
			ElseIf (tSourceProp [ ".") {
				Set tCubeSourceClass = pCube.sourceClass
				Set tWhereField = $REPLACE(tKeyFieldSourceProp,".","->")
				Set tSelectField = $REPLACE(tSourceProp,".","->")
				Set tLastProp = $P(tSourceProp,".",$L(tSourceProp,"."))
				Set tSourceProp = $P(tSourceProp,".",1,$L(tSourceProp,".")-1)
								
				Set tSC = ..%AnalyzeStarProperty(tSourceClass,tSourceProp,.tType,,tSourceClass_"."_tSourceProp)
				If ("datatype" '= $$$getClassType($$$NormalizeClassname(tType))) {
					Set tFTable = ..%GetSQLTableName(tCubeSourceClass)
					Set tFField = ..%GetSQLColumnName(tType,tLastProp)
					Do tMeth.Implementation.WriteLine(" &SQL(SELECT "_tSelectField_" INTO :tValue FROM "_tFTable_" WHERE " _ tWhereField _ " = :pKey)")
					// - WAL131
				}
				Quit:$$$ISERR(tSC)
			}
			Else {
				// property is in the source table
				Set tSC = ..%AnalyzeStarProperty(tSourceClass,tSourceProp,.tType,,tSourceClass_"."_tSourceProp)
				If ("datatype" = $$$getClassType($$$NormalizeClassname(tType))) {
					// must be a datatype in this case
					// in this case we need to use dynamic SQL
					// otherwise the External value is baked into the SQL code!
					// note that error in this SQL are not reported
					// most likely because we are stepping on some variable!!!
					Set tSTable = ..%GetSQLTableName(tSourceClass)
					Set tSField = ..%GetSQLColumnName(tSourceClass,tSourceProp)

					// + WAL131 (2)
					Set tWhereField = ..%GetSQLColumnName(tSourceClass,tKeyFieldSourceProp)
					// - WAL131 (2)

					Do tMeth.Implementation.WriteLine(" Set tSC = $$$OK")
					Do tMeth.Implementation.WriteLine(" Try {")
 					Do tMeth.Implementation.WriteLine("  Set tRS = ##class(%ResultSet).%New()")
					Do tMeth.Implementation.WriteLine("  Set tSC = tRS.Prepare(""SELECT TOP (1) %EXTERNAL("_tSField_") Value FROM "_tSTable_" WHERE "_tWhereField_" = ?"")") // + WAl131 (2)
					Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
 					Do tMeth.Implementation.WriteLine("  Set tSC = tRS.Execute(pKey)")
					Do tMeth.Implementation.WriteLine("  If $$$ISERR(tSC) Quit")
 					Do tMeth.Implementation.WriteLine("  If (tRS.Next(.tSC)) {")
 					Do tMeth.Implementation.WriteLine("   Set tValue = tRS.Data(""Value"")")
					Do tMeth.Implementation.WriteLine("  }")
					Do tMeth.Implementation.WriteLine(" }")
					Do tMeth.Implementation.WriteLine(" Catch(ex) {")
					Do tMeth.Implementation.WriteLine("  Set tSC = ex.AsStatus()")
					Do tMeth.Implementation.WriteLine(" }")
					Do tMeth.Implementation.WriteLine(" If $$$ISERR(tSC) {")
					Do tMeth.Implementation.WriteLine("  Set tValue = $System.Status.GetOneStatusText(tSC)")
					Do tMeth.Implementation.WriteLine(" }")
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Field referenced in sourceClass must be a datatype: "_tSourceProp)
				}
				Quit:$$$ISERR(tSC)
			}

			Do tMeth.Implementation.WriteLine(" Quit tValue")

			Do tClassDef.Methods.Insert(tMeth)
			Set tRefField = $O(tRefFields(tRefField))
		}
		Quit:$$$ISERR(tSC)

		#; determine what indices are needed
		#; there should be an index for the key and each name (if any)
		#; if there are rollups, then there is an index for the combination
		#; of each rollup and key and rollup and name.
		#; the key (or first rollup and key) serves as the primary key for the
		#; dimension table; this is used to lookup member ids at cube insert time.
		Set tPrimaryIndex = ""
		If ($D(tRollups)) {
			Set tRollup = $O(tRollups(""))
			While (tRollup'="") {
				Set tIndices(tRollup_","_tKeyField) = $LB(tRollup,tKeyField)
				If (tPrimaryIndex="") {
					Set tPrimaryIndex = tRollup_","_tKeyField
				}
				Set tNameField = $O(tNameFields(""))
				While (tNameField'="") {
					If (tNameField'=tKeyField) {
						Set tIsRef = +$G(pStarInfo(pStar,"prop",tNameField,"isref"))
						Set tIsDesc = ($G(pStarInfo(pStar,"prop",tNameField,"use"))="description")		// DTB152
						If ('tIsRef)&&('tIsDesc) {
							// no index on ref fields
							// DTB152 - do not create an index for descriptions
							Set tIndices(tRollup_"AND"_tNameField) = $LB(tRollup,tNameField)

							// JMD883: also include an index on the name by itself
							Set tIndices(tNameField) = $LB(tNameField)
						}
					}
					Set tNameField = $O(tNameFields(tNameField))
				}
				Set tRollup = $O(tRollups(tRollup))
			}
		}
		Else {
			If (tKeyField = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Internal error: no key field found")
				Quit
			}
			Else {
				Set tIndices(tKeyField) = $LB(tKeyField)
				Set tPrimaryIndex = tKeyField
				Set tNameField = $O(tNameFields(""))
				While (tNameField'="") {
					If (tNameField'=tKeyField) {
						Set tIsDesc = ($G(pStarInfo(pStar,"prop",tNameField,"use"))="description")		// DTB152
						If 'tIsDesc {
							// DTB152 - do not create an index for descriptions
							Set tIndices(tNameField) = $LB(tNameField)
						}
					}
					Set tNameField = $O(tNameFields(tNameField))
				}
			}
		}

		// JMD938: add index for sort by properties (unless already indexed)
		Set tSortBy = $G(pStarInfo(pStar,"sortBy"))
		If (tSortBy'="") {
			If '$D(tIndices(tSortBy)) {
				Set tIndices(tSortBy) = $LB(tSortBy)
			}
		}

		#; return primary key info
		Set pStarInfo(pStar,"primary") = tPrimaryIndex

		#; create indices
		Set tIndexCount = 0
		Set tName = $O(tIndices(""))
		While (tName'="") {
			Set tIndexCount = tIndexCount + 1
			Set tUnique = 0
			If (tName = tPrimaryIndex) {
				Set tIndexName = "Primary"
				Set tUnique = 1
			}
			Else {
				Set tIndexName = "Idx"_tIndexCount
			}
			Set tIndexDef = ##class(%Dictionary.IndexDefinition).%New(tClassDefName_"||"_tIndexName)
			Set tIndexDef.Name = tIndexName
			Set tIndexDef.Properties = $ListToString(tIndices(tName))
			Set tIndexDef.Unique = tUnique
			Set tIndexDef.SequenceNumber = $I(tSeq)
			Do tClassDef.Indices.Insert(tIndexDef)
			Set tName = $O(tIndices(tName))
		}

		#; done
	    Set tSC = tClassDef.%Save()
	    If $$$ISERR(tSC) Quit

		// Write !,tClassDef.Name," saved"

	    #; Now queue the generated class for compilation
	    Do QueueClass^%occCompile(tClassDefName)
	    #; Mark this class for deletion when the cube class is deleted.
	    $$$comClassArraySet(pCubeClass,$$$cCLASSclasses,tClassDefName_".CLS","")
	    $$$defClassKeySet(tClassDefName,$$$cCLASSgeneratedby,pCubeClass_".CLS")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a class and property return its type.<br/>
/// <var>pProp</var> can contain a set of referenced fields using dot syntax.<br/>
/// Return "" if the property does not exist.<br/>
/// <var>pContext</var> is used for error messages.
/// [Previously private]
ClassMethod %GetPropertyType(Output tSC As %Status, Output pParms As %String, pClass As %String, pProp As %String, pContext As %String = "") As %String [ Internal ]
{
	Set tSC = $$$OK
	Set tType = ""
	Kill pParms
	Try {
		Set:pContext="" pContext="Generator"
		Set tTargetClass = pClass
		Set tTargetProp = $P(pProp,".",1)
		Set tRefProps = $P(pProp,".",2,999)
		If (pClass="") {
			Set tSC = $$$ERROR($$$GeneralError,"No class specified: ("_pContext_")")
			Quit
		}

		// special case: test for worksheets and kpis
		Set tExt = $P(pClass,".",$L(pClass,"."))
		If ((tExt="kpi")||(tExt="metric")||(tExt="worksheet")) {
			// !!! return string for now
			Set tType = "%String"
			Quit
		}
		ElseIf '$$$comClassDefined(pClass) {
			Set tSC = $$$ERROR($$$GeneralError,"Class not found: "_pClass_" ("_pContext_")")
			Quit
		}
		If (pProp="") {
			Set tSC = $$$ERROR($$$GeneralError,"No property specified: "_pClass_" ("_pContext_")")
			Quit
		}

		Set tClassType = $$$getClassType(pClass)

		// Use different logic for data connector and persistent sources
		If ((tClassType'="persistent")&&$zobjclassmethod(pClass,"%IsA","%DeepSee.DataConnector")) {
			// get property info from connector
			// no "." allowed in connector property name
			Set tSC = $zobjclassmethod(pClass,"%GetPropertyInfo",.tInfo)
			If $$$ISERR(tSC) Quit

			// look for the property within the list
			Set n = $O(tInfo(""))
			While (n'="") {
				Set tName = $LG(tInfo(n),1)
				If (tName = pProp) {
					Set tType = $LG(tInfo(n),3)
					Quit
				}
				Set n = $O(tInfo(n))
			}
			If (tType = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Property not found in DataConnector: "_pProp_", Class:"_ pClass_" ("_pContext_")")
				Quit
			}
		}
		Else {
			If (pProp="%ID") {
				// special case for id
				Set tType = "%String"
				Quit
			}
			Set tType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,tTargetProp,$$$cPROPtype)
			If (tType = "") {
				Set tSC = $$$ERROR($$$GeneralError,"Property not found: "_tTargetProp_", Class:"_ pClass_" ("_pContext_")")
				Quit
			}

			If (tRefProps '= "") {
				Set tClsType = $$$getClassType($$$NormalizeClassname(tType))
				If (tClsType = "datatype") {
					Set tSC = $$$ERROR($$$GeneralError,"Cannot use a reference with a literal property: "_pClass_":"_tTargetProp_" ("_pContext_")")
					Quit
				}
				Else {
					// recursively find type
					Set tType = ..%GetPropertyType(.tSC, .pParms, tType, tRefProps, pContext)
					Quit
				}
			}

			// get popular parameters
			For p = "MAXLEN","MINVAL","MAXVAL","SCALE" {
				Set v = $$$comMemberArrayGet(tTargetClass,$$$cCLASSproperty,tTargetProp,$$$cPROPparameter,p)
				Set:v'="" pParms(p) = v
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tType = ""
	}
	Quit tType
}

/// Convert a dot syntax reference to an SQL arrow syntax expression.
ClassMethod %GetSQLFieldExpression(Output tSC As %Status, pClass As %String, pPropExpr As %String, pAllowStreams As %Boolean = 0) As %String
{
	Set tSC = $$$OK
	Set tExpr = ""
	Set tType = pClass
	Set tRefType = ""
	For p = 1:1:$L(pPropExpr,".") {
		Set tProp = $P(pPropExpr,".",p)

		Set tField = ..%GetSQLColumnName(tType,tProp)
		If (tField="") {
			// test for transient properties (to give better error message)
			If $$$comMemberKeyGet(tType,$$$cCLASSproperty,tProp,$$$cPROPtransient) {
				Set tSC = $$$ERROR($$$GeneralError,"Transient property cannot be used as a data source unless it is SQL computed: " _ tType _ ":" _ tProp)
				Quit
			}
			Set tSC = $$$ERROR($$$GeneralError,"No SQL field found for property: " _ tType _ ":" _ tProp)
			Quit
		}
		Set tType = $$$comMemberKeyGet(tType,$$$cCLASSproperty,tProp,$$$cPROPtype)
		Set:tType="" tType = "%Library.String"

		Set tExpr = tExpr _ $S(tExpr="":"",tRefType="serial":"_",1:"->") _ tField
		Set tRefType = $$$getClassType($$$NormalizeClassname(tType))

		// do not allow streams as data source properties
		// BDB243: except for iKnow measures
		If (tRefType="stream") && 'pAllowStreams {
			Set tSC = $$$ERROR($$$GeneralError,"Stream property cannot be used as a data source: " _ tType _ ":" _ tProp)
			Quit
		}
	}
	Quit tExpr
}

/// Return a description string for the given class member.
ClassMethod %MakeDescription(pMemberType As %String, pName As %String, pSource As %String = "", pNotes As %String = "") As %String
{
	Set tDesc = pMemberType _ ": " _ pName
	Set:pSource'="" tDesc = tDesc _ "<br/>"_$C(13,10) _ $$$Text("Source: ","%DeepSee") _ pSource
	Set:pNotes'="" tDesc = tDesc _ "<br/>"_$C(13,10) _ pNotes
	Quit tDesc
}

/// Produce a storage definition for the <var>pPropName</var> that can be inserted into the class's storage definition.
/// The array <var>pKnownValues</var> contains the previously compiled storage data, and is used
/// as a working index to avoid collisions in the storage definition. The <var>pNewValues</var> array
/// will contain the storage data for all properties actually encountered while working through
/// this current definition.
ClassMethod %MakePropStorageDef(pPropName As %String = "", ByRef pKnownValues, ByRef pNewValues) As %Dictionary.StorageDataValueDefinition
{
	// Method added by DTB961
	Set tValueDef = $$$NULLOREF
	Try {
		If (pPropName="") Quit
		
		Set tValueDef = ##class(%Dictionary.StorageDataValueDefinition).%New()
		Do tValueDef.ValueSet(pPropName)
		
		// Find the appropriate name for each fact number
		Set tNextAvailName = 0
		If $D(pKnownValues("value",pPropName),tKnownName) {
			Do tValueDef.NameSet(tKnownName)
			
			Set pNewValues("value",pPropName) = tKnownName
			Set pNewValues("name",tKnownName) = pPropName
		}
		Else {
			// Find the next available slot
			While $D(pKnownValues("name",$I(tNextName))) {}
			
			// Set the storage definition and the lookup indices
			Do tValueDef.NameSet(tNextName)
			Set pKnownValues("value",pPropName) = tNextName
			Set pKnownValues("name",tNextName) = pPropName
			
			Set pNewValues("value",pPropName) = tNextName
			Set pNewValues("name",tNextName) = pPropName
		}
	}
	Catch ex {
		Set tValueDef = $$$NULLOREF 
	}
	
	Quit tValueDef
}

/// For the given source class and reference to property within the source
/// class, find the type of the property; the aliased name for the property; the root property needed to
/// fetch complete details on the property.
ClassMethod %AnalyzeStarProperty(pSourceClass As %String, pSourceProperty As %String, Output pType As %String, Output pParms, pContext As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set pType = ""
		Set pName = ""
		Kill pParms

		If (pSourceProperty = "") {
			Quit
		}

		// Analyze the type of the source property.
		// If source property is a reference, pull it apart and
		// analyze each piece.
		Set tClass = pSourceClass
		Set tName = ""
		If (pSourceProperty '= "") {
			For p = 1:1:$L(pSourceProperty,".") {
				Set tProp = $P(pSourceProperty,".",p)
				Set tType = ..%GetPropertyType(.tSC, .tParms, tClass,tProp,pContext _ " AnalyzeStarProperty")
				Quit:$$$ISERR(tSC)
				If (tType = "") Quit
				If ("datatype" = $$$getClassType($$$NormalizeClassname(tType))) {
					If (p < $L(pSourceProperty,".")) {
						// we cannot have references after a datatype!
						Set tSC = $$$ERROR($$$GeneralError,"Invalid property reference: " _ pSourceProperty)
					}
					Merge pParms = tParms
					Quit
				}
				Set tClass = tType
			}
			Quit:$$$ISERR(tSC)
		}

		Set tName = "" 
		For j=$L(pSourceProperty,"."):-1:1 {
			Set tName = tName _ $S(tName="":"",1:"Via")_ $P(pSourceProperty,".",j)
		}

		Set pType = tType
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a class name of the form %Library.xxx to %xxx.
ClassMethod %DenormalizeType(pType As %String) As %String [ CodeMode = expression ]
{
$S($E(pType,1,9)="%Library.":"%"_$P(pType,".",2,999),1:pType)
}

/// Test to determine if the current type is a string or is a custom datatype
/// with %String as a superclass
ClassMethod %IsString(pType As %String) As %Boolean
{
	// Method added by DTB491
	Set tIsString = 0
	Try {
		If (pType="%String")||(pType="%Library.String") {
			Set tIsString = 1
			Quit
		}
		
		s tTypeDef = ##class(%Dictionary.CompiledClass).%OpenId(pType)
		If (tTypeDef.Super["%String")||(tTypeDef.Super["%Library.String") {
			Set tIsString = 1
			Quit
		}
		Else {
			// Parse the list of superclasses and see if there any %String subclasses
			Set tSuperList = tTypeDef.Super
			For c=1:1:$L(tSuperList,",") {
				Set tSuperType = $P(tSuperList,",",c)
				If ($E(tSuperType)'="%") {
					Set tIsString = ..%IsString(tSuperType)
				}
				
				If (tIsString) Quit
			}
		}
	}
	Catch ex {
		Set tIsString = ex.AsStatus()
	}
	Quit tIsString
}

/// Given a classname, method name, base expression, and optional list
/// of options, return a value that can be used as an SQL computed field
/// expression. Match the options with arguments in the functions formal spec.
ClassMethod %MakeSQLCompute(Output pCode, pClass As %String, pMethod As %String, pBase As %String, ByRef pOptions) As %Status
{
	Set pCode = ""
	Set tSC = $$$OK
	Try {
		// test for expression methods
		If ("expression" = $$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHcodemode)) {
			Set tExpr = ""
			For n = 1:1:$$$defMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHimplementation) {
				Set tExpr = tExpr _ $$$defMemberArrayGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHimplementation,n)
			}
			// replace formal arguments withing expression
			// using the method du fromage
			Set tSpec = $$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHformalspecparsed)
			For n=1:1:$LL(tSpec) {
				Set tArgName = $LG($LG(tSpec,n),1)
				Set tArgValue = ""
				If (n = 1) {
					Set tExpr = $Replace(tExpr,tArgName,"{"_pBase_"}")
				}
				Else {
					If $D(pOptions($$$UPPER(tArgName))) {
						Set tArgValue = pOptions($$$UPPER(tArgName))
						Set tExpr = $Replace(tExpr,tArgName,$$$quote(tArgValue))
					}
				}
			}

			Set pCode = tExpr
		}
		Else {
			// If options are available, match them with formal spec
			Set tArgList = ""
			If ($D(pOptions)) {
				Set tArgCount = 0
				// get formal spec for function: skip first argument
				Set tSpec = $$$comMemberKeyGet(pClass,$$$cCLASSmethod,pMethod,$$$cMETHformalspecparsed)
				For n=2:1:$LL(tSpec) {
					Set tArgName = $LG($LG(tSpec,n),1)
					Set tArgValue = ""
					If $D(pOptions($$$UPPER(tArgName))) {
						Set tArgCount = tArgCount + 1
						Set tArgValue = pOptions($$$UPPER(tArgName))
					}
					Set tArgList = tArgList _ "," _ $$$quote(tArgValue)
				}
				If (tArgCount = 0) {
					Set tArgList = ""
				}
			}

			Set pCode = "##class("_pClass_")."_pMethod _ "({" _ pBase _ "}"
			Set pCode = pCode _ tArgList _")"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Take a time function specification ("Function(p=1)") and find
/// from it the function name and list of options with their values.
ClassMethod %ParseTimeFunction(pSpec As %String, Output pFuncName As %String, Output pOptions As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pOptions
		Set pFuncName = ""
		Set tState = 0
		Set tDone = 0
		Set p = 1
		Set tToken = ""

		While (p <= $L(pSpec)) {
			Set ch = $E(pSpec,p)

			If (tState = 0) { // func name
				If (ch = "(") {
					Set pFuncName = $ZSTRIP(tToken,"<>W")
					If (pFuncName="") {
						Set tSC = $$$ERROR($$$GeneralError,"Missing function name in function specification: " _ pSpec)
						Quit
					}
					Set tToken = ""
					Set tState = 1
				}
				Else {
					Set tToken = tToken_ch
				}
			}
			ElseIf (tState = 1) { // (
				If (ch = ")") {
					Set tSC = $$$ERROR($$$GeneralError,"Missing option or option value in function specification: " _ pSpec)
					Quit
				}
				ElseIf (ch = "=") {
					Set tArg = $ZSTRIP(tToken,"<>W")
					If (tArg="") {
						Set tSC = $$$ERROR($$$GeneralError,"Missing option name in function specification: " _ pSpec)
						Quit
					}
					Set tToken = ""
					Set tState = 2
				}
				Else {
					Set tToken = tToken_ch
				}
			}
			ElseIf (tState = 2) { // (aaa=
				If ((ch = ")")||(ch = ",")) {
					Set tValue = $ZSTRIP(tToken,"<>W")
					If (tValue="") {
						Set tSC = $$$ERROR($$$GeneralError,"Missing option value in function specification: " _ pSpec)
						Quit
					}
					ElseIf ('$IsValidNum(tValue)) {
						Set tSC = $$$ERROR($$$GeneralError,"Invalid option value in function specification: " _ tValue)
						Quit
					}
					Set pOptions($$$UPPER(tArg)) = tValue
					Set tToken = ""
					Set tState = $CASE(ch,",":1,:5)
				}
				ElseIf (ch = """") {
					If (tToken'="") {
						// error
						Set tSC = $$$ERROR($$$GeneralError,"Unexpected "" in function specification: " _ pSpec)
						Quit
					}
					Set tState = 3
				}
				Else {
					Set tToken = tToken_ch
				}
			}
			ElseIf (tState = 3) { // ( (aaa="
				If (ch = """") {
					// test for ""
					If ($E(pSpec,p+1)="""") {
						Set tToken = tToken_ch
						Set p = p + 1
					}
					Else {
						Set tValue = $ZSTRIP(tToken,"<>W")
						Set pOptions($$$UPPER(tArg)) = tValue
						Set tToken = ""
						Set tState = 4
					}
				}
				Else {
					Set tToken = tToken_ch
				}
			}
			ElseIf (tState = 4) { // ( (aaa="" | aaa=22
				If (ch = ")") {
					Set tState = 5
				}
				ElseIf (ch = ",") {
					Set tState = 1
				}
				Else {
					Set tSC = $$$ERROR($$$GeneralError,"Unexpected character in function specification: " _ ch)
					Quit
				}
			}
			ElseIf (tState = 5) {
				Set tSC = $$$ERROR($$$GeneralError,"Unexpected characters after ')' in function specification: " _ pSpec)
				Quit
			}
			Set p = p + 1
		}

		If $$$ISERR(tSC) Quit


		If (tState = 0) {
			Set pFuncName = $ZSTRIP(tToken,"<>W")
		}
		ElseIf (tState '= 5) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing ) in function specification: " _ pSpec)
			Quit
		}

		If '$ZName(pFuncName) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid function name in function specification: " _ pFuncName)
			Quit
		}
		Set o = $O(pOptions(""))
		While (o'="") {
			If '$ZName(o) {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid option name in function specification: " _ o)
				Quit
			}
			Set o = $O(pOptions(o))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Take a ObjectScript expression and find all the occurences of
/// <pVarName>.Property, replace them and return a list of property references.
/// An expression can also contain a reference to a class method
/// of the cube class using the syntax %cube.Method. This is replaced later.
ClassMethod %ParseExpression(pCode As %String, Output pResult As %String, Output pPropList As %String, pVarName As %String = "%source") As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pPropList
		Set pResult = ""
		Set tLast = 1
		Set tPattern = pVarName_"."
		Set tSourceLen = $L(tPattern)
		Set p = $Find(pCode,tPattern)
		While (p > 0) {
			Set pResult = pResult _ $E(pCode,tLast,p-tSourceLen-1)
			Set tToken = ""
			// find end of property reference
			Set c = p
			While (1) {
				Set ch = $E(pCode,c)
				If ((ch'=".")&&(ch'="%")&&((ch="")||('$ZName("A"_ch)))) {
					Quit
				}
				If (pVarName="%expression")&&(ch=".") {
					// DP-403240 - The token for an expression identifier is considered complete just before the 
					// first '.' character to provide support for object references when expressions are 
					// used in other cube model elements.
					Quit
				}

				Set tToken = tToken_ch 
				Set c = c + 1
			} 
			If (tToken '= "") {
				Set pPropList(tToken) = ""
				Set pResult = pResult _ pVarName _ "("""_tToken_""")"
			}
			Set tLast = p + $L(tToken)
			Set p = $Find(pCode,tPattern,p)
		}
		Set pResult = pResult _ $E(pCode,tLast,*)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Returns the SQL table name for class <var>pClass</var>.
ClassMethod %GetSQLTableName(pClass As %String) As %String [ Final ]
{
	Set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(pClass,0)		// DTB786 - Call without verification since the oddCOM global is being built!
	// do we need delimited ids?
	// we have to check schema and table name separately
	Set tSchema = $P(tTable,".",1)
	Set tTable = $P(tTable,".",2)
	If ('$System.SQL.IsValidRegularIdentifier(tSchema)) {
		Set tSchema = $$$quote(tSchema)
	}
	If ('$System.SQL.IsValidRegularIdentifier(tTable)) {
		Set tTable = $$$quote(tTable)
	}
	Quit tSchema _ "." _ tTable
}

/// Returns the SQL name of property <var>pProp</var> for class <var>pClass</var>.
ClassMethod %GetSQLColumnName(pClass As %String, pProp As %String) As %String [ Final ]
{
	// n.b., names are already quoted at this point if needed.
	Set tName = ##class(%DeepSee.Utils).%GetSQLColumnName(pClass,pProp)
	Quit tName
}

/// Compare the meta data for the given cube with a prior definition.<br/>
/// Results are returned in <var>pResults</var>.
ClassMethod %CompareMetaData(pCube As %String, Output pResults) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pResults
		Set tCube = $$$UPPER(pCube)

		// bucket size affect cache
		Set pResults("bucketSize") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"bucketSize"))=$G($$$DeepSeeMetaGLVN("prior",tCube,"bucketSize"))

		// other cube meta data
		Set pResults("cube") = 1
		If ($G($$$DeepSeeMetaGLVN("cubes",tCube,"defdim"))'=$G($$$DeepSeeMetaGLVN("prior",tCube,"defdim"))) {
			Set pResults("cube") = 0
		}
		If ($G($$$DeepSeeMetaGLVN("cubes",tCube,"precompute"))'=$G($$$DeepSeeMetaGLVN("prior",tCube,"precompute"))) {
			Set pResults("cube") = 0
		}
		If ($G($$$DeepSeeMetaGLVN("cubes",tCube,"caption"))'=$G($$$DeepSeeMetaGLVN("prior",tCube,"caption"))) {
			Set pResults("cube") = 0
		}
		If ($G($$$DeepSeeMetaGLVN("cubes",tCube,"sourceClass"))'=$G($$$DeepSeeMetaGLVN("prior",tCube,"sourceClass"))) {
			Set pResults("cube") = 0
		}
		If ($G($$$DeepSeeMetaGLVN("cubes",tCube,"sourceType"))'=$G($$$DeepSeeMetaGLVN("prior",tCube,"sourceType"))) {
			Set pResults("cube") = 0
		}

		// dimensions
		Set tDimEqual = 1
		Set tCurrDNO = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",""))
		Set tPriorDNO = $O($$$DeepSeeMetaGLVN("prior",tCube,"mbr#",""))
		While ((tDimEqual = 1) && ((tCurrDNO'="")||(tPriorDNO'=""))) {
			Set tCurrHNO = $S(tCurrDNO="":"",1:$O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tCurrDNO,"")))
			Set tPriorHNO = $S(tPriorDNO="":"",1:$O($$$DeepSeeMetaGLVN("prior",tCube,"mbr#",tPriorDNO,"")))
			While ((tDimEqual = 1) && ((tCurrHNO'="")||(tPriorHNO'=""))) {
				Set tCurrLNO = $S(tCurrHNO="":"",1:$O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tCurrDNO,tCurrHNO,""),1,cnode))
				Set tPriorLNO = $S(tPriorHNO="":"",1:$O($$$DeepSeeMetaGLVN("prior",tCube,"mbr#",tPriorDNO,tPriorHNO,""),1,pnode))
				While ((tDimEqual = 1) && ((tCurrLNO'="")||(tPriorLNO'=""))) {
					If ($G(cnode) '= $G(pnode)) {
						Set tDimEqual = 0
					}
					Set:((tCurrDNO'="")&&(tCurrHNO'="")) tCurrLNO = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tCurrDNO,tCurrHNO,tCurrLNO),1,cnode)
					Set:((tPriorDNO'="")&&(tPriorHNO'="")) tPriorLNO = $O($$$DeepSeeMetaGLVN("prior",tCube,"mbr#",tPriorDNO,tPriorHNO,tPriorLNO),1,pnode)
				}
				Set:(tCurrDNO'="") tCurrHNO = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tCurrDNO,tCurrHNO))
				Set:(tPriorDNO'="") tPriorHNO = $O($$$DeepSeeMetaGLVN("prior",tCube,"mbr#",tPriorDNO,tPriorHNO))
			}
			Set tCurrDNO = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tCurrDNO))
			Set tPriorDNO = $O($$$DeepSeeMetaGLVN("prior",tCube,"mbr#",tPriorDNO))
		}

		// facts
		Set tFactEqual = 1
		Set tFactReason = ""
		Set tCurrFact = $O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",""),1,cfno)
		Set tPriorFact = $O($$$DeepSeeMetaGLVN("prior",tCube,"fact","prop",""),1,pfno)
		While (tFactEqual && ((tCurrFact'="")||(tPriorFact'=""))) {
			Set tFactReason = tCurrFact_"/"_tPriorFact
			If ((tCurrFact'=tPriorFact)||($G(cfno)'=$G(pfno))) {
				Set tFactEqual = 0
			}
			Else {
				// test next level subscripts	
				Set kc = $S(tCurrFact="":"",1:$O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tCurrFact,""),1,cval))
				Set kp = $S(tPriorFact="":"",1:$O($$$DeepSeeMetaGLVN("prior",tCube,"fact","prop",tPriorFact,""),1,pval))
				While (tFactEqual && ((kc'="")||(kp'=""))) {
					If ((kc'=kp)||($G(cval)'=$G(pval))) {
						Set tFactEqual = 0
					}
					Else {
						// parameters
						Set kc2 = $S(kc="":"",1:$O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tCurrFact,kc,""),1,cval2))
						Set kp2 = $S(kp="":"",1:$O($$$DeepSeeMetaGLVN("prior",tCube,"fact","prop",tPriorFact,kp,""),1,pval2))
						While (tFactEqual && ((kc2'="")||(kp2'=""))) {
							If ((kc2'=kp2)||($G(cval2)'=$G(pval2))) {
								Set tFactEqual = 0
							}
							Set:(tCurrFact'="")&&(kc'="") kc2 = $O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tCurrFact,kc,kc2),1,cval2)
							Set:(tPriorFact'="")&&(kp'="") kp2 = $O($$$DeepSeeMetaGLVN("prior",tCube,"fact","prop",tPriorFact,kp,kp2),1,pval2)
						}
					}
					Set:(tCurrFact'="") kc = $O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tCurrFact,kc),1,cval)
					Set:(tPriorFact'="") kp = $O($$$DeepSeeMetaGLVN("prior",tCube,"fact","prop",tPriorFact,kp),1,pval)
				}
			}
			// next
			Set tCurrFact = $O($$$DeepSeeMetaGLVN("cubes",tCube,"fact","prop",tCurrFact),1,cfno)
			Set tPriorFact = $O($$$DeepSeeMetaGLVN("prior",tCube,"fact","prop",tPriorFact),1,pfno)
		}
		Set:tFactEqual tFactReason = ""

		Set pResults("facts") = tFactEqual 
		Set pResults("dims") = tDimEqual 
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Build the meta data for the given subject area model.
/// pCaptions(dname,hname,lname) = displayName<br/>
ClassMethod %ProcessSubjectArea(pCubeClass As %String, pSubject As %DeepSee.Model.SubjectArea.subjectArea, ByRef pCaptions As %String, pJoinList As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tBaseCube = $$$UPPER(pSubject.baseCube)
		Set tCube = $$$UPPER(pSubject.name) // cube for subject area

		// first merge over all meta data for base, then we will prune
		Kill $$$DeepSeeMetaGLVN("cubes",tCube)
		Merge $$$DeepSeeMetaGLVN("cubes",tCube) = $$$DeepSeeMetaGLVN("cubes",tBaseCube)

		// fix class name
		Set $$$DeepSeeMetaGLVN("cubes",tCube) = pCubeClass

		// we don't need "star" info
		Kill $$$DeepSeeMetaGLVN("cubes",tCube,"star")

		// add baseCube to meta data
		Set $$$DeepSeeMetaGLVN("cubes",tCube,"baseCube") = tBaseCube

		// if this is a compound cube; merge in elements from other base cubes
		If (pJoinList'="") {
			// merge cube elements
			For p = 2:1:$L(pJoinList,",") {
				Set tJoinCube = $$$UPPER($P(pJoinList,",",p))

				// dimensions
				Set tDim = $O($$$DeepSeeMetaGLVN("cubes",tJoinCube,"mbrs",""))
				While (tDim'="") {
					Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tJoinCube,"mbrs",tDim,""))
					While (tHier'="") {
						If $D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier)) {
							// make sure this dimension is "shared"
							If ('$D($$$DeepSeeMetaGLVN("cubes",tJoinCube,"sharesFrom",tBaseCube,tDim))&&
								'$D($$$DeepSeeMetaGLVN("cubes",tBaseCube,"sharesFrom",tJoinCube,tDim))) {
								If ((tDim'="%SEARCH")&&(tDim'="MEASURES")) {
									Set tSC = $$$ERROR($$$GeneralError,"Dimensions with same name must be shared: " _ tDim)
									Quit
								}
							}
						    If $$$ISERR(tSC) Quit
						}
						Else {
							// additional dimension from 2nd cube
							// add to compound cube
							// add a fake dim,hier number
							Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim))
							Set tHierInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier))
							If (tDimInfo="") {
								Set tNewDimNo = 1+$O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",""),-1)
								Set tNewHierNo = 1
							}
							Else {
								Set tNewDimNo = +$LG(tDimInfo,1)
								If (tHierInfo="") {
									Set tNewHierNo = 1+$O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tNewDimNo,""),-1)
								}
								Else {
									Set tNewHierNo = +$LG(tHierInfo,2)
								}
							}
							Set $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDim,tHier) = $LB(tNewDimNo,tNewHierNo,0)

							// get original element info and modify
							Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tJoinCube,"mbrs",tDim,tHier))
							Set tOrigInfo = $G($$$DeepSeeMetaGLVN("cubes",tJoinCube,"mbr#",+$LG(tInfo,1),+$LG(tInfo,2),+$LG(tInfo,3)))
						
							// remove fact name
							Set $List(tOrigInfo,5) = ""
							
							If $LG(tOrigInfo,1) = "m" {
								// PFS019 - Add source cube info to measure node's list item #14
								Set $List(tOrigInfo,14) = tJoinCube
							}
							Set $$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",tNewDimNo,tNewHierNo,0) = tOrigInfo
						}
						Set tHier = $O($$$DeepSeeMetaGLVN("cubes",tJoinCube,"mbrs",tDim,tHier))
					}
				    If $$$ISERR(tSC) Quit
					Set tDim = $O($$$DeepSeeMetaGLVN("cubes",tJoinCube,"mbrs",tDim))
				}
			}
		    If $$$ISERR(tSC) Quit

			// process connectsBy
			If (pSubject.connectsBy'="") {
				For n = 1:1:$L(pSubject.connectsBy,"],[") {
					Set tSpec = $P(pSubject.connectsBy,"],[",n)
					If (tSpec'="") {
						Set:$E(tSpec)'="[" tSpec="["_tSpec
						Set:$E(tSpec,*)'="]" tSpec=tSpec_"]"
						Set $$$DeepSeeMetaGLVN("cubes",tCube,"connectsBy",$$$UPPER(tSpec)) = ""
					}
				}
			}

		} // joinList
	    If $$$ISERR(tSC) Quit

		// cube overrides

		// DTB082
		Set $$$DeepSeeMetaGLVN("cubes",tCube,"disableListingGroups") = pSubject.disableListingGroups

		#; listings
		For n=1:1:pSubject.listings.Count() {
			Set tListing = pSubject.listings.GetAt(n)
			If ('tListing.disabled) {
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"fieldList") = tListing.fieldList
				Set:tListing.formatList'="" $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"formatList") = tListing.formatList
				If (tListing.hidden) {
					// hidden listing does not exist in subjectArea
					Kill $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name)
				}
				Else {
					Set:tListing.orderBy'="" $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"orderBy") = tListing.orderBy
					Set:tListing.sql'="" $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"sql") = tListing.sql
					Set:tListing.sourceClass'="" $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"sourceClass") = tListing.sourceClass
					Set:(tListing.listingType'="")&&(tListing.listingType'="table") $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"listingType") = tListing.listingType
					Set:tListing.resource'="" $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"resource") = tListing.resource
					Set:tListing.selectMode'="" $$$DeepSeeMetaGLVN("cubes",tCube,"listing",tListing.name,"selectMode") = tListing.selectMode		// DP-414835
				}
			}
		}

		// override of default listing
		If (pSubject.defaultListing'="") {
			If $D($$$DeepSeeMetaGLVN("cubes",tCube,"listing",pSubject.defaultListing)) {
				Set tDefaultListing = pSubject.defaultListing
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListing") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"fieldList"))
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListingOrder") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"orderBy"))
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListingSQL") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"sql"))
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListingSourceClass") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"sourceClass"))
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListingFormat") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"formatList"))
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListingResource") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"resource"))
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"defaultListingSelectMode") = $G($$$DeepSeeMetaGLVN("cubes",tCube,"listing",tDefaultListing,"selectMode"))		// DP-416501
			}
		}

		// filtering (what if cube defines a filter!)
		Set:pSubject.filterSpec'="" $$$DeepSeeMetaGLVN("cubes",tCube,"filterSpec") = pSubject.filterSpec

		Set:pSubject.resource'="" $$$DeepSeeMetaGLVN("cubes",tCube,"resource") = pSubject.resource

		// dimension overrides
		For d=1:1:pSubject.dimensions.Count() {
			Set tDim = pSubject.dimensions.GetAt(d)
			If (tDim.disabled) {
				// disabled means: ignore this definition
				Continue
			}
			Set tDimBase = $$$UPPER(tDim.name)
			If ('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase))) {
				Write !,$$$Text("Dimension not found in base cube, skipped","%DeepSee"),": ",tDim.name
				Continue
			}
			If (tDim.hidden) {
				// mark dimension as hidden
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase))
				Set dno = $LG(tInfo,1)
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",dno,0,0),17) = 1
			}

			// all level
			If ((tDim.allCaption = "")&&(tDim.allDisplayName '= "")) {
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase))
				Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),0,0))
				Set tOldAllCaption = $LG(tInfoD,4)
				Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tOldAllCaption)) = $LB(tOldAllCaption,tDim.allDisplayName)
			}
			ElseIf (tDim.allCaption '= "") {
				Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tDim.allCaption)) = $LB(tDim.allCaption,tDim.allDisplayName)

				// change ALL caption
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase))
				Set tInfoD = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),0,0))
				Set tOldAllCaption = $$$UPPER($LG(tInfoD,4))
				// replace in dimension node
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),0,0),4) = tDim.allCaption

				// replace in hierarchy nodes: all node should be level 1, if present
				Set hno = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),""))
				While (hno '= "") {
					Set tInfoH = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),hno,1))
					If ($LG(tInfoH,1)="all") {
						Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),hno,1),4) = tDim.allCaption
					}
					Set hno = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),hno))
				}

				// now fix mbr nodes
				Set hk = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,""))
				While (hk'="") {
					If (hk = tOldAllCaption) {
						Set $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,$$$UPPER(tDim.allCaption)) = $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk)
						Kill $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk)
					}
					// look one level down
					Set lk = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk,""))
					While (lk'="") {
						If (lk = tOldAllCaption) {
							Set $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk,$$$UPPER(tDim.allCaption)) = $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk,lk)
							Kill $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk,lk)
						}
						Set lk = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk,lk))
					}
					Set hk = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,hk))
				}
			}
			
			// name changes
			If (tDim.displayName '= "") {
				Set pCaptions($$$UPPER(tDim.name)) = $LB(tDim.name,tDim.displayName)
			}

			// other attributes
			For h=1:1:tDim.hierarchies.Count() {
				Set tHier = tDim.hierarchies.GetAt(h)
				If (tHier.disabled) {
					Continue
				}
				If (tHier.displayName '= "") {
					Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tHier.name)) = $LB(tHier.name,tHier.displayName)
				}

				// JMD1441
				// hide all levels of hidden hierarchy
				// (including the 0 level)
				If (tHier.hidden) {
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,$$$UPPER(tHier.name)))
					Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),$LG(tInfo,2),""))
					While (tLevelNo'="") {
						Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),$LG(tInfo,2),tLevelNo),17) = 1
						Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),$LG(tInfo,2),tLevelNo))
					}
				}

				For l=1:1:tHier.levels.Count() {
					Set tLevel = tHier.levels.GetAt(l)
					If (tLevel.disabled) {
						Continue
					}

					If (tLevel.displayName '= "") {
						Set pCaptions($$$UPPER(tDim.name),$$$UPPER(tHier.name),$$$UPPER(tLevel.name)) = $LB(tLevel.name,tLevel.displayName)
					}
					// find actual member #s
					Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase,$$$UPPER(tHier.name),$$$UPPER(tLevel.name)))
					If (tLevel.sort'="") {
						Set tLS = $Case(tLevel.sort,"asc":"asc","desc":"desc","desc numeric":"desc#","asc numeric":"asc#",:"")
						Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),$LG(tInfo,2),$LG(tInfo,3)),10) = tLS
					}
					If (tLevel.hidden) {
						// mark level as hidden
						Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),$LG(tInfo,2),$LG(tInfo,3)),17) = 1
					}
				}
			}
			
			// JMD1441 if all hierarchies are hidden, hide the dimension
			Set tAllHidden = 1
			Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tDimBase))

			Set tHierNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),0))
			While (tHierNo'="") {
				Set tHierHidden = +$LG($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),tHierNo,0),17)
				If ('tHierHidden) {
					// check if *all* the levels are hidden
					Set tLevelsH = 1
					Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),tHierNo,0))		// DP-429138 - $Order from level 0
					While (tLevelNo'="") {
						Set tLevelHidden = +$LG($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),tHierNo,tLevelNo),17)
						If ('tLevelHidden) {
							Set tLevelsH = 0
							Quit
						}
						Set tLevelNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),tHierNo,tLevelNo))
					}
					If (tLevelsH) {
						Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),tHierNo,0),17) = 1
						Set tHierHidden = 1
					}
				}

				If ('tHierHidden) {
					Set tAllHidden = 0
					Quit
				}
				Set tHierNo = $O($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),tHierNo))
			}

			// mark dimension hidden
			If (tAllHidden) {
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",$LG(tInfo,1),0,0),17) = 1
			}
		}

		// measure overrides
		For m=1:1:pSubject.measures.Count() {
			Set tMsr = pSubject.measures.GetAt(m)
			If (tMsr.disabled) {
				Continue
			}
			Set tMsrBase = $$$UPPER(tMsr.name)
			If ('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsrBase))) {
				Write !,$$$Text("Measure not found in base cube, skipped","%DeepSee"),": ",tMsr.name
				Continue
			}
			If (tMsr.hidden) {
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsrBase))
				Set mno = $LG(tInfo,2)

				// mark node
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",0,mno,0),1) = "-m"

				// remove reference to measure
				Kill $$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsrBase)
				Continue
			}
			// name changes
			If (tMsr.displayName '= "") {
				Set pCaptions("MEASURES",$$$UPPER(tMsr.name)) = $LB(tMsr.name,tMsr.displayName)
			}
			// JMD1189 formatString
			If (tMsr.formatString'="") {
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs","MEASURES",tMsrBase))
				Set mno = $LG(tInfo,2)
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",0,mno,0),12) = tMsr.formatString
			}
		}

		// relationship overrides
		For r=1:1:pSubject.relationships.Count() {
			Set tRel = pSubject.relationships.GetAt(r)
			If (tRel.disabled) {
				Continue
			}
			Set tRelBase = $$$UPPER(tRel.name)
			If ('$D($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tRelBase))) {
				Write !,$$$Text("Relationship not found in base cube, skipped","%DeepSee"),": ",tRel.name
				Continue
			}
			If (tRel.hidden) {
				// mark (relation) dimension as hidden
				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCube,"mbrs",tRelBase))
				Set dno = $LG(tInfo,1)
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"mbr#",dno,0,0),17) = 1
			}
			// name changes
			If (tRel.displayName '= "") {
				Set pCaptions(tRelBase) = $LB(tRel.name,tRel.displayName)
			}
		}
		// calculated members
		For m=1:1:pSubject.calculatedMembers.Count() {
			Set tMbr = pSubject.calculatedMembers.GetAt(m)
			If (tMbr.disabled) {
				Continue
			}
			
			// JMD911: If we are not overriding an existing calc mbr, enter info for it!
			If ('$D($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",$$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)))) {
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",$$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)) = $LB(tMbr.dimension,tMbr.name,tMbr.valueExpression,tMbr.formatString,tMbr.hidden,tMbr.listingFilter)
			}
			Else {
				If (tMbr.valueExpression'="") {
					Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",$$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)),3) = tMbr.valueExpression
				}
				If (tMbr.formatString'="") {
					Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",$$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)),4) = tMbr.formatString
				}
				// hide/show from Analyzer
				Set $List($$$DeepSeeMetaGLVN("cubes",tCube,"calcMbrs",$$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)),5) = tMbr.hidden

			}
			If (tMbr.displayName'="") {
				Set pCaptions($$$UPPER(tMbr.dimension)) = $LB(tMbr.dimension,tMbr.dimension)
				Set pCaptions($$$UPPER(tMbr.dimension),$$$UPPER(tMbr.name)) = $LB(tMbr.name,tMbr.displayName)
			}
		}

		// named sets
		For m=1:1:pSubject.namedSets.Count() {
			Set tMbr = pSubject.namedSets.GetAt(m)
			If (tMbr.disabled) {
				Continue
			}
			If (tMbr.hidden) {
				Kill $$$DeepSeeMetaGLVN("cubes",tCube,"namedSets",$$$UPPER(tMbr.name))
			}
			Else {
				Set $$$DeepSeeMetaGLVN("cubes",tCube,"namedSets",$$$UPPER(tMbr.name)) = $LB(tMbr.name,tMbr.setExpression)

				// use special %%NAMEDSETS dimension name
				Set pCaptions("%%NAMEDSETS",$$$UPPER(tMbr.name)) = $LB(tMbr.name,tMbr.displayName)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Create a unique cursor name to avoid SQL problems!
ClassMethod %CreateCursorName(pPrefix As %String, pClassName As %String) As %String [ Internal ]
{
	Set pClassName = $TR(pClassName,".","z")
	Set tPostFix = $S($L(pClassName)>20:$ZCRC(pClassName,7),1:pClassName)
	Quit pPrefix_tPostFix
}

}
