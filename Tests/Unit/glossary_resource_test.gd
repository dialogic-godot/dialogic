## This test suite tests the DialogicGlossary class.
extends GdUnitTestSuite


## We test to add a glossary entry and whether the resulting states of the
## glossary indicate that the entry was added correctly.
func test_add_entry() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()
	const NAME_ENTRY := "Example Name"
	const EXAMPLE_TITLE := "Example Title"
	const ALTERNATIVE_ENTRIES := ["A", "BE", "VERY LONG ENTRY"]

	var new_entry := {
		DialogicGlossary.TITLE_PROPERTY: EXAMPLE_TITLE,
		DialogicGlossary.NAME_PROPERTY: NAME_ENTRY,
		DialogicGlossary.ALTERNATIVE_PROPERTY: ALTERNATIVE_ENTRIES
	}

	glossary.set_entry(NAME_ENTRY, new_entry)

	assert(glossary.entries.size() == 1, "Glossary should have 1 entry")
	assert(not glossary.get_entry(NAME_ENTRY).is_empty(), "Entry index cannot be found via entry name.")

	const NAME_COUNTER := 1
	var total_entry_count := ALTERNATIVE_ENTRIES.size() + NAME_COUNTER

	var error :=  "Must have " + str(total_entry_count) + " entries, not " + str(glossary.entries.size()) + "."
	assert(glossary.entries.size() == total_entry_count, error)

	for alternative: String in ALTERNATIVE_ENTRIES:
		var assert_error_message := "Entry index cannot be found via alternative name: " + alternative
		assert(not glossary.get_entry(alternative).is_empty(), assert_error_message)


## We test whether an entry's key can be replaced and if the resulting action
## invalidates the old entry key when accessing the glossary.
func test_replace_entries() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()
	const NAME_ENTRY := "Example Name"
	const EXAMPLE_TITLE := "Example Title"
	const ALTERNATIVE_ENTRIES := ["A", "BE", "VERY LONG ENTRY"]

	var new_entry := {
		DialogicGlossary.TITLE_PROPERTY: EXAMPLE_TITLE,
		DialogicGlossary.NAME_PROPERTY: NAME_ENTRY,
		DialogicGlossary.ALTERNATIVE_PROPERTY: ALTERNATIVE_ENTRIES
	}

	glossary.set_entry(NAME_ENTRY, new_entry)

	const NEW_NAME := "NEW NAME"

	glossary.replace_entry_key(NAME_ENTRY, NEW_NAME)

	var entry := glossary.get_entry(NEW_NAME)
	var error :=  "Entry expected to be an instance, was null."
	assert(not entry == null, error)

	var old_entry := glossary.get_entry(NAME_ENTRY)
	error =  "Entry expected to be null, was an instance."
	assert(old_entry == null, error)


func _try_delete_alias() -> void:
    # remove_entry_key(entry_key: String) -> bool:
	# test
	pass
