/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Manages the many-to-many relationship of workflow Users and Roles.
/// Each instance represents the association of a specific User with a specific Role.
Class EnsLib.Workflow.RoleMembership Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, CompileAfter = (EnsLib.Workflow.RoleDefinition, EnsLib.Workflow.UserDefinition), Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter XMLNAME = "member";

Index ID On (Role, User) [ IdKey ];

ForeignKey RoleKey(Role) References EnsLib.Workflow.RoleDefinition(ID) [ OnDelete = cascade ];

ForeignKey UserKey(User) References EnsLib.Workflow.UserDefinition(ID) [ OnDelete = cascade ];

/// Role involved in the relationship.
Property Role As RoleDefinition(XMLNAME = "roleName", XMLPROJECTION = "attribute", XMLREFERENCE = "ID") [ SqlFieldName = RoleName ];

/// User that belongs to the associated Role.
Property User As UserDefinition(XMLNAME = "userName", XMLPROJECTION = "attribute", XMLREFERENCE = "ID") [ SqlFieldName = UserName ];

/// Defines a ranking value (1 is highest ranking) for members of a Role.
/// The Workflow Engine uses this value to help with task distribution.
Property Ranking As %Integer(MINVAL = 1, XMLNAME = "ranking", XMLPROJECTION = "attribute");

/// (Optional) Defines a title for a given user within a role.<br>
/// For example, a role member could be designated as the "Manager" of
/// the role. A Workflow can make use of this designation when distributing
/// tasks.
Property Title As %String(MAXLEN = 128, XMLNAME = "title", XMLPROJECTION = "attribute");

Storage Default
{
<Data name="RoleMembershipDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Ranking</Value>
</Value>
<Value name="3">
<Value>Title</Value>
</Value>
</Data>
<DataLocation>^EnsLib.W.RoleMembershipD</DataLocation>
<DefaultData>RoleMembershipDefaultData</DefaultData>
<IdLocation>^EnsLib.W.RoleMembershipD</IdLocation>
<IndexLocation>^EnsLib.W.RoleMembershipI</IndexLocation>
<StreamLocation>^EnsLib.W.RoleMembershipS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
