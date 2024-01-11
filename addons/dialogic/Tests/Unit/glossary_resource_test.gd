## This test suite tests the DialogicGlossary class.
class_name GlossaryResourceTest
extends GdUnitTestSuite


## We test to add a glossary entry and whether the resulting states of the
## glossary indicate that the entry was added correctly.
func test_add_entry() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()
	const NAME_ENTRY := "Example Name"
	const EXAMPLE_TITLE := "Example Title"
	const ALTERNATIVE_ENTRIES := ["A", "BE", "VERY LONG ENTRY"]

	const EXPECTED_ENTRY_INDEX := 0

	var new_entry := {
		DialogicGlossary.TITLE_PROPERTY: EXAMPLE_TITLE,
		DialogicGlossary.NAME_PROPERTY: NAME_ENTRY,
		DialogicGlossary.ALTERNATIVE_PROPERTY: ALTERNATIVE_ENTRIES
	}

	glossary.set_entry(NAME_ENTRY, new_entry)

	assert(glossary.entries.size() == 1, "Glossary should have 1 entry")
	assert(glossary._find_entry_index_by_key(NAME_ENTRY) == EXPECTED_ENTRY_INDEX, "Entry index cannot be found via entry name.")

	const NAME_COUNTER := 1
	var total_entry_count := ALTERNATIVE_ENTRIES.size() + NAME_COUNTER

	var error :=  "Must have " + str(total_entry_count) + " entries, not " + str(glossary._entry_keys.size()) + "."
	assert(glossary._entry_keys.size() == total_entry_count, error)

	for alternative: String in ALTERNATIVE_ENTRIES:
		var assert_error_message := "Entry index cannot be found via alternative name: " + alternative
		assert(glossary._find_entry_index_by_key(alternative) == 0, assert_error_message)


## We test whether an entry's key can be replaced and if the resulting action
## invalidates the old entry key when accessing the glossary.
func test_replace_entries() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()
	const NAME_ENTRY := "Example Name"
	const EXAMPLE_TITLE := "Example Title"
	const ALTERNATIVE_ENTRIES := ["A", "BE", "VERY LONG ENTRY"]

	const EXPECTED_ENTRY_INDEX := 0
	const MISSING_INDEX := -1

	var new_entry := {
		DialogicGlossary.TITLE_PROPERTY: EXAMPLE_TITLE,
		DialogicGlossary.NAME_PROPERTY: NAME_ENTRY,
		DialogicGlossary.ALTERNATIVE_PROPERTY: ALTERNATIVE_ENTRIES
	}

	glossary.set_entry(NAME_ENTRY, new_entry)

	const NEW_NAME := "NEW NAME"

	glossary.replace_entry_key(NAME_ENTRY, NEW_NAME)
	var entry_index := glossary._find_entry_index_by_key(NEW_NAME)

	var error :=  "Entry index expected to be " + str(EXPECTED_ENTRY_INDEX) + ", was: " + str(entry_index) + "."
	assert(entry_index == EXPECTED_ENTRY_INDEX, error)

	var old_entry_index := glossary._find_entry_index_by_key(NAME_ENTRY)
	assert(old_entry_index == MISSING_INDEX, "Old entry should not be found, entry index was: " + str(old_entry_index) + ".")


## We are testing if a glossary with an entry key leading to a wrong index
## will be corrected.
## The correction must find the matching entry and take its index as the
## proper corrected index.
## This test stems from a bug, where editing the glossary in the editor
## was not updating the key properly.
func test_invalid_entry_index_correction() -> void:
	var glossary: DialogicGlossary = DialogicGlossary.new()
	const EXAMPLE_NAME := "Example Name"
	const EXAMPLE_TITLE := "Example Title"
	const ALTERNATIVE_ENTRIES := ["A", "BE", "VERY LONG ENTRY"]

	const EXPECTED_INDEX := 0

	var new_entry := {
		DialogicGlossary.TITLE_PROPERTY: EXAMPLE_TITLE,
		DialogicGlossary.NAME_PROPERTY: EXAMPLE_NAME,
		DialogicGlossary.ALTERNATIVE_PROPERTY: ALTERNATIVE_ENTRIES
	}

	# Initially, we add the entry.
	glossary.set_entry(EXAMPLE_NAME, new_entry)

	# Verify the glossary has properly picked up the entry.
	var entry_index: int = glossary._find_entry_index_by_key(EXAMPLE_NAME)
	assert(entry_index == EXPECTED_INDEX, "Entry index should be " + str(EXPECTED_INDEX) + ", was: " + str(entry_index) + ".")

	# Now, we will forcefully invalidate the entry key.
	glossary._entry_keys[0] = 2000

	# Next, we will try to rename the entry.
	const NEW_NAME := "new name"
	glossary.replace_entry_key(EXAMPLE_NAME, NEW_NAME)

	var corrected_entry_index: int = glossary._find_entry_index_by_key(NEW_NAME)
	assert(corrected_entry_index == EXPECTED_INDEX, "Corrected entry index should be " + str(EXPECTED_INDEX) + ", was: " + str(corrected_entry_index) + ".")
