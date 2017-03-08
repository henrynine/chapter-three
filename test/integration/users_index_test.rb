require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    @non_admin_user = users(:archer)
  end

  test "redirects to login page when not logged in" do
    get users_path
    assert_redirected_to login_url
  end

  test "displays links to users when logged in" do
    log_in_as @user
    get users_path
    assert_template 'users/index'
    assert_select "a[href=?]", user_path(@user)
  end

  test "only display links to activated users" do
    log_in_as @user
    get users_path
    assert_template 'users/index'
    assert_select "a[href=?]", user_path(User.find_by(email: "fake@example.com")), count: 0
  end


  test "index including pagination" do
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination', count: 2
    User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name if user.activated?
    end
  end

  test "index as admin including pagination and delete links" do
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination', count: 2
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name if user.activated?
      unless user == @user
        assert_select 'a[href=?]', user_path(user), text: 'delete' if user.activated?
      end
    end
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin_user)
    end
  end

  test "index as non-admin" do
    log_in_as(@non_admin_user)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end
end
