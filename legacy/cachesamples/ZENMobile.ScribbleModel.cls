Class ZENMobile.ScribbleModel Extends %ZEN.DataModel.ObjectDataModel
{

Property Name As %String;

Property Art As %String;

/// Load an instance of a new (unsaved) source object for this DataModel.
Method %OnNewSource(Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
    Quit ##class(ZENMobile.Data.Scribbles).%New()
}

/// Save instance of associated source object.
Method %OnSaveSource(pSource As ZENMobile.Data.Scribbles) As %Status
{
    Set tSC=pSource.%Save()
    Set ..%id=pSource.%Id()
    Quit tSC
}

/// Load an instance of the source object for this DataModel.
Method %OnOpenSource(pID As %String, pConcurrency As %Integer = -1, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
    Quit ##class(ZENMobile.Data.Scribbles).%OpenId(pID,pConcurrency,.pSC)
}

/// Delete instance of associated source object.
ClassMethod %OnDeleteSource(pID As %String) As %Status
{
   Quit ##class(ZENMobile.Data.Scribbles).%DeleteId(pID)
}

/// Do the actual work of loading values from the source object.
Method %OnLoadModel(pSource As ZENMobile.Data.Scribbles) As %Status
{
    Set ..Name = pSource.Name
    Set ..Art = pSource.Art
    Quit $$$OK
}

/// Do the actual work of storing values into the source object.
Method %OnStoreModel(pSource As ZENMobile.Data.Scribbles) As %Status
{
    Set pSource.Name = ..Name
    Set pSource.Art = ..Art
    Quit $$$OK
}

}

