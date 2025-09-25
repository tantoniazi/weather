require "test_helper"

class WeatherTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @weather = Weather.new(
      zip: "01310100",
      temperature: 25.0,
      temp_min: 20.0,
      temp_max: 30.0,
      description: "céu limpo",
      user: @user,
    )
  end

  test "should be valid" do
    assert @weather.valid?
  end

  test "zip should be present" do
    @weather.zip = "   "
    assert_not @weather.valid?
  end

  test "zip should be 8 digits" do
    @weather.zip = "123"
    assert_not @weather.valid?

    @weather.zip = "123456789"
    assert_not @weather.valid?

    @weather.zip = "01310100"
    assert @weather.valid?
  end

  test "temperature should be present" do
    @weather.temperature = nil
    assert_not @weather.valid?
  end

  test "temperature should be a number" do
    @weather.temperature = "not a number"
    assert_not @weather.valid?
  end

  test "temp_min should be present" do
    @weather.temp_min = nil
    assert_not @weather.valid?
  end

  test "temp_max should be present" do
    @weather.temp_max = nil
    assert_not @weather.valid?
  end

  test "description should be present" do
    @weather.description = "   "
    assert_not @weather.valid?
  end

  test "should belong to user" do
    assert_respond_to @weather, :user
    assert_equal @user, @weather.user
  end

  test "should be valid without user (for public searches)" do
    @weather.user = nil
    assert @weather.valid?
  end

  test "temp_min should be less than or equal to temp_max" do
    @weather.temp_min = 30.0
    @weather.temp_max = 20.0
    assert_not @weather.valid?

    @weather.temp_min = 20.0
    @weather.temp_max = 30.0
    assert @weather.valid?
  end

  test "temperature should be between temp_min and temp_max" do
    @weather.temperature = 15.0  # Less than temp_min (20.0)
    assert_not @weather.valid?

    @weather.temperature = 35.0  # Greater than temp_max (30.0)
    assert_not @weather.valid?

    @weather.temperature = 25.0  # Between temp_min and temp_max
    assert @weather.valid?
  end

  test "should save with valid attributes" do
    assert_difference "Weather.count" do
      @weather.save
    end
  end

  test "should not save with invalid attributes" do
    @weather.zip = "123"
    assert_no_difference "Weather.count" do
      @weather.save
    end
  end
end
