export interface ConnectionConfig {
    server: string;
    port: number;
    pathPrefix?: string;
    username: string;
    password: string;
    https?: boolean;
    namespace: string;
}
export interface SqlExecutionResult {
    success: boolean;
    resultSet?: any[];
    error?: string;
    sqlCode?: number;
    message?: string;
}
export interface ObjectScriptExecutionResult {
    success: boolean;
    result?: any;
    error?: string;
    output?: string;
    executionTime?: number;
}
