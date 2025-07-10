/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator Ensemble

/// Only applies to persistent classes using standard storage and bitmap indices.
Class Ens.Util.BitmapPurge [ Abstract, System = 4 ]
{

/// Utility method to call system bitmap cleanup API. <br>
/// Parameter pRunLimit is the maximum amount of time in seconds
/// that the bitmap purge ought to run for. 
/// The default is 600 seconds. <br>
/// pSizeReduction is the size the indices were reduced by. <br>
/// pNoJournal is to disable journaling during the purge. The
/// default is not to disable journalling. <br>
ClassMethod PurgeBitmaps(pRunLimit As %Integer = 600, Output pSizeReduction As %Integer, pNoJournal As %Boolean = 0) As %Status [ CodeMode = objectgenerator ]
{
	Set tBitmaps = ""
	Set tExtent = ""
	Set tIndexKey = ""
	For {
		Set tIndex = %compiledclass.Indices.GetNext(.tIndexKey)
		If (tIndexKey = "")||'$IsObject(tIndex) {
			Quit
		}
		If (tIndex.Type '= "bitmap") {
			Continue
		}
		If tIndex.Extent {
			If tExtent = "" { // only allow one extent
				Set tExtent = tIndex.Name
			}
		}
		ElseIf '$data(tBitmaps(tIndex.Name)) {
			Set tBitmaps(tIndex.Name) = ""
			Set tBitmaps = tBitmaps _ $lb($$$quote(tIndex.Name))
		}
	}
	// If we don't have an extent bitmap, there is nothing we can do.
	If (tExtent = "") {
		Do %code.WriteLine($char(9) _ "Set pSizeReduction = 0")
		Do %code.WriteLine($char(9) _ "Quit $$$OK")
		Quit $$$OK
	}
	// Check that we only have one storage defined. Return an error for the purge.
	If (%compiledclass.Storages.Count() > 1) {
		Quit $$$ERROR($$$EnsErrGeneral,"Multiple storages defined. Correct extent can't be determined for class " _ %compiledclass.Name)
	}
	Set tStorage = %compiledclass.Storages.GetNext("")
	If '$IsObject(tStorage) {
		Quit $$$ERROR($$$EnsErrGeneral,"Unable to load Compiled Storage for class " _ %compiledclass.Name)
	}
	Set tIndexLocation = tStorage.IndexLocation
	If (tIndexLocation = "") {
		Quit $$$ERROR($$$EnsErrGeneral,"Unable to determine index location for class " _ %compiledclass.Name)
	}
	Set tDataLocation = tStorage.DataLocation
	If (tDataLocation = "") {
		Quit $$$ERROR($$$EnsErrGeneral,"Unable to determine data location for class " _ %compiledclass.Name)
	}
	Set tExtentQuoted = $$$quote(tExtent)

	/*
		Using %SYS.Maint.Bitmap status object returned to find
		size reduction overall for class rather than querying
		%SYS.Maint.BitmapResults for classname which can be done 
		after if needs be.
	*/

	Do %code.WriteLine($char(9) _ "Set tStatus = $$$OK")
	Do %code.WriteLine($char(9) _ "Kill pSizeReduction")
	Do %code.WriteLine($char(9) _ "Set pSizeReduction = 0")
	Do %code.WriteLine($char(9) _ "Set tStopTime = """"")
	Do %code.WriteLine($char(9) _ "Try {")
	Do %code.WriteLine($char(9,9) _ "If (+pRunLimit=pRunLimit)&&(pRunLimit>0) Set tStopTime = $system.SQL.DATEADD(""s"",pRunLimit,$ZDT($H,3))")
	Do %code.WriteLine($char(9,9) _ "Set tStatus = ##class(%SYS.Maint.Bitmap).OneClass(""" _ %class.Name _ """, pNoJournal, 0 ,tStopTime, .tPurgeStatusObj )")
	Do %code.WriteLine($char(9,9) _ "If ($IsObject(tPurgeStatusObj)&&($$$ISOK(tStatus)||(tPurgeStatusObj.Status=""Stopped""))) { /* Account for possible future change in OneClass() to return an error if Stopped */")
	Do %code.WriteLine($char(9,9,9) _ "Set pSizeReduction = tPurgeStatusObj.OldSize-tPurgeStatusObj.NewSize") /* Reporting size change rather than NumberCompressed or CompressionAmount */
	Do %code.WriteLine($char(9,9,9) _ "Set pSizeReduction(" _ $C(34) _ %class.Name _ $C(34) _ ") = pSizeReduction") /* No Longer reporting per index */
	Do %code.WriteLine($char(9,9,9) _ "If tPurgeStatusObj.Status=""Stopped"" {")
	Do %code.WriteLine($char(9,9,9,9) _ "Set:(tStatus=0) tStatus = $$$OK /* Account for OneClass() returning just 0 when Stopped */")
	Do %code.WriteLine($char(9,9,9,9) _ "Set tWarning = $namespace _ "": Interoperability purging did not finish bitmap purging for '" _ %class.Name _ "' after requested maximum seconds of "" _ pRunLimit ")
	Do %code.WriteLine($char(9,9,9,9) _ "Do ##class(%SYS.System).WriteToConsoleLog(tWarning,0,$$$MWARN,""Interop.Purge"")")
	Do %code.WriteLine($char(9,9,9) _ "}") /* Check to see if finished within stop time */
	Do %code.WriteLine($char(9,9) _ "}")
	Do %code.WriteLine($char(9) _ "} Catch {")
	Do %code.WriteLine($char(9,9) _ "Set tStatus = $$$SystemError")
	Do %code.WriteLine($char(9) _ "}")
	Do %code.WriteLine($char(9) _ "Return tStatus")
	Quit $$$OK
}

}
