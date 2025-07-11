/// Demo File Service for Testing
/// This Business Service reads files and sends them as messages
Class Demo.FileService Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

Property Adapter As EnsLib.File.InboundAdapter;

/// Process input from file
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
    Try {
        Set tSC = $$$OK
        
        // Get the file stream
        Set tStream = pInput
        
        // Create a string request with file contents
        Set tRequest = ##class(Ens.StringRequest).%New()
        Set tRequest.StringValue = tStream.Read()
        
        // Send to configured target (if any)
        Set tSC = ..SendRequestSync("Demo.FileOperation", tRequest, .tResponse)
        
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    
    Return tSC
}

/// Return an array of connections for this Business Service
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Do ##super(.pArray,pItem)
}

}