/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This provides a scrollable resultset object that can also be saved and loaded
/// It works by running the entire query when the first item of data is requested
/// and storing the results in a global. Then you can move around the results by setting the
/// <property>CurrRow</property> and you may also call <method>Previous</method> as
/// well as the standard <method>Next</method>. In addition you may save this resultset
/// and then load it potentially in a different process at a later date and continue
/// reading from it, for example:
/// <example> Set results=##class(%ScrollableResultSet).%New("Classname:QueryName")
/// Do results.Execute()
/// Do results.Next()
/// Write results.Data("fieldname")
/// Do results.%Save()
/// Set id=results.%Id()
/// Kill results
/// Set results=##class(%ScrollableResultSet).%OpenId(id)
/// Do results.Next()
/// Write results.Data("fieldname")
/// </example>
/// Note that if you open a %ScrollableResultSet and do not call %Save on it then when you
/// close this object the data stored in the global will be removed and so you will not be
/// able to open this resultset again. So if you open a scrollable resultset and you wish
/// to use this again call %Save on it, but you must always make sure that when you are finished
/// with it you do not call %Save so the temporary global used is cleaned up when you are done.
/// Alterntively you can call %DeleteId passing the id to remove the saved data.<p>
/// There is also a <method>Count</method> to find the total number of entries in this resultset.
/// This will not work if running with a query against a remote linked table which returns stream data for a column
/// because the remote linked table returns the stream as an oref and this class does not support persisting this oref.
Class %Library.ScrollableResultSet Extends %Library.ResultSet [ System = 3 ]
{

/// Index into temp global used to hold results
Property TempIndex As %Integer [ Private ];

/// Number of current row in the temp table, you can set this property to
/// move to a new location and also use this to check the current position.
/// If you specify a value that is out of bounds then the row will not be moved.
/// The first row is at CurrRow=1, so it is 1 based and not 0 based.
Property CurrRow As %Integer;

Method CurrRowSet(val As %String) As %Status
{
	If i%TempIndex="" Set sc=..PopulateData() If $$$ISERR(sc) Quit sc
	Set Row = $get(^IRIS.TempRSet(i%TempIndex,"Data",+val))
	If (Row = "") {
		Quit $$$OK
	}
	
	Set i%CurrRow=+val

	#; move data into row buffer
	Set ptr=0,end=0
	For i=1:1:i%ColIndex {
		If 'end,'$listnext(Row,ptr,val) Set val="",end=1
		Set i%Data(i%ColIndex(i))=$get(val)
	}
	Set i%Row=Row,i%AtEnd=1
	Quit $$$OK
}

/// This determines how many rows this query will load, the default '0' will load
/// all the results, if you set it to 10,000 then it will only load the first 10,000
/// rows, which will mean you can not access any data beyond the 10,000th element.
/// Also the actual stopping point may be slightly larger than MaxRows because of the
/// way the data is imported, but it will be around this figure.
Property MaxRows As %Integer [ InitialExpression = 0 ];

/// If true, the temp table has been saved and should not be
/// automatically deleted.
Property IsSaved As %Boolean [ InitialExpression = 0, Private ];

Method %OnClose() As %Status [ Private ]
{
	#; note: *real* result set is already closed by now...
	#; if temp table is allocated, AND not saved, delete it.
	If ((i%TempIndex '= "") && ('i%IsSaved)) {
		Kill ^IRIS.TempRSet(i%TempIndex)
	}
	
	Quit $$$OK
}

/// Executes the current query.
/// <p>The arguments <var>p1...</var> supply the value of any parameters the 
/// query may have.
Method PopulateData() As %Status [ Private, ProcedureBlock = 0 ]
{
	New idx,columns,i,query,RowSet,ReturnCount,AtEnd,qHandle,classname,sc,j,PrevMode,data,pos
	#; We need query info to work correctly
	If 'i%HasInfo Quit ..GetInfo()
	If i%TempIndex="" Set i%TempIndex=$increment(^IRIS.TempRSet)
	Set idx=i%TempIndex,columns=i%ColIndex
	Kill ^IRIS.TempRSet(idx)
	If 'i%IsOpened||(i%AtEnd) QUIT $$$OK
	#; Now fill in this global with the results
	Set ^IRIS.TempRSet(idx)=$listbuild($zdt($horolog,3),$job)
	If i%%RuntimeMode'="" Set PrevMode=$zu(115,5,i%%RuntimeMode)
	If i%ClassName="%Library.DynamicQuery",i%QueryName="SQL" {
		If ($isobject($get(i%QHandle(1)))'=1) {
			Set sc=$$$ERROR($$$QueryNotPrepared)
		} Else {
			Set i=0,AtEnd=0
			For  {
				Set sc=i%QHandle(1).FetchRows()
				Quit:$get(RowSet)=""
				Set data=$list(RowSet,1,columns),pos=$length(data)+1
				Set ^IRIS.TempRSet(idx,"Data",$increment(i))=data
				While pos'>$length(RowSet) {
					Set data=$list($extract(RowSet,pos,*),1,columns),pos=pos+$length(data)
					Set ^($increment(i))=data
					If i%MaxRows&&(i>i%MaxRows) QUIT
				}
				Quit:$$$ISERR(sc)||(AtEnd)||(i%MaxRows&&(i>i%MaxRows))
			}
		}
	} Else {
		Merge qHandle=i%QHandle
		Set i="",classname=i%ClassName,query=i%QueryName_"FetchRows",AtEnd=0
		For  {
			Set sc=$classmethod(classname,query,.qHandle,0,.RowSet,.ReturnCount,.AtEnd)
			Quit:$get(RowSet)=""
			Set data=$list(RowSet,1,columns),pos=$length(data)+1
			Set ^IRIS.TempRSet(idx,"Data",$increment(i))=data
			While pos'>$length(RowSet) {
				Set data=$list($extract(RowSet,pos,*),1,columns),pos=pos+$length(data)
				Set ^($increment(i))=data
				If i%MaxRows&&(i>i%MaxRows) QUIT
			}
			Quit:$$$ISERR(sc)||(AtEnd)||(i%MaxRows&&(i>i%MaxRows))
		}
		Kill i%QHandle Merge i%QHandle=qHandle
	}
	Set i%AtEnd=0,i%CurrRow=""
	If i%%RuntimeMode'="" Do $zu(115,5,PrevMode)
	Do ..Close()
	QUIT sc
}

/// Advance the result set cursor to the next row. Returns 0 if the cursor is at the end of the 
/// result set.
Method Next(ByRef sc As %Status) As %Integer
{
	Set sc = $$$OK
	If i%TempIndex="" Set sc=..PopulateData() If $$$ISERR(sc) Quit sc
	Kill i%Data
	Set i%CurrRow = $order(^IRIS.TempRSet(i%TempIndex,"Data",i%CurrRow),1,Row)
	If (i%CurrRow = "") {
		Set i%AtEnd=1,i%Row=""
		Quit 0
	}
	
	#; move data into row buffer
	Set ptr=0,end=0
	For i=1:1:i%ColIndex {
		If 'end,'$listnext(Row,ptr,val) Set val="",end=1
		Set i%Data(i%ColIndex(i))=$get(val)
	}
	Set i%Row=Row,i%AtEnd=0
	Quit 1
}

/// Advance the result set cursor to the previous row. Returns 0 if the cursor is at the end of the 
/// result set.
Method Previous(ByRef sc As %Status) As %Integer
{
	Set sc = $$$OK
	If i%TempIndex="" Set sc=..PopulateData() If $$$ISERR(sc) Quit sc
	Kill i%Data
	Set i%CurrRow = $order(^IRIS.TempRSet(i%TempIndex,"Data",i%CurrRow),-1,Row)
	If (i%CurrRow = "") {
		Set i%AtEnd=1,i%Row=""
		Quit 0
	}
	
	#; move data into row buffer
	Set ptr=0,end=0
	For i=1:1:i%ColIndex {
		If 'end,'$listnext(Row,ptr,val) Set val="",end=1
		Set i%Data(i%ColIndex(i))=$get(val)
	}
	Set i%Row=Row,i%AtEnd=0
	Quit 1
}

/// Returns the number of rows contained in this ResultSet.
Method Count() As %Integer
{
	If i%TempIndex="" Set sc=..PopulateData() If $$$ISERR(sc) Quit 0
	Quit $select(i%TempIndex="":0,1:+$order(^IRIS.TempRSet(i%TempIndex,"Data",""),-1))
}

ClassMethod %OpenId(id As %String, concurrency As %Integer = -1, ByRef sc As %Status = {$$$OK}) As %ObjectHandle
{
	Set oref=..%New()
	Set sc=oref.Load(id)
	If $$$ISERR(sc) Quit ""
	Quit oref
}

Method Load(id As %String) As %Status
{
	If '$data(^IRIS.TempRSet(id)) Quit $$$ERROR($$$LoadObjectNotFound)
	Set i%TempIndex=id,i%IsSaved=0
	Merge i%ColIndex=^IRIS.TempRSet(i%TempIndex,"Index"),i%QHandle=^("QHandle"),i%Data=^("RowData")
	Set $listget(i%ClassName,i%QueryName,i%%RuntimeMode,i%HasInfo,i%ParamInfo,i%ColInfo,i%IdInfo,i%AtEnd,i%IsOpened,i%CurrRow)=^("Info")
	Set i%Row=^("Row")
	Quit $$$OK
}

Method %Save() As %Status
{
	If i%TempIndex="" Set sc=..PopulateData() If $$$ISERR(sc) Quit sc
	Set i%IsSaved=1
	Set ^IRIS.TempRSet(i%TempIndex)=$listbuild($zdt($horolog,3),$job)
	Merge ^IRIS.TempRSet(i%TempIndex,"Index")=i%ColIndex,^("QHandle")=i%QHandle,^("RowData")=i%Data
	Set ^("Info")=$listbuild(i%ClassName,i%QueryName,i%%RuntimeMode,i%HasInfo,i%ParamInfo,i%ColInfo,i%IdInfo,i%AtEnd,i%IsOpened,i%CurrRow)
	Set ^("Row")=i%Row
	Quit $$$OK
}

ClassMethod %DeleteId(id As %String, concurrency As %Integer = -1) As %Status
{
	Kill ^IRIS.TempRSet(id)
	Quit $$$OK
}

Method %Id() As %String [ CodeMode = expression, Final ]
{
$select(i%IsSaved:i%TempIndex,1:"")
}

Method GetObject() As %RegisteredObject [ ProcedureBlock = 1 ]
{
	If i%TempIndex="" {
		If 'i%IsOpened Set sc=..PopulateData() If $$$ISERR(sc) Quit $$$NULLOREF
		Quit $$$NULLOREF
	}
	If 'i%HasInfo If $$$ISERR(..GetInfo()) Quit $$$NULLOREF
	If '$list(i%IdInfo,1)||($listget(i%IdInfo,2)="")||(i%Row="") Quit $$$NULLOREF
	Set id=$listget(i%Row,$list(i%IdInfo))
	Quit $classmethod($list(i%IdInfo,2),"%OpenId",id)
}

}
