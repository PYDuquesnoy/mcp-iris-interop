/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Api.InteropMetrics.v1.spec Extends %REST.Spec [ ProcedureBlock ]
{

XData OpenAPI [ MimeType = application/json ]
{
{
    "swagger":"2.0",
    "info": {
      "title":"Interop Metrics API",
      "description": "Set of REST APIs for getting interop metrics",
      "version":"1.0.0"
    },
    "produces": [
        "text/plain"
    ],
    "basePath": "/api/monitor/interop",
    "paths": {
        "/current/interfaces": {
            "get": {
                "description": "Returns information about all inbound, outbound, and web API interfaces for all currently active data.",
                "operationId": "currentInterfaces",
                "parameters": [ 
                    {"$ref": "#/parameters/start"},
                    {"$ref": "#/parameters/end"},
                    {"$ref": "#/parameters/namespace"}
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_active_inbound_interfaces{protocol=\"TCP\"} 9\niris_interop_active_inbound_interfaces{id=\"NAMESPACE1\"} 5\niris_interop_active_inbound_interfaces{id=\"NAMESPACE1\",protocol=\"TCP\"} 5\niris_interop_active_inbound_interfaces{id=\"NAMESPACE2\"} 4\niris_interop_active_inbound_interfaces{id=\"NAMESPACE2\",protocol=\"TCP\"} 4\niris_interop_active_inbound_interfaces_total 9\niris_interop_active_outbound_interfaces{protocol=\"TCP\"} 6\niris_interop_active_outbound_interfaces{protocol=\"FILE\"} 1\niris_interop_active_outbound_interfaces{id=\"NAMESPACE2\"} 12\niris_interop_active_outbound_interfaces{id=\"NAMESPACE2\",protocol=\"TCP\"} 6\niris_interop_active_outbound_interfaces{id=\"NAMESPACE2\",protocol=\"FILE\"} 1\niris_interop_active_outbound_interfaces_total 12\niris_interop_active_web_api_interfaces{protocol=\"REST/SOAP\"} 5\niris_interop_active_web_api_interfaces{id=\"NAMESPACE3\"} 5\niris_interop_active_web_api_interfaces{id=\"NAMESPACE3\",protocol=\"REST/SOAP\"} 5\niris_interop_active_web_api_interfaces_total 5\niris_interop_inbound_interfaces{protocol=\"TCP\"} 39\niris_interop_inbound_interfaces{id=\"NAMESPACE1\"} 27\niris_interop_inbound_interfaces{id=\"NAMESPACE1\",protocol=\"TCP\"} 27\niris_interop_inbound_interfaces{id=\"NAMESPACE2\"} 12\niris_interop_inbound_interfaces{id=\"NAMESPACE2\",protocol=\"TCP\"} 12\niris_interop_inbound_interfaces_total 39\niris_interop_outbound_interfaces{protocol=\"TCP\"} 23\niris_interop_outbound_interfaces{protocol=\"FILE\"} 12\niris_interop_outbound_interfaces{id=\"NAMESPACE2\"} 54\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",protocol=\"TCP\"} 23\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",protocol=\"FILE\"} 12\niris_interop_outbound_interfaces_total 54\niris_interop_web_api_interfaces{protocol=\"REST/SOAP\"} 31\niris_interop_web_api_interfaces{id=\"NAMESPACE3\"} 31\niris_interop_web_api_interfaces{id=\"NAMESPACE3\",protocol=\"REST/SOAP\"} 31\niris_interop_web_api_interfaces_total 31"
						}
                    },
                    "400": {
                        "description": "Invalid start or end format, or end date is before start date.",
						"schema": {
							"type": "string",
                            "example": "ERROR #40103: Invalid value 'example' for start time. Times must be a valid date and optionally time in ODBC format'YYYY-MM-DD[ HH:MM:SS]'."
						}
                    }
                }
            }
        },
        "/historical/interfaces": {
            "get": {
                "description": "Returns information about all inbound, outbound, and web API interfaces for all historical data",
                "operationId": "historicalInterfaces",
                "parameters": [ 
                    {"$ref": "#/parameters/startmonth"},
                    {"$ref": "#/parameters/endmonth"},
                    {"$ref": "#/parameters/namespace"}
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_inbound_interfaces{month=\"2024-07\",protocol=\"TCP\"} 14\niris_interop_inbound_interfaces{month=\"2024-08\",protocol=\"TCP\"} 11\niris_interop_inbound_interfaces{id=\"NAMESPACE1\",month=\"2024-07\"} 10\niris_interop_inbound_interfaces{id=\"NAMESPACE1\",month=\"2024-07\",protocol=\"TCP\"} 10\niris_interop_inbound_interfaces{id=\"NAMESPACE1\",month=\"2024-08\"} 8\niris_interop_inbound_interfaces{id=\"NAMESPACE1\",month=\"2024-08\",protocol=\"TCP\"} 8\niris_interop_inbound_interfaces{id=\"NAMESPACE2\",month=\"2024-07\"} 4\niris_interop_inbound_interfaces{id=\"NAMESPACE2\",month=\"2024-07\",protocol=\"TCP\"} 4\niris_interop_inbound_interfaces{id=\"NAMESPACE2\",month=\"2024-08\"} 3\niris_interop_inbound_interfaces{id=\"NAMESPACE2\",month=\"2024-08\",protocol=\"TCP\"} 3\niris_interop_inbound_interfaces_total{month=\"2024-07\"} 14\niris_interop_inbound_interfaces_total{month=\"2024-08\"} 11\niris_interop_outbound_interfaces{month=\"2024-07\",protocol=\"TCP\"} 9\niris_interop_outbound_interfaces{month=\"2024-07\",protocol=\"FILE\"} 5\niris_interop_outbound_interfaces{month=\"2024-08\",protocol=\"TCP\"} 8\niris_interop_outbound_interfaces{month=\"2024-08\",protocol=\"FILE\"} 3\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",month=\"2024-07\"} 23\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",month=\"2024-07\",protocol=\"TCP\"} 9\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",month=\"2024-07\",protocol=\"FILE\"} 5\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",month=\"2024-08\"} 19\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",month=\"2024-08\",protocol=\"TCP\"} 8\niris_interop_outbound_interfaces{id=\"NAMESPACE2\",month=\"2024-08\",protocol=\"FILE\"} 3\niris_interop_outbound_interfaces_total{month=\"2024-07\"} 23\niris_interop_outbound_interfaces_total{month=\"2024-08\"} 19\niris_interop_web_api_interfaces{month=\"2024-07\",protocol=\"REST/SOAP\"} 12\niris_interop_web_api_interfaces{month=\"2024-08\",protocol=\"REST/SOAP\"} 9\niris_interop_web_api_interfaces{id=\"NAMESPACE3\",month=\"2024-07\"} 12\niris_interop_web_api_interfaces{id=\"NAMESPACE3\",month=\"2024-07\",protocol=\"REST/SOAP\"} 12\niris_interop_web_api_interfaces{id=\"NAMESPACE3\",month=\"2024-08\"} 9\niris_interop_web_api_interfaces{id=\"NAMESPACE3\",month=\"2024-08\",protocol=\"REST/SOAP\"} 9\niris_interop_web_api_interfaces_total{month=\"2024-07\"} 12\niris_interop_web_api_interfaces_total{month=\"2024-08\"} 9"
						}
                    },
                    "400": {
                        "description": "Invalid startmonth or endmonth format, or endmonth is before startmonth.",
						"schema": {
							"type": "string",
                            "example": "ERROR #40113: Invalid month 'example'. Month must be of format 'YYYY-MM'."
						}
                    }
                }
            }
        },
        "/current/databaseimpact": {
            "get": {
                "description": "Returns estimated size of data (in MB) created for each database for all currently active data.",
                "operationId": "currentDatabaseImpact",
                "parameters": [ 
                    {"$ref": "#/parameters/start"},
                    {"$ref": "#/parameters/end"},
                    {"$ref": "#/parameters/database"}
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_database_impact{id=\"DATABASE\"} 100"
						}
                    },
                    "400": {
                        "description": "Invalid start or end format, or end date is before start date.",
						"schema": {
							"type": "string",
                            "example": "ERROR #40103: Invalid value 'example' for start time. Times must be a valid date and optionally time in ODBC format'YYYY-MM-DD[ HH:MM:SS]'."
						}
                    }
                }
            }
        },
        "/historical/databaseimpact": {
            "get": {
                "description": "Returns estimated size of data (in MB) created for each database for all historical data.",
                "operationId": "historicalDatabaseImpact",
                "parameters": [ 
                    {"$ref": "#/parameters/startmonth"},
                    {"$ref": "#/parameters/endmonth"},
                    {"$ref": "#/parameters/database"}
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_database_impact{id=\"DATABASE\",month=\"2024-07\"} 5418966\niris_interop_database_impact{id=\"DATABASE\",month=\"2024-08\"} 5925089"
						}
                    },
                    "400": {
                        "description": "Invalid startmonth or endmonth format, or endmonth is before startmonth.",
						"schema": {
							"type": "string",
                            "example": "ERROR #40113: Invalid month 'example'. Month must be of format 'YYYY-MM'."
						}
                    }
                }
            }
        },
        "/current/volume": {
            "get": {
                "description": "Returns the total inbound and outbound volume metrics per namespace for all currently active data.",
                "operationId": "currentVolume",
                "parameters": [ 
                    {"$ref": "#/parameters/startDate"},
                    {"$ref": "#/parameters/endDate"},
                    {"$ref": "#/parameters/namespace"}
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_volume{id=\"NAMESPACE\",type=\"Inbound\"} 100\niris_interop_volume{id=\"NAMESPACE\",type=\"Outbound\"} 200"
						}
                    },
                    "400": {
                        "description": "Invalid startDate or startDate format, or endDate is before startDate.",
						"schema": {
							"type": "string",
                            "example": "ERROR #40103: Invalid value 'example' for start time. Times must be a valid date and optionally time in ODBC format'YYYY-MM-DD[ HH:MM:SS]'."
						}
                    }
                }
            }
        },
        "/historical/volume": {
            "get": {
                "description": "Returns the total inbound and outbound volume metrics per namespace for all historical data.",
                "operationId": "historicalVolume",
                "parameters": [ 
                    {"$ref": "#/parameters/startmonth"},
                    {"$ref": "#/parameters/endmonth"},
                    {"$ref": "#/parameters/namespace"}
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_volume{id=\"NAMESPACE1\",month=\"2024-07\",type=\"Inbound\"} 450\niris_interop_volume{id=\"NAMESPACE1\",month=\"2024-07\",type=\"Outbound\"} 100\niris_interop_volume{id=\"NAMESPACE1\",month=\"2024-08\",type=\"Inbound\"} 50\niris_interop_volume{id=\"NAMESPACE1\",month=\"2024-08\",type=\"Outbound\"} 20\niris_interop_volume{id=\"NAMESPACE2\",month=\"2024-07\",type=\"Inbound\"} 10\niris_interop_volume{id=\"NAMESPACE2\",month=\"2024-07\",type=\"Outbound\"} 10\niris_interop_volume{id=\"NAMESPACE2\",month=\"2024-08\",type=\"Inbound\"} 10\niris_interop_volume{id=\"NAMESPACE2\",month=\"2024-08\",type=\"Outbound\"} 10\niris_interop_volume_total{month=\"2024-07\",type=\"Inbound\"} 460\niris_interop_volume_total{month=\"2024-07\",type=\"Outbound\"} 110\niris_interop_volume_total{month=\"2024-08\",type=\"Inbound\"} 60\niris_interop_volume_total{month=\"2024-08\",type=\"Outbound\"} 30\n"
						}
                    },
                    "400": {
                        "description": "Invalid startmonth or endmonth format, or endmonth is before startmonth.",
						"schema": {
							"type": "string",
                            "example": "ERROR #40113: Invalid month 'example'. Month must be of format 'YYYY-MM'."
						}
                    }
                }
            }
        },
        "/current/range": {
            "get": {
                "description": "Returns the date of both the earliest and most recent currently active records. If no metrics data exist, an empty response is returned.",
                "operationId": "currentRange",
                "parameters": [ 
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_start 2024-10-01\niris_interop_end 2024-12-01"
						}
                    }
                }
            }
        },
        "/historical/range": {
            "get": {
                "description": "Returns the date of both the earliest and most recent historical data. If no metrics data exist, an empty response is returned.",
                "operationId": "historicalRange",
                "parameters": [ 
                ],
                "responses": {
                    "200": {
                        "description": "OK",
						"schema": {
							"type": "string",
                            "example": "iris_interop_start 2024-10-01\niris_interop_end 2024-12-01"
						}
                    }
                }
            }
        }
    },
    "parameters": {
        "start": {
            "name": "start",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data since start (inclusive) is included. The start parameter is a date or datetime in UTC that must specified in ODBC format YYYY-MM-DD[ HH:MM:SS]. If only YYYY-MM-DD is specified, HH:MM:SS is assumed to be 00:00:00."
        },
        "end": {
            "name": "end",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data until end (inclusive) is included. The end parameter is a date or datetime in UTC that must specified in ODBC format YYYY-MM-DD[ HH:MM:SS]. If only YYYY-MM-DD is specified, HH:MM:SS is assumed to be 23:59:59."
        },
        "startDate": {
            "name": "startDate",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data since startDate (inclusive) is included. The startDate parameter is a date in UTC that must specified in ODBC format YYYY-MM-DD."
        },
        "endDate": {
            "name": "endDate",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data until endDate (inclusive) is included. The endDate parameter is a date in UTC that must specified in ODBC format YYYY-MM-DD."
        },
        "startmonth": {
            "name": "startmonth",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data since startmonth (inclusive) is included. The startmonth parameter is string of format YYYY-MM. Note that all times and dates are in UTC."
        },
        "endmonth": {
            "name": "endmonth",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data until endmonth (inclusive) is included. The endmonth parameter is string of format YYYY-MM. Note that all times and dates are in UTC."
        },
        "namespace": {
            "name": "namespace",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data related to that namespace is included."
        },
        "database": {
            "name": "database",
            "in": "query",
            "type": "string",
            "required": false,
            "description": "If specified, only data related to that database is included."
        }
    },
    "definitions": {
	}
}
}

}
