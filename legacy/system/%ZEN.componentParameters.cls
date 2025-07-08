/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Property superclass used to define special parameters for ZEN components.
Class %ZEN.componentParameters [ Deprecated, System = 3 ]
{

/// If true, then the associated property will have localization
/// support automatically created for it.
Parameter ZENLOCALIZE As BOOLEAN = 0;

/// If true, this indicates that the associated property can contain
/// a #()# expression that will be evaluated by the property's component.
Parameter ZENEXPRESSION As BOOLEAN = 0;

/// If true, then the associated property will be encrypted when 
/// sent to the client.
Parameter ZENENCRYPT As BOOLEAN = 0;

/// If true, then the associated property is treated as a "setting"
/// in the client object. That is, it is reported as a setting and
/// it is accessible via the client getProperty / setProperty API.
Parameter ZENSETTING As BOOLEAN = 1;

/// If true, then the associated property is treated as a client-only
/// property. That is, it is part of the client-side object but it is
/// not synched to the server-version of the object and is not serialized.
Parameter ZENCLIENTONLY As BOOLEAN = 0;

}
