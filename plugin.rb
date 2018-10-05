# name: discourse-chat-integration
# about: This plugin integrates discourse with a number of chat providers
# version: 0.1
# url: https://github.com/discourse/discourse-chat-integration
# author: David Taylor

enabled_site_setting :chat_integration_enabled

register_asset "stylesheets/chat-integration-admin.scss"

# Site setting validators must be loaded before initialize
require_relative "lib/discourse_chat/provider/slack/slack_enabled_setting_validator"

after_initialize do
  require_relative "app/initializers/discourse_chat"

  on(:post_created) do |post|
    # This will run for every post, even PMs. Don't worry, they're filtered out later.
    time = SiteSetting.chat_integration_delay_seconds.seconds
    Jobs.enqueue_in(time, :notify_chats, post_id: post.id)
  end

  on(:accepted_solution) do |post|
    time = SiteSetting.chat_integration_delay_seconds.seconds
    Jobs.enqueue_in(time, :notify_chats, post_id: post.id)
  end

  add_admin_route 'chat_integration.menu_title', 'chat'

  AdminDashboardData.add_problem_check do
    error = false;
    DiscourseChat::Channel.find_each do |channel|
      error = true unless channel.error_key.blank?
    end
    I18n.t("chat_integration.admin_error") if error
  end

  DiscourseChat::Provider.mount_engines
end
