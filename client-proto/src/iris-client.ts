import axios, { AxiosInstance, AxiosResponse } from 'axios';
import https from 'https';
import { ConnectionConfig, AtelierResponse, ServerInfo, Namespace } from './types';

export class IrisClient {
  private config: ConnectionConfig;
  private axios: AxiosInstance;
  private cookies: string[] = [];
  private authenticated: boolean = false;

  constructor(config: ConnectionConfig) {
    this.config = config;
    
    // Create axios instance with base configuration
    this.axios = axios.create({
      baseURL: this.buildBaseUrl(),
      timeout: 30000,
      headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache'
      },
      httpsAgent: new https.Agent({
        rejectUnauthorized: false // For development - should be configurable in production
      }),
      validateStatus: (status) => status < 504
    });

    // Add request interceptor for authentication
    this.axios.interceptors.request.use((config) => {
      // Add cookies if we have them
      if (this.cookies.length > 0) {
        config.headers.Cookie = this.cookies.join('; ');
      }
      
      // Add basic auth header
      if (this.config.username && this.config.password) {
        const auth = Buffer.from(`${this.config.username}:${this.config.password}`).toString('base64');
        config.headers.Authorization = `Basic ${auth}`;
      }
      
      return config;
    });

    // Add response interceptor to handle cookies
    this.axios.interceptors.response.use((response) => {
      // Update cookies from response
      if (response.headers['set-cookie']) {
        this.updateCookies(response.headers['set-cookie']);
      }
      return response;
    });
  }

  private buildBaseUrl(): string {
    const protocol = this.config.https ? 'https' : 'http';
    const pathPrefix = this.config.pathPrefix || '';
    return `${protocol}://${this.config.server}:${this.config.port}${pathPrefix}/api/atelier`;
  }

  private updateCookies(newCookies: string[]): void {
    newCookies.forEach((cookie) => {
      const [cookieName] = cookie.split('=');
      const index = this.cookies.findIndex((el) => el.startsWith(cookieName));
      if (index >= 0) {
        this.cookies[index] = cookie;
      } else {
        this.cookies.push(cookie);
      }
    });
  }

  private async request<T>(
    method: string,
    path: string,
    data?: any,
    params?: any,
    headers?: any
  ): Promise<AtelierResponse<T>> {
    try {
      const response: AxiosResponse = await this.axios.request({
        method,
        url: path,
        data,
        params,
        headers: {
          'Content-Type': data ? 'application/json' : undefined,
          ...headers
        }
      });

      // Handle authentication errors
      if (response.status === 401) {
        this.authenticated = false;
        throw new Error('Authentication failed. Please check your credentials.');
      }

      // Handle server unavailable
      if (response.status === 503) {
        throw new Error('Server unavailable. Check license usage.');
      }

      // Handle successful responses
      if (response.status >= 200 && response.status < 300) {
        this.authenticated = true;
        return response.data as AtelierResponse<T>;
      }

      // Handle other errors
      const errorData = response.data as AtelierResponse;
      throw new Error(errorData.status?.summary || `HTTP ${response.status}: ${response.statusText}`);

    } catch (error) {
      if (axios.isAxiosError(error)) {
        if (error.code === 'ECONNREFUSED') {
          throw new Error(`Connection refused. Is IRIS server running on ${this.config.server}:${this.config.port}?`);
        }
        if (error.code === 'ENOTFOUND') {
          throw new Error(`Host not found: ${this.config.server}`);
        }
      }
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * Test connection and authenticate
   */
  async connect(): Promise<boolean> {
    try {
      await this.request('HEAD', '/');
      return this.authenticated;
    } catch (error) {
      console.error('Connection failed:', error instanceof Error ? error.message : String(error));
      return false;
    }
  }

  /**
   * Get server information including available namespaces
   */
  async getServerInfo(): Promise<ServerInfo> {
    const response = await this.request<{ content: ServerInfo }>('GET', '/');
    return response.result.content;
  }

  /**
   * Get list of all namespaces
   */
  async getNamespaces(): Promise<string[]> {
    const serverInfo = await this.getServerInfo();
    return serverInfo.namespaces;
  }

  /**
   * Get information about a specific namespace
   */
  async getNamespaceInfo(namespace?: string): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    return this.request('GET', `/v1/${ns}`);
  }

  /**
   * Get list of documents in a namespace
   */
  async getDocumentList(
    namespace?: string,
    category: string = '*',
    type: string = '*',
    filter?: string,
    includeGenerated: boolean = false
  ): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    const params: any = {
      generated: includeGenerated ? '1' : '0'
    };
    
    if (filter) {
      params.filter = filter;
    }

    return this.request('GET', `/v1/${ns}/docnames/${category}/${type}`, null, params);
  }

  /**
   * Get document content
   */
  async getDocument(documentName: string, namespace?: string): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    const encodedDocName = encodeURIComponent(documentName);
    return this.request('GET', `/v1/${ns}/doc/${encodedDocName}`);
  }

  /**
   * Compile documents
   */
  async compileDocuments(
    documents: string[],
    namespace?: string,
    flags: string = 'cuk'
  ): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    const params = {
      flags,
      source: false
    };
    
    return this.request('POST', `/v1/${ns}/action/compile`, documents, params);
  }

  /**
   * Execute SQL query
   */
  async executeQuery(query: string, parameters: string[] = [], namespace?: string): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    const body = {
      query,
      parameters
    };
    
    return this.request('POST', `/v1/${ns}/action/query`, body);
  }

  /**
   * Get connection info string
   */
  getConnectionInfo(): string {
    return `${this.config.server}:${this.config.port}[${this.config.namespace || 'USER'}]`;
  }

  /**
   * Check if client is authenticated
   */
  isAuthenticated(): boolean {
    return this.authenticated;
  }

  // ===== STEP 4: CLASS MANAGEMENT FUNCTIONALITY =====

  /**
   * Get list of classes in a namespace
   */
  async getClasses(namespace?: string, filter?: string): Promise<AtelierResponse> {
    return this.getDocumentList(namespace, '*', 'CLS', filter);
  }

  /**
   * Get list of packages in a namespace
   */
  async getPackages(namespace?: string): Promise<string[]> {
    const classes = await this.getClasses(namespace);
    const packages = new Set<string>();
    
    if (classes.result?.content) {
      for (const cls of classes.result.content) {
        const className = cls.name || '';
        const lastDot = className.lastIndexOf('.');
        if (lastDot > 0) {
          const packageName = className.substring(0, lastDot);
          packages.add(packageName);
        }
      }
    }
    
    return Array.from(packages).sort();
  }

  /**
   * Upload (save) a class to IRIS
   */
  async uploadClass(
    className: string,
    content: string[],
    namespace?: string,
    overwrite: boolean = true
  ): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    const document = {
      enc: false,
      content: content
    };
    
    const method = overwrite ? 'PUT' : 'POST';
    const encodedClassName = encodeURIComponent(className);
    return this.request(method, `/v1/${ns}/doc/${encodedClassName}`, document);
  }

  /**
   * Download a class from IRIS
   */
  async downloadClass(className: string, namespace?: string): Promise<AtelierResponse> {
    return this.getDocument(className, namespace);
  }

  /**
   * Download all classes in a package
   */
  async downloadPackage(packageName: string, namespace?: string): Promise<AtelierResponse[]> {
    const classes = await this.getClasses(namespace, `${packageName}.*`);
    const results: AtelierResponse[] = [];
    
    if (classes.result?.content) {
      for (const cls of classes.result.content) {
        try {
          const classContent = await this.downloadClass(cls.name, namespace);
          results.push(classContent);
        } catch (error) {
          console.warn(`Failed to download class ${cls.name}:`, error instanceof Error ? error.message : String(error));
        }
      }
    }
    
    return results;
  }

  /**
   * Upload and compile a class
   */
  async uploadAndCompileClass(
    className: string,
    content: string[],
    namespace?: string,
    flags: string = 'cuk'
  ): Promise<{ upload: AtelierResponse; compile: AtelierResponse }> {
    const upload = await this.uploadClass(className, content, namespace, true);
    const compile = await this.compileDocuments([className], namespace, flags);
    
    return { upload, compile };
  }

  /**
   * Delete a class from IRIS
   */
  async deleteClass(className: string, namespace?: string): Promise<AtelierResponse> {
    const ns = namespace || this.config.namespace || 'USER';
    const encodedClassName = encodeURIComponent(className);
    return this.request('DELETE', `/v1/${ns}/doc/${encodedClassName}`);
  }

  /**
   * Check if a class exists
   */
  async classExists(className: string, namespace?: string): Promise<boolean> {
    try {
      const ns = namespace || this.config.namespace || 'USER';
      const encodedClassName = encodeURIComponent(className);
      const response = await this.request('HEAD', `/v1/${ns}/doc/${encodedClassName}`);
      return true;
    } catch (error) {
      return false;
    }
  }
}