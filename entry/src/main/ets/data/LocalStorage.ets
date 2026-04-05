import { preferences } from '@kit.ArkData';
import { FaultLogger } from '@kit.PerformanceAnalysisKit';


export class LocalStorage{
  dataPreferences: preferences.Preferences | null = null;
  Storage:string = ''
  constructor(S:string) {
    this.Storage = S
  }
  private async getPreferences(){
    if(!this.dataPreferences){
      let dataPreferences = await preferences.getPreferences(globalThis.context,this.Storage)
      this.dataPreferences = dataPreferences
    }
    return this.dataPreferences
  }
  //记录
  public async setDate(date_name:string,data_value:string|boolean|number){
    let preferences = await this.getPreferences()
    let result = await preferences.put(date_name,data_value)
    //长期存储
    preferences.flush((err)=>{
      if(err){
        console.log("local_pre","setData flush fail")
        return
      }
      console.log("local_pre","setData flush success")
    })
    return result
  }
  //读取
  public async getDate(date_name:string){
    let preferences = await this.getPreferences()
    let result = await preferences.get(date_name,false)

    return result
  }
  public async _getDate_(date_name:string):Promise<string>{
    let preferences = await this.getPreferences()
    let result = await preferences.get(date_name,'')

    return result.toString()
  }
  //读取
  public async clare_Date(date_name:string){
    let preferences = await this.getPreferences()
    let result = await preferences.put(date_name,'')
    //长期存储
    preferences.flush((err)=>{
      if(err){
        console.log("local_pre","setData flush fail")
        return
      }
      console.log("local_pre","setData flush success")
    })
    return result
  }

}