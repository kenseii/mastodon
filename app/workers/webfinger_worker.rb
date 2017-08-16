# frozen_string_literal: true

class WebfingerWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', unique: :until_executed

  def perform(acct)
    ResolveRemoteAccountService.new.call(acct)
  end
end
