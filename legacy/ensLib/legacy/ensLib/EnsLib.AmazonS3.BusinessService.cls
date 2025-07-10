/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.AmazonS3.BusinessService uses an EnsLib.AmazonS3.InboundAdapter to fetch objects from Amazon S3 and then forwards the messages to its targets.
Class EnsLib.AmazonS3.BusinessService Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.AmazonS3.InboundAdapter";

Property Adapter As EnsLib.AmazonS3.InboundAdapter;

Property TargetConfigNames As Ens.DataType.ConfigName;

Property %targetConfigs As %String [ Internal, MultiDimensional, Private ];

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Parameter CONTAINERCLASS = "Ens.StreamContainer";

Method OnInit() As %Status [ Internal ]
{
    Kill ..%targetConfigs
    Set targets = $LFS(..TargetConfigNames)
    For i=1:1:$LL(targets) {
        Set target = $LG(targets, i)
        Set ..%targetConfigs(target) = ""
    }

    Return $$$OK
}

Method OnProcessInput(pInput As EnsLib.CloudStorage.InboundInput, Output pOutput As %RegisteredObject) As %Status [ Internal ]
{
    $$$sysTRACE("Fetched blob: " _ pInput.Name)

    Set sc = $$$OK

    Set message = $CLASSMETHOD(..#CONTAINERCLASS, "%New", pInput.Content)
    Set message.OriginalFilename = pInput.Name
    Do message.SetAttributes("Meta=" _ pInput.Meta)

    $$$SyncCommitSet(syncCommit)
    Set target="" For { Set target = $ORDER(..%targetConfigs(target)) Quit:target=""
        Set sc1 = ..SendRequestAsync(target, message)
        Set:$$$ISERR(sc1) sc = $$$ADDSC(sc, sc1)
    }
    $$$SyncCommitClear(syncCommit)

    Return sc
}

}
