/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class stores various Embedding endpoints as a table.
/// To use the EMBEDDING SQL function or the %Embedding datatype, users need to first insert a configuration into this table
Class %Embedding.Config Extends %Persistent [ Final ]
{

/// Name of configuration, to be referenced when using the EMBEDDING SQL function or the %Embedding datatype
Property Name As %String(MAXLEN = 100) [ Required ];

Index NameIndex On Name [ IdKey ];

/// JSON formatted string that contains class specific configuration details. Refer to the Embedding Class's IsValidConfig for more information
Property Configuration As %String(MAXLEN = "") [ Required ];

/// Name of %Embedding class that extends %Embedding.Interface. Eg. %Embedding.SentenceTransformers
Property EmbeddingClass As %String(MAXLEN = 250) [ Required ];

/// Length of embedding vector. If using %Embedding.SentenceTransformers, this can be left empty and will be automatically computed. If not, users must provide the vector length.
Property VectorLength As %Integer [ SqlComputed, SqlComputeOnChange = %%UPDATE ];

/// Optional description of configuration
Property Description As %String(MAXLEN = 5000);

Trigger ValidateConfig [ Event = INSERT/UPDATE ]
{
    // Check configuration based on EmbeddingClass
    set embeddingClass = {EmbeddingClass}
    
    // Check if embeddingClass exists and is compiled
    if '##class(%Dictionary.CompiledClass).%Exists($lb(embeddingClass)){
        set %ok = 0, %msg = $$$FormatText($$$Text("Embedding class ""%1"" does not exist","%SQL.Function"), embeddingClass)
    }
    // Check if embeddingClass is a subclass of the %Embedding.Interface abstract class
    if '$classmethod(embeddingClass,"%Extends","%Embedding.Interface"){
        set %ok = 0, %msg = $$$FormatText($$$Text("Embedding class ""%1"" is not a subclass of %Embedding.Interface","%SQL.Function"),embeddingClass)
    }
    // Validate Configuration JSON
    try {
        set config = [].%FromJSON({Configuration})
    } catch ex {
        set %ok = 0, %msg = $$$FormatText($$$Text("Invalid Configuration: Not a valid JSON format. %1","%SQL.Function"),{Configuration})
    }
    // Validate class specific Configuration 
    if '$CLASSMETHOD(embeddingClass, "IsValidConfig", config, .errorMsg){
        set %ok = 0, %msg = $$$FormatText($$$Text("Invalid Configuration: %1 %2","%SQL.Function"),errorMsg,{Configuration})
    }
}

ClassMethod VectorLengthComputation(cols As %Library.PropertyHelper) As %String
{
    if cols.getfield("EmbeddingClass") = "%Embedding.SentenceTransformers" {
        // If it's hf, we can retrieve the vector length
        set config = [].%FromJSON(cols.getfield("Configuration"))
        // validate config first then do vector length
        return ##class(%Embedding.SentenceTransformers).GetVectorLength(config.%Get("modelName"),config.%Get("pythonPath",""), config.%Get("hfCachePath"))
    } elseif cols.getfield("VectorLength") = "" {
        $$$ThrowStatus($$$ERROR($$$EmbeddingConfigError,"VectorLength not set"))
    }
    return cols.getfield("VectorLength")
}

Storage Default
{
<Data name="ConfigDefaultData">
<Value name="1">
<Value>Configuration</Value>
</Value>
<Value name="2">
<Value>EmbeddingClass</Value>
</Value>
<Value name="3">
<Value>VectorLength</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
</Data>
<DataLocation>^rINDEXSQL("Embedding")</DataLocation>
<DefaultData>ConfigDefaultData</DefaultData>
<IdLocation>^rINDEXSQL("Embedding")</IdLocation>
<IndexLocation>^rINDEXSQL("EmbeddingI")</IndexLocation>
<StreamLocation>^rINDEXSQL("EmbeddingS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
