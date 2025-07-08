/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specification class to define API Management version 2.
Class %Api.Mgmnt.v2.spec Extends %REST.Spec [ System = 4 ]
{

/// This parameter influences the CORS support. The default is an empty string meaning 'not specified'.
/// If set to true (1) then CORS processing is ON. If set to false (0) then CORS processing is OFF.
/// If left unset "" then the decision to process CORS is delegated to the setting on the URL map route.
Parameter HandleCorsRequest = 1;

XData OpenAPI [ MimeType = application/json ]
{
{
  "swagger":"2.0",
  "info":{
    "title":"API Management",
    "version":"2",
    "description":"The API Management API manages the APIs which are defined using a RESTSpec.\r\nIn addition limited supported for legacy REST applications based on direct subclassing of %CSP.REST is included.",
    "x-ISC_DispatchParent":"%REST.disp"
  },
  "basePath":"/api/mgmnt",
  "schemes":[
    "http",
    "https"
  ],
  "consumes":[
    "application/json"
  ],
  "produces":[
    "application/json"
  ],
  "paths":{
    "/v2/":{
      "get":{
        "summary":"Get the list of all REST applications",
        "description":"This request returns a list of all REST applications in all namespaces as a JSON array.",
        "operationId":"GetAllRESTApps",
        "parameters":[
        ],
        "responses":{
          "200":{
            "description":"Returns an array of objects describing the defined REST application.",
            "schema":{
              "type":"array",
              "items":{
                "$ref":"#/definitions/RESTApplication"
              }
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        }
      }
    },
    "/v2/{namespace}/":{
      "get":{
        "summary":"Get the list of all REST applications in a namespace",
        "description":"This request returns a list of all REST applications in the specified namespace as a JSON array.",
        "operationId":"GetRESTApps",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "responses":{
          "200":{
            "description":"Returns an array of objects describing the defined REST application.",
            "schema":{
              "type":"array",
              "items":{
                "$ref":"#/definitions/RESTApplication"
              }
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        }
      }
    },
    "/v2/{namespace}/{applicationName}":{
      "get":{
        "summary":"Get OpenAPI 2.0 definition of this REST application",
        "description":"This request returns the OpenAPI 2.0 swagger description of this application as a JSON object.",
        "operationId":"GetApplication",
        "produces":[
          "application/json"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/applicationName"
          }
        ],
        "responses":{
          "200":{
            "description":"Returns an OpenAPI 2.0 swagger description of the REST application.",
            "schema":{
              "$ref":"#/definitions/RESTSwagger"
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        }
      },
      "post":{
        "summary":"Create a REST applicaiton from the OpenAPI 2.0 definition.",
        "description":"This request replaces an existing REST application or creates a new REST application.\r\nThe request body may specify an OpenAPI 2.0 swagger description which is used to replace/create the application.\r\nIf the request body is empty, then the RESTSpec and dispatch classes are replaced with any empty application.",
        "operationId":"CreateApplication",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/applicationName"
          },
          {
            "name":"swagger",
            "in":"body",
            "description":"The body is a JSON object containing the swagger definition for this application.",
            "required":false,
            "schema":{
              "$ref":"#/definitions/RESTSwagger"
            }
          },
          {
            "name":"strict",
            "in":"query",
            "description":"If strict is false, then only the swagger properties which are needed for code generation are checked.  If strict is true, then all swagger properties are checked.  The value of the strict parameter defaults to true.",
            "required":false,
            "type":"boolean"
          }
        ],
        "responses":{
          "200":{
            "description":"A success response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        },
        "x-ISC_RequiredResource":[
          "%Development:USE"
        ]
      },
      "delete":{
        "summary":"Delete a REST application.",
        "description":"This request deletes an application by deleting the specification class and the dispatch class that represent the application.  The implementation class is not deleted.",
        "operationId":"DeleteApplication",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/applicationName"
          }
        ],
        "responses":{
          "200":{
            "description":"A success response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        },
        "x-ISC_RequiredResource":[
          "%Development:USE"
        ]
      }
    },
    "/":{
      "get":{
        "summary":"Get the list of all legacy REST applications",
        "description":"This request returns a list of all %CSP.REST based REST applications in all namespaces as a JSON array.",
        "operationId":"GetAllWebRESTApps",
        "parameters":[
        ],
        "responses":{
          "200":{
            "description":"Returns an array of objects describing the defined REST application.",
            "schema":{
              "type":"array",
              "items":{
                "$ref":"#/definitions/RESTApplication"
              }
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        },
        "deprecated":true
      }
    },
    "/v1/{namespace}/restapps":{
      "get":{
        "summary":"Get the list of all legacy REST applications in a namespace",
        "description":"This request returns a list of all %CSP.REST based REST applications in the specified namespace as a JSON array.",
        "operationId":"GetWebRESTApps",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "responses":{
          "200":{
            "description":"Returns an array of objects describing the defined REST application.",
            "schema":{
              "type":"array",
              "items":{
                "$ref":"#/definitions/RESTApplication"
              }
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        },
        "deprecated":true
      }
    },
    "/v1/{namespace}/spec/{webApplication}":{
      "get":{
        "summary":"Get OpenAPI 2.0 definition of this %CSP.REST based REST application.",
        "description":"This request returns the OpenAPI 2.0 swagger description based on the UrlMap of %CSP.REST subclass for this REST application.  The namespace parameter defaults to the web application's namespace.",
        "operationId":"GetWebRESTApplication",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "name":"webApplication",
            "in":"path",
            "description":"The name of the web application which to which this %CSP.REST based application is deployed.",
            "required":true,
            "type":"string",
            "pattern":"(.*)"
          }
        ],
        "responses":{
          "200":{
            "description":"Returns an OpenAPI 2.0 swagger description of the REST application.",
            "schema":{
              "$ref":"#/definitions/RESTSwagger"
            }
          },
          "default":{
            "description":"An error response",
            "schema":{
              "$ref":"#/definitions/ResponseText"
            }
          }
        },
        "deprecated":true
      }
    }
  },
  "definitions":{
    "RESTApplication":{
      "title":"REST Application Description",
      "description":"The RESTApplication object contains the description of a REST application.",
      "type":"object",
      "required":[
        "name",
        "namespace"
      ],
      "properties":{
        "name":{
          "title":"Application Name",
          "type":"string"
        },
        "dispatchClass":{
          "title":"Dispatch class name",
          "type":"string"
        },
        "namespace":{
          "title":"Application Namespace",
          "type":"string"
        },
        "resource":{
          "title":"Resource which is required for this application of the form resource:mode.",
          "type":"string"
        },
        "swaggerSpec":{
          "title":"URL to get a OpenAPI 2.o swagger defintion",
          "type":"string"
        },
        "enabled":{
          "title":"Enabled flag.",
          "type":"boolean"
        }
      }
    },
    "RESTSwagger":{
      "title":"REST Application Swagger Definition",
      "description":"The RESTSwagger object contains the OpenAPI 2.0 swagger definition of a REST application",
      "type":"object"
    },
    "ResponseText":{
      "title":"Response Message",
      "type":"object",
      "properties":{
        "msg":{
          "title":"Response Message",
          "type":"string"
        }
      }
    }
  },
  "parameters":{
    "namespace":{
      "name":"namespace",
      "in":"path",
      "description":"The IRIS namespace in which to perform the requested operation.",
      "required":true,
      "type":"string"
    },
    "applicationName":{
      "name":"applicationName",
      "in":"path",
      "description":"The name of the REST application which is the package name for the classes defining and implementing the application.",
      "required":true,
      "type":"string"
    }
  }
}
}

}
