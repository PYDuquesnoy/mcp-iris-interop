/// Sample DataModel used by MVC Form page.
Class ZENMVC.FormDataModel2 Extends %ZEN.DataModel.ObjectDataModel
{

Property Name As %String;

Property SSN As %String;

Property City As %String(ZENSQL = "Select ID,Name,ZIP FROM ZENDemo_Data.City ORDER BY Name,ZIP", ZENSQLLOOKUP = "Select Name,ZIP FROM ZENDemo_Data.City WHERE ID = ?");

/// Load an instance of the source object for this DataModel.
Method %OnOpenSource(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	Quit ##class(ZENDemo.Data.Patient).%OpenId(pID,pConcurrency,.pSC)
}

/// Load an instance of the source object for this DataModel.
Method %OnSaveSource(pSource As ZENDemo.Data.Patient) As %Status
{
	Quit pSource.%Save()
}

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As ZENDemo.Data.Patient) As %Status
{
	Set ..Name = pSource.Name
	Set ..SSN = pSource.SSN
	Set ..City = pSource.Home.City
	Quit $$$OK
}

/// This callback method does the actual work of storing values into the source object.
Method %OnStoreModel(pSource As ZENDemo.Data.Patient) As %Status
{
	Set pSource.Name = ..Name
	Set pSource.SSN = ..SSN
	Set pSource.Home.City = ..City
	Quit $$$OK
}

}

