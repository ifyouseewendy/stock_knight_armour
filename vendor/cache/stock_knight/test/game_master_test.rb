require 'test_helper'

class GameMasterTest < Minitest::Test
  attr_reader :gm, :level

  def setup
    @level = :first_steps
    @gm = StockKnight::GameMaster.new(ENV['APIKEY'])
  end

  def test_start
    resp = nil

    VCR.use_cassette("test_start") do
      resp = gm.start(level)

      assert resp.has_key?(:ok)
      resp[:ok] ? assert_nil(resp[:error]) : refute_nil(resp[:error])
    end

    VCR.use_cassette("test_stop") do
      instance_id = resp[:instanceId]
      gm.stop(instance_id)
    end
  end

  def test_stop
    resp = nil

    VCR.use_cassette("test_start") do
      resp = gm.start(level)
    end

    VCR.use_cassette("test_stop") do
      instance_id = resp[:instanceId]

      resp = gm.stop(instance_id)

      assert resp.has_key?(:ok)
      resp[:ok] ? assert_empty(resp[:error]) : refute_empty(resp[:error])
    end
  end

  def test_active?
    VCR.use_cassette("test_active_fake_id") do
      refute gm.active?('fake_id')
    end

    resp = nil
    VCR.use_cassette("test_start") do
      resp = gm.start(level)
    end

    VCR.use_cassette("test_active_instance_id") do
      instance_id = resp[:instanceId]
      assert gm.active?(instance_id)

      VCR.use_cassette("test_stop") do
        gm.stop(instance_id)
      end
    end

  end

  def test_resume
    resp = nil

    VCR.use_cassette("test_start") do
      resp = gm.start(level)
    end

    instance_id = resp[:instanceId]

    VCR.use_cassette("test_resume") do
      resp = gm.resume(instance_id)
      assert resp.has_key?(:ok)
      resp[:ok] ? assert_empty(resp[:error]) : refute_empty(resp[:error])
    end

    VCR.use_cassette("test_stop") do
      gm.stop(instance_id)
    end
  end

  def test_restart
    resp = nil

    VCR.use_cassette("test_start") do
      resp = gm.start(level)
    end

    instance_id = resp[:instanceId]
    account     = resp[:account]

    VCR.use_cassette("test_restart") do
      resp = gm.restart(instance_id)
      assert_equal instance_id, resp[:instanceId]
      refute_equal account, resp[:account]
    end
  end

  def test_levels
    skip # from GM server: "Not implemented yet (an oversight).  Expect it to be available soonish."

    # VCR.use_cassette("test_levels") do
    #   resp = gm.levels
    #   assert resp.has_key?(:ok)
    #   resp[:ok] ? assert_empty(resp[:error]) : refute_empty(resp[:error])
    # end
  end
end
