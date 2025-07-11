/// CSV File Service for Reading and Parsing CSV Files
/// This Business Service reads CSV files and converts them to CSV.PersonRecord messages
Class CSV.FileService Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

Property Adapter As EnsLib.File.InboundAdapter;

/// Process CSV file input
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
    Try {
        Set tSC = $$$OK
        
        // Get the file stream
        Set tStream = pInput
        
        // Read all lines from the file
        Set lineCount = 0
        While 'tStream.AtEnd {
            Set tLine = tStream.ReadLine()
            If tLine'="" {
                Set lineCount = lineCount + 1
                
                // Skip header line if it exists (optional)
                If lineCount=1 && (tLine["Firstname" || tLine["firstname" || tLine["First") {
                    Continue
                }
                
                // Parse CSV line into PersonRecord
                Set tPersonRecord = ##class(CSV.PersonRecord).CreateFromCSVLine(tLine)
                
                // Send to target operation with new session for each line
                Set tSC = ..SendRequestAsync("CSV.XMLFileOperation", tPersonRecord)
                If $$$ISERR(tSC) Quit
                
                // Log successful processing
                $$$LOGINFO("Processed person: "_tPersonRecord.%DisplayString())
            }
        }
        
        $$$LOGINFO("Processed "_lineCount_" records from CSV file")
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        $$$LOGERROR("Error processing CSV file: "_ex.DisplayString())
    }
    
    Return tSC
}

/// Return an array of connections for this Business Service
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Do ##super(.pArray,pItem)
}

}
