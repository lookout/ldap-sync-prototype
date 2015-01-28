Then %r{^run_sync should get option :(\S+) with "(.*)"$} do |option, value|
  expect(run_sync_called?).to be_true
  expect(run_sync_opts[option.to_sym]).to eq(value)
end

Given %r{^a stubbed run_sync method$} do
  allow(Conjur::Ldap::Sync).to receive(:run_sync) do |opts|
    self.run_sync_opts = opts
    self.run_sync_called = true
  end
end