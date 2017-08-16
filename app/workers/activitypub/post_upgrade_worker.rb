# frozen_string_literal: true

class ActivityPub::PostUpgradeWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(account_id)
    @account = Account.find(account_id)

    # Unsubscribe from PuSH as it's no longer needed
    ::UnsubscribeService.new.call(@account)

    # Invalidate webfinger cache on other accounts from
    # the same domain
    affected_accounts.in_batches
                     .update_all(last_webfingered_at: nil)

    # And queue them all to be refreshed
    WebfingerWorker.push_bulk(affected_accounts.pluck(:username)) do |username|
      ["#{username}@#{@account.domain}"]
    end
  end

  def affected_accounts
    @affected_accounts ||= Account.where(domain: @account.domain)
                                  .where(protocol: :ostatus)
  end
end
