/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Meta-data for a hierarchy level within a dimension within a DeepSee cube.
Class %DeepSee.Model.level Extends (%DeepSee.Model.node, %DeepSee.Model.source) [ System = 3 ]
{

/// Hierarchy that this level belongs to.
Relationship hierarchy As %DeepSee.Model.hierarchy(XMLPROJECTION = "none") [ Cardinality = one, Inverse = levels ];

/// Set of properties defined for this level.<br/>
Property properties As list Of %DeepSee.Model.property(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Optional. Set of explicitly defined members for this level.<br/>
/// If defined, this is a list of the members that
/// are to be displayed for this level in the given order.<br/>
Property members As list Of %DeepSee.Model.member(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// For time dimensions, this is the name of the function that provides
/// the data for this level.<br/>
/// A time function is the class name of a time level class (without
/// the package name). E.g., "Year".
Property timeFunction As %DeepSee.Datatype.string(VALUELIST = ",Year,QuarterYear,MonthYear,WeekYear,DayMonthYear,Decade,QuarterNumber,MonthNumber,WeekNumber,DayNumber,HourNumber,MinuteNumber,Days,Months,Years", XMLPROJECTION = "attribute") [ Internal ];

/// For time dimensions, this is optional display format to apply to time values within this level.<br/>
/// (See the %FormatDate method in the <class>%DeepSee.Utils</class> class) for details on the format.
Property timeFormat As %DeepSee.Datatype.string(XMLPROJECTION = "attribute") [ Internal ];

/// For time dimensions, this is optional offset to apply to time values within this level.<br/>
/// The offset is an interval in the form "99y99m99d" where 9 is any digit and y,m, and d
/// indicate years, months, and days. The interval may have a leading minus sign.<br/>
/// This is used in cases where a time period does not correspond to actual time (such as a
/// fiscal year starting on Oct 1).
Property timeOffset As %DeepSee.Datatype.string(XMLPROJECTION = "attribute") [ Internal ];

/// If true, then the value for this level contains a list of items. Each
/// distinct item is treated as a member of this level.<br/>
/// By default the list consists of a $List of items. You can also use a character-delimited
/// list by setting the <property>listDelimiter</property> attribute.<br/>
/// A <property>nullReplacement</property> for a list property is applied when the 
/// entire list is missing. Missing elements within a list are simply ignored.
Property list As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Optional. If the <property>list</property> attribute for this level is true, then
/// setting this will cause the list to be interpreted as a character delimited value using
/// this attribute as the delimiter character.
Property listDelimiter As %DeepSee.Datatype.string(MAXLEN = 1, XMLPROJECTION = "attribute");

/// Optional. If defined, this is used as the display value for
/// any members of this level whose value is null (missing).<br/>
/// If not defined, then missing members will not be listed by queries.<br/>
/// This cannot be used for levels within time dimensions or for levels that
/// contain a list of values (see <property>list</property>).
Property nullReplacement As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Optional. If defined, this contains a range expression that transforms incoming
/// values according to a set of range conditions.<br/>
/// A range condition is a string containing one or more range conditions.
/// Each condition has a test value and a replacement value of the form "test:replace;"
/// A test value can contain a single value or a range. A range is enclosed with 
/// () (exclusive) or [] (inclusive).<br/>
/// For example:<br/>
/// "(,0]:Below Normal;(0,100):Normal;[100,):Above Normal;"
/// This cannot be used for levels within time dimensions or for levels that
/// contain a list of values (see <property>list</property>).<br/>
/// Range expressions are applied before null value substitution.<br/>
/// Values that do not match any range condition are converted to null.<br/>
Property rangeExpression As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// Optional. If defined, this is a comma-delimited list of the members that
/// are to be displayed for this level in the given order.<br/>
/// This is deprecated in favor of the <property>members</property> collection.
Property memberList As %DeepSee.Datatype.string(XMLPROJECTION = "attribute") [ Deprecated ];

/// If true, then use the display (external) value of the field (if applicable) in the source
/// table when fetching data for this level.<br/>
/// This is only applied for levels that specify a <property>sourceProperty</property>.
Property useDisplayValue As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If specified, then use this property to define the default sort order for members of the current level.<br/>
/// The value can be "asc" for ascending order, "desc" for descending order,
/// "asc numeric" for ascending numeric order, or "desc numeric" for descending numeric order.<br/>
/// For more precise control, you can specify sort order within the property definitions associated
/// with this level.
Property sort As %DeepSee.Datatype.string(VALUELIST = ",asc,desc,asc numeric,desc numeric", XMLPROJECTION = "attribute");

/// If defined, this is an MDX expression identifying another level within this cube
/// that this level depends on, e.g., "[Outlet].[H1].[City]"<br/>
/// This causes the following changes to this cube.<br/>
/// <ol>
/// <li>An additional index is created based on the "master" level's fact and this level's fact.</li>
/// <li>When the set of members for this level is produced it is filtered using this index.</li>
/// </ol>
Property dependsOn As %DeepSee.Datatype.string(MAXLEN = 32000, XMLPROJECTION = "attribute");

/// If true (the default), then this level can be used a filter within a dashboard. If false,
/// it is still visible to the Analyzer, but is not listed as a choice for a widget filter.<br/>
/// This has no effect on the operation of the cube.
Property useAsFilter As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// If true, the engine will treat the members of this level as numbers.
Property castAsNumeric As %Boolean(XMLPROJECTION = "attribute");

/// If true, this level is hidden. That is, it will not be listed among the
/// cube's members within the various DeepSee utilities.<br/>
/// It can still be used within MDX queries and expressions.
Property hidden As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// Define a stable fact number for this level
Property factNumber As %DeepSee.Datatype.string(XMLPROJECTION = "attribute");

/// Override default validation to allow for additional time classes.
ClassMethod timeFunctionIsValid(%val) As %Status
{
	Quit $$$OK
}

/// Produce the structures needed to emit the appropriate JSON and export this item to AtScale
Method %AtScaleExport(pStatus As %Status = {$$$OK}, ByRef pAuxiliaryIndex As %DynamicAbstractObject = {$$$NULLOREF}) As %DynamicAbstractObject
{
	// Method added by DP-404535
	Set tLevel = ""
	
	Try {
		// Perform a series of checks to see if this is AtScale-compatible
		If (..sourceProperty="")&&(pAuxiliaryIndex.currentDimType'="time") {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Level cannot be exported without a sourceProperty: ")_..hierarchy.dimension.name_"."_..hierarchy.name_"."_..name,$$$msgInfo))
			Set tLevel = ""
			Quit
		}
		If ..disabled {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($$$Text("Level is disabled and will not be exported: ")_..hierarchy.dimension.name_"."_..hierarchy.name_"."_..name,$$$msgInfo))
			Set tLevel = ""
			Quit
		}
		
		// This generates an attribute to collect information for this level and sets the appropriate
		// level name to find that attribute.
		If (..sourceProperty'="") {
			Set pStatus = ..%AtScaleProcessSourceRef(..sourceProperty,.pAuxiliaryIndex)
			If $$$ISERR(pStatus) Quit
			
			// Produce the attribute and source column.
			Set tCurrAttribute = ..%AtScaleProduceAttribute(..sourceProperty,.pAuxiliaryIndex)
		}
		ElseIf (pAuxiliaryIndex.currentDimType="time")&&(pAuxiliaryIndex.currentDimProp'="") {
			// Each level name must match an attribute name, and these could come from the primary dataset or could come
			// from a supporting calendar dataset. In the degenerate dimension case this will communicate the correct
			// SQL function to the primary dataset's field list through an attribute that connects this
			// level to the proper SQL column. When a calendar table exists the current attribute will link to that table and
			// a relationship will be generated to link it to the primary fact table.
			Set pStatus = ..%AtScaleProcessSourceRef(pAuxiliaryIndex.currentDimProp,.pAuxiliaryIndex,..timeFunction)
			If $$$ISERR(pStatus) Quit
			
			// Produce the attribute incorporating the time function into the custom SQL.
			Set tCurrAttribute = ..%AtScaleProduceAttribute(pAuxiliaryIndex.currentDimProp,.pAuxiliaryIndex,..timeFunction)
		}
		Else {
			Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj("Level could not be exported: " _ 
													..hierarchy.dimension.name _ "." _
													..hierarchy.name _ "." _ ..name))
			Quit
		}
		
		If $IsObject(tCurrAttribute) {
			// Pass along level-specific properties to the current attribute
			
			If (..nullReplacement'="") {
				// Null replacement strings get transformed into an attribute's customEmptyMember
				Set tCustomEmpty = {}
				Set tCustomEmpty.name = "Custom Empty Member for " _ tCurrAttribute.name
				Set tCustomEmpty.values = [].%Push(..nullReplacement)
				
				Set tCurrAttribute.customEmptyMember = tCustomEmpty
			}
			
			Set:(..rangeExpression'="") tCurrAttribute.rangeExpression = ..rangeExpression
			
			If (..sort'="") {
				// DP-407548 - Create a sort object if the source 
				Set tSortObj = {}
				Set tSortObj.order = $$$atScaleSort(..sort)
				Set tSortObj.column = tCurrAttribute.keyColumns.%Get(0)		// These attributes use a single column
				Set tCurrAttribute.sort = tSortObj
			}
			
			// Properties get converted to secondary attributes
			Set tPropertiesArray = []
			Set pAuxiliaryIndex.currLevelName = ..name
			For p=1:1:..properties.Count() {
				// Push each dimension object in the tDimensions array if it is exportable
				Set tProp = ..properties.GetAt(p).%AtScaleExport(.pStatus,.pAuxiliaryIndex)
				If $$$ISERR(pStatus) Quit
				
				Do:(tProp'="") tPropertiesArray.%Push(tProp)
			}
			Do pAuxiliaryIndex.%Remove("currLevelName")
			
			If (tPropertiesArray.%Size()) {
				Set tCurrAttribute.propertyNames = tPropertiesArray
			}
			
			Do pAuxiliaryIndex.attributes.%Push(tCurrAttribute)
			
			// Read the name of the returned attribute to make sure the reference and the produced
			// attribute will always match.
			Set tLevel = tCurrAttribute.name
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tLevel=""
		Do pAuxiliaryIndex.messages.%Push(..%AtScaleCreateMessageObj($system.Status.GetOneErrorText(pStatus),$$$msgErr))
	}
	
	Quit tLevel
}

}
