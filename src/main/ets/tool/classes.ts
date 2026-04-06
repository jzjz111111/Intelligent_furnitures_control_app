export class Furniture {
  name: string;
  switch: number;      // 0/1
  type_id: number;

  constructor(name: string, sw: number, type_id: number) {
    this.name = name;
    this.switch = sw;
    this.type_id = type_id;
  }
}

export class room {
  name: string;
  furniture_s: Furniture[];
  location?: string;
  note?: string;

  constructor(name: string, furniture_s: Furniture[], location?: string, note?: string) {
    this.name = name;
    this.furniture_s = furniture_s;
    this.location = location;
    this.note = note;
  }
}