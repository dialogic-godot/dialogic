extends GdUnitTestSuite

var history := Dialogic.History
var save := Dialogic.Save

const EXAMPLE_SEEN_HISTORY: Dictionary = {
    "res://Dialogic/Timelines/start.dtl1": 1,
    "res://Dialogic/Timelines/start.dtl2": 2,
    "res://Dialogic/Timelines/start.dtl3": 3,
    "res://Dialogic/Timelines/start.dtl4": 4,
    "res://Dialogic/Timelines/start.dtl5": 5,
    "res://Dialogic/Timelines/start.dtl7": 7
}

func test_save_load_already_seen() -> void:
    assert(history.already_read_history_content == {}, "Seen events should have be empty.")
    save.load_already_seen_history()
    assert(history.already_read_history_content == {}, "Seen events should have be empty after empty load.")

    history.already_read_history_content = EXAMPLE_SEEN_HISTORY
    assert(history.already_read_history_content == EXAMPLE_SEEN_HISTORY, "Seen events should have be identical to test data.")

    history.save_already_seen_history()
    var global_data_seen_events: Dictionary = save.get_saved_already_seen_history()

    assert(global_data_seen_events == EXAMPLE_SEEN_HISTORY, "Global data does not have example data.")

    save.load_already_seen_history()
    assert(history.already_read_history_content == EXAMPLE_SEEN_HISTORY, "Seen events should have be identical to test data after load.")


func test_deletion_save_already_seen() -> void:
    history.already_read_history_content = EXAMPLE_SEEN_HISTORY
    assert(history.already_read_history_content == EXAMPLE_SEEN_HISTORY, "Seen events should have be identical to test data.")

    history.save_already_seen_history()
    var global_data_seen_events: Dictionary = save.get_saved_already_seen_history()
    assert(global_data_seen_events == EXAMPLE_SEEN_HISTORY, "Global data does not have example data.")

    save.reset_already_seen_history(false)
    var global_data_seen_events_after_reset: Dictionary = save.get_saved_already_seen_history()
    assert(history.already_read_history_content == EXAMPLE_SEEN_HISTORY, "Seen events are gone after global data only reset.")
    assert(global_data_seen_events_after_reset == {}, "Global data should be empty after reset.")

    save.load_already_seen_history()
    assert(history.already_read_history_content == {}, "Seen events should have be empty after empty load.")

    history.already_read_history_content = EXAMPLE_SEEN_HISTORY
    save.reset_already_seen_history(true)
    var global_data_seen_events_after_full_reset: Dictionary = history.get_saved_already_seen_history()
    assert(global_data_seen_events_after_full_reset == {}, "Seen events in global data should have be empty after full data reset.")
    assert(history.already_read_history_content == {}, "Seen events in history should have be empty after full data reset.")
