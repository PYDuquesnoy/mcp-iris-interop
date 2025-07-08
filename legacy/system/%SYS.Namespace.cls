/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

Class %SYS.Namespace Extends %Persistent [ Abstract, System = 4 ]
{

/// Returns True if a namespace is enabled, that is, if its default directory is 
/// reachable.<br>
/// This method will implicitly mount a database which has not yet been accessed 
/// by the system. If the database has been explicitly dismounted, or is not mountable, 
/// then the method will return false.
ClassMethod Enabled(NamespaceName As %String) As %Boolean [ Internal ]
{
	Try {
		s Namespace=$zcvt(NamespaceName,"U")
		s Sys=$$defsys^%SYS.GLO(Namespace)
		s Dir=$$defdir^%SYS.GLO(Namespace)
		i $d(^|"^"_Sys_"^"_Dir|X)
		s Status=1
	} Catch {
		s Status=0
	}
	q Status
}

ClassMethod Exists(NamespaceName As %String) As %Boolean [ CodeMode = expression ]
{
$zu(90,10,NamespaceName)
}

/// Return information about a namespaces default global database.<br>
/// Parameters:<br>
/// Namespace - Namespace to obtain information about. Can be either a real namespace
///             or an implied namespace. Real namespace must be in uppercase.<br>
/// DontConnect - If the namespace's default database is a remote database mounted across ECP,
/// then if set to 1, and the remote database is not mounted, we will not try to mount it (default = 0).<br><br>
/// 
/// Return Values:<br>
/// Returns an array of information about the default global database.<br>
/// Info("System") - name of system default global directory resides on.<br>
/// Info("Directory") - Name of default global directory.<br>
/// Info("Resource") - Name of resource attached to the directory.<br>
/// Info("ReadOnly") - 0/1 is the database mounted read only.<br>
/// Info("Mounted") - 0/1 is the database mounted.<br>
/// Info("Status") - 1 = Success, %Status if any kind of error.<br><br>
/// This also returns a second level of subscript with the same values, but
/// subscripted by "GlobalDB" and "RoutineDB". This allows us to return info about
/// the default Routine database for the namespace e.g.<br>
/// Info("GlobalDB","System") <br>
/// Info("RoutineDB","System") <br>
/// If an implied namespace is passed in, ^SERVER^DIR, and the SERVER is the local
/// system, then the database is treated as a local database, and Info("System") will
/// be returned as "".
/// 	
ClassMethod GetNSInfo(Namespace As %String, ByRef Info As %String, DontConnect As %Boolean = 0)
{
 i (Namespace'["/")&&(Namespace'["\")&&(Namespace'["]")&&(Namespace'[":") s Namespace=$zcvt(Namespace,"U")
 d GetNSInfo^%SYS.NAMESPACE(Namespace,.Info,DontConnect)
 q
}

/// Return information about a namespaces default global and routine database
/// On Input:
/// Namespace - Namespace to obtain information about. Can be either a real namespace
///             or an implied namespace
/// DontConnect - If the namespace's default database is a remote database mounted across ECP,
/// then if set to 1, and the remote database is not mounted, we will not try to mount it (default = 0).<br><br>
/// 
/// Returns an array of information about the default global and routine databases.
/// Info("GlobalDB","System") - name of system default global directory resides on.
/// Info("GlobalDB","Directory") - Name of default global directory.
/// Info("GlobalDB","Resource") - Name of resource attached to the directory.
/// Info("GlobalDB","ReadOnly") - 0/1 is the database mounted read only.
/// Info("GlobalDB","Mounted") - 0/1 is the database mounted.
/// Info("GlobalDB","Status") - 1 = Success, %Status if any kind of error.
/// Info("RoutineDB","System") - name of system default routine directory resides on.
/// Info("RoutineDB","Directory") - Name of default routine directory.
/// Info("RoutineDB","Resource") - Name of resource attached to the directory.
/// Info("RoutineDB","ReadOnly") - 0/1 is the database mounted read only.
/// Info("RoutineDB","Mounted") - 0/1 is the database mounted.
/// Info("RoutineDB","Status") - 1 = Success, %Status if any kind of error.
ClassMethod GetAllNSInfo(Namespace As %String, ByRef Info As %String, DontConnect As %Boolean = 0)
{
 i (Namespace'["/")&&(Namespace'["\")&&(Namespace'["]") s Namespace=$zcvt(Namespace,"U")
 d GetAllNSInfo^%SYS.NAMESPACE(Namespace,.Info,DontConnect)
 q
}

/// Returns the system^directory where ^[Namespace]Global(Subscript) is mapped to.
/// If Subscript is missing, it returns the location for ^[Namespace]Global.
/// If Global is missing, it returns the default global location for Namespace.<br>
/// This API support multi-level subscripts mapping, for example, pass "abc",1,2 in Subscript will check
/// the destination of Global("abc",1,2).<br>
/// If the system is the same as the local system, then system is set to "".
ClassMethod GetGlobalDest(Namespace As %String = {$namespace}, Global As %String = "^", Subscript As %String = "") As %String
{
	i Namespace="" s Namespace=$namespace
#;SML1068 ; to support multi-level subscript, we should not put quote around the input.
#;SML1197 ; we need to check whether we need to put '"' around the Subscript argument.
	s:Subscript'="" Subscript=$$QuoteSub(Subscript)
	s Dest=$$getdest^%SYS.GXLINF1(Namespace,Global,Subscript)
	i $p(Dest,"^",1)=$zu(63,4,0) s $p(Dest,"^",1)=""
	q Dest
#;SML1197+ ; Put '"' around the subscript if it is not valid for getdest^%SYS.GXLINF1
QuoteSub(sub)
	s $zt="err"
	s vnam="x("_sub_")",ql=$ql(vnam)
	#; No error, don't need to add '"' around it.
	quit sub
err quit """"_sub_""""
#;SML1197-
}

/// Returns the system^directory where Routine is mapped to in this Namespace.
/// If Routine is missing, it returns the default routine location for Namespace.
/// The allowed types are: INC, INT, MAC and OBJ.
/// If the system is the same as the local system, then system is set to "".
ClassMethod GetRoutineDest(Namespace As %String = {$namespace}, Routine As %String = "", Type As %String = "INT") As %String
{
#;RJF244+
	#; We convert ^ to @ if this is an implied namespace to be compatible with
	#; GetGlobalDest() and the pre-RJF244 behavior of GetRoutineDest().  If the
	#; implied namespace hasn't been set up by ZN yet, these methods will
	#; return null (this isn't the best definition but it's been this way and
	#; we don't really want to set up the namespace here).
	i Namespace="" {
		s nsp=$namespace
	} else {
		s nsp=Namespace
	}
	i $e(nsp)="^" { s nsp=$tr(nsp,"^","@") }
	Set Global=$s(Type="MAC":"rMAC",Type="OBJ":"rOBJ",Type="INC":"rINC",1:"ROUTINE")
	#; return null for namespace that doesn't exist
	return:'$zu(90,10,nsp) ""
	return:Routine="" $piece($zu(90,22,nsp,Global),"^",2,3)
	return $piece($zu(90,22,nsp,Global,Routine),"^",2,3)
#;RJF244-
}

/// Returns the system^directory where Package is mapped to in this Namespace.
/// If Package is missing, it returns the default package location for Namespace.
/// If the system is the same as the local system, then system is set to "".
ClassMethod GetPackageDest(Namespace As %String = "", Package As %String = "") As %String
{
	i Package'=""&&($e(Package,*)'=".") s Package=Package_"."
	quit ..GetRoutineDest(Namespace,Package)
}

/// The <b>ListAll</b> method quickly returns a list of all the
/// namespaces in the current process.
/// The parameter <b>array</b> is a local array
/// name passed by reference.  On return from <b>ListAll</b>, the subscripts
/// of the <b>array</b> parameter will be the namespace names of
/// the current process.  Each subscripted entry in <b>array</b>
/// will contain the empty string.
/// When <b>ConvertImplicit</b> is true, it will convert the '@' in implicit namespace to '^'.
/// The default value of <b>ConvertImplicit</b> is true when it is not specified.
/// <p>
/// Each explicit namespace is returned using the local namespace name as
/// the subscript string.
/// Each implicit namespace is returned using a subscript string that contains a
/// caret ^, followed by the system name, followed by another caret ^,
/// followed by the name of directory containing the database file.  If
/// the implicit namespace is local then the system name is the empty string
/// and the subscript string starts with two adjacent carets ^^.
/// 
ClassMethod ListAll(Output array, ConvertImplicit As %Boolean = 1) As %Status
{
	Kill array
	#;SML1565+
	s nsversion=$zu(90,20,1)
	s nsplist=$zu(90,28,0,0,nsversion)
	s lastp=$p(nsplist,",",$l(nsplist,","))
	s startidx=$s(nsplist]"":$s(lastp?1N.N:+lastp,1:0),1:0)
	while (nsplist=-1 || startidx) {
		if nsplist=-1 {
			#; The nsversion must be changed need to re-scan the namespace table.
			s startidx=0,nsversion=$zu(90,20,1)
			k array
		} else {
			#; Setup the array from the retrieved list.
			f i=1:1:$l(nsplist,",") s array($p(nsplist,",",i))=""
		}
		s nsplist=$zu(90,28,0,startidx,nsversion)
		s lastp=$p(nsplist,",",$l(nsplist,","))
		s startidx=$s(nsplist]"":$s(lastp?1N.N:+lastp,1:0),1:0)
	}
	#; Setup the array from the retrieved list.
	i nsplist]"" f i=1:1:$l(nsplist,",") s array($p(nsplist,",",i))=""
	Quit:'ConvertImplicit $$$OK
	#; Convert @ in implicit namespaces to ^
	Set I="@"
	For {
	  Set I=$Order(array(I))
	  Quit:$E(I)'="@"
	  Kill array(I)
	  Set R=$P(I,"@",2)
	  Set array("^"_R_"^"_$E(I,$L(R)+3,*))=""
	}
	Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = ListExecute ]
{
	Set Index=$p(qHandle,"^",1)
	Kill $$$ISCQUERYTEMP(Index)
	Quit $$$OK
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Remote As %Boolean = 0, DontConnect As %Boolean = 0) As %Status [ Internal ]
{
	Set Index=$i($$$ISCQUERYTEMP)
	;
	Do List^%SYS.NAMESPACE(.NspLst,4, Remote,DontConnect)
	Set ns=""
	For {
		Set ns=$o(NspLst(ns)) If ns="" Set qHandle=Index_"^" Quit
		Set $$$ISCQUERYTEMP(Index,ns)=$ListBuild(ns)_NspLst(ns)
	}
	Quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = ListExecute ]
{
 	$$$DEFAULTFETCHPPG
	Quit $$$OK
}

/// Returns a list of namespaces defined on the system.<br>
/// Parameters:<br>
/// Remote - 0/1 whether to return any remotely mapped namespaces or not.<br>
/// DontConnect - 0/1 whether to connect to remote system or not if a connection
/// has not been made yet.<br>
/// Return values:<br>
/// Status - (0/1) Whether the namespace is available or not.<br>
/// If the Status returned is 1, the default global database for the namespace is 
/// either mounted, or not mounted yet. If 0, then the database has been dismounted.<br>
/// Remote -  (0/1) Whether the namespace is mapped to a remote ECP system.<br>
Query List(Remote As %Boolean, DontConnect As %Boolean) As %Query(ROWSPEC = "Nsp:%String,Status:%String,Remote:%Boolean") [ SqlProc ]
{
}

Storage Default
{
<Data name="NamespaceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^SYS.NamespaceD</DataLocation>
<DefaultData>NamespaceDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^SYS.NamespaceD</IdLocation>
<IndexLocation>^SYS.NamespaceI</IndexLocation>
<StreamLocation>^SYS.NamespaceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
