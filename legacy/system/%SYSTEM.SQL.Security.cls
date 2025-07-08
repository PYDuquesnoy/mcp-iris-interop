/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.SQL.Security Extends %SYSTEM.Help [ Abstract, Not ProcedureBlock, System = 4 ]
{

/// Check if user has SQL privilege for a particular action. This does not check grant privileges.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Username</i>
/// <dd>Name of the user to check.  Required.
/// <dt><i>ObjectType</i>
/// <dd>Required. Specifies the type to check the privilege of. ObjectTypes are 1 (table), 3 (view), 5 (schema), 6 (ml configuration), 7 (foreign server), 9 (procedure). 
/// <dt><i>Object</i>
/// <dd>Required. The name the object to check the privilege of.  
/// <dd>For example, ObjectType and Object could be "1" and "Sample.Person", or "9" and "SQLUser.My_Procedure".  
/// <dt><i>Action</i>
/// <dd>Comma delimited string of actions letters to check privileges for.  Actions are one or more of the 
/// letters "a,s,i,u,d,r,e,l" (in any order) which stands for ALTER,SELECT,INSERT,UPDATE,DELETE,REFERENCES,EXECUTE,USE (USE for ML Configurations/Foreign Server).  
/// Privilege "e" is only allowed for Procedures.  Privilege "l" is only allowed for ML Configurations and Foreign Servers. CheckPrivilege will only return 1 if the user has privileges on all Actions specified.  Required.
/// <dt><i>Namespace</i>
/// <dd>Namespace object resides in (optional) default is current namespace
/// </dl>
/// <p><b>Returns</b>:
/// <li>1 - if the Username does have the privilege</li> 
/// <li>0 - if the Username does not have the privilege</li>
/// <li>%Status - if CheckPrivilege call is reporting an error</li>
/// <p><b>Notes:</b>
/// <li>If Username is a user with the %All role, CheckPrivilege will return 1 even if the Object does not exist.
/// <li>If the user calling CheckPrivilege is not the same as Username, the calling user must hold the %Admin_Secure:"U" privilege.
/// <p><b>Example</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Security.CheckPrivilege("Miranda",3,"SQLUser.Person","s","PRODUCT")</li>
/// </ul>
ClassMethod CheckPrivilege(Username As %String, ObjectType As %Integer, Object As %String, Action As %String, Namespace As %String = "") As %Boolean
{
	if $$$LOWER(Username)'=$$$LOWER($username) {
			#; If not checking for yourself, make sure user has permission to check (%Admin Secure:"U")
		If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
			RETURN $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
		}
	}
	set:$g(Namespace)="" Namespace=$namespace
	set Action=$$$LOWER(Action)
	set Namespace=$$$UPPER(Namespace)
	if $tr(Action,"asiudrel,","")'="" RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue,"$SYSTEM.SQL.Security.CheckPrivilege","Action","a,s,i,u,d,r,e,l")
	if $case(ObjectType,1:0,3:0,5:0,6:0,7:0,9:0,:1) RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue2,"$SYSTEM.SQL.Security.CheckPrivilege","ObjectType","1,3,6,7,9")
	if ObjectType=9,Action'="e" RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue3,"$SYSTEM.SQL.Security.CheckPrivilege","Action","e")
	if $e(ObjectType)=6||($e(ObjectType)=7),Action'="l" RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue3,"$SYSTEM.SQL.CheckPriv","Action","l")
	if $e(ObjectType)<4&&(Action="e"||(Action="l")) RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue4,"$SYSTEM.SQL.CheckPriv","Object")
	if '##class(%SYS.Namespace).Exists(Namespace) RETURN $$$ERROR($$$NamespaceDoesNotExist,Namespace)
	RETURN $$CheckPriv^%SYS.SQLSEC(Username,ObjectType_","_Object,Action,Namespace,0)
}

/// Check if user has SQL grant privilege for a particular action.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>Username</i>
/// <dd>Name of the user to check.  Required.
/// <dt><i>ObjectType</i>
/// <dd>Required. Specifies the type to check the grant privilege of. ObjectTypes are 1 (table), 3 (view), 5 (schema), 6 (ml configuration), 7 (foreign server), 9 (procedure). 
/// <dt><i>Object</i>
/// <dd>Required. The name the object to check the grant privilege of.  
/// <dd>For example, ObjectType and Object could be "1" and "Sample.Person", or "9" and "SQLUser.My_Procedure". 
/// <dt><i>Action</i>
/// <dd>Comma delimited string of actions letters to check grant privileges for.  Actions are one or more of the 
/// letters "a,s,i,u,d,r,e,l" (in any order) which stands for ALTER,SELECT,INSERT,UPDATE,DELETE,REFERENCES,EXECUTE,USE (USE for ML Configurations/ForeignServers).  
/// Privilege "e" is only allowed for Procedures.  Privilege "l" is only allowed for ML Configurations and Foreign Servers. CheckPrivilegeWithGrant will only return 1 if the user has grant privileges on all Actions specified.  Required.
/// <dt><i>Namespace</i>
/// <dd>Namespace object resides in (optional) default is current namespace
/// </dl>
/// <p><b>Returns</b>:
/// <li>1 - if the Username does have the privilege</li>
/// <li>0 - if the Username does not have the privilege</li>
/// <li>%Status - if CheckPrivilegeWithGrant call is reporting an error</li>
/// <p><b>Notes:</b>
/// <li>If Username is a user with the %All role, CheckPrivilegeWithGrant will return 1 even if the Object does not exist.
/// <li>If the user calling CheckPrivilegeWithGrant is not the same as Username, the calling user must hold the %Admin_Secure:"U" privilege.
/// <p><b>Example</b>:
/// <ul>
/// <li>Do $SYSTEM.SQL.Security.CheckPrivilegeWithGrant($username,1,"HHR.ProductionValues","s,i,u,d","USER")</li>
/// </ul>
ClassMethod CheckPrivilegeWithGrant(Username As %String, ObjectType As %Integer, Object As %String, Action As %String, Namespace As %String = "") As %Boolean
{
	if $$$LOWER(Username)'=$$$LOWER($username) {
			#; If not checking for yourself, make sure user has permission to check (%Admin Secure:"U")
		If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
			RETURN $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
		}
	}
	set:$g(Namespace)="" Namespace=$namespace
	set Action=$$$LOWER(Action)
	set Namespace=$$$UPPER(Namespace)
	if $tr(Action,"asiudrel,","")'="" RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue,"$SYSTEM.SQL.Security.CheckPrivilege","Action","a,s,i,u,d,r,e,l")
	if $case(ObjectType,1:0,3:0,5:0,6:0,7:0,9:0,:1) RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue2,"$SYSTEM.SQL.Security.CheckPrivilege","ObjectType","1,3,6,7,9")
	if ObjectType=9,Action'="e" RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue3,"$SYSTEM.SQL.Security.CheckPrivilege","Action","e")
	if $e(ObjectType)=6||($e(ObjectType)=7),Action'="l" RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue3,"$SYSTEM.SQL.CheckPriv","Action","l")
	if $e(ObjectType)<4&&(Action="e"||(Action="l")) RETURN $$$ERROR($$$SystemSQLInvalidArgumentValue4,"$SYSTEM.SQL.CheckPriv","Object")
	if '##class(%SYS.Namespace).Exists(Namespace) RETURN $$$ERROR($$$NamespaceDoesNotExist,Namespace)
	RETURN $$CheckPriv^%SYS.SQLSEC(Username,ObjectType_","_Object,Action,Namespace,1)
}

/// GrantPrivilege lets you grant an <i>ObjPriv</i> to a <i>User</i> via this call instead of using the SQL GRANT statement. 
/// This does not include grant privileges.
/// <p>
/// $SYSTEM.SQL.Security.GrantPrivilege(<i>ObjPriv</i>,<i>ObjList</i>,<i>Type</i>,<i>User</i>)<br>
/// <dl>
///   Parameters:
/// <p>
/// <dt><i>ObjPriv</i>     	
/// <dd>Comma delimited string of actions to grant. * for all actions:<br>
/// <ul>
/// <li>Alter</li>
/// <li>Select</li>
/// <li>Insert</li>
/// <li>Update</li>
/// <li>Delete</li>
/// <li>References</li>
/// <li>Execute</li>
/// <li>Use</li>
/// <li>or any combination</li>
/// </ul>
/// <dt><i>ObjList</i>
/// <dd> * for all objects, else a comma delimited list of SQL object names (tables, views, procedures, schemas). The specified schemas cannot be empty. <br>
/// <dt><i>Type</i>
/// <dd> Table, View, Schema, Stored Procedure(s), ML Configuration, or Foreign Server<br>
/// <dt><i>User</i>
/// <dd> Comma delimited list of users<br>
ClassMethod GrantPrivilege(ObjPriv As %String, ObjList As %String, Type As %String, User As %String) As %Status [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	Try {
		TSTART
		set Type=$$$UPPER(Type)
		//	MJG295 - accept both STORED PROCEDURE and STORED PROCEDURES
		set Type=$case(Type,"TABLE":1,"VIEW":3,"CUBES":4,"SCHEMA":5,"ML CONFIGURATION":6,"FOREIGN SERVER":7,"STORED PROCEDURES":9,"STORED PROCEDURE":9,:"")
		if Type="" { THROW ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Object Type of TABLE, VIEW, CUBES, SCHEMA, ML CONFIGURATION, FOREIGN SERVER, or STORED PROCEDURE expected" ) }
		
		s ObjPriv=$$$UPPER(ObjPriv)
		s Objs=""
		for i=1:1:$L(ObjPriv,",") {
			s Obj=$P(ObjPriv,",",i) 
			s Obj=$S(Obj="*":"*",Obj="ALTER":"a",Obj="SELECT":"s",Obj="INSERT":"i",Obj="UPDATE":"u",Obj="DELETE":"d",Obj="REFERENCES":"r",Obj="EXECUTE":"e",Obj="USE":"l",1:"")
			if Obj="" s Objs="" quit
			s Objs=Objs_Obj
		}
		i Objs="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-60,$$$GetSysMessage("en","%SqlCode","SqlCode60","GrantObjPriv Error"))		// invalid action found
		
		s ObjList=$$$UPPER(ObjList)
		if ObjList'="*" {
			s ObjList=$LISTFROMSTRING(ObjList,",")
			s VObjList=""
			f i=1:1:$LL(ObjList) {
				s Obj=$LG(ObjList,i)
				s schema=$P(Obj,".",1)
				s object=$P(Obj,".",2)
				if Type=1||(Type=3) {
					If (schema'=""),(object'=""),($D(^rINDEXSQL("rv",schema,object))) { s VObjList=VObjList_$LB($LG(^rINDEXSQL("rv",schema,object),4)) }
					ELSE  { s VObjList="" quit }
				}
				ELSEIF Type=4 {
					
				}
				ELSEIF Type=5 {
						// If at least one object is defined in the schema grant the privilege.
						// schema is upper case here, and we store "5,<schame>" in the priv global in uppercase
					if (schema'=""),($d(^rINDEXSQL("rv",schema))) { set VObjList=VObjList_$lb(schema) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-473,$$$FormatText($$$Text("Schema %1 not found","%SQL.Function"),schema))		// invalid schema found
					}
				}
				ELSEIF Type=6 {
					if Obj'="",$d(^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(Obj))) { set VObjList=VObjList_$LB(Obj) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-187,$$$FormatText($$$Text("ML Configuration %1 not found","%SQL.Function"),Obj))		// invalid ML Configuration found
					}
				}
				ELSEIF Type=7 {
					set badServerName = 0
					if Obj'="" {
						set sc = $$updateForeignServerIndex^%SYS.SQLSEC
						if $$$ISERR(sc) {
							THROW ##class(%Exception.SQL).CreateFromSQLCODE(-400,$$$FormatText($$$Text("Failed to update foreign server index","%SQL.Function")))		// invalid ML Configuration found
						}
						if $d(^rINDEXSQL("SERVER", $$$UPPER(schema), $$$UPPER(object)), serverData) {
							set VObjList=VObjList_$LB($lg(serverData, 4) _ "." _ $lg(serverData, 5))
						} else {
							set badServerName = 1
						}
					} else {
						set badServerName = 1
					}

					if badServerName {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-30,$$$FormatText($$$Text("Foreign server %1 not found","%SQL.Function"),Obj))		// invalid foreign server
					}
				}
				ELSEIF Type=9 {
					If (schema'=""),(object'=""),($D(^oddPROC(schema,object))) { s VObjList=VObjList_$LB(schema_"."_object) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-428,$$$FormatText($$$Text("Stored Procedure %1.%2 not found","%SQL.Function"),schema,object))		// invalid procedure found
					}
				}
			}
			s ObjList=VObjList
		}
		i ObjList="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-30,$$$GetSysMessage("en","%SqlCode","SqlCode30","GrantObjPriv Error"))		// invalid object found
		
		if '$$CheckAllUsersExist^%SYS.SQLSEC(User, .badUser) {
			THROW ##class(%Exception.SQL).CreateFromSQLCODE(-118,$$$GetSysMessage("en","%SqlCode","SqlCode118","GrantObjPriv Error"))	
		}
		
		s SQLCODE=100   
		d setup^%SYS.SQLSEC(Objs,Type,ObjList,User,0,1)
		if SQLCODE<0 {
			THROW ##class(%Exception.General).%New("GrantObjPriv Error",SQLCODE,,"SQL Error Code")
		} else { s status = $$$OK }
		TCOMMIT 

	}
	
	Catch err {
		TROLLBACK 1 
		s status=err.AsStatus()
	}
	RETURN status
}

/// GrantPrivilegeWithGrant lets you grant an <i>ObjPriv</i>, WITH GRANT OPTION, to a <i>User</i>
/// <p>
/// $SYSTEM.SQL.Security.GrantPrivilegeWithGrant(<i>ObjPriv</i>,<i>ObjList</i>,<i>Type</i>,<i>User</i>)<br>
/// <dl>
///   Parameters:
/// <p>
/// <dt><i>ObjPriv</i>     	
/// <dd>Comma delimited string of actions to grant. * for all actions:<br>
/// <ul>
/// <li>Alter</li>
/// <li>Select</li>
/// <li>Insert</li>
/// <li>Update</li>
/// <li>Delete</li>
/// <li>References</li>
/// <li>Execute</li>
/// <li>Use</li>
/// <li>or any combination</li>
/// </ul>
/// <dt><i>ObjList</i>
/// <dd> * for all objects, else a comma delimited list of SQL object names (tables, views, procedures, schemas). The specified schemas cannot be empty. <br>
/// <dt><i>Type</i>
/// <dd> Table, View, Schema, Stored Procedure, ML Configuration, or Foreign Server<br>
/// <dt><i>User</i>
/// <dd> Comma delimited list of users<br>
ClassMethod GrantPrivilegeWithGrant(ObjPriv As %String, ObjList As %String, Type As %String, User As %String) As %Status [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	Try {
		TSTART
		set Type=$$$UPPER(Type)
		set Type=$case(Type,"TABLE":1,"VIEW":3,"CUBES":4,"SCHEMA":5,"ML CONFIGURATION":6,"FOREIGN SERVER":7,"STORED PROCEDURES":9,"STORED PROCEDURE":9,:"")
		if Type="" { THROW ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Object Type of TABLE, VIEW, CUBES, SCHEMA, ML CONFIGURATION, FOREIGN SERVER, or STORED PROCEDURE expected" ) }
		
		s ObjPriv=$$$UPPER(ObjPriv)
		s Objs=""
		for i=1:1:$L(ObjPriv,",") {
			s Obj=$P(ObjPriv,",",i) 
			s Obj=$S(Obj="*":"*",Obj="ALTER":"a",Obj="SELECT":"s",Obj="INSERT":"i",Obj="UPDATE":"u",Obj="DELETE":"d",Obj="REFERENCES":"r",Obj="EXECUTE":"e",Obj="USE":"l",1:"")
			if Obj="" s Objs="" quit
			s Objs=Objs_Obj
		}
		i Objs="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-60,$$$GetSysMessage("en","%SqlCode","SqlCode60","GrantObjPriv Error"))		// invalid action found
		
		s ObjList=$$$UPPER(ObjList)
		if ObjList'="*" {
			s ObjList=$LISTFROMSTRING(ObjList,",")
			s VObjList=""
			f i=1:1:$LL(ObjList) {
				s Obj=$LG(ObjList,i)
				s schema=$P(Obj,".",1)
				s object=$P(Obj,".",2)
				if Type=1||(Type=3) {
					If (schema'=""),(object'=""),($D(^rINDEXSQL("rv",schema,object))) { s VObjList=VObjList_$LB($LG(^rINDEXSQL("rv",schema,object),4)) }
					ELSE  { s VObjList="" quit }
				}
				ELSEIF Type=4 {
					
				}
				ELSEIF Type=5 {
						// If at least one object is defined in the schema grant the privilege.
						// schema is upper case here, and we store "5,<schame>" in the priv global in uppercase
					if (schema'=""),($d(^rINDEXSQL("rv",schema))) { set VObjList=VObjList_$lb(schema) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-473,$$$FormatText($$$Text("Schema %1 not found","%SQL.Function"),schema))		// invalid schema found
					}
				}
				ELSEIF Type=6 {
					if Obj'="",$d(^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(Obj))) { set VObjList=VObjList_$LB(Obj) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-187,$$$FormatText($$$Text("ML Configuration %1 not found","%SQL.Function"),Obj))		// invalid ML Configuration found
					}
				}
				ELSEIF Type=7 {
					set badServerName = 0
					if Obj'="" {
						set sc = $$updateForeignServerIndex^%SYS.SQLSEC
						if $$$ISERR(sc) {
							THROW ##class(%Exception.SQL).CreateFromSQLCODE(-400,$$$FormatText($$$Text("Failed to update foreign server index","%SQL.Function")))		// invalid foreign server
						}
						if $d(^rINDEXSQL("SERVER", $$$UPPER(schema), $$$UPPER(object)), serverData) {
							set VObjList=VObjList_$LB($lg(serverData, 4) _ "." _ $lg(serverData, 5))
						} else {
							set badServerName = 1
						}
					} else {
						set badServerName = 1
					}

					if badServerName {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-30,$$$FormatText($$$Text("Foreign server %1 not found","%SQL.Function"),Obj))		// invalid foreign server
					}
				}
				ELSEIF Type=9 {
					If (schema'=""),(object'=""),($D(^oddPROC(schema,object))) { s VObjList=VObjList_$LB(schema_"."_object) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-428,$$$FormatText($$$Text("Stored Procedure %1.%2 not found","%SQL.Function"),schema,object))		// invalid procedure found
					}
				}
			}
			s ObjList=VObjList
		}
		i ObjList="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-30,$$$GetSysMessage("en","%SqlCode","SqlCode30","GrantObjPriv Error"))		// invalid object found
		
		if '$$CheckAllUsersExist^%SYS.SQLSEC(User, .badUser) {
			THROW ##class(%Exception.SQL).CreateFromSQLCODE(-118,$$$GetSysMessage("en","%SqlCode","SqlCode118","GrantObjPriv Error"))	
		}
		
		s SQLCODE=100   
		d setup^%SYS.SQLSEC(Objs,Type,ObjList,User,1,1)
		if SQLCODE<0 { 
			THROW ##class(%Exception.General).%New("GrantObjPriv Error",SQLCODE,,"SQL Error Code")
		} else { s status = $$$OK }
		TCOMMIT 

	}
	
	Catch err {
		 TROLLBACK 1 
		s status=err.AsStatus()
	}
	RETURN status
}

/// Wrapper around GrantPrivilege() and GrantPrivilegeWithGrant() to support
/// declarative syntax in CPF Actions
ClassMethod GrantOne(ByRef Properties As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s $zt="Error"

 s ObjPriv=$g(Properties("ObjPriv"))
 s ObjList=$g(Properties("ObjList"))
 s Type=$g(Properties("Type"))
 s User=$g(Properties("User"))
 s Namespace=$g(Properties("Namespace"))
 s WithGrant=$g(Properties("WithGrant"))
 
 q:ObjPriv="" $$$ERROR($$$MGActionMissingProperty, "GrantPrivilege", "ObjPriv")
 q:ObjList="" $$$ERROR($$$MGActionMissingProperty, "GrantPrivilege", "ObjList")
 q:Type="" $$$ERROR($$$MGActionMissingProperty, "GrantPrivilege", "Type")
 q:User="" $$$ERROR($$$MGActionMissingProperty, "GrantPrivilege", "User")
 q:Namespace="" $$$ERROR($$$MGActionMissingProperty, "GrantPrivilege", "Namespace")
 
 n $NAMESPACE
 s $NAMESPACE=Namespace

 i WithGrant {
	s Status=##class(%SYSTEM.SQL.Security).GrantPrivilege(ObjPriv,ObjList,Type,User)
 } else {
	s Status=##class(%SYSTEM.SQL.Security).GrantPrivilegeWithGrant(ObjPriv,ObjList,Type,User)
 }
 i '$$$ISOK(Status) q Status

 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// RevokePrivilege lets you revoke an <i>ObjPriv</i> from a <i>User</i> via this call instead of using the SQL REVOKE statement
/// <p>
/// $SYSTEM.SQL.Security.RevokePrivilege(<i>ObjPriv</i>,<i>ObjList</i>,<i>Type</i>,<i>User</i>,<i>wGrant</i>,<i>Cascade</i>,<i>AsGrantor</i>)<br>
/// <dl>
///   Parameters:
/// <p>
/// <dt><i>ObjPriv</i>     	
/// <dd>Comma delimited string of actions to grant. * for all actions:<br>
/// <ul>
/// <li>Alter</li>
/// <li>Select</li>
/// <li>Insert</li>
/// <li>Update</li>
/// <li>Delete</li>
/// <li>References</li>
/// <li>Execute</li>
/// <li>Use</li>
/// <li>or any combination</li>
/// </ul>
/// <dt><i>ObjList</i>
/// <dd> * for all objects, else a comma delimited list of SQL object names (tables, views, procedures, schemas)<br>
/// <dt><i>Type</i>
/// <dd> Table, View, Schema, ML Configuration, Foreign Server, or Stored Procedure(s)<br>
/// <dt><i>User</i>
/// <dd> Comma delimited list of users<br>
/// <dt><i>wGrant</i>
/// <dd> 0/1 for WITH GRANT OPTION<br>
/// <dt><i>Cascade</i>
/// <dd> 0/1 cascade revoke?<br>
/// <dt><i>AsGrantor</i>
/// <dd> Alternate User to remove privileges for. AsGrantor can be a user name, a comma-separated list of user names, or "*". <br>
ClassMethod RevokePrivilege(ObjPriv As %String, ObjList As %String, Type As %String, User As %String, wGrant As %Integer = 0, Cascade As %Integer = 0, AsGrantor As %String = "") As %Status [ ProcedureBlock = 1, PublicList = SQLCODE ]
{
	Try {
		TSTART
		s Type=$$$UPPER(Type)
		set Type=$case(Type,"TABLE":1,"VIEW":3,"CUBES":4,"SCHEMA":5,"ML CONFIGURATION":6,"FOREIGN SERVER":7,"STORED PROCEDURES":9,"STORED PROCEDURE":9,:"")
		i Type="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-400,"Object Type of TABLE, VIEW, CUBES, SCHEMA, STORED PROCEDURE, FOREIGN SERVER, or ML CONFIGURATION expected" )
		
		s ObjPriv=$$$UPPER(ObjPriv)
		s Objs=""
		for i=1:1:$L(ObjPriv,",") {
			s Obj=$P(ObjPriv,",",i) 
			s Obj=$S(Obj="*":"*",Obj="ALTER":"a",Obj="SELECT":"s",Obj="INSERT":"i",Obj="UPDATE":"u",Obj="DELETE":"d",Obj="REFERENCES":"r",Obj="EXECUTE":"e",Obj="USE":"l",1:"")
			if Obj="" Set Objs="" quit
			s Objs=Objs_Obj
		}
		i Objs="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-60,$$$GetSysMessage("en","%SqlCode","SqlCode60","GrantObjPriv Error"))		// invalid action found
		
		s ObjList=$$$UPPER(ObjList)
		if ObjList'="*" {
			s ObjList=$LISTFROMSTRING(ObjList,",")
			s VObjList=""
			f i=1:1:$LL(ObjList) {
				s Obj=$LG(ObjList,i)
				s schema=$P(Obj,".",1)
				s object=$P(Obj,".",2)
				if Type=1||(Type=3) {
					if (schema'=""),(object'=""),($D(^rINDEXSQL("rv",schema,object))) { s VObjList=VObjList_$LB($LG(^rINDEXSQL("rv",schema,object),4)) }
					ELSE  { s VObjList="" quit }
				}
				ELSEIF Type=4 {
					
				}
				ELSEIF Type=5 {
						// If at least one object is defined in the schema revoke the privilege.
						// schema is upper case here, and we store "5,<schame>" in the priv global in uppercase
					if (schema'=""),($d(^rINDEXSQL("rv",schema))) { set VObjList=VObjList_$lb(schema) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-437,$$$FormatText($$$Text("Schema %1 not found","%SQL.Function"),schema))		// invalid schema found
					}
				}
				ELSEIF Type=6 {
					if Obj'="",$d(^%SYS("ml","configuration","i","NameIndex",$$$SQLUPPER(Obj))) { set VObjList=VObjList_$LB(Obj) }
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-187,$$$FormatText($$$Text("ML Configuration %1 not found","%SQL.Function"),Obj))		// invalid ML Configuration found
					}
				}
				ELSEIF Type=7 {
					set badServerName = 0
					if Obj'="" {
						set sc = $$updateForeignServerIndex^%SYS.SQLSEC
						if $$$ISERR(sc) {
							THROW ##class(%Exception.SQL).CreateFromSQLCODE(-400,$$$FormatText($$$Text("Failed to update foreign server index","%SQL.Function")))		// invalid foreign server
						}
						if $d(^rINDEXSQL("SERVER", $$$UPPER(schema), $$$UPPER(object)), serverData) {
							set VObjList=VObjList_$LB($lg(serverData, 4) _ "." _ $lg(serverData, 5))
						} else {
							set badServerName = 1
						}
					} else {
						set badServerName = 1
					}

					if badServerName {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-30,$$$FormatText($$$Text("Foreign server %1 not found","%SQL.Function"),Obj))		// invalid foreign server
					}
				}
				ELSEIF Type=9 {
					if (schema'=""),(object'=""),($D(^oddPROC(schema,object))) {
						s exschema=$LG(^oddPROC(schema,object,11),2)
						s exobject=$LG(^oddPROC(schema,object,11),3)
						s VObjList=VObjList_$LB(exschema_"."_exobject)
					}
					else {
						THROW ##class(%Exception.SQL).CreateFromSQLCODE(-428,$$$FormatText($$$Text("Stored Procedure %1.%2 not found","%SQL.Function"),schema,object))		// invalid procedure found
					}
				}
			}
			s ObjList=VObjList
		}
		i ObjList="" THROW ##class(%Exception.SQL).CreateFromSQLCODE(-30,$$$GetSysMessage("en","%SqlCode","SqlCode30","GrantObjPriv Error"))		// invalid objects found
		
		if '$$CheckAllUsersExist^%SYS.SQLSEC(User, .badUser) {
			THROW ##class(%Exception.SQL).CreateFromSQLCODE(-118,$$$GetSysMessage("en","%SqlCode","SqlCode118","GrantObjPriv Error"))	
		}
		
		s AsGrantor=$S(AsGrantor="*":"*",AsGrantor="":"",1:AsGrantor_",")
		s SQLCODE=100
		d setup1^%SYS.SQLSEC(Objs,Type,ObjList,User,wGrant,Cascade,,,AsGrantor,)
		if SQLCODE<0 {
			THROW ##class(%Exception.General).%New("RevokeObjPriv Error",SQLCODE,,"SQL Error Code")
		} else { set status=$$$OK }
		TCOMMIT 

	}
	
	Catch err {
		TROLLBACK 1 
		s status=err.AsStatus()
	}
 	RETURN status
}

/// Wrapper around RevokePrivilege() to support declarative syntax in CPF Actions
ClassMethod RevokeOne(ByRef Properties As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s $zt="Error"

 s ObjPriv=$g(Properties("ObjPriv"))
 s ObjList=$g(Properties("ObjList"))
 s Type=$g(Properties("Type"))
 s User=$g(Properties("User"))
 s Namespace=$g(Properties("Namespace"))
 s WithGrant=$g(Properties("wGrant"))
 s:WithGrant="" WithGrant=$g(Properties("WithGrant")) // alternate spelling
 s Cascade=$g(Properties("Cascade"))
 s AsGrantor=$g(Properties("AsGrantor"))
 
 q:ObjPriv="" $$$ERROR($$$MGActionMissingProperty, "RevokePrivilege", "ObjPriv")
 q:ObjList="" $$$ERROR($$$MGActionMissingProperty, "RevokePrivilege", "ObjList")
 q:Type="" $$$ERROR($$$MGActionMissingProperty, "RevokePrivilege", "Type")
 q:User="" $$$ERROR($$$MGActionMissingProperty, "RevokePrivilege", "User")
 q:Namespace="" $$$ERROR($$$MGActionMissingProperty, "RevokePrivilege", "Namespace")

 n $NAMESPACE
 s $NAMESPACE=Namespace

 s Status=##class(%SYSTEM.SQL.Security).RevokePrivilege(ObjPriv,ObjList,Type,User,+WithGrant,+Cascade,AsGrantor)
 i '$$$ISOK(Status) q Status

 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Wrapper around SQL call "GRANT <admin-privs> TO <grantee> [WITH ADMIN OPTION]"
/// Validates all user input to protect against SQL injection
ClassMethod GrantAdminOne(ByRef Properties As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s $zt="Error"

 s Privs=$zcvt($g(Properties("AdminPriv")),"u")
 s Grantee=$zcvt($g(Properties("Grantee")),"u")
 s Namespace=$g(Properties("Namespace"))
 s WithGrant=$g(Properties("WithGrant"))
 
 q:Privs="" $$$ERROR($$$MGActionMissingProperty, "GrantAdminPrivilege", "AdminPriv")
 q:Grantee="" $$$ERROR($$$MGActionMissingProperty, "GrantAdminPrivilege", "Grantee")
 q:Namespace="" $$$ERROR($$$MGActionMissingProperty, "GrantAdminPrivilege", "Namespace")

 // 1) validate AdminPriv
 set ValidPrivs=$$$AdminPrivsLB_$lb("%DB_OBJECT_DEFINITION")
 for i=1:1:$l(Privs,",") {
	s Priv=$p(Privs,",",i)
	i '$lf(ValidPrivs,Priv) {
		return $$$ERROR($$$MGInvalidPrivilege,Priv,"GrantAdminPrivilege","AdminPriv")
	}
 }
 // 2) validate Grantee: users, roles, "*", or _PUBLIC
 for i=1:1:$l(Grantee,",") {
	s Target=$p(Grantee,",",i)
	s Found=0
	s Found=Found||(Target="*")
	s Found=Found||(Target="_PUBLIC")
	s Found=Found||(##class(Security.Roles).Exists(Target))
	s Found=Found||(##class(Security.Users).Exists(Target))
	return:'Found $$$ERROR($$$MGInvalidGrantee,Target,"GrantAdminPrivilege","Grantee")
 }
 
 n $NAMESPACE
 s $NAMESPACE=Namespace

 s Command="GRANT "_Privs_" TO "_Grantee
 s:WithGrant Command=Command_" WITH ADMIN OPTION" 
 
 s rs=##class(%SYSTEM.SQL).Execute(Command)
 s code=rs.%SQLCODE
 q:code $$$ERROR($$$MGActionSQLErrorCode, "GrantAdminPrivilege", code)
	 
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Wrapper around SQL call "REVOKE <admin-privs> FROM <grantee>"
/// Validates all user input to protect against SQL injection
ClassMethod RevokeAdminOne(ByRef Properties As %String) As %Status [ Internal, ProcedureBlock = 1 ]
{
 s $zt="Error"

 s Privs=$zcvt($g(Properties("AdminPriv")),"u")
 s Grantee=$zcvt($g(Properties("Grantee")),"u")
 s Namespace=$g(Properties("Namespace"))
 
 q:Privs="" $$$ERROR($$$MGActionMissingProperty, "RevokeAdminPrivilege", "AdminPriv")
 q:Grantee="" $$$ERROR($$$MGActionMissingProperty, "RevokeAdminPrivilege", "Grantee")
 q:Namespace="" $$$ERROR($$$MGActionMissingProperty, "RevokeAdminPrivilege", "Namespace")

 // validate all user input to protect against SQL injection:
 // 1) validate AdminPriv
 set ValidPrivs=$$$AdminPrivsLB_$lb("%DB_OBJECT_DEFINITION")
 for i=1:1:$l(Privs,",") {
	s Priv=$p(Privs,",",i)
	i '$lf(ValidPrivs,Priv) {
		return $$$ERROR($$$MGInvalidPrivilege,Priv,"RevokeAdminPrivilege","AdminPriv")
	}
 }
 // 2) validate Grantee: users, roles, "*", or _PUBLIC
 for i=1:1:$l(Grantee,",") {
	s Target=$p(Grantee,",",i)
	s Found=0
	s Found=Found||(Target="*")
	s Found=Found||(Target="_PUBLIC")
	s Found=Found||(##class(Security.Roles).Exists(Target))
	s Found=Found||(##class(Security.Users).Exists(Target))
	return:'Found $$$ERROR($$$MGInvalidGrantee,Target,"RevokeAdminPrivilege","Grantee")
 }
 
 n $NAMESPACE
 s $NAMESPACE=Namespace

 s Command="REVOKE "_Privs_" FROM "_Grantee
 
 s rs=##class(%SYSTEM.SQL).Execute(Command)
 s code=rs.%SQLCODE
 q:code $$$ERROR($$$MGActionSQLErrorCode, "RevokeAdminPrivilege", code)
	 
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// This entry point can be used to determine if a role exists.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>rolename</i>
/// <dd>Name of the role to check.
/// </dl>
/// <p><b>Examples</b>:
/// <ul>
/// <li>Write $SYSTEM.SQL.Security.RoleExists("SalesManager") // Writes a 1 if role SalesManager exists</li>
/// </ul>
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Security_RoleExists(<i>rolename</i>)
ClassMethod RoleExists(rolename As %Library.String = "") As %Library.Boolean [ SqlProc ]
{
	RETURN $$RoleExists^%SYS.SQLSEC(rolename)
}

/// This entry point can be used to determine if a user exists.
/// <br><br>
/// <b>Parameters:</b>
/// <dl>
/// <dt><i>username</i>
/// <dd>Name of the user to check.
/// </dl>
/// <p><b>Examples</b>: 
/// <ul>
/// <li>Write $SYSTEM.SQL.Security.UserExists("Robert") // Writes a 1 if user Robert exists</li>
/// </ul>
/// This method can also be called as a Stored Procedure named %SYSTEM_SQL.Security_UserExists(<i>username</i>)
ClassMethod UserExists(username As %Library.String = "") As %Library.Boolean [ SqlProc ]
{
	RETURN $$UsersSQLExists^%SYS.SQLSEC(username)
}

}
