import relationalStore from '@ohos.data.relationalStore';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;

export function startRuleService(context: any, store: relationalStore.RdbStore) {
  setInterval(async () => {
    try {
      const rulesRs = await store.query(
        new relationalStore.RdbPredicates('Rule').equalTo('enabled', 1),
        ['id','zone_id','sensor_metric','operator','threshold_low','threshold_high','action','target_device_id','duration_sec','priority']
      );
      if (rulesRs?.goToFirstRow()) {
        do {
          const ci = (c: string) => rulesRs.getColumnIndex(c);
          const metric = rulesRs.getString(ci('sensor_metric'));
          const operator = rulesRs.getString(ci('operator'));
          const low = Number(rulesRs.getString(ci('threshold_low')));
          const high = Number(rulesRs.getString(ci('threshold_high')));
          const action = rulesRs.getString(ci('action'));
          const targetId = rulesRs.getLong(ci('target_device_id'));
          const durationSec = rulesRs.getLong(ci('duration_sec'));

          const preds = new relationalStore.RdbPredicates('SensorReading')
            .equalTo('metric', metric)
            .orderByDesc('ts')
            .limitAs(1);
          const readRs = await store.query(preds, ['value','ts']);
          let val: number | null = null;
          if (readRs?.goToFirstRow()) {
            const raw = readRs.getString(readRs.getColumnIndex('value'));
            const n = Number(raw);
            val = Number.isNaN(n) ? null : n;
          }
          readRs?.close();

          if (shouldTrigger(operator, val, low, high)) {
            await triggerAction(action, targetId, durationSec);
            hilog.info(DOMAIN, 'rule', '%{public}s', 'triggered');
          }
        } while (rulesRs.goToNextRow());
      }
      rulesRs?.close();
    } catch (e) {
      hilog.error(DOMAIN, 'rule', '%{public}s', JSON.stringify(e));
    }
  }, 10000);
}

function shouldTrigger(op: string, val: number | null, low?: number, high?: number): boolean {
  if (val === null || val === undefined) return false;
  switch (op) {
    case '<': return val < Number(low);
    case '>': return val > Number(low);
    case '<=': return val <= Number(low);
    case '>=': return val >= Number(low);
    case 'between': return val >= Number(low) && val <= Number(high);
    default: return false;
  }
}

async function triggerAction(action: string, deviceId: number, durationSec: number) {}