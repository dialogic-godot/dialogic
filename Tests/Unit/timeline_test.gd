extends GdUnitTestSuite

func test_speaker_name() -> void:
	var test_timeline := DialogicTimeline.new()
	test_timeline.from_text("tyler: hello\ndominic: hello")
	
	test_timeline.process()
	assert(test_timeline.events.size() == 2, "Error when processing test timeline.")
	
	for event: DialogicEvent in test_timeline.events:
		assert(event is DialogicTextEvent, "Text event was parsed incorrectly.")
