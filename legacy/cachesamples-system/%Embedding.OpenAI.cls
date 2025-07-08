/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Extends the %Embedding.Interface class, using OpenAI's API endpoint.
Class %Embedding.OpenAI Extends %Embedding.Interface
{

/// Validates %Embedding.Config's Configuration property. 
/// { "modelName": <Embedding model name>, "apiKey" : <OpenAI Api Key>, "sslConfig" : <Name of SSL Configuration>, "checkTokenCount": <Optional, whether to check token count of input>, "maxTokens": <Optional, token threshold for input>, "httpConfig": <Optional JSON of http configurations>}
/// As OpenAI's API uses a https endpoint, User must set up a SSL config in the Management Portal: System Administration -> Security -> SSL/TSL Configurations -> Create new configuration 
ClassMethod IsValidConfig(config As %DynamicObject, ByRef errorMsg As %String) As %Boolean
{
    if config.%Get("modelName") = "" {
        set errorMsg = $$$Text("'modelName' not set", "%SQL.VECTOR")
        return 0
    }
    if config.%Get("apiKey") = "" {
        set errorMsg = $$$Text("'apiKey' not set", "%SQL.VECTOR")
        return 0
    }
    set sslConfig = config.%Get("sslConfig")
    if sslConfig= ""{
        set errorMsg = $$$Text("'sslConfig' not set", "%SQL.VECTOR")
        return 0
    } else{
        // Check if SSL Configuration exists
        do GetSSLConfigList^%SYS.SECURITY1(.sslConfigs)
        set key = ""
        set key = $ORDER(sslConfigs(""),1,value) 
        while (key '= ""){
            if (value = sslConfig) {
                return 1
            }
            set key = $ORDER(sslConfigs(key),1,value) 
        }
        set errorMsg = $$$FormatText($$$Text("sslConfig '%1' does not exist. Check your SSL config in the Management Portal: System Administration -> Security -> SSL/TSL Configurations", "%SQL.Function"),sslConfig)
        return 0
    }
    return 1
}

/// Generates embeddings using Open AI's embedding API endpoint
ClassMethod Embedding(input As %String, configuration As %String) As %Vector
{
    try {
        set inputData = $SELECT($ISOBJECT(input)=1:input.%ToJSON(), 1:input)
        set config = [].%FromJSON(configuration)
        set checkTokenCount = config.%Get("checkTokenCount", 0) // Defaults to false
        set apiKey = config.%Get("apiKey")
        set modelName = config.%Get("modelName")
        set sslConfig = config.%Get("sslConfig")
        set httpConfig = config.%Get("httpConfig")
        if (checkTokenCount){
            set maxTokens = config.%Get("maxTokens", -1) 
            set inputTokens = ..EstimateTokenCount(inputData)
            if (maxTokens = -1){
                if (inputTokens > 8191) {
                // OpenAI defaults to 8191
                $$$ThrowStatus($$$ERROR($$$InputTokenExceededError, inputTokens, 8191))
                }
            }
            elseif (inputTokens > maxTokens){
                $$$ThrowStatus($$$ERROR($$$InputTokenExceededError, inputTokens, maxTokens))
            }
            
        }
    } catch e {
        $$$ThrowStatus($$$ERROR($$$EmbeddingGeneralError,"Error processing input or configuration in %Embedding.OpenAI: "_e.DisplayString()))
    }
    try{
        // Set up the HTTP request
        Set req = ##class(%Net.HttpRequest).%New()
        Set req.Server = "api.openai.com"
        Set req.Authorization = "Bearer "_apiKey 
        Set req.Https = 1
        Set req.SSLConfiguration=sslConfig 
        Set req.ContentType = "application/json"

        // Set Http Configurations
        if (httpConfig'="") {
            set iterator = httpConfig.%GetIterator()
            while iterator.%GetNext(.key, .value) {
                set $PROPERTY(req,key) = value
            }
        }
        // Create the request body
        Set body = ##class(%Library.DynamicObject).%New()
        set body.input = inputData
        set body.model = modelName 
        
        // Convert the request body to JSON and write to the request
        do req.EntityBody.Write(body.%ToJSON())

        // Send POST request to the embeddings endpoint
        set endpoint = "/v1/embeddings"
    } catch e {
            $$$ThrowStatus($$$ERROR($$$EmbeddingGeneralError,"Error setting up %Net.HttpRequest: "_e.DisplayString()))
        }
    try {
        set sc = req.Post(endpoint)
        $$$ThrowOnError(sc)
        
        set statusCode = req.HttpResponse.StatusCode
        if (statusCode '= 200) {
            set response = [].%FromJSON(req.HttpResponse.Data)
            $$$ThrowStatus($$$ERROR($$$EmbeddingApiError, "openai", req.HttpResponse.StatusLine _ ". "_response.%Get("error").%Get("message")))
        }

        // Parse the JSON response
        set response = {}.%FromJSON(req.HttpResponse.Data) 
        
        // Extract the embedding data from the response
        set embeddings = response.data.%Get(0).embedding

        // Convert from dynamic array to vector
        set iter = embeddings.%GetIterator()
        while iter.%GetNext(.key,.value, .type){
            set $vector(v, $increment(i), "xf32") = value
        }
        return v

    } catch e {
        $$$ThrowStatus($$$ERROR($$$EmbeddingApiError,""""_req.Server_endpoint_"""",e.DisplayString()))
    }
}

ClassMethod EstimateTokenCount(input As %String)
{
    set charEstimate = $NUMBER($LENGTH(input)/4,0) // 4 characters per token
    set wordEstimate = $NUMBER($LENGTH(input, " ") * 4 / 3, 0) // 3/4 words per token
    return $s(wordEstimate>charEstimate:wordEstimate, 1: charEstimate) // return larger estimate
}

}
