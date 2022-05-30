# frozen_string_literal: true

require "test_helper"

require "fixture/basic_set"

class ModelTest < Test::Unit::TestCase
  class << self
    def startup
    end
  end

  setup do
    @user = User.new(
      name: "hasumikin",
      height: 175,
      temperature: 36.3
    )
  end

  sub_test_case "Internal methods" do
    test "Model#_set_id" do
      @user._set_id(1)
      assert_equal 1, @user.id
    end

    test "Model#_destroy" do
      @user._destroy
      @user.members do |member|
        assert_nil @user.send(member)
      end
    end
  end

  sub_test_case "Class methods" do
    test "timestamp" do
      mock(User).col(:created_at, Time, null: false)
      mock(User).col(:updated_at, Time, null: false)
      User.timestamp
    end
  end

  sub_test_case "User" do
    test "User.table_name" do
      assert_equal :users, User.table_name
    end

    test "User.literal_id" do
      User.literal_id(:ID)
      assert_equal :ID, @user.literal_id
      User.literal_id(:id) # Revert for other tests
    end

    test "User.new" do
      assert_equal nil, @user.id
      assert_equal "hasumikin", @user.name
      assert_equal 175, @user.height
      assert_equal 36.3, @user.temperature
    end

    test "@user.members" do
      assert_equal(
        %i[id name height temperature created_at updated_at].sort,
        @user.members.sort
      )
    end

    test "@user.table_name" do
      assert_equal :users, @user.table_name
    end

    test "@user.literal_id" do
      assert_equal :id, @user.literal_id
    end

    test "timestamp at update" do
      now = Time.now
      mock(Time).now { now }
      assert @user.set_timestamp(at: :update)
      assert_equal now, @user.updated_at
      assert_nil @user.created_at
    end

    test "timestamp at create" do
      now = Time.now
      mock(Time).now.times(2) { now }
      assert @user.set_timestamp(at: :create)
      assert_equal now, @user.updated_at
      assert_equal now, @user.created_at
    end

    test "no timestamp updated" do
      @user.instance_variable_set :@timestamp, false
      assert_equal false, @user.set_timestamp(at: :create)
    end
  end

  sub_test_case "Entry" do
    setup do
      @entry = Entry.new(
        title: "Use Struct",
        body: ""
      )
    end

    test "Entry.table_name" do
      assert_equal :entries, Entry.table_name
    end

    test "@entry.user is blank" do
      assert_nil @entry.user
    end

    test "@entry.table_name" do
      assert_equal :entries, @entry.table_name
    end

    test "when @entry.user exists" do
      any_instance_of(Struct) do |struct|
        mock(struct)[:user] { nil }
      end
      any_instance_of(Struct) do |struct|
        mock(struct)[:user_id].times(2) { 1 }
      end
      mock(AuroraDataApi::UserDepot).select(
        'where "id" = :id', id: 1
      ) {
        [@user]
      }
      assert_equal @user, @entry.user
    end
  end
end
