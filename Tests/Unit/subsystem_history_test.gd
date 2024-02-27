extends GdUnitTestSuite

var history := Dialogic.History

const EXAMPLE_SEEN_HISTORY: Dictionary = {
    "res://Dialogic/Timelines/start.dtl1": 1,
    "res://Dialogic/Timelines/start.dtl2": 2,
    "res://Dialogic/Timelines/start.dtl3": 3,
    "res://Dialogic/Timelines/start.dtl4": 4,
    "res://Dialogic/Timelines/start.dtl5": 5,
    "res://Dialogic/Timelines/start.dtl7": 7
}

func test_save_load_visited() -> void:
    assert(history.visited_event_history_content == {}, "Seen events should have be empty.")
    history.load_visited_history()
    assert(history.visited_event_history_content == {}, "Seen events should have be empty after empty load.")

    history.visited_event_history_content = EXAMPLE_SEEN_HISTORY
    assert(history.visited_event_history_content == EXAMPLE_SEEN_HISTORY, "Seen events should have be identical to test data.")

    history.save_visited_history()
    var global_data_seen_events: Dictionary = history.get_saved_visited_history()

    assert(global_data_seen_events == EXAMPLE_SEEN_HISTORY, "Global data does not have example data.")

    history.load_visited_history()
    assert(history.visited_event_history_content == EXAMPLE_SEEN_HISTORY, "Seen events should have be identical to test data after load.")


func test_deletion_save_visited() -> void:
    history.visited_event_history_content = EXAMPLE_SEEN_HISTORY
    assert(history.visited_event_history_content == EXAMPLE_SEEN_HISTORY, "Seen events should have be identical to test data.")

    history.save_visited_history()
    var global_data_seen_events: Dictionary = history.get_saved_visited_history()
    assert(global_data_seen_events == EXAMPLE_SEEN_HISTORY, "Global data does not have example data.")

    history.reset_visited_history(false)
    var global_data_seen_events_after_reset: Dictionary = history.get_saved_visited_history()
    assert(history.visited_event_history_content == EXAMPLE_SEEN_HISTORY, "Seen events are gone after global data only reset.")
    assert(global_data_seen_events_after_reset == {}, "Global data should be empty after reset.")

    history.load_visited_history()
    assert(history.visited_event_history_content == {}, "Seen events should have be empty after empty load.")

    history.visited_event_history_content = EXAMPLE_SEEN_HISTORY
    history.reset_visited_history(true)
    var global_data_seen_events_after_full_reset: Dictionary = history.get_saved_visited_history()
    assert(global_data_seen_events_after_full_reset == {}, "Seen events in global data should have be empty after full data reset.")
    assert(history.visited_event_history_content == {}, "Seen events in history should have be empty after full data reset.")
