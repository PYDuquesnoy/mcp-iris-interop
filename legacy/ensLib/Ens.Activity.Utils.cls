/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Data synchronization.<br>
Class Ens.Activity.Utils Extends %RegisteredObject [ System = 4 ]
{

/// tLocalTime, tUTC, tInstance, tNamespace, tHostType, tHostName, tUserDimension, tCount, tDuration, tQueueduration, tSquares
/// Last parameter is output parameter than advises if can retry on error returned
ClassMethod AddActivity(pTimeSlot As %String, pTimeSlotUTC As %String, pInstance As %String, pNamespaceJob As %String, pHostType As %String, pHostName As %String, pSiteDimension As %String, pCount As %String, pDuration As %String, pQueueDuration As %String, pDurationSquare As %String, Output pCanRetryOnError = 0) As %Status [ Internal ]
{

	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tCurrentJournal As %Integer = 0

	#dim tNamespace As %String

	#dim tTargetTimeSlotUTC, tTargetTimeSlot As %String

	#dim tCurCount, tCurDuration, tCurQueueDuration, tCurSquares As %Numeric
	#dim tID As %String

	#dim tLocked As %Integer

	Try {

		Set tNamespace = $P(pNamespaceJob,"~",1)

		Set tTargetTimeSlotUTC = pTimeSlotUTC
		Set tTargetTimeSlot = pTimeSlot

		Set tLocked = 0 
		If pSiteDimension = "" Set pSiteDimension = "-"
		Lock +^Ens.Activity.Data.Control(pInstance,pSiteDimension,tNamespace,pHostName):$SYSTEM.SQL.GetLockTimeout()
		If '$T {
			Set tSC = $$$ERROR($$$GeneralError,"Failed to obtain exclusive lock to allow for possible multiple updating processes. Retryable.")
			Set pCanRetryOnError = 1
			Quit
		} Else {
			Set tLocked = 1
		}
		TStart

		&sql( SELECT ID, TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare INTO :tID, :tCurCount, :tCurDuration, :tCurQueueDuration, :tCurSquares
		FROM Ens_Activity_Data.Seconds 
		WHERE TimeSlotUTC=:tTargetTimeSlotUTC AND Instance=:pInstance AND SiteDimension=:pSiteDimension AND Namespace=:tNamespace AND HostName=:pHostName
		)
		If SQLCODE=0 {
			Set tCurCount = tCurCount + pCount
			Set tCurDuration = tCurDuration + pDuration
			Set tCurQueueDuration = tCurQueueDuration + pQueueDuration
			Set tCurSquares = tCurSquares + pDurationSquare
			&sql( UPDATE Ens_Activity_Data.Seconds (TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare) 
			VALUES (:tCurCount, :tCurDuration, :tCurQueueDuration, :tCurSquares)  
			WHERE ID=:tID
			)
		} Else {
			&sql( INSERT INTO Ens_Activity_Data.Seconds (Instance, Namespace, SiteDimension, HostType, HostName, TimeSlot, TimeSlotUTC, TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare) 
			VALUES (:pInstance, :tNamespace, :pSiteDimension, :pHostType, :pHostName, :tTargetTimeSlot, :tTargetTimeSlotUTC, :pCount, :pDuration, :pQueueDuration, :pDurationSquare)
			)
		}
		If SQLCODE {
			Set tSC = $$$ERROR($$$GeneralError,"SQLCODE="_SQLCODE)
			Quit
		}

		Set tTargetTimeSlotUTC = ..RoundTimeBack("hh",pTimeSlotUTC)
		Set tTargetTimeSlot = ..RoundTimeBack("hh",pTimeSlot)

		&sql( SELECT ID, TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare INTO :tID, :tCurCount, :tCurDuration, :tCurQueueDuration, :tCurSquares
		FROM Ens_Activity_Data.Hours 
		WHERE TimeSlotUTC=:tTargetTimeSlotUTC AND Instance=:pInstance AND SiteDimension=:pSiteDimension AND Namespace=:tNamespace AND HostName=:pHostName
		)
		If SQLCODE=0 {
			Set tCurCount = tCurCount + pCount
			Set tCurDuration = tCurDuration + pDuration
			Set tCurQueueDuration = tCurQueueDuration + pQueueDuration
			Set tCurSquares = tCurSquares + pDurationSquare
			&sql( UPDATE Ens_Activity_Data.Hours (TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare) 
			VALUES (:tCurCount, :tCurDuration, :tCurQueueDuration, :tCurSquares)  
			WHERE ID=:tID
			)
		} Else {
			&sql( INSERT INTO Ens_Activity_Data.Hours (Instance, Namespace, SiteDimension, HostType, HostName, TimeSlot, TimeSlotUTC, TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare) 
			VALUES (:pInstance, :tNamespace, :pSiteDimension, :pHostType, :pHostName, :tTargetTimeSlot, :tTargetTimeSlotUTC, :pCount, :pDuration, :pQueueDuration, :pDurationSquare)
			)
		}
		If SQLCODE {
			Set tSC = $$$ERROR($$$GeneralError,"SQLCODE="_SQLCODE)
			Quit
		}

		Set tTargetTimeSlotUTC = ..RoundTimeBack("d",pTimeSlotUTC)
		Set tTargetTimeSlot = ..RoundTimeBack("d",pTimeSlot)

		&sql( SELECT ID, TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare INTO :tID, :tCurCount, :tCurDuration, :tCurQueueDuration, :tCurSquares
		FROM Ens_Activity_Data.Days 
		WHERE TimeSlot=:tTargetTimeSlot AND TimeSlotUTC=:tTargetTimeSlotUTC AND Instance=:pInstance AND SiteDimension=:pSiteDimension AND Namespace=:tNamespace AND HostName=:pHostName
		)
		If SQLCODE=0 {
			Set tCurCount = tCurCount + pCount
			Set tCurDuration = tCurDuration + pDuration
			Set tCurQueueDuration = tCurQueueDuration + pQueueDuration
			Set tCurSquares = tCurSquares + pDurationSquare
			&sql( UPDATE Ens_Activity_Data.Days (TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare) 
			VALUES (:tCurCount, :tCurDuration, :tCurQueueDuration, :tCurSquares)  
			WHERE ID=:tID
			)
		} Else {
			&sql( INSERT INTO Ens_Activity_Data.Days (Instance, Namespace, SiteDimension, HostType, HostName, TimeSlot, TimeSlotUTC, TotalCount, TotalDuration, TotalQueueDuration, TotalDurationSquare) 
			VALUES (:pInstance, :tNamespace, :pSiteDimension, :pHostType, :pHostName, :tTargetTimeSlot, :tTargetTimeSlotUTC, :pCount, :pDuration, :pQueueDuration, :pDurationSquare)
			)
		}
		If SQLCODE {
			Set tSC = $$$ERROR($$$GeneralError,"SQLCODE="_SQLCODE)
			Quit
		}

	} Catch e {
		Set tSC = e.AsStatus()
	}
	If tLocked {
		Try {
			Lock -^Ens.Activity.Data.Control(pInstance,pSiteDimension,tNamespace,pHostName)
			Set tLocked = 0
			If $$$ISERR(tSC) {
				TRollback
			} Else {
				TCommit
			}
		} Catch e {
			Set tSC = $$$ADDSC(tSC,e.AsStatus())
		}
	}
	Quit tSC
}

ClassMethod AddActivityList(pActivityList As %String = "", Output pCanRetryOnError = 0) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	Try {
		#dim tData = pActivityList
		#dim tStatsCategory = $LG(tData,1)
		If tStatsCategory '= "SC" {
			Set tSC = $$$ERROR($$$NotImplemented)
			Quit
		}
		#dim tDays = $LG(tData,2)
		#dim tSeconds = $LG(tData,3)
		#dim tLocalTime = $LG(tData,4)
		#dim tUTC = $LG(tData,5)
		#dim tInstance = $LG(tData,6)
		#dim tNamespace = $LG(tData,7)
		#dim tHostType = $LG(tData,8)
		#dim tHostName = $LG(tData,9)
		#dim tUserDimension = $LG(tData,10)
		#dim tCount = $LG(tData,11)
		#dim tDuration = $LG(tData,12)
		#dim tQueueduration = $LG(tData,13)
		#dim tSquares = $LG(tData,14)
		Set tSC = ##class(Ens.Activity.Utils).AddActivity(tLocalTime, tUTC, tInstance, tNamespace, tHostType, tHostName, tUserDimension, tCount, tDuration, tQueueduration, tSquares, .pCanRetryOnError)
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod RoundTimeBack(pPeriod As %String, pTime As %String) As %String [ Internal ]
{
	Quit $CASE(pPeriod,
		"yy":$P(pTime,"-")_"-01-01",	;Rounded to Jan 1st
		"mm":$P(pTime,"-",1,2)_"-01", 	;Rounded to 1st of the month
		"d" :$P(pTime," ")_" 00:00:00",	;Rounded to midnight (day start)
		"hh":$P(pTime,":")_":00:00",	;Rounded to hour start
		"mi":$P(pTime,":",1,2)_":00",	;Rounded to minute start
		:pTime							;Stay the same
		)
}

ClassMethod Purge(pPeriodToKeep As %String = "", pClassScale As %String = "", Output pCount As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tNowUTC = $ZDATETIME($ZTIMESTAMP,3)
	#dim tDateAddScale As %String
	#dim tPeriod As %String
	#dim tAmount As %Integer
	#dim tCutOffDate As %String
	
	#dim tStatement As %SQL.Statement
	#dim tResult As %String

	#dim tClass As %String = ""

	#dim tCurrentJournal As %Integer = 0
	If $$CURRENT^%SYS.NOJRN() {
		Set tCurrentJournal = 1
		Do DISABLE^%SYS.NOJRN
	}

	Try {
		Set pCount = 0
		Set tAmount = +pPeriodToKeep
		If tAmount = 0 && (pPeriodToKeep'=pPeriodToKeep) {Set tSC = $$$ERROR($$$GeneralError,"Invalid period to keep")  Quit}
		Set tDateAddScale = $P(pPeriodToKeep,tAmount,2)
		If tDateAddScale = "" Set tDateAddScale = "D" 
		Set tPeriod = pClassScale
		If tPeriod = "" Set tPeriod = tDateAddScale
		Set tPeriod = $ZCVT(tPeriod,"L")
		Set tClass = $Case(tPeriod,"s":"Seconds","hh":"Hours","d":"Days")
		Set tCutOffDate = $SYSTEM.SQL.DATEADD(tDateAddScale,-tAmount,tNowUTC)
		Set tStatement = ##class(%SQL.Statement).%New()
		Set tSC = tStatement.%Prepare("SELECT ID FROM Ens_Activity_Data."_tClass_" WHERE TimeSlotUTC <= ?")
		Set tResult = tStatement.%Execute(tCutOffDate)
		While tResult.%Next() {
			Do $CLASSMETHOD("Ens.Activity.Data."_tClass,"%DeleteId",tResult.ID)
			Set pCount = pCount +1
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	If tCurrentJournal Do ENABLE^%SYS.NOJRN
	Quit tSC
}

}
