## This test suite tests the DialogicGlossary class.
extends GdUnitTestSuite


const NAME_ENTRY := "Example Name"
const EXAMPLE_TITLE := "Example Title"
const ALTERNATIVE_ENTRIES := ["A", "BE", "VERY LONG ENTRY"]

var SAMPLE_ENTRY := {
	DialogicGlossary.TITLE_PROPERTY: EXAMPLE_TITLE,
	DialogicGlossary.NAME_PROPERTY: NAME_ENTRY,
	DialogicGlossary.ALTERNATIVE_PROPERTY: ALTERNATIVE_ENTRIES
}


## We test to add a glossary entry and whether the resulting states of the
## glossary indicate that the entry was added correctly.
func test_add_entry() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()

	assert(glossary.try_add_entry(SAMPLE_ENTRY.duplicate()), "Unable to add entry.")

	const NAME_COUNTER := 1
	var total_entry_count := ALTERNATIVE_ENTRIES.size() + NAME_COUNTER

	assert(glossary.entries.size() == total_entry_count, "Glossary should have 1 entry")
	assert(not glossary.get_entry(NAME_ENTRY).is_empty(), "Entry index cannot be found via entry name.")

	for alternative: String in ALTERNATIVE_ENTRIES:
		var assert_error_message := "Entry index cannot be found via alternative name: " + alternative
		assert(not glossary.get_entry(alternative).is_empty(), assert_error_message)


## We test whether an entry's key can be replaced and if the resulting action
## invalidates the old entry key when accessing the glossary.
func test_replace_entries() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()

	assert(glossary.try_add_entry(SAMPLE_ENTRY.duplicate()), "Unable to add entry.")

	const NEW_NAME := "NEW NAME"

	glossary.replace_entry_key(NAME_ENTRY, NEW_NAME)

	var entry := glossary.get_entry(NEW_NAME)
	var error :=  "Entry expected to be non-empty, was empty."
	assert(not entry.is_empty(), error)

	var old_entry := glossary.get_entry(NAME_ENTRY)
	error =  "Entry expected to be empty, was an instance."
	assert(old_entry.is_empty(), error)


## We test whether adding and deleting entries work.
func test_remove_entry() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()

	assert(glossary.try_add_entry(SAMPLE_ENTRY.duplicate()), "Unable to add entry.")

	const NAME_COUNTER := 1
	var total_entry_count := ALTERNATIVE_ENTRIES.size() + NAME_COUNTER

	assert(glossary.entries.size() == total_entry_count, "Glossary should have " + str(total_entry_count) + " entries.")

	var remove_result: bool = glossary.remove_entry(NAME_ENTRY)

	assert(remove_result, "Removal of entry failed.")
	assert(glossary.get_entry(NAME_ENTRY).is_empty(), "Entry should not exist.")
	assert(glossary.entries.size() == 0, "Glossary should have 0 entries but has " + str(glossary.entries.size()) + " entries.")


func test_add_duplicates() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()

	assert(glossary.try_add_entry(SAMPLE_ENTRY.duplicate()), "Unable to add entry.")
	assert(not glossary.try_add_entry(SAMPLE_ENTRY.duplicate()), "Entry should not have been added.")
