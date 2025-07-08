/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%ZEN.Utils, %ZEN.ReportUtil)

/// 
/// This class provides a way to assemble data.
/// 
/// A <class>dataBag</class> object contains a set of name-value pairs.
/// 
/// This is used internally by the pseudo-MVC classes in Zen Reports.
Class %ZEN.Report.Display.COSChart.dataBag Extends %RegisteredObject [ Deprecated ]
{

/// 
/// List of property names contained within this dataBag.
Property propertyList As %ZEN.Datatype.csv(XMLPROJECTION = "NONE") [ Private ];

/// 
/// List of property labels (if different than property name) contained within this dataBag.
Property labelList As %ZEN.Datatype.csv(XMLPROJECTION = "NONE") [ Private ];

/// 
/// List of types of the properties contained within this dataBag.
Property propertyTypes As %ZEN.Datatype.csv(XMLPROJECTION = "NONE") [ Private ];

/// 
/// Array of data values within the dataBag, indexed by series and property name.
Property %data As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ MultiDimensional ];

/// 
/// Array of data types within the dataBag, indexed by property name.
Property %types As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ MultiDimensional ];

/// 
/// Array of labels within the dataBag, indexed by property name.
Property %labels As %ZEN.Datatype.string(XMLPROJECTION = "NONE") [ MultiDimensional ];

/// 
/// Array of serialized data values going to and coming from the client.
Property clientData As %ZEN.Datatype.list(XMLPROJECTION = "NONE");

/// 
/// Number of data series held within the dataBag.
Property seriesCount As %ZEN.Datatype.integer(MINVAL = 1, XMLPROJECTION = "NONE") [ InitialExpression = 1 ];

/// 
/// List of data series names contained within this dataBag.
Property seriesNames As %ZEN.Datatype.csv(XMLPROJECTION = "NONE") [ Private ];

/// 
/// Set the property list for the dataBag.
/// 
/// This deletes the contents of the dataBag.
Method %SetPropertyList(pPropList As %String, pPropTypes As %String = "", pLabelList As %String = "") [ Internal ]
{

	Do ..%Clear()

	Set ..propertyList = pPropList

	Set ..propertyTypes = pPropTypes

	Set ..labelList = pLabelList
}

/// 
/// Internal method.
Method %GetPropertyList() As %String [ CodeMode = expression, Internal ]
{
..propertyList
}

/// 
/// Internal method.
Method %GetPropertyTypes() As %String [ CodeMode = expression, Internal ]
{
..propertyTypes
}

/// 
/// Internal method.
Method %GetLabelList() As %String [ CodeMode = expression, Internal ]
{
..labelList
}

/// 
/// Delete data currently in the dataBag.
Method %Clear()
{
	Kill ..%data,..%types,..%labels
}

/// 
/// Get the value of a property within the dataBag.<br>
/// 
/// Note that this can return a literal value,
/// 
/// an object value (oref), or $$$ZENMISSING if the given
/// 
/// property is not in the model.
Method %GetValue(pProperty As %String, pSeries As %Integer = 1) As %String [ CodeMode = expression ]
{
$S(pProperty'="":$G(..%data(pSeries,pProperty),$$$ZENMISSING),1:"")
}

/// 
/// Get the type of a property within the dataBag.<br>
Method %GetType(pProperty As %String) As %String [ CodeMode = expression ]
{
$S(pProperty'="":$G(..%types(pProperty)),1:"")
}

/// 
/// Get the label for a property within the dataBag.<br>
Method %GetLabel(pProperty As %String) As %String [ CodeMode = expression ]
{
$S(pProperty'="":$G(..%labels(pProperty),pProperty),1:"")
}

/// 
/// Set the value of a property within the dataBag.
Method %SetValue(pProperty As %String, pValue As %String)
{

	#; force client change

	//Do ..%ForceClientRender()

	Set:pProperty'="" ..%data(1,pProperty) = pValue
}

/// 
/// Copy the contents of this dataBag into a local array.
Method %GetArray(Output pArray)
{

	Kill pArray

	Merge pArray = ..%data
}

/// 
/// Fill the contents of this dataBag from the given DataModel
Method %CopyFromModel(pModel As %ZEN.DataModel.DataModel) As %Status
{

	Set tSC = $$$OK

	Set $ZT = "Trap"



	Do {

		Set tSC = $zobjmethod(pModel,"%CopyDataFromModel",.tData)

		If $$$ISERR(tSC) Quit



		#; get series info

		Set ..seriesCount = pModel.%seriesCount

		

		Set tNames = ""

		Set n = $O(pModel.%seriesNames(""))

		While (n '= "") {

			Set tNames = tNames _ $S(tNames="":"",1:",") _ $TR($G(pModel.%seriesNames(n)),","," ")

			Set n = $O(pModel.%seriesNames(n))

		}

		Set ..seriesNames = tNames



		#; copy data into bag

		Kill ..%data

		Merge ..%data = tData

	} While(0)

Done

	Quit tSC

Trap

	Set $ZT=""

	Set tSC = $$$ERROR($$$ObjectScriptError,"%CopyFromModel: " _ $ZE)

	Goto Done
}

/// 
/// Copy the contents of this dataBag into the given DataModel.
Method %CopyToModel(pModel As %ZEN.DataModel.DataModel) As %Status
{

	Set tSC = $$$OK

	Set $ZT = "Trap"

	Do {

		Set pModel.%seriesCount=..seriesCount

		For sno=1:1:..seriesCount {

			Set pModel.%seriesNames(sno)=$Piece(..seriesNames,",",sno)	

		}

		Merge tData = ..%data

		Set tSC = $zobjmethod(pModel,"%CopyDataToModel",.tData)

		If $$$ISERR(tSC) Quit

	} While(0)

Done

	Quit tSC

Trap

	Set $ZT=""

	Set tSC = $$$ERROR($$$ObjectScriptError,"%CopyToModel: " _ $ZE)

	Goto Done
}

/// 
/// Make sure client data is prepared.
Method %OnObjectSynch() As %Status
{
	Quit ..%SerializeData()
}

/// 
/// Deserialize additional values from the client.
Method %OnZENDeserialize() As %Status
{

	Set tSC = $$$OK

	Set $ZT = "Trap"



	#; convert client properties to server representation

	#; using meta-data within propertyList

	If (..propertyList '= "") {

		For n = 1:1:$L(..propertyList,",") {

			Set tProp = $P(..propertyList,",",n)

			Set tType = $P(..propertyTypes,",",n)

			Set tLabel = $P(..labelList,",",n)

			Set:tType'="" ..%types(tProp) = tType

			Set:tLabel'="" ..%labels(tProp) = tLabel

		}

	}



	#; data for all series are concatenated into one list

	If (..propertyList '= "") {

		Set tPropCount = $L(..propertyList,",")

		For s = 1:1:..seriesCount {

			Set tOff = (s-1) * tPropCount

			For n = 1:1:tPropCount {

				Set tProp = $P(..propertyList,",",n)

				Set ..%data(s,tProp) = $P(..clientData,$C(5),tOff + n)

			}

		}

	}

Done

	Quit tSC

Trap

	Set $ZT=""

	Set tSC = $$$ERROR($$$ObjectScriptError,"%OnZENDeserialize: " _ $ZE)

	Goto Done
}

/// 
/// Called just before we serve property values to the client.
Method %OnDrawObjectProperties() As %Status
{

	#; convert data to serialized array for client

	Quit ..%SerializeData()
}

/// 
/// Convert internal arrays to a serialized strings for use on the client.
Method %SerializeData(pDelim As %String = {$C(5)}) As %Status
{

	Set tSC = $$$OK

	;Set $ZT = "Trap"



	#; put values in the order they appear in the list of properties.

	Set tData = ""

	Set tOff = 0

	Set tCount = 0

	For s = 1:1:..seriesCount {

		If (..propertyList '= "") {

			For n = 1:1:$L(..propertyList,",") {

				Set tProp = $P(..propertyList,",",n)

				Set tType = $P(..propertyTypes,",",n)

				Set tLabel = $P(..labelList,",",n)
				Set tValue = $G(..%data(s,tProp))

				If (tValue = $$$ZENMISSING) {

					Set tValue = ""

				}

				Set tData = tData_$S((tOff+n)=1:"",1:pDelim)_tValue

				Set tCount = tCount + 1

			}

		}

		Set tOff = tOff + ..seriesCount

	}



	If ((tData="")&&(tCount>0)) {

		// make sure we don't serialize single "" to null

		Set tData = pDelim

	}



	Set ..clientData = tData

Done

	Quit tSC

Trap

	Set $ZT=""

	Set tSC = $$$ERROR($$$ObjectScriptError,"%SerializeData: " _ $ZE)

	Goto Done
}

/// 
/// Clear contents of this dataBag.
ClientMethod clear() [ Language = javascript ]
{

	for (var n = 0; n < this.clientData.length; n++) {

		this.clientData[n] = '';

	}
}

/// 
/// Return the data value associated with a given property name.
/// 
/// If there is no property with the name, <var>property</var>, return null.
ClientMethod getValue(property, series) [ Language = javascript ]
{

	series = (null == series) ? 0 : series;

	var data = null;

	var index = this.getPropertyIndex(property);

	if (index>=0) {

		var idx = index + (series * this.getPropertyCount());

		data = this.clientData[idx];

	}

	return data;
}

/// 
/// Return the data value at the given ordinal position.
/// 
/// If <var>n</var> is out of range, return null.<br>
/// 
/// <var>series</var> is 0-based.
ClientMethod getValueByPosition(n, series) [ Language = javascript ]
{

	series = (null == series) ? 0 : series;

	var idx = n + (series * this.getPropertyCount());

	return this.clientData[idx];
}

/// 
/// This is a specialized variant of <method>getValueByPosition</method> that
/// 
/// return the data in this bag as an array of arrays (used
/// 
/// by charts).
Method getValuesAsArrays(ByRef data)
{

	Set this=##this
	//var data = new Array(this.seriesCount);
	Set pc = this.getPropertyCount()
	for i=0:1:this.seriesCount-1 {
		for j=0:1:pc -1 {
			Set data(i,j)= 0
		}
	}


	Set idx = 1

	for i = 0:1:this.seriesCount-1 {

		//data[i] = new Array(pc);

		for j = 0: 1 : pc -1 {

			Set data(i,j) = $P(this.clientData,$C(5),idx)
			Set idx=$i(idx)
		}

	}

	//return data
}

/// 
/// Return the values in this dataBag as a zenProxy object.
/// 
/// If there is more than one data series, <var>series</var>
/// 
/// specifies which one to use.<br/>
/// 
/// Return null if there are no properties in the dataBag.
ClientMethod getValuesAsObject(series) [ Language = javascript ]
{

	if (''==this.propertyList) { return null; }

	var obj = new zenProxy();

	var props = this.propertyList.split(',');

	for (var n = 0; n < props.length; n++) {

		if (props[n] && props[n]!='') {

			var prop = props[n].split(':')[0];

			obj[prop] = this.getValue(prop, series);

		}

	}

	return obj;
}

/// 
/// Internal method.<br>
/// 
/// Find index number of given property name.
ClientMethod getPropertyIndex(property) [ Internal, Language = javascript ]
{

	if (''==this.propertyList || ''==property) { return -1; }



	if (null == this._propertyIndex) {

		// build index

		this._propertyIndex = new Object();

		var props = this.propertyList.split(',');

		for (var n=0; n < props.length; n++) {

			this._propertyIndex[props[n].split(':')[0]] = n;

		}

	}



	return this._propertyIndex[property];
}

/// 
/// Set the data value for the given property.<br>
/// 
/// <var>series</var> is 0-based.
ClientMethod setValue(property, value, series) [ Language = javascript ]
{

	// find index of property within list

	var index = this.getPropertyIndex(property);

	if (index>=0) {

		series = (null == series) ? 0 : series;

		this.clientData[index + (series * this.getPropertyCount())] = value;

	}
}

/// 
/// Set the data value at the given ordinal position.<br>
/// 
/// <var>series</var> is 0-based.
ClientMethod setValueByPosition(value, n, series) [ Language = javascript ]
{

	if (n>=0) {

		series = (null == series) ? 0 : series;

		var idx = n + (series * this.getPropertyCount());

		this.clientData[idx] = value;

	}
}

/// 
/// dataSet API
/// 
/// Return the number of items in the specified dimension.<br>
/// 
/// (<var>dim</var> is 1,2, or 3).
/// 
/// The size of the first dimension is defined by the number of properties in the dataBag.<br>
/// 
/// The size of the second dimension is defined by number of data series in the dataBag.
/// 
/// The dataBag does not support a third dimension.
Method getDimSize(dim)
{
	quit $case(dim, 1:..getPropertyCount(), 2:..getSeriesCount(),:0)
}

/// 
/// Return the number of data series within this dataBag.
Method getSeriesCount()
{
	quit ..seriesCount
}

/// 
/// Return the number of properties within this dataBag.
Method getPropertyCount()
{
	quit $s(..clientData'="" : $$$FLOOR($L(..clientData,$C(5)) / ..seriesCount), 1 : 0)
}

/// 
/// Return the name of a property within this dataBag given its ordinal
/// 
/// (0-based) position.
Method getPropertyName(n)
{

	if (""=..propertyList) { quit "" }

	Set props = ..propertyList

	Set prop = $P(props,",",n+1)
	quit $s("" = prop: "" , 1: $P(prop,":",1))
}

/// 
/// Return the type code of a property within this dataBag given its ordinal
/// 
/// (0-based) position.
ClientMethod getPropertyType(n) [ Language = javascript ]
{

	if ('' == this.propertyTypes) { return ''; }

	var props = this.propertyTypes.split(',');

	return (null == props[n]) ? '' : props[n].split(':')[0];
}

/// 
/// Return the label of a property within this dataBag given its ordinal
/// 
/// (0-based) position.
Method getPropertyLabel(n)
{

	if ("" = ..labelList) { quit "" }

	Set labels = ..labelList // CSV

	Set lbl = $s("" = $P(labels,",",n) : "", 1 : $P($P(labels,",",n),":",1))

	quit $s("" = lbl : ..getPropertyName(n), 1 : lbl)
}

/// 
/// Return the label of a dataSeries within this dataBag given its ordinal
/// 
/// (0-based) position.
Method getSeriesLabel(n)
{

	Set this = ##this
	
	if ("" = this.seriesNames) { quit ("Series " _ (n+1)) }

	Set labels = $LISTFROMSTRING(this.seriesNames,",")

	Set lbl = $P($LG(labels,n+1),":",1)

	quit $s("" = lbl : ("Series " _ (n+1)), 1 : lbl)
}

/// 
/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{

	switch(property) {

	case 'propertyList':

		if (this._propertyIndex) {

			delete this._propertyIndex;

		}

		this.propertyList = value;

		break;

	case 'propertyTypes':

		this.propertyTypes = value;

		break;

	default:

		// dispatch

		return this.invokeSuper('setProperty',arguments);

	}

	return true;
}

}
