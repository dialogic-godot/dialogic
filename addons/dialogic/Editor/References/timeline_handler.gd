@tool
extends Node

const VARIABLES = 'variables'
#const PORTRAITS = 'portraits'

const DEFAULT_TIMELINE_REFERENCES = {
    VARIABLES : []
#   PORTRAITS : []
}

var timeline_references = {}


func get_variables(timeline: DialogicTimeline) -> Array:
    var variables_in_timeline : Array = []
    var file = FileAccess.open(timeline.resource_path, FileAccess.READ).get_as_text()

    var regex = RegEx.new()
    regex.compile('(?<={)(.*?)(?=})')

    var result = regex.search_all(file)
    
    if result.is_empty():
        return []
    
    for variable in result:
        if not variable.get_string() in variables_in_timeline:
            variables_in_timeline.append(variable.get_string())

    return variables_in_timeline


func create_key_in_references(timeline: DialogicTimeline):
    timeline_references[timeline] = DEFAULT_TIMELINE_REFERENCES


func clear_variable_links(timeline: DialogicTimeline):
    timeline_references[timeline] = { VARIABLES : [] }


func store_variables(timeline: DialogicTimeline, variables_in_timeline: Array):    
    timeline_references[timeline] = { VARIABLES : variables_in_timeline } 
