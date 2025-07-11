/// Demo File Operation for Testing
/// This Business Operation writes messages to files
Class Demo.FileOperation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Property Adapter As EnsLib.File.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// Write a string request to a file
Method OnMessage(pRequest As Ens.StringRequest, Output pResponse As Ens.Response) As %Status
{
    Try {
        Set tSC = $$$OK
        
        // Generate filename with timestamp
        Set tFilename = "demo-output-"_$TR($ZDT($H,3)," :","_")_".txt"
        
        // Write the string content to file
        Set tSC = ..Adapter.PutLine(tFilename, pRequest.StringValue)
        If $$$ISERR(tSC) Quit
        
        // Create response
        Set pResponse = ##class(Ens.StringResponse).%New()
        Set pResponse.StringValue = "File written: "_tFilename
        
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
    <MapItem MessageType="Ens.StringRequest">
        <Method>OnMessage</Method>
    </MapItem>
</MapItems>
}

}