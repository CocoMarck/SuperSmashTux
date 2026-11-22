class_name PowerFighterData
extends RefCounted

var control: GlobalUtils.ControlType
var config_id: StringName
var lives: int

# Solo uno de los dos aplica, según `control`: PLAYER usa player_id, NPC usa npc_id.
var player_id: GlobalUtils.PlayerId
var npc_id: GlobalUtils.NPCId
