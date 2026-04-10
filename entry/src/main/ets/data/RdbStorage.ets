import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';



import { temperature_control_device, Device, farmland } from '../tool/classes';


// 定义数据库操作类
export class FarmlandDatabase {
  private context: Context; // 这里假设你有合适的 Context 对象
  private rdbStore: relationalStore.RdbStore | null = null;
  private readonly DB_NAME = 'farmland.db';
  private readonly TABLE_NAME = 'Farmland';


  constructor(context: Context) {
    this.context = context;
    this.initDatabase();
  }

  // 初始化数据库
  private async initDatabase() {

    try {
      // 将第23行的 globalThis.getContext() 改为:
      const context = getContext(this) as common.UIAbilityContext;
      this.rdbStore = await relationalStore.getRdbStore(context, {
        name: 'farmland_store.db',
        securityLevel: relationalStore.SecurityLevel.S1
      });
      // 创建 Device 表
      this.rdbStore.executeSql('CREATE TABLE IF NOT EXISTS Device (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, switch INTEGER,farmlandId INTEGER,type_id INTEGER UNIQUE)');
      // 创建 Farmland 表
      this.rdbStore.executeSql('CREATE TABLE IF NOT EXISTS Farmland (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)');
      console.log('Database initialized and table created.');
    } catch (err) {
      console.error(`Failed to initialize database: ${err.message}`);
    }
  }

  // 插入书籍数据
  async insertFarmland(farmland: farmland) {
    try {
      const farmlandId = await this.rdbStore?.insert(this.TABLE_NAME, {
        'name': farmland.name
      });

      for (const device of farmland.device_s) {
        const deviceId = await this.rdbStore?.insert('Device', {
          'name': device.name,
          'switch': device.switch,
          'farmlandId': farmlandId,
          'type_id': device.type_id
        })
      }

      return 1
    } catch (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        console.error(`Failed to insert farmland: Name ${farmland.name} already exists.`);
        return -1
      } else {
        console.error(`Failed to insert farmland: ${err.message}`);
        return -1
      }
    }
  }

  async insertFuByFarmlandId(farmlandId: number, f_name: string, type_id: number) {
    try {
      const deviceId = await this.rdbStore?.insert('Device', {
        'name': f_name + ':' + farmlandId,
        'switch': 0,
        'farmlandId': farmlandId,
        'type_id': type_id

      });

      console.log('Farmland inserted successfully.');
      return 1
    } catch (err) {
      if (err.message.includes('UNIQUE constraint failed')) {
        console.error(`Failed to insert farmlandsdevice: Name ${f_name} already exists.`);
        return -1
      } else {
        console.error(`Failed to insert device: ${err.message}`);
        return -1
      }
    }
  }

  // 查询所有农田数据
  async getAllFarmlands() {

    const farmlands: farmland[] = [];
    const deviceList: Device[] = [];
    const predicates_farmland = new relationalStore.RdbPredicates(this.TABLE_NAME);

    try {
      const resultSet = await this.rdbStore?.query(predicates_farmland);
      console.log('Farmlands queried successfully.');
      if (resultSet?.rowCount == 0) {
        return []
      }

      while (resultSet?.goToNextRow()) {
        const farmland_id = resultSet.getLong(0);
        console.log('Farmland,,,deviceId:' + JSON.stringify(farmland_id))
        //获取农田名字
        const farmland_name = resultSet.getString(1);

        //获取农田工具组
        const devices: Device[] = []
        const DeviceResultSet = await this.rdbStore?.query(
          new relationalStore.RdbPredicates('Device')
            .equalTo('farmlandId', farmland_id),
          ['id', 'name', 'switch', 'farmlandId', 'type_id']
        )
        if (DeviceResultSet?.goToFirstRow()) {
          do {
            const f_id = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('id'))
            const f_name = DeviceResultSet.getString(DeviceResultSet.getColumnIndex('name')).split(":")[0]
            const f_switch = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('switch'))
            const f_type = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('type_id'))
            devices.push(new Device(f_name, f_switch, f_type))
            console.log("Farmland" + f_name + f_switch)
          } while (DeviceResultSet.goToNextRow())
        }
        DeviceResultSet?.close()
        farmlands.push(new farmland(farmland_name, devices))

      }
      resultSet?.close();
      console.log('Farmland,Farmlands:' + JSON.stringify(farmlands))
      return farmlands;


    } catch (err) {
      console.error(`Failed to query books: ${err.message}`);

      return farmlands
    }
  }
  async getAllDevice_num() {

    let Num:number = 0


    const predicates_farmland = new relationalStore.RdbPredicates(this.TABLE_NAME);

    try {
      const resultSet = await this.rdbStore?.query(predicates_farmland);
      console.log('Farmlands queried successfully.');


      while (resultSet?.goToNextRow()) {
        const farmland_id = resultSet.getLong(0);
        console.log('Farmland,,,deviceId:' + JSON.stringify(farmland_id))
        const DeviceResultSet = await this.rdbStore?.query(
          new relationalStore.RdbPredicates('Device')
            .equalTo('farmlandId', farmland_id),
          ['id', 'name', 'switch', 'farmlandId', 'type_id']
        )

        if (DeviceResultSet?.goToFirstRow()) {
          do {

            Num++
          } while (DeviceResultSet.goToNextRow())
        }
        DeviceResultSet?.close()
      }
      resultSet?.close();
      return Num


    } catch (err) {
      console.error(`Failed to query books: ${err.message}`);
      return Num
    }
  }
  async getAllDevice() {


    const Fs:Device[] = []

    const predicates_farmland = new relationalStore.RdbPredicates(this.TABLE_NAME);

    try {
      const resultSet = await this.rdbStore?.query(predicates_farmland);
      console.log('Farmlands queried successfully.');


      while (resultSet?.goToNextRow()) {
        const farmland_id = resultSet.getLong(0);
        console.log('Farmland,,,deviceId:' + JSON.stringify(farmland_id))
        const DeviceResultSet = await this.rdbStore?.query(
          new relationalStore.RdbPredicates('Device')
            .equalTo('farmlandId', farmland_id),
          ['id', 'name', 'switch', 'farmlandId', 'type_id']
        )

        if (DeviceResultSet?.goToFirstRow()) {
          do {
            const f_id = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('id'))
            const f_name = DeviceResultSet.getString(DeviceResultSet.getColumnIndex('name')).split(":")[0]
            const f_switch = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('switch'))
            const f_type = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('type_id'))
            Fs.push(new Device(f_name, f_switch, f_type))

          } while (DeviceResultSet.goToNextRow())
        }
        DeviceResultSet?.close()
      }
      resultSet?.close();
      return Fs


    } catch (err) {
      console.error(`Failed to query books: ${err.message}`);
      return Fs
    }
  }

  async getFarmlandById(id: number) {
    let _farmland: farmland = new farmland('', [])
    const FarmlandResultSet =
      await this.rdbStore?.query(new relationalStore.RdbPredicates(this.TABLE_NAME).equalTo('id', id), ['id', 'name'])
    while (FarmlandResultSet?.goToNextRow()) {
      const farmland_id = FarmlandResultSet.getLong(0);
      console.log('Farmland,,,deviceId:' + JSON.stringify(farmland_id))
      //获取农田名字
      const farmland_name = FarmlandResultSet.getString(1);

      //获取农田工具组
      const devices: Device[] = []
      const DeviceResultSet = await this.rdbStore?.query(
        new relationalStore.RdbPredicates('Device')
          .equalTo('farmlandId', farmland_id),
        ['id', 'name', 'switch', 'farmlandId','type_id']
      )
      if (DeviceResultSet?.goToFirstRow()) {
        do {
          const f_id = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('id'))
          const f_name = DeviceResultSet.getString(DeviceResultSet.getColumnIndex('name')).split(":")[0]
          const f_switch = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('switch'))
          const f_type = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('type_id'))
          devices.push(new Device(f_name, f_switch, f_type))
          console.log("Farmland" + f_name + f_switch)
        } while (DeviceResultSet.goToNextRow())
      }
      DeviceResultSet?.close()
      _farmland = new farmland(farmland_name, devices)

    }
    FarmlandResultSet?.close();
    return _farmland
  }

  async getDeviceByR_Id(id: number) {

    console.log("Q_Farmland is  ..ing1")
    const devices: Device[] = []
    const DeviceResultSet = await this.rdbStore?.query(
      new relationalStore.RdbPredicates('Device')
        .equalTo('farmlandId', id),
      ['id', 'name', 'switch', 'farmlandId','type_id']
    )
    console.log("Q_Farmland is  ..ing2")
    if (DeviceResultSet?.goToNextRow()) {
      DeviceResultSet.goToFirstRow()
      do{
        const f_id = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('id'))
        const f_name = DeviceResultSet.getString(DeviceResultSet.getColumnIndex('name')).split(":")[0]
        const f_switch = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('switch'))
        const f_type = DeviceResultSet.getLong(DeviceResultSet.getColumnIndex('type_id'))
        devices.push(new Device(f_name, f_switch, f_type))
        console.log("Farmland" + f_name + f_switch)
      }while (DeviceResultSet.goToNextRow())
    } else {
      console.log("Q_Farmland is fail")
    }
    console.log("Q_Farmland is  ..ing3")
    DeviceResultSet?.close()
    console.log("Q_Farmland is" + JSON.stringify(devices))


    return devices
  }

  async getFarmlandsIdByName(name: string): Promise<number> {

    console.log('farmlandwwwwww ing 1')
    const _farmland: farmland = new farmland('', []);
    const deviceList: Device[] = [];
    const predicates_farmland = new relationalStore.RdbPredicates(this.TABLE_NAME);
    console.log('farmlandwwwwww ing 2')
    try {
      const resultSet = await this.rdbStore?.query(predicates_farmland);
      console.log('Farmlands queried successfully.');


      while (resultSet?.goToNextRow()) {
        const farmland_id = resultSet.getLong(0);
        console.log('Farmland,,,deviceId:' + JSON.stringify(farmland_id))
        //获取农田名字
        const farmland_name = resultSet.getString(1);

        if (farmland_name == name) {
          return farmland_id
        }
      }
      resultSet?.close();
      console.log('Farmland,Farmlands:' + JSON.stringify(_farmland))
      return -1;


    } catch (err) {
      console.error(`Failed to query books: ${err.message}`);

      return -1
    }
  }


  async renameDeviceBy_RIdAndName(r_id: number, name: string, new_name: string) {
    if (!this.rdbStore) {
      console.error('Database is not initialized.');
      return 0;
    }
    try {

      const sql = 'UPDATE Device SET name = ? WHERE farmlandId =? AND name =?';
      const params = [new_name + ':' + r_id, r_id, name + ':' + r_id];
      await this.rdbStore.executeSql(sql, params);
      console.log("Farmland update success:" + new_name + ':' + r_id, r_id, name + ':' + r_id)

      return 1
    } catch (err) {
      console.error(`Failed to delete device: ${err.message}`);
      return -1
    }


  }

  async deleteFarmlandByName( name: string) {
    if (!this.rdbStore) {
      console.error('Database is not initialized.');
      return;
    }
    try {
      const farmlandId = await this.getFarmlandsIdByName(name)
      //先删除农田ID对应的工具
      const sql1 = 'DELETE FROM Device WHERE farmlandId =?';
      const params = [farmlandId];
      await this.rdbStore.executeSql(sql1, params);
      //在删除农田
      const sql2 = 'DELETE FROM Farmland WHERE id =?'
      await this.rdbStore.executeSql(sql2,params)

      console.log(`farmland with name ${name} deleted successfully.`);
    } catch (err) {
      console.error(`Failed to delete device: ${err.message}`);
    }
  }

  async deleteDeviceByFarmlandIdAndName(farmlandId: number, name: string) {
    if (!this.rdbStore) {
      console.error('Database is not initialized.');
      return;
    }
    try {
      const sql = 'DELETE FROM Device WHERE farmlandId =? AND name =?';
      const params = [farmlandId, name + ':' + farmlandId];
      await this.rdbStore.executeSql(sql, params);
      console.log(`Device with farmlandId ${farmlandId} and name ${name} deleted successfully.`);
    } catch (err) {
      console.error(`Failed to delete device: ${err.message}`);
    }
  }

  async clear() {
    try {
      if (!this.rdbStore) {
        console.error('Database is not initialized.');
        return;
      }
      // 清空 Device 表中的数据
      await this.rdbStore.executeSql('DELETE FROM Device');
      // 清空 Farmland 表中的数据
      await this.rdbStore.executeSql('DELETE FROM Farmland');
      console.log('All data in the tables has been cleared.');
    } catch (err) {
      console.error(`Failed to clear data: ${err.message}`);
    }
  }

  // 根据 ID 查询书籍数据

}


