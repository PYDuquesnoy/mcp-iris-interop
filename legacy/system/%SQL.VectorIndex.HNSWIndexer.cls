/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %KNNIndexInclude

IncludeGenerator %KNNIndexInclude

/// Hierarchical Navigable Small World (HNSW), implemented based on https://arxiv.org/abs/1603.09320
Class %SQL.VectorIndex.HNSWIndexer Extends %SQL.VectorIndex.KNNIndexer
{

/// graph storage version number
Parameter Version = 1;

/// The number of bi-directional links created for every new element during construction
Property M As %Integer(MINVAL = 1);

Property efConstruction As %Integer(MINVAL = 2);

Property efSearch As %Integer(MINVAL = 1);

/// A parameter that controls the number of layers in this graph
Property mL As %Double(MINVAL = 0);

Method %OnNew(ClassName, IndexName, Distance, IndexProperty, DIM, IndexData) As %Status
{
    Set sc = ##super(.ClassName, .IndexName, .Distance, .IndexProperty, .DIM, .IndexData)
    Set i%efConstruction = $$$comMemberArrayGet(ClassName,$$$cCLASSindex,IndexName,$$$cINDEXparameter,"efConstruction")
    Set i%M = $$$comMemberArrayGet(ClassName,$$$cCLASSindex,IndexName,$$$cINDEXparameter,"M")
    Return sc
}

/// Return a random positive integer based on the probability distribution described in the HNSW paper (https://arxiv.org/abs/1603.09320)
/// Parameter:
///     mL: controls the shape of the distribution. A larger mL results in more layers in the graph
ClassMethod HNSWrandomLevel(mL)
{
    Return (-$zln($random(1e17)/1e17)*mL)\1
}

/// Search for the top ef neighbors in layer lc for query point q, given the entry point epIdx
/// Stores the result in "results" local array that has most ef nodes. Each node in results is a list that contains the ID of the neighbor point and the distance between the neighbor point and q, subscripted by the ranking: results(ranking)=$lb(ID, distance)
Method HNSWsearchLayer(ByRef results, q, epIdx, ef, lc, lock = 0, ByRef rerun)
{
    Set epvec = $$$getVec(epIdx), rerun = 0
    If epvec="" {
        // the vector for the entry point (epIdx) of this search has been removed, so remove this point from the HNSW index and set rerun=1 to suggest reruning the top K search from the top layer
        Do ..Delete(epIdx)
        Set rerun=1
        Return
    }
    Set $$$bit(visited,epIdx)=1
    Set dist = ..ComputeDistance(q,epvec,.status)

    Set candidateArray(dist, epIdx)="",candidateSize=1, bestCdistance = dist
    Set resultArray(dist, epIdx)="",resultSize=1, worstRdistance = dist
    While candidateSize>0 {
        // extract nearest element from candidate to q 
        Set bestCdistance = $o(candidateArray(""))
        Set c = $o(candidateArray(bestCdistance,""))
        
        Quit:$DOUBLE(bestCdistance)>$DOUBLE(worstRdistance)

        Kill candidateArray(bestCdistance,c)
        Set candidateSize=candidateSize-1

        $$$HNSWLock(c,lc,"","searching")
        Try {
            // loop on the neighbors
            Set neighbor = ""
            For {
                Set neighbor=$o($$$HNSWEdge(lc,c,neighbor))
                Quit:neighbor=""

                If '$$$bit(visited,neighbor){
                    // Check if the neighbor point has been removed from the data map of the table. If so, remove it from the HNSW graph
                    Set nbrvec = $$$getVec(neighbor)
                    If nbrvec = "" {
                        Do ..Delete(neighbor)
                        Continue 
                    }

                    set $$$bit(visited,neighbor) = 1
                    Set dist = ..ComputeDistance(q,nbrvec,.status)
                    // update resultArray and candidateArray if needed
                    If (resultSize < ef)||(dist < worstRdistance) {
                        Set resultArray(dist,neighbor)=""
                        set resultSize = resultSize+1
                        If dist > worstRdistance {
                            Set worstRdistance = dist
                        }
                        while resultSize > ef {
                            Kill resultArray(worstRdistance,$o(resultArray(worstRdistance,""),-1))
                            Set worstRdistance = $o(resultArray(""),-1)
                            Set resultSize = resultSize-1
                        }

                        Set candidateArray(dist,neighbor)=""
                        Set candidateSize = candidateSize+1
                        if dist<bestCdistance Set bestCdistance=dist
                    }
                }
            }
            $$$HNSWUnlock(c,lc,"I")
        } catch ex {
            $$$HNSWUnlock(c,lc,"I")
            Throw ex
        }
    }

    do ..buildResults(.resultArray,.results)
}

/// Given a resultArray in HNSWsearchLayer,returns the same data in an array of lists: results(ranking)=$lb(idx, distance)
Method buildResults(ByRef data, ByRef results)
{
    Kill results
    Set distance = "",rst="",len=0
    For {
        Set distance = $o(data(distance))
        Quit:distance=""
        Set vecIdx = ""
        For {
            Set vecIdx = $o(data(distance,vecIdx))
            Quit:vecIdx=""
            Set results($i(len)) = $lb(+vecIdx,+distance)
        }
    }
    Set results=len
}

/// Inserts row with id pID into the HNSW index
/// lock indicates if locking is in effect (lock=1) or not (lock =0). Default value is 1.
Method Insert(pID, ByRef pArg, lock = 1)
{
    Return:pArg(1)=""

    If (i%Distance="COSINE"){
        // Cosine distance is not defined when point is an all-zero vector, ignore this point in this case
        Try { Return:$$$isAllZeroVector(pArg(1))} 
        catch ex1 {
            If ex1.Name = "<FUNCTION>"{
                // $$$isAllZeroVector doesn't work for xf32 vectors, check cosine instead 
                Try {Set temp = $VECTOROP("COSINE-SIMILARITY",pArg(1),pArg(1))} 
                Catch ex2 {Return:ex2.Name="<DIVIDE>"}
            }
        }
    }

    $$$HNSWCheckVersion
    Set M0max = 2*i%M
    Do HNSWinsert(i%M, pArg(1), pID, M0max, i%efConstruction, i%mL, lock)
    Return 

/// Insert a point vec from row ID pID into the HNSW graph index
/// Parameters:
///     M: The number of bi-directional links created for every new element during construction
///     M0max: the maximal number of bi-directional links created for every data vector in the 0th layer of the graph
///     efConstruction: The size of the candidate vectors when finding nearest neighbors for vec
///     mL: controls the number of layers in this graph
///     lock: indicates if locking is in effect (lock=1) or not (lock =0). Default value is 1.
HNSWinsert(M, vec, pID, M0max, efConstruction, mL, lock = 1)
    Set W = "" // list for the currently found nearest elements   
    //get top layer for HNSW (L) and vector index of enter point for hnsw (ep)
    Set $lg(L,ep) = $g($$$HNSWTopLayerAndEntryPoint,$lb(-1,-1)) 
    Set l = ..HNSWrandomLevel(mL) // new element's level

    if l>L {
        // Adding new layers to the graph, therefore hold exclusively lock on the graph global until this point is fully added to the graph
        $$$Lock(@(i%GraphLocation),"","inserting")

        Try {
            // Re-read the data of ep and L as the value of $$$HNSWTopLayer right before applying the lock. Check again that we do need to add a new layer
            //get top layer for HNSW (L) and vector index of enter point for hnsw (ep)
            Set $lg(L,ep) = $g($$$HNSWTopLayerAndEntryPoint, $lb(-1,-1)) 

            If l>L {
                If ep '= -1 {
                    // initialize new layers
                    for lc=(L+1):1:l {
                        Set $$$HNSWNode(lc, pID) = "" 
                    }
                    // add point to the existing layers if this point is not the first point in the graph
                    Do AddPointToExistingLayers
                } else {
                    // if this point is the first one in the graph, record the storage version number 
                    Set $$$HNSWVersion = ..#Version
                    Set $$$HNSWEfConstruct=efConstruction

                    // initialize new layers
                    for lc=(L+1):1:l {
                        Set $$$HNSWNode(lc, pID) = "" 
                    }
                }
                // update entry point and top layer, which makes new layers visible to search
                Set $$$HNSWTopLayerAndEntryPoint = $lb(l,pID)

            } else {
                Do AddPointToExistingLayers
            }
            $$$Unlock(@(i%GraphLocation),"")
        } Catch exp {
            $$$Unlock(@(i%GraphLocation),"")
            Throw exp
        }
        Return
    }

AddPointToExistingLayers
    // If l<=L, find the entry point for this vec on layer l
    for lc=L:-1:(l+1) {
        Do ..HNSWsearchLayer(.W, vec,ep,1,lc,lock)
        Set ep = $lg(W(1),1) // nearest element from W to q 
    }

    set topL = $s(L<l:L,1:l) // min(L,l)
    Set vecIdx="", distance="",neighbors=""

    $$$HNSWLockOnAllLayers(pID,"","inserting")

    Try {
        for lc= topL:-1:0 {
            Set Mmax = $s(lc:M,1:M0max)
            Do ..HNSWsearchLayer(.neighbors,vec,ep,efConstruction,lc,lock)  
            Set ep = $lg(neighbors(1),1)
            Set count = 0
        
            Set $$$HNSWNode(lc, pID) = ""
            For i=1:1:neighbors {
                Quit:$i(count)>M
                
                Set newNbrIdx = $lg(neighbors(i),1)
                $$$HNSWLock(newNbrIdx,lc,"","inserting")

                Try {
                    If '$data($$$HNSWNode(lc,newNbrIdx)) {
                        //If newNbrIdx has been removed from the graph, continue to the next one
                        $$$HNSWUnlock(newNbrIdx,lc,"I")
                        Continue
                    } 
                    
                    // add an edge from pID to newNbrIdx
                    Set $$$HNSWEdge(lc, pID, newNbrIdx)="" 
                    // compute the number of neighbors of newNbrIdx
                    Set size = 0, ptIdx=""
                    For {
                        Set ptIdx=$o($$$HNSWEdge(lc,newNbrIdx,ptIdx))
                        Quit:ptIdx=""
                        Do $i(size)
                    }

                    If size < Mmax {
                        Set $$$HNSWEdge(lc, newNbrIdx, pID)=""
                    } else {
                        // Check if the newNbrVec point has been removed from the data map of the table. If so, remove it from the HNSW graph
                        Set newNbrVec = $$$getVec(newNbrIdx)
                        If newNbrVec="" {
                            Do ..Delete(newNbrIdx,,lock)
                            $$$HNSWUnlock(newNbrIdx,lc,"I")
                            Continue 
                        }
                        // shrink connection for newNbrIdx
                        
                        Set newNbrDists($lg(neighbors(i),2),pID)="" // distances from neighbors of newNbrIdx to newNbrIdx

                        Set ptIdx = ""
                        For {
                            Set ptIdx=$o($$$HNSWEdge(lc,newNbrIdx,ptIdx))
                            Quit:ptIdx=""

                            // Check if the ptVec point has been removed from the data map of the table. If so, remove it from the HNSW graph
                            Set ptVec = $$$getVec(ptIdx)
                            If ptVec="" {
                                Do ..Delete(ptIdx,,lock)
                                Continue
                            }

                            Set dist = ..ComputeDistance(newNbrVec,ptVec,.status)
                            Set newNbrDists(dist, ptIdx) = ""
                        }

                        /// Alg 3 SELECT-NEIGHBORS-SIMPLE(q, C, M)
                        Set worstDist = $o(newNbrDists(""),-1)
                        Set worstIdx = $o(newNbrDists(worstDist,""),-1)
                        
                        If worstIdx'= pID {
                            // remove the worst point and add pID to the neighborhood of newNbrIdx
                            Set $$$HNSWEdge(lc,newNbrIdx, pID)=""
                            Kill $$$HNSWEdge(lc,newNbrIdx, worstIdx)
                        }
                            
                        Kill newNbrDists
                    }
                    $$$HNSWUnlock(newNbrIdx,lc,"I")
                } catch exp{
                    $$$HNSWUnlock(newNbrIdx,lc,"I")
                    Throw exp
                }
            }
        } 
        $$$HNSWUnlockOnAllLayers(pID,"I")
    } catch ex {
        $$$HNSWUnlockOnAllLayers(pID,"I")
        throw ex
    }
    Return
}

/// Removes row with id pID from the HNSW index
/// lock indicates if locking is in effect (lock=1) or not (lock =0). Default value is 1.
Method Delete(pID, ByRef pArg, lock = 1)
{
    $$$HNSWCheckVersion

    Set $lg(L,ep) = $g($$$HNSWTopLayerAndEntryPoint) 

    If pID = ep {
        // update entry point if needed
        $$$Lock(@(i%GraphLocation),"", "deleting")

        Try {
            Set $lg(L,ep) = $g($$$HNSWTopLayerAndEntryPoint)
            If pID = ep {
                Do RemovePoint

                // remove empty layers if any
                While ('$data($$$HNSWLayer(L)))&&(L>0){
                    Set L=L-1
                }

                if $data($$$HNSWLayer(L)) {
                    Set ep = $o($$$HNSWNode(L,""))
                    set $$$HNSWTopLayerAndEntryPoint = $lb(L,ep)
                } else {
                    Kill @(i%GraphLocation)
                }
            }
            $$$Unlock(@(i%GraphLocation),"")
        } catch exp {
            $$$Unlock(@(i%GraphLocation),"")
            Throw exp
        }
        Return 
    }

RemovePoint

    For layer=0:1:L{

        $$$HNSWLock(pID,layer,"","deleting")

        Try {
            // loop on the neighbors, remove the edge from neighbors to pID
            Set nbr = ""
            For {
                Set nbr=$o($$$HNSWEdge(layer,pID,nbr))
                Quit:nbr=""
                Kill $$$HNSWEdge(layer, nbr, pID)
            }

            Kill $$$HNSWNode(layer, pID)
            $$$HNSWUnlock(pID,layer,"")
        } catch exp {
            $$$HNSWUnlock(pID,layer,"")
            Throw exp
        }
    }

    // remove node data
    Kill $$$NodeData(pID)

    Return
}

/// Update a point by first deleting the old point, and then inserting the new point
/// lock indicates if locking is in effect (lock=1) or not (lock =0). Default value is 1.
Method Update(pID, ByRef pArg, lock = 1)
{
    Do ..Delete(pID, .pArg,lock)
    Do ..Insert(pID, .pArg,lock)
}

/// Find the top k nearest neighbor of point and store the results as a local array in i%TopK. Each node in i%TopK is a list that contains the ID of the neighbor point and the distance between the neighbor point and q, subscripted by the ranking: i%TopK(ranking)=$lb(ID, distance)
/// Parameter: 
///     efSearch: The size of the candidate vectors when finding nearest neighbors for point
Method TopK(point, k, efSearch = "")
{
    If (i%Distance="COSINE") {
        // Cosine distance is not defined when point is an all-zero vector, return 0 in this case
        Try { Return:$$$isAllZeroVector(point) 0} 
        catch ex1 {
            If ex1.Name = "<FUNCTION>"{
                // $$$isAllZeroVector doesn't work for xf32 vectors
                Try {Set temp = $VECTOROP("COSINE-SIMILARITY",point,point)} 
                Catch ex2 {Return:ex2.Name="<DIVIDE>" 0}
            }
        }
    } 

    Set:(efSearch="") efSearch = i%efConstruction
    Set:(efSearch="")||(efSearch<k) efSearch=k
TopKSearch
    $$$HNSWCheckVersion
    Set $lg(L,ep) = $g($$$HNSWTopLayerAndEntryPoint) 
    Return:L="" 0 // if top layer is not defined, return 0 as the graph is empty

    Set results=""
    For lc=L:-1:1 {
        Do ..HNSWsearchLayer(.results, point,ep,1, lc,,.rerun)
        Goto:rerun=1 TopKSearch // redo the top K search from the top layer if rerun=1
        Set ep = $lg(results(1),1) // nearest element from W to q 
    }
    Do ..HNSWsearchLayer(.results, point,ep,efSearch,0,,.rerun)
    Goto:rerun=1 TopKSearch // redo the top K search from the top layer if rerun=1

    // only return at most k nearest neighbors
    Kill i%TopK
    For i=1:1:k {
        Quit:i>results
        Set i%TopK(i)=results(i)
    }
    Set i%TopK=$s(k>results:results,1:k)
}

/// Returns by reference the next nearest neighbor to i%Point and the distance between this neighbor to i%Point
Method getNext(ByRef distance, ByRef id) As %Boolean
{
    If '$data(i%TopK) {Do ..TopK(i%Point, i%K, i%efSearch)}
    Return:'$data(i%TopK) 0 ; return 0 is TopK is empty, likely due to empty table/index
    Set i%OffSet = i%OffSet+1
    If i%OffSet>i%K {
        Set i%K = i%K+i%K // exponential growth 
        Do ..TopK(i%Point,i%K,i%efSearch)
    } 
    Return:i%OffSet>i%TopK 0 // we have returned all the vectors in this index, or we have returned all the vectors that can be reached in this search. It is a known issue of HNSW algorithm that it returns less that the world size when K equals or greater than the world size (see https://github.com/nmslib/hnswlib/issues/352). When this happens, return 0 as we have reached the end of HNSW search result.
    Set $listget(id, distance) = i%TopK(i%OffSet)
    if (i%Distance="COSINE")||(i%Distance="DOTPRODUCT") {Set distance=-distance}
    Return 1
}

/// for internal use only
Method validateGraph(pID, lock = 1, print = 1) As %List
{
#define BITCHUNKSIZE 64000
#define bit(%bitarray,%pos) $bit(%bitarray((%pos\$$$BITCHUNKSIZE)+1),(%pos#$$$BITCHUNKSIZE+1))
    $$$Lock(@(i%GraphLocation),"", "logging")
    try { 
        set errs = ""

        // check if graph version is defined 
        If '$data($$$HNSWVersion) {
            Set errs = errs_$lb("HNSW graph version not defined")
        }
        Set $lg(L,ep) = $g($$$HNSWTopLayerAndEntryPoint) 

        for l=L:-1:0 {
            k exists,reached
            Set pid = "", maxpid = 0
            For {
                Set pid = $o($$$HNSWNode(l,pid))
                Quit:pid="" 
                
                // check if the number of neighbours is correct for this point
                set numNbr=0, nbrpt = ""

                For {
                    Set nbrpt = $o($$$HNSWEdge(l,pid,nbrpt))
                    Quit:nbrpt=""

                    Set $$$bit(exists,pid)=1
                    Set $$$bit(exists,nbrpt)=1
                    Set $$$bit(reached,nbrpt)=1

                    set maxpid = $s(pid>maxpid:pid, 1:maxpid)
                    set maxpid = $s(nbrpt>maxpid:nbrpt, 1:maxpid)

                    Set numNbr=numNbr+1
                }
                set MMax = $SELECT(l:i%M,1:2*i%M)
                If numNbr = 0 {
                    Set prevPt = $o($$$HNSWNode(l, pid),-1)
                    Set nextPt = $o($$$HNSWNode(l, pid))
                    // add an error if this is not the only point in this layer
                    If (prevPt'="") ||(nextPt'="") {
                        Set errs = errs_$lb("Point "_pid_" has 0 neighbors on layer "_l)
                    }
                } elseif numNbr > MMax {
                    Set errs = errs_$lb("Point "_pid_" has too many neighbors ("_numNbr_") on layer "_l_"; expected number is "_MMax)
                }
                // check if this point exists on all the layers 0, ... ,l-1
                If l > 0 {
                    For i=0:1:(l-1) {
                        If '$data($$$HNSWNode(i,pid)) {
                            Set errs = errs_$lb("Point "_pid_" exists on layer "_l_" but not on layer "_i)
                        }
                    }
                }

            }
            
            for pid = 1:1:maxpid{
                set ex = $$$bit(exists,pid)
                set re = $$$bit(reached,pid)

                if ('ex) && re {
                    Set errs = errs_$lb(pid_" can be reached in layer "_l_" but doesn't exist")

                } elseif ('re)&&ex {
                    Set errs = errs_$lb(pid_" exists in layer "_l_" but cannot be reached")
                } 
            }

        }

        $$$Unlock(@(i%GraphLocation),"I")

        Return errs

    } catch ex{
        $$$Unlock(@(i%GraphLocation),"I")
        throw ex
    
    }
}

}
