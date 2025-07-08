/// Sample DataModel used by MVC Form page.
Class ZENMVC.FormDataModel Extends %ZEN.DataModel.ObjectDataModel
{

Property Name As %String(ZENGROUP = "group1", ZENTITLE = "This is a name") [ Required ];

Property SSN As %String(MAXLEN = 15, ZENGROUP = "group1");

Property City As %String(ZENGROUP = "group1");

Property State As %String(MAXLEN = 2, ZENGROUP = "group1");

Property Memo As %String(MAXLEN = 32000);

Property MaritalStatus As %String(MAXLEN = 1, VALUELIST = ",S,M,D,W,O");

/// JavaScript validation for SSN property
ClientClassMethod SSNIsValidJS(value) [ Language = javascript ]
{
	return (value==666) ? 'invalid SSN' : '';
}

/// Load an instance of a new (unsaved) source object for this DataModel.
Method %OnNewSource(Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ##class(ZENDemo.Data.Patient).%New()
}

/// Load an instance of the source object for this DataModel.
Method %OnOpenSource(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ##class(ZENDemo.Data.Patient).%OpenId(pID,pConcurrency,.pSC)
}

/// Load an instance of the source object for this DataModel.
Method %OnSaveSource(pSource As ZENDemo.Data.Patient) As %Status
{
	Set tSC = pSource.%Save()
	Set ..%id = pSource.%Id()
	Quit tSC
}

/// Delete instance of associated source object.
ClassMethod %OnDeleteSource(pID As %String) As %Status
{
	Quit ##class(ZENDemo.Data.Patient).%DeleteId(pID)
}

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As ZENDemo.Data.Patient) As %Status
{
	Set ..Name = pSource.Name
	Set ..SSN = pSource.SSN
	Set ..Memo = pSource.Memo
	Set ..City = pSource.Home.City
	Set ..State = pSource.Home.State
	Set ..MaritalStatus = pSource.MaritalStatus
	Quit $$$OK
}

/// This callback method does the actual work of storing values into the source object.
Method %OnStoreModel(pSource As ZENDemo.Data.Patient) As %Status
{
	Set pSource.Name = ..Name
	Set pSource.SSN = ..SSN
	Set pSource.Memo = ..Memo
	Set pSource.Home.City = ..City
	Set pSource.Home.State = ..State
	Set pSource.MaritalStatus = ..MaritalStatus	
	Quit $$$OK
}

/// Dynamically modify information about properties contained by this model.
ClassMethod %OnGetPropertyInfo(pIndex As %Integer, ByRef pInfo As %String, pExtended As %Boolean = 0) As %Status
{
	Quit $$$OK
}

/// Invoke a named action on this dataModel.
Method %OnInvokeAction(pAction As %String, pData As %String) As %Status
{
	If (pAction = "log") {
		#; log this action to a global
		Set ^ZENMVC = "time: " _ $ZH _ " id:" _ ..%id
	}
	Quit $$$OK
}

}

