require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @admin = users(:michael)
    @non_admin = users(:archer)
  end

  test "index including pagination and delete links" do
    log_in_as(@admin)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination', count: 2
    first_page_of_users = User.paginate(page:1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      unless user == @admin
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end

  test "index as non-admin" do
    log_in_as(@non_admin)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end

  test "users search" do
    log_in_as(@admin)
    #ユーザーを検索
    get users_path, params: { q: { name_cont: "a" } }
    q = User.ransack(name_cont: "a", activated: true)
    q.result.paginate(page:1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
    end
    assert_select 'title', "Search Result | Photogram"
    #全てのユーザー
    get users_path, params: { q: { name_cont: "" } }
    User.paginate(page:1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
    end
    assert_select 'title', "All users | Photogram"
    #検索対象のユーザーが存在しない
    get users_path, params: { q: { name_cont: "abcdefghijklmnopqrstuvwxyz" } }
    assert_match "Couldn't find any user.", response.body
  end

end
