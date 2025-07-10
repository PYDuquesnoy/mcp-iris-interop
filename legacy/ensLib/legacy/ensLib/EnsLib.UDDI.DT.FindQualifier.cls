/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DataType to represent the FindQualifier enumeration
Class EnsLib.UDDI.DT.FindQualifier Extends %String [ ClassType = datatype, ProcedureBlock, System = 4 ]
{

/// The 'AndAllKeys' value specifies that the keys for the identifierBag are AND'd together, rather than OR'd together, for FindBusiness and FindTModel queries
/// The 'CaseSensitiveMatch value specifies that the match is case-sensitive for FindBusiness, FindService, and FindTModel queries.
/// The 'CombineCategoryBags' value specifies that the categoryBag entries for the current, contained, or referenced CategoryBag entries are combined for a FindBusiness query.
/// The 'ExactNameMatch' value specifies that the match must be exact for FindBusiness, FindService, and FindTModel queries.
/// The 'OrAllKeys' value specifies that the keys for TModelBag and CategoryBag are OR'd together, negating any AND treatment or OrLikeKeys, for FindBinding, FindBusiness, FindService and FindTModel queries.
/// The 'OrLikeKeys' value specifies that keys from the same namespace are OR'd together, rather than AND'd together, for FindBusiness, FindService and FindTModel queries.
/// The 'ServiceSubset' value specifies that only the CategoryBags from contained or referenced businessService elements are used for a FindBusiness query.
/// The 'SortByDateAscending' value specifies that the results are sorted by date, from earliest to latest, for FindBinding, FindBusiness, FindService and FindTModel queries.
/// The 'SortByDateDescending' value specifies that the results are sorted by date, from latest to earlies, for FindBinding, FindBusiness, FindService and FindTModel queries.
/// The 'SortByNameAscending' field contains the string that specifies that the results are sorted by name, from A to Z, for FindBusiness, FindService, and FindTModel queries.
/// The 'SortByNameDescending' field contains the string that specifies that the results are sorted by name, from Z to A, for FindBusiness, FindService, and FindTModel queries.
Parameter VALUELIST = ",AndAllKeys,CaseSensitiveMatch,CombineCategoryBags,ExactNameMatch,OrAllKeys,OrLikeKeys,ServiceSubset,SortByDateAscending,SortByDateDescending,SortByNameAscending,SortByNameDescending";

}
