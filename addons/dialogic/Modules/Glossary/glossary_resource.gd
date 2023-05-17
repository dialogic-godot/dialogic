@tool
class_name DialogicGlossary
extends Resource

## Resource used to store glossary entries. Can be saved to disc and used as a glossary. 
## Add/create glossaries fom the glossaries editor 

## Stores all entry information
@export var entries :Dictionary = {}

## If false, no entries from this glossary will be shown
@export var enabled :bool = true
