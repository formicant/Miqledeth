; https://autohotkey.com/boards/viewtopic.php?t=3786


; Case-sensitive dictionary
class Dictionary
{
  __New(p*)
  {
    this.Insert("_", ComObjCreate("Scripting.Dictionary"))
    Loop % p.MaxIndex()//2
      this[p[A_Index*2-1]] := p[A_Index*2]
  }

  __Call(m, p*)
  {
    if m in % "
    (LTrim Join,
    Add
    Exists
    Item,Items
    Key,Keys
    Remove,RemoveAll
    )"
      return (this._)[m](p*)
  }

  __Set(k, v, p*)
  {
    if (k = "base" || k = "__Class")
      goto bypass_set
    else if (k == "CompareMode")
      return this._[k] := v
    else if this.Exists(k)
      return this._.Item(k) := v
    else return this.Add(k, v)
    bypass_set:
  }

  __Get(k, p*)
  {
    if (k = "base" || k = "__Class")
      goto bypass_get
    else if k in Count,CompareMode
      return this._[k]
    else if this.Exists(k)
      return this.Item(k)
    bypass_get:
  }

  _NewEnum()
  {
    return new this.base.Enum(this)
  }

  class Enum
  {
    __New(obj)
    {
      this.obj := obj
      this.enum := obj._._NewEnum()
    }

    Next(ByRef k, ByRef v := "")
    {
      if(r := this.enum.Next(k, v))
        v := (this.obj)[k]
      return r
    }
  }
}
