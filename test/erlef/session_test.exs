defmodule Erlef.SessionTest do
  use ExUnit.Case, async: true

  # See test/support/models/wild_apricot.ex for service detail

  describe "new/2" do
    test "when is admin" do
      data = %{
        "Permissions" => [
          %{
            "AccountId" => "account_id",
            "AvailableScopes" => ["contacts_me", "account_view"],
            "SecurityProfileId" => 12_345_67
          }
        ],
        "access_token" => "basic_member",
        "expires_in" => 1800,
        "refresh_token" => "rt_basic_member",
        "token_type" => "Bearer"
      }

      assert %Erlef.Session{} = Erlef.Session.new(data)
    end

    test "when is not admin" do
      data = %{
        "Permissions" => [
          %{
            "AccountId" => "account_id",
            "AvailableScopes" => ["contacts_me", "account_view"],
            "SecurityProfileId" => 54_321
          }
        ],
        "access_token" => "basic_member",
        "expires_in" => 1_800,
        "refresh_token" => "rt_basic_member",
        "token_type" => "Bearer"
      }

      assert %Erlef.Session{
               access_token: _,
               account_id: _,
               member_id: _,
               expires_at: _,
               refresh_token: _,
               username: "Basic Member"
             } = Erlef.Session.new(data)
    end
  end

  test "encode/1" do
    session = %Erlef.Session{
      access_token: "HiuWUvqcMMuY-4AlJ5rM2ZqSbeo-",
      account_id: "account_id",
      member_id: "basic_member",
      expires_at: "2020-02-23 18:51:18.548936Z",
      refresh_token: "rt_2020-02-23_JoR0ez-SYAFjcOIkgO-5HqHWt9E-",
      username: "eh"
    }

    map = session |> Map.from_struct() |> Map.delete(:member)
    expected = Jason.encode!(%{"member_session" => map})
    assert {:ok, ^expected} = Erlef.Session.encode(%{"member_session" => session})
  end

  test "normalize/1" do
    session = %{
      "access_token" => "basic_member",
      "account_id" => "account_id",
      "member_id" => "basic_member",
      "expires_at" => "2020-02-23 18:51:18.548936Z",
      "refresh_token" => "rt_basic_member",
      "username" => "Basic Member"
    }

    assert normalized = %Erlef.Session{} = Erlef.Session.normalize(session)
    assert normalized.member
    assert normalized.access_token == "basic_member"

    #     assert Erlef.Session.normalize(session) == %Erlef.Session{
    #              access_token: "basic_member",
    #              account_id: "account_id",
    #              member_id: "basic_member",
    #              member: %Erlef.Accounts.Member{},
    #              expires_at: "2020-02-23 18:51:18.548936Z",
    #              refresh_token: "rt_basic_member",
    #              username: "Basic Member"
    #            }
  end

  test "login/1" do
    assert {:ok, %Erlef.Session{}} = Erlef.Session.login("basic_member")
  end

  test "logout/1" do
    assert {:ok, session} = Erlef.Session.login("basic_member")
    assert :ok = Erlef.Session.logout(session)
  end

  test "should_refresh/1" do
    session = %Erlef.Session{
      access_token: "HiuWUvqcMMuY-4AlJ5rM2ZqSbeo-",
      account_id: "account_id",
      member_id: "basic_member",
      expires_at: "2020-02-23 18:51:18.548936Z",
      refresh_token: "rt_2020-02-23_JoR0ez-SYAFjcOIkgO-5HqHWt9E-",
      username: "eh"
    }

    assert Erlef.Session.should_refresh?(session) == true

    session = %Erlef.Session{
      access_token: "HiuWUvqcMMuY-4AlJ5rM2ZqSbeo-",
      account_id: "account_id",
      member_id: "basic_member",
      expires_at: DateTime.to_string(Timex.shift(DateTime.utc_now(), minutes: 100)),
      refresh_token: "rt_2020-02-23_JoR0ez-SYAFjcOIkgO-5HqHWt9E-",
      username: "eh"
    }

    assert Erlef.Session.should_refresh?(session) == false
  end

  test "expired?/1" do
    session = %Erlef.Session{
      access_token: "HiuWUvqcMMuY-4AlJ5rM2ZqSbeo-",
      account_id: "account_id",
      member_id: "basic_member",
      expires_at: "2020-02-23 18:51:18.548936Z",
      refresh_token: "rt_2020-02-23_JoR0ez-SYAFjcOIkgO-5HqHWt9E-",
      username: "eh"
    }

    assert Erlef.Session.expired?(session) == true

    session = %Erlef.Session{
      access_token: "basic_member",
      account_id: "account_id",
      member_id: "basic_member",
      expires_at: DateTime.to_string(Timex.shift(DateTime.utc_now(), minutes: 100)),
      refresh_token: "rt_basic_member",
      username: "Basic Member"
    }

    assert Erlef.Session.expired?(session) == false
  end

  test "refresh/1" do
    session = %Erlef.Session{
      access_token: "basic_member",
      account_id: "account_id",
      member_id: "basic_member",
      expires_at: DateTime.to_string(Timex.shift(DateTime.utc_now(), minutes: 100)),
      refresh_token: "rt_basic_member",
      username: "Basic Member"
    }

    assert {:ok,
            %Erlef.Session{
              access_token: _,
              account_id: _,
              member_id: _,
              expires_at: _,
              refresh_token: _,
              username: "Basic Member"
            }} = Erlef.Session.refresh(session)
  end
end
