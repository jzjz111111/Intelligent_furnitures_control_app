import relationalStore from '@ohos.data.relationalStore';
import { openAgriDb, runInitSql } from '../common/db';
import { startRuleService } from '../service/ruleService';
import { HttpClient } from '../network/httpRequest';
import { LocalStorage } from '../storage/localStorage';

export async function bootstrap(context: any): Promise<void> {
  const store: relationalStore.RdbStore = await openAgriDb(context);
  await runInitSql(store, context);
  startRuleService(context, store);

  try {
    const arr: ArrayBuffer = context.resourceManager.getRawFileContent('cloud.json');
    const text = String.fromCharCode.apply(null, Array.from(new Uint8Array(arr)) as any);
    const cfg = JSON.parse(text);
    const httpClient = new HttpClient();
    const { token } = await httpClient.getToken(cfg.iamEndpoint, cfg.domain, cfg.username, cfg.password);
    const ls = new LocalStorage('agri');
    await ls.set('token', token);
  } catch (_) {}

  AppStorage.setOrCreate('rdb', store);
  AppStorage.setOrCreate('ctx', context);
}