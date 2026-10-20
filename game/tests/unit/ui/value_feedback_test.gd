extends GdUnitTestSuite
## Sayı değişimi geri bildirimi — resource-system.md §9, art bible §7 "HUD sayı değişimi" (C-66).


func before_test() -> void:
	TranslationServer.set_locale("en")


func _observed(start: int, reduce_motion: bool = false, increases_only: bool = false) -> ValueFeedback:
	var feedback: ValueFeedback = ValueFeedback.new()
	feedback.reduce_motion = reduce_motion
	feedback.increases_only = increases_only
	feedback.observe(start)
	return feedback


func test_value_feedback_first_observation_is_baseline_without_feedback() -> void:
	var feedback: ValueFeedback = ValueFeedback.new()
	assert_bool(feedback.observe(25)).is_false()
	assert_bool(feedback.is_flashing()).is_false()
	assert_str(feedback.delta_text()).is_empty()


func test_value_feedback_increase_flashes_green_with_up_arrow() -> void:
	var feedback: ValueFeedback = _observed(10)
	assert_bool(feedback.observe(15)).is_true()
	assert_object(feedback.flash_color(Color.WHITE)).is_equal(ValueFeedback.COLOR_GAIN)
	assert_str(feedback.delta_text()).is_equal(NumberFormatter.ltr("↑+5"))


func test_value_feedback_decrease_flashes_red_with_down_arrow_and_ascii_minus() -> void:
	var feedback: ValueFeedback = _observed(10)
	feedback.observe(4)
	assert_object(feedback.flash_color(Color.WHITE)).is_equal(ValueFeedback.COLOR_LOSS)
	assert_str(feedback.delta_text()).is_equal(NumberFormatter.ltr("↓-6"))


func test_value_feedback_unchanged_value_gives_no_feedback() -> void:
	var feedback: ValueFeedback = _observed(10)
	assert_bool(feedback.observe(10)).is_false()
	assert_object(feedback.flash_color(Color.WHITE)).is_equal(Color.WHITE)


func test_value_feedback_flash_is_two_ui_frames_and_shorter_than_delta_text() -> void:
	assert_float(ValueFeedback.FLASH_SEC).is_equal_approx(2 * ValueFeedback.UI_FRAME_SEC, 0.0001)
	assert_float(ValueFeedback.DELTA_HOLD_SEC).is_greater(ValueFeedback.FLASH_SEC)
	var feedback: ValueFeedback = _observed(10)
	feedback.observe(12)
	feedback.expire_flash()
	assert_bool(feedback.is_flashing()).is_false()
	assert_str(feedback.delta_text()).is_not_empty()
	feedback.expire_delta()
	assert_str(feedback.delta_text()).is_empty()


func test_value_feedback_reduce_motion_keeps_highlight_until_next_change() -> void:
	var feedback: ValueFeedback = _observed(10, true)
	feedback.observe(12)
	feedback.expire_flash()
	feedback.expire_delta()
	assert_object(feedback.flash_color(Color.WHITE)).is_equal(ValueFeedback.COLOR_GAIN)
	assert_str(feedback.delta_text()).is_equal(NumberFormatter.ltr("↑+2"))
	feedback.observe(9)
	assert_str(feedback.delta_text()).is_equal(NumberFormatter.ltr("↓-3"))


func test_value_feedback_increases_only_clears_on_decrease() -> void:
	var feedback: ValueFeedback = _observed(3, false, true)
	feedback.observe(5)
	assert_bool(feedback.observe(1)).is_false()
	assert_bool(feedback.is_flashing()).is_false()
	assert_str(feedback.delta_text()).is_empty()
