/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a dimension within a DeepSee cube.
/// Subclasses of this class are used to implement specific
/// types of dimension.
Class %DeepSee.Model.dimension Extends node [ System = 3 ]
{

/// Cube that this dimension belongs to.
Relationship cube As %DeepSee.Model.cube(XMLPROJECTION = "none") [ Cardinality = one, Inverse = dimensions ];

/// Optional. If true, this is the name of another, pre-existing, cube that this 
/// dimension shares from. This means that the other cube has a dimension of the same name
/// and that the dimensional tables of the other cube are used to track members of the dimension
/// in *this* cube.
Property sharesFrom As %DeepSee.Datatype.entityName(XMLPROJECTION = "attribute");

/// Indicates whether this dimension has an "All" level.<br/>
/// The default is true.
Property hasAll As %Library.Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Optional. Specifies the name used for the All level for this dimension.
/// If not provided, then "All" + dimension name is used.
Property allCaption As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional. Specifies the localized name used for the All level for this dimension.
/// If defined, this is the text displayed by DeepSee applications,
/// otherwise the <property>allCaption</property> is used.
Property allDisplayName As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Name of the property in the source data that provides the
/// value for this element.<br/>
/// If specified, this is used as a default value for any
/// level within this dimension that does not explicitly define
/// a sourceProperty.<br/>
/// For time dimensions, this property must be defined.<br/>
/// Using dot syntax, it is possible to refer to a property within
/// a related class, for example "City.Name" or "City.State.Name".
Property sourceProperty As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional expression used to get the value of this member.<br/>
/// This can refer to properties of the source table using the
/// syntax: "%source.Property".
Property sourceExpression As %ZEN.Datatype.expression(LANGUAGE = "OBJECTSCRIPT", XMLPROJECTION = "attribute");

/// For shared dimensions, this is used to track a local override of this property on the
/// sharing side.
Property localSourceProperty As %DeepSee.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// For shared dimensions, this is used to track a local override of this property on the
/// sharing side.
Property localSourceExpression As %ZEN.Datatype.expression(LANGUAGE = "OBJECTSCRIPT", XMLPROJECTION = "none") [ Internal ];

/// Specifies what type of dimension this is.<br/>
/// The type can be one of the following:
/// <ul>
/// <li>"measures" - reserved.</li>
/// <li>"data" - this dimension is based on data values supplied from a source property or expression.
/// One or more dimension tables are generated to hold the set of possible values.</li>
/// <li>"time" - this dimension is based on time values. No dimension tables are generated, instead
/// the hierarchy of time classes are used to process the values for this dimension.</li>
/// <li>"age" - similar to "time" except that
/// the hierarchy of age classes are used to process the values for this dimension.</li>
/// <li>"computed" - a computed dimension that uses a special dimension class (<property>dimensionClass</property>) to process its values.</li>
/// <li>"iKnow" - a dimension that makes use of text processed by the iKnow Smart Indexing API. This must be linked to 
/// an "iKnow" measure (<property>iKnowMeasure</property>) which supplies the values for this dimension.</li>
/// </ul>
/// If not specified, then the type will be set to "data".<br/>
Property type As %DeepSee.Datatype.string(VALUELIST = ",measures,data,time,age,computed,iKnow", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "data" ];

/// Specifies which calendar is to be used if this is a time dimension
Property calendar As %DeepSee.Datatype.string(VALUELIST = ",gregorian,partial,hijriTabular,hijriObserved", XMLPROJECTION = "ATTRIBUTE");

/// Optional. For "computed" dimensions, this is the name of the class that provides the dimension
/// computation logic. This is an advanced feature that requires some expertise.<br/>
/// If the package name is omitted, then the "%DeepSee.ComputedDimension" package is used.
Property dimensionClass As %DeepSee.Datatype.string(XMLPROJECTION = "attribute") [ Internal ];

/// Optional. For "iKnow" dimensions, this is the name of the "iKnow" measure that provides the 
/// data for this dimension.
Property iKnowMeasure As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional. For "iKnow" dimensions, this provides a way to define the specific way in which
/// iKnow works with this dimension.
Property iKnowType As %DeepSee.Datatype.string(VALUELIST = ",entity,dictionary", XMLPROJECTION = "attribute");

/// Set of hierarchies defined for this dimension.<br/>
/// Via a set of levels, a hierarchy defines a way in which this dimension can roll up.
Relationship hierarchies As %DeepSee.Model.hierarchy(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = dimension ];

/// If true, this dimension is hidden. That is, it will not be listed among the
/// cube's members within the various DeepSee utilities.<br/>
/// It can still be used within MDX queries and expressions.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If "true", then always display this dimension's hierarchies within the Analyzer.
/// If "false", then never display hierarchies. If "default", then only show hierarchies if
/// there is more than one hierarchy.<br/>
/// This has no effect on the operation of the cube.
Property showHierarchies As %DeepSee.Datatype.string(VALUELIST = ",true,false,default", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "default" ];

/// Test if this dimension's definition is valid.
Method %Validate() As %Status
{
	Set tSC = $$$OK

	Try {
		Set tSourceProperty = $S(..localSourceProperty'="":..localSourceProperty,1:..sourceProperty)
		Set tSourceExpression = $S(..localSourceExpression'="":..localSourceExpression,1:..sourceExpression)

		If (..type = "time") {
			If ((tSourceProperty="")&&((tSourceExpression=""))) {
				Set tSC = $$$ERROR($$$GeneralError,"Time dimension must have a sourceProperty or sourceExpression attribute: " _ ..name)
				Quit
			}
			// check if source property exists
			If ((tSourceProperty'="")&&((tSourceExpression=""))) {
				Set tType = ##Class(%DeepSee.Generator).%GetPropertyType(.tSC, .tParms, ..cube.sourceClass,tSourceProperty,(..name))
				If ($$$ISERR(tSC)) {
					Set tSC = $$$ERROR($$$GeneralError,"Property referred to by sourceProperty not found (1). Dimension: "_..name_", property: "_tSourceProperty _ ", source: " _ ..cube.sourceClass)
					Quit
				}
			}
			If (..calendar="") {
				Set ..calendar = "gregorian"			// DTB181 - Set calendar for backwards compatibility
			}

		}
		ElseIf (..type = "age") {
			If ((tSourceProperty="")&&((tSourceExpression=""))) {
				Set tSC = $$$ERROR($$$GeneralError,"Age dimension must have a sourceProperty or sourceExpression attribute: " _ ..name)
				Quit
			}
			// check if source property exists
			If ((tSourceProperty'="")&&((tSourceExpression=""))) {
				Set tType = ##Class(%DeepSee.Generator).%GetPropertyType(.tSC, .tParms, ..cube.sourceClass,tSourceProperty,(..name))
				If ($$$ISERR(tSC)) {
					Set tSC = $$$ERROR($$$GeneralError,"Property referred to by sourceProperty not found (2). Dimension: "_..name_", property: "_tSourceProperty _ ", source: " _ ..cube.sourceClass)
					Quit
				}
			}
			If (..calendar="") {
				Set ..calendar = "gregorian"			// DTB184 - Set calendar for backwards compatibility
			}
		}
		ElseIf (..type = "computed") {
			If (..dimensionClass="") {
				Set tSC = $$$ERROR($$$GeneralError,"Computed dimension must specify a dimensionClass: " _ ..name)
				Quit
			}
			If (..dimensionClass'[".") {
				// add default package
				Set ..dimensionClass = "%DeepSee.ComputedDimension." _..dimensionClass
			}
			
			If ('$$$comClassDefined(..dimensionClass)) {
				Set tSC = $$$ERROR($$$GeneralError,"dimensionClass does not exist: " _ ..name _ ": " _ ..dimensionClass)
				Quit
			}
		}
		ElseIf (..type = "iKnow") {
			If (..iKnowMeasure="") {
				Set tSC = $$$ERROR($$$GeneralError,"iKnow dimension must specify an iKnowMeasure: " _ ..name)
				Quit
			}
			If (..dimensionClass'="") {
				Set tSC = $$$ERROR($$$GeneralError,"iKnow dimension must not specify a dimensionClass: " _ ..name)
				Quit
			}

			// make sure iknow measure exists
			Set tFound = 0
			For m=1:1:..cube.measures.Count() {
				Set tMsr = ..cube.measures.GetAt(m)
				If (('tMsr.disabled)&&(tMsr.name=..iKnowMeasure)&&(tMsr.type="iKnow")) {
					Set tFound = 1
					Quit
				}
			}

			If ('tFound) {
				Set tSC = $$$ERROR($$$GeneralError,"iKnow dimension must refer to a valid iKnow measure: " _ ..name)
				Quit
			}

			// set type and dimension
			Set ..type = "computed"

			// derive dimensionClass from iKnowType
			If (..iKnowType="") {
				Set tSC = $$$ERROR($$$GeneralError,"iKnow dimension must specify an iKnowType: " _ ..name)
				Quit
			}
			Set ..dimensionClass = $case(..iKnowType, "entity":"%iKnow.DeepSee.Dimensions.Entities", "dictionary":"%iKnow.DeepSee.Dimensions.Dictionaries")
		}

		Set tHCount = ..hierarchies.Count()
		Set tHCountActual = 0
		For h=1:1:tHCount {
			Set tHier = ..hierarchies.GetAt(h)
			If ('tHier.disabled) {
				Set tHCountActual = tHCountActual + 1
			}
		}

		If (tHCountActual<1) {
			Set tSC = $$$ERROR($$$GeneralError,"Dimension must have at least one enabled hierarchy: " _ ..name)
			Quit
		}
		For h=1:1:tHCount {
			Set tHier = ..hierarchies.GetAt(h)
			If (tHier.disabled) {
				Continue
			}
			If (tHier.name="") {
				Set tSC = $$$ERROR($$$GeneralError,"Missing name for hierarchy: " _ ..name)
				Quit
			}
			ElseIf ($D(tHierNames($$$UPPER(tHier.name)))) {
				Set tSC = $$$ERROR($$$GeneralError,"Duplicate hierarchy name: " _ ..name _ "." _ tHier.name)
				Quit
			}

			Set tHierNames($$$UPPER(tHier.name)) = ""
			Set tLvlCount = tHier.levels.Count()
			Set tLvlCountActual = 0
			Set tHierHasList = 0
			For lvl=1:1:tLvlCount {
				Set tLevel = tHier.levels.GetAt(lvl)
				If ('tLevel.disabled) {
					Set tLvlCountActual = tLvlCountActual + 1
				}

				Set:(tLevel.list) tHierHasList = 1,tListLevelName = tLevel.name
			}

			If (tLvlCountActual<1) {
				Set tSC = $$$ERROR($$$GeneralError,"Hierarchy must have at least one enabled level: " _ ..name _ "." _ tHier.name)
				Quit
			}
			If (tHierHasList)&&(tLvlCountActual>1) {
				// DP-412094 - Report the problem of having a list level in a hierarchywith other levels
				Set tSC = $$$ERROR($$$GeneralError,"A list-based level must be the only level in a hierarchy. Move " _ ..name _ "." _ tHier.name _ "." _ tListLevelName _ " to its own hierarchy")
				Quit
			}

			Kill tLevelNames
			Kill tLevelSource
			For lvl=1:1:tLvlCount {
				Set tLevel = tHier.levels.GetAt(lvl)
				If (tLevel.disabled) {
					Continue
				}

				Set tLevelSourceProperty = $S(tLevel.localSourceProperty'="":tLevel.localSourceProperty,1:tLevel.sourceProperty)
				Set tLevelSourceExpression = $S(tLevel.localSourceExpression'="":tLevel.localSourceExpression,1:tLevel.sourceExpression)

				If (tLevel.name="") {
					Set tSC = $$$ERROR($$$GeneralError,"Missing name for level: " _ ..name _ "." _ tHier.name)
					Quit
				}
				ElseIf ($D(tLevelNames($$$UPPER(tLevel.name)))) {
					Set tSC = $$$ERROR($$$GeneralError,"Duplicate level name: " _ ..name _ "." _ tHier.name _ "." _ tLevel.name)
					Quit
				}
				Set tLevelNames($$$UPPER(tLevel.name)) = ""

				If ((tLevel.factName'="")&&('$ZNAME(tLevel.factName)||(tLevel.factName["%"))) {
					Set tSC = $$$ERROR($$$GeneralError,"Level factName must contain a valid identifier: " _ ..name _ "." _ tHier.name _ "." _ tLevel.name)
					Quit
				}
				
				// DTB090 - do not allow factName that will mangle the star schema
				Set tBadFactNames("FACT") = ""
				Set tBadFactNames("LISTING") = ""
				If ((tLevel.factName'="")&&$Data(tBadFactNames($$$UPPER(tLevel.factName)))) {
					Set tSC = $$$ERROR($$$GeneralError,"Reserved word used for factName: '" _ tLevel.factName _ "' " _ ..name _ "." _ tHier.name _ "." _ tLevel.name)
					Quit
				}

				If (..type = "time") {
					If ((tLevelSourceProperty'="")||(tLevelSourceExpression'="")) {
						Set tSC = $$$ERROR($$$GeneralError,"Level in time dimension must not specify sourceProperty or sourceExpression: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					}
					ElseIf (tLevel.timeFunction = "") {
						Set tSC = $$$ERROR($$$GeneralError,"Level in time dimension must have a timeFunction: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					}
					ElseIf (tLevel.rangeExpression '= "") {
						Set tSC = $$$ERROR($$$GeneralError,"Level in time dimension cannot have a rangeExpression: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					}
					Else {
						Set tSC = ##class(%DeepSee.Generator).%ParseTimeFunction(tLevel.timeFunction,.tFuncName,.tOptions)
						Quit:$$$ISERR(tSC)
						If ('$D(..cube.%timeFunctions(..calendar,$$$UPPER(tFuncName)))) {		// DTB177 - Lookup by calendar
							Set tSC = $$$ERROR($$$GeneralError,"Level in time dimension refers to invalid or undefined timeFunction name. " _ ..name _ "."_ tHier.name_ "." _ tLevel.name _ " (" _ tFuncName _ ")")
							Quit
						}
						Else {
							// make sure this is a time class
							Set tTimeClass = ..cube.%timeFunctions(..calendar,$$$UPPER(tFuncName))		// DTB177 - Lookup by calendar
							If ($classmethod(tTimeClass,"%IsA","%DeepSee.Age.AbstractLevel")) {
								Set tSC = $$$ERROR($$$GeneralError,"Level in time dimension refers to an age function. " _ ..name _ "."_ tHier.name_ "." _ tLevel.name _ " (" _ tFuncName _ ")")
								Quit
							}
						}
					}
					If $$$ISERR(tSC) Quit
				}
				ElseIf (..type = "age") {
					If ((tLevelSourceProperty'="")||(tLevelSourceExpression'="")) {
						Set tSC = $$$ERROR($$$GeneralError,"Level in age dimension must not specify sourceProperty or sourceExpression: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					}
					ElseIf (tLevel.timeFunction = "") {
						Set tSC = $$$ERROR($$$GeneralError,"Level in age dimension must have a timeFunction: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					}
					ElseIf (tLevel.rangeExpression '= "") {
						Set tSC = $$$ERROR($$$GeneralError,"Level in age dimension cannot have a rangeExpression: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					}
					Else {
						Set tSC = ##class(%DeepSee.Generator).%ParseTimeFunction(tLevel.timeFunction,.tFuncName,.tOptions)
						Quit:$$$ISERR(tSC)
						If ('$D(..cube.%timeFunctions(..calendar,$$$UPPER(tFuncName)))) {		// DTB177 - Lookup by calendar
							Set tSC = $$$ERROR($$$GeneralError,"Level in age dimension refers to invalid or undefined timeFunction name. " _ ..name _ "."_ tHier.name_ "." _ tLevel.name _ " (" _ tFuncName _ ")")
							Quit
						}
						Else {
							// make sure this is an age class
							Set tTimeClass = ..cube.%timeFunctions(..calendar,$$$UPPER(tFuncName))		// DTB177 - Lookup by calendar
							If ('$classmethod(tTimeClass,"%IsA","%DeepSee.Age.AbstractLevel")) {
								Set tSC = $$$ERROR($$$GeneralError,"Level in age dimension refers to a time function. " _ ..name _ "."_ tHier.name_ "." _ tLevel.name _ " (" _ tFuncName _ ")")
								Quit
							}
						}
					}
					If $$$ISERR(tSC) Quit
				}
				ElseIf (..type = "computed") {
				}
				Else {
					If ((tLevelSourceProperty="")&&(tLevelSourceExpression="")&&(tSourceProperty="")&&(tSourceExpression="")) {
						Set tSC = $$$ERROR($$$GeneralError,"Level must have a sourceProperty or sourceExpression attribute: " _ ..name_"."_tHier.name_"."_tLevel.name)
						Quit
					}
				}
				
				If (tLevelSourceProperty'="") {
					// do not allow the same source in the same hierarchy
					Set tQName = $$$UPPER(tLevelSourceProperty) _ $S(tLevel.rangeExpression="":"",1:":") _ tLevel.rangeExpression
					// JMD926: use hash to avoid subscript limit
					Set:$L(tQName)>100 tQName = $ZCRC(tQName,7)
					Set:(tLevel.linkProperty'="") tQName = tQName _ "LX" _ $ZCRC(tLevel.linkClass_tLevel.linkProperty,7)
					If ($D(tLevelSource(tQName))) {
						Set tSC = $$$ERROR($$$GeneralError,"Different levels in same hierarchy cannot have the same source: " _ ..name _ "." _ tHier.name _ "." _ tLevel.name)
						Quit
					}
					Set tLevelSource(tQName) = ""

					// check if source property exists
					Set tType = ##Class(%DeepSee.Generator).%GetPropertyType(.tSC, .tParms, ..cube.sourceClass,tLevelSourceProperty,(..name_"."_tHier.name_"."_tLevel.name))
					If ($$$ISERR(tSC)) {
						Set tSC = $$$ERROR($$$GeneralError,"Property referred to by sourceProperty not found (3). Level: "_..name_"."_tHier.name_"."_tLevel.name_", property: "_tLevelSourceProperty _ ", source: " _ ..cube.sourceClass)
						Quit
					}
				}
				If ((tLevel.linkClass'="")&&(tLevel.linkProperty="")) {
					Set tSC = $$$ERROR($$$GeneralError,"Property must define linkProperty if linkClass is defined: " _ ..name_"."_tHier.name_"."_tLevel.name)
					Quit
				}
				ElseIf ((tLevel.linkClass="")&&(tLevel.linkProperty'="")) {
					Set tSC = $$$ERROR($$$GeneralError,"Property must define linkClass if linkProperty is defined: " _ ..name_"."_tHier.name_"."_tLevel.name)
					Quit
				}
				ElseIf ((tLevel.linkClass'="")&&(tLevel.linkProperty'="")) {
					Set tType = ##Class(%DeepSee.Generator).%GetPropertyType(.tSC, .tParms, tLevel.linkClass,tLevel.linkProperty)
					If ($$$ISERR(tSC)) {
						Set tSC = $$$ERROR($$$GeneralError,"Class or property referred to by linkProperty not found: "_..name_"."_tHier.name_"."_tLevel.name_":"_tLevel.linkClass_"."_tLevel.linkProperty)
						Quit
					}
				}

				If (tLevel.rangeExpression'="") {
					// validate expression
					Set tContext = ": "_(..name_"."_tHier.name_"."_tLevel.name)
					Set tSC = ##class(%DeepSee.Utils).%ParseRangeExpression(tLevel.rangeExpression,,tContext)
					If $$$ISERR(tSC) Quit
				}

				Set tPropCount = tLevel.properties.Count()
				If ((tPropCount>0)&&(..type = "time")) {
					Set tSC = $$$ERROR($$$GeneralError,"Level in time dimension may not contain member properties: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					Quit
				}
				ElseIf ((tPropCount>0)&&(..type = "age")) {
					Set tSC = $$$ERROR($$$GeneralError,"Level in age dimension may not contain member properties: " _ ..name _ "." _ tHier.name _ "."_ tLevel.name)
					Quit
				}

				Set tIsName = 0
				For p = 1:1:tPropCount {
					Set tProp = tLevel.properties.GetAt(p)
					If (tProp.disabled) {
						Continue
					}
					If (tProp.name="") {
						Set tSC = $$$ERROR($$$GeneralError,"Member property must have a name: "_..name_"."_tHier.name_"."_tLevel.name)
						Quit
					}
					Set tPropSourceProperty = $S(tProp.localSourceProperty'="":tProp.localSourceProperty,1:tProp.sourceProperty)
					Set tPropSourceExpression = $S(tProp.localSourceExpression'="":tProp.localSourceExpression,1:tProp.sourceExpression)

					If ((tPropSourceProperty="")&&(tPropSourceExpression="")) {
						Set tSC = $$$ERROR($$$GeneralError,"Member property must have a sourceProperty or sourceExpression attribute: " _ ..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name)
						Quit
					}

					If ((tProp.linkClass'="")&&(tProp.linkProperty="")) {
						Set tSC = $$$ERROR($$$GeneralError,"Member property must define linkProperty if linkClass is defined: " _ ..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name)
						Quit
					}
					ElseIf ((tProp.linkClass="")&&(tProp.linkProperty'="")) {
						Set tSC = $$$ERROR($$$GeneralError,"Member property must define linkClass if linkProperty is defined: " _ ..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name)
						Quit
					}
					ElseIf ((tProp.linkClass'="")&&(tProp.linkProperty'="")) {
						Set tType = ##Class(%DeepSee.Generator).%GetPropertyType(.tSC, .tParms, tProp.linkClass,tProp.linkProperty)
						If ($$$ISERR(tSC)) {
							Set tSC = $$$ERROR($$$GeneralError,"Class or property referred to by linkProperty not found: "_..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name_":"_tProp.linkClass_"."_tProp.linkProperty)
							Quit
						}
					}

					If ((tProp.sourceExpression'="")&&(tProp.isReference)) {
						Set tSC = $$$ERROR($$$GeneralError,"Property using isReference cannot use a source expression: "_..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name)
						Quit
					}

					If ((tLevelSourceProperty'="")&&(tPropSourceProperty'="")) {
						If ((tLevel.useDisplayValue)&&('tProp.useDisplayValue)) {
							If ($$$UPPER(tLevelSourceProperty)=$$$UPPER(tPropSourceProperty)) {
								Set tSC = $$$ERROR($$$GeneralError,"Member property with same sourceProperty as its level must have the same useDisplayValue: " _ ..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name _ $C(13,10)_"("_tLevelSourceProperty_")")
								Quit
							}
						}
					}
					If ((tLevelSourceExpression'="")&&(tPropSourceExpression'="")) {
						If ($$$UPPER(tLevelSourceExpression)=$$$UPPER(tPropSourceExpression)) {
							Set tSC = $$$ERROR($$$GeneralError,"Member property cannot have the same sourceExpression as its level: " _ ..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name _ $C(13,10)_"("_tLevelSourceExpression_")")
							Quit
						}
					}
					
					If (tProp.isName) {
						If (tIsName) {
							Set tSC = $$$ERROR($$$GeneralError,"Only one member property can set isName true: " _ ..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name)
							Quit
						}
						Set tIsName = 1
					}

					If (tPropSourceProperty'="") {
						Set tType = ##Class(%DeepSee.Generator).%GetPropertyType(.tSC, .tParms, ..cube.sourceClass,tPropSourceProperty,(..name_"."_tHier.name_"."_tLevel.name))
						If ($$$ISERR(tSC)) {
							Set tSC = $$$ERROR($$$GeneralError,"Property referred to by sourceProperty not found (4). Element:"_..name_"."_tHier.name_"."_tLevel.name_"."_tProp.name_", property:"_tPropSourceProperty _ ", source: " _ ..cube.sourceClass)
							Quit
						}
					}
				} // props
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the SQL table name for the given class name.
ClassMethod %GetSQLTableName(pClass As %String) As %String [ CodeMode = expression ]
{
$$$comClassKeyGet(pClass,$$$cCLASSsqlschemaname)_"."_$$$comClassKeyGet(pClass,$$$cCLASSsqltablename)
}

/// Returns the SQL name of property <var>pProp</var> for class <var>pClass</var>.
ClassMethod %GetSQLColumnName(pClass As %String, pProp As %String) As %String [ Final ]
{
	Set tCol = $Get($$$EXTPROPsqlcolumnname($$$pEXT,pClass,pProp))
	If (tCol'="") {
		Set x = $$QuoteId^%occStorageUtil(tCol,.tColQ)
		Set tCol = tColQ
	}
	Quit tCol
}

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tDimObj = {}
	
	Try {
		// Perform a series of checks to see if this is AtScale-compatible
		If (..type'="data")&&(..type'="time") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Dimension type cannot be exported:")_..name_":"_..type,$$$msgInfo))
			Set tDimObj = ""
			Quit
		}
		If ..disabled {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Dimension is disabled and will not be exported:")_..name_":"_..type,$$$msgInfo))
			Set tDimObj = ""
			Quit
		}

		// Information from this specific dimension
		Set tDimObj.name = ..name
		Set tDimObj.displayName = $S(..displayName'="":..displayName,1:..name)
		Set tDimObj.description = ..description
		Set tDimObj.dimensionType = $Case(..type,"time":"Time","data":"Regular",:"Regular")
		Do tDimObj.%Set("visible",'..hidden,"boolean")		// DP-405037
		
		// Reset the current property for this dimension. If a date dimension, the sourceProperty will
		// be defined at this level but will be needed to point the level at the proper attribute.
		Set pAuxiliaryIndex.currentDimProp = "" 
		Set pAuxiliaryIndex.currentDimAttribute = ""
		Set pAuxiliaryIndex.currentDimType = ""
		
		If (..sourceProperty'="") {
			// DP-407134 - sourceProperty processing shouldn't be needed here since the time levels
			// convert to direct SQL calls for each time type.
			// Store the dimension-level source information so the levels can see it.
			// The attribute representation is a convenient structure for defining a common
			// set of terms so that is created even though it ultiamtely will not be ushed to the 
			// attributes array.
			Set pAuxiliaryIndex.currentDimProp = ..sourceProperty
			Do:(pAuxiliaryIndex.calendarTable'="") ..%AtScaleProcessSourceRef(..sourceProperty,pAuxiliaryIndex)
			Set pAuxiliaryIndex.currentDimAttribute = ..%AtScaleProduceAttribute(..sourceProperty,pAuxiliaryIndex)
			Set pAuxiliaryIndex.currentDimType = $$$LOWER(..type)
		}
		
		// Walk through and collect the hierarchies
		Set tHierarchiesArray = []
		For h=1:1:..hierarchies.Count() {
			// Push each dimension object in the tDimensions array if it is exportable
			Set tHier = ..hierarchies.GetAt(h).%AtScaleExport(.pStatus,.pAuxiliaryIndex)
			If $$$ISERR(pStatus) Quit
			
			Do:(tHier'="") tHierarchiesArray.%Push(tHier)
		}
		
		// DP-406089 - If this dimension contains no exportable hierarchies, don't bother exporting it.
		If (tHierarchiesArray.%Size()) {
			Set tDimObj.hierarchies = tHierarchiesArray
		}
		Else {
			Set tDimObj = ""
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tDimObj=""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tDimObj
}

}
