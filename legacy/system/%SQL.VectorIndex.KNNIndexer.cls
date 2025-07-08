/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %KNNIndexInclude

IncludeGenerator %KNNIndexInclude

Class %SQL.VectorIndex.KNNIndexer Extends %Library.RegisteredObject
{

Property GraphLocation As %String;

Property DataLocation As %String;

Property IndexGlobalLocation As %String;

Property ClassName As %String;

Property IndexName As %String;

Property Property As %String;

Property Data As %String;

Property PropertyGlb As %String;

Property PropertyGlbListIdx As %Integer [ InitialExpression = 0 ];

Property Dim As %Integer(MINVAL = 1);

Property Distance As %String [ InitialExpression = "COSINE" ];

Property K As %Integer(MINVAL = 1) [ InitialExpression = 5 ];

Property OffSet As %Integer [ InitialExpression = 0 ];

Property Point As %Vector;

Property TopK [ Internal, MultiDimensional ];

Method %OnNew(ClassName, IndexName, Distance, IndexProperty, DIM, IndexData) As %Status
{
    Set i%ClassName = ClassName, i%IndexName = IndexName
    Set indexSQLName = $$$SQLLocMapIndexName($g($$$EXTSQLMAPsqlinfo($$$rEXT,i%ClassName,IndexName)))
    Set:indexSQLName="" indexSQLName=IndexName

    If '$data(Distance) {
        Set Distance = $$$comMemberArrayGet(ClassName,$$$cCLASSindex,indexSQLName,$$$cPROPparameter,"Distance")
    }
    Set Distance = $$$UPPER(Distance)

    
    If '$data(IndexProperty) {
        Set IndexProperty = $$$comMemberKeyGet(ClassName,$$$cCLASSindex,indexSQLName,$$$cINDEXproperties)
    }
    If '$data(DIM) {
        Set DIM = $$$comMemberArrayGet(ClassName,$$$cCLASSproperty,IndexProperty,$$$cPROPparameter,"LEN")
    }
    If '$DATA(IndexData) {
        Set IndexData = $$$comMemberKeyGet(ClassName,$$$cCLASSindex,IndexProperty,$$$cINDEXdata)
    }
    Set i%Distance = Distance, i%Dim = DIM, i%Property=IndexProperty, i%Data = IndexData

    Set baseref = $$$EXTADDRbasereference($$$pEXT,ClassName,indexSQLName)
    If baseref '= "" {
        Set i%IndexGlobalLocation = baseref
        if $e(baseref,*) = ")"{
            Set baseref = $e(baseref,1,*-1)
            Set i%GraphLocation = baseref_",""G"")" //GRAPH
            Set i%DataLocation = baseref_",""D"")" //Data
        } else {
            Set i%GraphLocation = baseref_"(""G"")" //GRAPH
            Set i%DataLocation = baseref_"(""D"")" //Data
        } 
    } else {
        Set i%IndexGlobalLocation = "^IRIS.KNNIndex("_$$$AddQuote(i%ClassName)_","_$$$AddQuote(i%IndexName)_")"
        Set i%GraphLocation = "^IRIS.KNNIndex("_$$$AddQuote(i%ClassName)_","_$$$AddQuote(i%IndexName)_",""G"")"
        Set i%DataLocation = "^IRIS.KNNIndex("_$$$AddQuote(i%ClassName)_","_$$$AddQuote(i%IndexName)_",""D"")"
    }

    set propertyloc =$$$EXTPROPondisk($$$pEXT,ClassName,IndexProperty)
    set i%PropertyGlb = $p($p(propertyloc,"$g(",2),"(id)",1)
    If ($e(propertyloc,1,4)="$lg(")||($e(propertyloc,1,9)="$listget("){
        set i%PropertyGlbListIdx=$e($p(propertyloc,",",*),1,*-1)
    }

    Return $$$OK
}

/// Inserts row with id pID into the KNN index
/// lock indicates if locking is in effect (lock=1) or not (lock =0). 
Method Insert(pID, ByRef pArg, lock)
{
    Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$MethodNotImplemented,"%SQL.VectorIndex.KNNIndexer::Insert"))
}

/// Removes row with id pID from the KNN index
/// lock indicates if locking is in effect (lock=1) or not (lock =0). 
Method Delete(pID, ByRef pArg, lock)
{
    Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$MethodNotImplemented,"%SQL.VectorIndex.KNNIndexer::Delete"))
}

/// Update row with id pID in the KNN index
/// lock indicates if locking is in effect (lock=1) or not (lock =0). Default value is 1.
Method Update(pID, ByRef pArg, lock)
{
    Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$MethodNotImplemented,"%SQL.VectorIndex.KNNIndexer::Update"))
}

/// Purge the KNN index
/// lock indicates if locking is in effect (lock=1) or not (lock =0). Default value is 1.
Method Purge(lock = 1)
{
    $$$Lock(@(i%GraphLocation),"","purging")
    Try {
        Kill @(i%IndexGlobalLocation)
        $$$Unlock(@(i%GraphLocation),"")
    } catch exp {
        $$$Unlock(@(i%GraphLocation),"")
        Throw exp
    }
}

/// Find the top K nearest neighbor of point and store the results as a local array in i%TopK
Method TopK(point, k, additionalParameters...)
{
    Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$MethodNotImplemented,"%SQL.VectorIndex.KNNIndexer::TopK"))
}

/// Returns by reference the next nearest neighbor to i%Point and the distance between this neighbor to i%Point
Method getNext(ByRef distance, ByRef id) As %Boolean
{
    Throw ##class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$MethodNotImplemented,"%SQL.VectorIndex.KNNIndexer::getNext"))
}

/// Compute the distance between vec1 and vec2, using the distance function specified in i%Distance
/// Supported distance functions: "COSINE" and "DOTPRODUCT"
Method ComputeDistance(vec1 As %Vector, vec2 As %Vector, ByRef status As %Status) As %Library.Decimal
{
    If i%Distance = "COSINE" {
        Return -$vop("cosine-similarity",vec1,vec2)
    } Elseif i%Distance = "DOTPRODUCT" {
        Return -$vop("dot-product",vec1,vec2)
    /*} Elseif i%Distance = "L2" {
        Set vecdiff = $vop("v-",vec1,vec2)
        Return $vop("sum",$vop("v*",vecdiff,vecdiff)) */
    } Else {
        Set status = $$$ERROR($$$VecIdxDistanceNotSupported,i%Distance)
    }
}

}
