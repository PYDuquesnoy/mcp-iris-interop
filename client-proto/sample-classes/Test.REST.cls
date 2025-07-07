/// Sample REST service class for testing
Class Test.REST Extends %CSP.REST
{

/// URL map for the REST service
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/info" Method="GET" Call="GetInfo" />
<Route Url="/sample/:id" Method="GET" Call="GetSample" />
<Route Url="/sample" Method="POST" Call="CreateSample" />
<Route Url="/utility/factorial/:number" Method="GET" Call="CalculateFactorial" />
</Routes>
}

/// Get basic system information
ClassMethod GetInfo() As %Status
{
    Set %response.ContentType = "application/json"
    Set info = {
        "namespace": ($NAMESPACE),
        "timestamp": ($ZDATETIME($HOROLOG, 3)),
        "version": ($SYSTEM.Version.GetNumber()),
        "user": ($USERNAME)
    }
    Write info.%ToJSON()
    Return $$$OK
}

/// Get a sample object by ID
ClassMethod GetSample(id As %String) As %Status
{
    Set %response.ContentType = "application/json"
    
    Set obj = ##class(Test.Sample).%OpenId(id)
    If '$IsObject(obj) {
        Set %response.Status = "404 Not Found"
        Write {"error": "Sample not found", "id": (id)}.%ToJSON()
        Return $$$OK
    }
    
    Set result = {
        "id": (obj.%Id()),
        "name": (obj.Name),
        "value": (obj.Value),
        "createdDate": (obj.CreatedDate)
    }
    Write result.%ToJSON()
    Return $$$OK
}

/// Create a new sample object
ClassMethod CreateSample() As %Status
{
    Set %response.ContentType = "application/json"
    
    Try {
        Set input = {}.%FromJSON(%request.Content)
        Set name = input.name
        Set value = input.value
        
        Set obj = ##class(Test.Sample).CreateSample(name, value)
        Set sc = obj.%Save()
        
        If $$$ISERR(sc) {
            Set %response.Status = "400 Bad Request"
            Write {"error": "Failed to save object", "details": ($SYSTEM.Status.GetErrorText(sc))}.%ToJSON()
            Return $$$OK
        }
        
        Set result = {
            "id": (obj.%Id()),
            "name": (obj.Name),
            "value": (obj.Value),
            "createdDate": (obj.CreatedDate),
            "message": "Object created successfully"
        }
        Write result.%ToJSON()
        
    } Catch ex {
        Set %response.Status = "500 Internal Server Error"
        Write {"error": "Internal error", "details": (ex.DisplayString())}.%ToJSON()
    }
    
    Return $$$OK
}

/// Calculate factorial using utility class
ClassMethod CalculateFactorial(number As %String) As %Status
{
    Set %response.ContentType = "application/json"
    
    If '$ISVALIDNUM(number) {
        Set %response.Status = "400 Bad Request"
        Write {"error": "Invalid number", "input": (number)}.%ToJSON()
        Return $$$OK
    }
    
    Set n = +number
    If (n < 0) || (n > 20) {
        Set %response.Status = "400 Bad Request"
        Write {"error": "Number must be between 0 and 20", "input": (n)}.%ToJSON()
        Return $$$OK
    }
    
    Set factorial = ##class(Test.Utility).Factorial(n)
    Set result = {
        "input": (n),
        "factorial": (factorial),
        "timestamp": ($ZDATETIME($HOROLOG, 3))
    }
    Write result.%ToJSON()
    
    Return $$$OK
}

}