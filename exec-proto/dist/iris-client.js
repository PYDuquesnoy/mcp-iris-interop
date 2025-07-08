"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.IrisClient = void 0;
const axios_1 = __importDefault(require("axios"));
class IrisClient {
    constructor(config) {
        this.config = config;
        this.axiosInstance = axios_1.default.create({
            baseURL: this.buildBaseUrl(),
            auth: {
                username: config.username,
                password: config.password
            },
            timeout: 30000,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            }
        });
    }
    buildBaseUrl() {
        const protocol = this.config.https ? 'https' : 'http';
        const prefix = this.config.pathPrefix ? `/${this.config.pathPrefix}` : '';
        return `${protocol}://${this.config.server}:${this.config.port}${prefix}`;
    }
    getConnectionInfo() {
        return `${this.buildBaseUrl()} (namespace: ${this.config.namespace})`;
    }
    /**
     * Execute SQL statement directly
     */
    async executeSql(sql) {
        try {
            const response = await this.axiosInstance.post(`/api/atelier/v1/${this.config.namespace}/action/query`, { query: sql });
            if (response.data.status === 'ERROR') {
                return {
                    success: false,
                    error: response.data.console || 'SQL execution failed',
                    sqlCode: response.data.sqlcode
                };
            }
            return {
                success: true,
                resultSet: response.data.result?.content || [],
                message: response.data.console
            };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error occurred'
            };
        }
    }
    /**
     * Execute ObjectScript code via stored procedure
     */
    async executeObjectScript(code) {
        try {
            // Call the stored procedure that executes ObjectScript
            const sql = `CALL ExecProto.ObjectScript_Execute(?)`;
            const response = await this.axiosInstance.post(`/api/atelier/v1/${this.config.namespace}/action/query`, {
                query: sql,
                parameters: [code]
            });
            if (response.data.status === 'ERROR') {
                return {
                    success: false,
                    error: response.data.console || 'ObjectScript execution failed'
                };
            }
            const result = response.data.result?.content?.[0];
            return {
                success: true,
                result: result?.result,
                output: result?.output,
                executionTime: result?.executionTime
            };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error.message : 'Unknown error occurred'
            };
        }
    }
    /**
     * Test connection to IRIS server
     */
    async testConnection() {
        try {
            const response = await this.axiosInstance.get(`/api/atelier/v1/${this.config.namespace}/action/ping`);
            return response.status === 200;
        }
        catch (error) {
            return false;
        }
    }
}
exports.IrisClient = IrisClient;
//# sourceMappingURL=iris-client.js.map