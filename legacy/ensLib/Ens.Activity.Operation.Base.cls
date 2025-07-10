/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Activity.Operation.Base Extends Ens.BusinessOperation [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// How frequently the activity statistics should be moved into permanent storage. <br>
/// 0 means do not check. Default is 60 seconds.
Property RecordStatsInterval As %Numeric [ InitialExpression = 60 ];

Property %Instance As %String(MAXLEN = 128) [ InitialExpression = {##class(%SYS.System).GetUniqueInstanceName()}, Private, Transient ];

Property %StatsInterval As %Integer [ InitialExpression = {##class(Ens.Util.Statistics).StatsCounterInterval()}, Private, Transient ];

/// How long to keep retrying before giving up and returning an error code. <br/>
/// -1 means never give up.
Property FailureTimeout As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// If System Alert and Monitoring for interoperability is enabled then
/// provide statistics for SAM only and not also for persistent tables. <br>
/// Default is to store in persistent tables as well.
Property SAMOnly As %Boolean [ InitialExpression = 0 ];

/// Class that contains the XData JSON definition
Property SAMDefinitionClass As %String [ InitialExpression = "Ens.SAM.SensorDefinitions" ];

/// XData JSON definition name
Property SAMDefinitionXData As %String [ InitialExpression = "EnsActivityOperationBase" ];

Parameter SETTINGS = "RecordStatsInterval,SAMOnly:Additional";

Method OnInit() As %Status
{
	If ..RecordStatsInterval>0 Set ..Adapter.KeepaliveInterval=..RecordStatsInterval

	#dim tIsSAMSamplingEnabled, tSAMStatus
	$$$EnsSetSAMSampler(..SAMDefinitionClass,..SAMDefinitionXData,.tIsSAMSamplingEnabled,.tSAMStatus)
	If $$$ISERR(tSAMStatus) $$$LOGERROR("Error initializing SAM Sensor "_$$$StatusDisplayString(tSAMStatus))

	Quit ##super()
}

Method OnKeepalive(pAdapterStatus As %Status) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	#dim tNamespace, tHostName, tUserDimension, tUTC As %String
	#dim tDay, tSecondsSlot, tHostType, tCount, tSeconds As %Integer
	#dim tTimeStampDay, tTimeStampSeconds As %Integer
	
	#dim tDuration, tQueueDuration, tSquares As %Numeric
	
	If $$$ISOK(pAdapterStatus),(..RecordStatsInterval>0) {
		Try {

			#; need to be able to calculate time span of temp data
			#dim tEarliestUTC
			Set tEarliestUTC("day")=""
			#dim tLatestUTC
			$$$EnsStartSAMSample

			// Sample data:
			// $$$StatsPersistCountersRoot("DEVBUS~2336",63334,6704,1,"RESTaCSP3","enterpriseid 525","count") = 20
			// $$$StatsPersistCountersRoot("DEVBUS~2336",63334,6704,1,"RESTaCSP3","enterpriseid 525","duration") = .225824
			// $$$StatsPersistCountersRoot("DEVBUS~2336",63334,6704,1,"RESTaCSP3","enterpriseid 525","queue") = .5
			// $$$StatsPersistCountersRoot("DEVBUS~2336",63334,6704,1,"RESTaCSP3","enterpriseid 525","d2") = .0144
			Set tNamespace = $O($$$StatsPersistCountersRoot(($NAMESPACE_"~")))
			While ($NAMESPACE=$P(tNamespace,"~",1)) {
				Set tDay = ""
				Set tTimeStampDay = $ZTS
				Set tTimeStampSeconds = $P(tTimeStampDay,",",2)\..%StatsInterval*..%StatsInterval // Current tSeconds slot
				Set tTimeStampDay = +tTimeStampDay
				For {
					Set tDay = $O($$$StatsPersistCountersRoot(tNamespace,tDay))
					If (tDay="") Quit
					Set tSecondsSlot = ""
					For {
						Set tSecondsSlot = $O($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot))
						If tSecondsSlot="" Quit
						If (tDay<tTimeStampDay) || ((tDay=tTimeStampDay) && ($P(tSecondsSlot,",",2)<tTimeStampSeconds)) {
							// Time slot is in the past
							Set tHostType = ""
							For {
								Set tHostType = $O($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType))
								If tHostType="" Quit
								Set tHostName = ""
								For {	
									Set tHostName = $O($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName))
									If tHostName="" Quit
									Set tUserDimension = ""
									For {
										Set tUserDimension = $O($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName,tUserDimension))
										If tUserDimension="" Quit
										Set tCount = $G($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName,tUserDimension,"count"),0)
										Set tDuration = $G($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName,tUserDimension,"duration"),0)
										Set tQueueDuration = $G($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName,tUserDimension,"queue"),0)
										Set tSquares = $G($$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName,tUserDimension,"d2"),0)
										Set tSeconds = (tSecondsSlot*..%StatsInterval)
										Set tUTC = $ZDT(tDay_","_tSeconds,3)
										If (tEarliestUTC("day")="") {
											Set tEarliestUTC("day") = tDay
											Set tLatestUTC("day") = tDay
											Set tEarliestUTC("seconds") = tSeconds
											Set tLatestUTC("seconds") = tSeconds
										} Else {
											If ((tDay<tEarliestUTC("day"))||((tDay=tEarliestUTC("day"))&&(tSeconds<tEarliestUTC("seconds")))) {
												Set tEarliestUTC("day") = tDay
												Set tEarliestUTC("seconds") = tSeconds
											}
										}
										If ((tDay>tLatestUTC("day"))||((tDay=tLatestUTC("day"))&&(tSeconds>tLatestUTC("seconds")))) {
											Set tLatestUTC("day") = tDay
											Set tLatestUTC("seconds") = tSeconds
										}
										Set tLocalTime = $$$timeUTCtoLocal(tUTC)
										#;"SC" = stats counters										
										If '..SAMOnly Set tSC = ..OnAddActivity("SC",tDay,tSecondsSlot,tLocalTime, tUTC, ..%Instance, tNamespace, tHostType, tHostName, $ZSTRIP(tUserDimension,"<>W"), tCount, tDuration, tQueueDuration, tSquares)
										If (tSC || ..SAMOnly) {
											#; Ensure clean up local before trying SAM Sample recording
											Kill $$$StatsPersistCountersRoot(tNamespace,tDay,tSecondsSlot,tHostType,tHostName,tUserDimension) // Not using a lock here to avoid slowing things down, it is unlikely to need a lock as only sending data in past tSeconds slot
											Do ..OnCollectSAMSample(tHostType, tHostName, $ZSTRIP(tUserDimension,"<>W"), tCount, tDuration, tQueueDuration)
										} Else {
											Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
										}
									} // End loop on tUserDimension
								} // End loop on tHostName
							} // End loop on tHostType
						} // End if
					} // End loop on tSecondsSlot
				} // End loop on tDay
				Set tNamespace = $O($$$StatsPersistCountersRoot(tNamespace))
			} // End while tNamespace
		} Catch e {
			Set tSC = e.AsStatus()
		}

		 /*	For the PerSec calc we need to know diff b/n max and min UTC in this sample collection.
			Initialize to polling interval of this operation incase no sample data. tEarliestUTC("day") will always be defined.
			Precise elapased town is going to be rounded to ..%StatsInterval slots.
		*/
		#dim tTempDataElapsedTime = ..RecordStatsInterval
		
		Try {
			#dim tStartSample, tEndSample
			If (tEarliestUTC("day")'="") {
				Set tStartSample = $ZDT((tEarliestUTC("day")_","_tEarliestUTC("seconds")),3)
				Set tEndSample = $ZDT((tLatestUTC("day")_","_tLatestUTC("seconds")),3)
				Set tTempDataElapsedTime = $SYSTEM.SQL.DATEDIFF("ss",tStartSample,tEndSample)
			}
		} Catch {}

		$$$EnsCompleteSAMSample(tTempDataElapsedTime)

		If $$$ISERR(tSC) {
			Set pAdapterStatus = tSC
		} Else {
			$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"OK")
			#If ..#INVOCATION="Queue"
				$$$SetJobMonitor(..%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorStatus,"OK")
			#EndIf
		}
	} //End if pAdapterStatus ok
	Quit ##super(pAdapterStatus)
}

/// SubClass responsibility <br>
/// Only return an error if expect a retry will be successful as 
/// returning an error will mean the temporary data is not deleted <br>
/// Expected parameters are 
/// "SC",tLocalTime, tUTC, ..%Instance, tNamespace, tHostType, tHostName, tUserDimension, tCount, tDuration, tQueueDuration, tSquares
Method OnAddActivity(pStatsCategory As %String = "SC", pDays, pSeconds, pLocalTime, pUTC, pInstance, pNamespace, pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration, pSquares) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

Method OnCollectSAMSample(pHostType, pHostName, pUserDimension, pCount, pDuration, pQueueduration) As %Status
{
	/*
		Metrics:
			MessageActivityCount
			Average ActivityMessage Processing time
			Average ActivityMessage Queue Duration
		With labels of:
			Namespace
			Production
			Hosttype
			Hostname
			Message Type or other User Dimension.


	*/
	Try {
		#dim labels = "hosttype="_$$$EnsSAMSampler.HostTypeMap(pHostType)
		Set labels = labels_","_$$$EnsSAMHostLabelAndValue(pHostName)_","_"messagetype="_pUserDimension
		$$$EnsCollectOneSAMSample("InteropSampleCount",pCount,labels)
		$$$EnsCollectOneSAMSample("InteropAvgProcessingTime",pDuration,labels)
		$$$EnsCollectOneSAMSample("InteropAvgQueueingTime",pQueueduration,labels)
	} Catch {}
	Quit $$$OK
}

/// If collecting SAM data then remove last sample by this code.
/// This is  needed since this sampler might not be running but the Production is. <br>
Method OnTearDown() As %Status
{
	$$$EnsRemoveLastRecordedSensorSample
	Return ##super()
}

}
