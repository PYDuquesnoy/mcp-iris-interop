/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Context search methods for MFT.
Class Ens.MFT.ContextSearch Extends %ZEN.Portal.ContextSearch [ System = 4 ]
{

/// Get a list of MFT Connection Names. <br>
/// Can limit by Service if specify service parameter.
ClassMethod Connections(Output pCaption As %String, Output pTopResults, Output pResults, ByRef pParms As %String, pSearchKey As %String = "") As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Kill pResults

	Try {

		#;Only try if have Select privilege on the connection table
		If $SYSTEM.SQL.CheckPriv($USERNAME,"1,%SYS_MFT_Connection.Base","s") {

			#dim tStatement  = ##class(%SQL.Statement).%New()
			#dim tSQL = "SELECT Name, Service FROM %SYS_MFT_Connection.Base"

			If $Get(pParms("service"))'="" {
				Set tSQL = tSQL_" WHERE SERVICE = "_pParms("service")
			}

			Set tSC = tStatement.%Prepare(tSQL)
			If $$$ISERR(tSC) Quit

			#dim tStatementResult = tStatement.%Execute()
			#dim tCounter = 0

			While tStatementResult.%Next() {
				Set pResults($I(tCounter)) = tStatementResult.Name
			}

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

}
