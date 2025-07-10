/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Service to consume data from FTP file sources using the RecordMap parsing framework.
Class EnsLib.RecordMap.Service.FTPService Extends EnsLib.RecordMap.Service.FileService [ System = 4 ]
{

Parameter ADAPTER = "EnsLib.FTP.InboundAdapter";

}
