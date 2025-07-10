/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %syInterop)

Class Ens.SAM.SensorSampler Extends %RegisteredObject [ Language = objectscript, System = 4 ]
{

/// Storage for Sensor info - HELP & UNIT
Property SAMSensorInfo As %String [ MultiDimensional ];

/// Storage for Sensor data during one sample
Property SAMSensorReadings As %String [ MultiDimensional ];

/// Storage for Sensor data Calculated during one sample
Property SAMSensorCalculatedReadings As %String [ MultiDimensional ];

/// Storage for Sensor data from last sample recording
/// to aid pruning
Property LastSAMSensorReadings As %String [ MultiDimensional ];

/// Storage for Sensor data Calculated during one sample from last
/// sample recording to aid pruning
Property LastSAMSensorCalculatedReadings As %String [ MultiDimensional ];

/// Array of Sensor names this instance will sample
/// Sensor names are Camel Case
/// Sensor types: Counter, Gauge, Histogram, Summary.
/// Which Counter types ought to calculate per sec 
/// Counter, CounterWithPerSec, Gauge, Histogram, Summary
Property SAMSensors As %String [ MultiDimensional ];

/// Label 'production' equal to name of current running production
Property SAMProductionLabel As %String [ InitialExpression = {$ListBuild($$$EnsSAMProductionLabel,$Get($$$EnsRuntime("Name")))} ];

/// Flag to indicate if include production name as data for label 'production'
/// Used  in conjunction with sensorLabels that are defined in the definition.Br> 
/// Defaults to true
Property IncludeProductionLabel As %Boolean [ InitialExpression = {$$$SAMInteropIncludeProdLabelGet} ];

/// Flag to indicate if include host name as data for Business Host label<br>
/// Busines Host label is defined as $$$EnsSAMHostLabel "host"<br>
/// Used  in conjunction with sensorLabels that are defined in the definition.Br> 
/// Defaults to true.<br>
Property IncludeHostLabel As %Boolean [ InitialExpression = {$$$SAMInteropIncludeHostLabelGet} ];

/// Internal $ZH for calculating time since last sample
Property lastSamplePointInTime As %Numeric [ InitialExpression = {$ZH} ];

/// Storage for last Sample data needed to calculate per second
Property lastPerSecSensorReadings As %String [ MultiDimensional ];

/// The code checks if SAM recording is enabled for the Interoperability SAM <br>
/// Set this to 1 to force SAM recording even if SAM recording is not enabled for the Interoperability SAM 
Property ForceSAMEnabled As %Boolean [ InitialExpression = 0 ];

/// Array of labels that can be collected <br>
/// If empty then all labels requested will be recorded <br>
/// Array can be populated when initialized using the JSON definition 
/// sensors.sensorLabels array.<br>
Property RegisteredLabels As %String [ MultiDimensional ];

/// Map used to translate host types
Property HostTypeMap As %String [ MultiDimensional ];

/// OnNew optional populate sensor names
/// Any error thrown initializing will be suppressed
/// inorder to return a sampler instance
Method %OnNew(ByRef pSensors) As %Status [ Private, ServerOnly = 1 ]
{
	Try {
		If $Data(pSensors) Do ..SetSensors(.pSensors)
		#dim tHostType
		For tHostType=0:1:4 Set ..HostTypeMap(tHostType)=##class(EnsPortal.Utils).getHostTypeString(tHostType)
	} Catch {}
	Quit $$$OK
}

/// Takes sensors definition (either as an array or object) 
/// and  populate instance data.
Method SetSensors(ByRef pSensors)
{
	If $IsObject(pSensors) {

		Do ..initSensorsFromObject(pSensors)

	} Else {

		Do ..initSensorsFromArray(.pSensors)

	}
}

Method initSensorsFromObject(pSensors As %DynamicArray)
{
	/* If dynamic array object 
		"sensorName":"InteropHosts",
		"sensorType":"Gauge",
		"sensorUnit":"",
		"sensorDescription":"Count of host items",
		"sensorLabels" : [
							"namespace",
							"production",
							"status"
						]
	*/
	#dim tSensorIterator = pSensors.%GetIterator()

	#dim tSensorNumber,tSensor
	While tSensorIterator.%GetNext(.tSensorNumber, .tSensorDefinition) {

		Set ..SAMSensors(tSensorDefinition.sensorName) = tSensorDefinition

		Set tSensorType = tSensorDefinition.sensorType
		If tSensorType = "" Set tSensorType = $$$SAMInteropMetricDefault
		/*	Set meta data using 0 in the label subscript position
			The types that are WithPerSec will be handled in the central collector %Library.InteroperabilityMgr::SetSAMSensors()
		*/
		Set ..SAMSensorInfo(tSensorDefinition.sensorName,tSensorType,0,"HELP")=tSensorDefinition.sensorDescription
		Set ..SAMSensorInfo(tSensorDefinition.sensorName,tSensorType,0,"UNIT")=tSensorDefinition.sensorUnit

		Do ..initRegisteredLabels(tSensorDefinition.sensorLabels)

	}
}

Method initSensorsFromArray(ByRef pSensors)
{

	#dim tSensor, tSensorDefinition, tSensorType
	Set tSensor = $Order(pSensors(""),1,tSensorDefinition)

	While (tSensor'="") {

		If tSensorDefinition'["{" {

			Set tSensorType = tSensorDefinition
			If tSensorType = "" Set tSensorType = $$$SAMInteropMetricDefault

			Set tSensorDefinition = {}
			Set tSensorDefinition.sensorType = tSensorType

		} Else {

			Try {
				Set tSensorDefinition = {}.%FromJSON(tSensorDefinition)
				Do ..initRegisteredLabels(tSensor.sensorLabels)
			} Catch {
				Set tSensorDefinition = {}
				Set tSensorDefinition.sensorType = $$$SAMInteropMetricDefault
			}

		}

		Set ..SAMSensors(tSensor) = tSensorDefinition

		Set tSensor = $Order(pSensors(tSensor),1,tSensorDefinition)

	}
}

/// Method to loop over sensor definition sensorLabels and populate instance array
Method initRegisteredLabels(pSensorLabels As %DynamicArray) [ Internal ]
{
	#dim tLabelsIterator = pSensorLabels.%GetIterator()

	#dim tLabelNumber,tLabel
	While tLabelsIterator.%GetNext(.tLabelNumber, .tLabel) {

		If tLabel'="" Set ..RegisteredLabels(tLabel) = ""

	}
}

/// Clean up last sample of data
Method StartSensorSample()
{
	#; No need to check if enabled
	Kill ..SAMSensorReadings
	Kill ..SAMSensorCalculatedReadings
}

/// pLabels is an optional  comma separate list of label=value or
/// an array where label name is the key. <br>
/// This method always add namespace as the id label. <br>
Method CollectOneSensorSample(pSensorName As %String, pSensorData, ByRef pLabels As %String = "")
{
	If '..ForceSAMEnabled && '$$$SAMInteropEnabled Return

	#dim tSensorInfo As %DynamicObject

	#; Check we are supposed to sample this sensor
	If '($Data(..SAMSensors(pSensorName),tSensorInfo)#2) Return

	#; Will always add namespace as the id label
	#dim tLabelsList = ""

	If (pLabels'="") Set tLabelsList = ..labelsAsListFromInput(.pLabels)

	Do ..addProductionLabelIfIncluded(.tLabelsList)

	#; Find type of sensor/metric from initial object/
	Set tSensorInfo = ..SAMSensors(pSensorName)
	#dim tType = tSensorInfo.sensorType
	If tType = "" Set tType = $$$SAMInteropMetricDefault

	#; We increment since this allows caller to call more than once per a caller's cycle 
	Do $Increment(..SAMSensorReadings(pSensorName,tType,$$$SAMInteropLabelsWithNamespace($namespace,tLabelsList)),pSensorData)
	#; Track collectioned per sensor for external use
	Do $Increment(..SAMSensorReadings(pSensorName))
}

/// Pass in the Elapsed Time used to calculate average per second
/// to override elapsed time calculated since last sample.
Method CompleteSensorSample(pOverrideElapsedTime As %Integer)
{
	If '..ForceSAMEnabled && '$$$SAMInteropEnabled Return

	Try {
		#; Sensors not recorded in ..SAMSensorReadings are set to 0
		#; Calculate the _"PerSec" sensors for "^ps"
		Do ..preRecordingCalculations(.pOverrideElapsedTime)
		#; Copy data for central SAM reporter
		Do ..RecordSensorSamples()
	} Catch {}
}

Method RecordSensorSamples()
{
	Try {

		/*	Since the values of labels might change for certain entries, for example status values
			we need to call ..RemoveLastRecordedSensorSample().
			We need to ensure that multiple processes recording for the same 
			SensorName do not delete others' data.
			Merge ..SAMSensorReadings and ..SAMSensorCalculatedReadings
			into ..LastSAMSensorReadings & ..LastSAMSensorCalculatedReadings
			call RemoveLastRecordedSensorSample that clears from $$$SAMInteropCentralGlobal($namespace) the
			entries from ..LastSAMSensorReadings & ..LastSAMSensorCalculatedReadings that will not be
			added in current update
		*/
		Do ..RemoveLastRecordedSensorSample(1)

		Kill ..LastSAMSensorReadings
		Kill ..LastSAMSensorCalculatedReadings
		Merge ..LastSAMSensorReadings = ..SAMSensorReadings
		Merge ..LastSAMSensorCalculatedReadings = ..SAMSensorCalculatedReadings

		Merge $$$SAMInteropCentralGlobal($namespace) = ..SAMSensorInfo
		Merge $$$SAMInteropCentralGlobal($namespace) = ..SAMSensorReadings

		Merge $$$SAMInteropCentralGlobal($namespace) = ..SAMSensorCalculatedReadings

		Set ..lastSamplePointInTime = $ZH

	} Catch {/* if unexpected error exit since metric gathering */}
}

/// If collecting SAM data then remove last sample.
/// If the code using this calls might not be running when the Production is running it is 
/// is necessary to call this when exiting , for example during OnTearDown(). <br>
/// The parameter pOnlyLastInstanceSample is set to true when recording current values
/// to ensure prior data is pruned.
Method RemoveLastRecordedSensorSample(pOnlyLastInstanceSample As %Boolean = 0)
{
	#; No need to check if SAM sampling enabled.
	Try {
		For tArray = "SAMSensorReadings","SAMSensorCalculatedReadings" {
			Set tLastArray = "..Last"_tArray
			Set tCurrentArray = ".."_tArray
			Set tArraySubscripts = $Query(@tLastArray@(""))
			While tArraySubscripts'="" {
				If ($QLength(tArraySubscripts)=3) {
					#; Only remove if not replacing
					If 'pOnlyLastInstanceSample || '$Data(@tCurrentArray@($Data(@tCurrentArray@($QSubscript(tArraySubscripts,1),$QSubscript(tArraySubscripts,2),$QSubscript(tArraySubscripts,3))))) {
						Kill $$$SAMInteropCentralGlobal($namespace,$QSubscript(tArraySubscripts,1),$QSubscript(tArraySubscripts,2),$QSubscript(tArraySubscripts,3))
						If $Order($$$SAMInteropCentralGlobal($namespace,$QSubscript(tArraySubscripts,1),$QSubscript(tArraySubscripts,2),0))="" {
							#; Remove sensor info subscripts if no labels
							Kill $$$SAMInteropCentralGlobal($namespace,$QSubscript(tArraySubscripts,1),$QSubscript(tArraySubscripts,2),0)
						}
					}
				}
				Set tArraySubscripts=$Query(@tArraySubscripts) 
			}
			If 'pOnlyLastInstanceSample {
				/*	Remove top level data for sensors this instance
					If no other hosts have been using this sensor - ie after clean out of the ones we set.
					This is the default and is called for example by OnTearDown
				*/
				Set tSensor = $Order(@tLastArray@(""))
				While (tSensor'="") {
					If $Data($$$SAMInteropCentralGlobal($namespace,tSensor))=1 Kill $$$SAMInteropCentralGlobal($namespace,tSensor)
					Set tSensor = $Order(@tLastArray@(tSensor))
				}
			}
		}
	} Catch {/* if unexpected error exit since metric gathering */}
}

/// Internal method to convert label input into list structure for SAM <br>
/// Filters labels to those that are allowed. <br>
/// Supports comma delimited or array list. <br>
Method labelsAsListFromInput(ByRef pLabels As %String) As %String [ Internal ]
{
	#dim tLabelsAsList = ""
	#dim tCounter,tLabel,tValue
	If $Get(pLabels)["=" {
		For tCounter=1:1:$L(pLabels,",") {
			Set tLabel=$P(pLabels,",",tCounter)
			Set tValue=$ZStrip($Piece(tLabel,"=",2),"<>W")
			Set tLabel=$ZStrip($Piece(tLabel,"="),"<>W")
			If (tLabel'="") Do ..addToRegisteredLabelList(.tLabelsAsList,tLabel,tValue)
		}
	} ElseIf $Data(pLabels)>1 {
		Set tLabel=$Order(pLabels(""),1,tValue)
		While (tLabel'="") {
			Do ..addToRegisteredLabelList(.tLabelsAsList,tLabel,tValue)
			Set tLabel=$Order(pLabels(tLabel),1,tValue)
		}
	}
	Return tLabelsAsList
}

/// Internal method to build label list filtered by RegisteredLabels
/// pLabelsAsList must defined by caller.
Method addToRegisteredLabelList(ByRef pLabelsAsList As %String, pLabel As %String, pValue As %String) [ Internal ]
{
	If ('$Data(..RegisteredLabels) || $Data(..RegisteredLabels(pLabel))) {
		If ((pLabel'=$$$EnsSAMHostLabel)||..IncludeHostLabel) {
			#dim tListLabel = $ListBuild(pLabel,pValue)
			#; Ensure no duplicates.
			If '$ListFind(pLabelsAsList,tListLabel) Set pLabelsAsList = pLabelsAsList_$ListBuild(tListLabel)
		}
	}
}

/// Internal method add production label if required.
/// pLabelsAsList must defined by caller.
Method addProductionLabelIfIncluded(ByRef pLabelsAsList As %String) [ Internal ]
{
	If ..IncludeProductionLabel && ('$Data(..RegisteredLabels) || $Data(..RegisteredLabels($$$EnsSAMProductionLabel))) {
		#; Ensure no duplicates.
		If '$ListFind(pLabelsAsList,..SAMProductionLabel) Set pLabelsAsList = pLabelsAsList_$ListBuild(..SAMProductionLabel)
	}
}

Method preRecordingCalculations(pOverrideElapsedTime As %Integer) [ Internal ]
{
	Do ..postProcessSensorValues()
	Do ..calculatePerSec(.pOverrideElapsedTime)
}

/// Set undefined to 0
/// Re-calculate those values dependent on another sensor's values
/// Record sensor info
Method postProcessSensorValues() [ Internal ]
{
	#dim tSensorDefinition
	#dim tSensorLabels = ""
	#dim tSensorValue
	#dim tSensorAverageBy
	#dim tSensorType
	#dim tSensorAverageByType

	#dim tSensor = $Order(..SAMSensors(""),1,tSensorDefinition)

	While (tSensor'="") {

		Kill tSensorLabels

		Set tSensorType = tSensorDefinition.sensorType

		If tSensorType = "" Set tSensorType = $$$SAMInteropMetricDefault

		#; If no readings for any labels for this sensor
		If '$Data(..SAMSensorReadings(tSensor)) {

			#; Set to zero
			Set tSensorLabels = ""
			Do ..addProductionLabelIfIncluded(.tSensorLabels)
			Set ..SAMSensorReadings(tSensor,tSensorType,$$$SAMInteropLabelsWithNamespace($namespace,tSensorLabels)) = 0

		} ElseIf (tSensorDefinition.sensorValueAverageBy '= "") {

			#; Re-calculate value to average for all different labels
			Set tSensorType = $Order(..SAMSensorReadings(tSensor,""))
			While (tSensorType'="") {

				Set tSensorLabels = $Order(..SAMSensorReadings(tSensor,tSensorType,""),1,tSensorValue)
				While tSensorLabels'="" {

					Set tSensorAverageByType = $Order(..SAMSensorReadings(tSensorDefinition.sensorValueAverageBy,""))
					If (tSensorAverageByType'="") {
						Set tSensorAverageBy = +$Get(..SAMSensorReadings(tSensorDefinition.sensorValueAverageBy,tSensorAverageByType,tSensorLabels))
						If tSensorAverageBy {
							Set ..SAMSensorReadings(tSensor,tSensorType,tSensorLabels)=$number((tSensorValue/tSensorAverageBy),2)
						} Else {
							#; Set to zero since we cannot calculate due to missing denominator
							Set ..SAMSensorReadings(tSensor,tSensorType,tSensorLabels)=0
						}
					}

					Set tSensorLabels = $Order(..SAMSensorReadings(tSensor,tSensorType,tSensorLabels),1,tSensorValue)
				}

				Set tSensorType = $Order(..SAMSensorReadings(tSensor,tSensorType))
			}

		}

		Set tSensor = $Order(..SAMSensors(tSensor),1,tSensorDefinition)
	}
}

Method calculatePerSec(pOverrideElapsedTime As %Integer) [ Internal ]
{
	#dim tSensorDefinition
	#dim tLabels = ""
	#dim tElapsedSeconds = ($ZH - ..lastSamplePointInTime)
	If +$Get(pOverrideElapsedTime,0)>0 Set tElapsedSeconds = +pOverrideElapsedTime
	#dim tSensor = $Order(..SAMSensorReadings(""))
	While (tSensor'="") {
		#dim tType = $Order(..SAMSensorReadings(tSensor,""))
		While (tType'="") {
			If tType[$$$SAMInteropMetricPerSecIdentifier {
				Do ..calculatePerSecForSensor(tSensor,tType,tElapsedSeconds)
			}
			Set tType = $Order(..SAMSensorReadings(tSensor,tType))
		}
		Set tSensor = $Order(..SAMSensorReadings(tSensor))
	}
}

Method calculatePerSecForSensor(pSensorName, pType, pElapsedSeconds As %Numeric = 0) [ Internal ]
{
	Try {
		#dim data, previousData, rate
		#dim tLabels = $Order(..SAMSensorReadings(pSensorName,pType,""),1,data)
		While (tLabels'="") {

			Set rate = 0

			If (pElapsedSeconds) {

				If pType = $$$SAMInteropMetricCounterWithPerSec {

					If ($Data(..lastPerSecSensorReadings(pSensorName,pType,tLabels),previousData)#2) {

						Set rate=$number(((data - previousData) / pElapsedSeconds),2)

					}

					Set ..lastPerSecSensorReadings(pSensorName,pType,tLabels)=data

				} Else {

					Set rate=$number(((data) / pElapsedSeconds),2)

				}

			}

			Set ..SAMSensorCalculatedReadings((pSensorName_"PerSec"),pType,tLabels)=rate

			Set tLabels = $Order(..SAMSensorReadings(pSensorName,pType,tLabels),1,data)
		}

	} Catch {}
}

/// This returns how many seconds since the last sample was recorded
/// or the sampling was started if a recording has not taken place.
Method CurrentSampleDuration() As %Numeric
{
	Return $ZH-..lastSamplePointInTime
}

/// Number of times CollectOneSensorSample has been called
/// for pSensorName
Method SamplesCollectedForSensor(pSensorName As %String) As %Integer
{
	Return $Get(..SAMSensorReadings(pSensorName),0)
}

/// This method can be used during development to remove all 
/// centrally recorded Interoperability Sensor data for this namespace.<br>
/// This is to help where Sensor names change. <br>
ClassMethod RemoveAllRecordedSensorSample()
{
	Kill $$$SAMInteropCentralGlobal($namespace)
}

}
