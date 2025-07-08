import { ConnectionConfig, SqlExecutionResult, ObjectScriptExecutionResult } from './types';
export declare class IrisClient {
    private axiosInstance;
    private config;
    constructor(config: ConnectionConfig);
    private buildBaseUrl;
    getConnectionInfo(): string;
    /**
     * Execute SQL statement directly
     */
    executeSql(sql: string): Promise<SqlExecutionResult>;
    /**
     * Execute ObjectScript code via stored procedure
     */
    executeObjectScript(code: string): Promise<ObjectScriptExecutionResult>;
    /**
     * Test connection to IRIS server
     */
    testConnection(): Promise<boolean>;
}
