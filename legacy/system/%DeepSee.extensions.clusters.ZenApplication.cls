/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.extensions.clusters.ZenApplication Extends %ZEN.application [ System = 4 ]
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "Cluster Analysis";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE;

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

}
