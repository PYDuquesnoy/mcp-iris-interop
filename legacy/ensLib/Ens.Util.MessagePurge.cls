/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is the utility class to purge Message Headers and associated Message Bodies.
/// The method to use is Purge.
/// Multi thread purging depends on Work Queue Manager.
/// <p>
/// The Purge method supersedes the Purge method in Ens.MessageHeader class.
/// /// <p>
/// /// The caller of the Purge api requires SELECT privilege on the Ens.MessageHeader table.
Class Ens.Util.MessagePurge Extends %RegisteredObject [ System = 4 ]
{

/// The Purge Method has the following parameters:
/// <EXAMPLE>
/// /*
///     pDeletedCount - this is an array indicating how many message headers and bodies and bitmap extents have been deleted
///     pDaysToKeep - this is used to calculate the non inclusive end date for the purge process.
///     pKeepIntegrity - if true this is used to prevent the deletion of any messages within a session that is not considered 'Complete'.
///     pBodiesToo - if true this means that the message bodies associated with the Message Headers are deleted. By default bodies are not deleted. Any bodies with a class definition that has Parameter ENSPURGE = 0 will not be deleted.
///     pBitmapPurgeRunLimit - this is an optional parameter to control the maximum amount of time deletion of zeroed bitmap chunks can run for
///     pExtendedOptions - this is an array of giving extended options to refine the purging process. Subscripts can be:
///         Restricting candidate messages other than 'pKeepIntegrity':
///             "LimitToConfigItems" - a comma separated list of production host items that if defined will limit the purge to SourceConfigName or TargetConfigName contained in the list
///         Multi-threaded:
///             "WQCategory"   - if defined then use Work Queue Manager using this category. If the category entered does not exist then the 'Default' category will be used.
///             "WQBatchSize"  - if WQBatchPeriodMinutes is not defined and using WQCategory then this gives the number of messages to split into multiple jobs (exclusive of completeness or config item name requirements) as starting batch lists
///                            - the minimum count applied will be 10,000. The default if neither WQBatchSize nor WQBatchPeriodMinutes is specified is a batch size of 100,000
///             "WQBatchPeriodMinutes" - if defined and using WQCategory this is the time interval to split into multiple jobs.
///                           - the minimum interval applied will be 15 (minutes)
///         Used by multi-thread framework but available to pass in initial call
///             "StartDateTime" and "DoNotDeleteEndDateTime" - optional UTC TimeStamps that override parameter pDaysToKeep
///         Internal subscripts:
///             "isWQJob" - this is an internal subscript used to identify the purge process as a spawned Work Queue job
///             "masterPurgeJob" - this is an internal subscript used to identify master purge process that requested Work Queue submissions. Used to coordinate delete counts
///         Extra Purging:
///              "NamespaceBitmapMaint" - if this is set to 1 then %SYS.Maint.Bitmap method Namespace() will be called as the last step
/// */
/// </EXAMPLE>
ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0, pBitmapPurgeRunLimit As %Integer = 600, ByRef pExtendedOptions As %String) As %Status
{

	Set pDeletedCount=0, pDeletedCount("bodies")=0

	#; The following is used for caching
	If '$Data($$$EnsJobLocal) New $$$EnsJobLocal Set $$$EnsJobLocal = ""

	#dim tSC As %Status = $$$OK
	#dim tBitmapSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tErrorMsg As %String

	#dim tDeleteSelectQuery As %String
	#dim tDeleteSQLParams As Array of %String

	#dim tDeletedChunks As %Integer

	Try {
		Set tSC1 = ##class(%SYS.Monitor.Interop.DatabaseImpact.Utils).LogDatabaseSizes(0)
		If $$$ISERR(tSC1) {
			$$$LOGWARNING("Error encountered logging database impact metrics: "_$system.Status.GetErrorText(tSC1))
		}

		If $Get(pExtendedOptions("WQCategory"))'="" {
			/* Use ^IRIS.Temp.Intrp for WQ jobs to record individual delete counts */
			Kill ^IRIS.Temp.Intrp($namespace,"pDeletedCount",$Job)

			Set tSC = ..PurgeUsingWorkQueue(.pDeletedCount, pDaysToKeep, pKeepIntegrity, pBodiesToo, pBitmapPurgeRunLimit, .pExtendedOptions)

		} Else {

			Set tDeleteSelectQuery = ..generateDeleteSelectSQL(.tDeleteSQLParams, pDaysToKeep, pKeepIntegrity, pBodiesToo, .pExtendedOptions)

			Set tSC = ..deleteDataUsingSelectQuery(tDeleteSelectQuery, .tDeleteSQLParams, pBodiesToo, .pDeletedCount)

		}

		Set tSC1 = ##class(%SYS.Monitor.Interop.DatabaseImpact.Utils).LogDatabaseSizes(0)
		If $$$ISERR(tSC1) {
			$$$LOGWARNING("Error encountered logging database impact metrics: "_$system.Status.GetErrorText(tSC1))
		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	/* If this is a Work Queue Job then save counts	*/
	If $Get(pExtendedOptions("isWQJob")) {
		Do ..incrementWQDeleteCounts(pExtendedOptions("masterPurgeJob"),.pDeletedCount)
	} Else {
		#; Still try to cleanup bitmap indices if error
		If $Get(pExtendedOptions("NamespaceBitmapMaint")) {
			Set tStopTime = ""
			If (+pBitmapPurgeRunLimit=pBitmapPurgeRunLimit)&&(pBitmapPurgeRunLimit>0) Set tStopTime = $system.SQL.DATEADD("s",pBitmapPurgeRunLimit,$ZDT($H,3))
			Set tBitmapSC = ##class(%SYS.Maint.Bitmap).Namespace($namespace, 0, 0, tStopTime)
		} Else {
			#; limit to just header bitmap purges
			Set tBitmapSC = ##class(Ens.MessageHeader).PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
			Merge pDeletedCount("bitmaps") = tDeletedChunks
		}
		Set:($$$ISERR(tBitmapSC)) tSC = $$$ADDSC(tSC,tBitmapSC)
	}

	Quit tSC
}

/// This method is intended to be called from <METHOD>Purge</Method> and not called directly
ClassMethod PurgeUsingWorkQueue(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0, pBitmapPurgeRunLimit As %Integer = 600, ByRef pExtendedOptions As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tStartDateTime As %TimeStamp
	#dim tDoNotDeleteEndDateTime As %TimeStamp

	#dim tBatchPeriodMinutes As %Integer
	#dim tBatchSize As %Integer

	#dim tPurgeQueueMgr As %SYSTEM.WorkMgr

	#dim tOptionsForWQJob As %String

	#dim tOneJobStartDateTime As %TimeStamp
	#dim tOneJobDoNotDeleteEndDateTime As %TimeStamp
	#dim tMoreWork AS %Boolean

	#define minimumTimePeriodMins		15
	#define defaultBatchSize			100000
	#define minimumBatchSize			10000

	Try {

		Set tStartDateTime  = $Get(pExtendedOptions("StartDateTime"))
		Set tDoNotDeleteEndDateTime = $Get(pExtendedOptions("DoNotDeleteEndDateTime"))

		If tStartDateTime="" {
			/* findOldestMessageHeader without any restrictions to obtain
				quickly a starting date.
				Restrictions will be applied as necessary during the actual purge
			*/
			Set tSC = ..findOldestMessageHeader(.tStartDateTime)
			If $$$ISERR(tSC) || (tStartDateTime = "") Quit /* try */
		}
		If tDoNotDeleteEndDateTime="" Set tDoNotDeleteEndDateTime = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)

		/* Options that remain constant for each WQ job */
		Set tOptionsForWQJob("LimitToConfigItems") = $Get(pExtendedOptions("LimitToConfigItems"))
		Set tOptionsForWQJob("isWQJob")=1
		Set tOptionsForWQJob("masterPurgeJob")=$Job

		/*	Instantiate WorkQueue manager interface using requested category
			If caller requested an invalid WQCategory fall back to trying default
			so that purging can still be tried.
		*/
		Set tPurgeQueueMgr = ##class(%SYSTEM.WorkMgr).%New(/* default qstruct */, /* limit NumberOfJobs*/, pExtendedOptions("WQCategory") /* category */)
		If '$IsObject(tPurgeQueueMgr) {
			Kill %objlasterror
			Set tPurgeQueueMgr = ##class(%SYSTEM.WorkMgr).%New(/* default qstruct */, /* limit NumberOfJobs*/, /* Default category */)
			If '$IsObject(tPurgeQueueMgr) && $Get(%objlasterror) {
				Set tSC = %objlasterror
				Return tSC 
			}
		}

		Set tMoreWork = 1
		Set tOneJobStartDateTime = tStartDateTime

		/* Default to using batch amount. Need to account for pExtendedOptions("WQBatchPeriodMinutes")=""
			and pExtendedOptions("WQBatchSize")="" treating those as undefined.
		*/
		If +$Get(pExtendedOptions("WQBatchPeriodMinutes"),0)=0 {
			#; remove if empty string or a string to fall back to default
			If ($Data(pExtendedOptions("WQBatchSize"))#2) && 
				(pExtendedOptions("WQBatchSize")'=+pExtendedOptions("WQBatchSize")) {
				Kill pExtendedOptions("WQBatchSize")
			}
			Set tBatchSize = +$Get(pExtendedOptions("WQBatchSize"),$$$defaultBatchSize)
			If tBatchSize < $$$minimumBatchSize Set tBatchSize=$$$minimumBatchSize
			#dim tBatchSizeSQL As %String
			#dim tBatchSizeStatement As %SQL.Statement
			#dim tBatchSizeResultSet As %SQL.StatementResult
			#dim tOneJobDoNotDeleteEndDateTimeHdr As Ens.MessageHeader
			/*	Find the TimeCreated end for batches of size tBatchSize
				Cannot assume ID in numerical order and in line with TimeCreated order.
			*/
			Set tBatchSizeSQL = "SELECT MAX(TimeCreated) AS MaxTimeCreated FROM Ens.MessageHeader "_
									"WHERE TimeCreated >= ? AND TimeCreated < ? "_
									"AND (ID IN (SELECT TOP ? ID FROM Ens.MessageHeader WHERE TimeCreated >= ? AND TimeCreated < ? ORDER BY TimeCreated ASC)) "_
									"ORDER BY TimeCreated ASC"
			Set tBatchSizeStatement = ##class(%SQL.Statement).%New()
			/* Ensure LOGICAL mode */
			Set tBatchSizeStatement.%SelectMode = 0
			Set tSC = tBatchSizeStatement.%Prepare(tBatchSizeSQL)
			Quit:$$$ISERR(tSC)
		} Else {
			Set tBatchPeriodMinutes = +pExtendedOptions("WQBatchPeriodMinutes")
			If tBatchPeriodMinutes < $$$minimumTimePeriodMins Set tBatchPeriodMinutes=$$$minimumTimePeriodMins
		}

		/* Loop to Queue Purge jobs in time based sequential batches */
		While tMoreWork {

			If $Get(tBatchPeriodMinutes) {
				#; check how long it is between first start and end to advise if gap creeping due to KeepIntegrity.
				If $system.SQL.Functions.DATEDIFF("mi",tOneJobStartDateTime,tDoNotDeleteEndDateTime) > tBatchPeriodMinutes {
					Set tOneJobDoNotDeleteEndDateTime = $system.SQL.Functions.DATEADD("mi",tBatchPeriodMinutes,tOneJobStartDateTime)
				} Else {
					Set tOneJobDoNotDeleteEndDateTime = tDoNotDeleteEndDateTime
					#; Mark this as the last WQ Job 
					Set tMoreWork = 0
				}
			} ElseIf $Get(tBatchSize) {
				Set tBatchSizeResultSet = tBatchSizeStatement.%Execute(tOneJobStartDateTime, tDoNotDeleteEndDateTime, tBatchSize, tOneJobStartDateTime, tDoNotDeleteEndDateTime)
				Set tOneJobDoNotDeleteEndDateTime = ""
				If tBatchSizeResultSet.%Next() {
					Set tOneJobDoNotDeleteEndDateTime = tBatchSizeResultSet.%Get("MaxTimeCreated")
					/*	Add a second to make last message batch inclusive for the max time created end date.
						If tOneJobDoNotDeleteEndDateTime is empty string then adding 1 s still empty string
					*/
					Set tOneJobDoNotDeleteEndDateTime =$system.SQL.Functions.DATEADD("s",1,tOneJobDoNotDeleteEndDateTime)
				}
				/* No more batches to submit. Quit While loop */
				If (tOneJobDoNotDeleteEndDateTime="")||(tOneJobStartDateTime = tOneJobDoNotDeleteEndDateTime) Quit
			} Else {
				/*No batching criteria. Quit While loop */
				Quit
			}

			/* Queue one purge batch */
			Set tOptionsForWQJob("StartDateTime") = tOneJobStartDateTime
			Set tOptionsForWQJob("DoNotDeleteEndDateTime") = tOneJobDoNotDeleteEndDateTime
			Set tSC = tPurgeQueueMgr.Queue("##class(Ens.Util.MessagePurge).Purge",/*pDeletedCount*/,/*pDaysToKeep*/,pKeepIntegrity,pBodiesToo,pBitmapPurgeRunLimit,.tOptionsForWQJob)
			Quit:$$$ISERR(tSC)

			Set tOneJobStartDateTime = tOneJobDoNotDeleteEndDateTime

		}

		/*	Calling WaitForComplete() rather than Sync() as per documentation
			to aid any back ports to before 2021.2.0.
			 WaitForComplete() is maintained as a wrapper to Sync()
		*/
		Set tSC = $$$ADDSC(tSC,tPurgeQueueMgr.WaitForComplete())
		If $$$ISERR(tSC) Quit

		Do ..retrieveWQDeleteCounts(.pDeletedCount)

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Return tSC
}

/// Internal method to generate the selection SQL used for the deletion
ClassMethod generateDeleteSelectSQL(Output pDeleteSQLParams As %String, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBodiesToo As %Boolean = 0, ByRef pExtendedOptions As %String) As %String [ Internal ]
{
	#dim tStartDateTime As %TimeStamp = $Get(pExtendedOptions("StartDateTime"))
	#dim tDoNotDeleteEndDateTime As %TimeStamp = $Get(pExtendedOptions("DoNotDeleteEndDateTime"))

	#dim tDeleteSelectQuery As %String = "SELECT ID"

	#dim tLimitToConfigItems As %String

	If pBodiesToo Set tDeleteSelectQuery = tDeleteSelectQuery_",MessageBodyId,MessageBodyClassName"
	Set tDeleteSelectQuery = tDeleteSelectQuery_" FROM Ens.MessageHeader h WHERE"

	Set pDeleteSQLParams = 0

	If tStartDateTime '= "" {
		Set tDeleteSelectQuery = tDeleteSelectQuery_" (h.TimeCreated >= ?) AND"
		Set pDeleteSQLParams($I(pDeleteSQLParams)) = tStartDateTime
	}

	/* Always have maximum time restriction */
	If tDoNotDeleteEndDateTime = "" Set tDoNotDeleteEndDateTime = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set tDeleteSelectQuery = tDeleteSelectQuery_" (h.TimeCreated < ?)"
	Set pDeleteSQLParams($I(pDeleteSQLParams)) = tDoNotDeleteEndDateTime

	If pKeepIntegrity {
		Set tDeleteSelectQuery = tDeleteSelectQuery _ " And 0 = ( Select Count(*) From Ens.MessageHeader "_
								" Where (SessionId = h.SessionId)" _
								" And (Status<>9)"_
								" And (Status<>7)"_
								" And (Status<>8)"_
								" And (Status<>4) )"
	}

	If ($Get(pExtendedOptions("LimitToConfigItems"))'="") {
		Set tDeleteSelectQuery = tDeleteSelectQuery_" And ( (? [ {fn CONCAT(',',{fn CONCAT(h.SourceConfigName,',')})}) OR (? [  {fn CONCAT(',',{fn CONCAT(h.TargetConfigName, ',')})}) )"
		Set tLimitToConfigItems = ","_pExtendedOptions("LimitToConfigItems")_","
		Set pDeleteSQLParams($I(pDeleteSQLParams)) = tLimitToConfigItems
		Set pDeleteSQLParams($I(pDeleteSQLParams)) = tLimitToConfigItems
	}
	Set tDeleteSelectQuery = tDeleteSelectQuery_" ORDER BY h.TimeCreated ASC"

	Return tDeleteSelectQuery
}

/// Internal private method to execute the delete selection SQL and then delete the bodies if so required and the headers
ClassMethod deleteDataUsingSelectQuery(pDeleteSelectQuery As %String, ByRef pDeleteSQLParams, pBodiesToo As %Boolean, ByRef pDeletedCount As %Integer) As %Status [ Internal, Private ]
{
	#dim tSC As %Status = $$$OK
	#dim tDeleteBodySC As %Status = $$$OK
	#dim tDeleteSearchTableSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tErrorMsg As %String
	/* Log purging errors in Event log but no more than $$$ensPurgeMaxWarn per type (body, search table & header) */
	#dim tPurgeErrorWarningsArray = $$$ensPurgeMaxWarn

	#dim tByDateStatement As %SQL.Statement
	#dim tByDateResultSet As %SQL.StatementResult

	#dim tHdrID As %Integer
	#dim tBodyId As %String
	#dim tBodyClassName As %String

	#dim aClass As Array of %String
	#dim tBodyClassExists As %Boolean

	Try {
		Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

		Set tByDateStatement = ##class(%SQL.Statement).%New()
		/* Ensure LOGICAL mode */
		Set tByDateStatement.%SelectMode = 0
		Set tSC = tByDateStatement.%Prepare(pDeleteSelectQuery)
		Quit:$$$ISERR(tSC)

		Set tByDateResultSet = tByDateStatement.%Execute(pDeleteSQLParams...)

		While tByDateResultSet.%Next() {
			Set tHdrID = tByDateResultSet.%Get("ID")
			If pBodiesToo {
				Set tBodyId = tByDateResultSet.%Get("MessageBodyId")
				Set tBodyClassName = tByDateResultSet.%Get("MessageBodyClassName")
				If tBodyId'="" {
					#; Delete body if body class exists and is persistent and ENSPURGE is NOT explicitly set to 0 (i.e. ENSPURGE=1 by default)
					Set:""=tBodyClassName&&(tBodyId=+tBodyId) tBodyClassName="Ens.MessageBody"
					If ""'=tBodyClassName {
						Set tBodyClassExists=$G(aClass(tBodyClassName))
						If 0'=tBodyClassExists {
							If ""=tBodyClassExists&&'($$$comClassDefined(tBodyClassName)&&($classmethod(tBodyClassName,"%IsA","%Persistent")||$classmethod(tBodyClassName,"%IsA","%Stream.Object")))||($parameter(tBodyClassName,"ENSPURGE")=0) {
								Set aClass(tBodyClassName)=0
							} Else {
								try {
									Set tDeleteBodySC=$classmethod(tBodyClassName,"%DeleteId",tBodyId)
									Set:""=tBodyClassExists aClass(tBodyClassName)=1, tBodyClassExists=1
								} catch {
									Set tDeleteBodySC = $$$SystemError
								}
								If $$$ISOK(tDeleteBodySC) || $$$StatusEquals(tDeleteBodySC,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) {
									Set tDeleteSearchTableSC = ##class(Ens.SearchTableBase).RemoveSearchTableEntries(tBodyClassName,tBodyId,1)
									If $$$ISERR(tDeleteSearchTableSC)&&'$G(aClass(tBodyClassName,"doneErrST")) && '$$$StatusEquals(tDeleteSearchTableSC,$$$DeleteObjectNotFound,$$$FileCanNotDelete,$$$NotAnInstanceError) {
										Set tErrorMsg = "Failed to purge SearchTable entries for deleted body with BodyClassname='"_tBodyClassName_"', BodyId='"_tBodyId_"' from header "_tHdrID_" :"_$$$StatusDisplayString(tDeleteSearchTableSC)
										Do ..ReportPurgeError($$$ensPurgeST,tErrorMsg,tSC,tDeleteSearchTableSC,.tPurgeErrorWarningsArray)
										#; If error purging search table but body purged/already deleted then carry on
									}
								} Else {
									Set tErrorMsg = "Failed to purge body for header "_tHdrID_", BodyClassname='"_tBodyClassName_"':"_$$$StatusDisplayString(tDeleteBodySC)
									Do ..ReportPurgeError($$$ensPurgeBody,tErrorMsg,tSC,tDeleteBodySC,.tPurgeErrorWarningsArray)
									#; If protect error purging body continue to next message and do not try to delete message header
									If (tErrorMsg["<PROTECT>") Continue
								}
								Set pDeletedCount("bodies")=pDeletedCount("bodies")+$$$ISOK(tDeleteBodySC)
							}
						}
					}
				}
			}

			/* Delete header */
			Set tSC = ##class(Ens.MessageHeader).%DeleteId(tHdrID)
			If $$$ISERR(tSC) {
				Set tErrorMsg = "Failed to purge message header "_tHdrID_": "_$system.Status.GetErrorText(tSC)
				Do ..ReportPurgeError($$$ensPurgeHdr,tErrorMsg,tSC,$$$ERROR($$$EnsErrGeneral,tErrorMsg),.tPurgeErrorWarningsArray)
				#;	If protect error when trying to delete message header quit purge completely
				#;	as all message header purges will encounter protect
				If (tErrorMsg["<PROTECT>") Quit
				#; Other errors will lead to continue to purge next record
			} Else {
				Do $I(pDeletedCount)
			}

		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Kill tTransactionSuspendedSwitch

	Return tSC
}

/// Internal method to find the oldest MessageHeader
/// The parameters pKeepIntegrity and pExtendedOptions can be used but
/// will increase the time to results. Provided here for possible manual investigation.
ClassMethod findOldestMessageHeader(Output pStartDateTime As %TimeStamp = "", pKeepIntegrity As %Boolean = 0, ByRef pExtendedOptions As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tOldestSQL As %String
	#dim tOldestStatement As %SQL.Statement
	#dim tOldestResultSet As %SQL.StatementResult

	#dim tLimitToConfigItems As %String = ""
	#dim tOldestSQLParams As Array of %String = 0

	#dim tNextWhereOrAnd As %String

	Try {

		Set tOldestSQL = "SELECT MIN(h.TimeCreated) As MINDATETIME FROM Ens.MessageHeader h"

		If pKeepIntegrity {
			Set tOldestSQL = tOldestSQL_" WHERE 0 = ( Select Count(*) From Ens.MessageHeader "_
								" Where (SessionId = h.SessionId)" _
								" And (Status<>9)"_
								" And (Status<>7)"_
								" And (Status<>8)"_
								" And (Status<>4) )"
			Set tNextWhereOrAnd = "AND"
		} Else {
			Set tNextWhereOrAnd = "WHERE"
		}

		If ($Get(pExtendedOptions("LimitToConfigItems"))'="") {
			Set tOldestSQL = tOldestSQL_" "_tNextWhereOrAnd_" ( (? [ {fn CONCAT(',',{fn CONCAT(h.SourceConfigName,',')})}) OR (? [  {fn CONCAT(',',{fn CONCAT(h.TargetConfigName, ',')})}) )"
			Set tLimitToConfigItems = ","_pExtendedOptions("LimitToConfigItems")_","
			Set tOldestSQLParams($I(tOldestSQLParams)) = tLimitToConfigItems
			Set tOldestSQLParams($I(tOldestSQLParams)) = tLimitToConfigItems
		}

		Set tOldestStatement = ##class(%SQL.Statement).%New()
		/* Ensure LOGICAL mode */
		Set tOldestStatement.%SelectMode = 0
		Set tSC = tOldestStatement.%Prepare(tOldestSQL)

		If $$$ISOK(tSC) {
			Set tOldestResultSet = tOldestStatement.%Execute(tOldestSQLParams...)
			If tOldestResultSet.%Next() Set pStartDateTime = tOldestResultSet.%Get("MINDATETIME")
		}

	} Catch ex {
		Set tSC = ex.AsStatus()
	}

	Return tSC
}

/// Internal private method to retrieve delete counts from the various Work Queue purge jobs
ClassMethod retrieveWQDeleteCounts(ByRef pDeletedCount As %Integer) [ Internal, Private ]
{
	Merge pDeletedCount = ^IRIS.Temp.Intrp($namespace,"pDeletedCount",$Job)
	Kill ^IRIS.Temp.Intrp($namespace,"pDeletedCount",$Job)
}

/// Internal private method to for WQ Purge jobs to record delete counts
ClassMethod incrementWQDeleteCounts(pMasterJob As %String, ByRef pDeletedCount As %Integer) [ Internal, Private ]
{
	#; Master job runs purge bitmaps
	Do $I(^IRIS.Temp.Intrp($namespace,"pDeletedCount",pMasterJob),$Get(pDeletedCount,0))
	Do $I(^IRIS.Temp.Intrp($namespace,"pDeletedCount",pMasterJob,"bodies"),$Get(pDeletedCount("bodies"),0))
}

/// Wrapper to call method in Ens.MessageHeader due to use of code in <method>deleteDataUsingSelectQuery</method> 
/// migrated from Ens.MessageHeader::Purge.
ClassMethod ReportPurgeError(pType As %Integer, pMsg As %String, pSC As %Status, pSC2 As %Status, ByRef pPurgeErrorWarningsArray) As %Status [ Internal ]
{
	Return ##class(Ens.MessageHeader).ReportPurgeError(pType, pMsg, pSC, pSC2, .pPurgeErrorWarningsArray)
}

}
