/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used to implement the Model portion of the Zen 
/// Model-View-Controller mechanism.<br>
/// An ObjectDataModel is specific type of <class>DataModel</class> that
/// contains a set of named values (properties).<br>
/// The properties of an ObjectDataModel can either be formally defined within
/// the ObjectDataModel class, or they can be "virtual" properties - properties
/// defined at run-time.<br>
/// When an ObjectDataModel is displayed using a <class>%ZEN.Component.dynaForm</class>, the
/// properties will be displayed in the following default ways:<br>
/// <ul>
/// <li>Private properties - Not displayed.</li>
/// <li>Reference properties - Using a <class>%ZEN.Component.dataCombo</class>.</li>
/// <li>Strings - Using a <class>%ZEN.Component.text</class>.</li>
/// <li>Strings with MAXLEN over 250 - Using a <class>%ZEN.Component.textarea</class>.</li>
/// <li>Numerics - Using a <class>%ZEN.Component.text</class>.</li>
/// <li>Dates - Using a <class>%ZEN.Component.dateText</class>.</li>
/// <li>Enumerated value (using VALUELIST) - Using a <class>%ZEN.Component.radioSet</class> or <class>%ZEN.Component.comboBox</class>.</li>
/// </ul>
Class %ZEN.DataModel.ObjectDataModel Extends %ZEN.DataModel.DataModel [ Abstract, DependsOn = (%ZEN.Generator, %ZEN.DataModelUtils), Deprecated, PropertyClass = %ZEN.DataModel.objectModelParameters, System = 3 ]
{

/// Localization domain.
/// DataModel classes that wish to support localization must provide a value for this
/// within subclasses.
Parameter DOMAIN;

/// If true (the default), then this dataModel class supports dynamic properties:
/// that is, you can reference arbitrary property names within the data model object.
/// Any such properties that are not formally defined will refer to a location within the
/// private property, <property>%data</property> using the dynamic dispatch mechanism.
/// Set this to false to disable this feature.
Parameter DYNAMICPROPERTIES As BOOL = 1;

/// This property is used to hold any virtual properties used
/// by this model.<br>
/// A virtual property is a property referenced by the data model but not
/// defined as a formal property within the data model class.
/// This is only used when the DYNAMICPROPERTIES parameter is true.
Property %data As %ZEN.Datatype.string(POPORDER = -1, XMLPROJECTION = "NONE") [ InitialExpression = {$H}, Internal, MultiDimensional, Transient ];

/// If needed, this transient property is used to hold a copy of the source
/// object used by this model.
Property %source As %RegisteredObject(POPORDER = -1, XMLPROJECTION = "NONE") [ Transient ];

/// Create an instance of this DataModel object.<br>
/// Subclasses may override this for special behavior.<br>
/// The default implementation returns the DataModel itself as the source
/// object (this allows for simple DataModel classes that have no actual
/// source object).
ClassMethod %CreateModelInstance(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject [ CodeMode = expression ]
{
..%New()
}

/// Open and return an instance of this DataModel object (given an id value <var>pID</var> and 
/// fill in its property values.<br>
/// The actual loading of the properties is carried out by the <method>%OnLoadModel</method> method.
/// The property values can come from an independent
/// data source object or may be local to this data model object.<br>
/// If <var>pID</var> is "", then a new instance of data model object should
/// be created.<br>
/// <var>pConcurrency</var> is an optional concurrency flag that can be used in cases
/// where the data source is a persistent object.<br>
/// On return, <var>pSC</var> contains a status code indicating success of failure.
ClassMethod %OpenModel(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject [ Final ]
{
	Set pSC = $$$OK
	Set $ZT = "Trap"
	Set tModel = ""
	Do {
		Set tModel = ..%CreateModelInstance(pID,pConcurrency,.pSC)
		If $$$ISERR(pSC) Quit

		Set tModel.%id = pID
		Kill tModel.%data

		#; new or open
		If (pID = "") {
			Set tModel.%source = tModel.%OnNewSource(.pSC)
			$$$ZENLOGINFO("MVC: New model instance")
		}
		Else {
			Set tModel.%source = tModel.%OnOpenSource(pID,pConcurrency,.pSC)
			$$$ZENLOGINFO("MVC: Open existing model instance")
		}
		
		#; no source object
		If ($$$ISERR(pSC)||'$IsObject(tModel.%source)) {
			$$$ZENLOGINFO("MVC: No source object")
			Set tModel.%id = ""
			Quit
		}

		#; invoke callback to copy values into this model
		Set pSC = tModel.%OnLoadModel(tModel.%source)
		If $$$ISERR(pSC) {
			$$$ZENLOGERROR("MVC: Error loading data model")
			Quit
		}
	} While(0)

	Quit tModel
Trap
	Set $ZT=""
	Set pSC = $$$ERROR($$$ObjectScriptError,..%ClassName(1)_":%OpenModel: " _ $ZE)
	Quit ""
}

/// Save the values currently within this DataModel object back to a data source.
/// Before saving, the values of the properties will be validated (as specified
/// by the property definitions).<br>
/// The actual save operation works as follows:<br>
/// The <method>%OnStoreModel</method> callback is invoked. This copies the 
/// properties of this model back to the data source object (if there is an
/// independent data source).<br>
/// The <method>%OnSaveSource</method> callback is invoked. This causes the independent
/// data source object to be saved.<br>
/// Returns a status code indicating success or failure.
Method %SaveModel() As %Status [ Final ]
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Do {
		If (..%IsReadOnly()) {
			Set tSC = $$$ERROR($$$ClassIsReadOnly,$zobjclass($this))
			Quit
		}

		$$$ZENLOGINFO("SaveModel")

		#; invoke callback to copy values from model to source
		Set tSC = ..%OnStoreModel(..%source)
		If $$$ISERR(tSC) Quit

		#; save source object
		Set tSC = ..%OnSaveSource(..%source)
		If $$$ISERR(tSC) Quit
	} While(0)	
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,..%ClassName(1)_":%SaveModel: " _ $ZE)
	Goto Done
}

/// Delete a given DataModel instance.<br>
/// This is implemented by the subclasses of this class by providing implementations
/// of the <method>%OnDeleteModel</method> and <method>%OnDeleteSource</method> methods.
ClassMethod %DeleteModel(pID As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	Do {
		If (..%IsReadOnly()) {
			Set tSC = $$$ERROR($$$ClassIsReadOnly,$zobjclass($this))
			Quit
		}

		Set tSC = ..%OnDeleteModel(pID)
		If $$$ISERR(tSC) Quit

		#; delete source object
		Set tSC = ..%OnDeleteSource(pID)
		If $$$ISERR(tSC) Quit
	} While(0)	

Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$ObjectScriptError,..%ClassName(1)_":%DeleteModel: " _ $ZE)
	Goto Done
}

/// This callback method is invoked when a DataModel is loaded into memory.
/// If implemented, it loads an instance of the data source object
/// used by the DataModel.<br>
/// The default implementation returns the DataModel itself as the source
/// object (this allows for simple DataModel classes that have no actual
/// source object).
Method %OnOpenSource(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Set pSC = $$$OK
	Quit $this
}

/// This callback method is invoked when a new instance of DataModel is required.
/// If implemented, it returns a new instance of the data source object
/// used by the DataModel.<br>
/// The default implementation returns the DataModel itself as the source
/// object (this allows for simple DataModel classes that have no actual
/// source object).
Method %OnNewSource(Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Set pSC = $$$OK
	Quit $this
}

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status
{
	Quit $$$OK
}

/// This callback method does the actual work of copying values 
/// from the DataModel to the data source.<br>
/// The default implementation is an expression method.
Method %OnStoreModel(pSource As %RegisteredObject) As %Status [ CodeMode = expression ]
{
$$$OK
}

/// This callback method is called when the DataModel is saved. If
/// implemented, it is responsible for saving changes to the data source.
Method %OnSaveSource(pSource As %RegisteredObject) As %Status
{
	Quit $$$OK
}

/// This callback method is invoked when the DataModel is deleted.
/// This is implemented by the subclasses of this class.
ClassMethod %OnDeleteModel(pID As %String) As %Status
{
	Quit $$$OK
}

/// This callback method is called when the DataModel is deleted. If
/// implemented, it is responsible for making the appropriate deletes
/// against the data source.
ClassMethod %OnDeleteSource(pID As %String) As %Status
{
	Quit $$$OK
}

/// Internal method.<br>
/// Called by the dataController to move data into this model.
/// Copies the values in the array <var>pData</var> (subscripted by series and property name)
/// into this data model.
Method %CopyDataToModel(ByRef pData, pSeries As %Integer = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = (%GetPropertyInfo, %OnCopyDataToModel), Internal ]
{
	Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
#define quote(%val) $zutil(144,1,%val)
	Set tClassName = $$$NormalizeClassname(%class.Name)
	Do %code.WriteLine(" Set tSC = $$$OK")
	If ('%class.Abstract) {
		#; invoke callback, if defined
		If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnCopyDataToModel",$$$cMETHrunnable)) {
			Do %code.WriteLine(" Set tSC = ..%OnCopyDataToModel(.pData)")
			Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")
		}

		#; loop over data series
		Do %code.WriteLine(" For sno = $S(pSeries="""":1,1:pSeries):1:..%seriesCount {")

		#; loop over properties we have already gathered
		#; we want to generate something like
		#; Set ..Name = $G(pData(sno,"Name"))
		Set tPropList = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"ZENProperties"))
		For n = 1:1:$LL(tPropList) {
			Set tName = $LG(tPropList,n)
			Set tPropName = $P(tName,":",1)
			Set tType = $P(tName,":",2)
			Set tSkip = 0

			#; see if we want to skip this property
			Set:'tSkip tSkip=$$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPcalculated)
			Set:'tSkip tSkip=$$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPreadonly)

			If ('tSkip) {
				#; for embedded object, inject a call to its method
				If (tType = $$$ZENMVCSERIAL) {
					#; delegate to serial object
					#; first copy "Serial.Prop" values to "Prop"
					Do %code.WriteLine(" Kill tData")
					Do %code.WriteLine(" Set k = $O(pData(sno,"""_tPropName_".""))")
					Do %code.WriteLine(" While ($E(k,1,"_($L(tPropName)+1)_")="""_tPropName_"."") {")
					Do %code.WriteLine("  Set tData(sno,$P(k,""."",2,999)) = $G(pData(sno,k))")
					Do %code.WriteLine("  Set k = $O(pData(sno,k))")
					Do %code.WriteLine(" }")
					Do %code.WriteLine(" Set tSC = .."_tPropName_".%CopyDataToModel(.tData,sno)")
					Do %code.WriteLine(" If $$$ISERR(tSC) Quit")
				}
				ElseIf (tType = $$$ZENMVCPERSISTENT) {
					Do %code.WriteLine(" Do .."_tPropName_"SetObjectId($G(pData(sno,"_$$$quote(tPropName)_")))")
				}
				ElseIf (tType=$$$ZENMVCSTREAM) {
					Do %code.WriteLine(" Do .."_tPropName_".Rewind()")
					Do %code.WriteLine(" Do .."_tPropName_".Write($G(pData(sno,"_$$$quote(tPropName)_")))")
				}
				ElseIf (tType=$$$ZENMVCBSTREAM) {
					#; ignore--you cannot upload image via dataController
				}
				ElseIf (tType=$$$ZENMVCLIST) {
					Do %code.WriteLine(" Do ##class(%ZEN.Utils).%DeserializeList(.."_tPropName_",$G(pData(sno,"_$$$quote(tPropName)_")))")
				}
				ElseIf (tType=$$$ZENMVCARRAY) {
					Do %code.WriteLine(" Do ##class(%ZEN.Utils).%DeserializeArray(.."_tPropName_",$G(pData(sno,"_$$$quote(tPropName)_")))")
				}
				ElseIf (tType = $$$ZENMVCOBJECT) {
					// object reference: skip
					Do %code.WriteLine(" // skip "_tPropName)
				}
				ElseIf (tType=$$$ZENMVCBOOLEAN) {
					#; boolean may still be in form of true|false
					Do %code.WriteLine(" Set tBool = $G(pData(sno,"_$$$quote(tPropName)_"))")
					Do %code.WriteLine(" Set tBool = $Case(tBool,""true"":1,""false"":0,:tBool)")
					Do %code.WriteLine(" Set .."_tPropName_" = tBool")
				}
				Else {
					Set tClassName = $$$NormalizeClassname(%class.Name)
					Set tPropType = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPtype)
					Set:tPropType'="" tPropClientType = $$$comClassKeyGet(tPropType,$$$cCLASSclientdatatype)
					If (tPropType = "%MV.Date") {
						#; even specialer handling for MV dates!
						Do %code.WriteLine(" Set .."_tPropName_" = .."_tPropName_"OdbcToLogical($G(pData(sno,"_$$$quote(tPropName)_")))")
					}
					ElseIf ($G(tPropClientType)="DATE") {
						#; special handling for date: client always sends YYYY-MM-DD
						Do %code.WriteLine(" Set .."_tPropName_" = $S($G(pData(sno,"_$$$quote(tPropName)_"))="""":"""",1:+$ZDTH($G(pData(sno,"_$$$quote(tPropName)_")),3,,,,,,,,""Invalid date: '""_$G(pData(sno,"_$$$quote(tPropName)_"))_""'""))")
					}
					ElseIf (''$$$comMemberDefined(tClassName,$$$cCLASSmethod,$$$nameMemberMethodName(tPropName,"DisplayToLogical"))) {
						#; see if there is a local display-to-logical conversion method
						Do %code.WriteLine(" Set .."_tPropName_" = .."_tPropName_"DisplayToLogical($G(pData(sno,"_$$$quote(tPropName)_")))")
					}
					ElseIf (''$$$comSubMemberDefined(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPmethod,"DisplayToLogical")) {
						#; see if there is a display-to-logical conversion method
						Do %code.WriteLine(" Set .."_tPropName_" = .."_tPropName_"DisplayToLogical($G(pData(sno,"_$$$quote(tPropName)_")))")
					}
					Else {
						Do %code.WriteLine(" Set .."_tPropName_" = $G(pData(sno,"_$$$quote(tPropName)_"))")
					}
				}
			} // skip
			
			#; remove this property from the list
			If (+$G(%parameter("DYNAMICPROPERTIES"))) {
				Do %code.WriteLine(" Kill pData(sno,"_$$$quote(tPropName)_")")
			}
		}

		#; if we are called with a series number, then break here
		Do %code.WriteLine(" Quit:pSeries'=""""")

		#; end of series loop
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

		#; copy remaining virtual properties
		If (+$G(%parameter("DYNAMICPROPERTIES"))) {
			Do %code.WriteLine(" Kill ..%data")
			Do %code.WriteLine(" Merge ..%data = pData")
		}
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Internal method.<br>
/// Called by the dataController to get data from this model.
/// Copies the values in the data demo to the array <var>pData</var> 
/// (subscripted by series number and property name).
Method %CopyDataFromModel(Output pData, Output pTypes, pSeries As %Integer = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = (%GetPropertyInfo, %OnCopyDataFromModel), Internal ]
{
	Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
#define quote(%val) $zutil(144,1,%val)
	Do %code.WriteLine(" Set tSC = $$$OK")
	If ('%class.Abstract) {
		#; loop over data series
		Do %code.WriteLine(" For sno = $S(pSeries="""":1,1:pSeries):1:..%seriesCount {")

		#; loop over properties we have already gathered
		#; we want to generate something like
		#; Set pData(sno, "Name") = ..Name
		Set tPropList = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"ZENProperties"))
		For n = 1:1:$LL(tPropList) {
			Set tName = $LG(tPropList,n)
			Set tPropName = $P(tName,":",1)
			Set tType = $P(tName,":",2)

			#; for embedded object, inject a call to its method
			If (tType = $$$ZENMVCSERIAL) {
				#; delegate to serial object
				Do %code.WriteLine(" Kill tData,tTypes")
				Do %code.WriteLine(" Set tSC = .."_tPropName_".%CopyDataFromModel(.tData,.tTypes,sno)")
				Do %code.WriteLine(" If $$$ISERR(tSC) Quit")
				Do %code.WriteLine(" Set k = $O(tData(sno,""""))")
				Do %code.WriteLine(" While (k'="""") {")
				Do %code.WriteLine("  Set pData(sno,"_$$$quote(tPropName)_"_"".""_k) = $G(tData(sno,k))")
				Do %code.WriteLine("  Set k = $O(tData(sno,k))")
				Do %code.WriteLine(" }")
			}
			ElseIf (tType = $$$ZENMVCPERSISTENT) {
				Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = .."_tPropName_"GetObjectId()")
			}
			ElseIf (tType = $$$ZENMVCOBJECT) {
				// object reference: skip
				Do %code.WriteLine(" // skip "_tPropName)
			}
			ElseIf (tType=$$$ZENMVCSTREAM) {
				Do %code.WriteLine(" Set tValue=##class(%ZEN.Utils).%ReadStreamIntoString(.."_tPropName_",.tOverflow)")
				Do %code.WriteLine(" Set:tOverflow tValue = $$$Text(""Stream too big"",""%ZEN"")")
				Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = tValue")
			}
			ElseIf (tType=$$$ZENMVCBSTREAM) {
				#; set value to encoded Stream ID
				Do %code.WriteLine(" Set tValue=##class(%ZEN.Utils).%EncodeBinaryStream(.."_tPropName_")")
				Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = tValue")
			}
			ElseIf (tType=$$$ZENMVCLIST) {
				Do %code.WriteLine(" Set tValue=##class(%ZEN.Utils).%SerializeList(.."_tPropName_")")
				Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = tValue")
			}
			ElseIf (tType=$$$ZENMVCARRAY) {
				Do %code.WriteLine(" Set tValue=##class(%ZEN.Utils).%SerializeArray(.."_tPropName_")")
				Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = tValue")
			}
			Else {
				Set tClassName = $$$NormalizeClassname(%class.Name)
				Set tPropType = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPtype)
				Set:tPropType'="" tPropClientType = $$$comClassKeyGet(tPropType,$$$cCLASSclientdatatype)
				If (tPropType = "%MV.Date") {
					#; even specialer handling for MV dates!
					Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = .."_tPropName_"LogicalToOdbc(.."_tPropName_")")
				}
				ElseIf ($G(tPropClientType)="DATE") {
					#; special handling for date: always send YYYY-MM-DD to client
					Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = $S(.."_tPropName_"="""":"""",1:$ZDT(.."_tPropName_",3,,,,,,,,,""Invalid date: '""_.."_tPropName_"_""'""))")
				}
				ElseIf (''$$$comMemberDefined(tClassName,$$$cCLASSmethod,$$$nameMemberMethodName(tPropName,"LogicalToDisplay"))) {
					#; there is a logical-to-display conversion method
					Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = .."_tPropName_"LogicalToDisplay(.."_tPropName_")")
				}
				ElseIf (''$$$comSubMemberDefined(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPmethod,"LogicalToDisplay")) {
					#; there is a logical-to-display conversion method
					Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = .."_tPropName_"LogicalToDisplay(.."_tPropName_")")
				}
				Else {
					Do %code.WriteLine(" Set pData(sno,"_$$$quote(tPropName)_") = .."_tPropName)
				}
			}

		}
		#; if we are called with a series number, then break here
		Do %code.WriteLine(" Quit:pSeries'=""""")

		#; end of series loop
		Do %code.WriteLine(" }")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")

		#; pick up any virtual properties
		If (+$G(%parameter("DYNAMICPROPERTIES"))) {
			Do %code.WriteLine(" Merge pData = ..%data")
		}

		#; invoke callback, if defined
		If ($$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnCopyDataFromModel",$$$cMETHrunnable)) {
			Do %code.WriteLine(" Set tSC = ..%OnCopyDataFromModel(.pData)")
		}
	}
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// If defined, this callback method is invoked just before the dataController
/// copies its values into the properties of this DataModel object.<br>
/// <var>pData</var> is an array containing the values provided by the
/// controller, subscripted by property name.
Method %OnCopyDataToModel(ByRef pData) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// If defined, this callback method is invoked just as this DataModel object
/// is about to copy its values into a dataController.<br>
/// <var>pData</var> is an array containing the values that will be provided to the
/// controller, subscripted by property name.
Method %OnCopyDataFromModel(ByRef pData) As %Status [ Abstract ]
{
	Quit $$$OK
}

/// Return an array, subscripted by property name, describing the properties within this DataModel.<br>
/// These are returned as an array of the form:<br>
/// pInfo(name) = seqno<br>
/// If <var>pExtended</var> is true (1), then the array will include
/// additional nodes for each property. This information is used to 
/// create dynamic forms for this model.<br>
/// Applications should not change this method. To modify the information
/// returned by this method, override the <method>%OnGetPropertyInfo</method>
/// callback method.
ClassMethod %GetPropertyInfo(Output pInfo As %String, pExtended As %Boolean = 0, pModelId As %String = "", pContainer As %String = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %OnGetPropertyInfo ]
{
	#; define for backports
#ifndef ZENMVCNONE
#define ZENMVCNONE			0
#endif

	Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
	Do %code.WriteLine(" Set tSC = $$$OK")

	Set tClassName = %class.Name

	#; skip if we are the top level class
	If (tClassName '= "%ZEN.DataModel.ObjectDataModel") {

		#; figure out if this class should provide automatic localization
		#; For library (system) classes, localization occurs for %ZEN domain
		#; For non-library classes, check for non-%ZEN domain
		Set tLocalize = 0
		Set DOMAIN = $G(%parameter("DOMAIN"))
		If (%class.System > 0) {
			Set tLocalize = (DOMAIN '= "")
		}
		Else {
			Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%ZEN")
		}

		Set tSerialClass = $$$getClassType(tClassName)="serial"

		#; get list of properties, in sequence order
		#; skip library and Zen classes
		Set tSkipPackage("%Library")=""
		Set tSkipPackage("%XML")=""
		Set tSkipPackage("%ZEN.DataModel")=""
		Do ##class(%ZEN.Generator).GetOrderedProps(%compiledclass, .tListSeq, .tSkip,.tSkipPackage)

		#; now sort by ZENTAB (if present)
		#; first pick up everything with a tab order
		Set i = 0
		Set n = $O(tListSeq(""))
		While (n '= "") {
			Set tab = +$$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tListSeq(n),$$$cPROPparameter,"ZENTAB")
			If (tab > 0) {
				Set i = i + 1
				Set tListTab(tab,i) = tListSeq(n)
				Kill tListSeq(n)
			}
			Set n = $O(tListSeq(n))
		}
		
		#; build final list of props from the 2 lists
		Set c = 0
		Set tab = $O(tListTab(""))
		While (tab '= "") {
			Set i = $O(tListTab(tab,""))
			While (i '= "") {
				Set c = c + 1
				Set tList(c) = tListTab(tab,i)
				Set i = $O(tListTab(tab,i))
			}
			Set tab = $O(tListTab(tab))
		}
		Kill tListTab

		Set seq = $O(tListSeq(""))
		While (seq '= "") {
			Set c = c + 1
			Set tList(c) = tListSeq(seq)
			Set seq = $O(tListSeq(seq))
		}
		Kill tListSeq

		#; basic info: list of property names
		#; build proplist as a side effect
		#; for non-literal props, get the type
		Set tPropList = ""
		Set tCount = 0
		Set n = $O(tList(""))
		While (n '= "") {
			Set tPropName = tList(n)
			Set tTypeFlag = ""
			Set tLabel = ""
			Set tSerialProp = 0

			#; if control is "none" do not generate code
			Set ZENCONTROL = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"ZENCONTROL")
			If (ZENCONTROL'="none") {
				#; find a label for the property (if needed)
				Set ZENLABEL = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"ZENLABEL")
				Set CAPTION = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"CAPTION")
				If (ZENLABEL '= "") {
					Set tLabel = ZENLABEL
				}
				ElseIf (CAPTION '= "") {
					Set tLabel = CAPTION
				}
				#; get normalized type of property
				Set tType = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPtype)

				#; figure out the classtype for the property
				#; first normalize the type name
				If ((tType '[ ".") && (tType '[ "%")) {
					#; assume this type belongs to our package
					Set tType = $P(tClassName,".",1,$L(tClassName,".")-1) _ "." _ tType
				}
				Set tType = $$$NormalizeClassname(tType)
				Set tCollection = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPcollection)
				If ($$$classIsDataType(tType)) {
					If (tCollection="list") {
						Set tTypeFlag = $$$ZENMVCLIST
					}
					ElseIf (tCollection="array") {
						Set tTypeFlag = $$$ZENMVCARRAY
					}
					Else {
						#; literal
						$$$comClassKeyGetLvar(odbctype,tType,$$$cCLASSodbctype)
						Set tTypeFlag = $Case(odbctype,"DATE":$$$ZENMVCDATE,"TIME":$$$ZENMVCTIME,"INTEGER":$$$ZENMVCINTEGER,"FLOAT":$$$ZENMVCFLOAT,"BOOLEAN":$$$ZENMVCBOOLEAN,"BIT":$$$ZENMVCBOOLEAN,:"")
					}
				}
				Else {
					#; non-literal; determine its type
					Set ctype = $$$getClassType(tType)
					If (ctype = $$$cCLASSCLASSTYPESTREAM) {
						$$$comClassKeyGetLvar(odbctype,tType,$$$cCLASSodbctype)
						If (odbctype = "LONGVARCHAR") {
							Set tTypeFlag = $$$ZENMVCSTREAM
						}
						Else {
							Set tTypeFlag = $$$ZENMVCBSTREAM
						}
					}
					ElseIf (tCollection="list") {
						#; ignore object lists
						Set tTypeFlag = $$$ZENMVCNONE
					}
					ElseIf (tCollection="array") {
						Set tCardinality = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPcardinality)
						Set tInverse = $$$comMemberKeyGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPinverse)
						If ((tCardinality="")&&(tInverse="")) {
							#; ignore object arrays
							Set tTypeFlag = $$$ZENMVCNONE
						}
						Else {
							#; ignore relationships
							Set tTypeFlag = $$$ZENMVCNONE
						}
					}
					ElseIf (ctype="persistent") {
						Set tTypeFlag = $$$ZENMVCPERSISTENT
					}
					ElseIf (ctype="serial") {
						Set tSerialProp = 1
					}
					Else {
						Set tTypeFlag = $$$ZENMVCOBJECT
					}
				}

				If (tTypeFlag '= $$$ZENMVCNONE) {
					#; if this is a serial property, dispatch to it
					If (tSerialProp) {
						Do %code.WriteLine(" Set tSC = ##class("_tType_").%GetPropertyInfo(.pInfo,pExtended,pModelId,"""_tList(n)_""")")
						Do %code.WriteLine(" Quit:$$$ISERR(tSC) tSC")
						Set tPropList = tPropList _ $LB(tList(n) _ ":"_$$$ZENMVCSERIAL)
						Kill tList(n)
					}
					Else {
						#; if we are a serial class, generate code to test for pContainer
						If (tSerialClass) {
							Do %code.WriteLine(" Set tProp = $S(pContainer="""":"""",1:pContainer_""."")_"""_tList(n)_"""")
							Do %code.WriteLine(" Set pInfo(tProp) = $I(pInfo)")
							If (tTypeFlag '= "") {
								Do %code.WriteLine(" Set pInfo(tProp,""%ptype"") = """ _ tTypeFlag _ """")
							}
						}
						Else {
							Do %code.WriteLine(" Set pInfo("""_tList(n)_""") = $I(pInfo)")
							If (tTypeFlag '= "") {
								Do %code.WriteLine(" Set pInfo("""_tList(n)_""",""%ptype"") = """ _ tTypeFlag _ """")
							}
						}
						Set tPropList = tPropList _ $LB(tList(n) _ $S(tTypeFlag'="":":"_tTypeFlag,tLabel'="":":",1:"") _ $S(tLabel="":"",1:":"_tLabel))
					}
					Set tCount = tCount + 1
				}
			} // not none

			#; remember type for next step
			Set tTypeFlags(n) = tTypeFlag
			Set n = $O(tList(n))
		}

		#; generate extended info for dynaforms
		Do %code.WriteLine(" If (pExtended) {")
		Set n = $O(tList(""))
		While (n '= "") {
			Set tPropName = tList(n)
			Set ZENCONTROL = $$$comMemberArrayGet(tClassName,$$$cCLASSproperty,tPropName,$$$cPROPparameter,"ZENCONTROL")
			If ((ZENCONTROL'="none")&&($G(tTypeFlags(n))'=$$$ZENMVCNONE)) {
				If (tSerialClass) {
					Do %code.WriteLine("  Set tProp = $S(pContainer="""":"""",1:pContainer_""."")_"""_tPropName_"""")
				}
				Else {
					Do %code.WriteLine("  Set tProp = """_tPropName_"""")
				}
				#; Get utils class to generate code for us
				Set tSC = ##class(%ZEN.DataModelUtils).GeneratePropInfoCode(tList(n),tClassName, tPropName, %code, tLocalize)
			}
			Set n = $O(tList(n))
		}
		Do %code.WriteLine(" }")

		#; cache the property list (in $LB format)
		Set ^IRIS.TempCls($get(%ISCName,$job),tClassName,"ZENProperties") = tPropList

		#; check for callback
		If ($$$comMemberKeyGet(tClassName,$$$cCLASSmethod,"%OnGetPropertyInfo",$$$cMETHrunnable)) {
			Do %code.WriteLine(" Set tSC=..%OnGetPropertyInfo("_(tCount+1)_",.pInfo,pExtended,pModelId,pContainer)")
		}
	} // is ObjectDataModel class?

	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// This callback method, if present, is called by the <method>%GetPropertyInfo</method>
/// method. This gives subclasses the opportunity to add additional property
/// descriptions to the DataModel.<br>
/// <var>pIndex</var> is the index number that should be used to add the next
/// property to the list.<br>
/// <var>pInfo</var> is a multidimensional array containing information about the
/// properties of this data model.<br>
/// If <var>pExtended</var> is true, then complete information about the properties
/// should be returned; if false, then only property names need be returned (applications
/// can simply ignore this).<br>
/// <var>pModelId</var> is the id value of the current Data Model instance. This is provided
/// for cases where the contents of a dynamic form may vary by instance of the Data Model object.<br>
/// 
ClassMethod %OnGetPropertyInfo(pIndex As %Integer, ByRef pInfo As %String, pExtended As %Boolean = 0, pModelId As %String = "", pContainer As %String = "") As %Status [ Abstract ]
{
}

/// Return a comma-delimited list of properties within this DataModel,
/// including any virtual properties provided by the <method>%OnGetPropertyInfo</method>
/// <var>pContainer</var> is the containing property in the case of an embedded object.
/// This method is simply an optimization for cases where there is no user-defined
/// <method>%OnGetPropertyInfo</method> method.
ClassMethod %GetPropertyList(pModelId As %String = "", pContainer As %String = "") As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %GetPropertyInfo, Internal ]
{
	Set %code.CodeMode = "expression"
	If (($$$getClassType(%class.Name)="serial") || $$$comMemberKeyGet(%class.Name,$$$cCLASSmethod,"%OnGetPropertyInfo",$$$cMETHrunnable)) {
		#; if there is an OnGetPropertyInfo callback, use BuildPropertyList
		#; or if we are a serial object (to pick up pContainer)
		Do %code.WriteLine("..%BuildPropertyList(pModelId,pContainer)")
	}
	Else {
		#; just return a string
		Set tNeedComma = 0
		Set tList = ""
		Set tPropList = $G(^IRIS.TempCls($get(%ISCName,$job),%compiledclass.Name,"ZENProperties"))
		For n = 1:1:$LL(tPropList) {
			Set tName = $LG(tPropList,n)
			Set tType = $P(tName,":",2)
			Set tLabel = $P(tName,":",3)
			
			#; for embedded object, inject a call to its method
			If (tType = $$$ZENMVCSERIAL) {
				If (tNeedComma) {
					Do %code.Write("_"",""_")
				}
				If (tList'="") {
					#; write out first part of list
					Do %code.Write($$$quote(tList_",")_"_")
					Set tList = ""
				}
				Set tPropName = $P(tName,":",1)
				Set tCls = $$$comMemberKeyGet(%compiledclass.Name,$$$cCLASSproperty,tPropName,$$$cPROPtype)
				Do %code.Write("##class("_tCls_").%GetPropertyList(pModelId,"""_tPropName_""")")
				Set tNeedComma = 1
			}
			Else {
				Set tList = tList _ $S(tList="":"",1:",") _ tName
			}
		}
		If (tList="") {
			Do:'tNeedComma %code.WriteLine("""""")
		}
		Else {
			Do %code.WriteLine($S(tNeedComma:"_",1:"")_$$$quote($S(tNeedComma:",",1:"")_tList))
		}
	}
	Quit $$$OK
}

/// Internal method.<br>
/// Build a comma-delimited list of of properties within this DataModel
/// using the list returned by <method>%GetPropertyInfo</method>.
ClassMethod %BuildPropertyList(pModelId As %String = "", pContainer As %String = "") As %String [ Internal, Private ]
{
	Set tList = ""
	#; We must use extended info to pick up label
	Set tSC = ..%GetPropertyInfo(.tInfo,1,pModelId,pContainer)
	If $$$ISERR(tSC) Quit ""

	#; sort by ordinal position
	Set tName = $O(tInfo(""))
	While (tName '= "") {
		Set tSeq = +$G(tInfo(tName))
		Set:tSeq=0 tSeq=1000
		Set tSort(tSeq,tName)=""
		Set tName = $O(tInfo(tName))
	}

	#; build list in order	
	Set tSeq = $O(tSort(""))
	While (tSeq '= "") {
		Set tName = $O(tSort(tSeq,""))
		While (tName '= "") {
			Set tPType = $G(tInfo(tName,"%ptype"))
			Set tPLabel = $G(tInfo(tName,"label"))
			Set tList = tList _ $S(tList="":"",1:",") _ tName _ $S(tPType'="":":"_tPType,tPLabel'="":":",1:"") _ $S(tPLabel'="":":"_tPLabel,1:"")
			Set tName = $O(tSort(tSeq,tName))
		}
		Set tSeq = $O(tSort(tSeq))
	}
	Quit tList
}

/// Internal method.<br>
/// This generated method contructs client-side JS validation code
/// for the properties within this provider.
/// The client-side code is returned as a string that is converted to 
/// JS function at run-time.
ClassMethod %GetJSValidationCode() As %String [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
	Do %code.WriteLine(" Set tCode=""""")
	Do %code.WriteLine(" Set tCode=tCode_""switch(property) {""_$C(10)")

	#; loop over properties; test for <Prop>IsValidJS methods
	#; first test for local method, then test datatype class 
	For n=1:1:%compiledclass.Properties.Count() {
		Set tImp = ""
		Set pdef = %compiledclass.Properties.GetAt(n)
		If ##class(%Dictionary.CompiledMethod).%ExistsId(%class.Name _ "||" _ pdef.Name _ "IsValidJS") {
			Set mdef = ##class(%Dictionary.CompiledMethod).%OpenId(%class.Name _ "||" _ pdef.Name _ "IsValidJS")
			If ($IsObject(mdef)) {
				If ('mdef.ClassMethod || (mdef.Language '= "javascript")) {
					#; compile warning
					Write !,"NOTE: JS validation method, ",mdef.Name,", must be a class method with language=javascript.",!  
				}
				Else {
					Set tImp = mdef.Implementation
				}
			}
			Else {
				Write !,"Unable to open method definition: ",mdef.Name,!  
			}
		}
		Else {
			#; try datatype class
			Set tType = $$$NormalizeClassname(pdef.Type)
			If ##class(%Dictionary.CompiledMethod).%ExistsId(tType _ "||" _ "IsValidJS") {
				Set mdef = ##class(%Dictionary.CompiledMethod).%OpenId(tType _ "||" _ "IsValidJS")
				If ($IsObject(mdef)) {
					If ('mdef.ClassMethod || (mdef.Language '= "javascript")) {
						#; compile warning
						Write !,"NOTE: JS validation method, ",mdef.Name,", in datatype class must be a class method with language=javascript.",!  
					}
					Else {
						Set tImp = mdef.Implementation
					}
				}
				Else {
					Write !,"Unable to open method definition: ",mdef.Name,!  
				}
			}
		}

		#; get JS from method
		If ($IsObject(tImp)) {
			Do %code.WriteLine(" Set tCode=tCode_""case '"_pdef.Name_"':""_$C(10)")
			While ('tImp.AtEnd) {
				Set tJSCode = tImp.ReadLine()
				Set tJSCode = $Replace(tJSCode,"""","""""")
				Do %code.WriteLine(" Set tCode=tCode_"" "_tJSCode_"""_$C(10)")
			}
			Do %code.WriteLine(" Set tCode=tCode_"" break;""_$C(10)")
		}
	}
	Do %code.WriteLine(" Set tCode=tCode_""}""_$C(10)")
	Do %code.WriteLine(" Quit tCode")
	Quit $$$OK
}

/// Internal method.
/// This is called in order to get the SQL statements (specified
/// by the ZENSQL and ZENSQLLOOKUP parameters) that will provide a set of lookup 
/// values for a property.
ClassMethod %GetLookupSQL(pProperty As %String, Output pSQL As %String, Output pSQLLookup As %String) As %Status [ CodeMode = objectgenerator, Internal ]
{
	Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
	Do %code.WriteLine(" Set pSQL=""""")
	Do %code.WriteLine(" Set pSQLLookup=""""")
	Do %code.WriteLine(" Goto Dispatch")

	Set tList = ""
	Set tTagCount = 0

	#; loop over properties; 
	#; look for ZENSQL/ZENSQLLOOKUP parameters OR 
	#; persistent object references
	For n=1:1:%compiledclass.Properties.Count() {
		Set pdef = %compiledclass.Properties.GetAt(n)
		Set tPropClass = $$$NormalizeClassname(pdef.Type)

		#; test for serial properties
		#; we currently support only embedded objects that are one-level deep
		Set tType = $$$getClassType(tPropClass)
		If (tType = "serial") {
			Set classDef = ##class(%Dictionary.CompiledClass).%OpenId(tPropClass)
			For n2=1:1:classDef.Properties.Count() {
				Set pdef2 = classDef.Properties.GetAt(n2)
				Set ZENSQL = pdef2.Parameters.GetAt("ZENSQL")
				Set ZENSQLLOOKUP = pdef2.Parameters.GetAt("ZENSQLLOOKUP")
				If ((ZENSQL '= "")||(ZENSQLLOOKUP '= "")) {
					Set tTagCount = tTagCount + 1
					Set tList = tList _ $S(tList="":"",1:",") _ pdef.Name _ "." _ pdef2.Name
					Do %code.WriteLine("t"_tTagCount_" // "_pdef.Name _ "." _ pdef2.Name)
					Do %code.WriteLine(" Set pSQL = " _$$$quote(ZENSQL))
					Do %code.WriteLine(" Set pSQLLookup = " _$$$quote(ZENSQLLOOKUP))
					Do %code.WriteLine(" Goto Done")
				}
			}
		}
        Else {
			#; get property parameters
			Set ZENSQL = pdef.Parameters.GetAt("ZENSQL")
			Set ZENSQLLOOKUP = pdef.Parameters.GetAt("ZENSQLLOOKUP")

			#; generate default queries if none provided
			If (tType = "persistent") {
				#; ignore many side of relationships
				Set tSkip = 0
				Set tCollection = pdef.Collection
				If (tCollection="array") {
					Set tCardinality = pdef.Cardinality
					Set tInverse = pdef.Inverse
					If ((tCardinality'="")||(tInverse'="")) {
						Set tSkip = 1
					}
				}
				If ('tSkip) {
					If (ZENSQL="") {
						Set ZENSQL = ##class(%ZEN.DataModelUtils).GetSQLForProperty(%class.Name,pdef.Name)
					}
					If (ZENSQLLOOKUP="") {
						Set ZENSQLLOOKUP = ##class(%ZEN.DataModelUtils).GetSQLLookupForProperty(%class.Name,pdef.Name)
					}
				}
			}

			If ((ZENSQL '= "")||(ZENSQLLOOKUP '= "")) {
				Set tTagCount = tTagCount + 1
				Set tList = tList _ $S(tList="":"",1:",") _ pdef.Name
				Do %code.WriteLine("t"_tTagCount_" // "_pdef.Name)
				Do %code.WriteLine(" Set pSQL = " _$$$quote(ZENSQL))
				Do %code.WriteLine(" Set pSQLLookup = " _$$$quote(ZENSQLLOOKUP))
				Do %code.WriteLine(" Goto Done")
			}
        }
	}

	Do %code.WriteLine("Dispatch")
	If (tList'="") {
		Do %code.Write(" Goto $Case(pProperty,")
		For n=1:1:tTagCount {
			Do %code.Write($$$quote($P(tList,",",n))_":t"_n_",")
		}
		Do %code.WriteLine(":Done)")
	}
	Do %code.WriteLine("Done")
	Do %code.WriteLine(" Quit $$$OK")
	Quit $$$OK
}

/// Provide a property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
/// This method is only generated if the DYNAMICPROPERTIES parameter is true.
Method %DispatchGetProperty(pProperty As %String) [ CodeMode = objectgenerator, Internal ]
{
	If +$G(%parameter("DYNAMICPROPERTIES")) {
		Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
		Do %code.WriteLine(" Quit $G(..%data(1,pProperty))")
	}
	Quit $$$OK
}

/// Provide a property dispatch method to catch references to 
/// virtual properties.<br>
/// This should not be called directly.<br>
/// This method is only generated if the DYNAMICPROPERTIES parameter is true.
Method %DispatchSetProperty(pProperty As %String, pValue As %String) [ CodeMode = objectgenerator, Internal ]
{
	If +$G(%parameter("DYNAMICPROPERTIES")) {
		Do %code.WriteLine(" // Generated by %ZEN.DataModel.ObjectDataModel")
		Do %code.WriteLine(" Set ..%data(1,pProperty) = pValue")
	}
	Quit $$$OK
}

/// Internal method.<br>
/// If a form connected to this DataModel is submitted, this method handles the
/// server-side processing of the submit.
ClassMethod %SubmitHandler(pSubmit As %ZEN.Submit) As %Status
{
	// Defined by %ZEN.DataModel.ObjectDataModel")

	Set tSC = $$$OK

	Do {
		#; id is in FormKey
		Set tID = pSubmit.%FormKey
	
		#; open instance of DataModel class 
		Set tModel = ..%OpenModel(tID,,.tSC)
		If $$$ISERR(tSC)||'$IsObject(tModel) Quit
	
		#; copy submitted data into an array so that
		#; we can pass it to the pre-generated %CopyDataToModel method

		Merge tData(1) = pSubmit.%Data
		Set tSC = tModel.%CopyDataToModel(.tData)
		If $$$ISERR(tSC) Quit
		
		#; invoke callback
		Set tSC = tModel.%OnSubmit(pSubmit)
		If $$$ISERR(tSC) Quit
	} While(0)
	
	Quit tSC
}

/// If defined, this callback is called when a form connected to this 
/// DataModel is submitted.<br>
/// The contents of this DataModel will be filled in from the submitted values
/// before this callback is invoked.<br>
/// The default implementation is to store the submitted values back to the model.
Method %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	#; try to save this model
	Set tSC = ..%SaveModel()
	Quit tSC
}

}
