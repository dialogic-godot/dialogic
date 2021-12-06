using Godot;
using GC = Godot.Collections;
using System;

public static class DialogicSharp
{
  private static Script _dialogic = GD.Load<Script>("res://addons/dialogic/Other/DialogicClass.gd");
  private const String DEFAULT_DIALOG_RESOURCE = "res://addons/dialogic/Nodes/DialogNode.tscn";

  // Check the documentation of the DialogicClass for more information on how to use these functions!
  public static Node Start(String timeline = "", String default_timeline = "", bool useCanvasInstead = true)
  {
    return Start<Node>(timeline, default_timeline, DEFAULT_DIALOG_RESOURCE, useCanvasInstead);
  }

  public static T Start<T>(String timeline = "", String default_timeline = "", String dialogScenePath = "", bool useCanvasInstead = true) where T : class
  {
    return (T)_dialogic.Call("start", timeline, default_timeline, dialogScenePath, useCanvasInstead);
  }
  
  // ------------------------------------------------------------------------------------------
  // 				SAVING/LOADING
  // ------------------------------------------------------------------------------------------
  public static void Load(String slot_name = "")
  {
     _dialogic.Call("load", slot_name);
  }
  
  public static void Save(String slot_name = "")
  {
     _dialogic.Call("save", slot_name);
  }

  public static GC.Array GetSlotNames()
  {
     return (GC.Array)_dialogic.Call("get_slot_names");
  }
  
  public static void EraseSlot(String slot_name)
  {
     _dialogic.Call("erase_slot", slot_name);
  }

  public static bool HasCurrentDialogNode()
  {
     return (bool)_dialogic.Call("has_current_dialog_node");
  }

  public static void ResetSaves()
  {
    _dialogic.Call("reset_saves");
  }

  public static String GetCurrentSlot()
  {
     return (String)_dialogic.Call("get_current_slot");
  }
  
  // ------------------------------------------------------------------------------------------
  // 				IMPORT/EXPORT
  // ------------------------------------------------------------------------------------------
  public static GC.Dictionary Export()
  {
    return (GC.Dictionary)_dialogic.Call("export");
  }

  public static void Import(GC.Dictionary data)
  {
    _dialogic.Call("import", data);
  }
  
  // ------------------------------------------------------------------------------------------
  // 				DEFINITIONS
  // ------------------------------------------------------------------------------------------
  public static String GetVariable(String name)
  {
    return (String)_dialogic.Call("get_variable", name);
  }

  public static void SetVariable(String name, String value)
  {
    _dialogic.Call("set_variable", name, value);
  }

  // ------------------------------------------------------------------------------------------
  // 				OTHER STUFF
  // ------------------------------------------------------------------------------------------
  public static String CurrentTimeline
  {
    get
    {
      return (String)_dialogic.Call("get_current_timeline");
    }
    set
    {
      _dialogic.Call("set_current_timeline", value);
    }
  }

  public static GC.Dictionary Definitions
  {
    get
    {
      return (GC.Dictionary)_dialogic.Call("get_definitions");
    }
  }

  public static GC.Dictionary DefaultDefinitions
  {
    get
    {
      return (GC.Dictionary)_dialogic.Call("get_default_definitions");
    }
  }

  public static bool Autosave
  {
    get
    {
      return (bool)_dialogic.Call("get_autosave");
    }
    set
    {
      _dialogic.Call("set_autosave", value);
    }
  }
}
