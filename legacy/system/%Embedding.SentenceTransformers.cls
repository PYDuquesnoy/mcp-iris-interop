/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Extends the %Embedding.Interface class, using Hugging Face's SentenceTransformers package. 
Class %Embedding.SentenceTransformers Extends %Embedding.Interface
{

/// Validates %Embedding.Config's Configuration property. 
/// { 
/// "modelName" : <Name of sentence_transformers model>,
/// "hfCachePath" : <Path to cache folder where models will be downloaded>, 
/// "hfToken" : <Optional token to access gated hugging face models>, 
/// "checkTokenCount": <Optional, whether to check token count of input>, 
/// "maxTokens": <Optional, token threshold for input>
/// "pythonPath": <Optional, path to use to retrieve python packages>}
/// Also checks if the python package 'sentence_transformers' is installed. 
ClassMethod IsValidConfig(config As %DynamicObject, ByRef errorMsg As %String) As %Boolean
{
    // TODO: Warn if CUDA/MPS is not enabled / installed
    if config.%Get("modelName") = "" {
        set errorMsg = $$$Text("'modelName' not set", "%SQL.VECTOR")
        return 0
    }
    if config.%Get("hfCachePath") = "" {
        set errorMsg = $$$Text("'hfCachePath' not set", "%SQL.VECTOR")
        return 0
    }
    try {
        do ..CheckInstall(config.%Get("pythonPath", ""))
    } catch e {
        set errorMsg = $$$FormatText($$$Text("%1. Install python package 'sentence_transformers'","%SQL.VECTOR"),e.Data)
        return 0
    }
    try {
        do ..DownloadModel(config.%Get("modelName"), config.%Get("hfCachePath"), config.%Get("hfToken",""),config.%Get("pythonPath", ""))
    } catch e {
        set errorMsg = $$$FormatText($$$Text("%1. Error downloading model","%SQL.VECTOR"),e.Data)
        return 0
    }
    return 1
}

/// Generates embeddings locally using sentence_transformers
ClassMethod Embedding(input As %String, configuration As %String) As %Vector
{
    try {
        set config = [].%FromJSON(configuration)
        set inputData = $SELECT($ISOBJECT(input)=1:input.%ToJSON(), 1:input)
        set embeddingsPy = ..EmbeddingPy(config.%Get("modelName"), inputData_"", config.%Get("hfCachePath"), config.%Get("hfToken", ""), config.%Get("checkTokenCount", 0), config.%Get("maxTokens", -1),config.%Get("pythonPath", ""))
        return ##class(%Library.Vector).DisplayToLogical(embeddingsPy)
    } catch e {
        $$$ThrowStatus($$$ERROR($$$EmbeddingGeneralError,e.Data))
    }
}

/// Embedded python function that uses sentence_transformers to retrieve embeddings. Example modelName: sentence-transformers/all-MiniLM-L6-v2
ClassMethod EmbeddingPy(modelName As %String, input As %String, cacheFolder As %String, token As %String, checkTokenCount As %Boolean, maxTokens As %Integer, pythonPath As %String = "") [ Language = python ]
{
    if pythonPath:
        import sys
        sys.path.append(pythonPath)
    import os 
    import stat
    import platform
    from sentence_transformers import SentenceTransformer
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    
    if token:
        os.environ["HF_TOKEN"] = token
    else:
        os.environ["HF_TOKEN"] = "." # Set to some dummy value to prevent unintended access to local storage, caused by a sentence_transformers package bug

    # The code here ensures there is no unexpected 'Access Denied' when sentence_transformers downloads models or updates any cache
    current_os = platform.system()
    if current_os == "Linux" or current_os == "Darwin":
        # Set umask on Linux or Mac
        old_umask = os.umask(0o002)
    elif current_os == "Windows":
        # Save the current permissions on Windows and set folder to writable
        old_permissions = os.stat(cacheFolder).st_mode
        os.chmod(cacheFolder, old_permissions | stat.S_IWRITE) 

    model = SentenceTransformer(modelName, cache_folder = cacheFolder, trust_remote_code=True)
    
    # Check token count if needed
    if checkTokenCount:
        tokenCount = len(model[0].tokenizer(input, return_attention_mask=False, return_token_type_ids=False).input_ids)
        if maxTokens == -1:
            if tokenCount > model.max_seq_length:
                # maxTokens not provided, check against model's max token count
                raise Exception(f"Input has a token count of {tokenCount}, which exceeds the model's maximum token count of {model.max_seq_length}")
        elif tokenCount > maxTokens:
            # maxTokens provided by user
            raise Exception(f"Input has a token count of {tokenCount}, which exceeds maxTokens {maxTokens}")

    # Generate embeddings
    embeddings = model.encode([input])[0]

    # Revert umask on Linux or Mac
    if (current_os == "Linux" or current_os == "Darwin") and old_umask is not None:
        os.umask(old_umask)
    # Revert folder permissions on Windows
    elif current_os == "Windows" and old_permissions is not None:
        os.chmod(cacheFolder, old_permissions)

    return str(embeddings.tolist())
}

ClassMethod DownloadModel(modelName As %String, cacheFolder As %String, token As %String, pythonPath As %String = "") [ Language = python ]
{
    if pythonPath:
        import sys
        sys.path.append(pythonPath)
    import stat
    import os
    import platform
    from huggingface_hub import hf_hub_download
    os.environ["TOKENIZERS_PARALLELISM"] = "false"
    
    if token:
        os.environ["HF_TOKEN"] = token
    else:
        os.environ["HF_TOKEN"] = "." # Set to some dummy value to prevent unintended access to local storage, caused by a sentence_transformers package bug
        token = None
    
    # The code here ensures there is no unexpected 'Access Denied' when sentence_transformers downloads models or updates any cache
    current_os = platform.system()
    if current_os == "Linux" or current_os == "Darwin":
        # Set umask on Linux or Mac
        old_umask = os.umask(0o002)
    elif current_os == "Windows":
        # Save the current permissions on Windows and set folder to writable
        old_permissions = os.stat(cacheFolder).st_mode
        os.chmod(cacheFolder, old_permissions | stat.S_IWRITE) 

    hf_hub_download(
            modelName,
            filename="modules.json",
            token=token,
            cache_dir=cacheFolder,
        )

     # Revert umask on Linux or Mac
    if (current_os == "Linux" or current_os == "Darwin") and old_umask is not None:
        os.umask(old_umask)
    # Revert folder permissions on Windows
    elif current_os == "Windows" and old_permissions is not None:
        os.chmod(cacheFolder, old_permissions)
}

/// Throws an error if python package 'sentence_transformers' is not installed.
ClassMethod CheckInstall(pythonPath As %String = "") [ Language = python ]
{
    if pythonPath:
        import sys
        sys.path.append(pythonPath)
    import sentence_transformers
}

/// Retrieves a model's vector length using the sentence_transformers package
ClassMethod GetVectorLength(modelName As %String, pythonPath As %String = "", cacheFolder As %String = "") As %Integer [ Language = python ]
{
    if pythonPath:
        import sys
        sys.path.append(pythonPath)
    from sentence_transformers import SentenceTransformer
    # Load your chosen model
    model = SentenceTransformer(modelName, cache_folder=cacheFolder, trust_remote_code=True)
    # Get the model's embedding vector length
    return model.get_sentence_embedding_dimension()
}

/// Helper function to retrieve a model's maximum input tokens using the sentence_transformers package
ClassMethod GetMaxTokens(modelName As %String, pythonPath As %String = "", cacheFolder As %String = "") As %Integer [ Language = python ]
{
    if pythonPath:
        import sys
        sys.path.append(pythonPath)
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer(modelName, cache_folder=cacheFolder, trust_remote_code=True)
    return model.max_seq_length
}

}
