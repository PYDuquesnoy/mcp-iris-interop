/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Api.InteropEditors.v2.spec Extends %REST.Spec [ ProcedureBlock ]
{

Projection OnGeneration As %Api.InteropEditors.OnGeneration;

XData OpenAPI [ MimeType = application/json ]
{
{
  "swagger":"2.0",
  "info":{
    "title":"Interoperability Editor API",
    "description":"Interoperability Editor API for InterSystems IRIS",
    "version":"1.0",
    "x-ISC_DispatchParent":"%Api.InteropEditors.base.dispParent",
    "x-ISC_ImplParent":"%Api.InteropEditors.v1.impl"
  },
  "schemes":[
    "http",
    "https"
  ],
  "paths":{
    "/{namespace}/mgmt-url":{
      "get":{
        "summary":"Get the 'path' portion of the Interoperability management URL for a given namespace.",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetMgmtUrl",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the URL."
          }
        }
      }
    },
    "/{namespace}/rules":{
      "get":{
        "summary":"Get a list of rule classes available on the server.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetRules",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of rules."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/packages":{
      "get":{
        "summary":"Get a list of defined packages.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetPackages",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of packages."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/classSummaries":{
      "get":{
        "summary":"Get summaries of non-hidden classes in this namespace.",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetClassSummaries",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of classes."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/types":{
      "get":{
        "summary":"Get a list of rule types available on the server.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetRuleTypes",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of rule types."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/types/{assistClass}/constraint-options":{
      "post":{
        "summary":"Get a list of constraint options for this rule type.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/rule-type"
          },
          {
            "$ref":"#/parameters/constraints"
          }
        ],
        "operationId":"GetConstraintOptions",
        "produces":[
          "application/json"
        ],
        "consumes": [
            "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of constraints options."
          },
          "400":{
            "description":"Invalid assist class."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/types/{assistClassName}":{
      "get":{
        "summary":"Get the schema for this rule type.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "name":"assistClassName",
            "in":"path",
            "description":"Rule type in the form of an assist class name.",
            "required":true,
            "type":"string"
          }
        ],
        "operationId":"GetRuleTypeSchema",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the schema."
          },
          "400":{
            "description":"Invalid assist class name."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/{ruleClass}": {
      "post": {
         "summary": "Create a new rule class.",
         "tags": [
            "Rule Editor"
         ],
         "parameters": [
            {
               "$ref": "#/parameters/namespace"
            },
            {
               "$ref": "#/parameters/ruleClass"
            },
            {
               "$ref": "#/parameters/ruleDefinition"
            }
         ],
         "operationId": "PostRule",
         "consumes": [
            "application/json"
         ],
         "produces": [
            "application/json"
         ],
         "responses": {
            "201": {
               "description": "Successfully created the new rule class."
            },
            "400": {
               "description": "Invalid rule name."
            },
            "500": {
               "description": "Server error."
            }
         }
      },
      "put": {
         "summary": "Overwrite this rule class.",
         "tags": [
            "Rule Editor"
         ],
         "parameters": [
            {
               "$ref": "#/parameters/namespace"
            },
            {
               "$ref": "#/parameters/ruleClass"
            },
            {
               "$ref": "#/parameters/ruleDefinition"
            },
            {
              "$ref": "#/parameters/ignoreConflict"
            }
         ],
         "operationId": "PutRule",
         "consumes": [
            "application/json"
         ],
         "produces": [
            "application/json"
         ],
         "responses": {
            "200": {
               "description": "Successfully updated this rule class."
            },
            "400": {
               "description": "Invalid rule name."
            },
            "500": {
               "description": "Server error."
            }
         }
      },
      "get": {
         "summary": "Get this rule class.",
         "tags": [
            "Rule Editor"
         ],
         "parameters": [
            {
               "$ref": "#/parameters/namespace"
            },
            {
               "$ref": "#/parameters/ruleClass"
            }
         ],
         "operationId": "GetRule",
         "produces": [
            "application/json"
         ],
         "responses": {
            "200": {
               "description": "Got this rule class."
            },
            "500": {
               "description": "Server error."
            }
         }
      }
    },
    "/{namespace}/rules/compile/{ruleClass}": {
      "put": {
         "summary": "Compile this rule class.",
         "tags": [
            "Rule Editor"
         ],
         "parameters": [
            {
               "$ref": "#/parameters/namespace"
            },
            {
               "$ref": "#/parameters/ruleClass"
            }
         ],
         "operationId": "CompileRule",
         "consumes": [
            "application/json"
         ],
         "produces": [
            "application/json"
         ],
         "responses": {
            "200": {
               "description": "Successfully compiled the rule class."
            },
            "500": {
               "description": "Server error."
            }
         }
      }
    },
    "/%SYS/session/expiry":{
      "get":{
        "summary":"Get the expiry of the current session",
        "operationId":"GetExpiry",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the expiration time of the current session."
          }
        }
      }
    },
    "/%SYS/session":{
      "delete":{
        "summary":"Terminate CSP Session.",
        "operationId":"Logout",
        "responses":{
          "200":{
            "description":"Successfully logged out."
          }
        }
      }
    },
    "/%SYS/session/language":{
      "get":{
        "summary":"Get the language for this session",
        "operationId":"GetLanguage",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the language for this session."
          }
        }
      }
    },
    "/%SYS/session/language/{language}":{
      "put":{
        "summary":"Set the language for this session",
        "parameters":[
          {
            "$ref":"#/parameters/language"
          }
        ],
        "operationId":"SetLanguage",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Set the language for this session."
          },
          "400":{
            "description":"Unable to set the language for this session."
          }
        }
      }
    },
    "/%SYS/permissions":{
      "get":{
        "summary":"Get a list of permissions for the current user and namespaces they can access.",
        "operationId":"GetPermissions",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got list of permissions for current user.",
            "schema":{
                "$ref":"#/definitions/permissionsResponse"
            }
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/%SYS/system-mode":{
      "get":{
        "summary":"Get the system mode of this instance.",
        "operationId":"GetSystemMode",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the system mode."
          }
        }
      }
    },
    "/{namespace}/rules/plugins":{
      "get":{
        "summary":"Get list of input plugins.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetInputPluginsList",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got input plugins."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/context/{contextClass}":{
      "get":{
        "summary":"Get information on this context class.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/contextClass"
          }
        ],
        "operationId":"GetContextInputs",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the context class information."
          },
          "404":{
            "description":"The given context class does not exist."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/document/{ruleClass}":{
      "get":{
        "summary":"Get information on this class.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/ruleClass"
          }
        ],
        "operationId":"GetTestingInputs",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the context class information."
          },
          "404":{
            "description":"The given context class does not exist."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/test/{ruleClass}":{
      "post":{
        "summary":"Run rule and return logs",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/ruleClass"
          },
          {
            "$ref":"#/parameters/ruleTestMessage"
          }
        ],
        "operationId":"TestRule",
        "consumes": [
            "application/json"
         ],
         "produces": [
            "application/json"
         ],
        "responses":{
          "200":{
            "description":"Test successful."
          },
          "404":{
            "description":"The given rule does not exist."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/productionItems":{
      "get":{
        "summary":"Get a list of production items in rule.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetProductionItems",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of production items."
          }
        }
      }
    },
    "/{namespace}/docTypes/{assistClassName}":{
      "get":{
        "summary":"Get a list of doctype names and categories for specified assist class",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "name":"assistClassName",
            "in":"path",
            "description":"Rule type in the form of an assist class name.",
            "required":true,
            "type":"string"
          }
        ],
        "operationId":"GetDocTypes",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of doctypes."
          }
        }
      }
    },
    "/{namespace}/lookup-tables":{
      "get":{
        "summary":"Get a list of lookup tables in this namespace.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetLookupTables",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of lookup tables."
          }
        }
      }
    },
    "/{namespace}/productions":{
      "get":{
        "summary":"Get a list of productions.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetProductions",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of productions."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/productions/config-items":{
      "get":{
        "summary":"Get a list of production configuration items.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/production"
          },
          {
            "$ref":"#/parameters/targets"
          }
        ],
        "operationId":"GetProductionConfigItems",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of configuration items."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/transforms":{
      "get":{
        "summary":"Get a list of data transforms.",
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"GetTransforms",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the list of transforms."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/rules/plugins/dispatch/{pluginPath}":{
      "get":{
        "summary":"Dispatch to plugin endpoint.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/pluginPath"
          }
        ],
        "operationId":"DispatchPlugin"
      },
      "head":{
        "summary":"Dispatch to plugin endpoint.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/pluginPath"
          }
        ],
        "operationId":"DispatchPlugin"
      },
      "post":{
        "summary":"Dispatch to plugin endpoint.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/pluginPath"
          }
        ],
        "operationId":"DispatchPlugin"
      },
      "put":{
        "summary":"Dispatch to plugin endpoint.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/pluginPath"
          }
        ],
        "operationId":"DispatchPlugin"
      },
      "delete":{
        "summary":"Dispatch to plugin endpoint.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/pluginPath"
          }
        ],
        "operationId":"DispatchPlugin"
      },
      "patch":{
        "summary":"Dispatch to plugin endpoint.",
        "tags":[
            "Rule Editor Plugins"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/pluginPath"
          }
        ],
        "operationId":"DispatchPlugin"
      }
    },
    "/{namespace}/sourcecontrol/enabled":{
      "get":{
        "summary":"Returns enabled true or false if Source Control Enabled for the namespace",
        "tags":[
            "Source Control"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          }
        ],
        "operationId":"SourceControlEnabled",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Is Source Control Enabled",
            "schema":{
                "$ref":"#/definitions/sourceControlResponse"
            }
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/sourcecontrol/menus":{
      "post":{
        "summary":"Returns Source Control Menu for the given parameters",
        "tags":[
            "Source Control"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/sourceControlRequestBody"
          }
        ],
        "operationId":"SourceControlGetMenus",
        "consumes": [
            "application/json"
         ],
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Source Control Get Menus",
            "schema":{
                "$ref":"#/definitions/sourceControlResponse"
            }
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/sourcecontrol/useraction":{
      "post":{
        "summary":"Requests Source Control User Action for the given parameters",
        "tags":[
            "Source Control"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/sourceControlRequestBody"
          }
        ],
        "operationId":"SourceControlUserAction",
        "consumes": [
            "application/json"
         ],
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Source Control User Action",
            "schema":{
                "$ref":"#/definitions/sourceControlResponse"
            }
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/sourcecontrol/afteruseraction":{
      "post":{
        "summary":"Requests Source Control After User Action for the given parameters",
        "tags":[
            "Source Control"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/sourceControlRequestBody"
          }
        ],
        "operationId":"SourceControlAfterUserAction",
        "consumes": [
            "application/json"
         ],
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Source Control After User Action"
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
    "/{namespace}/sourcecontrol/status":{
      "post":{
        "summary":"Requests Source Control GetStatus for the given parameters",
        "tags":[
            "Source Control"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/sourceControlRequestBody"
          }
        ],
        "operationId":"SourceControlGetStatus",
        "consumes": [
            "application/json"
         ],
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Source Control GetStatus",
            "schema":{
                "$ref":"#/definitions/sourceControlResponse"
            }
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
      "/{namespace}/rules/types/{assistClassName}/properties":{
      "post":{
        "summary":"Get the property list for this rule type.",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "name":"assistClassName",
            "in":"path",
            "description":"Rule type in the form of an assist class name.",
            "required":true,
            "type":"string"
          },
          { 
            "name":"searchProperties",
            "in":"body",
            "description":"Search context and key for property list",
            "required":false,
            "schema":{
              "type":"array",
              "items":"object"
            }
          }
        ],
        "operationId":"GetPropertyList",
        "produces":[
          "application/json"
        ],
        "consumes": [
            "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the property list."
          },
          "400":{
            "description":"Invalid assist class name."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    },
      "/{namespace}/rules/context/types/{contextClass}":{
      "get":{
        "summary":"Get list of context types",
        "tags":[
            "Rule Editor"
        ],
        "parameters":[
          {
            "$ref":"#/parameters/namespace"
          },
          {
            "$ref":"#/parameters/contextClass"
          }
        ],
        "operationId":"GetContextTypes",
        "produces":[
          "application/json"
        ],
        "responses":{
          "200":{
            "description":"Got the context types."
          },
          "404":{
            "description":"The given context class does not exist."
          },
          "500":{
            "description":"Server error."
          }
        }
      }
    }

  },
  "parameters":{
    "namespace": {
      "name":"namespace",
      "in":"path",
      "description":"InterSystems IRIS namespace this operation will be performed in.",
      "required":true,
      "type":"string"
    },
    "contextClass": {
      "name":"contextClass",
      "in":"path",
      "description":"Name of the ObjectScript class used as a context class for a rule.",
      "required":true,
      "type":"string"
    },
    "ruleClass": {
      "name":"ruleClass",
      "in":"path",
      "description":"Name of the ObjectScript class in which this rule definition is defined.",
      "required":true,
      "type":"string"
    },
    "ruleTestMessage": {
      "name":"ruleTestMessage",
      "in":"body",
      "description":"Defines test parameters for rule class",
      "required":true,
      "schema":{
        "type":"object"
      }
    },
    "ruleDefinition": {
      "name":"ruleDefinition",
      "in":"body",
      "description":"Definition which defines the contents of a rule class.",
      "required":true,
      "schema":{
        "type":"object"
      }
    },
    "pluginPath": {
      "name":"pluginPath",
      "in":"path",
      "description":"Path of the plugin endpoint to hit.",
      "required":true,
      "type":"string"
    },
    "ignoreConflict":{
      "name":"ignoreConflict",
      "in":"query",
      "description":"Overwrite this class if it exists, ignoring conflicts.",
      "type": "boolean",
      "required":false
    },
    "sourceControlRequestBody":{
      "name":"sourceControlRequestBody",
      "in":"body",
      "description":"The parameters for the requested Source Control function",
      "required":true,
      "schema":{
        "type":"object",
        "required": [
          "parameters"
        ],
        "properties":{
          "parameters":{
            "type":"array",
            "items":"string"
          }
        }
      }
    },
    "rule-type": {
      "name":"assistClass",
      "in":"path",
      "description":"Rule type, in the form of an assist class.",
      "required":true,
      "type":"string"
    },
    "constraints": {
      "name":"constraints",
      "in":"body",
      "description":"Constraints to get options for.",
      "required":false,
      "schema":{
        "type":"array",
        "items":"object"
      }
    },
    "production":{
      "name":"production",
      "in":"query",
      "description":"Get the configuration items for only this production.",
      "type": "string",
      "required":false
    },
    "targets":{
      "name":"targets",
      "in":"query",
      "description":"Only get the configuration items of type 'target'.",
      "type": "boolean",
      "required":false
    },
    "language": {
      "name":"language",
      "in":"path",
      "description":"Language code to set for this session.",
      "required":true,
      "type":"string"
    }
  },
  "definitions":{
    "permissionsResponse":{
        "type":"object",
        "properties":{
          "RuleEditor":{
            "type":"boolean"
          },
          "UserWritePrivs":{
            "type":"array",
            "items":"string"
          },
          "Namespaces":{
            "type":"array",
            "items":"string"
          }
        }
    },
    "sourceControlResponse":{
        "type":"object",
        "properties":{
          "status":{
            "type":"object",
            "properties":{
              "errors":{
                "type":"array",
                "items":"object"
              },
              "summary":{
                "type":"string"
              }
            }
          },
          "console":{
            "type":"array",
            "items":"string"
          },
          "result":{
            "type":"object",
            "properties":{
              "content":{
                "type":"array",
                "items":"object"
              }
            }
          }
        }
      }
    }
  }
}

}
