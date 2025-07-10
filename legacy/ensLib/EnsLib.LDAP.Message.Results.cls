/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Results returned by <CLASS>EnsLib.LDAP.Operation.Standard</CLASS> following
/// a <CLASS>EnsLib.LDAP.Message.Search</CLASS> request.
Class EnsLib.LDAP.Message.Results Extends EnsLib.LDAP.Message.Status [ System = 4 ]
{

Relationship Results As EnsLib.LDAP.Message.Result [ Cardinality = children, Inverse = Results ];

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
