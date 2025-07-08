/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%syCluster, %sySystem, %syJrninc, %syINET)

/// Cluster-specific Information
Class %SYS.ClusterInfo Extends %RegisteredObject [ System = 4 ]
{

/// Is the system part of a cluster or not
ClassMethod IsMember() As %Boolean [ CodeMode = expression ]
{
$$$IsCluSys
}

/// True when this system is the cluster master
ClassMethod IsMaster() As %Boolean
{
	/// Use && not & so that we don't evaluate the 2nd term when the
	/// 1st term indicates this is not a cluster build
	q (($$$SYSUSECLUSTER) && ($$$EnqIsMaster))
}

/// Return node name of the current master in the cluster.<br>
/// Returned null string if this system is not a cluster member.
ClassMethod MasterNodeName() As %String
{
 Q:'..IsMember() ""
 Q:..IsMaster() $zu(63,4,0)
 S maddr=$P($ZU(59),",",11)
 S mnode=$$$IPTextToHostName(maddr)
 Quit $s(mnode'="":mnode,1:maddr)
}

ClassMethod NodeStatus() As %String [ Internal ]
{
	If $zu(40,2,95)=0 Quit "This system is not part of a cluster"
	If +$zu(59)=0 Quit "This system is able to join a cluster"
	Quit "This system is part of a cluster"
}

/// Swap the Hostname and IP fields in a CluNodeInfoD-delimited node info string
/// <em>if</em> Hostname does NOT contain commas, the delimiter we will use.
/// On exit, also convert the delimiter from CluNodeInfoD to comma.
ClassMethod NodeInfoConvert(NodeInfo As %String) As %String [ Internal ]
{
	s Hostname=$p(NodeInfo,$$$CluNodeInfoD,$$$CluNodeHostfn)
	#; We cannot do the swap if Hostname contains a comma (unlikely), as
	#; that conflicts the delimiter we are going to use for these fields.
	i '$f(Hostname,",") {
		#; If Hostname does NOT contain commas, swap Hostname and IP fields 
		#; so that caller will use Hostname instead of IP without any change.
		s IP=$p(NodeInfo,$$$CluNodeInfoD,$$$CluNodeIPfn)
		s $p(NodeInfo,$$$CluNodeInfoD,$$$CluNodeIPfn)=Hostname
		s $p(NodeInfo,$$$CluNodeInfoD,$$$CluNodeHostfn)=IP
	}
	#; Convert delimiter from CluNodeInfoD to comma for backward compatibility
	q $$$CluNodeInfoDCvt(NodeInfo)
}

/// Return by reference the info piece about the cluster node of the given CSN,
/// converted to a comma-delimited string (for backward compatibility) <br>
/// Return code: <ul><li>
/// 0 if there no cluster node of CSN (that is alive at the moment) - NodeInfo is undefined; </li><li>
/// 1 if the cluster node of CSN is the first piece (meaning it is the local node); </li><li> 
/// n>1 if the cluster node of CSN is the n-th piece (n has no particular meaning).</li></ul>
ClassMethod FindNode(CSN As %Integer, ByRef NodeInfo As %String) As %Integer [ Internal ]
{
	s nodes=$$$CluNodesInfo
	s NumberOfNodes=$$$CluNodesNumber(nodes)
	f i=1:1:NumberOfNodes s NodeI=$$$CluNodeInfo(nodes,i) i $p(NodeI,$$$CluNodeInfoD,$$$CluNodeCSNfn)=CSN s NodeInfo=..NodeInfoConvert(NodeI),index=i q
	q +$g(index)
}

/// Return by reference an array of info pieces about all cluster nodes (that are currently alive) <br>
/// The array NodeInfo is indexed by csn, with the value of each element being 
/// a comma-delimited string containing the info about the node of csn.<br>
/// The value of the top node NodeInfo is the csn of the local node <br>
/// Return code: the number of nodes in the cluster (that are alive at the moment)
ClassMethod GetNodes(ByRef NodeInfo As %String, NoConvert As %Boolean = 0, SkipSelf As %Boolean = 0) As %Integer [ Internal ]
{
	s nodes=$$$CluNodesInfo
	s NumberOfNodes=$$$CluNodesNumber(nodes)
	#; If SkipSelf is 1, start from the 2nd piece, as the 1st piece is always
	#; the info about the local node ("self"); otherwise, start from the 1st.
	f i=(1+''SkipSelf):1:NumberOfNodes d
	. s NodeI=$$$CluNodeInfo(nodes,i)
	. s csn=$p(NodeI,$$$CluNodeInfoD,$$$CluNodeCSNfn)
	. i NoConvert s NodeInfo(csn)=NodeI
	. e  s NodeInfo(csn)=..NodeInfoConvert(NodeI) 
	. i i=1 s NodeInfo=csn
	q NumberOfNodes
}

/// Returns information about member nodes of the cluster using DNS resolution of the members' hostnames.
/// If SkipSelf = 1, skip the node where the query is run
Query NodeList(SkipSelf As %Boolean = 0) As %Query(ROWSPEC = "CSN:%Integer,IP:%String,Port:%Integer,MGR Dir:%String,Journal Offset:%Integer,Journal File:%String,Journal File Count:%Integer,Transaction Offset:%Integer,Transaction File:%String,Transaction File Count:%Integer,Host Name:%String,Prev Journal Offset:%Integer,Prev Journal File Count:%Integer,Prev Journal File:%String,Journal WDPass:%Integer")
{
}

ClassMethod NodeListExecute(ByRef qHandle As %Binary, SkipSelf As %Boolean = 0) As %Status
{
	i '..IsMember() q $$$ERROR($$$SystemNotPartOfCluster) ;not part of a Cache cluster
	d ..GetNodes(.qHandle,1,SkipSelf)
	s qHandle=""
	q $$$OK
}

ClassMethod NodeListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	s qHandle=$o(qHandle(qHandle),1,NodeInfo) 
	i qHandle="" s Row="",AtEnd=1 q $$$OK
	s $li(Row,1)=$p(NodeInfo,$$$CluNodeInfoD,3),csn=$li(Row,1) ;CSN
	s $li(Row,2)=$p(NodeInfo,$$$CluNodeInfoD,2) ;IP
	s $li(Row,3)=$p(NodeInfo,$$$CluNodeInfoD,1) ;port
	s $li(Row,11)=$p(NodeInfo,$$$CluNodeInfoD,4) ;host name
	s wijinfo=$$$JRNLOOKUP(csn)
#;JO2192+
	s $li(Row,4)=$p(wijinfo,",",$$$JLMGRDIR) ;MGR Dir
	s $li(Row,5)=$p(wijinfo,",",$$$JLJRNOFF) ;journal file offset
	s $li(Row,6)=$p(wijinfo,",",$$$JLJRNFILENAME),jfile=$li(Row,6) ;journal file path
	s $li(Row,7)=$p(wijinfo,",",$$$JLJRNFILECNT),jfcnt=$li(Row,7) ;journal file count
	s $li(Row,8)=$p(wijinfo,",",$$$JLTRANSINDEX) ;journal file offset of the earliest possible open transaction
	s $li(Row,10)=$p(wijinfo,",",$$$JLTRANSFILECNT),xfcnt=$li(Row,10) ;journal file count of the earliest possible open transaction
    s $li(Row,12)=$p(wijinfo,",",$$$JLPREVJRNOFF)  ;previous chkpnt journal file offset
    s $li(Row,13)=$p(wijinfo,",",$$$JLPREVJRNFILECNT),prevjfcnt=$li(Row,13)  ;previous chkpnt journal file count
    s $li(Row,15)=$P(wijinfo,",",$$$JLJRNWDPASS) ;wdpass value of prev chkpnt journal info
	while (prevjfcnt<jfcnt) {
	   s prev=$$$JRNFPREV(jfile) 
	   q:prev=""  
	   q:$$$JRNCHECK(prev)<1  
	   s jfile=prev
	   s jfcnt=jfcnt-1
	}
	s $li(Row,14)=jfile  ; journal file for $$$JLPREVJRNFILECNT
#;JO2192-
	i xfcnt<jfcnt d  i 1
	. f  s prev=$$$JRNFPREV(jfile) q:prev=""  q:$$$JRNCHECK(prev)<1  s jfile=prev,jfcnt=jfcnt-1 q:jfcnt=xfcnt
	#; If we couldn't reach the file corresponding to xfcnt through back 
	#; pointer (prev="" or prev is not a valid journal file), just set xfile
	#; to the last valid journal file reachable through back pointer. This
	#; scenerio should never happen as it indicates there is a gap in the
	#; journal, most likely caused by the disabling of journaling, which
	#; should have cleared the old transaction info in the wij. Journal
	#; purging should have been careful enough to preserve files containing
	#; open transactions.
	#; If xfcnt>jfcnt, which should never happen either, set xfile to jfile too.
	s xfile=jfile
	s $li(Row,9)=xfile ;journal file path of the earliest possible open transaction
	q $$$OK
}

ClassMethod NodeListClose(ByRef qHandle As %Binary) As %Status
{
	Quit $$$OK
}

Storage Default
{
<Data name="ClusterInfoDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%SYS.ClusterInfoD</DataLocation>
<DefaultData>ClusterInfoDefaultData</DefaultData>
<IdLocation>^%SYS.ClusterInfoD</IdLocation>
<IndexLocation>^%SYS.ClusterInfoI</IndexLocation>
<StreamLocation>^%SYS.ClusterInfoS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
