class_name GdUnitExampleTest
extends GdUnitTestSuite

func test_example() -> void:
    const EXAMPLE_STRING := "Dialogic!"

    assert_str(EXAMPLE_STRING)\
        .has_length(EXAMPLE_STRING.length())\
        .starts_with("Dia")
