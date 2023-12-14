class_name DialogicTranslationRecord extends RefCounted

var updated_csvs := 0
var new_csvs := 0

var updated_events := 0
var new_events := 0

var updated_characters := 0
var new_characters := 0

var updated_timelines := 0
var new_timelines := 0

var new_names := 0
var updated_names := 0

## Combines the changes from [param other_record] into this record.
func combine(other_record: DialogicTranslationRecord) -> void:
    updated_csvs += other_record.updated_csvs
    new_csvs += other_record.new_csvs

    updated_events += other_record.updated_events
    new_events += other_record.new_events

    updated_characters += other_record.updated_characters
    new_characters += other_record.new_characters
