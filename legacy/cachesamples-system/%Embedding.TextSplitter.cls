/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Embedding.TextSplitter Extends %RegisteredObject
{

/// Splits text into chunks naively based on one separator.
ClassMethod split(text As %String, separator As %String = " ", chunkSize As %Integer = 4000, overlap As %Integer = 200, stripWhitespace As %Boolean = 1) As %List
{
    return ..mergeSplits($LISTFROMSTRING(text, separator), chunkSize, overlap, stripWhitespace)
}

/// Splits text into chunks recursively, based on a list of separators.
ClassMethod recursiveSplit(text As %String, separators As %DynamicArray, chunkSize As %Integer = 4000, overlap As %Integer = 200, stripWhitespace As %Boolean = 1, separatorIdx = 0) As %List
{
    try {
        if (separatorIdx = separators.%Size()){
            // No more separators, just forcefully split based on character
            set finalChunks = ""
            set stepSize = chunkSize - overlap
            set textLen = $LENGTH(text)
            // This keep the chunkSizes roughly even, while staying close to the desired chunk size
            set optimalChunkCount = $$$ceiling((textLen - overlap)/stepSize)
            set optimalChunkSize = $$$ceiling((textLen + ((optimalChunkCount - 1)*overlap))/optimalChunkCount)
            set startIdx = 1
            while (startIdx <= textLen){
                set endIdx = startIdx + optimalChunkSize - 1
                if (endIdx >= textLen){
                    // Reached the end
                    set finalChunks = finalChunks_$LISTBUILD($EXTRACT(text,startIdx,textLen))
                    quit
                }
                // Add chunk to finalChunks
                set finalChunks = finalChunks_$LISTBUILD($EXTRACT(text,startIdx,endIdx))
                set startIdx = startIdx + optimalChunkSize - overlap 
            }
            return finalChunks
        }
        // Split based on current separator
        set sep = separators.%Get(separatorIdx)
        set splits = $LISTFROMSTRING(text, sep)

        // Iterate through splits 
        set ptr = 0
        set finalChunks = "", currentChunk = "", currentChunkLen = -$LENGTH(sep)
        while $LISTNEXT(splits, ptr, split){
            set splitLen = $LENGTH(split)
            set currSplit = $SELECT(stripWhitespace=1: $ZSTRIP(split, "<>W"), 1: split)
            // if splitLen is less than chunkSize, add to currentChunk
            if (splitLen <= chunkSize){
                #; set $LIST(currentChunk, *+1) = split
                set currentChunk = currentChunk_ $LISTBUILD(split)
                set currentChunkLen = currentChunkLen + splitLen + $LENGTH(sep)
            }
            else{
                // If splitLen is greater than chunkSize, we merge existing splits in currentChunk, and recursively split this split further
                if currentChunk '= ""{ 
                    // Merge current chunks  and concat to final chunk list. 
                    set finalChunks=finalChunks_..mergeSplits(currentChunk,chunkSize,overlap,sep)
                    // Reset currentChunk 
                    set currentChunk = ""
                    set currentChunkLen = 0
                }
                set finalChunks = finalChunks _..recursiveSplit(split, separators, chunkSize, overlap, stripWhitespace, separatorIdx + 1)
            }
        }
        // Merge remaining splits
        if currentChunk '= ""{
            set finalChunks=finalChunks_..mergeSplits(currentChunk,chunkSize,overlap,sep)
        }
    } catch e {
        $$$ThrowStatus($$$ERROR($$$TextSplitterSplitError,e.Data))
    }
    return finalChunks
}

/// Method to merge splits to reach desired chunkSize and overlap
ClassMethod mergeSplits(splits As %List, chunkSize As %Integer = 4000, overlap As %Integer = 200, separator As %String = " ", stripWhitespace As %Boolean = 1) As %List
{
    try {
        set finalChunks = "", currentChunk = "", currentChunkLen = 0
        set ptr=0
        WHILE $LISTNEXT(splits,ptr,split) {
            set splitLen = $LENGTH(split)
            // Check if we've reached chunkSize
            if (currentChunk '= "" && (currentChunkLen + splitLen + $LENGTH(separator) > chunkSize)) {
                // Strip whitespace if needed and add to finalChunks
                set finalChunks = finalChunks_$LISTBUILD($SELECT(stripWhitespace=1: $ZSTRIP($LISTTOSTRING(currentChunk, separator), "<>W"), 1: $LISTTOSTRING(currentChunk, separator)))
                While (currentChunkLen > overlap){
                    if ($LISTLENGTH(currentChunk) = 1){
                        // Single subchunk is more than overlap, so we don't duplicate it
                        set currentChunk = ""
                        set currentChunkLen = 0
                        quit
                    } 
                    set currentChunkLen = currentChunkLen - $LENGTH($LIST(currentChunk, 1)) - $LENGTH(separator)
                    set currentChunk = $LIST(currentChunk, 2, *)
                }
            }
            // Build up currentChunk
            set currentChunk = currentChunk _$LISTBUILD(split)
            set currentChunkLen = currentChunkLen + splitLen + $LENGTH(separator)
        }
        // Add in remainder
        If currentChunk '= "" {
            // Strip whitespace if needed and add to finalChunks
            set finalChunks = finalChunks_$LISTBUILD($SELECT(stripWhitespace=1: $ZSTRIP($LISTTOSTRING(currentChunk, separator), "<>W"), 1: $LISTTOSTRING(currentChunk, separator)))
        }
    } catch e {
        $$$ThrowStatus($$$ERROR($$$TextSplitterMergeError,e.Data))
    }
    Quit finalChunks
}

}
