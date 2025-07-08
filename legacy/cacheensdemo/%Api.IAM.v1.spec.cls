/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Api.IAM.v1.spec Extends %REST.Spec
{

XData OpenAPI [ MimeType = application/json ]
{
{
  "swagger":"2.0",
  "info":{
    "description":"API for managing the IAM License for InterSystems IRIS.",
    "title":"IAM License Manager",
    "x-ISC_DispatchParent":"%REST.disp",
    "version":"1"
  },
  "schemes":[
    "http"
  ],
  "paths":{
    "/license":{
      "get":{
        "summary":"Get your IAM License Key from server.",
        "description":"Get the JSON string of your IAM License Key from your licensed InterSystems IRIS instance.",
        "operationId":"getLicense",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the IAM License Key."
          },
          "204":{
            "description":"This instance of InterSystems IRIS doesn't have an IAM License Key."
          },
          "423":{
            "description":"Failed to acquire IAM License lock."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    }
  }
}
}

}
