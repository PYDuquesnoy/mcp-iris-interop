/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// Subclasses of this class are used to define
/// "cubes" that can be queried by the DeepSee engine.<br/>
/// The Cube XDATA block defines the contents of a DeepSee cube
/// (dimensions and measures) as an XML document.
/// When a subclass of this class is compiled, it generates
/// the indexed fact table that holds the data for this cube.<br/>
/// This class also provides the APIs needs to explore
/// a cube's metadata that are used by the DeepSee utilities.
Class %DeepSee.CubeDefinition Extends %RegisteredObject [ Abstract, CompileAfter = (%DeepSee.Model.cube, %DeepSee.Generator), System = 4 ]
{

/// This parameter is used to transform original cube definition.
/// If it is defined in subclass then the cube definition is piped
/// through XSLT transformation. XSL is taken from XData block named
/// in this parameter.
Parameter TRANSFORMXSL As STRING;

/// This parameter is used to transform original cube definition.
/// If it is defined in a subclass then the cube definition is piped
/// through the transformation defined in the class named
/// by this parameter.
Parameter TRANSFORMERCLASS As STRING;

/// This parameter controls whether the compile of this class will utilize the cube versioning mechanism. If
/// set to 1, the current class definition will act as a generator for a distinct version of the cube. <br>
/// The <var>version</var> attribute of the &lt;cube&gt tag must be set if this is set to 1.
Parameter USECUBEVERSIONS = 0;

/// This projection is used to keep track of when Cubes are
/// compiled or deleted.
Projection CubeProjection As %DeepSee.CubeProjection [ Internal ];

/// This XData section provides the definition of the cube.
XData Cube [ XMLNamespace = "http://www.intersystems.com/deepsee" ]
{
}

/// Return an instance of the <class>%DeepSee.Model.cube</class>
/// meta-data object that describes this cube.
ClassMethod %GetModel() As %DeepSee.Model.cube [ CodeMode = objectgenerator, Final, GenerateAfter = (%OnProcessFact, %OnApplyOverrides), Internal ]
{
	Set tSC = $$$OK
	Try {
		// See if the old cube name and timestamp are stashed
		Set tOldCubeName = $G(^||%Cls(%compiledclass.Name,"cube"))
		Set tOldDSTIME = $G(^||%Cls(%compiledclass.Name,"dstime"))
		Merge tStorage = ^||%Cls(%compiledclass.Name,"storage")		// DTB961 - Remember previous storage

		Kill ^||%Cls(%compiledclass.Name)
		
		// DTB949 - The previous cube name (if it exists) is kept in case the compile fails 
		// and information needs to be recorded
		Set:(tOldCubeName'="") ^||%Cls(%compiledclass.Name,"oldCubeName") = tOldCubeName
		
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

	// JMD1348 prevent incremental compile
#ifdef cCLASSdisableincremental
	$$$comClassKeySet(%class.Name,$$$cCLASSdisableincremental,1)
#endif
		Set tDisplay=$$$qualifierGetValue(%qstruct,"displaylog")
		
		#; figure out if this page should provide automatic localization
		#; For library (system) classes, localization occurs for %ZEN domain
		#; For non-library classes, check for non-%DeepSee domain
		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		#; find XDATA block named Cube
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||Cube")

		Do %code.WriteLine(" Set tCube1 = """"")

		If (tIndex '= "") {
			#; get XDATA as stream
			Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()

			#; Transform if required
			set tTransformer = %compiledclass.Parameters.FindObjectId(%class.Name_"||TRANSFORMERCLASS")
			Set tClassName = %compiledclass.Parameters.GetAt(tTransformer).Default
			if (tClassName'="") {
				if ('##class(%Dictionary.CompiledClass).%ExistsId(tClassName)) {
					Set tSC = $$$ERROR($$$GeneralError,"Transformer Class: "_tClassName_" Does not Exist")
					Quit
				}
				Set tSC = $zobjclassmethod(tClassName,"Transform",tStream,.tOut)
				If $$$ISERR(tSC) Quit
				Do tOut.Rewind()
				Set tStream = tOut
			} else {
				set tTransformer = %compiledclass.Parameters.FindObjectId(%class.Name_"||TRANSFORMXSL")
				set tXSL = %compiledclass.Parameters.GetAt(tTransformer).Default
				if (tXSL="") {
					Set tSupers = %compiledclass.Super
					for i=1:1:$l(tSupers,",") {
						Set tSuper = $p(tSupers,",",i)
						set tClass = ##class(%Dictionary.CompiledClass).%OpenId(tSuper)
						set tTransformer = tClass.Parameters.FindObjectId(tSuper_"||TRANSFORMXSL")
						Continue:tTransformer=""
						set tXSL = tClass.Parameters.GetAt(tTransformer).Default
						Quit:tXSL'=""
					}
				}
				if (tXSL'="") {
					Set tXSLId = %compiledclass.Name_"||"_tXSL
					if ('##class(%Dictionary.CompiledXData).%ExistsId(tXSLId)) {
						Set tSC = $$$ERROR($$$GeneralError,"XSL Block: "_tXSLId_" Does not Exist")
						Quit
					}
					Set tSC = ..%OnGetModel(tXSLId,tStream,.tOut)
					If $$$ISERR(tSC) Quit
					Do tOut.Rewind()
					Set tStream = tOut
				}
			}

			If (tStream.Size > 0) {

				#; render the stream into cube meta-data object (with children)
				Set tReader = ##class(%XML.Reader).%New()

				Set tSC = tReader.OpenStream(tStream)
				If $$$ISERR(tSC) Quit

				Do tReader.Correlate("cube","%DeepSee.Model.cube")

				#; there should only be one cube defined
				Do tReader.Next(.tCube,.tSC)
				If $$$ISERR(tSC) Quit
				If '$IsObject(tCube) {
					Set tSC = $$$ERROR($$$GeneralError,"No <cube> element defined in Cube block.")
					Quit
				}

				Set tCubeName = tCube.name
				If (tCubeName = "") {
					Set tSC = $$$ERROR($$$GeneralError,"Cube must be given a name")
					Quit
				}
				If '##class(%DeepSee.Utils).%IsValidCubeName(tCubeName) {
					// DTB951 - Check for valid cube name. Prevent the compile if the name is invalid.
					Set tSC = $$$ERROR($$$GeneralError,"Cube name is invalid: " _ tCubeName)
					Quit
				}
				
				#; is this cube name already used?
				Set tRegClass = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName)))
				If ((tRegClass'="") && (tRegClass '= %class.Name)) {
					Set tSC = $$$ERROR($$$GeneralError,"Cube with given name already exists: " _ tCubeName)
					Quit
				}
				
				#; is cube disabled?
				// DTB294 - Move after name check and look at the override setting for disabled only
				Set tDisabledByOverride = +$G(^DeepSee.Overrides($$$UPPER(tCubeName),"DISABLED"))
				If (tCube.disabled)||(tDisabledByOverride) {
					If tDisabledByOverride {
						// DTB294 this can be hard-coded to true. An override cannot turn disabled off!
						Write:tDisplay !,$$$Text("Applying override to: ""disabled"" = ""1""","%DeepSee")
					}
					Write:tDisplay !,$$$FormatText($$$Text("Cube '%1' is disabled","%DeepSee"),tCube.name)
					Do %code.WriteLine(" Set tCube1 = """"")
					Do %code.WriteLine(" Quit tCube1")
					Set ^||%Cls(%compiledclass.Name,"cubeName") = tCubeName //APV019
					Quit
				}

				#; have cube generate code to recreate itself at run-time
				#; do this *before* inheritance is resolved
				Do tCube.%GenerateCode(%code,tLocalize)
				
				// +DTB130 - process cube version information
				Set tCubeVersionNo = tCube.version
				If $G(%parameter("USECUBEVERSIONS"),0) {
					If tCubeVersionNo="" {
						Set tSC = $$$ERROR($$$GeneralError,"A versioned cube definition must declare a version.")
						Quit
					}
					Else {
						// Define a new cube definition based on the version number
						Set tSC = ##class(%DeepSee.CubeVersion.Utils).%CreateCubeVersionDefinition(%compiledclass.Name,.tCube,.tNewClassName,.tCubeVersionIndex)
						If $$$ISERR(tSC) Quit
						Set tSC = $system.OBJ.Compile(tNewClassName)
						If $$$ISERR(tSC) Quit
						
						// Log this version of the cube in the versionIndex
						Set $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeName),tCubeVersionNo,"class") = tNewClassName
						Set $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeName),tCubeVersionNo,"cube") = tCubeVersionIndex
						
						// Cross-reference the primary definition in the version metadata
						Set $$$DeepSeeMetaGLVN("versionIndex","versionOf",tCubeVersionIndex) = $$$UPPER(tCubeName)
						
						// If this was the active version and is being recompiled, mark that the cube has  
						// no active version and that the current version is pending
						If ##class(%DeepSee.CubeVersion.Utils).%IsActiveVersion(tCubeVersionIndex) {
							Set tSC = ##class(%DeepSee.CubeVersion.Utils).%SetActiveCubeVersion(tCubeName,"")
						}
						
						// Look to see if there is a pending version already. If there is one that is not this version, deprecate it
						Set tPendingVersion = ##class(%DeepSee.CubeVersion.Utils).%GetPendingCubeVersion(tCubeName)
						If (tPendingVersion'=tCubeVersionNo) {
							Set tSC = ##class(%DeepSee.CubeVersion.Utils).%DeprecateCubeVersion(tCubeName,tPendingVersion)
						}

						// DTB130 - Cube being compiled is automatically set as the pending version
						Set tSC = ##class(%DeepSee.CubeVersion.Utils).%SetPendingCubeVersion(tCubeName,tCubeVersionNo)
						
					}
				}
				ElseIf ($G(%parameter("USECUBEVERSIONS"),0)=0) {
					// The version is ignored in this case, notify that this is the case
					If (tCubeVersionNo'="") {
						Write:tDisplay !,$$$FormatText($$$Text("Cube version is set to '%1' but USECUBEVERSIONS=0. The version attribute will be ignored.","%DeepSee"),tCubeVersionNo)
					}
					
					// Look to see if there is a pending version already. If there is one that is not this version, deprecate it
					Set tPendingVersion = ##class(%DeepSee.CubeVersion.Utils).%GetPendingCubeVersion(tCubeName)
					If tPendingVersion {
						Set tSC = ##class(%DeepSee.CubeVersion.Utils).%DeprecateCubeVersion(tCubeName,tPendingVersion)
					}
					Set tActiveVersion = ##class(%DeepSee.CubeVersion.Utils).%GetActiveCubeVersion(tCubeName)
					If tActiveVersion {
						Set tSC = ##class(%DeepSee.CubeVersion.Utils).%SetActiveCubeVersion(tCubeName,"")
						Set tSC = ##class(%DeepSee.CubeVersion.Utils).%DeprecateCubeVersion(tCubeName,tActiveVersion)
					}
					
					Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeName),"activeVersion")
					Kill $$$DeepSeeMetaGLVN("versionIndex","versions",$$$UPPER(tCubeName),"pendingVersion")
				}
				// -DTB130

				#; resolve inheritance (if any)
				Set tSC = tCube.%ResolveInheritance()
				If $$$ISERR(tSC) Quit

				#; resolve shared dimensions (if any)
				Set tSC = tCube.%ResolveSharedDimensions(.tSharedInfo)
				If $$$ISERR(tSC) Quit

				#; apply overrides to model (if any)
				Set tSC = tCube.%ApplyOverrides($Name(^DeepSee.Overrides))
				If $$$ISERR(tSC) Quit

				#; skip validation for abstract classes
				If ('+tCube.abstract) {
					#; test source class
					If (tCube.sourceClass="") {
						Set tSC = $$$ERROR($$$GeneralError,"Cube must define a sourceClass")
						Quit
					}

					Set tSourceType = ""

					// special case: test for worksheets and kpis
					Set tExt = $P(tCube.sourceClass,".",$L(tCube.sourceClass,"."))
					If ((tExt="kpi")||(tExt="metric")||(tExt="worksheet")) {
						If (tExt="kpi") {
							Set tName = $P(tCube.sourceClass,".",1,$L(tCube.sourceClass,".")-1)
							Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
							If (tKPIClass="") {
								Set tSC = $$$ERROR($$$GeneralError,"Class referred to by sourceClass is not defined: "_tCube.sourceClass)
								Quit
							}
							Set tSourceType = "kpi"
						}
						ElseIf (tExt="worksheet") {
							Set tName = tCube.sourceClass
							Set tKPIClass = "%DeepSee.KPIWorksheet"
							Set tSourceType = "worksheet"
						}
						Else {
							Set tSourceType = "metric"
							Set tName = tCube.sourceClass
							Set tKPIClass = "Ens.BusinessMetricKPI"
						}
					}
					ElseIf '$$$defClassDefined(tCube.sourceClass) {
						Set tSC = $$$ERROR($$$GeneralError,"Class referred to by sourceClass is not defined: "_tCube.sourceClass)
						Quit
					}

					#; determine type of sourceClass
					If (tSourceType = "") {
						Try {
							If ($$$getClassType(tCube.sourceClass)="view") {
								Set tSC = $$$ERROR($$$GeneralError,"View cannot be used as a data source; use a DataConnector class: "_tCube.sourceClass)
							}
							ElseIf ($$$getClassType(tCube.sourceClass)="persistent") {
								Set tSourceType = "persistent"
							}
							ElseIf $zobjclassmethod(tCube.sourceClass,"%IsA","%DeepSee.DataConnector") {
								Set tSourceType = "dataconnector"
							}
						}
						Catch (ex) {
							Set tSC = $$$ERROR($$$GeneralError,"Invalid or missing sourceClass "_tCube.sourceClass)
						}
						If $$$ISERR(tSC) Quit
					}

					If (tSourceType = "") {
						Set tSC = $$$ERROR($$$GeneralError,"Source class must be either be a persistent class or a DeepSee DataConnector class: "_tCube.sourceClass)
						Quit
					}

					Set tSC = tCube.%ProcessFunctions()
					If $$$ISERR(tSC) Quit

					#; validate cube
					Set tSC = tCube.%Validate()
					If $$$ISERR(tSC) Quit
				}

				#; get name of cube
				Set ^||%Cls(%compiledclass.Name,"cubeName") = tCubeName
				Set ^||%Cls(%compiledclass.Name,"sourceType") = $G(tSourceType)
				Set ^||%Cls(%compiledclass.Name,"sourceClass") = tCube.sourceClass
				Set ^||%Cls(%compiledclass.Name,"cubeCaption") = $S(tCube.caption'="":tCube.caption,1:tCube.displayName)
				Set ^||%Cls(%compiledclass.Name,"countName") = tCube.countMeasureName
				Set ^||%Cls(%compiledclass.Name,"countCaption") = tCube.countMeasureCaption
				Set ^||%Cls(%compiledclass.Name,"maxFacts") = tCube.maxFacts
				Set ^||%Cls(%compiledclass.Name,"abstract") = +tCube.abstract
				Set:tCube.initialBuildOrder'="" ^||%Cls(%compiledclass.Name,"initialBuildOrder") = tCube.initialBuildOrder
				Set:tCube.buildRestriction'="" ^||%Cls(%compiledclass.Name,"buildRestriction") = tCube.buildRestriction

				#; nothing more to do for abstract cubes
				If (+tCube.abstract) {
					Do %code.WriteLine(" Quit tCube1")
					Quit
				}

				Set tCubeNameU = $$$UPPER(tCubeName)

				#; JMD1472: if cube is disabled at this point then it is due to
				#; an override; mark the cube as disabled, but compile as normal
				If (tCube.disabled) {
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"disabled") = 1
				}

				#; does this cube support drill through
				#; JMD989 No longer used
				#; Set ^||%Cls(%compiledclass.Name,"drillThrough") = (tCube.listings.Count()>0)

				#; schema for generated classes
				Set tSchema = %compiledclass.Name

				// +DTB119
				// Look through the methods in %compiledclass to see if %OnProcessFact is user-defined.
				// %Dictionary.CompiledMethod does not have this entry yet!
				Set tOnProcessFact = 0
				For ii=1:1:%compiledclass.Methods.Count() {
					Set tMethod = %compiledclass.Methods.GetAt(ii)
					// The method could be inherited from a different user class that the current class inherits.
					If (tMethod.Name="%OnProcessFact")&&(tMethod.Origin'="%DeepSee.CubeDefinition") {
						Set tOnProcessFact = 1
					}
				} 
	
				If tOnProcessFact {
					// Indicate the cube actually uses this method in the metadata
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"onProcessFact") = 1
				}
				// -DTB119

				#; take out lock to prevent queries
				// +DTB130 - timeout and report locking problem
				Set tLocked = 1
				Lock +^DeepSee.Build(tCubeNameU):10 Else  Set tLocked=0	
				If 'tLocked {
					Set tSC = $$$ERROR($$$GeneralError,"Unable to obtain the lock needed for compile: " _ tCubeNameU)
					Quit
				}
				// -DTB130

				#; Analyze cube and get meta-structures
				Set tSC = ##class(%DeepSee.Generator).%BuildCubeInfo(tCube,tSchema,.tMbrInfo,.tMbrNames,.tFactIndex,.tFactInfo,.tStarInfo,.tMsrIndex,.tRelationInfo,.tRelIndex,.tCaptions,.tCubeMeta,.tLevelDepends,.tComputedDims,.tDescriptions) // JSL4475 - fill in tDescriptions
				If $$$ISERR(tSC) Quit

				#; save meta data to global
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#") = tMbrInfo
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbrs") = tMbrNames
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact#") = tFactIndex
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"msr#") = tMsrIndex
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact") = tFactInfo
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"star") = tStarInfo
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"relations") = tRelationInfo
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"rel#") = tRelIndex

				#; JMD1453 compute *actual* fact count
				Set tFactCount = 0
				Set k = $O(tFactIndex(""))
				While (k'="") {
					Set:(k>tFactCount) tFactCount = k
					Set k = $O(tFactIndex(k))
				}
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"factCount") = tFactCount

				#; JMD910 levelDepends: (d#,h#,l#,masterFact#)
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"levelDepends") = tLevelDepends

				#; JMD1329
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"computedDims") = tComputedDims

				#; JMD1059 get factDepends info: (MasterFact#,SlaveFact#)
				Set xd = $O(tLevelDepends(""))
				While (xd'="") {
					Set xh = $O(tLevelDepends(xd,""))
					While (xh'="") {
						Set xl = $O(tLevelDepends(xd,xh,""))
						While (xl'="") {
							Set tMasterFactNo = $O(tLevelDepends(xd,xh,xl,""))
							While (tMasterFactNo'="") {
								Set tSlaveInfo = $G(tMbrInfo(xd,xh,xl))
								Set tSlaveFactNo = $LG(tSlaveInfo,5)
								If (tSlaveFactNo'="") {
									Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"factDepends",tMasterFactNo,tSlaveFactNo) = ""
								}
								Set tMasterFactNo = $O(tLevelDepends(xd,xh,xl,tMasterFactNo))
							}
							Set xl = $O(tLevelDepends(xd,xh,xl))
						}
						Set xh = $O(tLevelDepends(xd,xh))
					}
					Set xd = $O(tLevelDepends(xd))
				}

				// DTB886 - Look at anything that might have been packed into the metadata and place
				// it in the appropriate global node
				Set tMetaProp = $O(tCubeMeta(""),1,tMetaPropValue)
				While (tMetaProp'="") {
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,tMetaProp) = tMetaPropValue
					Set tMetaProp = $O(tCubeMeta(tMetaProp),1,tMetaPropValue)
				}

				// BDB267: create any iKnow domains for iKnow measures in this cube.
				// To verify if any domains created for a previous version of this cube
				// can be reused (and need to be renamed) or should be dropped, first
				// browse through the "prior" facts and note all iKnow domains
				set tOldCubeNameU = $s(tOldCubeName'="":$$$UPPER(tOldCubeName), 1:tCubeNameU)
				set tFact = "", gPriorFacts = $name($$$DeepSeeMetaGLVN("prior",tOldCubeNameU,"fact","prop"))
				for {
					set tFact = $order(@gPriorFacts@(tFact))
					quit:tFact=""
				
					set tIndexType = $g(@gPriorFacts@(tFact,"index"))
					continue:$piece(tIndexType,":",1)'="iKnow"
				
					// skip iKnow-managed domains
					continue:$piece(tIndexType,":",2)="domain"
				
					set tIKMeasure = $g(@gPriorFacts@(tFact,"msrname"))
					set tExprOrProp = $g(@gPriorFacts@(tFact,"expr"), $g(@gPriorFacts@(tFact,"source")))
					continue:tExprOrProp=""
				
					set tDomainName = $piece(tIndexType,":",3)
					set tDomainParams = $piece(tIndexType,":",5,9999)
					if (tDomainName="") {
						set tDomainName = ##class(%iKnow.DeepSee.CubeUtils).GetDeepSeeDomainName(tOldCubeNameU,tIKMeasure)
					}
					
					set ^||%Cls(%compiledclass.Name,"iKnow","props",tExprOrProp, tDomainName) = $$$UPPER(tIKMeasure)
				}
				kill tFixedDomainNames
				set tFact = ""
				for {
					set tFact = $order(tFactInfo("prop",tFact))
					quit:tFact=""
					
					set tIndexType = $g(tFactInfo("prop",tFact,"index"))
					continue:$piece(tIndexType,":",1)'="iKnow"
					
					// skip iKnow-managed domains
					continue:$piece(tIndexType,":",2)="domain"
					
					set tIKMeasure = $g(tFactInfo("prop",tFact,"msrname"))
					
					set tExprOrProp = $g(tFactInfo("prop",tFact,"expr"), $g(tFactInfo("prop",tFact,"source")))
					continue:tExprOrProp=""
					
					set tDomainName = $piece(tIndexType,":",3)
					set tDomainDictionaries = $piece(tIndexType,":",4) // BDB387
					set tDomainParams = $piece(tIndexType,":",5,9999)
					if (tDomainName="") {
						set tDomainName = ##class(%iKnow.DeepSee.CubeUtils).GetDeepSeeDomainName(tCubeName,tIKMeasure)
					}
					
					// Check if this domain name is not already in use by another measure
					if $d(tFixedDomainNames($$$UPPER(tDomainName)), tOtherMeasure) {
						set tSC = $$$ERROR($$$GeneralError, "Domain name """_tDomainName_""" already in use by "_tOtherMeasure)
						quit
					}
					set tFixedDomainNames($$$UPPER(tDomainName)) = tIKMeasure
					
					// if we have a domain with the same name, we'll reuse it
					set gPrevDomains = $name(^||%Cls(%compiledclass.Name,"iKnow","props",tExprOrProp))
					if $d(@gPrevDomains@(tDomainName)) {
						
						// reuse as is, remove from the to-be-dropped list
						kill @gPrevDomains@(tDomainName)
						
					} elseif $d(@gPrevDomains) {
						
						// usually there's only one domain, but let's make sure to make
						// a well-educated guess if there's more.
						
						// check if the measure name happens to be the same
						// (fe if only the cube name changed)
						set tPrevDomainName=""
						for {
							set tPrevDomainName = $order(@gPrevDomains@(tPrevDomainName),1,tPrevIKMeasure)
							quit:tPrevDomainName=""
							quit:$$$UPPER(tIKMeasure)=tPrevIKMeasure
						}
						
						// if we didn't find any, just take the first
						set:tPrevDomainName="" tPrevDomainName = $order(@gPrevDomains@(""))
					
						// now try to rename tPrevDomainName to the new domain name 
						/// BDB348 - delegate to CubeUtils (domain manager)
						set tSC = ##class(%iKnow.DeepSee.CubeUtils).RenameDomain(tPrevDomainName, tDomainName)
						quit:$$$ISERR(tSC)
					
						// if we were able to rename it, just remove it from the list to indicate
						// we'll be reusing it as tDomainName
						kill @gPrevDomains@(tPrevDomainName)
					}
					
					// now create the domain, which will just apply the required parameters if it
					// already exists
					set tDomainId = ##class(%iKnow.DeepSee.CubeUtils).CreateDomain(tCubeName, tIKMeasure, tDomainParams, tDomainDictionaries, .tDomainName, .tSC)
					quit:$$$ISERR(tSC)
				}
				quit:$$$ISERR(tSC)
				
				// if there's any domains left from a previous version, drop them
				if ($d(^||%Cls(%compiledclass.Name,"iKnow","props"))) {
					set tExprOrProp=""
					for {
						set tExprOrProp = $order(^||%Cls(%compiledclass.Name,"iKnow","props",tExprOrProp))
						quit:tExprOrProp=""
						
						set tDomainName=""
						for {
							set tDomainName = $order(^||%Cls(%compiledclass.Name,"iKnow","props",tExprOrProp, tDomainName))
							quit:tDomainName=""
							
							/// BDB348 - delegate to CubeUtils (domain manager)
							do ##class(%iKnow.DeepSee.CubeUtils).DropDomain(tDomainName)
						}
					}
					kill ^||%Cls(%compiledclass.Name,"iKnow","props")
				}

				#; additional meta data
				Set:tCube.actionClass'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"actionClass") = tCube.actionClass
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"sourceType") = tSourceType
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"sourceClass") = tCube.sourceClass
				Set:tCube.resource'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"resource") = tCube.resource
				Set:tCube.initialBuildOrder'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"initialBuildOrder") = tCube.initialBuildOrder
				Set:tCube.buildRestriction'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"buildRestriction") = tCube.buildRestriction

				#; reset sharesFrom index
				Set tSCube1 = $O($$$DeepSeeMetaGLVN("sharesIndex",""))
				While (tSCube1'="") {
					Set tFNO = $O($$$DeepSeeMetaGLVN("sharesIndex",tSCube1,""))
					While (tFNO'="") {
						Set tSCube2 = $O($$$DeepSeeMetaGLVN("sharesIndex",tSCube1,tFNO,""))
						While (tSCube2'="") {
							If (tSCube2=tCubeNameU) {
								Kill $$$DeepSeeMetaGLVN("sharesIndex",tSCube1,tFNO,tSCube2)
							}
							Set tSCube2 = $O($$$DeepSeeMetaGLVN("sharesIndex",tSCube1,tFNO,tSCube2))
						}
						Set tFNO = $O($$$DeepSeeMetaGLVN("sharesIndex",tSCube1,tFNO))
					}

					If (tSCube1=tCubeNameU) {
						Kill $$$DeepSeeMetaGLVN("sharesIndex",tSCube1)
					}
					Set tSCube1 = $O($$$DeepSeeMetaGLVN("sharesIndex",tSCube1))
				}

				If $D(tSharedInfo) {
					#; tSharedInfo(OTHERCUBE,DIMENSION) = ""
					Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"sharesFrom") = tSharedInfo
					Set tSC = ..%UpdateSharesIndex(tCubeNameU)
					If $$$ISERR(tSC) Quit
				}

				If (tSourceType = "dataconnector") {
					Set tVersion = $zobjclassmethod(tCube.sourceClass,"%GetVersion")
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"connectorVersion") = tVersion
				}

				#; listings
				Set tDefaultListing = ""
				Set tDefaultListingOrder = ""
				Set tDefaultListingSQL = ""
				Set tDefaultSourceClass = ""
				Set tDefaultListingFormat = ""
				Set tDefaultListingResource = ""
				Set tDefaultListingSelectMode = ""		// DP-416501

				// DTB082 
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"disableListingGroups") = tCube.disableListingGroups

				// DTB717 - Set up a special computed dimension to support %SQLRESTRICT
				If tCube.enableSqlRestrict {
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbrs","%SQLRESTRICT") = $LB(-1,1,1)
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",-1,0,0) = $LB("d","%SQLRESRICT",,"")
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",-1,1,0) = $LB("h","%SQLRESTRICT","H1",,,"%DeepSee.Query.memberComputed",,,,,,,,,,,0)
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",-1,1,1) = $LB("l","%SQLRESTRICT","H1","%SQLRESTRICT",-1,"%DeepSee.ComputedDimension.SQL","%sourceId","","","",1,"%sourceId")
				}

				For n=1:1:tCube.listings.Count() {
					Set tListing = tCube.listings.GetAt(n)
					If ('tListing.disabled) {
						Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"fieldList") = tListing.fieldList
						Set:tListing.formatList'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"formatList") = tListing.formatList
						Set:tListing.orderBy'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"orderBy") = tListing.orderBy
						Set:tListing.sql'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"sql") = tListing.sql
						Set:tListing.sourceClass'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"sourceClass") = tListing.sourceClass
						Set:(tListing.listingType'="")&&(tListing.listingType'="table") $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"listingType") = tListing.listingType
						Set:tListing.resource'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"resource") = tListing.resource
						Set:tListing.selectMode'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"selectMode") = tListing.selectMode		// DP-414835
						// JMD989: store display name
						Set:tListing.displayName'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"displayName") = tListing.displayName
						// JSL4477: store display name
						Set:tListing.description'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listing",tListing.name,"description") = tListing.description

						If ((n=1)||($$$UPPER(tListing.name)=$$$UPPER(tCube.defaultListing))) {
							Set tDefaultListing = tListing.fieldList
							Set tDefaultListingOrder = tListing.orderBy
							Set tDefaultListingSQL = tListing.sql
							Set tDefaultSourceClass = tListing.sourceClass
							Set tDefaultListingFormat = tListing.formatList
							Set tDefaultListingResource = tListing.resource
							Set tDefaultListingSelectMode = tListing.selectMode		// DP-416501
						}
					}
				}

				Set:tDefaultListing'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListing") = tDefaultListing
				Set:tDefaultListingOrder'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListingOrder") = tDefaultListingOrder
				Set:tDefaultListingSQL'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListingSQL") = tDefaultListingSQL
				Set:tDefaultSourceClass'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListingSourceClass") = tDefaultSourceClass
				Set:tDefaultListingFormat'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListingFormat") = tDefaultListingFormat
				Set:tDefaultListingResource'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListingResource") = tDefaultListingResource
				Set:tDefaultListingSelectMode'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defaultListingSelectMode") = tDefaultListingSelectMode		// DP-416501

				#; listing fields
				For n=1:1:tCube.listingFields.Count() {
					Set tField = tCube.listingFields.GetAt(n)
					If ('tField.disabled) {
						Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listingFields",tField.name,"fieldExpression") = tField.fieldExpression
						Set:tField.resource'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listingFields",tField.name,"resource") = tField.resource
						Set:tField.displayName'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listingFields",tField.name,"displayName") = tField.displayName
						Set:tField.description'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"listingFields",tField.name,"description") = tField.description // JSL4477
					}
				}

				#; specify where data comes from
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"factClass") = %compiledclass.Name_".Fact"
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"indexName") = tCubeNameU

				#; find list of classes that provide data for dimensions (used for synchronization)
				If (tSourceType="persistent") {
					Set tProp = $O(tFactInfo("prop",""))
					While (tProp '= "") {
						Set tPropLocalSource = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",tProp,"localSource"))
						Set tPropLocalExpr = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",tProp,"localExpr"))

						#; ignore shared properties
						If ((tPropLocalSource="")&&(tPropLocalExpr="")) {
							// !!! we have to pick up expressions also !!!
							// what about ref fields? -- we can ignore these
							Set tPropSource = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",tProp,"source"))
							Set tDepth = $L(tPropSource,".")
							Set tPropRef = $P(tPropSource,".",1,tDepth-1)
							If (tPropRef'="") {
								// find type of reference *before* final property
								Set tSC = ##class(%DeepSee.Generator).%AnalyzeStarProperty(tCube.sourceClass,tPropRef,.tType,,"cube")
								If $$$ISERR(tSC) Quit
								If (tType'="") {
									// check if DSTIME is in play
									$$$comMemberKeyGetLvar(tDSTIME,tType,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
									If ((tDSTIME'="")&&($$$UPPER(tDSTIME)'="NONE")) {
										Set tSourceExpr = ##class(%DeepSee.Generator).%GetSQLFieldExpression(.tSC,tCube.sourceClass,tPropRef)
										If $$$ISERR(tSC) Quit
										Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"depends",tType) = tSourceExpr
									}
								}
							}
						}
						Set tProp = $O(tFactInfo("prop",tProp))
					}
				}
				If $$$ISERR(tSC) Quit

				#; Analyze calculated members and named sets
				// + WAL065 -- pass tMbrNames array so that we don't overwrite captions for standard dimensions
				//             this array is created above by %BuildCubeInfo and contains all of the standard dimensions, hierarchies and levels
				Set tSC = ##class(%DeepSee.Generator).%ProcessVirtualMembers(tCube,.tNamedSets,.tCalcMbrs, .tCaptions,.tDescriptions,.tMbrNames)
				// - WAL065
				If $$$ISERR(tSC) Quit

				Merge ^||%Cls(%compiledclass.Name,"captions") = tCaptions
				Merge ^||%Cls(%compiledclass.Name,"descriptions") = tDescriptions // JSL4475
				Set ^||%Cls(%compiledclass.Name,"precompute") = tCube.precompute
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"precompute") = tCube.precompute
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"caption") = tCube.caption

				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"namedSets") = tNamedSets
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"calcMbrs") = tCalcMbrs

				#; apply bucket size
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"bucketSize") = tCube.bucketSize

				If (tCube.defaultMeasure'="") {
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defmsr") = tCube.defaultMeasure
				}
				If (tCube.defaultMember'="") {
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defmbr") = tCube.defaultMember
				}
				Set tDimNode = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",1,0,0))
				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"defdim") = $LG(tDimNode,2)

				If ($$$UPPER(tOldCubeName)=tCubeNameU) {
					If (tOldDSTIME'="") {
						// restore sync point (timestamp)
						Set tSC = ##class(%DeepSee.Utils).%SetCubeDSTime(tCubeNameU,tOldDSTIME)		// DTB838 - Use API
						If $$$ISERR(tSC) Quit
					}
				}

				#; test if *other* cubes share from *this* cube
				Set tOtherCube = $O($$$DeepSeeMetaGLVN("cubes",""))
				While (tOtherCube'="") {
					If $D($$$DeepSeeMetaGLVN("cubes",tOtherCube,"sharesFrom",tCubeNameU)) {
						Write:tDisplay !,"Updating shared cube info: ",tOtherCube,!
						Set tSC = ..%UpdateSharesIndex(tOtherCube)
						If $$$ISERR(tSC) Quit
					}
					Set tOtherCube = $O($$$DeepSeeMetaGLVN("cubes",tOtherCube))
				}
				If $$$ISERR(tSC) Quit

				#; compute fact order
				#; this is the order in which facts are ANDed, most selective first
				Set tProp = $O(tFactInfo("prop",""))
				While (tProp '= "") {
					Set tFactNo = $G(tFactInfo("prop",tProp))
					If ((tFactNo = +tFactNo) && (tFactNo>0)) {
						Set tLevelNo = +$G(tFactInfo("prop",tProp,"levelNo"))
						If ((tCube.initialBuildOrder'="")&&($G(tFactInfo("prop",tProp,"source"))=tCube.initialBuildOrder)) {
							#; give slight edge to the initial sort property
							Set tLevelNo = tLevelNo + 1
						}
						Set tFactOrder(tLevelNo,tFactNo) = tProp
					}
					Set tProp = $O(tFactInfo("prop",tProp))
				}
				
				Set tFactOrderList = $LB("")
				Set k = $O(tFactOrder(""),-1)
				While (k'="") {
					Set f = $O(tFactOrder(k,""),-1)
					While (f'="") {
						Set tFactOrderList = tFactOrderList_$LB(f)
						Set f = $O(tFactOrder(k,f),-1)
					}
					Set k = $O(tFactOrder(k),-1)
				}

				Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"factOrder") = tFactOrderList

				#; compare meta data with prior data
				Set tSC = ##class(%DeepSee.Generator).%CompareMetaData(tCubeName,.tDelta)
				If $$$ISERR(tSC) Quit
				If (('+$G(tDelta("dims")))||('+$G(tDelta("bucketSize")))||('+$G(tDelta("facts")))||('+$G(tDelta("cube")))) {
					// meta data change
					If (('+$G(tDelta("dims")))&&(+$G(tDelta("bucketSize")))&&(+$G(tDelta("facts")))&&(+$G(tDelta("cube")))) {
						// results cache only
						Set tSC = ##class(%DeepSee.Query.Engine).%ClearCache(tCubeName,1)
						If $$$ISERR(tSC) Quit
					}
					Else {
						Set tSC = ##class(%DeepSee.Query.Engine).%ClearCache(tCubeName)
						If $$$ISERR(tSC) Quit
					}
					#; time stamps (utc)
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"lastSchemaUpdate") = $ZTIMESTAMP
					Set $$$DeepSeeUpdateQueue("cubes",tCubeNameU,"lastDataUpdate") = ""		// DTB422 - Store data updates in the updates global
				}
				Else {
					Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"lastSchemaUpdate") = $G($$$DeepSeeMetaGLVN("prior",tCubeNameU,"lastSchemaUpdate"))
				}
				// !!! for this last test, we need to track our own dependencies!!!
				If (1||('+$G(tDelta("facts")))||('+$G(tDelta("cube")))) {
					#; build FACT and STAR tables
					// DTB961 - Provide the previous fact storage information in the creation of the 
					// fact table. This will get processed and be returned with the proper metadata
					// to store with this compile of the cube.
					Set tSC = ##class(%DeepSee.Generator).%CreateFactTable(tCube,%compiledclass.Name,tSchema,tSourceType,.tFactIndex,.tFactInfo,.tStarInfo,.tMsrIndex,.tRelationInfo,.tStorage)
					If $$$ISERR(tSC) Quit
				}

				// pick up some additional metadata created by create fact table
				Set tStar = $O(tStarInfo(""))
				While (tStar'="") {
					Set tPrimary = $G(tStarInfo(tStar,"primary"))
					Set:tPrimary'="" $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"star",tStar,"primary") = tPrimary
					Set tStar = $O(tStarInfo(tStar))
				}
				
				// + DTB908 - Copy over "enabled" settings from the prior if fact numbers are stable.
				// If no prior exists for the cube, mark all facts as enabled=0.
				If $$$dsSupportsSelectedList(tCubeNameU) {
					If '$D($$$DeepSeeMetaGLVN("prior",tCubeNameU)) {
						// If there is no prior, this is the first compile. Mark all dimensions enabled=0
						Set tSC = ##class(%DeepSee.Utils).%MarkFactsEnabled(tCubeNameU,"",0)
						If $$$ISERR(tSC) Quit
					}
					Else {
						Set tProperty = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",""))
						While (tProperty'="") {
							If $D($$$DeepSeeMetaGLVN("prior",tCubeNameU,"fact","prop",tProperty,"enabled")) {
								// If there is a prior, copy t over to the current metadata
								Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",tProperty,"enabled") = $$$DeepSeeMetaGLVN("prior",tCubeNameU,"fact","prop",tProperty,"enabled")
							}
							ElseIf '$D($$$DeepSeeMetaGLVN("prior",tCubeNameU,"fact","prop",tProperty)) {
								// DTB918 - Specifically test for missing property in the prior.
								// A property without a prior at all will be marked enabled=0
								Set $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",tProperty,"enabled") = 0
							}

							Set tProperty = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"fact","prop",tProperty))
						}
					}
				}
				// - DTB908
				
				// + DTB961 - Log the storage location for each fact as assigned to the .Fact class.
				Kill $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"storage")
				Merge $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"storage") = tStorage
				// - DTB961
			}
			Else {
				Set tSC = $$$ERROR($$$GeneralError,"No Cube definition in cube definition class: " _ %class.Name)
				Quit
			}
		}
		Else {
			Do %code.WriteLine(" Set tCube1 = """"")
		}

		Do %code.WriteLine(" Quit tCube1")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	#; remove lock
	If $G(tLocked) {
		Lock -^DeepSee.Build(tCubeNameU)
	}
	
	// DTB949 - If there was an error, communicate it to the projection for recording in the metadata
	Set:$$$ISERR(tSC) ^||%Cls(%compiledclass.Name,"error") = tSC

	Quit tSC
}

/// Update the "sharesIndex" for the given cube.
ClassMethod %UpdateSharesIndex(pCubeName As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		#; add facts to sharesIndex
		#; this takes the form: META("sharesFrom","CUBE1",FACT,"CUBE2") = ""

		Set tCubeNameU = $$$UPPER(pCubeName)
		Merge tSharedInfo = $$$DeepSeeMetaGLVN("cubes",tCubeNameU,"sharesFrom")

		Set tShareCube = $O(tSharedInfo(""))
		While (tShareCube'="") {
			Set tShareDim = $O(tSharedInfo(tShareCube,""))
			While (tShareDim'="") {
				// loop over facts for the dimension in *this* cube
				Set tDimNo = +$LG($G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbrs",tShareDim)),1)
				Set tOtherDimNo = +$LG($G($$$DeepSeeMetaGLVN("cubes",tShareCube,"mbrs",tShareDim)),1)

				If (tDimNo>0) {
					Set h = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",tDimNo,""))
					While (h'="") {
						Set l = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",tDimNo,h,""))
						While (l'="") {
							Set tLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",tDimNo,h,l))
							Set tFactNo = $LG(tLevelInfo,5)
							If (+tFactNo) {
								// get fact info for *other* cube
								Set tOtherLevelInfo = $G($$$DeepSeeMetaGLVN("cubes",tShareCube,"mbr#",tOtherDimNo,h,l))
								Set tOtherFactNo = $LG(tOtherLevelInfo,5)

								// set both index entries
								// JMD920: prevent subscript error
								If (tOtherFactNo'="") {
									Set $$$DeepSeeMetaGLVN("sharesIndex",tCubeNameU,tFactNo,tShareCube) = tOtherFactNo
									Set $$$DeepSeeMetaGLVN("sharesIndex",tShareCube,tOtherFactNo,tCubeNameU) = tFactNo
								}
							}
							Set l = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",tDimNo,h,l))
						}
						Set h = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"mbr#",tDimNo,h))
					}
				}

				Set tShareDim = $O(tSharedInfo(tShareCube,tShareDim))
			}
			Set tShareCube = $O(tSharedInfo(tShareCube))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return information on the source data for this cube.
ClassMethod %GetSourceInfo(Output pInfo) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Quit
		}
		Do %code.WriteLine(" Kill pInfo")
		Set tSourceClass = $G(^||%Cls(%compiledclass.Name,"sourceClass"))
		Set tSourceType = $G(^||%Cls(%compiledclass.Name,"sourceType"))
		Set tMaxFacts = $G(^||%Cls(%compiledclass.Name,"maxFacts"))
		Set tInitialBuildOrder = $G(^||%Cls(%compiledclass.Name,"initialBuildOrder"))
		Set tBuildRestriction = $G(^||%Cls(%compiledclass.Name,"buildRestriction"))

		If (tSourceClass '= "") {
			Do %code.WriteLine(" Set pInfo(""sourceType"") = " _ $$$quote(tSourceType))
			Do %code.WriteLine(" Set pInfo(""sourceClass"") = " _ $$$quote(tSourceClass))
			Do %code.WriteLine(" Set pInfo(""maxFacts"") = " _ $$$quote(tMaxFacts))

			If (tSourceType = "persistent") {
				Do:tInitialBuildOrder'="" %code.WriteLine(" Set pInfo(""initialBuildOrder"") = " _ $$$quote(tInitialBuildOrder))
				Do:tBuildRestriction'="" %code.WriteLine(" Set pInfo(""buildRestriction"") = " _ $$$quote(tBuildRestriction))

				// JMD1177: find out if DSTIME and DSINTERVAL are defined
				$$$comMemberKeyGetLvar(tDSTIME,tSourceClass,$$$cCLASSparameter,"DSTIME",$$$cPARAMdefault)
				$$$comMemberKeyGetLvar(tDSINTERVAL,tSourceClass,$$$cCLASSparameter,"DSINTERVAL",$$$cPARAMdefault)

				Do %code.WriteLine(" Set pInfo(""dstime"") = " _ $$$quote(tDSTIME))
				Do %code.WriteLine(" Set pInfo(""dsinterval"") = " _ $$$quote(tDSINTERVAL))
				If $$$UPPER(tDSTIME)="CONDITIONAL" { //DP-404466
					$$$comMemberKeyGetLvar(tDSCONDITION,tSourceClass,$$$cCLASSparameter,"DSCONDITION",$$$cPARAMdefault)
					Do %code.WriteLine(" Set pInfo(""dscondition"") = " _ $$$quote(tDSCONDITION))
				}
				// find out if source class is final
				Set tFinal = $$$comClassKeyGet(tSourceClass,$$$cCLASSfinal)
				Do:+tFinal %code.WriteLine(" Set pInfo(""sourceFinal"") = 1")

				// if not final, build a list of sourceClass subclasses,
				// these are used by %SynchronizeCube
				If ('tFinal) {
					// Find all subclasses of the source class
					Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
					Set tSC = tRS.Execute(tSourceClass)
					If $$$ISERR(tSC) Quit
					While (tRS.Next(.tSC)) {
						If $$$ISERR(tSC) Quit
						Set tName = $G(tRS.Data("Name"))
						Do %code.WriteLine(" Set pInfo(""sourceSubClass"","_$$$quote(tName)_") = """"")
					}
					If $$$ISERR(tSC) Quit
				}

				// determine if the source class is bitmap friendly
				Set tIDKEY = $G($$$EXTidkey($$$pEXT,tSourceClass))
				Do %code.WriteLine(" Set pInfo(""idkey"") = " _ $$$quote(tIDKEY))
				If (tIDKEY'="") {
					Set tIndex = ##class(%Dictionary.CompiledIndex).IDKEYOpen(tSourceClass,tIDKEY)
					If $IsObject(tIndex) {
						Do %code.WriteLine(" Set pInfo(""posint"") = " _ tIndex.PosInt)
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do %code.WriteLine(" Quit $$$OK")
	Quit tSC
}

/// Return the logical name for the %COUNT measure used by this cube.
ClassMethod %GetCountName() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Do %code.WriteLine(" Quit ""%COUNT""")
			Quit
		}

		Set tName = $G(^||%Cls(%compiledclass.Name,"countName"))
		If (tName="") {
			Do %code.WriteLine(" Quit ""%COUNT""")
			Quit
		}
		Do %code.WriteLine(" Quit "_$$$quote(tName))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the (localized) caption for the %COUNT measure used by this cube.
/// Returns "" if this has not been overridden by the cube.
ClassMethod %GetCountCaption() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Do %code.WriteLine(" Quit """"")
			Quit
		}

		Set tName = $G(^||%Cls(%compiledclass.Name,"countCaption"))
		If (tName="") {
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

/// Return the (localized) caption for a given listing within this cube.
ClassMethod %GetListingCaption(pListing As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
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
ClassMethod %GetListingDescription(pListing As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	// method added by JSL4477
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
			Set tDescription = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listing",k,"description")) // JSL4477
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
ClassMethod %GetListingFieldCaption(pField As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
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
ClassMethod %GetListingFieldDescription(pField As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
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
			Set tDescription = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"listingFields",k,"description")) // JSL4477
			;Set:tDescription="" tDescription = k
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
ClassMethod %GetLevelMemberCaption(pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer, pName As %String) As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
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

/// For a given dimension, hierarchy, and level return its localized caption. The <var>pPropName</var> may be
/// used to reference either a property or a pre-defined &lt;member&gt; element.
ClassMethod %GetMemberCaption(pDimName As %String, pHierName As %String = "", pLevelName As %String = "", pPropName As %String = "") As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	Set tSC = $$$OK
	Try {
		Do %code.WriteLine(" Set tCaption = """"")
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Quit
		}

		Do %code.WriteLine(" Set pDimName = $$$UPPER(pDimName)")
		Do %code.WriteLine(" Set pHierName = $$$UPPER(pHierName)")
		Do %code.WriteLine(" Set pLevelName = $$$UPPER(pLevelName)")
		Do %code.WriteLine(" Set pPropName = $$$UPPER(pPropName)")

		// first check captions global
		// (if %dsCaptionContext is defined)
		Set tCubeName = $$$UPPER($G(^||%Cls(%compiledclass.Name,"cubeName")))
		Do %code.WriteLine(" If ($G(%dsCaptionContext)'="""") {")
		Do %code.WriteLine("  If (pDimName'="""") {")
		Do %code.WriteLine("   If (pHierName="""") {")
		Do %code.WriteLine("    Set tCaption = $G(^DeepSee.Captions(%dsCaptionContext,"_$$$quote(tCubeName)_",pDimName))")
		Do %code.WriteLine("   }")
		Do %code.WriteLine("   Else {")
		Do %code.WriteLine("    If (pLevelName="""") {")
		Do %code.WriteLine("     Set tCaption = $G(^DeepSee.Captions(%dsCaptionContext,"_$$$quote(tCubeName)_",pDimName,pHierName))")
		Do %code.WriteLine("    }")
		Do %code.WriteLine("    Else {")
		Do %code.WriteLine("     If (pPropName="""") {")
		Do %code.WriteLine("      Set tCaption = $G(^DeepSee.Captions(%dsCaptionContext,"_$$$quote(tCubeName)_",pDimName,pHierName,pLevelName))")
		Do %code.WriteLine("     }")
		Do %code.WriteLine("     Else {")
		Do %code.WriteLine("      Set tCaption = $G(^DeepSee.Captions(%dsCaptionContext,"_$$$quote(tCubeName)_",pDimName,pHierName,pLevelName,pPropName))")
		Do %code.WriteLine("     }")
		Do %code.WriteLine("    }")
		Do %code.WriteLine("   }")
		Do %code.WriteLine("  }")
		Do %code.WriteLine(" If (tCaption'="""") Quit tCaption")
		Do %code.WriteLine(" }")

		// test for count measure
		Do %code.WriteLine(" If (pDimName = ""MEASURES"") {")
		Do %code.WriteLine("  Set tCountName = ..%GetCountName()")
		Do %code.WriteLine("  If (pHierName = $$$UPPER(tCountName)) {")
		Do %code.WriteLine("   Set tCountCaption = ..%GetCountCaption()")
		Do %code.WriteLine("   Quit $S(tCountCaption="""":$S(tCountName=""%COUNT"":""Count"",1:tCountName),1:tCountCaption)")
		Do %code.WriteLine("  }")
		Do %code.WriteLine(" }")

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Merge tCaptions = ^||%Cls(%compiledclass.Name,"captions")
		// tCaptions(d,h,l...) = $LB(name, displayName)

		Set tDimTest = "If"
		Set tDimName = $O(tCaptions(""))
		While (tDimName '= "") {
			Do %code.WriteLine(" "_tDimTest_" (pDimName="_$$$quote($$$UPPER(tDimName))_") {")
			Set tDimTest = "ElseIf"

			Do %code.Write("  If ((pHierName="""")&&(pLevelName="""")) {")

			If ($LG($G(tCaptions(tDimName)),2)'="") {
				If (tLocalize) {
					Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG(tCaptions(tDimName),2))_","_$$$quote(DOMAIN)_") }")
				}
				Else {
					Do %code.WriteLine(" Quit "_$$$quote($LG(tCaptions(tDimName),2))_" }")
				}
			}
			Else {
				Do %code.WriteLine(" Quit "_$$$quote($LG($G(tCaptions(tDimName)),1))_" }")
			}
			
			Set tHierName = $O(tCaptions(tDimName,""))
			While (tHierName '= "") {
				Do %code.WriteLine("  ElseIf (pHierName="_$$$quote($$$UPPER(tHierName))_") {")

				Do %code.Write("   If (pLevelName="""") {")

				If ($LG($G(tCaptions(tDimName,tHierName)),2)'="") {
					If (tLocalize) {
						Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG(tCaptions(tDimName,tHierName),2))_","_$$$quote(DOMAIN)_")"_" }")
					}
					Else {
						Do %code.WriteLine(" Quit "_$$$quote($LG(tCaptions(tDimName,tHierName),2))_" }")
					}
				}
				Else {
					Do %code.WriteLine(" Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName)),1))_" }")
				}

				Set tLevelName = $O(tCaptions(tDimName,tHierName,""))
				While (tLevelName '= "") {
					Set tPropName = $O(tCaptions(tDimName,tHierName,tLevelName,""))
					Set tHasProps = (tPropName '= "")

					Do %code.WriteLine("   ElseIf (pLevelName="_$$$quote($$$UPPER(tLevelName))_") {")
					Do:tHasProps %code.WriteLine("    If (pPropName="""") {")
					If ($LG($G(tCaptions(tDimName,tHierName,tLevelName)),2)'="") {
						If (tLocalize) {
							Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG(tCaptions(tDimName,tHierName,tLevelName),2))_","_$$$quote(DOMAIN)_")")
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG(tCaptions(tDimName,tHierName,tLevelName),2)))
						}
					}
					Else {
						// JMD817
						If (tLocalize) {
							Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName)),1))_","_$$$quote(DOMAIN)_")")
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName)),1)))
						}
					}
					Do %code.WriteLine("    }")

					While (tPropName '= "") {
						Do %code.WriteLine("    ElseIf (pPropName="_$$$quote($$$UPPER(tPropName))_") {")
						If ($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),2)'="") {
							If (tLocalize) {
								Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG(tCaptions(tDimName,tHierName,tLevelName,tPropName),2))_","_$$$quote(DOMAIN)_")")
							}
							Else {
								Do %code.WriteLine("     Quit "_$$$quote($LG(tCaptions(tDimName,tHierName,tLevelName,tPropName),2)))
							}
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tCaptions(tDimName,tHierName,tLevelName,tPropName)),1)))
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
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do %code.WriteLine(" Quit tCaption")
	Quit tSC
}

/// For a given dimension, hierarchy, and level return its localized description. The <var>pPropName</var> may be
/// used to reference either a property or a pre-defined &lt;member&gt; element.
ClassMethod %GetMemberDescription(pDimName As %String, pHierName As %String = "", pLevelName As %String = "", pPropName As %String = "") As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	/// This code added as part of JSL4475
	Set tSC = $$$OK
	Try {
		Do %code.WriteLine(" Set tDescription = """"")
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Quit
		}

		Do %code.WriteLine(" Set pDimName = $$$UPPER(pDimName)")
		Do %code.WriteLine(" Set pHierName = $$$UPPER(pHierName)")
		Do %code.WriteLine(" Set pLevelName = $$$UPPER(pLevelName)")
		Do %code.WriteLine(" Set pPropName = $$$UPPER(pPropName)")

		Set tCubeName = $$$UPPER($G(^||%Cls(%compiledclass.Name,"cubeName")))

		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
		}

		Merge tDescriptions = ^||%Cls(%compiledclass.Name,"descriptions")
		// tDescriptions(d,h,l...) = $LB(name, displayName)

		Set tDimTest = "If"
		Set tDimName = $O(tDescriptions(""))
		While (tDimName '= "") {
			Do %code.WriteLine(" "_tDimTest_" (pDimName="_$$$quote($$$UPPER(tDimName))_") {")
			Set tDimTest = "ElseIf"

			Do %code.Write("  If ((pHierName="""")&&(pLevelName="""")) {")

			If ($LG($G(tDescriptions(tDimName)),1)'="") {
				If (tLocalize) {
					Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG(tDescriptions(tDimName),1))_","_$$$quote(DOMAIN)_") }")
				}
				Else {
					Do %code.WriteLine(" Quit "_$$$quote($LG(tDescriptions(tDimName),1))_" }")
				}
			}
			Else {
				Do %code.WriteLine(" Quit "_$$$quote($LG($G(tDescriptions(tDimName)),1))_" }")
			}
			
			Set tHierName = $O(tDescriptions(tDimName,""))
			While (tHierName '= "") {
				Do %code.WriteLine("  ElseIf (pHierName="_$$$quote($$$UPPER(tHierName))_") {")

				Do %code.Write("   If (pLevelName="""") {")

				If ($LG($G(tDescriptions(tDimName,tHierName)),1)'="") {
					If (tLocalize) {
						Do %code.WriteLine(" Quit $$$Text("_$$$quote($LG(tDescriptions(tDimName,tHierName),1))_","_$$$quote(DOMAIN)_")"_" }")
					}
					Else {
						Do %code.WriteLine(" Quit "_$$$quote($LG(tDescriptions(tDimName,tHierName),1))_" }")
					}
				}
				Else {
					Do %code.WriteLine(" Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName)),1))_" }")
				}

				Set tLevelName = $O(tDescriptions(tDimName,tHierName,""))
				While (tLevelName '= "") {
					Set tPropName = $O(tDescriptions(tDimName,tHierName,tLevelName,""))
					Set tHasProps = (tPropName '= "")

					Do %code.WriteLine("   ElseIf (pLevelName="_$$$quote($$$UPPER(tLevelName))_") {")
					Do:tHasProps %code.WriteLine("    If (pPropName="""") {")
					If ($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1)'="") {
						If (tLocalize) {
							Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG(tDescriptions(tDimName,tHierName,tLevelName),1))_","_$$$quote(DOMAIN)_")")
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG(tDescriptions(tDimName,tHierName,tLevelName),1)))
						}
					}
					Else {
						// JMD817
						If (tLocalize) {
							Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1))_","_$$$quote(DOMAIN)_")")
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName)),1)))
						}
					}
					Do %code.WriteLine("    }")

					While (tPropName '= "") {
						Do %code.WriteLine("    ElseIf (pPropName="_$$$quote($$$UPPER(tPropName))_") {")
						If ($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1)'="") {
							If (tLocalize) {
								Do %code.WriteLine("     Quit $$$Text("_$$$quote($LG(tDescriptions(tDimName,tHierName,tLevelName,tPropName),1))_","_$$$quote(DOMAIN)_")")
							}
							Else {
								Do %code.WriteLine("     Quit "_$$$quote($LG(tDescriptions(tDimName,tHierName,tLevelName,tPropName),1)))
							}
						}
						Else {
							Do %code.WriteLine("     Quit "_$$$quote($LG($G(tDescriptions(tDimName,tHierName,tLevelName,tPropName)),1)))
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
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do %code.WriteLine(" Quit tDescription")
	Quit tSC
}

/// Return the list of cell-cache values that should be pre-loaded.
/// On return <var>pList</var> will contain an array of the form:<br/>
/// pList(n,spec) = factNo<br/>
ClassMethod %GetCellCachePreLoads(Output pList) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %GetModel, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (%class.Abstract || (%class.Name = "%DeepSee.CubeDefinition")) {
			Quit
		}

		#; find XDATA block named CellCache
		Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||CellCache")
		Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))

		If ((tCubeName'="")&&(tIndex '= "")) {
			#; get XDATA as stream
			Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
			Do tStream.Rewind()

			If (tStream.Size > 0) {
				#; render the stream into cube meta-data object (with children)
				Set tReader = ##class(%XML.Reader).%New()

				Set tSC = tReader.OpenStream(tStream)
				If $$$ISERR(tSC) Quit

				Do tReader.Correlate("cellCache","%DeepSee.Model.cellCache")

				#; there should only be one cellCache defined
				Do tReader.Next(.tCache,.tSC)
				If $$$ISERR(tSC) Quit
				If '$IsObject(tCache) {
					Set tSC = $$$ERROR($$$GeneralError,"No <cellCache> element defined in CellCache block.")
					Quit
				}

				#; is cache disabled?
				If (tCache.disabled) {
					Write !,$$$FormatText($$$Text("CellCache is disabled","%DeepSee"))
					Quit
				}

				#; walk down cache spec and generate code
				Set tCount = 0
				For g = 1:1:tCache.cellGroups.Count() {
					Set tGroup = tCache.cellGroups.GetAt(g)
					If ('tGroup.disabled) {
						Set tGroupName = $S(tGroup.name="":"group"_g,1:tGroup.name)
						Set tCount = tCount + 1
						For i = 1:1:tGroup.items.Count() {
							Set tItem = tGroup.items.GetAt(i)
							If ('tItem.disabled) {
								Set tFactList = ""
								// user may have defined facts or specifications: deal with both
								For e = 1:1:tItem.elements.Count() {
									Set tSpec = tItem.elements.GetAt(e)
									Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeName,tSpec,.tDNO,.tHNO,.tLNO)
									If $$$ISERR(tSC) {
										Set tSC = $$$ERROR($$$GeneralError,"Invalid cell specification within cell cache definition: " _ tSpec)
										Quit
									}
									
									If (tDNO<0) {
										// DTB211 - A dimension number of <1 is returned for calcMbrs, qualMsrs, and namedSets. There is no 
										// processing of MDX in the computation of the cell cache, so these cannot be generally resolved.
										Set tSC = $$$ERROR($$$GeneralError,"Unsupported cell specification within cell cache definition: " _ tSpec)
										Quit
									}

									Set tNode = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"mbr#",tDNO,tHNO,tLNO))
									Set tFactNo = $LG(tNode,5)

									If ($E(tFactNo,1,1)="M") {
										Set tFactName = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"msr#",tFactNo))
									}
									Else {
										Set tFactName = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"fact#",tFactNo))
									}
									Set tFactList = tFactList _ $S(tFactList="":"",1:",") _ tFactName
								}
								For f = 1:1:tItem.facts.Count() {
									Set tFactName = tItem.facts.GetAt(f)
									If ('$D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"fact","prop",tFactName))) {
										Set tSC = $$$ERROR($$$GeneralError,"Invalid fact name within cube definition: " _ tFactName)
										Quit
									}
									Set tFactList = tFactList _ $S(tFactList="":"",1:",") _ tFactName
								}
								Do %code.WriteLine(" Set pList("_$$$quote($$$UPPER(tGroupName))_","_+i_") = "_$$$quote(tFactList))
							}
						}
					}
					If $$$ISERR(tSC) Quit
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do %code.WriteLine(" Quit $$$OK")
	Quit tSC
}

/// Build the entire fact table with data from the source table.<br/>
/// If <var>pVerbose</var> is true, then status information is written to the console.<br/>
/// Users should not call this method; they should used the %BuildCube method
/// in the <class>%DeepSee.Utils</class> class.
ClassMethod %BuildFactTable(pVerbose As %Boolean = 0, pFactList As %String = "") As %Status [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnProcessFact), Internal ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	// JMD1137
	Do %code.WriteLine(" Set tSC = ..%OnBuildCube(pFactList)")		// DTB891 - Pass the fact list into the user callback
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

	// Dispatch to Fact table
	Set tFactName = %class.Name_".Fact"
	Do %code.WriteLine(" Set tSC = ##class("_tFactName_").%BuildAllFacts(pVerbose,pFactList)")		// DTB891 - Pass the fact list
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

	// Invalidate the cube's result cache.
	Do %code.WriteLine(" Set tSC = ..%KillCache()")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Update Fact indices with data from the source table.<br/>
/// Read all rows from the source table between <var>pStartId</var> and 
/// <var>pEndId</var>.<br/>
/// If <var>pEndId</var> is missing (""), then update one fact with source id <var>pStartId</var><br/>.
/// If <var>pVerbose</var> is true, then write status information to the console.<br/>
/// <var>pTaskGroup</var> is used when this method is called by the DeepSee TaskMaster.<br/>
/// If <var>pBatchMode</var> is true, then perform the update in batch mode.<br/>
ClassMethod %UpdateFacts(pStartId As %String, pEndId As %String = "", pBatchMode As %Boolean = 0, pVerbose As %Boolean = 0, pTaskGroup As %String = "", Output pUpdates As %Integer, pRefProp As %String = "", pRefID As %String = "", ByRef pDimTables) As %Status [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnProcessFact) ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set tSC = $$$OK")

	// Dispatch to Fact table
	Set tFactName = %class.Name_".Fact"
	Do %code.WriteLine(" Set tSC = ##class("_tFactName_").%UpdateFacts(pStartId,pEndId,pBatchMode,.tChunks, pVerbose,pTaskGroup,.pUpdates,pRefProp,pRefID,.pDimTables)")
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

	// Invalidate the needed portions of this cube's result cache.
	Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	If (tCubeName '= "") {
		Set tCubeName = $$$UPPER(tCubeName)

		// invalidate buckets
		Do %code.WriteLine(" Set tSC = ##class(%DeepSee.Query.Engine).%InvalidateBuckets("_$$$quote(tCubeName)_","_$$$quote(tFactName)_",.tChunks)")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

		// update cube timestamp
		Set tResultsGLVN = $Name($$$DeepSeeResultsGLVN(tCubeName))
		Do %code.WriteLine(" #; update cube timestamp")
		Do %code.WriteLine(" Set tTimeStamp = $I("_tResultsGLVN_")")
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Update Fact indices with data from selected columns in the source table.<br/>
/// The fact list is limited using the <var>pFactList</var> parameter, which can be either a comma-delimited list or a $LB.
/// Read all rows from the source table between <var>pStartId</var> and 
/// <var>pEndId</var>.<br/>
/// If <var>pEndId</var> is missing (""), then update one fact with source id <var>pStartId</var><br/>.
/// If <var>pVerbose</var> is true, then write status information to the console.<br/>
/// <var>pTaskGroup</var> is used when this method is called by the DeepSee TaskMaster.<br/>
/// If <var>pBatchMode</var> is true, then perform the update in batch mode.<br/>
ClassMethod %UpdateFactsList(pFactList As %String = "", pStartId As %String, pEndId As %String = "", pBatchMode As %Boolean = 0, pVerbose As %Boolean = 0, pTaskGroup As %String = "", Output pUpdates As %Integer, pRefProp As %String = "", pRefID As %String = "", ByRef pDimTables) As %Status [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnProcessFact) ]
{
	// Method added by DTB886
	Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	Set tCubeName = $$$UPPER(tCubeName)
	
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	If $D($$$DeepSeeMetaGLVN("cubes",tCubeName))&&'$G($$$DeepSeeMetaGLVN("cubes",tCubeName,"namedFactNums")) {
		// DTB886 - Consult the namedFactNums setting for this cube and quit with an error if it is not enabled
		Do %code.WriteLine(" Quit $$$ERROR($$$GeneralError,""%UpdateFactsList cannot be called without enabling namedFactNums for this cube."")")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Try {")
	// DTB886 - Pre-process the incoming pFatList to normalize as a $lb for the internal methods 
	Do %code.WriteLine("  Set tFactList = $S($ListValid(pFactList):pFactList,1:$ListFromString(pFactList,"",""))")
	// Dispatch to Fact table
	Set tFactName = %class.Name_".Fact"
	Do %code.WriteLine("  Set tSC = ##class("_tFactName_").%UpdateFacts(pStartId,pEndId,pBatchMode,.tChunks, pVerbose,pTaskGroup,.pUpdates,pRefProp,pRefID,.pDimTables,tFactList)")
	Do %code.WriteLine("  If $$$ISERR(tSC) Quit")

	// Invalidate the needed portions of this cube's result cache.
	If (tCubeName '= "") {
		// invalidate buckets
		Do %code.WriteLine("  Set tSC = ##class(%DeepSee.Query.Engine).%InvalidateBuckets("_$$$quote(tCubeName)_","_$$$quote(tFactName)_",.tChunks)")
		Do %code.WriteLine("  If $$$ISERR(tSC) Quit")

		// update cube timestamp
		Set tResultsGLVN = $Name($$$DeepSeeResultsGLVN(tCubeName))
		Do %code.WriteLine("  #; update cube timestamp")
		Do %code.WriteLine("  Set tTimeStamp = $I("_tResultsGLVN_")")
	}
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Catch ex {")
	Do %code.WriteLine("   Set tSC = ex.AsStatus()")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Delete facts from this cube that correspond to rows in the source table with source id <var>pSourceId</var><br/>.
/// If <var>pVerbose</var> is true, then write status information to the console.<br/>
ClassMethod %DeleteFact(pSourceId As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnProcessFact) ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	// Dispatch to Fact table
	Set tFactName = %class.Name_".Fact"

	Do %code.WriteLine(" Set tSC = ##class("_tFactName_").%DeleteFact(pSourceId,.tFactId)")
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")
	Do %code.WriteLine(" Set:(tFactId'="""") tChunks(tFactId\64000+1)=""""")

	// Invalidate the needed portions of this cube's result cache.
	Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	If (tCubeName '= "") {
		Set tCubeName = $$$UPPER(tCubeName)

		// invalidate buckets
		Do %code.WriteLine(" Set tSC = ##class(%DeepSee.Query.Engine).%InvalidateBuckets("_$$$quote(tCubeName)_","_$$$quote(tFactName)_",.tChunks)")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

		// update cube timestamp
		Set tResultsGLVN = $Name($$$DeepSeeResultsGLVN(tCubeName))
		Do %code.WriteLine(" #; update cube timestamp")
		Do %code.WriteLine(" Set tTimeStamp = $I("_tResultsGLVN_")")
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Check to make sure a given ID exists in the source table.<br/>
ClassMethod %CheckSourceId(pSourceId As %String, pVerbose As %Boolean = 0, pStatus As %Status) As %Boolean [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnProcessFact) ]
{
	// Method added by DTB422
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	// Dispatch to Fact table
	Set tFactName = %class.Name_".Fact"

	Do %code.WriteLine(" Quit ##class("_tFactName_").%CheckSourceId(pSourceId,pVerbose,.pStatus)")
	Quit $$$OK
}

/// Find the starting and ending id values for this cube's source data class.<br/>
/// This is used when populating an entire cube.
ClassMethod %GetSourceIds(Output pStartId As %String, Output pEndId As %String) As %Status [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnGetSourceIds), Internal ]
{
	Do %code.WriteLine(" Set (pStartId,pEndId)=""""")
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}
	// invoke %OnGetSourceIds if present
	If ($$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSmethod,"%OnGetSourceIds",$$$cMETHrunnable)) {
		Do %code.WriteLine("   Quit ..%OnGetSourceIds(.pStartId,.pEndId)")
		Quit $$$OK
	}

	Set tSourceType = $G(^||%Cls(%compiledclass.Name,"sourceType"))
	Set tSourceClass = $G(^||%Cls(%compiledclass.Name,"sourceClass"))
	If (tSourceClass '= "") {
		If ((tSourceType = "kpi")||(tSourceType = "worksheet")||(tSourceType = "metric")) {
			// skip
		}
		ElseIf (tSourceType = "persistent") {
			Set tTable = ##class(%DeepSee.Generator).%GetSQLTableName(tSourceClass)
			Do %code.WriteLine(" Set tSC = $$$OK")

			// find first, last id of source table
			Do %code.WriteLine(" &sql(SELECT MIN(%ID),MAX(%ID) INTO :pStartId,:pEndId FROM "_tTable_")")
			
			// +DTB495 - If the first and last IDs are null, double check to make sure there are truly no source records
			Do %code.WriteLine(" If (pStartId="""")&&(pEndId="""") {")
			Do %code.WriteLine("  &sql(SELECT TOP 1 %ID FROM "_tTable_" WHERE %NOINDEX %ID IS NOT NULL)")		// DTB672
			Do %code.WriteLine("  If (+$G(%ROWCOUNT)>0) {		// DTB495 - Double check that there are in fact zero source records.")
			Do %code.WriteLine(" Quit $$$ERROR($$$GeneralError,""Failure to determine first and last IDs in source table '"_$$$iscEscapeDblQuote(tTable)_"'. Check indices on the source."")") //APV003
			Do %code.WriteLine("  }")
			Do %code.WriteLine(" }")
			// -DTB495
		}
		Else {
			// dispatch to data source class
			Do %code.WriteLine(" Set tSC = ##class("_tSourceClass_").%OnGetSourceIds(.pStartId,.pEndId)")
		}
	}
	Else {
		Do %code.WriteLine(" Set tSC = $$$ERROR($$$GeneralError,""Cube is not enabled or does not have a valid source class"")")
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// If implemented, this method is called when a cube is being completely rebuilt *and*
/// the rebuild is not using parallel processing.<br/>
/// On return <var>pStartId</var> and <var>pEndId</var> must contain the first and last row id values
/// for this cube's source data table, such that a query of the form:<br/>
/// SELECT ... FROM SOURCE WHERE %ID BETWEEN pStartId AND pEndId<br/>
/// will return all the rows of the source table.<br/>
/// This gives the developer the opportunity to bypass the built-in query that fetchs these values.<br/>
ClassMethod %OnGetSourceIds(Output pStartId As %String, Output pEndId As %String) As %Status [ Abstract ]
{
}

/// Delete all cached values for this cube.
ClassMethod %KillCache() As %Status [ Final ]
{
	Set tSC = ..%KillCellCache()
	If $$$ISERR(tSC) Quit tSC
	Set tSC = ..%KillResultsCache()
	If $$$ISERR(tSC) Quit tSC

	Set tCube = $$$UPPER(..%GetCubeName())
	Kill $$$DeepSeeMaskGLVN(tCube)		// DTB989 - New cache global
	Kill $$$DeepSeeBucketsGLVN(tCube)
	Quit tSC
}

/// Delete the cell cache for this cube.
ClassMethod %KillCellCache() As %Status [ Final ]
{
	
	Kill $$$DeepSeeCellsGLVN($$$UPPER(..%GetCubeName()))
	Quit $$$OK
}

/// Delete the results cache for this cube.
ClassMethod %KillResultsCache() As %Status [ Final ]
{
	Set tCube = $$$UPPER(..%GetCubeName())
	// WAL295 -- Preserve cache timestamp
	Set tResultsCacheTimestamp = $G($$$DeepSeeResultsGLVN(tCube))
	Kill $$$DeepSeeAxisGLVN(tCube)
	Kill $$$DeepSeeResultsGLVN(tCube)
	Kill $$$DeepSeeListingGLVN(tCube)
	Kill $$$DeepSeeJoinGLVN(tCube)
	Kill ^DeepSee.IDList(tCube)		// DTB990 - The IDList is a cache used in some slicers
	Set:(tResultsCacheTimestamp'="") $$$DeepSeeResultsGLVN(tCube) = tResultsCacheTimestamp // WAL295
	// JMD900: kill KPI cache based on this cube
	Set tSC = ##class(%DeepSee.Utils).%KillKPICacheForCube(tCube) 
	Quit tSC
}

/// Delete all Facts as well as cached results from the cube.
ClassMethod %KillFacts() As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Try {")

	// star tables
	Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	If (tCubeName '= "") {
		Set tStar = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"star",""))
		While (tStar '= "") {
			// don't kill shared dimensions
			Set tShared = $G($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"star",tStar,"sharedCube"))
			If (tShared="") {
				Do %code.WriteLine(" Do ##class("_tStar_").%KillExtent()")
			}
			Set tStar = $O($$$DeepSeeMetaGLVN("cubes",$$$UPPER(tCubeName),"star",tStar))
		}
		
		// computed dimensions
		set tDim = 0
		for {
			set tDim = $order($$$DeepSeeMetaGLVN("cubes", $$$UPPER(tCubeName), "mbr#", tDim))
			quit:tDim=""
			set tHier = 0
			for {
				set tHier = $order($$$DeepSeeMetaGLVN("cubes", $$$UPPER(tCubeName), "mbr#", tDim, tHier))
				quit:tHier=""
				set tLevel = 0
				for {
					set tLevel = $order($$$DeepSeeMetaGLVN("cubes", $$$UPPER(tCubeName), "mbr#", tDim, tHier, tLevel), 1, tInfo)
					quit:tLevel=""
					set tDimClass = $lg(tInfo,6)
					if $$IsDerivedFrom^%occLibrary(tDimClass, "%DeepSee.ComputedDimension.Base") {
						do %code.WriteLine(" do ##class("_tDimClass_").%OnKillFacts("_$$$QUOTE(tCubeName)_", "_$lg(tInfo,5)_", "_tDim_", "_tHier_", "_tLevel_")")
					}
				}
			}
		}
	}

	// kill cache
	Do %code.WriteLine(" Set tSC = ..%KillCache()")
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit")

	// kill facts
	Do %code.WriteLine(" Set tSC = ##class("_%class.Name_".Fact).%KillExtent()")
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit")

	// kill source index and reverse source index
	Do %code.WriteLine(" Kill $$$DeepSeeIndexGLVN("_$$$quote($$$UPPER(tCubeName))_",""%sourceId"")")
	Do %code.WriteLine(" Kill $$$DeepSeeIndexGLVN("_$$$quote($$$UPPER(tCubeName))_",""%sourceIdReverse"")")
	// DP-403191 - Remove the index branch reserved for SQLRestrict
	Do %code.WriteLine(" Kill $$$DeepSeeIndexGLVN("_$$$quote($$$UPPER(tCubeName))_",-1)")

	// kill any streams stored for this cube
	Set tClassName = %class.Name_".Fact"
	Set tStreamGLVN = $Name($$$DeepSeeFactGLVN)_"S"
	Do %code.WriteLine(" Kill "_tStreamGLVN_"("_$$$quote($$$UPPER(tClassName))_")")
	
	// DTB163 - Clean up the previous relation index
	Do %code.WriteLine(" Kill $$$DeepSeeRelationGLVN("_$$$quote($$$UPPER(tCubeName))_")")
	// DTB990 - Clean up the update tracking
	Do %code.WriteLine(" Kill $$$DeepSeeUpdateQueue(""cubes"","_$$$quote($$$UPPER(tCubeName))_")")

	// notify fact table
	Do %code.WriteLine(" Set tSC = ##class("_%class.Name_".Fact).%OnKillFacts()")
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit")

	// invoke callback
	Do %code.WriteLine(" Set tSC = ..%OnKillFacts()")
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit")
	Do %code.WriteLine(" }")
	Do %code.WriteLine("  Catch(ex) {")
	Do %code.WriteLine("  Set tSC = ex.AsStatus()")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Notification that all facts have been deleted.<br/>
/// If implemented, this is called when the <method>%KillFacts</method> is called.
ClassMethod %OnKillFacts() As %Status
{
	Quit $$$OK
}

/// Notification that this cube is about to be built.<br/>
/// If the build is invoked using a selected <var>pFactList</var>, this list will be passed to the callback in a $LB format.
ClassMethod %OnBuildCube(pFactList As %List) As %Status
{
	Quit $$$OK
}

/// Notification that this cube has completed its build.<br/>
/// The status of the overall build is contained in <var>pBuildStatus</var>. If the build is otherwise successful, 
/// the value of <var>pBuildStatus</var> can be changed within the callback to become the new status returned by %BuildCube.
/// If there were any build errors in the individual facts the count of these errors is reported in 
/// <var>pBuildErrors</var>
ClassMethod %OnAfterBuildCube(pBuildStatus As %Status, pBuildErrors As %Boolean = 0) As %Status
{
	Quit $$$OK
}

/// Notification that a fact within the cube is to be processed (inserted
/// or updated).<br/>
/// <var>pID</var> is the id of the row in the source data being processed.<br/>
/// <var>pFacts</var> is an array containing the values that will be used for the
/// row, subscripted by fact name.<br/>
/// <var>pSkip</var> is a boolean value returned by reference; If true then the record
/// is not processed.<br/>
/// <var>pInsert</var> is true if the current fact will be inserted into the cube's fact table.
ClassMethod %OnProcessFact(pID As %String, ByRef pFacts As %String, Output pSkip As %Boolean, pInsert As %Boolean) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// Notification that a fact within the cube has been processed (inserted
/// or updated). This method does not allow for any intervention of the processing of the fact,
/// but rather provides an opportunity to react to success or failure in processing. The return status is ignored by the caller.<br/>
/// <var>pID</var> is the id of the row in the source data being processed.<br/>
/// <var>pFacts</var> is an array containing the values that will be used for the
/// row, subscripted by fact name.<br/>
/// <var>pUpdateStatus</var> is the status about to be returned by %ProcessFact. If an error is passed in, this error will
/// already be logged in the DeepSee logs and the ^DeepSee.BuildErrors global.
ClassMethod %OnAfterProcessFact(pID As %String, ByRef pFactArray As %String, pUpdateStatus As %Status) As %Status [ Abstract ]
{
	// Method added by DTB290
	Quit $$$OK
}

/// Return number of facts in this cube's fact table.
ClassMethod %GetFactCount() As %Integer
{
	Quit $zobjclassmethod(..%GetFactClass(),"%Count")
}

/// Return name of the fact class used by this cube.
ClassMethod %GetFactClass() As %String
{
	Quit ..%ClassName(1)_".Fact"
}

/// Return the approximate starting and ending id values for this cubes fact table.
ClassMethod %GetFactIdRange(Output pStartId As %Integer, Output pEndId As %Integer) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set pStartId = ""
		Set pEndId = ""
		Set tFactClass = ..%GetFactClass()
		If ($D($$$DeepSeeFactGLVN($$$UPPER(tFactClass)))) {
			Set pStartId = $O($$$DeepSeeFactGLVN($$$UPPER(tFactClass),""))
			Set pEndId = $$$DeepSeeFactGLVN($$$UPPER(tFactClass))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the logical name of the cube defined by this class (in its original case).
ClassMethod %GetCubeName() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"cubeName"))))
	Quit $$$OK
}

/// Test whether this cube is abstract or not.
ClassMethod %IsAbstract() As %Boolean [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Quit "_+$G(^||%Cls(%compiledclass.Name,"abstract")))
	Quit $$$OK
}

/// Test whether this cube is compound or not.
ClassMethod %IsCompound(Output pJoinList As %String) As %Boolean
{
	Set pJoinList = ""
	Quit 0
}

/// Return the caption of the cube defined by this class.
/// If not defined, the cube name is returned.
ClassMethod %GetCubeCaption() As %String [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
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

/// Return the precompute level of the cube defined by this class.
ClassMethod %GetPrecomputeLevel() As %Integer [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Set tPrecompute = +$G(^||%Cls(%compiledclass.Name,"precompute"))
	Do %code.WriteLine(" Quit "_tPrecompute)
	Quit $$$OK
}

/// Test if this cube supports drill through (listing) queries.
ClassMethod %CanDrillThrough() As %Boolean
{
	// see if any listings are available to the current user
	Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(..%GetCubeName(),.tListings)
	Quit $S($D(tListings):1,1:0)
}

/// Take cube relationship  with name <var>pRelationName</var>
/// and transform the original key value <var>pKey</var> into
/// the id of the corresponding fact in the fact table and return it
/// via <var>pID</var>.
ClassMethod %GetRelationshipId(pRelationName As %String, pKey As %String, Output pID As %Integer) As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetModel ]
{
	Do %code.WriteLine(" Set (pStartId,pEndId)=""""")
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Set pID = """"")

	Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	Set tCubeNameU = $$$UPPER(tCubeName)

	If (tCubeName = "") {
		Quit $$$OK
	}

	// walk down set of relations
	Set tCount = 0
	Set f = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"relations",""))
	While (f'="") {
		Set tStoredSide = +$G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"relations",f,"storedSide"))
		Set tRelName = $G($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"relations",f,"name"))
		If ('tStoredSide) {
			If (tCount = 0) {
				Do %code.Write(" If")
			}
			Else {
				Do %code.Write(" ElseIf")
			}
			Set tCount = tCount + 1
			Do %code.WriteLine(" ($$$UPPER(pRelationName)=" _ $$$quote($$$UPPER(tRelName)) _ ") {")

			Do %code.WriteLine(" }")
		}
		Set f = $O($$$DeepSeeMetaGLVN("cubes",tCubeNameU,"relations",f))
	}

	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Notification that a listing (drillthrough) query is about to be executed.<br/>
/// This is called immediately before a listing query is executed.
/// This is useful for cases where additional setup work is required before
/// a listing query can run.<br/>
/// <var>pSQL</var> is the listing query that will be executed.
ClassMethod %OnExecuteListing(pSQL As %String) As %Status
{
	Quit $$$OK
}

/// Return the filter spec for this cube, if any.
ClassMethod %GetFilterSpec() As %String [ Final ]
{
	If '$D(%dsUserName) {
		// DTB687 - If this does not exist, make sure it is set
		New %dsUserName
		Set %dsUserName = $UserName
	}
	
	Set tFilter = ..%OnGetFilterSpec("")
	Quit tFilter
}

/// This callback gives a Cube a chance to programmatically define a filter spec.
ClassMethod %OnGetFilterSpec(pFilterSpec As %String) As %String
{
	Quit pFilterSpec
}

/// Return the name of the default listing for this cube, if any.
ClassMethod %GetDefaultListing() As %String [ Final ]
{
	Quit ..%OnGetDefaultListing()
}

/// This callback gives a cube a chance to programmatically return the name 
/// of the listing to use as its default listing.
/// This must be the name of a defined listing within the cube.
/// Return "" to use the pre-defined default listing.
ClassMethod %OnGetDefaultListing() As %String
{
	Quit ""
}

/// Return list of possible actions for this Cube.
/// This list is supplied from the KPI class specified by the cube's actionClass property, if defined.
/// This drives the list of action selections for widget connected to this cube.
/// This takes the form:<br/>
/// pActions(n)=$LB(name,caption)<br/>
ClassMethod %GetActionList(ByRef pActions As %List) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tCubeName = $$$UPPER(..%GetCubeName())
		Set tActionClass = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"actionClass"))
		If (tActionClass'="") {
			Set tSC = $zobjclassmethod(tActionClass,"%GetActionList",.pActions)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Inject a fact into the fact table for this cube that is not associated with the source data table.<br/>
/// <var>pFactId</var> is the id of the fact in the fact table. Set this to "" for an insert. On return
/// it will contain the id used for the fact.<br/>
/// <var>pValues</var> is an array of fact values subscripted by sourceProperty name (case must match <b>exactly</b>.
/// If <var>pDimensionsOnly</var> is true, then only the dimension tables for the cube are affected;
/// no facts are inserted.
ClassMethod %InjectFact(ByRef pFactId As %String, ByRef pValues As %String, pDimensionsOnly As %Boolean = 0, pFactList As %String = "") As %Status [ CodeMode = objectgenerator, GenerateAfter = (%GetModel, %OnProcessFact) ]
{
	// JMD1137 add pDimensionsOnly
	// DTB886 - Add pFactList
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit $$$OK")
		Quit $$$OK
	}

	Do %code.WriteLine(" Set tSC = $$$OK")
	
	// DTB893
	Do %code.WriteLine(" Set tFactList = $S($ListValid(pFactList):pFactList,1:$ListFromString(pFactList,"",""))")

	// Dispatch to Fact table
	Set tFactName = %class.Name_".Fact"
	Do %code.WriteLine(" Set tSC = ##class("_tFactName_").%InjectFact(.pFactId,.pValues,.tChunks,pDimensionsOnly,tFactList)")		// DTB893 - Use tFactList
	Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

	Do %code.WriteLine(" If ('pDimensionsOnly) {")

	// Invalidate the needed portions of this cube's result cache.
	Set tCubeName = $G(^||%Cls(%compiledclass.Name,"cubeName"))
	If (tCubeName '= "") {
		Set tCubeName = $$$UPPER(tCubeName)

		// invalidate buckets
		Do %code.WriteLine("  Set tSC = ##class(%DeepSee.Query.Engine).%InvalidateBuckets("_$$$quote(tCubeName)_","_$$$quote(tFactName)_",.tChunks)")
		Do %code.WriteLine("  If $$$ISERR(tSC) Quit tSC")

		// update cube timestamp
		Set tResultsGLVN = $Name($$$DeepSeeResultsGLVN(tCubeName))
		Do %code.WriteLine("  #; update cube timestamp")
		Do %code.WriteLine("  Set tTimeStamp = $I("_tResultsGLVN_")")
	}
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Callback used for XSL transforms.
ClassMethod %OnGetModel(pXSL As %String, tSource As %Stream.TmpCharacter, Output tOutput As %BinaryStream) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		// Get a stream of XSL from the XSL block contained in this class
		Set tXSL=##class(%Dictionary.CompiledXData).%OpenId(pXSL).Data
		If '$IsObject(tXSL) Set tSC=%objlasterror Quit

		// Transform the source according to the XSL
		Set tSC=##class(%XML.XSLT.Transformer).TransformStream(tSource,tXSL,.tOutput)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// If implemented, this is called before the cube model is processed.
/// It gives the class a change to modify the ^DeepSee.Overrides global.
ClassMethod %OnApplyOverrides() As %Status [ CodeMode = objectgenerator ]
{
	Quit $$$OK
}

/// Lookup a single value with the given key and DeepSee term list name.
/// This can be invoked by source expressions within this cube.<br/>
/// <var>pTermList</var> is the name (with no extension) of the termlist.<br/>
/// <var>pKey</var> is the key to lookup within the termlist.<br/>
/// <var>pDefault</var> is an optional default value to return if the key is not found within the termlist.<br/>
/// <var>pField</var> is an optional field to lookup within the termlist. By default, this is the "value" field.<br/>
ClassMethod %Lookup(pTermList As %String = "", pKey As %String = "", pDefault As %String, pField As %String = "VALUE") As %String
{
	// Return original value if key is not in table
	If '$D(pDefault) {
		Set pDefault = pKey
	}
	Quit ##class(%DeepSee.TermList).%Lookup(pTermList,pKey,pField,pDefault)
}

/// Invoke a Business Rule on the current record within the source class.
/// <var>pID</var> should contain the object id of the record within the source class.
/// This can be invoked by source expressions within this cube.
ClassMethod %Rule(pRuleName As %String = "") As %String
{
	Set tValue = ""
	Set tSC = $$$OK
	Try {
		Do ..%GetSourceInfo(.tInfo)
		Set tSourceClass = $G(tInfo("sourceClass"))
		If $$$ISERR(tSC) Quit

		// open instance of source class
		// use sourceId in context
		// share open object
		If (('$IsObject($G(%dsSourceObj)))||(%dsSourceObj.%Id()'=$G(%dsSourceId))) {
			Set %dsSourceObj = $classmethod(tSourceClass,"%OpenId",$G(%dsSourceId))
		}
		If $IsObject(%dsSourceObj) {
			// invoke rule
			Set tSessionId = 1
			Set tSC = ##class(Ens.Rule.Definition).EvaluateRules(pRuleName,tSessionId,%dsSourceObj,"DeepSee",.tValue, .tReason)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		// JMD920
		Set tText = $System.Status.GetErrorText(tSC)
		Do ##class(%DeepSee.Utils).%WriteToLog("Rule","Error in %Rule " _ tText)

		// return error code
		Set tValue = $System.Status.GetErrorText(tSC)
	}

	Quit tValue
}

/// This callback gives a Cube a chance to programmatically provide a set of
/// members for a computed dimension.<br/>
/// Find the set of members for this computed dimension object satisfying
/// <var>pRollupKey</var> and <var>pRange</var> (if applicable for this implementation).<br/>
/// This is passed and returns:<br/>
/// pMemberList($I(pMemberList)) = $LB(id (expression for MDX computed dimension),caption,key,[format])<br/>
ClassMethod %OnGetComputedMembers(pDimName As %String, pHierName As %String, pLevelName As %String, ByRef pMemberList, pRollupKey As %String = "", ByRef pRange As %String = "") As %Status
{
	Quit $$$OK
}

}
