/// CSV to XML File Operation
/// This Business Operation receives CSV.PersonRecord messages and writes them as XML files
Class CSV.XMLFileOperation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Property Adapter As EnsLib.File.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// Process CSV PersonRecord and write as XML file
Method OnMessage(pRequest As CSV.PersonRecord, Output pResponse As Ens.Response) As %Status
{
    Try {
        Set tSC = $$$OK
        
        // Generate XML filename with timestamp and person name
        Set tTimestamp = $TR($ZDT($H,3)," :","_")
        Set tFilename = "person-"_pRequest.Firstname_"-"_pRequest.Lastname_"-"_tTimestamp_".xml"
        
        // Get XML content from the message
        Set tSC = pRequest.%XMLExportToString(.tXMLContent)
        If $$$ISERR(tSC) Quit
        
        // Write XML content to file
        Set tSC = ..Adapter.PutLine(tFilename, tXMLContent)
        If $$$ISERR(tSC) Quit
        
        // Create response
        Set pResponse = ##class(Ens.StringResponse).%New()
        Set pResponse.StringValue = "XML file written: "_tFilename
        
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    
    Return tSC
}

/// Return an array of connections for this Business Operation
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Do ##super(.pArray,pItem)
}

XData MessageMap
{
<MapItems>
    <MapItem MessageType="CSV.PersonRecord">
        <Method>OnMessage</Method>
    </MapItem>
</MapItems>
}

}
