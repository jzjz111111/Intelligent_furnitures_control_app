import { http } from '@kit.NetworkKit';

export type HttpResult = {
  code: number;
  headers: Record<string, string>;
  body: string;
  cookies?: string;
};

export class HttpClient {
  private client = http.createHttp();

  async request(
    url: string,
    options: {
      method?: http.RequestMethod;
      headers?: Record<string, string>;
      body?: string;
      connectTimeout?: number;
      readTimeout?: number;
    } = {}
  ): Promise<HttpResult> {
    const res = await this.client.request(url, {
      method: options.method ?? http.RequestMethod.GET,
      header: options.headers ?? {},
      extraData: options.body ?? '',
      connectTimeout: options.connectTimeout ?? 5000,
      readTimeout: options.readTimeout ?? 10000
    });
    const body = typeof res.result === 'string' ? res.result : JSON.stringify(res.result);
    return { code: res.responseCode, headers: (res.header ?? {}) as Record<string,string>, body, cookies: res.cookies ?? '' };
  }

  async getToken(iamEndpoint: string, domain: string, username: string, password: string): Promise<{ token: string; code: number; body: string; }> {
    const url = `${iamEndpoint}/v3/auth/tokens`;
    const payload = JSON.stringify({
      auth: {
        identity: { methods: ['password'], password: { user: { name: username, domain: { name: domain }, password } } },
        scope: { domain: { name: domain } }
      }
    });
    const res = await this.client.request(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: payload
    });
    const body = typeof res.result === 'string' ? res.result : JSON.stringify(res.result);
    const h = res.header || {};
    const token = (h['X-Subject-Token'] as string) || (h['x-subject-token'] as string) || '';
    return { token, code: res.responseCode, body };
  }
}