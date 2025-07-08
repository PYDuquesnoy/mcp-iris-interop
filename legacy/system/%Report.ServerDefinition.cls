/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

/// This class defines the storage for a Report Server Definition.
/// 
Class %Report.ServerDefinition Extends %Persistent [ Language = objectscript ]
{

/// The name of the report server definition
Property Name As %String(MAXLEN = 128) [ Required ];

Index NameIdx On Name [ Unique ];

/// The host where the Logi Report server is running. 
/// Can be specified as an IPv4 or IPv6 address, or as a hostname 
Property Host As %String(MAXLEN = 256, PATTERN = "") [ Required ];

/// The port on the <Property>Host</Property> for the Report Server.
Property Port As %Integer(MAXVAL = 65535, MINVAL = 1) [ InitialExpression = 8888, Required ];

Property SSOEnabled As %Boolean [ Required ];

/// Return the set of Report Server Definitions.
Query ByName(name As %String = "") As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,Name,Host,Port") [ SqlProc ]
{
	Select %ID,Name,Host,Port
	From %Report.ServerDefinition
	Order By Name
}

/// Return the Report Server Definition by specified id
Query WhereID(id As %String = "") As %SQLQuery(CONTAINID = 1, ROWSPEC = "Name") [ SqlProc ]
{
    Select Name
    From %Report.ServerDefinition
    WHERE %ID=:id
}

Method %OnValidateObject() As %Status [ Internal, Private, ServerOnly = 1 ]
{
	Set tSC = $$$OK
	
	If '$match(..Name,"[a-zA-Z0-9\.]+") { 
		/* Name must be alphanumeric */
		Set tSC = $System.Status.AppendStatus(tSC,$System.Status.Error($$$DatatypeValidationFailed,"Name",..Name))
	}
	
	If '$match(..Host,"[a-zA-Z0-9\.:]+") { 
		/* Host must be alphanumeric plus period or colon */
		Set tSC = $System.Status.AppendStatus(tSC,$System.Status.Error($$$DatatypeValidationFailed,"Host",..Host))
	}
	
	Return tSC
}

/// Creates the "admin" and "guest" roles for this report server
Trigger CreateDefaultRoles [ Event = INSERT/UPDATE, Foreach = row/object, Time = AFTER ]
{
    Quit:'{SSOEnabled} $$$OK
    
    Set tSC1 = $$$OK
    Set role = {Name} _ "_admin"
    if ('##class(Security.Roles).Exists(role)) {
        Set tSC1 = ##class(Security.Roles).Create(role, "Admin role on Report Server " _ {Name})
    }
    
    Set tSC2 = $$$OK
    Set role = {Name} _ "_guest"
    if ('##class(Security.Roles).Exists(role)) {
        Set tSC2 = ##class(Security.Roles).Create(role, "Guest role on Report Server " _ {Name})
    }
    
    Quit $$$ADDSC(tSC1,tSC2)
}

/// Updates all roles for %Report.ServerDefinition objects after report server rename
/// Renames each role from <{Name*O}>_<role> to <..Name>_<role>
/// Replaces all instances of <{Name*O}> in role description with ..Name
Trigger UpdateRoles [ Event = UPDATE, Foreach = row/object ]
{
    Set statement = ##class(%SQL.Statement).%New()
    Set tSC = statement.%PrepareClassQuery("Security.Roles","List")
    Quit:$$$ISERR(tSC) tSC
    
    Set tSC = $$$OK
    Set tPointer = 0
    Set tRoleSet = statement.%Execute("*") // get all roles
    while tRoleSet.%Next() {
        Set prevRole = tRoleSet.%Get("Name")
        if ($PIECE(prevRole,"_", 1) = {Name*O}) {
            Set newRole = {Name} _ "_" _ $PIECE(prevRole,"_", 2, *)
            Set sc = ##class(Security.Roles).Rename(newRole, prevRole)
            Set:$$$ISERR(sc) tSC = sc
            
            // replace instances of previous name in role description
            Set sc = ##class(Security.Roles).Get(newRole, .prop, .obj)
            Set:$$$ISERR(sc) tSC = $$$ERROR($$$GeneralError, "Unable to update all linked roles")
            
            Set tDesc = prop("Description")
            Set pos = 1
            while (pos '= 0) {
                if ($LENGTH(tDesc) > 0 && $FIND(tDesc, {Name*O}, pos) > 0) {
                    Set index = $FIND(tDesc, {Name*O}, pos) 
                    Set $EXTRACT(tDesc, index - $LENGTH({Name*O}), index - 1) = {Name}
                }
                Set pos = $FIND(tDesc, {Name}, pos)
            }
            
            Set prop("Description") = tDesc
            Set sc = ##class(Security.Roles).Modify(newRole, .prop)
            Set:$$$ISERR(sc) tSC = $$$ERROR($$$GeneralError, "Unable to update all linked roles")
        }
    }
    Quit tSC
}

/// Deletes all roles for this %Report.ServerDefinition object
Trigger DeleteRoles [ Event = DELETE, Foreach = row/object ]
{
    Set statement = ##class(%SQL.Statement).%New()
    Set tSC = statement.%PrepareClassQuery("Security.Roles","List")
    Quit:$$$ISERR(tSC) tSC
    
    Set tSC = $$$OK
    Set tPointer = 0
    Set tRoleSet = statement.%Execute("*") // get all roles
    while tRoleSet.%Next() {
        Set tRole = tRoleSet.%Get("Name")
        if ($PIECE(tRole,"_", 1) = {Name}) {
            Set sc = ##class(Security.Roles).Delete(tRole)
            Set:$$$ISERR(sc) tSC = $$$ERROR($$$GeneralError, "Unable to delete all linked roles")
        }
    }
    Quit tSC
}

Storage Default
{
<Data name="ServerDefinitionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Host</Value>
</Value>
<Value name="4">
<Value>Port</Value>
</Value>
<Value name="5">
<Value>SSOEnabled</Value>
</Value>
</Data>
<DataLocation>^%Report.ServerDefinitionD</DataLocation>
<DefaultData>ServerDefinitionDefaultData</DefaultData>
<IdLocation>^%Report.ServerDefinitionD</IdLocation>
<IndexLocation>^%Report.ServerDefinitionI</IndexLocation>
<StreamLocation>^%Report.ServerDefinitionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
